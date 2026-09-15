// C:\sirena\sirena-backend\src\modules\puntos-venta\puntos-venta.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreatePuntoVentaDto } from './dto/create-punto-venta.dto';
import { PuntoVentaResponseDto } from './dto/punto-venta-response.dto';
import { FindPuntosVentaQueryDto } from './dto/find-puntos-venta-query.dto';
import { UpdatePuntoVentaDto } from './dto/update-punto-venta.dto';
import { PuntoVenta } from './entities/punto-venta.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class PuntosVentaService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'puntos_venta',
        nombreEntidad: 'Punto de Venta',
        campoPK: 'punto_venta_id',
        alias: 't',
        responseDto: PuntoVentaResponseDto,
        camposBusquedaEnQ: FindPuntosVentaQueryDto.getCamposParaQ(),
        tablasDependientes: FindPuntosVentaQueryDto.getDependencias(),
        joins: [
            {
                table: 'sucursales',
                alias: 's',
                onCondition: 's.sucursal_id = t.sucursal_id',
                selectColumns: [
                    's.sucursal AS sucursal_nombre',
                    's.codigo AS sucursal_codigo'
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
                nombreCampo: 'tipo_punto_venta_id',
                nombreColumna: 'tipo_punto_venta_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'codigo',
                nombreColumna: 'codigo',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'punto_venta_id',
            camposPermitidosParaOrdenar: FindPuntosVentaQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindPuntosVentaQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindPuntosVentaQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreatePuntoVentaDto, usuarioId: number): Promise<PuntoVentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const nombreSucursal = await this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id, 't.sucursal');

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'codigo', valor: dto.codigo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe un punto de venta con el código '${dto.codigo}' para la sucursal '${nombreSucursal}'.`,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'nombre', valor: dto.nombre }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                    mensajePersonalizado: `Ya existe un punto de venta con el nombre '${dto.nombre}' para la sucursal '${nombreSucursal}'.`,
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId, undefined, 'El usuario del sistema no se encuentra activo o no existe.')
            ]);

            const puntoVenta = manager.create(PuntoVenta, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(puntoVenta);
                return this.findOne<PuntoVentaResponseDto>(saved.punto_venta_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el punto de venta', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdatePuntoVentaDto, usuarioId: number): Promise<PuntoVentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const puntoVentaActual = await manager.findOne(PuntoVenta, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!puntoVentaActual) {
                throw new DomainException(
                    'Punto de venta no encontrado.',
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindPuntosVentaQueryDto.getDependencias(),
                FindPuntosVentaQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const sucursalIdEval = dtoProcesado.sucursal_id ?? puntoVentaActual.sucursal_id;
            const nombreSucursal = await this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', sucursalIdEval, 't.sucursal');

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.codigo !== undefined || dtoProcesado.sucursal_id !== undefined) {
                const valorCodigo = dtoProcesado.codigo ?? puntoVentaActual.codigo;
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: sucursalIdEval },
                            { nombre: 'codigo', valor: valorCodigo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                        mensajePersonalizado: `Ya existe un punto de venta con el código '${valorCodigo}' para la sucursal '${nombreSucursal}'.`,
                    })
                );
            }

            if (dtoProcesado.nombre !== undefined || dtoProcesado.sucursal_id !== undefined) {
                const valorNombre = dtoProcesado.nombre ?? puntoVentaActual.nombre;
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: sucursalIdEval },
                            { nombre: 'nombre', valor: valorNombre }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                        mensajePersonalizado: `Ya existe un punto de venta con el nombre '${valorNombre}' para la sucursal '${nombreSucursal}'.`,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(puntoVentaActual, dtoProcesado);
            puntoVentaActual.update(usuarioId);

            try {
                await manager.save(puntoVentaActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el punto de venta', 'actualizar');
            }
        });
    }
}
