// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\inventarios-fisicos.service.ts

import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, EntityManager } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateInventarioFisicoDto } from './dto/create-inventario-fisico.dto';
import { InventarioFisicoResponseDto } from './dto/inventario-fisico-response.dto';
import { FindInventariosFisicosQueryDto } from './dto/find-inventarios-fisicos-query.dto';
import { UpdateInventarioFisicoDto } from './dto/update-inventario-fisico.dto';
import { InventarioFisico } from './entities/inventario-fisico.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class InventariosFisicosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'inventarios_fisicos',
        nombreEntidad: 'InventarioFisico',
        campoPK: 'inventario_fisico_id',
        alias: 't',
        responseDto: InventarioFisicoResponseDto,
        camposBusquedaEnQ: FindInventariosFisicosQueryDto.getCamposParaQ(),
        tablasDependientes: FindInventariosFisicosQueryDto.getDependencias(),
        joins: [
            {
                table: 'ubicaciones',
                alias: 'u',
                onCondition: 'u.ubicacion_id = t.ubicacion_id',
                selectColumns: [
                    'u.codigo AS ubicacion_codigo',
                    'u.descripcion AS ubicacion_descripcion',
                    'u.almacen_id'
                ],
                type: 'INNER'
            },
            {
                table: 'almacenes',
                alias: 'a',
                onCondition: 'a.almacen_id = u.almacen_id',
                selectColumns: [
                    'a.sucursal_id',
                    'a.almacen AS almacen_nombre',
                    'a.codigo AS almacen_codigo',
                    'a.tipo_almacen_id',
                    'a.tipo_operacion_almacen_id'
                ],
                type: 'INNER'
            },
            {
                table: 'sucursales',
                alias: 's',
                onCondition: 's.sucursal_id = a.sucursal_id',
                selectColumns: [
                    's.sucursal AS sucursal_nombre',
                    's.codigo AS sucursal_codigo',
                    's.codigo_sin AS sucursal_codigo_sin'
                ],
                type: 'INNER'
            },
            {
                table: 'trabajadores',
                alias: 'tr',
                onCondition: 'tr.trabajador_id = t.trabajador_responsable_id',
                selectColumns: [
                    `TRIM(CONCAT_WS(' ', tr.nombres, tr.paterno, tr.materno)) AS trabajador_responsable_nombre`
                ],
                type: 'INNER'
            },
            {
                table: 'trabajadores_cargos',
                alias: 'tcr',
                onCondition: 'tcr.trabajador_id = tr.trabajador_id AND tcr.es_activo = 1',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'cargos',
                alias: 'crc',
                onCondition: 'crc.cargo_id = tcr.cargo_id',
                selectColumns: [
                    'crc.cargo AS trabajador_responsable_cargo',
                    'crc.codigo AS trabajador_responsable_cargo_codigo'
                ],
                type: 'INNER'
            },
            {
                table: 'trabajadores',
                alias: 'ts',
                onCondition: 'ts.trabajador_id = t.trabajador_supervisor_id',
                selectColumns: [
                    `TRIM(CONCAT_WS(' ', ts.nombres, ts.paterno, ts.materno)) AS trabajador_supervisor_nombre`
                ],
                type: 'INNER'
            },
            {
                table: 'trabajadores_cargos',
                alias: 'tcs',
                onCondition: 'tcs.trabajador_id = ts.trabajador_id AND tcs.es_activo = 1',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'cargos',
                alias: 'csc',
                onCondition: 'csc.cargo_id = tcs.cargo_id',
                selectColumns: [
                    'csc.cargo AS trabajador_supervisor_cargo',
                    'csc.codigo AS trabajador_supervisor_cargo_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'almacen_id',
                nombreColumna: 'almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'ubicacion_id',
                nombreColumna: 'ubicacion_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'estado_id',
                nombreColumna: 'estado_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'trabajador_responsable_id',
                nombreColumna: 'trabajador_responsable_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            }
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'inventario_fisico_id',
            camposPermitidosParaOrdenar: FindInventariosFisicosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindInventariosFisicosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindInventariosFisicosQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    private async obtenerAlmacenDeUbicacion(
        manager: EntityManager,
        ubicacionId: number
    ): Promise<{ almacen_id: number; sucursal_id: number }> {
        const query = `
            SELECT u.almacen_id, a.sucursal_id
            FROM ubicaciones u
            INNER JOIN almacenes a ON a.almacen_id = u.almacen_id
            WHERE u.ubicacion_id = $1
              AND u.estado_id = $2
              AND a.estado_id = $2
            LIMIT 1
        `;
        const resultado = await manager.query(query, [ubicacionId, ESTADO_ACTIVO]);

        if (!resultado || resultado.length === 0) {
            throw new DomainException(
                `La ubicación con ID ${ubicacionId} no existe, no está activa o no tiene un almacén activo asociado.`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        return {
            almacen_id: Number(resultado[0].almacen_id),
            sucursal_id: Number(resultado[0].sucursal_id),
        };
    }

    private async validarAlmacenPerteneceASucursal(
        manager: EntityManager,
        sucursalId: number,
        almacenId: number
    ): Promise<void> {
        const query = `
            SELECT 1 FROM almacenes
            WHERE almacen_id = $1
              AND sucursal_id = $2
              AND estado_id = $3
            LIMIT 1
        `;
        const resultado = await manager.query(query, [almacenId, sucursalId, ESTADO_ACTIVO]);

        if (!resultado || resultado.length === 0) {
            throw new DomainException(
                `El almacén con ID ${almacenId} no pertenece a la sucursal con ID ${sucursalId} o no se encuentra activo.`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateInventarioFisicoDto, usuarioId: number): Promise<InventarioFisicoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const { sucursal_id } = await this.obtenerAlmacenDeUbicacion(manager, dto.ubicacion_id);

            await this.validarAlmacenPerteneceASucursal(manager, sucursal_id, dto.almacen_id);

            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dto.almacen_id),
                this.tablaValidador.validarRegistrosActivos('ubicaciones', 'ubicacion_id', dto.ubicacion_id),
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_responsable_id),
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_supervisor_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'almacen_id', valor: dto.almacen_id },
                        { nombre: 'ubicacion_id', valor: dto.ubicacion_id },
                        { nombre: 'fecha_conteo', valor: dto.fecha_conteo },
                        { nombre: 'trabajador_responsable_id', valor: dto.trabajador_responsable_id },
                        { nombre: 'trabajador_supervisor_id', valor: dto.trabajador_supervisor_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                }),
            ]);

            const inventario = manager.create(InventarioFisico, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(inventario);
                return this.findOne<InventarioFisicoResponseDto>(saved.inventario_fisico_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el inventario físico', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateInventarioFisicoDto, usuarioId: number): Promise<InventarioFisicoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const inventarioActual = await manager.findOne(InventarioFisico, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!inventarioActual) {
                throw new DomainException(
                    `Inventario físico no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindInventariosFisicosQueryDto.getDependencias(),
                FindInventariosFisicosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const nuevoAlmacenId = dtoProcesado.almacen_id ?? inventarioActual.almacen_id;
            const nuevoUbicacionId = dtoProcesado.ubicacion_id ?? inventarioActual.ubicacion_id;
            const nuevoTrabajadorResponsableId = dtoProcesado.trabajador_responsable_id ?? inventarioActual.trabajador_responsable_id;
            const nuevoTrabajadorSupervisorId = dtoProcesado.trabajador_supervisor_id ?? inventarioActual.trabajador_supervisor_id;
            const nuevaFechaConteo = dtoProcesado.fecha_conteo ?? inventarioActual.fecha_conteo;

            const { sucursal_id } = await this.obtenerAlmacenDeUbicacion(manager, nuevoUbicacionId);
            await this.validarAlmacenPerteneceASucursal(manager, sucursal_id, nuevoAlmacenId);

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.almacen_id !== undefined && dtoProcesado.almacen_id !== inventarioActual.almacen_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dtoProcesado.almacen_id)
                );
            }

            if (dtoProcesado.ubicacion_id !== undefined && dtoProcesado.ubicacion_id !== inventarioActual.ubicacion_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('ubicaciones', 'ubicacion_id', dtoProcesado.ubicacion_id)
                );
            }

            if (dtoProcesado.trabajador_responsable_id !== undefined && dtoProcesado.trabajador_responsable_id !== inventarioActual.trabajador_responsable_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dtoProcesado.trabajador_responsable_id)
                );
            }

            if (dtoProcesado.trabajador_supervisor_id !== undefined && dtoProcesado.trabajador_supervisor_id !== inventarioActual.trabajador_supervisor_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dtoProcesado.trabajador_supervisor_id)
                );
            }

            if (
                dtoProcesado.almacen_id !== undefined ||
                dtoProcesado.ubicacion_id !== undefined ||
                dtoProcesado.fecha_conteo !== undefined ||
                dtoProcesado.trabajador_responsable_id !== undefined ||
                dtoProcesado.trabajador_supervisor_id !== undefined
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen_id', valor: nuevoAlmacenId },
                            { nombre: 'ubicacion_id', valor: nuevoUbicacionId },
                            { nombre: 'fecha_conteo', valor: nuevaFechaConteo },
                            { nombre: 'trabajador_responsable_id', valor: nuevoTrabajadorResponsableId },
                            { nombre: 'trabajador_supervisor_id', valor: nuevoTrabajadorSupervisorId }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(inventarioActual, dtoProcesado);
            inventarioActual.update(usuarioId);

            try {
                await manager.save(inventarioActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el inventario físico', 'actualizar');
            }
        });
    }
}
