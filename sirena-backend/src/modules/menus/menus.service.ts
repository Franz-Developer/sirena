// C:\sirena\sirena-backend\src\modules\menus\menus.service.ts
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
import { MenuResponseDto } from './dto/menu-response.dto';
import { CreateMenuDto } from './dto/create-menu.dto';
import { FindMenusQueryDto } from './dto/find-menus-query.dto';
import { UpdateMenuDto } from './dto/update-menu.dto';
import { Menu } from './entities/menu.entity';

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
            const dtoNormalizado = {
                ...dto,
                titulo: dto.titulo.trim().toUpperCase(),
                url: dto.url ? dto.url.trim() : null,
                icono: dto.icono ? dto.icono.trim() : null,
            };

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'titulo', valor: dtoNormalizado.titulo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (menu_padre_id, titulo, icono, url, orden, estado_id, usuario_id_registro, fecha_registro)
                VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;
            const params = [
                dtoNormalizado.menu_padre_id ?? null,
                dtoNormalizado.titulo,
                dtoNormalizado.icono,
                dtoNormalizado.url,
                dtoNormalizado.orden ?? 0,
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
                        `Error al insertar el menú "${dtoNormalizado.titulo}".`,
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

    async update(id: number, dto: UpdateMenuDto, usuarioId: number): Promise<MenuResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            if (dtoNormalizado.titulo) {
                dtoNormalizado.titulo = dtoNormalizado.titulo.trim().toUpperCase();
            }
            if (dtoNormalizado.url) {
                dtoNormalizado.url = dtoNormalizado.url.trim();
            }
            if (dtoNormalizado.icono) {
                dtoNormalizado.icono = dtoNormalizado.icono.trim();
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const menuActual = await manager.findOne(Menu, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!menuActual) {
                throw new DomainException(
                    `Menú no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindMenusQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindMenusQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dtoNormalizado) {
                        delete (dtoNormalizado as any)[campo];
                    }
                });
            }

            const validaciones: Promise<any>[] = [];

            if (dtoNormalizado.titulo && dtoNormalizado.titulo !== menuActual.titulo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'titulo', valor: dtoNormalizado.titulo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(menuActual, dtoNormalizado);
            menuActual.update(usuarioId);

            try {
                await manager.save(menuActual);
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
