// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA, TIPOS_ALMACEN_VENTA_DIRECTA, TIPOS_ALMACEN_LOGISTICA_INTERNA, TIPO_ALMACEN_METADATA, TipoAlmacen } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateAlmacenDto } from './dto/create-almacen.dto';
import { AlmacenResponseDto } from './dto/almacen-response.dto';
import { FindAlmacenesQueryDto } from './dto/find-almacenes-query.dto';
import { UpdateAlmacenDto } from './dto/update-almacen.dto';
import { Almacen } from './entities/almacen.entity';

@Injectable()
export class AlmacenesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'almacenes',
        nombreEntidad: 'Almacen',
        campoPK: 'almacen_id',
        alias: 't',
        responseDto: AlmacenResponseDto,
        camposBusquedaEnQ: FindAlmacenesQueryDto.getCamposParaQ(),
        tablasDependientes: FindAlmacenesQueryDto.getDependencias(),
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
                nombreCampo: 'tipo_almacen_id',
                nombreColumna: 'tipo_almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_operacion_almacen_id',
                nombreColumna: 'tipo_operacion_almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'almacen_id',
            camposPermitidosParaOrdenar: FindAlmacenesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindAlmacenesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
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

    private validarCombinacionTipoAlmacen(
        tipoOperacionId: number,
        tipoAlmacenId: number
    ): void {
        const combinacionesValidas: Record<number, number[]> = {
            [TipoOperacionAlmacen.LOGISTICA_INTERNA]: [
                ...TIPOS_ALMACEN_LOGISTICA_INTERNA
            ],
            [TipoOperacionAlmacen.VENTA_DIRECTA]: [
                ...TIPOS_ALMACEN_VENTA_DIRECTA
            ],
        };

        const tiposPermitidos = combinacionesValidas[tipoOperacionId];
        if (!tiposPermitidos) {
            const operacionesValidas = Object.keys(combinacionesValidas)
                .map(id => {
                    const meta = TIPO_OPERACION_ALMACEN_METADATA[Number(id) as TipoOperacionAlmacen];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');
            throw new DomainException(
                `tipo_operacion_almacen_id "${tipoOperacionId}" no es válido. ` +
                `Valores permitidos: ${operacionesValidas}`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (!tiposPermitidos.includes(tipoAlmacenId)) {
            const operacionMeta = TIPO_OPERACION_ALMACEN_METADATA[tipoOperacionId as TipoOperacionAlmacen];
            const operacionNombre = operacionMeta?.abreviatura ?? 'DESCONOCIDO';

            const tiposPermitidosStr = tiposPermitidos
                .map(id => {
                    const meta = TIPO_ALMACEN_METADATA[id as TipoAlmacen];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');

            throw new DomainException(
                `Combinación inválida: tipo_operacion_almacen_id "${tipoOperacionId}" (${operacionNombre}) ` +
                `no permite tipo_almacen_id "${tipoAlmacenId}". ` +
                `Tipos permitidos: ${tiposPermitidosStr}`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'almacen', valor: dto.almacen },
                        { nombre: 'sucursal_id', valor: dto.sucursal_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'codigo', valor: dto.codigo },
                        { nombre: 'sucursal_id', valor: dto.sucursal_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            this.validarCombinacionTipoAlmacen(dto.tipo_operacion_almacen_id, dto.tipo_almacen_id);

            const almacen = manager.create(Almacen, {
                ...dto,
                estado_id: ESTADO_ACTIVO,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(almacen);
                return this.findOne<AlmacenResponseDto>(saved.almacen_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));

                throw new DomainException(
                    `Ocurrió un error inesperado al crear el almacén.`,
                    {
                        details: errorMessage,
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }
        });
    }

    async update(id: number, dto: UpdateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const almacenActual = await manager.findOne(Almacen, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!almacenActual) {
                throw new DomainException(
                    `Almacén no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindAlmacenesQueryDto.getDependencias(),
                FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.sucursal_id !== undefined && dtoProcesado.sucursal_id !== almacenActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dtoProcesado.sucursal_id)
                );
            }

            if (
                (dtoProcesado.almacen !== undefined && dtoProcesado.almacen !== almacenActual.almacen) ||
                (dtoProcesado.sucursal_id !== undefined && dtoProcesado.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen', valor: dtoProcesado.almacen ?? almacenActual.almacen },
                            { nombre: 'sucursal_id', valor: dtoProcesado.sucursal_id ?? almacenActual.sucursal_id }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (
                (dtoProcesado.codigo !== undefined && dtoProcesado.codigo !== almacenActual.codigo) ||
                (dtoProcesado.sucursal_id !== undefined && dtoProcesado.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'codigo', valor: dtoProcesado.codigo ?? almacenActual.codigo },
                            { nombre: 'sucursal_id', valor: dtoProcesado.sucursal_id ?? almacenActual.sucursal_id }
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

            const operacionId = dtoProcesado.tipo_operacion_almacen_id ?? almacenActual.tipo_operacion_almacen_id;
            const tipoId = dtoProcesado.tipo_almacen_id ?? almacenActual.tipo_almacen_id;

            if (dtoProcesado.tipo_operacion_almacen_id !== undefined || dtoProcesado.tipo_almacen_id !== undefined) {
                this.validarCombinacionTipoAlmacen(operacionId, tipoId);
            }

            Object.assign(almacenActual, dtoProcesado);
            almacenActual.update(usuarioId);

            try {
                await manager.save(almacenActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                throw new DomainException(
                    `Ocurrió un error inesperado al actualizar: ${getErrorMessage(error)}`,
                    {
                        details: getErrorMessage(error),
                        stack: getErrorStack(error),
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }
        });
    }
}
