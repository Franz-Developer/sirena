Lista de Observaciones y Recomendaciones
1. Seguridad: Validación de Permisos por Tabla (Posible Bypass)
    Archivo(s): tabla-validador.service.ts
    Observación: En validarPermisoTabla, el caché de permisos (permisoCache) se usa con un TTL. Si un administrador cambia los permisos de un usuario, el cambio no se reflejará hasta que el caché expire.
    Sugerencia: Es una decisión de dise?o, pero para un sistema que maneja permisos de seguridad, el caché es arriesgado. Si se decide mantener, la función invalidarPermisoCache debería llamarse siempre que se actualice la tabla roles_tablas. Sin esta invalidación activa, hay un riesgo real de que un usuario tenga permisos que ya no debería tener, o viceversa.

12. Transacciones y Concurrencia: runInTransaction
    Archivo(s): transaction.helper.ts
    Observación: La función runInTransaction es robusta, usa el dataSource.transaction y tiene un intento de reintento en runInTransactionWithRetry.
    Sugerencia: runInTransactionWithRetry es una excelente práctica, pero se debe considerar que un deadlock puede ser un síntoma de un problema de dise?o mayor. Es una buena solución para manejar conflictos de concurrencia.

13. Código: Orden de los Imports
    Archivo(s): Varios.
    Observación: En algunos archivos, los imports no están ordenados de forma consistente, alternando entre absolutos y relativos.
    Sugerencia: No afecta la funcionalidad, pero configurar un linter (como ESLint con import/order) ayuda a mantener un código más limpio.


🟢 TABLAS CON CACHÉ RECOMENDADO
| Tabla                  | Razón                                      | TTL sugerido |
+ ---------------------- + ------------------------------------------ + ------------ +
| alertas_notificaciones | Solo para consultas de bandeja             |        5 min |
| bancos                 | Catálogo de bancos, cambia muy poco        |         24 h |
| cargos                 | Catálogo de cargos                         |         24 h |
| categorias             | Categorías de productos                    |         24 h |
| concentraciones        | Concentraciones de principios activos      |         24 h |
| empresas               | Datos corporativos, cambian raramente      |         24 h |
| empresas_cuentas       | Cuentas bancarias de la empresa            |         12 h |
| empresas_nits          | NITs y configuraciones fiscales            |         12 h |
| especialidades         | Especialidades médicas                     |         24 h |
| formas                 | Formas farmacéuticas                       |         24 h |
| instituciones          | Instituciones médicas                      |         24 h |
| laboratorios           | Laboratorios farmacéuticos                 |         24 h |
| listas_precios         | Listas de precios                          |          6 h |
| marcas                 | Marcas comerciales                         |         24 h |
| menus                  | Estructura de menús                        |         24 h |
| modelos                | Modelos de IA disponibles                  |         12 h |
| parametros_globales    | Configuraciones del sistema                |          1 h |
| politicas_precios      | Políticas de precios                       |          6 h |
| principios_activos     | Principios activos                         |         24 h |
| presentaciones         | Presentaciones comerciales                 |         24 h |
| puntos_venta           | Puntos de venta por sucursal               |         24 h |
| rangos_edad            | Rangos etarios                             |         24 h |
| roles                  | Roles del sistema                          |         24 h |
| sucursales             | Catálogo de sucursales                     |         24 h |
| tipos_cambios          | Tasas de cambio, se actualizan diariamente |          1 h |
| tipos_planes_pago      | Tipos de planes de pago                    |         24 h |
| unidades               | Unidades de medida                         |         24 h |
| vias                   | Vías de administración                     |         24 h |

🟡 TABLAS CON CACHÉ PARCIAL
| Tabla            | Estrategia                             | TTL    |
+ ---------------- + -------------------------------------- + ------ +
| clientes         | Caché por ID para clientes frecuentes  | 15 min |
| control_facturas | Último número de factura               |  1 min |
| cufd             | CUFD activo por sucursal               |    1 h |
| cuis             | CUIS activo por sucursal               |    1 h |
| medicos          | Caché por ID                           |    1 h |
| productos        | Caché por ID para productos populares  | 30 min |
| proveedores      | Caché por ID                           |    1 h |
| trabajadores     | Caché por ID para consultas frecuentes |    1 h |
| usuarios         | Caché de sesión (login)                |  5 min |

🔴 TABLAS SIN CACHÉ
| Tabla                        | Razón                                        |
+ ---------------------------- + -------------------------------------------- +
| almacenes                    | Catálogo de almacenes                        |
| almacenes_puntos_venta       | Relación almacén-punto venta                 |
| analitica_productos          | Datos calculados, consulta pesada            |
| arqueos_detalle              | Solo durante arqueos                         |
| asistencias                  | Marcaciones en tiempo real                   |
| cajas                        | Estado de caja en tiempo real                |
| carritos_compra              | Por usuario y en tiempo real                 |
| comprobantes_pagos           | Transacciones financieras                    |
| contratos                    | Cambios esporádicos                          |
| conversiones_unidad          | Conversiones de unidades                     |
| costos_promedio              | Cálculos diarios                             |
| detalles_carritos            | Depende de carritos                          |
| detalles_pedidos_online      | Depende de pedidos                           |
| entrenamientos               | Procesos batch                               |
| equivalentes                 | Catálogo de sustitutos                       |
| historicos                   | Inmutable, solo consulta                     |
| inventarios_fisicos          | Procesos puntuales                           |
| inventarios_fisicos_detalle  | Depende del inventario físico                |
| kardex                       | Movimientos constantes, datos en tiempo real |
| kardex_productos             | Detalle de movimientos, cambios constantes   |
| logs_ejecucion               | Solo escritura, grandes volúmenes            |
| lotes_productos              | Stock cambia constantemente                  |
| metricas_rendimiento         | Solo consulta para reportes                  |
| movimientos                  | Transacciones de caja                        |
| ordenes_compra               | Estado cambia frecuentemente                 |
| patrones_consumo             | Actualización periódica                      |
| pedidos_online               | Estado cambia constantemente                 |
| planillas                    | Cálculos mensuales                           |
| planillas_detalle            | Depende de planillas                         |
| precios_productos            | Precios cambian frecuentemente               |
| productos_controlados        | Control de sustancias                        |
| productos_principios         | Relación producto-principio activo           |
| productos_rangos_edad        | Relación producto-rango edad                 |
| productos_ubicaciones        | Cambios constantes por movimientos           |
| productos_vias               | Relación producto-vía                        |
| promociones                  | Cambios esporádicos                          |
| promociones_productos        | Depende de promociones                       |
| proveedores_contactos        | Contactos de proveedores                     |
| proveedores_rating_historico | Historial de ratings                         |
| recetas                      | Datos sensibles y cambiantes                 |
| registros_sanitarios         | Registros sanitarios                         |
| roles_menus                  | Permisos de menús                            |
| roles_tablas                 | Permisos de roles                            |
| tareas_programadas           | Configuración de tareas                      |
| trabajadores_cargos          | Relación trabajador-cargo                    |
| ubicaciones                  | Stock actual cambia constantemente           |
| ubicaciones_historial        | Auditoría, solo escritura                    |
| ubicaciones_movimientos      | Registro de movimientos                      |
| umbrales_configuracion       | Cambios esporádicos                          |
| variables_exogenas           | Datos externos variables                     |

-- ANTES 
CREATE TABLE configuraciones (
    configuracion_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
    formato_pdf_id INTEGER NOT NULL DEFAULT 1950,  		-- 1950=ESTANDAR, 1951=RESUMIDO, 1952=DETALLADO
    pie_pagina VARCHAR(500) NULL,
    logo_secundario VARCHAR(255) NULL,
    mensaje_agradecimiento VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_configuraciones_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT chk_configuraciones_formatopdfid CHECK (formato_pdf_id IN (1950, 1951, 1952)),
    CONSTRAINT chk_configuraciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_configuraciones_piepagina_notempty CHECK (pie_pagina IS NULL OR TRIM(pie_pagina) <> ''),
    CONSTRAINT chk_configuraciones_piepagina CHECK (pie_pagina IS NULL OR LENGTH(TRIM(pie_pagina)) >= 3),
    CONSTRAINT chk_configuraciones_logosecundario_notempty CHECK (logo_secundario IS NULL OR TRIM(logo_secundario) <> ''),
    CONSTRAINT chk_configuraciones_logosecundario_minlength CHECK (logo_secundario IS NULL OR LENGTH(TRIM(logo_secundario)) >= 3),
    CONSTRAINT chk_configuraciones_mensajeagradecimiento_notempty CHECK (mensaje_agradecimiento IS NULL OR TRIM(mensaje_agradecimiento) <> ''),
    CONSTRAINT chk_configuraciones_mensajeagradecimiento CHECK (mensaje_agradecimiento IS NULL OR LENGTH(TRIM(mensaje_agradecimiento)) >= 3)
);
CREATE UNIQUE INDEX uix_configuraciones_empresaid_unique ON configuraciones (empresa_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE configuraciones IS 'Reglas de la tabla - configuraciones
R.0: La tabla configuraciones almacena las preferencias de personalización de la interfaz de usuario para cada empresa, como el formato de los PDFs de facturación y los mensajes de agradecimiento. Su propósito es permitir la customización de la imagen corporativa y el formato de los documentos emitidos, mejorando la experiencia del cliente y la uniformidad de la marca.
R.1: Cada empresa puede tener una única configuración de facturación activa o histórica, garantizada por el índice único uix_cfg_empresa_unique.
R.2: pie_pagina almacena el texto que aparecerá al final de cada página del documento fiscal. Es opcional y debe tener al menos 3 caracteres si se especifica.
R.3: logo_secundario almacena únicamente el nombre del archivo y su extensión (ej. ''logo_secundario.png''). La resolución de la URL absoluta para el renderizado en el frontend se realiza mediante variable de entorno. Sigue la regla R.G.4 para el reemplazo controlado de archivos multimedia.
R.4: mensaje_agradecimiento almacena el texto de agradecimiento que aparecerá al final del documento fiscal. Es opcional y debe tener al menos 3 caracteres si se especifica.
R.5: Solo puede existir un único registro en estado ACTIVO por empresa_id. Al crear una nueva configuración, la anterior debe pasar automáticamente a estado HISTORICO para preservar la trazabilidad de los cambios en el formato de facturación.';

-- ================================================================================================
-- FALTA 

5. CacheService - Memoria sin límite de tiempo
typescript

// El Map no tiene límite de tiempo automático
private readonly cache = new Map<string, CacheEntry>();

// Sugerido: Agregar cleaner periódico
setInterval(() => this.cleanExpired(), 60000); // Limpiar cada minuto esto donde

- import { Injectable, Logger } from '@nestjs/common';
+ import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';

- export class CacheService implements ICacheService {
+ export class CacheService implements ICacheService, OnModuleDestroy {

    private readonly defaultTtl: number;
    private readonly maxSize: number;
+   private readonly cleanupInterval: number;
+   private cleanupTimer: NodeJS.Timeout | null = null;

    constructor() {
        this.defaultTtl = parseInt(process.env['CACHE_TTL'] ?? '300000', 10);
        this.maxSize = parseInt(process.env['CACHE_MAX_SIZE'] ?? '1000', 10);
+       this.cleanupInterval = parseInt(process.env['CACHE_CLEANUP_INTERVAL'] ?? '60000', 10);
+       this.startCleanupTimer();
+       this.logger.log(`CacheService inicializado...`);
    }

+   private startCleanupTimer(): void {
+       if (this.cleanupTimer) {
+           clearInterval(this.cleanupTimer);
+       }
+       this.cleanupTimer = setInterval(() => {
+           this.cleanExpired();
+       }, this.cleanupInterval);
+       if (this.cleanupTimer.unref) {
+           this.cleanupTimer.unref();
+       }
+   }

+   private cleanExpired(): void {
+       const now = Date.now();
+       let expiredCount = 0;
+       for (const [key, entry] of this.cache.entries()) {
+           if (now - entry.timestamp > this.defaultTtl) {
+               this.cache.delete(key);
+               expiredCount++;
+           }
+       }
+       if (expiredCount > 0) {
+           this.logger.debug(`🧹 Limpiadas ${expiredCount} entradas expiradas`);
+       }
+   }

+   onModuleDestroy(): void {
+       if (this.cleanupTimer) {
+           clearInterval(this.cleanupTimer);
+           this.cleanupTimer = null;
+           this.logger.debug('Timer de limpieza de caché detenido.');
+       }
+   }
}
