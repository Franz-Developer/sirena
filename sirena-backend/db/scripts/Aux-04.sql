TENGO 
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename ASC;

INSERT INTO pg_tables (tablename) VALUES
	 ('alertas_notificaciones'),
	 ('almacenes'),
	 ('almacenes_puntos_venta'),
	 ('analitica_productos'),
	 ('arqueos_detalle'),
	 ('asistencias'),
	 ('bancos'),
	 ('cajas'),
	 ('cargos'),
	 ('carritos_compra'),
	 ('categorias'),
	 ('clientes'),
	 ('comprobantes_pagos'),
	 ('concentraciones'),
	 ('contratos'),
	 ('control_facturas'),
	 ('conversiones_unidad'),
	 ('costos_promedio'),
	 ('cufd'),
	 ('cuis'),
	 ('detalles_carritos'),
	 ('detalles_pedidos_online'),
	 ('empresas'),
	 ('empresas_cuentas'),
	 ('empresas_nits'),
	 ('entrenamientos'),
	 ('equivalentes'),
	 ('especialidades'),
	 ('formas'),
	 ('historicos'),
	 ('instituciones'),
	 ('inventarios_fisicos'),
	 ('inventarios_fisicos_detalle'),
	 ('kardex'),
	 ('kardex_productos'),
	 ('laboratorios'),
	 ('listas_precios'),
	 ('logs_ejecucion'),
	 ('lotes_productos'),
	 ('marcas'),
	 ('medicos'),
	 ('menus'),
	 ('metricas_rendimiento'),
	 ('modelos'),
	 ('movimientos'),
	 ('ordenes_compra'),
	 ('pagos'),
	 ('parametros_globales'),
	 ('patrones_consumo'),
	 ('pedidos_online'),
	 ('planes_pagos'),
	 ('planillas'),
	 ('planillas_detalle'),
	 ('politicas_precios'),
	 ('precios_productos'),
	 ('presentaciones'),
	 ('principios_activos'),
	 ('productos'),
	 ('productos_controlados'),
	 ('productos_principios'),
	 ('productos_rangos_edad'),
	 ('productos_ubicaciones'),
	 ('productos_vias'),
	 ('promociones'),
	 ('promociones_productos'),
	 ('proveedores'),
	 ('proveedores_contactos'),
	 ('proveedores_rating_historico'),
	 ('puntos_venta'),
	 ('rangos_edad'),
	 ('recetas'),
	 ('registros_sanitarios'),
	 ('roles'),
	 ('roles_menus'),
	 ('roles_permisos_sucesos'),
	 ('roles_permisos_tablas'),
	 ('sucesos'),
	 ('sucursales'),
	 ('tablas'),
	 ('tareas_programadas'),
	 ('tipos_cambios'),
	 ('tipos_planes_pago'),
	 ('trabajadores'),
	 ('trabajadores_cargos'),
	 ('ubicaciones'),
	 ('ubicaciones_historial'),
	 ('ubicaciones_movimientos'),
	 ('umbrales_configuracion'),
	 ('unidades'),
	 ('usuarios'),
	 ('variables_exogenas'),
	 ('vias');

TODAS LAS TABLAS TIENE ESTOS CAMPOS EN COMUN 
usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
	
aqui falta alguna tabla 
static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'bancos', campoFk: 'usuario_id_registro' },
            { tabla: 'bancos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'bancos', campoFk: 'usuario_id_baja' },

            { tabla: 'tipos_cambios', campoFk: 'usuario_id_registro' },
            { tabla: 'tipos_cambios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tipos_cambios', campoFk: 'usuario_id_baja' },

            { tabla: 'empresas', campoFk: 'usuario_id_registro' },
            { tabla: 'empresas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'empresas', campoFk: 'usuario_id_baja' },

            { tabla: 'empresas_nits', campoFk: 'usuario_id_registro' },
            { tabla: 'empresas_nits', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'empresas_nits', campoFk: 'usuario_id_baja' },

            { tabla: 'empresas_cuentas', campoFk: 'usuario_id_registro' },
            { tabla: 'empresas_cuentas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'empresas_cuentas', campoFk: 'usuario_id_baja' },

            { tabla: 'sucursales', campoFk: 'usuario_id_registro' },
            { tabla: 'sucursales', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'sucursales', campoFk: 'usuario_id_baja' },

            { tabla: 'puntos_venta', campoFk: 'usuario_id_registro' },
            { tabla: 'puntos_venta', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'puntos_venta', campoFk: 'usuario_id_baja' },

            { tabla: 'cuis', campoFk: 'usuario_id_registro' },
            { tabla: 'cuis', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cuis', campoFk: 'usuario_id_baja' },

            { tabla: 'cufd', campoFk: 'usuario_id_registro' },
            { tabla: 'cufd', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cufd', campoFk: 'usuario_id_baja' },

            { tabla: 'unidades', campoFk: 'usuario_id_registro' },
            { tabla: 'unidades', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'unidades', campoFk: 'usuario_id_baja' },

            { tabla: 'almacenes', campoFk: 'usuario_id_registro' },
            { tabla: 'almacenes', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'almacenes', campoFk: 'usuario_id_baja' },

            { tabla: 'ubicaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'ubicaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ubicaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'almacenes_puntos_venta', campoFk: 'usuario_id_registro' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'usuario_id_baja' },

            { tabla: 'cargos', campoFk: 'usuario_id_registro' },
            { tabla: 'cargos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cargos', campoFk: 'usuario_id_baja' },

            { tabla: 'trabajadores', campoFk: 'usuario_id_registro' },
            { tabla: 'trabajadores', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'trabajadores', campoFk: 'usuario_id_baja' },

            { tabla: 'trabajadores_cargos', campoFk: 'usuario_id_registro' },
            { tabla: 'trabajadores_cargos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'trabajadores_cargos', campoFk: 'usuario_id_baja' },

            { tabla: 'roles', campoFk: 'usuario_id_registro' },
            { tabla: 'roles', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles', campoFk: 'usuario_id_baja' },

            { tabla: 'usuarios', campoFk: 'usuario_id_registro' },
            { tabla: 'usuarios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'usuarios', campoFk: 'usuario_id_baja' },

            { tabla: 'tablas', campoFk: 'usuario_id_registro' },
            { tabla: 'tablas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tablas', campoFk: 'usuario_id_baja' },

            { tabla: 'sucesos', campoFk: 'usuario_id_registro' },
            { tabla: 'sucesos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'sucesos', campoFk: 'usuario_id_baja' },

            { tabla: 'roles_permisos_tablas', campoFk: 'usuario_id_registro' },
            { tabla: 'roles_permisos_tablas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles_permisos_tablas', campoFk: 'usuario_id_baja' },

            { tabla: 'roles_permisos_sucesos', campoFk: 'usuario_id_registro' },
            { tabla: 'roles_permisos_sucesos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles_permisos_sucesos', campoFk: 'usuario_id_baja' },

            { tabla: 'menus', campoFk: 'usuario_id_registro' },
            { tabla: 'menus', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'menus', campoFk: 'usuario_id_baja' },

            { tabla: 'roles_menus', campoFk: 'usuario_id_registro' },
            { tabla: 'roles_menus', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles_menus', campoFk: 'usuario_id_baja' },

            { tabla: 'inventarios_fisicos', campoFk: 'usuario_id_registro' },
            { tabla: 'inventarios_fisicos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'inventarios_fisicos', campoFk: 'usuario_id_baja' },

            { tabla: 'clientes', campoFk: 'usuario_id_registro' },
            { tabla: 'clientes', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'clientes', campoFk: 'usuario_id_baja' },

            { tabla: 'categorias', campoFk: 'usuario_id_registro' },
            { tabla: 'categorias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'categorias', campoFk: 'usuario_id_baja' },

            { tabla: 'laboratorios', campoFk: 'usuario_id_registro' },
            { tabla: 'laboratorios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'laboratorios', campoFk: 'usuario_id_baja' },

            { tabla: 'formas', campoFk: 'usuario_id_registro' },
            { tabla: 'formas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'formas', campoFk: 'usuario_id_baja' },

            { tabla: 'presentaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'presentaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'presentaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'concentraciones', campoFk: 'usuario_id_registro' },
            { tabla: 'concentraciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'concentraciones', campoFk: 'usuario_id_baja' },

            { tabla: 'vias', campoFk: 'usuario_id_registro' },
            { tabla: 'vias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'vias', campoFk: 'usuario_id_baja' },

            { tabla: 'rangos_edad', campoFk: 'usuario_id_registro' },
            { tabla: 'rangos_edad', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'rangos_edad', campoFk: 'usuario_id_baja' },

            { tabla: 'marcas', campoFk: 'usuario_id_registro' },
            { tabla: 'marcas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'marcas', campoFk: 'usuario_id_baja' },

            { tabla: 'productos', campoFk: 'usuario_id_registro' },
            { tabla: 'productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_vias', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_vias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_vias', campoFk: 'usuario_id_baja' },

            { tabla: 'equivalentes', campoFk: 'usuario_id_registro' },
            { tabla: 'equivalentes', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'equivalentes', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_rangos_edad', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_rangos_edad', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_rangos_edad', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_ubicaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_ubicaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_ubicaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'principios_activos', campoFk: 'usuario_id_registro' },
            { tabla: 'principios_activos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'principios_activos', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_principios', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_principios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_principios', campoFk: 'usuario_id_baja' },

            { tabla: 'registros_sanitarios', campoFk: 'usuario_id_registro' },
            { tabla: 'registros_sanitarios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'registros_sanitarios', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_controlados', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_controlados', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_controlados', campoFk: 'usuario_id_baja' },

            { tabla: 'promociones', campoFk: 'usuario_id_registro' },
            { tabla: 'promociones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'promociones', campoFk: 'usuario_id_baja' },

            { tabla: 'promociones_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'promociones_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'promociones_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'conversiones_unidad', campoFk: 'usuario_id_registro' },
            { tabla: 'conversiones_unidad', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'conversiones_unidad', campoFk: 'usuario_id_baja' },

            { tabla: 'proveedores', campoFk: 'usuario_id_registro' },
            { tabla: 'proveedores', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'proveedores', campoFk: 'usuario_id_baja' },

            { tabla: 'proveedores_contactos', campoFk: 'usuario_id_registro' },
            { tabla: 'proveedores_contactos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'proveedores_contactos', campoFk: 'usuario_id_baja' },

            { tabla: 'proveedores_rating_historico', campoFk: 'usuario_id_registro' },
            { tabla: 'proveedores_rating_historico', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'proveedores_rating_historico', campoFk: 'usuario_id_baja' },

            { tabla: 'parametros_globales', campoFk: 'usuario_id_registro' },
            { tabla: 'parametros_globales', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'parametros_globales', campoFk: 'usuario_id_baja' },

            { tabla: 'tareas_programadas', campoFk: 'usuario_id_registro' },
            { tabla: 'tareas_programadas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tareas_programadas', campoFk: 'usuario_id_baja' },

            { tabla: 'control_facturas', campoFk: 'usuario_id_registro' },
            { tabla: 'control_facturas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'control_facturas', campoFk: 'usuario_id_baja' },

            { tabla: 'kardex', campoFk: 'usuario_id_registro' },
            { tabla: 'kardex', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'kardex', campoFk: 'usuario_id_baja' },

            { tabla: 'ordenes_compra', campoFk: 'usuario_id_registro' },
            { tabla: 'ordenes_compra', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ordenes_compra', campoFk: 'usuario_id_baja' },

            { tabla: 'instituciones', campoFk: 'usuario_id_registro' },
            { tabla: 'instituciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'instituciones', campoFk: 'usuario_id_baja' },

            { tabla: 'especialidades', campoFk: 'usuario_id_registro' },
            { tabla: 'especialidades', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'especialidades', campoFk: 'usuario_id_baja' },

            { tabla: 'medicos', campoFk: 'usuario_id_registro' },
            { tabla: 'medicos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'medicos', campoFk: 'usuario_id_baja' },

            { tabla: 'recetas', campoFk: 'usuario_id_registro' },
            { tabla: 'recetas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'recetas', campoFk: 'usuario_id_baja' },

            { tabla: 'lotes_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'lotes_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'lotes_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'kardex_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'kardex_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'kardex_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'inventarios_fisicos_detalle', campoFk: 'usuario_id_registro' },
            { tabla: 'inventarios_fisicos_detalle', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'inventarios_fisicos_detalle', campoFk: 'usuario_id_baja' },

            { tabla: 'ubicaciones_movimientos', campoFk: 'usuario_id_registro' },
            { tabla: 'ubicaciones_movimientos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ubicaciones_movimientos', campoFk: 'usuario_id_baja' },

            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id_registro' },
            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id_baja' },

            { tabla: 'tipos_planes_pago', campoFk: 'usuario_id_registro' },
            { tabla: 'tipos_planes_pago', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tipos_planes_pago', campoFk: 'usuario_id_baja' },

            { tabla: 'planes_pagos', campoFk: 'usuario_id_registro' },
            { tabla: 'planes_pagos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'planes_pagos', campoFk: 'usuario_id_baja' },

            { tabla: 'comprobantes_pagos', campoFk: 'usuario_id_registro' },
            { tabla: 'comprobantes_pagos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'comprobantes_pagos', campoFk: 'usuario_id_baja' },

            { tabla: 'pagos', campoFk: 'usuario_id_registro' },
            { tabla: 'pagos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'pagos', campoFk: 'usuario_id_baja' },

            { tabla: 'cajas', campoFk: 'usuario_id_registro' },
            { tabla: 'cajas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cajas', campoFk: 'usuario_id_baja' },

            { tabla: 'movimientos', campoFk: 'usuario_id_registro' },
            { tabla: 'movimientos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'movimientos', campoFk: 'usuario_id_baja' },

            { tabla: 'arqueos_detalle', campoFk: 'usuario_id_registro' },
            { tabla: 'arqueos_detalle', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'arqueos_detalle', campoFk: 'usuario_id_baja' },

            { tabla: 'alertas_notificaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'alertas_notificaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'alertas_notificaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'modelos', campoFk: 'usuario_id_registro' },
            { tabla: 'modelos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'modelos', campoFk: 'usuario_id_baja' },

            { tabla: 'entrenamientos', campoFk: 'usuario_id_registro' },
            { tabla: 'entrenamientos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'entrenamientos', campoFk: 'usuario_id_baja' },

            { tabla: 'metricas_rendimiento', campoFk: 'usuario_id_registro' },
            { tabla: 'metricas_rendimiento', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'metricas_rendimiento', campoFk: 'usuario_id_baja' },

            { tabla: 'patrones_consumo', campoFk: 'usuario_id_registro' },
            { tabla: 'patrones_consumo', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'patrones_consumo', campoFk: 'usuario_id_baja' },

            { tabla: 'variables_exogenas', campoFk: 'usuario_id_registro' },
            { tabla: 'variables_exogenas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'variables_exogenas', campoFk: 'usuario_id_baja' },

            { tabla: 'umbrales_configuracion', campoFk: 'usuario_id_registro' },
            { tabla: 'umbrales_configuracion', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'umbrales_configuracion', campoFk: 'usuario_id_baja' },

            { tabla: 'logs_ejecucion', campoFk: 'usuario_id_registro' },
            { tabla: 'logs_ejecucion', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'logs_ejecucion', campoFk: 'usuario_id_baja' },

            { tabla: 'analitica_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'analitica_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'analitica_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'pedidos_online', campoFk: 'usuario_id_registro' },
            { tabla: 'pedidos_online', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'pedidos_online', campoFk: 'usuario_id_baja' },

            { tabla: 'detalles_pedidos_online', campoFk: 'usuario_id_registro' },
            { tabla: 'detalles_pedidos_online', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'detalles_pedidos_online', campoFk: 'usuario_id_baja' },

            { tabla: 'carritos_compra', campoFk: 'usuario_id_registro' },
            { tabla: 'carritos_compra', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'carritos_compra', campoFk: 'usuario_id_baja' },

            { tabla: 'detalles_carritos', campoFk: 'usuario_id_registro' },
            { tabla: 'detalles_carritos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'detalles_carritos', campoFk: 'usuario_id_baja' },

            { tabla: 'listas_precios', campoFk: 'usuario_id_registro' },
            { tabla: 'listas_precios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'listas_precios', campoFk: 'usuario_id_baja' },

            { tabla: 'precios_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'precios_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'precios_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'costos_promedio', campoFk: 'usuario_id_registro' },
            { tabla: 'costos_promedio', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'costos_promedio', campoFk: 'usuario_id_baja' },

            { tabla: 'politicas_precios', campoFk: 'usuario_id_registro' },
            { tabla: 'politicas_precios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'politicas_precios', campoFk: 'usuario_id_baja' },

            { tabla: 'asistencias', campoFk: 'usuario_id_registro' },
            { tabla: 'asistencias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'asistencias', campoFk: 'usuario_id_baja' },

            { tabla: 'planillas', campoFk: 'usuario_id_registro' },
            { tabla: 'planillas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'planillas', campoFk: 'usuario_id_baja' },

            { tabla: 'planillas_detalle', campoFk: 'usuario_id_registro' },
            { tabla: 'planillas_detalle', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'planillas_detalle', campoFk: 'usuario_id_baja' },

            { tabla: 'contratos', campoFk: 'usuario_id_registro' },
            { tabla: 'contratos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'contratos', campoFk: 'usuario_id_baja' },

            { tabla: 'historicos', campoFk: 'usuario_id_registro' },
            { tabla: 'historicos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'historicos', campoFk: 'usuario_id_baja' },
        ];
    }


SOLO DIME SI FALTA ALGUNA TABLA EN static getDependencias(): Array<string | { tabla: string; campoFk: string }> {