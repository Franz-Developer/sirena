// C:\sirena\sirena-backend\src\modules\sucesos\sucesos.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateSucesoDto } from './dto/create-suceso.dto';
import { SucesoResponseDto } from './dto/suceso-response.dto';
import { FindSucesosQueryDto } from './dto/find-sucesos-query.dto';
import { UpdateSucesoDto } from './dto/update-suceso.dto';
import { Suceso } from './entities/suceso.entity';
import { logSqlQuery } from '../../common/utils/sql-logger.util';

@Injectable()
export class SucesosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'sucesos',
        nombreEntidad: 'Suceso',
        campoPK: 'suceso_id',
        alias: 't',
        responseDto: SucesoResponseDto,
        camposBusquedaEnQ: FindSucesosQueryDto.getCamposParaQ(),
        tablasDependientes: FindSucesosQueryDto.getDependencias(),
        joins: [
            {
                table: 'tablas',
                alias: 'tb',
                onCondition: 'tb.tabla_id = t.tabla_id',
                selectColumns: [
                    'tb.nombre AS tabla_nombre'
                ],
                type: 'INNER'
            },
            {
                table: 'roles_permisos_sucesos',
                alias: 'rps',
                onCondition: 'rps.suceso_id = t.suceso_id',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'roles_permisos_tablas',
                alias: 'rpt',
                onCondition: 'rpt.rol_permiso_tabla_id = rps.rol_permiso_tabla_id',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'roles',
                alias: 'r',
                onCondition: 'r.rol_id = rpt.rol_id',
                selectColumns: [
                    'r.rol_id AS rol_id',
                    'r.rol AS rol_nombre',
                    'r.codigo AS rol_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'tabla_id',
                nombreColumna: 't.tabla_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'rol_id',
                nombreColumna: 'r.rol_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'suceso_id',
            camposPermitidosParaOrdenar: FindSucesosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindSucesosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindSucesosQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource() dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string { return this.config.nombreTabla; }
    private get campoPK(): string { return this.config.campoPK; }

    async create(dto: CreateSucesoDto, usuarioId: number): Promise<SucesoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, 'sucesos', 'crear'),
                dto.tabla_id ? this.tablaValidador.validarRegistrosActivos('tablas', 'tabla_id', dto.tabla_id) : Promise.resolve()
            ]);

            await Promise.all([
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo', valor: dto.codigo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'suceso', valor: dto.suceso }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (tabla_id, codigo, suceso, descripcion, estado_id, usuario_id_registro, fecha_registro)
                VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;
            const params = [
                dto.tabla_id,
                dto.codigo,
                dto.suceso,
                dto.descripcion,
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
                        `Error al insertar el suceso "${dto.codigo}".`,
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne<SucesoResponseDto>(newId, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateSucesoDto, usuarioId: number): Promise<SucesoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const sucesoActual = await manager.findOne(Suceso, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!sucesoActual) {
                throw new DomainException('Suceso no encontrado.', { httpStatus: HttpStatus.NOT_FOUND });
            }

            const dtoParaActualizar = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindSucesosQueryDto.getDependencias(),
                FindSucesosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            if (dtoParaActualizar.codigo !== undefined) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo', valor: dtoParaActualizar.codigo }],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                });
            }

            if (dtoParaActualizar.suceso !== undefined) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'suceso', valor: dtoParaActualizar.suceso }],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                });
            }

            manager.merge(Suceso, sucesoActual, dtoParaActualizar);
            sucesoActual.update(usuarioId);

            try {
                await manager.save(sucesoActual);

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
