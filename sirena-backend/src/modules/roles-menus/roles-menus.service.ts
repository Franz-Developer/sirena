// C:\sirena\sirena-backend\src\modules\roles-menus\roles-menus.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateRolMenuDto } from './dto/create-rol-menu.dto';
import { RolMenuResponseDto } from './dto/rol-menu-response.dto';
import { FindRolesMenusQueryDto } from './dto/find-roles-menus-query.dto';
import { UpdateRolMenuDto } from './dto/update-rol-menu.dto';
import { RolMenu } from './entities/rol-menu.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

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
            await Promise.all([
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
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const rolMenu = manager.create(RolMenu, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(rolMenu);
                return this.findOne<RolMenuResponseDto>(saved.rol_menu_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la asignación de rol a menú', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateRolMenuDto, usuarioId: number): Promise<RolMenuResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const registroActual = await manager.findOne(RolMenu, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!registroActual) {
                throw new DomainException(
                    `Asignación de rol a menú no encontrada.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindRolesMenusQueryDto.getDependencias(),
                FindRolesMenusQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const nuevoRolId = dtoProcesado.rol_id ?? registroActual.rol_id;
            const nuevoMenuId = dtoProcesado.menu_id ?? registroActual.menu_id;

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.rol_id !== undefined && dtoProcesado.rol_id !== registroActual.rol_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dtoProcesado.rol_id)
                );
            }

            if (dtoProcesado.menu_id !== undefined && dtoProcesado.menu_id !== registroActual.menu_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('menus', 'menu_id', dtoProcesado.menu_id)
                );
            }

            if (dtoProcesado.rol_id !== undefined || dtoProcesado.menu_id !== undefined) {
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

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(registroActual, dtoProcesado);
            registroActual.update(usuarioId);

            try {
                await manager.save(registroActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la asignación de rol a menú', 'actualizar');
            }
        });
    }
}
