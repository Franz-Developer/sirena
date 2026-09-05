// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\almacenes-puntos-venta.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS, TIPO_ALMACEN_METADATA, TIPO_ALMACEN_PROHIBIDOS, TipoPuntoVenta } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateAlmacenPuntoVentaDto } from './dto/create-almacen-punto-venta.dto';
import { AlmacenPuntoVentaResponseDto } from './dto/almacen-punto-venta-response.dto';
import { FindAlmacenesPuntosVentaQueryDto } from './dto/find-almacenes-puntos-venta-query.dto';
import { UpdateAlmacenPuntoVentaDto } from './dto/update-almacen-punto-venta.dto';
import { AlmacenPuntoVenta } from './entities/almacen-punto-venta.entity';

@Injectable()
export class AlmacenesPuntosVentaService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'almacenes_puntos_venta',
        nombreEntidad: 'Asignación de Almacén',
        campoPK: 'almacen_punto_venta_id',
        alias: 't',
        responseDto: AlmacenPuntoVentaResponseDto,
        camposBusquedaEnQ: FindAlmacenesPuntosVentaQueryDto.getCamposParaQ(),
        tablasDependientes: [],
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
            },
            {
                table: 'almacenes',
                alias: 'a',
                onCondition: 'a.almacen_id = t.almacen_id',
                selectColumns: [
                    'a.almacen AS almacen_nombre',
                    'a.codigo AS almacen_codigo',
                    'a.tipo_almacen_id AS almacen_tipo_almacen_id'
                ],
                type: 'INNER'
            },
            {
                table: 'puntos_venta',
                alias: 'pv',
                onCondition: 'pv.punto_venta_id = t.punto_venta_id',
                selectColumns: [
                    'pv.nombre AS punto_venta_nombre',
                    'pv.codigo AS punto_venta_codigo'
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
                nombreCampo: 'almacen_id',
                nombreColumna: 'almacen_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'punto_venta_id',
                nombreColumna: 'punto_venta_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'es_principal',
                nombreColumna: 'es_principal',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            }
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'almacen_punto_venta_id',
            camposPermitidosParaOrdenar: FindAlmacenesPuntosVentaQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindAlmacenesPuntosVentaQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindAlmacenesPuntosVentaQueryDto.getCamposProtegidosConDependencias(),
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

    private async validarReglasNegocioAlmacenPuntoVenta(
        manager: any,
        sucursalId: number,
        almacenId: number,
        puntoVentaId: number,
    ): Promise<void> {
        const queryAlmacen = `
            SELECT tipo_almacen_id FROM almacenes
            WHERE almacen_id = $1
              AND sucursal_id = $2
              AND estado_id = $3
            LIMIT 1
        `;
        const resAlmacen = await manager.query(queryAlmacen, [almacenId, sucursalId, ESTADO_ACTIVO]);

        if (!resAlmacen || resAlmacen.length === 0) {
            throw new DomainException(
                `El almacén con ID ${almacenId} no pertenece a la sucursal con ID ${sucursalId} o no se encuentra activo.`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        const tipoAlmacenId = Number(resAlmacen[0].tipo_almacen_id);

        if ((TIPO_ALMACEN_PROHIBIDOS as readonly number[]).includes(tipoAlmacenId)) {
            const nombresProhibidos = TIPO_ALMACEN_PROHIBIDOS
                .map(tipo => TIPO_ALMACEN_METADATA[tipo]?.abreviatura)
                .filter(Boolean)
                .join(', ');

            throw new DomainException(
                `No se puede vincular un almacén de tipo no comercial (${nombresProhibidos}) a un punto de venta.`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        const queryPuntoVenta = `
            SELECT 1 FROM puntos_venta
            WHERE punto_venta_id = $1
                AND sucursal_id = $2
                AND estado_id = $3
                AND tipo_punto_venta_id = $4
            LIMIT 1
        `;
        const resPuntoVenta = await manager.query(queryPuntoVenta, [puntoVentaId, sucursalId, ESTADO_ACTIVO, TipoPuntoVenta.CAJA]);

        if (!resPuntoVenta || resPuntoVenta.length === 0) {
            throw new DomainException(
                `El punto de venta con ID ${puntoVentaId} no pertenece a la sucursal con ID ${sucursalId} o no se encuentra activo o no es del tipo de punto caja. `,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateAlmacenPuntoVentaDto, usuarioId: number): Promise<AlmacenPuntoVentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const esPrincipalVal = dto.es_principal ?? 0;

            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dto.almacen_id),
                this.tablaValidador.validarRegistrosActivos('puntos_venta', 'punto_venta_id', dto.punto_venta_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.validarReglasNegocioAlmacenPuntoVenta(manager, dto.sucursal_id, dto.almacen_id, dto.punto_venta_id),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'almacen_id', valor: dto.almacen_id },
                        { nombre: 'punto_venta_id', valor: dto.punto_venta_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
            ];

            await Promise.all(validaciones);

            if (esPrincipalVal === 1) {
                await manager.query(
                    `UPDATE ${this.nombreTabla} SET es_principal = 0 WHERE punto_venta_id = $1 AND es_principal = 1 AND estado_id = ANY($2)`,
                    [dto.punto_venta_id, ESTADOS_VIVOS]
                );
            }

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    almacen_id,
                    punto_venta_id,
                    prioridad,
                    es_principal,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.almacen_id,
                dto.punto_venta_id,
                dto.prioridad,
                esPrincipalVal,
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
                            'Error al insertar el registro de relación almacén punto de venta.',
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

    async update(id: number, dto: UpdateAlmacenPuntoVentaDto, usuarioId: number): Promise<AlmacenPuntoVentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const registroActual = await manager.findOne(AlmacenPuntoVenta, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!registroActual) {
                throw new DomainException(
                    `Registro de relación almacén punto de venta no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindAlmacenesPuntosVentaQueryDto.getDependencias(),
                FindAlmacenesPuntosVentaQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const nuevoSucursalId = dto.sucursal_id ?? registroActual.sucursal_id;
            const nuevoAlmacenId = dto.almacen_id ?? registroActual.almacen_id;
            const nuevoPuntoVentaId = dto.punto_venta_id ?? registroActual.punto_venta_id;
            const nuevoEsPrincipal = dto.es_principal !== undefined ? dto.es_principal : registroActual.es_principal;

            const validaciones: Promise<any>[] = [
                this.validarReglasNegocioAlmacenPuntoVenta(manager, nuevoSucursalId, nuevoAlmacenId, nuevoPuntoVentaId)
            ];

            if (dto.sucursal_id !== undefined && dto.sucursal_id !== registroActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id)
                );
            }

            if (dto.almacen_id !== undefined && dto.almacen_id !== registroActual.almacen_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('almacenes', 'almacen_id', dto.almacen_id)
                );
            }

            if (dto.punto_venta_id !== undefined && dto.punto_venta_id !== registroActual.punto_venta_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('puntos_venta', 'punto_venta_id', dto.punto_venta_id)
                );
            }

            if (dto.sucursal_id !== undefined || dto.almacen_id !== undefined || dto.punto_venta_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevoSucursalId },
                            { nombre: 'almacen_id', valor: nuevoAlmacenId },
                            { nombre: 'punto_venta_id', valor: nuevoPuntoVentaId }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            await Promise.all(validaciones);

            if (nuevoEsPrincipal === 1) {
                await manager.query(
                    `UPDATE ${this.nombreTabla} SET es_principal = 0 WHERE punto_venta_id = $1 AND es_principal = 1 AND ${this.campoPK} != $2 AND estado_id = ANY($3)`,
                    [nuevoPuntoVentaId, id, ESTADOS_VIVOS]
                );
            }

            Object.assign(registroActual, dto);
            registroActual.update(usuarioId);

            try {
                await manager.save(registroActual);
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
