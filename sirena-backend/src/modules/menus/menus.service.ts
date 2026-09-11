// C:\sirena\sirena-backend\src\modules\menus\menus.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { MenuResponseDto } from './dto/menu-response.dto';
import { CreateMenuDto } from './dto/create-menu.dto';
import { FindMenusQueryDto } from './dto/find-menus-query.dto';
import { UpdateMenuDto } from './dto/update-menu.dto';
import { Menu } from './entities/menu.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class MenusService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'menus',
        nombreEntidad: 'Menu',
        campoPK: 'menu_id',
        alias: 't',
        responseDto: MenuResponseDto,
        camposBusquedaEnQ: FindMenusQueryDto.getCamposParaQ(),
        tablasDependientes: FindMenusQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [],
        configuracionOrden: {
            campoOrdenPorDefecto: 'menu_id',
            camposPermitidosParaOrdenar: FindMenusQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindMenusQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindMenusQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        private readonly unicidadValidador: UnicidadValidadorService,
        tablaValidador: TablaValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    async create(dto: CreateMenuDto, usuarioId: number): Promise<MenuResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            if (dto.menu_padre_id) {
                await this.tablaValidador.validarRegistrosActivos('menus', 'menu_id', dto.menu_padre_id);
            }

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'titulo', valor: dto.titulo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const menu = manager.create(Menu, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(menu);
                return this.findOne<MenuResponseDto>(saved.menu_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el menú', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateMenuDto, usuarioId: number): Promise<MenuResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const menuActual = await manager.findOne(Menu, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!menuActual) {
                throw new DomainException(
                    `Menú no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindMenusQueryDto.getDependencias(),
                FindMenusQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            if (dtoProcesado.menu_padre_id) {
                await this.tablaValidador.validarRegistrosActivos('menus', 'menu_id', dtoProcesado.menu_padre_id);
            }

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.titulo !== undefined && dtoProcesado.titulo !== menuActual.titulo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'titulo', valor: dtoProcesado.titulo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(menuActual, dtoProcesado);
            menuActual.update(usuarioId);

            try {
                await manager.save(menuActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el menú', 'actualizar');
            }
        });
    }
}
