// C:\sirena\sirena-backend\src\modules\tipos-cambios\tipos-cambios.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DomainException } from '../../common/exceptions/domain.exception';
import { DataSource } from 'typeorm';
import { TipoCambio } from './entities/tipo-cambio.entity';
import { CreateTipoCambioDto } from './dto/create-tipo-cambio.dto';
import { UpdateTipoCambioDto } from './dto/update-tipo-cambio.dto';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoMoneda, TIPO_MONEDA_METADATA } from '../../common/constants/estados.constant';
import { TipoCambioResponseDto } from './dto/tipo-cambio-response.dto';
import { FindTiposCambiosQueryDto } from './dto/find-tipos-cambios-query.dto';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class TiposCambiosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'tipos_cambios',
        nombreEntidad: 'Tipo de Cambio',
        campoPK: 'tipo_cambio_id',
        alias: 't',
        responseDto: TipoCambioResponseDto,
        camposBusquedaEnQ: FindTiposCambiosQueryDto.getCamposParaQ(),
        tablasDependientes: FindTiposCambiosQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [
            {
                nombreCampo: 'origen_moneda_id',
                nombreColumna: 'origen_moneda_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'destino_moneda_id',
                nombreColumna: 'destino_moneda_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'fecha_cotizacion_desde',
                nombreColumna: 'fecha_cotizacion',
                tipoDatoFiltro: 'date',
                operador: 'gte',
            },
            {
                nombreCampo: 'fecha_cotizacion_hasta',
                nombreColumna: 'fecha_cotizacion',
                tipoDatoFiltro: 'date',
                operador: 'lte',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'tipo_cambio_id',
            camposPermitidosParaOrdenar: FindTiposCambiosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindTiposCambiosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindTiposCambiosQueryDto.getCamposProtegidosConDependencias(),
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

    private validarReglasNegocio(dto: any): void {
        if ('origen_moneda_id' in dto && 'destino_moneda_id' in dto) {
            if (dto.origen_moneda_id === undefined || dto.destino_moneda_id === undefined) {
                throw new DomainException(
                    'Ambos campos origen_moneda_id y destino_moneda_id son obligatorios.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            if (dto.origen_moneda_id === dto.destino_moneda_id) {
                throw new DomainException(
                    'La moneda de origen y destino no pueden ser iguales.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }
        }

        if (dto.factor_compra !== undefined && dto.factor_venta !== undefined) {
            if (dto.factor_compra > dto.factor_venta) {
                throw new DomainException(
                    'El factor de compra debe ser menor o igual al factor de venta.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }
        }

        if (dto.factor_compra !== undefined && dto.factor_compra <= 0) {
            throw new DomainException(
                'El factor de compra debe ser mayor a 0.',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (dto.factor_venta !== undefined && dto.factor_venta <= 0) {
            throw new DomainException(
                'El factor de venta debe ser mayor a 0.',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateTipoCambioDto, usuarioId: number): Promise<TipoCambioResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            this.validarReglasNegocio(dto);

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'origen_moneda_id', valor: dto.origen_moneda_id },
                        { nombre: 'destino_moneda_id', valor: dto.destino_moneda_id },
                        { nombre: 'fecha_cotizacion', valor: dto.fecha_cotizacion }
                    ],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const tipoCambio = manager.create(TipoCambio, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(tipoCambio);
                return this.findOne<TipoCambioResponseDto>(saved.tipo_cambio_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el tipo de cambio', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateTipoCambioDto, usuarioId: number): Promise<TipoCambioResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            this.validarReglasNegocio(dto);
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const tipoCambioActual = await manager.findOne(TipoCambio, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!tipoCambioActual) {
                throw new DomainException(
                    `Tipo de cambio con ID #${id} no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindTiposCambiosQueryDto.getDependencias(),
                FindTiposCambiosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            if (dtoProcesado.origen_moneda_id !== undefined ||
                dtoProcesado.destino_moneda_id !== undefined ||
                dtoProcesado.fecha_cotizacion !== undefined) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        {
                            nombre: 'origen_moneda_id',
                            valor: dtoProcesado.origen_moneda_id ?? tipoCambioActual.origen_moneda_id
                        },
                        {
                            nombre: 'destino_moneda_id',
                            valor: dtoProcesado.destino_moneda_id ?? tipoCambioActual.destino_moneda_id
                        },
                        {
                            nombre: 'fecha_cotizacion',
                            valor: dtoProcesado.fecha_cotizacion ?? tipoCambioActual.fecha_cotizacion
                        }
                    ],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                });
            }

            Object.assign(tipoCambioActual, dtoProcesado);
            tipoCambioActual.update(usuarioId);

            try {
                await manager.save(tipoCambioActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el tipo de cambio', 'actualizar');
            }
        });
    }

    async convertirBolivianosADolares(
        montoBolivianos: number,
        fechaCotizacion: string,
        usuarioId: number,
    ): Promise<{
        montoBolivianos: number;
        montoDolares: number;
        factorUsado: number;
        tipoCambioId: number;
        origen: { id: number; abreviatura: string; prefijo: string };
        destino: { id: number; abreviatura: string; prefijo: string };
    }> {
        const origenMonedaId = TipoMoneda.BOLIVIANO;
        const destinoMonedaId = TipoMoneda.DOLAR;

        if (montoBolivianos <= 0) {
            throw new DomainException(
                'El monto en bolivianos debe ser mayor a 0.',
                { monto_bolivianos: montoBolivianos, httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (!/^\d{4}-\d{2}-\d{2}$/.test(fechaCotizacion)) {
            throw new DomainException(
                'La fecha de cotización debe tener formato YYYY-MM-DD.',
                {
                    fecha_cotizacion: fechaCotizacion,
                    httpStatus: HttpStatus.BAD_REQUEST
                }
            );
        }

        await this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'leer');

        const query = `
            SELECT tipo_cambio_id, factor_compra, factor_venta
            FROM ${this.nombreTabla}
            WHERE origen_moneda_id = $1
            AND destino_moneda_id = $2
            AND fecha_cotizacion = $3
            AND estado_id IN (${ESTADOS_VIVOS.join(', ')})
            LIMIT 1
        `;
        const params = [origenMonedaId, destinoMonedaId, fechaCotizacion];
        logSqlQuery(query, params, `convertir - ${this.nombreTabla}`);

        const result = await this.dataSource.query(query, params);
        if (!result || result.length === 0) {
            throw new DomainException(
                `No se encontró un tipo de cambio activo para la fecha ${fechaCotizacion}.`,
                { fecha_cotizacion: fechaCotizacion, httpStatus: HttpStatus.NOT_FOUND }
            );
        }

        const tipoCambio = result[0];
        const factorVenta = Number(tipoCambio.factor_venta);
        const montoDolares = Number((montoBolivianos / factorVenta).toFixed(2));

        const origenMeta = TIPO_MONEDA_METADATA[TipoMoneda.BOLIVIANO];
        const destinoMeta = TIPO_MONEDA_METADATA[TipoMoneda.DOLAR];

        return {
            montoBolivianos,
            montoDolares,
            factorUsado: factorVenta,
            tipoCambioId: Number(tipoCambio.tipo_cambio_id),
            origen: {
                id: origenMonedaId,
                abreviatura: origenMeta.abreviatura,
                prefijo: origenMeta.prefijo ?? ''
            },
            destino: {
                id: destinoMonedaId,
                abreviatura: destinoMeta.abreviatura,
                prefijo: destinoMeta.prefijo ?? ''
            }
        };
    }
}
