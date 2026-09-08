// C:\sirena\sirena-backend\src\modules\cufds\cufds.service.ts
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
import { CreateCufdDto } from './dto/create-cufd.dto';
import { CufdResponseDto } from './dto/cufd-response.dto';
import { FindCufdsQueryDto } from './dto/find-cufds-query.dto';
import { UpdateCufdDto } from './dto/update-cufd.dto';
import { Cufd } from './entities/cufd.entity';

@Injectable()
export class CufdsService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'cufd',
        nombreEntidad: 'CUFD',
        campoPK: 'cufd_id',
        alias: 't',
        responseDto: CufdResponseDto,
        camposBusquedaEnQ: FindCufdsQueryDto.getCamposParaQ(),
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
                nombreCampo: 'punto_venta_id',
                nombreColumna: 'punto_venta_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'estado_id',
                nombreColumna: 'estado_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            }
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'cufd_id',
            camposPermitidosParaOrdenar: FindCufdsQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindCufdsQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindCufdsQueryDto.getCamposProtegidosConDependencias(),
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

    private async validarPertenenciaSucursalPuntoVenta(
        manager: any,
        sucursalId: number,
        puntoVentaId: number | null | undefined
    ): Promise<void> {
        if (puntoVentaId === undefined || puntoVentaId === null) {
            return;
        }

        const query = `
            SELECT 1 FROM puntos_venta
            WHERE punto_venta_id = $1
              AND sucursal_id = $2
              AND estado_id = $3
            LIMIT 1
        `;
        const params = [puntoVentaId, sucursalId, ESTADO_ACTIVO];
        const resultado = await manager.query(query, params);

        if (!resultado || resultado.length === 0) {
            throw new DomainException(
                `El punto de venta con ID ${puntoVentaId} no pertenece a la sucursal con ID ${sucursalId} o no se encuentra activo.`,
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }
    }

    async create(dto: CreateCufdDto, usuarioId: number): Promise<CufdResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dto.sucursal_id),
                this.tablaValidador.validarRegistrosActivos('puntos_venta', 'punto_venta_id', dto.punto_venta_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.validarPertenenciaSucursalPuntoVenta(manager, dto.sucursal_id, dto.punto_venta_id),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'sucursal_id', valor: dto.sucursal_id },
                        { nombre: 'punto_venta_id', valor: dto.punto_venta_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'codigo_cufd', valor: dto.codigo_cufd }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
            ];

            await Promise.all(validaciones);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    punto_venta_id,
                    codigo_cufd,
                    codigo_control,
                    fecha_vigencia,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.punto_venta_id,
                dto.codigo_cufd,
                dto.codigo_control,
                dto.fecha_vigencia,
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
                        'Error al insertar el registro CUFD.',
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

    async update(id: number, dto: UpdateCufdDto, usuarioId: number): Promise<CufdResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            if (dtoNormalizado.codigo_cufd) {
                dtoNormalizado.codigo_cufd = dtoNormalizado.codigo_cufd.trim().toUpperCase();
            }

            if (dtoNormalizado.codigo_control) {
                dtoNormalizado.codigo_control = dtoNormalizado.codigo_control.trim().toUpperCase();
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const cufdActual = await manager.findOne(Cufd, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!cufdActual) {
                throw new DomainException(
                    `Registro CUFD no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dtoNormalizado,
                FindCufdsQueryDto.getDependencias(),
                FindCufdsQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const nuevoSucursalId = dtoNormalizado.sucursal_id ?? cufdActual.sucursal_id;
            const nuevoPuntoVentaId = dtoNormalizado.punto_venta_id !== undefined ? dtoNormalizado.punto_venta_id : cufdActual.punto_venta_id;

            const validaciones: Promise<any>[] = [
                this.validarPertenenciaSucursalPuntoVenta(manager, nuevoSucursalId, nuevoPuntoVentaId)
            ];

            if (dtoNormalizado.sucursal_id !== undefined && dtoNormalizado.sucursal_id !== cufdActual.sucursal_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dtoNormalizado.sucursal_id)
                );
            }

            if (dtoNormalizado.punto_venta_id !== undefined && dtoNormalizado.punto_venta_id !== cufdActual.punto_venta_id) {
                if (dtoNormalizado.punto_venta_id !== null) {
                    validaciones.push(
                        this.tablaValidador.validarRegistrosActivos('puntos_venta', 'punto_venta_id', dtoNormalizado.punto_venta_id)
                    );
                }
            }

            if (dtoNormalizado.sucursal_id !== undefined || dtoNormalizado.punto_venta_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevoSucursalId },
                            { nombre: 'punto_venta_id', valor: nuevoPuntoVentaId }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoNormalizado.codigo_cufd !== undefined && dtoNormalizado.codigo_cufd !== cufdActual.codigo_cufd) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'codigo_cufd', valor: dtoNormalizado.codigo_cufd }
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

            Object.assign(cufdActual, dtoNormalizado);
            cufdActual.update(usuarioId);

            try {
                await manager.save(cufdActual);
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
