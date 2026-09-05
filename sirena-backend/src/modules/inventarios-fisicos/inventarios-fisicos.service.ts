// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\inventarios-fisicos.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateInventarioFisicoDto } from './dto/create-inventario-fisico.dto';
import { InventarioFisicoResponseDto } from './dto/inventario-fisico-response.dto';
import { FindInventariosFisicosQueryDto } from './dto/find-inventarios-fisicos-query.dto';
import { UpdateInventarioFisicoDto } from './dto/update-inventario-fisico.dto';
import { InventarioFisico } from './entities/inventario-fisico.entity';

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
                table: 'trabajadores',
                alias: 'ts',
                onCondition: 'ts.trabajador_id = t.trabajador_supervisor_id',
                selectColumns: [
                    `TRIM(CONCAT_WS(' ', ts.nombres, ts.paterno, ts.materno)) AS trabajador_supervisor_nombre`
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'sucursal_id',
                nombreColumna: 'sucursal_id',
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

    private async validarPertenenciaUbicacionSucursal(
        manager: any,
        sucursalId: number,
        ubicacionId: number
    ): Promise<void> {
        const query = `
            SELECT 1 FROM ubicaciones
            WHERE ubicacion_id = $1
              AND sucursal_id = $2
              AND estado_id = $3
            LIMIT 1
        `;
        const params = [ubicacionId, sucursalId, ESTADO_ACTIVO];
        const resultado = await manager.query(query, params);

        if (!resultado || resultado.length === 0) {
            throw new DomainException(
                `La ubicación con ID ${ubicacionId} no pertenece a la sucursal con ID ${sucursalId} o no se encuentra activa.`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateInventarioFisicoDto, usuarioId: number): Promise<InventarioFisicoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarRegistrosActivos('ubicaciones', 'ubicacion_id', dto.ubicacion_id),
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_responsable_id),
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_supervisor_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.validarPertenenciaUbicacionSucursal(manager, dto.sucursal_id, dto.ubicacion_id),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'ubicacion_id', valor: dto.ubicacion_id },
                        { nombre: 'fecha_conteo', valor: dto.fecha_conteo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
            ];

            await Promise.all(validaciones);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    ubicacion_id,
                    fecha_conteo,
                    fecha_inicio,
                    fecha_fin,
                    trabajador_responsable_id,
                    trabajador_supervisor_id,
                    observaciones,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.ubicacion_id,
                dto.fecha_conteo,
                dto.fecha_inicio,
                dto.fecha_fin || null,
                dto.trabajador_responsable_id,
                dto.trabajador_supervisor_id,
                dto.observaciones?.trim() || null,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];

            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] || 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al insertar el registro de inventario físico.',
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne(newId, usuarioId, manager);
            } catch (error) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateInventarioFisicoDto, usuarioId: number): Promise<InventarioFisicoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            if (dtoNormalizado.observaciones !== undefined && dtoNormalizado.observaciones !== null) {
                dtoNormalizado.observaciones = dtoNormalizado.observaciones.trim();
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const inventarioActual = await manager.findOne(InventarioFisico, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!inventarioActual) {
                throw new DomainException(
                    `Registro de inventario físico no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dtoNormalizado,
                FindInventariosFisicosQueryDto.getDependencias(),
                FindInventariosFisicosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const nuevoSucursalId = dtoNormalizado.sucursal_id ?? inventarioActual.sucursal_id;
            const nuevoUbicacionId = dtoNormalizado.ubicacion_id ?? inventarioActual.ubicacion_id;
            const nuevaFechaConteo = dtoNormalizado.fecha_conteo !== undefined ? dtoNormalizado.fecha_conteo : inventarioActual.fecha_conteo;

            const validaciones: Promise<any>[] = [
                this.validarPertenenciaUbicacionSucursal(manager, nuevoSucursalId, nuevoUbicacionId)
            ];

            if (dtoNormalizado.sucursal_id !== undefined && dtoNormalizado.sucursal_id !== inventarioActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dtoNormalizado.sucursal_id)
                );
            }

            if (dtoNormalizado.ubicacion_id !== undefined && dtoNormalizado.ubicacion_id !== inventarioActual.ubicacion_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('ubicaciones', 'ubicacion_id', dtoNormalizado.ubicacion_id)
                );
            }

            if (dtoNormalizado.trabajador_responsable_id !== undefined && dtoNormalizado.trabajador_responsable_id !== inventarioActual.trabajador_responsable_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dtoNormalizado.trabajador_responsable_id)
                );
            }

            if (dtoNormalizado.trabajador_supervisor_id !== undefined && dtoNormalizado.trabajador_supervisor_id !== inventarioActual.trabajador_supervisor_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dtoNormalizado.trabajador_supervisor_id)
                );
            }

            if (dtoNormalizado.sucursal_id !== undefined || dtoNormalizado.ubicacion_id !== undefined || dtoNormalizado.fecha_conteo !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevoSucursalId },
                            { nombre: 'ubicacion_id', valor: nuevoUbicacionId },
                            { nombre: 'fecha_conteo', valor: nuevaFechaConteo }
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

            Object.assign(inventarioActual, dtoNormalizado);
            inventarioActual.update(usuarioId);

            try {
                await manager.save(inventarioActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }
}
