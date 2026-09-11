// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\roles-permisos-sucesos.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateRolPermisoSucesoDto } from './dto/create-rol-permiso-suceso.dto';
import { UpdateRolPermisoSucesoDto } from './dto/update-rol-permiso-suceso.dto';
import { RolPermisoSucesoResponseDto } from './dto/rol-permiso-suceso-response.dto';
import { FindRolesPermisosSucesosQueryDto } from './dto/find-roles-permisos-sucesos-query.dto';
import { RolPermisoSuceso } from './entities/rol-permiso-suceso.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class RolesPermisosSucesosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'roles_permisos_sucesos',
        nombreEntidad: 'Permiso de Suceso',
        campoPK: 'rol_permiso_suceso_id',
        alias: 't',
        responseDto: RolPermisoSucesoResponseDto,
        camposBusquedaEnQ: FindRolesPermisosSucesosQueryDto.getCamposParaQ(),
        tablasDependientes: FindRolesPermisosSucesosQueryDto.getDependencias(),
        joins: [
            {
                table: 'roles_permisos_tablas',
                alias: 'rpt',
                onCondition: 'rpt.rol_permiso_tabla_id = t.rol_permiso_tabla_id',
                selectColumns: [
                    'rpt.rol_id AS rol_id'
                ],
                type: 'INNER'
            },
            {
                table: 'roles',
                alias: 'r',
                onCondition: 'r.rol_id = rpt.rol_id',
                selectColumns: [
                    'r.rol AS rol_nombre',
                    'r.codigo AS rol_codigo'
                ],
                type: 'INNER'
            },
            {
                table: 'tablas',
                alias: 'tb',
                onCondition: 'tb.tabla_id = rpt.tabla_id',
                selectColumns: [
                    'tb.nombre AS tabla_nombre'
                ],
                type: 'INNER'
            },
            {
                table: 'sucesos',
                alias: 's',
                onCondition: 's.suceso_id = t.suceso_id',
                selectColumns: [
                    's.codigo AS suceso_codigo',
                    's.suceso AS suceso_nombre'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'rol_permiso_tabla_id',
                nombreColumna: 't.rol_permiso_tabla_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'suceso_id',
                nombreColumna: 't.suceso_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'rol_permiso_suceso_id',
            camposPermitidosParaOrdenar: FindRolesPermisosSucesosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindRolesPermisosSucesosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindRolesPermisosSucesosQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateRolPermisoSucesoDto, usuarioId: number): Promise<RolPermisoSucesoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('roles_permisos_tablas', 'rol_permiso_tabla_id', dto.rol_permiso_tabla_id),
                this.tablaValidador.validarRegistrosActivos('sucesos', 'suceso_id', dto.suceso_id),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'rol_permiso_tabla_id', valor: dto.rol_permiso_tabla_id },
                        { nombre: 'suceso_id', valor: dto.suceso_id }
                    ],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const permiso = manager.create(RolPermisoSuceso, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(permiso);
                return this.findOne<RolPermisoSucesoResponseDto>(saved.rol_permiso_suceso_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el permiso de suceso', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateRolPermisoSucesoDto, usuarioId: number): Promise<RolPermisoSucesoResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const permisoActual = await manager.findOne(RolPermisoSuceso, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!permisoActual) {
                throw new DomainException(
                    `Permiso de suceso no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindRolesPermisosSucesosQueryDto.getDependencias(),
                FindRolesPermisosSucesosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.rol_permiso_tabla_id !== undefined && dtoProcesado.rol_permiso_tabla_id !== permisoActual.rol_permiso_tabla_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('roles_permisos_tablas', 'rol_permiso_tabla_id', dtoProcesado.rol_permiso_tabla_id)
                );
            }

            if (dtoProcesado.suceso_id !== undefined && dtoProcesado.suceso_id !== permisoActual.suceso_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('sucesos', 'suceso_id', dtoProcesado.suceso_id)
                );
            }

            if (
                (dtoProcesado.rol_permiso_tabla_id !== undefined && dtoProcesado.rol_permiso_tabla_id !== permisoActual.rol_permiso_tabla_id) ||
                (dtoProcesado.suceso_id !== undefined && dtoProcesado.suceso_id !== permisoActual.suceso_id)
            ) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [
                            { nombre: 'rol_permiso_tabla_id', valor: dtoProcesado.rol_permiso_tabla_id ?? permisoActual.rol_permiso_tabla_id },
                            { nombre: 'suceso_id', valor: dtoProcesado.suceso_id ?? permisoActual.suceso_id }
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
                throw crearError(error, 'el permiso de suceso', 'actualizar');
            }
        });
    }
}
