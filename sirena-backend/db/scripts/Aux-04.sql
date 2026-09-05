INSERT INTO tablas (tabla_id, nombre, estado_id, usuario_id_registro) VALUES
(1, 'ninguno', 1000, 1),
(2, 'alertas_notificaciones', 1000, 2),
(3, 'almacenes', 1000, 2),
(4, 'almacenes_puntos_venta', 1000, 2),
(5, 'analitica_productos', 1000, 2),
(6, 'arqueos_detalle', 1000, 2),
(7, 'asistencias', 1000, 2),
(8, 'bancos', 1000, 2),
(9, 'cajas', 1000, 2),
(10, 'cargos', 1000, 2),
(11, 'carritos_compra', 1000, 2),
(12, 'categorias', 1000, 2),
(13, 'clientes', 1000, 2),
(14, 'comprobantes_pagos', 1000, 2),
(15, 'concentraciones', 1000, 2),
(16, 'contratos', 1000, 2),
(17, 'control_facturas', 1000, 2),
(18, 'conversiones_unidad', 1000, 2),
(19, 'costos_promedio', 1000, 2),
(20, 'cufd', 1000, 2),
(21, 'cuis', 1000, 2),
(22, 'detalles_carritos', 1000, 2),
(23, 'detalles_pedidos_online', 1000, 2),
(24, 'empresas', 1000, 2),
(25, 'empresas_cuentas', 1000, 2),
(26, 'empresas_nits', 1000, 2),
(27, 'entrenamientos', 1000, 2),
(28, 'equivalentes', 1000, 2),
(29, 'especialidades', 1000, 2),
(30, 'formas', 1000, 2),
(31, 'historicos', 1000, 2),
(32, 'instituciones', 1000, 2),
(33, 'inventarios_fisicos', 1000, 2),
(34, 'inventarios_fisicos_detalle', 1000, 2),
(35, 'kardex', 1000, 2),
(36, 'kardex_productos', 1000, 2),
(37, 'laboratorios', 1000, 2),
(38, 'listas_precios', 1000, 2),
(39, 'logs_ejecucion', 1000, 2),
(40, 'lotes_productos', 1000, 2),
(41, 'marcas', 1000, 2),
(42, 'medicos', 1000, 2),
(43, 'menus', 1000, 2),
(44, 'metricas_rendimiento', 1000, 2),
(45, 'modelos', 1000, 2),
(46, 'movimientos', 1000, 2),
(47, 'ordenes_compra', 1000, 2),
(48, 'pagos', 1000, 2),
(49, 'parametros_globales', 1000, 2),
(50, 'patrones_consumo', 1000, 2),
(51, 'pedidos_online', 1000, 2),
(52, 'planes_pagos', 1000, 2),
(53, 'planillas', 1000, 2),
(54, 'planillas_detalle', 1000, 2),
(55, 'politicas_precios', 1000, 2),
(56, 'precios_productos', 1000, 2),
(57, 'presentaciones', 1000, 2),
(58, 'principios_activos', 1000, 2),
(59, 'productos', 1000, 2),
(60, 'productos_controlados', 1000, 2),
(61, 'productos_principios', 1000, 2),
(62, 'productos_rangos_edad', 1000, 2),
(63, 'productos_ubicaciones', 1000, 2),
(64, 'productos_vias', 1000, 2),
(65, 'promociones', 1000, 2),
(66, 'promociones_productos', 1000, 2),
(67, 'proveedores', 1000, 2),
(68, 'proveedores_contactos', 1000, 2),
(69, 'proveedores_rating_historico', 1000, 2),
(70, 'puntos_venta', 1000, 2),
(71, 'rangos_edad', 1000, 2),
(72, 'recetas', 1000, 2),
(73, 'registros_sanitarios', 1000, 2),
(74, 'roles', 1000, 2),
(75, 'roles_menus', 1000, 2),
(76, 'roles_tablas', 1000, 2),
(77, 'sucursales', 1000, 2),
(78, 'tablas', 1000, 2),
(79, 'tareas_programadas', 1000, 2),
(80, 'tipos_cambios', 1000, 2),
(81, 'tipos_planes_pago', 1000, 2),
(82, 'trabajadores', 1000, 2),
(83, 'trabajadores_cargos', 1000, 2),
(84, 'ubicaciones', 1000, 2),
(85, 'ubicaciones_historial', 1000, 2),
(86, 'ubicaciones_movimientos', 1000, 2),
(87, 'umbrales_configuracion', 1000, 2),
(88, 'unidades', 1000, 2),
(89, 'usuarios', 1000, 2),
(90, 'variables_exogenas', 1000, 2),
(91, 'vias', 1000, 2);


como hago para que insert into el rol_id=5 tenga todos los permisos 
para todas las tablas 
-- ================================================================================================
-- OTORGAR TODOS LOS PERMISOS EN LA TABLA 'bancos' AL ROL COMPRADOR (rol_id = 5)
-- ================================================================================================


DELETE FROM roles_permisos_tablas;
ALTER SEQUENCE roles_permisos_tablas_rol_permiso_tabla_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - TODOS LOS PERMISOS EN 0
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 1, t.tabla_id, 1, 0, 0, 0, 0, 0, 0, 1000, 1 
FROM tablas t 
WHERE t.estado_id = 1000;

-- ROL: ADMINISTRADOR (rol_id = 2) - PERMISOS GENERALES Y RESTRICCIONES CRÍTICAS
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    2,
    t.tabla_id,
    1, 1, 1, 1, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END, 
    1, 1,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre NOT IN ('roles_permisos_tablas', 'ninguno');

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    3,
    t.tabla_id,
    1, 0, 0, 0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre NOT IN ('roles_permisos_tablas', 'ninguno');

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - OPERATIVO CON RESTRICCIONES
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    4,
    t.tabla_id,
    1, 1, 1, 1, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre NOT IN ('roles_permisos_tablas', 'ninguno');

-- ROL: COMPRADOR (rol_id = 5) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    5,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('proveedores', 'proveedores_contactos', 'ordenes_compra', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos') THEN 1
        WHEN t.nombre IN ('proveedores_rating_historico', 'parametros_globales', 'tareas_programadas') THEN 1
        WHEN t.nombre IN ('kardex', 'kardex_productos', 'lotes_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('proveedores', 'proveedores_contactos', 'ordenes_compra', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos') THEN 1
        WHEN t.nombre IN ('kardex', 'kardex_productos', 'lotes_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('proveedores', 'proveedores_contactos', 'ordenes_compra', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('proveedores', 'proveedores_contactos', 'proveedores_rating_historico', 'kardex', 'kardex_productos', 'lotes_productos', 'ordenes_compra', 'parametros_globales', 'tareas_programadas', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos');

-- ROL: VENDEDOR (rol_id = 6) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    6,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('clientes', 'productos', 'kardex', 'kardex_productos', 'lotes_productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos') THEN 1
        WHEN t.nombre IN ('listas_precios', 'precios_productos', 'politicas_precios', 'cajas', 'movimientos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('clientes', 'productos', 'kardex', 'kardex_productos', 'lotes_productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('clientes', 'productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('clientes', 'productos', 'kardex', 'kardex_productos', 'lotes_productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos', 'listas_precios', 'precios_productos', 'politicas_precios', 'cajas', 'movimientos');

-- ROL: ALMACENERO (rol_id = 7) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    7,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos_ubicaciones', 'kardex', 'lotes_productos', 'kardex_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos') THEN 1
        WHEN t.nombre IN ('productos', 'umbrales_configuracion', 'analitica_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos_ubicaciones', 'kardex', 'lotes_productos', 'kardex_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos_ubicaciones', 'lotes_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos', 'productos_ubicaciones', 'kardex', 'lotes_productos', 'kardex_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos', 'umbrales_configuracion', 'analitica_productos');

-- ROL: CAJERO (rol_id = 8) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    8,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle') THEN 1
        WHEN t.nombre IN ('control_facturas', 'bancos', 'listas_precios', 'precios_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('comprobantes_pagos', 'pagos', 'cajas', 'arqueos_detalle') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'control_facturas', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle', 'bancos', 'listas_precios', 'precios_productos');

SELECT setval('roles_permisos_tablas_rol_permiso_tabla_id_seq', COALESCE((SELECT MAX(rol_permiso_tabla_id) FROM roles_permisos_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_tablas));

-- ================================================================================================

DELETE FROM roles_permisos_sucesos;
ALTER SEQUENCE roles_permisos_sucesos_rol_permiso_suceso_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - SIN PERMISOS DE SUCESOS
-- No se insertan registros para NINGUNO

-- ROL: ADMINISTRADOR (rol_id = 2) - TODOS LOS SUCESOS PERMITIDOS
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 2
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA, SIN SUCESOS
-- No se insertan registros para GERENTE (solo lectura)

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - TODOS LOS SUCESOS PERMITIDOS
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 4
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: COMPRADOR (rol_id = 5) - SOLO SUCESOS DE COMPRA Y SOLICITUD_COMPRA
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 5
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1058)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: VENDEDOR (rol_id = 6) - SUCESOS DE VENTA, PROFORMA Y VENTA_RESERVA
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 6
AND t.nombre = 'kardex'
AND s.suceso_id IN (1051, 1052, 1059)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: ALMACENERO (rol_id = 7) - SUCESOS DE TRASPASOS, AJUSTES, INVENTARIO FISICO, ETC
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 7
AND t.nombre = 'kardex'
AND s.suceso_id IN (1053, 1054, 1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: CAJERO (rol_id = 8) - SOLO SUCESO DE VENTA
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 8
AND t.nombre = 'kardex'
AND s.suceso_id IN (1051)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

SELECT setval('roles_permisos_sucesos_rol_permiso_suceso_id_seq', COALESCE((SELECT MAX(rol_permiso_suceso_id) FROM roles_permisos_sucesos), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_sucesos));

-- ================================================================================================


INSERT INTO roles_permisos_tablas (
    rol_id,
    tabla_id,
    leer,
    crear,
    editar,
    eliminar,
    anular,
    archivar,
    desarchivar,
    estado_id,
    usuario_id_registro
)
SELECT
    5,                              -- ROL COMPRADOR
    t.tabla_id,                     -- ID de la tabla 'bancos'
    1,                              -- leer: SI
    1,                              -- crear: SI
    1,                              -- editar: SI
    1,                              -- eliminar: SI
    1,                              -- anular: SI
    1,                              -- archivar: SI
    1,                              -- desarchivar: SI
    1000,                           -- estado_id ACTIVO
    2                               -- usuario_id_registro (ADMIN otorga el permiso)
FROM tablas t
WHERE t.nombre = 'bancos'
AND t.estado_id = 1000
ON CONFLICT (rol_id, tabla_id) WHERE estado_id = 1000
DO UPDATE SET
    leer = 1,
    crear = 1,
    editar = 1,
    eliminar = 1,
    anular = 1,
    archivar = 1,
    desarchivar = 1,
    estado_id = 1000,
    usuario_id_actualizacion = 2,
    fecha_actualizacion = CURRENT_TIMESTAMP;
	
	
	
tambien quiero insert into roles_permisos_sucesos para rol_id=5 	