// C:\sirena\sirena-backend\src\modules\puntos-venta\puntos-venta.service.ts
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
import { CreatePuntoVentaDto } from './dto/create-punto-venta.dto';
import { PuntoVentaResponseDto } from './dto/punto-venta-response.dto';
import { FindPuntosVentaQueryDto } from './dto/find-puntos-venta-query.dto';
import { UpdatePuntoVentaDto } from './dto/update-punto-venta.dto';
import { PuntoVenta } from './entities/punto-venta.entity';

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
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear')
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

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    sucursal_id,
                    codigo,
                    nombre,
                    tipo_punto_venta_id,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.sucursal_id,
                dto.codigo,
                dto.nombre,
                dto.tipo_punto_venta_id,
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
                        'Error al insertar el punto de venta.',
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

    async update(id: number, dto: UpdatePuntoVentaDto, usuarioId: number): Promise<PuntoVentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const puntoVentaActual = await manager.findOne(PuntoVenta, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!puntoVentaActual) {
                throw new DomainException(
                    `Punto de venta no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindPuntosVentaQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindPuntosVentaQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dtoNormalizado) {
                        delete (dtoNormalizado as any)[campo];
                    }
                });
            }

            if (dtoNormalizado.sucursal_id !== undefined && dtoNormalizado.sucursal_id !== puntoVentaActual.sucursal_id) {
                await this.tablaValidador.validarRegistrosActivos('sucursales', 'sucursal_id', dtoNormalizado.sucursal_id);
            }

            const nuevoSucursalId = dtoNormalizado.sucursal_id ?? puntoVentaActual.sucursal_id;
            const nuevoCodigo = dtoNormalizado.codigo ?? puntoVentaActual.codigo;
            const nuevoNombre = dtoNormalizado.nombre ?? puntoVentaActual.nombre;

            // VALIDACIÓN DE UNICIDAD EN UPDATE
            const validacionesUnicidad: Promise<any>[] = [];

            if (dtoNormalizado.sucursal_id !== undefined || dtoNormalizado.codigo !== undefined) {
                validacionesUnicidad.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevoSucursalId },
                            { nombre: 'codigo', valor: nuevoCodigo }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (dtoNormalizado.sucursal_id !== undefined || dtoNormalizado.nombre !== undefined) {
                validacionesUnicidad.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'sucursal_id', valor: nuevoSucursalId },
                            { nombre: 'nombre', valor: nuevoNombre }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validacionesUnicidad.length > 0) {
                await Promise.all(validacionesUnicidad);
            }

            Object.assign(puntoVentaActual, dtoNormalizado);
            puntoVentaActual.update(usuarioId);

            try {
                await manager.save(puntoVentaActual);
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
