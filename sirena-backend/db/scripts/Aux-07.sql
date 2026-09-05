// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts
// ==========================================
// INTERFAZ GENERAL PARA CONSTANTES PARAMÉTRICOS
// ==========================================
export interface ConstanteMetadata {
    id: number;
    abreviatura: string;
    prefijo: string | null;
    valor: number;
    descripcion: string;
}

// ==========================================
// ESTADO
// ==========================================
export enum Estado {
    ACTIVO = 1000,
    BORRADO = 1001,
    HISTORICO = 1002,
    ANULADO = 1003,
}

export const ESTADO_ACTIVO = Estado.ACTIVO;
export const ESTADO_HISTORICO = Estado.HISTORICO;
export const ESTADO_BORRADO = Estado.BORRADO;
export const ESTADO_ANULADO = Estado.ANULADO;

export const ESTADOS_CONSULTA = [
    Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_PERMITIDOS = [
    Estado.ACTIVO,
    Estado.BORRADO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_VIVOS = [
    Estado.ACTIVO,
    Estado.HISTORICO
	] as const;

export const ESTADOS_VIVOS_ESPECIAL = [
Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO
] as const;

export const ESTADO_METADATA: Record<Estado, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Estado.ACTIVO]: { id: Estado.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Estado.BORRADO]: { id: Estado.BORRADO, abreviatura: 'BORRADO', prefijo: null, valor: 0, descripcion: 'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.' },
    [Estado.HISTORICO]: { id: Estado.HISTORICO, abreviatura: 'HISTORICO', prefijo: null, valor: 0, descripcion: 'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.' },
    [Estado.ANULADO]: { id: Estado.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.' },
};


en validarPermisoTabla( no usar 1000, 1002 se debe usar estados.constant.ts 
async validarPermisoTabla(
        usuarioId: number,
        tabla: string,
        accion: string,
        eventos?: number[],
    ): Promise<boolean> {
        // 1. Validaciones básicas.
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

        // 2. Mapeo de acciones a columnas de roles_permisos_tablas.
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

        // 3. Verificar caché (mejora de rendimiento).
        const cacheKey = `${usuarioId}:${tablaNormalizada}:${accionNormalizada}`;
        const cached = this.permisoCache.get(cacheKey);
        const now = Date.now();

        if (cached && (now - cached.timestamp < this.PERMISO_CACHE_TTL_MS)) {
            this.logger.debug(`Usando caché de permiso: ${cacheKey}`);

            if (!cached.tienePermiso) {
                const eventosStr = eventos && eventos.length > 0 ? ` para los eventos: ${eventos.join(', ')}` : '';
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

        // 4. Consulta optimizada utilizando roles_permisos_tablas, tablas y roles_permisos_sucesos.
        const query = `
            SELECT
                ${columnaPermiso} AS tiene_permiso,
                u.login,
                COALESCE(
                    ARRAY_AGG(rps.suceso_id) FILTER (WHERE rps.suceso_id IS NOT NULL),
                    ARRAY[]::integer[]
                ) AS eventos_permitidos
            FROM usuarios u
            INNER JOIN roles r ON r.rol_id = u.rol_id AND r.estado_id = 1000
            INNER JOIN roles_permisos_tablas rpt ON rpt.rol_id = r.rol_id AND rpt.estado_id = 1000
            INNER JOIN tablas t ON t.tabla_id = rpt.tabla_id AND t.estado_id = 1000
            LEFT JOIN roles_permisos_sucesos rps ON rps.rol_permiso_tabla_id = rpt.rol_permiso_tabla_id AND rps.estado_id = 1000
            WHERE u.usuario_id = $1
                AND t.nombre = $2
                AND u.estado_id IN (1000, 1002)
            GROUP BY u.usuario_id, u.login, ${columnaPermiso}
            LIMIT 1
        `;

        const params = [Number(usuarioId), tablaNormalizada];
        logSqlQuery(query, params, `validarPermisoTabla - roles_permisos_tablas`);

        try {
            const permisosRes = await this.dataSource.query(query, params);

            // 5. Validar resultado y guardar en caché.
            const tienePermiso = permisosRes?.[0]?.tiene_permiso === 1;

            // Guardar en caché (tanto positivo como negativo).
            this.permisoCache.set(cacheKey, { tienePermiso, timestamp: now });

            if (!tienePermiso || !permisosRes || permisosRes.length === 0) {
                const eventosStr = eventos && eventos.length > 0 ? ` para los eventos: ${eventos.join(', ')}` : '';
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

            // 6. Validación específica para Kardex (extraída para claridad).
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
	
	
SOLUCION 
async validarPermisoTabla(
    usuarioId: number,
    tabla: string,
    accion: string,
    eventos?: number[],
): Promise<boolean> {
    // 1. Validaciones básicas.
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

    // 2. Mapeo de acciones a columnas de roles_permisos_tablas.
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

    // 3. Verificar caché (mejora de rendimiento).
    const cacheKey = `${usuarioId}:${tablaNormalizada}:${accionNormalizada}`;
    const cached = this.permisoCache.get(cacheKey);
    const now = Date.now();

    if (cached && (now - cached.timestamp < this.PERMISO_CACHE_TTL_MS)) {
        this.logger.debug(`Usando caché de permiso: ${cacheKey}`);

        if (!cached.tienePermiso) {
            const eventosStr = eventos && eventos.length > 0 ? ` para los eventos: ${eventos.join(', ')}` : '';
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

    // 4. Consulta optimizada utilizando roles_permisos_tablas, tablas y roles_permisos_sucesos (con constantes de estado).
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

    const params = [
        Number(usuarioId),
        tablaNormalizada,
        Estado.ACTIVO,
        [Estado.ACTIVO, Estado.HISTORICO]
    ];
    logSqlQuery(query, params, `validarPermisoTabla - roles_permisos_tablas`);

    try {
        const permisosRes = await this.dataSource.query(query, params);

        // 5. Validar resultado y guardar en caché.
        const tienePermiso = permisosRes?.[0]?.tiene_permiso === 1;

        // Guardar en caché (tanto positivo como negativo).
        this.permisoCache.set(cacheKey, { tienePermiso, timestamp: now });

        if (!tienePermiso || !permisosRes || permisosRes.length === 0) {
            const eventosStr = eventos && eventos.length > 0 ? ` para los eventos: ${eventos.join(', ')}` : '';
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

        // 6. Validación específica para Kardex (extraída para claridad).
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

LA SOLUCION ES CORRECTA 
