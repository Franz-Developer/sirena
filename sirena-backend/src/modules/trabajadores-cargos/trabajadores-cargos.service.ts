// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\trabajadores-cargos.service.ts
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
import { CreateTrabajadorCargoDto } from './dto/create-trabajador-cargo.dto';
import { TrabajadorCargoResponseDto } from './dto/trabajador-cargo-response.dto';
import { FindTrabajadoresCargosQueryDto } from './dto/find-trabajadores-cargos-query.dto';
import { UpdateTrabajadorCargoDto } from './dto/update-trabajador-cargo.dto';
import { TrabajadorCargo } from './entities/trabajador-cargo.entity';

@Injectable()
export class TrabajadoresCargosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'trabajadores_cargos',
        nombreEntidad: 'TrabajadorCargo',
        campoPK: 'trabajador_cargo_id',
        alias: 't',
        responseDto: TrabajadorCargoResponseDto,
        camposBusquedaEnQ: FindTrabajadoresCargosQueryDto.getCamposParaQ(),
        tablasDependientes: FindTrabajadoresCargosQueryDto.getDependencias(),
        joins: [
            {
                table: 'trabajadores',
                alias: 'tr',
                onCondition: 'tr.trabajador_id = t.trabajador_id',
                selectColumns: [
                    'tr.nombres AS trabajador_nombres',
                    'tr.paterno AS trabajador_paterno',
                    'tr.materno AS trabajador_materno',
                    'tr.dni AS trabajador_dni'
                ],
                type: 'INNER'
            },
            {
                table: 'cargos',
                alias: 'c',
                onCondition: 'c.cargo_id = t.cargo_id',
                selectColumns: [
                    'c.cargo AS cargo_nombre',
                    'c.codigo AS cargo_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'trabajador_id',
                nombreColumna: 'trabajador_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'cargo_id',
                nombreColumna: 'cargo_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_moneda_id',
                nombreColumna: 'tipo_moneda_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'trabajador_cargo_id',
            camposPermitidosParaOrdenar: FindTrabajadoresCargosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindTrabajadoresCargosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindTrabajadoresCargosQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateTrabajadorCargoDto, usuarioId: number): Promise<TrabajadorCargoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_id),
                this.tablaValidador.validarRegistrosActivos('cargos', 'cargo_id', dto.cargo_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'trabajador_id', valor: dto.trabajador_id },
                        { nombre: 'cargo_id', valor: dto.cargo_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK
                })
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    trabajador_id,
                    cargo_id,
                    sueldo_base,
                    tipo_moneda_id,
                    fecha_desde,
                    fecha_hasta,
                    es_activo,
                    observaciones,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.trabajador_id,
                dto.cargo_id,
                dto.sueldo_base,
                dto.tipo_moneda_id,
                dto.fecha_desde,
                dto.fecha_hasta || null,
                dto.es_activo ?? 1,
                dto.observaciones || null,
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
                        'Error al insertar la asignación de trabajador y cargo.',
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

    async update(id: number, dto: UpdateTrabajadorCargoDto, usuarioId: number): Promise<TrabajadorCargoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const asignacionActual = await manager.findOne(TrabajadorCargo, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!asignacionActual) {
                throw new DomainException(
                    `Asignación de trabajador y cargo no encontrada.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const validaciones: Promise<any>[] = [];

            if (dto.trabajador_id !== undefined && dto.trabajador_id !== asignacionActual.trabajador_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_id)
                );
            }

            if (dto.cargo_id !== undefined && dto.cargo_id !== asignacionActual.cargo_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('cargos', 'cargo_id', dto.cargo_id)
                );
            }

            if (
                (dto.trabajador_id !== undefined && dto.trabajador_id !== asignacionActual.trabajador_id) ||
                (dto.cargo_id !== undefined && dto.cargo_id !== asignacionActual.cargo_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'trabajador_id', valor: dto.trabajador_id ?? asignacionActual.trabajador_id },
                            { nombre: 'cargo_id', valor: dto.cargo_id ?? asignacionActual.cargo_id }
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

            Object.assign(asignacionActual, dto);
            asignacionActual.update(usuarioId);

            try {
                await manager.save(asignacionActual);
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
