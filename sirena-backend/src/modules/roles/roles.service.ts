// C:\sirena\sirena-backend\src\modules\roles\roles.service.ts
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
import { RolResponseDto } from './dto/rol-response.dto';
import { CreateRolDto } from './dto/create-rol.dto';
import { FindRolesQueryDto } from './dto/find-roles-query.dto';
import { UpdateRolDto } from './dto/update-rol.dto';
import { Rol } from './entities/rol.entity';

@Injectable()
export class RolesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'roles',
        nombreEntidad: 'Rol',
        campoPK: 'rol_id',
        alias: 't',
        responseDto: RolResponseDto,
        camposBusquedaEnQ: FindRolesQueryDto.getCamposParaQ(),
        tablasDependientes: FindRolesQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [],
        configuracionOrden: {
            campoOrdenPorDefecto: 'rol_id',
            camposPermitidosParaOrdenar: FindRolesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindRolesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindRolesQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateRolDto, usuarioId: number): Promise<RolResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo', valor: dtoNormalizado.codigo }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'rol', valor: dtoNormalizado.rol }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                })
            ]);

            const query = `
                INSERT INTO ${this.nombreTabla} (rol, codigo, descripcion, estado_id, usuario_id_registro, fecha_registro)
                VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;
            const params = [
                dtoNormalizado.rol,
                dtoNormalizado.codigo,
                dtoNormalizado.descripcion,
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
                        `Error al insertar el rol "${dtoNormalizado.rol}".`,
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

    async update(id: number, dto: UpdateRolDto, usuarioId: number): Promise<RolResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

            const rolActual = await manager.findOne(Rol, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!rolActual) {
                throw new DomainException(
                    `Rol no encontrado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindRolesQueryDto.getDependencias(),
                this.campoPK
            );

            if (tieneDependencias) {
                const camposProtegidos = FindRolesQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dtoNormalizado) {
                        delete (dtoNormalizado as any)[campo];
                    }
                });
            }

            const validaciones: Promise<any>[] = [];

            if (dtoNormalizado.codigo && dtoNormalizado.codigo !== rolActual.codigo) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'codigo', valor: dtoNormalizado.codigo }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (dtoNormalizado.rol && dtoNormalizado.rol !== rolActual.rol) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'rol', valor: dtoNormalizado.rol }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS]
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(rolActual, dtoNormalizado);
            rolActual.update(usuarioId);

            try {
                await manager.save(rolActual);
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
