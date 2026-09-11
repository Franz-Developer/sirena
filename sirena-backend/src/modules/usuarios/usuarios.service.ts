// C:\sirena\sirena-backend\src\modules\usuarios\usuarios.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UsuarioResponseDto } from './dto/usuario-response.dto';
import { FindUsuariosQueryDto } from './dto/find-usuarios-query.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { Usuario } from './entities/usuario.entity';
import { verifyPassword, hashPassword } from '../../common/utils/crypto.util';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class UsuariosService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'usuarios',
        nombreEntidad: 'Usuario',
        campoPK: 'usuario_id',
        alias: 't',
        responseDto: UsuarioResponseDto,
        camposBusquedaEnQ: FindUsuariosQueryDto.getCamposParaQ(),
        tablasDependientes: FindUsuariosQueryDto.getDependencias(),
        joins: [
            {
                table: 'trabajadores',
                alias: 'tr',
                onCondition: 'tr.trabajador_id = t.trabajador_id',
                selectColumns: [
                    "TRIM(CONCAT_WS(' ', tr.nombres, tr.paterno, tr.materno)) AS trabajador_nombre_completo",
                    'tr.nombres AS trabajador_nombres',
                    'tr.paterno AS trabajador_paterno',
                    'tr.materno AS trabajador_materno',
                    'tr.dni AS trabajador_dni',
                    'tr.foto AS trabajador_foto',
                    'tr.sucursal_id AS trabajador_sucursal_id'
                ],
                type: 'INNER'
            },
            {
                table: 'sucursales',
                alias: 's',
                onCondition: 's.sucursal_id = tr.sucursal_id',
                selectColumns: [
                    's.sucursal_id AS sucursal_id',
                    's.sucursal AS sucursal_nombre',
                    's.codigo AS sucursal_codigo',
                    's.codigo_sin AS sucursal_codigo_sin',
                    's.telefono AS sucursal_telefono',
                    's.ubicacion AS sucursal_ubicacion',
                    's.horario_atencion AS sucursal_horario',
                    's.empresa_id AS sucursal_empresa_id'
                ],
                type: 'INNER'
            },
            {
                table: 'empresas',
                alias: 'e',
                onCondition: 'e.empresa_id = s.empresa_id',
                selectColumns: [
                    'e.empresa_id AS empresa_id',
                    'e.empresa AS empresa_nombre',
                    'e.codigo AS empresa_codigo',
                    'e.logo AS empresa_logo',
                    'e.eslogan AS empresa_eslogan',
                    'e.direccion AS empresa_direccion',
                    'e.telefono AS empresa_telefono'
                ],
                type: 'INNER'
            },
            {
                table: 'trabajadores_cargos',
                alias: 'tc',
                onCondition: 'tc.trabajador_id = tr.trabajador_id AND tc.es_activo = 1',
                selectColumns: [],
                type: 'INNER'
            },
            {
                table: 'cargos',
                alias: 'c',
                onCondition: 'c.cargo_id = tc.cargo_id',
                selectColumns: [
                    'c.cargo_id AS cargo_id',
                    'c.cargo AS cargo_nombre',
                    'c.codigo AS cargo_codigo'
                ],
                type: 'INNER'
            },
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
                nombreCampo: 'trabajador_id',
                nombreColumna: 'trabajador_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'empresa_id',
                nombreColumna: 'e.empresa_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'sucursal_id',
                nombreColumna: 's.sucursal_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'cargo_id',
                nombreColumna: 'c.cargo_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'usuario_id',
            camposPermitidosParaOrdenar: FindUsuariosQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindUsuariosQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindUsuariosQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateUsuarioDto, usuarioId: number): Promise<UsuarioResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, 'usuarios', 'crear'),
                this.tablaValidador.validarRegistrosActivos('roles', 'rol_id', dto.rol_id),
                this.tablaValidador.validarRegistrosActivos('trabajadores', 'trabajador_id', dto.trabajador_id),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            if (!dto.avatar) {
                throw new DomainException(
                    'El avatar del usuario es obligatorio.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.unicidadValidador.validarUnicidad({
                tabla: this.nombreTabla,
                campos: [{ nombre: 'login', valor: dto.login }],
                campoPk: this.campoPK,
                estadosValidos: [...ESTADOS_VIVOS],
            });

            const usuario = manager.create(Usuario, {
                ...dto,
                contrasena: await hashPassword(dto.contrasena),
                avatar: dto.avatar,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(usuario);
                return this.findOne<UsuarioResponseDto>(saved.usuario_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el usuario', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateUsuarioDto, usuarioId: number): Promise<UsuarioResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const usuarioActual = await manager.findOne(Usuario, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!usuarioActual) {
                throw new DomainException('Usuario no encontrado.', { httpStatus: HttpStatus.NOT_FOUND });
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindUsuariosQueryDto.getDependencias(),
                FindUsuariosQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            if (dtoProcesado.login !== undefined) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'login', valor: dtoProcesado.login }],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                });
            }

            if (dtoProcesado.avatar && dtoProcesado.avatar === usuarioActual.avatar) {
                delete dtoProcesado.avatar;
            }

            manager.merge(Usuario, usuarioActual, dtoProcesado);
            usuarioActual.update(usuarioId);

            try {
                await manager.save(usuarioActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el usuario', 'actualizar');
            }
        });
    }

    async cambiarPassword(
        id: number,
        dto: UpdatePasswordDto,
        usuarioId: number
    ): Promise<void> {
        return runInTransaction(this.dataSource, async (manager) => {
            const usuario = await manager.findOne(Usuario, {
                where: { [this.campoPK]: id }
            });

            if (!usuario) {
                throw new DomainException(
                    'Usuario no encontrado.',
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const passwordValida = await verifyPassword(
                dto.contrasenaActual,
                usuario.contrasena
            );

            if (!passwordValida) {
                throw new DomainException(
                    'La contraseña actual es incorrecta.',
                    { httpStatus: HttpStatus.UNAUTHORIZED }
                );
            }

            const esMismaPassword = await verifyPassword(
                dto.nuevaContrasena,
                usuario.contrasena
            );

            if (esMismaPassword) {
                throw new DomainException(
                    'La nueva contraseña debe ser diferente a la actual.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            try {
                usuario.contrasena = await hashPassword(dto.nuevaContrasena);
                usuario.update(usuarioId);
                await manager.save(usuario);
                this.logger.log(`Contraseña cambiada para usuario ID: ${id}`);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado al cambiar contraseña: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la contraseña del usuario', 'actualizar');
            }
        });
    }
}
