// C:\sirena\sirena-backend\src\modules\roles-tablas\roles-tablas.service.ts
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
import { CreateRolTablaDto } from './dto/create-rol-tabla.dto';
import { RolTablaResponseDto } from './dto/rol-tabla-response.dto';
import { FindRolesTablasQueryDto } from './dto/find-roles-tablas-query.dto';
import { UpdateRolTablaDto } from './dto/update-rol-tabla.dto';
import { RolTabla } from './entities/rol-tabla.entity';

@Injectable()
export class RolesTablasService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'roles_tablas',
        nombreEntidad: 'Permiso de Rol por Tabla',
        campoPK: 'rol_tabla_id',
        alias: 't',
        responseDto: RolTablaResponseDto,
        camposBusquedaEnQ: FindRolesTablasQueryDto.getCamposParaQ(),
        tablasDependientes: [],
        joins: [
            {
                table: 'roles',
                alias: 'r',
                onCondition: 'r.rol_id = t.rol_id',
                selectColumns: [
                    'r.rol AS rol_nombre',
                    'r.codigo AS rol_codigo'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'rol_id',
                nombreColumna: 'rol_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tabla',
                nombreColumna: 'tabla',
                tipoDatoFiltro: 'string',
                operador: 'eq',
            },
            {
                nombreCampo: 'leer',
                nombreColumna: 'leer',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'crear',
                nombreColumna: 'crear',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'editar',
                nombreColumna: 'editar',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'eliminar',
                nombreColumna: 'eliminar',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'anular',
                nombreColumna: 'anular',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'archivar',
                nombreColumna: 'archivar',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'desarchivar',
                nombreColumna: 'desarchivar',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'rol_tabla_id',
            camposPermitidosParaOrdenar: FindRolesTablasQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindRolesTablasQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindRolesTablasQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateRolTablaDto, usuarioId: number): Promise<RolTablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dto.rol_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'rol_id', valor: dto.rol_id },
                        { nombre: 'tabla', valor: dto.tabla }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
            ];

            await Promise.all(validaciones);

            // Asegurar formato JSON válido o "{}" por defecto
            const eventosPermitidosObj = (dto.eventos_permitidos && typeof dto.eventos_permitidos === 'object')
                ? dto.eventos_permitidos
                : {};
            const eventosPermitidosJson = JSON.stringify(eventosPermitidosObj);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    rol_id,
                    tabla,
                    leer,
                    crear,
                    editar,
                    eliminar,
                    anular,
                    archivar,
                    desarchivar,
                    eventos_permitidos,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, $11, $12, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.rol_id,
                dto.tabla,
                dto.leer ?? 0,
                dto.crear ?? 0,
                dto.editar ?? 0,
                dto.eliminar ?? 0,
                dto.anular ?? 0,
                dto.archivar ?? 0,
                dto.desarchivar ?? 0,
                eventosPermitidosJson,
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
                        'Error al insertar el registro de permiso de rol por tabla.',
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

    async update(id: number, dto: UpdateRolTablaDto, usuarioId: number): Promise<RolTablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const registroActual = await manager.findOne(RolTabla, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!registroActual) {
                throw new DomainException(
                    `Registro de permiso de rol por tabla no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindRolesTablasQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindRolesTablasQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dto) {
                        delete (dto as any)[campo];
                    }
                });
            }

            const nuevoRolId = dto.rol_id ?? registroActual.rol_id;
            const nuevaTabla = dto.tabla ?? registroActual.tabla;

            const validaciones: Promise<any>[] = [];

            if (dto.rol_id !== undefined && dto.rol_id !== registroActual.rol_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dto.rol_id)
                );
            }

            if (dto.rol_id !== undefined || dto.tabla !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'rol_id', valor: nuevoRolId },
                            { nombre: 'tabla', valor: nuevaTabla }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            await Promise.all(validaciones);

            // Manejo correcto de eventos_permitidos para actualizaciones parciales
            if (dto.eventos_permitidos !== undefined) {
                if (dto.eventos_permitidos === null) {
                    dto.eventos_permitidos = {};
                } else if (typeof dto.eventos_permitidos === 'object') {
                    dto.eventos_permitidos = JSON.parse(JSON.stringify(dto.eventos_permitidos));
                }
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
