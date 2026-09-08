// C:\sirena\sirena-backend\src\modules\roles-menus\roles-menus.service.ts
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
import { CreateRolMenuDto } from './dto/create-rol-menu.dto';
import { RolMenuResponseDto } from './dto/rol-menu-response.dto';
import { FindRolesMenusQueryDto } from './dto/find-roles-menus-query.dto';
import { UpdateRolMenuDto } from './dto/update-rol-menu.dto';
import { RolMenu } from './entities/rol-menu.entity';

@Injectable()
export class RolesMenusService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'roles_menus',
        nombreEntidad: 'Asignación de Rol a Menú',
        campoPK: 'rol_menu_id',
        alias: 't',
        responseDto: RolMenuResponseDto,
        camposBusquedaEnQ: FindRolesMenusQueryDto.getCamposParaQ(),
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
            },
            {
                table: 'menus',
                alias: 'm',
                onCondition: 'm.menu_id = t.menu_id',
                selectColumns: [
                    'm.titulo AS menu_titulo',
                    'm.url AS menu_url'
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
                nombreCampo: 'menu_id',
                nombreColumna: 'menu_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            }
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'rol_menu_id',
            camposPermitidosParaOrdenar: FindRolesMenusQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindRolesMenusQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindRolesMenusQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateRolMenuDto, usuarioId: number): Promise<RolMenuResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dto.rol_id),
                this.tablaValidador.validarRegistrosActivos('menus', 'menu_id', dto.menu_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'rol_id', valor: dto.rol_id },
                        { nombre: 'menu_id', valor: dto.menu_id }
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                })
            ];

            await Promise.all(validaciones);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    rol_id,
                    menu_id,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.rol_id,
                dto.menu_id,
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
                        'Error al insertar el registro de asignación de rol a menú.',
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

    async update(id: number, dto: UpdateRolMenuDto, usuarioId: number): Promise<RolMenuResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const registroActual = await manager.findOne(RolMenu, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!registroActual) {
                throw new DomainException(
                    `Registro de asignación de rol a menú no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindRolesMenusQueryDto.getDependencias(),
                FindRolesMenusQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const nuevoRolId = dto.rol_id ?? registroActual.rol_id;
            const nuevoMenuId = dto.menu_id ?? registroActual.menu_id;

            const validaciones: Promise<any>[] = [];

            if (dto.rol_id !== undefined && dto.rol_id !== registroActual.rol_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dto.rol_id)
                );
            }

            if (dto.menu_id !== undefined && dto.menu_id !== registroActual.menu_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('menus', 'menu_id', dto.menu_id)
                );
            }

            if (dto.rol_id !== undefined || dto.menu_id !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'rol_id', valor: nuevoRolId },
                            { nombre: 'menu_id', valor: nuevoMenuId }
                        ],
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            await Promise.all(validaciones);

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
