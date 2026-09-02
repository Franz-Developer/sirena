-- ================================================================================================
Actúa como un Arquitecto de Bases de Datos Senior, DBA experto en PostgreSQL y Especialista en Desarrollo de Sistemas ERP multi-rubro de alta
disponibilidad.
Se te proporcionará la estructura completa de la base de datos dbsirena.
El sistema está diseñado inicialmente con un enfoque farmacéutico, pero su arquitectura debe ser completamente genérica y adaptable sin modificaciones estructurales mayores a cualquier tipo de negocio (minimarket, ferretería, comercio general, etc.).

Tu enfoque de análisis y auditoría exhaustiva en esta ocasión debe limitarse ÚNICAMENTE al siguiente módulo:

MODULO CONFIGURACION Y SISTEMA
Tablas Principales: dominios, bancos, tipos_cambios, empresas, empresas_nits, empresas_cuentas, sucursales, puntos_venta, cuis, cufd, parametros_globales, tareas_programadas, configuraciones
Tablas Relaciones: usuarios, roles, menus, roles_menus, trabajadores, cargos, trabajadores_cargos
Dominios utilizados:
    EstadoID (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO)
    TipoMonedaID (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV)
    TipoCuentaID (1750=CUENTA_CORRIENTE, 1751=CAJA_AHORROS, 1752=AHORRO_PROGRAMADO, 1753=PLAZO_FIJO, 1754=INVERSION, 1755=NO_APLICA)
    ModalidadFacturacionID (3900=NINGUNO, 3901=ELECTRONICA, 3902=COMPUTARIZADA, 3903=MANUAL)
    AmbienteID (2750=PRODUCCION, 2751=PILOTO_PRUEBAS)
    TipoPuntoVentaID (3950=NINGUNO, 3951=CAJA)
    EstadoFiscalID (1650=ACTIVO, 1651=AGOTADO, 1652=VENCIDO, 1653=CANCELADO)
    TipoDatoID (1800=STRING, 1801=INTEGER, 1802=DECIMAL, 1803=BOOLEAN)
    TipoTareaID (3400=REPORTE, 3401=IA_MODELO, 3402=BACKUP, 3403=ALERTA, 3404=MANTENIMIENTO, 3405=FORECASTING, 3406=CLASIFICACION, 3407=OPTIMIZACION, 3408=VALIDACION, 3409=NINGUNO)
    SubtipoTareaID (3450=SARIMA, 3451=SARIMAX, 3452=PROPHET, 3453=KMEANS, 3454=ROP_CALC, 3455=PATRON_CONSUMO, 3456=ALERTA_PREDICTIVA, 3457=VARIABLE_EXOGENA, 3458=METRICA_RENDIMIENTO, 3459=REENTRENAMIENTO, 3460=VALIDACION_CROSS, 3461=NINGUNO)
    FrecuenciaID (3350=MINUTOS, 3351=HORAS, 3352=DIARIO, 3353=SEMANAL, 3354=MENSUAL, 3355=ANUAL, 3356=CRON, 3357=CONTINUA, 3358=TRIGGER_EVENTO, 3359=NINGUNO)
    ModuloEstrategicoID (2150=FLUJO_CAJA, 2151=DEMANDA_INVENTARIO, 2152=PROVEEDORES_AHP, 2153=OPERACION_MERMAS, 2154=CLIENTES_RFM, 2155=PRECIOS_ELASTICIDAD, 2156=ANOMALIAS_FRAUDE, 2157=NINGUNO)
    FormatoPDFID (1950=ESTANDAR, 1951=RESUMIDO, 1952=DETALLADO)
Funciones: fn_validar_reglas_negocio

REGLAS ESTRICTAS DE RESPUESTA:
- NO menciones absolutamente nada de lo que esté bien o correcto. Concéntrate exclusivamente en fallos reales de lógica, redundancias críticas, campos innecesarios, problemas de cardinalidad, índices innecesarios (considerando tablas de bajísima tasa de crecimiento que penalizan escrituras) o elementos estructurales faltantes.
- Evita observaciones hiper-exquisitas o puristas excesivas. Sé pragmático y útil.
- NO des resúmenes introductorios ni conclusiones generales.
- Si no encuentras una sola observación o fallo real, responde únicamente con el texto exacto: MODULO COMPLETO!!!
- Toda la respuesta generada debe ir obligatoriamente dentro de un ÚNICO bloque de código con comillas invertidas de Markdown (backticks).
- PROHIBIDO usar formato de negritas (**texto**) en cualquier parte de la respuesta.
- Cualquier código SQL propuesto como solución debe entregarse estrictamente sin comentarios (sin guiones ni bloques de comentarios), listo para ser ejecutado o copiado.

OBJETIVOS DE LA AUDITORÍA TÉCNICA Y DE NEGOCIO:
1. INTEGRIDAD REFERENCIAL Y MODELADO: Verifica relaciones lógicas faltantes, problemas de cardinalidad y asegúrate de que las llaves foráneas críticas consideren valores por defecto lógicos (DEFAULT 1) alineados con la existencia del registro base primary_key_id = 1.
2. COHERENCIA DE DOMINIOS Y ESTADOS: Revisa si los IDs de dominios utilizados corresponden con los catálogos provistos, si hay valores hardcodeados indebidos, o si faltan dominios lógicos sin caer en redundancias.
3. OPTIMIZACIÓN Y RENDIMIENTO: Evalúa estrictamente si los índices únicos y de búsqueda se justifican considerando el volumen y la tasa de crecimiento estimada de las tablas del módulo, evitando penalizaciones innecesarias en operaciones de escritura.
4. REGLAS DE NEGOCIO Y CONFIGURACIÓN: Analiza la flexibilidad y el cumplimiento de las políticas operativas del negocio, asegurando que la parametrización soporte adecuadamente los flujos transaccionales sin acoplarse a un rubro específico.
4.1. RESTRICCIONES CHECK: Analiza la coherencia estructural y lógica de las restricciones CHECK y reglas asociadas, asegurando que no existan contradicciones lógicas, vacíos o errores de sintaxis.
5. EFICIENCIA Y SINTAXIS: Valida la correcta tipificación de datos y la correcta aplicación transversal de las reglas generales del sistema.
6. CAMPOS ESTÁNDAR EXCLUIDOS DEL ANÁLISIS: Excluye explícitamente de cualquier auditoría, revisión de redundancia o sugerencia de modificación a los campos de control transversal: estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion y fecha_baja. Asume que son parte de la plantilla estándar obligatoria.
7. COHERENCIA DE NOMBRES DE DOMINIOS: Verifica que el sufijo del nombre de cualquier columna que actúe como dominio coincida exactamente con el nombre lógico del dominio o catálogo paramétrico correspondiente (Ejemplo correcto: estado_fiscal_id con dominio EstadoFiscalID. Incorrecto: tipo_fiscal_id con dominio EstadoFiscalID).
8. ANÁLISIS DE TIPOS DE DATOS Y RESTRICCIONES: Evalúa con rigor técnico si el tipo de dato asignado a cada columna es el óptimo (VARCHAR, precisión numérica, temporales) y la pertinencia de NULL / NOT NULL / DEFAULT.
9. INTEGRIDAD DE LLAVES FORÁNEAS: Comprueba que toda llave foránea incorpore obligatoriamente DEFAULT 1 bajo la premisa de la existencia del registro base con ID 1.
10. PROPUESTA DE VALOR: Propone la adición de nuevos campos, dominios u opciones únicamente si aportan valor real y no son redundantes.
11. ANALIZAR LOS COMMENT puesto que almacenan las REGLAS DEL NEGOCIO: Cada tabla tiene reglas particulares debes verificar que estas no se contradigan, que explique lo que la tabla no explique, que no sean rebundantes a las reglas generales.

ESTRUCTURA OBLIGATORIA DE CADA HALLAZGO:

OBSERVACION No. 01
COMPONENTE: [Tabla o campo afectado del módulo]
DESCRIPCIÓN: [Párrafo corto y claro que integra el problema detectado y su impacto en el sistema, rendimiento o consistencia de datos]
SOLUCIÓN PROPUESTA: [Argumento técnico de la solución y a continuación el código SQL limpio, sin comentarios y sin bloques de código internos]

-- ================================================================================================
-- Contesta las observacion 

TAREA: Actúa como un DBA Senior y auditor de bases de datos. Debes evaluar la observación técnica proporcionada y decidir si es VÁLIDA o NO VÁLIDA para el contexto actual.
CONTEXTO: Base de datos "dbsirena", actualmente en fase de análisis estructural y diseño.
REGLAS DE EVALUACIÓN:
- Verifica si la observación aplica realmente al motor de base de datos en uso, integridad referencial, normalización o rendimiento.
- Si la observación se basa en una suposición errónea, no aplica al modelo o representa una mala práctica, márcala como NO VÁLIDA.
- Si la observación propone la creación de un índice de búsqueda, evalúa si la tabla crecerá y si ese índice propuesto no será prejudicial.

FORMATO DE RESPUESTA OBLIGATORIO:

1. Si la observación NO es válida, responde estrictamente con este formato exacto dentro del comentario:
-- OBSERVACION [Número]: NO VALE

2. Si la observación es VÁLIDA, responde estrictamente con este formato:
/*
RESPUESTA a OBSERVACION [Número]:
- Diagnóstico: [Explica brevemente el problema real].
- Solución: [Argumenta la solución técnica].
*/
[Código SQL ejecutable solución]

REGLA CRÍTICA DE SALIDA:
- Toda la respuesta generada debe ir obligatoriamente dentro de un ÚNICO bloque de código con comillas invertidas de Markdown (backticks).
- Las explicaciones, diagnósticos y comentarios deben estar envueltos estrictamente en bloques de comentarios SQL (/* ... */ o --).
- El código SQL de solución debe ir fuera de los comentarios para que DBeaver lo ejecute directamente, intercalado con sus respectivas explicaciones comentadas.
- No incluyas saludos, introducciones ni texto fuera del bloque de código único.
- Debe haber un espacio de separación visual entre cada bloque de respuesta.

-- ================================================================================================ 

TAREA: [lo que quieres que haga]
CONTEXTO: [dónde estamos]
FORMATO: [cómo quieres que responda]
PRIORIDAD: [qué es más importante]

TAREA: 
	1. QUIERO que analices toda la base de datos de dbsirena, las tablas (incluido sus campos), los dominios y las reglas.
	2. Quiero que los dividas por modulos 
	3. No quiero que te inventes tablas solo usa las que existen. 
	4. No quiero que te inventes dominios solo usa las que existen.
	5. Debes informar si existe tablas o dominios sueltos. o que no tienen razon de ser, 
	6. NO quiero resumenes. 
CONTEXTO: dbsirena. Estoy haciendo un analisis de los modulos que tiene  dbsirena. POR LO tanto no quiero SQL, no quiero codigo fuente, no quiero cardinalidad , no quiero que te inventes nada 
FORMATO SALIDA:

MODULO XXXX 	<-- El nombre del modulo (mayusculas) debe explicar por si mismo que hace el modulo. No quiero explicaciones que hace el modulo. No quiero salto de linea vacio.
Tablas Principales: tabla1, tabla2, ... tablaN	<-- Lista de nombres de tablas principales del modulo sin explicacion. en una sola linea separados por comas ','
Tablas Relaciones: tabla1, tabla2, ... tablaN   <-- Lista de nombres que se relacionan de tablas sin explicacion
Dominios utilizados: 
	Nombre_Dominio1 (dominio_id1=ABREVIATURA1, dominio_id2=ABREVIATURA2,....dominio_idN=ABREVIATURAN)  	<-- Dominio (todas sus opciones) EJ. GeneroID (1200=MASCULINO, 1201=FEMENINO)
	Nombre_Dominio1 (dominio_id1=ABREVIATURA1, dominio_id2=ABREVIATURA2,....dominio_idN=ABREVIATURAN)  	<-- Debe haber un salto de linea para que se note los Dominios.
	...
	Nombre_Dominio1 (dominio_id1=ABREVIATURA1, dominio_id2=ABREVIATURA2,....dominio_idN=ABREVIATURAN)  	
Debe haber espacio de separacion entre MODULOS. 	
Funciones: Funcion1,.... FuncionN  <-- Lista de funciones que pertenecen al modulo.

PRIORIDAD: CORTO y CLARO 

-- ================================================================================================
-- LISTA DE Módulos del Sistema dbsirena (Sistema de Gestión y Control Farmacéutico)

-- MODULO CONFIGURACION Y SISTEMA
Tablas Principales: dominios, bancos, tipos_cambios, empresas, empresas_nits, empresas_cuentas, sucursales, puntos_venta, cuis, cufd, parametros_globales, tareas_programadas, configuraciones
Tablas Relaciones: usuarios, roles, menus, roles_menus, trabajadores, cargos, trabajadores_cargos
Dominios utilizados:
    EstadoID 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO
    TipoMonedaID 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    TipoCuentaID 1750=CUENTA_CORRIENTE, 1751=CAJA_AHORROS, 1752=AHORRO_PROGRAMADO, 1753=PLAZO_FIJO, 1754=INVERSION, 1755=NO_APLICA
    ModalidadFacturacionID 3900=NINGUNO, 3901=ELECTRONICA, 3902=COMPUTARIZADA, 3903=MANUAL
    AmbienteID 2750=PRODUCCION, 2751=PILOTO_PRUEBAS
    TipoPuntoVentaID 3950=NINGUNO, 3951=CAJA
    EstadoFiscalID 1650=ACTIVO, 1651=AGOTADO, 1652=VENCIDO, 1653=CANCELADO
    TipoDatoID 1800=STRING, 1801=INTEGER, 1802=DECIMAL, 1803=BOOLEAN
    TipoTareaID 3400=REPORTE, 3401=IA_MODELO, 3402=BACKUP, 3403=ALERTA, 3404=MANTENIMIENTO, 3405=FORECASTING, 3406=CLASIFICACION, 3407=OPTIMIZACION, 3408=VALIDACION, 3409=NINGUNO
    SubtipoTareaID 3450=SARIMA, 3451=SARIMAX, 3452=PROPHET, 3453=KMEANS, 3454=ROP_CALC, 3455=PATRON_CONSUMO, 3456=ALERTA_PREDICTIVA, 3457=VARIABLE_EXOGENA, 3458=METRICA_RENDIMIENTO, 3459=REENTRENAMIENTO, 3460=VALIDACION_CROSS, 3461=NINGUNO
    FrecuenciaID 3350=MINUTOS, 3351=HORAS, 3352=DIARIO, 3353=SEMANAL, 3354=MENSUAL, 3355=ANUAL, 3356=CRON, 3357=CONTINUA, 3358=TRIGGER_EVENTO, 3359=NINGUNO
    ModuloEstrategicoID 2150=FLUJO_CAJA, 2151=DEMANDA_INVENTARIO, 2152=PROVEEDORES_AHP, 2153=OPERACION_MERMAS, 2154=CLIENTES_RFM, 2155=PRECIOS_ELASTICIDAD, 2156=ANOMALIAS_FRAUDE, 2157=NINGUNO
    FormatoPDFID 1950=ESTANDAR, 1951=RESUMIDO, 1952=DETALLADO
Funciones: fn_validar_reglas_negocio

-- MODULO SEGURIDAD Y ACCESOS
Tablas Principales: trabajadores, cargos, trabajadores_cargos, roles, menus, roles_menus, usuarios
Tablas Relaciones: 
Dominios utilizados:
    GeneroID 1200=MASCULINO, 1201=FEMENINO
    EstadoCivilMasculinoID 1250=SOLTERO, 1251=CASADO, 1252=DIVORCIADO, 1253=VIUDO, 1254=UNION_LIBRE
    EstadoCivilFemeninoID 1300=SOLTERA, 1301=CASADA, 1302=DIVORCIADA, 1303=VIUDA, 1304=UNION_LIBRE
Funciones: 

-- MODULO GESTIÓN DE PRODUCTOS
Tablas Principales: categorias, unidades, laboratorios, formas, presentaciones, concentraciones, vias, rangos_edad, productos, productos_vias, equivalentes, productos_rangos_edad, productos_ubicaciones, principios_activos, productos_principios, registros_sanitarios, productos_controlados, promociones, promociones_productos, conversiones_unidad
Tablas Relaciones: ubicaciones, almacenes
Dominios utilizados:
    TipoBeneficioID 1500=DESCUENTO, 1501=PORCENTAJE, 1502=MONTO_FIJO, 1503=CANTIDAD, 1504=NINGUNO
    GradoEquivalenciaID 3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO, 3803=NINGUNO
	CriticidadMedicaID 4150=NORMAL, 4151=CRITICO  
Funciones: fn_validarCoherenciaPromocion 

-- MODULO INVENTARIOS Y ALMACENES
Tablas Principales: almacenes, almacenes_puntos_venta, ubicaciones, ubicaciones_movimientos, productos_ubicaciones, lotes_productos, historial_ubicaciones, inventarios_fisicos, inventarios_fisicos_detalle
Tablas Relaciones: kardex, productos, kardex_productos, sucursales
Dominios utilizados:
    TipoAlmacenID 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    EstadoLoteID 2500=VIGENTE, 2501=VENCIDO, 2502=AGOTADO, 2503=NINGUNO
	TipoOperacionAlmacenID 4050=LOGISTICA_INTERNA, 4051=VENTA_DIRECTA
	TipoAlmacenID 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA 
	TipoUbicacionMovimientoID 3200=INGRESO, 3201=EGRESO
	EstadoTraspasoID 2100=EN_TRANSITO, 2101=RECIBIDO, 2102=RECHAZADO, 2103=NO_APLICA
Funciones: 

-- MODULO COMPRAS (AL CONTADO y A CREDITO) Y PROVEEDORES
Tablas Principales: proveedores, proveedores_contactos, kardex, kardex_productos, planes_pagos, pagos, comprobantes_pagos, tipos_planes_pago, proveedores_rating_historico, ordenes_compra
Tablas Relaciones: productos, lotes_productos, clientes, sucursales
Dominios utilizados:
    EventoID 1050=COMPRA, 1061=DEVOLUCION_PROVEEDOR, 1058=SOLICITUD_COMPRA
    EstadoPedidoID 2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO
    EstadoFinancieroID 2400=CANCELADO, 2401=PENDIENTE, 2402=PARCIAL, 2403=NINGUNO, 2404=DEVOLUCION_GENERADA
    EstadoPagoID 2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO
    CalidadRatingID 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
    MotivoDevolucionID 3500=PRODUCTO_VENCIDO, 3501=PRODUCTO_DAÑADO, 3502=ERROR_PEDIDO, 3503=EXCESO_STOCK, 3504=DESCONTINUADO, 3505=DEVOLUCION_CLIENTE, 3506=NINGUNO, 3507=PRODUCTO_NO_SOLICITADO, 3508=PRODUCTO_DEFECTUOSO
Funciones: fn_validar_reglas_negocio, fn_actualizar_rating_proveedor, fn_cerrar_planes_pago

-- MODULO VENTAS Y FACTURACION (SE puede vender a efectivo o a credito)
Tablas Principales: clientes, kardex, kardex_productos, control_facturas, recetas, medicos, instituciones, especialidades, historicos, comprobantes_pagos, planes_pagos, pagos, comprobantes_pagos
Tablas Relaciones: productos, lotes_productos, sucursales, puntos_venta, empresas, empresas_nits
Dominios utilizados:
    EventoID 1051=VENTA, 1052=PROFORMA, 1059=VENTA_RESERVA, 1060=DEVOLUCION_CLIENTE
    TipoClienteID 1150=NATURAL, 1151=JURIDICA
    TipoDocumentoID 2200=CEDULA_IDENTIDAD, 2201=CEDULA_IDENTIDAD_EXTRANJERO, 2202=PASAPORTE, 2203=OTRO, 2204=NIT
    TipoComprobanteID 1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO
    TipoVentaID 1350=NINGUNO, 1351=CON_FACTURA, 1352=SIN_FACTURA
    TipoPagoID 1400=NINGUNO, 1401=EFECTIVO, 1402=TARJETA, 1403=CHEQUE, 1404=VALE, 1405=OTROS, 1406=SIN_PAGO, 1407=TRANSFERENCIA, 1408=DEPOSITO, 1409=QR
    TipoFacturaID 2350=CON_FACTURA, 2351=SIN_FACTURA, 2352=NOTA_CREDITO_DEBITO, 2353=NINGUNO
    TipoDespachoID 3550=VENTA_MOSTRADOR, 3551=DOMICILIO, 3552=RETIRO, 3553=TRANSFERENCIA, 3554=NINGUNO
    EstadoDocumentoID 3300=EMITIDO, 3301=ANULADO, 3302=ANULADO_PARCIAL
    EstadoProformaID 4000=NO_APLICA, 4001=PENDIENTE, 4002=CONVERTIDA, 4003=EXPIRADA, 4004=ANULADA
    MotivoAnulacionID 2450=FACTURA_MAL_EMITIDA, 2451=ERROR_DATOS_CLIENTE, 2452=DEVOLUCION_MERCADERIA, 2453=CONTINGENCIA, 2454=OPERACION_NO_CONCRETADA, 2455=NINGUNO
    TipoRecetaID 3850=SIMPLE, 3851=ARCHIVADA, 3852=VALADA, 3853=NINGUNO
Funciones: liberar_reservas_expiradas, fn_validar_reglas_negocio

-- MODULO GESTION DE CAJA
Tablas Principales: cajas, movimientos, arqueos_detalle
Tablas Relaciones: usuarios, sucursales
Dominios utilizados:
    EstadoCajaID 2650=ABIERTA, 2651=CERRADA
    TipoMovimientoID 2600=INGRESO, 2601=EGRESO
	TipoBilleteMonedaID 4300=NINGUNO, 4301=B200, 4302=B100, 4303=B50, 4304=B20, 4305=B10, 4306=B5, 4307=B2, 4308=B1, 4309=M050, 4310=M020, 4311=M010, 4312=M10, 4313=M5, 4314=M2, 4315=M1
Funciones: fn_validar_coherencia_cierre_caja, fn_validar_coherencia_saldo_movimiento

-- MODULO NUCLEO ANALITICO Y PREDICCIONES
Tablas Principales: modelos, entrenamientos, metricas_rendimiento, patrones_consumo, variables_exogenas, umbrales_configuracion, logs_ejecucion, analitica_productos
Tablas Relaciones: productos, sucursales
Dominios utilizados:
	TipoModeloID 1450=ARIMA, 1451=SARIMA, 1452=SERIES_TEMPORALES, 1453=CLASIFICACION, 1454=OPTIMIZACION, 1455=DETECCION_ANOMALIAS, 1456=NINGUNO
	FrameworkID 3000=STATSMODELS, 3001=SCIKIT_LEARN, 3002=TENSORFLOW, 3003=CUSTOM, 3004=NINGUNO
	EstadoModeloID 2000=SIN_DATOS, 2001=ENTRENANDO, 2002=ACTIVO, 2003=RECHAZADO, 2004=OBSOLETO
	EstadoEjecucionID 3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO, 3053=NINGUNO
	TipoMetricasID 3100=REGRESION, 3101=CLASIFICACION, 3102=CLUSTERING, 3103=NINGUNO
	MetricaPrecisionID 3600=MAE, 3601=RMSE, 3602=MAPE, 3603=R2, 3604=F1, 3605=NINGUNO
	FactorEstacionalidadID 3650=NONE, 3651=DIARIO, 3652=SEMANAL, 3653=MENSUAL, 3654=ANUAL, 3655=MULTIPLE
	TemporadaID 1600=NINGUNO, 1601=ALTA, 1602=MEDIA, 1603=BAJA
	EstadoPronosticoID 1550=PENDIENTE, 1551=PROCESADO, 1552=ERROR, 1553=NINGUNO
	MotivoOutlierID 1900=BLOQUEO, 1901=FERIADO_LOCAL, 1902=ERROR_SISTEMA, 1903=PICO_ANORMAL, 1904=ROTURA, 1905=ROBO, 1906=SOBRANTE, 1907=NINGUNO
	NivelLogID 3150=INFO, 3151=WARNING, 3152=ERROR, 3153=DEBUG
	TipoUmbralID 3250=STOCK_MINIMO, 3251=DIAS_VENCIMIENTO, 3252=ERROR_PREDICCION, 3253=NINGUNO
	NivelUrgenciaID 1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO
	FuenteExogenaID 4250=SENAMHI, 4251=INE, 4252=BCB, 4253=API_CLIMA, 4254=CALENDARIO_FESTIVOS, 4255=CUSTOM
	SubtipoTareaID 3450=SARIMA, 3451=SARIMAX, 3452=PROPHET, 3453=KMEANS, 3454=ROP_CALC, 3455=PATRON_CONSUMO, 3456=ALERTA_PREDICTIVA, 3457=VARIABLE_EXOGENA, 3458=METRICA_RENDIMIENTO, 3459=REENTRENAMIENTO, 3460=VALIDACION_CROSS, 3461=NINGUNO
	TipoPatronID 4200=DEMANDA
Funciones: fn_validar_reglas_negocio, fn_validar_coherencia_metrica, fn_validar_registros_entrenamiento, fn_validar_metricas_rendimiento, fn_validar_outlier_con_error, fn_liberar_reservas_expiradas, fn_validar_coherencia_promocion

-- MODULO NOTIFICACIONES Y ALERTAS
Tablas Principales: alertas_notificaciones
Tablas Relaciones: usuarios, sucursales
Dominios utilizados:
    TipoAlertaNotificacionID 2700=SISTEMA, 2701=ALERTA_STOCK, 2702=STOCK_BAJO, 2703=STOCK_CRITICO, 2704=STOCK_EXCESO, 2705=VENCIMIENTO_PROXIMO, 2706=VENCIMIENTO_INMEDIATO, 2707=VENCIMIENTO_VENCIDO, 2708=DEMANDA_ALTA, 2709=DEMANDA_BAJA, 2710=TENDENCIA_ANOMALA, 2711=PREDICCION_ROP, 2712=PREDICCION_DEMANDA, 2713=FORECASTING, 2714=PAGOS, 2715=PAGO_VENCIDO, 2716=PAGO_PROXIMO, 2717=DOCUMENTOS, 2718=FACTURA_PENDIENTE, 2719=FACTURA_ANULADA, 2720=SEGURIDAD_ACCESO, 2721=SEGURIDAD_INTENTO_FALLIDO, 2722=SISTEMA_ERROR, 2723=SISTEMA_RENDIMIENTO, 2724=NINGUNO
    SubtipoAlertaID 2800=SARIMA, 2801=PROPHET, 2802=KMEANS, 2803=ROP_CALC, 2804=PATRON_CONSUMO, 2805=ALERTA_PREDICTIVA, 2806=QUIEBRE_STOCK, 2807=REORDEN, 2808=EXCESO, 2809=CADUCIDAD_CRITICA, 2810=CADUCIDAD_ALTA, 2811=CADUCIDAD_MEDIA, 2812=NINGUNO
    OrigenAlertaID 2850=SISTEMA, 2851=IA, 2852=USUARIO, 2853=TAREA_PROGRAMADA
    NivelCriticoID 2900=CRITICO, 2901=ALTA, 2902=MEDIA, 2903=BAJA, 2904=INFORMATIVA, 2905=NINGUNO
    EstadoAlertaID 2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA, 2955=NINGUNO
	EntidadAfectadaID 4100=PRODUCTOS, 4101=LOTES, 4102=VENTAS, 4103=COMPRAS, 4104=USUARIOS, 4105=SUCURSALES, 4106=PROVEEDORES, 4107=CLIENTES, 4108=FACTURAS, 4109=PAGOS, 4110=INVENTARIO, 4111=NINGUNO
Funciones: 

-- MÓDULO DE COMERCIO ELECTRÓNICO Y DELIVERY FARMACÉUTICO
Tablas Principales: pedidos_online, detalles_pedidos_online, carritos_compra, detalles_carritos
Tablas Relaciones: clientes, sucursales, kardex, kardex_productos, usuarios, productos, dominios
Dominios utilizados:
	EstadoPedidoOnlineID 3700=PENDIENTE, 3701=CONFIRMADO, 3702=PREPARANDO, 3703=EN_CAMINO, 3704=ENTREGADO, 3705=CANCELADO, 3706=RECHAZADO
	EstadoPagoID 2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO
Funciones: 

-- MÓDULO DE GESTIÓN DE PRECIOS, COSTOS Y MÁRGENES
Tablas Principales: listas_precios, precios_productos, costos_promedio, politicas_precios 
Tablas Relaciones: productos, dominios
Dominios utilizados: 
	MetodoCalculoID 3750=PONDERADO, 3751=FIFO, 3752=ULTIMA_COMPRA
	TipoAplicacionID 4350=GLOBAL, 4351=CATEGORIA, 4352=LABORATORIO, 4353=PRODUCTO
Funciones: 
		
-- MÓDULO DE RECURSOS HUMANOS Y GESTIÓN DEL TALENTO
Tablas: asistencias, planillas, planillas_detalle, contratos
Tablas Relaciones: trabajadores, trabajadores_cargos, dominios
Dominios utilizados: 
	TipoAsistenciaID 4400=NORMAL, 4401=LICENCIA, 4402=PERMISO, 4403=JUSTIFICADA
    EstadoAsistenciaID 4450=PRESENTE, 4451=AUSENTE, 4452=TARDE, 4453=FALTA_INJUSTIFICADA
    MetodoMarcacionID 4500=MANUAL, 4501=BIOMETRICO, 4502=QR, 4503=APP
	TipoPlanillaID 4600=SUELDOS, 4601=JORNALES, 4602=CONTRATO
	EstadoPlanillaID 4650=BORRADOR, 4651=CALCULADA, 4652=APROBADA, 4653=PAGADA, 4654=ANULADA
	TipoContratoID 4750=INDEFINIDO, 4751=FIJO, 4752=EVENTUAL, 4753=PRACTICAS, 4754=CONSULTORIA
    MonedaSueldoID 2300=BOB, 2301=USD, 2302=EUR
    TipoJornadaID 4800=COMPLETA, 4801=MEDIA, 4802=POR_HORAS
    EstadoContratoID 4700=VIGENTE, 4701=FINALIZADO, 4702=RENOVADO, 4703=SUSPENDIDO
Funciones: 
