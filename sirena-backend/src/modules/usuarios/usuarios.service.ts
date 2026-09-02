// C:\sirena\sirena-backend\src\modules\usuarios\usuarios.service.ts
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
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UsuarioResponseDto } from './dto/usuario-response.dto';
import { FindUsuariosQueryDto } from './dto/find-usuarios-query.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { Usuario } from './entities/usuario.entity';
import { verifyPassword, hashPassword } from '../../common/utils/crypto.util';
import { UpdatePasswordDto } from './dto/update-password.dto';

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
                    'tr.dni AS trabajador_dni'
                ],
                type: 'INNER'
            },
            {
                table: 'sucursales',
                alias: 's',
                onCondition: 's.sucursal_id = t.sucursal_id',
                selectColumns: [
                    's.sucursal AS sucursal_nombre',
                    's.codigo AS sucursal_codigo',
                    's.codigo_sin AS sucursal_codigo_sin'
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
                nombreCampo: 'sucursal_id',
                nombreColumna: 'sucursal_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
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
            await this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear');

            if (!dto.avatar) {
                throw new DomainException(
                    'El avatar del usuario es obligatorio.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await Promise.all([
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'login', valor: dto.login }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
            ]);

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
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateUsuarioDto, usuarioId: number): Promise<UsuarioResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const usuarioActual = await manager.findOne(Usuario, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
            });

            if (!usuarioActual) {
                throw new DomainException('Usuario no encontrado.', { httpStatus: HttpStatus.NOT_FOUND });
            }

            const tieneDependencias = await this.tablaValidador.validarDependencias(
                this.nombreTabla,
                id,
                FindUsuariosQueryDto.getDependencias(),
                this.campoPK
            );

            const dtoParaActualizar = { ...dto };

            if (tieneDependencias) {
                const camposProtegidos = FindUsuariosQueryDto.getCamposProtegidosConDependencias();
                camposProtegidos.forEach(campo => {
                    if (campo in dtoParaActualizar) {
                        delete (dtoParaActualizar as any)[campo];
                    }
                });
            } else {
                if (dto.login !== undefined) {
                    await this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: [{ nombre: 'login', valor: dto.login }],
                        idExcluir: id,
                        campoPk: this.campoPK,
                        estadosValidos: [...ESTADOS_VIVOS],
                    });
                }
            }

            if (dtoParaActualizar.avatar && dtoParaActualizar.avatar === usuarioActual.avatar) {
                delete dtoParaActualizar.avatar;
            }

            manager.merge(Usuario, usuarioActual, dtoParaActualizar);
            usuarioActual.update(usuarioId);

            try {
                const saved = await manager.save(usuarioActual);
                return this.findOne<UsuarioResponseDto>(saved.usuario_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
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

            usuario.contrasena = await hashPassword(dto.nuevaContrasena);
            usuario.update(usuarioId);

            await manager.save(usuario);
            this.logger.log(`Contraseña cambiada para usuario ID: ${id}`);
        });
    }
}
