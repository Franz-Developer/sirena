/*
	COMMENT ON DATABASE dbsirena IS
	'OBJETIVO GENERAL: Desarrollar e implementar la plataforma web modular "sirena" para gestión farmacéutica multi-sucursal bajo una arquitectura AK-47 de velocidad extrema y robustez ininterrumpida.
	REGLAS GENERALES (R.G. APLICABLES A TODAS LAS TABLAS):
	R.G.1: Registro Inicial Comodín: Las tablas maestras incorporan un registro inicial con pk_id = 1 ('NINGUNO' o 'NO APLICA') bajo estado_id = 1000 'ACTIVO'. Es inmodificable, ineliminable e inarchivable. Sirve como valor predeterminado (DEFAULT 1) en llaves foráneas para evitar nulos y asegurar la integridad referencial. Aparece en combos pero se excluye de listados operativos generales.
	R.G.2: Control de Estados: Todos los registros manejan obligatoriamente estado_id con cuatro valores normalizados: 1000 (ACTIVO - operativo, visible en grillas y combos, modificable), 1001 (BORRADO - baja lógica definitiva, requiere que los hijos estén borrados/históricos, excluido de grillas y combos), 1002 (HISTÓRICO - archivo inmutable de ciclos cerrados, reversible a activo, excluido de combos) y 1003 (ANULADO - exclusivo de kardex y comprobantes para operaciones abortadas, irreversible y testigo permanente de auditoría).
	R.G.3: Estructura de Auditoría Común: Todas las tablas incorporan obligatoriamente los campos de control al final: estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion y fecha_baja.
	R.G.4: Reemplazo Controlado de Archivos Multimedia: Al actualizar un registro con archivos físicos asociados, si se envía un archivo nuevo se sobrescribe en el servidor usando el identificador único existente; de lo contrario, se mantiene intacto el enlace previo.
	R.G.5: Documentación de Reglas Particulares: Toda tabla debe documentar sus reglas particulares empezando en R.1, evitando duplicar reglas generales, omitiendo redundancias de restricciones CHECK autoexplicativas y detallando la diferencia entre códigos, ambigüedades lógicas y contenidos de códigos QR o archivos.
	R.G.6: Archivos dependientes por defecto: El backend valida obligatoriamente la existencia física de archivos dependientes asociados al registro con pk_id = 1 o valores por defecto. Si faltan, el frontend emite una alarma e impide el acceso al módulo correspondiente.
	R.G.7: Validación de Dominios: Los campos con FK hacia la tabla dominios no deben validarse mediante constraints CHECK rígidos en las tablas transaccionales, permitiendo su correcta evolución a estados históricos o borrados. Toda restricción lógica de dominio debe documentarse mediante reglas específicas (R.XX).
	R.G.8: Nomenclatura de Archivos Dependientes: Los campos que almacenan nombres de archivos adjuntos o avatares deben tipificarse como VARCHAR(255) y su nomenclatura se genera estrictamente en el backend bajo el patrón: {timestamp}-{random}.{extension}.';
	
	SELECT
		datname AS base_datos,
		description AS reglas_generales_arquitectura
	FROM pg_database
	WHERE datname = 'dbsirena';

	SELECT
		c.relname AS tabla,
		obj_description(c.oid, 'pg_class') AS comentario
	FROM pg_class c
	JOIN pg_namespace n ON n.oid = c.relnamespace
	WHERE n.nspname = 'public' -- O el esquema donde se encuentre tu tabla
	AND c.relname = 'bancos';

*/

-- ================================================================================================

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT n.nspname AS schema_name, p.proname AS func_name, pg_get_function_identity_arguments(p.oid) AS func_args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
    ) LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE;', r.schema_name, r.func_name, r.func_args);
    END LOOP;
END $$;

-- ================================================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ================================================================================================

CREATE TABLE dominios (
    dominio_id INTEGER PRIMARY KEY,
    dominio VARCHAR(255) NOT NULL,
    abreviatura VARCHAR(40) NOT NULL,
    prefijo VARCHAR(15) NULL,
    valor INTEGER NOT NULL DEFAULT 0,
    es_protegido INTEGER NOT NULL DEFAULT 0,
    descripcion VARCHAR(3000) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_dom_dominio_not_empty CHECK (TRIM(dominio) <> ''),
    CONSTRAINT chk_dom_dominio_formato CHECK (dominio ~ '^[A-Za-zÁÉÍÓÚáéíóúÑñ]+$'),
    CONSTRAINT chk_dom_abreviatura_formato CHECK (abreviatura ~ '^[A-Z0-9_Ñ]+$')
);
CREATE UNIQUE INDEX uix_dom_unique ON dominios (dominio, abreviatura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dominios_dominio_activo ON dominios (dominio) WHERE fecha_baja IS NULL;
CREATE INDEX idx_dominios_estado_baja ON dominios (estado_id, fecha_baja) WHERE fecha_baja IS NULL;
CREATE INDEX idx_dominios_id_activo ON dominios (dominio_id) WHERE fecha_baja IS NULL;
CREATE INDEX idx_dominios_trgm_busqueda ON dominios USING gin ((dominio || ' ' || abreviatura || ' ' || COALESCE(prefijo, '')) gin_trgm_ops) WHERE fecha_baja IS NULL;
CREATE INDEX idx_dominios_fts_spanish 
ON dominios USING gin (
    to_tsvector('spanish', 
        COALESCE(dominio, '') || ' ' || 
        COALESCE(abreviatura, '') || ' ' || 
        COALESCE(prefijo, '') || ' ' || 
        COALESCE(descripcion, '')
    )
) 
WHERE fecha_baja IS NULL;

COMMENT ON TABLE dominios IS 'Reglas de la tabla - dominios
R.0: La tabla dominios actúa como el diccionario de datos maestro y paramétrico del sistema, centralizando todos los catálogos de valores fijos que gobiernan el comportamiento de la aplicación, como estados, tipos de documento, eventos y parámetros de configuración. Su propósito es garantizar la consistencia semántica y la integridad referencial de los datos operativos, evitando la proliferación de valores mágicos ("hard-coded") y proporcionando una única fuente de verdad para las restricciones CHECK y las listas de selección (combos, dropdowns) en la interfaz de usuario. Se conecta a través de claves foráneas con la práctica totalidad de las tablas maestras y transaccionales del sistema, sirviendo como la columna vertebral de la parametrización dinámica.
R.1: Los registros de esta tabla alimentan de forma dinámica los componentes de selección paramétrica del negocio.
R.2: El campo valor actúa como un código o identificador contextual cuya interpretación y formato dependen enteramente del dominio al que pertenece. Puede almacenar desde números secuenciales de orden interno hasta códigos alfanuméricos normalizados de sistemas externos (por ejemplo, los códigos de catálogos oficiales del SIAT para documentos, monedas, métodos de pago o motivos de anulación). Su propósito es servir de puente lógico para interfaces, interoperabilidad y reglas de negocio específicas sin alterar la estructura del diccionario.
R.3: Prefijo su interpretación depende del dominio. en el caso del dominio EventoID el prefijo ayuda a generar el codigo del evento. También puede ser usado como una abreviatura de abreviación.
R.4: La descripción debe explicar o definir la abreviatura.
R.5: El valor del campo dominio actúa como el nombre lógico del catálogo maestro (ej. ''EstadoID'', ''EventoID'', ''MonedaID''). Por estricta convención arquitectónica, cualquier columna en las tablas maestras o transaccionales que actúe como clave foránea hacia este diccionario debe nombrarse utilizando la raíz del nombre del dominio en minúsculas seguida del sufijo _id (por ejemplo, el dominio ''EstadoID'' se vincula mediante la columna estado_id). Excepción de Múltiples Relaciones: En escenarios donde una tabla requiera más de una clave foránea hacia el mismo dominio (por ejemplo, origen y destino), se permite anteponer un sufijo o prefijo descriptivo que precise su rol funcional (ej. origen_moneda_id y destino_moneda_id), siempre y cuando la raíz del dominio permanezca identificable para garantizar la predictibilidad del esquema y la integridad referencial.
R.6: El campo es_protegido actúa como un indicador booleano de seguridad (0 = No protegido, 1 = Protegido). Cuando su valor es 1, el registro pertenece al núcleo paramétrico del sistema y cuenta con protección no se edita, ni elimina.';

DELETE FROM dominios;

-- 1000: EstadoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1000,'EstadoID','ACTIVO',NULL,0,1,'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. DOMINIO POR DEFECTO.',1000,1),
(1001,'EstadoID','BORRADO',NULL,0,1,'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.',1000,1),
(1002,'EstadoID','HISTORICO',NULL,0,1,'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.',1000,1),
(1003,'EstadoID','ANULADO',NULL,0,1,'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.',1000,1);

-- 1050: EventoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1050,'EventoID','COMPRA','LOT',0,1,'Registro de ingreso de mercadería por compra a proveedor. Afecta positivamente el stock y genera cuentas por pagar. DOMINIO POR DEFECTO.',1000,1),
(1051,'EventoID','VENTA','VEN',0,1,'Registro de salida de mercadería por venta a cliente. Afecta negativamente el stock, genera facturación y movimiento de caja.',1000,1),
(1052,'EventoID','PROFORMA','PRO',0,1,'Cotización o presupuesto temporal que NO afecta stock ni finanzas. Solo documento informativo o estimación de precios.',1000,1),
(1053,'EventoID','EGRESO_TRASPASO','EGR',0,1,'Egreso de mercadería desde sucursal origen hacia destino. Disminuye stock en origen hasta confirmación en destino.',1000,1),
(1054,'EventoID','INGRESO_TRASPASO','ING',0,1,'Ingreso de mercadería a sucursal destino procedente de origen. Aumenta stock en destino al confirmar recepción.',1000,1),
(1055,'EventoID','ANULACION','ANU',0,1,'Cancelación de una transacción previa (compra o venta). Revierte automáticamente el stock afectado y deja registro inmutable para auditoría.',1000,1),
(1056,'EventoID','AJUSTE_INGRESO','AJI',0,1,'Incremento de stock por sobrante detectado en inventario físico. No genera transacción comercial.',1000,1),
(1057,'EventoID','AJUSTE_EGRESO','AJE',0,1,'Decremento de stock por faltante detectado en inventario físico. No genera transacción comercial.',1000,1),
(1058,'EventoID','SOLICITUD_COMPRA','SOL',0,1,'Pedido administrativo pendiente de aprobación. No afecta stock ni finanzas hasta su conversión a COMPRA (1050).',1000,1),
(1059,'EventoID','VENTA_RESERVA','VRE',0,1,'Proforma con reserva temporal de stock por tiempo limitado. Afecta negativamente el stock (lo aparta) y puede convertirse en VENTA (1051). Requiere validez_dias para definir plazo de reserva.',1000,1),
(1060,'EventoID','DEVOLUCION_CLIENTE','DCLI',0,1,'Devolución de mercadería por parte del cliente. Afecta positivamente el stock y requiere nota de crédito/débito fiscal si aplica.',1000,1),
(1061,'EventoID','DEVOLUCION_PROVEEDOR','DPRO',0,1,'Devolución de mercadería defectuosa o próxima a vencer al proveedor. Disminuye el stock y ajusta cuentas por pagar.',1000,1),
(1062,'EventoID','ROBO','ROB',0,1,'Salida extraordinaria de inventario por sustracción o robo detectado. Disminuye el stock sin contrapartida comercial y genera alerta de auditoría.',1000,1),
(1063,'EventoID','PERDIDA_CADUCIDAD','PCAD',0,1,'Baja de stock por productos vencidos o caducados detectados en control de almacén. Afecta como pérdida operativa.',1000,1),
(1064,'EventoID','MERMA_ROTURA','MER',0,1,'Salida de stock por daño físico, rotura o deterioro de medicamentos. No genera transacción comercial.',1000,1),
(1065,'EventoID','INVENTARIO_FISICO_SOBRANTE','IFSO',0,1,'Ajuste positivo por conteo físico de inventario (diferencia a favor respecto al sistema).',1000,1),
(1066,'EventoID','INVENTARIO_FISICO_FALTANTE','IFFAL',0,1,'Ajuste negativo por conteo físico de inventario (diferencia en contra o merma no identificada).',1000,1),
(1067,'EventoID','CONVERSION_UNIDADES','CENV',0,1,'Salida de productos en empaque mayor (cajas/blísteres) y reingreso automático como unidades sueltas por fraccionamiento.',1000,1),
(1068,'EventoID','RETIRO_CUARENTENA','RCUA',0,1,'Salida temporal o definitiva de stock retenido por alerta sanitaria o control de calidad. Bloquea o saca la mercadería de la disponibilidad comercial.',1000,1),
(1069,'EventoID','INGRESO_DONACION','DON',0,1,'Ingreso de mercadería por donación o recepción sin costo. Afecta positivamente el stock sin generar obligación de pago.',1000,1),
(1070,'EventoID','LIBERACION_RESERVA','LRES',0,1,'Liberación de stock retenido por expiración de tiempo o anulación de reserva. Reintegra el stock disponible.',1000,1);

-- 1100: TipoComprobanteID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1100,'TipoComprobanteID','FACTURA',NULL,0,1,'Documento fiscal oficial emitido por el SIN. Genera obligación tributaria y derecho a crédito fiscal. Utilizado en ventas formales que requieren comprobante fiscal.',1000,1),
(1101,'TipoComprobanteID','RECIBO',NULL,0,1,'Documento interno de pago sin valor fiscal. Utilizado para comprobantes de pago, abonos parciales o registro de ingresos/egresos operativos.',1000,1),
(1102,'TipoComprobanteID','OTRO',NULL,0,1,'Comprobante no clasificado en las categorías anteriores. Utilizado para documentos especiales o casos excepcionales.',1000,1),
(1103,'TipoComprobanteID','NINGUNO',NULL,0,1,'Sin comprobante fiscal definido. DOMINIO POR DEFECTO.',1000,1);

-- 1150: TipoClienteID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1150,'TipoClienteID','NATURAL',NULL,0,0,'Persona física individual. Requiere documento de identidad (CI, CEX, Pasaporte) para facturación. Puede tener límite de crédito personal. DOMINIO POR DEFECTO.',1000,1),
(1151,'TipoClienteID','JURIDICA',NULL,0,0,'Persona jurídica, empresa o institución. Requiere NIT y razón social obligatoria para facturación. Puede tener límite de crédito corporativo y condiciones especiales de pago.',1000,1);

-- 1200: GeneroID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1200,'GeneroID','MASCULINO',NULL,0,1,'Género masculino. Utilizado en trabajadores y clientes. Determina el conjunto de estados civiles disponibles (1250-1254). DOMINIO POR DEFECTO.',1000,1),
(1201,'GeneroID','FEMENINO',NULL,0,1,'Género femenino. Utilizado en trabajadores y clientes. Determina el conjunto de estados civiles disponibles (1300-1304).',1000,1);

-- 1250: EstadoCivilMasculinoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1250,'EstadoCivilMasculinoID','SOLTERO',NULL,0,1,'Estado civil soltero para género masculino. Aplica a trabajadores y clientes de sexo masculino que no tienen vínculo conyugal legal. DOMINIO POR DEFECTO.',1000,1),
(1251,'EstadoCivilMasculinoID','CASADO',NULL,0,1,'Estado civil casado para género masculino. Aplica a trabajadores y clientes de sexo masculino que tienen vínculo conyugal legal registrado.',1000,1),
(1252,'EstadoCivilMasculinoID','DIVORCIADO',NULL,0,1,'Estado civil divorciado para género masculino. Aplica a trabajadores y clientes de sexo masculino que han disuelto legalmente su vínculo conyugal.',1000,1),
(1253,'EstadoCivilMasculinoID','VIUDO',NULL,0,1,'Estado civil viudo para género masculino. Aplica a trabajadores y clientes de sexo masculino cuyo cónyuge ha fallecido.',1000,1),
(1254,'EstadoCivilMasculinoID','UNION_LIBRE',NULL,0,1,'Unión libre o de hecho para género masculino. Aplica a trabajadores y clientes de sexo masculino que conviven en pareja sin vínculo matrimonial legal.',1000,1);

-- 1300: EstadoCivilFemeninoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1300,'EstadoCivilFemeninoID','SOLTERA',NULL,0,1,'Estado civil soltera para género femenino. Aplica a trabajadoras y clientas de sexo femenino que no tienen vínculo conyugal legal. DOMINIO POR DEFECTO.',1000,1),
(1301,'EstadoCivilFemeninoID','CASADA',NULL,0,1,'Estado civil casada para género femenino. Aplica a trabajadoras y clientas de sexo femenino que tienen vínculo conyugal legal registrado.',1000,1),
(1302,'EstadoCivilFemeninoID','DIVORCIADA',NULL,0,1,'Estado civil divorciada para género femenino. Aplica a trabajadoras y clientas de sexo femenino que han disuelto legalmente su vínculo conyugal.',1000,1),
(1303,'EstadoCivilFemeninoID','VIUDA',NULL,0,1,'Estado civil viuda para género femenino. Aplica a trabajadoras y clientas de sexo femenino cuyo cónyuge ha fallecido.',1000,1),
(1304,'EstadoCivilFemeninoID','UNION_LIBRE',NULL,0,1,'Unión libre o de hecho para género femenino. Aplica a trabajadoras y clientas de sexo femenino que conviven en pareja sin vínculo matrimonial legal.',1000,1);

-- 1350: TipoVentaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1350,'TipoVentaID','NINGUNO','NIN',0,1,'Sin tipo de venta definido. Utilizado exclusivamente en transacciones de compra a proveedores, proformas y ajustes de inventario. No aplica a ventas a clientes. DOMINIO POR DEFECTO.',1000,1),
(1351,'TipoVentaID','CON_FACTURA','CF',0,1,'Venta formal con emisión de factura fiscal. Genera documento válido ante el SIN, permite crédito fiscal al cliente y debe estar asociada a una dosificación vigente en facturas.',1000,1),
(1352,'TipoVentaID','SIN_FACTURA','SF',0,1,'Venta sin emisión de factura fiscal. Utilizada para ventas de mostrador, ventas a consumidor final sin exigencia de factura o transacciones que no requieren comprobante fiscal. No genera crédito fiscal.',1000,1);

-- 1400: TipoPagoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1400,'TipoPagoID','NINGUNO','NIN',0,1,'Sin medio de pago definido. Utilizado exclusivamente en transacciones que no involucran cobro o pago (compras, proformas, ajustes de inventario, traspasos). No aplica para ventas a clientes. DOMINIO POR DEFECTO.',1000,1),
(1401,'TipoPagoID','EFECTIVO','EF',1,1,'Pago en efectivo en moneda local o extranjera. Aplica para ventas de mostrador y cobros inmediatos. No requiere verificación bancaria ni comprobante digital adicional.',1000,1),
(1402,'TipoPagoID','TARJETA','TA',2,1,'Pago mediante tarjeta.',1000,1),
(1403,'TipoPagoID','CHEQUE','CH',3,1,'Pago mediante cheque bancario. Requiere verificación de fondos y autorización previa. Debe registrarse número de cheque, banco emisor y fecha de cobro. Aplica para ventas a empresas o clientes con convenio.',1000,1),
(1404,'TipoPagoID','VALE','VL',4,1,'Pago mediante vale.',1000,1),
(1405,'TipoPagoID','OTROS','OT',5,1,'Otros medio de pago no contemplado en la lista. Requiere descripción detallada en el campo observaciones. Aplica para casos excepcionales, vales de salud, bonos o pagos en especie.',1000,1),
(1406,'TipoPagoID','SIN_PAGO','SP',6,1,'Sin Pago.',1000,1),
(1407,'TipoPagoID','TRANSFERENCIA','TR',7,1,'Pago mediante transferencia bancaria (electrónica o ventanilla). Requiere comprobante de transferencia para validación. Aplica para pagos interbancarios, ventas corporativas o clientes a distancia.',1000,1),
(1408,'TipoPagoID','DEPOSITO','DP',8,1,'Pago mediante depósito en cuenta bancaria de la empresa. Requiere comprobante de depósito obligatorio (voucher o captura). Aplica para pagos en ventanilla, convenios con aseguradoras o clientes sin acceso a transferencia.',1000,1),
(1409,'TipoPagoID','QR','QR',9,1,'Pago mediante código QR a través de plataformas de pago (SIN, QRs, Yape, etc.). Genera comprobante digital automático. Aplica para pagos electrónicos rápidos.',1000,1);

-- 1450: TipoModeloID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1450,'TipoModeloID','ARIMA',NULL,0,0,'Modelo ARIMA (Autoregressive Integrated Moving Average) para pronóstico de demanda de productos sin componente estacional significativa. Aplica para productos de consumo regular y estable.',1000,1),
(1451,'TipoModeloID','SARIMA',NULL,0,0,'Modelo SARIMA (Seasonal ARIMA) para pronóstico de demanda con componente estacional semanal, mensual o anual. Aplica para productos con patrones estacionales (alergias, gripes, vacaciones).',1000,1),
(1452,'TipoModeloID','SERIES_TEMPORALES',NULL,0,0,'Modelo genérico de series temporales para análisis de tendencias y patrones de consumo. Utilizado como base para otros modelos más específicos.',1000,1),
(1453,'TipoModeloID','CLASIFICACION',NULL,0,0,'Modelo de clasificación para segmentación de productos, clientes o proveedores. Incluye técnicas como K-Means, ABC, RFM y clustering jerárquico.',1000,1),
(1454,'TipoModeloID','OPTIMIZACION',NULL,0,0,'Modelo de optimización para cálculo de niveles óptimos de inventario, puntos de reorden (ROP), stock de seguridad y cantidades económicas de pedido (EOQ).',1000,1),
(1455,'TipoModeloID','DETECCION_ANOMALIAS',NULL,0,0,'Modelo para detección de anomalías en patrones de consumo, ventas y stock. Identifica comportamientos atípicos, fraudes y errores operativos.',1000,1),
(1456,'TipoModeloID','NINGUNO',NULL,0,0,'Sin modelo definido. Para productos o módulos que no requieren análisis predictivo o no tienen datos suficientes. DOMINIO POR DEFECTO.',1000,1);

-- 1500: TipoBeneficioID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1500,'TipoBeneficioID','DESCUENTO',NULL,0,0,'Beneficio genérico que agrupa diferentes tipos de descuentos. Utilizado como categoría superior para promociones que reducen el precio final del producto.',1000,1),
(1501,'TipoBeneficioID','PORCENTAJE',NULL,0,0,'Descuento porcentual sobre el precio de venta del producto. Fórmula: PrecioFinal = PrecioBase * (1 - ValorBeneficio/100). Aplica para promociones por temporada o liquidación.',1000,1),
(1502,'TipoBeneficioID','MONTO_FIJO',NULL,0,0,'Descuento de monto fijo en moneda local sobre el precio del producto. Fórmula: PrecioFinal = PrecioBase - ValorBeneficio. Aplica para promociones por volumen o cupones de descuento.',1000,1),
(1503,'TipoBeneficioID','CANTIDAD',NULL,0,0,'Descuento basado en cantidad de unidades adquiridas (ej. 2x1, 3x2). Fórmula: Se aplica sobre la cantidad total del ítem. Aplica para promociones de incentivo por volumen.',1000,1),
(1504,'TipoBeneficioID','NINGUNO',NULL,0,0,'Sin beneficio o promoción definida. Para productos sin oferta activa o cuando no se aplica descuento. DOMINIO POR DEFECTO.',1000,1);

-- 1550: EstadoPronosticoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1550,'EstadoPronosticoID','PENDIENTE',NULL,0,0,'Pronóstico en cola de espera para procesamiento. El modelo aún no ha generado la predicción. Aplica para solicitudes de pronóstico recién creadas o en espera de ejecución.',1000,1),
(1551,'EstadoPronosticoID','PROCESADO',NULL,0,0,'Pronóstico completado exitosamente. El modelo generó la predicción y los resultados están disponibles en analitica_productos. Aplica para pronósticos que finalizaron sin errores.',1000,1),
(1552,'EstadoPronosticoID','ERROR',NULL,0,0,'Pronóstico fallido por error en el procesamiento. Puede deberse a datos insuficientes, errores en el modelo o fallos técnicos. Requiere revisión manual y posible reentrenamiento.',1000,1),
(1553,'EstadoPronosticoID','NINGUNO',NULL,0,0,'Sin estado de pronóstico definido. Para productos que no han sido procesados por el motor de IA o que no requieren pronóstico. DOMINIO POR DEFECTO.',1000,1);

-- 1600: TemporadaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1600,'TemporadaID','NINGUNO',NULL,0,0,'Sin temporada definida o período transicional sin estacionalidad marcada. Para productos con demanda constante o cuando no hay datos suficientes para clasificar. DOMINIO POR DEFECTO.',1000,1),
(1601,'TemporadaID','ALTA',NULL,0,0,'Temporada de demanda alta con incremento significativo en ventas. Aplica en períodos de enfermedades estacionales (gripe, alergias, dengue), eventos especiales o campañas promocionales intensivas.',1000,1),
(1602,'TemporadaID','MEDIA',NULL,0,0,'Temporada de demanda media o regular con comportamiento estable dentro de los patrones normales. Aplica en períodos intermedios sin picos ni caídas significativas.',1000,1),
(1603,'TemporadaID','BAJA',NULL,0,0,'Temporada de demanda baja con decremento notable en ventas. Aplica en períodos de baja incidencia de enfermedades, vacaciones o cuando el consumo disminuye estacionalmente.',1000,1);

-- 1650: EstadoFiscalID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1650,'EstadoFiscalID','ACTIVO',NULL,0,0,'Dosificación fiscal vigente y operativa. Permite la emisión de facturas electrónicas con validez ante el SIN. El sistema puede generar comprobantes fiscales sin restricciones. DOMINIO POR DEFECTO.',1000,1),
(1651,'EstadoFiscalID','AGOTADO',NULL,0,0,'Rango de numeración de facturas completamente consumido. No es posible emitir más facturas con esta dosificación. Se debe solicitar una nueva autorización al SIN. Bloquea automáticamente la emisión de comprobantes.',1000,1),
(1652,'EstadoFiscalID','VENCIDO',NULL,0,0,'Fecha de vigencia de la dosificación superada según lo establecido por el SIN. No es posible emitir facturas con esta autorización vencida. Se debe renovar la dosificación ante el SIN.',1000,1),
(1653,'EstadoFiscalID','CANCELADO',NULL,0,0,'Dosificación anulada o cancelada por decisión administrativa o por disposición del SIN. No es posible emitir facturas con esta autorización. Estado irreversible que mantiene el registro histórico para auditoría.',1000,1);

-- 1700: TipoAlmacenID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1700,'TipoAlmacenID','NORMAL',NULL,0,0,'Almacén de temperatura ambiente (15°C a 30°C) para productos que no requieren condiciones especiales de conservación. Aplica para la mayoría de medicamentos de venta libre y productos de consumo regular. DOMINIO POR DEFECTO.',1000,1),
(1701,'TipoAlmacenID','REFRIGERADO',NULL,0,0,'Almacén refrigerado con temperatura controlada (2°C a 8°C). Para vacunas, insulinas, biológicos y medicamentos termolábiles que requieren cadena de frío. Equipado con monitoreo de temperatura continua.',1000,1),
(1702,'TipoAlmacenID','CONGELADO',NULL,0,0,'Almacén congelado con temperatura controlada (-18°C o menor). Para productos biológicos, hemoderivados y medicamentos que requieren congelación profunda para su conservación.',1000,1),
(1703,'TipoAlmacenID','ESPECIAL',NULL,0,0,'Almacén de alta seguridad para productos controlados (psicotrópicos, estupefacientes, sustancias fiscalizadas). Requiere doble llave, registro de accesos y control de inventario riguroso según normativa vigente.',1000,1),
(1704,'TipoAlmacenID','TRANSITO',NULL,0,0,'Almacén temporal para mercadería en tránsito entre sucursales o en proceso de distribución. Productos con estado de "en movimiento" que no están disponibles para venta hasta su recepción en destino.',1000,1),
(1705,'TipoAlmacenID','MATERIAL_MEDICO',NULL,0,0,'Almacén para material médico-quirúrgico, dispositivos médicos, insumos descartables (jeringas, guantes, gasas) y equipos de diagnóstico. No requiere condiciones especiales de temperatura.',1000,1),
(1706,'TipoAlmacenID','COSMETICA',NULL,0,0,'Almacén para productos cosméticos, de cuidado personal, higiene y belleza. Incluye cremas, lociones, shampoos, perfumes y productos de maquillaje.',1000,1),
(1707,'TipoAlmacenID','ALIMENTOS',NULL,0,0,'Almacén para suplementos nutricionales, alimentos funcionales, vitaminas, minerales y productos dietéticos. Requiere condiciones de humedad controlada y protección contra contaminación cruzada.',1000,1),
(1708,'TipoAlmacenID','MATERIA_PRIMA',NULL,0,0,'Almacén para materias primas utilizadas en farmacia magistral o preparación de fórmulas personalizadas. Incluye principios activos, excipientes, vehículos y materiales de acondicionamiento.',1000,1),
(1709,'TipoAlmacenID','RECEPCION',NULL,0,0,'Área de recepción de mercadería y control de calidad. Zona de tránsito para productos que ingresan al sistema, pendientes de verificación, conteo y asignación a su almacén definitivo.',1000,1),
(1710,'TipoAlmacenID','DEVOLUCIONES',NULL,0,0,'Área para productos en proceso de devolución a proveedores o clientes. Incluye productos defectuosos, vencidos, dañados o en espera de gestión de devolución.',1000,1),
(1711,'TipoAlmacenID','DESPACHO',NULL,0,0,'Área de despacho, consolidación de pedidos y preparación de entregas. Productos que han sido seleccionados (picking) y están listos para distribución a clientes o traslado entre sucursales.',1000,1),
(1712,'TipoAlmacenID','CUARENTENA',NULL,0,0,'Área de cuarentena sanitaria para productos en revisión, análisis o evaluación. Incluye productos sospechosos de contaminación, lotes en investigación o productos pendientes de liberación por control de calidad.',1000,1);

-- 1750: TipoCuentaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1750,'TipoCuentaID','CUENTA_CORRIENTE',NULL,0,0,'Cuenta corriente bancaria para operaciones diarias. Permite emisión de cheques, débitos automáticos y múltiples transacciones sin límite de operaciones. Ideal para cuentas empresariales con alta rotación. Aplica para cuentas de la empresa y de clientes corporativos.',1000,1),
(1751,'TipoCuentaID','CAJA_AHORROS',NULL,0,0,'Cuenta de ahorros para depósitos y retiros con disponibilidad inmediata. Generalmente genera intereses y tiene límite de operaciones mensuales. Ideal para ahorro personal y cuentas de clientes individuales.',1000,1),
(1752,'TipoCuentaID','AHORRO_PROGRAMADO',NULL,0,0,'Cuenta de ahorro con depósitos programados en fechas fijas (mensuales, quincenales). Permite acumulación de fondos con propósitos específicos. Aplica para clientes con planes de ahorro o empresas que manejan fondos de reserva.',1000,1),
(1753,'TipoCuentaID','PLAZO_FIJO',NULL,0,0,'Depósito a plazo fijo con tasa de interés definida y fecha de vencimiento determinada. No permite retiros anticipados sin penalización. Aplica para inversiones de capital de trabajo o excedentes de caja.',1000,1),
(1754,'TipoCuentaID','INVERSION',NULL,0,0,'Cuenta de inversión con diferentes instrumentos financieros (acciones, bonos, fondos mutuos). Mayor rendimiento potencial con mayor riesgo asociado. Aplica para empresas con estrategias de inversión diversificadas.',1000,1),
(1755,'TipoCuentaID','NO_APLICA',NULL,0,0,'No aplica. Utilizado como valor por defecto cuando no se registra información de cuenta bancaria. Aplica para clientes sin cuenta asociada, transacciones en efectivo o cuando el medio de pago no requiere cuenta bancaria. DOMINIO POR DEFECTO.',1000,1);

-- 1800: TipoDatoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1800,'TipoDatoID','STRING',NULL,0,1,'Tipo de dato para valores de texto. Acepta caracteres alfanuméricos, espacios y símbolos. Ejemplos: "BOB", "VEN", "CASA_MATRIZ". DOMINIO POR DEFECTO.',1000,1),
(1801,'TipoDatoID','INTEGER',NULL,0,1,'Tipo de dato para valores numéricos enteros. Acepta solo dígitos (0-9), sin puntos, comas o signos. Ejemplos: "50", "7", "365".',1000,1),
(1802,'TipoDatoID','DECIMAL',NULL,0,1,'Tipo de dato para valores numéricos con decimales. Acepta dígitos con punto decimal opcional. Ejemplos: "13.00", "0.95", "1.50".',1000,1),
(1803,'TipoDatoID','BOOLEAN',NULL,0,1,'Tipo de dato para valores lógicos binarios. Acepta exclusivamente "1" (VERDADERO/SI) o "0" (FALSO/NO).',1000,1);

-- 1850: NivelUrgenciaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1850,'NivelUrgenciaID','BAJA',NULL,0,0,'Nivel de urgencia bajo. Situación monitoreable sin acción inmediata. Tiempo de respuesta sugerido: 24-48 horas. Aplica para alertas informativas o de seguimiento sin impacto crítico en operaciones.',1000,1),
(1851,'NivelUrgenciaID','MEDIA',NULL,0,0,'Nivel de urgencia medio. Requiere atención en el corto plazo pero no bloquea operaciones críticas. Tiempo de respuesta sugerido: 4-8 horas. Aplica para alertas que requieren evaluación y posible ajuste.',1000,1),
(1852,'NivelUrgenciaID','ALTA',NULL,0,0,'Nivel de urgencia alto. Requiere atención prioritaria y puede afectar operaciones si no se aborda. Tiempo de respuesta sugerido: 1-2 horas. Aplica para alertas de stock crítico, vencimientos inminentes o desviaciones significativas.',1000,1),
(1853,'NivelUrgenciaID','CRITICA',NULL,0,0,'Nivel de urgencia crítico. Requiere acción inmediata porque bloquea operaciones esenciales o representa un riesgo grave. Tiempo de respuesta sugerido: inmediato (< 30 minutos). Aplica para quiebre de stock de medicamentos esenciales, fallos en cadena de frío o alertas de seguridad.',1000,1),
(1854,'NivelUrgenciaID','NINGUNO',NULL,0,0,'Sin nivel de urgencia definido. Para casos donde no aplica clasificación de urgencia. DOMINIO POR DEFECTO.',1000,1);

-- 1900: MotivoOutlierID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1900,'MotivoOutlierID','BLOQUEO',NULL,0,0,'Anomalía por bloqueo de caminos, protestas sociales, restricciones de movilidad o desastres naturales que afectan la distribución y disponibilidad de productos. Ajusta pronósticos considerando interrupciones externas.',1000,1),
(1901,'MotivoOutlierID','FERIADO_LOCAL',NULL,0,0,'Anomalía por día festivo local no considerado en el calendario estándar. Incluye feriados departamentales, municipales o religiosos que afectan patrones de consumo y operación.',1000,1),
(1902,'MotivoOutlierID','ERROR_SISTEMA',NULL,0,0,'Anomalía por error en registro de datos, fallos en integración con otros sistemas o problemas técnicos que generan datos inconsistentes. Requiere revisión y corrección manual.',1000,1),
(1903,'MotivoOutlierID','PICO_ANORMAL',NULL,0,0,'Anomalía por pico anormal de demanda no repetible. Incluye eventos puntuales como epidemias, campañas de vacunación masiva o promociones extraordinarias que distorsionan el patrón histórico.',1000,1),
(1904,'MotivoOutlierID','ROTURA',NULL,0,0,'Anomalía por rotura, daño físico, deterioro o contaminación de material. Genera pérdida de inventario y requiere ajuste por merma. Aplica para productos dañados en almacén o durante el transporte.',1000,1),
(1905,'MotivoOutlierID','ROBO',NULL,0,0,'Anomalía por robo, hurto o sustracción de mercadería detectada en inventario. Genera pérdida de stock y requiere ajuste negativo con reporte a seguridad. Aplica para faltantes no justificados.',1000,1),
(1906,'MotivoOutlierID','SOBRANTE',NULL,0,0,'Anomalía por sobrante detectado en inventario físico. Genera ajuste positivo de stock. Generalmente ocasionado por errores de conteo previo, recepciones sin registrar o devoluciones no contabilizadas.',1000,1),
(1907,'MotivoOutlierID','NINGUNO',NULL,0,0,'Sin motivo de outlier definido. Cuando no se identifica una causa específica para la anomalía o cuando el pronóstico no presenta desviaciones significativas. DOMINIO POR DEFECTO.',1000,1);

-- 1950: FormatoPDFID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1950,'FormatoPDFID','ESTANDAR',NULL,0,0,'Formato estándar de factura con todos los datos fiscales requeridos por el SIN. Incluye información completa del emisor, receptor, detalle de productos, impuestos desglosados y códigos de control. Aplica para facturación regular. DOMINIO POR DEFECTO.',1000,1),
(1951,'FormatoPDFID','RESUMIDO',NULL,0,0,'Formato resumido con información esencial y diseño compacto. Incluye solo los datos fiscales obligatorios: emisor, receptor, totales e impuestos. Omite detalles extensos. Aplica para tickets rápidos, ventas de mostrador o comprobantes internos.',1000,1),
(1952,'FormatoPDFID','DETALLADO',NULL,0,0,'Formato extendido con información completa y adicional. Incluye todos los datos del estándar más información complementaria: desglose por lote, fechas de vencimiento, registros sanitarios, datos del laboratorio y notas adicionales. Aplica para facturas a instituciones o clientes corporativos.',1000,1);

-- 2000: EstadoModeloID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2000,'EstadoModeloID','SIN_DATOS',NULL,0,0,'Estado inicial cuando un producto no cuenta con datos históricos suficientes para entrenar el modelo. Requiere mínimo de registros configurado en parametros_globales. El modelo no genera predicciones hasta acumular datos suficientes. DOMINIO POR DEFECTO.',1000,1),
(2001,'EstadoModeloID','ENTRENANDO',NULL,0,0,'Modelo en proceso de entrenamiento. El motor de IA está calculando parámetros, ajustando hiperparámetros y validando el modelo con datos históricos. No genera predicciones hasta finalizar el proceso.',1000,1),
(2002,'EstadoModeloID','ACTIVO',NULL,0,0,'Modelo entrenado exitosamente y en producción. Genera predicciones de demanda, puntos de reorden y análisis de tendencias. Se actualiza periódicamente según frecuencia configurada. Estado operativo deseado para modelos funcionales.',1000,1),
(2003,'EstadoModeloID','RECHAZADO',NULL,0,0,'Modelo rechazado por error de predicción (MAPE) superior al umbral permitido. No genera predicciones hasta que se reentrene con mejores datos o se ajusten los parámetros. Requiere revisión manual.',1000,1),
(2004,'EstadoModeloID','OBSOLETO',NULL,0,0,'Modelo reemplazado por una versión más reciente o mejorada. Se mantiene en histórico para trazabilidad y comparación, pero ya no se utiliza para predicciones activas. Puede reactivarse si es necesario.',1000,1);

-- 2050: CalidadRatingID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2050,'CalidadRatingID','PESIMO',NULL,0,0,'Calificación más baja. Proveedor con incumplimientos graves en plazos de entrega, productos defectuosos recurrentes o problemas de calidad crítica. Se recomienda evaluar discontinuación de la relación comercial.',1000,1),
(2051,'CalidadRatingID','DEFICIENTE',NULL,0,0,'Calificación baja. Proveedor con incumplimientos frecuentes en calidad o plazos. Requiere supervisión estricta y seguimiento continuo. Se recomienda restringir volumen de compras.',1000,1),
(2052,'CalidadRatingID','REGULAR',NULL,0,0,'Calificación media. Proveedor que cumple con lo mínimo esperado pero sin destacar. Presenta algunos incumplimientos ocasionales. Se recomienda monitoreo periódico y definir plan de mejora.',1000,1),
(2053,'CalidadRatingID','BUENO',NULL,0,0,'Calificación alta. Proveedor confiable que cumple consistentemente con plazos y calidad. Presenta incumplimientos menores y excepcionales. Se recomienda mantener relación y considerar aumentar volumen de compras.',1000,1),
(2054,'CalidadRatingID','EXCELENTE',NULL,0,0,'Calificación máxima. Proveedor destacado que supera expectativas en calidad, plazos, servicio y precio. Presenta incumplimientos nulos o insignificantes. Se recomienda priorizar en compras y establecer alianzas estratégicas.',1000,1),
(2055,'CalidadRatingID','NINGUNO',NULL,0,0,'Sin calificación de calidad definida. Para proveedores nuevos o cuando aún no se ha realizado evaluación formal de desempeño. DOMINIO POR DEFECTO.',1000,1);

-- 2100: EstadoTraspasoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2100,'EstadoTraspasoID','EN_TRANSITO',NULL,0,1,'Mercancía en tránsito entre sucursales. Stock disminuido en origen pero aún no disponible en destino. El producto no está disponible para venta en ninguna de las dos sucursales durante el traslado. Estado inicial al generar el traspaso.',1000,1),
(2101,'EstadoTraspasoID','RECIBIDO',NULL,0,1,'Mercancía recibida y confirmada en sucursal destino. Stock incrementado en destino y el producto queda disponible para venta. El traspaso se considera completado exitosamente. Estado final del flujo.',1000,1),
(2102,'EstadoTraspasoID','RECHAZADO',NULL,0,1,'Traspaso cancelado o rechazado. Reversión automática del stock en origen (se restituye la cantidad disminuida). No se realiza incremento en destino. Aplica por falta de productos, daños en transporte o decisión administrativa.',1000,1),
(2103,'EstadoTraspasoID','NO_APLICA',NULL,0,1,'Estado por defecto para transacciones que no son traspasos inter-sucursales. Aplica para compras, ventas, proformas, ajustes y cualquier otro evento que no involucre movimiento entre almacenes. DOMINIO POR DEFECTO.',1000,1);

-- 2150: ModuloEstrategicoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2150,'ModuloEstrategicoID','FLUJO_CAJA',NULL,0,0,'Módulo de análisis y pronóstico de flujo de caja e ingresos. Utiliza modelos ARIMA y LSTM para predecir ingresos, identificar estacionalidades y optimizar liquidez. Aplica para planificación financiera y gestión de tesorería.',1000,1),
(2151,'ModuloEstrategicoID','DEMANDA_INVENTARIO',NULL,0,0,'Módulo de pronóstico de demanda y optimización de inventario. Utiliza XGBoost para predicción de demanda y EOQ (Economic Order Quantity) para niveles óptimos de stock. Aplica para gestión de compras y reducción de quiebres.',1000,1),
(2152,'ModuloEstrategicoID','PROVEEDORES_AHP',NULL,0,0,'Módulo de evaluación y gestión de proveedores. Utiliza AHP (Analytic Hierarchy Process) y sistemas de scoring para calificar desempeño. Aplica para selección de proveedores, negociación y evaluación continua.',1000,1),
(2153,'ModuloEstrategicoID','OPERACION_MERMAS',NULL,0,0,'Módulo de análisis de operaciones diarias y control de mermas. Utiliza Teoría de Colas para optimizar atención y algoritmos genéticos para minimizar pérdidas. Aplica para eficiencia operativa y reducción de desperdicios.',1000,1),
(2154,'ModuloEstrategicoID','CLIENTES_RFM',NULL,0,0,'Módulo de segmentación y análisis de clientes. Utiliza RFM (Recencia, Frecuencia, Monto), K-Means y CLV (Customer Lifetime Value). Aplica para campañas de fidelización y marketing personalizado.',1000,1),
(2155,'ModuloEstrategicoID','PRECIOS_ELASTICIDAD',NULL,0,0,'Módulo de optimización de precios y análisis de márgenes. Utiliza modelos de elasticidad de demanda y reglas de asociación Apriori. Aplica para estrategias de precios y maximización de rentabilidad.',1000,1),
(2156,'ModuloEstrategicoID','ANOMALIAS_FRAUDE',NULL,0,0,'Módulo de detección de anomalías y prevención de fraude. Utiliza Isolation Forest y LOF (Local Outlier Factor). Aplica para identificación de comportamientos sospechosos en ventas, inventario y pagos.',1000,1),
(2157,'ModuloEstrategicoID','NINGUNO',NULL,0,0,'Sin módulo estratégico definido. Valor por defecto para tareas y procesos que no pertenecen a un módulo específico o que aún no han sido clasificados. DOMINIO POR DEFECTO.',1000,1);

-- 2200: TipoDocumentoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2200,'TipoDocumentoID','CEDULA_IDENTIDAD','CI',1,0,'Cédula de identidad boliviana. Documento nacional emitido por el SEGIP. Formato: numérico (ej. 1234567) o con complemento (ej. 1234567-1A). DOMINIO POR DEFECTO.',1000,1),
(2201,'TipoDocumentoID','CEDULA_IDENTIDAD_EXTRANJERO','CEX',2,0,'Cédula de identidad de extranjero. Documento para residentes no bolivianos emitido por el SEGIP. Formato: numérico con prefijo (ej. 1234567-1). Utilizado para extranjeros con residencia.',1000,1),
(2202,'TipoDocumentoID','PASAPORTE','PAS',3,0,'Pasaporte. Documento de identidad internacional emitido por autoridades migratorias de cada país. Formato: alfanumérico variable (ej. AB123456). Utilizado para extranjeros sin residencia.',1000,1),
(2203,'TipoDocumentoID','OTRO','OTRO',4,0,'Otro tipo de documento de identidad no contemplado en las categorías anteriores. Utilizado para casos excepcionales, documentos diplomáticos, cédulas especiales o documentos temporales.',1000,1),
(2204,'TipoDocumentoID','NIT','NIT',5,0,'Número de Identificación Tributaria. Emitido por el Servicio de Impuestos Nacionales (SIN). Formato: numérico de 7-10 dígitos (ej. 1023456021).',1000,1);

-- 2250: EstadoPedidoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2250,'EstadoPedidoID','COTIZADO','COT',1,0,'Pedido cotizado y en espera de aprobación administrativa. No afecta stock ni genera obligación de compra. Estado inicial del flujo. DOMINIO POR DEFECTO.',1000,1),
(2251,'EstadoPedidoID','APROBADO','APR',2,0,'Pedido aprobado por administración y enviado al proveedor. En proceso de gestión de compra. Aún no afecta stock ni inventario.',1000,1),
(2252,'EstadoPedidoID','EN_RUTA','RUT',3,0,'Pedido despachado por el proveedor y en tránsito hacia la farmacia. No afecta stock hasta su recepción física. Requiere seguimiento logístico.',1000,1),
(2253,'EstadoPedidoID','RECIBIDO','REC',4,0,'Pedido recibido completamente en almacén. Incrementa stock según los lotes y cantidades registradas. Estado final exitoso del flujo.',1000,1),
(2254,'EstadoPedidoID','PARCIAL','PAR',5,0,'Pedido recibido de forma parcial. Parte de la mercadería fue recibida, pero faltan productos por llegar. Genera incremento parcial de stock y requiere seguimiento de pendientes.',1000,1),
(2255,'EstadoPedidoID','RECHAZADO','RCH',6,0,'Pedido rechazado por problemas de calidad, incumplimiento de especificaciones o condiciones. No afecta stock. Requiere gestión de devolución o reclamo al proveedor.',1000,1),
(2256,'EstadoPedidoID','CANCELADO','CAN',7,0,'Pedido cancelado por decisión del proveedor o de la farmacia antes de su recepción. No afecta stock. Estado final sin ejecución.',1000,1);

-- 2300: TipoMonedaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2300,'TipoMonedaID','BOLIVIANO','BOB',1,1,'Boliviano (Bs.). Moneda oficial de Bolivia. Utilizada como moneda base del sistema para todas las transacciones locales, facturación y reportes financieros. DOMINIO POR DEFECTO.',1000,1),
(2301,'TipoMonedaID','DOLAR','USD',2,1,'Dólar estadounidense ($). Moneda de referencia internacional. Utilizada para transacciones con proveedores internacionales, precios de referencia y operaciones en moneda extranjera.',1000,1),
(2302,'TipoMonedaID','EURO','EUR',3,1,'Euro (€). Moneda oficial de la Unión Europea. Utilizada para transacciones con proveedores europeos y operaciones internacionales en esta moneda.',1000,1),
(2303,'TipoMonedaID','UFV','UFV',4,1,'Unidad de Fomento a la Vivienda. Unidad de cuenta indexada a la inflación en Bolivia. Utilizada para contratos de largo plazo, ajustes de precios y operaciones indexadas.',1000,1);

-- 2350: TipoFacturaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2350,'TipoFacturaID','CON_FACTURA','CF',1,0,'Factura con derecho a crédito fiscal. Documento fiscal válido ante el SIN que permite al comprador descontar el IVA pagado. Requiere NIT del cliente y dosificación fiscal activa. Aplica para ventas a empresas e instituciones.',1000,1),
(2351,'TipoFacturaID','SIN_FACTURA','SF',2,0,'Factura sin derecho a crédito fiscal. Documento fiscal válido ante el SIN que NO permite descontar el IVA. Utilizado para ventas a consumidor final o cuando el cliente no requiere crédito fiscal.',1000,1),
(2352,'TipoFacturaID','NOTA_CREDITO_DEBITO','NCD',3,0,'Nota de crédito o débito para ajustes, devoluciones o correcciones de facturas previamente emitidas. Afecta los saldos fiscales y contables de la transacción original.',1000,1),
(2353,'TipoFacturaID','NINGUNO','NIN',4,0,'Sin tipo de factura definido. Valor por defecto para transacciones que no requieren facturación fiscal, como proformas, ajustes de inventario o traspasos internos. DOMINIO POR DEFECTO.',1000,1);

-- 2400: EstadoFinancieroID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2400,'EstadoFinancieroID','CANCELADO',NULL,0,1,'Transacción totalmente liquidada. El saldo pendiente es cero. Aplica para compras a proveedores totalmente pagadas o ventas al contado. No requiere acciones adicionales.',1000,1),
(2401,'EstadoFinancieroID','PENDIENTE',NULL,0,1,'Transacción sin abonos registrados. El saldo pendiente es igual al monto total. Aplica para compras a crédito donde aún no se ha realizado ningún pago.',1000,1),
(2402,'EstadoFinancieroID','PARCIAL',NULL,0,1,'Transacción con abonos parciales registrados. El saldo pendiente es menor al monto total pero mayor a cero. Aplica para compras a crédito con pagos fraccionados.',1000,1),
(2403,'EstadoFinancieroID','NINGUNO',NULL,0,1,'Sin estado financiero definido. Valor por defecto para transacciones que no generan obligación financiera, como proformas, ajustes de inventario o movimientos internos. DOMINIO POR DEFECTO.',1000,1);

-- 2450: MotivoAnulacionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2450,'MotivoAnulacionID','FACTURA_MAL_EMITIDA','FME',1,0,'Anulación por error en la emisión de la factura. Incluye errores en montos, productos, cantidades o datos fiscales. Requiere justificación detallada y autorización. Aplica para correcciones antes de notificar al SIN.',1000,1),
(2451,'MotivoAnulacionID','ERROR_DATOS_CLIENTE','EDC',2,0,'Anulación por error en los datos del cliente. Incluye NIT incorrecto, razón social errónea o documento de identidad inválido. Aplica cuando la factura fue emitida con información fiscal incorrecta.',1000,1),
(2452,'MotivoAnulacionID','DEVOLUCION_MERCADERIA','DM',3,0,'Anulación por devolución de mercadería por parte del cliente. Revierte el stock y el valor de la transacción. Aplica para ventas anuladas por productos defectuosos, vencidos o devoluciones voluntarias.',1000,1),
(2453,'MotivoAnulacionID','CONTINGENCIA','CON',4,0,'Anulación por contingencia operativa o técnica. Incluye fallos en el sistema de facturación, problemas de conectividad con el SIN o situaciones excepcionales. Requiere documentación de respaldo.',1000,1),
(2454,'MotivoAnulacionID','OPERACION_NO_CONCRETADA','ONC',5,0,'Anulación por operación que no se concretó. Incluye ventas abortadas, clientes que no completaron el pago o transacciones canceladas por acuerdo mutuo. No afecta stock si no hubo despacho.',1000,1),
(2455,'MotivoAnulacionID','NINGUNO','NIN',0,0,'Sin motivo de anulación definido. Valor por defecto para casos donde no se requiere justificación o cuando la anulación es automática por sistema (ej. expiración de reservas). DOMINIO POR DEFECTO.',1000,1);

-- 2500: EstadoLoteID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2500,'EstadoLoteID','VIGENTE',NULL,0,0,'Lote con producto en buen estado y dentro de su fecha de vencimiento. Disponible para venta y despacho. Estado operativo normal del lote.',1000,1),
(2501,'EstadoLoteID','VENCIDO',NULL,0,0,'Lote cuya fecha de vencimiento ha sido superada. No disponible para venta ni despacho. Requiere gestión de baja o devolución. Se excluye automáticamente de transacciones de venta.',1000,1),
(2502,'EstadoLoteID','AGOTADO',NULL,0,0,'Lote con cantidad_actual igual a cero. No disponible para venta. Permanece en histórico para trazabilidad pero ya no tiene stock físico. Puede reactivarse solo mediante ajuste de inventario.',1000,1),
(2503,'EstadoLoteID','NINGUNO',NULL,0,0,'Sin estado de lote definido. Valor por defecto para el registro comodín o casos excepcionales donde no se requiere clasificación de estado. DOMINIO POR DEFECTO.',1000,1);

-- 2550: EstadoPagoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2550,'EstadoPagoID','PENDIENTE',NULL,0,0,'Estado de pago pendiente',1000,1),
(2551,'EstadoPagoID','PARCIAL',NULL,0,0,'Estado de pago parcial',1000,1),
(2552,'EstadoPagoID','PAGADO',NULL,0,0,'Estado de pago pagado',1000,1),
(2553,'EstadoPagoID','CERRADO',NULL,0,0,'Estado de pago cerrado',1000,1),
(2554,'EstadoPagoID','EN_VERIFICACION',NULL,0,0,'Pago en proceso de verificación bancaria',1000,1),
(2555,'EstadoPagoID','NINGUNO',NULL,0,0,'Sin estado de pago definido. Valor por defecto para registros comodín o cuando no aplica un estado específico. DOMINIO POR DEFECTO.',1000,1);

-- 2600: TipoMovimientoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2600,'TipoMovimientoID','INGRESO',NULL,0,1,'Movimiento que incrementa el saldo de caja. Aplica para cobros, ventas, depósitos, devoluciones de clientes y cualquier entrada de dinero. Aumenta el monto_ingresos de la caja. DOMINIO POR DEFECTO.',1000,1),
(2601,'TipoMovimientoID','EGRESO',NULL,0,1,'Movimiento que disminuye el saldo de caja. Aplica para pagos, compras, retiros, devoluciones a proveedores y cualquier salida de dinero. Aumenta el monto_egresos de la caja.',1000,1);

-- 2650: EstadoCajaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2650,'EstadoCajaID','ABIERTA',NULL,0,1,'Caja operativa y disponible para recibir transacciones. Permite registrar ventas, cobros, pagos y movimientos de efectivo. Estado activo durante la jornada laboral. DOMINIO POR DEFECTO.',1000,1),
(2651,'EstadoCajaID','CERRADA',NULL,0,1,'Caja finalizada y cerrada. No permite registrar nuevas transacciones. Requiere arqueo físico y conciliación de montos. Estado final de la jornada.',1000,1);

-- 2700: TipoAlertaNotificacionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2700,'TipoAlertaNotificacionID','SISTEMA',NULL,0,0,'Alerta general del sistema. Notificaciones sobre eventos operativos, mantenimiento programado o cambios en la configuración. Origen: sistema.',1000,1),
(2701,'TipoAlertaNotificacionID','ALERTA_STOCK',NULL,0,0,'Alerta relacionada con niveles de inventario. Agrupa todas las notificaciones de stock bajo, crítico o excesivo. Origen: sistema/IA.',1000,1),
(2702,'TipoAlertaNotificacionID','STOCK_BAJO',NULL,0,0,'Alerta por stock bajo. El inventario ha caído por debajo del punto de reorden. Requiere evaluación de reposición. Acción: generar orden de compra.',1000,1),
(2703,'TipoAlertaNotificacionID','STOCK_CRITICO',NULL,0,0,'Alerta por stock crítico. El inventario está por debajo del stock mínimo de seguridad. Riesgo de quiebre inminente. Acción: compra urgente o traspaso.',1000,1),
(2704,'TipoAlertaNotificacionID','STOCK_EXCESO',NULL,0,0,'Alerta por exceso de stock. El inventario supera el stock máximo permitido. Riesgo de sobre-inversión y vencimientos. Acción: revisar compras y promocionar salida.',1000,1),
(2705,'TipoAlertaNotificacionID','VENCIMIENTO_PROXIMO',NULL,0,0,'Alerta por vencimiento próximo (30-60 días). Productos que caducarán en el mediano plazo. Acción: planificar promociones o devoluciones.',1000,1),
(2706,'TipoAlertaNotificacionID','VENCIMIENTO_INMEDIATO',NULL,0,0,'Alerta por vencimiento inmediato (menos de 30 días). Productos que caducarán pronto. Acción: priorizar venta, promociones agresivas o gestionar devolución.',1000,1),
(2707,'TipoAlertaNotificacionID','VENCIMIENTO_VENCIDO',NULL,0,0,'Alerta por producto vencido. Lotes que han superado su fecha de vencimiento. Acción: dar de baja, gestionar devolución o disposición final.',1000,1),
(2708,'TipoAlertaNotificacionID','DEMANDA_ALTA',NULL,0,0,'Alerta por demanda alta inusual. Incremento significativo en ventas que podría generar quiebre de stock. Acción: evaluar reposición anticipada. Origen: IA.',1000,1),
(2709,'TipoAlertaNotificacionID','DEMANDA_BAJA',NULL,0,0,'Alerta por demanda baja inusual. Caída significativa en ventas que podría indicar problemas de mercado. Acción: revisar precios o promociones. Origen: IA.',1000,1),
(2710,'TipoAlertaNotificacionID','TENDENCIA_ANOMALA',NULL,0,0,'Alerta por tendencia anómala detectada. Comportamiento inusual en patrones de consumo que no corresponde a estacionalidad esperada. Acción: investigar causa. Origen: IA.',1000,1),
(2711,'TipoAlertaNotificacionID','PREDICCION_ROP',NULL,0,0,'Alerta sobre punto de reorden (ROP) calculado. Actualización del nivel óptimo de reorden basado en nuevas predicciones. Acción: revisar configuración de umbrales. Origen: IA.',1000,1),
(2712,'TipoAlertaNotificacionID','PREDICCION_DEMANDA',NULL,0,0,'Alerta sobre predicción de demanda. Resultados del pronóstico disponibles para revisión. Acción: revisar proyecciones en dashboard. Origen: IA.',1000,1),
(2713,'TipoAlertaNotificacionID','FORECASTING',NULL,0,0,'Alerta sobre resultados de forecasting. Actualización de proyecciones de ventas y tendencias. Acción: revisar reportes de pronóstico. Origen: IA.',1000,1),
(2714,'TipoAlertaNotificacionID','PAGOS',NULL,0,0,'Alerta relacionada con pagos y cuentas por cobrar/pagar. Agrupa notificaciones de vencimientos y estados de pago. Origen: sistema.',1000,1),
(2715,'TipoAlertaNotificacionID','PAGO_VENCIDO',NULL,0,0,'Alerta por pago vencido. Cuota o factura con fecha de vencimiento superada sin pago registrado. Acción: gestionar cobranza o aplicar multas. Origen: sistema.',1000,1),
(2716,'TipoAlertaNotificacionID','PAGO_PROXIMO',NULL,0,0,'Alerta por pago próximo. Cuota o factura que vence en los próximos días (según configuración). Acción: preparar pago o notificar al cliente. Origen: sistema.',1000,1),
(2717,'TipoAlertaNotificacionID','DOCUMENTOS',NULL,0,0,'Alerta relacionada con documentos fiscales y administrativos. Agrupa notificaciones sobre facturas y comprobantes. Origen: sistema.',1000,1),
(2718,'TipoAlertaNotificacionID','FACTURA_PENDIENTE',NULL,0,0,'Alerta por factura pendiente de emisión o envío. Documentos fiscales que requieren atención. Acción: completar facturación. Origen: sistema.',1000,1),
(2719,'TipoAlertaNotificacionID','FACTURA_ANULADA',NULL,0,0,'Alerta por factura anulada. Notificación de anulación de documento fiscal. Acción: verificar motivo y documentar. Origen: sistema.',1000,1),
(2720,'TipoAlertaNotificacionID','SEGURIDAD_ACCESO',NULL,0,0,'Alerta por evento de seguridad de acceso. Incluye inicios de sesión desde ubicaciones desconocidas o fuera de horario. Acción: verificar actividad sospechosa. Origen: sistema.',1000,1),
(2721,'TipoAlertaNotificacionID','SEGURIDAD_INTENTO_FALLIDO',NULL,0,0,'Alerta por intentos fallidos de acceso. Múltiples fallos en autenticación que podrían indicar ataque de fuerza bruta. Acción: bloquear usuario o IP. Origen: sistema.',1000,1),
(2722,'TipoAlertaNotificacionID','SISTEMA_ERROR',NULL,0,0,'Alerta por error crítico del sistema. Fallos en procesos, servicios o integraciones que requieren intervención técnica. Acción: revisar logs y solucionar. Origen: sistema.',1000,1),
(2723,'TipoAlertaNotificacionID','SISTEMA_RENDIMIENTO',NULL,0,0,'Alerta por problemas de rendimiento del sistema. Tiempos de respuesta elevados, uso excesivo de recursos o cuellos de botella. Acción: optimizar o escalar recursos. Origen: sistema.',1000,1),
(2724,'TipoAlertaNotificacionID','NINGUNO',NULL,0,0,'Sin tipo de alerta definido. Valor por defecto para registros comodín o casos donde no se requiere clasificación de alerta. DOMINIO POR DEFECTO.',1000,1),
(2725,'TipoAlertaNotificacionID','RRHH_FALTAS',NULL,0,0,'Alerta por faltas consecutivas del trabajador. Acción: contactar al trabajador.',1000,1),
(2726,'TipoAlertaNotificacionID','RRHH_CONTRATO',NULL,0,0,'Alerta por vencimiento de contrato. Acción: gestionar renovación.',1000,1),
(2727,'TipoAlertaNotificacionID','RRHH_PLANILLA',NULL,0,0,'Alerta relacionada con planillas de sueldos. Acción: revisar estado de planilla.',1000,1);

-- 2750: AmbienteID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2750,'AmbienteID','PRODUCCION',NULL,1,0,'Ambiente del sistema en producción.',1000,1),
(2751,'AmbienteID','PILOTO_PRUEBAS',NULL,2,0,'Ambiente del sistema en piloto ó pruebas. DOMINIO POR DEFECTO.',1000,1);

-- 2800: SubtipoAlertaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2800,'SubtipoAlertaID','SARIMA',NULL,0,0,'Subtipo SARIMA',1000,1),
(2801,'SubtipoAlertaID','PROPHET',NULL,0,0,'Subtipo PROPHET',1000,1),
(2802,'SubtipoAlertaID','KMEANS',NULL,0,0,'Subtipo KMEANS',1000,1),
(2803,'SubtipoAlertaID','ROP_CALC',NULL,0,0,'Subtipo ROP_CALC',1000,1),
(2804,'SubtipoAlertaID','PATRON_CONSUMO',NULL,0,0,'Subtipo PATRON_CONSUMO',1000,1),
(2805,'SubtipoAlertaID','ALERTA_PREDICTIVA',NULL,0,0,'Subtipo ALERTA_PREDICTIVA',1000,1),
(2806,'SubtipoAlertaID','QUIEBRE_STOCK',NULL,0,0,'Subtipo QUIEBRE_STOCK',1000,1),
(2807,'SubtipoAlertaID','REORDEN',NULL,0,0,'Subtipo REORDEN',1000,1),
(2808,'SubtipoAlertaID','EXCESO',NULL,0,0,'Subtipo EXCESO',1000,1),
(2809,'SubtipoAlertaID','CADUCIDAD_CRITICA',NULL,0,0,'Subtipo CADUCIDAD_CRITICA',1000,1),
(2810,'SubtipoAlertaID','CADUCIDAD_ALTA',NULL,0,0,'Subtipo CADUCIDAD_ALTA',1000,1),
(2811,'SubtipoAlertaID','CADUCIDAD_MEDIA',NULL,0,0,'Subtipo CADUCIDAD_MEDIA',1000,1),
(2812,'SubtipoAlertaID','NINGUNO',NULL,0,0,'Sin subtipo de alerta definido o no aplica. DOMINIO POR DEFECTO.',1000,1);

-- 2850: OrigenAlertaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2850,'OrigenAlertaID','SISTEMA',NULL,0,0,'Alerta generada por el sistema operativo o módulos internos. Incluye eventos de seguridad, errores de procesos y notificaciones automáticas. Origen más común. DOMINIO POR DEFECTO.',1000,1),
(2851,'OrigenAlertaID','IA',NULL,0,0,'Alerta generada por el motor de Inteligencia Artificial. Incluye predicciones de demanda, detección de anomalías y análisis de tendencias. Basada en modelos de aprendizaje automático.',1000,1),
(2852,'OrigenAlertaID','USUARIO',NULL,0,0,'Alerta generada manualmente por un usuario del sistema. Incluye reportes de incidencias, solicitudes de revisión o notificaciones creadas por operadores.',1000,1),
(2853,'OrigenAlertaID','TAREA_PROGRAMADA',NULL,0,0,'Alerta generada por tareas programadas automáticas. Incluye resultados de procesos batch, ejecución de jobs y monitoreo periódico. Ejecutada según frecuencia configurada.',1000,1);

-- 2900: NivelCriticoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2900,'NivelCriticoID','CRITICO',NULL,0,0,'Nivel crítico. Impacto máximo en operaciones. Requiere acción inmediata. Aplica para quiebre de stock de medicamentos esenciales, fallos de seguridad o errores que detienen el sistema.',1000,1),
(2901,'NivelCriticoID','ALTA',NULL,0,0,'Nivel alto de criticidad. Impacto significativo en operaciones. Requiere atención prioritaria en el corto plazo. Aplica para vencimientos inminentes o desviaciones importantes.',1000,1),
(2902,'NivelCriticoID','MEDIA',NULL,0,0,'Nivel medio de criticidad. Impacto moderado en operaciones. Requiere atención planificada. Aplica para stock bajo, alertas de rendimiento o desviaciones menores.',1000,1),
(2903,'NivelCriticoID','BAJA',NULL,0,0,'Nivel bajo de criticidad. Impacto mínimo en operaciones. Requiere monitoreo sin acción inmediata. Aplica para alertas informativas o seguimiento de tendencias.',1000,1),
(2904,'NivelCriticoID','INFORMATIVA',NULL,0,0,'Nivel informativo. No representa una criticidad operativa. Solo proporciona información para conocimiento del usuario. Aplica para notificaciones de sistema y reportes.',1000,1),
(2905,'NivelCriticoID','NINGUNO',NULL,0,0,'Sin nivel crítico definido. Valor por defecto para casos donde no aplica clasificación de criticidad. DOMINIO POR DEFECTO.',1000,1);

-- 2950: EstadoAlertaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(2950,'EstadoAlertaID','PENDIENTE',NULL,0,0,'Alerta pendiente de atención. No se ha iniciado ningún proceso de resolución. Estado inicial de toda alerta. Requiere asignación de responsable.',1000,1),
(2951,'EstadoAlertaID','EN_PROCESO',NULL,0,0,'Alerta en proceso de resolución. Se ha asignado responsable y se están tomando acciones. La investigación o corrección está en curso. Requiere seguimiento activo.',1000,1),
(2952,'EstadoAlertaID','RESUELTA',NULL,0,0,'Alerta resuelta completamente. La causa ha sido identificada y corregida. No requiere acciones adicionales. Estado final exitoso de la alerta.',1000,1),
(2953,'EstadoAlertaID','IGNORADA',NULL,0,0,'Alerta ignorada. Se ha decidido no tomar acción por considerarse no relevante o de bajo impacto. Requiere justificación documentada. Estado final sin resolución.',1000,1),
(2954,'EstadoAlertaID','ESCALADA',NULL,0,0,'Alerta escalada a nivel superior. No pudo ser resuelta en el nivel actual y requiere intervención de gerencia o soporte especializado. Requiere seguimiento priorizado.',1000,1),
(2955,'EstadoAlertaID','NINGUNO',NULL,0,0,'Sin estado de alerta definido. Valor por defecto para registros comodín o cuando no aplica clasificación de estado de alerta. DOMINIO POR DEFECTO.',1000,1);

-- 3000: FrameworkID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3000,'FrameworkID','STATSMODELS',NULL,0,0,'Framework estadístico para modelos de series temporales y econometría. Ideal para ARIMA, SARIMA y modelos lineales. Compatible con Python.',1000,1),
(3001,'FrameworkID','SCIKIT_LEARN',NULL,0,0,'Framework de aprendizaje automático para clasificación, regresión y clustering. Incluye K-Means, Random Forest y SVM. Compatible con Python.',1000,1),
(3002,'FrameworkID','TENSORFLOW',NULL,0,0,'Framework de deep learning para redes neuronales y modelos avanzados. Incluye LSTM, CNN y Transformers. Compatible con Python.',1000,1),
(3003,'FrameworkID','CUSTOM',NULL,0,0,'Framework personalizado o propietario. Desarrollado específicamente para necesidades particulares del sistema. No es un framework estándar.',1000,1),
(3004,'FrameworkID','NINGUNO',NULL,0,0,'Sin framework definido. Valor por defecto para modelos que no utilizan un framework específico o cuando no aplica. DOMINIO POR DEFECTO.',1000,1);

-- 3050: EstadoEjecucionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3050,'EstadoEjecucionID','EN_PROCESO',NULL,0,1,'Ejecución en curso. El proceso está activo y en ejecución. No hay resultados disponibles hasta su finalización. Aplica para entrenamientos de IA y procesos batch.',1000,1),
(3051,'EstadoEjecucionID','COMPLETADO',NULL,0,1,'Ejecución finalizada exitosamente. El proceso ha concluido sin errores. Los resultados están disponibles para su uso. Aplica para tareas programadas y entrenamientos exitosos.',1000,1),
(3052,'EstadoEjecucionID','FALLIDO',NULL,0,1,'Ejecución fallida. El proceso ha terminado con errores. Requiere revisión de logs para identificar la causa. Aplica para entrenamientos fallidos y tareas con errores.',1000,1),
(3053,'EstadoEjecucionID','NINGUNO',NULL,0,1,'Sin estado de ejecución definido. Valor por defecto para registros comodín o cuando no se ha registrado estado de ejecución. DOMINIO POR DEFECTO.',1000,1);

-- 3100: TipoMetricasID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3100,'TipoMetricasID','REGRESION',NULL,0,0,'Métricas para modelos de regresión. Incluye MAE, RMSE, MAPE, R2 y otras métricas que evalúan la precisión de predicciones numéricas. Aplica para pronósticos de demanda y series temporales.',1000,1),
(3101,'TipoMetricasID','CLASIFICACION',NULL,0,0,'Métricas para modelos de clasificación. Incluye F1 Score, precisión, sensibilidad y exactitud. Aplica para segmentación de clientes, clasificación de productos y detección de anomalías.',1000,1),
(3102,'TipoMetricasID','CLUSTERING',NULL,0,0,'Métricas para modelos de clustering. Incluye coeficiente de silueta, índice de Davies-Bouldin y otras métricas de calidad de agrupamiento. Aplica para segmentación ABC y agrupación de datos.',1000,1),
(3103,'TipoMetricasID','NINGUNO',NULL,0,0,'Sin tipo de métrica definido. Valor por defecto para casos donde no se requiere clasificación específica de métricas. DOMINIO POR DEFECTO.',1000,1);

-- 3150: NivelLogID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3150,'NivelLogID','INFO',NULL,0,0,'Log informativo. Registra eventos normales del sistema, procesos exitosos y cambios de estado. No requiere acción. Utilizado para trazabilidad operativa. DOMINIO POR DEFECTO.',1000,1),
(3151,'NivelLogID','WARNING',NULL,0,0,'Log de advertencia. Indica condiciones anormales que no son críticas pero requieren atención. Puede preceder a errores. Requiere monitoreo y posible acción preventiva.',1000,1),
(3152,'NivelLogID','ERROR',NULL,0,0,'Log de error. Indica fallos en procesos, excepciones o condiciones que impiden la ejecución normal. Requiere acción correctiva inmediata y análisis de causa raíz.',1000,1),
(3153,'NivelLogID','DEBUG',NULL,0,0,'Log de depuración. Registro detallado para desarrollo y diagnóstico. Incluye variables internas, trazas de ejecución y datos de depuración. No debe activarse en producción.',1000,1);

-- 3200: TipoUbicacionMovimientoID
INSERT INTO dominios (dominio_id, dominio, abreviatura, prefijo, valor, es_protegido, descripcion, estado_id, usuario_id_registro) VALUES
(3200,'TipoUbicacionMovimientoID','INGRESO', NULL,0,1,'Movimiento que representa la entrada o ingreso físico de productos a una ubicación de almacenamiento (estantería, almacén o depósito). Incrementa el stock_actual de la ubicación de destino. DOMINIO POR DEFECTO.',1000,1),
(3201,'TipoUbicacionMovimientoID','EGRESO', NULL,0,1,'Movimiento que representa la salida o egreso físico de productos desde una ubicación de almacenamiento hacia otra área, despacho o proceso. Disminuye el stock_actual de la ubicación de origen.',1000,1);

-- 3250: TipoUmbralID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3250,'TipoUmbralID','STOCK_MINIMO',NULL,0,0,'Umbral de stock mínimo. Define el nivel mínimo de inventario permitido para un producto. Cuando el stock cae por debajo de este valor, se activa una alerta de reposición. DOMINIO POR DEFECTO.',1000,1),
(3251,'TipoUmbralID','DIAS_VENCIMIENTO',NULL,0,0,'Umbral de días de vencimiento. Define el número de días antes del vencimiento para activar una alerta. Aplica para control de caducidad y planificación de promociones.',1000,1),
(3252,'TipoUmbralID','ERROR_PREDICCION',NULL,0,0,'Umbral de error de predicción. Define el porcentaje máximo de error permitido en pronósticos de demanda (MAPE). Si se supera, el modelo se considera rechazado y requiere reentrenamiento.',1000,1),
(3253,'TipoUmbralID','NINGUNO',NULL,0,0,'Sin tipo de umbral definido. Valor por defecto para configuraciones que no requieren clasificación específica de umbral.',1000,1);

-- 3300: EstadoDocumentoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3300,'EstadoDocumentoID','EMITIDO',NULL,0,0,'Documento emitido y vigente. El comprobante fiscal ha sido generado y registrado correctamente. Es válido ante el SIN. DOMINIO POR DEFECTO.',1000,1),
(3301,'EstadoDocumentoID','ANULADO',NULL,0,0,'Documento anulado completamente. El comprobante fiscal ha sido cancelado en su totalidad. No tiene validez fiscal. Se mantiene en histórico para auditoría.',1000,1),
(3302,'EstadoDocumentoID','ANULADO_PARCIAL',NULL,0,0,'Documento anulado parcialmente. Solo parte del comprobante fiscal ha sido cancelado (ej. devolución de algunos ítems). Afecta parcialmente la validez fiscal del documento.',1000,1);

-- 3350: FrecuenciaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3350,'FrecuenciaID','MINUTOS',NULL,0,0,'Ejecución programada en intervalos de minutos. Aplica para tareas que requieren monitoreo frecuente o actualizaciones rápidas. Configurable en parametros_globales.',1000,1),
(3351,'FrecuenciaID','HORAS',NULL,0,0,'Ejecución programada en intervalos de horas. Aplica para tareas de sincronización, actualización de datos o procesos batch cortos.',1000,1),
(3352,'FrecuenciaID','DIARIO',NULL,0,0,'Ejecución programada una vez al día. Aplica para tareas de generación de reportes diarios, respaldos y actualizaciones de inventario. Frecuencia más común.',1000,1),
(3353,'FrecuenciaID','SEMANAL',NULL,0,0,'Ejecución programada una vez por semana. Aplica para tareas de consolidación semanal, reportes gerenciales y análisis de tendencias.',1000,1),
(3354,'FrecuenciaID','MENSUAL',NULL,0,0,'Ejecución programada una vez al mes. Aplica para tareas de cierre contable, reportes mensuales y análisis de rendimiento de modelos.',1000,1),
(3355,'FrecuenciaID','ANUAL',NULL,0,0,'Ejecución programada una vez al año. Aplica para tareas de cierre fiscal, auditorías anuales y mantenimiento mayor del sistema.',1000,1),
(3356,'FrecuenciaID','CRON',NULL,0,0,'Ejecución programada mediante expresión CRON. Permite configuración flexible de fechas y horas. Aplica para tareas con programación compleja o personalizada.',1000,1),
(3357,'FrecuenciaID','CONTINUA',NULL,0,0,'Ejecución continua sin interrupción. Aplica para tareas de monitoreo en tiempo real, servicios de background o procesos que requieren ejecución permanente.',1000,1),
(3358,'FrecuenciaID','TRIGGER_EVENTO',NULL,0,0,'Ejecución disparada por un evento específico. Aplica para tareas que se activan ante condiciones o acciones particulares (ej. cambio de estado, fin de proceso).',1000,1),
(3359,'FrecuenciaID','NINGUNO',NULL,0,0,'Sin frecuencia definida. Valor por defecto para tareas que no requieren programación automática o que se ejecutan de forma manual. DOMINIO POR DEFECTO.',1000,1);

-- 3400: TipoTareaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3400,'TipoTareaID','REPORTE',NULL,0,0,'Tarea de generación de reportes y documentos. Incluye reportes operativos, financieros, de inventario y gerenciales. Puede generar archivos PDF, Excel o CSV.',1000,1),
(3401,'TipoTareaID','IA_MODELO',NULL,0,0,'Tarea de ejecución y gestión de modelos de IA. Incluye entrenamiento, predicción y actualización de modelos. Asociada a subtipos específicos de modelos.',1000,1),
(3402,'TipoTareaID','BACKUP',NULL,0,0,'Tarea de respaldo y copia de seguridad. Incluye backup de base de datos, archivos del sistema y modelos de IA. Programada para ejecución periódica.',1000,1),
(3403,'TipoTareaID','ALERTA',NULL,0,0,'Tarea de generación y gestión de alertas. Incluye monitoreo de condiciones críticas y envío de notificaciones. Puede ser operativa o predictiva.',1000,1),
(3404,'TipoTareaID','MANTENIMIENTO',NULL,0,0,'Tarea de mantenimiento del sistema. Incluye limpieza de logs, archivado de datos y optimización de rendimiento. Ejecución programada o bajo demanda.',1000,1),
(3405,'TipoTareaID','FORECASTING',NULL,0,0,'Tarea de pronóstico y predicción. Incluye modelos ARIMA, SARIMA, Prophet y otros para predicción de demanda. Genera proyecciones futuras.',1000,1),
(3406,'TipoTareaID','CLASIFICACION',NULL,0,0,'Tarea de clasificación y segmentación. Incluye K-Means, RFM y clustering. Utilizada para clasificación ABC y segmentación de clientes.',1000,1),
(3407,'TipoTareaID','OPTIMIZACION',NULL,0,0,'Tarea de optimización de procesos. Incluye cálculo de ROP, EOQ y niveles óptimos de inventario. Busca minimizar costos y maximizar eficiencia.',1000,1),
(3408,'TipoTareaID','VALIDACION',NULL,0,0,'Tarea de validación y evaluación de modelos. Incluye validación cruzada, comparación de métricas y análisis de rendimiento. Asegura calidad de los modelos.',1000,1),
(3409,'TipoTareaID','NINGUNO',NULL,0,0,'Sin tipo de tarea definido. Valor por defecto para tareas no clasificadas o cuando no aplica tipo específico. DOMINIO POR DEFECTO.',1000,1);

-- 3450: SubtipoTareaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3450,'SubtipoTareaID','SARIMA',NULL,0,0,'Subtipo para tareas de entrenamiento y ejecución del modelo SARIMA (Seasonal ARIMA). Utilizado para pronósticos de demanda con componente estacional. Asociado a TipoTarea: FORECASTING, IA_MODELO.',1000,1),
(3451,'SubtipoTareaID','SARIMAX',NULL,0,0,'Subtipo para tareas de entrenamiento y ejecución del modelo SARIMAX (SARIMA con variables exógenas). Incorpora factores externos al pronóstico. Asociado a TipoTarea: FORECASTING, IA_MODELO.',1000,1),
(3452,'SubtipoTareaID','PROPHET',NULL,0,0,'Subtipo para tareas de entrenamiento y ejecución del modelo Prophet de Meta. Detecta estacionalidades múltiples y días festivos. Asociado a TipoTarea: FORECASTING, IA_MODELO.',1000,1),
(3453,'SubtipoTareaID','KMEANS',NULL,0,0,'Subtipo para tareas de clustering y clasificación con K-Means. Utilizado para segmentación ABC de inventario y clasificación de clientes. Asociado a TipoTarea: CLASIFICACION, IA_MODELO.',1000,1),
(3454,'SubtipoTareaID','ROP_CALC',NULL,0,0,'Subtipo para tareas de cálculo de Punto de Reorden (ROP). Determina niveles óptimos de reorden basados en demanda y lead time. Asociado a TipoTarea: OPTIMIZACION, FORECASTING.',1000,1),
(3455,'SubtipoTareaID','PATRON_CONSUMO',NULL,0,0,'Subtipo para tareas de detección y análisis de patrones de consumo. Identifica estacionalidades y tendencias en datos históricos. Asociado a TipoTarea: FORECASTING, ANALISIS.',1000,1),
(3456,'SubtipoTareaID','ALERTA_PREDICTIVA',NULL,0,0,'Subtipo para tareas de generación de alertas predictivas. Evalúa riesgos futuros basados en modelos de IA. Asociado a TipoTarea: ALERTA, IA_MODELO.',1000,1),
(3457,'SubtipoTareaID','VARIABLE_EXOGENA',NULL,0,0,'Subtipo para tareas de procesamiento y actualización de variables exógenas. Obtiene datos externos (clima, festivos, economía). Asociado a TipoTarea: IA_MODELO, MANTENIMIENTO.',1000,1),
(3458,'SubtipoTareaID','METRICA_RENDIMIENTO',NULL,0,0,'Subtipo para tareas de cálculo y actualización de métricas de rendimiento de modelos IA. Genera reportes de precisión. Asociado a TipoTarea: REPORTE, VALIDACION.',1000,1),
(3459,'SubtipoTareaID','REENTRENAMIENTO',NULL,0,0,'Subtipo para tareas de reentrenamiento automático de modelos. Ejecuta cuando el error supera el umbral configurado. Asociado a TipoTarea: IA_MODELO, MANTENIMIENTO.',1000,1),
(3460,'SubtipoTareaID','VALIDACION_CROSS',NULL,0,0,'Subtipo para tareas de validación cruzada de modelos. Evalúa y compara el rendimiento de diferentes modelos. Asociado a TipoTarea: VALIDACION, IA_MODELO.',1000,1),
(3461,'SubtipoTareaID','NINGUNO',NULL,0,0,'Sin subtipo de tarea definido. Valor por defecto para tareas que no requieren clasificación específica o cuando no aplica subtipo. DOMINIO POR DEFECTO.',1000,1);

-- 3500: MotivoDevolucionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3500,'MotivoDevolucionID','PRODUCTO_VENCIDO','PV',1,0,'Devolución por producto vencido. El producto ha superado su fecha de vencimiento y no puede ser comercializado. Aplica para devoluciones a proveedores o baja de inventario.',1000,1),
(3501,'MotivoDevolucionID','PRODUCTO_DAÑADO','PD',2,0,'Devolución por producto dañado o roto. Incluye envases deteriorados, productos derramados o con daños físicos. No apto para la venta.',1000,1),
(3502,'MotivoDevolucionID','ERROR_PEDIDO','EP',3,0,'Devolución por error en el pedido. Producto incorrecto, cantidad errónea o especificaciones no coincidentes. Aplica para devoluciones a proveedores por errores de despacho.',1000,1),
(3503,'MotivoDevolucionID','EXCESO_STOCK','ES',4,0,'Devolución por exceso de stock. Producto con inventario sobrepasado que no tiene rotación esperada. Aplica para devoluciones planificadas para liberar espacio.',1000,1),
(3504,'MotivoDevolucionID','DESCONTINUADO','DES',5,0,'Devolución por producto descontinuado. Producto que ya no es fabricado o comercializado. Aplica para devoluciones de productos que serán retirados del catálogo.',1000,1),
(3505,'MotivoDevolucionID','DEVOLUCION_CLIENTE','DC',6,0,'Devolución por cliente. Producto devuelto voluntariamente por el comprador por insatisfacción, cambio de opinión o producto no deseado. Aplica para devoluciones de ventas.',1000,1),
(3506,'MotivoDevolucionID','NINGUNO','NIN',0,0,'Sin motivo de devolución definido. Valor por defecto para transacciones que no requieren clasificación de devolución o cuando no aplica motivo específico. DOMINIO POR DEFECTO.',1000,1),
(3507,'MotivoDevolucionID','PRODUCTO_NO_SOLICITADO',NULL,0,0,'Devolución por producto no solicitado o error en el pedido',1000,1),
(3508,'MotivoDevolucionID','PRODUCTO_DEFECTUOSO', NULL,0,0,'Devolución por producto defectuoso o dañado',1000,1);

-- 3550: TipoDespachoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3550,'TipoDespachoID','VENTA_MOSTRADOR','VM',1,0,'Venta realizada directamente en el mostrador de la farmacia. El cliente recibe el producto en el punto de venta. No requiere logística de entrega. Modalidad más común.',1000,1),
(3551,'TipoDespachoID','DOMICILIO','DOM',2,0,'Despacho a domicilio del cliente. El producto es entregado en la dirección indicada por el comprador. Requiere logística de reparto y gestión de tiempos de entrega.',1000,1),
(3552,'TipoDespachoID','RETIRO','RET',3,0,'Cliente retira el producto en la sucursal después de haber realizado el pedido. Aplica para pedidos por teléfono, web o aplicación. El producto es reservado para el cliente.',1000,1),
(3553,'TipoDespachoID','TRANSFERENCIA','TRF',4,0,'Transferencia de producto entre sucursales para cumplir con un pedido. El cliente retira en una sucursal diferente a la que originó el pedido. Requiere coordinación logística.',1000,1),
(3554,'TipoDespachoID','NINGUNO','NIN',0,0,'Sin tipo de despacho definido. Valor por defecto para transacciones que não requieren clasificación de despacho, como compras a proveedores, ajustes de inventario o movimientos internos. DOMINIO POR DEFECTO.',1000,1);

-- 3600: MetricaPrecisionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3600,'MetricaPrecisionID','MAE','MAE',1,0,'Mean Absolute Error (Error Absoluto Medio). Mide la magnitud promedio de los errores en un conjunto de predicciones, sin considerar su dirección. Útil para modelos de regresión.',1000,1),
(3601,'MetricaPrecisionID','RMSE','RMSE',2,0,'Root Mean Square Error (Raíz del Error Cuadrático Medio). Penaliza errores grandes más que MAE. Útil para modelos de regresión donde se quiere evitar errores extremos.',1000,1),
(3602,'MetricaPrecisionID','MAPE','MAPE',3,0,'Mean Absolute Percentage Error (Error Porcentual Absoluto Medio). Expresa el error en porcentaje, facilitando la interpretación. Útil para comparar precisión entre diferentes escalas.',1000,1),
(3603,'MetricaPrecisionID','R2','R2',4,0,'R-squared (Coeficiente de Determinación). Mide la proporción de varianza explicada por el modelo. Valores cercanos a 1 indican mejor ajuste. Útil para modelos de regresión.',1000,1),
(3604,'MetricaPrecisionID','F1','F1',5,0,'F1 Score (Puntuación F1). Media armónica entre precisión y sensibilidad. Útil para modelos de clasificación con clases desbalanceadas.',1000,1),
(3605,'MetricaPrecisionID','NINGUNO','NIN',0,0,'Sin métrica de precisión definida. Valor por defecto para modelos que no han sido evaluados o cuando no aplica métrica específica. DOMINIO POR DEFECTO.',1000,1);

-- 3650: FactorEstacionalidadID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3650,'FactorEstacionalidadID','NONE','NON',0,0,'Sin componente estacional. El modelo no considera estacionalidad en el pronóstico. Aplica para productos con demanda constante o cuando la estacionalidad no es significativa. DOMINIO POR DEFECTO.',1000,1),
(3651,'FactorEstacionalidadID','DIARIO','DIA',1,0,'Estacionalidad con patrón diario recurrente. El comportamiento de demanda se repite cada día. Aplica para productos con horarios de consumo específicos (ej. medicamentos para el desayuno, almuerzo o cena).',1000,1),
(3652,'FactorEstacionalidadID','SEMANAL','SEM',2,0,'Estacionalidad con patrón semanal recurrente. El comportamiento de demanda se repite cada semana. Aplica para productos con mayor consumo en días específicos (ej. fines de semana, días de consulta médica).',1000,1),
(3653,'FactorEstacionalidadID','MENSUAL','MEN',3,0,'Estacionalidad con patrón mensual recurrente. El comportamiento de demanda se repite cada mes. Aplica para productos con consumo vinculado a ciclos mensuales (ej. medicamentos de prescripción mensual, productos de planificación familiar).',1000,1),
(3654,'FactorEstacionalidadID','ANUAL','ANU',4,0,'Estacionalidad con patrón anual recurrente. El comportamiento de demanda se repite cada año. Aplica para productos con consumo estacional (ej. antigripales en invierno, antialérgicos en primavera, vacunas en campañas anuales).',1000,1),
(3655,'FactorEstacionalidadID','MULTIPLE','MUL',5,0,'Estacionalidad con múltiples patrones combinados (ej. semanal + anual, mensual + anual). El comportamiento de demanda tiene más de una componente estacional significativa. Aplica para productos con estacionalidad compleja.',1000,1);

-- 3700: EstadoPedidoOnlineID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3700,'EstadoPedidoOnlineID','PENDIENTE', NULL,0,0,'Pedido recibido, pendiente de confirmación. DOMINIO POR DEFECTO.',1000,1),
(3701,'EstadoPedidoOnlineID','CONFIRMADO',NULL,1,0,'Pedido confirmado por la farmacia',1000,1),
(3702,'EstadoPedidoOnlineID','PREPARANDO',NULL,2,0,'Pedido en proceso de preparación',1000,1),
(3703,'EstadoPedidoOnlineID','EN_CAMINO', NULL,3,0,'Pedido despachado, en ruta de entrega',1000,1),
(3704,'EstadoPedidoOnlineID','ENTREGADO', NULL,4,0,'Pedido entregado al cliente',1000,1),
(3705,'EstadoPedidoOnlineID','CANCELADO',NULL,5,0,'Pedido cancelado por el cliente o la farmacia',1000,1),
(3706,'EstadoPedidoOnlineID','RECHAZADO',NULL,6,0,'Pedido rechazado por el cliente',1000,1);

-- 3750: MetodoCalculoID
INSERT INTO dominios (dominio_id, dominio, abreviatura, prefijo, valor, es_protegido, descripcion, estado_id, usuario_id_registro) VALUES
(3750,'MetodoCalculoID','PONDERADO',NULL,0,0,'Costo promedio ponderado: (stock_actual * costo_anterior + cantidad_comprada * costo_compra) / (stock_actual + cantidad_comprada). DOMINIO POR DEFECTO.',1000,1),
(3751,'MetodoCalculoID','FIFO',NULL,0,0,'Primeras en entrar, primeras en salir. Se venden primero los lotes más antiguos.',1000,1),
(3752,'MetodoCalculoID','ULTIMA_COMPRA',NULL,0,0,'Usa el costo del último lote comprado como referencia.',1000,1);

-- 3800: GradoEquivalenciaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3800,'GradoEquivalenciaID','TOTAL',NULL,1,0,'Mismo principio activo, misma concentración, misma forma farmacéutica. Intercambio directo y seguro. No requiere ajuste de dosis ni evaluación médica adicional.',1000,1),
(3801,'GradoEquivalenciaID','PARCIAL',NULL,2,0,'Mismo principio activo, diferente concentración o forma farmacéutica. Requiere ajuste de dosis por parte del profesional de salud. No es intercambio directo.',1000,1),
(3802,'GradoEquivalenciaID','TERAPEUTICO',NULL,3,0,'Diferente principio activo pero mismo efecto terapéutico. Requiere evaluación médica obligatoria antes del intercambio. No es intercambio directo.',1000,1),
(3803,'GradoEquivalenciaID','NINGUNO',NULL,4,0,'Sin grado de equivalencia definido. Valor por defecto para productos sin equivalencia registrada o cuando no aplica clasificación. DOMINIO POR DEFECTO.',1000,1);

-- 3850: TipoRecetaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3850,'TipoRecetaID','SIMPLE','SIM',1,0,'Receta médica estándar para medicamentos de venta libre,  antibióticos comunes y medicamentos que no requieren control especial. No requiere retención física en farmacia.',1000,1),
(3851,'TipoRecetaID','ARCHIVADA','ARC',2,0,'Receta retenida obligatoriamente en farmacia. Aplica para medicamentos psicotrópicos y sustancias fiscalizadas que requieren control de dispensación. Se debe conservar por el tiempo establecido por normativa.',1000,1),
(3852,'TipoRecetaID','VALADA','VAL',3,0,'Receta oficial valorada y timbrada por autoridad competente. Aplica para estupefacientes y medicamentos de control estricto. Requiere registro especial y cumplimiento riguroso de normativa.',1000,1),
(3853,'TipoRecetaID','NINGUNO','NIN',4,0,'Sin tipo de receta definido. Valor por defecto para casos donde no se requiere receta médica (venta libre, productos OTC, dispositivos médicos) o cuando no aplica el control por receta. DOMINIO POR DEFECTO.',1000,1);

-- 3900: ModalidadFacturacionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3900,'ModalidadFacturacionID','NINGUNO','NIN',0,1,'Modalidad de facturación ninguno. DOMINIO POR DEFECTO.',1000,1),
(3901,'ModalidadFacturacionID','ELECTRONICA','EL',1,1,'Electrónica en Línea',1000,1),
(3902,'ModalidadFacturacionID','COMPUTARIZADA','CL',2,1,'Computarizada en Línea',1000,1),
(3903,'ModalidadFacturacionID','MANUAL','MN',2,1,'Manual',1000,1);

-- 3950: TipoPuntoVentaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3950,'TipoPuntoVentaID','NINGUNO','NIN',0,0,'Tipo punto venta ninguno. DOMINIO POR DEFECTO.',1000,1),
(3951,'TipoPuntoVentaID','CAJA','CAJ',1,0,'Punto de venta caja.',1000,1);

-- 4000: EstadoProformaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4000,'EstadoProformaID','NO_APLICA',NULL,0,1,'Proforma por default. DOMINIO POR DEFECTO.',1000,1),
(4001,'EstadoProformaID','PENDIENTE',NULL,0,1,'Proforma o reserva emitida y pendiente de resolución o cobro. DOMINIO POR DEFECTO.',1000,1),
(4002,'EstadoProformaID','CONVERTIDA',NULL,1,1,'Proforma o reserva convertida exitosamente en venta definitiva.',1000,1),
(4003,'EstadoProformaID','EXPIRADA',NULL,2,1,'Reserva cancelada automáticamente por tiempo vencido (TTL) liberando el stock.',1000,1),
(4004,'EstadoProformaID','ANULADA',NULL,3,1,'Proforma o reserva anulada manualmente por el operador.',1000,1);

-- 4050: TipoOperacionAlmacenID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4050,'TipoOperacionAlmacenID','LOGISTICA_INTERNA','LI',0,0,'Almacén destinado a depósito general, tránsito o reabastecimiento interno sin venta directa. DOMINIO POR DEFECTO.',1000,1),
(4051,'TipoOperacionAlmacenID','VENTA_DIRECTA','VD',1,0,'Almacén vinculado a un punto de venta donde las transacciones afectan directamente el stock operativo.',1000,1);

-- 4100: EntidadAfectadaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4100,'EntidadAfectadaID','PRODUCTOS','PROD',0,0,'Productos del catalogo general. DOMINIO POR DEFECTO.',1000,1),
(4101,'EntidadAfectadaID','LOTES','LOT',0,0,'Lotes de inventario y fechas de vencimiento.',1000,1),
(4102,'EntidadAfectadaID','VENTAS','VEN',0,0,'Transacciones de venta realizadas.',1000,1),
(4103,'EntidadAfectadaID','COMPRAS','COM',0,0,'Transacciones de compra a proveedores.',1000,1),
(4104,'EntidadAfectadaID','USUARIOS','USR',0,0,'Usuarios del sistema registrados.',1000,1),
(4105,'EntidadAfectadaID','SUCURSALES','SUC',0,0,'Sucursales operativas de la empresa.',1000,1),
(4106,'EntidadAfectadaID','PROVEEDORES','PROV',0,0,'Proveedores comerciales registrados.',1000,1),
(4107,'EntidadAfectadaID','CLIENTES','CLI',0,0,'Clientes del sistema o compradores.',1000,1),
(4108,'EntidadAfectadaID','FACTURAS','FAC',0,0,'Documentos fiscales y facturación.',1000,1),
(4109,'EntidadAfectadaID','PAGOS','PAG',0,0,'Pagos, abonos y transacciones financieras.',1000,1),
(4110,'EntidadAfectadaID','INVENTARIO','INV',0,0,'Movimientos generales de inventario y stock.',1000,1),
(4111,'EntidadAfectadaID','NINGUNO','NIN',0,1,'Sin entidad afectada o registro neutral. DOMINIO POR DEFECTO.',1000,1);

-- 4150: CriticidadMedicaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4150,'CriticidadMedicaID','NORMAL',0,0,'Producto sin criticidad medica especial. DOMINIO POR DEFECTO.',1000,1),
(4151,'CriticidadMedicaID','CRITICO',0,1,'Producto critico para la salud',1000,1);

-- 4200: TipoPatronID
INSERT INTO dominios (dominio_id, dominio, abreviatura, prefijo, valor, es_protegido, descripcion, estado_id, usuario_id_registro)
VALUES (4200, 'TipoPatronID', 'DEMANDA', 'DEM', 0, 0, 'Patrón basado en la demanda histórica. DOMINIO POR DEFECTO.', 1000, 1);

-- 4250: FuenteExogenaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4250,'FuenteExogenaID','SENAMHI',0,0,'Servicio Nacional de Meteorologia e Hidrologia. DOMINIO POR DEFECTO.',1000,1),
(4251,'FuenteExogenaID','INE',0,0,'Instituto Nacional de Estadistica',1000,1),
(4252,'FuenteExogenaID','BCB',0,0,'Banco Central de Bolivia',1000,1),
(4253,'FuenteExogenaID','API_CLIMA',0,0,'API de clima externa',1000,1),
(4254,'FuenteExogenaID','CALENDARIO_FESTIVOS',0,0,'Calendario oficial de festivos',1000,1),
(4255,'FuenteExogenaID','CUSTOM',0,0,'Fuente personalizada definida por el usuario',1000,1);

-- 4300: TipoBilleteMonedaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4300,'TipoBilleteMonedaID','NINGUNO',0,0,'Registro comodín para arqueos. DOMINIO POR DEFECTO.',1000,1),
(4301,'TipoBilleteMonedaID','B200',0,0,'Billete de 200 Bs',1000,1),
(4302,'TipoBilleteMonedaID','B100',0,0,'Billete de 100 Bs',1000,1),
(4303,'TipoBilleteMonedaID','B50',0,0,'Billete de 50 Bs',1000,1),
(4304,'TipoBilleteMonedaID','B20',0,0,'Billete de 20 Bs',1000,1),
(4305,'TipoBilleteMonedaID','B10',0,0,'Billete de 10 Bs',1000,1),
(4306,'TipoBilleteMonedaID','B5',0,0,'Billete de 5 Bs',1000,1),
(4307,'TipoBilleteMonedaID','B2',0,0,'Billete de 2 Bs',1000,1),
(4308,'TipoBilleteMonedaID','B1',0,0,'Billete de 1 Bs',1000,1),
(4309,'TipoBilleteMonedaID','M050',0,0,'Moneda de 50 centavos',1000,1),
(4310,'TipoBilleteMonedaID','M020',0,0,'Moneda de 20 centavos',1000,1),
(4311,'TipoBilleteMonedaID','M010',0,0,'Moneda de 10 centavos',1000,1),
(4312,'TipoBilleteMonedaID','M10',0,0,'Moneda de 10 Bs',1000,1),
(4313,'TipoBilleteMonedaID','M5',0,0,'Moneda de 5 Bs',1000,1),
(4314,'TipoBilleteMonedaID','M2',0,0,'Moneda de 2 Bs',1000,1),
(4315,'TipoBilleteMonedaID','M1',0,0,'Moneda de 1 Bs',1000,1);

-- 4350: TipoAplicacionID
INSERT INTO dominios (dominio_id, dominio, abreviatura, prefijo, valor, es_protegido, descripcion, estado_id, usuario_id_registro) VALUES
(4350,'TipoAplicacionID','GLOBAL', NULL,0,0,'Política que aplica a todos los productos sin excepción. DOMINIO POR DEFECTO.',1000,1),
(4351,'TipoAplicacionID','CATEGORIA', NULL,0,0,'Política que aplica solo a productos de una categoría específica.',1000,1),
(4352,'TipoAplicacionID','LABORATORIO', NULL,0,0,'Política que aplica solo a productos de un laboratorio específico.',1000,1),
(4353,'TipoAplicacionID','PRODUCTO', NULL,0,0,'Política que aplica solo a un producto específico.',1000,1);

-- 4400: TipoAsistenciaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4400,'TipoAsistenciaID','NORMAL',0,0,'Asistencia regular sin incidencias. Marcación de entrada y salida estándar. DOMINIO POR DEFECTO.',1000,1),
(4401,'TipoAsistenciaID','LICENCIA', 1, 0,'Ausencia justificada por licencia médica, vacaciones, estudio o personal. Requiere documentación respaldo.',1000,1),
(4402,'TipoAsistenciaID','PERMISO', 2, 0,'Permiso por horas o días con autorización del supervisor. Afecta el cálculo de horas trabajadas.',1000,1),
(4403,'TipoAsistenciaID','JUSTIFICADA', 3, 0,'Ausencia justificada sin goce de sueldo (ej. emergencia familiar).',1000,1);

-- 4450: EstadoAsistenciaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4450,'EstadoAsistenciaID','PRESENTE',0,0,'Trabajador asistió puntualmente y cumplió su jornada laboral completa. DOMINIO POR DEFECTO.',1000,1),
(4451,'EstadoAsistenciaID','AUSENTE', 1, 0,'Trabajador no asistió a su jornada laboral. Sin justificación o sin registrar marcación.',1000,1),
(4452,'EstadoAsistenciaID','TARDE', 2, 0,'Trabajador llegó después de la hora de inicio de jornada (más de 15 minutos de retraso).',1000,1),
(4453,'EstadoAsistenciaID','FALTA_INJUSTIFICADA', 3, 0,'Ausencia sin justificación válida. Afecta el cálculo de sueldo y puede generar sanciones.',1000,1);

-- 4500: MetodoMarcacionID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4500,'MetodoMarcacionID','MANUAL',0,0,'Registro manual por parte del supervisor o administrador. Requiere validación. DOMINIO POR DEFECTO.',1000,1),
(4501,'MetodoMarcacionID','BIOMETRICO', 1, 0,'Marcación mediante dispositivo biométrico (huella digital, reconocimiento facial). Método más seguro.',1000,1),
(4502,'MetodoMarcacionID','QR', 2, 0,'Marcación mediante escaneo de código QR en el punto de acceso. Aplicable para control de acceso.',1000,1),
(4503,'MetodoMarcacionID','APP', 3, 0,'Marcación desde aplicación móvil con geolocalización. Permite registro remoto.',1000,1);

-- 4550: TipoAlertaRRHHID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4550,'TipoAlertaRRHHID','RRHH',0,0,'Alerta relacionada con el módulo de Recursos Humanos. Agrupa notificaciones de asistencia, planillas y personal.',1000,1),
(4551,'TipoAlertaRRHHID','FALTAS_CONSECUTIVAS', 1, 0,'Alerta por faltas consecutivas del trabajador. Requiere atención del supervisor.',1000,1),
(4552,'TipoAlertaRRHHID','BAJA_RENDIMIENTO', 2, 0,'Alerta por bajo rendimiento del trabajador. Requiere evaluación de desempeño.',1000,1),
(4553,'TipoAlertaRRHHID','VENCIMIENTO_CONTRATO', 3, 0,'Alerta por vencimiento de contrato del trabajador. Requiere renovación o finalización.',1000,1),
(4554,'TipoAlertaRRHHID','CUMPLEANOS', 4, 0,'Alerta por cumpleaños del trabajador. Notificación para área de RRHH.',1000,1);

-- 4600: TipoPlanillaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4600,'TipoPlanillaID','SUELDOS',0,0,'Planilla mensual de sueldos para trabajadores con contrato indefinido o fijo. DOMINIO POR DEFECTO.',1000,1),
(4601,'TipoPlanillaID','JORNALES', 1, 0,'Planilla por jornales para trabajadores eventuales o temporales.',1000,1),
(4602,'TipoPlanillaID','CONTRATO', 2, 0,'Planilla por contrato de servicios profesionales (consultores, asesores).',1000,1);

-- 4650: EstadoPlanillaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4650,'EstadoPlanillaID','BORRADOR',0,0,'Planilla en edición. Los valores pueden ser modificados. No está lista para aprobación. DOMINIO POR DEFECTO.',1000,1),
(4651,'EstadoPlanillaID','CALCULADA', 1, 0,'Planilla calculada automáticamente por el sistema. Pendiente de aprobación por gerencia.',1000,1),
(4652,'EstadoPlanillaID','APROBADA', 2, 0,'Planilla aprobada por gerencia. Lista para pago a los trabajadores.',1000,1),
(4653,'EstadoPlanillaID','PAGADA', 3, 0,'Planilla pagada completamente a los trabajadores. Registro cerrado y contabilizado.',1000,1),
(4654,'EstadoPlanillaID','ANULADA', 4, 0,'Planilla anulada irreversiblemente. Solo permitido desde BORRADOR o CALCULADA.',1000,1);

-- 4700: EstadoContratoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4700,'EstadoContratoID','VIGENTE',0,0,'Contrato activo y operativo. El trabajador se encuentra en funciones. DOMINIO POR DEFECTO.',1000,1),
(4701,'EstadoContratoID','FINALIZADO', 1, 0,'Contrato finalizado por cumplimiento de plazo o decisión del trabajador.',1000,1),
(4702,'EstadoContratoID','RENOVADO', 2, 0,'Contrato renovado por un nuevo período.',1000,1),
(4703,'EstadoContratoID','SUSPENDIDO', 3, 0,'Contrato suspendido temporalmente por licencia o situación especial.',1000,1);

-- 4750: TipoContratoID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4750,'TipoContratoID','INDEFINIDO',0,0,'Contrato sin fecha de término definida. Establece relación laboral permanente. DOMINIO POR DEFECTO.',1000,1),
(4751,'TipoContratoID','FIJO', 1, 0,'Contrato con fecha de inicio y fin definidas. Se renueva automáticamente o finaliza.',1000,1),
(4752,'TipoContratoID','EVENTUAL', 2, 0,'Contrato por tiempo determinado para proyectos específicos o temporada.',1000,1),
(4753,'TipoContratoID','PRACTICAS', 3, 0,'Contrato de prácticas profesionales o pasantías para estudiantes.',1000,1),
(4754,'TipoContratoID','CONSULTORIA', 4, 0,'Contrato de servicios profesionales para consultores o asesores externos.',1000,1);

-- 4800: TipoJornadaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(4800,'TipoJornadaID','COMPLETA',0,0,'Jornada laboral completa (40 horas semanales). DOMINIO POR DEFECTO.',1000,1),
(4801,'TipoJornadaID','MEDIA', 1, 0,'Jornada laboral media (20 horas semanales).',1000,1),
(4802,'TipoJornadaID','POR_HORAS', 2, 0,'Jornada laboral por horas (trabajo por horas).',1000,1);

UPDATE dominios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE dominios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

-- ================================================================================================

CREATE TABLE bancos (
    banco_id BIGSERIAL PRIMARY KEY,
    banco VARCHAR(100) NOT NULL,
    codigo_asfi VARCHAR(2) NOT NULL,
    abreviatura VARCHAR(20) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_efi_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
	CONSTRAINT chk_efi_banco_min_longitud CHECK (LENGTH(TRIM(banco)) >= 3),
    CONSTRAINT chk_efi_abreviatura_min_longitud CHECK (LENGTH(TRIM(abreviatura)) >= 2),
    CONSTRAINT chk_efi_abreviatura_mayusculas CHECK (abreviatura = UPPER(abreviatura))
);
CREATE UNIQUE INDEX uix_efi_codigo_asfi ON bancos (codigo_asfi) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_efi_abreviatura ON bancos (abreviatura) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE bancos IS 'Reglas de la tabla - bancos
R.0: La tabla bancos constituye el catálogo estandarizado de entidades financieras que operan en el sistema, almacenando tanto el nombre comercial como el código regulador oficial de la ASFI. Su función principal es respaldar los procesos contables y de pagos, permitiendo la asociación de cuentas bancarias propias (empresas_cuentas), de clientes (clientes), y de comprobantes de pago (comprobantes_pagos), garantizando la trazabilidad de las transacciones financieras. Se conecta directamente con las tablas empresas_cuentas, clientes, comprobantes_pagos y tipos_cambios.
R.1: codigo_asfi almacena el código oficial asignado por la ASFI (Autoridad de Supervisión del Sistema Financiero) para identificación regulatoria.
R.3: abreviatura debe almacenarse en mayúsculas y representa el identificador corto de la entidad financiera.
R.4: El campo banco almacena el nombre comercial.';

DELETE FROM bancos;
ALTER SEQUENCE bancos_banco_id_seq RESTART WITH 1;

INSERT INTO bancos (banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', '99', 'NIN', 1000, 1),
(2, 'BANCO NACIONAL DE BOLIVIA S.A.', '01', 'BNB', 1000, 1),
(3, 'BANCO MERCANTIL SANTA CRUZ S.A.', '02', 'BMSC', 1000, 1),
(4, 'BANCO BISA S.A.', '03', 'BISA', 1000, 1),
(5, 'BANCO DE CREDITO DE BOLIVIA S.A.', '04', 'BCB', 1000, 1),
(6, 'BANCO ECONOMICO S.A.', '05', 'BEC', 1000, 1),
(7, 'BANCO GANADERO S.A.', '06', 'BGA', 1000, 1),
(8, 'BANCO SOLIDARIO S.A.', '07', 'BSO', 1000, 1),
(9, 'BANCO UNION S.A.', '08', 'BUN', 1000, 1),
(10, 'BANCO FIE S.A.', '09', 'FIE', 1000, 1),
(11, 'BANCO PRODEM S.A.', '10', 'PRD', 1000, 1),
(12, 'BANCO PYME ECOFUTURO S.A.', '11', 'ECO', 1000, 1),
(13, 'BANCO PYME DE LA COMUNIDAD S.A.', '12', 'BCO', 1000, 1);

UPDATE bancos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE bancos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 1));

-- ================================================================================================

CREATE TABLE tipos_cambios (
    tipo_cambio_id BIGSERIAL PRIMARY KEY,
    origen_moneda_id INTEGER NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    destino_moneda_id INTEGER NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    factor_compra DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    factor_venta DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    fecha_cotizacion DATE NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_tpc_origen_moneda_id FOREIGN KEY (origen_moneda_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tpc_destino_moneda_id FOREIGN KEY (destino_moneda_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tpc_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_tpc_factor_compra CHECK (factor_compra > 0),
    CONSTRAINT chk_tpc_factor_venta CHECK (factor_venta > 0),
    CONSTRAINT chk_tpc_factor_compra_venta CHECK (factor_compra <= factor_venta),
    CONSTRAINT chk_tpc_monedas_diferentes CHECK (origen_moneda_id <> destino_moneda_id)
);
CREATE UNIQUE INDEX uix_tpc_cotizacion_vigente ON tipos_cambios (origen_moneda_id, destino_moneda_id, fecha_cotizacion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE tipos_cambios IS 'Reglas de la tabla - tipos_cambios
R.0: La tabla tipos_cambios gestiona el registro histórico y actualizado de las tasas de cambio entre las diferentes monedas soportadas por el sistema, como el Boliviano (BOB) y el Dólar (USD). Su propósito es respaldar las operaciones de compra y venta en múltiples divisas, proporcionando factores de compra y venta oficiales para la correcta valuación de transacciones financieras, facturación y reportes gerenciales. Se conecta directamente con la tabla bancos para identificar la entidad emisora de la cotización y con dominios para las monedas.
R.1: La restricción chk_tpc_monedas_diferentes valida que para cualquier registro operativo (estado_id = 1000), origen_moneda_id sea diferente de destino_moneda_id, rechazando la transacción si ambas monedas son iguales.
R.2: fecha_cotizacion registra la fecha de vigencia de la tasa de cambio. El índice uix_tpc_cotizacion_vigente garantiza unicidad por combinación de origen_moneda_id, destino_moneda_id y fecha_cotizacion para registros activos o históricos.';

DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro) VALUES
(1, 2300, 2301, 1.0000, 1.0000, '2099-12-31', 1000, 1),
(2, 2300, 2301, 6.8600, 6.9600, '2026-07-01', 1000, 1),
(3, 2300, 2301, 6.8600, 6.9600, '2026-07-02', 1000, 1),
(4, 2300, 2301, 6.8600, 6.9600, '2026-07-03', 1000, 1),
(5, 2300, 2301, 6.8600, 6.9600, '2026-07-04', 1000, 1),
(6, 2300, 2301, 6.8600, 6.9600, '2026-07-05', 1000, 1),
(7, 2300, 2301, 6.8600, 6.9600, '2026-07-06', 1000, 1),
(8, 2300, 2301, 6.8600, 6.9600, '2026-07-07', 1000, 1),
(9, 2300, 2301, 6.8600, 6.9600, '2026-07-08', 1000, 1),
(10, 2300, 2301, 6.8600, 6.9600, '2026-07-09', 1000, 1),
(11, 2300, 2301, 6.8600, 6.9600, '2026-07-10', 1000, 1),
(12, 2300, 2301, 6.8600, 6.9600, '2026-07-11', 1000, 1),
(13, 2300, 2301, 6.8600, 6.9600, '2026-07-12', 1000, 1),
(14, 2300, 2301, 6.8600, 6.9600, '2026-07-13', 1000, 1),
(15, 2300, 2301, 6.8600, 6.9600, '2026-07-14', 1000, 1),
(16, 2300, 2301, 6.8600, 6.9600, '2026-07-15', 1000, 1),
(17, 2300, 2301, 6.8600, 6.9600, '2026-07-16', 1000, 1),
(18, 2300, 2301, 6.8600, 6.9600, '2026-07-17', 1000, 1),
(19, 2300, 2301, 6.8600, 6.9600, '2026-07-18', 1000, 1),
(20, 2300, 2301, 6.8600, 6.9600, '2026-07-19', 1000, 1),
(21, 2300, 2301, 6.8600, 6.9600, '2026-07-20', 1000, 1),
(22, 2300, 2301, 6.8600, 6.9600, '2026-07-21', 1000, 1),
(23, 2300, 2301, 6.8600, 6.9600, '2026-07-22', 1000, 1),
(24, 2300, 2301, 6.8600, 6.9600, '2026-07-23', 1000, 1),
(25, 2300, 2301, 6.8600, 6.9600, '2026-07-24', 1000, 1),
(26, 2300, 2301, 6.8600, 6.9600, '2026-07-25', 1000, 1),
(27, 2300, 2301, 6.8600, 6.9600, '2026-07-26', 1000, 1),
(28, 2300, 2301, 6.8600, 6.9600, '2026-07-27', 1000, 1),
(29, 2300, 2301, 6.8600, 6.9600, '2026-07-28', 1000, 1),
(30, 2300, 2301, 6.8600, 6.9600, '2026-07-29', 1000, 1),
(31, 2300, 2301, 6.8600, 6.9600, '2026-07-30', 1000, 1),
(32, 2300, 2301, 6.8600, 6.9600, '2026-07-31', 1000, 1);

UPDATE tipos_cambios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_cambios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 1));

-- ================================================================================================

CREATE TABLE empresas (
    empresa_id BIGSERIAL PRIMARY KEY,
    empresa VARCHAR(200) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    logo VARCHAR(255) NOT NULL,
    eslogan VARCHAR(150) NULL,
    descripcion VARCHAR(1500) NULL,
    lugar VARCHAR(100) NULL,
    representante VARCHAR(100) NULL,
    direccion VARCHAR(3000) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    matricula_comercio VARCHAR(50) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_emp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_emp_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_emp_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_emp_codigo_max_length CHECK (LENGTH(TRIM(codigo)) <= 10),
    CONSTRAINT chk_emp_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_emp_empresa_not_empty CHECK (TRIM(empresa) <> ''),
    CONSTRAINT chk_emp_empresa_mayusculas CHECK (empresa = UPPER(empresa)),
    CONSTRAINT chk_emp_empresa_min_length CHECK (LENGTH(TRIM(empresa)) >= 3),
	CONSTRAINT chk_emp_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_emp_logo_not_empty CHECK (TRIM(logo) <> '')
);
CREATE UNIQUE INDEX uix_emp_empresa_unique ON empresas (empresa) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_emp_codigo_unique ON empresas (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_emp_matricula_unique ON empresas (matricula_comercio) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE empresas IS 'Reglas de la tabla - empresas
R.0: La tabla empresas actúa como el nodo raíz de la estructura organizacional, almacenando la información corporativa general de la o las compañías que operan la plataforma sirena. Su función es centralizar la identidad corporativa, incluyendo razón social, logotipo, eslogan y datos de contacto, para personalizar la interfaz de usuario y, más críticamente, para proveer los datos base en la emisión de documentos fiscales y la configuración de sucursales. Se conecta jerárquicamente con sucursales, y a través de empresas_nits y empresas_cuentas con la información tributaria y bancaria de la organización.
R.1: El campo codigo es alfanumérico y corresponde a un dato maestro ingresado manualmente por el usuario desde el formulario; el sistema no genera este código de forma automática.
R.2: La columna logo almacena únicamente el nombre del archivo y su extensión (ej. ''2.jpg''). La resolución de la URL absoluta para el renderizado en el frontend se realiza mediante variable de entorno.
R.3: El campo empresa registra el nombre comercial de la empresa.';

DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.jpg', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@dominio.com', 'MAT-000', 1000, 1),
(2, 'FARMACIA SALUD Y VIDA S.R.L.', '309', '2.jpg', 'Tu salud es nuestra prioridad', 'Venta de medicamentos', 'LA PAZ - BOLIVIA', 'JUAN PEREZ FLORES', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '22441122', 'central@saludyvida.com.bo', 'M-356981', 1000, 1);

UPDATE empresas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_empresa_id_seq', COALESCE((SELECT MAX(empresa_id) FROM empresas), 1));

-- ================================================================================================

CREATE TABLE empresas_nits (
    empresa_nit_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
    ambiente_id INTEGER NOT NULL DEFAULT 2751,        		-- 2750=PRODUCCION, 2751=PILOTO_PRUEBAS
    nit VARCHAR(20) NOT NULL,
    razon_social VARCHAR(500) NOT NULL,
    actividad_economica_principal VARCHAR(2000) NOT NULL,
    modalidad_facturacion_id INTEGER NOT NULL DEFAULT 3900,	-- 3900=NINGUNO, 3901=ELECTRONICA, 3902=COMPUTARIZADA, 3903=MANUAL
    certificado_digital VARCHAR(1000) NULL,
    certificado_password VARCHAR(500) NULL,
    token_siat VARCHAR(2000) NULL,
    fecha_inicio_vigencia DATE NULL,
    fecha_fin_vigencia DATE NULL,
    email_fiscal VARCHAR(200) NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_en_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT fk_en_ambiente_id FOREIGN KEY (ambiente_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_en_modalidad_facturacion_id FOREIGN KEY (modalidad_facturacion_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_en_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_en_nit_numerico CHECK (nit ~ '^[0-9]+$'),
    CONSTRAINT chk_en_nit_not_empty CHECK (TRIM(nit) <> ''),
    CONSTRAINT chk_en_nit_min_length CHECK (LENGTH(TRIM(nit)) >= 7),
    CONSTRAINT chk_en_nit_max_length CHECK (LENGTH(TRIM(nit)) <= 20),
    CONSTRAINT chk_en_razon_social_not_empty CHECK (TRIM(razon_social) <> ''),
    CONSTRAINT chk_en_razon_social_min_length CHECK (LENGTH(TRIM(razon_social)) >= 3),
    CONSTRAINT chk_en_actividad_economica_not_empty CHECK (TRIM(actividad_economica_principal) <> ''),
    CONSTRAINT chk_en_actividad_economica_min_length CHECK (LENGTH(TRIM(actividad_economica_principal)) >= 3),
    CONSTRAINT chk_en_email_fiscal_formato CHECK (email_fiscal ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_en_email_fiscal_not_empty CHECK (TRIM(email_fiscal) <> ''),
    CONSTRAINT chk_en_fechas_vigencia CHECK (fecha_inicio_vigencia IS NULL OR fecha_fin_vigencia IS NULL OR fecha_inicio_vigencia <= fecha_fin_vigencia)
);
CREATE UNIQUE INDEX uix_en_nit_activo ON empresas_nits (nit) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_en_nit_historico ON empresas_nits (nit, fecha_inicio_vigencia, fecha_fin_vigencia) WHERE estado_id = 1002;

COMMENT ON TABLE empresas_nits IS 'Reglas de la tabla - empresas_nits
R.0: La tabla empresas_nits almacena la información de dosificación fiscal de la empresa, incluyendo el NIT, número de autorización y fechas de vigencia, necesaria para el cumplimiento de las obligaciones tributarias ante el Servicio de Impuestos Nacionales (SIN). Su propósito es controlar los rangos de numeración de facturas y la vigencia de los talonarios fiscales, asegurando que la emisión de comprobantes electrónicos se realice con credenciales válidas y activas. Se conecta directamente con la tabla empresas.
R.1: Una misma empresa (empresa_id) puede operar con el mismo número de nit bajo distintas modalidades de facturación y ambientes dependiendo de la sucursal o punto de venta asignado. El frontend debe desplegar las descripciones de la actividad económica de forma segmentada según la dosificación seleccionada.
R.2: El campo modalidad_facturacion_id controla el tipo de facturación autorizada por el SIN: ELECTRONICA, COMPUTARIZADA o MANUAL, afectando el flujo de emisión de comprobantes.
R.3: El campo ambiente_id define si el NIT se utiliza en entorno de producción (2750) o en piloto/pruebas (2751), permitiendo validaciones sin afectar documentos fiscales reales.
R.4: Los campos certificado_digital y certificado_password almacenan la ruta del archivo .p12 y su contraseña para la firma digital de documentos electrónicos. El token_siat contiene el token de acceso a los Web Services del SIN.';

DELETE FROM empresas_nits;
ALTER SEQUENCE empresas_nits_empresa_nit_id_seq RESTART WITH 1;

INSERT INTO empresas_nits (empresa_nit_id, empresa_id, ambiente_id, nit, razon_social, actividad_economica_principal, modalidad_facturacion_id, certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id, usuario_id_registro) VALUES
(1, 1, 2751, '0000000', 'NINGUNO', 'NINGUNA', 3900, NULL, NULL, NULL, NULL, NULL, 'ninguno@ninguno.com', 1000, 1);

UPDATE empresas_nits SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_nits SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_nits_empresa_nit_id_seq', COALESCE((SELECT MAX(empresa_nit_id) FROM empresas_nits), 1));

-- ================================================================================================

CREATE TABLE empresas_cuentas (
    empresa_cuenta_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
    banco_id BIGINT NOT NULL DEFAULT 1,
    tipo_moneda_id INTEGER NOT NULL DEFAULT 2300,  		-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    nro_cuenta VARCHAR(50) NOT NULL,
    tipo_cuenta_id INTEGER NOT NULL DEFAULT 1755,  		-- 1750=CUENTA_CORRIENTE, 1751=CAJA_AHORROS, 1752=AHORRO_PROGRAMADO, 1753=PLAZO_FIJO, 1754=INVERSION, 1755=NO_APLICA
    titular VARCHAR(150) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ecb_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT fk_ecb_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
    CONSTRAINT fk_ecb_tipo_moneda_id FOREIGN KEY (tipo_moneda_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_ecb_tipo_cuenta_id FOREIGN KEY (tipo_cuenta_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_ecb_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ecb_nro_cuenta_min CHECK (LENGTH(TRIM(nro_cuenta)) >= 5),
    CONSTRAINT chk_ecb_titular_not_empty CHECK (TRIM(titular) <> ''),
    CONSTRAINT chk_ecb_titular_min_length CHECK (LENGTH(TRIM(titular)) >= 3)
);
CREATE UNIQUE INDEX uix_ecb_cuenta_unica ON empresas_cuentas (empresa_id, banco_id, nro_cuenta, tipo_moneda_id, tipo_cuenta_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE empresas_cuentas IS 'Reglas de la tabla - empresas_cuentas
R.0: La tabla empresas_cuentas gestiona el catálogo de cuentas bancarias operativas de la empresa, registrando la entidad financiera, el tipo de cuenta, la moneda y el titular. Su función es proporcionar la información de las cuentas de destino para la recepción de pagos de clientes, la realización de transferencias y la conciliación bancaria de los movimientos de caja. Se conecta directamente con las tablas empresas y bancos.
R.1: titular almacena la razón social autorizada para las operaciones bancarias.
R.2: tipo_cuenta_id define la naturaleza de la cuenta bancaria (CUENTA_CORRIENTE, CAJA_AHORROS, AHORRO_PROGRAMADO, PLAZO_FIJO, INVERSION o NO_APLICA), afectando la disponibilidad de fondos y los tipos de transacciones permitidas.
R.3: La restricción uix_ecb_cuenta_unica garantiza que no existan cuentas duplicadas para el mismo banco y número de cuenta en registros activos o históricos.';

DELETE FROM empresas_cuentas;
ALTER SEQUENCE empresas_cuentas_empresa_cuenta_id_seq RESTART WITH 1;

INSERT INTO empresas_cuentas (empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 2300, '0000000000', 1755, 'NINGUNO', 1000, 1);

UPDATE empresas_cuentas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_cuentas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_cuentas_empresa_cuenta_id_seq', COALESCE((SELECT MAX(empresa_cuenta_id) FROM empresas_cuentas), 1));

-- ================================================================================================

CREATE TABLE sucursales (
    sucursal_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
    sucursal VARCHAR(2000) NOT NULL,
    sucursal_largo VARCHAR(2000) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    codigo_sin INTEGER NOT NULL,
    telefono VARCHAR(100) NULL,
    ubicacion VARCHAR(500) NULL,
    horario_atencion VARCHAR(200) NULL,
    factor_venta DECIMAL(12,2) NOT NULL DEFAULT 1.50,
    factor_facturacion DECIMAL(12,2) NOT NULL DEFAULT 1.19,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_suc_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
	CONSTRAINT fk_suc_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_suc_codigo_sin CHECK (codigo_sin >= 0),
    CONSTRAINT chk_suc_sucursal_not_empty CHECK (TRIM(sucursal) <> ''),
    CONSTRAINT chk_suc_sucursal_largo_not_empty CHECK (TRIM(sucursal_largo) <> ''),
    CONSTRAINT chk_suc_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_suc_codigo_longitud CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_suc_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_suc_factor_venta CHECK (factor_venta > 1),
	CONSTRAINT chk_suc_factor_facturacion CHECK (factor_facturacion > 1)
);
CREATE UNIQUE INDEX uix_suc_sucursal ON sucursales (empresa_id, sucursal) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_suc_codigo ON sucursales (empresa_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_suc_codigo_sin ON sucursales (empresa_id, codigo_sin) WHERE estado_id = 1000;

COMMENT ON TABLE sucursales IS 'Reglas de la tabla - sucursales
R.0: La tabla sucursales define los puntos de venta operativos de la empresa, mapeando su estructura legal, geográfica y fiscal (código, número de punto de venta). Su propósito es segmentar la operación del negocio por ubicación física, controlando los factores de precio (factor_venta, factor_facturacion) que se heredan a los productos y sirviendo como eje central para los procesos de inventario, ventas, facturación (números de autorización) y asignación de personal. Se conecta directamente con las tablas almacenes, usuarios, facturas, kardex, cajas y analitica_productos.
R.1: Siempre se debe cumplir precio_compra < precio_venta_sin_factura < precio_venta_con_factura. el campo precio_compra esta en la tabla productos.
R.2: codigo_sin representa codigo_sucursal_sin es secuencial por empresa. 0=Casa Matriz, 1,2,3...
R.3: factor_venta y factor_facturacion son valores iniciales que se heredan al crear un producto. Precio Sin Factura = Costo × factor_venta. Precio Con Factura = Costo × factor_venta × factor_facturacion.
R.4: Cada producto preserva sus propios factores de forma independiente, rompiendo la herencia de la sucursal sin afectarla.
R.5: Los nombres sucursal (nombre corto generalmente para reportes) y sucursal_largo (nombre legal).';

DELETE FROM sucursales;
ALTER SEQUENCE sucursales_sucursal_id_seq RESTART WITH 1;

INSERT INTO sucursales (sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', 'NIN', 0, '00000000', 'DIRECCION NINGUNA', '00:00 - 00:00', 1.50, 1.19, 1000, 1),
(2, 2, 'CASA MATRIZ - SOPOCACHI', 'FARMACIA SALUD Y VIDA - CASA MATRIZ SOPOCACHI', 'FSM', 0, '22441122', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '08:00 - 22:00', 1.50, 1.19, 1000, 1),
(3, 2, 'SUCURSAL ZONA SUR', 'FARMACIA SALUD Y VIDA - SUCURSAL ZONA SUR CALACOTO', 'FSZ', 1, '22774433', 'AV. BALLIVIAN NRO. 540, CALACOTO, LA PAZ', '08:00 - 23:00', 1.50, 1.19, 1000, 1);

UPDATE sucursales SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE sucursales SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('sucursales_sucursal_id_seq', COALESCE((SELECT MAX(sucursal_id) FROM sucursales), 1));

-- ================================================================================================

CREATE TABLE puntos_venta (
    punto_venta_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL,
    codigo_punto_venta INTEGER NOT NULL,
    descripcion VARCHAR(500) NULL,
    tipo_punto_venta_id INTEGER NOT NULL DEFAULT 3950,		-- 3950=NINGUNO, 3951=CAJA
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pv_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_pv_tipo_punto_venta_id FOREIGN KEY (tipo_punto_venta_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_pv_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pv_codigo_punto CHECK (codigo_punto_venta >= 0),
    CONSTRAINT chk_pv_descripcion_not_empty CHECK (TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_pv_codigo_punto ON puntos_venta (sucursal_id, codigo_punto_venta) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE puntos_venta IS 'Reglas de la tabla - puntos_venta
R.0: La tabla puntos_venta define los puntos de venta específicos dentro de cada sucursal, permitiendo segmentar operaciones por cajas, mostradores o módulos de atención. Su función es identificar cada punto de emisión de comprobantes fiscales y controlar la asignación de turnos, cajeros y flujo de caja. Se conecta directamente con las tablas sucursales, cajas y facturas.
R.1: codigo_punto_venta es secuencial por sucursal empezando por 0 para el punto de venta principal, incrementando en 1 para cada punto adicional. La combinación de sucursal_id y codigo_punto_venta es única para registros activos o históricos.
R.2: tipo_punto_venta_id clasifica el punto de venta según su función: NINGUNO (3950) para puntos sin clasificar o CAJA (3951) para cajas de cobro, afectando los flujos de facturación y cierre de caja.';

DELETE FROM puntos_venta;
ALTER SEQUENCE puntos_venta_punto_venta_id_seq RESTART WITH 1;

INSERT INTO puntos_venta (punto_venta_id, sucursal_id, codigo_punto_venta, descripcion, tipo_punto_venta_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0, 'NINGUNO', 3950, 1000, 1),
(2, 2, 0, 'CAJA PRINCIPAL - SOPOCACHI', 3951, 1000, 1),
(3, 2, 1, 'CAJA SECUNDARIA - SOPOCACHI', 3951, 1000, 1),
(4, 3, 0, 'CAJA PRINCIPAL - ZONA SUR', 3951, 1000, 1);

UPDATE puntos_venta SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE puntos_venta SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('puntos_venta_punto_venta_id_seq', COALESCE((SELECT MAX(punto_venta_id) FROM puntos_venta), 1));

-- ================================================================================================

CREATE TABLE cuis (
    cuis_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL,
    punto_venta_id BIGINT NULL,
    cuis VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,             -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cuis_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cuis_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT fk_cuis_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cuis_codigo_not_empty CHECK (TRIM(cuis) <> ''),
    CONSTRAINT chk_cuis_fecha_vigencia_futura CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cuis_activo ON cuis (sucursal_id, COALESCE(punto_venta_id, 0)) WHERE estado_id = 1000;

COMMENT ON TABLE cuis IS 'Reglas de la tabla - cuis
R.0: La tabla cuis almacena el Código Único de Identificación del Sistema (CUIS) otorgado por el SIN para la facturación electrónica. Cada sucursal y punto de venta requiere un CUIS vigente para la emisión de comprobantes fiscales. Su propósito es gestionar la validez de los códigos de autorización y controlar la caducidad de los mismos para garantizar la continuidad operativa. Se conecta directamente con las tablas sucursales y puntos_venta.
R.1: fecha_vigencia almacena la fecha y hora de expiración del CUIS devuelta por el SIN. Solo los registros con fecha_vigencia > CURRENT_TIMESTAMP y estado_id = 1000 son considerados vigentes para facturación.
R.2: El índice uix_cuis_activo garantiza que solo exista un CUIS activo por sucursal y punto de venta, utilizando COALESCE para tratar NULL como 0 en puntos_venta a nivel de sucursal.';

DELETE FROM cuis;
ALTER SEQUENCE cuis_cuis_id_seq RESTART WITH 1;

INSERT INTO cuis (cuis_id, sucursal_id, punto_venta_id, cuis, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1);

UPDATE cuis SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cuis SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cuis_cuis_id_seq', COALESCE((SELECT MAX(cuis_id) FROM cuis), 1));

-- ================================================================================================

CREATE TABLE cufd (
    cufd_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL,
    punto_venta_id BIGINT NULL,
    cufd VARCHAR(500) NOT NULL,
    codigo_control VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,             -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cufd_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cufd_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT fk_cufd_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cufd_codigo_not_empty CHECK (TRIM(cufd) <> ''),
    CONSTRAINT chk_cufd_codigo_control_not_empty CHECK (TRIM(codigo_control) <> ''),
    CONSTRAINT chk_cufd_fecha_vigencia_futura CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cufd_activo ON cufd (sucursal_id, COALESCE(punto_venta_id, 0)) WHERE estado_id = 1000;

COMMENT ON TABLE cufd IS 'Reglas de la tabla - cufd
R.0: La tabla cufd almacena el Código Único de Facturación Diaria (CUFD) otorgado por el SIN, necesario para la emisión de comprobantes fiscales electrónicos. Cada sucursal y punto de venta requiere un CUFD vigente con validez de 24 horas para la generación de facturas. Su propósito es gestionar los códigos de autorización diarios y controlar su caducidad para garantizar la continuidad operativa en la facturación electrónica. Se conecta directamente con las tablas sucursales y puntos_venta.
R.1: fecha_vigencia almacena la fecha y hora de expiración del CUFD devuelta por el SIN (vigencia de 24 horas). Solo los registros con fecha_vigencia > CURRENT_TIMESTAMP y estado_id = 1000 son considerados vigentes para la emisión de facturas.
R.2: codigo_control almacena el código de control asociado al CUFD, utilizado para la validación y generación de la firma digital de los comprobantes fiscales.
R.3: El índice uix_cufd_activo garantiza que solo exista un CUFD activo por sucursal y punto de venta, utilizando COALESCE para tratar NULL como 0 en puntos_venta a nivel de sucursal.';

DELETE FROM cufd;
ALTER SEQUENCE cufd_cufd_id_seq RESTART WITH 1;

INSERT INTO cufd (cufd_id, sucursal_id, punto_venta_id, cufd, codigo_control, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNO', 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1);

UPDATE cufd SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cufd SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cufd_cufd_id_seq', COALESCE((SELECT MAX(cufd_id) FROM cufd), 1));


-- ================================================================================================

CREATE TABLE almacenes (
    almacen_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    almacen VARCHAR(200) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    tipo_almacen_id INTEGER NOT NULL DEFAULT 1700,                -- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    tipo_operacion_almacen_id INTEGER NOT NULL DEFAULT 4050,      -- 4050=LOGISTICA_INTERNA, 4051=VENTA_DIRECTA
    descripcion VARCHAR(1500) NULL,
    temperatura_min DECIMAL(5,2) NULL,
    temperatura_max DECIMAL(5,2) NULL,
    humedad_min DECIMAL(5,2) NULL,
    humedad_max DECIMAL(5,2) NULL,
    unidad_temperatura VARCHAR(10) NULL DEFAULT '°C',
    unidad_humedad VARCHAR(10) NULL DEFAULT '%',
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_alm_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_alm_tipo_operacion_almacen_id FOREIGN KEY (tipo_operacion_almacen_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_alm_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_alm_tipo_almacen_id FOREIGN KEY (tipo_almacen_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_alm_almacen_not_empty CHECK (TRIM(almacen) <> ''),
    CONSTRAINT chk_alm_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_alm_codigo_longitud CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_alm_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_alm_temperatura CHECK (
        (temperatura_min IS NULL AND temperatura_max IS NULL) OR
        (temperatura_min IS NOT NULL AND temperatura_max IS NOT NULL AND temperatura_max >= temperatura_min)
    ),
    CONSTRAINT chk_alm_humedad CHECK (
        (humedad_min IS NULL AND humedad_max IS NULL) OR
        (humedad_min IS NOT NULL AND humedad_max IS NOT NULL AND humedad_max >= humedad_min)
    )
);

CREATE UNIQUE INDEX uix_alm_almacen ON almacenes (sucursal_id, almacen) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_alm_codigo ON almacenes (sucursal_id, codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE almacenes IS 'Reglas de la tabla - almacenes
R.0: La tabla almacenes representa las áreas o depósitos físicos dentro de cada sucursal, categorizados por tipo (normal, refrigerado, controlado). Su propósito es organizar el inventario de manera lógica y física, permitiendo la gestión de stock diferenciado por tipo de producto y condición de almacenamiento. Actúa como el contenedor principal para la asignación de ubicaciones y para los movimientos de inventario, asegurando la trazabilidad de la mercancía. Se conecta directamente con las tablas sucursales y ubicaciones.
R.1: Capacidad de Almacenamiento. Cada almacén debe tener una capacidad máxima definida en la tabla ubicaciones (suma de capacidades_maxima de todas las ubicaciones asociadas). El sistema debe validar que el stock_total del almacén (suma de stock_actual de todas las ubicaciones) no exceda la capacidad_total del almacén al momento de registrar movimientos de ingreso.
R.2: Control de Temperatura y Condiciones Especiales. Cuando tipo_almacen_id = 1701 (REFRIGERADO) o 1702 (CONGELADO), el sistema debe permitir el registro de temperatura ambiental y generar alertas si se superan los rangos establecidos (2-8°C para refrigerado, -18°C o menor para congelado). Los productos con tipo_almacen_id = 1701 o 1702 solo pueden ubicarse en almacenes del mismo tipo.
R.3: Almacén de Controlados (ESPECIAL). Cuando tipo_almacen_id = 1703 (ESPECIAL), el sistema debe:
- Exigir doble autorización (dos usuarios diferentes) para cualquier movimiento de ingreso o egreso.
- Registrar obligatoriamente el motivo de cada movimiento en el campo comprobante de kardex.
- Mantener un historial de accesos (usuario, fecha, hora, acción) en una tabla de auditoría independiente o en logs_ejecucion.
R.4: Almacén de Tránsito (TRANSITO). Cuando tipo_almacen_id = 1704 (TRANSITO):
- Solo puede recibir productos provenientes de EGRESO_TRASPASO (evento_id = 1053).
- Los productos en este almacén no están disponibles para venta hasta que sean trasladados a un almacén de VENTA_DIRECTA.
- El stock en tránsito debe ser considerado en los reportes de inventario como "mercadería en camino".
R.5: Almacén de Cuarentena (CUARENTENA). Cuando tipo_almacen_id = 1712 (CUARENTENA):
- Los productos en este almacén están bloqueados para venta.
- Solo se puede ingresar stock mediante eventos de RETIRO_CUARENTENA (evento_id = 1068).
- La salida de cuarentena solo es posible mediante evento de AJUSTE_INGRESO (1056) con autorización especial o DEVOLUCION_PROVEEDOR (1061).
R.6: Cambio de Tipo de Almacén. Cuando se modifica tipo_almacen_id de un almacén con stock actual > 0, el sistema debe:
- Validar que todos los productos en el almacén sean compatibles con el nuevo tipo.
- Generar una alerta de seguridad si se cambia de un tipo especial a uno normal.
- Registrar el cambio en logs_ejecucion con nivel_log_id = 3151 (WARNING).
R.7: Venta Directa Dinámica. El carácter comercial del almacén se determina mediante la tabla almacenes_puntos_venta. Las ventas (evento_id = 1051) solo pueden afectar stock de almacenes vinculados a puntos de venta activos. Los almacenes con puntos de venta vinculados no pueden ser de tipo TRANSITO (1704), RECEPCION (1709), DEVOLUCIONES (1710), DESPACHO (1711) o CUARENTENA (1712).
R.8: Control de Stock Mínimo por Almacén. Cada almacén debe tener un umbral mínimo de stock global definido. El sistema debe generar alertas cuando el stock_total del almacén caiga por debajo de este umbral.
R.9: Auditoría de Movimientos de Almacén. Cada vez que un producto cambia de almacén (por traspaso, reubicación, ajuste), se debe registrar en ubicaciones_historial con:
- ubicacion_origen_id = NULL (cambio de almacén)
- ubicacion_destino_id = nueva ubicación en el almacén destino
- motivo = "TRASPASO_ALMACEN" + referencia al kardex_id correspondiente
R.10: Relación con Sucursales. Un almacén no puede ser trasladado entre sucursales. Para mover productos entre sucursales, se debe usar el flujo de traspasos (evento_id = 1053 EGRESO_TRASPASO y 1054 INGRESO_TRASPASO).
R.11: Registro Comodín. El registro con almacen_id = 1 (NINGUNO) es el registro predeterminado. No puede ser modificado ni eliminado. Sirve como valor por defecto para las FK que requieran un almacén de referencia.
R.12: Capacidad Máxima por Tipo de Producto. El sistema debe validar que al asignar un producto a una ubicación dentro del almacén, el tipo_almacen_id del producto (productos.tipo_almacen_id) sea compatible con el tipo_almacen_id del almacén. Si no son compatibles, debe rechazar la operación con el mensaje: "El producto requiere almacenamiento tipo X, pero el almacén es tipo Y".
R.13: Control de Temperatura y Humedad:
- Solo los almacenes de tipo REFRIGERADO (1701), CONGELADO (1702) y ESPECIAL (1703) pueden tener valores de temperatura y humedad definidos mediante los campos temperatura_min, temperatura_max, humedad_min y humedad_max.
- temperatura_min y temperatura_max definen el rango permitido en la unidad configurada (por defecto °C).
- humedad_min y humedad_max definen el rango permitido en porcentaje (%).
- El sistema debe registrar en logs_ejecucion las desviaciones de temperatura con nivel_log_id = 3151 (WARNING) cuando se detecten mediciones fuera de rango.
- Para almacenes de tipo NORMAL (1700), estos campos deben permanecer NULL.
R.14: Control de Capacidad:
- capacidad_total se calcula como la suma de capacidad_maxima de todas las ubicaciones activas del almacén.
- El sistema debe validar que el stock_total del almacén (suma de stock_actual de todas las ubicaciones) no exceda la capacidad_total.
- La unidad de medida de capacidad_total se determina por el producto predominante en el almacén. El backend debe convertir todas las cantidades a una unidad base común para el cálculo de capacidad.';

DELETE FROM almacenes;
ALTER SEQUENCE almacenes_almacen_id_seq RESTART WITH 1;

INSERT INTO almacenes (almacen_id, sucursal_id, almacen, codigo, tipo_almacen_id, tipo_operacion_almacen_id, descripcion, temperatura_min, temperatura_max, humedad_min, humedad_max, unidad_temperatura, unidad_humedad, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NIN', 1700, 4050, 'ALMACEN COMODIN', NULL, NULL, NULL, NULL, '°C', '%', 1000, 1);

UPDATE almacenes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_almacen_id_seq', COALESCE((SELECT MAX(almacen_id) FROM almacenes), 1));

-- ================================================================================================

CREATE TABLE ubicaciones (
    ubicacion_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(50) NOT NULL,
    jerarquia JSONB NOT NULL DEFAULT '{}'::jsonb,
    descripcion VARCHAR(500) NULL,
    capacidad_maxima DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_actual DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    umbral_minimo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    metadata JSONB NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_uba_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
    CONSTRAINT fk_uba_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_uba_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_uba_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_uba_capacidad_maxima CHECK (capacidad_maxima >= 0),
    CONSTRAINT chk_uba_stock_actual CHECK (stock_actual >= 0),
    CONSTRAINT chk_uba_umbral_minimo CHECK (umbral_minimo >= 0),
    CONSTRAINT chk_uba_stock_no_excede_capacidad CHECK (stock_actual <= capacidad_maxima),
    CONSTRAINT chk_uba_jerarquia_estructura CHECK (
        jerarquia IS NULL OR
        jsonb_typeof(jerarquia) = 'object' AND
        (jerarquia ? 'niveles' OR jerarquia ? 'camino')  -- Validación básica
    )
);
CREATE UNIQUE INDEX uix_uba_codigo_unique ON ubicaciones (almacen_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_uba_jerarquia ON ubicaciones USING GIN (jerarquia);

COMMENT ON TABLE ubicaciones IS 'Reglas de la tabla - ubicaciones
R.0: La tabla ubicaciones define la estructura detallada dentro de cada almacén utilizando un esquema jerárquico flexible en formato JSONB. Su propósito principal es optimizar los procesos de picking y el control de inventario al permitir una localización precisa de los productos físicos sin la rigidez de columnas fijas. Se conecta directamente con las tablas almacenes y dominios.
R.1: Estructura Jerárquica y Camino. El campo jerarquia almacena los niveles de ubicación o caminos directos en formato JSONB, permitiendo flexibilidad total sin necesidad de modificar el esquema. Ejemplos válidos de estructuras admitidas:
- Ubicación en estantería:
  {
    "niveles": [
      {"tipo": "PASILLO", "valor": "01"},
      {"tipo": "ESTANTERIA", "valor": "B"},
      {"tipo": "NIVEL", "valor": "03"},
      {"tipo": "POSICION", "valor": "A"}
    ],
    "camino": "PASILLO 01 > ESTANTERIA B > NIVEL 03 > POSICION A"
  }
- Ubicación en refrigerador:
  {
    "niveles": [
      {"tipo": "REFRIGERADOR", "valor": "REF-01"},
      {"tipo": "BANDEJA", "valor": "02"},
      {"tipo": "POSICION", "valor": "CENTRAL"}
    ],
    "camino": "REFRIGERADOR REF-01 > BANDEJA 02 > POSICION CENTRAL"
  }
- Ubicación simple (sin jerarquía):
  {
    "simplificado": true,
    "valor": "VITRINA-A-01"
  }
La estructura debe cumplir con el formato definido. El backend es responsable de validar la coherencia de la jerarquía y de generar el campo "camino" para la visualización rápida en el frontend.
R.2: Control de Capacidad y Stock. Las columnas capacidad_maxima, stock_actual y umbral_minimo se expresan en la unidad base del producto más común almacenado en esa ubicación. Para productos con diferentes unidades, el sistema debe convertir a la unidad base más pequeña común (ej. todas las unidades a mililitros o tabletas). El sistema valida estrictamente que el stock actual no exceda la capacidad máxima permitida. Al registrar movimientos de ingreso, si stock_actual > capacidad_maxima, debe rechazar la operación con el mensaje: "La ubicación X ha alcanzado su capacidad máxima. Disponible: Y, Solicitado: Z".
R.3: Identificador Único (Código). El campo codigo es un identificador corto y único dentro del almacén, escrito obligatoriamente en mayúsculas, sin espacios, y utilizado para escaneo de códigos QR o búsquedas rápidas.
R.4: Unicidad por Almacén. La combinación de almacen_id y codigo debe ser única para registros activos o históricos (estado_id 1000 o 1002), evitando colisiones de códigos en el mismo depósito.
R.5: Información Adicional (Metadata). El campo metadata puede almacenar información adicional específica del tipo de ubicación, como temperatura ambiente, humedad relativa, o condiciones especiales de almacenamiento. Ejemplo: {"temperatura_min": 2, "temperatura_max": 8, "humedad_max": 60}.';

DELETE FROM ubicaciones;
ALTER SEQUENCE ubicaciones_ubicacion_id_seq RESTART WITH 1;

INSERT INTO ubicaciones (ubicacion_id, almacen_id, codigo, jerarquia, descripcion, capacidad_maxima, stock_actual, umbral_minimo, metadata, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', '{"simplificado": true, "valor": "COMODIN", "camino": "COMODIN"}'::jsonb, 'UBICACION COMODIN', 0.00, 0.00, 0.00, NULL, 1000, 1);

UPDATE ubicaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_ubicacion_id_seq', COALESCE((SELECT MAX(ubicacion_id) FROM ubicaciones), 1));

-- ================================================================================================

CREATE TABLE almacenes_puntos_venta (
    almacen_punto_venta_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
    punto_venta_id BIGINT NOT NULL DEFAULT 1,
    prioridad INTEGER NOT NULL DEFAULT 1,
    es_principal INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_apv_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
    CONSTRAINT fk_apv_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT fk_apv_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_apv_es_principal CHECK (es_principal IN (0, 1)),
    CONSTRAINT chk_apv_prioridad CHECK (prioridad > 0)
);
CREATE UNIQUE INDEX uix_apv_almacen_punto_venta ON almacenes_puntos_venta (almacen_id, punto_venta_id) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_apv_principal_por_punto ON almacenes_puntos_venta (punto_venta_id) WHERE es_principal = 1 AND estado_id = 1000;

COMMENT ON TABLE almacenes_puntos_venta IS 'Reglas de la tabla - almacenes_puntos_venta
R.0: La tabla almacenes_puntos_venta gestiona la relación de muchos a muchos entre los almacenes y los puntos de venta (cajas o mostradores de atención). Su propósito es determinar dinámicamente qué almacenes surten a qué puntos de venta, permitiendo que un punto de venta se abastezca de múltiples almacenes y que un almacén central o secundario distribuya mercancía a varias cajas, eliminando la redundancia del campo es_venta_directa en la tabla maestra de almacenes.
R.1: Determinación Dinámica de Venta Directa. Un almacén se clasifica automáticamente como VENTA_DIRECTA (4051) si cuenta con al menos un registro activo en esta tabla. En ausencia de registros activos, se considera de LOGISTICA_INTERNA (4050).
R.2: Restricción de Tipos de Almacén No Comerciales. El sistema debe validar estrictamente que ningún almacén de tipo TRANSITO (1704), RECEPCION (1709), DEVOLUCIONES (1710), DESPACHO (1711) o CUARENTENA (1712) pueda ser vinculado a un punto de venta en esta tabla.
R.3: Prioridad de Despacho. El campo prioridad define el orden de preferencia con el que un punto de venta se surte de sus almacenes vinculados (1 = Mayor prioridad). El backend utiliza este valor para sugerir o automatizar el origen del stock durante la dispensación o venta.
R.4: Almacén Principal por Punto de Venta. El campo es_principal (0 o 1) identifica el depósito por defecto para un punto de venta determinado. Mediante un índice único parcial, se garantiza que cada punto de venta activo posea un único almacén principal asignado.
R.5: Propagación por Baja de Almacén o Punto de Venta. Si el almacén o el punto de venta asociado cambia de estado a BORRADO, el backend debe invalidar la relación correspondiente actualizando su estado a borrado o baja lógica para evitar transacciones sobre depósitos inhabilitados.';

DELETE FROM almacenes_puntos_venta;
ALTER SEQUENCE almacenes_puntos_venta_almacen_punto_venta_id_seq RESTART WITH 1;

INSERT INTO almacenes_puntos_venta (almacen_punto_venta_id, almacen_id, punto_venta_id, prioridad, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1000, 1);

UPDATE almacenes_puntos_venta SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes_puntos_venta SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_puntos_venta_almacen_punto_venta_id_seq', COALESCE((SELECT MAX(almacen_punto_venta_id) FROM almacenes_puntos_venta), 1));

-- ================================================================================================

CREATE TABLE cargos (
    cargo_id BIGSERIAL PRIMARY KEY,
    cargo VARCHAR(150) NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_car_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_car_cargo_not_empty CHECK (TRIM(cargo) <> '' AND LENGTH(TRIM(cargo)) >= 3)
);
CREATE UNIQUE INDEX uix_car_cargo_unique ON cargos (cargo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE cargos IS 'Reglas de la tabla - cargos
R.0: La tabla cargos define los puestos de trabajo o roles laborales dentro de la organización, sirviendo para clasificar al personal y definir jerarquías operativas. Se conecta directamente con la tabla usuarios o asignaciones de personal.';

DELETE FROM cargos;
ALTER SEQUENCE cargos_cargo_id_seq RESTART WITH 1;

INSERT INTO cargos (cargo_id, cargo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'CARGO COMODIN', 1000, 1),
(2, 'ADMINISTRADOR DEL SISTEMA', 'Gestión integral, configuración y control total de la plataforma.', 1000, 1),
(3, 'GERENTE GENERAL', 'Dirección estratégica y toma de decisiones corporativas.', 1000, 1),
(4, 'ADMINISTRADOR DE SUCURSAL', 'Supervisión de inventarios, dispensación y control de almacenes.', 1000, 1),
(5, 'CONTADOR', 'Contabilidad.', 1000, 1),
(6, 'COMPRAS', 'Encargado de compras.', 1000, 1),
(7, 'VENTAS', 'Encargado de ventas.', 1000, 1),
(8, 'INVENTARIO', 'Encargado del inventario.', 1000, 1),
(9, 'MENSAJERO', 'Encargado de mensajeria.', 1000, 1);

UPDATE cargos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cargos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cargos_cargo_id_seq', COALESCE((SELECT MAX(cargo_id) FROM cargos), 1));

-- ================================================================================================

CREATE TABLE trabajadores (
    trabajador_id BIGSERIAL PRIMARY KEY,
    genero_id INTEGER NOT NULL DEFAULT 1200,  		-- 1200=MASCULINO, 1201=FEMENINO
    estado_civil_id INTEGER NOT NULL DEFAULT 1250,  -- 1250=SOLTERO, 1251=CASADO, 1252=DIVORCIADO, 1253=VIUDO, 1254=UNION_LIBRE y 1300=SOLTERA, 1301=CASADA, 1302=DIVORCIADA, 1303=VIUDA, 1304=UNION_LIBRE
    nombres VARCHAR(150) NOT NULL,
    paterno VARCHAR(80) NOT NULL,
    materno VARCHAR(80) NULL,
    dni VARCHAR(20) NOT NULL,
	telefono VARCHAR(20) NULL,
	direccion VARCHAR(1000) NULL,
    email VARCHAR(100) NULL,
    fecha_nacimiento DATE NULL,
    fecha_contratacion DATE NULL,
    foto VARCHAR(255) NOT NULL,
	qr VARCHAR(255) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_tra_genero_id FOREIGN KEY (genero_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tra_estado_civil_id FOREIGN KEY (estado_civil_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tra_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_tra_nombres_not_empty CHECK (TRIM(nombres) <> '' AND LENGTH(TRIM(nombres)) >= 3),
    CONSTRAINT chk_tra_paterno_not_empty CHECK (TRIM(paterno) <> '' AND LENGTH(TRIM(paterno)) >= 3),
    CONSTRAINT chk_tra_dni_not_empty CHECK (TRIM(dni) <> '' AND LENGTH(TRIM(dni)) >= 5),
    CONSTRAINT chk_tra_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);
CREATE UNIQUE INDEX uix_tra_dni_unique ON trabajadores (dni) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE trabajadores IS 'Reglas de la tabla - trabajadores
R.0: La tabla trabajadores actúa como el registro maestro de individuos, centralizando la información demográfica básica de todos los actores del sistema, incluyendo empleados, clientes eventuales y contactos. Su propósito es servir como la entidad raíz de identificación personal, evitando la duplicación de datos y proporcionando una base de datos unificada para la creación de usuarios del sistema, gestión de clientes y cualquier otra interacción que requiera datos personales. Se conecta directamente con la tabla usuarios.
R.1: Prerrequisito Operativo Maestro. El registro completo y validado de un individuo en esta tabla es un requerimiento técnico obligatorio antes de que el sistema le pueda asignar credenciales de acceso, roles o vincularlo como operador activo en cualquier sucursal.
R.2: qr el backend debe generar la imagen de qr con datos del trabajador nombres, paterno, materno, dni, telefono.
R.3: Gestión de Archivos y Metadatos Digitales. Los campos foto y qr almacenan exclusivamente las rutas lógicas de los archivos correspondientes en el servidor. La generación del código QR y el procesamiento de la imagen se realizan de forma asíncrona en el backend. Siguiendo la regla general R.G.4, la desactivación de un registro no elimina físicamente estos recursos del disco.
R.4: Consistencia de Identidad Única. La restricción de unicidad sobre el documento de identidad (dni) se aplica de forma estricta sobre registros con estado ACTIVO e HISTORICO. Esto impide la duplicidad de trabajadores vigentes dentro de la plataforma, permitiendo la reutilización del valor únicamente si el registro previo ha sido modificado al estado BORRADO.
R.5: Integridad de Estado Civil y Género. El sistema utiliza dos dominios independientes para estado civil: EstadoCivilMasculinoID (1250-1254) para género MASCULINO y EstadoCivilFemeninoID (1300-1304) para género FEMENINO. El frontend debe filtrar las opciones de estado civil según el género seleccionado, mostrando SOLTERO/CASADO/DIVORCIADO/VIUDO/UNION LIBRE para MASCULINO y SOLTERA/CASADA/DIVORCIADA/VIUDA/UNION LIBRE para FEMENINO.
R.6: El campo `foto` almacena el nombre del archivo fisico de la imagen de perfil del trabajador. La imagen puede ser subida por el usuario o, si no se proporciona, se asigna una imagen por defecto. El backend controla la creación y el reemplazo del archivo según la R.G.4.
R.7: Para el registro comodín (trabajador_id = 1), el backend debe generar un archivo QR que contenga el texto "NINGUNO" o un identificador similar que indique su naturaleza de registro por defecto, asegurando su existencia según la R.G.6.';

DELETE FROM trabajadores;
ALTER SEQUENCE trabajadores_trabajador_id_seq RESTART WITH 1;

INSERT INTO trabajadores (trabajador_id, genero_id, estado_civil_id, nombres, paterno, materno, dni, telefono, email, fecha_nacimiento, fecha_contratacion, foto, qr, estado_id, usuario_id_registro) VALUES
(1, 1200, 1250, 'NINGUNO', 'NINGUNO', NULL, '0000000', NULL, NULL, NULL, NULL, '1.jpg', '1.png', 1000, 1),
(2, 1200, 1251, 'FRANZ', 'IBAÑEZ', NULL, '2630198', '60241524', 'franz.ibanez.c@gmail.com', '1980-06-24', NULL, '2.jpg', '2.png', 1000, 1),
(3, 1200, 1250, 'PASCUAL', 'QUISPE', 'HUANCA', '4892014', '70541489', 'pascual.q.h@hotmail.com', '1982-01-27', NULL, '3.png', '3.png', 1000, 1),
(4, 1201, 1301, 'GLADYS', 'ALANOCA', NULL, '3482910', '60241524', 'gladys.alanoca@gmail.com', '1980-06-24', NULL, '4.jpg', '4.png', 1000, 1),
(5, 1201, 1300, 'SILVIA', 'QUISPE', NULL, '6105824', '65201478', 'silvia.quispe@outlook.com', '1976-04-01', NULL, '5.jpg', '5.png', 1000, 1),
(6, 1200, 1250, 'JUAN PABLO', 'HIDALGO', 'HUANCA', '8342915', '71524311', 'jphidalgo.h@gmail.com', '1988-09-15', NULL, '6.jpg', '6.png', 1000, 1),
(7, 1200, 1250, 'MARCELO', 'VARGAS', 'FLORES', '5920147', '72014589', 'marcelovargas.f@hotmail.com', '1985-11-03', NULL, '7.jpg', '7.png', 1000, 1),
(8, 1201, 1301, 'BEATRIZ', 'MENDOZA', 'ROJAS', '12409581', '60112233', 'beatriz.mendoza.r@gmail.com', '1993-03-22', NULL, '8.png', '8.png', 1000, 1),
(9, 1201, 1300, 'CARLA', 'LOPEZ', 'ESTRADA', '7301948', '60581422', 'carla.lopez.e@gmail.com', '1991-05-14', NULL, '9.jpg', '9.png', 1000, 1),
(10, 1200, 1250, 'RODRIGO', 'APAZA', 'MAMANI', '4910283', '70611224', 'rodrigo.apaza@hotmail.com', '1989-12-08', NULL, '10.jpg', '10.png', 1000, 1),
(11, 1200, 1251, 'HECTOR', 'CONDO', 'ALANOCA', '5432109', '71254896', 'hector.condo@gmail.com', '1984-07-19', NULL, '11.jpg', '11.png', 1000, 1),
(12, 1201, 1300, 'PATRICIA', 'CHAVEZ', 'SOLIZ', '6198420', '65124578', 'patricia.chavez@outlook.com', '1995-10-02', NULL, '12.jpg', '12.png', 1000, 1),
(13, 1200, 1250, 'DIEGO', 'PINTO', 'GUTIERREZ', '8412975', '73021456', 'gustavo.pinto@gmail.com', '1992-04-30', NULL, '13.jpg', '13.png', 1000, 1),
(14, 1201, 1300, 'MONICA', 'SILES', 'ORELLANA', '9120843', '60145879', 'monica.siles@hotmail.com', '1990-02-15', NULL, '14.jpg', '14.png', 1000, 1),
(15, 1201, 1301, 'VALERIA', 'RIVERA', 'CRUZ', '3490218', '71954823', 'valeria.rivera.c@gmail.com', '1987-11-25', NULL, '15.png', '15.png', 1000, 1),
(16, 1200, 1250, 'ALEXANDER', 'QUISPE', 'CHOQUE', '7891234', '71589632', 'alexander.quispe@gmail.com', '2000-05-12', NULL, '16.jpg', '16.png', 1000, 1),
(17, 1200, 1250, 'KEVIN', 'MAMANI', 'FLORES', '6547891', '72036541', 'kevin.mamani@hotmail.com', '2002-08-19', NULL, '17.jpg', '17.png', 1000, 1);

UPDATE trabajadores SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE trabajadores SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('trabajadores_trabajador_id_seq', COALESCE((SELECT MAX(trabajador_id) FROM trabajadores), 1));

-- ================================================================================================

CREATE TABLE trabajadores_cargos (
    trabajador_cargo_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL,
    cargo_id BIGINT NOT NULL,
	sueldo_base DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	tipo_moneda_id INTEGER NOT NULL DEFAULT 2300,		-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
	fecha_desde DATE NOT NULL DEFAULT CURRENT_DATE,
	fecha_hasta DATE NULL,
	es_activo INTEGER NOT NULL DEFAULT 1,
	observaciones VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_trc_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_trc_cargo_id FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id),
    CONSTRAINT fk_trc_tipo_moneda_id FOREIGN KEY (tipo_moneda_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_trc_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
	CONSTRAINT chk_trc_sueldo CHECK (sueldo_base >= 0),
	CONSTRAINT chk_trc_es_activo CHECK (es_activo IN (0, 1)),
	CONSTRAINT chk_trc_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta >= fecha_desde)
);
CREATE UNIQUE INDEX uix_trc_trabajador_cargo_activo ON trabajadores_cargos (trabajador_id, cargo_id) WHERE es_activo = 1 AND estado_id = 1000;

COMMENT ON TABLE trabajadores_cargos IS 'Reglas de la tabla - trabajadores_cargos
R.0: La tabla trabajadores_cargos actúa como entidad asociativa (relación N:M) entre trabajadores y cargos, permitiendo asignar uno o múltiples puestos laborales a un trabajador con su respectiva trazabilidad histórica y estado vigente.';

DELETE FROM trabajadores_cargos;
ALTER SEQUENCE trabajadores_cargos_trabajador_cargo_id_seq RESTART WITH 1;

INSERT INTO trabajadores_cargos (trabajador_cargo_id, trabajador_id, cargo_id, sueldo_base, tipo_moneda_id, es_activo, estado_id, usuario_id_registro) VALUES
(1, 2, 2, 8000.00, 2300, 1, 1000, 1),
(2, 3, 4, 6000.00, 2300, 1, 1000, 1),
(3, 4, 5, 5500.00, 2300, 1, 1000, 1),
(4, 5, 4, 6000.00, 2300, 1, 1000, 1),
(5, 6, 7, 3500.00, 2300, 1, 1000, 1),
(6, 7, 8, 4000.00, 2300, 1, 1000, 1),
(7, 8, 8, 4000.00, 2300, 1, 1000, 1),
(8, 9, 7, 3500.00, 2300, 1, 1000, 1),
(9, 10, 8, 4000.00, 2300, 1, 1000, 1),
(10, 11, 8, 4000.00, 2300, 1, 1000, 1),
(11, 12, 6, 4500.00, 2300, 1, 1000, 1),
(12, 13, 7, 3500.00, 2300, 1, 1000, 1),
(13, 14, 8, 4000.00, 2300, 1, 1000, 1),
(14, 15, 3, 15000.00, 2300, 1, 1000, 1),
(15, 16, 9, 3000.00, 2300, 1, 1000, 1),
(16, 17, 9, 3000.00, 2300, 1, 1000, 1);

UPDATE trabajadores_cargos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE trabajadores_cargos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('trabajadores_cargos_trabajador_cargo_id_seq', COALESCE((SELECT MAX(trabajador_cargo_id) FROM trabajadores_cargos), 1));

-- ================================================================================================

CREATE TABLE roles (
    rol_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    rol VARCHAR(60) NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_rol_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_rol_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_rol_codigo_longitud CHECK (LENGTH(TRIM(codigo)) >= 2 AND LENGTH(TRIM(codigo)) <= 5),
    CONSTRAINT chk_rol_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_rol_rol_not_empty CHECK (TRIM(rol) <> ''),
    CONSTRAINT chk_rol_rol_mayusculas CHECK (rol = UPPER(rol))
);
CREATE UNIQUE INDEX uix_rol_codigo_unique ON roles (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_rol_rol_unique ON roles (rol) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE roles IS 'Reglas de la tabla - roles
R.0: La tabla roles define los perfiles de acceso y autorización dentro del sistema, estableciendo las categorías jerárquicas de usuarios (Administrador, Gerente, Vendedor). Su propósito es estructurar el modelo de seguridad y control de acceso basado en roles (RBAC), simplificando la gestión de permisos al agrupar operaciones y menús bajo un único perfil que se asigna a los usuarios, garantizando que cada operador tenga acceso únicamente a las funcionalidades pertinentes a su función. Se conecta directamente con las tablas usuarios y roles_menus.
R.1: Inmutabilidad del Perfil Raíz (ADMINISTRADOR). El rol con código ADM es el único perfil que cuenta de forma nativa e irrestricta con permisos globales en el backend para realizar operaciones CRUD, archivar y desarchivar sobre el catálogo de roles, usuarios y permisos del sistema.
R.2: Desacoplamiento de Permisos por Menú. La estructura de accesos, vistas funcionales y operaciones granulares (crear, modificar, eliminar, archivar) se delega por completo a las tablas relacionales hijas de asignación de menús, impidiendo lógica rígida o estática ligada a esta entidad.
R.3: Consistencia y Homologación de Códigos. Todo código de rol insertado o modificado en el sistema debe validarse obligatoriamente en mayúsculas sostenidas, con una longitud exacta de entre 2 y 5 caracteres alfanuméricos mediante restricciones CHECK nativas.
R.4: Unicidad Operativa del Catálogo. Se restringe la duplicidad semántica de los roles mediante índices únicos parciales sobre los campos codigo y rol para registros activos o históricos. Esto garantiza la coherencia en la asignación de perfiles sin interferir con registros eliminados lógicamente bajo el estado BORRADO.';

DELETE FROM roles;
ALTER SEQUENCE roles_rol_id_seq RESTART WITH 1;

INSERT INTO roles (rol_id, codigo, rol, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO DEL SISTEMA', 1000, 1),
(2, 'ADM', 'ADMINISTRADOR', 'Control total de la plataforma sirena acceso a todo, tiene todos los permisos', 1000, 1),
(3, 'GER', 'GERENTE', 'Control y acceso a todos los modulos pero solo de lectura', 1000, 1),
(4, 'SUC', 'ENCARGADO DE SUCURSAL', 'Responsable de la supervision, operaciones y arqueos de una sucursal especifica', 1000, 1),
(5, 'COM', 'COMPRADOR', 'Responsable de la gestion de proveedores, ordenes de compra y adquisiciones', 1000, 1),
(6, 'VEN', 'VENDEDOR', 'Responsable de la atencion a clientes, cotizaciones y registro de ventas', 1000, 1),
(7, 'ALM', 'ALMACENERO', 'Responsable de la recepcion de mercaderia, control de stock, ingresos y salidas de almacen', 1000, 1),
(8, 'CAJ', 'CAJERO', 'Responsable de la recepcion de pagos, facturacion y apertura/cierre de caja chica', 1000, 1);

UPDATE roles SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_rol_id_seq', COALESCE((SELECT MAX(rol_id) FROM roles), 1));

-- ================================================================================================

CREATE TABLE usuarios (
    usuario_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
	rol_id BIGINT NOT NULL DEFAULT 1,
    login VARCHAR(10) NOT NULL,
    contrasena VARCHAR(500) NOT NULL,
    avatar VARCHAR(255) NOT NULL DEFAULT 'default-avatar.png',
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_usu_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_usu_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
	CONSTRAINT fk_usu_rol_id FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
	CONSTRAINT fk_usu_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_usu_login_mayusculas CHECK (login = UPPER(login)),
    CONSTRAINT chk_usu_login_min_length CHECK (LENGTH(TRIM(login)) >= 4),
    CONSTRAINT chk_usu_login_formato CHECK (login ~ '^[A-Za-z0-9._-]+$'),
    CONSTRAINT chk_usu_contrasena_not_empty CHECK (TRIM(contrasena) <> ''),
    CONSTRAINT chk_usu_avatar_not_empty CHECK (TRIM(avatar) <> '')
);
CREATE UNIQUE INDEX uix_usu_login_unique ON usuarios (login) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE usuarios IS 'Reglas de la tabla - usuarios
R.0: La tabla usuarios gestiona las credenciales de acceso al sistema, vinculando a un trabajador con un rol específico y una sucursal operativa. Su propósito es autenticar y autorizar a los operadores de la plataforma, controlando el inicio de sesión y, mediante el rol_id asociado, determinando los menús y acciones permitidas para cada usuario. Se conecta directamente con las tablas trabajadores, sucursales, roles, cajas, movimientos, pagos, y alertas_notificaciones.
R.1: Restricción Estricta de Identidad (login). El identificador login debe registrarse obligatoriamente en mayúsculas sostenidas, con una longitud mínima de 4 caracteres. Se permiten únicamente letras, números, puntos (.) y guiones bajos (_), prohibiendo espacios o caracteres especiales mediante expresiones regulares nativas.
R.3: Criptografía Asimétrica Obligatoria. Toda contraseña debe ser procesada y almacenada mandatoriamente utilizando funciones de hash seguras de una sola vía (como Bcrypt con un factor de costo mínimo de 10 o Argon2) en el servidor backend, quedando estrictamente prohibido el almacenamiento en texto plano.
R.4: Inmutabilidad del Superusuario Técnico. Las credenciales de la cuenta con identificador ADMIN (vinculadas a la infraestructura central) están protegidas mediante restricciones lógicas en la capa de servicios, impidiendo su eliminación física o la transición de su estado operativo a BORRADO o HISTORICO.
R.5: Vinculación Directa de Perfil (Rol). La cuenta de usuario posee un rol estructural único asignado mediante la propiedad rol_id, el cual determina directamente su perfil operativo en el sistema. A través de este rol único, la plataforma valida de forma unívoca los permisos y opciones de menú habilitados para el operador, simplificando la arquitectura de autenticación.';

DELETE FROM usuarios;
ALTER SEQUENCE usuarios_usuario_id_seq RESTART WITH 1;

INSERT INTO usuarios (usuario_id, trabajador_id, sucursal_id, rol_id, login, contrasena, avatar, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 'NIGUNO', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '1.png', 1000, 1),
(2, 2, 2, 2, 'ADMIN', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '2.png', 1000, 1),
(3, 3, 2, 4, 'PASCUAL', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '3.png', 1000, 1),
(4, 4, 2, 5, 'GLADYS', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '4.png', 1000, 1),
(5, 5, 2, 4, 'SILVIA', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '5.png', 1000, 1),
(6, 6, 2, 6, 'JUAN', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '6.png', 1000, 1),
(7, 7, 2, 7, 'MARCELO', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '7.png', 1000, 1),
(8, 8, 2, 8, 'BEATRIZ', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '8.png', 1000, 1),
(9, 9, 3, 6, 'CARLA', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '9.png', 1000, 1),
(10, 10, 3, 8, 'RODRIGO', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '10.png', 1000, 1),
(11, 11, 3, 7, 'HECTOR', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '11.png', 1000, 1),
(12, 12, 3, 5, 'PATRICIA', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '12.png', 1000, 1),
(13, 13, 3, 6, 'DIEGO', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '13.png', 1000, 1),
(14, 14, 3, 7, 'MONICA', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '14.png', 1000, 1),
(15, 15, 2, 3, 'VALERIA', '$2b$10$bMjyFIk1wpFsHME7OgTOB.802Qs2N.ixngTGvUos1UIteA8F2z3Se', '15.png', 1000, 1);

UPDATE usuarios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE usuarios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('usuarios_usuario_id_seq', COALESCE((SELECT MAX(usuario_id) FROM usuarios), 1));

-- ================================================================================================

CREATE TABLE menus (
    menu_id BIGSERIAL PRIMARY KEY,
    menu_padre_id BIGINT NULL,
    titulo VARCHAR(150) NOT NULL,
    icono VARCHAR(50) NULL,
    url VARCHAR(255) NULL,
    orden INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_men_menu_padre_id FOREIGN KEY (menu_padre_id) REFERENCES menus(menu_id),
	CONSTRAINT fk_men_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_men_titulo_not_empty CHECK (TRIM(titulo) <> '')
);
CREATE UNIQUE INDEX uix_men_titulo_orden_unique ON menus (menu_padre_id, titulo, orden) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_menus_orden_estado ON menus (orden ASC) WHERE estado_id = 1000;

COMMENT ON TABLE menus IS 'Reglas de la tabla - menus
R.0: La tabla menus define la estructura jerárquica y navegacional de la interfaz de usuario, agrupando las funcionalidades del sistema en un árbol de navegación dinámico. Su propósito es construir el menú lateral de la aplicación para cada usuario, basándose en la asignación de permisos de la tabla roles_menus, y de esta manera, presentar únicamente las opciones correspondientes al rol del usuario. Se conecta de forma autorreferencial (menu_padre_id) para formar la jerarquía y con la tabla roles_menus.
R.1: Renderizado del Menú Lateral: El frontend procesará recursivamente la respuesta filtrando o ignorando el menu_id = 1. Aquellos registros cuyo menu_padre_id sea NULL o igual a 1 se tratarán como secciones principales o cabeceras de grupo en el Sidebar de PrimeVue.
R.2: Comportamiento de Enrutamiento: Si el campo url es NULL, el componente actuará exclusivamente como un contenedor colapsable (deshabilitando el enrutador y manejando el estado de expansión de la interfaz).
R.3: Tratamiento del Registro Comodín: El registro con menu_id = 1 representa el nodo raíz ficticio del sistema. No es visible en la interfaz operativa. El backend bloqueará cualquier intento de modificación o eliminación de este registro para salvaguardar la integridad referencial.
R.4: Ordenación Dinámica: Las consultas de menús deben ordenarse por el nivel jerárquico y luego por el campo orden. El frontend respetará estrictamente este índice numérico para la disposición visual de los accesos.';

DELETE FROM menus;
ALTER SEQUENCE menus_menu_id_seq RESTART WITH 1;

INSERT INTO menus (menu_id, menu_padre_id, titulo, icono, url, orden, estado_id, usuario_id_registro) VALUES
(1, NULL, 'NINGUNO', '', NULL, 0, 1000, 1),
(2, NULL, 'CONFIGURACIÓN Y SISTEMA', 'pi pi-cog', NULL, 1, 1000, 1),
(3, 2, 'DATOS DE LA EMPRESA', 'pi pi-building', '/configuracion/empresa', 1, 1000, 1),
(4, 2, 'GESTIÓN DE NITS Y AUTORIZACIONES', 'pi pi-id-card', '/configuracion/nits', 2, 1000, 1),
(5, 2, 'CUENTAS BANCARIAS', 'pi pi-credit-card', '/configuracion/cuentas-bancarias', 3, 1000, 1),
(6, 2, 'SUCURSALES Y PUNTOS', 'pi pi-map-marker', '/configuracion/sucursales', 4, 1000, 1),
(7, 2, 'CONTROL DE USUARIOS', 'pi pi-users', '/configuracion/usuarios', 5, 1000, 1),
(8, 2, 'ROLES Y PERMISOS', 'pi pi-key', '/configuracion/roles', 6, 1000, 1),
(9, 2, 'PARÁMETROS GLOBALES', 'pi pi-sliders-h', '/configuracion/parametros', 7, 1000, 1),
(10, 2, 'TASAS DE CAMBIO', 'pi pi-dollar', '/configuracion/tipos-cambio', 8, 1000, 1),
(11, 2, 'DICCIONARIO DE DOMINIOS', 'pi pi-book', '/configuracion/dominios', 9, 1000, 1),
(12, 2, 'TAREAS PROGRAMADAS', 'pi pi-calendar-clock', '/configuracion/tareas', 10, 1000, 1),
(13, 2, 'LOGS DE EJECUCIÓN', 'pi pi-file-code', '/configuracion/logs', 11, 1000, 1),
(14, 2, 'AUDITORÍA DE DATOS', 'pi pi-eye', '/configuracion/auditoria', 12, 1000, 1),
(15, 2, 'RESPALDOS DE DATOS (BACKUP)', 'pi pi-cloud-upload', '/configuracion/backup', 13, 1000, 1),
(16, NULL, 'GESTIÓN DE PRODUCTOS', 'pi pi-box', NULL, 2, 1000, 1),
(17, 16, 'CATÁLOGO DE PRODUCTOS', 'pi pi-shopping-bag', '/productos/catalogo', 1, 1000, 1),
(18, 16, 'CATEGORÍAS', 'pi pi-tags', '/productos/categorias', 2, 1000, 1),
(19, 16, 'LABORATORIOS', 'pi pi-percentage', '/productos/laboratorios', 3, 1000, 1),
(20, 16, 'PRINCIPIOS ACTIVOS', 'pi pi-info-circle', '/productos/principios-activos', 4, 1000, 1),
(21, 16, 'FORMAS FARMACÉUTICAS', 'pi pi-tablet', '/productos/formas', 5, 1000, 1),
(22, 16, 'PRESENTACIONES COMERCIALES', 'pi pi-clone', '/productos/presentaciones', 6, 1000, 1),
(23, 16, 'CONCENTRACIONES', 'pi pi-filter', '/productos/concentraciones', 7, 1000, 1),
(24, 16, 'REGISTROS SANITARIOS', 'pi pi-file', '/productos/registros-sanitarios', 8, 1000, 1),
(25, 16, 'PRODUCTOS CONTROLADOS', 'pi pi-exclamation-circle', '/productos/controlados', 9, 1000, 1),
(26, 16, 'UNIDADES DE MEDIDA', 'pi pi-calculator', '/productos/unidades', 10, 1000, 1),
(27, 16, 'CONVERSIONES DE UNIDAD', 'pi pi-refresh', '/productos/conversiones', 11, 1000, 1),
(28, 16, 'PROMOCIONES Y OFERTAS', 'pi pi-percentage', '/productos/promociones', 12, 1000, 1),
(29, NULL, 'INVENTARIOS Y ALMACENES', 'pi pi-home', NULL, 3, 1000, 1),
(30, 29, 'ALMACENES FÍSICOS', 'pi pi-map', '/inventario/almacenes', 1, 1000, 1),
(31, 29, 'UBICACIONES INTERNAS', 'pi pi-compass', '/inventario/ubicaciones', 2, 1000, 1),
(32, 29, 'MOVIMIENTOS DE KARDEX', 'pi pi-list', '/inventario/kardex', 3, 1000, 1),
(33, 29, 'CONTROL DE LOTES', 'pi pi-barcode', '/inventario/lotes', 4, 1000, 1),
(34, 29, 'TRASPASOS INTER-SUCURSALES', 'pi pi-arrow-h', '/inventario/traspasos', 5, 1000, 1),
(35, 29, 'DISTRIBUCIÓN EN ESTANTERÍAS', 'pi pi-server', '/inventario/productos-ubicaciones', 6, 1000, 1),
(36, NULL, 'COMPRAS Y PROVEEDORES', 'pi pi-shopping-cart', NULL, 4, 1000, 1),
(37, 36, 'REGISTRO DE PROVEEDORES', 'pi pi-truck', '/compras/proveedores', 1, 1000, 1),
(38, 36, 'ÓRDENES Y RECEPCIONES', 'pi pi-plus-circle', '/compras/ordenes', 2, 1000, 1),
(39, 36, 'PLANES DE PAGO Y CRÉDITOS', 'pi pi-calendar', '/compras/planes-pago', 3, 1000, 1),
(40, NULL, 'VENTAS Y FACTURACIÓN', 'pi pi-wallet', NULL, 5, 1000, 1),
(41, 40, 'PUNTO DE VENTA (POS)', 'pi pi-desktop', '/ventas/pos', 1, 1000, 1),
(42, 40, 'REGISTRO DE CLIENTES', 'pi pi-user-plus', '/ventas/clientes', 2, 1000, 1),
(43, 40, 'DOSIFICACIÓN Y FACTURAS (SIN)', 'pi pi-file-excel', '/ventas/control-facturas', 3, 1000, 1),
(44, 40, 'HISTÓRICO DE DOCUMENTOS', 'pi pi-folder-open', '/ventas/documentos-historicos', 4, 1000, 1),
(45, 36, 'GESTIÓN DE CRÉDITOS A PROVEEDORES', 'pi pi-money-bill', '/compras/pagos', 5, 1000, 1),
(46, 40, 'COMPROBANTES DIGITALES / QR', 'pi pi-qrcode', '/ventas/comprobantes', 6, 1000, 1),
(47, NULL, 'GESTIÓN DE CAJA', 'pi pi-percentage', NULL, 6, 1000, 1),
(48, 47, 'APERTURA Y CIERRE', 'pi pi-lock', '/caja/sesiones', 1, 1000, 1),
(49, 47, 'MOVIMIENTOS DE CAJA (VARIOS)', 'pi pi-sort', '/caja/movimientos', 2, 1000, 1),
(50, NULL, 'NÚCLEO ANALÍTICO Y PREDICCIONES', 'pi pi-android', NULL, 7, 1000, 1),
(51, 50, 'DASHBOARD DE ANALÍTICA CONSOLIDADA', 'pi pi-chart-bar', '/ia/analitica', 1, 1000, 1),
(52, 50, 'MODELOS ML DISPONIBLES', 'pi pi-share-alt', '/ia/modelos', 2, 1000, 1),
(53, 50, 'HISTORIAL DE ENTRENAMIENTOS', 'pi pi-sync', '/ia/entrenamientos', 3, 1000, 1),
(54, 50, 'MÉTRICAS DE RENDIMIENTO', 'pi pi-chart-line', '/ia/metricas', 4, 1000, 1),
(55, 50, 'VARIABLES EXÓGENAS AMBIENTALES', 'pi pi-cloud', '/ia/variables-exogenas', 5, 1000, 1),
(56, 50, 'PATRONES DE CONSUMO ESTACIONAL', 'pi pi-sliders-v', '/ia/patrones-consumo', 6, 1000, 1),
(57, 50, 'CONFIGURACIÓN DE UMBRALES PREDICTIVOS', 'pi pi-cog', '/ia/umbrales', 7, 1000, 1),
(58, NULL, 'NOTIFICACIONES Y ALERTAS', 'pi pi-bell', NULL, 8, 1000, 1),
(59, 58, 'BANDEJA DE NOTIFICACIONES', 'pi pi-inbox', '/alertas/notificaciones', 1, 1000, 1),
(60, 58, 'ALERTAS OPERATIVAS Y CRÍTICAS', 'pi pi-exclamation-triangle', '/alertas/criticas', 2, 1000, 1),
(61, NULL, 'REPORTES Y DIRECCIÓN GERENCIAL', 'pi pi-print', NULL, 9, 1000, 1),
(62, 61, 'CONSOLIDADOR DE REPORTES', 'pi pi-copy', '/reportes/dashboard-unico', 1, 1000, 1),
(63, 61, 'REPORTES DE INVENTARIO Y STOCK', 'pi pi-chart-scatter', '/reportes/inventario', 2, 1000, 1),
(64, 61, 'PANEL DE CONTROL FINANCIERO', 'pi pi-percentage', '/gerencia/reportes-financieros', 3, 1000, 1),
(65, 61, 'HISTORIAL DE COSTOS Y MÁRGENES', 'pi pi-chart-line', '/gerencia/historial-costos', 4, 1000, 1),
(66, 61, 'MONITOR DE ALERTAS DE RIESGO', 'pi pi-bolt', '/gerencia/alertas-criticas', 5, 1000, 1);

UPDATE menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('menus_menu_id_seq', COALESCE((SELECT MAX(menu_id) FROM menus), 1));

-- ================================================================================================

CREATE TABLE roles_menus (
    rol_menu_id BIGSERIAL PRIMARY KEY,
    rol_id BIGINT NOT NULL DEFAULT 1,
    menu_id BIGINT NOT NULL DEFAULT 1,
    crear INTEGER NOT NULL DEFAULT 0,
    editar INTEGER NOT NULL DEFAULT 0,
    eliminar INTEGER NOT NULL DEFAULT 0,
    archivar INTEGER NOT NULL DEFAULT 0,
    desarchivar INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_rm_rol_id FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT fk_rm_menu_id FOREIGN KEY (menu_id) REFERENCES menus(menu_id),
    CONSTRAINT fk_rm_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
	CONSTRAINT chk_rm_crear CHECK (crear IN (0, 1)),
    CONSTRAINT chk_rm_editar CHECK (editar IN (0, 1)),
    CONSTRAINT chk_rm_eliminar CHECK (eliminar IN (0, 1)),
    CONSTRAINT chk_rm_archivar CHECK (archivar IN (0, 1)),
    CONSTRAINT chk_rm_desarchivar CHECK (desarchivar IN (0, 1))
);
CREATE UNIQUE INDEX uix_rm_rol_menu_vigente ON roles_menus (rol_id, menu_id) WHERE estado_id = 1000;
CREATE INDEX idx_rm_busqueda_auth ON roles_menus (rol_id, estado_id) INCLUDE (menu_id, crear, editar, eliminar);

COMMENT ON TABLE roles_menus IS 'Reglas de la tabla - roles_menus
R.0: La tabla roles_menus actúa como el puente entre los perfiles de usuario y las funcionalidades del sistema, implementando un control de acceso granular. Su propósito es definir y persistir los permisos específicos (Crear, Editar, Eliminar, Archivar, Desarchivar) que un rol tiene sobre cada uno de los menús del sistema. Esta tabla es la base para la autorización de rutas (middleware) y la habilitación/deshabilitación de botones y acciones en la interfaz de usuario. Se conecta directamente con las tablas roles y menus.
R.1: Autorización en Frontera de Rutas (Middleware): El frontend (Nuxt Middleware) interceptará cada cambio de página consultando esta colección. Si para el rol_id del usuario autenticado el menu_id asociado no cuenta con registro activo, se denegará el acceso redirigiendo inmediatamente a una vista de error HTTP 403.
R.2: Restricciones de UI a Nivel de Componente: Los permisos atómicos (crear, editar, eliminar, archivar, desarchivar) mapean directamente el estado reactivo de la interfaz. Si un atributo posee el valor 0, los componentes PrimeVue asociados (ej. <Button>) deben deshabilitarse (:disabled="true") o remover su renderizado mediante directivas estricta de control visual (v-if).
R.3: Tratamiento del Registro de Control: El registro con rol_menu_id = 1 enlaza el rol por defecto con el menú comodín bajo estado HISTORICO. Este par opera como un bypass seguro de contingencia en capas internas del backend y no es gestionable desde pantallas de asignación de privilegios.
R.4: Persistencia Coherente de Permisos: Al remover u ocultar un acceso en la tabla padre menus, el backend no purga físicamente esta tabla de quiebre. En su lugar, de manera asíncrona, modificará el campo estado a BORRADO en todos los registros relacionados para mantener intactas las trazas de auditoría de seguridad del sistema.';

DELETE FROM roles_menus;
ALTER SEQUENCE roles_menus_rol_menu_id_seq RESTART WITH 1;

INSERT INTO roles_menus (rol_menu_id, rol_id, menu_id, crear, editar, eliminar, archivar, desarchivar, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, 0, 0, 0, 0, 1000, 1),

-- 2. ROL ADMINISTRADOR (ID: 2) - Acceso total a todos los menús del 1 al 66
(2, 2, 1, 1, 1, 1, 1, 1, 1000, 1),
(3, 2, 2, 1, 1, 1, 1, 1, 1000, 1),
(4, 2, 3, 1, 1, 1, 1, 1, 1000, 1),
(5, 2, 4, 1, 1, 1, 1, 1, 1000, 1),
(6, 2, 5, 1, 1, 1, 1, 1, 1000, 1),
(7, 2, 6, 1, 1, 1, 1, 1, 1000, 1),
(8, 2, 7, 1, 1, 1, 1, 1, 1000, 1),
(9, 2, 8, 1, 1, 1, 1, 1, 1000, 1),
(10, 2, 9, 1, 1, 1, 1, 1, 1000, 1),
(11, 2, 10, 1, 1, 1, 1, 1, 1000, 1),
(12, 2, 11, 1, 1, 1, 1, 1, 1000, 1),
(13, 2, 12, 1, 1, 1, 1, 1, 1000, 1),
(14, 2, 13, 1, 1, 1, 1, 1, 1000, 1),
(15, 2, 14, 1, 1, 1, 1, 1, 1000, 1),
(16, 2, 15, 1, 1, 1, 1, 1, 1000, 1),
(17, 2, 16, 1, 1, 1, 1, 1, 1000, 1),
(18, 2, 17, 1, 1, 1, 1, 1, 1000, 1),
(19, 2, 18, 1, 1, 1, 1, 1, 1000, 1),
(20, 2, 19, 1, 1, 1, 1, 1, 1000, 1),
(21, 2, 20, 1, 1, 1, 1, 1, 1000, 1),
(22, 2, 21, 1, 1, 1, 1, 1, 1000, 1),
(23, 2, 22, 1, 1, 1, 1, 1, 1000, 1),
(24, 2, 23, 1, 1, 1, 1, 1, 1000, 1),
(25, 2, 24, 1, 1, 1, 1, 1, 1000, 1),
(26, 2, 25, 1, 1, 1, 1, 1, 1000, 1),
(27, 2, 26, 1, 1, 1, 1, 1, 1000, 1),
(28, 2, 27, 1, 1, 1, 1, 1, 1000, 1),
(29, 2, 28, 1, 1, 1, 1, 1, 1000, 1),
(30, 2, 29, 1, 1, 1, 1, 1, 1000, 1),
(31, 2, 30, 1, 1, 1, 1, 1, 1000, 1),
(32, 2, 31, 1, 1, 1, 1, 1, 1000, 1),
(33, 2, 32, 1, 1, 1, 1, 1, 1000, 1),
(34, 2, 33, 1, 1, 1, 1, 1, 1000, 1),
(35, 2, 34, 1, 1, 1, 1, 1, 1000, 1),
(36, 2, 35, 1, 1, 1, 1, 1, 1000, 1),
(37, 2, 36, 1, 1, 1, 1, 1, 1000, 1),
(38, 2, 37, 1, 1, 1, 1, 1, 1000, 1),
(39, 2, 38, 1, 1, 1, 1, 1, 1000, 1),
(40, 2, 39, 1, 1, 1, 1, 1, 1000, 1),
(41, 2, 40, 1, 1, 1, 1, 1, 1000, 1),
(42, 2, 41, 1, 1, 1, 1, 1, 1000, 1),
(43, 2, 42, 1, 1, 1, 1, 1, 1000, 1),
(44, 2, 43, 1, 1, 1, 1, 1, 1000, 1),
(45, 2, 44, 1, 1, 1, 1, 1, 1000, 1),
(46, 2, 45, 1, 1, 1, 1, 1, 1000, 1),
(47, 2, 46, 1, 1, 1, 1, 1, 1000, 1),
(48, 2, 47, 1, 1, 1, 1, 1, 1000, 1),
(49, 2, 48, 1, 1, 1, 1, 1, 1000, 1),
(50, 2, 49, 1, 1, 1, 1, 1, 1000, 1),
(51, 2, 50, 1, 1, 1, 1, 1, 1000, 1),
(52, 2, 51, 1, 1, 1, 1, 1, 1000, 1),
(53, 2, 52, 1, 1, 1, 1, 1, 1000, 1),
(54, 2, 53, 1, 1, 1, 1, 1, 1000, 1),
(55, 2, 54, 1, 1, 1, 1, 1, 1000, 1),
(56, 2, 55, 1, 1, 1, 1, 1, 1000, 1),
(57, 2, 56, 1, 1, 1, 1, 1, 1000, 1),
(58, 2, 57, 1, 1, 1, 1, 1, 1000, 1),
(59, 2, 58, 1, 1, 1, 1, 1, 1000, 1),
(60, 2, 59, 1, 1, 1, 1, 1, 1000, 1),
(61, 2, 60, 1, 1, 1, 1, 1, 1000, 1),
(62, 2, 61, 1, 1, 1, 1, 1, 1000, 1),
(63, 2, 62, 1, 1, 1, 1, 1, 1000, 1),
(64, 2, 63, 1, 1, 1, 1, 1, 1000, 1),
(65, 2, 64, 1, 1, 1, 1, 1, 1000, 1),
(66, 2, 65, 1, 1, 1, 1, 1, 1000, 1),
(67, 2, 66, 1, 1, 1, 1, 1, 1000, 1),

-- 3. ROL GERENTE (ID: 3) - Ejemplo de acceso de lectura a reportes y analítica (Menús 50 a 66)
(68, 3, 50, 0, 0, 0, 0, 0, 1000, 1),
(69, 3, 51, 0, 0, 0, 0, 0, 1000, 1),
(70, 3, 61, 0, 0, 0, 0, 0, 1000, 1),
(71, 3, 62, 0, 0, 0, 0, 0, 1000, 1),
(72, 3, 63, 0, 0, 0, 0, 0, 1000, 1),
(73, 3, 64, 0, 0, 0, 0, 0, 1000, 1),
(74, 3, 65, 0, 0, 0, 0, 0, 1000, 1),
(75, 3, 66, 0, 0, 0, 0, 0, 1000, 1),

-- 4. ROL VENDEDOR (ID: 6) - Acceso al módulo de Ventas y POS (Menús 40 al 46)
(76, 6, 40, 1, 1, 0, 0, 0, 1000, 1),
(77, 6, 41, 1, 1, 0, 0, 0, 1000, 1),
(78, 6, 42, 1, 1, 0, 0, 0, 1000, 1),
(79, 6, 44, 1, 0, 0, 0, 0, 1000, 1),
(80, 6, 46, 1, 0, 0, 0, 0, 1000, 1);

UPDATE roles_menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles_menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_menus_rol_menu_id_seq', COALESCE((SELECT MAX(rol_menu_id) FROM roles_menus), 1));

-- ================================================================================================

CREATE TABLE inventarios_fisicos (
    inventario_fisico_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL,
    ubicacion_id BIGINT NULL,
    fecha_conteo DATE NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NULL,
    usuario_registro_id BIGINT NOT NULL,
    usuario_supervisor_id BIGINT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,  -- 1000=ABIERTO, 1002=CERRADO, 1001=CANCELADO
    observaciones VARCHAR(1000) NULL,
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_if_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_if_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_if_usuario_registro_id FOREIGN KEY (usuario_registro_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_if_usuario_supervisor_id FOREIGN KEY (usuario_supervisor_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_if_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_if_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
CREATE INDEX idx_if_sucursal_ubicacion ON inventarios_fisicos (sucursal_id, ubicacion_id) WHERE estado_id = 1000;

COMMENT ON TABLE inventarios_fisicos IS 'Reglas de la tabla - inventarios_fisicos
R.0: La tabla inventarios_fisicos gestiona las cabeceras de los procesos de conteo físico, conciliaciones de inventario y auditorías de stock dentro de una sucursal o ubicación específica.
R.1: Alcance del Conteo. Si ubicacion_id es NULL, el inventario físico representa un conteo general que abarca toda la sucursal.
R.2: Control de Fechas y Estados. El estado_id maneja el ciclo de vida del proceso (1000=ABIERTO, 1002=CERRADO, 1001=CANCELADO), validando mediante restricciones que la fecha de finalización sea coherente con la fecha de inicio.';

DELETE FROM inventarios_fisicos;
ALTER SEQUENCE inventarios_fisicos_inventario_fisico_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos (inventario_fisico_id, sucursal_id, ubicacion_id, fecha_conteo, fecha_inicio, fecha_fin, usuario_registro_id, usuario_supervisor_id, estado_id, observaciones, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, 1, NULL, 1000, 'REGISTRO INICIAL COMODIN DE INVENTARIO FISICO', 1);

UPDATE inventarios_fisicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE inventarios_fisicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('inventarios_fisicos_inventario_fisico_id_seq', COALESCE((SELECT MAX(inventario_fisico_id) FROM inventarios_fisicos), 1));

-- ================================================================================================

CREATE TABLE clientes (
    cliente_id BIGSERIAL PRIMARY KEY,
    tipo_cliente_id INTEGER NOT NULL DEFAULT 1150,     -- 1150=NATURAL, 1151=JURIDICA
    cliente VARCHAR(100) NOT NULL,
    nit VARCHAR(20) NULL,
	razon_social VARCHAR(150) NULL,
    documento VARCHAR(30) NOT NULL,
    documento_complemento VARCHAR(10) NULL,
    tipo_documento_id INTEGER NOT NULL DEFAULT 2200,   -- 2200=CEDULA_IDENTIDAD, 2201=CEDULA_IDENTIDAD_EXTRANJERO, 2202=PASAPORTE, 2203=OTRO, 2204=NIT
    direccion VARCHAR(255) NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    banco_id BIGINT NOT NULL DEFAULT 1,
    numero_cuenta VARCHAR(50) NULL,
    habilitado_ventas INTEGER NOT NULL DEFAULT 1,
    limite_credito DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cli_tipo_cliente_id FOREIGN KEY (tipo_cliente_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cli_tipo_documento_id FOREIGN KEY (tipo_documento_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cli_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
    CONSTRAINT fk_cli_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cli_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
	CONSTRAINT chk_cli_cliente_min_longitud CHECK (LENGTH(TRIM(cliente)) >= 3),
    CONSTRAINT chk_cli_documento_min_longitud CHECK (LENGTH(TRIM(documento)) >= 1),
    CONSTRAINT chk_cli_habilitado_ventas CHECK (habilitado_ventas IN (0, 1)),
    CONSTRAINT chk_cli_limite_credito_positivo CHECK (limite_credito >= 0.00),
    CONSTRAINT chk_cli_coherencia_credito CHECK (
        (limite_credito = 0.00) OR
        (limite_credito > 0.00 AND habilitado_ventas = 1)
    )
);
CREATE UNIQUE INDEX uix_cli_documento_vigente_null ON clientes (tipo_documento_id, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NULL;
CREATE UNIQUE INDEX uix_cli_documento_vigente_not_null ON clientes (tipo_documento_id, documento_complemento, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NOT NULL;
CREATE INDEX idx_clientes_busqueda ON clientes (documento, cliente) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE clientes IS 'Reglas de la tabla - clientes
R.0: La tabla clientes almacena el registro maestro de los compradores, ya sean trabajadores naturales o jurídicas, y es una entidad crítica para los procesos de venta y facturación. Su propósito es proporcionar los datos fiscales y de contacto necesarios para la emisión de comprobantes electrónicos, la aplicación de descuentos por volumen y el análisis de comportamiento de compra para los módulos de inteligencia de negocio. Se conecta directamente con las tablas kardex y historicos para vincular las transacciones a un comprador específico.
R.1: Tratamiento del Documento Genérico: El registro con cliente_id = 1 y documento ''0'' actúa como el cliente comodín universal (exclusivo para ventas de mostrador sin nominación de factura o "Sin Nombre"). Este registro está exento de las restricciones del índice de unicidad parcial para permitir operaciones de venta directa rápidas y masivas.
R.2: Control de Complemento de Identidad: El campo documento_complemento es mandatorio en la arquitectura de persistencia para clientes de tipo Cédula de Identidad (CI) que compartan la misma numeración base pero posean sufijos alfanuméricos de desambiguación emitidos por el ente de identificación estatal (ej. ''1A'', ''1B''). El frontend debe inicializar este campo como un string vacío '' por defecto para evitar colisiones involuntarias de nulidad.
R.3: Desacoplamiento de Entidad Bancaria para Clientes Corporativos/Aseguradoras: Los campos banco_id (apuntando por defecto a 1 - ''NINGUNO'') y numero_cuenta son obligatorios únicamente cuando se gestionan clientes de tipo institucional, convenios corporativos o aseguradoras de salud. Permiten registrar de forma nativa el canal de origen para transferencias interbancarias automáticas cuando se liquidan cuentas por cobrar o proformas consolidadas a fin de mes.
R.4: Validación de Contacto Digital (Email) para Factura en Línea: Aunque el campo email es estructuralmente opcional (NULL) para no bloquear la venta rápida en caja, el sistema de facturación electrónica del SIN exige el envío del XML/PDF al cliente. El backend deben exigir un correo electrónico válido si el cliente opta por la facturación en línea bajo la modalidad Nominada, sirviendo como canal único de notificación para la entrega del documento fiscal digitalizado.
R.5: Control de Habilitación Comercial (habilitado_ventas): El campo habilitado_ventas determina si el cliente puede realizar transacciones comerciales activas en el sistema. Los valores permitidos son estrictamente 0 (NO) y 1 (SI). Si un cliente posee el valor 0, cualquier intento de procesar una nueva venta o emisión de proforma hacia este debe ser bloqueado por la lógica de negocio y restricciones operativas.
R.6: Autorización y Límite de Crédito (limite_credito): El campo limite_credito define el monto máximo monetario acumulado que se le permite adeudar al cliente en operaciones a crédito. Para que a un cliente se le pueda asignar un límite de crédito mayor a 0.00, obligatoriamente su campo habilitado_ventas debe estar configurado en 1 (SI) y el sistema debe validar que no posea bloqueos administrativos vigentes. Un límite de 0.00 indica que opera estrictamente al contado.';

DELETE FROM clientes;
ALTER SEQUENCE clientes_cliente_id_seq RESTART WITH 1;

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(1, 1150, 'NINGUNO', NULL, NULL, '0', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 1),
(2, 1150, 'FRANZ IBAÑEZ', NULL, NULL, '2630198', NULL, 2200, 'Av. Arce No. 123', '71234567', 'franz@email.com', 2, '1000001234', 1, 1000.00, 1000, 1),
(3, 1151, 'JUAN PEREZ', '1020304025', 'DROGUERIA INTI S.A.', '1020304025', NULL, 2204, 'Zona Industrial El Alto', '22841414', 'contacto@inti.com.bo', 3, '4010005678', 1, 5000.00, 1000, 1);

UPDATE clientes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE clientes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('clientes_cliente_id_seq', COALESCE((SELECT MAX(cliente_id) FROM clientes), 1));

-- ================================================================================================

CREATE TABLE categorias (
    categoria_id BIGSERIAL PRIMARY KEY,
    categoria_padre_id BIGINT NULL,
    categoria VARCHAR(100) NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    descripcion VARCHAR(500) NULL,
    nivel INTEGER NOT NULL DEFAULT 1,
    orden INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cat_categoria_padre_id FOREIGN KEY (categoria_padre_id) REFERENCES categorias(categoria_id),
	CONSTRAINT fk_cat_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cat_categoria_not_empty CHECK (TRIM(categoria) <> ''),
    CONSTRAINT chk_cat_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_cat_codigo_length CHECK (LENGTH(TRIM(codigo)) = 3),
    CONSTRAINT chk_cat_codigo_format CHECK (codigo ~ '^[A-Z0-9-]+$')
);
CREATE UNIQUE INDEX uix_cat_padre_nombre ON categorias (categoria_padre_id, categoria) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_cat_codigo_activo ON categorias (codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE categorias IS 'Reglas de la tabla - categorias
R.0: La tabla categorias implementa una taxonomía jerárquica para clasificar los productos, agrupándolos lógicamente para su organización en el catálogo. Su propósito es facilitar la navegación, búsqueda y filtrado de productos en la interfaz de usuario, así como servir como criterio de segmentación para reportes de ventas, inventario y la aplicación de promociones. Se conecta de forma autorreferencial y con la tabla productos.
R.1: El campo codigo debe ser de exactamente 3 caracteres alfanuméricos, sin espacios, y debe almacenarse en mayúsculas pero puede tener guiones (-).
R.2: El registro con categoria_id = 1 con categoria = ''NINGUNA'' y codigo = ''NIN'' es el registro predeterminado, se mantiene en estado HISTORICO y no puede modificarse ni eliminarse.';

DELETE FROM categorias;
ALTER SEQUENCE categorias_categoria_id_seq RESTART WITH 1;

INSERT INTO categorias (categoria_id, categoria_padre_id, categoria, codigo, descripcion, nivel, orden, estado_id, usuario_id_registro) VALUES
(1, NULL, 'NINGUNA', 'NIN', 'Categoría predeterminada para productos sin clasificar', 1, 0, 1000, 1);

UPDATE categorias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE categorias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('categorias_categoria_id_seq', COALESCE((SELECT MAX(categoria_id) FROM categorias), 1));

-- ================================================================================================

CREATE TABLE unidades (
    unidad_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    codigo_sin INTEGER NOT NULL,
    unidad VARCHAR(100) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_uni_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_uni_unidad_not_empty CHECK (TRIM(unidad) <> ''),
    CONSTRAINT chk_uni_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_uni_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 1),
    CONSTRAINT chk_uni_codigo_mayusculas CHECK (codigo = UPPER(codigo))
);
CREATE UNIQUE INDEX uix_uni_codigo ON unidades (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_uni_unidad ON unidades (unidad) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE unidades IS 'Reglas de la tabla - unidades
R.0: La tabla unidades define el catálogo de unidades de medida (físicas y fiscales) utilizadas en el sistema, sirviendo como base para todas las operaciones que involucran cantidades. Su propósito es estandarizar la gestión de inventario, las compras y las ventas, proporcionando una referencia inequívoca (con código numérico para el SIN) para medir productos, y permitir conversiones de unidades a través de la tabla conversiones_unidad. Se conecta directamente con las tablas presentaciones, concentraciones, productos y conversiones_unidad.
R.1: El campo codigo_sin almacena los identificadores numéricos estandarizados correspondientes a la codificación oficial de unidades del Servicio de Impuestos Nacionales (SIN), requeridos para procesos de facturación electrónica.
R.2: El registro predeterminado (unidad_id = 1, ''NINGUNA'') opera como un comodín del sistema para omitir la validación de magnitudes físicas específicas en la gestión de servicios o productos intangibles.';

DELETE FROM unidades;
ALTER SEQUENCE unidades_unidad_id_seq RESTART WITH 1;

INSERT INTO unidades (unidad_id, codigo, codigo_sin, unidad, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 0, 'NINGUNA', 1000, 1),
(2, 'KG', 1, 'KILOGRAMO', 1000, 1),
(3, 'G', 2, 'GRAMO', 1000, 1),
(4, 'T', 3, 'TONELADA', 1000, 1),
(5, 'L', 4, 'LITRO', 1000, 1),
(6, 'ML', 5, 'MILILITRO', 1000, 1),
(7, 'M', 6, 'METRO', 1000, 1),
(8, 'CM', 7, 'CENTÍMETRO', 1000, 1),
(9, 'U', 58, 'UNIDAD', 1000, 1),
(10, 'PZ', 58, 'PIEZA', 1000, 1),
(11, 'CJ', 58, 'CAJA', 1000, 1),
(12, 'PQ', 58, 'PAQUETE', 1000, 1);

UPDATE unidades SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE unidades SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('unidades_unidad_id_seq', COALESCE((SELECT MAX(unidad_id) FROM unidades), 1));

-- ================================================================================================

CREATE TABLE laboratorios (
    laboratorio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    laboratorio VARCHAR(200) NOT NULL,
    nit VARCHAR(30) NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(50) NULL,
    email VARCHAR(100) NULL,
    web VARCHAR(200) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_lab_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
	CONSTRAINT chk_lab_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_lab_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_lab_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_lab_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_lab_laboratorio_not_empty CHECK (TRIM(laboratorio) <> '')
);
CREATE UNIQUE INDEX uix_lab_codigo ON laboratorios (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_lab_laboratorio ON laboratorios (laboratorio) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_lab_nit ON laboratorios (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND nit <> '';

COMMENT ON TABLE laboratorios IS 'Reglas de la tabla - laboratorios
R.0: La tabla laboratorios constituye el catálogo de fabricantes, proveedores o marcas de los productos farmacéuticos y de venta libre. Su función es gestionar la trazabilidad desde el origen del producto, facilitando la organización del catálogo, la aplicación de promociones por marca y la generación de reportes de compras y rentabilidad por laboratorio. Se conecta directamente con la tabla productos.
R.1: El registro predeterminado (laboratorio_id = 1, ''NINGUNO'') actúa como la entidad genérica del sistema para la creación obligatoria de productos magistrales, fórmulas propias o artículos de soporte que no correspondan a un fabricante farmacéutico comercial.';

DELETE FROM laboratorios;
ALTER SEQUENCE laboratorios_laboratorio_id_seq RESTART WITH 1;

INSERT INTO laboratorios (laboratorio_id, codigo, laboratorio, nit, direccion, telefono, email, web, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, NULL, NULL, NULL, 1000, 1);

UPDATE laboratorios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE laboratorios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('laboratorios_laboratorio_id_seq', COALESCE((SELECT MAX(laboratorio_id) FROM laboratorios), 1));

-- ================================================================================================

CREATE TABLE formas (
    forma_id BIGSERIAL PRIMARY KEY,
    forma_farmaceutica VARCHAR(100) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_f_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_f_forma_farmaceutica_not_empty CHECK (TRIM(forma_farmaceutica) <> ''),
    CONSTRAINT chk_f_forma_farmaceutica_min_length CHECK (LENGTH(TRIM(forma_farmaceutica)) >= 3),
    CONSTRAINT chk_f_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_f_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_f_codigo_mayusculas CHECK (codigo = UPPER(codigo))
);
CREATE UNIQUE INDEX uix_f_codigo ON formas (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_f_forma ON formas (forma_farmaceutica) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE formas IS 'Reglas de la tabla - formas
R.0: La tabla formas define las formas farmacéuticas de los productos (ej. tableta, jarabe, inyectable), describiendo la presentación física del medicamento. Su propósito es clasificar los productos para su correcta identificación, gestión y dispensación, así como para servir como un filtro de búsqueda avanzada y control de inventario. Se conecta directamente con la tabla productos.
R.1: El campo codigo debe ser validado por el Frontend para admitir únicamente caracteres alfanuméricos (A-Z, 0-9), restringiendo caracteres especiales, tildes o la letra "Ñ".
R.2: Al registrar una nueva forma farmacéutica, el Frontend debe convertir automáticamente la entrada a mayúsculas fijas (UPPERCASE) antes de realizar el envío al servicio API de la aplicación.
R.3: El campo descripcion se expone en la interfaz como un cuadro de texto multilínea opcional para documentar observaciones de almacenamiento o manipulación de la forma física, limitando su longitud a 500 caracteres.';

DELETE FROM formas;
ALTER SEQUENCE formas_forma_id_seq RESTART WITH 1;

INSERT INTO formas (forma_id, forma_farmaceutica, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', 'Forma farmacéutica predeterminada para productos sin clasificar', 1000, 1);

UPDATE formas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE formas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('formas_forma_id_seq', COALESCE((SELECT MAX(forma_id) FROM formas), 1));

-- ================================================================================================

CREATE TABLE presentaciones (
    presentacion_id BIGSERIAL PRIMARY KEY,
    unidad_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(10) NOT NULL,
    presentacion VARCHAR(200) NOT NULL,
    cantidad_unidades INTEGER NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pre_unidad_id FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
	CONSTRAINT fk_pre_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pre_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_pre_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_pre_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_pre_presentacion_not_empty CHECK (TRIM(presentacion) <> ''),
    CONSTRAINT chk_pre_presentacion_min_length CHECK (LENGTH(TRIM(presentacion)) >= 3),
    CONSTRAINT chk_pre_cantidad_unidades CHECK (cantidad_unidades > 0)
);
CREATE UNIQUE INDEX uix_pre_codigo ON presentaciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_pre_presentacion ON presentaciones (presentacion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE presentaciones IS 'Reglas de la tabla - presentaciones
R.0: La tabla presentaciones gestiona la forma comercial de venta de un producto, como una caja con 10 tabletas o un frasco de 100 ml. Su propósito es estandarizar cómo se comercializa y se mide el inventario del producto, definiendo la relación entre la unidad de venta y la unidad de base (unidad de medida). Es un vínculo fundamental para calcular el costo de venta y la gestión de precios, conectándose directamente con las tablas productos y kardex_productos.
R.1: El código de presentación no puede contener espacios y debe ser validado desde el cliente UI para mantener el patrón de la letra ''X'' seguida del número de unidades equivalentes.';

DELETE FROM presentaciones;
ALTER SEQUENCE presentaciones_presentacion_id_seq RESTART WITH 1;

INSERT INTO presentaciones (presentacion_id, unidad_id, codigo, presentacion, cantidad_unidades, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 1, 'Presentación predeterminada para productos sin clasificar', 1000, 1);

UPDATE presentaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE presentaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('presentaciones_presentacion_id_seq', COALESCE((SELECT MAX(presentacion_id) FROM presentaciones), 1));

-- ================================================================================================

CREATE TABLE concentraciones (
    concentracion_id BIGSERIAL PRIMARY KEY,
    unidad_base_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(20) NOT NULL,
    concentracion VARCHAR(100) NOT NULL,
    valor_numerico DECIMAL(12,2) NULL,
    descripcion VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_con_unidad_base_id FOREIGN KEY (unidad_base_id) REFERENCES unidades(unidad_id),
	CONSTRAINT fk_con_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_con_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_con_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_con_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_con_concentracion_not_empty CHECK (TRIM(concentracion) <> ''),
    CONSTRAINT chk_con_concentracion_min_length CHECK (LENGTH(TRIM(concentracion)) >= 2),
    CONSTRAINT chk_con_valor_numerico CHECK (valor_numerico >= 0)
);
CREATE UNIQUE INDEX uix_con_codigo ON concentraciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_con_concentracion ON concentraciones (concentracion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE concentraciones IS 'Reglas de la tabla - concentraciones
R.0: La tabla concentraciones define la potencia de los principios activos en un producto (ej. 500mg, 100mg/ml), describiendo la cantidad de fármaco por unidad de medida. Su propósito es identificar y diferenciar productos similares para evitar confusiones médicas y garantizar la precisión en la dispensación, siendo un atributo esencial en el catálogo de productos. Se conecta directamente con la tabla productos.
R.1: El código de la concentración no debe incluir espacios en blanco y el cliente UI debe validar obligatoriamente que concatene el valor numérico entero o decimal con la abreviatura de la unidad de medida en mayúsculas (ej. ''500MG'', ''0.5MG'').
R.2: Cuando el usuario seleccione la opción predeterminada con concentracion_id = 1 (''NINGUNA'') en el formulario de productos, el sistema en el cliente debe deshabilitar y limpiar automáticamente el campo correspondiente al valor numérico para consistencia de los datos.
R.3: Las modificaciones sobre las concentraciones activas recalculan dinámicamente las etiquetas descriptivas en la interfaz de usuario, pero el backend impedirá cualquier alteración física o lógica sobre el id 1 debido a su condición estricta de constante de control.';

DELETE FROM concentraciones;
ALTER SEQUENCE concentraciones_concentracion_id_seq RESTART WITH 1;

INSERT INTO concentraciones (concentracion_id, unidad_base_id, codigo, concentracion, valor_numerico, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 0.00, 'Concentración predeterminada para productos sin clasificar', 1000, 1);

UPDATE concentraciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE concentraciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('concentraciones_concentracion_id_seq', COALESCE((SELECT MAX(concentracion_id) FROM concentraciones), 1));

-- ================================================================================================

CREATE TABLE vias (
    via_id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(3000) NULL,
    requiere_ayuno INTEGER NOT NULL DEFAULT 0,
    tiempo_efecto_minutos INTEGER NULL,
    precauciones VARCHAR(3000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_via_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_via_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_via_requiere_ayuno CHECK (requiere_ayuno IN (0, 1)),
	CONSTRAINT chk_via_tiempo_efecto CHECK (tiempo_efecto_minutos IS NULL OR tiempo_efecto_minutos > 0)
);
CREATE UNIQUE INDEX uix_via_nombre ON vias (nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE vias IS 'Reglas de la tabla - vias
R.0: La tabla vias establece las diferentes vías de administración de los medicamentos, como oral o tópica, y es crítica para la seguridad del paciente. Su propósito es almacenar información adicional sobre la administración (ayuno, tiempo de efecto) y asociarla a los productos, permitiendo al farmacéutico ofrecer la información correcta y contraindicaciones relevantes. Se conecta a través de productos_vias con la tabla productos.
R.1: requiere_ayuno: 0=No requiere ayuno, 1=Requiere ayuno.
R.2: tiempo_efecto_minutos indica el tiempo estimado en minutos para que el medicamento haga efecto.
R.3: NINGUNO (via_id = 1) es un registro comodín para uso en otros módulos.';

DELETE FROM vias;
ALTER SEQUENCE vias_via_id_seq RESTART WITH 1;

INSERT INTO vias (via_id, nombre, descripcion, requiere_ayuno, tiempo_efecto_minutos, precauciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'Vía de administración predeterminada', 0, NULL, NULL, 1000, 1),
(2, 'ORAL', 'Administración por vía oral (tragado)', 0, 30, 'Tomar con suficiente agua', 1000, 1),
(3, 'TÓPICA', 'Aplicación sobre la piel o mucosas', 0, NULL, 'Evitar contacto con ojos y mucosas', 1000, 1),
(4, 'INHALADA', 'Administración por inhalación', 0, 5, 'Mantener el inhalador limpio', 1000, 1),
(5, 'PARENTERAL', 'Administración por vía inyectable', 1, 15, 'Solo personal capacitado', 1000, 1),
(6, 'RECTAL', 'Administración por vía rectal', 1, 30, NULL, 1000, 1),
(7, 'ÓTICA', 'Administración en el oído', 0, NULL, 'No usar si el tímpano está perforado', 1000, 1),
(8, 'OFTÁLMICA', 'Administración en el ojo', 0, NULL, 'Lavarse las manos antes y después', 1000, 1),
(9, 'NASAL', 'Administración por vía nasal', 0, 5, 'Limpiar la nariz antes de usar', 1000, 1),
(10, 'VAGINAL', 'Administración por vía vaginal', 0, 30, 'Usar aplicador si está incluido', 1000, 1),
(11, 'SUBLINGUAL', 'Administración bajo la lengua', 1, 5, 'No tragar, dejar disolver completamente', 1000, 1);

UPDATE vias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE vias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('vias_via_id_seq', COALESCE((SELECT MAX(via_id) FROM vias), 1));

-- ================================================================================================

CREATE TABLE rangos_edad (
    rango_edad_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL,
    rango VARCHAR(100) NOT NULL,
    edad_minima_meses INTEGER NULL,
    edad_maxima_meses INTEGER NULL,
    descripcion VARCHAR(3000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ran_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ran_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_ran_rango_not_empty CHECK (TRIM(rango) <> ''),
	CONSTRAINT chk_ran_limites_edad CHECK (edad_minima_meses IS NULL OR edad_maxima_meses IS NULL OR edad_maxima_meses >= edad_minima_meses)
);
CREATE UNIQUE INDEX uix_ran_codigo ON rangos_edad (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_ran_rango ON rangos_edad (rango) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE rangos_edad IS 'Reglas de la tabla - rangos_edad
R.0: La tabla rangos_edad define grupos etarios de pacientes (ej. lactante, adulto, geriátrico) para establecer la seguridad en la dispensación de medicamentos. Su propósito es clasificar a los pacientes y vincularlos con productos para gestionar contraindicaciones y dosificaciones recomendadas por edad, mejorando la calidad de la atención farmacéutica. Se conecta a través de productos_rangos_edad con la tabla productos.
R.1: La tabla rangos_edad clasifica los grupos etarios de pacientes para la dispensación de medicamentos, permitiendo asociar productos a rangos específicos para control de dosis y contraindicaciones.
R.2: edad_minima_meses y edad_maxima_meses definen el intervalo en meses del rango etario. Los valores son inclusivos (edad >= mínima y edad <= máxima). Si el valor es NULL, significa que el rango no tiene límite inferior o superior (ej. Adulto Mayor 780+ meses).
R.3: El registro con rango_edad_id = 1 (''NINGUNO'') actúa como el registro predeterminado para productos que no tienen un rango etario específico.
R.4: Los códigos (``codigo``) y nombres (``rango``) deben ser únicos para registros activos o históricos, garantizando que no existan duplicados semánticos en el catálogo.
R.5: El frontend debe utilizar esta tabla para filtrar y mostrar únicamente los medicamentos o productos que son seguros para la edad del paciente, ocultando aquellos cuyo rango etario no coincida.
R.6: Al asignar un producto a un rango etario, el sistema debe validar que el rango esté activo (estado_id = 1000) y que los límites de edad sean consistentes (edad_maxima_meses >= edad_minima_meses si ambos no son NULL).';

DELETE FROM rangos_edad;
ALTER SEQUENCE rangos_edad_rango_edad_id_seq RESTART WITH 1;

INSERT INTO rangos_edad (rango_edad_id, codigo, rango, edad_minima_meses, edad_maxima_meses, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'No especificado / General', NULL, NULL, 'Rango predeterminado o no aplicable', 1000, 1),
(2, 'REC', 'Recién Nacido', 0, 1, 'De 0 a 28 días de vida', 1000, 1),
(3, 'LAC', 'Lactante', 1, 12, 'De 1 mes a 1 año', 1000, 1),
(4, 'PRE', 'Preescolar', 12, 72, 'De 1 año a 5 años (60 meses)', 1000, 1),
(5, 'PED', 'Pediátrico (General)', 0, 144, 'Desde recién nacido hasta los 12 años', 1000, 1),
(6, 'ADO', 'Adolescente', 144, 216, 'De 12 a 18 años', 1000, 1),
(7, 'ADU', 'Adulto', 216, 780, 'De 18 a 65 años', 1000, 1),
(8, 'GER', 'Adulto Mayor / Geriátrico', 780, NULL, 'Mayores de 65 años', 1000, 1);

UPDATE rangos_edad SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE rangos_edad SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('rangos_edad_rango_edad_id_seq', COALESCE((SELECT MAX(rango_edad_id) FROM rangos_edad), 1));

-- ================================================================================================

CREATE TABLE productos (
    producto_id BIGSERIAL PRIMARY KEY,
    categoria_id BIGINT NOT NULL DEFAULT 1,
    laboratorio_id BIGINT NOT NULL DEFAULT 1,
    forma_id BIGINT NOT NULL DEFAULT 1,
    presentacion_id BIGINT NOT NULL DEFAULT 1,
    concentracion_id BIGINT NOT NULL DEFAULT 1,
    unidad_venta_id BIGINT NOT NULL DEFAULT 1,
	tipo_almacen_id INTEGER NOT NULL DEFAULT 1700,   	-- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(500) NOT NULL,
    nombre_generico VARCHAR(500) NULL,
    pcompra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    p_factor_venta DECIMAL(12,2) NOT NULL DEFAULT 1.50,
    p_factor_facturacion DECIMAL(12,2) NOT NULL DEFAULT 1.19,
    pventa DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    pventaf DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_minimo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_maximo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    punto_reorden DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    requiere_receta INTEGER NOT NULL DEFAULT 0,
    controlado INTEGER NOT NULL DEFAULT 0,
    tiene_registro_sanitario INTEGER NOT NULL DEFAULT 0,
    descripcion VARCHAR(3000) NULL,
	observacion VARCHAR(3000) NULL,
    foto1 VARCHAR(255) NULL,
    foto2 VARCHAR(255) NULL,
    foto3 VARCHAR(255) NULL,
	criticidad_medica_id INTEGER DEFAULT 4150,			-- 4150=NORMAL, 4151=CRITICO
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pro_categoria_id FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id),
    CONSTRAINT fk_pro_laboratorio_id FOREIGN KEY (laboratorio_id) REFERENCES laboratorios(laboratorio_id),
    CONSTRAINT fk_pro_forma_id FOREIGN KEY (forma_id) REFERENCES formas(forma_id),
    CONSTRAINT fk_pro_presentacion_id FOREIGN KEY (presentacion_id) REFERENCES presentaciones(presentacion_id),
    CONSTRAINT fk_pro_concentracion_id FOREIGN KEY (concentracion_id) REFERENCES concentraciones(concentracion_id),
    CONSTRAINT fk_pro_unidad_venta_id FOREIGN KEY (unidad_venta_id) REFERENCES unidades(unidad_id),
	CONSTRAINT fk_pro_criticidad_medica_id FOREIGN KEY (criticidad_medica_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_pro_tipo_almacen_id FOREIGN KEY (tipo_almacen_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_pro_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pro_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_pro_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 3),
	CONSTRAINT chk_pro_codigo_formato CHECK (codigo ~ '^[A-Za-z0-9_-]{3,30}$'),
    CONSTRAINT chk_pro_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_pro_nombre_min_length CHECK (LENGTH(TRIM(nombre)) >= 3),
	CONSTRAINT chk_pro_p_factor_venta CHECK (p_factor_venta > 1),
	CONSTRAINT chk_pro_p_factor_facturacion CHECK (p_factor_facturacion > 1),
    CONSTRAINT chk_pro_pcompra CHECK (pcompra >= 0),
    CONSTRAINT chk_pro_pventa CHECK (pventa >= 0),
    CONSTRAINT chk_pro_pventaf CHECK (pventaf >= 0),
	CONSTRAINT chk_pro_precios_flexible CHECK (
		(producto_id = 1 AND pcompra = 0 AND pventa = 0 AND pventaf = 0) OR
		(pcompra >= 0 AND pventa >= 0 AND pventaf >= 0)
	),
    CONSTRAINT chk_pro_stock_minimo CHECK (stock_minimo >= 0),
    CONSTRAINT chk_pro_stock_maximo CHECK (stock_maximo >= 0),
    CONSTRAINT chk_pro_stock_relacion CHECK (stock_maximo >= stock_minimo),
    CONSTRAINT chk_pro_punto_reorden CHECK (punto_reorden >= 0),
    CONSTRAINT chk_pro_requiere_receta CHECK (requiere_receta IN (0, 1)),
    CONSTRAINT chk_pro_controlado CHECK (controlado IN (0, 1)),
    CONSTRAINT chk_pro_tiene_registro_sanitario CHECK (tiene_registro_sanitario IN (0, 1))
);
CREATE UNIQUE INDEX uix_pro_codigo ON productos (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pro_nombre_trgm ON productos USING GIN (nombre gin_trgm_ops) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pro_nombre_generico_trgm ON productos USING GIN (nombre_generico gin_trgm_ops) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pro_categoria_laboratorio ON productos (categoria_id, laboratorio_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pro_tipo_almacen ON productos (tipo_almacen_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos IS 'Reglas de la tabla - productos
R.0: La tabla productos es el núcleo del catálogo de inventario y ventas, representando cada artículo o medicamento que se comercializa y gestiona en el sistema. Su propósito es integrar toda la información multidimensional del producto (código, nombre, precios, atributos, etc.), que es heredada y consultada por los módulos de compras, ventas, inventario, caja y analítica. Se conecta, mediante relaciones, a casi todas las tablas maestras del sistema para construir su descripción completa, y es la base para las transacciones de lotes_productos y kardex.
R.1: El campo requiere_receta con valor 1 indica que el producto solo puede venderse con receta médica; valor 0 indica venta libre.
R.2: El campo controlado con valor 1 indica que el producto está sujeto a control especial de sustancias; valor 0 indica producto sin control.
R.3: El registro con producto_id = 1 con nombre = ''NINGUNO'' y codigo = ''NIN'' es el registro predeterminado, se mantiene en estado HISTORICO y no puede modificarse ni eliminarse.
R.4: Los campos p_factor_venta y p_factor_facturacion son factores propios del producto que se heredan de la sucursal al momento de la creación y pueden modificarse independientemente.
R.5: Los campos pventa y pventaf se calculan automáticamente pero el usuario puede modificarlos. pventa = pcompra * p_factor_venta, pventaf = pcompra * p_factor_venta * p_factor_facturacion.
R.6: El campo tiene_registro_sanitario con valor 1 indica que el insumo o medicamento cuenta con la certificación sanitaria vigente emitida por la entidad reguladora pertinente para su comercialización legal; valor 0 indica que está exento o no posee el registro.
R.7: Control de Precios y Factores. Si se modifica pcompra, p_factor_venta o p_factor_facturacion, el sistema debe recalcular automáticamente pventa y pventaf.
R.8: Si productos.controlado = 1, debe existir obligatoriamente un registro en productos_controlados con el mismo producto_id en estado ACTIVO. El backend debe validar esta condición al insertar o actualizar un producto.
R.9: En descripcion se debe almacenar información de marketing, mientras que en observacion se debe almacenar información crucial del producto como Almacenar a temperatura ambiente (15-30°C), Almacenar en refrigeración (2-8°C), Proteger de la luz, Ambiente seco humedad < 60%.
R.10: tipo_almacen_id define el tipo de almacén requerido para la correcta conservación del producto. Este campo valida que el producto solo pueda ser ubicado en almacenes compatibles (ej. un producto refrigerado solo puede asignarse a un almacén de tipo REFRIGERADO). Los valores posibles corresponden al dominio TipoAlmacenID (1700-1712). El valor por defecto es 1700 (NORMAL).';

DELETE FROM productos;
ALTER SEQUENCE productos_producto_id_seq RESTART WITH 1;

INSERT INTO productos (producto_id, categoria_id, laboratorio_id, forma_id, presentacion_id, concentracion_id, unidad_venta_id, codigo, nombre, nombre_generico, pcompra, p_factor_venta, p_factor_facturacion, pventa, pventaf, stock_minimo, stock_maximo, punto_reorden, requiere_receta, controlado, tiene_registro_sanitario, descripcion, foto1, foto2, foto3, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1, 'NIN', 'NINGUNO', NULL, 0.00, 1.50, 1.19, 0.00, 0.00, 0.00, 1.00, 0.00, 0, 0, 0, 'Producto predeterminado para casos sin clasificar', NULL, NULL, NULL, 1000, 1);

UPDATE productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_producto_id_seq', COALESCE((SELECT MAX(producto_id) FROM productos), 1));

-- ================================================================================================

CREATE TABLE productos_vias (
    producto_via_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    via_id BIGINT NOT NULL DEFAULT 1,
    es_principal INTEGER NOT NULL DEFAULT 1,
    observaciones VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pva_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_pva_via_id FOREIGN KEY (via_id) REFERENCES vias(via_id),
    CONSTRAINT fk_pva_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pva_es_principal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_pv_relacion_unica ON productos_vias (producto_id, via_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pv_via ON productos_vias (via_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_vias IS 'Reglas de la tabla - productos_vias
R.0: La tabla productos_vias es una relación polimórfica que permite asociar múltiples vías de administración a un mismo producto, identificando una de ellas como principal. Su propósito es capturar la flexibilidad de algunos medicamentos que pueden ser administrados por diferentes vías, manteniendo la integridad referencial al mismo tiempo que se impone la regla de negocio de una única vía principal por producto. Se conecta directamente con las tablas productos y vias.
R.1: es_principal (1 = Sí, 0 = No) determina la vía de administración primaria del producto. El backend valida que exista exactamente un registro con es_principal = 1 por producto en estado ACTIVO.
R.2: Múltiples Vías por Producto. La interfaz de usuario debe permitir asociar más de una vía de administración a un mismo producto_id para dar soporte a medicamentos que pueden administrarse por diferentes vías (ej. oral y parenteral), asegurando que el frontend obligue a marcar exactamente una de ellas como la vía principal.
R.3: Validación de Vía Principal. Al insertar o actualizar registros en la tabla productos_vias, el backend debe validar que para cada producto_id exista exactamente uno y solo un registro con es_principal = 1 en estado ACTIVO. Si no existe ningún registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "El producto debe tener al menos una vía de administración marcada como principal (es_principal = 1)". Si existe más de un registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "Un producto no puede tener más de una vía de administración principal (es_principal = 1)".';

DELETE FROM productos_vias;
ALTER SEQUENCE productos_vias_producto_via_id_seq RESTART WITH 1;

INSERT INTO productos_vias (producto_via_id, producto_id, via_id, es_principal, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 'NINGUNO', 1000, 1);

UPDATE productos_vias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_vias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_vias_producto_via_id_seq', COALESCE((SELECT MAX(producto_via_id) FROM productos_vias), 1));

-- ================================================================================================

CREATE TABLE equivalentes (
    equivalente_id BIGSERIAL PRIMARY KEY,
    producto_base_id BIGINT NOT NULL DEFAULT 1,
    producto_alternativo_id BIGINT NOT NULL DEFAULT 1,
    grado_equivalente_id INTEGER NOT NULL DEFAULT 3803,  -- 3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO, 3803=NINGUNO
    prioridad_recomendacion INTEGER NOT NULL DEFAULT 1,
    observaciones VARCHAR(500) NULL,
    fecha_vigencia_desde DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vigencia_hasta DATE NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_eq_producto_base_id FOREIGN KEY (producto_base_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_eq_producto_alternativo_id FOREIGN KEY (producto_alternativo_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_eq_grado_equivalencia_id FOREIGN KEY (grado_equivalente_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_eq_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_eq_fechas_vigencia CHECK (fecha_vigencia_hasta IS NULL OR fecha_vigencia_hasta >= fecha_vigencia_desde),
    CONSTRAINT chk_eq_prioridad CHECK (prioridad_recomendacion >= 1),
	CONSTRAINT chk_eq_productos_diferentes CHECK (producto_base_id <> producto_alternativo_id OR equivalente_id = 1)
);
CREATE UNIQUE INDEX uix_eq_base_alternativo_vigente ON equivalentes (producto_base_id, producto_alternativo_id) WHERE estado_id IN (1000, 1002) AND NOT (producto_base_id = 1 AND producto_alternativo_id = 1);
CREATE INDEX idx_eq_vigente ON equivalentes (producto_base_id, fecha_vigencia_desde, fecha_vigencia_hasta) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE equivalentes IS 'Reglas de la tabla - equivalentes
R.0: La tabla equivalentes gestiona el catálogo de sustitutos farmacéuticos, vinculando un producto principal con alternativas comerciales o genéricas. Su propósito es permitir al personal de mostrador sugerir opciones viables de forma inmediata cuando el producto base está agotado o no disponible, garantizando la continuidad de la atención bajo criterios de equivalencia clínica. Se conecta directamente con la tabla productos y con dominios para el grado de equivalencia.
R.1: Restricción de Autoreferencia. El campo producto_base_id y producto_alternativo_id deben ser estrictamente diferentes (chk_eq_productos_diferentes), impidiendo que un producto sea equivalente de sí mismo.
R.2: Vigencia Temporal de la Equivalencia. fecha_vigencia_desde y fecha_vigencia_hasta controlan el periodo de validez operativa de la sustitución. El índice único parcial uix_eq_base_alternativo_vigente asegura que no existan duplicados activos para el mismo par de productos dentro de su rango de vigencia.
R.3: Grado de Equivalencia. grado_equivalente (3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO) clasifica el nivel de sustitución clínica, ordenando las sugerencias de mayor a menor equivalencia.
R.4: Prioridad de Recomendación. prioridad_recomendacion define el orden de despliegue en la interfaz de mostrador cuando el producto base se encuentra agotado, ordenando las alternativas de menor a mayor valor numérico entero positivo.';

DELETE FROM equivalentes;
ALTER SEQUENCE equivalentes_equivalente_id_seq RESTART WITH 1;

INSERT INTO equivalentes (equivalente_id, producto_base_id, producto_alternativo_id, grado_equivalente_id, prioridad_recomendacion, observaciones) VALUES
(1, 1, 1, 3803, 1, 'Sustituto directo');

UPDATE equivalentes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE equivalentes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('equivalentes_equivalente_id_seq', COALESCE((SELECT MAX(equivalente_id) FROM equivalentes), 1));

-- ================================================================================================

CREATE TABLE productos_rangos_edad (
    producto_rango_edad_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    rango_edad_id BIGINT NOT NULL DEFAULT 1,
    contraindicado INTEGER NOT NULL DEFAULT 0,
    dosis_recomendada VARCHAR(200) NULL,
    observaciones VARCHAR(500) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pre_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_pre_rango_edad_id FOREIGN KEY (rango_edad_id) REFERENCES rangos_edad(rango_edad_id),
    CONSTRAINT fk_pre_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pre_contraindicado CHECK (contraindicado IN (0, 1))
);
CREATE UNIQUE INDEX uix_pre_relacion_unica ON productos_rangos_edad (producto_id, rango_edad_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pre_rango_edad ON productos_rangos_edad (rango_edad_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_rangos_edad IS 'Reglas de la tabla - productos_rangos_edad
R.0: La tabla productos_rangos_edad es una relación polimórfica que asigna a un producto los rangos de edad para los cuales está indicado o contraindicado. Su propósito es gestionar la seguridad y el cumplimiento normativo, permitiendo al sistema filtrar automáticamente los productos adecuados según la edad del paciente y mostrando advertencias de contraindicación. Se conecta directamente con las tablas productos y rangos_edad.
R.1: Esta tabla establece la relación entre productos y rangos de edad, permitiendo definir si un producto está contraindicado para un grupo etario específico, así como la dosis recomendada y observaciones particulares.
R.2: El campo contraindicado con valor 1 (Sí) indica que el producto no debe ser dispensado a pacientes en ese rango de edad. Valor 0 (No) indica que el producto es seguro para ese rango etario.
R.3: La combinación de producto_id y rango_edad_id debe ser única para registros activos o históricos, garantizando que no existan duplicados en las relaciones.
R.4: El registro con producto_rango_edad_id = 1 actúa como registro comodín que relaciona el producto por defecto (producto_id = 1) con el rango de edad por defecto (rango_edad_id = 1), ambos en estado HISTORICO.
R.5: El frontend debe consultar esta tabla para determinar si un producto puede ser dispensado a un paciente según su edad, mostrando advertencias visuales si el producto está contraindicado para ese rango etario.
R.6: El campo dosis_recomendada almacena la dosis específica recomendada para el rango de edad, permitiendo personalizar la posología según el grupo etario del paciente.
R.7: Al asociar un rango de edad a un producto, el sistema debe validar que tanto el producto como el rango de edad estén en estado ACTIVO (estado_id = 1000) y que no exista una relación previa duplicada.';

DELETE FROM productos_rangos_edad;
ALTER SEQUENCE productos_rangos_edad_producto_rango_edad_id_seq RESTART WITH 1;

INSERT INTO productos_rangos_edad (producto_rango_edad_id, producto_id, rango_edad_id, contraindicado, dosis_recomendada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, NULL, NULL, 1000, 1);

UPDATE productos_rangos_edad SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_rangos_edad SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_rangos_edad_producto_rango_edad_id_seq', COALESCE((SELECT MAX(producto_rango_edad_id) FROM productos_rangos_edad), 1));

-- ================================================================================================

CREATE TABLE productos_ubicaciones (
    producto_ubicacion_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    ubicacion_id BIGINT NOT NULL DEFAULT 1,
    prioridad_picking INTEGER NOT NULL DEFAULT 1,
    estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pru_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_pru_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_pru_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT chk_pru_prioridad_rango CHECK (prioridad_picking BETWEEN 1 AND 99)
);
CREATE UNIQUE INDEX uix_pru_producto_posicion_unica ON productos_ubicaciones (producto_id, ubicacion_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pru_ubicacion_busqueda_rapida ON productos_ubicaciones (ubicacion_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_ubicaciones IS 'Reglas de la tabla - productos_ubicaciones
R.0: La tabla productos_ubicaciones mapea la ubicación física exacta de un producto dentro del almacén, definiendo la relación entre un producto y una coordenada espacial específica. Su propósito es habilitar una logística interna eficiente, optimizando las rutas de "picking" (prioridad) y controlando la capacidad máxima de almacenamiento por ubicación, lo que es esencial para la organización y el rápido despacho de mercadería. Se conecta directamente con las tablas productos y ubicaciones.
R.1: Separación Estricta de Responsabilidades: La tabla productos_ubicaciones delega la totalidad de la información geométrica y topológica del layout físico del almacén a la entidad ubicaciones, actuando únicamente como un nodo relacional que asocia existencias con coordenadas preestablecidas.
R.2: Integridad Espacial Unívoca: Se implementa una restricción de unicidad mediante el índice uix_pru_producto_posicion_unica, impidiendo de forma categórica que un mismo producto posea múltiples asignaciones logísticas concurrentes hacia la misma llave física espacial en estado operacional activo.
R.3: Optimización Algorítmica de Picking: El campo prioridad_picking rige de manera obligatoria el ordenamiento secuencial de las rutas automáticas de extracción generadas por el sistema (WMS), donde valores numéricos inferiores representan mayor prioridad de visitación o despacho inmediato.
R.4: Registro Comodín de Consistencia Mínima: La tupla inicial con ID igual a 1 vincula de manera explícita el producto por defecto al registro comodín de ubicaciones en estado ''HISTORICO'', garantizando la resolución exitosa de operaciones previas a la diagramación oficial de los centros de distribución.';

DELETE FROM productos_ubicaciones;
ALTER SEQUENCE productos_ubicaciones_producto_ubicacion_id_seq RESTART WITH 1;

INSERT INTO productos_ubicaciones (producto_ubicacion_id, producto_id, ubicacion_id, prioridad_picking, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 99, 1000, 1);

UPDATE productos_ubicaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_ubicaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_ubicaciones_producto_ubicacion_id_seq', COALESCE((SELECT MAX(producto_ubicacion_id) FROM productos_ubicaciones), 1));

-- ================================================================================================

CREATE TABLE principios_activos (
    principio_activo_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(1000) NULL,
    es_controlado INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_pri_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pri_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_pri_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_pri_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_pri_nombre_mayusculas CHECK (nombre = UPPER(nombre)),
    CONSTRAINT chk_pri_es_controlado CHECK (es_controlado IN (0, 1))
);
CREATE UNIQUE INDEX uix_pri_codigo ON principios_activos (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_pri_nombre ON principios_activos (nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE principios_activos IS 'Reglas de la tabla - principios_activos
R.0: La tabla principios_activos es un catálogo de compuestos farmacológicos que constituyen la base médica de los medicamentos. Su propósito es gestionar la información sobre sustancias activas, facilitar la búsqueda de genéricos, controlar los principios activos fiscalizados y servir como base para la clasificación médica de los productos. Se conecta a través de productos_principios con la tabla productos.
R.1: Control de Sustancias Fiscalizadas: El indicador es_controlado define las restricciones de dispensación del compuesto en el frontend; un valor de 1 (Sí) condiciona el formulario de venta para exigir la captura obligatoria de los datos de la receta médica, mientras que un valor de 0 (No) permite una salida libre de inventario.
R.2: Agrupación y Equivalencia Comercial: En el catálogo de productos, múltiples fármacos de marcas comerciales distintas pueden compartir el mismo principio_activo_id dinámicamente, lo que faculta a la pantalla de ventas a sugerir alternativas genéricas y de menor costo al paciente cuando no hay disponibilidad física de la marca solicitada.';

DELETE FROM principios_activos;
ALTER SEQUENCE principios_activos_principio_activo_id_seq RESTART WITH 1;

INSERT INTO principios_activos (principio_activo_id, codigo, nombre, descripcion, es_controlado, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN COMPONENTE ACTIVO REGISTRADO / NO APLICA', 0, 1000, 1);

UPDATE principios_activos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE principios_activos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('principios_activos_principio_activo_id_seq', COALESCE((SELECT MAX(principio_activo_id) FROM principios_activos), 1));

-- ================================================================================================

CREATE TABLE productos_principios (
    producto_principio_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    principio_activo_id BIGINT NOT NULL DEFAULT 1,
    concentracion VARCHAR(100) NOT NULL DEFAULT 'NO APLICA',
    es_principal INTEGER NOT NULL DEFAULT 1,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ppa_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_ppa_principio_activo_id FOREIGN KEY (principio_activo_id) REFERENCES principios_activos(principio_activo_id),
	CONSTRAINT fk_ppa_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ppa_concentracion_not_empty CHECK (TRIM(concentracion) <> ''),
    CONSTRAINT chk_ppa_es_principal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_ppa_relacion_unica ON productos_principios (producto_id, principio_activo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productos_principios_principio ON productos_principios (principio_activo_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_principios IS 'Reglas de la tabla - productos_principios
R.0: La tabla productos_principios es una relación polimórfica que asocia principios activos a un producto, permitiendo que un medicamento compuesto tenga múltiples sustancias activas. Su propósito es modelar la composición química de los productos, identificando el principio activo principal para su categorización médica y control, lo cual es fundamental para el cumplimiento regulatorio y la prescripción. Se conecta directamente con las tablas productos y principios_activos.
R.1: es_principal (1 = Sí, 0 = No) identifica al principio activo principal de la fórmula. El backend valida que exista exactamente un registro con es_principal = 1 por producto en estado ACTIVO.
R.2: Múltiples Principios Activos por Medicamento: La interfaz de usuario debe permitir asociar más de un principio activo a un mismo producto_id para dar soporte a medicamentos compuestos (multicomponentes o combinados), asegurando que el frontend obligue a marcar exactamente uno de ellos como el componente principal.
R.3: Validación de Principio Activo Principal: Al insertar o actualizar registros en la tabla productos_principios, el backend debe validar que para cada producto_id exista exactamente uno y solo un registro con es_principal = 1 en estado ACTIVO. Si no existe ningún registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "El producto debe tener al menos un principio activo marcado como principal (es_principal = 1)". Si existe más de un registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "Un producto no puede tener más de un principio activo principal (es_principal = 1)". Esta validación aplica tanto para inserciones como para actualizaciones, incluyendo cambios de estado.
R.4: Los campos ``foto1``, ``foto2`` y ``foto3`` almacenan las rutas de las imágenes del producto. Son opcionales y permiten hasta tres imágenes por producto. El backend controla la creación y el reemplazo de los archivos según la R.G.4.';

DELETE FROM productos_principios;
ALTER SEQUENCE productos_principios_producto_principio_id_seq RESTART WITH 1;

INSERT INTO productos_principios (producto_principio_id, producto_id, principio_activo_id, concentracion, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 0, 1000, 1);

UPDATE productos_principios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_principios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_principios_producto_principio_id_seq', COALESCE((SELECT MAX(producto_principio_id) FROM productos_principios), 1));

-- ================================================================================================

CREATE TABLE registros_sanitarios (
    registro_sanitario_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    codigo_registro VARCHAR(50) NOT NULL,
    entidad_emisora VARCHAR(100) NOT NULL DEFAULT '',
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_res_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_res_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_res_codigo_registro_not_empty CHECK (TRIM(codigo_registro) <> ''),
    CONSTRAINT chk_res_codigo_registro_mayusculas CHECK (codigo_registro = UPPER(codigo_registro)),
    CONSTRAINT chk_res_entidad_emisora_not_empty CHECK (TRIM(entidad_emisora) <> ''),
    CONSTRAINT chk_res_entidad_emisora_mayusculas CHECK (entidad_emisora = UPPER(entidad_emisora)),
    CONSTRAINT chk_res_fechas CHECK (fecha_vencimiento > fecha_emision)
);
CREATE UNIQUE INDEX uix_res_producto_vigente ON registros_sanitarios (producto_id) WHERE estado_id = 1000;

COMMENT ON TABLE registros_sanitarios IS 'Reglas de la tabla - registros_sanitarios
R.0: La tabla registros_sanitarios gestiona la información legal de los productos, almacenando el código de registro sanitario, su fecha de emisión y vencimiento. Su propósito es controlar la vigencia de la autorización de comercialización de cada producto, bloqueando su venta si el registro sanitario está caducado, lo que asegura el cumplimiento de la normativa sanitaria. Se conecta directamente con la tabla productos.
R.1: Control de Caducidad de Autorización: Al registrar compras o emitir ventas en el frontend, el sistema debe contrastar la fecha actual del servidor contra fecha_vencimiento; si el registro está caducado, la interfaz debe bloquear la comercialización del lote y alertar visualmente al regente farmacéutico.
R.2: Exclusividad de Registro Activo: Un producto farmacéutico (producto_id) puede poseer un historial extenso de renovaciones de licencias sanitarias, pero solo se permite un único registro con estado ''ACTIVO'' en simultáneo para garantizar la trazabilidad legal vigente.';

DELETE FROM registros_sanitarios;
ALTER SEQUENCE registros_sanitarios_registro_sanitario_id_seq RESTART WITH 1;

INSERT INTO registros_sanitarios (registro_sanitario_id, producto_id, codigo_registro, entidad_emisora, fecha_emision, fecha_vencimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', '2000-01-01', '2001-01-01', 1000, 1);

UPDATE registros_sanitarios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE registros_sanitarios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('registros_sanitarios_registro_sanitario_id_seq', COALESCE((SELECT MAX(registro_sanitario_id) FROM registros_sanitarios), 1));

-- ================================================================================================

CREATE TABLE productos_controlados (
    producto_controlado_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    numero_autorizacion VARCHAR(50) NOT NULL,
    requiere_receta_retenida INTEGER NOT NULL DEFAULT 1,
    observaciones_control VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_prc_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_prc_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_prc_numero_autorizacion_not_empty CHECK (TRIM(numero_autorizacion) <> ''),
    CONSTRAINT chk_prc_numero_autorizacion_mayusculas CHECK (numero_autorizacion = UPPER(numero_autorizacion)),
    CONSTRAINT chk_prc_requiere_receta CHECK (requiere_receta_retenida IN (0, 1))
);
CREATE UNIQUE INDEX uix_prc_producto_activo ON productos_controlados (producto_id) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_prc_numero_autorizacion ON productos_controlados (numero_autorizacion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_controlados IS 'Reglas de la tabla - productos_controlados
R.0: La tabla productos_controlados extiende la información de gestión para aquellos productos sujetos a fiscalización especial, como psicotrópicos o estupefacientes. Su propósito es imponer controles adicionales como la autorización específica, el stock máximo permitido y la retención obligatoria de recetas, para cumplir con las estrictas regulaciones de sustancias controladas. Se conecta directamente con la tabla productos.
R.1: Control de Retención de Recetas: Cuando la bandera requiere_receta_retenida es igual a 1 (Sí), el formulario de facturación del frontend debe bloquear la confirmación de la venta hasta que el operario registre el número de receta médica y los datos del médico colegiado. Un valor de 0 (No) exime de esta restricción.';

DELETE FROM productos_controlados;
ALTER SEQUENCE productos_controlados_producto_controlado_id_seq RESTART WITH 1;

INSERT INTO productos_controlados (producto_controlado_id, producto_id, numero_autorizacion, requiere_receta_retenida, observaciones_control, estado_id, usuario_id_registro) VALUES (1, 1, 'NINGUNO', 0, 'SIN FISCALIZACIÓN / NO APLICA', 1000, 1);

UPDATE productos_controlados SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_controlados SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_controlados_producto_controlado_id_seq', COALESCE((SELECT MAX(producto_controlado_id) FROM productos_controlados), 1));

-- ================================================================================================

CREATE TABLE promociones (
    promocion_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(1000) NULL,
	cantidad_requerida INTEGER NOT NULL DEFAULT 0,
	cantidad_beneficio INTEGER NOT NULL DEFAULT 0,
    tipo_beneficio_id INTEGER NOT NULL DEFAULT 1504,  	-- 1500=DESCUENTO, 1501=PORCENTAJE, 1502=MONTO_FIJO, 1503=CANTIDAD, 1504=NINGUNO
	valor_beneficio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_prom_tipo_beneficio_id FOREIGN KEY (tipo_beneficio_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_prom_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_prom_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_prom_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_prom_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_prom_nombre_mayusculas CHECK (nombre = UPPER(nombre)),
    CONSTRAINT chk_prom_valor_beneficio CHECK (valor_beneficio >= 0.00),
    CONSTRAINT chk_prom_vigencia CHECK (fecha_fin > fecha_inicio),
	CONSTRAINT chk_prom_cantidades CHECK (cantidad_requerida >= 0 AND cantidad_beneficio >= 0)
);
CREATE UNIQUE INDEX uix_prom_codigo ON promociones (codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE promociones IS 'Reglas de la tabla - promociones
R.0: La tabla promociones define campañas comerciales con fechas de vigencia y un tipo de beneficio (descuento, monto fijo, etc.). Su propósito es estructurar las reglas de cálculo para aplicar descuentos en el punto de venta (POS), gestionando ofertas temporales que incentivan las ventas. Se conecta a través de promociones_productos con la tabla productos.
R.1: Validación de Coincidencia de Campañas: Al calcular la liquidación del carrito en el punto de venta, el motor del backend debe filtrar las promociones basándose en la fecha y hora del servidor actual frente a los campos fecha_inicio y fecha_fin. Aquellas campañas fuera de rango o con estado diferente a ''ACTIVO'' deben ser omitidas de manera automática sin alterar los precios base del inventario.
R.2: Tipificación del Beneficio Económico: El campo tipo_beneficio_id orienta la fórmula aritmética de descuento en la interfaz. Si está configurado como ''PORCENTAJE'', el valor del campo valor_beneficio se procesa como una tasa de descuento aplicable sobre el precio del artículo (ej. 10.00 para un 10%); si es ''MONTO_FIJO'', representa una deducción monetaria directa y constante sobre el total de la línea.
R.3: Soporte para Promociones por Volumen y Cantidad: Los campos cantidad_requerida y cantidad_beneficio estructuran las reglas para ofertas basadas en unidades (ej. mecánicas tipo "Lleve X, Pague Y" o bonificaciones por volumen). Cuando el tipo_beneficio_id corresponda a ''CANTIDAD'' (1503), el motor del POS evaluará estos umbrales para determinar las unidades bonificadas o cobradas en la transacción.
R.4: La logica de negocio esta en fn_validarCoherenciaPromocion.';

DELETE FROM promociones;
ALTER SEQUENCE promociones_promocion_id_seq RESTART WITH 1;

INSERT INTO promociones (promocion_id, codigo, nombre, descripcion, tipo_beneficio_id, valor_beneficio, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN CAMPAÑA PROMOCIONAL / NO APLICA', 1504, 0.00, '2000-01-01', '2001-01-01', 1000, 1);

UPDATE promociones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE promociones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('promociones_promocion_id_seq', COALESCE((SELECT MAX(promocion_id) FROM promociones), 1));

-- ================================================================================================

CREATE TABLE promociones_productos (
    promocion_producto_id BIGSERIAL PRIMARY KEY,
    promocion_id BIGINT NOT NULL DEFAULT 1,
    producto_id BIGINT NOT NULL DEFAULT 1,
    limite_por_transaccion INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_prp_promocion_id FOREIGN KEY (promocion_id) REFERENCES promociones(promocion_id),
    CONSTRAINT fk_prp_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_prp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_prp_limite CHECK (limite_por_transaccion >= 0)
);
CREATE UNIQUE INDEX uix_prp_producto_activo ON promociones_productos (producto_id) WHERE estado_id = 1000;

COMMENT ON TABLE promociones_productos IS 'Reglas de la tabla - promociones_productos
R.0: La tabla promociones_productos es una relación polimórfica que vincula promociones con productos específicos, estableciendo límites por transacción. Su propósito es permitir que una promoción se aplique a un subconjunto de productos y controlar la cantidad de unidades que pueden ser beneficiadas, asegurando que la lógica de descuento sea transparente y no genere pérdidas. Se conecta directamente con las tablas promociones y productos.
R.1: Control de Racionamiento de Descuentos: El campo limite_por_transaccion restringe el número máximo de unidades de un mismo producto que pueden beneficiarse de la campaña en una única operación de venta. Un valor superior a 0 activa la validación en el punto de facturación; si el cliente excede dicha cantidad, las unidades adicionales se liquidarán automáticamente a la tarifa estándar de la lista de precios vigente. Un valor de 0 anula esta restricción, permitiendo unidades ilimitadas por ticket.
R.2: Exclusividad de Campaña Activa: Para prevenir conflictos de cálculo en cascada o márgenes negativos por doble descuento, un producto_id específico sólo puede estar asociado a una única relación de promoción en estado ''ACTIVO'' a través de esta tabla intermedia. El índice único compuesto restringe la duplicidad operativa.';

DELETE FROM promociones_productos;
ALTER SEQUENCE promociones_productos_promocion_producto_id_seq RESTART WITH 1;

INSERT INTO promociones_productos (promocion_producto_id, promocion_id, producto_id, limite_por_transaccion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, 1000, 1);

UPDATE promociones_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE promociones_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('promociones_productos_promocion_producto_id_seq', COALESCE((SELECT MAX(promocion_producto_id) FROM promociones_productos), 1));

-- ================================================================================================

CREATE TABLE conversiones_unidad (
    conversion_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    unidad_origen_id BIGINT NOT NULL DEFAULT 1,
    unidad_destino_id BIGINT NOT NULL DEFAULT 1,
    factor_conversion DECIMAL(10,4) NOT NULL DEFAULT 1.0000,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cv_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_cv_unidad_origen_id FOREIGN KEY (unidad_origen_id) REFERENCES unidades(unidad_id),
    CONSTRAINT fk_cv_unidad_destino_id FOREIGN KEY (unidad_destino_id) REFERENCES unidades(unidad_id),
	CONSTRAINT fk_cv_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cv_factor_conversion CHECK (factor_conversion > 0.0000),
    CONSTRAINT chk_cv_unidades_diferentes CHECK (unidad_origen_id <> unidad_destino_id OR conversion_id = 1)
);
CREATE UNIQUE INDEX uix_cv_unique ON conversiones_unidad (producto_id, unidad_origen_id, unidad_destino_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cv_producto ON conversiones_unidad (producto_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE conversiones_unidad IS 'Reglas de la tabla - conversiones_unidad
R.0: La tabla conversiones_unidad define los factores de conversión entre diferentes unidades de medida para un mismo producto, como de caja a unidad. Su propósito es resolver la equivalencia entre unidades (factores de empaque), lo que es fundamental para operaciones de compra, venta y gestión de inventario, permitiendo registrar, por ejemplo, una compra en cajas pero vender en unidades. Se conecta directamente con las tablas productos y unidades.
R.1: El campo factor_conversion representa cuántas unidades de destino equivalen a una unidad de origen (ej. 1 Caja = 24 Tabletas). El motor de inventario utiliza este factor para fraccionar o agrupar unidades en transacciones de venta y compra.
R.2: La combinación de producto_id, unidad_origen_id y unidad_destino_id debe ser única para registros activos o históricos, evitando factores de conversión redundantes.
R.3: Las unidades de origen y destino deben ser diferentes (chk_cv_unidades_diferentes) menos pk_id=1. El sistema no permite conversiones de una unidad consigo misma para evitar bucles infinitos en el cálculo de equivalencias.';

DELETE FROM conversiones_unidad;
ALTER SEQUENCE conversiones_unidad_conversion_id_seq RESTART WITH 1;

INSERT INTO conversiones_unidad (conversion_id, producto_id, unidad_origen_id, unidad_destino_id, factor_conversion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1.0000, 1000, 1);

UPDATE conversiones_unidad SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE conversiones_unidad SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('conversiones_unidad_conversion_id_seq', COALESCE((SELECT MAX(conversion_id) FROM conversiones_unidad), 1));

-- ================================================================================================

CREATE TABLE proveedores (
    proveedor_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    nit VARCHAR(30) NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(50) NULL,
    email VARCHAR(100) NULL,
    rating_calidad_id INTEGER NOT NULL DEFAULT 2055,  	-- 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
	monto_minimo_compra DECIMAL(12,2) DEFAULT 0.00,
	plazo_entrega_dias INTEGER DEFAULT 7,
	limite_credito DECIMAL(12,2) DEFAULT 0.00,
	dias_credito INTEGER DEFAULT 0,
	ultima_evaluacion DATE NULL,
	observaciones VARCHAR(2000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_prov_rating_calidad_id FOREIGN KEY (rating_calidad_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_prov_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_prov_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
	CONSTRAINT chk_prov_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_prov_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_prov_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_prov_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_prov_nombre_min_length CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_prov_nombre_mayusculas CHECK (nombre = UPPER(nombre))
);
CREATE UNIQUE INDEX uix_prov_codigo ON proveedores (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_prov_nombre ON proveedores (nombre) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_prov_nit ON proveedores (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND TRIM(nit) <> '';

COMMENT ON TABLE proveedores IS 'Reglas de la tabla - proveedores
R.0: La tabla proveedores es el registro maestro de los suministradores de productos, almacenando su información de contacto y un rating de calidad. Su propósito es gestionar las relaciones comerciales con los laboratorios y distribuidores, sirviendo como el referente para los procesos de compras, la evaluación de desempeño de proveedores y la planificación de inventario. Se conecta directamente con la tabla kardex.
R.1: El Número de Identificación Tributaria (nit) es opcional para dar soporte a proveedores extranjeros o laboratorios internacionales. Cuando se registra un valor, el índice único impide duplicados en registros activos o históricos.
R.2: El registro con proveedor_id = 1 y nombre ''NINGUNO'' representa el proveedor comodín para compras directas o donaciones; permanece en estado HISTORICO para garantizar la integridad referencial.
R.3: Los campos codigo y nombre deben almacenarse en mayúsculas y ser únicos para registros activos o históricos.
R.4: Rating de Calidad. rating_calidad_id utiliza el dominio CalidadRatingID (2050-2054) para calificar el desempeño del proveedor en aspectos como cumplimiento de plazos, calidad del producto, precios, etc. El valor por defecto es REGULAR (2052). Este campo es opcional y puede ser NULL si aún no se ha evaluado al proveedor.
R.5: Suficiencia del Modelo de Proveedores. Se ratifica que la estructura actual de la tabla proveedores, complementada por el campo rating_calidad_id (referenciado al dominio CalidadRatingID 2050-2055) y la integración transversal con el kardex de compras y los módulos estratégicos del sistema, cumple de manera óptima con la evaluación de desempeño y la gestión comercial, sin requerir tablas adicionales de scoring AHP que contravengan la filosofía de simplicidad y velocidad de la arquitectura AK-47.
R.6: Control de Rating de Calidad. rating_calidad_id utiliza el dominio CalidadRatingID (2050-2054).
- Si rating_calidad_id = 2050 (PESIMO), el sistema debe bloquear nuevas compras a este proveedor.
- El backend debe actualizar automáticamente el rating basado en incidencias de calidad.
R.7: Validación de Unicidad de NIT. El nit debe ser único para registros ACTIVOS o HISTORICOS. No pueden existir dos proveedores con el mismo nit.
R.8: Límite de Crédito por Proveedor. El sistema debe validar que el monto total de compras a crédito pendientes (estado_financiero_id IN (2401, 2402)) no exceda el límite de crédito configurado en parametros_globales (proveedor_limite_credito_default).
R.9: Valor Mínimo de Compra. Cada proveedor debe tener un monto mínimo de compra configurado (campo monto_minimo_compra DECIMAL(12,2) DEFAULT 0.00). El sistema debe validar que total_compra >= monto_minimo_compra.
R.10: Control de Plazos de Entrega. El campo plazo_entrega_dias (INTEGER) define el lead time estándar del proveedor. El sistema utiliza este valor para calcular puntos de reorden y fechas estimadas de recepción.
R.11: Historial de Calificación. La tabla debe mantener un historial de calificaciones en proveedores_rating (RELACIÓN FALTANTE - VER SECCIÓN 6) para trazabilidad de evaluaciones.';

DELETE FROM proveedores;
ALTER SEQUENCE proveedores_proveedor_id_seq RESTART WITH 1;

INSERT INTO proveedores (proveedor_id, codigo, nombre, nit, direccion, telefono, email, rating_calidad_id, monto_minimo_compra, plazo_entrega_dias, limite_credito, dias_credito, ultima_evaluacion, observaciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', NULL, NULL, NULL, NULL, 2055, 0.00, 0, 0.00, 0, NULL, 'PROVEEDOR COMODÍN PARA COMPRAS DIRECTAS O DONACIONES', 1000, 1);

UPDATE proveedores SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE proveedores SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('proveedores_proveedor_id_seq', COALESCE((SELECT MAX(proveedor_id) FROM proveedores), 1));

-- ================================================================================================

CREATE TABLE proveedores_contactos (
    proveedor_contacto_id BIGSERIAL PRIMARY KEY,
    proveedor_id BIGINT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    cargo VARCHAR(100) NULL,
    telefono VARCHAR(50) NULL,
    email VARCHAR(100) NULL,
    es_principal INTEGER NOT NULL DEFAULT 0,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pc_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT fk_pc_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pc_es_principal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_pc_proveedor_principal ON proveedores_contactos (proveedor_id) WHERE es_principal = 1 AND estado_id = 1000;

COMMENT ON TABLE proveedores_contactos IS 'Reglas de la tabla - proveedores_contactos
R.0: La tabla proveedores_contactos almacena la información de contacto asociados a cada proveedor (nombre, cargo, teléfono, email). Su propósito es gestionar los canales de comunicación y los puntos de contacto comerciales u operativos con cada suministrador.
R.1: El campo es_principal (INTEGER, 0 o 1) indica si el contacto es el principal para el proveedor. Un índice único parcial garantiza que solo exista un contacto principal en estado ACTIVO (estado_id = 1000) por cada proveedor.
R.2: Los estados de los registros se controlan mediante estado_id, vinculados al dominio de estados estándar (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO).
R.3: Cada contacto está vinculado obligatoriamente a un proveedor mediante la llave foránea fk_pc_proveedor_id y a la tabla de dominios mediante fk_pc_estado_id.';

DELETE FROM proveedores_contactos;
ALTER SEQUENCE proveedores_contactos_proveedor_contacto_id_seq RESTART WITH 1;

INSERT INTO proveedores_contactos (proveedor_contacto_id, proveedor_id, nombre, cargo, telefono, email, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', NULL, NULL, 1, 1000, 1);

UPDATE proveedores_contactos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE proveedores_contactos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1000;

SELECT setval('proveedores_contactos_proveedor_contacto_id_seq', COALESCE((SELECT MAX(proveedor_contacto_id) FROM proveedores_contactos), 1));

-- ================================================================================================

CREATE TABLE proveedores_rating_historico (
    rating_historico_id BIGSERIAL PRIMARY KEY,
    proveedor_id BIGINT NOT NULL,
    rating_calidad_id INTEGER NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    fecha_evaluacion DATE NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_rh_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT fk_rh_rating_calidad_id FOREIGN KEY (rating_calidad_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_rh_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id)
);
CREATE INDEX idx_rh_proveedor_fecha ON proveedores_rating_historico (proveedor_id, fecha_evaluacion DESC);

COMMENT ON TABLE proveedores_rating_historico IS 'Reglas de la tabla - proveedores_rating_historico
R.0: La tabla proveedores_rating_historico almacena el historial de calificaciones de calidad asignadas a cada proveedor a lo largo del tiempo. Su propósito es mantener la trazabilidad y auditoría de las evaluaciones de desempeño (vinculadas a la regla R.11 de la tabla proveedores), permitiendo analizar el comportamiento del suministrador ante incidencias.
R.1: Cada registro de evaluación está asociado a un proveedor mediante la llave foránea fk_rh_proveedor_id, a un rating específico mediante fk_rh_rating_calidad_id (referenciando el dominio CalidadRatingID), y requiere obligatoriamente una justificación en el campo motivo y una fecha de evaluación.
R.2: Los estados de los registros se controlan mediante estado_id, vinculados al dominio de estados estándar (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO) a través de la llave foránea fk_rh_estado_id.
R.3: Se incluye un índice compuesto (idx_rh_proveedor_fecha) sobre proveedor_id y fecha_evaluacion en orden descendente para optimizar las consultas del historial más reciente por cada proveedor.';

DELETE FROM proveedores_rating_historico;
ALTER SEQUENCE proveedores_rating_historico_rating_historico_id_seq RESTART WITH 1;

INSERT INTO proveedores_rating_historico (rating_historico_id, proveedor_id, rating_calidad_id, motivo, fecha_evaluacion, estado_id, usuario_id_registro)
VALUES (1, 1, 2055, 'REGISTRO INICIAL COMODÍN', CURRENT_DATE, 1000, 1);

UPDATE proveedores_rating_historico SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE proveedores_rating_historico SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1000;

SELECT setval('proveedores_rating_historico_rating_historico_id_seq', COALESCE((SELECT MAX(rating_historico_id) FROM proveedores_rating_historico), 1));

-- ================================================================================================

CREATE TABLE parametros_globales (
    parametro_id BIGSERIAL PRIMARY KEY,
    clave VARCHAR(100) NOT NULL,
    valor VARCHAR(500) NOT NULL,
    tipo_dato_id INTEGER NOT NULL DEFAULT 1800,  		-- 1800=STRING, 1801=INTEGER, 1802=DECIMAL, 1803=BOOLEAN
    descripcion VARCHAR(500) NULL,
    editable INTEGER NOT NULL DEFAULT 1,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pg_tipo_dato_id FOREIGN KEY (tipo_dato_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_pg_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pg_clave_formato CHECK (TRIM(clave) = clave AND clave ~ '^[a-z0-9_]+$' AND LENGTH(clave) >= 3),
    CONSTRAINT chk_pg_editable CHECK (editable IN (0, 1))
);
CREATE UNIQUE INDEX uix_pg_clave ON parametros_globales (clave) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE parametros_globales IS 'Reglas de la tabla - parametros_globales
R.0: La tabla parametros_globales actúa como un almacén de configuración clave-valor, que permite parametrizar el comportamiento del sistema. Su propósito es centralizar variables de negocio y operativas (como el porcentaje de IVA, días de alerta, etc.) en un solo lugar, haciendo que los ajustes sean dinámicos y no requieran recompilación de código. No se conecta directamente con otras tablas a través de claves foráneas, pero es consumida por todos los módulos de la aplicación.
R.1: El campo editable con valor 1 indica que el parámetro puede ser modificado por usuarios autorizados; valor 0 indica que solo puede ser modificado por administradores de sistemas.
R.2: tipo_dato_id define el formato de validación que el sistema aplica sobre el campo valor: STRING (texto), INTEGER (números enteros), DECIMAL (números con punto decimal), (1=Si, 0=No).
R.3: El campo clave debe ser único, en minúsculas, sin espacios, y solo caracteres alfanuméricos y guión bajo.';

DELETE FROM parametros_globales;
ALTER SEQUENCE parametros_globales_parametro_id_seq RESTART WITH 1;

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, descripcion, editable, estado_id, usuario_id_registro) VALUES
(1, 'ninguna', 'comodin_sistema', 1800, 'Registro comodin por defecto para parametros_globales', 0, 1000, 1),
(2, 'moneda_principal', 'BOB', 1800, 'Moneda base del sistema boliviano', 0, 1000, 1),
(3, 'porcentaje_iva', '13.00', 1802, 'Alícuota general del IVA en Bolivia', 1, 1000, 1),
(4, 'limite_items_proforma', '50', 1801, 'Cantidad máxima de ítems permitidos por proforma', 1, 1000, 1),
(5, 'controlar_lotes_vencidos', '1', 1803, 'Habilitar bloqueo de venta para lotes expirados (1=Si, 0=No)', 1, 1000, 1),
(6, 'dias_alerta_vencimiento', '90', 1801, 'Días de anticipación para notificar la expiración de medicamentos', 1, 1000, 1),
(7, 'modelo_arima_p', '1', 1801, 'Orden autorregresivo (p) para modelo ARIMA', 1, 1000, 1),
(8, 'modelo_arima_d', '1', 1801, 'Orden de diferenciación (d) para modelo ARIMA', 1, 1000, 1),
(9, 'modelo_arima_q', '1', 1801, 'Orden de promedio móvil (q) para modelo ARIMA', 1, 1000, 1),
(10, 'modelo_sarima_p', '1', 1801, 'Orden autorregresivo estacional (P) para SARIMA', 1, 1000, 1),
(11, 'modelo_sarima_d', '1', 1801, 'Orden de diferenciación estacional (D) para SARIMA', 1, 1000, 1),
(12, 'modelo_sarima_q', '1', 1801, 'Orden de promedio móvil estacional (Q) para SARIMA', 1, 1000, 1),
(13, 'modelo_sarima_s', '7', 1801, 'Período estacional (s) para SARIMA (7=días, 12=meses)', 1, 1000, 1),
(14, 'modelo_kmeans_n_clusters', '3', 1801, 'Número de clusters para K-Means (A, B, C)', 1, 1000, 1),
(15, 'modelo_kmeans_random_state', '42', 1801, 'Semilla aleatoria para reproducibilidad', 1, 1000, 1),
(16, 'modelo_kmeans_max_iter', '300', 1801, 'Máximo de iteraciones para K-Means', 1, 1000, 1),
(17, 'modelo_rop_lead_time_default', '7', 1801, 'Lead time por defecto en días para cálculo de ROP', 1, 1000, 1),
(18, 'modelo_rop_stock_seguridad_default', '10', 1802, 'Stock de seguridad por defecto para ROP', 1, 1000, 1),
(19, 'modelo_rop_nivel_confianza', '0.95', 1802, 'Nivel de confianza para intervalos de predicción', 1, 1000, 1),
(20, 'alerta_dias_vencimiento_critico', '15', 1801, 'Días para alerta CRÍTICA de vencimiento', 1, 1000, 1),
(21, 'alerta_dias_vencimiento_alta', '30', 1801, 'Días para alerta ALTA de vencimiento', 1, 1000, 1),
(22, 'alerta_dias_vencimiento_media', '60', 1801, 'Días para alerta MEDIA de vencimiento', 1, 1000, 1),
(23, 'alerta_stock_quiebre', '5', 1801, 'Stock mínimo para alerta de quiebre', 1, 1000, 1),
(24, 'alerta_stock_reorden', '20', 1801, 'Stock para alerta de reorden', 1, 1000, 1),
(25, 'alerta_dias_ventanas_dias', '90', 1801, 'Ventana de días para entrenar modelos', 1, 1000, 1),
(26, 'entrenamiento_min_registros', '30', 1801, 'Mínimo de registros para entrenar un modelo', 1, 1000, 1),
(27, 'entrenamiento_test_size', '0.2', 1802, 'Porcentaje de datos para prueba (test)', 1, 1000, 1),
(28, 'longitud_numero_factura', '7', 1801, 'Cantidad de dígitos para el número de factura (con ceros a la izquierda)', 1, 1000, 1),
(29, 'multa_dias_gracia', '10', 1801, 'Días de tolerancia permitidos antes de aplicar cargos por retraso en cuotas', 1, 1000, 1),
(30, 'multa_tipo_calculo', 'PORCENTAJE', 1800, 'Tipo de cálculo para la multa: MONTO_FIJO o PORCENTAJE sobre la cuota vencida', 1, 1000, 1),
(31, 'multa_valor_diario', '0.50', 1802, 'Valor diario de la multa (monto en moneda base o porcentaje según el tipo de cálculo)', 1, 1000, 1);

UPDATE parametros_globales SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE parametros_globales SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('parametros_globales_parametro_id_seq', COALESCE((SELECT MAX(parametro_id) FROM parametros_globales), 1));

-- ================================================================================================

CREATE TABLE tareas_programadas (
    tarea_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
    tipo_tarea_id INTEGER NOT NULL DEFAULT 3409,  	-- 3400=REPORTE, 3401=IA_MODELO, 3402=BACKUP, 3403=ALERTA, 3404=MANTENIMIENTO, 3405=FORECASTING, 3406=CLASIFICACION, 3407=OPTIMIZACION, 3408=VALIDACION, 3409=NINGUNO
    subtipo_tarea_id INTEGER NULL DEFAULT 3461,   	-- 3450=SARIMA, 3451=SARIMAX, 3452=PROPHET, 3453=KMEANS, 3454=ROP_CALC, 3455=PATRON_CONSUMO, 3456=ALERTA_PREDICTIVA, 3457=VARIABLE_EXOGENA, 3458=METRICA_RENDIMIENTO, 3459=REENTRENAMIENTO, 3460=VALIDACION_CROSS, 3461=NINGUNO
    frecuencia_id INTEGER NOT NULL DEFAULT 3359,  	-- 3350=MINUTOS, 3351=HORAS, 3352=DIARIO, 3353=SEMANAL, 3354=MENSUAL, 3355=ANUAL, 3356=CRON, 3357=CONTINUA, 3358=TRIGGER_EVENTO, 3359=NINGUNO
    cron_expresion VARCHAR(100) NULL,
    parametros JSONB NULL,
    ultima_ejecucion TIMESTAMPTZ NULL,
    proxima_ejecucion TIMESTAMPTZ NULL,
    ejecucion_exitosa INTEGER NULL,
    ultimo_error VARCHAR(3000) NULL,
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    max_intentos INTEGER NOT NULL DEFAULT 3,
    tarea_dependencia_id BIGINT NULL,
    ejecutar_en_cascada INTEGER NOT NULL DEFAULT 0,
    modulo_estrategico_id INTEGER NULL DEFAULT 2157,  	-- 2150=FLUJO_CAJA, 2151=DEMANDA_INVENTARIO, 2152=PROVEEDORES_AHP, 2153=OPERACION_MERMAS, 2154=CLIENTES_RFM, 2155=PRECIOS_ELASTICIDAD, 2156=ANOMALIAS_FRAUDE, 2157=NINGUNO
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_tar_tipo_tarea_id FOREIGN KEY (tipo_tarea_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tar_subtipo_tarea_id FOREIGN KEY (subtipo_tarea_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tar_frecuencia_id FOREIGN KEY (frecuencia_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_tar_tarea_dependencia_id FOREIGN KEY (tarea_dependencia_id) REFERENCES tareas_programadas(tarea_id),
    CONSTRAINT fk_tar_modulo_estrategico_id FOREIGN KEY (modulo_estrategico_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_tar_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_tar_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_tar_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_tar_nombre_not_empty CHECK (TRIM(nombre) <> ''),
	CONSTRAINT chk_tar_ejecucion_exitosa CHECK (ejecucion_exitosa IS NULL OR ejecucion_exitosa IN (0, 1)),
	CONSTRAINT chk_tar_ejecutar_en_cascada CHECK (ejecutar_en_cascada IN (0, 1)),
    CONSTRAINT chk_tar_intentos CHECK (intentos_fallidos >= 0 AND max_intentos > 0)
);
CREATE UNIQUE INDEX uix_tar_codigo ON tareas_programadas (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_tar_modulo_estrategico ON tareas_programadas (modulo_estrategico_id) WHERE modulo_estrategico_id IS NOT NULL AND estado_id IN (1000, 1002);

COMMENT ON TABLE tareas_programadas IS 'Reglas de la tabla - tareas_programadas
R.0: La tabla tareas_programadas es el orquestador de procesos automáticos y batch, definiendo los job que se ejecutarán en segundo plano (backups, entrenamientos de IA, alertas). Su propósito es gestionar el ciclo de vida de las tareas (frecuencia, dependencias, reintentos) y su clasificación por módulo estratégico, garantizando la automatización del sistema y la actualización continua de la inteligencia de negocio. Se conecta de forma autorreferencial para definir dependencias y con la tabla dominios para categorías.
R.1: Cuando una tarea falla, el sistema incrementa intentos_fallidos. Si alcanza max_intentos, el backend cambia automáticamente estado_id a 1001 (BORRADO) y registra el error en ultimo_error.
R.2: Si tarea_dependencia_id tiene valor y ejecutar_en_cascada es 1, el orquestador solo ejecuta la tarea cuando la tarea padre haya finalizado con ejecucion_exitosa = 1.
R.3: El campo estado_id utiliza los valores estándar del sistema (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). No se permiten estados personalizados como ''PAUSADO'' o ''INACTIVO''.
R.4: Módulo Estratégico. modulo_estrategico_id utiliza el dominio ModuloEstrategicoID (2150-2156) para clasificar la tarea según el área de negocio que impacta: FLUJO_CAJA (2150) para tareas financieras, DEMANDA_INVENTARIO (2151) para inventario, PROVEEDORES_AHP (2152) para proveedores, OPERACION_MERMAS (2153) para operaciones diarias, CLIENTES_RFM (2154) para clientes, PRECIOS_ELASTICIDAD (2155) para precios, ANOMALIAS_FRAUDE (2156) para detección de anomalías.
R.5: Campo ejecucion_exitosa.
- 1: La última ejecución de la tarea finalizó exitosamente, sin errores críticos y cumpliendo con todos los procesos definidos.
- 0: La última ejecución de la tarea falló por algún error (excepción, timeout, datos inconsistentes, etc.), registrando el detalle en ultimo_error.
- NULL: La tarea nunca ha sido ejecutada (estado inicial) o no se ha registrado el resultado de la última ejecución.
R.6: Campo ejecutar_en_cascada.
- 0 (valor por defecto): La tarea se ejecuta de forma independiente, sin esperar el resultado de la tarea dependiente (tarea_dependencia_id). Incluso si la tarea padre falla, la tarea hija se ejecutará según su propia programación.
- 1: La tarea solo se ejecutará cuando la tarea padre (tarea_dependencia_id) haya finalizado exitosamente (ejecucion_exitosa = 1). Si la tarea padre falla o no se ha ejecutado, la tarea hija se omite o se pospone hasta que la dependencia se cumpla exitosamente.';

DELETE FROM tareas_programadas;
ALTER SEQUENCE tareas_programadas_tarea_id_seq RESTART WITH 1;

INSERT INTO tareas_programadas (tarea_id, codigo, nombre, descripcion, tipo_tarea_id, subtipo_tarea_id, frecuencia_id, cron_expresion, parametros, ultima_ejecucion, proxima_ejecucion, ejecucion_exitosa, ultimo_error, intentos_fallidos, max_intentos, tarea_dependencia_id, ejecutar_en_cascada, modulo_estrategico_id, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'NINGUNA', 3409, 3461, 3359, NULL, '{"ejecutar": false}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(2, 'ALERTA_VENC', 'ALERTA DE VENCIMIENTO DE LOTES', 'Identifica lotes próximos a vencer y genera notificaciones', 3403, 3461, 3352, '0 6 * * *', '{"dias_alerta_critica": 15, "dias_alerta_alta": 30, "dias_alerta_media": 60}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2153, 1000, 1),
(3, 'ALERTA_STOCK', 'ALERTA DE STOCK CRÍTICO', 'Monitorea inventario y genera alertas por debajo del punto de reorden', 3403, 3461, 3351, '0 * * * *', '{"umbral_quiebre": 5, "umbral_reorden": 20}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(4, 'ENTRENAR_SARIMA', 'ENTRENAMIENTO DE MODELO SARIMA', 'Entrena el modelo de pronóstico de demanda con datos históricos', 3405, 3450, 3353, '0 2 * * 0', '{"ventana_dias": 90, "test_size": 0.2, "p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(5, 'CLASIFICAR_ABC', 'CLASIFICACIÓN ABC DE INVENTARIO', 'Reclasifica productos en categorías A, B y C con K-Means', 3406, 3453, 3354, '0 3 1 * *', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "criterios": ["costo", "rotacion", "margen", "criticidad"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(6, 'PREDECIR_DEMANDA', 'PREDICCIÓN DE DEMANDA Y ROP', 'Calcula predicciones de demanda y actualiza puntos de reorden', 3407, 3454, 3352, '0 4 * * *', '{"dias_a_predecir": 30, "lead_time_default": 7, "stock_seguridad_default": 10}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(7, 'BACKUP_DB', 'RESPALDO AUTOMÁTICO DE BASE DE DATOS', 'Genera backup completo de PostgreSQL', 3402, 3461, 3352, '0 1 * * *', '{"retencion_dias": 30, "compresion": true, "ruta_destino": "/backups/db/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(8, 'REPORTE_VENTAS_DIA', 'REPORTE DIARIO DE VENTAS', 'Consolida ventas del día con gráficos y resúmenes', 3400, 3461, 3352, '0 23 * * *', '{"formato": "PDF", "incluir_graficos": true, "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(9, 'LIMPIEZA_NOTIFICACIONES', 'LIMPIEZA DE NOTIFICACIONES LEÍDAS', 'Archiva notificaciones leídas con más de X días', 3404, 3461, 3353, '0 5 * * 0', '{"dias_para_archivar": 90}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(10, 'PREDECIR_VENCIMIENTOS', 'PREDICCIÓN DE FECHAS DE VENCIMIENTO', 'Pronostica vencimientos basados en patrones de consumo', 3405, 3452, 3353, '0 4 * * 1', '{"modelo": "PROPHET", "dias_proyeccion": 180}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2153, 1000, 1),
(11, 'ALERTA_PREDICTIVA', 'ALERTAS PREDICTIVAS DE IA', 'Evalúa riesgos futuros basados en modelos predictivos', 3403, 3456, 3352, '0 7 * * *', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2156, 1000, 1),
(12, 'ENTRENAR_SARIMAX', 'ENTRENAMIENTO SARIMAX CON VARIABLES EXÓGENAS', 'Entrena SARIMAX incorporando variables externas', 3405, 3451, 3353, '0 3 * * 0', '{"ventana_dias": 90, "incluir_festivos": true, "incluir_clima": true}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(13, 'ENTRENAR_PROPHET', 'ENTRENAMIENTO DE MODELO PROPHET', 'Entrena el modelo Prophet de Facebook', 3405, 3452, 3354, '0 4 1 * *', '{"ventana_dias": 180, "estacionalidad_anual": true, "estacionalidad_semanal": true}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(14, 'PATRON_CONSUMO', 'DETECCIÓN DE PATRONES DE CONSUMO', 'Analiza históricos para identificar patrones estacionales', 3405, 3455, 3354, '0 5 1 * *', '{"min_datos": 90, "umbral_correlacion": 0.7}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2151, 1000, 1),
(15, 'VAR_EXOGENA', 'PROCESAMIENTO DE VARIABLES EXÓGENAS', 'Obtiene y procesa variables externas', 3405, 3457, 3352, '0 1 * * *', '{"fuentes": ["API_CLIMA", "API_FESTIVOS", "API_ECONOMIA"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(16, 'VALIDAR_MODELOS', 'VALIDACIÓN CRUZADA DE MODELOS', 'Evalúa y compara el rendimiento de todos los modelos', 3408, 3460, 3354, '0 6 15 * *', '{"k_folds": 5, "metricas": ["MAPE", "RMSE", "MAE", "R2"]}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(17, 'METRICAS_IA', 'MÉTRICAS DE RENDIMIENTO DE IA', 'Genera reporte de métricas de todos los modelos', 3400, 3458, 3354, '0 7 1 * *', '{"incluir_graficos": true, "formato": "PDF"}', NULL, NULL, NULL, NULL, 0, 3, 16, 1, 2151, 1000, 1),
(18, 'REENTRENAR_AUTO', 'REENTRENAMIENTO AUTOMÁTICO DE MODELOS', 'Reentrena automáticamente si el error supera el umbral', 3405, 3459, 3357, NULL, '{"umbral_mape": 10.0, "min_datos_nuevos": 7, "modelos": ["SARIMA", "PROPHET"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(19, 'BACKUP_MODELOS', 'RESPALDO DE MODELOS DE IA', 'Guarda versionado de todos los modelos entrenados', 3402, 3461, 3353, '0 2 * * 0', '{"retencion_version": 10, "ruta_destino": "/backups/models/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(20, 'REPORTE_PREDICCIONES', 'REPORTE DE PREDICCIONES Y PROYECCIONES', 'Reporte consolidado de todas las predicciones de IA', 3400, 3461, 3354, '0 8 1 * *', '{"incluir_graficos": true, "formato": "PDF", "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2151, 1000, 1);

UPDATE tareas_programadas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tareas_programadas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tareas_programadas_tarea_id_seq', COALESCE((SELECT MAX(tarea_id) FROM tareas_programadas), 1));

-- ================================================================================================

CREATE TABLE control_facturas (
    control_factura_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    tipo_comprobante_id INTEGER NOT NULL DEFAULT 1103,  -- 1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO
    numero_actual INTEGER NOT NULL DEFAULT 0,
    numero_inicial INTEGER NOT NULL DEFAULT 1,
    numero_final INTEGER NOT NULL DEFAULT 999999,
    autorizacion VARCHAR(50) NOT NULL,
    cuf VARCHAR(100) NULL,
    cufd VARCHAR(100) NULL,
    cuis VARCHAR(50) NULL,
    codigo_control VARCHAR(20) NULL,
    codigo_qr VARCHAR(100) NULL,
    fecha_autorizacion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    gestion INTEGER NOT NULL,
    estado_operativo_id INTEGER NOT NULL DEFAULT 3300,  -- 3300=EMITIDO, 3301=ANULADO, 3302=ANULADO_PARCIAL
    estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cf_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cf_tipo_comprobante_id FOREIGN KEY (tipo_comprobante_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cf_estado_operativo_id FOREIGN KEY (estado_operativo_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_cf_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cf_numero_actual CHECK (numero_actual >= 0),
    CONSTRAINT chk_cf_numero_inicial CHECK (numero_inicial > 0),
    CONSTRAINT chk_cf_numero_final CHECK (numero_final >= numero_inicial),
    CONSTRAINT chk_cf_numero_actual_range CHECK (numero_actual <= numero_final),
    CONSTRAINT chk_cf_fechas CHECK (fecha_autorizacion <= fecha_vencimiento),
    CONSTRAINT chk_cf_gestion CHECK (gestion >= 2020 AND gestion <= 2100),
    CONSTRAINT chk_cf_autorizacion_not_empty CHECK (TRIM(autorizacion) <> ''),
    CONSTRAINT chk_cf_autorizacion_min_length CHECK (LENGTH(TRIM(autorizacion)) >= 3)
);
CREATE UNIQUE INDEX uix_cf_sucursal_tipo_gestion ON control_facturas (sucursal_id, tipo_comprobante_id, gestion) WHERE estado_operativo_id = 3300 AND estado_id IN (1000, 1002);
CREATE INDEX idx_cf_sucursal_estado ON control_facturas (sucursal_id, estado_operativo_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE control_facturas IS 'Reglas de la tabla - control_facturas
R.0: La tabla control_facturas gestiona los talonarios de facturación y la numeración fiscal, controlando el rango de números y las credenciales (CUF, CUIS) emitidas por el SIN. Su propósito es generar el número de factura de manera atómica y concurrente para cada transacción de venta, garantizando que el correlativo no se repita y se mantenga la integridad fiscal de la empresa. Se conecta directamente con la tabla sucursales.
R.1: El campo estado_operativo_id rige la disponibilidad de la dosificación. Los valores posibles son: 3300=EMITIDO (activo), 3301=ANULADO, 3302=ANULADO_PARCIAL. El sistema cambia automáticamente a ANULADO cuando numero_actual alcanza numero_final o cuando fecha_vencimiento es superada.
R.2: Los campos cuf, cufd, cuis, codigo_control y codigo_qr almacenan credenciales emitidas por el SIN. Ninguno se captura manualmente; la aplicación actúa como visor de los parámetros provistos por los middlewares de facturación.
R.3: Cada sucursal solo puede tener un registro ACTIVO por tipo de comprobante y gestión. El índice uix_cf_sucursal_tipo_gestion garantiza esta unicidad.
R.4: Generación de Número de Factura en el Backend: El sistema genera números de factura de forma atómica y concurrente en el backend, aplicando bloqueo pesimista mediante SELECT ... FOR UPDATE y formateándolos según parámetros corporativos.';

DELETE FROM control_facturas;
ALTER SEQUENCE control_facturas_control_factura_id_seq RESTART WITH 1;

INSERT INTO control_facturas (control_factura_id, sucursal_id, tipo_comprobante_id, numero_actual, numero_inicial, numero_final, autorizacion, cuf, cufd, cuis, codigo_control, codigo_qr, fecha_autorizacion, fecha_vencimiento, gestion, estado_operativo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1103, 0, 1, 999999, '00000000000000000000', NULL, NULL, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 2026, 3300, 1000, 1);

UPDATE control_facturas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE control_facturas SET
    usuario_id_actualizacion = 1,
    fecha_actualizacion = NOW(),
    usuario_id_baja = NULL,
    fecha_baja = NULL
WHERE estado_id = 1002;

SELECT setval('control_facturas_control_factura_id_seq', COALESCE((SELECT MAX(control_factura_id) FROM control_facturas), 1));

-- ================================================================================================

CREATE TABLE kardex (
    kardex_id BIGSERIAL PRIMARY KEY,
    tipo_comprobante_id INTEGER NOT NULL DEFAULT 1103,  -- 1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO
    motivo_anulacion_id INTEGER NOT NULL DEFAULT 2455,  -- 2450=FACTURA_MAL_EMITIDA, 2451=ERROR_DATOS_CLIENTE, 2452=DEVOLUCION_MERCADERIA, 2453=CONTINGENCIA, 2454=OPERACION_NO_CONCRETADA, 2455=NINGUNO
    motivo_devolucion_id INTEGER NULL DEFAULT 3506,  	-- 3500=PRODUCTO_VENCIDO, 3501=PRODUCTO_DAÑADO, 3502=ERROR_PEDIDO, 3503=EXCESO_STOCK, 3504=DESCONTINUADO, 3505=DEVOLUCION_CLIENTE, 3506=NINGUNO, 3507=PRODUCTO_NO_SOLICITADO
	cliente_id BIGINT NOT NULL DEFAULT 1,
    proveedor_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    sucursal_destino_id BIGINT NULL,
    kardex_origen_id BIGINT NULL,
	kardex_pedido_compra_id BIGINT NULL,
    evento_id INTEGER NOT NULL DEFAULT 1052,            -- 1050=COMPRA, 1051=VENTA, 1052=PROFORMA, 1053=EGR_TRASPASO, 1054=ING_TRASPASO, 1055=ANULACION, 1056=AJUSTE_INGRESO, 1057=AJUSTE_EGRESO, 1058=SOLICITUD_COMPRA, 1059=VENTA_RESERVA, 1060=DEV_CLIENTE, 1061=DEV_PROVEEDOR, 1062=ROBO, 1063=PERDIDA_CADUCIDAD, 1064=MERMA_ROTURA, 1065=INVENTARIO_FISICO_SOBRANTE, 1066=INVENTARIO_FISICO_FALTANTE, 1067=CONVERSION_UNIDADES, 1068=SALIDA_MUESTRA_MEDICA, 1069=INGRESO_DONACION, 1070=RETIRO_CUARENTENA
    codigo VARCHAR(60) NOT NULL,
    comprobante VARCHAR(100) NULL,
	comprobante_referencia VARCHAR(100) NULL,
	kardex_referencia_id BIGINT NULL,
    fecha_kardex TIMESTAMPTZ NOT NULL,
	total_compra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_venta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_venta_factura DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_cambio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    saldo_pendiente DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    lugar_entrega VARCHAR(2000) NULL,
    numero_factura VARCHAR(60) NULL,
	nota_credito_debito VARCHAR(60) NULL,
    validez_dias INTEGER NULL,
    fecha_expiracion TIMESTAMPTZ NULL,
	estado_proforma_id INTEGER NOT NULL DEFAULT 4000,				-- 4000=NO_APLICA, 4001=PENDIENTE, 4002=CONVERTIDA, 4003=EXPIRADA, 4004=ANULADA
	tipo_factura_id INTEGER NULL DEFAULT 2353,          			-- 2350=CON_FACTURA, 2351=SIN_FACTURA, 2352=NOTA_CREDITO_DEBITO, 2353=NINGUNO
    estado_traspaso_id INTEGER NOT NULL DEFAULT 2103,   			-- 2100=EN_TRANSITO, 2101=RECIBIDO, 2102=RECHAZADO, 2103=NO_APLICA
    estado_financiero_id INTEGER NOT NULL DEFAULT 2403,				-- 2400=CANCELADO, 2401=PENDIENTE, 2402=PARCIAL, 2403=NINGUNO
	estado_pedido_id INTEGER NULL DEFAULT 2250,  					-- 2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO
	tipo_despacho_id INTEGER NOT NULL DEFAULT 3554,  				-- 3550=VENTA_MOSTRADOR, 3551=DOMICILIO, 3552=RETIRO, 3553=TRANSFERENCIA, 3554=NINGUNO
	estado_id INTEGER NOT NULL DEFAULT 1000,						-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_kar_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_kar_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT fk_kar_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_kar_sucursal_destino_id FOREIGN KEY (sucursal_destino_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_kar_tipo_comprobante_id FOREIGN KEY (tipo_comprobante_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kar_motivo_anulacion_id FOREIGN KEY (motivo_anulacion_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kar_kardex_origen_id FOREIGN KEY (kardex_origen_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_kar_evento_id FOREIGN KEY (evento_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kar_tipo_factura_id FOREIGN KEY (tipo_factura_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kar_estado_traspaso_id FOREIGN KEY (estado_traspaso_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kar_estado_financiero_id FOREIGN KEY (estado_financiero_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_kar_estado_proforma_id FOREIGN KEY (estado_proforma_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kar_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_kar_motivo_devolucion_id FOREIGN KEY (motivo_devolucion_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_kar_kardex_referencia_id FOREIGN KEY (kardex_referencia_id) REFERENCES kardex(kardex_id),
	CONSTRAINT fk_kar_kardex_pedido_compra_id FOREIGN KEY (kardex_pedido_compra_id) REFERENCES kardex(kardex_id)
);
CREATE UNIQUE INDEX uix_kar_codigo ON kardex (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kar_cliente_id ON kardex (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kar_proveedor_id ON kardex (proveedor_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kar_numero_factura ON kardex (numero_factura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kar_sucursal_fecha ON kardex (sucursal_id, fecha_kardex DESC, evento_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kar_estado_financiero ON kardex (estado_financiero_id, sucursal_id) WHERE estado_id IN (1000, 1002) AND estado_financiero_id IN (3501, 3502);
CREATE INDEX idx_kar_estado_traspaso ON kardex (sucursal_destino_id, estado_traspaso_id) WHERE evento_id IN (1053, 1054) AND estado_traspaso_id = 2100;

COMMENT ON TABLE kardex IS 'Reglas de la tabla - kardex
R.0: La tabla kardex es el registro maestro de todas las transacciones que afectan el inventario y la operación comercial, como compras, ventas, traspasos y ajustes. Su propósito es centralizar y dar trazabilidad a cada movimiento, sirviendo como la cabecera que agrupa los detalles de los productos y que orquesta el flujo de caja, la facturación y la generación de documentos históricos. Se conecta directamente con las tablas clientes, proveedores, sucursales, kardex_productos, lotes_productos, planes_pagos y historicos.
R.1: Control de Estados (estado_id vs estado_financiero_id). estado_id controla el ciclo de vida lógico del registro (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO). estado_financiero_id aplica exclusivamente a créditos con proveedores (2400=CANCELADO, 2401=PENDIENTE, 2402=PARCIAL). CANCELADO obliga a que saldo_pendiente = 0.00.
R.2: Comportamiento y Obligatoriedad por Evento. El campo evento_id define la naturaleza de la transacción: COMPRA (1050)/DEVOLUCION_COMPRA/SOLICITUD_COMPRA (1058) obliga a seleccionar un proveedor; VENTA (1051)/DEVOLUCION_VENTA obliga a seleccionar un cliente; ANULACION (1055) requiere obligatoriamente un motivo_anulacion_id y muta el estado_id a 1003 (ANULADO), revirtiendo de forma automática el stock de los lotes asociados; PROFORMA (1052) requiere validez_dias; TRANSFERENCIA_SUCURSAL (1053/1054) genera pares de registros vinculados.
R.3: Gestión y Control del Correlativo Único (codigo). El campo codigo es inmutable en el frontend. El backend lo calcula de forma automática bajo el patrón [PREFIJO]-[SUCURSAL_ID]-[GESTION_ANUAL]-[CORRELATIVO], consumiendo los prefijos almacenados en el campo prefijo de la tabla kardex.
R.4: Reglas Fiscales y de Facturación. numero_factura se genera automáticamente SOLO para los eventos VENTA (1051) y DEVOLUCION_VENTA que tengan al menos un detalle con tipo_venta = ''CON_FACTURA'' en kardex_productos. Se toma de control_facturas incrementando numero_actual de forma atómica.
R.5: Automatización de Proformas y Temporalidad. Una tarea programada evalúa diariamente los registros. Si fecha_kardex + validez_dias es superada, el estado_id muta a HISTORICO. El frontend provee un botón "Transformar en Venta" que hereda los datos de la proforma vigente.
R.6: Logística de Entregas y Ajustes Internos. Para eventos VENTA (1051) y PROFORMA (1052), lugar_entrega es obligatorio si se activa el indicador de despacho a domicilio. Mermas y Ajustes restringen cliente_id = 1 y proveedor_id = 1, y exigen justificación en comprobante.
R.7: Gestión Inter-Sucursales y Recepción Física. Al emitir una TRANSFERENCIA_SUCURSAL, el registro destino nace con estado_id = 1000 (ACTIVO) pero el stock en destino solo se incrementa al presionar "Confirmar Recepción".
R.8: Automatización de Expiración de Reservas (TTL). El sistema ejecuta de forma periódica (mediante la función liberar_reservas_expiradas() o tareas en el backend) la revisión de los registros con evento_id = 1059 (VENTA_RESERVA) y estado_proforma_id = 4001 (PENDIENTE) cuya fecha_expiracion sea menor a la fecha actual. Al cumplirse, la función muta el estado a 4003 (EXPIRADA) y genera un movimiento compensatorio de tipo LIBERACION_RESERVA (1070) para reintegrar de forma transparente el inventario al stock disponible, evitando bloqueos indefinidos.
R.9: Validación de Crédito a Proveedores. Al registrar una COMPRA (1050) con estado_financiero_id = 2401 (PENDIENTE) o 2402 (PARCIAL), el backend debe validar que el proveedor tenga registros activos y que la empresa cuente con la capacidad crediticia configurada en parametros_globales.
R.10: Validación del Formato del Número de Factura. numero_factura debe contener solo dígitos numéricos (0-9). La longitud debe coincidir con el parámetro global ''longitud_numero_factura'' (por defecto 7 dígitos).
R.11: Actualización Atómica del Correlativo. Al generar un número de factura, el backend debe incrementar numero_actual en control_facturas en la misma transacción donde se inserta el registro en kardex.
R.12: Validación de Stock en Ventas. Al registrar una venta, el sistema debe validar que cantidad_salida <= cantidad_actual del lote correspondiente. Si el stock es insuficiente, debe rechazar la transacción con el mensaje: "Stock insuficiente. Disponible: X.XX, Solicitado: Y.YY".
R.13: Control de Mermas. Las mermas mensuales por producto no pueden superar el 5% del stock total del mes anterior. Se exige justificación obligatoria en el campo comprobante y, si se excede el umbral, el backend debe generar una alerta automática al gerente requiriendo autorización especial.
R.14: Tipo de Factura. tipo_factura_id utiliza el dominio TipoFacturaID (2350-2352): CF (2350) para factura con derecho a crédito fiscal, SF (2351) para factura sin derecho a crédito fiscal, NCD (2352) para nota de crédito-débito. Este campo complementa a tipo_comprobante_id y numero_factura para identificar el tipo de documento fiscal emitido.
R.15: Estado de Traspaso. estado_traspaso_id utiliza el dominio EstadoTraspasoID (2100-2103): EN_TRANSITO (2100) para mercancía en movimiento entre sucursales, RECIBIDO (2101) cuando la sucursal destino confirma la recepción, RECHAZADO (2102) cuando el traspaso es cancelado o rechazado, NO_APLICA (2103) para eventos que no son traspasos. Este campo SOLO aplica para eventos de traspaso (evento_id = 1053 EGR_TRASPASO o 1054 ING_TRASPASO). Para otros eventos, debe ser 2103.
R.16: Estado de Pedido (Solicitud de Compra). estado_pedido_id utiliza el dominio EstadoPedidoID (2250-2256) exclusivamente para el evento SOLICITUD_COMPRA (1058). Controla el ciclo de vida del pedido: COTIZADO (2250), APROBADO (2251), EN_RUTA (2252), RECIBIDO (2253), PARCIAL (2254), RECHAZADO (2255), CANCELADO (2256). Para cualquier otro evento debe ser NULL.
R.17: Tipo de Despacho. tipo_despacho_id utiliza el dominio TipoDespachoID (3550-3553) exclusivamente para el evento VENTA (1051). Define la modalidad de entrega: VENTA_MOSTRADOR (3550), DOMICILIO (3551), RETIRO (3552), TRANSFERENCIA (3553). Para eventos que no son ventas, el valor por defecto es VENTA_MOSTRADOR (3550).
R.18: Copia del límite de crédito del cliente al momento de la venta.
R.19: El campo comprobante_referencia hace referencia al comprobante en devoluciones. Mismo caso para kardex_referencia_id hace referencia a kardex_id.
R.20: Trazabilidad y Conversión de Solicitudes de Compra. Cuando una solicitud de compra (evento_id = 1058 SOLICITUD_COMPRA) con estado_pedido_id = 2251 (APROBADO) es procesada y transformada en una transacción de compra formal (evento_id = 1050 COMPRA), el backend debe establecer obligatoriamente la relación cruzada asignando el ID de la compra en el campo kardex_pedido_compra_id del registro de origen. Una solicitud aprobada que ya posea una referencia de compra vinculada no podrá ser utilizada nuevamente para generar otra compra, previniendo duplicidades y asegurando la auditoría de extremo a extremo entre el requerimiento y la adquisición.
R.21: nota_credito_debito se usa solo en DEVOLUCION_CLIENTE (evento_id = 1060). Almacena el número secuencial o código de autorización de la Nota de Crédito (o Nota de Débito) generada electrónicamente para respaldar la devolución ante el cliente y ante el ente regulador de impuestos (como el SIN). Diferencia clave: Mientras que el campo comprobante_referencia o kardex_referencia_id apunta al documento o movimiento original (la factura o venta vieja que le dio vida a la operación), el campo nota_credito_debito almacena el número del nuevo documento legal que formaliza la devolución.
R.22: fecha_expiracion Fecha y hora exacta de expiración (calculada a partir de fecha_kardex + validez_dias. Permite que el job diario o el backend evalúe de forma precisa el TTL de la reserva sin depender solo de días enteros.
R.23: Comportamiento Transaccional del Evento PROFORMA (1052). Al registrar una proforma, se genera la cabecera y el detalle en kardex_productos con fines estrictamente informativos, de impresión y de análisis estadístico. El backend NO debe alterar las columnas de stock real ni el stock disponible de los lotes afectados. Requiere obligatoriamente un valor en validez_dias para calcular la fecha_expiracion y establece estado_proforma_id = 4001 (PENDIENTE).
R.24: Comportamiento Transaccional del Evento VENTA_RESERVA (1059). Al registrar una reserva, el sistema aparta temporalmente el inventario disminuyendo el stock disponible de los lotes afectados (stock_disponible = stock_actual - cantidad_reservada), pero NO descarga el stock físico definitivo de la bodega. Su vigencia está gobernada por fecha_expiracion. Si transcurre el TTL sin conversión, un proceso automático ejecuta un evento de LIBERACION_RESERVA (1070) para reintegrar el stock al saldo disponible y muta el estado_proforma_id a 4003 (EXPIRADA).
R.25: Regla de Conversión de Proforma/Reserva a VENTA (1051). El backend provee un servicio atómico de transformación que ejecuta las siguientes acciones en una sola transacción:
- 1. Inserta un nuevo registro en kardex con evento_id = 1051 (VENTA), vinculando el campo kardex_origen_id con el ID de la proforma o reserva original.
- 2. Inserta los ítems correspondientes en kardex_productos, ejecutando la descarga definitiva del stock físico de los lotes.
- 3. Actualiza el registro de origen cambiando su estado_proforma_id a 4002 (CONVERTIDA) e invoca la lógica de compensación de stock reservado si el evento de origen fue una VENTA_RESERVA (1059), previniendo cualquier doble afectación o descuento duplicado en inventarios.
Reglas de la tabla - kardex (Sección Compras)
R.26: Validación de Proveedor Activo. Al registrar una COMPRA (evento_id = 1050) o SOLICITUD_COMPRA (1058), el proveedor debe estar ACTIVO (estado_id = 1000). Si el proveedor está BORRADO o HISTORICO, la operación debe ser rechazada.
R.27: Validación de Rating de Proveedor. Si el proveedor tiene rating_calidad_id = 2050 (PESIMO), el sistema debe generar una alerta (nivel_critico_id = 2901) y requerir autorización especial para la compra.
R.28: Control de Solicitudes de Compra Duplicadas. Una solicitud de compra (evento_id = 1058) solo puede ser convertida a compra (evento_id = 1050) una única vez. Si ya tiene un kardex_pedido_compra_id vinculado, la conversión debe ser bloqueada.
R.29: Actualización Automática de Estado de Pedido. Al insertar detalles en kardex_productos para una SOLICITUD_COMPRA (1058), el sistema debe actualizar estado_pedido_id automáticamente:
- Si todos los ítems recibidos completamente → 2253 (RECIBIDO)
- Si algunos ítems recibidos parcialmente → 2254 (PARCIAL)
- Si ninguno recibido → 2252 (EN_RUTA)
R.30: Validación de Fechas de Vencimiento en Compras. Al registrar una COMPRA (1050), el sistema debe validar que fecha_vencimiento de cada lote sea mayor a CURRENT_DATE + 30 días (mínimo). Si es menor, debe generar una advertencia.
R.31: Control de Monto Mínimo de Compra. El sistema debe validar que total_compra >= proveedores.monto_minimo_compra.
R.32: Política de Mermas por Proveedor. Las mermas mensuales por proveedor no pueden superar el 5% del total comprado en el mes. Si se supera, generar alerta de calidad y reducir rating.
R.33: Validación de Estado Financiero. Para COMPRA (1050):
- Si estado_financiero_id = 2400 (CANCELADO), total_pagado = total_compra.
- Si estado_financiero_id = 2401 (PENDIENTE), total_pagado = 0.
- Si estado_financiero_id = 2402 (PARCIAL), 0 < total_pagado < total_compra.
R.34: Control de Límite de Crédito. Al registrar una COMPRA (1050) con estado_financiero_id IN (2401, 2402), el sistema debe validar que el saldo total adeudado al proveedor (suma de saldo_pendiente de compras ACTIVAS) no exceda el límite de crédito configurado.
R.35: Validación de Devolución a Proveedor (1061):
- kardex_referencia_id debe apuntar a la compra original (1050).
- motivo_devolucion_id debe ser distinto de 3506 (NINGUNO).
- total_compra de la devolución debe ser <= total_compra de la compra original.
- El sistema debe generar una nota de crédito si aplica.
R.36: Generación de Número de Solicitud. Para SOLICITUD_COMPRA (1058), el backend debe generar un número de solicitud con formato: SOL-[SUCURSAL_ID]-[GESTION]-[CORRELATIVO].';

DELETE FROM kardex;
ALTER SEQUENCE kardex_kardex_id_seq RESTART WITH 1;

INSERT INTO kardex (kardex_id, tipo_comprobante_id, cliente_id, proveedor_id, sucursal_id, sucursal_destino_id, kardex_origen_id, evento_id, codigo, comprobante, fecha_kardex, total_compra, total_venta, total_venta_factura, total_pagado, total_cambio, saldo_pendiente, lugar_entrega, numero_factura, validez_dias, tipo_factura_id, estado_traspaso_id, estado_financiero_id, estado_id, usuario_id_registro) VALUES
(1, 1103, 1, 1, 1, NULL, NULL, 1050, 'INI-1-2026-00000000', 'REGISTRO COMODIN SISTEMA', CURRENT_TIMESTAMP, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, 2353, 2103, 2403, 1);

UPDATE kardex SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE kardex SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('kardex_kardex_id_seq', COALESCE((SELECT MAX(kardex_id) FROM kardex), 1));

-- ================================================================================================

CREATE TABLE ordenes_compra (
    orden_compra_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
    proveedor_id BIGINT NOT NULL,
    numero_orden VARCHAR(50) NOT NULL,
    fecha_orden DATE NOT NULL,
    fecha_entrega_estimada DATE NULL,
    fecha_entrega_real DATE NULL,
    estado_pedido_id INTEGER NOT NULL DEFAULT 2250,					-- 2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO
    observaciones VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,						-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_oc_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_oc_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT fk_oc_estado_pedido_id FOREIGN KEY (estado_pedido_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_oc_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id)
);
CREATE UNIQUE INDEX uix_oc_numero_orden ON ordenes_compra (numero_orden) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE ordenes_compra IS 'Reglas de la tabla - ordenes_compra
R.0: La tabla ordenes_compra registra las órdenes de compra emitidas a los proveedores para el abastecimiento de productos, enlazándose directamente con la tabla kardex y la tabla proveedores. Su propósito es controlar el ciclo de vida del pedido, desde su cotización hasta su recepción o anulación.
R.1: El número de orden (numero_orden) debe ser único para registros activos o históricos (estado_id IN (1000, 1002)), evitando duplicidades en la numeración oficial de compras.
R.2: El estado del pedido se controla mediante estado_pedido_id, vinculándose al dominio de estados de pedido (2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO).
R.3: Los estados de los registros se controlan mediante estado_id, vinculados al dominio de estados estándar (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO).
R.4: Cada orden de compra está vinculada obligatoriamente a un registro en kardex mediante fk_oc_kardex_id y a un proveedor mediante fk_oc_proveedor_id.';

DELETE FROM ordenes_compra;
ALTER SEQUENCE ordenes_compra_orden_compra_id_seq RESTART WITH 1;

INSERT INTO ordenes_compra (orden_compra_id, kardex_id, proveedor_id, numero_orden, fecha_orden, fecha_entrega_estimada, fecha_entrega_real, estado_pedido_id, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'OC-000000', CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 2253, 'ORDEN DE COMPRA COMODÍN PARA REGISTROS INICIALES', 1000, 1);

UPDATE ordenes_compra SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ordenes_compra SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1000;

SELECT setval('ordenes_compra_orden_compra_id_seq', COALESCE((SELECT MAX(orden_compra_id) FROM ordenes_compra), 1));

-- ================================================================================================

CREATE TABLE instituciones (
    institucion_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    institucion VARCHAR(150) NOT NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(60) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_inst_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_inst_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_inst_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_inst_codigo_min_length CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_inst_institucion_not_empty CHECK (TRIM(institucion) <> ''),
    CONSTRAINT chk_inst_institucion_mayusculas CHECK (institucion = UPPER(institucion)),
    CONSTRAINT chk_inst_institucion_min_length CHECK (LENGTH(TRIM(institucion)) >= 3)
);
CREATE UNIQUE INDEX uix_inst_codigo ON instituciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_inst_institucion ON instituciones (institucion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE instituciones IS 'Reglas de la tabla - instituciones
R.1: La tabla instituciones almacena el catálogo de centros de salud, clínicas y hospitales donde trabajan los médicos que emiten recetas. Su propósito es normalizar y consolidar la información de las instituciones médicas para reportes y análisis gerenciales.
R.2: codigo es un identificador alfanumérico único de la institución, ingresado manualmente por el administrador. Debe estar en mayúsculas y tener al menos 3 caracteres.
R.3: nombre debe estar en mayúsculas y ser único para registros activos o históricos.
R.4: direccion y telefono son campos opcionales que permiten registrar información de contacto para futuros módulos de comunicación o verificación de institucion.
R.5: El registro con institucion_id = institucionmbre = ''NINGUNO / OTRO'' es el registro comodín que actúa como valor predeterminado para las FK que requieran una institución de referencia. Su estado_id = 1002 lo mantiene en estado HISTORICO, excluyéndolo de los combos operativos pero preservando la integridad referencial.';

DELETE FROM instituciones;
ALTER SEQUENCE instituciones_institucion_id_seq RESTART WITH 1;

INSERT INTO instituciones (institucion_id, codigo, institucion, direccion, telefono, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, 1000, 1);

UPDATE instituciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE instituciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('instituciones_institucion_id_seq', COALESCE((SELECT MAX(institucion_id) FROM instituciones), 1));

-- ================================================================================================

CREATE TABLE especialidades (
    especialidad_id BIGSERIAL PRIMARY KEY,
    especialidad VARCHAR(150) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_esp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_esp_especialidad_not_empty CHECK (TRIM(especialidad) <> ''),
    CONSTRAINT chk_esp_especialidad_mayusculas CHECK (especialidad = UPPER(especialidad))
);
CREATE UNIQUE INDEX uix_esp_especialidad ON especialidades (especialidad) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE especialidades IS 'Reglas de la tabla - especialidades
R.0: La especialidad se almacena en mayúsculas para garantizar uniformidad en la búsqueda y agrupación.';

DELETE FROM especialidades;
ALTER SEQUENCE especialidades_especialidad_id_seq RESTART WITH 1;

INSERT INTO especialidades (especialidad_id, especialidad, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 1000, 1);

UPDATE especialidades SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE especialidades SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('especialidades_especialidad_id_seq', COALESCE((SELECT MAX(especialidad_id) FROM especialidades), 1));

-- ================================================================================================

CREATE TABLE medicos (
    medico_id BIGSERIAL PRIMARY KEY,
    medico VARCHAR(150) NOT NULL,
    matricula VARCHAR(50) NOT NULL,
    especialidad_id BIGINT NOT NULL DEFAULT 1,
    telefono VARCHAR(60) NULL,
    email VARCHAR(100) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_med_especialidad_id FOREIGN KEY (especialidad_id) REFERENCES especialidades(especialidad_id),
    CONSTRAINT fk_med_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_med_medico_not_empty CHECK (TRIM(medico) <> ''),
    CONSTRAINT chk_med_medico_min_length CHECK (LENGTH(TRIM(medico)) >= 3),
    CONSTRAINT chk_med_matricula_not_empty CHECK (TRIM(matricula) <> ''),
    CONSTRAINT chk_med_matricula_min_length CHECK (LENGTH(TRIM(matricula)) >= 3),
    CONSTRAINT chk_med_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);
CREATE UNIQUE INDEX uix_med_medico ON medicos (medico) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_med_matricula ON medicos (matricula) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_med_especialidad ON medicos (especialidad_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_med_estado ON medicos (estado_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE medicos IS 'Reglas de la tabla - medicos
R.0: La tabla medicos constituye el catálogo maestro de profesionales de la salud que prestan servicios en la farmacia, almacenando información personal, credenciales profesionales y datos de contacto. Su función principal es respaldar la prescripción de medicamentos, la emisión de recetas y la trazabilidad de los tratamientos médicos, garantizando la integridad y legalidad de las transacciones farmacéuticas. Se conecta directamente con las tablas recetas, historial_clinico y prescripciones.
R.1: medico almacena el nombre completo del profesional de la salud, incluyendo título profesional cuando corresponda.
R.2: matricula corresponde al número de registro profesional emitido por la autoridad competente (ej. Colegio Médico), es un identificador único para cada profesional.';

DELETE FROM medicos;
ALTER SEQUENCE medicos_medico_id_seq RESTART WITH 1;

INSERT INTO medicos (medico_id, medico, matricula, especialidad_id, telefono, email, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'MAT-000', 1, NULL, NULL, 1000, 1);

UPDATE medicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE medicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('medicos_medico_id_seq', COALESCE((SELECT MAX(medico_id) FROM medicos), 1));

-- ================================================================================================

CREATE TABLE recetas (
    receta_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
    cliente_id BIGINT NOT NULL,
    sucursal_id BIGINT NOT NULL,
    medico_id BIGINT NOT NULL DEFAULT 1,
    institucion_id BIGINT NOT NULL DEFAULT 1,
    tipo_receta_id INTEGER NOT NULL DEFAULT 3853,  -- 3850=SIMPLE, 3851=ARCHIVADA, 3852=VALADA, 3853=NINGUNO
    numero_receta VARCHAR(60) NOT NULL,
    fecha_emision DATE NOT NULL,
    diagnostico VARCHAR(250) NULL,
    receta_pdf VARCHAR(100) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_rec_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_rec_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_rec_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_rec_medico_id FOREIGN KEY (medico_id) REFERENCES medicos(medico_id),
    CONSTRAINT fk_rec_institucion_id FOREIGN KEY (institucion_id) REFERENCES instituciones(institucion_id),
    CONSTRAINT fk_rec_tipo_receta_id FOREIGN KEY (tipo_receta_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_rec_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_rec_numero_receta_not_empty CHECK (TRIM(numero_receta) <> ''),
    CONSTRAINT chk_rec_numero_receta_min_length CHECK (LENGTH(TRIM(numero_receta)) >= 3),
    CONSTRAINT chk_rec_fecha_emision_valida CHECK (fecha_emision <= CURRENT_DATE)
);
CREATE UNIQUE INDEX uix_rec_numero_receta ON recetas (numero_receta) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_rec_kardex_cliente_medico_fecha ON recetas (kardex_id, cliente_id, medico_id, fecha_emision) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE recetas IS 'Reglas de la tabla - recetas
R.0: La tabla recetas constituye el registro maestro de prescripciones médicas emitidas en la farmacia, almacenando la información completa de cada receta incluyendo el médico, paciente, institución y diagnóstico asociado. Su función principal es respaldar la dispensación de medicamentos, garantizar la trazabilidad de los tratamientos y cumplir con los requisitos legales de control de medicamentos controlados. Se conecta directamente con kardex, clientes, sucursales, medicos, instituciones y dominios.
R.1: numero_receta es un identificador alfanumérico único que puede ser generado automáticamente por el sistema o ingresado manualmente desde el formulario, según la configuración de la sucursal.
R.2: fecha_emision registra la fecha en que el médico emitió la receta. La restricción chk_rec_fecha_emision_valida garantiza que no sea una fecha futura.
R.3: receta_pdf almacena el nombre del archivo PDF que contiene la imagen digitalizada o escaneada de la receta física. El formato debe ser ''.pdf'' y el nombre solo debe contener caracteres alfanuméricos, guiones o guiones bajos.
R.4: tipo_receta_id clasifica la receta según su régimen legal: SIMPLE (medicamentos comunes), ARCHIVADA (psicotrópicos con retención obligatoria) o VALADA (estupefacientes con control estricto).
R.5: El diagnóstico es un campo descriptivo que puede contener el código CIE-10 o una descripción textual de la condición del paciente.';

DELETE FROM recetas;
ALTER SEQUENCE recetas_receta_id_seq RESTART WITH 1;

INSERT INTO recetas (receta_id, kardex_id, cliente_id, sucursal_id, medico_id, institucion_id, tipo_receta_id, numero_receta, fecha_emision, diagnostico, receta_pdf, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 3853, 'REC-000', '2024-01-01', NULL, NULL, 1000, 1);

UPDATE recetas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE recetas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('recetas_receta_id_seq', COALESCE((SELECT MAX(receta_id) FROM recetas), 1));

-- ================================================================================================

CREATE TABLE lotes_productos (
    lote_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    codigo_lote VARCHAR(50) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    cantidad_inicial DECIMAL(12,2) NOT NULL,
    cantidad_actual DECIMAL(12,2) NOT NULL,
    cantidad_reservada DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    precio_costo DECIMAL(12,2) NOT NULL,
    fecha_fabricacion DATE NULL,
    lote_proveedor VARCHAR(50) NULL,
    ubicacion_id BIGINT NULL,
    ultimo_movimiento TIMESTAMPTZ NULL,
    rating_calidad_id INTEGER DEFAULT 2055,             -- 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
    estado_lote_id INTEGER NOT NULL DEFAULT 2503,       -- 2500=VIGENTE, 2501=VENCIDO, 2502=AGOTADO, 2503=NINGUNO
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_lp_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_lp_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_lp_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_lp_estado_lote_id FOREIGN KEY (estado_lote_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_lp_rating_calidad_id FOREIGN KEY (rating_calidad_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_lp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_lp_codigo_lote CHECK (LENGTH(TRIM(codigo_lote)) >= 3),
    CONSTRAINT chk_lp_fecha_vencimiento CHECK (fecha_vencimiento > '2000-01-01'),
    CONSTRAINT chk_lp_cantidad_inicial CHECK (cantidad_inicial > 0),
    CONSTRAINT chk_lp_cantidad_actual CHECK (cantidad_actual >= 0),
    CONSTRAINT chk_lp_cantidad_reservada CHECK (cantidad_reservada >= 0),
    CONSTRAINT chk_lp_precio_costo CHECK (precio_costo >= 0),
    CONSTRAINT chk_lp_cantidad_coherencia CHECK (cantidad_actual <= cantidad_inicial),
    CONSTRAINT chk_lp_cantidad_coherencia_v2 CHECK (cantidad_actual + cantidad_reservada <= cantidad_inicial)
);

CREATE UNIQUE INDEX uix_lp_codigo_lote ON lotes_productos (producto_id, codigo_lote) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lp_producto_id ON lotes_productos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lp_fecha_vencimiento ON lotes_productos (fecha_vencimiento) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lp_ubicacion_id ON lotes_productos (ubicacion_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE lotes_productos IS 'Reglas de la tabla - lotes_productos
R.0: La tabla lotes_productos es el núcleo del control de inventario físico, representando la llegada de una cantidad de un producto con un precio de costo, fecha de vencimiento y una existencia inicial. Su propósito es permitir la trazabilidad FIFO (primero en entrar, primero en salir), controlar el stock por lote, gestionar el costo de venta y la ubicación física, así como las alertas de vencimiento y agotamiento de inventario. Se conecta directamente con las tablas productos, kardex, ubicaciones y dominios.
R.1: Gestión de Stock y Reservas. cantidad_actual representa el stock disponible para venta o despacho. cantidad_reservada representa el stock apartado para ventas en proceso o reservas (VENTA_RESERVA). El stock total del lote se define como stock_total = cantidad_actual + cantidad_reservada, y el sistema valida estrictamente que stock_total <= cantidad_inicial.
R.2: Control de Stock por Lote en Ventas. Al registrar una venta, el backend debe validar que la cantidad solicitada <= cantidad_actual del lote. Si el stock disponible es insuficiente, debe rechazar la transacción con el mensaje: "Stock insuficiente en lote X. Disponible: Y.YY, Solicitado: Z.ZZ".
R.3: Registro Inicial Comodín. El lote con lote_id = 1 es un registro histórico con cantidad_actual = 0, estado_lote_id = 2503 (NINGUNO) y estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un lote de referencia.
R.4: Precios de Lote vs Producto. precio_costo es específico del lote y puede diferir del precio base del producto (productos.pcompra). El sistema utiliza el precio_costo del lote para calcular el costo_venta en kardex_productos. Los precios de venta se gestionan en productos (catálogo) y kardex_productos (transaccional).
R.5: Control de Vencimientos y Calidad. El frontend debe mostrar alertas visuales cuando fecha_vencimiento esté próxima según los parámetros globales ''dias_alerta_vencimiento_critico'' (15 días), ''dias_alerta_vencimiento_alta'' (30 días) y ''dias_alerta_vencimiento_media'' (60 días). El campo rating_calidad_id utiliza el dominio CalidadRatingID (2050-2054, con 2055 por defecto como NINGUNO) para el control de calidad interna.
R.6: Inmutabilidad del Código de Lote y Trazabilidad del Proveedor. codigo_lote se genera automáticamente por el backend al registrar una compra o ajuste de inventario y no puede ser modificado por el usuario (patrón: [PREFIJO]-[PRODUCTO_ID]-[FECHA]-[CORRELATIVO]). El campo lote_proveedor almacena el código de lote original emitido por el proveedor para facilitar la trazabilidad externa.
R.7: Bloqueo de Lotes Agotados y Estados Automáticos. Un lote con cantidad_actual = 0 se bloquea automáticamente para nuevas ventas (estado_lote_id = 2502 AGOTADO), pero permanece visible en el histórico. Solo puede reactivarse mediante un ajuste que incremente cantidad_actual. Adicionalmente, el backend gestiona la actualización automática a VENCIDO (2501) si fecha_vencimiento < CURRENT_DATE.
R.8: Fuente de Verdad del Costo. El campo precio_costo almacena el costo de adquisición del lote en el momento de su creación. Este valor es la fuente de verdad para el costo de venta y se copia al campo pcompra de kardex_productos al momento de cada transacción que afecte este lote.
R.9: Ubicación y Auditoría de Movimientos. ubicacion_id indica el depósito físico actual del lote y puede ser NULL si se encuentra en tránsito o sin asignar. El backend es responsable de mantener actualizados los campos ultimo_movimiento y fecha_actualizacion ante cualquier cambio de estado o stock.';

DELETE FROM lotes_productos;
ALTER SEQUENCE lotes_productos_lote_id_seq RESTART WITH 1;

INSERT INTO lotes_productos (lote_id, producto_id, kardex_id, codigo_lote, fecha_vencimiento, cantidad_inicial, cantidad_actual, cantidad_reservada, precio_costo, fecha_fabricacion, lote_proveedor, ubicacion_id, rating_calidad_id, estado_lote_id, estado_id, usuario_id_registro)
VALUES (1, 1, 1, 'NINGUNO', '2099-12-31', 1.00, 0.00, 0.00, 0.00, NULL, NULL, 1, 2055, 2503, 1000, 1);

UPDATE lotes_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE lotes_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('lotes_productos_lote_id_seq', COALESCE((SELECT MAX(lote_id) FROM lotes_productos), 1));

-- ================================================================================================

CREATE TABLE kardex_productos (
    kardex_producto_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    lote_id BIGINT NOT NULL DEFAULT 1,
    presentacion_id BIGINT NOT NULL DEFAULT 1,
    tipo_pago_id BIGINT NOT NULL DEFAULT 1400,  	-- 1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO
    tipo_venta_id INTEGER NOT NULL DEFAULT 1350,  	-- 1350=NINGUNO, 1351=CON_FACTURA, 1352=SIN_FACTURA
	kardex_producto_origen_id BIGINT NULL,
    cantidad DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    cantidad_unidad_base DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    cantidad_salida DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    pcompra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    factor_venta DECIMAL(12,2) NOT NULL DEFAULT 1.00,
    factor_facturacion DECIMAL(12,2) NOT NULL DEFAULT 1.00,
    precio_venta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    precio_venta_factura DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    costo_venta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuento DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_kp_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_kp_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_kp_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_kp_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
    CONSTRAINT fk_kp_presentacion_id FOREIGN KEY (presentacion_id) REFERENCES presentaciones(presentacion_id),
    CONSTRAINT fk_kp_tipo_pago_id FOREIGN KEY (tipo_pago_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_kp_tipo_venta_id FOREIGN KEY (tipo_venta_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_kp_kardex_producto_origen_id FOREIGN KEY (kardex_producto_origen_id) REFERENCES kardex_productos(kardex_producto_id),
	CONSTRAINT fk_kp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_kp_pcompra CHECK (pcompra >= 0),
    CONSTRAINT chk_kp_factor_venta CHECK (factor_venta >= 0),
    CONSTRAINT chk_kp_factor_facturacion CHECK (factor_facturacion >= 0),
    CONSTRAINT chk_kp_precio_venta CHECK (precio_venta >= 0),
    CONSTRAINT chk_kp_precio_venta_factura CHECK (precio_venta_factura >= 0),
    CONSTRAINT chk_kp_costo_venta CHECK (costo_venta >= 0),
    CONSTRAINT chk_kp_descuento CHECK (descuento >= 0),
	CONSTRAINT chk_kp_cantidades CHECK (
        (cantidad >= 0 AND cantidad_salida = 0) OR
        (cantidad = 0 AND cantidad_salida >= 0) OR
        (cantidad = 0 AND cantidad_salida = 0)
    )
);
CREATE UNIQUE INDEX uix_kp_kardex_producto_lote_unique ON kardex_productos (kardex_id, producto_id, lote_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kp_kardex_id ON kardex_productos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kp_tipo_venta_fecha ON kardex_productos (tipo_venta_id, fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kp_lote_sucursal ON kardex_productos (lote_id, sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kp_detalle_origen ON kardex_productos (kardex_producto_origen_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE kardex_productos IS 'Reglas de la tabla - kardex_productos
R.0: La tabla kardex_productos es el detalle transaccional de cada movimiento de inventario, registrando las cantidades de entrada o salida de un producto específico, su precio y el lote afectado. Su propósito es registrar el impacto cuantitativo y financiero de las transacciones en el inventario, permitiendo la actualización del stock, el cálculo del costo de venta y la auditoría detallada de cada ítem de compra o venta. Se conecta directamente con las tablas kardex, productos, lotes_productos, presentaciones y dominios para tipos de pago y venta.
R.1: Destino de Flujos de Inventario. Para movimientos de entrada (COMPRA, TRANSFERENCIA_IN) las unidades se guardan exclusivamente en cantidad y cantidad_salida se fija en 0.00. Para movimientos de salida (VENTA, PROFORMA, TRANSFERENCIA_OUT, MERMA) las unidades se registran en cantidad_salida y cantidad se fija en 0.00. La restricción chk_kp_cantidades valida esta condición.
R.2: Control de Equivalencia de Unidades. cantidad_unidad_base almacena el subtotal físico del ítem transformado matemáticamente a su mínima unidad de fraccionamiento comercial (ej. tabletas sueltas o mililitros). Este valor es inyectado por el backend multiplicando la cantidad física por el factor del empaque para actualizar en tiempo real el stock consolidado de los lotes.
R.3: Metodología de Costeo Operativo. costo_venta registra el valor real de adquisición de las salidas y se determina en el backend calculando el precio de compra de origen indexado según la fracción del producto despachado. Este campo permanece estrictamente oculto para los cajeros en las vistas de ventas y se reserva de manera exclusiva para reportes gerenciales de margen y rentabilidad líquida.
R.4: Determinación de Precios por Tipo de Venta. Si tipo_venta_id = 1351 (CON FACTURA), la venta se tasa sobre precio_venta_factura y se bloquea la modificación del precio base. Si tipo_venta_id = 1352 (SIN FACTURA), los cálculos parciales se realizan sobre precio_venta. Cualquier deducción registrada en descuento se substrae del subtotal neto antes de consolidar la fila.
R.5: Cuando la cabecera transaccional corresponda al evento PROFORMA (1052), el sistema debe forzar tipo_pago_id = 1400 (NINGUNO) y tipo_venta_id = 1350 (NINGUNO) en los detalles, ya que una proforma no implica un cobro efectivo ni una venta formal.
R.6: Control de Conversión de Unidades. cantidad_unidad_base debe calcularse multiplicando la cantidad por el factor_conversion registrado en la tabla conversiones_unidad para el producto y las unidades involucradas.
R.7: Registro Inicial Comodín. El registro con kardex_producto_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un detalle de kardex de referencia.
R.8: Trazabilidad y Conversión a Nivel de Detalle (kardex_producto_origen_id). Al ejecutar el servicio de conversión de una proforma o venta-reserva (evento_id = 1059) hacia una venta definitiva (evento_id = 1051), el backend debe vincular obligatoriamente cada fila insertada en kardex_productos con su respectivo ítem de origen mediante el campo kardex_producto_origen_id. Esto permite auditar los precios congelados originales, mantener los descuentos pactados en la cotización inicial y calcular con exactitud las métricas de conversión comercial por producto.
Reglas de la tabla - kardex_productos (Sección Compras)
R.9: Validación de Lotes en Compra. Para COMPRA (1050):
- Cada detalle debe tener cantidad > 0.
- El lote_id debe ser nuevo (creado automáticamente al insertar la compra).
- precio_costo del lote debe ser igual a pcompra del detalle.
R.10: Control de Precios de Compra. pcompra debe ser mayor a 0.00. El sistema puede validar que pcompra <= precio de mercado según el producto.
R.11: Conversión de Unidades en Compras. cantidad_unidad_base debe calcularse multiplicando cantidad por factor_conversion de la tabla conversiones_unidad.
R.12: Validación de Recepción Parcial. Para SOLICITUD_COMPRA (1058) con estado_pedido_id = 2254 (PARCIAL):
- La sumatoria de cantidades_salida de todos los detalles debe ser < cantidad_total_solicitada.
- Debe existir al menos un detalle con cantidad_salida > 0.
R.13: Control de Devoluciones Parciales. Para DEVOLUCION_PROVEEDOR (1061):
- cantidad_salida > 0.
- cantidad_salida <= cantidad disponible en el lote original.
- La sumatoria de cantidades devueltas no puede exceder la cantidad comprada original.';

DELETE FROM kardex_productos;
ALTER SEQUENCE kardex_productos_kardex_producto_id_seq RESTART WITH 1;

INSERT INTO kardex_productos (kardex_producto_id, kardex_id, producto_id, sucursal_id, lote_id, presentacion_id, tipo_pago_id, tipo_venta_id, cantidad, cantidad_unidad_base, cantidad_salida, pcompra, factor_venta, factor_facturacion, precio_venta, precio_venta_factura, costo_venta, descuento, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1400, 1350, 0.00, 0.00, 0.00, 0.00, 1.00, 1.00, 0.00, 0.00, 0.00, 0.00, 1000, 1);

UPDATE kardex_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE kardex_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('kardex_productos_kardex_producto_id_seq', COALESCE((SELECT MAX(kardex_producto_id) FROM kardex_productos), 1));

-- ================================================================================================

CREATE TABLE inventarios_fisicos_detalle (
    inventario_fisico_detalle_id BIGSERIAL PRIMARY KEY,
    inventario_fisico_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    lote_id BIGINT NOT NULL,
    ubicacion_id BIGINT NOT NULL,
    cantidad_sistema DECIMAL(12,2) NOT NULL,
    cantidad_contada DECIMAL(12,2) NOT NULL,
    diferencia DECIMAL(12,2) GENERATED ALWAYS AS (cantidad_contada - cantidad_sistema) STORED,
    observaciones VARCHAR(500) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,  -- 1000=ABIERTO, 1002=CERRADO, 1001=CANCELADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ifd_inventario_fisico_id FOREIGN KEY (inventario_fisico_id) REFERENCES inventarios_fisicos(inventario_fisico_id),
    CONSTRAINT fk_ifd_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_ifd_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
    CONSTRAINT fk_ifd_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ifd_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ifd_cantidades CHECK (cantidad_sistema >= 0 AND cantidad_contada >= 0)
);
CREATE UNIQUE INDEX uix_ifd_inventario_lote_ubicacion ON inventarios_fisicos_detalle (inventario_fisico_id, lote_id, ubicacion_id) WHERE estado_id = 1000;

COMMENT ON TABLE inventarios_fisicos_detalle IS 'Reglas de la tabla - inventarios_fisicos_detalle
R.0: Almacena el desglose ítem por ítem de cada producto, lote y ubicación contados durante un proceso de inventario físico. Se conecta directamente con las tablas inventarios_fisicos, productos, lotes_productos, ubicaciones y dominios.
R.1: Stock Teórico. cantidad_sistema refleja el stock teórico registrado en el sistema antes de iniciar el conteo físico.
R.2: Stock Físico. cantidad_contada representa la cantidad física real obtenida mediante el conteo en almacén.
R.3: Diferencia Automática. La columna diferencia se calcula de forma automática mediante la expresión almacenada (cantidad_contada - cantidad_sistema).
R.4: Acciones de Ajuste. Si la diferencia es distinta de cero (diferencia <> 0) al momento de cerrar el inventario físico, el backend debe generar automáticamente un movimiento de ajuste de inventario asociado (evento_id = 1065 para sobrantes o 1066 para faltantes).';

DELETE FROM inventarios_fisicos_detalle;
ALTER SEQUENCE inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos_detalle (inventario_fisico_detalle_id, inventario_fisico_id, producto_id, lote_id, ubicacion_id, cantidad_sistema, cantidad_contada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 0.00, 0.00, 'REGISTRO INICIAL COMODIN DE DETALLE DE INVENTARIO FISICO', 1000, 1);

UPDATE inventarios_fisicos_detalle SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE inventarios_fisicos_detalle SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq', COALESCE((SELECT MAX(inventario_fisico_detalle_id) FROM inventarios_fisicos_detalle), 1));

-- ================================================================================================

-- ================================================================================================

CREATE TABLE ubicaciones_movimientos (
    ubicacion_movimiento_id BIGSERIAL PRIMARY KEY,
    kardex_producto_id BIGINT NOT NULL,
    ubicacion_origen_id BIGINT NULL,
    ubicacion_destino_id BIGINT NOT NULL,
    lote_id BIGINT NOT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    tipo_ubicacion_movimiento_id INTEGER NOT NULL DEFAULT 3200,      -- 3200=INGRESO, 3201=EGRESO
    motivo VARCHAR(500) NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_id INTEGER NOT NULL DEFAULT 1000,                        -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_um_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT fk_um_ubicacion_origen_id FOREIGN KEY (ubicacion_origen_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_um_ubicacion_destino_id FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_um_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
    CONSTRAINT fk_um_tipo_ubicacion_movimiento_id FOREIGN KEY (tipo_ubicacion_movimiento_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_um_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_um_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_um_ubicaciones_diferentes CHECK (ubicacion_origen_id IS NULL OR ubicacion_origen_id <> ubicacion_destino_id)
);
CREATE INDEX idx_um_kardex_producto ON ubicaciones_movimientos (kardex_producto_id);
CREATE INDEX idx_um_fecha_movimiento ON ubicaciones_movimientos (fecha_movimiento DESC);
CREATE INDEX idx_um_ubicacion_destino ON ubicaciones_movimientos (ubicacion_destino_id);
CREATE INDEX idx_um_lote ON ubicaciones_movimientos (lote_id);

COMMENT ON TABLE ubicaciones_movimientos IS 'Reglas de la tabla - ubicaciones_movimientos
R.0: La tabla ubicaciones_movimientos registra todos los movimientos físicos de productos entre ubicaciones, permitiendo una auditoría completa de la logística interna, la trazabilidad por lote y el control detallado de las transferencias de inventario. Se conecta directamente con las tablas kardex_productos, ubicaciones, lotes_productos y dominios.
R.1: Tipos de Movimiento. El campo tipo_ubicacion_movimiento_id indica la naturaleza operativa de la transacción dentro de la ubicación, soportando de forma específica dominios de UbicacionMovimientoTipoID como INGRESO (3200) o EGRESO (3201). El backend es responsable de validar la coherencia del tipo de movimiento frente a las ubicaciones de origen y destino especificadas.
R.2: Origen y Destino de las Transferencias. El campo ubicacion_origen_id representa el punto de partida de la mercancía y puede ser NULL únicamente cuando se trata de un ingreso inicial de inventario al sistema o una recepción externa sin precedentes en ubicaciones internas previas. El campo ubicacion_destino_id is obligatorio e indica el punto final donde se ubica físicamente el lote.
R.3: Validación y Actualización Automática de Stock. El backend es responsable de validar las reglas de capacidad de la ubicación de destino antes de confirmar la inserción, así como de actualizar de manera automática y transaccional el campo stock_actual tanto en la ubicación de origen (si aplica) como en la de destino.
R.4: Cantidades y Restricciones Estrictas. La columna cantidad se expresa en la unidad base del producto y debe cumplir estrictamente con la restricción de ser mayor a cero (cantidad > 0). Asimismo, se valida por restricción a nivel de base de datos que la ubicación de origen y la de destino nunca sean iguales, evitando bucles lógicos en la transferencia.
R.5: Inmutabilidad Histórica. Las filas registradas en esta tabla poseen un carácter inmutable para garantizar la integridad de las auditorías de inventario físico. No se permiten modificaciones (UPDATE) ni eliminaciones directas (DELETE) sobre los registros históricos de movimientos de ubicación.';

DELETE FROM ubicaciones_movimientos;
ALTER SEQUENCE ubicaciones_movimientos_ubicacion_movimiento_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_movimientos (ubicacion_movimiento_id, kardex_producto_id, ubicacion_origen_id, ubicacion_destino_id, lote_id, cantidad, tipo_ubicacion_movimiento_id, motivo, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, 1, 1.00, 3200, 'REGISTRO INICIAL COMODIN DE MOVIMIENTO', 1000, 1);

UPDATE ubicaciones_movimientos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones_movimientos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_movimientos_ubicacion_movimiento_id_seq', COALESCE((SELECT MAX(ubicacion_movimiento_id) FROM ubicaciones_movimientos), 1));

-- ================================================================================================

CREATE TABLE ubicaciones_historial (
    ubicacion_historial_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL,
    ubicacion_origen_id BIGINT NULL,
    ubicacion_destino_id BIGINT NOT NULL,
    kardex_producto_id BIGINT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    usuario_id BIGINT NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_uh_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_uh_ubicacion_origen_id FOREIGN KEY (ubicacion_origen_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_uh_ubicacion_destino_id FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_uh_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT fk_uh_usuario_id FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_uh_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_uh_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_uh_motivo_not_empty CHECK (TRIM(motivo) <> ''),
    CONSTRAINT chk_uh_ubicaciones_diferentes CHECK (
        ubicacion_origen_id IS NULL OR ubicacion_origen_id <> ubicacion_destino_id
    )
);
CREATE INDEX idx_uh_producto_id ON ubicaciones_historial (producto_id);
CREATE INDEX idx_uh_fecha_movimiento ON ubicaciones_historial (fecha_movimiento DESC);
CREATE INDEX idx_uh_ubicacion_destino ON ubicaciones_historial (ubicacion_destino_id);
CREATE INDEX idx_uh_usuario_id ON ubicaciones_historial (usuario_id);
CREATE INDEX idx_uh_usuario_fecha ON ubicaciones_historial (usuario_id, fecha_movimiento DESC);

COMMENT ON TABLE ubicaciones_historial IS 'Reglas de la tabla - ubicaciones_historial
R.0: La tabla ubicaciones_historial actúa como el registro de auditoría de todos los movimientos de productos entre ubicaciones dentro de los almacenes. Su propósito es proporcionar trazabilidad completa sobre cuándo, quién y por qué se movió un producto de una ubicación a otra, permitiendo análisis de eficiencia de picking, detección de errores logísticos y cumplimiento de procedimientos operativos.
R.1: Registro Obligatorio de Movimientos: Cada vez que un producto cambia de ubicación (ya sea por venta, reabastecimiento, ajuste de inventario o reubicación manual), el sistema debe insertar automáticamente un registro en esta tabla. El backend es responsable de generar este registro de forma atómica junto con la operación que origina el movimiento.
R.2: Vinculación con Transacciones: El campo kardex_producto_id permite asociar el movimiento de ubicación con una transacción específica (venta, compra, ajuste, traspaso), proporcionando trazabilidad completa desde el documento fiscal hasta la ubicación física del producto.
R.3: Motivos de Movimiento: El campo motivo debe documentar claramente la razón del movimiento, utilizando valores estandarizados como: ''VENTA'', ''COMPRA'', ''REABASTECIMIENTO'', ''AJUSTE_INVENTARIO'', ''TRASPASO'', ''REUBICACION_MANUAL'', ''DEVOLUCION'', ''CADUCIDAD'', etc. El frontend debe presentar un combo con estas opciones predefinidas para garantizar consistencia en el registro.
R.4: Control de Fechas y Auditoría: fecha_movimiento registra el momento exacto en que ocurrió el movimiento físico, mientras que fecha_registro puede diferir ligeramente por latencia de red. El sistema debe utilizar fecha_movimiento como fuente de verdad para reportes de trazabilidad.
R.5: Cantidad y Unidades: El campo cantidad almacena la cantidad de producto movida, expresada en unidades base del producto (ej. tabletas, mililitros). Esta cantidad debe ser positiva y corresponde al total de unidades trasladadas.
R.6: Inmutabilidad del Historial: Los registros en esta tabla son inmutables por diseño. No se permiten operaciones UPDATE o DELETE sobre registros existentes. Cualquier corrección debe realizarse mediante un nuevo registro que anule o complemente el movimiento anterior, manteniendo la trazabilidad completa sin pérdida de información.
R.7: Registro Comodín: El sistema debe mantener un registro inicial con ubicacion_historial_id = 1 que sirve como valor predeterminado para las FK que requieran un historial de referencia. Este registro tiene estado_id = 1002 (HISTORICO) y no puede ser modificado ni eliminado.
R.8: Consultas y Reportes: Los índices estratégicos (idx_uh_producto_id, idx_uh_fecha_movimiento, idx_uh_ubicacion_destino, idx_uh_usuario_id) garantizan consultas rápidas para reportes de trazabilidad, análisis de eficiencia de picking y auditorías de inventario.
R.9: Integración con Módulos: Esta tabla se integra con los módulos de:
- Ventas: Registra la salida de productos del almacén al cliente.
- Compras: Registra la entrada de productos al almacén desde proveedores.
- Inventario: Registra reubicaciones, ajustes y traspasos.
- Devoluciones: Registra movimientos de productos devueltos.
- Caducidad: Registra movimientos de productos vencidos a zonas de cuarentena.';

DELETE FROM ubicaciones_historial;
ALTER SEQUENCE ubicaciones_historial_ubicacion_historial_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_historial (ubicacion_historial_id, producto_id, ubicacion_origen_id, ubicacion_destino_id, kardex_producto_id, cantidad, motivo, usuario_id, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, NULL, 1.00, 'Registro predeterminado inicial de ubicación', 1, 1000, 1);

UPDATE ubicaciones_historial SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones_historial SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_historial_ubicacion_historial_id_seq', COALESCE((SELECT MAX(ubicacion_historial_id) FROM ubicaciones_historial), 1));

-- ================================================================================================

CREATE TABLE tipos_planes_pago (
    tipo_plan_pago_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    meses_plazo INTEGER NOT NULL DEFAULT 0,
    porcentaje_recargo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    monto_fijo_recargo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    permite_personalizar INTEGER NOT NULL DEFAULT 0,      -- 1=Sí (permite alterar cuotas y fechas), 0=No (cuotas fijas automáticas)
    descripcion VARCHAR(500) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,              -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_tpp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_tpp_meses_plazo CHECK (meses_plazo >= 0),
    CONSTRAINT chk_tpp_porcentaje CHECK (porcentaje_recargo >= 0),
    CONSTRAINT chk_tpp_recargo_fijo CHECK (monto_fijo_recargo >= 0),
    CONSTRAINT chk_tpp_personalizar CHECK (permite_personalizar IN (0, 1))
);
CREATE UNIQUE INDEX uix_tpp_codigo ON tipos_planes_pago (codigo) WHERE estado_id IN (1000, 1002);

DELETE FROM tipos_planes_pago;
ALTER SEQUENCE tipos_planes_pago_tipo_plan_pago_id_seq RESTART WITH 1;

INSERT INTO tipos_planes_pago (tipo_plan_pago_id, codigo, nombre, meses_plazo, porcentaje_recargo, monto_fijo_recargo, permite_personalizar, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 0, 0.00, 0.00, 0, 'Pago por defecto.', 1000, 1),
(2, '3M', 'Plan a 3 Meses', 3, 5.00, 0.00, 0, 'Fraccionado a 3 meses con un recargo financiero del 5% sobre capital.', 1000, 1),
(3, '6M', 'Plan a 6 Meses', 6, 10.00, 0.00, 0, 'Fraccionado a 6 meses con un recargo financiero del 10% sobre capital.', 1000, 1),
(4, '12M', 'Plan a 12 Meses', 12, 18.00, 0.00, 0, 'Fraccionado a 12 meses con un recargo financiero del 18% sobre capital.', 1000, 1),
(5, 'PER', 'Plan Personalizado', 0, 0.00, 0.00, 1, 'Plan a medida donde el usuario define fechas y porcentajes por cuota.', 1000, 1);

UPDATE tipos_planes_pago SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_planes_pago SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_planes_pago_tipo_plan_pago_id_seq', COALESCE((SELECT MAX(tipo_plan_pago_id) FROM tipos_planes_pago), 1));

-- ================================================================================================

CREATE TABLE planes_pagos (
    plan_pago_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    numero_cuota INTEGER NOT NULL,
    monto_programado DECIMAL(12,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado_pago_id INTEGER NOT NULL DEFAULT 2555,  		-- 2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO
    fecha_pago DATE NULL,
    monto_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    observaciones VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pp_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_pp_estado_pago_id FOREIGN KEY (estado_pago_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_pp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pp_numero_cuota CHECK (numero_cuota > 0),
    CONSTRAINT chk_pp_monto_programado CHECK (monto_programado >= 0),
    CONSTRAINT chk_pp_monto_pagado CHECK (monto_pagado >= 0),
    CONSTRAINT chk_pp_monto_coherencia CHECK (monto_pagado <= monto_programado),
    CONSTRAINT chk_pp_fecha_vencimiento CHECK (fecha_vencimiento > '2000-01-01'),
    CONSTRAINT chk_pp_fecha_pago CHECK (fecha_pago IS NULL OR fecha_pago > '2000-01-01')
);
CREATE UNIQUE INDEX uix_pp_cuota_kardex ON planes_pagos (kardex_id, numero_cuota) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pp_kardex_id ON planes_pagos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pp_fecha_vencimiento ON planes_pagos (fecha_vencimiento) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE planes_pagos IS 'Reglas de la tabla - planes_pagos
R.0: La tabla planes_pagos gestiona el calendario de vencimientos para las compras a crédito a proveedores, registrando las cuotas programadas y su estado de pago. Su propósito es administrar la deuda con los proveedores, facilitando la planificación financiera y el control de los pasivos, permitiendo registrar abonos parciales y ajustar automáticamente el estado de las cuotas. Se conecta directamente con las tablas kardex y pagos.
R.1: Control de Ciclo de Vida y Cierre. estado_pago_id califica de manera estricta el avance transaccional de la cuota. Pasará automáticamente a 2552 (PAGADO) o 2553 (CERRADO) cuando el monto_pagado iguale al monto_programado (saldo igual a 0.00). El frontend inhabilitará de forma inmediata la edición o inserción de nuevos abonos sobre registros cuyo estado_pago_id sea distinto de 2550 (PENDIENTE) o 2551 (PARCIAL) para proteger la integridad contable.
R.2: Diferenciación de Capas. estado_id regula únicamente el borrado lógico y el comportamiento histórico en el sistema general (''ACTIVO'', ''BORRADO'', ''HISTORICO'', ''ANULADO''), operando de forma independiente a los procesos de liquidación comercial controlados por estado_pago_id.
R.3: Los planes de pago solo pueden ser creados para transacciones de compra a proveedores (evento_id = 1050 ''COMPRA'' en la tabla kardex). El sistema bloquea la creación de planes de pago para cualquier otro evento, incluyendo VENTA (evento_id = 1051).
R.4: Registro Inicial Comodín. El registro con plan_pago_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO) y estado_pago_id = 2553 (CERRADO). Sirve como valor predeterminado para las FK que requieran un plan de pago de referencia.
R.5: Validación de Fechas. fecha_pago solo puede ser registrada si es posterior a ''2000-01-01''. El backend debe validar que fecha_pago >= fecha_vencimiento cuando se registre un pago.
R.6: Cálculo Automático del Estado de Pago. El backend debe actualizar estado_pago_id automáticamente al registrar abonos: si monto_pagado = monto_programado → 2552 (PAGADO); si monto_pagado > 0 y < monto_programado → 2551 (PARCIAL); si monto_pagado = 0 → 2550 (PENDIENTE). CERRADO solo aplica cuando la cuota está completamente liquidada y el plan ha finalizado.
Reglas de la tabla - planes_pagos (Sección Compras)
R.7: Validación de Compra a Crédito. Los planes de pago solo pueden ser creados para compras (evento_id = 1050) con estado_financiero_id IN (2401, 2402). No se permiten planes para compras CANCELADAS (2400).
R.8: Validación de Tipo de Plan de Pago. El tipo_plan_pago_id debe ser ACTIVO (estado_id = 1000).
R.9: Generación Automática de Cuotas. Cuando se selecciona un tipo_plan_pago_id con meses_plazo > 0:
- El backend debe generar automáticamente las cuotas mensuales.
- La primera cuota vence a los 30 días de fecha_kardex.
- Las siguientes cuotas vencen cada 30 días.
- El monto_programado de cada cuota = (total_compra + recargo) / meses_plazo.
R.10: Personalización de Cuotas. Si tipo_plan_pago_id = 5 (PER - Plan Personalizado):
- permite_personalizar = 1.
- El usuario puede definir montos y fechas de vencimiento individuales.
- La suma de los montos_programado debe ser igual a total_compra + recargo.
R.11: Validación de Monto Programado. monto_programado > 0.
R.12: Control de Fechas. fecha_vencimiento debe ser > CURRENT_DATE para cuotas pendientes.
R.13: Cierre Automático del Plan de Pago. El plan se cierra automáticamente cuando todas las cuotas tienen estado_pago_id = 2552 (PAGADO) o 2553 (CERRADO). Al cerrar, estado_financiero_id de la compra en kardex se actualiza a 2400 (CANCELADO).
R.14: Validación de Monto Pagado. monto_pagado <= monto_programado.
R.15: Control de Estado Financiero. El estado_pago_id se actualiza automáticamente según el monto_pagado:
- monto_pagado = 0 → 2550 (PENDIENTE)
- 0 < monto_pagado < monto_programado → 2551 (PARCIAL)
- monto_pagado = monto_programado → 2552 (PAGADO)';

DELETE FROM planes_pagos;
ALTER SEQUENCE planes_pagos_plan_pago_id_seq RESTART WITH 1;

INSERT INTO planes_pagos (plan_pago_id, kardex_id, numero_cuota, monto_programado, fecha_vencimiento, estado_pago_id, fecha_pago, monto_pagado, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, '2026-01-01', 2553, '2026-01-01', 0.00, 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

UPDATE planes_pagos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE planes_pagos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('planes_pagos_plan_pago_id_seq', COALESCE((SELECT MAX(plan_pago_id) FROM planes_pagos), 1));

-- ================================================================================================

CREATE TABLE comprobantes_pagos (
    comprobante_pago_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    banco_id BIGINT NOT NULL DEFAULT 1,
    tipo_pago_id BIGINT NOT NULL DEFAULT 1400,            -- 1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO
    tipo_moneda_id INTEGER NOT NULL DEFAULT 2300,         -- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    codigo_transaccion VARCHAR(100) NOT NULL,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_pago DATE NOT NULL,
    titular_cuenta VARCHAR(150) NOT NULL DEFAULT '',
    autorizacion_nro VARCHAR(50) NULL,
    cuenta_destino VARCHAR(50) NULL,
    comprobante_digital_ruta VARCHAR(255) NULL,
    confirmado INTEGER NOT NULL DEFAULT 0,
    estado_id INTEGER NOT NULL DEFAULT 1000,              -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cpp_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_cpp_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
    CONSTRAINT fk_cpp_tipo_moneda_id FOREIGN KEY (tipo_moneda_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cpp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cpp_confirmado CHECK (confirmado IN (0, 1)),
    CONSTRAINT chk_cpp_monto_positivo CHECK (monto > 0.00),
    CONSTRAINT chk_cpp_codigo_transaccion_min CHECK (LENGTH(TRIM(codigo_transaccion)) >= 2)
);
CREATE UNIQUE INDEX uix_cpp_transaccion_unica ON comprobantes_pagos (banco_id, codigo_transaccion) WHERE estado_id IN (1000, 1002) AND codigo_transaccion <> 'SN';
CREATE INDEX idx_cpp_kardex_id ON comprobantes_pagos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cpp_tipo_pago ON comprobantes_pagos (tipo_pago_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cpp_fecha_pago ON comprobantes_pagos (fecha_pago DESC) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE comprobantes_pagos IS 'Reglas de la tabla - comprobantes_pagos
R.0: La tabla comprobantes_pagos registra los comprobantes de pago asociados a transacciones de venta, compra u otras operaciones financieras. Sirve como soporte documental y de trazabilidad de los medios de pago utilizados en el sistema, permitiendo vincular cada transacción con su respectivo comprobante bancario o interno.
R.1: confirmado indica si el comprobante ha sido validado o verificado (1=Confirmado, 0=Pendiente). El sistema debe actualizar este campo manualmente o mediante procesos de conciliación bancaria.
R.2: codigo_transaccion almacena el número de operación, referencia o código único de la transacción bancaria. El campo es único por banco y debe tener al menos 2 caracteres.
R.3: tipo_pago_id define el medio de pago utilizado (EFECTIVO, CHEQUE, QR, TRANSFERENCIA, etc.). El registro con id 1400 corresponde a ''NINGUNO'' para casos de compras u operaciones que no requieren pago.
R.4: Permite la relación de uno a muchos (1 a N) con la tabla kardex mediante kardex_id, posibilitando registrar múltiples comprobantes de pago (como pagos mixtos o fraccionados con QR, transferencias o cheques) para una misma transacción comercial, manteniendo la normalización de datos sin duplicar información financiera.
R.5: Validación de Comprobantes para Pagos a Proveedores. Para pagos con tipo_pago_id = 1407 (TRANSFERENCIA) o 1408 (DEPOSITO), el comprobante_digital_ruta es obligatorio.
R.6: Confirmación de Comprobante. confirmado = 1 indica que el pago ha sido verificado por el banco. El sistema solo permite registrar pagos con comprobantes confirmados.
R.7: Unicidad de Transacción. El código de transacción debe ser único por banco.';

DELETE FROM comprobantes_pagos;
ALTER SEQUENCE comprobantes_pagos_comprobante_pago_id_seq RESTART WITH 1;

INSERT INTO comprobantes_pagos (comprobante_pago_id, kardex_id, banco_id, tipo_pago_id, tipo_moneda_id, codigo_transaccion, monto, fecha_pago, titular_cuenta, autorizacion_nro, cuenta_destino, comprobante_digital_ruta, confirmado, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 2300, 'SN', 0.01, CURRENT_DATE, 'NINGUNO', NULL, NULL, NULL, 0, 1000, 1);

UPDATE comprobantes_pagos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE comprobantes_pagos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('comprobantes_pagos_comprobante_pago_id_seq', COALESCE((SELECT MAX(comprobante_pago_id) FROM comprobantes_pagos), 1));

-- ================================================================================================

CREATE TABLE pagos (
    pago_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    plan_pago_id BIGINT NOT NULL DEFAULT 1,
    tipo_pago_id BIGINT NOT NULL DEFAULT 1400,		-- 1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO
    comprobante_pago_id BIGINT NOT NULL DEFAULT 1,
	proveedor_id BIGINT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    referencia VARCHAR(100) NULL,
    comprobante VARCHAR(100) NULL,
    observaciones VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_p_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_p_plan_pago_id FOREIGN KEY (plan_pago_id) REFERENCES planes_pagos(plan_pago_id),
    CONSTRAINT fk_p_tipo_pago_id FOREIGN KEY (tipo_pago_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_p_comprobante_pago_id FOREIGN KEY (comprobante_pago_id) REFERENCES comprobantes_pagos(comprobante_pago_id),
	CONSTRAINT fk_p_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT fk_p_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_p_monto CHECK (monto > 0),
    CONSTRAINT chk_p_fecha_pago CHECK (fecha_pago > '2000-01-01')
);
CREATE INDEX idx_p_kardex_id ON pagos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_p_plan_pago_id ON pagos (plan_pago_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_p_fecha_pago ON pagos (fecha_pago) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE pagos IS 'Reglas de la tabla - pagos
R.0: La tabla pagos registra los abonos o liquidaciones efectuadas por los clientes para cubrir las cuotas de financiamiento generadas en la tabla planes_pagos. Su propósito es consolidar el historial de cobranza, vinculando cada transacción de pago con el plan de cuotas, el medio de pago utilizado y el comprobante bancario asociado. Se conecta directamente con las tablas kardex, planes_pagos, comprobantes_pagos y dominios para garantizar la trazabilidad financiera completa.
R.1: referencia almacena un dato opcional ingresado por el usuario que permite identificar el pago en el sistema contable o bancario, como un número de factura, orden de compra o código interno.
R.2: comprobante almacena el código o número del documento soporte del pago (ej. número de factura, recibo, boleta) para facilitar la conciliación y auditoría de los movimientos financieros.
Reglas de la tabla - pagos (Sección Compras)
R.3: Validación de Pago a Proveedor. Los pagos solo pueden ser registrados para compras (evento_id = 1050) con estado_financiero_id IN (2401, 2402).
R.4: Validación de Monto de Pago. monto > 0.00.
R.5: Control de Saldo Pendiente. monto_pagado no puede exceder el saldo_pendiente de la compra.
R.6: Actualización de Estado de Pago. Al registrar un pago:
- Se actualiza total_pagado en kardex.
- Se actualiza saldo_pendiente = total_compra - total_pagado.
- Si saldo_pendiente = 0, estado_financiero_id = 2400 (CANCELADO).
- Si saldo_pendiente > 0, estado_financiero_id = 2402 (PARCIAL).
R.7: Validación de Comprobante de Pago. comprobante_pago_id debe existir y estar confirmado (confirmado = 1) para pagos con tipo_pago_id IN (1402, 1404, 1407, 1408).';

DELETE FROM pagos;
ALTER SEQUENCE pagos_pago_id_seq RESTART WITH 1;

INSERT INTO pagos (pago_id, kardex_id, plan_pago_id, tipo_pago_id, comprobante_pago_id, monto, fecha_pago, referencia, comprobante, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 1, 1.00, '2026-01-01', 'NINGUNO', 'NINGUNO', 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

UPDATE pagos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE pagos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('pagos_pago_id_seq', COALESCE((SELECT MAX(pago_id) FROM pagos), 1));

-- ================================================================================================

CREATE TABLE cajas (
    caja_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    usuario_id_apertura BIGINT NOT NULL,
    usuario_id_cierre BIGINT NULL,
    usuario_id_autorizacion BIGINT NULL,
    fecha_apertura TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre TIMESTAMPTZ NULL,
    fecha_autorizacion TIMESTAMPTZ NULL,
    monto_inicial DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_ingresos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_egresos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_final_esperado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_final_real DECIMAL(12,2) NULL,
    diferencia DECIMAL(12,2) NULL,
    total_transacciones INTEGER NOT NULL DEFAULT 0,
    total_ventas INTEGER NOT NULL DEFAULT 0,
    total_devoluciones INTEGER NOT NULL DEFAULT 0,
    total_retiros INTEGER NOT NULL DEFAULT 0,
    estado_caja_id INTEGER NOT NULL DEFAULT 2650,			-- 2650=ABIERTA, 2651=CERRADA
    observaciones VARCHAR(500) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,              	-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cja_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cja_usuario_apertura FOREIGN KEY (usuario_id_apertura) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_cja_usuario_cierre FOREIGN KEY (usuario_id_cierre) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_cja_usuario_autorizacion FOREIGN KEY (usuario_id_autorizacion) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_cja_estado_caja_id FOREIGN KEY (estado_caja_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cja_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cja_fechas_cierre CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_apertura),
    CONSTRAINT chk_cja_fechas_autorizacion CHECK (fecha_autorizacion IS NULL OR fecha_autorizacion <= fecha_apertura),
    CONSTRAINT chk_cja_montos CHECK (
        monto_inicial >= 0.00 AND
        monto_ingresos >= 0.00 AND
        monto_egresos >= 0.00 AND
        monto_ventas >= 0.00
    ),
    CONSTRAINT chk_cja_observaciones_min CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3)
);
CREATE UNIQUE INDEX uix_cja_una_abierta_por_sucursal ON cajas (sucursal_id) WHERE estado_caja_id = 2650 AND estado_id = 1000;
CREATE INDEX idx_cja_sucursal_estado ON cajas (sucursal_id, estado_caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cja_fecha_apertura ON cajas (fecha_apertura DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cja_usuario_apertura ON cajas (usuario_id_apertura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cja_estado_fecha ON cajas (estado_caja_id, fecha_apertura DESC) WHERE estado_id IN (1000, 1002);

DELETE FROM cajas;
ALTER SEQUENCE cajas_caja_id_seq RESTART WITH 1;

INSERT INTO cajas (caja_id, sucursal_id, usuario_id_apertura, usuario_id_cierre, usuario_id_autorizacion, fecha_apertura, fecha_cierre, fecha_autorizacion, monto_inicial, monto_ingresos, monto_egresos, monto_ventas, monto_final_esperado, monto_final_real, diferencia, total_transacciones, total_ventas, total_devoluciones, total_retiros, estado_caja_id, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, NULL, '2026-01-01 00:00:00-04', NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 0, 0, 0, 0, 2650, 'COMODIN INICIAL DE SISTEMA', 1000, 1);

UPDATE cajas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cajas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cajas_caja_id_seq', COALESCE((SELECT MAX(caja_id) FROM cajas), 1));

-- ================================================================================================

CREATE TABLE movimientos (
    movimiento_id BIGSERIAL PRIMARY KEY,
    caja_id BIGINT NOT NULL DEFAULT 1,
    referencia_id BIGINT NULL,
    usuario_id BIGINT NOT NULL,
    tipo_movimiento_id INTEGER NOT NULL DEFAULT 2600,		-- 2600=INGRESO, 2601=EGRESO
    tipo_pago_id INTEGER NULL DEFAULT 1400,					-- 1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO
    monto DECIMAL(12,2) NOT NULL,
    saldo_antes DECIMAL(12,2) NOT NULL,
    saldo_despues DECIMAL(12,2) NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_id INTEGER NOT NULL DEFAULT 1000,              	-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_mov_caja_id FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT fk_mov_usuario_id FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_mov_tipo_movimiento_id FOREIGN KEY (tipo_movimiento_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_mov_tipo_pago_id FOREIGN KEY (tipo_pago_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_mov_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_mov_monto CHECK (monto > 0.00),
    CONSTRAINT chk_mov_saldo_antes CHECK (saldo_antes >= 0.00),
    CONSTRAINT chk_mov_saldo_despues CHECK (saldo_despues >= 0.00),
    CONSTRAINT chk_mov_motivo_min CHECK (LENGTH(TRIM(motivo)) >= 3)
);
CREATE INDEX idx_mov_caja_id ON movimientos (caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mov_fecha ON movimientos (fecha_movimiento DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mov_tipo ON movimientos (tipo_movimiento_id, caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mov_usuario ON movimientos (usuario_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mov_referencia ON movimientos (referencia_id) WHERE referencia_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_mov_fecha_registro ON movimientos (fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mov_tipo_pago ON movimientos (tipo_pago_id) WHERE estado_id IN (1000, 1002);

DELETE FROM movimientos;
ALTER SEQUENCE movimientos_movimiento_id_seq RESTART WITH 1;

INSERT INTO movimientos (movimiento_id, caja_id, referencia_id, usuario_id, tipo_movimiento_id, tipo_pago_id, monto, saldo_antes, saldo_despues, motivo, fecha_movimiento, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, 2600, 1400, 0.01, 0.00, 0.01, 'REGISTRO COMODIN OBLIGATORIO', CURRENT_TIMESTAMP, 1000, 1);

UPDATE movimientos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE movimientos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('movimientos_movimiento_id_seq', COALESCE((SELECT MAX(movimiento_id) FROM movimientos), 1));

-- ================================================================================================

CREATE TABLE arqueos_detalle (
    arqueo_detalle_id BIGSERIAL PRIMARY KEY,
    caja_id BIGINT NOT NULL DEFAULT 1,
    tipo_billete_id INTEGER NOT NULL DEFAULT 4300,        -- 4300=NINGUNO, 4301=B200, 4302=B100, 4303=B50, 4304=B20, 4305=B10, 4306=B5, 4307=B2, 4308=B1, 4309=M050, 4310=M020, 4311=M010, 4312=M10, 4313=M5, 4314=M2, 4315=M1
    cantidad INTEGER NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado_id INTEGER NOT NULL DEFAULT 1000,              -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ad_caja_id FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT fk_ad_tipo_billete_id FOREIGN KEY (tipo_billete_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_ad_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ad_cantidad CHECK (cantidad >= 0),
    CONSTRAINT chk_ad_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_ad_caja_id ON arqueos_detalle (caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ad_tipo_billete ON arqueos_detalle (tipo_billete_id) WHERE estado_id IN (1000, 1002);

DELETE FROM arqueos_detalle;
ALTER SEQUENCE arqueos_detalle_arqueo_detalle_id_seq RESTART WITH 1;

INSERT INTO arqueos_detalle (arqueo_detalle_id, caja_id, tipo_billete_id, cantidad, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 4300, 0, 0.00, 1000, 1);

UPDATE arqueos_detalle SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE arqueos_detalle SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('arqueos_detalle_arqueo_detalle_id_seq', COALESCE((SELECT MAX(arqueo_detalle_id) FROM arqueos_detalle), 1));

-- ================================================================================================

CREATE TABLE alertas_notificaciones (
    alerta_notificacion_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(30) NOT NULL,
    tipo_alerta_notificacion_id INTEGER NOT NULL DEFAULT 2724,  -- 2700=SISTEMA, 2701=ALERTA_STOCK, 2702=STOCK_BAJO, 2703=STOCK_CRITICO, 2704=STOCK_EXCESO, 2705=VENCIMIENTO_PROXIMO, 2706=VENCIMIENTO_INMEDIATO, 2707=VENCIMIENTO_VENCIDO, 2708=DEMANDA_ALTA, 2709=DEMANDA_BAJA, 2710=TENDENCIA_ANOMALA, 2711=PREDICCION_ROP, 2712=PREDICCION_DEMANDA, 2713=FORECASTING, 2714=PAGOS, 2715=PAGO_VENCIDO, 2716=PAGO_PROXIMO, 2717=DOCUMENTOS, 2718=FACTURA_PENDIENTE, 2719=FACTURA_ANULADA, 2720=SEGURIDAD_ACCESO, 2721=SEGURIDAD_INTENTO_FALLIDO, 2722=SISTEMA_ERROR, 2723=SISTEMA_RENDIMIENTO, 2724=NINGUNO, 2725=RRHH_FALTAS, 2726=RRHH_CONTRATO, 2727=RRHH_PLANILLA
    subtipo_alerta_id INTEGER NULL DEFAULT 2812,                -- 2800=SARIMA, 2801=PROPHET, 2802=KMEANS, 2803=ROP_CALC, 2804=PATRON_CONSUMO, 2805=ALERTA_PREDICTIVA, 2806=QUIEBRE_STOCK, 2807=REORDEN, 2808=EXCESO, 2809=CADUCIDAD_CRITICA, 2810=CADUCIDAD_ALTA, 2811=CADUCIDAD_MEDIA, 2812=NINGUNO
    origen_alerta_id INTEGER NOT NULL DEFAULT 2850,             -- 2850=SISTEMA, 2851=IA, 2852=USUARIO, 2853=TAREA_PROGRAMADA, 2854=EXTERNO_TERCERO
    nivel_critico_id INTEGER NOT NULL DEFAULT 2905,             -- 2900=CRITICO, 2901=ALTA, 2902=MEDIA, 2903=BAJA, 2904=INFORMATIVA, 2905=NINGUNO
    titulo VARCHAR(200) NOT NULL,
    mensaje VARCHAR(3000) NOT NULL,
    entidad_afectada_tipo_id INTEGER NOT NULL DEFAULT 4111,		-- 4100=PRODUCTOS, 4101=LOTES, 4102=VENTAS, 4103=COMPRAS, 4104=USUARIOS, 4105=SUCURSALES, 4106=PROVEEDORES, 4107=CLIENTES, 4108=FACTURAS, 4109=PAGOS, 4110=INVENTARIO, 4111=NINGUNO
    entidad_afectada_id BIGINT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    estado_alerta_id INTEGER NOT NULL DEFAULT 2955,       		-- 2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA, 2955=NINGUNO
    prioridad_resolucion INTEGER NOT NULL DEFAULT 3,
    usuario_asignado_id BIGINT NOT NULL DEFAULT 1,
    fecha_asignacion TIMESTAMPTZ NULL,
    es_leido INTEGER NOT NULL DEFAULT 0,
    fecha_lectura TIMESTAMPTZ NULL,
    usuario_resolutor_id BIGINT NOT NULL DEFAULT 1,
    fecha_resolucion TIMESTAMPTZ NULL,
    comentarios_resolucion VARCHAR(3000) NULL,
    accion_tomada VARCHAR(50) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            		-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_aln_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_aln_usuario_asignado_id FOREIGN KEY (usuario_asignado_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_aln_usuario_resolutor_id FOREIGN KEY (usuario_resolutor_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_aln_tipo_alerta_notificacion_id FOREIGN KEY (tipo_alerta_notificacion_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_aln_subtipo_alerta_id FOREIGN KEY (subtipo_alerta_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_aln_origen_alerta_id FOREIGN KEY (origen_alerta_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_aln_nivel_critico_id FOREIGN KEY (nivel_critico_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_aln_entidad_afectada_tipo_id FOREIGN KEY (entidad_afectada_tipo_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_aln_estado_alerta_id FOREIGN KEY (estado_alerta_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_aln_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_aln_es_leido CHECK (es_leido IN (0, 1))
);
CREATE UNIQUE INDEX uix_aln_codigo_activo ON alertas_notificaciones (codigo) WHERE estado_id = 1000;
CREATE INDEX idx_aln_fecha_deteccion ON alertas_notificaciones (fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_aln_entidad_afectada ON alertas_notificaciones (entidad_afectada_tipo_id, entidad_afectada_id) WHERE estado_id = 1000;
CREATE INDEX idx_aln_bandeja_consulta ON alertas_notificaciones (sucursal_id, estado_alerta_id, fecha_registro DESC) WHERE estado_id = 1000;

COMMENT ON TABLE alertas_notificaciones IS 'Reglas de la tabla - alertas_notificaciones
R.0: La tabla alertas_notificaciones es el centro de gestión de eventos y avisos del sistema, consolidando tanto las notificaciones operativas (stock bajo, vencimientos) como las generadas por los modelos de IA (pronósticos, anomalías). Su propósito es unificar la bandeja de entrada del usuario, proporcionando un registro auditado de eventos críticos, su nivel de urgencia, asignación y resolución, lo que permite una gestión proactiva de la farmacia. Se conecta con las tablas sucursales, usuarios y dominios para las categorías de alertas.
R.1: Unificación de Eventos y Bandeja de Entrada. Esta entidad consolida tanto el registro técnico de la anomalía o predicción generada por el sistema/IA como el estado de interacción del operador asignado en una sola estructura unificada, controlando la visibilidad del mensaje en la UI a través del campo es_leido. Donde el campo es_leido está definido en la tabla como un INTEGER NOT NULL DEFAULT 0 (donde 0 = No leído y 1 = Leído).
R.2: Referencia Simplificada a Entidades. entidad_afectada_tipo_id (mapeada a través de la tabla dominios en el rango 4100-4111) y entidad_afectada_id permiten asociar la alerta con una entidad principal del dominio de forma íntegra y estandarizada. Si se necesita una segunda referencia o metadatos adicionales, se almacenan en el campo metadata.
R.3: Metadatos Flexibles con JSONB y Estructura por Defecto. El campo metadata almacena toda la información contextual específica del tipo de alerta (como modelos de IA, parámetros de automatización, resultados de acciones, etc.). Este campo es de uso obligatorio a nivel de esquema con la restricción NOT NULL DEFAULT ''{}''::jsonb, garantizando que la aplicación nunca reciba ni almacene valores nulos (NULL), facilitando el consumo directo de propiedades en el backend sin necesidad de evaluar nulos en el objeto.
R.4: Control Dual de Estados Operacionales. estado_alerta_id rige el ciclo de vida de resolución técnica del evento (2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA). estado_id controla la persistencia lógica en el repositorio de datos (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO).
R.5: Gestión de Lectura y Auditoría Temporal. Al interactuar el usuario con la interfaz, la aplicación debe actualizar es_leido = TRUE y registrar la marca de tiempo exacta en fecha_lectura.
R.6: Registro Inicial Comodín. El registro con alerta_notificacion_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran una alerta de referencia.
R.7: Niveles de Prioridad. prioridad_resolucion es un valor entre 1 y 5 donde 1 es la máxima prioridad y 5 la mínima. El frontend debe ordenar las alertas según este campo para guiar la atención del operador.
R.8: Estructura Estándar de Automatización en Metadata. Cuando la alerta involucre procesos automáticos, la información correspondiente debe almacenarse dentro del JSONB utilizando la siguiente estructura base acordada:
{
    "automatizacion": {
        "frecuencia_minutos": 60,
        "repeticiones": 3,
        "ultima_repeticion": "2026-07-24T10:00:00Z",
        "accion": {
            "nombre": "ENVIAR_CORREO",
            "fecha_ejecucion": "2026-07-24T10:05:00Z",
            "exitosa": true,
            "resultado": "Correo enviado exitosamente"
        }
    }
}';

DELETE FROM alertas_notificaciones;
ALTER SEQUENCE alertas_notificaciones_alerta_notificacion_id_seq RESTART WITH 1;

INSERT INTO alertas_notificaciones (alerta_notificacion_id, sucursal_id, codigo, tipo_alerta_notificacion_id, subtipo_alerta_id, origen_alerta_id, nivel_critico_id, titulo, mensaje, entidad_afectada_tipo_id, entidad_afectada_id, metadata, estado_alerta_id, usuario_asignado_id, fecha_asignacion, es_leido, fecha_lectura, usuario_resolutor_id, fecha_resolucion, comentarios_resolucion, accion_tomada, estado_id, usuario_id_registro) VALUES
(1, 1, 'ALN-000', 2700, 2812, 2850, 2905, 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO', 4111, NULL, '{}'::jsonb, 2953, 1, NULL, 1, CURRENT_TIMESTAMP, 1, NULL, NULL, NULL, 1000, 1);

UPDATE alertas_notificaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE alertas_notificaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('alertas_notificaciones_alerta_notificacion_id_seq', COALESCE((SELECT MAX(alerta_notificacion_id) FROM alertas_notificaciones), 1));

-- ================================================================================================

CREATE TABLE modelos (
    modelo_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_modelo_id INTEGER NOT NULL DEFAULT 1456,  		-- 1450=ARIMA, 1451=SARIMA, 1452=SERIES_TEMPORALES, 1453=CLASIFICACION, 1454=OPTIMIZACION, 1455=DETECCION_ANOMALIAS, 1456=NINGUNO
	framework_version VARCHAR(20) DEFAULT '0.0.0',
    descripcion TEXT NULL,
    framework_id INTEGER NOT NULL DEFAULT 3004,  		-- 3000=STATSMODELS, 3001=SCIKIT_LEARN, 3002=TENSORFLOW, 3003=CUSTOM, 3004=NINGUNO
    version VARCHAR(20) NOT NULL,
    parametros_default JSONB NOT NULL DEFAULT '{}'::jsonb,
    estado_modelo_id INTEGER NOT NULL DEFAULT 2002,  	-- 2000=SIN_DATOS, 2001=ENTRENANDO, 2002=ACTIVO, 2003=RECHAZADO, 2004=OBSOLETO
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_mod_tipo_modelo_id FOREIGN KEY (tipo_modelo_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_mod_framework_id FOREIGN KEY (framework_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_mod_estado_modelo_id FOREIGN KEY (estado_modelo_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_mod_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_mod_codigo_min_longitud CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_mod_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_mod_nombre_min CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_mod_version_min CHECK (LENGTH(TRIM(version)) >= 1)
);
CREATE UNIQUE INDEX uix_mod_codigo ON modelos (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_mod_nombre ON modelos (nombre) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mod_tipo_modelo ON modelos (tipo_modelo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mod_framework ON modelos (framework_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_mod_estado_modelo ON modelos (estado_modelo_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE modelos IS 'Reglas de la tabla - modelos
R.0: La tabla modelos es el catálogo de todos los algoritmos de inteligencia artificial y aprendizaje automático disponibles en el sistema, definiendo sus parámetros de configuración y estado. Su propósito es gestionar el ciclo de vida de los modelos (activo, en entrenamiento, obsoleto), permitiendo la estandarización y el versionado de las técnicas predictivas. Se conecta directamente con las tablas entrenamientos y dominios (tipo de modelo, framework).
R.1: Control del Ciclo de Vida. estado_id gestiona la vigencia y disponibilidad técnica del modelo en el sistema de predicción, garantizando la inmutabilidad y persistencia de configuraciones históricas.
R.2: Estructura de Hiperparámetros. parametros_default almacena la configuración base en formato JSONB para la inicialización y el entrenamiento de los algoritmos, evitando la fragmentación en múltiples tablas relacionales de variables técnicas.
R.3: Identificador Único de Modelo. codigo es un campo alfanumérico único en mayúsculas que identifica al modelo de forma abreviada. Debe tener al menos 3 caracteres y ser ingresado manualmente por el administrador del sistema.
R.4: Registro Inicial Comodín. El registro con modelo_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un modelo de referencia.
R.5: Tipos de Modelo. tipo_modelo_id utiliza el dominio TipoModeloID (1450-1455): ARIMA (1450), SARIMA (1451), SERIES_TEMPORALES (1452), CLASIFICACION (1453), OPTIMIZACION (1454), DETECCION_ANOMALIAS (1455).
R.6: Frameworks. framework_id utiliza el dominio FrameworkID (3000-3003): statsmodels (3000), scikit-learn (3001), tensorflow (3002), custom (3003).
R.7: Estado Operativo del Modelo. estado_modelo_id utiliza el dominio EstadoModeloID (2000-2004): SIN_DATOS (2000) cuando no hay suficientes datos históricos para entrenar, ENTRENANDO (2001) cuando el motor Python está calculando parámetros, ACTIVO (2002) cuando el modelo está entrenado y generando predicciones, RECHAZADO (2003) cuando el MAPE supera el umbral permitido, OBSOLETO (2004) cuando ha sido reemplazado por una versión más reciente. Este campo es independiente de estado_id y refleja el estado funcional del modelo.';

DELETE FROM modelos;
ALTER SEQUENCE modelos_modelo_id_seq RESTART WITH 1;

INSERT INTO modelos (modelo_id, codigo, nombre, tipo_modelo_id, descripcion, framework_id, framework_version, version, parametros_default, estado_modelo_id, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 1452, 'REGISTRO COMODIN POR DEFECTO', 3004, '0.0.0', '0.0.0', '{}'::jsonb, 2002, 1000, 1),
(2, 'ARIMA', 'ARIMA_CLASICO', 1452, 'Modelo ARIMA (Autoregressive Integrated Moving Average) para pronóstico de demanda sin componente estacional, útil para series temporales no estacionales', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(3, 'SARIMA', 'SARIMA_ESTACIONAL', 1452, 'Modelo SARIMA (Seasonal ARIMA) para pronóstico de demanda estacional con componentes autorregresivos, de diferenciación y promedio móvil estacional. Ideal para patrones semanales, mensuales o anuales', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(4, 'SARIMAX', 'SARIMAX_EXOGENO', 1452, 'Modelo SARIMAX (SARIMA con variables exógenas) que incorpora factores externos como clima, festivos, días especiales y campañas promocionales para mejorar la precisión del pronóstico', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "exog_variables": ["temperatura", "festivo", "dia_semana", "mes", "promocion"], "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(5, 'PROPHET', 'PROPHET_META', 1452, 'Modelo Prophet de Facebook/Meta para detección de estacionalidades múltiples (anual, semanal, diaria) y manejo de días festivos, ideal para patrones de consumo farmacéutico con múltiples estacionalidades', 3003, '1.1.5', '1.1.5', '{"growth": "linear", "yearly_seasonality": true, "weekly_seasonality": true, "daily_seasonality": false, "seasonality_mode": "additive", "changepoint_prior_scale": 0.05, "seasonality_prior_scale": 10.0, "holidays_prior_scale": 10.0, "interval_width": 0.95}'::jsonb, 2002, 1000, 1),
(6, 'PATRON', 'PATRON_CONSUMO', 1452, 'Modelo especializado en detección de patrones de consumo estacionales y tendencias de largo plazo para medicamentos, identificando picos por enfermedades estacionales (gripe, alergias, etc.)', 3003, '1.0.0', '1.0.0', '{"min_datos_entrenamiento": 90, "umbral_correlacion": 0.7, "ventana_deteccion": 30, "nivel_confianza": 0.95, "metrica_principal": "MAPE", "enfermedades_estacionales": ["gripe", "alergia", "dengue", "infecciones"]}'::jsonb, 2002, 1000, 1),
(7, 'KMEANS', 'KMEANS_ABC', 1453, 'Algoritmo K-Means Clustering para clasificación ABC de inventario multicriterio basado en costo, rotación, margen de ganancia y criticidad médica. Genera categorías A (alta prioridad), B (media) y C (baja)', 3001, '1.3.2', '1.3.2', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "n_init": 10, "algorithm": "lloyd", "criterios": ["costo", "rotacion", "margen", "criticidad"], "pesos": [0.30, 0.30, 0.20, 0.20], "etiquetas": ["A", "B", "C"]}'::jsonb, 2002, 1000, 1),
(8, 'CRITICIDAD', 'CLASIFICADOR_CRITICIDAD', 1453, 'Modelo para clasificar productos por nivel de criticidad médica basado en principios activos, uso, disponibilidad en el mercado y sustitutos disponibles', 3001, '1.3.2', '1.3.2', '{"niveles": ["CRITICO", "ALTO", "MEDIO", "BAJO"], "criterios": ["principio_activo", "frecuencia_uso", "disponibilidad", "sustitutos"], "random_state": 42, "pesos": [0.35, 0.30, 0.20, 0.15]}'::jsonb, 2002, 1000, 1),
(9, 'ROP', 'ROP_DINAMICO', 1454, 'Modelo para cálculo dinámico del Punto de Reorden (ROP) basado en demanda promedio histórica, lead time y stock de seguridad ajustable. Fórmula: ROP = (d * L) + SS', 3003, '2.0.0', '2.0.0', '{"lead_time_default": 7, "stock_seguridad_default": 10, "nivel_confianza": 0.95, "metrica_demanda": "media_movil", "ventana_dias": 30, "factor_estacional": true, "ajuste_estacional": 1.2}'::jsonb, 2002, 1000, 1),
(10, 'OPTSTOCK', 'OPTIMIZADOR_STOCK', 1454, 'Modelo de optimización de inventario que calcula niveles óptimos de stock mínimo, máximo y punto de reorden basado en costos de mantener vs. costos de quiebre (modelo EOQ adaptado)', 3003, '1.5.0', '1.5.0', '{"costo_mantener": 0.25, "costo_quiebre": 2.0, "lead_time_dias": 7, "ventana_historica": 180, "nivel_servicio": 0.95, "estacionalidad": true, "factor_estacional": 1.1}'::jsonb, 2002, 1000, 1),
(11, 'OPTCOMPRA', 'OPTIMIZADOR_COMPRAS', 1454, 'Modelo que optimiza las cantidades y fechas de compra considerando precios de proveedores, descuentos por volumen, costos de almacenamiento y restricciones de presupuesto', 3003, '1.0.0', '1.0.0', '{"ventana_optimizacion": 90, "costo_pedido": 50.0, "costo_mantener": 0.25, "descuentos_volumen": [[100, 0.05], [500, 0.10], [1000, 0.15]], "lead_time_proveedor": 5, "presupuesto_mensual": 10000.0, "minimo_pedido": 10}'::jsonb, 2002, 1000, 1),
(12, 'ANOMALIAS', 'DETECTOR_ANOMALIAS', 1455, 'Modelo para detección de anomalías en patrones de consumo, ventas y stock, identificando comportamientos atípicos que requieren atención inmediata (picos, caídas bruscas, estacionalidades rotas)', 3001, '1.3.2', '1.3.2', '{"contamination": 0.05, "n_neighbors": 20, "algorithm": "auto", "metric": "minkowski", "p": 2, "ventana_deteccion": 30, "umbral_anomalia": 0.8, "metodo": "LOF"}'::jsonb, 2002, 1000, 1),
(13, 'ALERTAS', 'ALERTAS_PREDICTIVAS', 1455, 'Modelo para generación de alertas tempranas basadas en desviaciones de los patrones esperados de demanda, stock y vencimientos. Detecta riesgo de quiebre de stock y excesos de inventario', 3003, '1.2.0', '1.2.0', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30, "ventana_historica": 90, "metricas_umbral": ["MAPE", "RMSE", "MAE"], "alertas": ["quiebre_stock", "exceso_stock", "vencimiento_proximo"]}'::jsonb, 2002, 1000, 1),
(14, 'PREDVENC', 'PREDICTOR_VENCIMIENTOS', 1452, 'Modelo especializado en pronosticar fechas de vencimiento de lotes basado en patrones históricos de consumo y rotación de inventario. Identifica lotes con riesgo de vencerse antes de ser vendidos', 3003, '1.0.0', '1.0.0', '{"dias_proyeccion": 180, "min_datos_consumo": 60, "umbral_riesgo_alto": 0.8, "umvald_riesgo_medio": 0.5, "incluir_estacionalidad": true, "factor_estacional": 1.15}'::jsonb, 2002, 1000, 1),
(15, 'ENSEMBLE', 'ENSEMBLE_FORECAST', 1452, 'Modelo Ensemble que combina predicciones de ARIMA, SARIMA, Prophet y otros modelos para mejorar la precisión del pronóstico mediante promedio ponderado y selección dinámica del mejor modelo', 3003, '1.0.0', '1.0.0', '{"modelos_ensemble": ["ARIMA_CLASICO", "SARIMA_ESTACIONAL", "PROPHET_META", "PATRON_CONSUMO"], "pesos": [0.20, 0.30, 0.25, 0.25], "metrica_optimizacion": "MAPE", "ventana_validacion": 30, "seleccion_dinamica": true}'::jsonb, 2002, 1000, 1),
(16, 'AUTOARIMA', 'AUTO_ARIMA', 1452, 'Modelo Auto-ARIMA que realiza búsqueda automática de los mejores parámetros (p, d, q, P, D, Q, s) utilizando criterios de información AIC/BIC. Ideal para automatizar el entrenamiento', 3000, '0.14.1', '0.14.1', '{"p_max": 5, "d_max": 2, "q_max": 5, "P_max": 2, "D_max": 1, "Q_max": 2, "s_max": 12, "criterio": "aic", "seasonal": true, "m": 7, "stepwise": true, "trace": false}'::jsonb, 2002, 1000, 1);

UPDATE modelos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE modelos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('modelos_modelo_id_seq', COALESCE((SELECT MAX(modelo_id) FROM modelos), 1));

-- ================================================================================================

CREATE TABLE entrenamientos (
    entrenamiento_id BIGSERIAL PRIMARY KEY,
    modelo_id BIGINT NOT NULL DEFAULT 1,
    fecha_ejecucion TIMESTAMPTZ NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NULL,
    estado_ejecucion_id INTEGER NOT NULL DEFAULT 3053,   -- 3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO, 3053=NINGUNO
    duracion_segundos INTEGER NULL,
    registros_procesados BIGINT NULL,
    total_esperado BIGINT NULL,
    mensaje_error TEXT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ent_modelo_id FOREIGN KEY (modelo_id) REFERENCES modelos(modelo_id),
    CONSTRAINT fk_ent_estado_ejecucion_id FOREIGN KEY (estado_ejecucion_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_ent_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ent_duracion CHECK (duracion_segundos >= 0),
    CONSTRAINT chk_ent_registros CHECK (registros_procesados IS NULL OR registros_procesados >= 0),
    CONSTRAINT chk_ent_total_esperado CHECK (total_esperado IS NULL OR total_esperado >= 0),
    CONSTRAINT chk_ent_fechas_coherentes CHECK (
        fecha_inicio <= fecha_ejecucion AND
        (fecha_fin IS NULL OR fecha_ejecucion <= fecha_fin) AND
        (fecha_fin IS NULL OR fecha_inicio <= fecha_fin)
    )
);
CREATE INDEX idx_ent_modelo_id ON entrenamientos (modelo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ent_fecha_ejecucion ON entrenamientos (fecha_ejecucion DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ent_estado_ejecucion ON entrenamientos (estado_ejecucion_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE entrenamientos IS 'Reglas de la tabla - entrenamientos
R.0: La tabla entrenamientos registra la ejecución histórica de los procesos de entrenamiento de los modelos de IA, almacenando su fecha, duración y estado. Su propósito es proveer trazabilidad sobre el rendimiento y la ejecución de los modelos, permitiendo auditar el proceso de aprendizaje y vincularlo a las métricas de precisión resultantes. Se conecta directamente con las tablas modelos, metricas_rendimiento, patrones_consumo, logs_ejecucion y dominios (estado de ejecución).
R.1: Control del Flujo de Ejecución. estado_ejecucion_id administra el progreso operativo del entrenamiento del modelo (3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO), definiendo la disponibilidad de métricas en el sistema.
R.2: Registro Desconectado de Errores. Si estado_ejecucion_id = 3052 (FALLIDO), el backend persistirá el detalle del rastro técnico en mensaje_error para fines de depuración de hiperparámetros sin interrumpir la consistencia lógica de la tabla.
R.3: Registro Inicial Comodín. El registro con entrenamiento_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO) y estado_ejecucion_id = 3051 (COMPLETADO). Sirve como valor predeterminado para las FK que requieran un entrenamiento de referencia.
R.4: Validación de Fechas. fecha_inicio debe ser anterior a fecha_fin cuando el entrenamiento esté completado. fecha_ejecucion es la fecha de registro del entrenamiento en el sistema.
R.5: Métricas de Rendimiento. duracion_segundos y registros_procesados se actualizan automáticamente al finalizar el entrenamiento. El backend debe calcular duracion_segundos = EXTRACT(EPOCH FROM (fecha_fin - fecha_inicio)) cuando estado_ejecucion_id = 3051 (COMPLETADO).
R.6: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, HISTORICO). Un entrenamiento en estado HISTORICO no puede ser modificado.';

DELETE FROM entrenamientos;
ALTER SEQUENCE entrenamientos_entrenamiento_id_seq RESTART WITH 1;

INSERT INTO entrenamientos (entrenamiento_id, modelo_id, fecha_ejecucion, fecha_inicio, fecha_fin, estado_ejecucion_id, duracion_segundos, registros_procesados, total_esperado, mensaje_error, estado_id, usuario_id_registro) VALUES
(1, 1, '2026-07-16 14:00:00-04', '2026-07-16 13:55:00-04', '2026-07-16 14:00:00-04', 3051, 300, 15000, 15000, NULL, 1000, 1);

UPDATE entrenamientos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE entrenamientos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('entrenamientos_entrenamiento_id_seq', COALESCE((SELECT MAX(entrenamiento_id) FROM entrenamientos), 1));

-- ================================================================================================

CREATE TABLE metricas_rendimiento (
    metrica_id BIGSERIAL PRIMARY KEY,
    entrenamiento_id BIGINT NOT NULL DEFAULT 1,
    tipo_metricas_id INTEGER NOT NULL DEFAULT 3103,          	-- 3100=REGRESION, 3101=CLASIFICACION, 3102=CLUSTERING, 3103=NINGUNO
    metrica_precision_id INTEGER NULL DEFAULT 3600,            	-- 3600=MAE, 3601=RMSE, 3602=MAPE, 3603=R2, 3604=F1
    factor_estacionalidad_id INTEGER NULL DEFAULT 3650,        	-- 3650=NONE, 3651=DIARIO, 3652=SEMANAL, 3653=MENSUAL, 3654=ANUAL, 3655=MULTIPLE
    version_metricas INTEGER NOT NULL DEFAULT 1,
    modelo_version VARCHAR(20) NOT NULL DEFAULT '0.0.0',
    fecha_evaluacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    periodo_evaluacion DATE NOT NULL DEFAULT CURRENT_DATE,
    error_absoluto_medio DECIMAL(10,4) NULL,
    raiz_error_cuadratico_medio DECIMAL(10,4) NULL,
    score_principal DECIMAL(5,4) NULL,
    detalles_metricas JSONB NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,                	-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_met_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT fk_met_tipo_metricas_id FOREIGN KEY (tipo_metricas_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_met_metrica_precision_id FOREIGN KEY (metrica_precision_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_met_factor_estacionalidad_id FOREIGN KEY (factor_estacionalidad_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_met_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_met_error_abs CHECK (error_absoluto_medio IS NULL OR error_absoluto_medio >= 0),
    CONSTRAINT chk_met_raiz_error CHECK (raiz_error_cuadratico_medio IS NULL OR raiz_error_cuadratico_medio >= 0),
    CONSTRAINT chk_met_score_principal CHECK (score_principal IS NULL OR score_principal >= 0),
    CONSTRAINT chk_met_al_menos_una_metrica CHECK (
        metrica_precision_id IS NOT NULL OR
        error_absoluto_medio IS NOT NULL OR
        raiz_error_cuadratico_medio IS NOT NULL OR
        score_principal IS NOT NULL OR
        detalles_metricas IS NOT NULL
    )
);

CREATE INDEX idx_met_entrenamiento_id ON metricas_rendimiento (entrenamiento_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_met_tipo_metricas ON metricas_rendimiento (tipo_metricas_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_met_fecha_evaluacion ON metricas_rendimiento (fecha_evaluacion DESC) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE metricas_rendimiento IS 'Reglas de la tabla - metricas_rendimiento
R.0: La tabla metricas_rendimiento cuantifica la precisión de los modelos de IA, almacenando indicadores clave como MAPE, RMSE, R2 y otras métricas de error. Su propósito es evaluar objetivamente el desempeño de los modelos predictivos, permitiendo la comparación entre diferentes algoritmos y versiones para elegir el mejor modelo para producción. Se conecta directamente con las tablas entrenamientos y dominios (tipo de métrica, precisión, estacionalidad).
R.1: Trazabilidad y Versión de Métricas. Cada evaluación de rendimiento almacena explícitamente su version_metricas, modelo_version, periodo_evaluacion y fecha_evaluacion, permitiendo auditorías retrospectivas cuando los hiperparámetros o las fórmulas subyacentes de los modelos de pronóstico cambien.
R.2: Desglose Híbrido Estructurado-JSONB. Las métricas críticas para reportes rápidos (MAE, RMSE y score principal) se almacenan en columnas planas indexadas, mientras que los coeficientes complejos específicos del algoritmo residen opcionalmente en detalles_metricas.
R.3: Ciclo de Vida Lógico. La entidad utiliza estado_id para mantener el histórico de entrenamiento de la IA sin perder trazabilidad ante eliminaciones lógicas.
R.4: Registro Comodín. El registro con metrica_id = 1 actúa como valor por defecto con estado_id = 1002 para aquellas relaciones que requieran un apuntador de respaldo seguro.
R.5: Estandarización de Métricas de Precisión. metrica_precision_id permite identificar el tipo de métrica de precisión utilizada (MAE, RMSE, MAPE, R2, F1), facilitando la comparación entre diferentes entrenamientos y modelos. Puede ser NULL si la métrica está definida en detalles_metricas.
R.6: factor_estacionalidad_id define el tipo de estacionalidad considerada durante la evaluación del modelo. Puede ser NULL si no aplica.
R.7: La combinación de tipo_metricas_id y metrica_precision_id debe ser coherente con el tipo de modelo evaluado. El backend valida que las métricas correspondan al tipo de problema (regresión, clasificación o clustering).';

DELETE FROM metricas_rendimiento;
ALTER SEQUENCE metricas_rendimiento_metrica_id_seq RESTART WITH 1;

INSERT INTO metricas_rendimiento (metrica_id, entrenamiento_id, tipo_metricas_id, metrica_precision_id, version_metricas, modelo_version, periodo_evaluacion, error_absoluto_medio, raiz_error_cuadratico_medio, score_principal, detalles_metricas, estado_id, usuario_id_registro) VALUES
(1, 1, 3103, 3600, 1, '0.0.0', CURRENT_DATE, 0.0000, 0.0000, 0.0000, '{"comodin": true}'::jsonb, 1000, 1);

UPDATE metricas_rendimiento SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE metricas_rendimiento SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('metricas_rendimiento_metrica_id_seq', COALESCE((SELECT MAX(metrica_id) FROM metricas_rendimiento), 1));

-- ================================================================================================

CREATE TABLE patrones_consumo (
    patron_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    entrenamiento_id BIGINT NOT NULL DEFAULT 1,
    temporada_id INTEGER NULL DEFAULT 1600,  			-- 1600=NINGUNO, 1601=ALTA, 1602=MEDIA, 1603=BAJA
    tipo_patron_id INTEGER NOT NULL DEFAULT 4200,		-- 4200=DEMANDA
	evento VARCHAR(200) NULL,
    factor_estacional DECIMAL(5,2) NULL,
    coeficiente_tendencia DECIMAL(5,2) NULL,
    fecha_inicio DATE NULL,
    fecha_fin DATE NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pat_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_pat_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_pat_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT fk_pat_temporada_id FOREIGN KEY (temporada_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_pat_tipo_patron_id FOREIGN KEY (tipo_patron_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_pat_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pat_evento_min CHECK (evento IS NULL OR LENGTH(TRIM(evento)) >= 3),
    CONSTRAINT chk_pat_fechas CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_inicio <= fecha_fin)
);
CREATE UNIQUE INDEX uix_pat_producto_sucursal_entrenamiento_tipo ON patrones_consumo (producto_id, sucursal_id, entrenamiento_id, tipo_patron_id, fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pat_producto_id ON patrones_consumo (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pat_sucursal_id ON patrones_consumo (sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pat_temporada ON patrones_consumo (temporada_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE patrones_consumo IS 'Reglas de la tabla - patrones_consumo
R.0: La tabla patrones_consumo almacena los factores estacionales y de tendencia identificados para un producto en una sucursal específica, como resultado de un entrenamiento de IA. Su propósito es capturar el comportamiento cíclico de la demanda, ajustando las predicciones futuras y los puntos de reorden para adaptarse a la realidad de cada mercado local. Se conecta directamente con las tablas productos, sucursales, entrenamientos y dominios (temporada).
R.1: Control de Elasticidad Comercial. factor_estacional y coeficiente_tendencia gestionan las fluctuaciones estacionales de la demanda, resguardando las variaciones cíclicas del mercado boliviano (ej. Feriado de San Juan o Todos Santos) de forma acumulativa y perenne.
R.2: Unicidad de Factores Multiplicadores. Para prevenir distorsiones en las proyecciones de inventario, la restricción uix_pat_producto_sucursal_entrenamiento restringe la existencia de más de un factor multiplicador activo para la misma combinación de artículo, punto de venta y ejecución analítica.
R.3: Registro Inicial Comodín. El registro con patron_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un patrón de consumo de referencia.
R.4: Clasificación Estacional. temporada_id utiliza el dominio TemporadaID (1600-1603): NINGUNA (1600) para patrones sin estacionalidad definida, ALTA (1601) para temporada de demanda alta, MEDIA (1602) para demanda regular, BAJA (1603) para demanda baja.
R.5: Control de Fechas. fecha_inicio y fecha_fin definen el período de vigencia del patrón estacional. El backend debe validar que fecha_fin >= fecha_inicio cuando ambos estén definidos.
R.6: Factor Estacional. factor_estacional es un multiplicador que ajusta la demanda esperada durante el período definido. Un valor de 1.25 indica un incremento del 25% en la demanda. coeficiente_tendencia representa la tendencia lineal de largo plazo.';

DELETE FROM patrones_consumo;
ALTER SEQUENCE patrones_consumo_patron_id_seq RESTART WITH 1;

INSERT INTO patrones_consumo (patron_id, producto_id, sucursal_id, entrenamiento_id, temporada_id, evento, factor_estacional, coeficiente_tendencia, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1600, 'NINGUNO', 0.00, 0.00, NULL, NULL, 1000, 1);

UPDATE patrones_consumo SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE patrones_consumo SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('patrones_consumo_patron_id_seq', COALESCE((SELECT MAX(patron_id) FROM patrones_consumo), 1));

-- ================================================================================================

CREATE TABLE variables_exogenas (
    variable_exogena_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    fuente_exogena_id INTEGER NOT NULL DEFAULT 4250,    -- 4250=SENAMHI, 4251=INE, 4252=BCB, 4253=API_CLIMA, 4254=CALENDARIO_FESTIVOS, 4255=CUSTOM
    nombre_variable VARCHAR(100) NOT NULL,
    valor DECIMAL(10,4) NOT NULL,
    fecha_variable DATE NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_veg_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_veg_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_veg_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_veg_fuente_exogena_id FOREIGN KEY (fuente_exogena_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_veg_nombre_variable_min CHECK (LENGTH(TRIM(nombre_variable)) >= 3)
);

CREATE UNIQUE INDEX uix_veg_sucursal_producto_fecha_variable ON variables_exogenas (sucursal_id, producto_id, fecha_variable, nombre_variable) WHERE estado_id IN (1000, 1002) AND producto_id != 1;
CREATE INDEX idx_veg_sucursal_fecha ON variables_exogenas (sucursal_id, fecha_variable DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_veg_fecha_variable ON variables_exogenas (fecha_variable DESC) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE variables_exogenas IS 'Reglas de la tabla - variables_exogenas
R.0: La tabla variables_exogenas almacena datos externos que influyen en la demanda de productos, como temperatura, precios de moneda o días festivos. Su propósito es enriquecer los modelos de pronóstico (como SARIMAX) con factores causales que mejoran significativamente la precisión de las predicciones de demanda. Se conecta directamente con las tablas productos y sucursales.
R.1: Control Coherente de Factores Externos. El registro continuo de indicadores macroeconómicos, climáticos o ambientales se asocia de forma inalterable a estado_id para salvaguardar el histórico multivariable, alimentando el motor de predicción sin particionamiento físico por periodos anuales.
R.2: Trazabilidad de Origen Técnico. fuente_exogena_id opera como un atributo obligatorio normalizado mediante la tabla dominios, garantizando la procedencia e institucionalidad de las series externas (ej. INE o SENAMHI).
R.3: Registro Inicial Comodín. El registro con variable_exogena_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran una variable exógena de referencia.
R.4: Unicidad de Variables por Período. La restricción uix_veg_sucursal_producto_fecha_variable garantiza que no existan duplicados de la misma variable para la misma combinación de sucursal, producto y fecha.
R.5: Control de Fechas. fecha_variable registra la fecha a la que corresponde el valor de la variable. El backend debe validar que fecha_variable <= CURRENT_DATE para variables históricas.
R.6: Ejemplos de Variables Exógenas. nombre_variable puede contener valores como "Temperatura Promedio C", "Precio Dolar", "Inflacion", "Festivo", etc.
R.7: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, HISTORICO).';

DELETE FROM variables_exogenas;
ALTER SEQUENCE variables_exogenas_variable_exogena_id_seq RESTART WITH 1;

INSERT INTO variables_exogenas (variable_exogena_id, producto_id, sucursal_id, fuente_exogena_id, nombre_variable, valor, fecha_variable, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 4250, 'NINGUNO', 0.0000, '2000-01-01', 1000, 1);

UPDATE variables_exogenas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE variables_exogenas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('variables_exogenas_variable_exogena_id_seq', COALESCE((SELECT MAX(variable_exogena_id) FROM variables_exogenas), 1));

-- ================================================================================================

CREATE TABLE umbrales_configuracion (
    umbral_id BIGSERIAL PRIMARY KEY,
    tipo_umbral_id INTEGER NOT NULL DEFAULT 3253,  		-- 3250=STOCK_MINIMO, 3251=DIAS_VENCIMIENTO, 3252=ERROR_PREDICCION, 3253=NINGUNO
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    valor_umbral DECIMAL(12,2) NOT NULL,
    nivel_urgencia_id INTEGER NOT NULL DEFAULT 1854,  	-- 1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO
    activo INTEGER NOT NULL DEFAULT 1,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_umb_tipo_umbral_id FOREIGN KEY (tipo_umbral_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_umb_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_umb_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_umb_nivel_urgencia_id FOREIGN KEY (nivel_urgencia_id) REFERENCES dominios(dominio_id),
	CONSTRAINT fk_umb_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_umb_activo CHECK (activo IN (0, 1)),
    CONSTRAINT chk_umb_valor_umbral CHECK (valor_umbral >= 0)
);
CREATE UNIQUE INDEX uix_umb_tipo_producto_sucursal_activo ON umbrales_configuracion (tipo_umbral_id, producto_id, sucursal_id) WHERE estado_id IN (1000, 1002) AND activo = 1 AND NOT (producto_id = 1 AND sucursal_id = 1);
CREATE UNIQUE INDEX uix_umb_tipo_global_activo ON umbrales_configuracion (tipo_umbral_id) WHERE estado_id IN (1000, 1002) AND activo = 1 AND producto_id = 1 AND sucursal_id = 1;

COMMENT ON TABLE umbrales_configuracion IS 'Reglas de la tabla - umbrales_configuracion
R.0: La tabla umbrales_configuracion define los límites operativos para alertas automáticas (stock mínimo, días de vencimiento, error de predicción) por producto y sucursal. Su propósito es parametrizar las condiciones que disparan notificaciones en el sistema, permitiendo ajustar la sensibilidad de las alarmas según la criticidad y el nivel de urgencia del negocio. Se conecta directamente con las tablas productos, sucursales y dominios (tipo de umbral, nivel de urgencia).
R.1: Persistencia Continua de Alertas. Los valores críticos, límites de tolerancia operativa y márgenes de desviación matemática no se segmentan temporalmente ni duplican por cierres de gestión anual, gestionando su vigencia mediante estado_id.
R.2: Unicidad de Configuración Activa. Para evitar colisiones en las alertas automáticas y notificaciones en el backend, no se permite la coexistencia de más de un parámetro configurado como vigente y activo (activo = 1) para el mismo tipo de umbral, artículo y sucursal de manera simultánea.
R.3: Registro Inicial Comodín. El registro con umbral_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un umbral de referencia.
R.4: Tipos de Umbral. tipo_umbral_id utiliza el dominio TipoUmbralID (3250-3252): STOCK_MINIMO (3250) define el stock mínimo antes de generar alerta, DIAS_VENCIMIENTO (3251) define días antes del vencimiento para alerta, ERROR_PREDICCION (3252) define el error máximo permitido en predicciones.
R.5: Control de Activación. activo = 1 indica que el umbral está activo y genera alertas. activo = 0 desactiva el umbral temporalmente sin eliminar la configuración.
R.6: Valor del Umbral. valor_umbral es el valor numérico que dispara la alerta. Su interpretación depende del tipo_umbral_id: para STOCK_MINIMO es la cantidad mínima, para DIAS_VENCIMIENTO es el número de días, para ERROR_PREDICCION es el porcentaje de error máximo permitido.';

DELETE FROM umbrales_configuracion;
ALTER SEQUENCE umbrales_configuracion_umbral_id_seq RESTART WITH 1;

INSERT INTO umbrales_configuracion (umbral_id, tipo_umbral_id, producto_id, sucursal_id, valor_umbral, nivel_urgencia_id, activo, estado_id, usuario_id_registro) VALUES
(1, 3253, 1, 1, 0.00, 1854, 0, 1000, 1);

UPDATE umbrales_configuracion SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE umbrales_configuracion SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('umbrales_configuracion_umbral_id_seq', COALESCE((SELECT MAX(umbral_id) FROM umbrales_configuracion), 1));

-- ================================================================================================

CREATE TABLE logs_ejecucion (
    log_id BIGSERIAL PRIMARY KEY,
    entrenamiento_id BIGINT NOT NULL DEFAULT 1,
    modulo VARCHAR(100) NOT NULL,
    nivel_log_id INTEGER NOT NULL DEFAULT 3150,          -- 3150=INFO, 3151=WARNING, 3152=ERROR, 3153=DEBUG
    mensaje TEXT NOT NULL,
    detalle JSONB NOT NULL DEFAULT '{}'::jsonb,
    fecha_log TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_log_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT fk_log_nivel_log_id FOREIGN KEY (nivel_log_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_log_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_log_modulo_min CHECK (LENGTH(TRIM(modulo)) >= 3)
);
CREATE INDEX idx_log_entrenamiento_id ON logs_ejecucion (entrenamiento_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_log_nivel_log ON logs_ejecucion (nivel_log_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_log_modulo_nivel ON logs_ejecucion (modulo, nivel_log_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE logs_ejecucion IS 'Reglas de la tabla - logs_ejecucion
R.0: La tabla logs_ejecucion es la bitácora técnica que almacena los eventos, advertencias y errores generados durante los procesos del sistema, especialmente durante los entrenamientos de IA. Su propósito es proveer un registro detallado para la depuración, el monitoreo de la salud del sistema y la trazabilidad de los procesos batch y analíticos. Se conecta directamente con las tablas entrenamientos y dominios (nivel de log).
R.1: Control Continuo de Trazabilidad. El almacenamiento cronológico de la bitácora operativa y las excepciones del motor analítico se administra centralizadamente mediante estado_id, asegurando la preservación persistente del histórico técnico sin segmentación de esquemas anuales.
R.2: Estructura No Estricta de Depuración. detalle en formato JSONB resguarda de forma dinámica el contexto técnico extendido (ej. pilas de ejecución o variables internas del modelo), operando de manera desacoplada sin imponer validaciones rígidas estructurales a nivel de motor de base de datos, inicializándose por defecto como objeto vacío.
R.3: Registro Inicial Comodín. El registro con log_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un log de ejecución de referencia.
R.4: Niveles de Log. nivel_log_id utiliza el dominio NivelLogID (3150-3153): INFO (3150) para información general, WARNING (3151) para advertencias, ERROR (3152) para errores, DEBUG (3153) para depuración.
R.5: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, HISTORICO). Un log en estado HISTORICO no puede ser modificado.
R.6: Fecha de Log. fecha_log registra la fecha y hora exacta en que ocurrió el evento. fecha_registro es la fecha de inserción en la base de datos, que puede diferir ligeramente por latencia de red o procesamiento.';

DELETE FROM logs_ejecucion;
ALTER SEQUENCE logs_ejecucion_log_id_seq RESTART WITH 1;

INSERT INTO logs_ejecucion (log_id, entrenamiento_id, modulo, nivel_log_id, mensaje, detalle, fecha_log, estado_id, usuario_id_registro) VALUES
(1, 1, 'PROCESAMIENTO_ARIMA', 3150, 'Inicio de analisis estacional', '{"productos": 12, "duracion_seg": 45}'::jsonb, CURRENT_TIMESTAMP, 1000, 1);

UPDATE logs_ejecucion SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE logs_ejecucion SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('logs_ejecucion_log_id_seq', COALESCE((SELECT MAX(log_id) FROM logs_ejecucion), 1));

-- ================================================================================================

CREATE TABLE analitica_productos (
    analitica_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL,
    sucursal_id BIGINT NOT NULL,
    demanda_pronosticada DECIMAL(12,2) NULL,
    intervalo_inf DECIMAL(12,2) NULL,
    intervalo_sup DECIMAL(12,2) NULL,
    fecha_prediccion DATE NULL,
    periodo_inicio DATE NULL,
    periodo_fin DATE NULL,
    fecha_vencimiento_critico DATE NULL,
    nivel_urgencia_id INTEGER NULL DEFAULT 1854,         -- 1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO
    punto_reorden DECIMAL(12,2) NULL,
    stock_seguridad DECIMAL(12,2) NULL,
    lead_time_dias INTEGER NULL,
    cluster_abc INTEGER NULL,
    fecha_clasificacion DATE NOT NULL DEFAULT CURRENT_DATE,
    puntaje_total DECIMAL(12,2) NULL,
    estado_pronostico_id INTEGER NOT NULL DEFAULT 1553, -- 1550=PENDIENTE, 1551=PROCESADO, 1552=ERROR, 1553=NINGUNO
    motivo_outlier_id INTEGER NULL DEFAULT 1907,        -- 1900=BLOQUEO, 1901=FERIADO_LOCAL, 1902=ERROR_SISTEMA, 1903=PICO_ANORMAL, 1904=ROTURA, 1905=ROBO, 1906=SOBRANTE, 1907=NINGUNO
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_an_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_an_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_an_nivel_urgencia_id FOREIGN KEY (nivel_urgencia_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_an_estado_pronostico_id FOREIGN KEY (estado_pronostico_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_an_motivo_outlier_id FOREIGN KEY (motivo_outlier_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_an_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_an_periodo CHECK (periodo_inicio IS NULL OR periodo_fin IS NULL OR periodo_inicio <= periodo_fin)
);
CREATE INDEX idx_an_producto_sucursal_fecha ON analitica_productos (producto_id, sucursal_id, fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_an_producto_id ON analitica_productos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_an_sucursal_id ON analitica_productos (sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_an_cluster ON analitica_productos (cluster_abc) WHERE cluster_abc IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_an_fecha_clasificacion ON analitica_productos (fecha_clasificacion DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_an_nivel_urgencia ON analitica_productos (nivel_urgencia_id) WHERE nivel_urgencia_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_an_vencimiento ON analitica_productos (fecha_vencimiento_critico) WHERE fecha_vencimiento_critico IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_an_estado_pronostico ON analitica_productos (estado_pronostico_id) WHERE estado_pronostico_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_an_motivo_outlier ON analitica_productos (motivo_outlier_id) WHERE motivo_outlier_id IS NOT NULL AND estado_id IN (1000, 1002);

COMMENT ON TABLE analitica_productos IS 'Reglas de la tabla - analitica_productos
R.0: La tabla analitica_productos es el repositorio central de todos los resultados analíticos generados por el motor de inteligencia artificial y aprendizaje automático para cada producto y sucursal. Su propósito es consolidar en un solo lugar las predicciones de demanda, los puntos de reorden dinámicos, el stock de seguridad calculado, la clasificación ABC de inventario y las alertas de vencimiento crítico. Esta tabla actúa como el puente entre el motor de IA (entrenamientos, modelos, métricas) y la operación diaria del negocio (compras, inventario, ventas), proporcionando inteligencia accionable para la toma de decisiones estratégicas y tácticas en tiempo real. Se conecta directamente con las tablas productos, sucursales y dominios para garantizar la integridad referencial y la trazabilidad completa de los análisis.
R.1: Periodicidad y Actualización de Datos. Cada registro en esta tabla representa un análisis o pronóstico realizado para un producto y sucursal en un momento específico. El sistema puede generar múltiples registros por producto/sucursal a lo largo del tiempo, permitiendo el seguimiento histórico de la evolución de las predicciones y la comparación de diferentes modelos. La frecuencia de actualización depende de la configuración de tareas programadas (tareas_programadas) y puede ser diaria, semanal o mensual según la estrategia de negocio.
R.2: Predicción de Demanda y Rangos de Confianza. Los campos demanda_pronosticada, intervalo_inf y intervalo_sup representan la predicción puntual y el intervalo de confianza (generalmente al 95%) generados por los modelos de series temporales (ARIMA, SARIMA, Prophet, etc.). El sistema debe garantizar que intervalo_inf <= demanda_pronosticada <= intervalo_sup. El backend debe calcular estos valores durante el proceso de entrenamiento y almacenarlos automáticamente. La precisión de estas predicciones se mide mediante las métricas almacenadas en metricas_rendimiento.
R.3: Control de Estados del Pronóstico. estado_pronostico_id gestiona el ciclo de vida del análisis:
- 1550 (PENDIENTE): Pronóstico en cola de espera o en proceso de cálculo. No debe mostrarse en dashboards operativos.
- 1551 (PROCESADO): Pronóstico completado exitosamente con todos los datos calculados (demanda, ROP, stock, etc.). Es el estado operativo para consumo en el negocio.
- 1552 (ERROR): Pronóstico fallido. Puede deberse a datos insuficientes, errores en el modelo o fallos técnicos. Requiere revisión manual en logs_ejecucion.
- 1553 (NINGUNO): Estado por defecto para registros comodín o productos que no han sido procesados por el motor de IA.
El backend debe cambiar automáticamente el estado a PROCESADO al finalizar exitosamente el entrenamiento y a ERROR si ocurre alguna excepción durante el proceso.
R.4: Clasificación ABC de Inventario. cluster_abc almacena el resultado de la clasificación multicriterio de productos (A, B, C) basada en algoritmos de clustering (K-Means, RFM) o reglas de negocio. Los valores posibles son:
- 1: Productos de categoría A (alta prioridad, alta rotación, alto valor, críticos para el negocio)
- 2: Productos de categoría B (prioridad media, rotación regular, valor moderado)
- 3: Productos de categoría C (baja prioridad, baja rotación, bajo valor)
- 0: Sin clasificar o cuando la clasificación no ha sido generada aún
Este campo se actualiza periódicamente (generalmente mensualmente) mediante tareas programadas y sirve como base para estrategias de compras, promociones y gestión de inventario.
R.5: Optimización de Inventario - Punto de Reorden y Stock de Seguridad. punto_reorden (ROP) y stock_seguridad son calculados automáticamente por los modelos de optimización (ROP_DINAMICO, OPTIMIZADOR_STOCK) basándose en:
- Demanda promedio histórica (ventana configurable)
- Lead time (tiempo de entrega del proveedor)
- Nivel de servicio deseado (configurable en parametros_globales)
- Estacionalidad detectada en patrones_consumo
- Desviación estándar de la demanda
El sistema debe actualizar estos valores automáticamente y generar alertas cuando el stock actual caiga por debajo del punto_reorden (a través de alertas_notificaciones).
R.6: Control de Lead Time. lead_time_dias representa el tiempo promedio en días que tarda el proveedor en entregar el producto después de realizar un pedido. Este valor puede ser:
- Específico por producto/sucursal (calculado históricamente)
- Heredado del proveedor principal (proveedores.plazo_entrega_dias)
- Valor por defecto de parametros_globales (modelo_rop_lead_time_default)
El sistema debe usar este valor para calcular el punto de reorden y las fechas estimadas de llegada de nuevas compras.
R.7: Gestión de Fechas Críticas y Vencimientos. fecha_vencimiento_critico identifica la fecha más temprana de vencimiento entre todos los lotes activos del producto en la sucursal. El sistema debe:
- Calcular automáticamente esta fecha a partir de lotes_productos.fecha_vencimiento
- Actualizar el campo cuando se registren nuevas compras o se vendan lotes
- Generar alertas según los umbrales configurados (dias_alerta_vencimiento_critico, etc.)
- Si fecha_vencimiento_critico < CURRENT_DATE + 15 días, nivel_urgencia_id debe ser 1853 (CRITICA) automáticamente
R.8: Nivel de Urgencia. nivel_urgencia_id clasifica la criticidad operativa del producto basada en múltiples factores:
- 1854 (NINGUNO): Producto sin urgencia o sin análisis
- 1853 (CRITICA): Quiebre de stock inminente, vencimiento inmediato (15 días), demanda alta inusual
- 1852 (ALTA): Stock bajo (cerca del punto de reorden), vencimiento próximo (30 días)
- 1851 (MEDIA): Producto con tendencia de consumo creciente, vencimiento moderado (60 días)
- 1850 (BAJA): Producto con demanda estable, stock suficiente, vencimiento lejano
El sistema debe calcular automáticamente este valor durante cada ejecución analítica y actualizarlo en función de las alertas generadas.
R.9: Detección y Gestión de Outliers. motivo_outlier_id documenta la causa de un pronóstico en estado ERROR (1552) o cuando se detectan anomalías significativas en los patrones de consumo:
- 1900 (BLOQUEO): Bloqueo de caminos, protestas, desastres naturales
- 1901 (FERIADO_LOCAL): Día festivo no considerado en el calendario estándar
- 1902 (ERROR_SISTEMA): Fallos en integración de datos, registros inconsistentes
- 1903 (PICO_ANORMAL): Evento puntual de demanda excepcional (epidemia, campaña)
- 1904 (ROTURA): Producto dañado o deteriorado
- 1905 (ROBO): Sustracción de mercadería
- 1906 (SOBRANTE): Excedente detectado en inventario físico
- 1907 (NINGUNO): Sin motivo o cuando no se aplica
Este campo es obligatorio cuando estado_pronostico_id = 1552 (ERROR) y debe ser registrado por el sistema o por el usuario encargado.
R.10: Puntaje Total y Clasificación Multidimensional. puntaje_total es un valor calculado que combina múltiples dimensiones del producto para generar una puntuación compuesta que refleja su importancia estratégica. Los factores considerados incluyen:
- Rotación del producto (cantidad vendida por período)
- Margen de ganancia (precio_venta - pcompra)
- Criticidad médica (criticidad_medica_id)
- Frecuencia de quiebres de stock (alertas generadas)
- Importancia estratégica para la sucursal
Este puntaje se utiliza para priorizar acciones de compra, promociones y asignación de recursos.
R.11: Período de Predicción. periodo_inicio y periodo_fin definen el horizonte temporal de la predicción de demanda. El sistema debe garantizar que:
- periodo_inicio <= periodo_fin (validado por chk_an_periodo)
- El período de predicción no supere el límite configurado en parametros_globales (dias_proyeccion)
- Los campos pueden ser NULL si la predicción es puntual (sin horizonte definido)
- Para predicciones mensuales, periodo_inicio = primer día del mes y periodo_fin = último día del mes
R.12: Inmutabilidad y Trazabilidad Histórica. Los registros en esta tabla son inmutables una vez completados (estado_pronostico_id = 1551 - PROCESADO). No se permiten operaciones UPDATE sobre campos de resultados (demanda, ROP, stock, etc.) después de su generación. Las correcciones deben realizarse mediante un nuevo registro con una nueva fecha_prediccion. El campo estado_id sigue el ciclo de vida estándar (ACTIVO, BORRADO, HISTORICO) para gestionar la vigencia de los análisis.
R.13: Registro Comodín. El registro con analitica_id = 1 es un registro histórico con estado_id = 1000 (ACTIVO) y estado_pronostico_id = 1553 (NINGUNO). Sirve como valor predeterminado para las FK que requieran un análisis de referencia. Este registro no puede ser modificado ni eliminado y se excluye automáticamente de reportes y dashboards operativos.
R.14: Integración con Otras Tablas. Esta tabla se integra con múltiples módulos del sistema:
- tareas_programadas: Las tareas de tipo FORECASTING generan registros automáticos en esta tabla
- entrenamientos: Cada ejecución de entrenamiento actualiza los registros en analitica_productos
- metricas_rendimiento: Las métricas calculadas se asocian a los pronósticos generados
- alertas_notificaciones: Los umbrales y niveles de urgencia disparan alertas automáticas
- umbrales_configuracion: Los valores de umbral (stock mínimo, error, etc.) definen los límites de actuación
- patrones_consumo: Los patrones estacionales detectados influyen en los cálculos de demanda y ROP
R.15: Política de Retención de Datos. Dado que esta tabla puede crecer rápidamente con ejecuciones diarias/semanales, el sistema debe implementar una política de retención:
- Mantener datos de los últimos 12 meses en estado ACTIVO
- Históricos de 12-36 meses en estado HISTORICO (accesibles para reporting)
- Datos de más de 36 meses pueden ser archivados o eliminados después de validación
- Esta política debe ser configurable en parametros_globales
R.16: Actualización Automática de Punto de Reorden y Stock de Seguridad. Cuando el motor de IA genera una nueva predicción de demanda, el sistema debe automáticamente:
- Actualizar productos.punto_reorden con el valor calculado (si es mayor que el actual)
- Actualizar productos.stock_minimo con el valor de stock_seguridad
- Si el punto_reorden recomendado supera el stock_minimo actual, generar una alerta en alertas_notificaciones
- Registrar el cambio en logs_ejecucion para trazabilidad
R.17: Validación de Datos de Entrada. Antes de almacenar un pronóstico, el backend debe validar:
- demanda_pronosticada >= 0
- intervalo_inf >= 0 y intervalo_sup >= 0
- punto_reorden >= 0 y stock_seguridad >= 0
- lead_time_dias > 0 (si es calculado)
- Si intervalo_inf > intervalo_sup, intercambiar automáticamente los valores o rechazar el registro
- Si demanda_pronosticada = 0, configurar automáticamente punto_reorden = 0 y stock_seguridad = 0
R.18: Clasificación de Productos Nuevos. Cuando se inserta un nuevo producto en la tabla productos, el sistema debe:
- Crear automáticamente un registro en analitica_productos con estado_pronostico_id = 1553 (NINGUNO)
- No generar predicciones hasta que el producto tenga al menos 30 días de datos históricos (parametros_globales.entrenamiento_min_registros)
- Una vez superado el umbral de datos, incluir el producto en la próxima ejecución de entrenamiento
R.19: Reportes y Dashboards. Esta tabla es la principal fuente de datos para:
- Dashboard de inteligencia de negocio (módulo NÚCLEO ANALÍTICO Y PREDICCIONES)
- Reportes de proyección de ventas (REPORTE_PREDICCIONES)
- Panel de control de inventario (punto_reorden, stock_seguridad vs stock_actual)
- Alertas de vencimiento y quiebre de stock
- Análisis de eficiencia de modelos (comparando predicciones vs ventas reales)
R.20: Desempeño y Escalabilidad. Dado el volumen potencial de registros, los índices estratégicos garantizan consultas rápidas:
- idx_an_producto_sucursal_fecha: Indexa por producto, sucursal y fecha descendente para consultas de último pronóstico
- idx_an_producto_id: Indexa por producto para búsquedas rápidas
- idx_an_sucursal_id: Indexa por sucursal para análisis de cadena
- idx_an_cluster: Indexa por clasificación ABC para filtrado y segmentación
- idx_an_fecha_clasificacion: Indexa por fecha para reportes históricos
- idx_an_nivel_urgencia: Indexa por nivel de urgencia para bandejas de alertas
- idx_an_vencimiento: Indexa por fecha de vencimiento crítico para alertas tempranas
- idx_an_estado_pronostico: Indexa por estado para filtrar pronósticos pendientes o en error
- idx_an_motivo_outlier: Indexa por motivo de outlier para análisis de causas de error';

DELETE FROM analitica_productos;
ALTER SEQUENCE analitica_productos_analitica_id_seq RESTART WITH 1;

INSERT INTO analitica_productos (analitica_id, producto_id, sucursal_id, demanda_pronosticada, intervalo_inf, intervalo_sup, fecha_prediccion, periodo_inicio, periodo_fin, fecha_vencimiento_critico, nivel_urgencia_id, punto_reorden, stock_seguridad, lead_time_dias, cluster_abc, fecha_clasificacion, puntaje_total, estado_pronostico_id, motivo_outlier_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 120.50, 100.00, 140.00, CURRENT_TIMESTAMP, '2026-08-01', '2026-08-31', '2027-01-15', 1854, 45.00, 15.00, 5, 0, CURRENT_DATE, 85.50, 1553, NULL, 1000, 1);

UPDATE analitica_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE analitica_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('analitica_productos_analitica_id_seq', COALESCE((SELECT MAX(analitica_id) FROM analitica_productos), 1));

-- ================================================================================================

CREATE TABLE pedidos_online (
    pedido_online_id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    sucursal_id BIGINT NOT NULL,
    kardex_id BIGINT NULL,
    codigo VARCHAR(30) NOT NULL,
    fecha_pedido TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_estimada TIMESTAMPTZ NULL,
    fecha_entrega_real TIMESTAMPTZ NULL,
    direccion_entrega VARCHAR(500) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    instrucciones_entrega VARCHAR(500) NULL,
    estado_pedido_online_id INTEGER NOT NULL DEFAULT 3700,		-- 3700=PENDIENTE, 3701=CONFIRMADO, 3702=PREPARANDO, 3703=EN_CAMINO, 3704=ENTREGADO, 3705=CANCELADO, 3706=RECHAZADO
    estado_pago_id INTEGER NOT NULL DEFAULT 2555,				-- 2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO
    subtotal DECIMAL(12,2) NOT NULL,
    costo_envio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuentos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12,2) NOT NULL,
    repartidor_id BIGINT NULL,
    ultima_actualizacion TIMESTAMPTZ NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_peo_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_peo_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_peo_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_peo_repartidor_id FOREIGN KEY (repartidor_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_peo_estado_pedido_online_id FOREIGN KEY (estado_pedido_online_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_peo_estado_pago_id FOREIGN KEY (estado_pago_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_peo_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id)
);
CREATE UNIQUE INDEX uix_peo_codigo ON pedidos_online (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_peo_cliente ON pedidos_online (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_peo_estado ON pedidos_online (estado_pedido_online_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE pedidos_online IS 'Reglas de la tabla - pedidos_online
R.0: La tabla pedidos_online gestiona todos los pedidos provenientes del canal digital (e-commerce, app móvil, etc.), actuando como el puente entre la tienda virtual y el sistema de ventas tradicional. Su propósito es centralizar la información de los pedidos digitales, controlar su ciclo de vida (desde la confirmación hasta la entrega) y permitir su conversión en transacciones de venta formales en el kardex cuando el pedido es confirmado y pagado.
R.1: Gestión de Estados del Pedido (Ciclo de Vida). El campo estado_pedido_online_id controla el flujo de trabajo del pedido digital utilizando el dominio EstadoPedidoOnlineID (3700-3706):
- 3700 (PENDIENTE): Pedido recibido, pendiente de confirmación por la farmacia.
- 3701 (CONFIRMADO): Pedido confirmado por la farmacia, se inicia la preparación.
- 3702 (PREPARANDO): Pedido en proceso de picking y empaque en el almacén.
- 3703 (EN_CAMINO): Pedido despachado, en ruta de entrega al cliente.
- 3704 (ENTREGADO): Pedido entregado exitosamente al cliente.
- 3705 (CANCELADO): Pedido cancelado por el cliente o la farmacia antes de la entrega.
- 3706 (RECHAZADO): Pedido rechazado por el cliente en el momento de la entrega (ej. producto dañado).
R.2: Control de Pagos (estado_pago_id). El campo estado_pago_id utiliza el dominio EstadoPagoID (2550-2555) para gestionar el estado financiero del pedido:
- 2550 (PENDIENTE): Pedido sin abonos registrados, esperando pago.
- 2551 (PARCIAL): Pedido con abonos parciales (ej. anticipo).
- 2552 (PAGADO): Pedido totalmente pagado.
- 2553 (CERRADO): Pedido cerrado contablemente.
- 2554 (EN_VERIFICACION): Pago en proceso de verificación bancaria.
- 2555 (NINGUNO): Sin estado de pago definido (para pedidos sin pago previo).
R.3: Conversión a Venta en Sistema (kardex_id). Cuando un pedido digital es confirmado y pagado, el backend debe:
- Generar una transacción de VENTA (evento_id = 1051) en la tabla kardex.
- Registrar el ID de la transacción en el campo kardex_id.
- Descontar el stock de los lotes correspondientes.
- Actualizar el estado del pedido a CONFIRMADO (3701) o PREPARANDO (3702).
El campo kardex_id permanece NULL mientras el pedido esté en estado PENDIENTE o no se haya convertido en venta.
R.4: Control de Fechas y Temporización. Los campos fecha_pedido, fecha_entrega_estimada y fecha_entrega_real permiten auditar el tiempo de respuesta del sistema:
- fecha_pedido: Momento en que el cliente realiza el pedido.
- fecha_entrega_estimada: Calculada por el sistema según la disponibilidad de stock y la ubicación del cliente.
- fecha_entrega_real: Se actualiza automáticamente cuando el pedido alcanza el estado ENTREGADO (3704) o RECHAZADO (3706).
R.5: Datos de Entrega (Desnormalización Estratégica). Los campos direccion_entrega, telefono_contacto e instrucciones_entrega se almacenan de forma redundante en la tabla pedidos_online para garantizar la inmutabilidad de la información de entrega, independientemente de los cambios futuros en la tabla clientes. Esto es crucial para la trazabilidad de entregas y la resolución de disputas.
R.6: Gestión de Repartidores (repartidor_id). El campo repartidor_id referencia al usuario (usuario_id) que realiza la entrega. Puede ser un repartidor interno (empleado de la farmacia) o externo (tercerizado). El sistema debe actualizar este campo al asignar un pedido a un repartidor (estado EN_CAMINO).
R.7: Asignación de Sucursal (sucursal_id). Cada pedido digital se asigna a una sucursal específica basada en:
- La ubicación del cliente (cercanía).
- La disponibilidad de stock en la sucursal.
- La configuración de cobertura de entregas de cada sucursal.
La sucursal asignada es responsable del despacho y la entrega.
R.8: Control de Código Único (codigo). El campo codigo es un identificador alfanumérico único generado automáticamente por el backend siguiendo el patrón: ''WEB-[GESTION]-[CORRELATIVO]'' (ej. ''WEB-2026-0001''). Es inmutable y se utiliza como referencia en la comunicación con el cliente y en los reportes.
R.9: Control de Montos y Validaciones. Se aplican restricciones CHECK para garantizar la integridad financiera del pedido:
- subtotal >= 0 (suma de los precios unitarios por cantidad).
- costo_envio >= 0 (puede ser 0 para pedidos que superen un monto mínimo).
- descuentos >= 0 (descuentos aplicados por cupones o promociones).
- total >= 0 (total a pagar por el cliente).
R.10: Integración con el Módulo de Ventas Tradicional. El flujo completo de un pedido online es:
1. El cliente realiza el pedido en la tienda virtual (estado PENDIENTE).
2. La farmacia confirma el pedido y verifica stock (estado CONFIRMADO).
3. El personal prepara el pedido en el almacén (estado PREPARANDO).
4. Se asigna un repartidor y se despacha el pedido (estado EN_CAMINO).
5. El repartidor entrega el pedido (estado ENTREGADO) o lo rechaza (RECHAZADO).
6. El pedido se convierte en una transacción de VENTA en el kardex (kardex_id se actualiza con el ID de la venta).
7. El pedido se archiva en HISTORICO para conservar la trazabilidad.
R.11: Registro Inicial Comodín. El sistema debe mantener un registro inicial con pedido_online_id = 1 que sirve como valor predeterminado para las FK que requieran un pedido de referencia. Este registro tiene estado_id = 1002 (HISTORICO) y no puede ser modificado ni eliminado.
R.12: Índices Estratégicos. Se han creado índices específicos para optimizar las consultas más frecuentes:
- idx_peo_cliente: Consultas de historial de pedidos por cliente.
- idx_peo_estado: Filtrado de pedidos pendientes para el dashboard de preparación.
- idx_peo_fecha_pedido: Reportes de pedidos por período.
- idx_peo_sucursal_estado: Consultas de pedidos por sucursal para el módulo de delivery.
R.13: Tareas Programadas para Expiración. El sistema debe ejecutar diariamente una tarea que:
- Identifique pedidos en estado PENDIENTE con fecha_pedido > 30 días.
- Automáticamente los cambie a estado CANCELADO (3705).
- Registre el evento en logs_ejecucion con motivo: "PEDIDO_EXPIRADO_POR_TIEMPO".
R.14: Validación de Cliente y Sucursal. Antes de insertar un pedido, el sistema debe validar que:
- El cliente_id exista y esté ACTIVO (estado_id = 1000).
- El cliente tenga habilitado_ventas = 1.
- La sucursal_id exista, esté ACTIVA y tenga cobertura de delivery configurada.
- La sucursal tenga stock suficiente para cubrir el pedido (se valida al confirmar, no al crear).
R.15: Integración con Módulo de Alertas. Cuando un pedido permanece en estado PREPARANDO por más de 60 minutos, el sistema debe generar una alerta de tipo SISTEMA (2700) con nivel_critico_id = 2902 (MEDIA) para notificar al encargado de almacén.
R.16: Trazabilidad de Cambios de Estado. Cada cambio de estado_pedido_online_id debe registrar automáticamente la fecha_hora en el campo ultima_actualizacion y crear un registro en logs_ejecucion con:
- modulo = ''PEDIDOS_ONLINE''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Pedido {codigo} cambió de estado {estado_anterior} a {estado_nuevo}''
- detalle = { "usuario": usuario_id, "motivo": "..." }
R.17: Política de Rechazo por Stock. Si al momento de confirmar un pedido (estado CONFIRMADO) no hay suficiente stock en la sucursal asignada, el sistema debe:
1. Intentar reasignar el pedido a otra sucursal con stock disponible.
2. Si no es posible, rechazar el pedido (estado RECHAZADO = 3706).
3. Notificar al cliente vía email (usando el módulo de notificaciones).
4. Registrar el motivo en observaciones.
R.18: Gestión de Cupones y Descuentos. Los descuentos aplicados en el campo descuentos deben validarse contra la tabla cupones_descuento cuando se aplica un código promocional. La validación debe incluir:
- El cupón debe estar ACTIVO (estado_id = 1000).
- La fecha actual debe estar entre fecha_inicio y fecha_fin.
- El número de usos_realizados < uso_maximo.
- El cliente no debe haber excedido el uso_por_cliente.
R.19: Control de Cambios de Dirección y Teléfono. Si el cliente modifica su dirección o teléfono en la tabla clientes, los pedidos ya registrados mantienen su información original de entrega (desnormalización). La interfaz de usuario debe mostrar un indicador cuando la dirección de entrega difiere de la dirección principal del cliente.
R.20: Flujo de Cancelación. Para cancelar un pedido (estado CANCELADO = 3705):
- Solo se permite si el pedido está en estado PENDIENTE (3700) o CONFIRMADO (3701).
- No se permite cancelar pedidos en estado PREPARANDO (3702), EN_CAMINO (3703) o ENTREGADO (3704).
- La cancelación debe registrar un motivo obligatorio (observaciones).
- Si el pedido ya tenía kardex_id asociado (venta generada), la cancelación debe generar una ANULACION (evento_id = 1055).';

DELETE FROM pedidos_online;
ALTER SEQUENCE pedidos_online_pedido_online_id_seq RESTART WITH 1;

INSERT INTO pedidos_online (pedido_online_id, cliente_id, sucursal_id, kardex_id, codigo, fecha_pedido, fecha_entrega_estimada, fecha_entrega_real, direccion_entrega, telefono_contacto, instrucciones_entrega, estado_pedido_online_id, estado_pago_id, subtotal, costo_envio, descuentos, total, repartidor_id, ultima_actualizacion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'WEB-0000', CURRENT_TIMESTAMP, NULL, NULL, 'NINGUNO', '00000000', NULL, 3700, 2555, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 1000, 1);

UPDATE pedidos_online SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE pedidos_online SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('pedidos_online_pedido_online_id_seq', COALESCE((SELECT MAX(pedido_online_id) FROM pedidos_online), 1));

-- ================================================================================================

CREATE TABLE detalles_pedidos_online (
    detalle_pedido_online_id BIGSERIAL PRIMARY KEY,
    pedido_online_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    kardex_producto_id BIGINT NULL,
    codigo_producto VARCHAR(30) NOT NULL,
    nombre_producto VARCHAR(500) NOT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    descuento_unitario DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12,2) NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,          -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_dpe_pedido_online_id FOREIGN KEY (pedido_online_id) REFERENCES pedidos_online(pedido_online_id),
    CONSTRAINT fk_dpe_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_dpe_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT fk_dpe_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_dpe_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_dpe_precio_unitario CHECK (precio_unitario >= 0),
    CONSTRAINT chk_dpe_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_dpe_pedido ON detalles_pedidos_online (pedido_online_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dpe_producto ON detalles_pedidos_online (producto_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE detalles_pedidos_online IS 'Reglas de la tabla - detalles_pedidos_online
R.0: La tabla detalles_pedidos_online almacena el detalle de productos de cada pedido digital, incluyendo información desnormalizada (nombre, código) para garantizar la inmutabilidad del pedido ante cambios en el catálogo de productos.
R.1: Desnormalización Estratégica. Los campos codigo_producto y nombre_producto se almacenan de forma redundante para preservar la foto exacta del pedido en el momento de la compra, independientemente de futuras modificaciones en la tabla productos.
R.2: Conversión a Venta (kardex_producto_id). Cuando el pedido se convierte en una venta formal, este campo se actualiza con el ID del detalle de la transacción en kardex_productos, permitiendo la trazabilidad completa.
R.3: Control de Cantidades y Precios. La cantidad debe ser mayor a 0. El precio_unitario y el subtotal no pueden ser negativos.
R.4: Registro Inicial Comodín. El sistema debe mantener un registro inicial con detalle_pedido_online_id = 1 que sirve como valor predeterminado.';

INSERT INTO detalles_pedidos_online (detalle_pedido_online_id, pedido_online_id, producto_id, kardex_producto_id, codigo_producto, nombre_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'NIN', 'NINGUNO', 1.00, 0.00, 0.00, 0.00, 1000, 1);

UPDATE detalles_pedidos_online SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE detalles_pedidos_online SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('detalles_pedidos_online_detalle_pedido_online_id_seq', COALESCE((SELECT MAX(detalle_pedido_online_id) FROM detalles_pedidos_online), 1));

-- ================================================================================================

CREATE TABLE carritos_compra (
    carrito_id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion_carrito TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    cliente_nombre VARCHAR(200) NOT NULL,
    cliente_documento VARCHAR(30) NOT NULL,
    total_items INTEGER NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado_id INTEGER NOT NULL DEFAULT 1000,          -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_car_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_car_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_car_total_items CHECK (total_items >= 0),
    CONSTRAINT chk_car_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_car_fecha_expiracion CHECK (fecha_expiracion > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_car_cliente_activo ON carritos_compra (cliente_id) WHERE estado_id = 1000;
CREATE INDEX idx_car_cliente ON carritos_compra (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_car_expiracion ON carritos_compra (fecha_expiracion) WHERE estado_id = 1000;

COMMENT ON TABLE carritos_compra IS 'Reglas de la tabla - carritos_compra
R.0: La tabla carritos_compra persiste los carritos de compra de los clientes registrados en el e-commerce, permitiendo que los usuarios retomen sus compras en diferentes sesiones.
R.1: Control de Expiración (TTL). fecha_expiracion define el tiempo de vida del carrito (configurable en parametros_globales). Una tarea programada debe eliminar o archivar carritos expirados diariamente.
R.2: Unicidad por Cliente Activo. Solo puede existir un carrito activo por cliente (estado_id = 1000). Al crear un nuevo carrito, el anterior debe pasar a HISTORICO.
R.3: Desnormalización de Datos del Cliente. cliente_nombre y cliente_documento se almacenan para preservar la información del cliente en el momento de la creación del carrito.
R.4: Registro Inicial Comodín. El sistema debe mantener un registro inicial con carrito_id = 1.';

INSERT INTO carritos_compra (carrito_id, cliente_id, fecha_creacion, fecha_actualizacion_carrito, fecha_expiracion, cliente_nombre, cliente_documento, total_items, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', 'NINGUNO', '0', 0, 0.00, 1000, 1);

UPDATE carritos_compra SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE carritos_compra SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('carritos_compra_carrito_id_seq', COALESCE((SELECT MAX(carrito_id) FROM carritos_compra), 1));

-- ================================================================================================

CREATE TABLE detalles_carritos (
    detalle_carrito_id BIGSERIAL PRIMARY KEY,
    carrito_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    codigo_producto VARCHAR(30) NOT NULL,
    nombre_producto VARCHAR(500) NOT NULL,
    presentacion_producto VARCHAR(200) NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    descuento_unitario DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12,2) NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_dca_carrito_id FOREIGN KEY (carrito_id) REFERENCES carritos_compra(carrito_id),
    CONSTRAINT fk_dca_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_dca_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_dca_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_dca_precio_unitario CHECK (precio_unitario >= 0),
    CONSTRAINT chk_dca_descuento_unitario CHECK (descuento_unitario >= 0),
    CONSTRAINT chk_dca_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_dca_carrito ON detalles_carritos (carrito_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dca_producto ON detalles_carritos (producto_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE detalles_carritos IS 'Reglas de la tabla - detalles_carritos
R.0: La tabla detalles_carritos almacena el detalle de productos de cada carrito de compra persistente, permitiendo a los clientes retomar sus compras en diferentes sesiones. Es la tabla hija de carritos_compra.
R.1: Desnormalización Estratégica. Los campos codigo_producto, nombre_producto y presentacion_producto se almacenan de forma redundante para preservar la foto exacta del carrito en el momento de la adición, independientemente de futuras modificaciones en la tabla productos.
R.2: Control de Cantidades y Precios. La cantidad debe ser mayor a 0. El precio_unitario, descuento_unitario y subtotal no pueden ser negativos.
R.3: Cálculo Automático del Subtotal. El subtotal se calcula como: (precio_unitario - descuento_unitario) * cantidad. El backend debe garantizar que subtotal = (precio_unitario - descuento_unitario) * cantidad.
R.4: Actualización de Totales del Carrito. Cada vez que se inserta, actualiza o elimina un detalle, el backend DEBE recalcular y actualizar los campos total_items y subtotal en la tabla carritos_compra. NO se utilizan triggers en la base de datos; la lógica debe implementarse en el servicio de carritos del backend.
R.5: Registro Inicial Comodín. El sistema debe mantener un registro inicial con detalle_carrito_id = 1 que sirve como valor predeterminado para las FK que requieran un detalle de carrito de referencia. Este registro tiene estado_id = 1002 (HISTORICO) y no puede ser modificado ni eliminado.
R.6: Integración con el Módulo de Precios. El precio_unitario debe obtenerse de la tabla precios_productos según la lista de precios aplicable al cliente (público, afiliado, institucional, etc.).
R.7: Control de Stock en Tiempo Real. Al agregar un producto al carrito, el sistema debe validar que la cantidad solicitada no exceda el stock disponible en la sucursal asignada. Si no hay stock suficiente, debe notificar al usuario.
R.8: Gestión de Descuentos por Cantidad. Si el producto tiene promociones activas por cantidad (ej. 2x1, 3x2), el sistema debe aplicar el descuento_unitario correspondiente según las reglas de la promoción.
R.9: Control de Cupones. Si el cliente aplica un cupón de descuento que afecta a productos específicos, el descuento_unitario debe reflejar el beneficio del cupón proporcionalmente.
R.10: Índices Estratégicos. Se han creado índices específicos para optimizar las consultas más frecuentes:
- idx_dca_carrito: Consulta rápida del contenido de un carrito.
- idx_dca_producto: Reportes de productos más agregados a carritos.
R.11: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, HISTORICO). Un detalle en estado HISTORICO no puede ser modificado.
R.12: Tarea de Limpieza de Carritos Huérfanos. El sistema debe ejecutar diariamente una tarea que:
- Identifique carritos en estado ACTIVO con fecha_expiracion < CURRENT_TIMESTAMP.
- Cambie su estado a HISTORICO (1002).
- Los detalles asociados también deben pasar a HISTORICO.
R.13: Validación de Coherencia de Totales. Al insertar o actualizar un detalle, el backend debe validar que el subtotal del detalle sea consistente con los datos de la cabecera del carrito.
R.14: Historial de Cambios. Cada modificación en la cantidad de un producto en el carrito debe registrar el evento en logs_ejecucion con:
- modulo = ''CARRITOS_COMPRA''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Carrito {carrito_id}: Producto {producto_id} cambió cantidad de {cantidad_anterior} a {cantidad_nueva}''
R.15: Límite Máximo de Items por Carrito. El sistema debe validar que un carrito no supere el límite máximo de items configurado en parametros_globales (parametro: ''limite_items_carrito''). Si se supera, debe notificar al usuario.
R.16: Control de Productos Controlados. Si el producto requiere receta (productos.requiere_receta = 1), el sistema debe mostrar un aviso al agregarlo al carrito y requerir la carga de la receta al momento del checkout.
R.17: Gestión de Lotes y Vencimientos. Al agregar un producto al carrito, el sistema debe seleccionar el lote más próximo a vencer (FEFO - First Expired, First Out) para garantizar la rotación adecuada del inventario.
R.18: Precios Especiales por Volumen. Si la cantidad del producto supera un umbral configurado en politicas_precios, el sistema debe aplicar automáticamente el precio por volumen correspondiente.
R.19: Inmutabilidad del Detalle. Una vez que el carrito se convierte en un pedido online (tabla pedidos_online), los detalles del carrito pasan a estado HISTORICO y no pueden ser modificados.
R.20: Integración con el Módulo de Ventas. Cuando un carrito se convierte en pedido online, el sistema debe:
- Crear un registro en pedidos_online con los datos del carrito.
- Crear los detalles en detalles_pedidos_online copiando los datos del carrito.
- Marcar el carrito y sus detalles como HISTORICO (estado_id = 1002).
R.21: Lógica de Recalculo de Totales en el Backend (NestJS). El servicio de carritos debe implementar el siguiente método:
- async recalcularTotales(carritoId: number): Promise<void>
- Este método debe calcular la suma de cantidad y subtotal de todos los detalles ACTIVOS del carrito.
- Debe actualizar los campos total_items y subtotal en la tabla carritos_compra.
- Debe actualizar la fecha_actualizacion_carrito y fecha_actualizacion con CURRENT_TIMESTAMP.
- Este método debe ser llamado después de cada INSERT, UPDATE o DELETE sobre detalles_carritos.
R.22: Transacciones y Consistencia. Todas las operaciones que involucren la creación, actualización o eliminación de detalles de carrito deben ejecutarse dentro de una transacción para garantizar la consistencia de los datos. El backend debe usar el patrón Unit of Work o un Transaction Manager para coordinar las operaciones.
R.23: Validación de Duplicados. Al agregar un producto al carrito, el backend debe verificar si el producto ya existe en el carrito. Si existe, debe actualizar la cantidad en lugar de insertar un nuevo registro. La combinación de carrito_id y producto_id debe ser única para registros ACTIVOS.
R.24: Control de Concurrencia. En escenarios de alta concurrencia (múltiples dispositivos del mismo cliente), el backend debe implementar bloqueo optimista o pesimista para evitar inconsistencias en el carrito. Se recomienda usar versionado (campo version) o SELECT ... FOR UPDATE en las operaciones críticas.
R.25: Log de Auditoría. Cada operación sobre detalles_carritos debe registrar en logs_ejecucion:
- modulo = ''CARRITOS_COMPRA''
- nivel_log_id = 3150 (INFO) para operaciones normales, 3151 (WARNING) para advertencias, 3152 (ERROR) para errores.
- mensaje = Descripción clara de la operación realizada.
- detalle = JSON con los datos afectados (antes/después).';

DELETE FROM detalles_carritos;
ALTER SEQUENCE detalles_carritos_detalle_carrito_id_seq RESTART WITH 1;

INSERT INTO detalles_carritos (detalle_carrito_id, carrito_id, producto_id, codigo_producto, nombre_producto, presentacion_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NIN', 'NINGUNO', NULL, 1.00, 0.00, 0.00, 0.00, 1000, 1);

UPDATE detalles_carritos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE detalles_carritos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('detalles_carritos_detalle_carrito_id_seq', COALESCE((SELECT MAX(detalle_carrito_id) FROM detalles_carritos), 1));

-- ================================================================================================

CREATE TABLE listas_precios (
    lista_precio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(500) NULL,
    es_publica INTEGER NOT NULL DEFAULT 1,
    prioridad INTEGER NOT NULL DEFAULT 1,
    requiere_autorizacion INTEGER NOT NULL DEFAULT 0,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_lis_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_lis_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_lis_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_lis_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_lis_es_publica CHECK (es_publica IN (0, 1)),
    CONSTRAINT chk_lis_prioridad CHECK (prioridad > 0),
    CONSTRAINT chk_lis_requiere_autorizacion CHECK (requiere_autorizacion IN (0, 1))
);
CREATE UNIQUE INDEX uix_lis_codigo ON listas_precios (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_lis_nombre ON listas_precios (nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE listas_precios IS 'Reglas de la tabla - listas_precios
R.0: La tabla listas_precios define los diferentes catálogos de precios comerciales que utiliza la farmacia para segmentar sus ventas por tipo de cliente (público general, afiliados, instituciones, mayoristas, etc.). Su propósito es centralizar la definición de listas de precios para que los módulos de ventas (POS y e-commerce) puedan aplicar el precio correcto según el perfil del cliente.
R.1: Gestión de Prioridad. El campo prioridad define el orden de aplicación cuando un cliente califica para múltiples listas. Un valor menor indica mayor prioridad. Ejemplo: si un cliente es afiliado y también institucional, se aplica la lista con prioridad más baja (ej. prioridad 1 = Mayorista, prioridad 2 = Institucional).
R.2: Control de Visibilidad (es_publica). es_publica = 1 indica que la lista es visible en el e-commerce para que los clientes puedan ver los precios. es_publica = 0 indica que es una lista interna (ej. precios de costo, precios especiales).
R.3: Requiere Autorización (requiere_autorizacion). requiere_autorizacion = 1 indica que para aplicar esta lista de precios se necesita autorización especial de un supervisor o gerente. El sistema debe solicitar aprobación al momento de la venta.
R.4: Registro Comodín. El registro con lista_precio_id = 1 (NINGUNO) es el valor predeterminado para productos sin lista asignada.
R.5: Unicidad de Código y Nombre. codigo y nombre deben ser únicos para registros activos o históricos.
R.6: Integración con Ventas. Al momento de una venta, el sistema debe:
- Identificar el perfil del cliente (tipo_cliente_id).
- Seleccionar la lista de precios con mayor prioridad.
- Obtener el precio de precios_productos.
- Si no existe precio para la lista seleccionada, buscar en la lista por defecto (PUB).';

DELETE FROM listas_precios;
ALTER SEQUENCE listas_precios_lista_precio_id_seq RESTART WITH 1;

INSERT INTO listas_precios (lista_precio_id, codigo, nombre, descripcion, es_publica, prioridad, requiere_autorizacion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'Lista de precios predeterminada para productos sin clasificar', 0, 999, 0, 1000, 1);

UPDATE listas_precios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE listas_precios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('listas_precios_lista_precio_id_seq', COALESCE((SELECT MAX(lista_precio_id) FROM listas_precios), 1));

-- ================================================================================================

CREATE TABLE precios_productos (
    precio_producto_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL,
    lista_precio_id BIGINT NOT NULL,
    precio_base DECIMAL(12,2) NOT NULL,
    precio_oferta DECIMAL(12,2) NULL,
    precio_minimo DECIMAL(12,2) NULL,
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin DATE NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pp_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_pp_lista_precio_id FOREIGN KEY (lista_precio_id) REFERENCES listas_precios(lista_precio_id),
    CONSTRAINT fk_pp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pp_precio_base CHECK (precio_base >= 0),
	CONSTRAINT chk_pp_precio_oferta CHECK (precio_oferta IS NULL OR precio_oferta <= precio_base),
    CONSTRAINT chk_pp_precio_minimo CHECK (precio_minimo IS NULL OR precio_minimo <= precio_base),
    CONSTRAINT chk_pp_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
CREATE UNIQUE INDEX uix_pp_producto_lista_vigente ON precios_productos (producto_id, lista_precio_id) WHERE estado_id = 1000;
CREATE INDEX idx_pp_producto ON precios_productos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pp_lista ON precios_productos (lista_precio_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pp_fechas ON precios_productos (fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE precios_productos IS 'Reglas de la tabla - precios_productos
R.0: La tabla precios_productos almacena los precios vigentes de cada producto en cada lista de precios, permitiendo que un producto tenga diferentes precios según el canal de venta o el perfil del cliente. Su propósito es centralizar la información de precios para que los módulos de ventas (POS y e-commerce) puedan consultar el precio correcto en tiempo real.
R.1: Control de Vigencia Temporal. fecha_inicio y fecha_fin permiten programar cambios de precios con anticipación. Si fecha_fin es NULL, el precio es indefinido. El índice uix_pp_producto_lista_vigente garantiza que solo exista un precio activo por producto y lista en un momento dado.
R.2: Precio Base vs Precio Oferta. precio_base es el precio estándar de la lista. precio_oferta es un precio promocional que reemplaza al base durante un período específico. El sistema debe usar precio_oferta si está vigente y es menor que precio_base.
R.3: Precio Mínimo (precio_minimo). Define el precio mínimo al que se puede vender el producto en esa lista. El sistema debe validar que ningún descuento adicional reduzca el precio por debajo de este umbral.
R.4: Registro Comodín. El registro con precio_producto_id = 1 es el valor predeterminado para productos sin precio asignado.
R.5: Herencia de Precios. Al crear un nuevo producto, el sistema debe:
- Copiar el precio del producto base (productos.pventa o pventaf) a la lista PÚBLICO GENERAL.
- Establecer los precios de otras listas aplicando los porcentajes de descuento configurados en parametros_globales.
R.6: Actualización Masiva de Precios. El sistema debe permitir actualizaciones masivas de precios por:
- Categoría (todos los productos de una categoría).
- Laboratorio (todos los productos de un laboratorio).
- Lista de precios específica.
- Porcentaje de incremento o decremento.
R.7: Historial de Precios. Cada cambio de precio debe registrar en logs_ejecucion:
- modulo = ''PRECIOS_PRODUCTOS''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Producto {producto_id} cambió precio en lista {lista_precio_id} de {precio_anterior} a {precio_nuevo}''
- detalle = { "usuario": usuario_id, "motivo": "..." }
R.8: Integración con Kardex. Al registrar una venta, el sistema debe:
- Obtener el precio de precios_productos según el tipo de cliente.
- Si no existe precio para la lista, usar la lista PÚBLICO GENERAL.
- Si no existe precio en ninguna lista, usar productos.pventa o pventaf.
R.9: Control de Márgenes. Al establecer un precio, el sistema debe validar que el margen de utilidad esté dentro de los límites configurados en politicas_precios.
R.10: Validación de Coherencia. precio_base debe ser mayor a 0. precio_oferta y precio_minimo pueden ser NULL. Si se especifican, deben ser menores o iguales a precio_base.';

DELETE FROM precios_productos;
ALTER SEQUENCE precios_productos_precio_producto_id_seq RESTART WITH 1;

INSERT INTO precios_productos (precio_producto_id, producto_id, lista_precio_id, precio_base, precio_oferta, precio_minimo, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, NULL, NULL, '2000-01-01', NULL, 1000, 1);

UPDATE precios_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE precios_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('precios_productos_precio_producto_id_seq', COALESCE((SELECT MAX(precio_producto_id) FROM precios_productos), 1));

-- ================================================================================================

CREATE TABLE costos_promedio (
    costo_promedio_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL,
    costo_promedio DECIMAL(12,4) NOT NULL,
    costo_ultima_compra DECIMAL(12,4) NULL,
    fecha_calculo DATE NOT NULL DEFAULT CURRENT_DATE,
    metodo_calculo_id INTEGER NOT NULL DEFAULT 3750,	-- 3750=PONDERADO, 3751=FIFO, 3752=ULTIMA_COMPRA
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cp_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_cp_metodo_calculo_id FOREIGN KEY (metodo_calculo_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cp_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cp_costo_promedio CHECK (costo_promedio >= 0),
    CONSTRAINT chk_cp_costo_ultima_compra CHECK (costo_ultima_compra IS NULL OR costo_ultima_compra >= 0)
);
CREATE UNIQUE INDEX uix_cp_producto_fecha ON costos_promedio (producto_id, fecha_calculo) WHERE estado_id = 1000;
CREATE INDEX idx_cp_producto ON costos_promedio (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cp_fecha ON costos_promedio (fecha_calculo DESC) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE costos_promedio IS 'Reglas de la tabla - costos_promedio
R.0: La tabla costos_promedio almacena el historial del costo promedio ponderado de adquisición de cada producto, calculado automáticamente a partir de las compras registradas en el kardex. Su propósito es proporcionar una base de datos confiable para el cálculo de márgenes de utilidad, la valoración de inventarios y la toma de decisiones de precios.
R.1: Métodos de Cálculo. El campo metodo_calculo define la fórmula utilizada:
- PONDERADO: Costo promedio = (stock_actual * costo_anterior + cantidad_comprada * costo_compra) / (stock_actual + cantidad_comprada).
- FIFO: Primeras en entrar, primeras en salir (primero se venden los lotes más antiguos).
- ULTIMA_COMPRA: Usa el costo del último lote comprado.
R.2: Cálculo Automático al Registrar una Compra. Cuando se registra una compra (evento_id = 1050), el sistema debe:
- Obtener el costo_promedio actual del producto.
- Calcular el nuevo costo_promedio según el método configurado.
- Insertar un nuevo registro en costos_promedio con la fecha de cálculo.
R.3: Registro Comodín. El registro con costo_promedio_id = 1 es el valor predeterminado.
R.4: Integración con Márgenes. El costo_promedio se utiliza para calcular:
- Margen bruto = (precio_venta - costo_promedio) / precio_venta * 100.
- Rentabilidad por producto, categoría y laboratorio.
R.5: Historial Diario. El sistema debe calcular y almacenar el costo_promedio diariamente para todos los productos con movimientos de compra. Esto permite análisis de evolución de costos en el tiempo.
R.6: Validación de Coherencia. El costo_promedio no puede ser negativo. Si no hay compras registradas, el costo_promedio debe ser 0.';

DELETE FROM costos_promedio;
ALTER SEQUENCE costos_promedio_costo_promedio_id_seq RESTART WITH 1;

INSERT INTO costos_promedio (costo_promedio_id, producto_id, costo_promedio, costo_ultima_compra, fecha_calculo, metodo_calculo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0.00, NULL, '2000-01-01', 3750, 1000, 1);

UPDATE costos_promedio SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE costos_promedio SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('costos_promedio_costo_promedio_id_seq', COALESCE((SELECT MAX(costo_promedio_id) FROM costos_promedio), 1));

-- ================================================================================================

CREATE TABLE politicas_precios (
    politica_precio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_aplicacion_id INTEGER NOT NULL DEFAULT 4350,	-- 4350=GLOBAL, 4351=CATEGORIA, 4352=LABORATORIO, 4353=PRODUCTO
    entidad_id BIGINT NULL,
    margen_minimo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    margen_maximo DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    redondeo INTEGER NOT NULL DEFAULT 0,
    aplica_descuentos INTEGER NOT NULL DEFAULT 1,
    descuento_maximo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ppol_tipo_aplicacion_id FOREIGN KEY (tipo_aplicacion_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_ppol_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_ppol_codigo_not_empty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_ppol_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_ppol_nombre_not_empty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_ppol_margenes CHECK (margen_minimo >= 0 AND margen_maximo >= margen_minimo),
    CONSTRAINT chk_ppol_redondeo CHECK (redondeo IN (0, 1, 5)),
    CONSTRAINT chk_ppol_aplica_descuentos CHECK (aplica_descuentos IN (0, 1)),
    CONSTRAINT chk_ppol_descuento_maximo CHECK (descuento_maximo >= 0 AND descuento_maximo <= 100)
);
CREATE UNIQUE INDEX uix_ppol_codigo ON politicas_precios (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ppol_tipo_entidad ON politicas_precios (tipo_aplicacion_id, entidad_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE politicas_precios IS 'Reglas de la tabla - politicas_precios
R.0: La tabla politicas_precios define las reglas globales de fijación de precios que el sistema debe aplicar para garantizar la rentabilidad y la consistencia de los precios. Su propósito es establecer límites de márgenes, reglas de redondeo y políticas de descuento que se aplican automáticamente al calcular los precios de venta.
R.1: Tipos de Aplicación (tipo_aplicacion). Define el alcance de la política:
- GLOBAL: Aplica a todos los productos.
- CATEGORIA: Aplica solo a productos de una categoría específica (entidad_id = categoria_id).
- LABORATORIO: Aplica solo a productos de un laboratorio específico (entidad_id = laboratorio_id).
- PRODUCTO: Aplica solo a un producto específico (entidad_id = producto_id).
R.2: Jerarquía de Aplicación. Cuando existen múltiples políticas aplicables, el sistema debe priorizar:
1. PRODUCTO (más específica)
2. CATEGORIA
3. LABORATORIO
4. GLOBAL (menos específica)
R.3: Control de Márgenes. margen_minimo y margen_maximo definen el rango permitido de margen de utilidad sobre el costo_promedio. El sistema debe validar que precio_venta = costo_promedio * (1 + margen/100) y que el margen esté dentro del rango permitido.
R.4: Reglas de Redondeo. redondeo define cómo se redondean los precios calculados:
- 0: Sin redondeo (precio exacto).
- 1: Redondeo al entero más cercano (ej. 12.30 → 12, 12.50 → 13).
- 5: Redondeo al múltiplo de 5 más cercano (ej. 12.30 → 10, 12.50 → 15).
R.5: Políticas de Descuento. aplica_descuentos = 0 significa que no se permiten descuentos en esta categoría/lista. descuento_maximo define el porcentaje máximo de descuento permitido.
R.6: Registro Comodín. El registro con politica_precio_id = 1 es el valor predeterminado.
R.7: Validación de Precios al Registrar Ventas. Al calcular el precio de venta, el sistema debe:
- Obtener la política aplicable al producto.
- Calcular el precio máximo y mínimo permitido.
- Validar que el precio ingresado esté dentro del rango.
- Aplicar el redondeo configurado.
R.8: Integración con Módulo de Precios. Las políticas se aplican automáticamente al:
- Crear o actualizar precios en precios_productos.
- Calcular descuentos en el punto de venta (POS).
- Generar ofertas y promociones.';

DELETE FROM politicas_precios;
ALTER SEQUENCE politicas_precios_politica_precio_id_seq RESTART WITH 1;

INSERT INTO politicas_precios (politica_precio_id, codigo, nombre, tipo_aplicacion_id, entidad_id, margen_minimo, margen_maximo, redondeo, aplica_descuentos, descuento_maximo, estado_id, usuario_id_registro) VALUES
(1, 'GLOBAL', 'POLÍTICA GLOBAL POR DEFECTO', 4350, NULL, 0.00, 100.00, 0, 1, 0.00, 1000, 1);

UPDATE politicas_precios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE politicas_precios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('politicas_precios_politica_precio_id_seq', COALESCE((SELECT MAX(politica_precio_id) FROM politicas_precios), 1));

-- ================================================================================================

CREATE TABLE asistencias (
    asistencia_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_entrada TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hora_salida TIMESTAMPTZ NULL,
    hora_entrada_almuerzo TIMESTAMPTZ NULL,
    hora_salida_almuerzo TIMESTAMPTZ NULL,
    horas_trabajadas DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    horas_extras DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    tipo_asistencia_id INTEGER NOT NULL DEFAULT 4400,    -- 4400=NORMAL, 4401=LICENCIA, 4402=PERMISO, 4403=JUSTIFICADA
    estado_asistencia_id INTEGER NOT NULL DEFAULT 4450,  -- 4450=PRESENTE, 4451=AUSENTE, 4452=TARDE, 4453=FALTA_INJUSTIFICADA
    metodo_marcacion_id INTEGER NOT NULL DEFAULT 4500,   -- 4500=MANUAL, 4501=BIOMETRICO, 4502=QR, 4503=APP
    dispositivo VARCHAR(50) NULL,
    ip_origen VARCHAR(45) NULL,
    observaciones VARCHAR(500) NULL,
    justificacion VARCHAR(1000) NULL,
    justificacion_archivo VARCHAR(255) NULL,
    usuario_registro_id BIGINT NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_asi_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_asi_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_asi_usuario_registro_id FOREIGN KEY (usuario_registro_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_asi_tipo_asistencia_id FOREIGN KEY (tipo_asistencia_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_asi_estado_asistencia_id FOREIGN KEY (estado_asistencia_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_asi_metodo_marcacion_id FOREIGN KEY (metodo_marcacion_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_asi_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_asi_horas CHECK (horas_trabajadas >= 0 AND horas_extras >= 0),
    CONSTRAINT chk_asi_fechas CHECK (hora_salida IS NULL OR hora_salida >= hora_entrada),
    CONSTRAINT chk_asi_almuerzo CHECK (
        hora_entrada_almuerzo IS NULL OR hora_salida_almuerzo IS NULL OR
        hora_salida_almuerzo > hora_entrada_almuerzo
    )
);
CREATE UNIQUE INDEX uix_asi_trabajador_fecha ON asistencias (trabajador_id, fecha) WHERE estado_id = 1000;
CREATE INDEX idx_asi_fecha ON asistencias (fecha DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_asi_trabajador ON asistencias (trabajador_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_asi_estado_asistencia ON asistencias (estado_asistencia_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE asistencias IS 'Reglas de la tabla - asistencias
R.0: La tabla asistencias registra el control de presencia de los trabajadores, permitiendo la marcación de entrada y salida, el control de horas trabajadas y la gestión de permisos y licencias. Su propósito es proporcionar la base de datos para el cálculo de planillas, el control de puntualidad y la gestión del talento humano.
R.1: Control de Jornada Laboral. Las horas_trabajadas se calculan automáticamente como la diferencia entre hora_entrada y hora_salida, restando el tiempo de almuerzo si está registrado. El backend debe calcular este valor antes de insertar o actualizar.
R.2: Tipos de Asistencia. tipo_asistencia_id utiliza el dominio TipoAsistenciaID (4400-4403): NORMAL (4400), LICENCIA (4401), PERMISO (4402), JUSTIFICADA (4403). Afecta el cálculo de planillas y la contabilidad de ausencias.
R.3: Estado de Asistencia. estado_asistencia_id utiliza el dominio EstadoAsistenciaID (4450-4453): PRESENTE (4450), AUSENTE (4451), TARDE (4452), FALTA_INJUSTIFICADA (4453). Determina si la marcación es válida para el cálculo de horas.
R.4: Método de Marcación. metodo_marcacion_id utiliza el dominio MetodoMarcacionID (4500-4503): MANUAL (4500), BIOMETRICO (4501), QR (4502), APP (4503). Permite auditoría y control de seguridad sobre los registros de entrada/salida.
R.5: Unicidad por Trabajador y Fecha. Cada trabajador solo puede tener un registro de asistencia por día (estado_id = 1000). El backend debe validar que no exista un registro previo antes de insertar una nueva marcación.
R.6: Validación de Fechas. No se permiten asistencias con fecha posterior a la fecha actual (fecha <= CURRENT_DATE). El backend debe validar esta condición al insertar registros.
R.7: Gestión de Permisos y Licencias. Los registros con tipo_asistencia_id = 4401 (LICENCIA) o 4402 (PERMISO) requieren justificacion_archivo y justificacion_texto. El backend debe validar que estos campos estén completos.
R.8: Cálculo Automático de Horas Extras. horas_extras se calcula como las horas trabajadas que exceden la jornada laboral definida en parametros_globales (jornada_horas_diarias, por defecto 8 horas). El backend debe calcular este valor automáticamente.
R.9: Registro Comodín. El sistema debe mantener un registro inicial con asistencia_id = 1 que sirve como valor predeterminado para las FK que requieran una asistencia de referencia.
R.10: Índices Estratégicos. Los índices sobre fecha y trabajador garantizan consultas rápidas para reportes de asistencia, planillas y control de ausentismo.
R.11: Integración con Planillas. La tabla asistencias es la fuente principal de datos para el cálculo de planillas mensuales, determinando los días trabajados, horas extras y ausencias.
R.12: Integración con Módulo de Notificaciones. Cuando un trabajador acumula 3 faltas injustificadas consecutivas, el sistema debe generar automáticamente una alerta de tipo RRHH (4550) con nivel_critico_id = 2902 (MEDIA) para notificar al supervisor.
R.13: Control de Tardanzas. Si hora_entrada > (hora_inicio_jornada + 15 minutos), el estado_asistencia_id debe ser automáticamente 4452 (TARDE). La hora_inicio_jornada se obtiene de parametros_globales.
R.14: Marcación por QR/APP. Para metodo_marcacion_id = 4502 (QR) o 4503 (APP), el campo dispositivo debe registrar el identificador único del dispositivo o el código QR escaneado.
R.15: Auditoría de Cambios. El campo usuario_registro_id registra quién valida o modifica la asistencia, permitiendo auditar correcciones manuales.
R.16: Inmutabilidad de Registros Históricos. Una vez que la asistencia pasa a estado HISTORICO (1002), no puede ser modificada. Esto preserva la integridad de los registros para cálculos de planillas y reportes.';

DELETE FROM asistencias;
ALTER SEQUENCE asistencias_asistencia_id_seq RESTART WITH 1;

INSERT INTO asistencias (asistencia_id, trabajador_id, sucursal_id, fecha, hora_entrada, hora_salida, hora_entrada_almuerzo, hora_salida_almuerzo, horas_trabajadas, horas_extras, tipo_asistencia_id, estado_asistencia_id, metodo_marcacion_id, dispositivo, ip_origen, observaciones, justificacion, justificacion_archivo, usuario_registro_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, NULL, NULL, 0.00, 0.00, 4400, 4450, 4500, NULL, NULL, 'REGISTRO COMODIN INICIAL', NULL, NULL, 1, 1000, 1);

UPDATE asistencias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE asistencias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('asistencias_asistencia_id_seq', COALESCE((SELECT MAX(asistencia_id) FROM asistencias), 1));

-- ================================================================================================

CREATE TABLE planillas (
    planilla_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    periodo_mes INTEGER NOT NULL,
    periodo_gestion INTEGER NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_calculo DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_pago DATE NULL,
    tipo_planilla_id INTEGER NOT NULL DEFAULT 4600,     -- 4600=SUELDOS, 4601=JORNALES, 4602=CONTRATO
    total_bruto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_descuentos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_neto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_aportes_empresa DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_aportes_trabajador DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_aguinaldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_utilidades DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado_planilla_id INTEGER NOT NULL DEFAULT 4650,   -- 4650=BORRADOR, 4651=CALCULADA, 4652=APROBADA, 4653=PAGADA, 4654=ANULADA
    observaciones VARCHAR(1000) NULL,
    usuario_aprobacion_id BIGINT NULL,
    usuario_pago_id BIGINT NULL,
    fecha_aprobacion TIMESTAMPTZ NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pla_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_pla_usuario_aprobacion_id FOREIGN KEY (usuario_aprobacion_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_pla_usuario_pago_id FOREIGN KEY (usuario_pago_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_pla_tipo_planilla_id FOREIGN KEY (tipo_planilla_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_pla_estado_planilla_id FOREIGN KEY (estado_planilla_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_pla_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_pla_meses CHECK (periodo_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_pla_gestion CHECK (periodo_gestion >= 2020 AND periodo_gestion <= 2100),
    CONSTRAINT chk_pla_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_pla_totales CHECK (total_bruto >= 0 AND total_descuentos >= 0 AND total_neto >= 0)
);
CREATE INDEX idx_pla_fecha_calculo ON planillas (fecha_calculo DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pla_estado ON planillas (estado_planilla_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pla_periodo ON planillas (periodo_gestion, periodo_mes) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE planillas IS 'Reglas de la tabla - planillas
R.0: La tabla planillas es la cabecera de los procesos de liquidación de sueldos y salarios, agrupando los pagos a los trabajadores por período. Su propósito es centralizar el cálculo y la gestión de las planillas mensuales, permitiendo la auditoría y el control financiero de la nómina.
R.1: Unicidad por Período. Solo puede existir una planilla por mes y gestión en cada sucursal en estado ACTIVO (no ANULADA). El índice uix_pla_sucursal_mes_gestion garantiza esta unicidad.
R.2: Ciclo de Vida de la Planilla. estado_planilla_id utiliza el dominio EstadoPlanillaID (4650-4654): BORRADOR (inicial, editable), CALCULADA (valores calculados, pendiente de aprobación), APROBADA (aprobada por gerencia), PAGADA (pagada a los trabajadores), ANULADA (cancelada, irreversible).
R.3: Transiciones de Estado. Las transiciones de estado deben ser secuenciales: BORRADOR -> CALCULADA -> APROBADA -> PAGADA. No se permiten saltos de estado. ANULADA solo puede ser aplicada desde BORRADOR o CALCULADA.
R.4: Cálculo Automático de Totales. Los campos total_bruto, total_descuentos, total_neto, total_aportes_empresa y total_aportes_trabajador se calculan automáticamente al pasar de BORRADOR a CALCULADA. El backend debe recalcular estos valores sumando los registros de planillas_detalle.
R.5: Fechas de Corte. fecha_inicio y fecha_fin definen el período de la planilla. Generalmente, fecha_inicio = primer día del mes y fecha_fin = último día del mes. El backend debe validar que la planilla no se solape con otras planillas en la misma sucursal.
R.6: Autorización y Pago. Los campos usuario_aprobacion_id, usuario_pago_id, fecha_aprobacion y fecha_pago se actualizan automáticamente cuando la planilla cambia de estado a APROBADA o PAGADA.
R.7: Tipos de Planilla. tipo_planilla_id utiliza el dominio TipoPlanillaID (4600-4602): SUELDOS (mensual), JORNALES (diario/semanal), CONTRATO (por proyecto). Afecta el cálculo de conceptos y la periodicidad.
R.8: Gestión de Aguinaldo y Utilidades. total_aguinaldo y total_utilidades se calculan en períodos específicos (diciembre para aguinaldo, según normativa para utilidades). El backend debe validar que estos campos solo se calculen en los períodos correspondientes.
R.9: Registro Comodín. El sistema debe mantener un registro inicial con planilla_id = 1 que sirve como valor predeterminado para las FK que requieran una planilla de referencia.
R.10: Integración con Contabilidad. Una vez que la planilla alcanza el estado PAGADA, el sistema debe generar automáticamente los asientos contables correspondientes en el módulo de contabilidad (tabla asientos_contables).
R.11: Política de Retención. Las planillas deben conservarse indefinidamente por requisitos legales. No se permite la eliminación física de planillas (estado_id = 1001). Solo pueden pasar a HISTORICO (1002) después de 5 años.
R.12: Notificación de Aprobación. Cuando una planilla pasa a estado APROBADA, el sistema debe enviar una notificación (alertas_notificaciones) al usuario responsable de pagos.
R.13: Índices Estratégicos. Los índices sobre fecha y período garantizan consultas rápidas para reportes financieros y auditorías fiscales.
R.14: Relación con el Módulo de Caja. Al pasar a PAGADA, la planilla debe generar movimientos de egreso en la tabla movimientos (caja) por el total_neto.
R.15: Validación de Fechas de Pago. fecha_pago no puede ser anterior a fecha_calculo. El backend debe validar que el pago se realice después del cálculo.
R.16: Control de Presupuesto. Al aprobar una planilla, el sistema debe validar que total_neto no exceda el presupuesto de nómina configurado en parametros_globales (presupuesto_nomina_mensual).';

DELETE FROM planillas;
ALTER SEQUENCE planillas_planilla_id_seq RESTART WITH 1;

INSERT INTO planillas (planilla_id, sucursal_id, periodo_mes, periodo_gestion, fecha_inicio, fecha_fin, tipo_planilla_id, estado_planilla_id, estado_id, usuario_id_registro)
VALUES (1, 1, 1, 2026, '2026-01-01', '2026-01-31', 4600, 4650, 1000, 1);

UPDATE planillas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE planillas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('planillas_planilla_id_seq', COALESCE((SELECT MAX(planilla_id) FROM planillas), 1));

-- ================================================================================================

CREATE TABLE planillas_detalle (
    planilla_detalle_id BIGSERIAL PRIMARY KEY,
    planilla_id BIGINT NOT NULL,
    trabajador_id BIGINT NOT NULL,
    cargo_id BIGINT NOT NULL,
    sueldo_base DECIMAL(12,2) NOT NULL,
    dias_trabajados DECIMAL(5,2) NOT NULL,
    horas_trabajadas DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    horas_extras DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    valor_hora_extra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_horas_extras DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    bonificaciones DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    comisiones DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    aguinaldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    utilidades DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_ingresos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuentos_legales DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuentos_extra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    aportes_empresa DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    aportes_trabajador DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    neto_pagar DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    observaciones VARCHAR(500) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_plad_planilla_id FOREIGN KEY (planilla_id) REFERENCES planillas(planilla_id),
    CONSTRAINT fk_plad_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_plad_cargo_id FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id),
    CONSTRAINT fk_plad_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_plad_sueldo CHECK (sueldo_base >= 0),
    CONSTRAINT chk_plad_dias CHECK (dias_trabajados >= 0 AND dias_trabajados <= 31),
    CONSTRAINT chk_plad_horas CHECK (horas_trabajadas >= 0 AND horas_extras >= 0),
    CONSTRAINT chk_plad_totales CHECK (
        total_ingresos >= 0 AND descuentos_legales >= 0 AND
        descuentos_extra >= 0 AND neto_pagar >= 0
    ),
    CONSTRAINT chk_plad_coherencia CHECK (
        neto_pagar = (sueldo_base + total_horas_extras + bonificaciones + comisiones) -
        (descuentos_legales + descuentos_extra)
    )
);
CREATE UNIQUE INDEX uix_plad_planilla_trabajador ON planillas_detalle (planilla_id, trabajador_id) WHERE estado_id = 1000;
CREATE INDEX idx_plad_trabajador ON planillas_detalle (trabajador_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_plad_planilla ON planillas_detalle (planilla_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE planillas_detalle IS 'Reglas de la tabla - planillas_detalle
R.0: La tabla planillas_detalle almacena el detalle de la liquidación de cada trabajador en una planilla, incluyendo sueldos, bonificaciones, descuentos y aportes. Su propósito es desglosar el cálculo de la nómina por empleado para auditoría y control.
R.1: Cálculo Automático de Totales. Los campos total_ingresos y neto_pagar se calculan automáticamente al generar la planilla. El backend debe recalcular estos valores si se modifican los conceptos base.
R.2: Cálculo del Neto a Pagar. neto_pagar = (sueldo_base + total_horas_extras + bonificaciones + comisiones + aguinaldo + utilidades) - (descuentos_legales + descuentos_extra). La restricción chk_plad_coherencia valida esta fórmula.
R.3: Cálculo de Horas Extras. total_horas_extras = horas_extras * valor_hora_extra. El valor_hora_extra se calcula como (sueldo_base / 30 / 8) * 1.5 (según normativa laboral). El backend debe calcular estos valores automáticamente.
R.4: Descuentos Legales. descuentos_legales incluye conceptos como AFP, seguridad social, impuestos, etc. El backend debe calcular estos valores según la normativa vigente en parametros_globales.
R.5: Aportes Empresa vs Trabajador. aportes_empresa y aportes_trabajador se calculan según los porcentajes definidos en parametros_globales (ej. aporte_empresa_porcentaje, aporte_trabajador_porcentaje).
R.6: Gestión de Aguinaldo y Utilidades. Los campos aguinaldo y utilidades solo se calculan en los períodos correspondientes (diciembre para aguinaldo, según normativa para utilidades). El backend debe validar que estos campos solo se llenen en los períodos correctos.
R.7: Registro Comodín. El sistema debe mantener un registro inicial con planilla_detalle_id = 1 que sirve como valor predeterminado para las FK que requieran un detalle de planilla de referencia.
R.8: Integración con Asistencias. dias_trabajados y horas_trabajadas se calculan automáticamente a partir de la tabla asistencias para el período de la planilla. El backend debe sumar las horas y días registrados.
R.9: Inmutabilidad de Detalles. Una vez que la planilla pasa a estado CALCULADA, los detalles no pueden ser modificados directamente. Cualquier corrección debe realizarse mediante un ajuste en la planilla (descuentos_extra o bonificaciones).
R.10: Validación de Sueldo Base. sueldo_base debe ser igual al sueldo registrado en trabajadores_cargos.sueldo_base. El backend debe validar esta coherencia al generar la planilla.
R.11: Índices Estratégicos. Los índices sobre planilla y trabajador garantizan consultas rápidas para reportes de nómina y auditorías individuales.
R.12: Relación con Pagos. Al pagar una planilla, el sistema debe generar registros en pagos para cada trabajador, vinculando el planilla_detalle_id con el pago correspondiente.
R.13: Trazabilidad de Cambios. Cualquier modificación manual en una planilla detalle (por ejemplo, ajuste de descuentos_extra) debe registrar el motivo en observaciones y el usuario responsable en usuario_id_actualizacion.
R.14: Notificación de Inconsistencias. Si neto_pagar es 0 o negativo, el sistema debe generar una alerta de tipo RRHH (5200) con nivel_critico_id = 2902 (MEDIA) para revisión del supervisor.';

DELETE FROM planillas_detalle;
ALTER SEQUENCE planillas_detalle_planilla_detalle_id_seq RESTART WITH 1;

INSERT INTO planillas_detalle (planilla_detalle_id, planilla_id, trabajador_id, cargo_id, sueldo_base, dias_trabajados, total_ingresos, neto_pagar, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 0.00, 0, 0.00, 0.00, 1000, 1);

UPDATE planillas_detalle SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE planillas_detalle SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('planillas_detalle_planilla_detalle_id_seq', COALESCE((SELECT MAX(planilla_detalle_id) FROM planillas_detalle), 1));

-- ================================================================================================

CREATE TABLE contratos (
    contrato_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL,
    tipo_contrato_id INTEGER NOT NULL DEFAULT 4750,    -- 4750=INDEFINIDO, 4751=FIJO, 4752=EVENTUAL, 4753=PRACTICAS, 4754=CONSULTORIA
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    sueldo_base DECIMAL(12,2) NOT NULL,
    moneda_sueldo_id INTEGER NOT NULL DEFAULT 2300,    -- 2300=BOB, 2301=USD, 2302=EUR
    tipo_jornada_id INTEGER NOT NULL DEFAULT 4800,     -- 4800=COMPLETA, 4801=MEDIA, 4802=POR_HORAS
    horas_semanales DECIMAL(5,2) NOT NULL DEFAULT 40.00,
    estado_contrato_id INTEGER NOT NULL DEFAULT 4700,  -- 4700=VIGENTE, 4701=FINALIZADO, 4702=RENOVADO, 4703=SUSPENDIDO
    observaciones VARCHAR(1000) NULL,
    documento_contrato VARCHAR(255) NULL,
    fecha_firma DATE NULL,
    usuario_firma_id BIGINT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_con_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_con_usuario_firma_id FOREIGN KEY (usuario_firma_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_con_tipo_contrato_id FOREIGN KEY (tipo_contrato_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_con_tipo_jornada_id FOREIGN KEY (tipo_jornada_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_con_estado_contrato_id FOREIGN KEY (estado_contrato_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_con_moneda_sueldo_id FOREIGN KEY (moneda_sueldo_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_con_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_con_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT chk_con_sueldo CHECK (sueldo_base >= 0),
    CONSTRAINT chk_con_horas CHECK (horas_semanales > 0)
);
CREATE UNIQUE INDEX uix_con_trabajador_vigente ON contratos (trabajador_id) WHERE estado_contrato_id = 4750 AND estado_id = 1000;
CREATE INDEX idx_con_trabajador ON contratos (trabajador_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_con_fechas ON contratos (fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_con_estado ON contratos (estado_contrato_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE contratos IS 'Reglas de la tabla - contratos
R.0: La tabla contratos gestiona el histórico de contratos laborales de los trabajadores, permitiendo controlar las fechas de vigencia, sueldos y condiciones de contratación. Su propósito es mantener un registro completo de la relación laboral para auditoría, cálculo de antigüedad y gestión de beneficios.
R.1: Unicidad de Contrato Vigente. Solo puede existir un contrato activo por trabajador (estado_contrato_id = 4700). El índice uix_con_trabajador_vigente garantiza esta unicidad.
R.2: Renovaciones Automáticas. Al renovar un contrato, el contrato anterior debe pasar a estado FINALIZADO (4701) y se crea uno nuevo con estado VIGENTE (4700). El backend debe gestionar esta transición.
R.3: Control de Fechas. fecha_inicio es obligatoria. fecha_fin puede ser NULL para contratos indefinidos o que aún no tienen fecha de término.
R.4: Gestión de Documentos. documento_contrato almacena la ruta del archivo PDF del contrato firmado. Sigue la regla R.G.8 para nomenclatura de archivos.
R.5: Tipos de Contrato. tipo_contrato_id utiliza el dominio TipoContratoID (4750-4754): INDEFINIDO, FIJO, EVENTUAL, PRACTICAS, CONSULTORIA. Afecta el cálculo de beneficios y la normativa aplicable.
R.6: Tipos de Jornada. tipo_jornada_id utiliza el dominio TipoJornadaID. Determina el cálculo de horas_trabajadas y el sueldo base.
R.7: Registro Comodín. El sistema debe mantener un registro inicial con contrato_id = 1 que sirve como valor predeterminado para las FK que requieran un contrato de referencia.
R.8: Integración con Planillas. El sueldo_base del contrato vigente se utiliza como base para el cálculo de la planilla mensual. Si el trabajador tiene un contrato con moneda diferente, el backend debe aplicar el tipo de cambio vigente.
R.9: Notificación de Vencimiento. Cuando un contrato con fecha_fin definida está a 30 días de vencer, el sistema debe generar una alerta de tipo VENCIMIENTO_CONTRATO (4553 / 2726) para notificar al supervisor.
R.10: Historial de Cambios. Cada cambio de estado o actualización del contrato debe registrar el evento en logs_ejecucion para trazabilidad completa.';

DELETE FROM contratos;
ALTER SEQUENCE contratos_contrato_id_seq RESTART WITH 1;

INSERT INTO contratos (contrato_id, trabajador_id, tipo_contrato_id, fecha_inicio, sueldo_base, moneda_sueldo_id, tipo_jornada_id, estado_contrato_id, estado_id, usuario_id_registro)
VALUES (1, 1, 4750, CURRENT_DATE, 0.00, 2300, 4800, 4700, 1000, 1);

UPDATE contratos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE contratos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('contratos_contrato_id_seq', COALESCE((SELECT MAX(contrato_id) FROM contratos), 1));

-- ================================================================================================

CREATE TABLE historicos (
    historico_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,

    -- Datos del Cliente (congelados en el momento de la venta).
	cliente_id BIGINT NOT NULL DEFAULT 1,
    cliente_nombre VARCHAR(200) NOT NULL,
    cliente_documento VARCHAR(30) NOT NULL,
    cliente_documento_complemento VARCHAR(10) NULL,
    cliente_tipo_documento_abreviatura VARCHAR(10) NOT NULL,
    cliente_razon_social VARCHAR(150) NULL,
    cliente_direccion VARCHAR(255) NULL,
    cliente_telefono VARCHAR(20) NULL,
    cliente_email VARCHAR(100) NULL,

    -- Datos de la Sucursal (congelados en el momento de la venta).
	sucursal_id BIGINT NOT NULL DEFAULT 1,
    sucursal_nombre VARCHAR(2000) NOT NULL,
    sucursal_codigo VARCHAR(30) NOT NULL,
    sucursal_telefono VARCHAR(100) NULL,
    sucursal_ubicacion VARCHAR(500) NULL,
    sucursal_codigo_sin INTEGER NOT NULL,
    sucursal_punto_venta INTEGER NOT NULL,

    -- Datos de la Empresa (congelados en el momento de la venta).
	empresa_id BIGINT NOT NULL DEFAULT 1,
    empresa_nombre VARCHAR(200) NOT NULL,
    empresa_codigo VARCHAR(10) NOT NULL,
    empresa_nit VARCHAR(30) NOT NULL,
    empresa_autorizacion VARCHAR(50) NOT NULL,
    empresa_actividad_economica VARCHAR(200) NULL,

    -- Datos de la Cabecera de la Factura (desnormalizados de kardex).
    numero_factura VARCHAR(60) NOT NULL,
    fecha_emision TIMESTAMPTZ NOT NULL,
    tipo_comprobante_abreviatura VARCHAR(10) NOT NULL,
    tipo_factura_abreviatura VARCHAR(10) NOT NULL,
    lugar_entrega VARCHAR(2000) NULL,

    items JSONB NOT NULL,

    -- Totales de la Factura
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuento_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    iva DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_cambio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    metodo_pago_abreviatura VARCHAR(10) NOT NULL DEFAULT 'E',
    tipo_moneda_abreviatura VARCHAR(10) NOT NULL DEFAULT 'BOB',
    factor_cambio DECIMAL(12,4) NOT NULL DEFAULT 1.0000,

    -- Auditoría y Control
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,

    -- Restricciones para asegurar la integridad de los datos históricos
    CONSTRAINT fk_dh_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_dh_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_dh_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_dh_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT fk_dh_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_dh_estado_id CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_dh_numero_factura_not_empty CHECK (TRIM(numero_factura) <> ''),
    CONSTRAINT chk_dh_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_dh_total CHECK (total >= 0),
    CONSTRAINT chk_dh_iva CHECK (iva >= 0),
    CONSTRAINT chk_dh_descuento_total CHECK (descuento_total >= 0)
);
CREATE INDEX idx_dh_kardex_id ON historicos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_cliente_id ON historicos (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_sucursal_id ON historicos (sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_empresa_id ON historicos (empresa_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_numero_factura ON historicos (numero_factura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_fecha_emision ON historicos (fecha_emision DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_cliente_documento ON historicos (cliente_documento) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_fecha_registro ON historicos (fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_dh_items ON historicos USING GIN (items);

COMMENT ON TABLE historicos IS 'Reglas de la tabla - historicos
R.0: La tabla historicos es el repositorio inmutable de los documentos fiscales emitidos, que congela toda la información contextual del momento de la transacción (cliente, productos, precios, empresa). Su propósito es garantizar la no repudiación y el cumplimiento fiscal, preservando la foto exacta de cada factura para su posterior consulta y auditoría, independientemente de los cambios que sufran las tablas maestras a lo largo del tiempo. Se conecta directamente con las tablas kardex, clientes, sucursales y empresas.
R.1: Acumulación Continua de Documentos Fiscales: La persistencia de transacciones e históricos de venta se realiza de manera ininterrumpida sin segmentaciones físicas ni clonación de esquemas ante los cierres de gestión anual, controlando su estado operativo exclusivamente mediante el campo estado_id.
R.2: Congelamiento Total de Entidades Relacionadas: Todo documento emitido debe almacenar de manera redundante y estática la totalidad de los datos fiscales de la empresa, sucursal y cliente vigentes al instante de la firma digital, garantizando la inmutabilidad jurídica frente a mutaciones posteriores en los catálogos maestros del sistema.
R.3: Estructura del JSON de Productos: El campo items almacena el detalle de la transacción en formato JSONB con la siguiente estructura:
[
    {
        "producto_id": 1,
        "codigo": "PARA500",
        "nombre": "Paracetamol 500 mg",
        "lote": "L2026001",
        "fecha_vencimiento": "2028-05-31",
        "cantidad": 2,
        "precio_unitario": 3.50,
        "descuento": 0,
        "subtotal": 7.00,
        "total": 7.00,
        "unidad_medida": "Caja",
        "registro_sanitario": "RS-123456",
        "laboratorio": "INTI",
        "concentracion": "500 mg",
        "presentacion": "CAJA X 10",
        "forma_farmaceutica": "Tableta"
    }
]
R.4: Inmutabilidad por Diseño y Protección a Nivel de Aplicación: La tabla historicos es inmutable por diseño. El sistema implementa la lógica de bloqueo de UPDATE y DELETE en la capa de servicios del backend (NestJS), garantizando su inmutabilidad fiscal y evitando la manipulación retrospectiva de documentos fiscales.
R.5: Control de Inserciones en Periodos Cerrados: Para proteger la integridad fiscal, el sistema bloquea la inserción de nuevos documentos en periodos fiscales que hayan sido marcados como "cerrados" en la tabla parametros_globales.
R.6: Registro Inicial Comodín: La tabla debe contener un registro inicial con historico_id = 1 que sirve como valor predeterminado para las FK que requieran un documento histórico de referencia. Este registro tiene estado_id = 1002 (HISTORICO) y no puede ser modificado ni eliminado.
R.7: Indexación y Rendimiento de Consultas Históricas: La tabla debe contar con índices estratégicos para garantizar consultas rápidas en la generación de reportes y búsquedas de documentos fiscales por periodo, número de factura, cliente o kardex relacionado.
R.8: Validación de Integridad del JSON de Items: El campo items debe ser un arreglo JSON válido que contenga al menos un objeto con la estructura definida en R.3. No se permiten items vacíos o con estructura incorrecta que impidan la reproducción fiel de la factura.
R.9: Trazabilidad de Documentos Anulados: Cuando un documento fiscal es anulado en la tabla kardex (estado_id = 1003), el registro en historicos debe permanecer intacto como evidencia de la transacción original, pero debe quedar claramente identificado que el documento fue anulado mediante una relación con el kardex anulado.
R.10: Almacenamiento de Respaldo de Recetas Médicas: Para productos que requieren receta médica (productos.requiere_receta = 1), el sistema debe almacenar una copia del documento en el campo receta_pdf de la tabla kardex, y esta información debe reflejarse en el documento histórico para auditoría sanitaria.
R.11: Esta tabla actúa como un repositorio inmutable de los documentos fiscales emitidos. Su propósito es preservar la foto exacta de la transacción en el momento de la emisión, independientemente de cambios posteriores en las tablas maestras (clientes, productos, precios).
R.12: El campo items es un arreglo JSONB que contiene el detalle de los productos vendidos. Cada objeto debe incluir, como mínimo: producto_id, codigo, nombre, lote, cantidad, precio_unitario y subtotal. Esta estructura garantiza la reproducción fiel de la factura original.';

DELETE FROM historicos;
ALTER SEQUENCE historicos_historico_id_seq RESTART WITH 1;

INSERT INTO historicos (historico_id, kardex_id, cliente_id, sucursal_id, empresa_id, cliente_nombre, cliente_documento, cliente_documento_complemento, cliente_tipo_documento_abreviatura, cliente_razon_social, cliente_direccion, cliente_telefono, cliente_email, sucursal_nombre, sucursal_codigo, sucursal_telefono, sucursal_ubicacion, sucursal_codigo_sin, sucursal_punto_venta, empresa_nombre, empresa_codigo, empresa_nit, empresa_autorizacion, empresa_actividad_economica, numero_factura, fecha_emision, tipo_comprobante_abreviatura, tipo_factura_abreviatura, lugar_entrega, items, subtotal, descuento_total, iva, total, total_pagado, total_cambio, metodo_pago_abreviatura, tipo_moneda_abreviatura, factor_cambio, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 'NINGUNO', '0', NULL, 'NINGUNO', NULL, NULL, NULL, NULL, 'NINGUNO', 'NIN', NULL, NULL, 0, 0, 'NINGUNA', 'NIN', '000000000', '00000000000000000000', NULL, '0000000', '2026-01-01', 'NINGUNO', 'NINGUNO', NULL, '[]'::jsonb, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 'E', 'BOB', 1.0000, 1000, 1);

UPDATE historicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE historicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('historicos_historico_id_seq', COALESCE((SELECT MAX(historico_id) FROM historicos), 1));

-- ================================================================================================

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
    CONSTRAINT fk_cfg_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT fk_cfg_formato_pdf_id FOREIGN KEY (formato_pdf_id) REFERENCES dominios(dominio_id),
    CONSTRAINT fk_cfg_estado_id FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
    CONSTRAINT chk_cfg_pie_pagina_min_length CHECK (pie_pagina IS NULL OR LENGTH(TRIM(pie_pagina)) >= 3),
    CONSTRAINT chk_cfg_mensaje_agradecimiento_min_length CHECK (mensaje_agradecimiento IS NULL OR LENGTH(TRIM(mensaje_agradecimiento)) >= 3)
);
CREATE UNIQUE INDEX uix_cfg_empresa_unique ON configuraciones (empresa_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE configuraciones IS 'Reglas de la tabla - configuraciones
R.0: La tabla configuraciones almacena las preferencias de personalización de la interfaz de usuario para cada empresa, como el formato de los PDFs de facturación y los mensajes de agradecimiento. Su propósito es permitir la customización de la imagen corporativa y el formato de los documentos emitidos, mejorando la experiencia del cliente y la uniformidad de la marca. Se conecta directamente con las tablas empresas y dominios (formato PDF).
R.1: Cada empresa puede tener una única configuración de facturación activa o histórica, garantizada por el índice único uix_cfg_empresa_unique.
R.2: pie_pagina almacena el texto que aparecerá al final de cada página del documento fiscal. Es opcional y debe tener al menos 3 caracteres si se especifica.
R.3: logo_secundario almacena únicamente el nombre del archivo y su extensión (ej. ''logo_secundario.png''). La resolución de la URL absoluta para el renderizado en el frontend se realiza mediante variable de entorno. Sigue la regla R.G.4 para el reemplazo controlado de archivos multimedia.
R.4: mensaje_agradecimiento almacena el texto de agradecimiento que aparecerá al final del documento fiscal. Es opcional y debe tener al menos 3 caracteres si se especifica.
R.5: Solo puede existir un único registro en estado ACTIVO por empresa_id. Al crear una nueva configuración, la anterior debe pasar automáticamente a estado HISTORICO para preservar la trazabilidad de los cambios en el formato de facturación.';

DELETE FROM configuraciones;
ALTER SEQUENCE configuraciones_configuracion_id_seq RESTART WITH 1;

INSERT INTO configuraciones (configuracion_id, empresa_id, formato_pdf_id, pie_pagina, logo_secundario, mensaje_agradecimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 1950, NULL, NULL, NULL, 1000, 1);

UPDATE configuraciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE configuraciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('configuraciones_configuracion_id_seq', COALESCE((SELECT MAX(configuracion_id) FROM configuraciones), 1));

-- ================================================================================================

/**
 * @function fn_validar_reglas_negocio
 * @description Valida TODAS las reglas de negocio del sistema en un solo lugar
 *
 * 📌 CONTEXTOS SOPORTADOS:
 *   - 'KARDEX': Validación de cabecera de transacción
 *   - 'KARDEX_PRODUCTO': Validación de detalle de transacción
 *   - 'DOMINIO': Validación de dominios protegidos
 *
 * 📌 REGLAS DE NEGOCIO APLICADAS:
 *   - R.1: Registro Inicial Comodín (ID=1) no modificable
 *   - R.2: Control de Estados (ACTIVO, BORRADO, HISTORICO, ANULADO)
 *   - R.8: Ventas al contado (estado_financiero_id = 2400)
 *   - R.9: Crédito a proveedores (estado_financiero_id 2400-2402)
 *   - R.14: Matriz de integridad de entidades por evento
 *   - R.16: Validación de estado de traspaso (OBS. 04)
 *   - R.17: Validación de estado de pedido
 *   - R.18: Validación de tipo de despacho
 *   - R.19: Validación de devoluciones (OBS. 11)
 *   - R.G.6: Dominios protegidos (es_protegido = 1)
 *
 * ================================================================================================
 *
 * @param {VARCHAR} p_contexto - Contexto de validación
 *   - 'KARDEX': Validación de cabecera de transacción
 *   - 'KARDEX_PRODUCTO': Validación de detalle de transacción
 *   - 'DOMINIO': Validación de dominios protegidos
 *
 * @param {INTEGER} p_evento_id - ID del evento (dominio EventoID 1050-1070)
 *   - 1050: COMPRA
 *   - 1051: VENTA
 *   - 1052: PROFORMA
 *   - 1053: EGRESO_TRASPASO
 *   - 1054: INGRESO_TRASPASO
 *   - 1055: ANULACION
 *   - 1056: AJUSTE_INGRESO
 *   - 1057: AJUSTE_EGRESO
 *   - 1058: SOLICITUD_COMPRA
 *   - 1059: VENTA_RESERVA
 *   - 1060: DEVOLUCION_CLIENTE ⚠️ (requiere lote real > 1, tipo_pago_id = 1406)
 *   - 1061: DEVOLUCION_PROVEEDOR ⚠️ (requiere lote real > 1)
 *   - 1062: ROBO
 *   - 1063: PERDIDA_CADUCIDAD
 *   - 1064: MERMA_ROTURA
 *   - 1065: INVENTARIO_FISICO_SOBRANTE
 *   - 1066: INVENTARIO_FISICO_FALTANTE
 *   - 1067: CONVERSION_UNIDADES ⚠️ (requiere cantidad > 0 Y cantidad_salida > 0)
 *   - 1068: RETIRO_CUARENTENA ⚠️ (evento de ajuste)
 *
 * @param {BIGINT} p_cliente_id - ID del cliente (tabla clientes)
 *   - 1: Cliente comodín (anónimo / sin identificar)
 *   - >1: Cliente registrado
 *
 * @param {BIGINT} p_proveedor_id - ID del proveedor (tabla proveedores)
 *   - 1: Proveedor comodín
 *   - >1: Proveedor registrado
 *
 * @param {INTEGER} p_estado_financiero_id - Estado financiero (dominio 2400-2404)
 *   - 2400: CANCELADO (transacción completamente pagada)
 *   - 2401: PENDIENTE (sin abonos registrados)
 *   - 2402: PARCIAL (con abonos parciales)
 *   - 2403: NINGUNO (sin estado financiero definido)
 *   - 2404: DEVOLUCION_GENERADA ✅ NUEVO (OBS. 14)
 *
 * @param {DECIMAL(12,2)} p_total_venta - Total de venta sin factura (precio base)
 * @param {DECIMAL(12,2)} p_total_venta_factura - Total de venta con factura (con IVA)
 *
 * @param {INTEGER} p_estado_id - Estado del registro (dominio EstadoID 1000-1003)
 *   - 1000: ACTIVO (registro operativo y vigente)
 *   - 1001: BORRADO (baja lógica definitiva)
 *   - 1002: HISTORICO (registro archivado e inmutable)
 *   - 1003: ANULADO (transacción cancelada e irreversible)
 *
 * @param {BIGINT} p_kardex_origen_id - ID del origen (para traspasos - OBS. 03)
 *   - Obligatorio para INGRESO_TRASPASO (1054)
 *   - Debe ser NULL para EGRESO_TRASPASO (1053)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_kardex_referencia_id - ID de la transacción original (para devoluciones)
 *   - Obligatorio para DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_sucursal_id - ID de la sucursal origen
 * @param {BIGINT} p_sucursal_destino_id - ID de la sucursal destino
 *   - Obligatorio para traspasos (1053, 1054)
 *   - Debe ser diferente a sucursal_id
 *
 * @param {INTEGER} p_estado_traspaso_id - Estado del traspaso (dominio 2100-2103 - OBS. 04)
 *   - 2100: EN_TRANSITO (estado inicial para INGRESO_TRASPASO - OBS. 13)
 *   - 2101: RECIBIDO
 *   - 2102: RECHAZADO
 *   - 2103: NO_APLICA (para eventos que no son traspasos)
 *
 * @param {BIGINT} p_kardex_pedido_compra_id - ID del pedido de compra (OBS. 14)
 *   - Obligatorio para SOLICITUD_COMPRA (1058)
 *   - Debe ser NULL para otros eventos
 *
 * @param {BIGINT} p_kardex_id - ID de la cabecera (tabla kardex)
 *   - Obligatorio para contexto 'KARDEX_PRODUCTO'
 *
 * @param {DECIMAL(12,2)} p_cantidad - Cantidad de entrada
 *   - Debe ser > 0 para eventos de ingreso (1050, 1054, 1056, 1060, 1065, 1069)
 *   - Debe ser = 0 para eventos de egreso (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
 *   - Debe ser > 0 para CONVERSION_UNIDADES (1067)
 *
 * @param {DECIMAL(12,2)} p_cantidad_salida - Cantidad de salida
 *   - Debe ser = 0 para eventos de ingreso
 *   - Debe ser > 0 para eventos de egreso (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
 *   - Debe ser > 0 para CONVERSION_UNIDADES (1067)
 *
 * @param {DECIMAL(12,2)} p_pcompra - Precio de compra unitario
 *   - Debe ser > 0 para COMPRA (1050)
 *   - Debe ser = 0 para ajustes y traspasos
 *
 * @param {DECIMAL(12,2)} p_precio_venta - Precio de venta sin factura
 *   - Debe ser > 0 para VENTA (1051) y VENTA_RESERVA (1059)
 *   - Debe ser = 0 para compras, ajustes y traspasos
 *
 * @param {DECIMAL(12,2)} p_precio_venta_factura - Precio de venta con factura (con IVA)
 *   - Debe ser > 0 para VENTA (1051) y VENTA_RESERVA (1059)
 *   - Debe ser = 0 para compras, ajustes y traspasos
 *
 * @param {BIGINT} p_tipo_pago_id - Tipo de pago (dominio 1400-1409 - OBS. 06)
 *   - 1400: NINGUNO (tipo neutral para proformas, ajustes y traspasos)
 *   - 1401-1409: Tipos definidos solo para VENTA (1051)
 *   - 1406: SIN_PAGO (obligatorio para DEVOLUCION_CLIENTE - OBS. 05)
 *
 * @param {INTEGER} p_tipo_venta_id - Tipo de venta (dominio 1350-1352 - OBS. 07)
 *   - 1350: NINGUNO (tipo neutral para proformas, ajustes y traspasos)
 *   - 1351: CON_FACTURA (solo para VENTA)
 *   - 1352: SIN_FACTURA (solo para VENTA)
 *
 * @param {BIGINT} p_lote_id - ID del lote afectado (tabla lotes_productos - OBS. 01)
 *   - Debe ser > 1 para DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
 *   - Debe ser el mismo que el origen para INGRESO_TRASPASO (1054 - OBS. 09)
 *   - Puede ser 1 (comodín) para otros eventos
 *
 * @param {DECIMAL(12,2)} p_costo_venta - Costo de venta (OBS. 16)
 *   - Debe ser 0 para INGRESO_TRASPASO (1054)
 *   - Debe ser > 0 para VENTA (1051)
 *   - Debe ser = costo_venta de la venta original para DEVOLUCION_CLIENTE (OBS. 16)
 *
 * @param {BIGINT} p_sucursal_detalle_id - ID de la sucursal en detalle (OBS. 10)
 *   - Debe coincidir con sucursal_id para EGRESO_TRASPASO (1053)
 *   - Debe coincidir con sucursal_destino_id para INGRESO_TRASPASO (1054)
 *
 * @param {DECIMAL(12,2)} p_descuento - Descuento aplicado (OBS. 10)
 *   - Solo permitido para VENTA (1051)
 *   - Debe ser 0 para ajustes, traspasos y otros eventos
 *   - Debe ser 0 para DEVOLUCION_CLIENTE (OBS. 06)
 *
 * @param {INTEGER} p_motivo_anulacion_id - Motivo de anulación (dominio 2450-2455 - OBS. 13)
 *   - 2450-2454: Motivos permitidos solo para ANULACION (1055)
 *   - 2455: NINGUNO para otros eventos
 *   - Debe ser 2455 para DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR (OBS. 09)
 *
 * @param {INTEGER} p_motivo_devolucion_id - Motivo de devolución (dominio 3500-3508 - OBS. 12)
 *   - 3500: PRODUCTO_VENCIDO
 *   - 3501: PRODUCTO_DAÑADO
 *   - 3502: ERROR_PEDIDO
 *   - 3503: EXCESO_STOCK
 *   - 3504: DESCONTINUADO
 *   - 3505: DEVOLUCION_CLIENTE
 *   - 3506: NINGUNO (para ajustes y otros eventos)
 *   - 3507: PRODUCTO_NO_SOLICITADO ✅ NUEVO
 *   - 3508: PRODUCTO_DEFECTUOSO ✅ NUEVO
 *   - Debe ser distinto de 3506 para DEVOLUCION_CLIENTE y DEVOLUCION_PROVEEDOR (OBS. 11)
 *
 * @param {VARCHAR} p_comprobante_referencia - Comprobante de referencia (OBS. 11)
 *   - Obligatorio para DEVOLUCION_CLIENTE
 *   - Debe ser NULL para otros eventos
 *
 * @param {DECIMAL(12,2)} p_total_compra - Total de compra
 *   - Debe ser > 0 para COMPRA (1050)
 *   - Debe ser >= 0 para DEVOLUCION_PROVEEDOR (OBS. 11)
 *
 * @param {BIGINT} p_dominio_id - ID del dominio a validar (tabla dominios)
 *   - Obligatorio para contexto 'DOMINIO'
 *   - Verifica que es_protegido != 1 (R.G.6)
 *
 * @returns {VOID} - No retorna valor
 *
 * @throws {EXCEPTION} Con mensajes descriptivos en los siguientes casos:
 *   - Evento no válido para el contexto
 *   - Cantidades inconsistentes con el tipo de evento (OBS. 05)
 *   - Precios incorrectos para el tipo de evento (OBS. 11)
 *   - Tipos de pago/venta no permitidos (OBS. 06, 07)
 *   - Descuento no permitido para ajustes (OBS. 10)
 *   - Descuento no permitido para DEVOLUCION_CLIENTE (OBS. 06)
 *   - Motivos de anulación/devolución no permitidos (OBS. 12, 13)
 *   - Lote comodín usado en devoluciones (OBS. 01)
 *   - Lote incorrecto en traspasos (OBS. 09)
 *   - Sucursal incorrecta en traspasos (OBS. 10)
 *   - costo_venta incorrecto en traspasos (OBS. 16)
 *   - Estado de traspaso incorrecto (OBS. 04, 13)
 *   - kardex_pedido_compra_id incorrecto (OBS. 14)
 *   - kardex_referencia_id obligatorio en devoluciones (OBS. 11)
 *   - comprobante_referencia obligatorio en DEVOLUCION_CLIENTE (OBS. 11)
 *   - Dominio protegido (es_protegido = 1 - R.G.6)
 *   - Contexto desconocido
 *
 * @since 4.3
 * @see kardex, kardex_productos, dominios
 * @see Reglas de Negocio R.1 a R.21 en la documentación
 *
 * ================================================================================================
 */

CREATE FUNCTION fn_validar_reglas_negocio(
    -- Contexto
    p_contexto VARCHAR,

    -- Parámetros para KARDEX (Cabecera)
    p_evento_id INTEGER DEFAULT NULL,
    p_cliente_id BIGINT DEFAULT NULL,
    p_proveedor_id BIGINT DEFAULT NULL,
    p_estado_financiero_id INTEGER DEFAULT NULL,
    p_total_venta DECIMAL(12,2) DEFAULT NULL,
    p_total_venta_factura DECIMAL(12,2) DEFAULT NULL,
    p_estado_id INTEGER DEFAULT NULL,

    -- Parámetros para TRASPASOS
    p_kardex_origen_id BIGINT DEFAULT NULL,
    p_sucursal_id BIGINT DEFAULT NULL,
    p_sucursal_destino_id BIGINT DEFAULT NULL,
    p_estado_traspaso_id INTEGER DEFAULT NULL,
    p_kardex_pedido_compra_id BIGINT DEFAULT NULL,
    p_kardex_referencia_id BIGINT DEFAULT NULL,
    p_comprobante_referencia VARCHAR DEFAULT NULL,
    p_total_compra DECIMAL(12,2) DEFAULT NULL,

    -- Parámetros para KARDEX_PRODUCTO (Detalle)
    p_kardex_id BIGINT DEFAULT NULL,
    p_cantidad DECIMAL(12,2) DEFAULT NULL,
    p_cantidad_salida DECIMAL(12,2) DEFAULT NULL,
    p_pcompra DECIMAL(12,2) DEFAULT NULL,
    p_precio_venta DECIMAL(12,2) DEFAULT NULL,
    p_precio_venta_factura DECIMAL(12,2) DEFAULT NULL,
    p_tipo_pago_id BIGINT DEFAULT NULL,
    p_tipo_venta_id INTEGER DEFAULT NULL,
    p_lote_id BIGINT DEFAULT NULL,
    p_costo_venta DECIMAL(12,2) DEFAULT NULL,
    p_sucursal_detalle_id BIGINT DEFAULT NULL,

    -- Parámetros adicionales
    p_descuento DECIMAL(12,2) DEFAULT NULL,
    p_motivo_anulacion_id INTEGER DEFAULT NULL,
    p_motivo_devolucion_id INTEGER DEFAULT NULL,

    -- Parámetros para DOMINIO
    p_dominio_id BIGINT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_evento_id INTEGER;
    v_es_protegido INTEGER;
    v_estado_actual INTEGER;
    v_origen_evento_id INTEGER;
    v_origen_estado_id INTEGER;
    v_origen_sucursal_id BIGINT;
    v_origen_lote_id BIGINT;
    v_origen_costo_venta DECIMAL(12,2);
    v_referencia_tipo INTEGER;
    v_monto_devolucion DECIMAL(12,2);
BEGIN
    ------------------------------------------------------------------
    -- CONTEXTO 1: VALIDACIÓN PARA KARDEX (CABECERA)
    ------------------------------------------------------------------
    IF p_contexto = 'KARDEX' THEN

        -- ============================================================
        -- 1.1: VALIDACIÓN DE EVENTOS DE AJUSTE
        -- ============================================================
        IF p_evento_id IN (1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_total_venta <> 0 OR p_total_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere total_venta = 0 y total_venta_factura = 0', p_evento_id;
            END IF;
            IF p_cliente_id <> 1 OR p_proveedor_id <> 1 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere cliente_id = 1 y proveedor_id = 1', p_evento_id;
            END IF;
            IF p_motivo_devolucion_id IS NOT NULL AND p_motivo_devolucion_id <> 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento ajuste % no permite motivo_devolucion_id', p_evento_id;
            END IF;
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id <> 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento ajuste % no permite motivo_anulacion_id', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 1.2: VENTA debe ser CANCELADO
        -- ============================================================
        IF p_evento_id = 1051 AND p_estado_financiero_id <> 2400 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: VENTA (1051) requiere estado_financiero_id = 2400 (CANCELADO)';
        END IF;

        -- ============================================================
        -- 1.3: COMPRA puede tener cualquier estado financiero
        -- ============================================================
        IF p_evento_id = 1050 AND p_estado_financiero_id NOT IN (2400, 2401, 2402) THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: COMPRA (1050) requiere estado_financiero_id en (2400, 2401, 2402)';
        END IF;

        -- ============================================================
        -- 1.4: OTROS EVENTOS deben tener estado_financiero_id = 2403
        -- ============================================================
        IF p_evento_id NOT IN (1050, 1051) AND p_estado_financiero_id <> 2403 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % requiere estado_financiero_id = 2403 (NINGUNO)', p_evento_id;
        END IF;

        -- ============================================================
        -- 1.5: VALIDACIÓN DE ESTADOS
        -- ============================================================
        IF p_estado_id IS NOT NULL AND p_estado_id NOT IN (1000, 1001, 1002, 1003) THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Estado % no válido', p_estado_id;
        END IF;

        -- ============================================================
        -- ✅ 1.6: VALIDACIÓN DE ESTADO_TRASPASO_ID (OBS. 04)
        -- ============================================================
        IF p_evento_id IN (1053, 1054) THEN
            IF p_estado_traspaso_id IS NULL OR p_estado_traspaso_id NOT IN (2100, 2101, 2102) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Traspaso % requiere estado_traspaso_id en (2100, 2101, 2102)', p_evento_id;
            END IF;
        ELSE
            IF p_estado_traspaso_id IS NOT NULL AND p_estado_traspaso_id != 2103 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % debe tener estado_traspaso_id = 2103 (NO_APLICA)', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- ✅ 1.7: VALIDACIÓN DE KARDEX_PEDIDO_COMPRA_ID (OBS. 14)
        -- ============================================================
        IF p_evento_id = 1058 THEN
            IF p_kardex_pedido_compra_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: SOLICITUD_COMPRA (1058) requiere kardex_pedido_compra_id no nulo';
            END IF;
            -- Validar que el pedido exista y sea una solicitud de compra
            IF NOT EXISTS (
                SELECT 1 FROM kardex
                WHERE kardex_id = p_kardex_pedido_compra_id
                AND evento_id = 1058
                AND estado_id = 1000
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_pedido_compra_id % debe ser una SOLICITUD_COMPRA (1058) activa',
                    p_kardex_pedido_compra_id;
            END IF;
        ELSE
            IF p_kardex_pedido_compra_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_pedido_compra_id', p_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- ✅ 1.8: VALIDACIÓN DE TRASPASOS (OBS. 03 y 13)
        -- ============================================================

        -- Solo traspasos pueden tener origen y sucursal_destino
        IF p_evento_id NOT IN (1053, 1054) THEN
            IF p_kardex_origen_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_origen_id', p_evento_id;
            END IF;
            IF p_sucursal_destino_id IS NOT NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener sucursal_destino_id', p_evento_id;
            END IF;
        END IF;

        -- Traspasos requieren sucursal_destino_id diferente
        IF p_evento_id IN (1053, 1054) THEN
            IF p_sucursal_destino_id IS NULL OR p_sucursal_destino_id = p_sucursal_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Traspaso requiere sucursal_destino_id diferente a sucursal_id';
            END IF;
            IF NOT EXISTS (SELECT 1 FROM sucursales WHERE sucursal_id = p_sucursal_destino_id AND estado_id = 1000) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Sucursal destino % no existe o no está ACTIVA', p_sucursal_destino_id;
            END IF;
        END IF;

        -- ✅ INGRESO_TRASPASO (1054) - OBS. 13: Debe empezar en EN_TRANSITO (2100)
        IF p_evento_id = 1054 THEN
            -- Validar que el estado sea EN_TRANSITO al crear
            IF p_estado_traspaso_id != 2100 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: INGRESO_TRASPASO (1054) debe crearse con estado_traspaso_id = 2100 (EN_TRANSITO)';
            END IF;

            -- Validar origen
            IF p_kardex_origen_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: INGRESO_TRASPASO (1054) requiere kardex_origen_id no nulo';
            END IF;

            SELECT evento_id, estado_id, sucursal_id
            INTO v_origen_evento_id, v_origen_estado_id, v_origen_sucursal_id
            FROM kardex
            WHERE kardex_id = p_kardex_origen_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_origen_id % no existe', p_kardex_origen_id;
            END IF;

            IF v_origen_evento_id != 1053 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_origen_id % debe ser EGRESO_TRASPASO (1053). Es %',
                    p_kardex_origen_id, v_origen_evento_id;
            END IF;

            IF v_origen_estado_id != 1000 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO % debe estar ACTIVO (1000). Está %',
                    p_kardex_origen_id, v_origen_estado_id;
            END IF;

            IF v_origen_sucursal_id = p_sucursal_destino_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: Sucursal origen % no puede ser igual a destino %',
                    v_origen_sucursal_id, p_sucursal_destino_id;
            END IF;

            IF (
                SELECT 1 FROM kardex
                WHERE kardex_origen_id = p_kardex_origen_id
                AND evento_id = 1054
                AND estado_id != 1001
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO % ya vinculado a otro INGRESO_TRASPASO',
                    p_kardex_origen_id;
            END IF;
        END IF;

        -- EGRESO_TRASPASO (1053) NO debe tener origen
        IF p_evento_id = 1053 AND p_kardex_origen_id IS NOT NULL THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: EGRESO_TRASPASO (1053) no debe tener kardex_origen_id';
        END IF;

        -- ============================================================
        -- ✅ 1.9: VALIDACIÓN DE DEVOLUCIONES (OBS. 11)
        -- ============================================================

        -- DEVOLUCION_CLIENTE (1060)
        IF p_evento_id = 1060 THEN
            -- Validar kardex_referencia_id
            IF p_kardex_referencia_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere kardex_referencia_id no nulo';
            END IF;

            -- Validar que la referencia exista y sea una VENTA (1051)
            SELECT evento_id INTO v_referencia_tipo
            FROM kardex
            WHERE kardex_id = p_kardex_referencia_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % no existe', p_kardex_referencia_id;
            END IF;

            IF v_referencia_tipo != 1051 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % debe ser una VENTA (1051). Es %',
                    p_kardex_referencia_id, v_referencia_tipo;
            END IF;

            -- Validar comprobante_referencia
            IF p_comprobante_referencia IS NULL OR TRIM(p_comprobante_referencia) = '' THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere comprobante_referencia no nulo';
            END IF;

            -- Validar motivo_devolucion_id
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id = 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere motivo_devolucion_id distinto de NINGUNO (3506)';
            END IF;

            -- Validar totales
            IF p_total_venta < 0 OR p_total_venta_factura < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere totales >= 0';
            END IF;

            -- Validar tipo_pago_id (OBS. 05)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.5)

            -- Validar descuento (OBS. 06)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.4)

            -- Validar motivo_anulacion_id (OBS. 09)
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id != 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere motivo_anulacion_id = 2455 (NINGUNO)';
            END IF;

            -- Validar estado_financiero_id (OBS. 14)
            IF p_estado_financiero_id IS NOT NULL AND p_estado_financiero_id != 2404 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_CLIENTE (1060) requiere estado_financiero_id = 2404 (DEVOLUCION_GENERADA)';
            END IF;
        END IF;

        -- DEVOLUCION_PROVEEDOR (1061)
        IF p_evento_id = 1061 THEN
            -- Validar kardex_referencia_id
            IF p_kardex_referencia_id IS NULL THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere kardex_referencia_id no nulo';
            END IF;

            -- Validar que la referencia exista y sea una COMPRA (1050)
            SELECT evento_id INTO v_referencia_tipo
            FROM kardex
            WHERE kardex_id = p_kardex_referencia_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % no existe', p_kardex_referencia_id;
            END IF;

            IF v_referencia_tipo != 1050 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: kardex_referencia_id % debe ser una COMPRA (1050). Es %',
                    p_kardex_referencia_id, v_referencia_tipo;
            END IF;

            -- Validar motivo_devolucion_id
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id = 3506 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere motivo_devolucion_id distinto de NINGUNO (3506)';
            END IF;

            -- Validar totales
            IF p_total_compra < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere total_compra >= 0';
            END IF;

            -- Validar tipo_pago_id (OBS. 05)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.5)

            -- Validar descuento (OBS. 06)
            -- NOTA: Se valida en el contexto KARDEX_PRODUCTO (sección 2.4)

            -- Validar motivo_anulacion_id (OBS. 09)
            IF p_motivo_anulacion_id IS NOT NULL AND p_motivo_anulacion_id != 2455 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere motivo_anulacion_id = 2455 (NINGUNO)';
            END IF;

            -- Validar estado_financiero_id (OBS. 14)
            IF p_estado_financiero_id IS NOT NULL AND p_estado_financiero_id != 2404 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex]: DEVOLUCION_PROVEEDOR (1061) requiere estado_financiero_id = 2404 (DEVOLUCION_GENERADA)';
            END IF;
        END IF;

        -- OTROS EVENTOS: no deben tener kardex_referencia_id
        IF p_evento_id NOT IN (1060, 1061) AND p_kardex_referencia_id IS NOT NULL THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex]: Evento % no debe tener kardex_referencia_id', p_evento_id;
        END IF;

    ------------------------------------------------------------------
    -- CONTEXTO 2: VALIDACIÓN PARA KARDEX_PRODUCTOS (DETALLE)
    ------------------------------------------------------------------
    ELSIF p_contexto = 'KARDEX_PRODUCTO' THEN
        -- 2.1: Obtener el evento_id y estado_id de la cabecera
        SELECT evento_id, estado_id INTO v_evento_id, v_estado_actual
        FROM kardex
        WHERE kardex_id = p_kardex_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Cabecera con ID % no existe', p_kardex_id;
        END IF;

        -- 2.2: No permitir modificar ANULADAS
        IF v_estado_actual = 1003 THEN
            RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: No se puede modificar transacción ANULADA (estado_id = 1003)';
        END IF;

        -- ============================================================
        -- 2.3: ✅ VALIDACIÓN DE CANTIDADES POR EVENTO (OBS. 05)
        -- ============================================================

        -- INGRESO (1050, 1054, 1056, 1060, 1065, 1069)
        IF v_evento_id IN (1050, 1056, 1060, 1065, 1069) OR v_evento_id = 1054 THEN
            IF p_cantidad <= 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % (INGRESO) requiere cantidad > 0 y cantidad_salida = 0', v_evento_id;
            END IF;

        -- EGRESO (1051, 1053, 1057, 1062, 1063, 1064, 1066, 1068)
        ELSIF v_evento_id IN (1051, 1057, 1062, 1063, 1064, 1066, 1068) OR v_evento_id = 1053 OR v_evento_id = 1061 THEN
            -- 1061 (DEVOLUCION_PROVEEDOR) es egreso
            IF p_cantidad <> 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % (EGRESO) requiere cantidad = 0 y cantidad_salida > 0', v_evento_id;
            END IF;

        -- PROFORMA (1052), SOLICITUD_COMPRA (1058)
        ELSIF v_evento_id IN (1052, 1058) THEN
            IF p_cantidad <> 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere cantidad = 0 y cantidad_salida = 0', v_evento_id;
            END IF;

        -- VENTA_RESERVA (1059)
        ELSIF v_evento_id = 1059 THEN
            IF p_cantidad <> 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA (1059) requiere cantidad = 0 y cantidad_salida > 0';
            END IF;

        -- MIXTOS (1055, 1061) - 1061 ya está en EGRESO
        ELSIF v_evento_id IN (1055) THEN
            IF p_cantidad < 0 OR p_cantidad_salida < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere cantidades >= 0', v_evento_id;
            END IF;
            IF p_cantidad = 0 AND p_cantidad_salida = 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere al menos una cantidad > 0', v_evento_id;
            END IF;

        -- CONVERSION_UNIDADES (1067)
        ELSIF v_evento_id = 1067 THEN
            IF p_cantidad <= 0 OR p_cantidad_salida <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: CONVERSION_UNIDADES (1067) requiere cantidad > 0 y cantidad_salida > 0';
            END IF;

        -- Evento desconocido
        ELSE
            IF p_cantidad <> 0 OR p_cantidad_salida <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % no contemplado. Solo cantidades = 0', v_evento_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.4: ✅ VALIDACIÓN DE PRECIOS POR EVENTO (OBS. 11)
        -- ============================================================

        -- COMPRA (1050)
        IF v_evento_id = 1050 THEN
            IF p_pcompra <= 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: COMPRA (1050) requiere pcompra > 0 y precios venta = 0';
            END IF;

        -- VENTA (1051)
        ELSIF v_evento_id = 1051 THEN
            IF p_precio_venta <= 0 OR p_precio_venta_factura <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA (1051) requiere precios > 0';
            END IF;

        -- TRASPASOS (1053, 1054) - OBS. 11: precios deben ser 0
        ELSIF v_evento_id IN (1053, 1054) THEN
            IF p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Traspaso % requiere precio_venta = 0 y precio_venta_factura = 0', v_evento_id;
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Traspaso % no permite descuentos', v_evento_id;
            END IF;

        -- AJUSTES INTERNOS
        ELSIF v_evento_id IN (1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_pcompra <> 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Ajuste % requiere TODOS los precios = 0', v_evento_id;
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Ajuste % no permite descuentos', v_evento_id;
            END IF;

        -- PROFORMA (1052)
        ELSIF v_evento_id = 1052 THEN
            IF p_pcompra <> 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: PROFORMA (1052) requiere TODOS los precios = 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: PROFORMA no permite descuentos';
            END IF;

        -- SOLICITUD_COMPRA (1058)
        ELSIF v_evento_id = 1058 THEN
            IF p_pcompra < 0 OR p_precio_venta <> 0 OR p_precio_venta_factura <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: SOLICITUD_COMPRA requiere pcompra >= 0 y demás precios = 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: SOLICITUD_COMPRA no permite descuentos';
            END IF;

        -- VENTA_RESERVA (1059)
        ELSIF v_evento_id = 1059 THEN
            IF p_precio_venta <= 0 OR p_precio_venta_factura <= 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere precios > 0';
            END IF;
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA no permite descuentos';
            END IF;

        -- DEVOLUCION_CLIENTE (1060)
        ELSIF v_evento_id = 1060 THEN
            IF p_precio_venta < 0 OR p_precio_venta_factura < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE requiere precios >= 0';
            END IF;
            -- ✅ OBS. 06: Descuento debe ser 0
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE no permite descuentos. Debe ser 0.00';
            END IF;
            -- ✅ OBS. 05: tipo_pago_id debe ser 1406 (SIN_PAGO)
            -- Se valida en 2.5

        -- DEVOLUCION_PROVEEDOR (1061)
        ELSIF v_evento_id = 1061 THEN
            IF p_pcompra < 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR requiere pcompra >= 0';
            END IF;
            -- ✅ OBS. 06: Descuento debe ser 0
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR no permite descuentos. Debe ser 0.00';
            END IF;
            -- ✅ OBS. 05: tipo_pago_id debe ser 1400 (NINGUNO)
            -- Se valida en 2.5

        -- ANULACION (1055)
        ELSIF v_evento_id = 1055 THEN
            IF p_descuento IS NOT NULL AND p_descuento <> 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: ANULACION no permite descuentos';
            END IF;
        END IF;

        -- ============================================================
        -- 2.5: ✅ VALIDACIÓN DE TIPOS DE PAGO Y VENTA (OBS. 06 y 07)
        -- ============================================================

        -- Eventos NEUTRALES (incluye traspasos)
        IF v_evento_id IN (1052, 1053, 1054, 1055, 1056, 1057, 1058, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068) THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere tipo_pago_id = 1400', v_evento_id;
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Evento % requiere tipo_venta_id = 1350', v_evento_id;
            END IF;
        END IF;

        -- VENTA (1051): tipos definidos
        IF v_evento_id = 1051 THEN
            IF p_tipo_pago_id = 1400 OR p_tipo_venta_id = 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA (1051) requiere tipo_pago_id != 1400 y tipo_venta_id != 1350';
            END IF;
        END IF;

        -- VENTA_RESERVA (1059)
        IF v_evento_id = 1059 THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere tipo_pago_id = 1400';
            END IF;
            IF p_tipo_venta_id = 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: VENTA_RESERVA requiere tipo_venta_id != 1350';
            END IF;
        END IF;

        -- ✅ DEVOLUCION_CLIENTE (1060) - OBS. 05
        IF v_evento_id = 1060 THEN
            IF p_tipo_pago_id <> 1406 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE (1060) requiere tipo_pago_id = 1406 (SIN_PAGO)';
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_CLIENTE (1060) requiere tipo_venta_id = 1350 (NINGUNO)';
            END IF;
        END IF;

        -- ✅ DEVOLUCION_PROVEEDOR (1061) - OBS. 05
        IF v_evento_id = 1061 THEN
            IF p_tipo_pago_id <> 1400 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR (1061) requiere tipo_pago_id = 1400 (NINGUNO)';
            END IF;
            IF p_tipo_venta_id <> 1350 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: DEVOLUCION_PROVEEDOR (1061) requiere tipo_venta_id = 1350 (NINGUNO)';
            END IF;
        END IF;

        -- ============================================================
        -- ✅ 2.6: VALIDACIÓN DE SUCURSAL_ID EN DETALLE (OBS. 10)
        -- ============================================================
        IF v_evento_id = 1053 THEN
            -- EGRESO_TRASPASO: sucursal del detalle debe ser la sucursal origen
            IF p_sucursal_detalle_id IS NOT NULL AND p_sucursal_detalle_id != p_sucursal_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: EGRESO_TRASPASO requiere sucursal_detalle_id = sucursal_id origen (%)',
                    p_sucursal_id;
            END IF;
        END IF;

        IF v_evento_id = 1054 THEN
            -- INGRESO_TRASPASO: sucursal del detalle debe ser la sucursal destino
            IF p_sucursal_detalle_id IS NOT NULL AND p_sucursal_detalle_id != p_sucursal_destino_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO requiere sucursal_detalle_id = sucursal_destino_id (%)',
                    p_sucursal_destino_id;
            END IF;
        END IF;

        -- ============================================================
        -- ✅ 2.7: VALIDACIÓN DE LOTE_ID (OBS. 09)
        -- ============================================================
        IF v_evento_id = 1054 AND p_kardex_origen_id IS NOT NULL THEN
            -- Obtener el lote del origen
            SELECT kp.lote_id INTO v_origen_lote_id
            FROM kardex_productos kp
            WHERE kp.kardex_id = p_kardex_origen_id
            LIMIT 1;

            IF v_origen_lote_id IS NOT NULL AND p_lote_id IS NOT NULL AND v_origen_lote_id != p_lote_id THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO debe usar el mismo lote que el origen (%). Lote destino: %',
                    v_origen_lote_id, p_lote_id;
            END IF;
        END IF;

        -- ============================================================
        -- ✅ 2.8: VALIDACIÓN DE COSTO_VENTA (OBS. 16)
        -- ============================================================
        IF v_evento_id = 1054 THEN
            IF p_costo_venta IS NOT NULL AND p_costo_venta != 0 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: INGRESO_TRASPASO (1054) requiere costo_venta = 0. Recibido: %',
                    p_costo_venta;
            END IF;
        END IF;

        -- ============================================================
        -- ✅ 2.9: VALIDACIÓN DE LOTE_ID Y MOTIVO PARA DEVOLUCIONES (OBS. 01)
        -- ============================================================
        -- DEVOLUCION_CLIENTE (1060) y DEVOLUCION_PROVEEDOR (1061)
        -- DEBEN usar un lote REAL (id > 1), NO el comodín (id = 1)
        -- Y DEBEN tener un motivo_devolucion_id válido (3500-3505, 3507, 3508)
        -- ============================================================
        IF v_evento_id IN (1060, 1061) THEN
            -- Validar que el lote no sea el comodín (1)
            IF p_lote_id IS NULL OR p_lote_id = 1 THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Devolución (%) requiere un lote real (lote_id > 1). No puede usar el lote comodín (1)',
                    v_evento_id;
            END IF;

            -- Validar que el lote exista y esté ACTIVO y VIGENTE
            IF NOT EXISTS (
                SELECT 1 FROM lotes_productos
                WHERE lote_id = p_lote_id
                AND estado_id = 1000
                AND estado_lote_id = 2500  -- VIGENTE
            ) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: El lote % no existe, no está ACTIVO o no está VIGENTE',
                    p_lote_id;
            END IF;

            -- ✅ Validar motivo_devolucion_id para DEVOLUCIONES
            -- 3500: PRODUCTO_VENCIDO
            -- 3501: PRODUCTO_DAÑADO
            -- 3502: ERROR_PEDIDO
            -- 3503: EXCESO_STOCK
            -- 3504: DESCONTINUADO
            -- 3505: DEVOLUCION_CLIENTE
            -- 3507: PRODUCTO_NO_SOLICITADO ✅ NUEVO
            -- 3508: PRODUCTO_DEFECTUOSO ✅ NUEVO
            IF p_motivo_devolucion_id IS NULL OR p_motivo_devolucion_id NOT IN (3500, 3501, 3502, 3503, 3504, 3505, 3507, 3508) THEN
                RAISE EXCEPTION 'Regla de Negocio [Kardex Producto]: Devolución (%) requiere motivo_devolucion_id válido (3500-3505, 3507, 3508). Recibido: %',
                    v_evento_id, p_motivo_devolucion_id;
            END IF;
        END IF;

        -- ============================================================
        -- 2.10: ✅ VALIDACIÓN DE STOCK PARA VENTAS
        -- ============================================================
        -- NOTA: Se implementa en el backend para evitar dependencias cíclicas
        -- Verificar cantidad_salida <= cantidad_actual del lote

    ------------------------------------------------------------------
    -- CONTEXTO 3: VALIDACIÓN DE DOMINIOS PROTEGIDOS
    ------------------------------------------------------------------
    ELSIF p_contexto = 'DOMINIO' THEN
        SELECT es_protegido INTO v_es_protegido
        FROM dominios
        WHERE dominio_id = p_dominio_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Regla de Seguridad [Dominios]: Dominio ID % no existe', p_dominio_id;
        END IF;

        IF v_es_protegido = 1 THEN
            RAISE EXCEPTION 'Regla de Seguridad [Dominios]: Dominio ID % está protegido (es_protegido = 1)', p_dominio_id;
        END IF;

    ------------------------------------------------------------------
    -- CONTEXTO DESCONOCIDO
    ------------------------------------------------------------------
    ELSE
        RAISE EXCEPTION 'Regla de Negocio: Contexto desconocido: %. Contextos válidos: KARDEX, KARDEX_PRODUCTO, DOMINIO', p_contexto;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * Procesa y libera de forma automática todas las reservas de inventario (VENTA_RESERVA)
 * cuyo tiempo de vida (TTL) configurado mediante la fecha de expiración haya vencido.
 *
 * Lógica ejecutada por cada reserva expirada encontrada:
 * 1. Actualiza el estado de la proforma o reserva original en la tabla `kardex`
 *    a EXPIRADA (estado_proforma_id = 4003).
 * 2. Inserta un nuevo registro maestro en el `kardex` bajo el evento de compensación
 *    LIBERACION_RESERVA (evento_id = 1070) para reintegrar formalmente las unidades al inventario disponible.
 * 3. Duplica los ítems asociados desde `kardex_productos` ajustando la cantidad de salida a 0.00
 *    para restablecer el stock apartado.
 *
 * @function fn_liberar_reservas_expiradas
 * @returns {Promise<number>} Cantidad total de reservas procesadas y liberadas exitosamente en la ejecución.
 * @throws {DatabaseError} Si ocurre un fallo de integridad o concurrencia durante la transacción en PL/pgSQL.
 */

CREATE FUNCTION fn_liberar_reservas_expiradas()
RETURNS INTEGER AS $$
DECLARE
    v_reserva RECORD;
    v_nuevo_kardex_id BIGINT;
    v_contador INTEGER := 0;
BEGIN
    -- Recorrer todas las reservas/proformas pendientes cuya fecha de expiración ya se cumplió
    FOR v_reserva IN
        SELECT kardex_id, sucursal_id, cliente_id, proveedor_id, codigo
        FROM kardex
        WHERE evento_id = 1059 -- VENTA_RESERVA
          AND estado_proforma_id = 4001 -- PENDIENTE
          AND fecha_expiracion IS NOT NULL
          AND fecha_expiracion < CURRENT_TIMESTAMP
          AND estado_id = 1000
    LOOP
        -- A. Actualizar el estado de la reserva original a EXPIRADA (4003)
        UPDATE kardex
        SET estado_proforma_id = 4003,
            fecha_actualizacion = CURRENT_TIMESTAMP,
            usuario_id_actualizacion = 1 -- O sistema
        WHERE kardex_id = v_reserva.kardex_id;

        -- B. Generar un nuevo registro en el kardex con evento LIBERACION_RESERVA (1070)
        -- para devolver formalmente las cantidades al stock disponible.
        INSERT INTO kardex (
            tipo_comprobante_id, cliente_id, proveedor_id, sucursal_id,
            kardex_origen_id, evento_id, codigo, comprobante,
            fecha_kardex, estado_proforma_id, estado_id, usuario_id_registro
        ) VALUES (
            1103, v_reserva.cliente_id, v_reserva.proveedor_id, v_reserva.sucursal_id,
            v_reserva.kardex_id, 1070, 'LIB-' || v_reserva.codigo,
            'Liberación automática por expiración de TTL de la reserva: ' || v_reserva.codigo,
            CURRENT_TIMESTAMP, 4000, 1000, 1
        ) RETURNING kardex_id INTO v_nuevo_kardex_id;

        -- C. Copiar los detalles asociados desde kardex_productos invirtiendo o liberando el stock apartado
        INSERT INTO kardex_productos (
            kardex_id, producto_id, sucursal_id, lote_id, presentacion_id,
            tipo_pago_id, tipo_venta_id, cantidad, cantidad_unidad_base,
            cantidad_salida, pcompra, factor_venta, factor_facturacion,
            precio_venta, precio_venta_factura, costo_venta, descuento,
            estado_id, usuario_id_registro
        )
        SELECT
            v_nuevo_kardex_id, producto_id, sucursal_id, lote_id, presentacion_id,
            1400, 1350, cantidad, cantidad_unidad_base,
            0.00, -- Cantidad salida en 0 para reingresar/liberar el stock apartado
            pcompra, factor_venta, factor_facturacion,
            precio_venta, precio_venta_factura, costo_venta, descuento,
            1000, 1
        FROM kardex_productos
        WHERE kardex_id = v_reserva.kardex_id
          AND estado_id = 1000;

        v_contador := v_contador + 1;
    END LOOP;

    RETURN v_contador;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * Valida la coherencia de las cantidades y valores de una promoción según su tipo de beneficio.
 *
 * @param {integer} p_tipo_beneficio_id - Identificador del tipo de beneficio (ej. 1503 para CANTIDAD, 1501 para PORCENTAJE, etc.).
 * @param {integer} p_cantidad_requerida - Cantidad de unidades requeridas para aplicar la promoción.
 * @param {integer} p_cantidad_beneficio - Cantidad de unidades otorgadas como beneficio.
 * @param {numeric} p_valor_beneficio - Valor monetario o porcentaje asociado al beneficio de la promoción.
 * @returns {boolean} Retorna true si la validación es exitosa.
 * @throws {Error} Lanza una excepción si los parámetros no guardan coherencia con el tipo de beneficio seleccionado.
 */
CREATE FUNCTION fn_validar_coherencia_promocion(
    p_tipo_beneficio_id INTEGER,
    p_cantidad_requerida INTEGER,
    p_cantidad_beneficio INTEGER,
    p_valor_beneficio NUMERIC
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_tipo_beneficio_id = 1503 AND (p_cantidad_requerida <= 0 OR p_cantidad_beneficio <= 0) THEN
        RAISE EXCEPTION 'Promociones de tipo CANTIDAD requieren cantidades mayores a cero.';
    END IF;

    IF p_tipo_beneficio_id = 1501 AND (p_valor_beneficio <= 0 OR p_valor_beneficio > 100) THEN
        RAISE EXCEPTION 'Promociones de tipo PORCENTAJE requieren valor entre 1 y 100.';
    END IF;

    IF p_tipo_beneficio_id = 1502 AND p_valor_beneficio <= 0 THEN
        RAISE EXCEPTION 'Promociones de tipo MONTO_FIJO requieren valor mayor a cero.';
    END IF;

    IF p_tipo_beneficio_id = 1504 AND (p_cantidad_requerida <> 0 OR p_cantidad_beneficio <> 0 OR p_valor_beneficio <> 0) THEN
        RAISE EXCEPTION 'Promociones de tipo NINGUNO no deben tener cantidades ni valores.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * Valida la coherencia entre el tipo de métrica, la precisión y el factor de estacionalidad de un modelo.
 *
 * @param {integer} p_tipo_metricas_id - Identificador del tipo de métrica (ej. 3100=REGRESION, 3101=CLASIFICACION, 3102=CLUSTERING, 3103=NINGUNO).
 * @param {integer} p_metrica_precision_id - Identificador de la métrica de precisión (ej. 3600=MAE, 3601=RMSE, 3602=MAPE, 3603=R2, 3604=F1, 3605=NINGUNO).
 * @param {integer} p_factor_estacionalidad_id - Identificador del factor de estacionalidad (ej. 3650=NONE, 3651=DIARIO, etc.).
 * @returns {boolean} Retorna true si la validación es exitosa.
 * @throws {Error} Lanza una excepción si los parámetros no guardan coherencia según el tipo de problema evaluado.
 */
CREATE FUNCTION fn_validar_coherencia_metrica(
    p_tipo_metricas_id INTEGER,
    p_metrica_precision_id INTEGER,
    p_factor_estacionalidad_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_tipo_metricas_id = 3100 AND p_metrica_precision_id NOT IN (3600, 3601, 3602, 3603, 3605) THEN
        RAISE EXCEPTION 'El tipo de métrica REGRESION (3100) no es coherente con la precisión seleccionada (%)', p_metrica_precision_id;
    END IF;

    IF p_tipo_metricas_id = 3101 AND p_metrica_precision_id NOT IN (3604, 3605) THEN
        RAISE EXCEPTION 'El tipo de métrica CLASIFICACION (3101) no es coherente con la precisión seleccionada (%)', p_metrica_precision_id;
    END IF;

    IF p_tipo_metricas_id = 3102 AND p_metrica_precision_id <> 3605 THEN
        RAISE EXCEPTION 'El tipo de métrica CLUSTERING (3102) requiere precisión NINGUNO (3605).';
    END IF;

    IF p_tipo_metricas_id = 3103 AND p_metrica_precision_id <> 3605 THEN
        RAISE EXCEPTION 'El tipo de métrica NINGUNO (3103) requiere precisión NINGUNO (3605).';
    END IF;

    IF p_tipo_metricas_id = 3100 AND p_factor_estacionalidad_id IS NULL THEN
        RAISE EXCEPTION 'Los modelos de REGRESION (3100) requieren obligatoriamente un factor de estacionalidad definido.';
    END IF;

    IF p_tipo_metricas_id IN (3101, 3102, 3103) AND p_factor_estacionalidad_id IS NOT NULL THEN
        RAISE EXCEPTION 'Los modelos que no son de regresión (clasificación, clustering o ninguno) no deben tener un factor de estacionalidad asignado.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * Valida la coherencia de los registros procesados en función del estado de ejecución del entrenamiento.
 *
 * @param {integer} p_estado_ejecucion_id - Identificador del estado de ejecución (ej. 3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO, 3053=NINGUNO).
 * @param {bigint} p_registros_procesados - Cantidad de registros efectivamente procesados.
 * @returns {boolean} Retorna true si la validación es exitosa.
 * @throws {Error} Lanza una excepción si un entrenamiento completado no tiene registros válidos mayores a cero.
 */
CREATE FUNCTION fn_validar_registros_entrenamiento(
    p_estado_ejecucion_id INTEGER,
    p_registros_procesados BIGINT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Si el entrenamiento está completado (3051), exige obligatoriamente registros procesados mayores a 0
    IF p_estado_ejecucion_id = 3051 AND (p_registros_procesados IS NULL OR p_registros_procesados <= 0) THEN
        RAISE EXCEPTION 'Un entrenamiento completado (3051) debe registrar obligatoriamente una cantidad de registros procesados mayor a cero. Valor actual: %', p_registros_procesados;
    END IF;

    -- Validación opcional para asegurar que no existan negativos en otros estados si se proveen
    IF p_registros_procesados IS NOT NULL AND p_registros_procesados < 0 THEN
        RAISE EXCEPTION 'La cantidad de registros procesados no puede ser un valor negativo (%)', p_registros_procesados;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * Valida la consistencia de las métricas de rendimiento según el tipo de modelo evaluado
 * (Resolución de la Observación No. 04).
 *
 * @param {integer} p_tipo_metricas_id - Identificador del tipo de métrica (ej. 3100=REGRESION, 3101=CLASIFICACION, 3102=CLUSTERING, 3103=NINGUNO).
 * @param {integer} p_metrica_precision_id - Identificador de la métrica de precisión asociada.
 * @param {numeric} p_error_absoluto_medio - Valor del MAE.
 * @param {numeric} p_raiz_error_cuadratico_medio - Valor del RMSE.
 * @param {numeric} p_score_principal - Score principal del rendimiento.
 * @param {text} p_detalles_metricas - JSON o texto con detalles adicionales de métricas.
 * @returns {boolean} Retorna true si la validación es exitosa.
 * @throws {Error} Lanza una excepción si las métricas registradas no guardan coherencia con el tipo de modelo.
 */
CREATE FUNCTION fn_validar_metricas_rendimiento(
    p_tipo_metricas_id INTEGER,
    p_metrica_precision_id INTEGER,
    p_error_absoluto_medio NUMERIC,
    p_raiz_error_cuadratico_medio NUMERIC,
    p_score_principal NUMERIC,
    p_detalles_metricas TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validación para REGRESION (3100)
    IF p_tipo_metricas_id = 3100 AND (p_error_absoluto_medio IS NULL AND p_raiz_error_cuadratico_medio IS NULL AND p_score_principal IS NULL) THEN
        RAISE EXCEPTION 'Los modelos de tipo REGRESION (3100) deben registrar al menos una métrica válida (error_absoluto_medio, raiz_error_cuadratico_medio o score_principal).';
    END IF;

    -- Validación para CLASIFICACION (3101)
    IF p_tipo_metricas_id = 3101 AND (p_metrica_precision_id NOT IN (3604, 3605) AND p_score_principal IS NULL) THEN
        RAISE EXCEPTION 'Los modelos de tipo CLASIFICACION (3101) requieren una métrica de precisión válida o un score principal.';
    END IF;

    -- Validación para CLUSTERING (3102)
    IF p_tipo_metricas_id = 3102 AND (p_score_principal IS NULL AND p_detalles_metricas IS NULL) THEN
        RAISE EXCEPTION 'Los modelos de tipo CLUSTERING (3102) requieren un score principal o detalles de métricas.';
    END IF;

    -- Validación para NINGUNO (3103)
    IF p_tipo_metricas_id = 3103 AND p_detalles_metricas IS NULL THEN
        RAISE EXCEPTION 'Los modelos con tipo de métrica NINGUNO (3103) deben registrar detalles en la estructura de métricas.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * Valida que un estado de pronóstico con error posea obligatoriamente un motivo de outlier justificado
 * (Resolución de la Observación No. 16).
 *
 * @param {integer} p_estado_pronostico_id - Identificador del estado del pronóstico (ej. 1552=ERROR).
 * @param {integer} p_motivo_outlier_id - Identificador del motivo del outlier (ej. 1907=NINGUNO).
 * @returns {boolean} Retorna true si la validación es exitosa.
 * @throws {Error} Lanza una excepción si se registra un estado de error sin especificar un motivo válido de outlier.
 */
CREATE FUNCTION fn_validar_outlier_con_error(
    p_estado_pronostico_id INTEGER,
    p_motivo_outlier_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Si el estado del pronóstico es ERROR (1552), exige un motivo de outlier diferente de NINGUNO (1907)
    IF p_estado_pronostico_id = 1552 AND (p_motivo_outlier_id IS NULL OR p_motivo_outlier_id = 1907) THEN
        RAISE EXCEPTION 'Un pronóstico en estado de ERROR (1552) requiere obligatoriamente especificar un motivo de outlier válido distinto de NINGUNO (1907).';
    END IF;

    -- Validación opcional para asegurar integridad si el motivo no es nulo
    IF p_motivo_outlier_id IS NOT NULL AND p_motivo_outlier_id < 0 THEN
        RAISE EXCEPTION 'El identificador del motivo de outlier no puede ser un valor negativo (%)', p_motivo_outlier_id;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * Valida la consistencia de los datos de cierre de una caja según su estado actual.
 *
 * @param {integer} p_estado_caja_id - Identificador del estado de la caja (ej. 2650=ABIERTA, 2651=CERRADA).
 * @param {timestamptz} p_fecha_cierre - Fecha y hora en la que se cerró la caja.
 * @param {numeric} p_monto_final_real - Monto físico contado al momento del cierre.
 * @param {bigint} p_usuario_id_cierre - Identificador del usuario que realizó el cierre de caja.
 * @returns {boolean} Retorna true si la validación de consistencia es exitosa.
 * @throws {Error} Lanza una excepción si los campos de cierre no concuerdan con el estado de la caja.
 */
CREATE FUNCTION fn_validar_coherencia_cierre_caja(
    p_estado_caja_id INTEGER,
    p_fecha_cierre TIMESTAMPTZ,
    p_monto_final_real DECIMAL(12,2),
    p_usuario_id_cierre BIGINT
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_estado_caja_id = 2650 AND (p_fecha_cierre IS NOT NULL OR p_monto_final_real IS NOT NULL OR p_usuario_id_cierre IS NOT NULL) THEN
        RAISE EXCEPTION 'Una caja abierta (2650) no debe tener fecha de cierre, monto final real ni usuario de cierre.';
    END IF;

    IF p_estado_caja_id = 2651 AND (p_fecha_cierre IS NULL OR p_monto_final_real IS NULL OR p_usuario_id_cierre IS NULL) THEN
        RAISE EXCEPTION 'Una caja cerrada (2651) requiere obligatoriamente fecha de cierre, monto final real y usuario de cierre.';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * Valida la coherencia matemática del saldo posterior en un movimiento de caja.
 *
 * @param {integer} p_tipo_movimiento_id - Identificador del tipo de movimiento (ej. 2600=INGRESO, 2601=EGRESO).
 * @param {numeric} p_saldo_antes - Saldo de caja previo a la ejecución del movimiento.
 * @param {numeric} p_monto - Monto de la transacción a realizar.
 * @param {numeric} p_saldo_despues - Saldo resultante posterior al movimiento.
 * @returns {boolean} Retorna true si la operación matemática del saldo es correcta.
 * @throws {Error} Lanza una excepción si el saldo después no coincide con la adición o sustracción del monto.
 */
CREATE FUNCTION fn_validar_coherencia_saldo_movimiento(
    p_tipo_movimiento_id INTEGER,
    p_saldo_antes DECIMAL(12,2),
    p_monto DECIMAL(12,2),
    p_saldo_despues DECIMAL(12,2)
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_tipo_movimiento_id = 2600 AND p_saldo_despues <> (p_saldo_antes + p_monto) THEN
        RAISE EXCEPTION 'El saldo despues (%) no coincide con el ingreso esperado (%) para el movimiento tipo INGRESO (2600).', p_saldo_despues, (p_saldo_antes + p_monto);
    END IF;

    IF p_tipo_movimiento_id = 2601 AND p_saldo_despues <> (p_saldo_antes - p_monto) THEN
        RAISE EXCEPTION 'El saldo despues (%) no coincide con el egreso esperado (%) para el movimiento tipo EGRESO (2601).', p_saldo_despues, (p_saldo_antes - p_monto);
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================================

/**
 * Cierra automáticamente los planes de pago cuando todas las cuotas están pagadas.
 *
 * @function fn_cerrar_planes_pago
 * @returns {INTEGER} Cantidad de planes cerrados
 */
CREATE FUNCTION fn_cerrar_planes_pago()
RETURNS INTEGER AS $$
DECLARE
    v_plan RECORD;
    v_total_cuotas INTEGER;
    v_cuotas_pagadas INTEGER;
    v_contador INTEGER := 0;
BEGIN
    FOR v_plan IN
        SELECT DISTINCT pp.kardex_id
        FROM planes_pagos pp
        JOIN kardex k ON k.kardex_id = pp.kardex_id
        WHERE k.evento_id = 1050  -- COMPRA
          AND k.estado_financiero_id IN (2401, 2402)  -- PENDIENTE o PARCIAL
          AND pp.estado_id = 1000
    LOOP
        -- Contar cuotas totales y pagadas
        SELECT COUNT(*), COUNT(*) FILTER (WHERE estado_pago_id IN (2552, 2553))
        INTO v_total_cuotas, v_cuotas_pagadas
        FROM planes_pagos
        WHERE kardex_id = v_plan.kardex_id
          AND estado_id = 1000;

        -- Si todas las cuotas están pagadas, cerrar el plan
        IF v_cuotas_pagadas = v_total_cuotas THEN
            -- Actualizar estado financiero de la compra
            UPDATE kardex
            SET estado_financiero_id = 2400,  -- CANCELADO
                fecha_actualizacion = CURRENT_TIMESTAMP,
                usuario_id_actualizacion = 1
            WHERE kardex_id = v_plan.kardex_id;

            -- Marcar todas las cuotas como CERRADAS
            UPDATE planes_pagos
            SET estado_pago_id = 2553,  -- CERRADO
                fecha_actualizacion = CURRENT_TIMESTAMP,
                usuario_id_actualizacion = 1
            WHERE kardex_id = v_plan.kardex_id
              AND estado_id = 1000;

            v_contador := v_contador + 1;
        END IF;
    END LOOP;

    RETURN v_contador;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * Actualiza automáticamente el rating de calidad de un proveedor basado en incidencias.
 *
 * @param {BIGINT} p_proveedor_id - ID del proveedor
 * @returns {INTEGER} Nuevo rating asignado
 */
CREATE FUNCTION fn_actualizar_rating_proveedor(
    p_proveedor_id BIGINT
) RETURNS INTEGER AS $$
DECLARE
    v_total_compras INTEGER;
    v_devoluciones INTEGER;
    v_porcentaje_devoluciones DECIMAL(5,2);
    v_rating_actual INTEGER;
    v_nuevo_rating INTEGER;
BEGIN
    -- Contar compras y devoluciones de los últimos 12 meses
    SELECT
        COUNT(*) FILTER (WHERE evento_id = 1050),
        COUNT(*) FILTER (WHERE evento_id = 1061)
    INTO v_total_compras, v_devoluciones
    FROM kardex
    WHERE proveedor_id = p_proveedor_id
      AND estado_id = 1000
      AND fecha_kardex >= CURRENT_DATE - INTERVAL '12 months';

    -- Calcular porcentaje de devoluciones
    IF v_total_compras > 0 THEN
        v_porcentaje_devoluciones := (v_devoluciones::DECIMAL / v_total_compras) * 100;
    ELSE
        v_porcentaje_devoluciones := 0;
    END IF;

    -- Determinar nuevo rating
    IF v_porcentaje_devoluciones > 30 THEN
        v_nuevo_rating := 2050;  -- PESIMO
    ELSIF v_porcentaje_devoluciones > 20 THEN
        v_nuevo_rating := 2051;  -- DEFICIENTE
    ELSIF v_porcentaje_devoluciones > 10 THEN
        v_nuevo_rating := 2052;  -- REGULAR
    ELSIF v_porcentaje_devoluciones > 5 THEN
        v_nuevo_rating := 2053;  -- BUENO
    ELSE
        v_nuevo_rating := 2054;  -- EXCELENTE
    END IF;

    -- Actualizar proveedor
    UPDATE proveedores
    SET rating_calidad_id = v_nuevo_rating,
        ultima_evaluacion = CURRENT_DATE,
        fecha_actualizacion = CURRENT_TIMESTAMP,
        usuario_id_actualizacion = 1
    WHERE proveedor_id = p_proveedor_id;

    RETURN v_nuevo_rating;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_tiene_dependencias_dominio
 * @description Verifica y lista las dependencias (claves foráneas) de un dominio específico.
 * Analiza las tablas que referencian a `dominios` para contar registros totales y activos,
 * garantizando la integridad referencial antes de eliminar o modificar un dominio.
 * 
 * @param {BIGINT} p_dominio_id - ID del dominio a verificar en la tabla `dominios` (> 0).
 * 
 * @returns {TABLE} Retorna una tabla con las columnas:
 *   - `table_name` {TEXT}: Nombre de la tabla con la FK hacia `dominios`.
 *   - `column_name` {TEXT}: Nombre de la columna que referencia al dominio.
 *   - `total_registros` {BIGINT}: Conteo total de registros que usan el dominio (incluye históricos/borrados).
 *   - `registros_activos` {BIGINT}: Conteo exclusivo de registros activos (`estado_id = 1000`).
 * 
 * @example
 * -- Verificar dependencias de un dominio
 * SELECT * FROM fn_tiene_dependencias_dominio(4800);
 * 
 * @performance
 * - Complejidad O(n * m). Requiere índices en las columnas FK de las tablas dependientes.
 * - Tiempos estimados: < 10ms (sin dependencias) hasta 200ms (con dependencias).
 * 
 * @security
 * - Previene Inyección SQL usando `format()` con `%I` para identificadores.
 * - Utiliza los permisos del usuario que la invoca.
 * 
 * @warning
 * - No ejecutar en producción sin índices en las columnas de claves foráneas.
 * - Evitar llamadas masivas concurrentes para prevenir bloqueos en transacciones.
 * 
 * @see fn_listar_tablas_con_fk_dominios
 * @see fn_validar_reglas_negocio
 * @see fn_liberar_reservas_expiradas
 * @see fn_auditar_cambios_dominio
 * @see fn_migrar_dependencias_dominio
 */
CREATE OR REPLACE FUNCTION fn_tiene_dependencias_dominio(p_dominio_id BIGINT)
RETURNS TABLE(
    table_name TEXT,
    column_name TEXT,
    total_registros BIGINT,
    registros_activos BIGINT
) AS $$
DECLARE
    v_query TEXT;
    v_record RECORD;
BEGIN
    -- Buscar todas las tablas que tienen FK a dominios.dominio_id
    FOR v_record IN
        SELECT 
            con.conrelid::regclass::TEXT AS table_name,
            a.attname AS column_name
        FROM 
            pg_constraint AS con
            JOIN pg_attribute AS a ON a.attnum = ANY(con.conkey) AND a.attrelid = con.conrelid
        WHERE 
            con.contype = 'f'
            AND con.confrelid = 'dominios'::regclass
            AND con.conrelid != 'dominios'::regclass
        ORDER BY 
            table_name, column_name
    LOOP
        -- Construir y ejecutar la consulta de conteo para cada columna
        v_query := format(
            'SELECT 
                $1::TEXT AS table_name,
                $2::TEXT AS column_name,
                COUNT(*) AS total_registros,
                COUNT(*) FILTER (WHERE estado_id = 1000) AS registros_activos
            FROM %I
            WHERE %I = $3
            AND estado_id IN (1000, 1002)',
            v_record.table_name,
            v_record.column_name
        );
        
        RETURN QUERY EXECUTE v_query 
        USING v_record.table_name, v_record.column_name, p_dominio_id;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @function fn_listar_tablas_con_fk_dominios
 * @description Lista las tablas, columnas y restricciones (FOREIGN KEY) que apuntan a la tabla `dominios`.
 * 
 * @returns {TABLE} Retorna una tabla con las columnas:
 *   - `table_name` {TEXT}: Nombre de la tabla con la FK hacia `dominios`.
 *   - `column_name` {TEXT}: Nombre de la columna que referencia al dominio.
 *   - `constraint_name` {TEXT}: Nombre de la restricción FK.
 * 
 * @example
 * SELECT * FROM fn_listar_tablas_con_fk_dominios() ORDER BY table_name;
 * 
 * @performance
 * - Muy rápida (< 5ms), accede únicamente a los catálogos del sistema.
 * 
 * @see fn_tiene_dependencias_dominio
 */
CREATE OR REPLACE FUNCTION fn_listar_tablas_con_fk_dominios()
RETURNS TABLE(
    table_name TEXT,
    column_name TEXT,
    constraint_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        con.conrelid::regclass::TEXT AS table_name,
        a.attname AS column_name,
        con.conname AS constraint_name
    FROM 
        pg_constraint AS con
        JOIN pg_attribute AS a ON a.attnum = ANY(con.conkey) AND a.attrelid = con.conrelid
    WHERE 
        con.contype = 'f'
        AND con.confrelid = 'dominios'::regclass
        AND con.conrelid != 'dominios'::regclass
    ORDER BY 
        table_name, column_name;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @file fn_verificar_dependencias.sql
 * @path c:\sirena\sirena-backend\database\functions\fn_verificar_dependencias.sql
 * @description Función PL/pgSQL que realiza la introspección del catálogo del sistema (pg_constraint)
 *              para verificar si existen registros hijos que dependan de un registro padre específico mediante
 *              claves foráneas (Foreign Keys). Evalúa dinámicamente los estados 'Activo' e 'Histórico'.
 *
 * @function fn_verificar_dependencias
 * 
 * @param {VARCHAR} p_table_name - Nombre de la tabla padre objetivo (ej: 'bancos', 'almacenes').
 * @param {INTEGER} p_id - Identificador único (ID) del registro padre a verificar.
 * @param {BOOLEAN} [p_solo_activos=FALSE] - Si es TRUE, cuenta únicamente dependencias en estado 'Activo' (1000).
 *                                           Si es FALSE, cuenta dependencias en estado 'Activo' (1000) e 'Histórico' (1001).
 *
 * @returns {TABLE}
 * @returns {BIGINT} total_dependencias - Cantidad total acumulada de registros dependientes encontrados.
 * @returns {TEXT} detalle_dependencias - Cadena formateada con el desglose de tablas, columnas y número de registros afectados.
 *
 * @example
 * -- Verificar dependencias totales (Activos e Históricos) para el Banco con ID 5
 * SELECT * FROM fn_verificar_dependencias('bancos', 5);
 *
 * @example
 * -- Verificar únicamente dependencias en estado Activo para el Almacén con ID 2
 * SELECT * FROM fn_verificar_dependencias('almacenes', 2, TRUE);
 */
CREATE OR REPLACE FUNCTION fn_verificar_dependencias(
    p_table_name VARCHAR,
    p_id INTEGER,
    p_solo_activos BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
    total_dependencias BIGINT,
    detalle_dependencias TEXT
) AS $$
DECLARE
    v_total BIGINT := 0;
    v_detalle TEXT := '';
    v_count BIGINT;
    v_row RECORD;
    v_estado_activo CONSTANT INTEGER := 1000;
    v_estado_historico CONSTANT INTEGER := 1001;
BEGIN
    FOR v_row IN 
        SELECT 
            cl_child.relname AS tabla_hija,
            att_child.attname AS columna_hija
        FROM pg_constraint c
        JOIN pg_class cl_child ON c.conrelid = cl_child.oid
        JOIN pg_class cl_parent ON c.confrelid = cl_parent.oid
        JOIN pg_attribute att_child ON att_child.attrelid = cl_child.oid 
            AND att_child.attnum = ANY(c.conkey)
        JOIN pg_namespace nsp ON cl_child.relnamespace = nsp.oid
        WHERE c.contype = 'f' 
          AND cl_parent.relname = p_table_name
          AND cl_child.relname != p_table_name
          AND nsp.nspname = 'public'
    LOOP
        IF p_solo_activos THEN
            EXECUTE format(
                'SELECT COUNT(1) FROM %I WHERE %I = $1 AND estado_id = $2',
                v_row.tabla_hija, v_row.columna_hija
            ) INTO v_count USING p_id, v_estado_activo;
        ELSE
            EXECUTE format(
                'SELECT COUNT(1) FROM %I WHERE %I = $1 AND estado_id IN ($2, $3)',
                v_row.tabla_hija, v_row.columna_hija
            ) INTO v_count USING p_id, v_estado_activo, v_estado_historico;
        END IF;
        
        IF v_count > 0 THEN
            v_total := v_total + v_count;
            v_detalle := v_detalle || 
                format('- Tabla "%s".%s: %s registro(s)\n', 
                    v_row.tabla_hija, 
                    v_row.columna_hija, 
                    v_count
                );
        END IF;
    END LOOP;

    RETURN QUERY SELECT v_total, v_detalle;
END;
$$ LANGUAGE plpgsql STABLE;

-- ================================================================================================
ARCHIVO CONSOLIDADO TYPESCRIPT (.TS) 
============================================ 
Generado: jue 06/08/2026 16:43:53,10 
Directorio analizado: C:\sirena\sirena-backend\src\common 
============================================ 
 
 
---- C:\sirena\sirena-backend\src\common\common.module.ts ---- 
 
// C:\sirena\sirena-backend\src\common\common.module.ts
import { Module, Global } from '@nestjs/common';
import { ValidatorsModule } from './validators/validators.module';
import { ServicesModule } from './services/services.module';

@Global()
@Module({
    imports: [
        ValidatorsModule,
        ServicesModule,
    ],
    exports: [
        ValidatorsModule,
        ServicesModule,
    ],
})
export class CommonModule {}
 
 
---- C:\sirena\sirena-backend\src\common\base\base-audit.entity.ts ---- 
 
// C:\sirena\sirena-backend\src\common\base\base-audit.entity.ts
import { Column, CreateDateColumn, BeforeUpdate } from 'typeorm';

/**
 * @class BaseAuditEntity
 * @description Clase abstracta base para la auditoría y trazabilidad de entidades.
 * Proporciona campos estándar de control de estado, usuarios responsables y marcas de tiempo
 * para la creación, actualización y baja lógica de los registros.
 */
export abstract class BaseAuditEntity {
    /**
     * Estado actual del registro.
     * @default 1000 (1000 = ACTIVO, 1001 = BORRADO, 1002 = HISTORICO). 1003=ANULACION es un caso especial.
     */
    @Column({
        name: 'estado_id',
        type: 'integer',
        nullable: false,
        default: 1000
    })
    estado_id: number;

    /**
     * ID del usuario que creó el registro.
     * @default 1
     */
    @Column({
        name: 'usuario_id_registro',
        type: 'bigint',
        nullable: false,
        default: 1,
        transformer: {
            to: (value: number): number => value,
            from: (value: string | null): number | null =>
                (value !== null && value !== undefined) ? parseInt(value, 10) : null
        }
    })
    usuario_id_registro: number;

    /**
     * ID del último usuario que modificó el registro (opcional).
     */
    @Column({
        name: 'usuario_id_actualizacion',
        type: 'bigint',
        nullable: true,
        transformer: {
            to: (value: number | null): number | null => value,
            from: (value: string | null): number | null =>
                (value !== null && value !== undefined) ? parseInt(value, 10) : null
        }
    })
    usuario_id_actualizacion?: number | null;

    /**
     * ID del usuario que realizó la baja lógica del registro (opcional).
     */
    @Column({
        name: 'usuario_id_baja',
        type: 'bigint',
        nullable: true,
        transformer: {
            to: (value: number | null): number | null => value,
            from: (value: string | null): number | null =>
                (value !== null && value !== undefined) ? parseInt(value, 10) : null
        }
    })
    usuario_id_baja?: number | null;

    /**
     * Fecha y hora exacta en la que se creó el registro.
     * Generado automáticamente por la base de datos (CURRENT_TIMESTAMP).
     */
    @CreateDateColumn({
        name: 'fecha_registro',
        type: 'timestamptz',
        default: () => 'CURRENT_TIMESTAMP'
    })
    fecha_registro: Date;

    /**
     * Fecha y hora de la última actualización realizada en el registro (opcional).
     */
    @Column({
        name: 'fecha_actualizacion',
        type: 'timestamptz',
        nullable: true
    })
    fecha_actualizacion?: Date | null;

    /**
     * Fecha y hora en la que se ejecutó la baja lógica del registro (opcional).
     */
    @Column({
        name: 'fecha_baja',
        type: 'timestamptz',
        nullable: true
    })
    fecha_baja?: Date | null;

    /**
     * Método del ciclo de vida de TypeORM que se ejecuta antes de actualizar un registro.
     * Gestiona de forma automatizada y excluyente las marcas de tiempo para actualizaciones o bajas lógicas.
     */
    @BeforeUpdate()
    updateTimestamps() {
        if (this.usuario_id_baja && !this.fecha_baja) {
            this.fecha_baja = new Date();
        } else if (!this.usuario_id_baja) {
            this.fecha_actualizacion = new Date();
        }
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\constants\estados.constant.ts ---- 
 
// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts
export const ESTADOS = {
    ACTIVO: 1000,
    BORRADO: 1001,
    HISTORICO: 1002,
    ANULADO: 1003,
} as const;

export type EstadoType = typeof ESTADOS[keyof typeof ESTADOS];

export const ESTADOS_CONSULTA = [
    ESTADOS.ACTIVO,
    ESTADOS.HISTORICO,
    ESTADOS.BORRADO,
    ESTADOS.ANULADO,
] as const;

export const ESTADOS_VIVOS = [
    ESTADOS.ACTIVO,
    ESTADOS.HISTORICO
] as const;
 
 
---- C:\sirena\sirena-backend\src\common\decorators\get-user.decorator.ts ---- 
 
// C:\sirena\sirena-backend\src\common\decorators\get-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const GetUser = createParamDecorator(
    (_data, ctx: ExecutionContext) => {
        const request = ctx.switchToHttp().getRequest();
        const user = request.user;

        return {
            id: user.usuario_id ?? user.sub ?? null,
            ...user,
        };
    },
);
 
 
---- C:\sirena\sirena-backend\src\common\dto\base-pagination-query.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\common\dto\base-pagination-query.dto.ts
import { IsOptional, IsInt, IsString, Min, IsIn, Max } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO base para consultas paginadas en todo el sistema.
 *
 * Proporciona propiedades y métodos utilitarios para:
 * - Paginación (offset, limit)
 * - Ordenamiento (sortField, sortOrder)
 * - Valores por defecto consistentes
 * - Validaciones comunes
 *
 * @example
 * // Extender en un DTO específico
 * export class FindBancosQueryDto extends BasePaginationQueryDto {
 *   @IsOptional()
 *   @IsString()
 *   q?: string;
 * }
 */
export abstract class BasePaginationQueryDto {
    // ============ PROPIEDADES ============

    /**
     * Número de registros a saltar (paginación)
     * @default 0
     * @minimum 0
     */
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'offset debe ser un número entero.' })
    @Min(0, { message: 'offset debe ser >= 0' })
    offset?: number;

    /**
     * Cantidad de registros a devolver (paginación)
     * @default 10
     * @minimum 1
     * @maximum 100
     */
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'limit debe ser un número entero.' })
    @Min(1, { message: 'limit debe ser >= 1' })
    @Max(100, { message: 'limit no puede exceder 100 registros.' })
    limit?: number;

    /**
     * Campo por el cual ordenar los resultados
     * @default Depende de la implementación (usar getDefaultSortField())
     */
    @IsOptional()
    @IsString({ message: 'El campo sortField debe ser una cadena de texto.' })
    sortField?: string;

    /**
     * Dirección del ordenamiento
     * - 1: Ascendente (A-Z, 0-9)
     * - -1: Descendente (Z-A, 9-0)
     * @default -1 (descendente)
     */
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo sortOrder debe ser un número entero.' })
    @IsIn([1, -1] as const, { message: 'El campo sortOrder debe ser 1 (ascendente) o -1 (descendente).' })
    sortOrder?: 1 | -1;

    // ============ MÉTODOS GETTERS CON VALORES POR DEFECTO ============

    // Obtiene el offset con valor por defecto
    getOffset(): number {
        return this.offset ?? 0;
    }

    // Obtiene el limit con valor por defecto
    getLimit(): number {
        return this.limit ?? 10;
    }

    // Obtiene el sortField con valor por defecto. Usa el campo default definido por la implementación
    getSortField(): string {
        return this.sortField ?? this.getDefaultSortField();
    }

    // Obtiene el sortOrder con valor por defecto
    getSortOrder(): 1 | -1 {
        return this.sortOrder ?? -1;
    }

    // Obtiene la dirección del ordenamiento en formato SQL
    getOrderDirection(): 'ASC' | 'DESC' {
        return this.getSortOrder() === 1 ? 'ASC' : 'DESC';
    }

    // ============ MÉTODOS ABSTRACTOS (DEBEN SER IMPLEMENTADOS) ============

    /**
     * Define el campo de ordenamiento por defecto para esta entidad
     * SOLO EL NOMBRE DEL CAMPO, sin alias. Debe ser implementado por la clase hija.
     */
    abstract getDefaultSortField(): string;

    /**
     * Define los campos permitidos para ordenamiento
     * SOLO LOS NOMBRES DE LOS CAMPOS, sin alias. Debe ser implementado por la clase hija
     */
    abstract getAllowedSortFields(): string[];

    // ============ MÉTODOS DE UTILIDAD ============

    /**
     * Obtiene el campo de ordenamiento validado
     * Devuelve solo el nombre del campo, sin alias
     */
    getValidatedSortField(): string {
        const allowed = this.getAllowedSortFields();
        const field = this.getSortField();

        // Si el campo existe en los permitidos, devolverlo
        if (field && allowed.includes(field)) {
            return field;
        }

        // Si no existe, devolver el campo por defecto
        return this.getDefaultSortField();
    }

    /**
     * Construye la cláusula ORDER BY completa con el alias proporcionado
     * @param alias El alias de la tabla (ej: 'b', 'e', 'a')
     */
    getOrderByClause(alias: string): string {
        const field = this.getValidatedSortField();
        const direction = this.getOrderDirection();
        return `ORDER BY ${alias}.${field} ${direction}`;
    }

    // Construye la cláusula LIMIT y OFFSET completa
    getPaginationClause(): string {
        const limit = this.getLimit();
        const offset = this.getOffset();
        return `LIMIT ${limit} OFFSET ${offset}`;
    }

    /**
     * Obtiene todos los parámetros de paginación con el alias proporcionado
     * @param alias El alias de la tabla (ej: 'b', 'e', 'a')
     */
    getPaginationParams(alias: string): {
        limit: number;
        offset: number;
        sortField: string;
        sortOrder: 1 | -1;
        orderDirection: 'ASC' | 'DESC';
        orderByClause: string;
        paginationClause: string;
        validatedField: string;
    } {
        const validatedField = this.getValidatedSortField();
        return {
            limit: this.getLimit(),
            offset: this.getOffset(),
            sortField: this.getSortField(),
            sortOrder: this.getSortOrder(),
            orderDirection: this.getOrderDirection(),
            orderByClause: `ORDER BY ${alias}.${validatedField} ${this.getOrderDirection()}`,
            paginationClause: this.getPaginationClause(),
            validatedField
        };
    }

    // Verifica si hay paginación activa
    hasPagination(): boolean {
        return this.offset !== undefined || this.limit !== undefined;
    }

    // Verifica si hay ordenamiento activo
    hasSorting(): boolean {
        return this.sortField !== undefined || this.sortOrder !== undefined;
    }
} 
 
---- C:\sirena\sirena-backend\src\common\interfaces\pagination.interface.ts ---- 
 
// C:\sirena\sirena-backend\src\common\interfaces\pagination.interface.ts
export interface PaginatedResult<T> {
    data: T[];
    total: number;
    limit: number;
    offset: number;
}
 
 
---- C:\sirena\sirena-backend\src\common\services\estado-manager.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\services\estado-manager.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';
import { DominiosValidatorService } from '../validators/dominios-validator.service';
import { ValidatorFactoryService } from '../validators/validator-factory.service';

// Interfaz base de auditoría que deben cumplir las entidades administradas por el sistema.
export interface BaseAuditEntity {
    estado_id: number;
    usuario_id_actualizacion?: number | null;
    usuario_id_baja?: number | null;
    fecha_baja?: Date | string | null | (() => string);
    [key: string]: any;
}

export interface CambiarEstadoOptions {
    entityKey: string;             // ej: 'banco', 'empresa', 'almacen'
    id: number;
    nuevoEstadoId: number;
    usuarioId: number;
    validarDependencias?: boolean; // Para soft delete (remove)
}

@Injectable()
export class EstadoManagerService {
    constructor(
        private readonly catalogoConfig: CatalogoDominioConfigService,
        private readonly dominiosValidator: DominiosValidatorService,
        private readonly validatorFactory: ValidatorFactoryService,
    ) {}

    private get BORRADO_ID(): number {
        return Number(this.catalogoConfig.CATALOGO.ESTADO.BORRADO);
    }

    // Centraliza el cambio de estado de cualquier entidad del sistema
    async cambiarEstado<T extends BaseAuditEntity>(repository: Repository<T>, options: CambiarEstadoOptions): Promise<T> {
        const { entityKey, id, nuevoEstadoId, usuarioId, validarDependencias = false } = options;

        // 1. Obtener el proxy de validación configurado en ValidatorFactory
        const entityValidator = this.validatorFactory.get(entityKey);

        // 2. Validaciones genéricas requeridas
        await this.validatorFactory.usuario.validarActivo(usuarioId);
        await this.dominiosValidator.validarFkDominio(nuevoEstadoId, 'EstadoID', 'estado_id');

        // 3. Si es un borrado suave, verificar dependencias activas/existentes
        if (validarDependencias) {
            await entityValidator.validarSinDependencias(id);
        }

        // 4. Buscar entidad usando el nombre de la PK configurado en el Factory o fallback dinámico
        const pkField = `${entityKey}_id`;
        const entidad = await repository.findOne({ where: { [pkField]: id } as any });

        if (!entidad) {
            throw new NotFoundException(`Registro #${id} en ${entityKey} no encontrado.`);
        }

        // 5. Aplicar cambios según el tipo de estado destino
        if (nuevoEstadoId === this.BORRADO_ID) {
            await repository.update(
                { [pkField]: id } as any,
                {
                    estado_id: nuevoEstadoId,
                    usuario_id_baja: usuarioId,
                    fecha_baja: new Date(),
                } as any,
            );
        } else {
            entidad.estado_id = nuevoEstadoId;
            entidad.usuario_id_actualizacion = usuarioId;
            entidad.usuario_id_baja = null;
            entidad.fecha_baja = null;
            await repository.save(entidad);
        }

        return entidad;
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\services\services.module.ts ---- 
 
// C:\sirena\sirena-backend\src\common\services\services.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DominiosModule } from '../../modules/dominios/dominios.module';
import { ValidatorsModule } from '../validators/validators.module';
import { EstadoManagerService } from './estado-manager.service';

@Module({
    imports: [
        ConfigModule,
        DominiosModule,
        ValidatorsModule,
    ],
    providers: [
        EstadoManagerService,
    ],
    exports: [
        EstadoManagerService,
    ],
})
export class ServicesModule {}
 
 
---- C:\sirena\sirena-backend\src\common\utils\auth.util.ts ---- 
 
// C:\sirena\sirena-backend\src\common\utils\auth.util.ts
import { BadRequestException } from '@nestjs/common';

/**
 * Valida que el objeto usuario extraído del token JWT sea válido.
 * @param user Objeto usuario del request
 * @throws BadRequestException si el usuario no tiene ID
 */
export function validateUser(user: any): void {
    if (!user?.usuario_id) {
        throw new BadRequestException('Usuario no identificado en el token.');
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\utils\date-formatter.util.ts ---- 
 
// C:\sirena\sirena-backend\src\common\utils\date-formatter.util.ts

// Formatea marcas de tiempo con zona horaria (TIMESTAMPTZ) para la API
export const formatLocalDate = (value: any): string | null => {
    if (!value) return null;

    const date = new Date(value);
    if (isNaN(date.getTime())) return null;

    const formatter = new Intl.DateTimeFormat('sv-SE', {
        timeZone: 'America/La_Paz',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
    });

    const parts = formatter.formatToParts(date);
    const get = (type: string) => parts.find(p => p.type === type)?.value ?? '';
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');
    return `${get('year')}-${get('month')}-${get('day')} ${get('hour')}:${get('minute')}:${get('second')}.${milliseconds} -0400`;
};

// Formatea campos exclusivamente de FECHA (DATE: YYYY-MM-DD) evitando desfases por zona horaria
export const formatOnlyDate = (value: any): string | null => {
    if (!value) return null;
    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
        return value;
    }
    const date = new Date(value);
    if (isNaN(date.getTime())) return null;

    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};
 
 
---- C:\sirena\sirena-backend\src\common\utils\menu-parser.util.ts ---- 
 
// C:\sirena\sirena-backend\src\common\utils\menu-parser.util.ts
export function estructurarMenu(rows: any[]) {
    const map: any = {};
    const menuTree: any[] = [];

    rows.forEach(row => {
        map[row.menu_id] = {
            label: row.titulo,
            icon: row.icono,
            to: row.url || null,
            items: [],
            permissions: {
                crear: row.crear === 1,
                editar: row.editar === 1,
                eliminar: row.eliminar === 1
            }
        };
    });

    rows.forEach(row => {
        if (row.menu_padre_id !== null) {
            if (map[row.menu_padre_id]) {
                map[row.menu_padre_id].items.push(map[row.menu_id]);
            }
        } else {
                menuTree.push(map[row.menu_id]);
        }
    });
    return menuTree;
}
 
 
---- C:\sirena\sirena-backend\src\common\utils\string.util.ts ---- 
 
// C:\sirena\sirena-backend\src\common\utils\string.util.ts
import { BadRequestException } from '@nestjs/common';

// Genera una expresión SQL para normalizar una columna en PostgreSQL. Elimina espacios en blanco y convierte el texto a minúsculas de forma nativa.
export const SQL_NORMALIZE = (column: string) => {
    return `LOWER(TRIM(${column}))`;
};

/**
 * Normaliza texto: elimina diacríticos (NFD), convierte 'ñ'->'n', 'ç'->'c' y pasa a minúsculas.
 * @param text Cadena original @returns Cadena limpia o vacía
 */
export function normalizeText(text: string): string {
    if (!text) return '';
    return text
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[ñÑ]/g, 'n')
        .replace(/[çÇ]/g, 'c')
        .toLowerCase();
}

/**
 * Valida que una cadena no contenga caracteres de control invisibles o código de inyección XSS (<script>).
 * Permite acentos, diéresis, símbolos comerciales (&, $, -) y comillas estándar.
 */
export function validateSafeText(text: string, fieldName: string = 'Texto'): void {
    if (!text) return;

    // 1. Bloquea caracteres de control invisibles/trampa (excepto saltos de línea y tabulaciones normales)
    const trapCharsRegExp = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\u202E]/;

    // 2. Evita intentos de inyección HTML / Script tag (<...>)
    const htmlTagRegExp = /<[^>]*>/;

    if (trapCharsRegExp.test(text)) {
        throw new BadRequestException(`${fieldName} contiene caracteres de control o formato no válidos.`);
    }

    if (htmlTagRegExp.test(text)) {
        throw new BadRequestException(`${fieldName} contiene etiquetas de código o formato no permitidas.`);
    }
}

// Formatea una consulta SQL reemplazando los '$' por sus valores reales. SOLO PARA FINES DE LOGS/DEBUG.
function formatQuery(query: string, params: any[]): string {
    if (!params || params.length === 0) return query;
    let formattedQuery = query;
    params.forEach((val, i) => {
        const placeholder = new RegExp(`\\$${i + 1}(?=\\D|$)`, 'g');
        const replacement = val === null ? 'NULL'
                          : val === undefined ? 'DEFAULT'
                          : typeof val === 'string' ? `'${val}'`
                          : val;
        formattedQuery = formattedQuery.replace(placeholder, replacement);
    });
    return formattedQuery;
}

// Imprime en consola el query formateado con colores para mejor visibilidad. En producción solo se imprime si ocurre un error (error != null) o si LOG_SQL='true'.
export function logSQL(fileName: string, methodName: string, query: string, params: any[], error?: any): void {
    const isDev = process.env['NODE_ENV'] !== 'production';
    const isLogSqlEnabled = process.env['LOG_SQL'] === 'true';
    const hasError = error !== undefined && error !== null;

    // Solo imprime si hubo un error, si estamos en desarrollo o si LOG_SQL está activo en .env
    if (hasError || isDev || isLogSqlEnabled) {
        const fullQuery = formatQuery(query, params);

        if (hasError) {
            console.log('\n\x1b[31m%s\x1b[0m', `--- ERROR SQL ${fileName} -> ${methodName} ---`);
            console.log('\x1b[33m%s\x1b[0m', 'QUERY QUE FALLÓ:');
            console.log(fullQuery);
            console.log('\x1b[31m%s\x1b[0m', 'DETALLE DEL ERROR:');
            console.log(error);
            console.log('\x1b[31m%s\x1b[0m', `--- FIN ERROR SQL ${fileName} -> ${methodName} ---\n`);
        } else {
            console.log('\n\x1b[35m%s\x1b[0m', `--- SQL ${fileName} -> ${methodName} ---`);
            console.log('\x1b[36m%s\x1b[0m', 'QUERY COMPLETA:');
            console.log(fullQuery);
            console.log('\x1b[35m%s\x1b[0m', `--- FIN SQL ${fileName} -> ${methodName} ---\n`);
        }
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\validators\dominios-validator.service.ts ---- 
 
// src/common/validators/dominios-validator.service.ts
import { Injectable, BadRequestException, ConflictException, RequestTimeoutException } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';
import { DependenciaRaw, MetricData } from '../../modules/dominios/interfaces/dominios.interface';
import { logSQL } from '../utils/string.util';

interface CacheEntry {
    data: DependenciaRaw[];
    timestamp: number;
}

@Injectable()
export class DominiosValidatorService {
    // ✅ CONFIGURACIÓN CON VARIABLES DE ENTORNO (CORREGIDO)
    private readonly CACHE_TTL = parseInt(
        process.env['DOMINIO_CACHE_TTL'] ?? '300000', 10
    );

    private readonly QUERY_TIMEOUT_MS = parseInt(
        process.env['DOMINIO_DEPENDENCIAS_TIMEOUT'] ?? '5000', 10
    );

    private readonly cache = new Map<number, CacheEntry>();

    private readonly metrics = {
        cacheHits: 0,
        cacheMisses: 0,
        avgQueryTime: 0,
        totalQueries: 0
    };

    constructor(
        @InjectDataSource() private readonly dataSource: DataSource,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID(): number {
        return this.catalogoConfig.CATALOGO.ESTADO.ACTIVO;
    }

    /**
     * VALIDACIÓN MÚLTIPLE DE FKs (OPTIMIZADA)
     */
    async validarMultiplesFK(items: { id: number; dominio: string; campo: string }[]): Promise<void> {
        if (!items || items.length === 0) return;

        const ids = [...new Set(items.map(i => i.id))];
        const dominios = [...new Set(items.map(i => i.dominio))];

        const query = `
            SELECT d.dominio_id, d.dominio
            FROM dominios d
            WHERE d.dominio_id = ANY($1)
              AND d.dominio = ANY($2)
              AND d.estado_id = $3
              AND d.fecha_baja IS NULL
        `;

        logSQL('dominios-validator.service.ts', 'validarMultiplesFK', query, [ids, dominios, this.ACTIVO_ID]);

        const validos = (await this.dataSource.query(query, [
            ids,
            dominios,
            this.ACTIVO_ID
        ])) as { dominio_id: number; dominio: string }[];

        const validSet = new Set(validos.map(v => `${v.dominio_id}_${v.dominio}`));
        const invalidos = items.filter(item => !validSet.has(`${item.id}_${item.dominio}`));

        if (invalidos.length > 0) {
            const msgs = invalidos.map(i => `${i.campo} (ID: ${i.id}, Dominio: ${i.dominio})`).join(', ');
            throw new BadRequestException(`Las siguientes referencias son inválidas o están inactivas: ${msgs}`);
        }
    }

    /**
     * VALIDACIÓN FK ÚNICA
     */
    async validarFkDominio(dominioId: number | null | undefined, dominioEsperado: string, campo: string): Promise<void> {
        if (dominioId === null || dominioId === undefined) return;

        const query = `
            SELECT d.dominio_id
            FROM dominios d
            WHERE d.dominio_id = $1
              AND d.dominio = $2
              AND d.estado_id = $3
              AND d.fecha_baja IS NULL
        `;

        logSQL('dominios-validator.service.ts', 'validarFkDominio', query, [dominioId, dominioEsperado, this.ACTIVO_ID]);

        const result = (await this.dataSource.query(query, [
            dominioId,
            dominioEsperado,
            this.ACTIVO_ID
        ])) as { dominio_id: number }[];

        if (!result || result.length === 0) {
            const permitidos = (await this.dataSource.query(
                `
                SELECT dominio_id, abreviatura
                FROM dominios
                WHERE dominio = $1
                  AND estado_id = $2
                  AND fecha_baja IS NULL
                ORDER BY abreviatura ASC
                `,
                [dominioEsperado, this.ACTIVO_ID]
            )) as { dominio_id: number; abreviatura: string }[];

            const permitidosStr = permitidos
                .map(d => `${d.dominio_id} (${d.abreviatura})`)
                .join(', ') || 'Ninguno';

            throw new BadRequestException(`El ${campo} (${dominioId}) no existe, no está activo o no pertenece a ${dominioEsperado}. ` + `Los valores permitidos son: ${permitidosStr}.`);
        }
    }

    /**
     * VERIFICAR DEPENDENCIAS (CON TIMEOUT Y CACHÉ)
     */
    async verificarDependencias(dominioId: number, verificarActivos: boolean = false): Promise<DependenciaRaw[]> {
        // ✅ CACHÉ
        const cached = this.cache.get(dominioId);
        if (cached && (Date.now() - cached.timestamp) < this.CACHE_TTL) {
            this.metrics.cacheHits++;
            return cached.data;
        }

        this.metrics.cacheMisses++;
        const startTime = Date.now();
        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();

        try {
            await queryRunner.query(`SET LOCAL statement_timeout = '${this.QUERY_TIMEOUT_MS}ms';`);

            const query = `
                SELECT
                    table_name,
                    column_name,
                    total_registros,
                    registros_activos
                FROM fn_tiene_dependencias_dominio($1)
            `;

            logSQL('dominios-validator.service.ts', 'verificarDependencias', query, [dominioId]);

            const dependencias = (await queryRunner.query(query, [
                dominioId
            ])) as DependenciaRaw[];

            // ✅ FILTRAR según verificarActivos
            const filtradas = (dependencias || []).filter(d =>
                verificarActivos ? Number(d.registros_activos) > 0 : Number(d.total_registros) > 0
            );

            // ✅ MÉTRICAS
            const elapsed = Date.now() - startTime;
            this.metrics.totalQueries++;
            this.metrics.avgQueryTime = ((this.metrics.avgQueryTime * (this.metrics.totalQueries - 1)) + elapsed) / this.metrics.totalQueries;

            // ✅ GUARDAR EN CACHÉ
            this.cache.set(dominioId, { data: filtradas, timestamp: Date.now() });

            return filtradas;
        } catch (error: any) {
            if (error?.code === '57014') {
                throw new RequestTimeoutException(`La verificación de dependencias excedió el tiempo límite de ${this.QUERY_TIMEOUT_MS / 1000} segundos.`);
            }
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    /**
     * VALIDAR ELIMINACIÓN (Verifica protección y dependencias)
     */
    async validarEliminacionDominio(dominioId: number, verificarActivos: boolean = false): Promise<void> {
        // ✅ PROTECCIÓN: AHORA SOLO AQUÍ
        await this.validarExistenciaYProteccion(dominioId);
        const dependencias = await this.verificarDependencias(dominioId, verificarActivos);

        if (dependencias.length > 0) {
            const detalles = dependencias.map(
                (d: DependenciaRaw) =>
                    `- Tabla "${d.table_name}".${d.column_name}: ${d.total_registros} registros (${d.registros_activos} activos)`
            ).join('\n');

            throw new ConflictException(
                `No se puede eliminar el dominio porque está siendo utilizado en otras tablas:\n${detalles}`
            );
        }
    }

    /**
     * VALIDAR EXISTENCIA Y PROTECCIÓN
     */
    async validarExistenciaYProteccion(dominioId: number): Promise<void> {
        const query = `
            SELECT dominio_id, dominio, abreviatura, es_protegido
            FROM dominios
            WHERE dominio_id = $1
              AND fecha_baja IS NULL
        `;

        const result = (await this.dataSource.query(query, [dominioId])) as {
            dominio_id: number;
            dominio: string;
            abreviatura: string;
            es_protegido: number;
        }[];

        if (!result || result.length === 0) {
            throw new BadRequestException(`El dominio con ID ${dominioId} no existe o está eliminado.`);
        }

        // ✅ CORREGIDO: Validación explícita
        const primerRegistro = result[0];
        if (!primerRegistro) {
            throw new BadRequestException(`El dominio con ID ${dominioId} no existe.`);
        }

        if (Number(primerRegistro.es_protegido) === 1) {
            throw new BadRequestException(`El dominio "${primerRegistro.dominio}" (${primerRegistro.abreviatura}) está protegido y no puede ser modificado ni eliminado.`);
        }
    }

    /**
     * VALIDAR SI ES PROTEGIDO
     */
    async validarEsProtegido(dominioId: number): Promise<boolean> {
        const query = `
            SELECT es_protegido
            FROM dominios
            WHERE dominio_id = $1
              AND fecha_baja IS NULL
        `;

        logSQL('dominios-validator.service.ts', 'validarEsProtegido', query, [dominioId]);

        const result = (await this.dataSource.query(query, [dominioId])) as { es_protegido: number }[];

        if (!result || result.length === 0) {
            return false;
        }

        const primerRegistro = result[0];
        if (!primerRegistro) {
            return false;
        }

        return Number(primerRegistro.es_protegido) === 1;
    }

    /**
     * VALIDAR EXISTENCIA (RÁPIDA)
     */
    async validarExistencia(dominioId: number): Promise<boolean> {
        const query = `
            SELECT 1
            FROM dominios
            WHERE dominio_id = $1
              AND fecha_baja IS NULL
        `;

        const result = await this.dataSource.query(query, [dominioId]);
        return result && result.length > 0;
    }

    /**
     * OBTENER NOMBRE DEL DOMINIO
     */
    async obtenerNombreDominio(dominioId: number): Promise<string> {
        const query = `
            SELECT CONCAT(dominio, ' (', abreviatura, ')') as nombre
            FROM dominios
            WHERE dominio_id = $1
              AND fecha_baja IS NULL
        `;

        const result = (await this.dataSource.query(query, [dominioId])) as { nombre: string }[];

        // ✅ CORREGIDO: Validación explícita
        if (!result || result.length === 0) {
            return `ID ${dominioId}`;
        }

        const primerRegistro = result[0];
        if (!primerRegistro) {
            return `ID ${dominioId}`;
        }

        return primerRegistro.nombre;
    }

    /**
     * OBTENER INFORMACIÓN DE DEPENDENCIAS
     */
    async obtenerInformacionDependencias(
        dominioId: number,
        verificarActivos: boolean = false
    ) {
        const query = `
            SELECT dominio_id, dominio, abreviatura, es_protegido
            FROM dominios
            WHERE dominio_id = $1
              AND fecha_baja IS NULL
        `;

        const dominioResult = (await this.dataSource.query(query, [dominioId])) as {
            dominio_id: number;
            dominio: string;
            abreviatura: string;
            es_protegido: number;
        }[];

        if (!dominioResult || dominioResult.length === 0) {
            throw new BadRequestException(`El dominio con ID ${dominioId} no existe`);
        }

        // ✅ CORREGIDO: Validación explícita
        const dominio = dominioResult[0];
        if (!dominio) {
            throw new BadRequestException(`El dominio con ID ${dominioId} no existe.`);
        }

        const dependencias = await this.verificarDependencias(dominioId, verificarActivos);
        const tieneDependencias = dependencias.length > 0;

        let mensaje = '';
        if (tieneDependencias) {
            const totalRegistros = dependencias.reduce(
                (sum: number, d: DependenciaRaw) => sum + Number(d.total_registros),
                0
            );
            mensaje = `El dominio "${dominio.dominio}" (${dominio.abreviatura}) tiene ` +
                      `${dependencias.length} dependencia(s) en ${totalRegistros} registro(s).`;
        } else {
            mensaje = `El dominio "${dominio.dominio}" (${dominio.abreviatura}) no tiene dependencias y puede ser eliminado.`;
        }

        return {
            dominio,
            dependencias,
            tieneDependencias,
            mensaje
        };
    }

    /**
     * LIMPIAR CACHÉ
     */
    limpiarCache(dominioId?: number): void {
        if (dominioId) {
            this.cache.delete(dominioId);
        } else {
            this.cache.clear();
        }
    }

    /**
     * OBTENER TAMAÑO DE CACHÉ
     */
    getCacheSize(): number {
        return this.cache.size;
    }

    /**
     * OBTENER MÉTRICAS
     */
    getMetrics(): MetricData {
        const totalReq = this.metrics.cacheHits + this.metrics.cacheMisses;
        return {
            ...this.metrics,
            cacheHitRate: totalReq > 0 ? (this.metrics.cacheHits / totalReq) * 100 : 0
        };
    }
} 
 
---- C:\sirena\sirena-backend\src\common\validators\empresas-validator.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\empresas-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Empresa } from '../../modules/empresas/entities/empresa.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class EmpresasValidatorService {
    constructor(
        @InjectRepository(Empresa)
        private readonly empresaRepository: Repository<Empresa>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get HISTORICO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }

    async validarEmpresaActivo(empresaId: number): Promise<void> {
        const empresaGeneral = await this.empresaRepository.findOne({
            where: { empresa_id: empresaId },
            select: ['empresa', 'estado_id']
        });

        if (!empresaGeneral) { throw new BadRequestException(`La empresa indicada no existe en el sistema.`); }
        if (empresaGeneral.estado_id !== this.ACTIVO_ID) { throw new BadRequestException(`La empresa "${empresaGeneral.empresa}" no se encuentra en estado Activo.`); }
    }

    async validarEmpresaHistorico(empresaId: number): Promise<void> {
        const empresaGeneral = await this.empresaRepository.findOne({
            where: { empresa_id: empresaId },
            select: ['empresa', 'estado_id']
        });

        if (!empresaGeneral) { throw new BadRequestException(`La empresa indicada no existe en el sistema.`); }
        if (empresaGeneral.estado_id !== this.HISTORICO_ID) { throw new BadRequestException(`La empresa "${empresaGeneral.empresa}" no se encuentra en estado Histórico.`); }
    }

    async validarEmpresaActivoOHistorico(empresaId: number): Promise<void> {
        const empresaGeneral = await this.empresaRepository.findOne({
            where: { empresa_id: empresaId },
            select: ['empresa', 'estado_id']
        });

        if (!empresaGeneral) { throw new BadRequestException(`La empresa indicada no existe en el sistema.`); }
        if (![this.ACTIVO_ID, this.HISTORICO_ID].includes(empresaGeneral.estado_id)) { throw new BadRequestException(`La empresa "${empresaGeneral.empresa}" no se encuentra en un estado válido para la consulta.`); }
    }

    async validarEmpresaSinDependencias(empresaId: number): Promise<void> {
       const empresaGeneral = await this.empresaRepository.findOne({
            where: { empresa_id: empresaId },
            select: ['empresa']
        });

        if (!empresaGeneral) { throw new BadRequestException(`La empresa indicada no existe en el sistema.`); }

        const query = `
            SELECT
                (SELECT COUNT(1) FROM empresas_nits WHERE empresa_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM empresas_cuentas WHERE empresa_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM sucursales WHERE empresa_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM configuraciones WHERE empresa_id = $1 AND estado_id IN ($2, $3))
            AS total_dependencias
        `;

        const result = await this.empresaRepository.query(query, [empresaId, this.ACTIVO_ID, this.HISTORICO_ID]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) { throw new BadRequestException(`No se puede eliminar la empresa "${empresaGeneral.empresa}" porque tiene registros asociados (NITs, cuentas, sucursales o configuraciones) en estado Activo o Histórico.`); }
    }
} 
 
---- C:\sirena\sirena-backend\src\common\validators\entity-validator.service.ts ---- 
 
// c:\sirena\sirena-backend\src\common\validators\entity-validator.service.ts
import { Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

export interface EntityValidatorConfig {
    entityName: string;          // ej: 'trabajador'
    tableName: string;           // ej: 'trabajadores'
    idField: string;             // ej: 'trabajador_id'
    displayFields: string[];     // ej: ['nombres', 'paterno', 'materno']
    codeField?: string;          // ej: 'codigo'
    protectedIds?: number[];     // ej: [1]
}

@Injectable()
export class EntityValidatorService {
    constructor(
        private readonly dataSource: DataSource,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get HISTORICO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }

    async validarEstado(config: EntityValidatorConfig, id: number, estadosPermitidos: number[]): Promise<any> {
        const fieldsToSelect = Array.from(
            new Set([
                config.idField,
                ...config.displayFields,
                ...(config.codeField ? [config.codeField] : []),
                'estado_id',
            ]),
        ).join(', ');

        const query = `SELECT ${fieldsToSelect} FROM ${config.tableName} WHERE ${config.idField} = $1 LIMIT 1`;
        const result = await this.dataSource.query(query, [id]);

        if (!result || result.length === 0) {
            throw new BadRequestException(`El ${config.entityName} indicado no existe en el sistema.`);
        }

        const entity = result[0];

        if (!estadosPermitidos.includes(Number(entity.estado_id))) {
            const nombre = this.formatNombre(entity, config);
            const estadoStr = this.getEstadoStr(estadosPermitidos);
            throw new BadRequestException(`El ${config.entityName} "${nombre}" no se encuentra en estado ${estadoStr}.`);
        }

        return entity;
    }

    async validarSinDependencias(config: EntityValidatorConfig, id: number, soloActivos: boolean = false): Promise<void> {
        const entity = await this.validarEstado(config, id, [this.ACTIVO_ID, this.HISTORICO_ID]);
        const query = `SELECT * FROM fn_verificar_dependencias($1, $2, $3)`;
        const res = await this.dataSource.query(query, [config.tableName, id, soloActivos]);

        if (res && res.length > 0) {
            const total = parseInt(res[0].total_dependencias, 10) || 0;
            const detalles = res[0].detalle_dependencias || '';

            if (total > 0) {
                const nombre = this.formatNombre(entity, config);
                throw new ConflictException(`No se puede eliminar el ${config.entityName} "${nombre}" porque tiene ${total} registro(s) asociado(s):\n${detalles}`);
            }
        }
    }

    validarNoProtegido(config: EntityValidatorConfig, id: number): void {
        if (config.protectedIds && config.protectedIds.includes(id)) {
            throw new BadRequestException(`Operación no permitida para el registro protegido del sistema (ID ${id}) en ${config.entityName}.`);
        }
    }

    private formatNombre(entity: any, config: EntityValidatorConfig): string {
        const namePart = config.displayFields
            .map((field) => entity[field])
            .filter(Boolean)
            .join(' ');

        if (config.codeField && entity[config.codeField]) {
            return `${namePart} (${entity[config.codeField]})`;
        }

        return namePart || `ID ${entity[config.idField]}`;
    }

    private getEstadoStr(estados: number[]): string {
        if (estados.includes(this.ACTIVO_ID) && estados.includes(this.HISTORICO_ID)) {
            return 'Activo o Histórico';
        }

        if (estados.includes(this.ACTIVO_ID)) return 'Activo';
        if (estados.includes(this.HISTORICO_ID)) return 'Histórico';

        return 'válido';
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\validators\roles-validator.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\roles-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Rol } from '../../modules/roles/entities/rol.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class RolesValidatorService {
    constructor(
        @InjectRepository(Rol)
        private readonly rolRepository: Repository<Rol>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get HISTORICO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }

    async validarRolActivo(rolId: number): Promise<void> {
        const rolGeneral = await this.rolRepository.findOne({
            where: { rol_id: rolId },
            select: ['rol', 'estado_id']
        });

        if (!rolGeneral) {
            throw new BadRequestException(`El rol indicado no existe en el sistema.`);
        }
        if (rolGeneral.estado_id !== this.ACTIVO_ID) {
            throw new BadRequestException(`El rol "${rolGeneral.rol}" no se encuentra en estado Activo.`);
        }
    }

    async validarRolHistorico(rolId: number): Promise<void> {
        const rolGeneral = await this.rolRepository.findOne({
            where: { rol_id: rolId },
            select: ['rol', 'estado_id']
        });

        if (!rolGeneral) {
            throw new BadRequestException(`El rol indicado no existe en el sistema.`);
        }
        if (rolGeneral.estado_id !== this.HISTORICO_ID) {
            throw new BadRequestException(`El rol "${rolGeneral.rol}" no se encuentra en estado Histórico.`);
        }
    }

    async validarRolActivoOHistorico(rolId: number): Promise<void> {
        const rolGeneral = await this.rolRepository.findOne({
            where: { rol_id: rolId },
            select: ['rol', 'estado_id']
        });

        if (!rolGeneral) {
            throw new BadRequestException(`El rol indicado no existe en el sistema.`);
        }
        if (![this.ACTIVO_ID, this.HISTORICO_ID].includes(rolGeneral.estado_id)) {
            throw new BadRequestException(`El rol "${rolGeneral.rol}" no se encuentra en un estado válido para la consulta.`);
        }
    }

    async validarRolSinDependencias(rolId: number): Promise<void> {
        const rolGeneral = await this.rolRepository.findOne({
            where: { rol_id: rolId },
            select: ['rol']
        });

        if (!rolGeneral) { throw new BadRequestException(`El rol indicado no existe en el sistema.`); }

        const query = `
            SELECT
                (SELECT COUNT(1) FROM usuarios WHERE rol_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM roles_menus WHERE rol_id = $1 AND estado_id IN ($2, $3))
            AS total_dependencias
        `;

        const result = await this.rolRepository.query(query, [rolId, this.ACTIVO_ID, this.HISTORICO_ID]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) {
            throw new BadRequestException(`No se puede eliminar el rol "${rolGeneral.rol}" porque tiene registros asociados (usuarios o permisos de menú) en estado Activo o Histórico.`);
        }
    }
} 
 
---- C:\sirena\sirena-backend\src\common\validators\sucursales-validator.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\sucursales-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Sucursal } from '../../modules/sucursales/entities/sucursal.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class SucursalesValidatorService {
    constructor(
        @InjectRepository(Sucursal)
        private readonly sucursalRepository: Repository<Sucursal>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO); }
    private get HISTORICO_ID(): number { return Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO); }

    async validarSucursalActivo(sucursalId: number): Promise<void> {
        const sucursal = await this.sucursalRepository.findOne({
            where: { sucursal_id: sucursalId },
            select: ['sucursal', 'codigo', 'estado_id']
        });

        if (!sucursal) { throw new BadRequestException(`El registro de sucursal indicado no existe en el sistema.`); }
        if (sucursal.estado_id !== this.ACTIVO_ID) { throw new BadRequestException(`La sucursal "${sucursal.sucursal}" con código "${sucursal.codigo}" no se encuentra en estado Activo.`); }
    }

    async validarSucursalHistorico(sucursalId: number): Promise<void> {
        const sucursal = await this.sucursalRepository.findOne({
            where: { sucursal_id: sucursalId },
            select: ['sucursal', 'codigo', 'estado_id']
        });

        if (!sucursal) { throw new BadRequestException(`El registro de sucursal indicado no existe en el sistema.`); }
        if (sucursal.estado_id !== this.HISTORICO_ID) { throw new BadRequestException(`La sucursal "${sucursal.sucursal}" con código "${sucursal.codigo}" no se encuentra en estado Histórico.`); }
    }

    async validarSucursalActivoOHistorico(sucursalId: number): Promise<void> {
        const sucursal = await this.sucursalRepository.findOne({
            where: { sucursal_id: sucursalId },
            select: ['sucursal', 'codigo', 'estado_id']
        });

        if (!sucursal) { throw new BadRequestException(`El registro de sucursal indicado no existe en el sistema.`); }
        if (![this.ACTIVO_ID, this.HISTORICO_ID].includes(sucursal.estado_id)) { throw new BadRequestException(`La sucursal "${sucursal.sucursal}" con código "${sucursal.codigo}" no se encuentra en un estado válido para la consulta.`); }
    }

    async validarSucursalSinDependencias(sucursalId: number): Promise<void> {
        const sucursalGeneral = await this.sucursalRepository.findOne({
            where: { sucursal_id: sucursalId },
            select: ['sucursal']
        });

        if (!sucursalGeneral) { throw new BadRequestException(`La sucursal indicada no existe en el sistema.`); }

        const query = `
            SELECT
                (SELECT COUNT(1) FROM almacenes WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM usuarios WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM control_facturas WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM kardex WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM cajas WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM patrones_consumo WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM variables_exogenas WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM umbrales_configuracion WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM alertas_notificaciones WHERE sucursal_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM analitica_productos WHERE sucursal_id = $1 AND estado_id IN ($2, $3))
            AS total_dependencias
        `;

        const result = await this.sucursalRepository.query(query, [sucursalId, this.ACTIVO_ID, this.HISTORICO_ID]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) {
            throw new BadRequestException(`No se puede eliminar la sucursal "${sucursalGeneral.sucursal}" porque tiene registros asociados en estado Activo o Histórico.`);
        }
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\validators\trabajadores-validator.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\trabajadores-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Trabajador } from '../../modules/trabajadores/entities/trabajador.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class TrabajadoresValidatorService {
    constructor(
        @InjectRepository(Trabajador)
        private readonly trabajadorRepository: Repository<Trabajador>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.ACTIVO; }
    private get HISTORICO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.HISTORICO; }

    /**
     * Valida si el registro está protegido (ID 1).
     * Aplica de manera obligatoria para operaciones de update, remove, archivar y desarchivar.
     */
    async validarRegistroProtegido(trabajadorId: number): Promise<void> {
        if (Number(trabajadorId) === 1) {
            throw new BadRequestException('Esta operación no está permitida para el registro protegido del sistema (ID 1).');
        }
    }

    async validarTrabajadorActivo(trabajadorId: number): Promise<void> {
        const trabajador = await this.trabajadorRepository.findOne({
            where: { trabajador_id: trabajadorId },
            select: ['trabajador_id', 'nombres', 'paterno', 'estado_id']
        });

        if (!trabajador) { throw new BadRequestException(`El trabajador indicado no existe en el sistema.`); }
        if (trabajador.estado_id !== this.ACTIVO_ID) { throw new BadRequestException(`El trabajador "${trabajador.nombres} ${trabajador.paterno}" no se encuentra en estado Activo.`); }
    }

    async validarTrabajadorHistorico(trabajadorId: number): Promise<void> {
        const trabajador = await this.trabajadorRepository.findOne({
            where: { trabajador_id: trabajadorId },
            select: ['trabajador_id', 'nombres', 'paterno', 'estado_id']
        });

        if (!trabajador) { throw new BadRequestException(`El trabajador indicado no existe en el sistema.`); }
        if (trabajador.estado_id !== this.HISTORICO_ID) { throw new BadRequestException(`El trabajador "${trabajador.nombres} ${trabajador.paterno}" no se encuentra en estado Histórico.`); }
    }

    async validarTrabajadorActivoOHistorico(trabajadorId: number): Promise<void> {
        const trabajador = await this.trabajadorRepository.findOne({
            where: { trabajador_id: trabajadorId },
            select: ['trabajador_id', 'nombres', 'paterno', 'estado_id']
        });

        if (!trabajador) { throw new BadRequestException(`El trabajador indicado no existe en el sistema.`); }
        if (![this.ACTIVO_ID, this.HISTORICO_ID].includes(trabajador.estado_id)) { throw new BadRequestException(`El trabajador "${trabajador.nombres} ${trabajador.paterno}" no se encuentra en un estado válido para la consulta.`); }
    }

    async validarTrabajadorSinDependencias(trabajadorId: number): Promise<void> {
        const trabajador = await this.trabajadorRepository.findOne({
            where: { trabajador_id: trabajadorId },
            select: ['nombres', 'paterno']
        });

        if (!trabajador) { throw new BadRequestException(`El trabajador indicado no existe en el sistema.`); }

        const query = `
            SELECT
                (SELECT COUNT(1) FROM trabajadores_cargos WHERE trabajador_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM usuarios WHERE trabajador_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM asistencias WHERE trabajador_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM planillas_detalle WHERE trabajador_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM contratos WHERE trabajador_id = $1 AND estado_id IN ($2, $3))
            AS total_dependencias
        `;

        const result = await this.trabajadorRepository.query(query, [trabajadorId, this.ACTIVO_ID, this.HISTORICO_ID]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) {
            throw new BadRequestException(`No se puede eliminar el trabajador "${trabajador.nombres} ${trabajador.paterno}" porque tiene registros asociados (cargos, usuarios, asistencias, planillas o contratos) en estado Activo o Histórico.`);
        }
    }

    async validarReglasNegocio(dto: { dni?: string; trabajador_id?: number; fecha_nacimiento?: string; fecha_contratacion?: string; nombres?: string; paterno?: string; email?: string }): Promise<void> {
        if (dto.dni) {
            const dniTrim = dto.dni.trim();
            if (dniTrim.length < 5) {
                throw new BadRequestException('El DNI debe tener al menos 5 caracteres.');
            }
            const existingTrabajador = await this.trabajadorRepository.findOne({
                where: { dni: dniTrim }
            });

            if (existingTrabajador && (!dto.trabajador_id || existingTrabajador.trabajador_id !== dto.trabajador_id)) {
                if ([this.ACTIVO_ID, this.HISTORICO_ID].includes(existingTrabajador.estado_id)) {
                    throw new BadRequestException(`Ya existe un trabajador registrado con el DNI "${dniTrim}".`);
                }
            }
        }

        if (dto.nombres) {
            const nombresTrim = dto.nombres.trim();
            if (nombresTrim === '' || nombresTrim.length < 3) {
                throw new BadRequestException('El campo nombres no puede estar vacío y debe tener al menos 3 caracteres.');
            }
        }

        if (dto.paterno) {
            const paternoTrim = dto.paterno.trim();
            if (paternoTrim === '' || paternoTrim.length < 3) {
                throw new BadRequestException('El campo paterno no puede estar vacío y debe tener al menos 3 caracteres.');
            }
        }

        if (dto.email) {
            const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
            if (!emailRegex.test(dto.email)) {
                throw new BadRequestException('El formato del correo electrónico no es válido.');
            }
        }

        if (dto.fecha_nacimiento && dto.fecha_contratacion) {
            const fechaNacimiento = new Date(dto.fecha_nacimiento);
            const fechaContratacion = new Date(dto.fecha_contratacion);
            if (fechaContratacion < fechaNacimiento) {
                throw new BadRequestException('La fecha de contratación no puede ser anterior a la fecha de nacimiento.');
            }
        }
    }
}
 
 
---- C:\sirena\sirena-backend\src\common\validators\unique-validator.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\unique-validator.service.ts
import { Injectable, ConflictException, BadRequestException } from '@nestjs/common';
import { DataSource } from 'typeorm';

/**
 * @class UniqueValidatorService
 * @description Servicio centralizado para validar unicidad de campos en cualquier tabla.
 */
@Injectable()
export class UniqueValidatorService {
    private readonly primaryKeysCache = new Map<string, string>();

    constructor(private readonly dataSource: DataSource) {}

    /**
     * Valida que un campo sea único en la tabla especificada.
     */
    async validarCampoUnico(
        tabla: string,
        campo: string,
        valor: string | number,
        idActual?: number,
        estadosPermitidos: number[] = [1000, 1002],
        mensajePersonalizado?: string,
    ): Promise<void> {
        // Ignorar valores vacíos/no definidos para campos opcionales
        if (valor === undefined || valor === null || valor === '') return;

        if (!tabla || !campo) {
            throw new BadRequestException('Parámetros incompletos para validación de unicidad');
        }

        const tablaSanitizada = this.sanitizarIdentificador(tabla);
        const campoSanitizado = this.sanitizarIdentificador(campo);

        // Comparación insensible a mayúsculas/minúsculas
        let query = `
            SELECT 1
            FROM ${tablaSanitizada}
            WHERE ${campoSanitizado} = $1
              AND estado_id = ANY($2)
        `;
        const params: any[] = [valor, estadosPermitidos];

        if (idActual !== undefined && idActual !== null) {
            const pkField = await this.obtenerNombreClavePrimaria(tablaSanitizada);
            query += ` AND ${pkField} <> $3`;
            params.push(idActual);
        }

        query += ` LIMIT 1;`;

        const rows = await this.dataSource.query(query, params);

        if (rows && rows.length > 0) {
            const mensaje = mensajePersonalizado || `Ya existe un registro con el campo "${campo}" igual a "${valor}".`;
            throw new ConflictException(mensaje);
        }
    }

    /**
     * Valida múltiples campos únicos en una sola operación (paralelo).
     */
    async validarMultiplesCamposUnicos(
        tabla: string,
        campos: Array<{
            campo: string;
            valor: string | number;
            mensajePersonalizado?: string;
        }>,
        idActual?: number,
        estadosPermitidos: number[] = [1000, 1002],
    ): Promise<void> {
        await Promise.all(
            campos.map(({ campo, valor, mensajePersonalizado }) =>
                this.validarCampoUnico(
                    tabla,
                    campo,
                    valor,
                    idActual,
                    estadosPermitidos,
                    mensajePersonalizado,
                )
            )
        );
    }

    /**
     * Obtiene el nombre de la clave primaria de una tabla con caché en memoria.
     */
    private async obtenerNombreClavePrimaria(tabla: string): Promise<string> {
        if (this.primaryKeysCache.has(tabla)) {
            return this.primaryKeysCache.get(tabla)!;
        }

        try {
            const query = `
                SELECT a.attname
                FROM pg_index i
                JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
                WHERE i.indrelid = $1::regclass
                  AND i.indisprimary
                LIMIT 1
            `;
            const result = await this.dataSource.query(query, [tabla]);
            const pkName = (result && result.length > 0) ? result[0].attname : `${tabla}_id`;

            this.primaryKeysCache.set(tabla, pkName);
            return pkName;
        } catch {
            const fallbackPk = `${tabla}_id`;
            this.primaryKeysCache.set(tabla, fallbackPk);
            return fallbackPk;
        }
    }

    /**
     * Sanitiza identificadores SQL.
     */
    private sanitizarIdentificador(identificador: string): string {
        return identificador.replace(/[^a-zA-Z0-9_]/g, '');
    }
} 
 
---- C:\sirena\sirena-backend\src\common\validators\usuarios-validator.service.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\usuarios-validator.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Usuario } from '../../modules/usuarios/entities/usuario.entity';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

@Injectable()
export class UsuariosValidatorService {
    constructor(
        @InjectRepository(Usuario)
        private readonly usuarioRepository: Repository<Usuario>,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {}

    private get ACTIVO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.ACTIVO; }
    private get HISTORICO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.HISTORICO; }

    async validarUsuarioActivo(usuarioId: number): Promise<void> {
        const usuarioGeneral = await this.usuarioRepository.findOne({
            where: { usuario_id: usuarioId },
            select: ['login', 'estado_id']
        });

        if (!usuarioGeneral) { throw new BadRequestException(`El usuario indicado no existe en el sistema.`); }
        if (usuarioGeneral.estado_id !== this.ACTIVO_ID) { throw new BadRequestException(`El usuario "${usuarioGeneral.login}" no se encuentra en estado Activo.`); }
    }

    async validarUsuarioActivoOHistorico(usuarioId: number): Promise<void> {
        const usuarioGeneral = await this.usuarioRepository.findOne({
            where: { usuario_id: usuarioId },
            select: ['login', 'estado_id']
        });

        if (!usuarioGeneral) { throw new BadRequestException(`El usuario indicado no existe en el sistema.`); }
        if (![this.ACTIVO_ID, this.HISTORICO_ID].includes(usuarioGeneral.estado_id)) { throw new BadRequestException(`El usuario "${usuarioGeneral.login}" no se encuentra en un estado válido para la consulta.`); }
    }

    async validarUsuarioSinDependencias(usuarioId: number): Promise<void> {
        const usuarioGeneral = await this.usuarioRepository.findOne({
            where: { usuario_id: usuarioId },
            select: ['login']
        });

        if (!usuarioGeneral) { throw new BadRequestException(`El usuario indicado no existe en el sistema.`); }

        const query = `
            SELECT
                (SELECT COUNT(1) FROM trabajadores WHERE usuario_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM sucursales WHERE usuario_id = $1 AND estado_id IN ($2, $3)) +
                (SELECT COUNT(1) FROM roles WHERE usuario_id = $1 AND estado_id IN ($2, $3))
            AS total_dependencias
        `;

        const result = await this.usuarioRepository.query(query, [usuarioId, this.ACTIVO_ID, this.HISTORICO_ID]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) {
            throw new BadRequestException(`No se puede eliminar el usuario "${usuarioGeneral.login}" porque tiene registros asociados (trabajadores, sucursales o roles) en estado Activo o Histórico.`);
        }
    }

    async validarUsuarioSinDependenciasAuditoria(usuarioId: number): Promise<void> {
        const usuarioGeneral = await this.usuarioRepository.findOne({
            where: { usuario_id: usuarioId },
            select: ['login']
        });

        if (!usuarioGeneral) { throw new BadRequestException(`El usuario indicado no existe en el sistema.`); }

        const tablas = [
            'configuraciones', 'historicos', 'analitica_productos', 'auditorias',
            'logs_ejecucion', 'umbrales_configuracion', 'variables_exogenas',
            'patrones_consumo', 'metricas_rendimiento', 'entrenamientos', 'modelos',
            'alertas_notificaciones', 'movimientos', 'cajas', 'comprobantes_pagos',
            'pagos', 'planes_pagos', 'lotes_productos', 'kardex_productos', 'kardex',
            'control_facturas', 'tareas_programadas', 'parametros_globales', 'proveedores',
            'conversiones_unidad', 'promociones_productos', 'promociones',
            'productos_controlados', 'registros_sanitarios', 'productos_principios',
            'principios_activos', 'productos_ubicaciones', 'productos_rangos_edad',
            'productos_vias', 'vias', 'rangos_edad', 'productos', 'concentraciones',
            'presentaciones', 'formas', 'laboratorios', 'unidades', 'categorias',
            'clientes', 'roles_menus', 'menus', 'usuarios', 'roles', 'trabajadores',
            'ubicaciones', 'almacenes', 'sucursales', 'empresas_cuentas',
            'empresas_nits', 'empresas', 'tipos_cambios', 'bancos', 'dominios'
        ];

        const partesQuery = tablas.map(
            tabla => `(SELECT COUNT(1) FROM ${tabla} WHERE usuario_id_registro = $1 OR usuario_id_actualizacion = $1 OR usuario_id_baja = $1)`
        );

        const query = `SELECT (${partesQuery.join(' + ')}) AS total_dependencias`;

        const result = await this.usuarioRepository.query(query, [usuarioId]);
        const total = result[0]?.total_dependencias ? parseInt(result[0].total_dependencias, 10) : 0;
        if (total > 0) {
            throw new BadRequestException(`No se puede eliminar el usuario "${usuarioGeneral.login}" porque tiene registros de auditoría asociados en las tablas del sistema.`);
        }
    }
} 
 
---- C:\sirena\sirena-backend\src\common\validators\validator-factory.service.ts ---- 
 
// c:\sirena\sirena-backend\src\common\validators\validator-factory.service.ts
import { Injectable } from '@nestjs/common';
import { EntityValidatorService, EntityValidatorConfig } from './entity-validator.service';
import { CatalogoDominioConfigService } from '../../modules/dominios/catalogo-dominio-config.service';

export class EntityValidatorProxy {
    constructor(
        private readonly service: EntityValidatorService,
        private readonly catalogoConfig: CatalogoDominioConfigService,
        private readonly config: EntityValidatorConfig,
    ) { }

    async validarActivo(id: number) {
        return this.service.validarEstado(this.config, id, [
            Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO),
        ]);
    }

    async validarHistorico(id: number) {
        return this.service.validarEstado(this.config, id, [
            Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO),
        ]);
    }

    async validarActivoOHistorico(id: number) {
        return this.service.validarEstado(this.config, id, [
            Number(this.catalogoConfig.CATALOGO.ESTADO.ACTIVO),
            Number(this.catalogoConfig.CATALOGO.ESTADO.HISTORICO),
        ]);
    }

    async validarSinDependencias(id: number, soloActivos: boolean = false) {
        this.service.validarNoProtegido(this.config, id);
        return this.service.validarSinDependencias(this.config, id, soloActivos);
    }

    validarNoProtegido(id: number): void {
        this.service.validarNoProtegido(this.config, id);
    }
}

@Injectable()
export class ValidatorFactoryService {
    private readonly registry = new Map<string, EntityValidatorProxy>();

    constructor(
        private readonly validatorService: EntityValidatorService,
        private readonly catalogoConfig: CatalogoDominioConfigService,
    ) {
        this.init();
    }

    private init() {
        const configs: Array<{ key: string; config: EntityValidatorConfig }> = [
            {
                key: 'banco',
                config: { entityName: 'banco', tableName: 'bancos', idField: 'banco_id', displayFields: ['banco'] },
            },
            {
                key: 'empresa',
                config: { entityName: 'empresa', tableName: 'empresas', idField: 'empresa_id', displayFields: ['empresa'] },
            },
            {
                key: 'empresaCuenta',
                config: { entityName: 'cuenta bancaria', tableName: 'empresas_cuentas', idField: 'empresa_cuenta_id', displayFields: ['nro_cuenta'], }
            },
            {
                key: 'empresaNit',
                config: { entityName: 'NIT y autorización de empresa', tableName: 'empresas_nits', idField: 'empresa_nit_id', displayFields: ['nit', 'autorizacion'] },
            },
            {
                key: 'almacen',
                config: { entityName: 'almacén', tableName: 'almacenes', idField: 'almacen_id', displayFields: ['almacen'], codeField: 'codigo' },
            },
            {
                key: 'sucursal',
                config: { entityName: 'sucursal', tableName: 'sucursales', idField: 'sucursal_id', displayFields: ['sucursal'], codeField: 'codigo' },
            },
            {
                key: 'trabajador',
                config: { entityName: 'trabajador', tableName: 'trabajadores', idField: 'trabajador_id', displayFields: ['nombres', 'paterno', 'materno'], protectedIds: [1] },
            },
            {
                key: 'rol',
                config: { entityName: 'rol', tableName: 'roles', idField: 'rol_id', displayFields: ['rol'] },
            },
            {
                key: 'menu',
                config: { entityName: 'menú', tableName: 'menus', idField: 'menu_id', displayFields: ['titulo'] },
            },
            {
                key: 'ubicacion',
                config: { entityName: 'ubicación', tableName: 'ubicaciones', idField: 'ubicacion_id', displayFields: ['codigo'] },
            },
            {
                key: 'usuario',
                config: { entityName: 'usuario', tableName: 'usuarios', idField: 'usuario_id', displayFields: ['login'] },
            },
        ];

        for (const item of configs) {
            this.registry.set(
                item.key,
                new EntityValidatorProxy(this.validatorService, this.catalogoConfig, item.config),
            );
        }
    }

    get(key: string): EntityValidatorProxy {
        const validator = this.registry.get(key);
        if (!validator) throw new Error(`Validator for key "${key}" is not registered.`);
        return validator;
    }

    get banco() { return this.get('banco'); }
    get empresa() { return this.get('empresa'); }
    get empresaCuenta() { return this.get('empresaCuenta'); }
    get empresaNit() { return this.get('empresaNit'); }
    get almacen() { return this.get('almacen'); }
    get sucursal() { return this.get('sucursal'); }
    get trabajador() { return this.get('trabajador'); }
    get rol() { return this.get('rol'); }
    get menu() { return this.get('menu'); }
    get ubicacion() { return this.get('ubicacion'); }
    get usuario() { return this.get('usuario'); }
}
 
 
---- C:\sirena\sirena-backend\src\common\validators\validators.module.ts ---- 
 
// C:\sirena\sirena-backend\src\common\validators\validators.module.ts
import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DominiosModule } from '../../modules/dominios/dominios.module';
import { Banco } from '../../modules/bancos/entities/banco.entity';
import { Empresa } from '../../modules/empresas/entities/empresa.entity';
import { Sucursal } from '../../modules/sucursales/entities/sucursal.entity';

import { Trabajador } from '../../modules/trabajadores/entities/trabajador.entity';
import { Rol } from '../../modules/roles/entities/rol.entity';
import { Usuario } from '../../modules/usuarios/entities/usuario.entity';

import { DominiosValidatorService } from './dominios-validator.service';
import { EmpresasValidatorService } from './empresas-validator.service';
import { SucursalesValidatorService } from './sucursales-validator.service';

import { TrabajadoresValidatorService } from './trabajadores-validator.service';
import { RolesValidatorService } from './roles-validator.service';
import { UsuariosValidatorService } from './usuarios-validator.service';
import { EntityValidatorService } from './entity-validator.service';
import { ValidatorFactoryService } from './validator-factory.service';
import { UniqueValidatorService } from './unique-validator.service';

@Global()
@Module({
    imports: [
        TypeOrmModule.forFeature([
            Banco,
            Empresa,
            Sucursal,
            Trabajador,
            Rol,
            Usuario,
        ]),
        DominiosModule,
    ],
    providers: [
        DominiosValidatorService,
        EmpresasValidatorService,
        SucursalesValidatorService,
        TrabajadoresValidatorService,
        RolesValidatorService,
        UsuariosValidatorService,
        EntityValidatorService,
        ValidatorFactoryService,
        UniqueValidatorService,
    ],
    exports: [
        DominiosValidatorService,
        EmpresasValidatorService,
        SucursalesValidatorService,
        TrabajadoresValidatorService,
        RolesValidatorService,
        UsuariosValidatorService,
        EntityValidatorService,
        ValidatorFactoryService,
        UniqueValidatorService,
    ],
})
export class ValidatorsModule {}
 
 
============================================ 
RESUMEN DE ARCHIVOS CONSOLIDADOS: 
============================================ 
[1] C:\sirena\sirena-backend\src\common\common.module.ts 
[2] C:\sirena\sirena-backend\src\common\base\base-audit.entity.ts 
[3] C:\sirena\sirena-backend\src\common\constants\estados.constant.ts 
[4] C:\sirena\sirena-backend\src\common\decorators\get-user.decorator.ts 
[5] C:\sirena\sirena-backend\src\common\dto\base-pagination-query.dto.ts 
[6] C:\sirena\sirena-backend\src\common\interfaces\pagination.interface.ts 
[7] C:\sirena\sirena-backend\src\common\services\estado-manager.service.ts 
[8] C:\sirena\sirena-backend\src\common\services\services.module.ts 
[9] C:\sirena\sirena-backend\src\common\utils\auth.util.ts 
[10] C:\sirena\sirena-backend\src\common\utils\date-formatter.util.ts 
[11] C:\sirena\sirena-backend\src\common\utils\menu-parser.util.ts 
[12] C:\sirena\sirena-backend\src\common\utils\string.util.ts 
[13] C:\sirena\sirena-backend\src\common\validators\dominios-validator.service.ts 
[14] C:\sirena\sirena-backend\src\common\validators\empresas-validator.service.ts 
[15] C:\sirena\sirena-backend\src\common\validators\entity-validator.service.ts 
[16] C:\sirena\sirena-backend\src\common\validators\roles-validator.service.ts 
[17] C:\sirena\sirena-backend\src\common\validators\sucursales-validator.service.ts 
[18] C:\sirena\sirena-backend\src\common\validators\trabajadores-validator.service.ts 
[19] C:\sirena\sirena-backend\src\common\validators\unique-validator.service.ts 
[20] C:\sirena\sirena-backend\src\common\validators\usuarios-validator.service.ts 
[21] C:\sirena\sirena-backend\src\common\validators\validator-factory.service.ts 
[22] C:\sirena\sirena-backend\src\common\validators\validators.module.ts 
============================================ 
Total de archivos procesados: 22 
============================================ 
ARCHIVO CONSOLIDADO TYPESCRIPT (.TS) 
============================================ 
Generado: jue 06/08/2026 16:44:54,93 
Directorio analizado: C:\sirena\sirena-backend\src\modules\dominios 
============================================ 
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\catalogo-dominio-config.service.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\catalogo-dominio-config.service.ts
import { Injectable, OnModuleInit, InternalServerErrorException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull, In } from 'typeorm';
import { Dominio } from './entities/dominio.entity';

type DominioMap = { [key: string]: number };

export interface CatalogoItem {
    id: number;
    dominio: string;
    nombre: string | null;
    abreviatura: string;
    prefijo?: string | null;
    es_protegido: number;
}

interface EstadoIds {
    ACTIVO: number;
    BORRADO: number;
    HISTORICO: number;
    ANULADO: number;
}

interface EventoIds {
    COMPRA: number;
    VENTA: number;
    PROFORMA: number;
    EGR_TRASPASO: number;
    ING_TRASPASO: number;
    ANULACION: number;
    AJUSTE_INGRESO: number;
    AJUSTE_EGRESO: number;
    SOLICITUD_COMPRA: number;
    VENTA_RESERVA: number;
    DEVOLUCION_CLIENTE: number;
    DEVOLUCION_PROVEEDOR: number;
    ROBO: number;
    PERDIDA_CADUCIDAD: number;
    MERMA_ROTURA: number;
    INVENTARIO_FISICO_SOBRANTE: number;
    INVENTARIO_FISICO_FALTANTE: number;
    CONVERSION_UNIDADES: number;
    RETIRO_CUARENTENA: number;
    INGRESO_DONACION: number;
    LIBERACION_RESERVA: number;
}

interface TipoComprobanteIds {
    FACTURA: number;
    RECIBO: number;
    OTRO: number;
    NINGUNO: number;
}

interface TipoClienteIds {
    NATURAL: number;
    JURIDICA: number;
}

interface GeneroIds {
    MASCULINO: number;
    FEMENINO: number;
}

interface EstadoCivilMasculinoIds {
    SOLTERO: number;
    CASADO: number;
    DIVORCIADO: number;
    VIUDO: number;
    UNION_LIBRE: number;
}

interface EstadoCivilFemeninoIds {
    SOLTERA: number;
    CASADA: number;
    DIVORCIADA: number;
    VIUDA: number;
    UNION_LIBRE: number;
}

interface TipoVentaIds {
    NINGUNO: number;
    CON_FACTURA: number;
    SIN_FACTURA: number;
}

interface TipoPagoIds {
    NINGUNO: number;
    EFECTIVO: number;
    TARJETA: number;
    CHEQUE: number;
    VALE: number;
    OTROS: number;
    SIN_PAGO: number;
    TRANSFERENCIA: number;
    DEPOSITO: number;
    QR: number;
}

interface TipoModeloIds {
    ARIMA: number;
    SARIMA: number;
    SERIES_TEMPORALES: number;
    CLASIFICACION: number;
    OPTIMIZACION: number;
    DETECCION_ANOMALIAS: number;
    NINGUNO: number;
}

interface TipoBeneficioIds {
    DESCUENTO: number;
    PORCENTAJE: number;
    MONTO_FIJO: number;
    CANTIDAD: number;
    NINGUNO: number;
}

interface EstadoPronosticoIds {
    PENDIENTE: number;
    PROCESADO: number;
    ERROR: number;
    NINGUNO: number;
}

interface TemporadaIds {
    NINGUNA: number;
    ALTA: number;
    MEDIA: number;
    BAJA: number;
}

interface EstadoFiscalIds {
    ACTIVO: number;
    AGOTADO: number;
    VENCIDO: number;
    CANCELADO: number;
}

interface TipoAlmacenIds {
    NORMAL: number;
    REFRIGERADO: number;
    CONGELADO: number;
    ESPECIAL: number;
    TRANSITO: number;
    MATERIAL_MEDICO: number;
    COSMETICA: number;
    ALIMENTOS: number;
    MATERIA_PRIMA: number;
    RECEPCION: number;
    DEVOLUCIONES: number;
    DESPACHO: number;
    CUARENTENA: number;
}

interface TipoCuentaIds {
    CUENTA_CORRIENTE: number;
    CAJA_AHORROS: number;
    AHORRO_PROGRAMADO: number;
    PLAZO_FIJO: number;
    INVERSION: number;
    NO_APLICA: number;
}

interface TipoDatoIds {
    STRING: number;
    INTEGER: number;
    DECIMAL: number;
    BOOLEAN: number;
}

interface NivelUrgenciaIds {
    BAJA: number;
    MEDIA: number;
    ALTA: number;
    CRITICA: number;
    NINGUNO: number;
}

interface MotivoOutlierIds {
    BLOQUEO: number;
    FERIADO_LOCAL: number;
    ERROR_SISTEMA: number;
    PICO_ANORMAL: number;
    ROTURA: number;
    ROBO: number;
    SOBRANTE: number;
    NINGUNO: number;
}

interface FormatoPDFIds {
    ESTANDAR: number;
    RESUMIDO: number;
    DETALLADO: number;
}

interface EstadoModeloIds {
    SIN_DATOS: number;
    ENTRENANDO: number;
    ACTIVO: number;
    RECHAZADO: number;
    OBSOLETO: number;
}

interface CalidadRatingIds {
    PESIMO: number;
    DEFICIENTE: number;
    REGULAR: number;
    BUENO: number;
    EXCELENTE: number;
    NINGUNO: number;
}

interface EstadoTraspasoIds {
    EN_TRANSITO: number;
    RECIBIDO: number;
    RECHAZADO: number;
    NO_APLICA: number;
}

interface ModuloEstrategicoIds {
    FLUJO_CAJA: number;
    DEMANDA_INVENTARIO: number;
    PROVEEDORES_AHP: number;
    OPERACION_MERMAS: number;
    CLIENTES_RFM: number;
    PRECIOS_ELASTICIDAD: number;
    ANOMALIAS_FRAUDE: number;
    NINGUNO: number;
}

interface TipoDocumentoIds {
    CEDULA_IDENTIDAD: number;
    CEDULA_IDENTIDAD_EXTRANJERO: number;
    PASAPORTE: number;
    OTRO: number;
    NIT: number;
}

interface EstadoPedidoIds {
    COTIZADO: number;
    APROBADO: number;
    EN_RUTA: number;
    RECIBIDO: number;
    PARCIAL: number;
    RECHAZADO: number;
    CANCELADO: number;
}

interface TipoMonedaIds {
    BOLIVIANO: number;
    DOLAR: number;
    EURO: number;
    UFV: number;
}

interface TipoFacturaIds {
    CON_FACTURA: number;
    SIN_FACTURA: number;
    NOTA_CREDITO_DEBITO: number;
    NINGUNO: number;
}

interface EstadoFinancieroIds {
    CANCELADO: number;
    PENDIENTE: number;
    PARCIAL: number;
    NINGUNO: number;
}

interface MotivoAnulacionIds {
    FACTURA_MAL_EMITIDA: number;
    ERROR_DATOS_CLIENTE: number;
    DEVOLUCION_MERCADERIA: number;
    CONTINGENCIA: number;
    OPERACION_NO_CONCRETADA: number;
    NINGUNO: number;
}

interface EstadoLoteIds {
    VIGENTE: number;
    VENCIDO: number;
    AGOTADO: number;
    NINGUNO: number;
}

interface EstadoPagoIds {
    PENDIENTE: number;
    PARCIAL: number;
    PAGADO: number;
    CERRADO: number;
    EN_VERIFICACION: number;
    NINGUNO: number;
}

interface TipoMovimientoIds {
    INGRESO: number;
    EGRESO: number;
}

interface EstadoCajaIds {
    ABIERTA: number;
    CERRADA: number;
}

interface TipoAlertaNotificacionIds {
    SISTEMA: number;
    ALERTA_STOCK: number;
    STOCK_BAJO: number;
    STOCK_CRITICO: number;
    STOCK_EXCESO: number;
    VENCIMIENTO_PROXIMO: number;
    VENCIMIENTO_INMEDIATO: number;
    VENCIMIENTO_VENCIDO: number;
    DEMANDA_ALTA: number;
    DEMANDA_BAJA: number;
    TENDENCIA_ANOMALA: number;
    PREDICCION_ROP: number;
    PREDICCION_DEMANDA: number;
    FORECASTING: number;
    PAGOS: number;
    PAGO_VENCIDO: number;
    PAGO_PROXIMO: number;
    DOCUMENTOS: number;
    FACTURA_PENDIENTE: number;
    FACTURA_ANULADA: number;
    SEGURIDAD_ACCESO: number;
    SEGURIDAD_INTENTO_FALLIDO: number;
    SISTEMA_ERROR: number;
    SISTEMA_RENDIMIENTO: number;
    NINGUNO: number;
    RRHH_FALTAS: number;
    RRHH_CONTRATO: number;
    RRHH_PLANILLA: number;
}

interface SubtipoAlertaIds {
    SARIMA: number;
    PROPHET: number;
    KMEANS: number;
    ROP_CALC: number;
    PATRON_CONSUMO: number;
    ALERTA_PREDICTIVA: number;
    QUIEBRE_STOCK: number;
    REORDEN: number;
    EXCESO: number;
    CADUCIDAD_CRITICA: number;
    CADUCIDAD_ALTA: number;
    CADUCIDAD_MEDIA: number;
    NINGUNO: number;
}

interface OrigenAlertaIds {
    SISTEMA: number;
    IA: number;
    USUARIO: number;
    TAREA_PROGRAMADA: number;
}

interface NivelCriticoIds {
    CRITICO: number;
    ALTA: number;
    MEDIA: number;
    BAJA: number;
    INFORMATIVA: number;
    NINGUNO: number;
}

interface EstadoAlertaIds {
    PENDIENTE: number;
    EN_PROCESO: number;
    RESUELTA: number;
    IGNORADA: number;
    ESCALADA: number;
    NINGUNO: number;
}

interface FrameworkIds {
    STATSMODELS: number;
    SCIKIT_LEARN: number;
    TENSORFLOW: number;
    CUSTOM: number;
    NINGUNO: number;
}

interface EstadoEjecucionIds {
    EN_PROCESO: number;
    COMPLETADO: number;
    FALLIDO: number;
    NINGUNO: number;
}

interface TipoMetricasIds {
    REGRESION: number;
    CLASIFICACION: number;
    CLUSTERING: number;
    NINGUNO: number;
}

interface NivelLogIds {
    INFO: number;
    WARNING: number;
    ERROR: number;
    DEBUG: number;
}

interface AccionRealizadaIds {
    INSERT: number;
    UPDATE: number;
    DELETE: number;
}

interface TipoUmbralIds {
    STOCK_MINIMO: number;
    DIAS_VENCIMIENTO: number;
    ERROR_PREDICCION: number;
    NINGUNO: number;
}

interface EstadoDocumentoIds {
    EMITIDO: number;
    ANULADO: number;
    ANULADO_PARCIAL: number;
}

interface FrecuenciaIds {
    MINUTOS: number;
    HORAS: number;
    DIARIO: number;
    SEMANAL: number;
    MENSUAL: number;
    ANUAL: number;
    CRON: number;
    CONTINUA: number;
    TRIGGER_EVENTO: number;
    NINGUNO: number;
}

interface TipoTareaIds {
    REPORTE: number;
    IA_MODELO: number;
    BACKUP: number;
    ALERTA: number;
    MANTENIMIENTO: number;
    FORECASTING: number;
    CLASIFICACION: number;
    OPTIMIZACION: number;
    VALIDACION: number;
    NINGUNO: number;
}

interface SubtipoTareaIds {
    SARIMA: number;
    SARIMAX: number;
    PROPHET: number;
    KMEANS: number;
    ROP_CALC: number;
    PATRON_CONSUMO: number;
    ALERTA_PREDICTIVA: number;
    VARIABLE_EXOGENA: number;
    METRICA_RENDIMIENTO: number;
    REENTRENAMIENTO: number;
    VALIDACION_CROSS: number;
    NINGUNO: number;
}

interface MotivoDevolucionIds {
    PRODUCTO_VENCIDO: number;
    PRODUCTO_DAÑADO: number;
    ERROR_PEDIDO: number;
    EXCESO_STOCK: number;
    DESCONTINUADO: number;
    DEVOLUCION_CLIENTE: number;
    NINGUNO: number;
    PRODUCTO_NO_SOLICITADO: number;
    PRODUCTO_DEFECTUOSO: number;
}

interface TipoDespachoIds {
    VENTA_MOSTRADOR: number;
    DOMICILIO: number;
    RETIRO: number;
    TRANSFERENCIA: number;
    NINGUNO: number;
}

interface MetricaPrecisionIds {
    MAE: number;
    RMSE: number;
    MAPE: number;
    R2: number;
    F1: number;
    NINGUNO: number;
}

interface FactorEstacionalidadIds {
    NONE: number;
    DIARIO: number;
    SEMANAL: number;
    MENSUAL: number;
    ANUAL: number;
    MULTIPLE: number;
}

interface AmbienteIds {
    PRODUCCION: number;
    PILOTO_PRUEBAS: number;
}

interface TipoUbicacionMovimientoIds {
    INGRESO: number;
    EGRESO: number;
}

interface EstadoPedidoOnlineIds {
    PENDIENTE: number;
    CONFIRMADO: number;
    PREPARANDO: number;
    EN_CAMINO: number;
    ENTREGADO: number;
    CANCELADO: number;
    RECHAZADO: number;
}

interface MetodoCalculoIds {
    PONDERADO: number;
    FIFO: number;
    ULTIMA_COMPRA: number;
}

interface GradoEquivalenciaIds {
    TOTAL: number;
    PARCIAL: number;
    TERAPEUTICO: number;
    NINGUNO: number;
}

interface TipoRecetaIds {
    SIMPLE: number;
    ARCHIVADA: number;
    VALADA: number;
    NINGUNO: number;
}

interface ModalidadFacturacionIds {
    NINGUNO: number;
    ELECTRONICA: number;
    COMPUTARIZADA: number;
    MANUAL: number;
}

interface TipoPuntoVentaIds {
    NINGUNO: number;
    CAJA: number;
}

interface EstadoProformaIds {
    NO_APLICA: number;
    PENDIENTE: number;
    CONVERTIDA: number;
    EXPIRADA: number;
    ANULADA: number;
}

interface TipoOperacionAlmacenIds {
    LOGISTICA_INTERNA: number;
    VENTA_DIRECTA: number;
}

interface EntidadAfectadaIds {
    PRODUCTOS: number;
    LOTES: number;
    VENTAS: number;
    COMPRAS: number;
    USUARIOS: number;
    SUCURSALES: number;
    PROVEEDORES: number;
    CLIENTES: number;
    FACTURAS: number;
    PAGOS: number;
    INVENTARIO: number;
    NINGUNO: number;
}

interface CriticidadMedicaIds {
    NORMAL: number;
    CRITICO: number;
}

interface TipoPatronIds {
    DEMANDA: number;
}

interface FuenteExogenaIds {
    SENAMHI: number;
    INE: number;
    BCB: number;
    API_CLIMA: number;
    CALENDARIO_FESTIVOS: number;
    CUSTOM: number;
}

interface TipoBilleteMonedaIds {
    NINGUNO: number;
    B200: number;
    B100: number;
    B50: number;
    B20: number;
    B10: number;
    B5: number;
    B2: number;
    B1: number;
    M050: number;
    M020: number;
    M010: number;
    M10: number;
    M5: number;
    M2: number;
    M1: number;
}

interface TipoAplicacionIds {
    GLOBAL: number;
    CATEGORIA: number;
    LABORATORIO: number;
    PRODUCTO: number;
}

interface TipoAsistenciaIds {
    NORMAL: number;
    LICENCIA: number;
    PERMISO: number;
    JUSTIFICADA: number;
}

interface EstadoAsistenciaIds {
    PRESENTE: number;
    AUSENTE: number;
    TARDE: number;
    FALTA_INJUSTIFICADA: number;
}

interface MetodoMarcacionIds {
    MANUAL: number;
    BIOMETRICO: number;
    QR: number;
    APP: number;
}

interface TipoAlertaRRHHIds {
    RRHH: number;
    FALTAS_CONSECUTIVAS: number;
    BAJA_RENDIMIENTO: number;
    VENCIMIENTO_CONTRATO: number;
    CUMPLEANOS: number;
}

interface TipoPlanillaIds {
    SUELDOS: number;
    JORNALES: number;
    CONTRATO: number;
}

interface EstadoPlanillaIds {
    BORRADOR: number;
    CALCULADA: number;
    APROBADA: number;
    PAGADA: number;
    ANULADA: number;
}

interface EstadoContratoIds {
    VIGENTE: number;
    FINALIZADO: number;
    RENOVADO: number;
    SUSPENDIDO: number;
}

interface TipoContratoIds {
    INDEFINIDO: number;
    FIJO: number;
    EVENTUAL: number;
    PRACTICAS: number;
    CONSULTORIA: number;
}

interface TipoJornadaIds {
    COMPLETA: number;
    MEDIA: number;
    POR_HORAS: number;
}

export interface CatalogoDominioIds {
    ESTADO: EstadoIds;
    EVENTO: EventoIds;
    TIPO_COMPROBANTE: TipoComprobanteIds;
    TIPO_CLIENTE: TipoClienteIds;
    GENERO: GeneroIds;
    ESTADO_CIVIL_MASCULINO: EstadoCivilMasculinoIds;
    ESTADO_CIVIL_FEMENINO: EstadoCivilFemeninoIds;
    TIPO_VENTA: TipoVentaIds;
    TIPO_PAGO: TipoPagoIds;
    TIPO_MODELO: TipoModeloIds;
    TIPO_BENEFICIO: TipoBeneficioIds;
    ESTADO_PRONOSTICO: EstadoPronosticoIds;
    TEMPORADA: TemporadaIds;
    ESTADO_FISCAL: EstadoFiscalIds;
    TIPO_ALMACEN: TipoAlmacenIds;
    TIPO_CUENTA: TipoCuentaIds;
    TIPO_DATO: TipoDatoIds;
    NIVEL_URGENCIA: NivelUrgenciaIds;
    MOTIVO_OUTLIER: MotivoOutlierIds;
    FORMATO_PDF: FormatoPDFIds;
    ESTADO_MODELO: EstadoModeloIds;
    CALIDAD_RATING: CalidadRatingIds;
    ESTADO_TRASPASO: EstadoTraspasoIds;
    MODULO_ESTRATEGICO: ModuloEstrategicoIds;
    TIPO_DOCUMENTO: TipoDocumentoIds;
    ESTADO_PEDIDO: EstadoPedidoIds;
    TIPO_MONEDA: TipoMonedaIds;
    TIPO_FACTURA: TipoFacturaIds;
    ESTADO_FINANCIERO: EstadoFinancieroIds;
    MOTIVO_ANULACION: MotivoAnulacionIds;
    ESTADO_LOTE: EstadoLoteIds;
    ESTADO_PAGO: EstadoPagoIds;
    TIPO_MOVIMIENTO: TipoMovimientoIds;
    ESTADO_CAJA: EstadoCajaIds;
    TIPO_ALERTA_NOTIFICACION: TipoAlertaNotificacionIds;
    SUBTIPO_ALERTA: SubtipoAlertaIds;
    ORIGEN_ALERTA: OrigenAlertaIds;
    NIVEL_CRITICO: NivelCriticoIds;
    ESTADO_ALERTA: EstadoAlertaIds;
    FRAMEWORK: FrameworkIds;
    ESTADO_EJECUCION: EstadoEjecucionIds;
    TIPO_METRICAS: TipoMetricasIds;
    NIVEL_LOG: NivelLogIds;
    ACCION_REALIZADA: AccionRealizadaIds;
    TIPO_UMBRAL: TipoUmbralIds;
    ESTADO_DOCUMENTO: EstadoDocumentoIds;
    FRECUENCIA: FrecuenciaIds;
    TIPO_TAREA: TipoTareaIds;
    SUBTIPO_TAREA: SubtipoTareaIds;
    MOTIVO_DEVOLUCION: MotivoDevolucionIds;
    TIPO_DESPACHO: TipoDespachoIds;
    METRICA_PRECISION: MetricaPrecisionIds;
    FACTOR_ESTACIONALIDAD: FactorEstacionalidadIds;
    AMBIENTE: AmbienteIds;
    TIPO_UBICACION_MOVIMIENTO: TipoUbicacionMovimientoIds;
    ESTADO_PEDIDO_ONLINE: EstadoPedidoOnlineIds;
    METODO_CALCULO: MetodoCalculoIds;
    GRADO_EQUIVALENCIA: GradoEquivalenciaIds;
    TIPO_RECETA: TipoRecetaIds;
    MODALIDAD_FACTURACION: ModalidadFacturacionIds;
    TIPO_PUNTO_VENTA: TipoPuntoVentaIds;
    ESTADO_PROFORMA: EstadoProformaIds;
    TIPO_OPERACION_ALMACEN: TipoOperacionAlmacenIds;
    ENTIDAD_AFECTADA: EntidadAfectadaIds;
    CRITICIDAD_MEDICA: CriticidadMedicaIds;
    TIPO_PATRON: TipoPatronIds;
    FUENTE_EXOGENA: FuenteExogenaIds;
    TIPO_BILLETE_MONEDA: TipoBilleteMonedaIds;
    TIPO_APLICACION: TipoAplicacionIds;
    TIPO_ASISTENCIA: TipoAsistenciaIds;
    ESTADO_ASISTENCIA: EstadoAsistenciaIds;
    METODO_MARCACION: MetodoMarcacionIds;
    TIPO_ALERTA_RRHH: TipoAlertaRRHHIds;
    TIPO_PLANILLA: TipoPlanillaIds;
    ESTADO_PLANILLA: EstadoPlanillaIds;
    ESTADO_CONTRATO: EstadoContratoIds;
    TIPO_CONTRATO: TipoContratoIds;
    TIPO_JORNADA: TipoJornadaIds;
}

interface CacheEntry<T> {
    data: T;
    timestamp: number;
}

@Injectable()
export class CatalogoDominioConfigService implements OnModuleInit {
    private static readonly DOMINIOS_A_CARGAR = [
        'EstadoID',
        'EventoID',
        'TipoComprobanteID',
        'TipoClienteID',
        'GeneroID',
        'EstadoCivilMasculinoID',
        'EstadoCivilFemeninoID',
        'TipoVentaID',
        'TipoPagoID',
        'TipoModeloID',
        'TipoBeneficioID',
        'EstadoPronosticoID',
        'TemporadaID',
        'EstadoFiscalID',
        'TipoAlmacenID',
        'TipoCuentaID',
        'TipoDatoID',
        'NivelUrgenciaID',
        'MotivoOutlierID',
        'FormatoPDFID',
        'EstadoModeloID',
        'CalidadRatingID',
        'EstadoTraspasoID',
        'ModuloEstrategicoID',
        'TipoDocumentoID',
        'EstadoPedidoID',
        'TipoMonedaID',
        'TipoFacturaID',
        'EstadoFinancieroID',
        'MotivoAnulacionID',
        'EstadoLoteID',
        'EstadoPagoID',
        'TipoMovimientoID',
        'EstadoCajaID',
        'TipoAlertaNotificacionID',
        'SubtipoAlertaID',
        'OrigenAlertaID',
        'NivelCriticoID',
        'EstadoAlertaID',
        'FrameworkID',
        'EstadoEjecucionID',
        'TipoMetricasID',
        'NivelLogID',
        'TipoUmbralID',
        'EstadoDocumentoID',
        'FrecuenciaID',
        'TipoTareaID',
        'SubtipoTareaID',
        'MotivoDevolucionID',
        'TipoDespachoID',
        'MetricaPrecisionID',
        'FactorEstacionalidadID',
        'AmbienteID',
        'TipoUbicacionMovimientoID',
        'EstadoPedidoOnlineID',
        'MetodoCalculoID',
        'GradoEquivalenciaID',
        'TipoRecetaID',
        'ModalidadFacturacionID',
        'TipoPuntoVentaID',
        'EstadoProformaID',
        'TipoOperacionAlmacenID',
        'EntidadAfectadaID',
        'CriticidadMedicaID',
        'TipoPatronID',
        'FuenteExogenaID',
        'TipoBilleteMonedaID',
        'TipoAplicacionID',
        'TipoAsistenciaID',
        'EstadoAsistenciaID',
        'MetodoMarcacionID',
        'TipoAlertaRRHHID',
        'TipoPlanillaID',
        'EstadoPlanillaID',
        'EstadoContratoID',
        'TipoContratoID',
        'TipoJornadaID',
    ];

    private readonly logger = new Logger(CatalogoDominioConfigService.name);
    private estadoActivoId: number | undefined;
    private estadoHistoricoId: number | undefined;
    private catalogoIds!: CatalogoDominioIds;
    private initialized: boolean = false;

    private cache = new Map<string, CacheEntry<CatalogoItem[]>>();
    private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutos

    constructor(
        @InjectRepository(Dominio)
        private readonly dominioRepository: Repository<Dominio>,
    ) {}

    async onModuleInit() {
        try {
            await this.loadCatalogoIds();
            this.initialized = true;
            this.logger.log('Catálogo de dominios inicializado correctamente');
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
            this.logger.error(`Error al inicializar catálogo: ${errorMessage}`);
            throw error;
        }
    }

    private async loadCatalogoIds(): Promise<void> {
        const estadosEsenciales = await this.dominioRepository.find({
            where: {
                dominio: 'EstadoID',
                fecha_baja: IsNull(),
            },
            select: ['dominio_id', 'abreviatura'],
        });

        const activoReg = estadosEsenciales.find(e => e.abreviatura === 'ACTIVO');
        const historicoReg = estadosEsenciales.find(e => e.abreviatura === 'HISTORICO');

        if (!activoReg) {
            throw new InternalServerErrorException('No se pudo encontrar el ID del estado ACTIVO en la DB.');
        }

        this.estadoActivoId = activoReg.dominio_id;
        this.estadoHistoricoId = historicoReg?.dominio_id;

        const estadosPermitidos = [this.estadoActivoId];
        if (this.estadoHistoricoId) {
            estadosPermitidos.push(this.estadoHistoricoId);
        }

        const registros = await this.dominioRepository.find({
            where: {
                dominio: In(CatalogoDominioConfigService.DOMINIOS_A_CARGAR),
                estado_id: In(estadosPermitidos),
                fecha_baja: IsNull(),
            },
            select: ['dominio_id', 'abreviatura', 'dominio', 'es_protegido'],
        });

        if (registros.length === 0) {
            throw new InternalServerErrorException('No se encontraron registros de dominios en la base de datos.');
        }

        const tempCatalogo: any = {};
        const dominiosCargados: string[] = [];

        for (const dominioName of CatalogoDominioConfigService.DOMINIOS_A_CARGAR) {
            const items = registros.filter(r => r.dominio === dominioName);

            if (items.length === 0) {
                throw new InternalServerErrorException(
                    `Fallo al cargar dominios esenciales: ${dominioName}. ` +
                    `Verificar que existan registros con estado ACTIVO o HISTORICO.`
                );
            }

            const domainKey = dominioName
                .replace(/ID$/, '')
                .replace(/([A-Z])/g, '_$1')
                .toUpperCase()
                .replace(/^_/, '');

            const dominioMap = items.reduce((acc: DominioMap, curr) => {
                const rawAbreviatura = curr.abreviatura ?? '';
                const abreviaturaKey = rawAbreviatura
                    .toUpperCase()
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, "")
                    .replace(/[^A-Z0-9_]/g, '_')
                    .replace(/__+/g, '_')
                    .replace(/^_|_$/g, '');

                if (abreviaturaKey) {
                    acc[abreviaturaKey] = Number(curr.dominio_id);
                }
                return acc;
            }, {} as DominioMap);

            tempCatalogo[domainKey] = dominioMap;
            dominiosCargados.push(dominioName);
        }

        this.catalogoIds = tempCatalogo as CatalogoDominioIds;

        this.logger.debug(`Dominios cargados: ${dominiosCargados.length}`);
        this.logger.debug(`Estado ACTIVO ID: ${this.estadoActivoId}`);
        this.logger.debug(`Estado HISTORICO ID: ${this.estadoHistoricoId || 'No definido'}`);
    }

    public get CATALOGO(): CatalogoDominioIds {
        if (!this.initialized || !this.catalogoIds) {
            throw new InternalServerErrorException('El catálogo no ha sido inicializado correctamente.');
        }
        return this.catalogoIds;
    }

    public async getDominioItems(dominio: string): Promise<CatalogoItem[]> {
        const cached = this.cache.get(dominio);
        const now = Date.now();

        if (cached && (now - cached.timestamp) < this.CACHE_TTL) {
            this.logger.debug(`Cache hit para dominio: ${dominio}`);
            return cached.data;
        }
        this.logger.debug(`Cache miss para dominio: ${dominio}, cargando desde BD...`);

        if (this.estadoActivoId === undefined) {
            throw new InternalServerErrorException('ID de estado ACTIVO no disponible.');
        }

        const estadosVisibles = [this.estadoActivoId];
        if (this.estadoHistoricoId) {
            estadosVisibles.push(this.estadoHistoricoId);
        }

        const registros = await this.dominioRepository.find({
            where: {
                dominio,
                estado_id: In(estadosVisibles),
                fecha_baja: IsNull(),
            },
            order: { abreviatura: 'ASC' },
            select: ['dominio_id', 'dominio', 'descripcion', 'abreviatura', 'prefijo', 'es_protegido'],
        });

        const items = registros.map(r => ({
            id: r.dominio_id,
            dominio: r.dominio,
            nombre: r.descripcion ?? null,
            abreviatura: r.abreviatura,
            prefijo: r.prefijo ?? null,
            es_protegido: r.es_protegido,
        }));

        this.cache.set(dominio, { data: items, timestamp: now });
        this.logger.debug(`Dominio "${dominio}" cacheado con ${items.length} ítems`);

        return items;
    }

    public isInitialized(): boolean {
        return this.initialized;
    }

    public limpiarCache(dominio?: string): void {
        if (dominio) {
            this.cache.delete(dominio);
            this.logger.log(`Caché del dominio "${dominio}" limpiada`);
        } else {
            this.cache.clear();
            this.logger.log('Caché de dominios limpiada completamente');
        }
    }

    public async listarDominiosActivosOrdenados(): Promise<string[]> {
        try {
            const activoId = this.estadoActivoId;
            if (activoId === undefined) {
                throw new InternalServerErrorException('ID de estado ACTIVO no disponible.');
            }

            const registros = await this.dominioRepository.find({
                where: {
                    estado_id: activoId,
                    fecha_baja: IsNull(),
                },
                select: ['dominio'],
                order: {
                    dominio: 'ASC',
                },
            });

            const nombresUnicos = [...new Set(registros.map(r => r.dominio))];
            return nombresUnicos.sort((a, b) => a.localeCompare(b));
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
            this.logger.error(`Error al listar dominios activos: ${errorMessage}`);
            throw new InternalServerErrorException('Error al obtener la lista ordenada de dominios activos');
        }
    }
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\catalogo.controller.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\catalogo.controller.ts
import { GetUser } from '../../common/decorators/get-user.decorator';
import { validateUser } from '../../common/utils/auth.util';
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { CatalogoDominioConfigService, CatalogoItem } from '../dominios/catalogo-dominio-config.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('catalogos')
export class CatalogoController {
    constructor(private readonly catalogoService: CatalogoDominioConfigService) {}

    // Endpoint para obtener todos los IDs de catálogo cargados al inicio. Mapea a GET /api/catalogos/ids
    @Get('ids')
    getCatalogoIds(@GetUser() user: any) {
        validateUser(user);
        return this.catalogoService.CATALOGO;
    }

    // Lista los nombres de dominios activos ordenado alfabeticamente Mapea a GET /api/catalogos/dominios-activos
    @Get('dominios-activos')
    async listarDominiosActivos(@GetUser() user: any): Promise<string[]> {
        validateUser(user);
        return await this.catalogoService.listarDominiosActivosOrdenados();
    }

    // Endpoint para obtener la lista de ítems de un dominio específico. Mapea a GET /api/catalogos/dominios/:dominio
    @Get('dominios/:dominio')
    async getDominioItems(
        @Param('dominio') dominio: string,
        @GetUser() user: any
    ): Promise<CatalogoItem[]> {
        validateUser(user);
        return this.catalogoService.getDominioItems(dominio);
    }
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dominios.controller.ts ---- 
 
// src/modules/dominios/dominios.controller.ts
import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, ParseIntPipe } from '@nestjs/common';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { validateUser } from '../../common/utils/auth.util';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DominiosService } from './dominios.service';
import { CreateDominioDto } from './dto/create-dominio.dto';
import { UpdateDominioDto } from './dto/update-dominio.dto';
import { FindDominiosQueryDto } from './dto/find-dominios-query.dto';
import { DominioResponseDto } from './dto/dominio-response.dto';

@UseGuards(JwtAuthGuard)
@Controller('dominios')
export class DominiosController {
    constructor(private readonly dominiosService: DominiosService) {}

    @Get()
    async findAll(
        @Query() queryDto: FindDominiosQueryDto,
        @GetUser() user: any
    ): Promise<{ data: DominioResponseDto[], total: number }> {
        validateUser(user);
        return this.dominiosService.findAll(queryDto);
    }

    @Get('dominio/:dominio')
    async findByDominio(
        @Param('dominio') dominio: string,
        @GetUser() user: any
    ): Promise<DominioResponseDto[]> {
        validateUser(user);
        return this.dominiosService.findByDominio(dominio);
    }

    @Get('abreviaturas')
    async findByAbreviaturas(
        @Query('dominio') dominio: string,
        @Query('abreviaturas') abreviaturas: string,
        @GetUser() user: any
    ): Promise<DominioResponseDto[]> {
        validateUser(user);
        const abrevList = abreviaturas.split(',').map(a => a.trim());
        return this.dominiosService.findByAbreviaturas(dominio, abrevList);
    }

    @Get(':id')
    async findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: any
    ): Promise<DominioResponseDto> {
        validateUser(user);
        return this.dominiosService.findOne(id);
    }

    @Post()
    async create(
        @Body() createDto: CreateDominioDto,
        @GetUser() user: any
    ): Promise<DominioResponseDto> {
        validateUser(user);
        const createData = {
            ...createDto,
            usuario_id_registro: user.id || 1
        };
        return this.dominiosService.create(createData);
    }

    @Put(':id')
    async update(
        @Param('id', ParseIntPipe) id: number,
        @Body() updateDto: UpdateDominioDto,
        @GetUser() user: any
    ): Promise<DominioResponseDto> {
        validateUser(user);
        return this.dominiosService.update(id, updateDto, user.id);
    }

    @Delete(':id')
    async remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: any
    ): Promise<DominioResponseDto> {
        validateUser(user);
        return this.dominiosService.remove(id, user.id);
    }

    @Post(':id/archivar')
    async archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: any
    ): Promise<DominioResponseDto> {
        validateUser(user);
        return this.dominiosService.archivar(id, user.id);
    }

    @Post(':id/desarchivar')
    async desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: any
    ): Promise<DominioResponseDto> {
        validateUser(user);
        return this.dominiosService.desarchivar(id, user.id);
    }

    @Get(':id/dependencias')
    async obtenerDependencias(
        @GetUser() user: any,
        @Param('id', ParseIntPipe) id: number,
        @Query('verificarActivos') verificarActivos?: string,
    ): Promise<{
        dominio: any;
        dependencias: any[];
        tieneDependencias: boolean;
        mensaje: string;
    }> {
        validateUser(user);
        const verificar = verificarActivos !== 'false';
        return this.dominiosService.obtenerDependencias(id, verificar);
    }

    @Get(':id/puede-eliminar')
    async puedeEliminar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: any
    ): Promise<{ puedeEliminar: boolean; mensaje: string; dependencias?: any[] }> {
        validateUser(user);
        return this.dominiosService.puedeEliminar(id);
    }

    @Get(':id/tiene-dependencias')
    async tieneDependencias(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: any
    ): Promise<boolean> {
        validateUser(user);
        return this.dominiosService.tieneDependencias(id);
    }
} 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dominios.module.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\dominios.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DominiosService } from './dominios.service';
import { DominiosController } from './dominios.controller';
import { CatalogoController } from './catalogo.controller';
import { CatalogoDominioConfigService } from './catalogo-dominio-config.service';
import { Dominio } from './entities/dominio.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Dominio])
    ],
    controllers: [
        DominiosController,
        CatalogoController
    ],
    providers: [
        DominiosService,
        CatalogoDominioConfigService,
    ],
    exports: [
        DominiosService,
        CatalogoDominioConfigService,
        TypeOrmModule.forFeature([Dominio]),
    ],
})
export class DominiosModule {}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dominios.service.ts ---- 
 
// src/modules/dominios/dominios.service.ts
import { Injectable, NotFoundException, ConflictException, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Dominio } from './entities/dominio.entity';
import { CatalogoDominioConfigService } from './catalogo-dominio-config.service';
import { DominiosValidatorService } from '../../common/validators/dominios-validator.service';
import { ValidatorFactoryService } from '../../common/validators/validator-factory.service';
import { logSQL } from '../../common/utils/string.util';
import { normalizeText, validateSafeText } from '../../common/utils/string.util';
import { plainToInstance } from 'class-transformer';
import { FindDominiosQueryDto } from './dto/find-dominios-query.dto';
import { DominioResponseDto } from './dto/dominio-response.dto';
import { CreateDominioDto } from './dto/create-dominio.dto';
import { UpdateDominioDto } from './dto/update-dominio.dto';

@Injectable()
export class DominiosService {
    private readonly MAX_INTEGER_LIMIT = 2147483647;
    private readonly RANGO_DEFAULT: number;

    constructor(
        @InjectRepository(Dominio)
        private readonly dominioRepository: Repository<Dominio>,
        private readonly dominiosValidator: DominiosValidatorService,
        private readonly catalogoConfig: CatalogoDominioConfigService,
        private readonly validatorFactory: ValidatorFactoryService,
        private readonly configService: ConfigService,
    ) {
        this.RANGO_DEFAULT = this.configService.get<number>('DOMINIO_RANGO_TAMANO') || 50;
    }

    private get ACTIVO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.ACTIVO; }
    private get HISTORICO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.HISTORICO; }
    private get BORRADO_ID() { return this.catalogoConfig.CATALOGO.ESTADO.BORRADO; }

    private getRangoTamano(dominio: string): number {
        const keyOverride = `DOMINIO_RANGO_TAMANO_${dominio.toUpperCase()}`;
        return this.configService.get<number>(keyOverride) || this.RANGO_DEFAULT;
    }

    private validarCamposTexto(dto: CreateDominioDto | UpdateDominioDto): void {
        if (dto.dominio) { validateSafeText(dto.dominio, 'Dominio'); }
        if (dto.abreviatura) { validateSafeText(dto.abreviatura, 'Abreviatura'); }
        if (dto.prefijo) { validateSafeText(dto.prefijo, 'Prefijo'); }
        if (dto.descripcion) { validateSafeText(dto.descripcion, 'Descripción'); }
    }

    // ============================================================
    // FIND METHODS
    // ============================================================

    async findOne(id: number): Promise<DominioResponseDto> {
        const query = `
            SELECT
                d.dominio_id, d.dominio, d.abreviatura, d.prefijo, d.valor,
                d.es_protegido, d.descripcion, d.estado_id, d.usuario_id_registro,
                d.usuario_id_actualizacion, d.usuario_id_baja, d.fecha_registro,
                d.fecha_actualizacion, d.fecha_baja, e.abreviatura AS "estadoAbreviatura"
            FROM dominios d
            INNER JOIN dominios e ON d.estado_id = e.dominio_id
            WHERE d.dominio_id = $1
                AND d.estado_id IN ($2, $3, $4)
        `;
        const params: (string | number)[] = [id, this.ACTIVO_ID, this.HISTORICO_ID, this.BORRADO_ID];

        logSQL('dominios.service.ts', 'findOne', query, params);
        const rows = await this.dominioRepository.query(query, params);

        if (!rows || rows.length === 0) {
            throw new NotFoundException(`El dominio con ID #${id} no existe.`);
        }

        return plainToInstance(DominioResponseDto, rows[0], { excludeExtraneousValues: true });
    }

    async findAll(queryDto: FindDominiosQueryDto): Promise<{ data: DominioResponseDto[], total: number }> {
        console.log('📥 Parámetros recibidos en findAll:', {
            estado_id: queryDto.estado_id,
            q: queryDto.q,
            exactMatch: queryDto.exactMatch,
            offset: queryDto.offset,
            limit: queryDto.limit,
            sortField: queryDto.sortField,
            sortOrder: queryDto.sortOrder
        });

        const { estado_id, q, exactMatch, offset, limit, sortField, sortOrder } = queryDto;

        if (estado_id !== undefined) {
            await this.dominiosValidator.validarFkDominio(estado_id, 'EstadoID', 'estado_id');
        }

        const estados = estado_id ? [estado_id] : [this.ACTIVO_ID, this.HISTORICO_ID];
        const estadosValidos = [this.ACTIVO_ID, this.HISTORICO_ID];
        const estadosPlaceholders = estados.map((_, i) => `$${i + 1}`).join(', ');
        const estadosValidosPlaceholders = estadosValidos.map((_, i) => `$${i + estados.length + 1}`).join(', ');

        let baseQuery = `
            FROM dominios d
            INNER JOIN dominios e ON d.estado_id = e.dominio_id
            WHERE 1=1
                AND d.estado_id IN (${estadosPlaceholders})
                AND e.estado_id IN (${estadosValidosPlaceholders})
                AND d.fecha_baja IS NULL
        `;

        const params: any[] = [...estados, ...estadosValidos];
        let pIdx = params.length + 1;

        if (q?.trim()) {
            const words = q.trim().split(/\s+/);

            if (exactMatch === 1) {
                words.forEach(word => {
                    const cleanWord = word.trim();
                    if (cleanWord) {
                        const escapedWord = cleanWord.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                        const wordPattern = `(^|\\s)${escapedWord}(\\s|$)`;

                        baseQuery += `
                            AND (
                                TRIM(d.dominio) ~ $${pIdx}
                                OR TRIM(d.abreviatura) ~ $${pIdx + 1}
                                OR TRIM(d.prefijo) ~ $${pIdx + 2}
                                OR TRIM(COALESCE(d.descripcion, '')) ~ $${pIdx + 3}
                            )
                        `;
                        params.push(wordPattern, wordPattern, wordPattern, wordPattern);
                        pIdx += 4;
                    }
                });
            } else {
                words.forEach(word => {
                    const search = `%${normalizeText(word)}%`;
                    const SQL_UNACCENT_NORMALIZE = (col: string) => `LOWER(TRANSLATE(TRIM(${col}), 'ÁÉÍÓÚáéíóúÑñ', 'AEIOUaeiouNn'))`;

                    baseQuery += `
                        AND (
                            ${SQL_UNACCENT_NORMALIZE('d.dominio')} LIKE $${pIdx}
                            OR ${SQL_UNACCENT_NORMALIZE('d.abreviatura')} LIKE $${pIdx + 1}
                            OR ${SQL_UNACCENT_NORMALIZE('d.prefijo')} LIKE $${pIdx + 2}
                            OR ${SQL_UNACCENT_NORMALIZE("COALESCE(d.descripcion, '')")} LIKE $${pIdx + 3}
                        )
                    `;
                    params.push(search, search, search, search);
                    pIdx += 4;
                });
            }
        }

        const countQuery = `SELECT COUNT(*) as total ${baseQuery}`;
        logSQL('dominios.service.ts', 'findAll (count)', countQuery, params);
        const countRes = await this.dominioRepository.query(countQuery, params);
        const total = countRes[0]?.total ? parseInt(countRes[0].total, 10) : 0;

        const allowedSortFields: Record<string, string> = {
            dominio_id: 'd.dominio_id',
            dominio: 'd.dominio',
            abreviatura: 'd.abreviatura',
            valor: 'd.valor',
            fecha_registro: 'd.fecha_registro'
        };

        const sortFieldDb = (sortField && allowedSortFields[sortField]) || 'd.dominio_id';
        const sortOrderDb = sortOrder === 1 ? 'ASC' : 'DESC';

        let dataQuery = `
            SELECT
                d.dominio_id, d.dominio, d.abreviatura, d.prefijo, d.valor,
                d.es_protegido, d.descripcion, d.estado_id, d.usuario_id_registro,
                d.usuario_id_actualizacion, d.usuario_id_baja, d.fecha_registro,
                d.fecha_actualizacion, d.fecha_baja, e.abreviatura AS "estadoAbreviatura"
            ${baseQuery}
            ORDER BY ${sortFieldDb} ${sortOrderDb}
        `;

        const dataParams = [...params];
        if (limit !== undefined && offset !== undefined) {
            dataQuery += ` LIMIT $${pIdx++} OFFSET $${pIdx++}`;
            dataParams.push(Number(limit), Number(offset));
        }

        logSQL('dominios.service.ts', 'findAll (data)', dataQuery, dataParams);
        const rows = await this.dominioRepository.query(dataQuery, dataParams);
        const data = plainToInstance(DominioResponseDto, rows, { excludeExtraneousValues: true });
        return { data: Array.isArray(data) ? data : [], total };
    }

    async findByDominio(dominio: string): Promise<DominioResponseDto[]> {
        const estados = [this.ACTIVO_ID, this.HISTORICO_ID];
        if (!dominio || dominio.trim().length === 0) {
            return [];
        }
        const estadosPlaceholders = estados.map((_, i) => `$${i + 1}`).join(', ');

        const query = `
            SELECT
                d.dominio_id, d.dominio, d.abreviatura, d.prefijo, d.valor,
                d.es_protegido, d.descripcion, d.estado_id, d.usuario_id_registro,
                d.usuario_id_actualizacion, d.usuario_id_baja, d.fecha_registro,
                d.fecha_actualizacion, d.fecha_baja, e.abreviatura AS "estadoAbreviatura"
            FROM dominios d
            INNER JOIN dominios e ON d.estado_id = e.dominio_id
            WHERE d.fecha_baja IS NULL
            AND d.estado_id IN (${estadosPlaceholders})
            AND d.dominio ILIKE $${estados.length + 1}
            ORDER BY d.abreviatura ASC
        `;
        const params = [...estados, `%${dominio}%`];
        logSQL('dominios.service.ts', 'findByDominio', query, params);
        const rows = await this.dominioRepository.query(query, params);

        return plainToInstance(DominioResponseDto, rows, { excludeExtraneousValues: true }) as unknown as DominioResponseDto[];
    }

    async findByAbreviaturas(dominio: string, abreviaturas: string | string[]): Promise<DominioResponseDto[]> {
        const estados = [this.ACTIVO_ID, this.HISTORICO_ID];
        const listaAbreviaturas = Array.isArray(abreviaturas) ? abreviaturas : [abreviaturas];
        const listaAbreviaturasNormalizadas = listaAbreviaturas.map(a => a.toUpperCase());
        const estadosPlaceholders = estados.map((_, i) => `$${i + 1}`).join(', ');
        const abrevPlaceholders = listaAbreviaturasNormalizadas.map((_, i) => `$${estados.length + 2 + i}`).join(', ');

        const query = `
            SELECT
                d.dominio_id, d.dominio, d.abreviatura, d.prefijo, d.valor,
                d.es_protegido, d.descripcion, d.estado_id, d.usuario_id_registro,
                d.usuario_id_actualizacion, d.usuario_id_baja, d.fecha_registro,
                d.fecha_actualizacion, d.fecha_baja, e.abreviatura AS "estadoAbreviatura"
            FROM dominios d
            INNER JOIN dominios e ON d.estado_id = e.dominio_id
            WHERE d.dominio = $${estados.length + 1}
                AND d.abreviatura IN (${abrevPlaceholders})
                AND d.estado_id IN (${estadosPlaceholders})
                AND d.fecha_baja IS NULL
            ORDER BY d.dominio_id ASC
        `;
        const params = [dominio, ...estados, ...listaAbreviaturasNormalizadas];
        logSQL('dominios.service.ts', 'findByAbreviaturas', query, params);
        const rows = await this.dominioRepository.query(query, params);

        if (!rows || rows.length === 0) {
            throw new NotFoundException(`No se encontraron registros para [${listaAbreviaturas.join(', ')}] en el dominio "${dominio}"`);
        }

        return plainToInstance(DominioResponseDto, rows, { excludeExtraneousValues: true }) as unknown as DominioResponseDto[];
    }

    async create(createData: Partial<Dominio>): Promise<DominioResponseDto> {
        if (!createData.dominio || !createData.abreviatura) {
            throw new BadRequestException('Los campos "dominio" y "abreviatura" son obligatorios.');
        }

        const rangoTamano = this.getRangoTamano(createData.dominio);

        const queryCTE = `
            WITH stats AS (
                SELECT
                    COUNT(*) FILTER (
                        WHERE dominio = $1
                          AND abreviatura = $2
                          AND estado_id IN ($3, $4)
                          AND fecha_baja IS NULL
                    ) AS existe_duplicado,
                    MIN(dominio_id) FILTER (
                        WHERE estado_id IN ($3, $4) AND fecha_baja IS NULL
                    ) AS menor_id_activo,
                    MAX(dominio_id) FILTER (
                        WHERE estado_id IN ($3, $4) AND fecha_baja IS NULL
                    ) AS mayor_id_activo,
                    MIN(dominio_id) AS menor_id_total,
                    MAX(dominio_id) AS mayor_id_total
                FROM dominios
                WHERE dominio = $1
            )
            INSERT INTO dominios (
                dominio_id, dominio, abreviatura, prefijo, valor, descripcion,
                es_protegido, estado_id, usuario_id_registro, fecha_registro
            )
            SELECT
                COALESCE(s.mayor_id_activo, s.mayor_id_total, 0) + 1,
                $1, $2, $5, $6, $7, $8, $3, $9, CURRENT_TIMESTAMP
            FROM stats s
            WHERE s.existe_duplicado = 0
              AND s.menor_id_total IS NOT NULL
              AND (COALESCE(s.mayor_id_activo, s.mayor_id_total, 0) + 1) <
                  (FLOOR(COALESCE(s.menor_id_total, 0) / $10) * $10 + $10)
            RETURNING dominio_id;
        `;

        const params = [
            createData.dominio,
            createData.abreviatura,
            this.ACTIVO_ID,
            this.HISTORICO_ID,
            createData.prefijo || null,
            createData.valor !== undefined ? createData.valor : 0,
            createData.descripcion || null,
            createData.es_protegido !== undefined ? createData.es_protegido : 0,
            createData.usuario_id_registro || 1,
            rangoTamano
        ];

        logSQL('dominios.service.ts', 'create (CTE)', queryCTE, params);
        const res = await this.dominioRepository.query(queryCTE, params);

        if (!res || res.length === 0) {
            await this.diagnosticarFalloCreate(createData.dominio, createData.abreviatura, rangoTamano);
        }

        // ✅ LIMPIAR CACHÉ
        this.catalogoConfig.limpiarCache(createData.dominio);
        this.dominiosValidator.limpiarCache();

        return this.findOne(res[0].dominio_id);
    }

    async update(id: number, updateData: UpdateDominioDto, usuarioIdActualizacion?: number): Promise<DominioResponseDto> {
        this.validarCamposTexto(updateData);
        const dominioActual = await this.findOne(id);

        if (dominioActual.estado_id === this.BORRADO_ID || dominioActual.fecha_baja) {
            throw new BadRequestException('No se puede editar un dominio que se encuentra eliminado.');
        }

        if (dominioActual.estado_id === this.HISTORICO_ID) {
            throw new BadRequestException('No se puede editar un dominio que se encuentra en estado histórico.');
        }

        const queryUpdate = `
            UPDATE dominios
            SET
                valor = COALESCE($1, valor),
                descripcion = COALESCE($2, descripcion),
                es_protegido = COALESCE($3, es_protegido),
                prefijo = COALESCE($4, prefijo),
                usuario_id_actualizacion = COALESCE($5, usuario_id_actualizacion),
                fecha_actualizacion = NOW()
            WHERE dominio_id = $6
            RETURNING dominio_id
        `;

        const paramsUpdate: any[] = [
            updateData.valor !== undefined ? updateData.valor : null,
            updateData.descripcion !== undefined ? updateData.descripcion : null,
            updateData.es_protegido !== undefined ? updateData.es_protegido : null,
            updateData.prefijo !== undefined ? updateData.prefijo : null,
            usuarioIdActualizacion || null,
            id
        ];

        logSQL('dominios.service.ts', 'update', queryUpdate, paramsUpdate);
        await this.dominioRepository.query(queryUpdate, paramsUpdate);

        // ✅ LIMPIAR CACHÉ
        this.dominiosValidator.limpiarCache(id);
        this.catalogoConfig.limpiarCache(dominioActual.dominio);

        return this.findOne(id);
    }

    async remove(id: number, usuarioIdBaja: number): Promise<DominioResponseDto> {
        const dominio = await this.findOne(id);

        if (dominio.estado_id !== this.ACTIVO_ID) {
            throw new BadRequestException(`El dominio (${dominio.abreviatura}) no está activo y no puede ser eliminado.`);
        }

        if (dominio.es_protegido === 1) {
            throw new BadRequestException(`El dominio (${dominio.abreviatura}) está protegido por el sistema y no puede ser eliminado.`);
        }

        await this.dominiosValidator.validarEliminacionDominio(id, true);
        await this.validatorFactory.usuario.validarActivo(usuarioIdBaja);
        await this.dominiosValidator.validarFkDominio(this.BORRADO_ID, 'EstadoID', 'estado_id');

        const timezone = this.configService.get<string>('DB_TIMEZONE') || 'America/La_Paz';
        await this.dominioRepository.update(id, {
            estado_id: this.BORRADO_ID,
            usuario_id_baja: usuarioIdBaja,
            fecha_baja: () => `NOW() AT TIME ZONE '${timezone}'`
        });

        // ✅ LIMPIAR CACHÉ
        this.dominiosValidator.limpiarCache(id);
        this.catalogoConfig.limpiarCache(dominio.dominio);

        return await this.findOne(id);
    }

    async archivar(id: number, usuarioId: number): Promise<DominioResponseDto> {
        const dominio = await this.findOne(id);

        if (dominio.es_protegido === 1) {
            throw new BadRequestException(`El dominio (${dominio.abreviatura}) está protegido por el sistema y no puede ser archivado.`);
        }

        const dependencias = await this.dominiosValidator.verificarDependencias(id, true);
        if (dependencias.length > 0) {
            throw new ConflictException(
                `No se puede archivar el dominio porque tiene ${dependencias.length} dependencia(s) activa(s). ` +
                `Primero debe resolver las dependencias: ${dependencias.map(d => d.table_name + '.' + d.column_name).join(', ')}`
            );
        }

        await this.validatorFactory.usuario.validarActivo(usuarioId);
        await this.dominiosValidator.validarFkDominio(this.HISTORICO_ID, 'EstadoID', 'estado_id');

        await this.dominioRepository.update(id, {
            estado_id: this.HISTORICO_ID,
            usuario_id_actualizacion: usuarioId
        });

        // ✅ LIMPIAR CACHÉ
        this.dominiosValidator.limpiarCache(id);
        this.catalogoConfig.limpiarCache(dominio.dominio);

        return await this.findOne(id);
    }

    async desarchivar(id: number, usuarioId: number): Promise<DominioResponseDto> {
        const queryCheck = `
            SELECT dominio_id FROM dominios
            WHERE dominio_id = $1
            AND estado_id = $2
            AND fecha_baja IS NULL
        `;
        const checkRows = await this.dominioRepository.query(queryCheck, [id, this.HISTORICO_ID]);

        if (!checkRows || checkRows.length === 0) {
            throw new NotFoundException(`El dominio con ID #${id} no existe o no se encuentra en estado Histórico.`);
        }

        await this.validatorFactory.usuario.validarActivo(usuarioId);
        await this.dominiosValidator.validarFkDominio(this.ACTIVO_ID, 'EstadoID', 'estado_id');
        await this.dominioRepository.update(id, {
            estado_id: this.ACTIVO_ID,
            usuario_id_actualizacion: usuarioId
        });

        // ✅ LIMPIAR CACHÉ
        this.dominiosValidator.limpiarCache(id);

        return await this.findOne(id);
    }

    async tieneDependencias(id: number): Promise<boolean> {
        try {
            const dependencias = await this.dominiosValidator.verificarDependencias(id, true);
            return dependencias.length > 0;
        } catch {
            return true;
        }
    }

    async obtenerDependencias(id: number, verificarActivos: boolean = true): Promise<{
        dominio: any;
        dependencias: any[];
        tieneDependencias: boolean;
        mensaje: string;
    }> {
        try {
            return await this.dominiosValidator.obtenerInformacionDependencias(id, verificarActivos);
        } catch (error: unknown) {
            const dominio = await this.findOne(id).catch(() => ({ dominio: 'Desconocido', abreviatura: '' }));
            const mensajeError = error instanceof Error ? error.message : `El dominio no puede ser procesado debido a restricciones de seguridad.`;

            return {
                dominio,
                dependencias: [],
                tieneDependencias: true,
                mensaje: mensajeError
            };
        }
    }

    async puedeEliminar(id: number): Promise<{ puedeEliminar: boolean; mensaje: string; dependencias?: any[] }> {
        try {
            const dominio = await this.findOne(id);

            if (dominio.es_protegido === 1) {
                return {
                    puedeEliminar: false,
                    mensaje: `El dominio (${dominio.abreviatura}) está protegido y no puede ser eliminado.`
                };
            }

            await this.dominiosValidator.validarEliminacionDominio(id, true);
            return {
                puedeEliminar: true,
                mensaje: `El dominio "${dominio.dominio}" (${dominio.abreviatura}) puede ser eliminado.`
            };
        } catch (error) {
            if (error instanceof ConflictException) {
                return {
                    puedeEliminar: false,
                    mensaje: error.message,
                };
            }
            throw error;
        }
    }

    // ============================================================
    // DIAGNÓSTICO
    // ============================================================

    private async diagnosticarFalloCreate(dominio: string, abreviatura: string, rangoTamano: number): Promise<never> {
        // 1. Duplicado activo / histórico
        const checkDuplicado = await this.dominioRepository.query<{ dominio_id: number }[]>(`
            SELECT dominio_id FROM dominios
            WHERE dominio = $1 AND abreviatura = $2
            AND estado_id IN ($3, $4) AND fecha_baja IS NULL
        `, [dominio, abreviatura, this.ACTIVO_ID, this.HISTORICO_ID]);

        if (checkDuplicado.length > 0) {
            throw new ConflictException(`Ya existe el dominio "${dominio}" con la abreviatura "${abreviatura}".`);
        }

        // 2. Registro eliminado previamente
        const checkEliminado = await this.dominioRepository.query<{ dominio_id: number }[]>(`
            SELECT dominio_id FROM dominios
            WHERE dominio = $1 AND abreviatura = $2 AND estado_id = $3
        `, [dominio, abreviatura, this.BORRADO_ID]);

        if (checkEliminado.length > 0) {
            throw new ConflictException(`El dominio "${dominio}" con abreviatura "${abreviatura}" fue borrado previamente. Debe restaurarlo.`);
        }

        // 3. Overflow o Límite de Rango
        const rangoInfo = await this.dominioRepository.query<{ min_id: number; max_id: number }[]>(`
            SELECT MIN(dominio_id) as min_id, MAX(dominio_id) as max_id
            FROM dominios WHERE dominio = $1
        `, [dominio]);

        if (rangoInfo[0]?.min_id) {
            const minId = Number(rangoInfo[0].min_id);
            const maxId = Number(rangoInfo[0].max_id || minId);

            if (maxId >= this.MAX_INTEGER_LIMIT) {
                throw new ConflictException(`El dominio "${dominio}" alcanzó el límite numérico de PostgreSQL (INTEGER).`);
            }

            const nextAvailable = Math.floor(minId / rangoTamano) * rangoTamano + rangoTamano;
            if (maxId + 1 >= nextAvailable) {
                throw new ConflictException(`El dominio "${dominio}" alcanzó su límite de IDs asignado (${minId} - ${nextAvailable - 1}).`
                );
            }
        }

        throw new InternalServerErrorException(`No se pudo crear el dominio "${dominio}". Error de inconsistencia interna.`);
    }
} 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dto\create-dominio.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\dto\create-dominio.dto.ts
import { IsString, IsNotEmpty, IsInt, IsOptional, MaxLength, Matches, Min, Max } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class CreateDominioDto {
    @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
    @IsString({ message: 'El campo dominio debe ser una cadena de texto válida.' })
    @IsNotEmpty({ message: 'El campo dominio es obligatorio y no puede estar vacío.' })
    @MaxLength(255, { message: 'El campo dominio no puede exceder los 255 caracteres.' })
    @Matches(/^[A-Za-zÁÉÍÓÚáéíóúÑñ]+$/, { message: 'El campo dominio solo debe contener letras y tildes, sin espacios ni números.' })
    dominio: string;

    @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
    @IsString({ message: 'El campo abreviatura debe ser una cadena de texto válida.' })
    @IsNotEmpty({ message: 'El campo abreviatura es obligatorio y no puede estar vacío.' })
    @MaxLength(40, { message: 'El campo abreviatura no puede exceder los 40 caracteres.' })
    @Matches(/^[A-Z0-9_Ñ]+$/, { message: 'El campo abreviatura solo debe contener letras mayúsculas, números y guiones bajos.' })
    abreviatura: string;

    @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
    @IsOptional()
    @IsString({ message: 'El campo prefijo debe ser una cadena de texto válida.' })
    @MaxLength(15, { message: 'El campo prefijo no puede exceder los 15 caracteres.' })
    prefijo?: string;

    @Type(() => Number)
    @IsOptional()
    @IsInt({ message: 'El campo valor debe ser un número entero válido.' })
    valor?: number = 0;

    @Type(() => Number)
    @IsOptional()
    @IsInt({ message: 'El campo es_protegido debe ser un número entero válido.' })
    @Min(0, { message: 'El campo es_protegido debe ser 0 o 1.' })
    @Max(1, { message: 'El campo es_protegido debe ser 0 o 1.' })
    es_protegido?: number = 0;

    @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
    @IsOptional()
    @IsString({ message: 'El campo descripcion debe ser una cadena de texto válida.' })
    @MaxLength(3000, { message: 'El campo descripcion no puede exceder los 3000 caracteres.' })
    descripcion?: string;

    @Type(() => Number)
    @IsOptional()
    @IsInt({ message: 'El ID de usuario debe ser un número entero válido.' })
    @Min(1, { message: 'El ID de usuario de registro debe ser mayor a 0.' })
    @Max(9007199254740991, { message: 'El ID de usuario excede el rango máximo permitido.' })
    usuario_id_registro?: number = 1;
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dto\dominio-response.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\dto\dominio-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { formatLocalDate } from '@/common/utils/date-formatter.util';

export class DominioResponseDto {
    @Expose() dominio_id!: number;
    @Expose() dominio!: string;
    @Expose() abreviatura!: string;
    @Expose() prefijo?: string | null;
    @Expose() valor!: number;
    @Expose() es_protegido!: number;
    @Expose() descripcion?: string | null;
    @Expose() estado_id!: number;

    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion?: number | null;
    @Expose() usuario_id_baja?: number | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_registro!: string;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_actualizacion?: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_baja?: string | null;

    @Expose() estadoAbreviatura?: string;
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dto\find-abreviaturas-query.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\dto\find-abreviaturas-query.dto.ts
import { IsNotEmpty, IsString } from 'class-validator';

export class FindAbreviaturasQueryDto {
    @IsNotEmpty({ message: 'El nombre del dominio es obligatorio.' })
    @IsString()
    dominio!: string;

    @IsNotEmpty({ message: 'Debe proporcionar al menos una abreviatura.' })
    @IsString()
    abreviaturas!: string;
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dto\find-dominios-query.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\dto\find-dominios-query.dto.ts
import { IsOptional, IsInt, IsString, Min, IsIn } from 'class-validator';
import { Type } from 'class-transformer';

export class FindDominiosQueryDto {
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    estado_id?: number;

    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo exactMatch debe ser un número entero.' })
    @IsIn([0, 1], { message: 'El campo exactMatch debe ser 0 o 1.' })
    exactMatch: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'offset debe ser un número entero.' })
    @Min(0, { message: 'offset debe ser >= 0' })
    offset?: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'limit debe ser un número entero.' })
    @Min(1, { message: 'limit debe ser >= 1' })
    limit?: number = 15;

    @IsOptional()
    @IsString({ message: 'El campo sortField debe ser una cadena de texto.' })
    sortField?: string = 'dominio_id';

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo sortOrder debe ser un número entero.' })
    @IsIn([1, -1], { message: 'El campo sortOrder debe ser 1 (ascendente) o -1 (descendente).' })
    sortOrder?: number = -1;
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\dto\update-dominio.dto.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\dto\update-dominio.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateDominioDto } from './create-dominio.dto';

export class UpdateDominioDto extends PartialType(CreateDominioDto) {}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\entities\dominio.entity.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\entities\dominio.entity.ts
import { Entity, Column, PrimaryColumn, Index } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'dominios' })
@Index('uix_dom_unique', ['dominio', 'abreviatura'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('idx_dominios_dominio_activo', ['dominio'], { where: 'fecha_baja IS NULL' })
@Index('idx_dominios_estado_baja', ['estado_id', 'fecha_baja'], { where: 'fecha_baja IS NULL' })
@Index('idx_dominios_id_activo', ['dominio_id'], { where: 'fecha_baja IS NULL' })
export class Dominio extends BaseAuditEntity {
    @PrimaryColumn({ name: 'dominio_id', type: 'integer' })
    dominio_id!: number;

    @Column({ name: 'dominio', type: 'varchar', length: 255, nullable: false })
    dominio!: string;

    @Column({ name: 'abreviatura', type: 'varchar', length: 40, nullable: false })
    abreviatura!: string;

    @Column({ name: 'prefijo', type: 'varchar', length: 15, nullable: true, default: null })
    prefijo?: string | null;

    @Column({ name: 'valor', type: 'integer', nullable: false, default: 0 })
    valor!: number;

    @Column({ name: 'es_protegido', type: 'integer', nullable: false, default: 0 })
    es_protegido!: number;

    @Column({ name: 'descripcion', type: 'varchar', length: 3000, nullable: true, default: null })
    descripcion?: string | null;
}
 
 
---- C:\sirena\sirena-backend\src\modules\dominios\interfaces\dominios.interface.ts ---- 
 
// C:\sirena\sirena-backend\src\modules\dominios\interfaces\dominios.interface.ts
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';

export interface DependenciaRaw {
    table_name: string;
    column_name: string;
    total_registros: number;
    registros_activos: number;
}

export interface DominioRangoInfoRaw {
    min_id: number | null;
    max_id: number | null;
}

export interface MetricData {
    cacheHits: number;
    cacheMisses: number;
    avgQueryTime: number;
    totalQueries: number;
    cacheHitRate: number;
}

export interface FindAllParams {
    q?: string;
    exactMatch?: number;
    useFullText?: boolean;
    limit?: number;
    offset?: number;
}

// Re-exportamos por conveniencia para los archivos internos del módulo
export { PaginatedResult };
 
 
============================================ 
RESUMEN DE ARCHIVOS CONSOLIDADOS: 
============================================ 
[1] C:\sirena\sirena-backend\src\modules\dominios\catalogo-dominio-config.service.ts 
[2] C:\sirena\sirena-backend\src\modules\dominios\catalogo.controller.ts 
[3] C:\sirena\sirena-backend\src\modules\dominios\dominios.controller.ts 
[4] C:\sirena\sirena-backend\src\modules\dominios\dominios.module.ts 
[5] C:\sirena\sirena-backend\src\modules\dominios\dominios.service.ts 
[6] C:\sirena\sirena-backend\src\modules\dominios\dto\create-dominio.dto.ts 
[7] C:\sirena\sirena-backend\src\modules\dominios\dto\dominio-response.dto.ts 
[8] C:\sirena\sirena-backend\src\modules\dominios\dto\find-abreviaturas-query.dto.ts 
[9] C:\sirena\sirena-backend\src\modules\dominios\dto\find-dominios-query.dto.ts 
[10] C:\sirena\sirena-backend\src\modules\dominios\dto\update-dominio.dto.ts 
[11] C:\sirena\sirena-backend\src\modules\dominios\entities\dominio.entity.ts 
[12] C:\sirena\sirena-backend\src\modules\dominios\interfaces\dominios.interface.ts 
============================================ 
Total de archivos procesados: 12 
============================================ 

ANALIZALO a fondo
busca errores, cuellos de botella, cosas que se puede mejorar referentes a DOMINIOS y catalogos.
DAME una lista de OBSERVACIONES 
OBSERVACION: No. XXX
EXPLICACION: 
SOLUCION: 
