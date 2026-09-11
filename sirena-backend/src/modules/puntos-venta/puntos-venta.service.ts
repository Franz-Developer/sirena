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
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            // VALIDACIÓN DE UNICIDAD: Código y Nombre son únicos por sucursal para estados vivos (1000, 1002)
            await Promise.all([
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'codigo', valor: dto.codigo }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'nombre', valor: dto.nombre }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
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

            if (dtoProcesado.sucursal_id !== undefined && dtoProcesado.sucursal_id !== puntoVentaActual.sucursal_id) {
                await this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dtoProcesado.sucursal_id);
            }

            const validaciones: Promise<any>[] = [];
            const nuevaSucursalId = dtoProcesado.sucursal_id ?? puntoVentaActual.sucursal_id;

            if (dtoProcesado.sucursal_id !== undefined || dtoProcesado.codigo !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevaSucursalId },
                            { nombre: 'codigo', valor: dtoProcesado.codigo ?? puntoVentaActual.codigo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoProcesado.sucursal_id !== undefined || dtoProcesado.nombre !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevaSucursalId },
                            { nombre: 'nombre', valor: dtoProcesado.nombre ?? puntoVentaActual.nombre }
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
