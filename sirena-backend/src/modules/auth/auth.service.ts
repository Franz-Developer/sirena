// C:\sirena\sirena-backend\src\modules\auth\auth.service.ts
import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { plainToInstance } from 'class-transformer';
import { DataSource } from 'typeorm';
import { Estado } from '../../common/constants/estados.constant';
import { estructurarMenu } from '../../common/utils/menu-parser.util';
import { UsuarioResponseDto } from '../usuarios/dto/usuario-response.dto';
import { LoginDto } from './dto/login.dto';

interface PermisoMenu {
    crear: boolean;
    editar: boolean;
    eliminar: boolean;
}

interface PermisosMap {
    [menuTitulo: string]: PermisoMenu;
}

@Injectable()
export class AuthService {
    private readonly logger = new Logger(AuthService.name);

    constructor(
        private readonly jwtService: JwtService,
        private readonly dataSource: DataSource,
    ) {}

    async validarLogin(dto: LoginDto) {
        const { username, password } = dto;
        const startTime = Date.now();

        this.logger.debug(`Iniciando proceso de autenticación para usuario: ${username}`);

        // 1. OBTENER USUARIO
        const sqlUsuario = `
            SELECT
                u.usuario_id,
                u.login,
                u.sucursal_id,
                u.avatar,
                u.rol_id,
                u.contrasena,
                p.trabajador_id AS "trabajadorID",
                p.nombres,
                r.codigo AS "rolCodigo",
                r.rol,
                trim(p.nombres || ' ' || p.paterno || ' ' || COALESCE(p.materno, '')) AS "trabajadorNombreCompleto",
                p.nombres AS "trabajadorNombres",
                p.paterno AS "trabajadorPaterno",
                p.materno AS "trabajadorMaterno",
                p.dni AS "trabajadorDNI",
                s.sucursal AS "sucursalNombre",
                s.codigo AS "sucursalCodigo",
                e.empresa_id AS "empresaID",
                e.empresa AS "empresaNombre",
                e.codigo AS "empresaCodigo"
            FROM usuarios u
            INNER JOIN roles r ON r.rol_id = u.rol_id
            INNER JOIN trabajadores p ON p.trabajador_id = u.trabajador_id
            INNER JOIN sucursales s ON s.sucursal_id = u.sucursal_id
            INNER JOIN empresas e ON e.empresa_id = s.empresa_id
            WHERE u.login = $1
                AND u.estado_id = $2
        `;

        const queryStart = Date.now();
        const resultadoUser = await this.dataSource.query(sqlUsuario, [username, Estado.ACTIVO]);
        this.logger.debug(`Consulta usuario completada en ${Date.now() - queryStart}ms`);

        const datosCompletos = resultadoUser[0];

        if (!datosCompletos) {
            this.logger.warn(`Intento de login fallido: Usuario '${username}' no encontrado o inactivo.`);
            throw new UnauthorizedException('Usuario no encontrado o inactivo');
        }

        // 2. VALIDAR CONTRASEÑA
        const bcryptStart = Date.now();
        const passwordValido = await bcrypt.compare(password, datosCompletos.contrasena);
        this.logger.debug(`Verificación bcrypt completada en ${Date.now() - bcryptStart}ms`);

        if (!passwordValido) {
            this.logger.warn(`Intento de login fallido: Contraseña incorrecta para el usuario '${username}'.`);
            throw new UnauthorizedException('Credenciales inválidas');
        }

        // Limpiar credencial y transformar a DTO seguro
        delete datosCompletos.contrasena;
        const usuarioDto = plainToInstance(UsuarioResponseDto, datosCompletos, {
            excludeExtraneousValues: true
        });

        // 3. CONSULTA DE MENÚ (YA INCLUYE PERMISOS)
        const sqlMenu = `
            SELECT
                m.menu_id,
                m.menu_padre_id,
                m.titulo,
                m.icono,
                m.url,
                m.orden
            FROM menus m
            INNER JOIN roles_menus rm ON m.menu_id = rm.menu_id
            INNER JOIN usuarios u ON rm.rol_id = u.rol_id
            WHERE u.usuario_id = $1
                AND m.estado_id = $2
                AND rm.estado_id = $3
                AND u.estado_id = $4
            ORDER BY m.orden ASC
        `;

        const menuStart = Date.now();
        const rawMenu = await this.dataSource.query(sqlMenu, [
            usuarioDto.usuario_id,
            Estado.ACTIVO,
            Estado.ACTIVO,
            Estado.ACTIVO
        ]);
        this.logger.debug(`Consulta menú completada en ${Date.now() - menuStart}ms`);

        // 4. TRANSFORMACIÓN DE DATOS
        const menuEstructurado = estructurarMenu(rawMenu);

        const permisosMap = rawMenu.reduce((acc: PermisosMap, row: any) => {
            acc[row.titulo] = {
                crear: row.crear === 1,
                editar: row.editar === 1,
                eliminar: row.eliminar === 1
            };
            return acc;
        }, {} as PermisosMap);

        // 5. GENERACIÓN DE TOKEN JWT
        const payload = {
            sub: usuarioDto.usuario_id,
            username: usuarioDto.login,
        };

        const token = this.jwtService.sign(payload);

        // Log final con tiempo total
        this.logger.log(
            `Login exitoso: ${username} (ID Usuario: ${usuarioDto.usuario_id}) - ` +
            `Tiempo total: ${Date.now() - startTime}ms`
        );

        return {
            token,
            usuario: usuarioDto,
            menu: menuEstructurado,
            permisos: permisosMap
        };
    }
}
