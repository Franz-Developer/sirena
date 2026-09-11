// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\roles-permisos-tablas.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateRolPermisoTablaDto } from './dto/create-rol-permiso-tabla.dto';
import { UpdateRolPermisoTablaDto } from './dto/update-rol-permiso-tabla.dto';
import { RolPermisoTablaResponseDto } from './dto/rol-permiso-tabla-response.dto';
import { FindRolesPermisosTablasQueryDto } from './dto/find-roles-permisos-tablas-query.dto';
import { RolPermisoTabla } from './entities/rol-permiso-tabla.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class RolesPermisosTablasService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'roles_permisos_tablas',
        nombreEntidad: 'Permiso de Tabla',
        campoPK: 'rol_permiso_tabla_id',
        alias: 't',
        responseDto: RolPermisoTablaResponseDto,
        camposBusquedaEnQ: FindRolesPermisosTablasQueryDto.getCamposParaQ(),
        tablasDependientes: FindRolesPermisosTablasQueryDto.getDependencias(),
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
                table: 'tablas',
                alias: 'tb',
                onCondition: 'tb.tabla_id = t.tabla_id',
                selectColumns: [
                    'tb.nombre AS tabla_nombre'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'rol_id',
                nombreColumna: 't.rol_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tabla_id',
                nombreColumna: 't.tabla_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'rol_permiso_tabla_id',
            camposPermitidosParaOrdenar: FindRolesPermisosTablasQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindRolesPermisosTablasQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindRolesPermisosTablasQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateRolPermisoTablaDto, usuarioId: number): Promise<RolPermisoTablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dto.rol_id),
                this.tablaValidador.validarRegistrosActivos('tablas', 'tabla_id', dto.tabla_id),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'rol_id', valor: dto.rol_id },
                        { nombre: 'tabla_id', valor: dto.tabla_id }
                    ],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const permiso = manager.create(RolPermisoTabla, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(permiso);
                return this.findOne<RolPermisoTablaResponseDto>(saved.rol_permiso_tabla_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el permiso de tabla', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateRolPermisoTablaDto, usuarioId: number): Promise<RolPermisoTablaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const permisoActual = await manager.findOne(RolPermisoTabla, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!permisoActual) {
                throw new DomainException(
                    `Permiso de tabla no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindRolesPermisosTablasQueryDto.getDependencias(),
                FindRolesPermisosTablasQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.rol_id !== undefined && dtoProcesado.rol_id !== permisoActual.rol_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dtoProcesado.rol_id)
                );
            }

            if (dtoProcesado.tabla_id !== undefined && dtoProcesado.tabla_id !== permisoActual.tabla_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('tablas', 'tabla_id', dtoProcesado.tabla_id)
                );
            }

            if (
                (dtoProcesado.rol_id !== undefined && dtoProcesado.rol_id !== permisoActual.rol_id) ||
                (dtoProcesado.tabla_id !== undefined && dtoProcesado.tabla_id !== permisoActual.tabla_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'rol_id', valor: dtoProcesado.rol_id ?? permisoActual.rol_id },
                            { nombre: 'tabla_id', valor: dtoProcesado.tabla_id ?? permisoActual.tabla_id }
                        ],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS],
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(permisoActual, dtoProcesado);
            permisoActual.update(usuarioId);

            try {
                await manager.save(permisoActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el permiso de tabla', 'actualizar');
            }
        });
    }
}
