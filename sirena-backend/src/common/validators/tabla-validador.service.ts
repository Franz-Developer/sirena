// C:\sirena\sirena-backend\src\common\validators\tabla-validador.service.ts
import { Injectable, Inject, HttpStatus, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { ESTADO_ACTIVO, ESTADO_HISTORICO,  ESTADOS_VIVOS } from '../constants/estados.constant';
import { DomainException } from '../exceptions/domain.exception';
import { IDataSource } from '../interfaces/repository.interface';
import { getErrorMessage, getErrorStack, isDomainException } from '../utils/error.util';
import { ConfiguracionService } from '../services/configuracion.service';

export interface ItemValidacionFK {
    id: number;
    campo?: string;
}

interface RegistroGenerico {
    id: number;
    estado_id: number;
    fecha_baja: Date | string | null;
    [key: string]: unknown;
}

@Injectable()
export class TablaValidadorService {
    private readonly logger = new Logger(TablaValidadorService.name);
    private permisoCache = new Map<string, { tienePermiso: boolean; timestamp: number }>();
    private readonly PERMISO_CACHE_TTL_MS: number;
    private dependenciasCache = new Map<string, { tiene: boolean; timestamp: number }>();
    private readonly DEPENDENCIAS_CACHE_TTL_MS: number;

    constructor(
        @Inject('IDataSource') private readonly dataSource: IDataSource,
        private readonly configService: ConfigService,
        private readonly configuracionService: ConfiguracionService,
    ) {
        const permisoTtlSeconds = parseInt(this.configService.get<string>('PERMISO_CACHE_TTL', '60'), 10);
        this.PERMISO_CACHE_TTL_MS = Math.max(permisoTtlSeconds, 1) * 1000;

        const dependenciasTtlSeconds = parseInt(this.configService.get<string>('DEPENDENCIAS_CACHE_TTL', '10'), 10);
        this.DEPENDENCIAS_CACHE_TTL_MS = Math.max(dependenciasTtlSeconds, 1) * 1000;
    }

    async obtenerFechaInicioGestion(): Promise<Date> {
        try {
            const fecha = await this.configuracionService.obtenerValorTipado<Date>('gestion_activa');
            if (fecha && !isNaN(new Date(fecha).getTime())) {
                return new Date(fecha);
            }

            const year = new Date().getFullYear();
            const fallback = new Date(Date.UTC(year, 0, 1));
            this.logger.warn(`No se encontró gestión_activa o es inválida, usando fallback: ${fallback.toISOString()}`);
            return fallback;
        } catch (error) {
            const year = new Date().getFullYear();
            const fallback = new Date(Date.UTC(year, 0, 1));
            this.logger.error(`Error al obtener gestión_activa desde ConfiguracionService: ${getErrorMessage(error)}`);
            return fallback;
        }
    }

    invalidarCacheGestion(): void {
        this.configuracionService.invalidarCache();
        this.logger.debug(`Caché de gestión_activa invalidada mediante ConfiguracionService.`);
    }

    async validarRegistrosActivos(
        tabla: string,
        campoPk: string = 'id',
        pkId: number,
    ): Promise<boolean> {
        const tablaNormalizada = tabla.toLowerCase().trim();
        const tablaSanitizada = this.dataSource.escapeIdentifier(tablaNormalizada);
        const campoPkSanitizado = this.dataSource.escapeIdentifier(campoPk);

        const query = `
            SELECT 1
            FROM ${tablaSanitizada} t
            WHERE t.${campoPkSanitizado} = $1
                AND t.estado_id = $2
                AND t.fecha_baja IS NULL
            LIMIT 1
        `;
        const params: any[] = [Number(pkId), ESTADO_ACTIVO];

        try {
            const resultado = await this.dataSource.query(query, params);

            if (!resultado || resultado.length === 0) {
                throw new DomainException(
                    `No se encontró un registro activo con ID ${pkId}. Verifique que el registro exista y no esté dado de baja.`,
                    {
                        httpStatus: HttpStatus.BAD_REQUEST,
                        tabla: tablaNormalizada,
                        campoPk,
                        pkId,
                    }
                );
            }
            return true;
        } catch (error) {
            if (isDomainException(error)) {
                throw error;
            }
            this.logger.error(`Error validando ${tablaNormalizada}#${pkId}: ${getErrorMessage(error)}`);
            throw error;
        }
    }

    async validarPreUpdate(
        tabla: string,
        pkId: number,
        dto: Record<string, any>,
        campoPk: string = 'id',
        usuarioId: number,
    ): Promise<Record<string, any>> {
        const tablaNormalizada = tabla.toLowerCase().trim();

        // 1. Validar registros protegidos
        if (Number(pkId) === 1) {
            throw new DomainException(
                `Operación denegada: El registro con ID = 1 en la tabla '${tablaNormalizada}' es un registro comodín del sistema y no puede ser modificado. Esta restricción protege la integridad referencial de los datos maestros.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'REGISTRO_COMODIN_PROTEGIDO'
                }
            );
        }

        if (tablaNormalizada === 'usuarios' && Number(pkId) === 2) {
            throw new DomainException(
                `Operación denegada: El usuario administrador principal del sistema ADMIN es un registro crítico que no puede ser modificado. Esta restricción asegura que siempre exista un usuario con privilegios de administrador en el sistema.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'USUARIO_ADMIN_PROTEGIDO'
                }
            );
        }

        // 2. Validar permisos del usuario
        await this.validarPermisoTabla(usuarioId, tablaNormalizada, 'editar');

        // 3. Validar que no se modifique el estado directamente
        if ('estado_id' in dto) {
            throw new DomainException(
                `La operación de actualización no permite modificar el campo 'estado_id' directamente. Para cambiar el estado del registro, utilice los endpoints específicos de 'archivar' (para pasar a HISTORICO) o 'desarchivar' (para pasar a ACTIVO).`,
                {
                    httpStatus: HttpStatus.BAD_REQUEST,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'CAMBIO_ESTADO_NO_PERMITIDO'
                }
            );
        }

        // 4. Buscar el registro
        const tablaSanitizada = this.dataSource.escapeIdentifier(tablaNormalizada);
        const campoPkSanitizado = this.dataSource.escapeIdentifier(campoPk);

        const query = `
            SELECT ${campoPkSanitizado}, estado_id, fecha_baja
            FROM ${tablaSanitizada}
            WHERE ${campoPkSanitizado} = $1
                AND estado_id = $2
                AND fecha_baja IS NULL
        `;
        const params = [Number(pkId), ESTADO_ACTIVO];
        logSqlQuery(query, params, `validarPreUpdate - ${tablaSanitizada}`);

        const resultados = await this.dataSource.query(query, params);
        const registro = resultados?.[0];

        if (!registro) {
            throw new DomainException(
                `No se encontró un registro activo con ID ${pkId}. La operación de actualización requiere que el registro exista y esté activo.`,
                {
                    httpStatus: HttpStatus.NOT_FOUND,
                    tabla: tablaNormalizada,
                    campoPk,
                    pkId,
                }
            );
        }

        return registro;
    }

    async validarPreArchivar(
        tabla: string,
        pkId: number,
        usuarioId: number,
        campoPk: string = 'id',
    ): Promise<RegistroGenerico> {
        const tablaNormalizada = tabla.toLowerCase().trim();

        if (Number(pkId) === 1) {
            throw new DomainException(
                `Operación denegada: El registro con ID = 1 en la tabla '${tablaNormalizada}' es un registro comodín del sistema y no puede ser archivado. Esta restricción preserva la integridad referencial de los datos maestros.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'REGISTRO_COMODIN_PROTEGIDO'
                }
            );
        }

        if (tablaNormalizada === 'usuarios' && Number(pkId) === 2) {
            throw new DomainException(
                `Operación denegada: El usuario administrador principal del sistema ADMIN es un registro crítico que no puede ser archivado. Esta restricción asegura que siempre exista un usuario con privilegios de administrador en el sistema.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'USUARIO_ADMIN_PROTEGIDO'
                }
            );
        }

        await this.validarPermisoTabla(usuarioId, tablaNormalizada, 'archivar');

        const tablaSanitizada = this.dataSource.escapeIdentifier(tablaNormalizada);
        const campoPkSanitizado = this.dataSource.escapeIdentifier(campoPk);

        const query = `
            SELECT estado_id, fecha_baja, ${tablaNormalizada === 'parametros_globales' ? 'editable' : '0 AS editable'}
            FROM ${tablaSanitizada} t
            WHERE t.${campoPkSanitizado} = $1
                AND t.estado_id = $2
                AND t.fecha_baja IS NULL
            LIMIT 1
        `;
        const params = [pkId, ESTADO_ACTIVO];
        logSqlQuery(query, params, `validarPreArchivar - ${tablaSanitizada}`);

        let registro: RegistroGenerico | undefined;

        try {
            const resultados = (await this.dataSource.query(query, params)) as RegistroGenerico[];
            registro = resultados[0];
        } catch (error) {
            if (isDomainException(error)) {
                throw error;
            }
            this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
            throw error;
        }

        if (!registro) {
            throw new DomainException(
                `No se encontró un registro activo con ID ${pkId}. La operación de archivado requiere que el registro exista y esté activo.`,
                {
                    httpStatus: HttpStatus.NOT_FOUND,
                    tabla: tablaNormalizada,
                    campoPk,
                    pkId,
                }
            );
        }

        if (tablaNormalizada === 'parametros_globales' && Number(registro['editable']) === 1) {
            const clave = registro['clave'];
            throw new DomainException(
                `Operación denegada: El parámetro global con clave "${clave}" (ID = ${pkId}) está marcado como NO editable y no puede ser archivado. Solo los parámetros editables pueden ser modificados.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    clave,
                    motivo: 'PARAMETRO_NO_EDITABLE'
                }
            );
        }

        return registro;
    }

    async validarPreDesarchivar(
        tabla: string,
        pkId: number,
        usuarioId: number,
        campoPk: string = 'id',
    ): Promise<RegistroGenerico> {
        const tablaNormalizada = tabla.toLowerCase().trim();

        if (Number(pkId) === 1) {
            throw new DomainException(
                `Operación denegada: El registro con ID = 1 en la tabla '${tablaNormalizada}' es un registro comodín del sistema y no puede ser desarchivado. Esta restricción preserva la integridad referencial de los datos maestros.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'REGISTRO_COMODIN_PROTEGIDO'
                }
            );
        }

        await this.validarPermisoTabla(usuarioId, tablaNormalizada, 'desarchivar');
        const tablaSanitizada = this.dataSource.escapeIdentifier(tablaNormalizada);
        const campoPkSanitizado = this.dataSource.escapeIdentifier(campoPk);

        const query = `
            SELECT 1
            FROM ${tablaSanitizada} t
            WHERE t.${campoPkSanitizado} = $1
                AND t.estado_id = $2
                AND t.fecha_baja IS NULL
        `;
        const params = [pkId, ESTADO_HISTORICO];
        logSqlQuery(query, params, `validarPreDesarchivar - ${tablaSanitizada}`);

        let registro: RegistroGenerico | undefined;

        try {
            const resultados = (await this.dataSource.query(query, params)) as RegistroGenerico[];
            registro = resultados[0];
        } catch (error) {
            if (isDomainException(error)) {
                throw error;
            }
            this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
            throw error;
        }

        if (!registro) {
            throw new DomainException(
                `No se encontró un registro histórico con ID ${pkId}. La operación de desarchivado requiere que el registro exista y esté en estado histórico.`,
                {
                    httpStatus: HttpStatus.NOT_FOUND,
                    tabla: tablaNormalizada,
                    campoPk,
                    pkId,
                }
            );
        }

        return registro;
    }

    async validarPreDelete(
        tablaOrigen: string,
        pkId: number,
        tablasDependientes: Array<string | { tabla: string; campoFk: string }>,
        campoFkDefault: string,
        usuarioId: number,
    ): Promise<void> {
        const tablaNormalizada = tablaOrigen.toLowerCase().trim();

        if (Number(pkId) === 1) {
            throw new DomainException(
                `Operación denegada: El registro con ID = 1 en la tabla '${tablaNormalizada}' es un registro comodín del sistema y no puede ser eliminado. Esta restricción protege la integridad referencial de los datos maestros.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'REGISTRO_COMODIN_PROTEGIDO'
                }
            );
        }

        if (tablaNormalizada === 'usuarios' && Number(pkId) === 2) {
            throw new DomainException(
                `Operación denegada: El usuario administrador principal del sistema ADMIN es un registro crítico que no puede ser eliminado. Esta restricción asegura que siempre exista un usuario con privilegios de administrador en el sistema.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'USUARIO_ADMIN_PROTEGIDO'
                }
            );
        }

        await this.validarPermisoTabla(usuarioId, tablaNormalizada, 'eliminar');

        const tablaSanitizada = this.dataSource.escapeIdentifier(tablaNormalizada);
        const campoPkSanitizado = this.dataSource.escapeIdentifier(campoFkDefault || 'id');

        const query = `
            SELECT estado_id, fecha_baja, ${tablaNormalizada === 'parametros_globales' ? 'editable' : '0 AS editable'}
            FROM ${tablaSanitizada}
            WHERE ${campoPkSanitizado} = $1
                AND estado_id = $2
                AND fecha_baja IS NULL
            LIMIT 1
        `;
        const params = [pkId, ESTADO_ACTIVO];
        logSqlQuery(query, params, `validarPreDelete - ${tablaSanitizada}`);

        let existeResult;
        try {
            existeResult = await this.dataSource.query(query, params);
        } catch (error) {
            if (isDomainException(error)) throw error;

            const errorMessage = getErrorMessage(error);
            throw new DomainException(
                `Error interno al verificar la existencia del registro con ${campoPkSanitizado} = ${pkId} en la tabla '${tablaNormalizada}'. Detalle técnico: ${errorMessage}. Por favor, contacte al administrador del sistema.`,
                {
                    tabla: tablaNormalizada,
                    pkId,
                    campoPk: campoFkDefault,
                    originalError: errorMessage,
                    httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                }
            );
        }

        if (!existeResult || existeResult.length === 0) {
            throw new DomainException(
                `No se encontró un registro activo con ID ${pkId}. La operación de eliminación requiere que el registro exista y esté activo.`,
                {
                    httpStatus: HttpStatus.NOT_FOUND,
                    tabla: tablaNormalizada,
                    campoPk: campoFkDefault,
                    pkId,
                }
            );
        }

        const registro = existeResult[0];

        if (tablaNormalizada === 'parametros_globales' && Number(registro['editable']) === 1) {
            throw new DomainException(
                `Operación denegada: El parámetro global con ID = ${pkId} en la tabla '${tablaNormalizada}' está marcado como NO editable y no puede ser eliminado. Solo los parámetros editables pueden ser eliminados.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'PARAMETRO_NO_EDITABLE'
                }
            );
        }

        if (tablasDependientes && tablasDependientes.length > 0) {
            let tieneDependencias = false;
            try {
                tieneDependencias = await this.validarDependencias(
                    tablaOrigen,
                    pkId,
                    tablasDependientes,
                    campoFkDefault,
                );
            } catch (error) {
                if (isDomainException(error)) throw error;

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error al validar dependencias para ${tablaNormalizada}#${pkId}: ${errorMessage}`, getErrorStack(error));

                const tablasDependientesStr = tablasDependientes
                    .map(item => typeof item === 'string' ? item : `${item.tabla}(${item.campoFk})`)
                    .join(', ');

                throw new DomainException(
                    `Error interno al validar dependencias del registro con ${campoFkDefault} = ${pkId} en la tabla '${tablaNormalizada}'. Tablas dependientes verificadas: [${tablasDependientesStr}]. Detalle técnico: ${errorMessage}. Por favor, contacte al administrador del sistema.`,
                    {
                        tabla: tablaNormalizada,
                        pkId,
                        campoPk: campoFkDefault,
                        tablasDependientes: tablasDependientesStr,
                        originalError: errorMessage,
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }

            if (tieneDependencias) {
                const tablasDependientesStr = tablasDependientes
                    .map(item => typeof item === 'string' ? item : `${item.tabla}(${item.campoFk})`)
                    .join(', ');

                throw new DomainException(
                    `No se puede eliminar el registro porque tiene dependencias en: ${tablasDependientesStr}. Primero debe eliminar los registros dependientes.`,
                    {
                        httpStatus: HttpStatus.CONFLICT,
                        tabla: tablaNormalizada,
                        pkId,
                        campoPk: campoFkDefault,
                        tablasDependientes: tablasDependientesStr,
                        motivo: 'DEPENDENCIAS_ACTIVAS'
                    }
                );
            }
        }
    }

    /**
     * Verifica si un registro tiene dependencias en otras tablas,
     * considerando estados ACTIVOS (1000) e HISTÓRICOS (1002).
     *
     * @param tablaOrigen - Tabla principal que se está verificando (solo para contexto)
     * @param pkId - ID del registro a verificar
     * @param tablasDependientes - Lista de tablas dependientes (string o { tabla, campoFk })
     * @param campoFkDefault - Campo FK por defecto (usado cuando solo se pasa string)
     * @returns true si tiene dependencias, false si no
     *
     * @example
     * // Usando strings (usa campoFkDefault)
     * const tiene = await validarDependencias(
     *   'empresas',
     *   1,
     *   ['sucursales', 'empresas_nits', 'empresas_cuentas'],
     *   'empresa_id'
     * );
     *
     * // Usando objetos (campo FK específico por tabla)
     * const tiene = await validarDependencias(
     *   'empresas',
     *   1,
     *   [
     *     { tabla: 'sucursales', campoFk: 'empresa_id' },
     *     { tabla: 'empresas_nits', campoFk: 'empresa_id' },
     *      { tabla: 'empresas_cuentas', campoFk: 'empresa_id' },
     *     { tabla: 'empresas_news', campoFk: 'empresa_base_id' }
     *   ],
     *   'empresa_id' // fallback
     * );
     */
    async validarDependencias(
        tablaOrigen: string,
        pkId: number,
        tablasDependientes: Array<string | { tabla: string; campoFk: string }>,
        campoFkDefault: string,
    ): Promise<boolean> {
        // 1. Validaciones básicas.
        if (!tablasDependientes || tablasDependientes.length === 0) {
            return false;
        }

        if (!pkId || pkId <= 0) {
            throw new DomainException(
                `El ID de registro proporcionado (${pkId}) es inválido para verificar dependencias en la tabla '${tablaOrigen}'. El ID debe ser un número entero positivo mayor a 0.`,
                {
                    httpStatus: HttpStatus.BAD_REQUEST,
                    tabla: tablaOrigen,
                    pkId,
                    motivo: 'ID_INVALIDO'
                }
            );
        }

        const pkNumber = Number(pkId);
        const tablaNormalizada = tablaOrigen.toLowerCase().trim();
        const estadosStr = ESTADOS_VIVOS.join(', ');

        // 2. Construir consulta.
        const subQueries = tablasDependientes.map((item) => {
            const tabla = typeof item === 'string' ? item : item.tabla;
            const fk = typeof item === 'string' ? campoFkDefault : item.campoFk;

            const tablaSanitizada = this.dataSource.escapeIdentifier(tabla);
            const fkSanitizado = this.dataSource.escapeIdentifier(fk);

            return `
                SELECT '${tabla}' AS tabla_dep, COUNT(*) AS total
                FROM ${tablaSanitizada}
                WHERE ${fkSanitizado} = $1
                    AND estado_id IN (${estadosStr})
                    AND fecha_baja IS NULL
                GROUP BY 1
            `;
        });

        const unionQuery = subQueries.join(' UNION ALL ');

        // 3. Ejecutar consulta con caché (opcional).
        const cacheKey = `${tablaNormalizada}:${pkNumber}`;
        const cached = this.dependenciasCache.get(cacheKey);
        const now = Date.now();

        if (cached && (now - cached.timestamp < this.DEPENDENCIAS_CACHE_TTL_MS)) {
            this.logger.debug(`Usando caché de dependencias: ${cacheKey}`);
            return cached.tiene;
        }

        try {
            const resultados = await this.dataSource.query(unionQuery, [pkNumber]);
            const tieneDependencias = resultados.some(
                (res: any) => Number(res.total || 0) > 0
            );

            // 4. Guardar en caché.
            this.dependenciasCache.set(cacheKey, {
                tiene: tieneDependencias,
                timestamp: now
            });

            this.logger.debug(
                `Dependencias para ${tablaNormalizada}#${pkNumber}: ${tieneDependencias ? 'Tiene' : 'No tiene'} ` +
                `(estados: ${estadosStr})`
            );

            return tieneDependencias;
        } catch (error) {
            const errorMessage = getErrorMessage(error);

            this.logger.error(
                `Error verificando dependencias para ${tablaNormalizada}#${pkNumber}: ${errorMessage}`,
                getErrorStack(error)
            );

            const tablasDependientesStr = tablasDependientes
                .map(item => typeof item === 'string' ? item : `${item.tabla}(${item.campoFk})`)
                .join(', ');

            throw new DomainException(
                `Error interno al verificar dependencias para la tabla '${tablaNormalizada}' con ID = ${pkNumber}. Tablas dependientes verificadas: [${tablasDependientesStr}]. Detalle técnico: ${errorMessage}. Por favor, contacte al administrador del sistema.`,
                {
                    tablaOrigen: tablaNormalizada,
                    pkId: pkNumber,
                    tablasDependientes: tablasDependientesStr,
                    originalError: errorMessage,
                    httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                }
            );
        }
    }

    // Invalidar caché de dependencias.
    invalidarDependenciasCache(tablaOrigen?: string, pkId?: number): void {
        if (tablaOrigen && pkId) {
            const key = `${tablaOrigen.toLowerCase().trim()}:${Number(pkId)}`;
            this.dependenciasCache.delete(key);
            this.logger.debug(`Caché de dependencias invalidado: ${key}`);
        } else if (tablaOrigen) {
            const prefix = `${tablaOrigen.toLowerCase().trim()}:`;
            for (const key of this.dependenciasCache.keys() || []) {
                if (key.startsWith(prefix)) {
                    this.dependenciasCache.delete(key);
                }
            }
            this.logger.debug(`Caché de dependencias invalidado para ${tablaOrigen}`);
        } else {
            this.dependenciasCache.clear();
            this.logger.debug('Caché de dependencias limpiado completamente.');
        }
    }

    async validarPermisoTabla(
        usuarioId: number,
        tabla: string,
        accion: string,
        eventos?: number[],
    ): Promise<boolean> {
        if (!usuarioId || usuarioId <= 0) {
            throw new DomainException(
                `El ID de usuario proporcionado (${usuarioId}) es inválido. El ID debe ser un número entero positivo.`,
                {
                    httpStatus: HttpStatus.BAD_REQUEST,
                    usuarioId,
                }
            );
        }

        const tablaNormalizada = tabla.toLowerCase().trim();
        const accionNormalizada = accion.toLowerCase().trim();

        const columnasPermisoMap: Record<string, string> = {
            leer: 'rpt.leer',
            crear: 'rpt.crear',
            editar: 'rpt.editar',
            eliminar: 'rpt.eliminar',
            anular: 'rpt.anular',
            archivar: 'rpt.archivar',
            desarchivar: 'rpt.desarchivar',
        };

        const columnaPermiso = columnasPermisoMap[accionNormalizada];
        const accionesValidas = Object.keys(columnasPermisoMap).join(', ');

        if (!columnaPermiso) {
            throw new DomainException(
                `La acción "${accion}" no es válida para la validación de permisos. Las acciones permitidas son: ${accionesValidas}.`,
                {
                    httpStatus: HttpStatus.BAD_REQUEST,
                    accion,
                    accionesPermitidas: accionesValidas,
                }
            );
        }

        const cacheKey = `${usuarioId}:${tablaNormalizada}:${accionNormalizada}`;
        const cached = this.permisoCache.get(cacheKey);
        const now = Date.now();

        if (cached && (now - cached.timestamp < this.PERMISO_CACHE_TTL_MS)) {
            this.logger.debug(`Usando caché de permiso: ${cacheKey}`);

            if (!cached.tienePermiso) {
                const eventosStr = eventos && eventos.length > 0
                    ? ` para los eventos: ${eventos.join(', ')}`
                    : '';
                throw new DomainException(
                    `Acceso denegado: El usuario con ID ${usuarioId} no tiene permiso de "${accionNormalizada}"${eventosStr} en la tabla "${tablaNormalizada}". Contacte al administrador del sistema para solicitar los permisos necesarios.`,
                    {
                        httpStatus: HttpStatus.FORBIDDEN,
                        usuarioId,
                        tabla: tablaNormalizada,
                        accion: accionNormalizada,
                        eventos,
                    }
                );
            }
            return true;
        }

        const query = `
            SELECT
                ${columnaPermiso} AS tiene_permiso,
                u.login,
                COALESCE(
                    ARRAY_AGG(rps.suceso_id) FILTER (WHERE rps.suceso_id IS NOT NULL),
                    ARRAY[]::integer[]
                ) AS eventos_permitidos
            FROM usuarios u
            INNER JOIN roles r ON r.rol_id = u.rol_id AND r.estado_id = $3
            INNER JOIN roles_permisos_tablas rpt ON rpt.rol_id = r.rol_id AND rpt.estado_id = $3
            INNER JOIN tablas t ON t.tabla_id = rpt.tabla_id AND t.estado_id = $3
            LEFT JOIN roles_permisos_sucesos rps ON rps.rol_permiso_tabla_id = rpt.rol_permiso_tabla_id AND rps.estado_id = $3
            WHERE u.usuario_id = $1
                AND t.nombre = $2
                AND u.estado_id = ANY($4::int[])
            GROUP BY u.usuario_id, u.login, ${columnaPermiso}
            LIMIT 1
        `;

        const params = [Number(usuarioId), tablaNormalizada, ESTADO_ACTIVO, ESTADOS_VIVOS];
        logSqlQuery(query, params, `validarPermisoTabla - roles_permisos_tablas`);

        try {
            const permisosRes = await this.dataSource.query(query, params);

            const tienePermiso = permisosRes?.[0]?.tiene_permiso === 1;

            this.permisoCache.set(cacheKey, { tienePermiso, timestamp: now });

            if (!tienePermiso || !permisosRes || permisosRes.length === 0) {
                const eventosStr = eventos && eventos.length > 0
                    ? ` para los eventos: ${eventos.join(', ')}`
                    : '';
                throw new DomainException(
                    `Acceso denegado: El usuario con ID ${usuarioId} no tiene permiso de "${accionNormalizada}"${eventosStr} en la tabla "${tablaNormalizada}". Contacte al administrador del sistema para solicitar los permisos necesarios.`,
                    {
                        httpStatus: HttpStatus.FORBIDDEN,
                        usuarioId,
                        tabla: tablaNormalizada,
                        accion: accionNormalizada,
                        eventos,
                        motivo: 'PERMISO_DENEGADO'
                    }
                );
            }

            const login = permisosRes[0].login || `ID #${usuarioId}`;

            if (tablaNormalizada === 'kardex' && eventos && eventos.length > 0) {
                await this.validarEventosKardex(
                    eventos,
                    permisosRes[0],
                    accionNormalizada,
                    usuarioId,
                    tablaNormalizada,
                    login
                );
            }

            return true;

        } catch (error) {
            if (isDomainException(error)) throw error;

            const errorMessage = getErrorMessage(error);
            this.logger.error(
                `Error validando permiso para ${tablaNormalizada}#${accionNormalizada} (usuario ${usuarioId}): ${errorMessage}`,
                getErrorStack(error)
            );

            throw new DomainException(
                `Error interno al validar permisos del usuario con ID ${usuarioId} para la acción "${accionNormalizada}" en la tabla "${tablaNormalizada}". Detalle técnico: ${errorMessage}. Por favor, contacte al administrador del sistema.`,
                {
                    httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
                    usuarioId,
                    tabla: tablaNormalizada,
                    accion: accionNormalizada,
                    eventos,
                    originalError: errorMessage
                }
            );
        }
    }

    private async validarEventosKardex(
        eventos: number[],
        permiso: any,
        accion: string,
        usuarioId: number,
        tabla: string,
        login: string
    ): Promise<void> {
        const listaPermitida = permiso.eventos_permitidos || [];
        const eventosNoPermitidos = eventos.filter(ev => !listaPermitida.includes(ev));

        if (eventosNoPermitidos.length > 0) {
            throw new DomainException(
                `Acceso denegado: El usuario "${login}" no tiene permisos para realizar "${accion}" sobre los eventos: ${eventosNoPermitidos.join(', ')}.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    usuarioId,
                    login,
                    tabla,
                    accion,
                    eventosNoPermitidos,
                    eventosPermitidos: listaPermitida,
                    motivo: 'EVENTOS_NO_PERMITIDOS_EN_KARDEX'
                }
            );
        }
    }

    invalidarPermisoCache(usuarioId?: number, tabla?: string): void {
        if (usuarioId && tabla) {
            const prefix = `${Number(usuarioId)}:${tabla.toLowerCase().trim()}:`;
            for (const key of this.permisoCache.keys()) {
                if (key.startsWith(prefix)) {
                    this.permisoCache.delete(key);
                }
            }
            this.logger.debug(`Caché invalidado para usuario ${usuarioId} y tabla "${tabla.toLowerCase().trim()}".`);
        } else if (usuarioId) {
            const prefix = `${Number(usuarioId)}:`;
            for (const key of this.permisoCache.keys()) {
                if (key.startsWith(prefix)) {
                    this.permisoCache.delete(key);
                }
            }
            this.logger.debug(`Caché invalidado para usuario ${usuarioId}.`);
        } else {
            this.permisoCache.clear();
            this.logger.debug('Caché de permisos limpiado completamente.');
        }
    }

    async esUsuarioAdministrador(usuarioId: number): Promise<boolean> {
        const res = await this.dataSource.query(
            `SELECT 1
            FROM usuarios u
            INNER JOIN roles r ON u.rol_id = r.rol_id
            WHERE u.usuario_id = $1
            AND u.estado_id = $2
            AND r.estado_id = $2
            AND (r.codigo = 'ADM' OR r.rol_id = 2)
            LIMIT 1`,
            [usuarioId, ESTADO_ACTIVO]
        );
        return res.length > 0;
    }

    async procesarCamposProtegidos<T extends object>(
        tabla: string,
        id: number,
        dto: T,
        dependencias: Array<string | { tabla: string; campoFk: string }>,
        camposProtegidos: string[],
        campoPk: string,
        usuarioId: number
    ): Promise<T> {
        const tieneDependencias = await this.validarDependencias(tabla, id, dependencias, campoPk);
        if (!tieneDependencias) return dto;

        const esAdmin = await this.esUsuarioAdministrador(usuarioId);
        if (esAdmin) {
            this.logger.warn(
                `[BYPASS ADMIN] El usuario_id=${usuarioId} está modificando campos protegidos (${camposProtegidos.join(', ')}) en la tabla "${tabla}" id=${id} que posee dependencias activas.`
            );
            return dto;
        }

        const dtoFiltrado = { ...dto };
        camposProtegidos.forEach(campo => {
            if (campo in dtoFiltrado) {
                delete (dtoFiltrado as any)[campo];
            }
        });

        return dtoFiltrado;
    }
}
