FALTA. Eliminar cada 24 horas a las 3 am las fotos de logos de empresas, usuarios avatar y trabajador foto 
FALTA. Crear UN TRIGGER QUE NO permita modificar ni eliminar todos los registros pk_id=1
FALTA. Crear UN TRIGGER QUE NO permita modificar ni eliminar el usuario_id=2
FALTA. Crear UN trigger que no permita eliminar nada que tenga que ver con usuario_id=2
--FALTA. ARREGLAR EL modulo trabajador. POR QUE SE CAMBIO los campos de ubicaciones se cambio 
--FALTA. ARREGLAR EL MODULO CLientes.
--FALTA. Arreglar el modulo roles_menus.
--FALTA. Arreglar el modulo menus.
--FALTA. Hacer el modulo roles_permisos_sucesos 
--FALTA. Arreglar el modulo roles_tablas.
--FALTA. Arreglar C:\sirena\sirena-backend\src\common\validators\is-eventos-permitidos.validator.service.ts
--FALTA. Hacer el modulo roles_permisos_tablas
--FALTA. Arreglar el modulo tablas
--FALTA. ELIMINAR EL MODULO actual tablas.
--FALTA. Modulo Tablas.
--FALTA. Arreglar el modulo roles.
--FALTA. Arreglar el modulo sucesos
--FALTA. Ubicaciones
--FALTA. revisar el modulo sucursal se eliminio de usuarios sucursal_id 
--FALTA. MEJORAR usuarios eliminar FK sucursal_id
--FALTA. MEJORAR AUTENTIFICACION 
--FALTA. MEJORAR tabla y modulo trabajadores ADD sucursal_id
--FALTA. Estandarizar lo mismo de bancos .http 
--FALTA. Mejorar servicios de bancos aplicar la misma logica en todos los servicios.
--FALTA. Arreglar tabla-validador.service.ts arreglar validarPermisoTabla()
--FALTA. Arreglar tabla-validador.service.ts arreglar validarEventosKardex() Motivo: La validación de eventos usaba eventos_permitidos (JSONB) de roles_tablas, que ya no existe. Cambio: Debe consultar roles_permisos_sucesos usando rol_permiso_tabla_id.
--FALTA. Arreglar tabla-validador.service.ts arreglar invalidarPermisoCache() (opcional) Motivo: Si se modifica la estructura de permisos, puede ser necesario ajustar la lógica de invalidación.
--FALTA. ARREGLAR EL MODULO usuarios. POR QUE SE CAMBIO los campos de ubicaciones se cambio 
--FALTA. Mejorar el modulo usuarios no muestra cargo, trabajador y C:\sirena\sirena-backend\src\modules\usuarios\dto\find-usuarios-query.dto.ts
--FALTA. Arreglar el modulo usuarios.
--FALTA. Mejorar autentificacion.
--FALTA. Revisar el modulo inventarios_fisicos se quito CONSTRAINT fk_inventariosfisicos_usuarioregistro_id FOREIGN KEY (usuario_id_registro) REFERENCES usuarios(usuario_id), CONSTRAINT fk_inventariosfisicos_usuarioactualizacion_id FOREIGN KEY (usuario_id_actualizacion) REFERENCES usuarios(usuario_id), CONSTRAINT fk_inventariosfisicos_usuariobaja_id FOREIGN KEY (usuario_id_baja) REFERENCES usuarios(usuario_id),
--FALTA 00. Verificar todos los campos usuario_id REFERENCIAS 
--FALTA 06. Arreglar la tabla cajas.
--FALTA 07. Arreglar la tabla movimientos.
--FALTA 08. Arreglar la tabla alertas_notificaciones.
--FALTA 09. Arreglar la tabla pedidos_online.
--FALTA 10. Arreglar la tabla asistencias.
--FALTA 11. Arreglar la tabla planillas.
--FALTA 12. Arreglar la tabla contratos.
--FALTA 17. Deberia haber insert into por todas las tablas 
--FALTA 20. MEJORAR modulo constantes se aumentarion ESTADO PEDIDO se aumento NINGUNO = 2257, ESTADO RESERVA se aumento EstadoReserva
--FALTA 21. TABLAS TRANSACCIONALES (SOLO 1000, 1001, 1003)
--4	recetas	Transaccional - Prescripciones médicas	❌ Incluye 1002	Sí
--8	inventarios_fisicos_detalle	Transaccional - Detalle de conteos	❌ Incluye 1002	Sí
--9	comprobantes_pagos	Transaccional - Comprobantes de pago	❌ Incluye 1002	Sí
--10	pagos	Transaccional - Pagos registrados	❌ Incluye 1002	Sí
--11	planes_pagos	Transaccional - Planes de pago	❌ Incluye 1002	Sí
--12	movimientos	Transaccional - Movimientos de caja	❌ Incluye 1002	Sí
-- arqueos_detalle
--15	pedidos_online	Transaccional - Pedidos digitales	❌ Incluye 1002	Sí
--16	detalles_pedidos_online	Transaccional - Detalle de pedidos	❌ Incluye 1002	Sí
--20	asistencias	Transaccional - Marcaciones	❌ Incluye 1002	Sí
--24	alertas_notificaciones	Transaccional - Alertas generadas	❌ Incluye 1002	Sí
--28	variables_exogenas	Transaccional - Datos externos	❌ Incluye 1002	Sí
--29	patrones_consumo	Transaccional - Patrones detectados	❌ Incluye 1002	Sí
--kardex y kardex_productos: Correcto. Los movimientos de inventario son eventos en tiempo real; si una transacción falla o se reversa, se anula (1003), pero los registros contables de kardex no se "archivan" individualmente.
--ordenes_compra y recetas: Correcto. Su ciclo operativo directo es estar activas, borradas lógicamente o anuladas.
--inventarios_fisicos y su detalle: Correcto. Son actas de conteo puntual en un momento dado que se aplican directamente al stock; no requieren un ciclo de histórico individual en sus tablas de detalle.
--carritos_compra y detalles_carritos: Correcto. Son tablas temporales de sesión web que se eliminan o expiran, sin requerir histórico de archivo permanente.
-- Contienen 1000, 1001, 1002
-- lotes_productos: Requiere 1002. Los lotes vencidos o con stock agotado no se borran (1001), pasan a histórico para mantener la trazabilidad legal y farmacéutica de los medicamentos dispensados.
-- cajas y arqueos_detalle: Requieren 1002. Las sesiones de caja cerradas no se anulan ni se eliminan; pasan a un estado histórico de auditoría financiera inalterable.
-- planillas y planillas_detalle: Requieren 1002. Las nóminas de sueldos cerradas y pagadas de periodos pasados se archivan como históricas para cumplir normativas laborales y fiscales.
-- contratos: Requieren 1002. Los contratos laborales finalizados o rescindidos pasan a histórico, nunca deben borrarse físicamente.
-- precios_productos y costos_promedio: Requieren 1002. Las listas de precios anteriores y costos históricos de inventario deben congelarse con 1002 para que las transacciones pasadas mantengan su congruencia financiera.
-- analitica_productos: Requieren 1002. Los resultados de pronósticos estadísticos (como corridas de modelos ARIMA/SARIMA) de meses anteriores deben archivarse como históricos para comparar la precisión del modelo frente a la realidad.



SELECT
    kcu.table_name AS tabla_dependiente,
    kcu.column_name AS columna_fk,
    ccu.table_name AS tabla_referenciada,
    ccu.column_name AS columna_pk,
    tc.constraint_name AS nombre_restriccion
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY kcu.table_name, ccu.table_name;

