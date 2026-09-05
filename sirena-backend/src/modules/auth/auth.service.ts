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
import { logSqlQuery } from '../../common/utils/sql-logger.util';

interface PermisoDetalle {
    crear: boolean;
    editar: boolean;
    eliminar: boolean;
    leer: boolean;
    anular: boolean;
    archivar: boolean;
    desarchivar: boolean;
}

interface PermisosMap {
    [nombreTablaOModulo: string]: PermisoDetalle;
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
                e.empresa_id AS empresa_id,
                e.empresa AS empresa_nombre,
                e.codigo AS empresa_codigo,
                u.sucursal_id,
                s.sucursal AS sucursal_nombre,
                s.codigo AS sucursal_codigo,
                u.avatar,
                u.rol_id,
                r.codigo AS rol_codigo,
                r.rol AS rol_nombre,
                u.contrasena,
                t.trabajador_id AS trabajador_id,
                TRIM(t.nombres || ' ' || t.paterno || ' ' || COALESCE(t.materno, '')) AS trabajador_nombre_completo,
                t.nombres AS trabajador_nombres,
                t.paterno AS trabajador_paterno,
                t.materno AS trabajador_materno,
                t.dni AS trabajador_dni,
                c.cargo_id AS cargo_id,
                c.cargo AS cargo_nombre,
                c.codigo AS cargo_codigo
            FROM usuarios u
            INNER JOIN roles r ON r.rol_id = u.rol_id AND r.estado_id = $2
            INNER JOIN trabajadores t ON t.trabajador_id = u.trabajador_id AND t.estado_id = $2
            INNER JOIN trabajadores_cargos tc ON tc.trabajador_id = t.trabajador_id AND tc.estado_id = $2 AND tc.es_activo = 1
            INNER JOIN cargos c ON c.cargo_id = tc.cargo_id AND c.estado_id = $2
            INNER JOIN sucursales s ON s.sucursal_id = u.sucursal_id AND s.estado_id = $2
            INNER JOIN empresas e ON e.empresa_id = s.empresa_id AND e.estado_id = $2
            WHERE u.login = $1
            AND u.estado_id = $2
        `;

        let param = [username, Estado.ACTIVO];
        const queryStart = Date.now();
        logSqlQuery(sqlUsuario, param, 'Consulta Usuario');

        const resultadoUser = await this.dataSource.query(sqlUsuario, param);
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

        // 3. CONSULTA DE MENÚS (Vía la nueva tabla relacional roles_menus)
        const sqlMenu = `
            SELECT
                m.menu_id,
                m.menu_padre_id,
                m.titulo,
                m.icono,
                m.url,
                m.orden
            FROM menus m
            INNER JOIN roles_menus rm ON rm.menu_id = m.menu_id AND rm.estado_id = $1
            WHERE m.menu_id > 1
                AND m.estado_id = $1
                AND rm.rol_id = $2
            ORDER BY m.orden ASC
        `;

        param = [Estado.ACTIVO, usuarioDto.rol_id];
        logSqlQuery(sqlMenu, param, 'Consulta Menu');

        const menuStart = Date.now();
        const rawMenu = await this.dataSource.query(sqlMenu, param);
        this.logger.debug(`Consulta menú completada en ${Date.now() - menuStart}ms`);

        const menuEstructurado = estructurarMenu(rawMenu);

        // 4. CONSULTA DE PERMISOS GRANULARES (Vía roles_permisos_tablas y la tabla tablas)
        const sqlPermisosTablas = `
            SELECT
                t.nombre AS tabla_nombre,
                rpt.crear,
                rpt.editar,
                rpt.eliminar,
                rpt.leer,
                rpt.anular,
                rpt.archivar,
                rpt.desarchivar
            FROM roles_permisos_tablas rpt
            INNER JOIN tablas t ON t.tabla_id = rpt.tabla_id AND t.estado_id = $2
            WHERE rpt.rol_id = $1
                AND rpt.estado_id = $2
        `;
        param = [usuarioDto.rol_id, Estado.ACTIVO];
        logSqlQuery(sqlMenu, param, 'Consulta Menu');

        const permisosStart = Date.now();
        const rawPermisos = await this.dataSource.query(sqlPermisosTablas, param);
        this.logger.debug(`Consulta permisos de tablas completada en ${Date.now() - permisosStart}ms`);

        const permisosMap = rawPermisos.reduce((acc: PermisosMap, row: any) => {
            acc[row.tabla_nombre] = {
                crear: row.crear === 1 || row.crear === true,
                editar: row.editar === 1 || row.editar === true,
                eliminar: row.eliminar === 1 || row.eliminar === true,
                leer: row.leer === 1 || row.leer === true,
                anular: row.anular === 1 || row.anular === true,
                archivar: row.archivar === 1 || row.archivar === true,
                desarchivar: row.desarchivar === 1 || row.desarchivar === true,
            };
            return acc;
        }, {} as PermisosMap);

        // 5. GENERACIÓN DE TOKEN JWT
        const payload = {
            sub: usuarioDto.usuario_id,
            username: usuarioDto.login,
            rol_id: usuarioDto.rol_id,
        };

        const token = this.jwtService.sign(payload);

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
