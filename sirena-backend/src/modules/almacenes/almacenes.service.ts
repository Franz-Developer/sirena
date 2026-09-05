// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA, TIPO_ALMACEN_PROHIBIDOS, TIPO_ALMACEN_VALIDOS, TIPO_ALMACEN_METADATA, TipoAlmacen } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
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
                ...TIPO_ALMACEN_PROHIBIDOS
            ],
            [TipoOperacionAlmacen.VENTA_DIRECTA]: [
                ...TIPO_ALMACEN_VALIDOS
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
                })
            ]);

            this.validarCombinacionTipoAlmacen(
                dto.tipo_operacion_almacen_id,
                dto.tipo_almacen_id
            );

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    almacen,
                    codigo,
                    tipo_almacen_id,
                    tipo_operacion_almacen_id,
                    descripcion,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.almacen,
                dto.codigo,
                dto.tipo_almacen_id,
                dto.tipo_operacion_almacen_id,
                dto.descripcion || null,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];

            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] ?? 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al insertar el almacén.',
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne(newId, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateAlmacenDto, usuarioId: number): Promise<AlmacenResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const almacenActual = await manager.findOne(Almacen, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!almacenActual) {
                throw new DomainException(
                    `Almacén no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindAlmacenesQueryDto.getDependencias(),
                FindAlmacenesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id)
                );
            }

            if (
                (dto.almacen !== undefined && dto.almacen !== almacenActual.almacen) ||
                (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'almacen', valor: dto.almacen ?? almacenActual.almacen },
                            { nombre: 'sucursal_id', valor: dto.sucursal_id ?? almacenActual.sucursal_id }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (
                (dto.codigo !== undefined && dto.codigo !== almacenActual.codigo) ||
                (dto.sucursal_id !== undefined && dto.sucursal_id !== almacenActual.sucursal_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'codigo', valor: dto.codigo ?? almacenActual.codigo },
                            { nombre: 'sucursal_id', valor: dto.sucursal_id ?? almacenActual.sucursal_id }
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

            const operacionId = dto.tipo_operacion_almacen_id ?? almacenActual.tipo_operacion_almacen_id;
            const tipoId = dto.tipo_almacen_id ?? almacenActual.tipo_almacen_id;

            if (dto.tipo_operacion_almacen_id !== undefined || dto.tipo_almacen_id !== undefined) {
                this.validarCombinacionTipoAlmacen(operacionId, tipoId);
            }

            Object.assign(almacenActual, dto);
            almacenActual.update(usuarioId);

            try {
                await manager.save(almacenActual);
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
