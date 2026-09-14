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
	WHERE n.nspname = 'dbsirena' # O el esquema donde se encuentre tu tabla
		AND c.relname = 'bancos';

	
*/

-- ================================================================================================

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ================================================================================================

/**
 * @name fn_obtener_login_para_operacion
 *
 * @description
 * Esta función retorna el login del usuario que realizó la última actualización (`usuario_id_actualizacion`).
 * En caso de que el registro no haya sido modificado (es decir, el campo de actualización sea nulo),
 * retorna automáticamente el login del usuario que realizó el registro inicial (`usuario_id_registro`).
 * Utiliza SQL dinámico protegido contra Inyección SQL mediante el uso de identificadores seguros (%I)
 * y parámetros preparados ($1).
 * 
 * @param {TEXT} p_tabla - Nombre de la tabla sobre la cual se realizará la consulta.
 * @param {TEXT} p_pk_campo - Nombre de la columna que actúa como llave primaria en la tabla indicada.
 * @param {BIGINT} p_pk_id - Identificador único (Primary Key) del registro específico a consultar.
 * 
 * @return {TEXT} Retorna el texto del login del usuario correspondiente (ej. 'ADMIN', 'PAUL'), o NULL si no se encuentra.
 * 
 * @example
 *   Consultar el login del último usuario que operó sobre el banco con ID 2
 *   SELECT fn_obtener_login_para_operacion('bancos', 'banco_id', 2);
 */
CREATE OR REPLACE FUNCTION fn_obtener_login_para_operacion(
    p_tabla TEXT,
    p_pk_campo TEXT,
    p_pk_id BIGINT
) 
RETURNS TEXT AS $$
DECLARE
    v_login TEXT;
    v_sql TEXT;
BEGIN
    v_sql := format(
        'SELECT COALESCE(u_act.login, u_reg.login) ' ||
        'FROM %I t ' ||
        'LEFT JOIN usuarios u_reg ON t.usuario_id_registro = u_reg.usuario_id ' ||
        'LEFT JOIN usuarios u_act ON t.usuario_id_actualizacion = u_act.usuario_id ' ||
        'WHERE t.%I = $1',
        p_tabla, p_pk_campo
    );

EXECUTE v_sql INTO v_login USING p_pk_id;
    
    RETURN v_login;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================================

/**
 * @name fn_unaccent_immutable
 *
 * @description
 * Función envoltorio inmutable (IMMUTABLE) y segura para paralelización (PARALLEL SAFE)
 * alrededor de la función `public.unaccent`, utilizada para remover acentos y marcas
 * diacríticas de un texto dado. Esto permite su uso en índices y operaciones donde
 * PostgreSQL requiere que la función sea estrictamente inmutable.
 * 
 * @param {TEXT} $1 - Texto de entrada al cual se le removerán los acentos.
 * 
 * @return {TEXT} Retorna el texto procesado sin acentos ni diacríticos.
 * 
 * @example
 *   Remover acentos de una cadena de texto
 *   SELECT fn_unaccent_immutable('Áéíóú');
 */
CREATE OR REPLACE FUNCTION fn_unaccent_immutable(text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    -- Se pasa 'unaccent' como el nombre del diccionario de la extensión
    SELECT public.unaccent('unaccent', $1);
$$;

/**
 * @function fn_normalize_search
 * @desc Normalizes a text string by stripping accents, removing leading/trailing spaces, 
 *       and converting all characters to lowercase. Useful for accent-insensitive and 
 *       case-insensitive search operations.
 * 
 * @param {text} input_text - The raw text string to normalize.
 * @returns {text} - The cleaned, lowercase, and accent-free string.
 * 
 * @example
 *   SELECT fn_normalize_search('  Niño MÁS Rápido  '::text);
 *   Resultado: 'nino mas rapido'
 */
CREATE OR REPLACE FUNCTION fn_normalize_search(text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT lower(
        translate(
            trim($1),
            'ÁÉÍÓÚÜáéíóúü',
            'AEIOUUaeiouu'
        )
    );
$$;

-- ================================================================================================

CREATE TABLE bancos (
    banco_id BIGSERIAL PRIMARY KEY,
    banco VARCHAR(60) NOT NULL,
    codigo_asfi CHAR(2) NOT NULL,
    abreviatura VARCHAR(20) NOT NULL,
	descripcion VARCHAR(255) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_bancos_banco_minlength CHECK (LENGTH(TRIM(banco)) >= 3),
    CONSTRAINT chk_bancos_abreviatura_minlength CHECK (LENGTH(TRIM(abreviatura)) >= 2),
    CONSTRAINT chk_bancos_codigoasfi_numerico CHECK (codigo_asfi ~ '^[0-9]{2}$'),
	CONSTRAINT chk_bancos_banco_mayusculas CHECK (banco = UPPER(banco)),
	CONSTRAINT chk_bancos_estadoid CHECK (estado_id IN (1000, 1001, 1002))
);
CREATE UNIQUE INDEX uix_bancos_codigoasfi_unique ON bancos (codigo_asfi) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_abreviatura_unique ON bancos (abreviatura) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_banco_unique ON bancos (banco) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE bancos IS 'Reglas de la tabla - bancos
R.0: La tabla bancos constituye el catálogo estandarizado de entidades financieras que operan en el sistema, almacenando tanto el nombre comercial como el código regulador oficial de la ASFI. Su función principal es respaldar los procesos contables y de pagos, permitiendo la asociación de cuentas bancarias propias (empresas_cuentas), de clientes (clientes), y de comprobantes de pago (comprobantes_pagos), garantizando la trazabilidad de las transacciones financieras.
R.1: codigo_asfi almacena el código oficial asignado por la ASFI (Autoridad de Supervisión del Sistema Financiero) para identificación regulatoria.
R.3: abreviatura debe almacenarse en mayúsculas y representa el identificador corto de la entidad financiera.
R.4: El campo banco almacena el nombre comercial.';

-- ================================================================================================

CREATE TABLE tipos_cambios (
    tipo_cambio_id BIGSERIAL PRIMARY KEY,
    origen_moneda_id SMALLINT NOT NULL DEFAULT 2300,	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    destino_moneda_id SMALLINT NOT NULL DEFAULT 2300,   -- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    factor_compra DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    factor_venta DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    fecha_cotizacion DATE NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_tiposcambios_origenmonedaid CHECK (origen_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_tiposcambios_destinomonedaid CHECK (destino_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_tiposcambios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_tiposcambios_factorcompra CHECK (factor_compra > 0),
    CONSTRAINT chk_tiposcambios_factorventa CHECK (factor_venta > 0),
    CONSTRAINT chk_tiposcambios_factores CHECK (factor_compra <= factor_venta),
    CONSTRAINT chk_tiposcambios_distinto CHECK (origen_moneda_id <> destino_moneda_id)
);
CREATE UNIQUE INDEX uix_tiposcambios_varios_unique ON tipos_cambios (origen_moneda_id, destino_moneda_id, fecha_cotizacion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE tipos_cambios IS 'Reglas de la tabla - tipos_cambios
R.0: La tabla tipos_cambios gestiona el registro histórico y actualizado de las tasas de cambio entre las diferentes monedas soportadas por el sistema, como el Boliviano (BOB) y el Dólar (USD). Su propósito es respaldar las operaciones de compra y venta en múltiples divisas, proporcionando factores de compra y venta oficiales para la correcta valuación de transacciones financieras, facturación y reportes gerenciales.
R.1: La restricción chk_tiposcambios_distinto valida que para cualquier registro operativo, origen_moneda_id sea diferente de destino_moneda_id, rechazando la transacción si ambas monedas son iguales.
R.2: fecha_cotizacion registra la fecha de vigencia de la tasa de cambio. El índice uix_tiposcambios_varios_unique garantiza unicidad por combinación de origen_moneda_id, destino_moneda_id y fecha_cotizacion para registros activos o históricos.';

-- ================================================================================================

CREATE TABLE empresas (
    empresa_id BIGSERIAL PRIMARY KEY,
    empresa VARCHAR(200) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    logo VARCHAR(255) NOT NULL,
    eslogan VARCHAR(150) NULL,
    descripcion VARCHAR(500) NULL,
    lugar VARCHAR(60) NULL,
    representante VARCHAR(100) NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    matricula_comercio VARCHAR(50) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_empresas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_empresas_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_empresas_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_empresas_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_empresas_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_empresas_empresa_notempty CHECK (TRIM(empresa) <> ''),
    CONSTRAINT chk_empresas_empresa_mayusculas CHECK (empresa = UPPER(empresa)),
    CONSTRAINT chk_empresas_empresa_minlength CHECK (LENGTH(TRIM(empresa)) >= 3),
    CONSTRAINT chk_empresas_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_empresas_logo_notempty CHECK (TRIM(logo) <> ''),
    CONSTRAINT chk_empresas_eslogan_notempty CHECK (eslogan IS NULL OR TRIM(eslogan) <> ''),
    CONSTRAINT chk_empresas_lugar_notempty CHECK (lugar IS NULL OR TRIM(lugar) <> ''),
    CONSTRAINT chk_empresas_representante_notempty CHECK (representante IS NULL OR TRIM(representante) <> ''),
    CONSTRAINT chk_empresas_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_empresas_matricula_notempty CHECK (matricula_comercio IS NULL OR TRIM(matricula_comercio) <> '')
);
CREATE UNIQUE INDEX uix_empresas_empresa_unique ON empresas (empresa) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_empresas_codigo_unique ON empresas (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_empresas_matriculacomercio_unique ON empresas (matricula_comercio) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE empresas IS 'Reglas de la tabla - empresas
R.0: La tabla empresas actúa como el nodo raíz de la estructura organizacional, almacenando la información corporativa general de la o las compañías que operan la plataforma sirena. Su función es centralizar la identidad corporativa, incluyendo razón social, logotipo, eslogan y datos de contacto, para personalizar la interfaz de usuario y, más críticamente, para proveer los datos base en la emisión de documentos fiscales y la configuración de sucursales. Se conecta jerárquicamente con sucursales, y a través de empresas_nits y empresas_cuentas con la información tributaria y bancaria de la organización.
R.1: El campo codigo es alfanumérico y corresponde a un dato maestro ingresado manualmente por el usuario desde el formulario; el sistema no genera este código de forma automática.
R.2: La columna logo almacena únicamente el nombre del archivo y su extensión (ej. ''2.jpg''). La resolución de la URL absoluta para el renderizado en el frontend se realiza mediante variable de entorno.
R.3: El campo empresa registra el nombre comercial de la empresa.';

-- ================================================================================================

CREATE TABLE empresas_nits (
    empresa_nit_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
    ambiente_id SMALLINT NOT NULL DEFAULT 2751,        			-- 2750=PRODUCCION, 2751=PILOTO_PRUEBAS
    nit VARCHAR(20) NOT NULL,
    razon_social VARCHAR(500) NOT NULL,
    actividad_economica_principal VARCHAR(2000) NOT NULL,
    etiqueta VARCHAR(30) NOT NULL,
	modalidad_facturacion_id SMALLINT NOT NULL DEFAULT 3900,	-- 3900=NINGUNO, 3901=ELECTRONICA, 3902=COMPUTARIZADA, 3903=MANUAL
    certificado_digital VARCHAR(2000) NULL,
    certificado_password VARCHAR(500) NULL,
    token_siat VARCHAR(4000) NULL,
    fecha_inicio_vigencia DATE NULL,
    fecha_fin_vigencia DATE NULL,
    email_fiscal VARCHAR(200) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_empresasnits_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT chk_empresasnits_ambienteid CHECK (ambiente_id IN (2750, 2751)),
    CONSTRAINT chk_empresasnits_modalidadfacturacionid CHECK (modalidad_facturacion_id IN (3900, 3901, 3902, 3903)),
    CONSTRAINT chk_empresasnits_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_empresasnits_nit_numerico CHECK (nit ~ '^[0-9]+$'),
    CONSTRAINT chk_empresasnits_nit_notempty CHECK (TRIM(nit) <> ''),
    CONSTRAINT chk_empresasnits_nit_minlength CHECK (LENGTH(TRIM(nit)) >= 7),
    CONSTRAINT chk_empresasnits_razonsocial_notempty CHECK (TRIM(razon_social) <> ''),
    CONSTRAINT chk_empresasnits_razonsocial_minlength CHECK (LENGTH(TRIM(razon_social)) >= 3),
    CONSTRAINT chk_empresasnits_actividadeconomicaprincipal_notempty CHECK (TRIM(actividad_economica_principal) <> ''),
    CONSTRAINT chk_empresasnits_actividadeconomicaprincipal_minlength CHECK (LENGTH(TRIM(actividad_economica_principal)) >= 3),
    CONSTRAINT chk_empresasnits_etiqueta_notempty CHECK (TRIM(etiqueta) <> ''),
    CONSTRAINT chk_empresasnits_etiqueta_formato CHECK (etiqueta ~ '^[A-Z_]+$'),
	CONSTRAINT chk_empresasnits_emailfiscal_formato CHECK (email_fiscal ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_empresasnits_emailfiscal_notempty CHECK (TRIM(email_fiscal) <> ''),
    CONSTRAINT chk_empresasnits_fechas CHECK (fecha_inicio_vigencia IS NULL OR fecha_fin_vigencia IS NULL OR fecha_inicio_vigencia <= fecha_fin_vigencia)
);
CREATE UNIQUE INDEX uix_empresasnits_varios_unique ON empresas_nits (nit, empresa_id, etiqueta) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE empresas_nits IS 'Reglas de la tabla - empresas_nits
R.0: La tabla empresas_nits almacena la información de dosificación fiscal de la empresa, incluyendo el NIT, número de autorización y fechas de vigencia, necesaria para el cumplimiento de las obligaciones tributarias ante el Servicio de Impuestos Nacionales (SIN). Su propósito es controlar los rangos de numeración de facturas y la vigencia de los talonarios fiscales, asegurando que la emisión de comprobantes electrónicos se realice con credenciales válidas y activas.
R.1: Una misma empresa (empresa_id) puede operar con el mismo número de nit bajo distintas modalidades de facturación y ambientes dependiendo de la sucursal o punto de venta asignado. El frontend debe desplegar las descripciones de la actividad económica de forma segmentada según la dosificación seleccionada.
R.2: El campo modalidad_facturacion_id controla el tipo de facturación autorizada por el SIN: ELECTRONICA, COMPUTARIZADA o MANUAL, afectando el flujo de emisión de comprobantes.
R.3: El campo ambiente_id define si el NIT se utiliza en entorno de producción (2750) o en piloto/pruebas (2751), permitiendo validaciones sin afectar documentos fiscales reales.
R.4: Los campos certificado_digital y certificado_password almacenan la ruta del archivo .p12 y su contraseña para la firma digital de documentos electrónicos. El token_siat contiene el token de acceso a los Web Services del SIN.
R.5: El campo etiqueta define en una sola palabra cual es la actividad economica sirve para la tabla catalogos';

-- ================================================================================================

CREATE TABLE empresas_cuentas (
    empresa_cuenta_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
    banco_id BIGINT NOT NULL DEFAULT 1,
    tipo_moneda_id SMALLINT NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    nro_cuenta VARCHAR(50) NOT NULL,
    tipo_cuenta_id SMALLINT NOT NULL DEFAULT 1755,  	-- 1750=CUENTA_CORRIENTE, 1751=CAJA_AHORROS, 1752=AHORRO_PROGRAMADO, 1753=PLAZO_FIJO, 1754=INVERSION, 1755=NO_APLICA
    titular VARCHAR(150) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_empresascuentas_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT fk_empresascuentas_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
    CONSTRAINT chk_empresascuentas_tipomonedaid CHECK (tipo_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_empresascuentas_tipocuentaid CHECK (tipo_cuenta_id IN (1750, 1751, 1752, 1753, 1754, 1755)),
    CONSTRAINT chk_empresascuentas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_empresascuentas_nrocuenta_minlength CHECK (LENGTH(TRIM(nro_cuenta)) >= 5),
    CONSTRAINT chk_empresascuentas_titular_notempty CHECK (TRIM(titular) <> ''),
    CONSTRAINT chk_empresascuentas_titular_minlength CHECK (LENGTH(TRIM(titular)) >= 3)
);
CREATE UNIQUE INDEX uix_empresascuentas_varios_unique ON empresas_cuentas (empresa_id, banco_id, nro_cuenta, tipo_moneda_id, tipo_cuenta_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE empresas_cuentas IS 'Reglas de la tabla - empresas_cuentas
R.0: La tabla empresas_cuentas gestiona el catálogo de cuentas bancarias operativas de la empresa, registrando la entidad financiera, el tipo de cuenta, la moneda y el titular. Su función es proporcionar la información de las cuentas de destino para la recepción de pagos de clientes, la realización de transferencias y la conciliación bancaria de los movimientos de caja.
R.1: titular almacena la razón social autorizada para las operaciones bancarias.
R.2: tipo_cuenta_id define la naturaleza de la cuenta bancaria (CUENTA_CORRIENTE, CAJA_AHORROS, AHORRO_PROGRAMADO, PLAZO_FIJO, INVERSION o NO_APLICA), afectando la disponibilidad de fondos y los tipos de transacciones permitidas.
R.3: La restricción uix_ecb_cuenta_unica garantiza que no existan cuentas duplicadas para el mismo banco y número de cuenta en registros activos o históricos.';

-- ================================================================================================

CREATE TABLE sucursales (
    sucursal_id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL DEFAULT 1,
	sucursal VARCHAR(150) NOT NULL,
    sucursal_largo VARCHAR(300) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    codigo_sin INTEGER NOT NULL,
    telefono VARCHAR(100) NULL,
    ubicacion VARCHAR(500) NULL,
    horario_atencion VARCHAR(200) NULL,
    factor_venta DECIMAL(12,2) NOT NULL DEFAULT 1.50,
    factor_facturacion DECIMAL(12,2) NOT NULL DEFAULT 1.19,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_sucursales_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
	CONSTRAINT chk_sucursales_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_sucursales_codigosin CHECK (codigo_sin >= 0),
    CONSTRAINT chk_sucursales_sucursal_notempty CHECK (TRIM(sucursal) <> ''),
    CONSTRAINT chk_sucursales_sucursallargo_notempty CHECK (TRIM(sucursal_largo) <> ''),
    CONSTRAINT chk_sucursales_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_sucursales_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_sucursales_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_sucursales_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_sucursales_factorventa CHECK (factor_venta > 1),
    CONSTRAINT chk_sucursales_factorfacturacion CHECK (factor_facturacion > 1)
);
CREATE UNIQUE INDEX uix_sucursales_empresaid_sucursal_unique ON sucursales (empresa_id, sucursal) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_sucursales_empresaid_sucursallargo_unique ON sucursales (empresa_id, sucursal) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_sucursales_empresaid_codigo_unique ON sucursales (empresa_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_sucursales_empresaid_codigosin_unique ON sucursales (empresa_id, codigo_sin) WHERE estado_id = 1000;

COMMENT ON TABLE sucursales IS 'Reglas de la tabla - sucursales
R.0: La tabla sucursales define los puntos de venta operativos de la empresa, mapeando su estructura legal, geográfica y fiscal (código, número de punto de venta). Su propósito es segmentar la operación del negocio por ubicación física, controlando los factores de precio (factor_venta, factor_facturacion) que se heredan a los productos y sirviendo como eje central para los procesos de inventario, ventas, facturación (números de autorización) y asignación de personal.
R.1: Siempre se debe cumplir precio_compra < precio_venta_sin_factura < precio_venta_con_factura. el campo precio_compra esta en la tabla productos.
R.2: codigo_sin representa codigo_sucursal_sin es secuencial por empresa. 0=Casa Matriz, 1,2,3...
R.3: factor_venta y factor_facturacion son valores iniciales que se heredan al crear un producto. Precio Sin Factura = Costo × factor_venta. Precio Con Factura = Costo × factor_venta × factor_facturacion.
R.4: Cada producto preserva sus propios factores de forma independiente, rompiendo la herencia de la sucursal sin afectarla.
R.5: Los nombres sucursal (nombre corto generalmente para reportes) y sucursal_largo (nombre legal).';

-- ================================================================================================

CREATE TABLE puntos_venta (
    punto_venta_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    codigo INTEGER NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo_punto_venta_id SMALLINT NOT NULL DEFAULT 3950,	-- 3950=NINGUNO, 3951=CAJA
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_puntosventa_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_puntosventa_tipopuntoventaid CHECK (tipo_punto_venta_id IN (3950, 3951)),
    CONSTRAINT chk_puntosventa_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_puntosventa_codigopuntoventa CHECK (codigo >= 0),
    CONSTRAINT chk_puntosventa_longitud CHECK (LENGTH(TRIM(UPPER(nombre))) > 3)
);
CREATE UNIQUE INDEX uix_puntosventa_sucursalid_puntoventaid_unique ON puntos_venta (sucursal_id, punto_venta_id) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_puntosventa_codigo_unique ON puntos_venta (sucursal_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_puntosventa_nombre_unique ON puntos_venta (sucursal_id, nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE puntos_venta IS 'Reglas de la tabla - puntos_venta
R.0: La tabla puntos_venta define los puntos de venta específicos dentro de cada sucursal, permitiendo segmentar operaciones por cajas, mostradores o módulos de atención. Su función es identificar cada punto de emisión de comprobantes fiscales y controlar la asignación de turnos, cajeros y flujo de caja.
R.1: codigo es secuencial por sucursal empezando por 0 para el punto de venta principal, incrementando en 1 para cada punto adicional. La combinación de sucursal_id y codigo es única para registros activos o históricos.
R.2: tipo_punto_venta_id clasifica el punto de venta según su función: NINGUNO (3950) para puntos sin clasificar o CAJA (3951) para cajas de cobro, afectando los flujos de facturación y cierre de caja.';

-- ================================================================================================

CREATE TABLE cuis (
    cuis_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    punto_venta_id BIGINT NOT NULL DEFAULT 1,
    codigo_cuis VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cuis_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cuis_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_cuis_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_cuis_codigo_notempty CHECK (TRIM(codigo_cuis) <> ''),
    CONSTRAINT chk_cuis_fechavigencia CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cuis_varios_unique ON cuis (sucursal_id, punto_venta_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cuis_puntoventaid ON cuis(punto_venta_id);

COMMENT ON TABLE cuis IS 'Reglas de la tabla - cuis
R.0: La tabla cuis almacena el Código Único de Identificación del Sistema (CUIS) otorgado por el SIN para la facturación electrónica. Cada sucursal y punto de venta requiere un CUIS vigente para la emisión de comprobantes fiscales. Su propósito es gestionar la validez de los códigos de autorización y controlar la caducidad de los mismos para garantizar la continuidad operativa.
R.1: fecha_vigencia almacena la fecha y hora de expiración del CUIS devuelta por el SIN. Solo los registros con fecha_vigencia > CURRENT_TIMESTAMP y estado_id = 1000 son considerados vigentes para facturación.';

-- ================================================================================================

CREATE TABLE cufd (
    cufd_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    punto_venta_id BIGINT NOT NULL DEFAULT 1,
    codigo_cufd VARCHAR(500) NOT NULL,
    codigo_control VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cufd_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cufd_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_cufd_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_cufd_codigocufd_notempty CHECK (TRIM(codigo_cufd) <> ''),
    CONSTRAINT chk_cufd_codigocontrol_notempty CHECK (TRIM(codigo_control) <> ''),
    CONSTRAINT chk_cufd_fechavigencia CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cufd_varios_unique ON cufd (sucursal_id, punto_venta_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cufd_puntoventaid ON cufd(punto_venta_id);

COMMENT ON TABLE cufd IS 'Reglas de la tabla - cufd
R.0: La tabla cufd almacena el Código Único de Facturación Diaria (CUFD) otorgado por el SIN, necesario para la emisión de comprobantes fiscales electrónicos. Cada sucursal y punto de venta requiere un CUFD vigente con validez de 24 horas para la generación de facturas. Su propósito es gestionar los códigos de autorización diarios y controlar su caducidad para garantizar la continuidad operativa en la facturación electrónica.
R.1: fecha_vigencia almacena la fecha y hora de expiración del CUFD devuelta por el SIN (vigencia de 24 horas). Solo los registros con fecha_vigencia > CURRENT_TIMESTAMP y estado_id = 1000 son considerados vigentes para la emisión de facturas.
R.2: codigo_control almacena el código de control asociado al CUFD, utilizado para la validación y generación de la firma digital de los comprobantes fiscales.';

-- ================================================================================================

CREATE TABLE unidades (
    unidad_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    codigo_sin INTEGER NOT NULL,
    unidad VARCHAR(100) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_unidades_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_unidades_unidad_notempty CHECK (TRIM(unidad) <> ''),
    CONSTRAINT chk_unidades_unidad_minlength CHECK (LENGTH(TRIM(unidad)) >= 1),
    CONSTRAINT chk_unidades_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_unidades_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 1),
    CONSTRAINT chk_unidades_codigosin CHECK (codigo_sin >= 0)
);
CREATE UNIQUE INDEX uix_unidades_codigo_unique ON unidades (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_unidades_unidad_unique ON unidades (unidad) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE unidades IS 'Reglas de la tabla - unidades
R.0: La tabla unidades define el catálogo de unidades de medida (físicas y fiscales) utilizadas en el sistema, sirviendo como base para todas las operaciones que involucran cantidades. Su propósito es estandarizar la gestión de inventario, las compras y las ventas, proporcionando una referencia inequívoca (con código numérico para el SIN) para medir productos, y permitir conversiones de unidades a través de la tabla conversiones_unidad.
R.1: El campo codigo_sin almacena los identificadores numéricos estandarizados correspondientes a la codificación oficial de unidades del Servicio de Impuestos Nacionales (SIN), requeridos para procesos de facturación electrónica.
R.2: El registro predeterminado (unidad_id = 1, ''NINGUNA'') opera como un comodín del sistema para omitir la validación de magnitudes físicas específicas en la gestión de servicios o productos intangibles.';

-- ================================================================================================

CREATE TABLE almacenes (
    almacen_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    almacen VARCHAR(200) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    tipo_almacen_id SMALLINT NOT NULL DEFAULT 1700,              -- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    tipo_operacion_almacen_id SMALLINT NOT NULL DEFAULT 4050,    -- 4050=LOGISTICA_INTERNA, 4051=VENTA_DIRECTA
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_almacenes_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_almacenes_tipoalmacenid CHECK (
        tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)
        AND (
            (tipo_operacion_almacen_id = 4050 AND tipo_almacen_id IN (1704, 1709, 1710, 1711, 1712))
            OR
            (tipo_operacion_almacen_id = 4051 AND tipo_almacen_id IN (1700, 1701, 1702, 1703, 1705, 1706, 1707, 1708))
        )
    ),
    CONSTRAINT chk_almacenes_tipooperacionalmacenid CHECK (tipo_operacion_almacen_id IN (4050, 4051)),
    CONSTRAINT chk_almacenes_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_almacenes_almacen_notempty CHECK (TRIM(almacen) <> ''),
    CONSTRAINT chk_almacenes_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_almacenes_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_almacenes_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_almacenes_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$')
);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_almacenid_unique ON almacenes (sucursal_id, almacen_id);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_almacen_unique ON almacenes (sucursal_id, almacen) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_codigo_unique ON almacenes (sucursal_id, codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE almacenes IS 'Reglas de la tabla - almacenes
R.0: La tabla almacenes representa las áreas o depósitos físicos dentro de cada sucursal, categorizados por tipo (normal, refrigerado, controlado). Su propósito es organizar el inventario de manera lógica y física, permitiendo la gestión de stock diferenciado por tipo de producto y condición de almacenamiento. Actúa como el contenedor principal para la asignación de ubicaciones y para los movimientos de inventario, asegurando la trazabilidad de la mercancía.';

-- ================================================================================================

CREATE TABLE ubicaciones (
    ubicacion_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
	codigo VARCHAR(60) NOT NULL,
    jerarquia JSONB NOT NULL DEFAULT '{}'::jsonb,
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ubicaciones_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
	CONSTRAINT chk_ubicaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicaciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_ubicaciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
	CONSTRAINT chk_ubicaciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_ubicaciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_ubicaciones_jerarquia_estructura CHECK (
        jerarquia IS NULL OR
        jsonb_typeof(jerarquia) = 'object' AND
        (jerarquia ? 'niveles' OR jerarquia ? 'camino')
    )
);
CREATE UNIQUE INDEX uix_ubicaciones_varios_unique ON ubicaciones (almacen_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ubicaciones_jerarquia ON ubicaciones USING GIN (jerarquia);

COMMENT ON TABLE ubicaciones IS '
R.0: La tabla ubicaciones define la estructura detallada dentro de cada almacén utilizando un esquema jerárquico flexible en formato JSONB. Su propósito principal es optimizar los procesos de picking y el control de inventario al permitir una localización precisa de los productos físicos sin la rigidez de columnas fijas.
R.1: Estructura Jerárquica y Camino. El campo jerarquia almacena los niveles de ubicación o caminos directos en formato JSONB, permitiendo flexibilidad total sin necesidad de modificar el esquema.

ESTRUCTURAS VÁLIDAS:

1. Ubicación con jerarquía completa (niveles):
   {
     "niveles": [
       {"tipo": "PASILLO", "valor": "01"},
       {"tipo": "ESTANTERIA", "valor": "B"},
       {"tipo": "NIVEL", "valor": "03"},
       {"tipo": "POSICION", "valor": "A"}
     ],
     "camino": "PASILLO 01 > ESTANTERIA B > NIVEL 03 > POSICION A"
   }

2. Ubicación en refrigerador con bandejas:
   {
     "niveles": [
       {"tipo": "REFRIGERADOR", "valor": "REF-01"},
       {"tipo": "BANDEJA", "valor": "02"},
       {"tipo": "POSICION", "valor": "CENTRAL"}
     ],
     "camino": "REFRIGERADOR REF-01 > BANDEJA 02 > POSICION CENTRAL"
   }

3. Ubicación simple (sin jerarquía):
   {
     "simplificado": true,
     "valor": "VITRINA-A-01",
     "camino": "VITRINA-A-01"
   }

4. Ubicación estándar con tipo y nivel (recomendada):
   {
     "tipo": "ESTANTERIA",
     "valor": "A",
     "nivel": "1",
     "camino": "ESTANTERIA A > NIVEL 1"
   }

5. Zona operativa (sin niveles):
   {
     "tipo": "ZONA",
     "valor": "RECEPCION",
     "camino": "ZONA RECEPCION"
   }

R.2: El backend es responsable de validar la coherencia de la jerarquía y de generar el campo "camino" para la visualización rápida en el frontend. La estructura debe cumplir al menos con uno de estos formatos:
    - Debe tener el campo "camino" (obligatorio para visualización)
    - Debe tener el campo "niveles" (para jerarquías complejas) O
    - Debe tener los campos "tipo" y "valor" (para jerarquías simples)

R.3: Identificador Único (Código). El campo codigo es un identificador corto y único dentro del almacén, escrito obligatoriamente en mayúsculas, sin espacios, y utilizado para escaneo de códigos QR o búsquedas rápidas.
    - Formato recomendado: [PREFIJO]-[VALOR]-[NIVEL]
    - Ejemplos: EST-A-1, REF-01-2, ZON-RECEPCION, CF-01-1

R.4: Unicidad por Almacén. La combinación de almacen_id y codigo debe ser única para registros activos o históricos (estado_id 1000 o 1002), evitando colisiones de códigos en el mismo depósito.

R.5: Tipos de Ubicación Soportados. El sistema reconoce los siguientes tipos a través del campo "tipo" en la jerarquía:
    - ESTANTERIA: Estanterías estándar (prefijo EST)
    - RACK: Racks industriales (prefijo RCK)
    - VITRINA: Exhibidores visibles al cliente (prefijo VIT)
    - REFRIGERADOR: Equipos de refrigeración (prefijo REF)
    - CONGELADOR: Equipos de congelación (prefijo CON)
    - ARMARIO: Armarios con puertas (prefijo ARM)
    - CAJA_FUERTE: Para medicamentos controlados (prefijo CF)
    - GAVETA: Cajones o gavetas (prefijo GAV)
    - ZONA: Áreas operativas (prefijo ZON)
    - PALETIZADO: Productos en pallets (prefijo PAL)
    - ANAQUEL: Anaqueles pequeños (prefijo ANA)
    - EXHIBIDOR: Exhibidores promocionales (prefijo EXP)
    - BANDEJA: Bandejas dentro de refrigeradores (prefijo BAN)
R.6: El campo descripcion es opcional y permite agregar información adicional sobre la ubicación, como características especiales, capacidad, o notas operativas.

R.7: Control de Estados. estado_id gestiona el ciclo de vida de la ubicación:
    - 1000: ACTIVO - Ubicación operativa, visible en grillas y combos
    - 1001: BORRADO - Baja lógica, excluido de operaciones
    - 1002: HISTORICO - Ubicación archivada, preservada para auditoría

R.8: Auditoría. La tabla incluye campos de auditoría estándar (usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fechas) para trazabilidad completa de cambios.';

-- ================================================================================================

CREATE TABLE almacenes_puntos_venta (
    almacen_punto_venta_id BIGSERIAL PRIMARY KEY,
	sucursal_id BIGINT NOT NULL DEFAULT 1,
    almacen_id BIGINT NOT NULL DEFAULT 1,
    punto_venta_id BIGINT NOT NULL DEFAULT 1,
    prioridad SMALLINT NOT NULL DEFAULT 1,
    es_principal SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_almacenespuntosventa_almacen FOREIGN KEY (sucursal_id, almacen_id) REFERENCES almacenes(sucursal_id, almacen_id),
    CONSTRAINT fk_almacenespuntosventa_puntoventa FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_almacenespuntosventa_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_almacenespuntosventa_esprincipal CHECK (es_principal IN (0, 1)),
    CONSTRAINT chk_almacenespuntosventa_prioridad CHECK (prioridad > 0)
);
CREATE UNIQUE INDEX uix_almacenespuntosventa_varios_unique ON almacenes_puntos_venta (sucursal_id, almacen_id, punto_venta_id) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_almacenespuntosventa_puntoventaid_unique ON almacenes_puntos_venta (punto_venta_id) WHERE es_principal = 1 AND estado_id IN (1000, 1002);
CREATE INDEX idx_almacenespuntosventa_sucursal_almacen ON almacenes_puntos_venta (sucursal_id, almacen_id);

COMMENT ON TABLE almacenes_puntos_venta IS 'Reglas de la tabla - almacenes_puntos_venta
R.0: La tabla almacenes_puntos_venta gestiona la relación de muchos a muchos entre los almacenes y los puntos de venta (cajas o mostradores de atención) en una sucursal. Su propósito es determinar dinámicamente qué almacenes surten a qué puntos de venta, permitiendo que un punto de venta se abastezca de múltiples almacenes y que un almacén central o secundario distribuya mercancía a varias cajas, eliminando la redundancia del campo es_venta_directa en la tabla maestra de almacenes.
R.1: Determinación Dinámica de Venta Directa. Un almacén se clasifica automáticamente como VENTA_DIRECTA (4051) si cuenta con al menos un registro activo en esta tabla. En ausencia de registros activos, se considera de LOGISTICA_INTERNA (4050).
R.2: Restricción de Tipos de Almacén No Comerciales. El sistema debe validar estrictamente que ningún almacén de tipo TRANSITO (1704), RECEPCION (1709), DEVOLUCIONES (1710), DESPACHO (1711) o CUARENTENA (1712) pueda ser vinculado a un punto de venta en esta tabla.
R.3: Prioridad de Despacho. El campo prioridad define el orden de preferencia con el que un punto de venta se surte de sus almacenes vinculados (1 = Mayor prioridad). El backend utiliza este valor para sugerir o automatizar el origen del stock durante la dispensación o venta.
R.4: Almacén Principal por Punto de Venta. El campo es_principal (0 o 1) identifica el depósito por defecto para un punto de venta determinado. Mediante un índice único parcial, se garantiza que cada punto de venta activo posea un único almacén principal asignado.
R.5: Propagación por Baja de Almacén o Punto de Venta. Si el almacén o el punto de venta asociado cambia de estado a BORRADO, el backend debe invalidar la relación correspondiente actualizando su estado a borrado o baja lógica para evitar transacciones sobre depósitos inhabilitados.';

-- ================================================================================================

CREATE TABLE cargos (
    cargo_id BIGSERIAL PRIMARY KEY,
    cargo VARCHAR(100) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(255) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_cargos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_cargos_cargo_notempty CHECK (TRIM(cargo) <> ''),
    CONSTRAINT chk_cargos_cargo_minlength CHECK (LENGTH(TRIM(cargo)) >= 3),
    CONSTRAINT chk_cargos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_cargos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_cargos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_cargos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_cargos_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_cargos_cargo_unique ON cargos (cargo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_cargos_codigo_unique ON cargos (codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE cargos IS 'Reglas de la tabla - cargos
R.0: La tabla cargos define los puestos de trabajo o roles laborales dentro de la organización, sirviendo para clasificar al personal y definir jerarquías operativas.';

-- ================================================================================================

CREATE TABLE trabajadores (
    trabajador_id BIGSERIAL PRIMARY KEY,
	sucursal_id BIGINT NOT NULL DEFAULT 1,
    genero_id SMALLINT NOT NULL DEFAULT 1200,  		-- 1200=MASCULINO, 1201=FEMENINO
    estado_civil_id SMALLINT NOT NULL DEFAULT 1250, -- 1250=SOLTERO, 1251=CASADO, 1252=DIVORCIADO, 1253=VIUDO, 1254=UNION_LIBRE y 1300=SOLTERA, 1301=CASADA, 1302=DIVORCIADA, 1303=VIUDA, 1304=UNION_LIBRE
    nombres VARCHAR(150) NOT NULL,
    paterno VARCHAR(80) NOT NULL,
    materno VARCHAR(80) NULL,
    dni VARCHAR(20) NOT NULL,
	telefono VARCHAR(100) NULL,
	direccion VARCHAR(255) NULL,
    email VARCHAR(100) NULL,
    fecha_nacimiento DATE NULL,
    fecha_contratacion DATE NULL,
    foto VARCHAR(255) NOT NULL,
	qr VARCHAR(255) NULL DEFAULT '',
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_trabajadores_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_trabajadores_generoid CHECK (genero_id IN (1200, 1201)),
    CONSTRAINT chk_trabajadores_estadocivil CHECK (
        (genero_id = 1200 AND estado_civil_id IN (1250, 1251, 1252, 1253, 1254)) OR
        (genero_id = 1201 AND estado_civil_id IN (1300, 1301, 1302, 1303, 1304))
    ),
    CONSTRAINT chk_trabajadores_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_trabajadores_nombres_notempty CHECK (TRIM(nombres) <> ''),
    CONSTRAINT chk_trabajadores_nombres_minlength CHECK (LENGTH(TRIM(nombres)) >= 3),
    CONSTRAINT chk_trabajadores_paterno_notempty CHECK (TRIM(paterno) <> ''),
    CONSTRAINT chk_trabajadores_paterno_minlength CHECK (LENGTH(TRIM(paterno)) >= 3),
    CONSTRAINT chk_trabajadores_materno_notempty CHECK (materno IS NULL OR TRIM(materno) <> ''),
    CONSTRAINT chk_trabajadores_materno_minlength CHECK (materno IS NULL OR LENGTH(TRIM(materno)) >= 3),
	CONSTRAINT chk_trabajadores_nombres_mayus CHECK (nombres = UPPER(nombres)),
    CONSTRAINT chk_trabajadores_paterno_mayus CHECK (paterno = UPPER(paterno)),
    CONSTRAINT chk_trabajadores_materno_mayus CHECK (materno IS NULL OR materno = UPPER(materno)),
    CONSTRAINT chk_trabajadores_dni_notempty CHECK (TRIM(dni) <> ''),
    CONSTRAINT chk_trabajadores_dni_minlength CHECK (LENGTH(TRIM(dni)) >= 5),
    CONSTRAINT chk_trabajadores_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_trabajadores_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_trabajadores_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_trabajadores_foto_notempty CHECK (TRIM(foto) <> ''),
    CONSTRAINT chk_trabajadores_fechanacimiento CHECK (fecha_nacimiento IS NULL OR fecha_nacimiento <= CURRENT_DATE),
    CONSTRAINT chk_trabajadores_fechacontratacion CHECK (fecha_contratacion IS NULL OR fecha_contratacion <= CURRENT_DATE)
);
CREATE UNIQUE INDEX uix_trabajadores_dni_unique ON trabajadores (dni) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_trabajadores_trabajador_unique ON trabajadores (trabajador_id, sucursal_id) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_trabajadores_nombre_completo_unique ON trabajadores (nombres, paterno, COALESCE(materno, '')) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_trabajadores_sucursal ON trabajadores (sucursal_id) WHERE estado_id = 1000;

COMMENT ON TABLE trabajadores IS 'Reglas de la tabla - trabajadores
R.0: La tabla trabajadores actúa como el registro maestro de individuos, centralizando la información demográfica básica de todos los actores del sistema, incluyendo empleados, clientes eventuales y contactos. Su propósito es servir como la entidad raíz de identificación personal, evitando la duplicación de datos y proporcionando una base de datos unificada para la creación de usuarios del sistema, gestión de clientes y cualquier otra interacción que requiera datos personales.
R.1: Prerrequisito Operativo Maestro. El registro completo y validado de un individuo en esta tabla es un requerimiento técnico obligatorio antes de que el sistema le pueda asignar credenciales de acceso, roles o vincularlo como operador activo en cualquier sucursal.
R.2: qr el backend debe generar la imagen de qr con datos del trabajador nombres, paterno, materno, dni, telefono.
R.3: Gestión de Archivos y Metadatos Digitales. Los campos foto y qr almacenan exclusivamente las rutas lógicas de los archivos correspondientes en el servidor. La generación del código QR y el procesamiento de la imagen se realizan de forma asíncrona en el backend. Siguiendo la regla general R.G.4, la desactivación de un registro no elimina físicamente estos recursos del disco.
R.4: Consistencia de Identidad Única. La restricción de unicidad sobre el documento de identidad (dni) se aplica de forma estricta sobre registros con estado ACTIVO e HISTORICO. Esto impide la duplicidad de trabajadores vigentes dentro de la plataforma, permitiendo la reutilización del valor únicamente si el registro previo ha sido modificado al estado BORRADO.
R.5: Integridad de Estado Civil y Género. El sistema utiliza dos grupos de valores independientes para el estado civil: Identificadores masculinos (1250-1254) para el género MASCULINO y identificadores femeninos (1300-1304) para el género FEMENINO. El frontend debe filtrar las opciones de estado civil según el género seleccionado, mostrando SOLTERO/CASADO/DIVORCIADO/VIUDO/UNION LIBRE para MASCULINO y SOLTERA/CASADA/DIVORCIADA/VIUDA/UNION LIBRE para FEMENINO.
R.6: El campo foto almacena el nombre del archivo fisico de la imagen de perfil del trabajador. La imagen puede ser subida por el usuario o, si no se proporciona, se asigna una imagen por defecto. El backend controla la creación y el reemplazo del archivo según la R.G.4.
R.7: Para el registro comodín (trabajador_id = 1), el backend debe generar un archivo QR que contenga el texto "NINGUNO" o un identificador similar que indique su naturaleza de registro por defecto, asegurando su existencia según la R.G.6.';

-- ================================================================================================

CREATE TABLE trabajadores_cargos (
    trabajador_cargo_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    cargo_id BIGINT NOT NULL DEFAULT 1,
	sueldo_base DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	tipo_moneda_id SMALLINT NOT NULL DEFAULT 2300,		-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
	fecha_desde DATE NOT NULL DEFAULT CURRENT_DATE,
	fecha_hasta DATE NULL,
	es_activo SMALLINT NOT NULL DEFAULT 1,
	observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_trabajadorescargos_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_trabajadorescargos_cargo_id FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id),
    CONSTRAINT chk_trabajadorescargos_tipomonedaid CHECK (tipo_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_trabajadorescargos_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_trabajadorescargos_sueldobase CHECK (sueldo_base >= 0),
    CONSTRAINT chk_trabajadorescargos_esactivo CHECK (es_activo IN (0, 1)),
    CONSTRAINT chk_trabajadorescargos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_trabajadorescargos_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta >= fecha_desde)
);
CREATE UNIQUE INDEX uix_trabajadorescargos_varios_unique ON trabajadores_cargos (trabajador_id, cargo_id) WHERE es_activo = 1 AND estado_id = 1000;

COMMENT ON TABLE trabajadores_cargos IS 'Reglas de la tabla - trabajadores_cargos
R.0: La tabla trabajadores_cargos actúa como entidad asociativa (relación N:M) entre trabajadores y cargos, permitiendo asignar uno o múltiples puestos laborales a un trabajador con su respectiva trazabilidad histórica y estado vigente.';

-- ================================================================================================

CREATE TABLE roles (
    rol_id BIGSERIAL PRIMARY KEY,
    rol VARCHAR(60) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
	descripcion VARCHAR(500) NULL,
	es_admin SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_roles_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_roles_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_roles_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_roles_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_roles_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_roles_rol_not_empty CHECK (TRIM(rol) <> ''),
    CONSTRAINT chk_roles_rol_minlength CHECK (LENGTH(TRIM(rol)) >= 3),
    CONSTRAINT chk_roles_rol_mayusculas CHECK (rol = UPPER(rol)),
    CONSTRAINT chk_roles_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_roles_unico_admin ON roles (es_admin) WHERE es_admin = 1 AND estado_id = 1000;
CREATE UNIQUE INDEX uix_roles_codigo_unique ON roles (codigo) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_roles_rol_unique ON roles (rol) WHERE estado_id = 1000;

COMMENT ON TABLE roles IS 'Reglas de la tabla - roles
R.0: La tabla roles define los perfiles de acceso y autorización dentro del sistema, estableciendo las categorías jerárquicas de usuarios (Administrador, Gerente, Vendedor). Su propósito es estructurar el modelo de seguridad y control de acceso basado en roles (RBAC), simplificando la gestión de permisos al agrupar operaciones y menús bajo un único perfil que se asigna a los usuarios, garantizando que cada operador tenga acceso únicamente a las funcionalidades pertinentes a su función.
R.1: Inmutabilidad del Perfil Raíz (ADMINISTRADOR). El rol con código ADM es el único perfil que cuenta de forma nativa e irrestricta con permisos globales en el backend para realizar operaciones CRUD, archivar y desarchivar sobre el catálogo de roles, usuarios y permisos del sistema.
R.2: Desacoplamiento de Permisos por Menú. La estructura de accesos, vistas funcionales y operaciones granulares (crear, modificar, eliminar, archivar) se delega por completo a las tablas relacionales hijas de asignación de menús, impidiendo lógica rígida o estática ligada a esta entidad.
R.3: Consistencia y Homologación de Códigos. Todo código de rol insertado o modificado en el sistema debe validarse obligatoriamente en mayúsculas sostenidas, con una longitud exacta de entre 2 y 5 caracteres alfanuméricos mediante restricciones CHECK nativas.
R.4: Unicidad Operativa del Catálogo. Se restringe la duplicidad semántica de los roles mediante índices únicos parciales sobre los campos codigo y rol para registros activos o históricos. Esto garantiza la coherencia en la asignación de perfiles sin interferir con registros eliminados lógicamente bajo el estado BORRADO.';

-- ================================================================================================

CREATE TABLE usuarios (
    usuario_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    rol_id BIGINT NOT NULL DEFAULT 1,
    login VARCHAR(10) NOT NULL,
    contrasena VARCHAR(500) NOT NULL,
    avatar VARCHAR(255) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_usuarios_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_usuarios_rol_id FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT chk_usuarios_estadoid CHECK (estado_id IN (1000, 1002)),
    CONSTRAINT chk_usuarios_login_notempty CHECK (TRIM(login) <> ''),
    CONSTRAINT chk_usuarios_login_mayusculas CHECK (login = UPPER(login)),
    CONSTRAINT chk_usuarios_login_minlength CHECK (LENGTH(TRIM(login)) >= 4),
    CONSTRAINT chk_usuarios_login_formato CHECK (login ~ '^[A-Z0-9._-]+$'),
    CONSTRAINT chk_usuarios_contrasena_notempty CHECK (TRIM(contrasena) <> ''),
    CONSTRAINT chk_usuarios_avatar_notempty CHECK (TRIM(avatar) <> '')
);
CREATE UNIQUE INDEX uix_usuarios_login_unique ON usuarios (login) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_usuarios_usuario_id_registro ON usuarios(usuario_id_registro);
CREATE INDEX idx_usuarios_usuario_id_actualizacion ON usuarios(usuario_id_actualizacion) WHERE usuario_id_actualizacion IS NOT NULL;
CREATE INDEX idx_usuarios_operacion_covering ON usuarios(usuario_id_registro, usuario_id_actualizacion, login) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_usuarios_rolid ON usuarios(rol_id);

COMMENT ON TABLE usuarios IS 'Reglas de la tabla - usuarios
R.0: La tabla usuarios gestiona las credenciales de acceso al sistema, vinculando a un trabajador con un rol específico. Su propósito es autenticar y autorizar a los operadores de la plataforma, controlando el inicio de sesión y, mediante el rol_id asociado, determinando los menús y acciones permitidas para cada usuario.
R.1: Restricción Estricta de Identidad (login). El identificador login debe registrarse obligatoriamente en mayúsculas sostenidas, con una longitud mínima de 4 caracteres. Se permiten únicamente letras, números, puntos (.) y guiones bajos (_), prohibiendo espacios o caracteres especiales mediante expresiones regulares nativas.
R.3: Criptografía Asimétrica Obligatoria. Toda contraseña debe ser procesada y almacenada mandatoriamente utilizando funciones de hash seguras de una sola vía (como Bcrypt con un factor de costo mínimo de 10 o Argon2) en el servidor backend, quedando estrictamente prohibido el almacenamiento en texto plano.
R.4: Inmutabilidad del Superusuario Técnico. Las credenciales de la cuenta con identificador ADMIN (vinculadas a la infraestructura central) están protegidas mediante restricciones lógicas en la capa de servicios, impidiendo su eliminación física o la transición de su estado operativo a BORRADO o HISTORICO.
R.5: Vinculación Directa de Perfil (Rol). La cuenta de usuario posee un rol estructural único asignado mediante la propiedad rol_id, el cual determina directamente su perfil operativo en el sistema. A través de este rol único, la plataforma valida de forma unívoca los permisos y opciones de menú habilitados para el operador, simplificando la arquitectura de autenticación.
R.6: Un usuario no se puede BORRAR solo se cambia a HISTORICO';

-- ================================================================================================

CREATE TABLE tablas (
    tabla_id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_tablas_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_tablas_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_tablas_nombre_formato CHECK (nombre = LOWER(TRIM(nombre)) AND nombre ~ '^[a-z][a-z0-9_]*$')
);
CREATE UNIQUE INDEX uix_tablas_nombre_unique ON tablas (nombre) WHERE estado_id = 1000;
CREATE INDEX idx_tablas_estado ON tablas (estado_id) WHERE estado_id = 1000;

COMMENT ON TABLE tablas IS 'Reglas de la tabla - tablas
R.0: La tabla tablas define los nombres de las tablas que pertenecen a la base de datos del sistema.';

-- ================================================================================================

CREATE TABLE sucesos (
    suceso_id INT PRIMARY KEY,
    tabla_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(15) NOT NULL,
    suceso VARCHAR(30) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_sucesos_tabla FOREIGN KEY (tabla_id) REFERENCES tablas(tabla_id),
    CONSTRAINT chk_suceso_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_sucesos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_sucesos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_sucesos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_sucesos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_sucesos_suceso_not_empty CHECK (TRIM(suceso) <> ''),
    CONSTRAINT chk_sucesos_suceso_minlength CHECK (LENGTH(TRIM(suceso)) >= 3),
    CONSTRAINT chk_sucesos_suceso_mayusculas CHECK (suceso = UPPER(suceso)),
    CONSTRAINT chk_sucesos_descripcion_notempty CHECK (TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_sucesos_codigo_unique ON sucesos (codigo) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_sucesos_suceso_unique ON sucesos (suceso) WHERE estado_id = 1000;

COMMENT ON TABLE sucesos IS 'Reglas de la tabla - sucesos
R.0: La tabla sucesos define los nombres de los eventos.';

-- ================================================================================================

CREATE TABLE roles_permisos_tablas (
    rol_permiso_tabla_id BIGSERIAL PRIMARY KEY,
    rol_id BIGINT NOT NULL DEFAULT 1,
    tabla_id BIGINT NOT NULL DEFAULT 1,
    leer SMALLINT NOT NULL DEFAULT 0,
    crear SMALLINT NOT NULL DEFAULT 0,
    editar SMALLINT NOT NULL DEFAULT 0,
    eliminar SMALLINT NOT NULL DEFAULT 0,
    anular SMALLINT NOT NULL DEFAULT 0,
    archivar SMALLINT NOT NULL DEFAULT 0,
    desarchivar SMALLINT NOT NULL DEFAULT 0,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_rpt_rol FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT fk_rpt_tabla FOREIGN KEY (tabla_id) REFERENCES tablas(tabla_id),
    CONSTRAINT chk_rpt_estado CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_rpt_leer CHECK (leer IN (0, 1)),
    CONSTRAINT chk_rpt_crear CHECK (crear IN (0, 1)),
    CONSTRAINT chk_rpt_editar CHECK (editar IN (0, 1)),
    CONSTRAINT chk_rpt_eliminar CHECK (eliminar IN (0, 1)),
    CONSTRAINT chk_rpt_anular CHECK (anular IN (0, 1)),
    CONSTRAINT chk_rpt_archivar CHECK (archivar IN (0, 1)),
    CONSTRAINT chk_rpt_desarchivar CHECK (desarchivar IN (0, 1)),
    CONSTRAINT chk_rpt_no_vacio CHECK (leer = 1 OR crear = 1 OR editar = 1 OR eliminar = 1 OR anular = 1 OR archivar = 1 OR desarchivar = 1)
);
CREATE UNIQUE INDEX uix_rpt_unique ON roles_permisos_tablas (rol_id, tabla_id) WHERE estado_id = 1000;

-- ================================================================================================
 
CREATE TABLE roles_permisos_sucesos (
    rol_permiso_suceso_id BIGSERIAL PRIMARY KEY,
    rol_permiso_tabla_id BIGINT NOT NULL DEFAULT 1,
    suceso_id INT NOT NULL DEFAULT 1,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_rps_permiso_id FOREIGN KEY (rol_permiso_tabla_id) REFERENCES roles_permisos_tablas(rol_permiso_tabla_id),
    CONSTRAINT fk_rps_suceso_id FOREIGN KEY (suceso_id) REFERENCES sucesos(suceso_id),
    CONSTRAINT chk_rps_estado CHECK (estado_id IN (1000, 1001))
);
CREATE UNIQUE INDEX uix_rps_unique ON roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id) WHERE estado_id = 1000;

-- ================================================================================================
 
CREATE TABLE menus (
    menu_id BIGSERIAL PRIMARY KEY,
    menu_padre_id BIGINT NULL,
    titulo VARCHAR(150) NOT NULL,
    icono VARCHAR(50) NULL,
    url VARCHAR(255) NULL,
    orden SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_menus_menu_padre_id FOREIGN KEY (menu_padre_id) REFERENCES menus(menu_id),
    CONSTRAINT chk_menus_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_menus_titulo_notempty CHECK (TRIM(titulo) <> ''),
    CONSTRAINT chk_menus_titulo_minlength CHECK (LENGTH(TRIM(titulo)) >= 3),
    CONSTRAINT chk_menus_icono_notempty CHECK (icono IS NULL OR TRIM(icono) <> ''),
    CONSTRAINT chk_menus_url_notempty CHECK (url IS NULL OR TRIM(url) <> ''),
    CONSTRAINT chk_menus_orden CHECK (orden >= 0)
);
CREATE UNIQUE INDEX uix_menus_varios_unique ON menus (menu_padre_id, titulo, orden) WHERE estado_id = 1000;
CREATE INDEX idx_menus_orden ON menus (orden ASC) WHERE estado_id = 1000;

COMMENT ON TABLE menus IS 'Reglas de la tabla - menus
R.0: La tabla menus define la estructura jerárquica y navegacional de la interfaz de usuario, agrupando las funcionalidades del sistema en un árbol de navegación dinámico. Su propósito es construir el menú lateral de la aplicación para cada usuario, basándose en la asignación de permisos de la tabla roles_menus, y de esta manera, presentar únicamente las opciones correspondientes al rol del usuario. Se conecta de forma autorreferencial (menu_padre_id) para formar la jerarquía y con la tabla roles_menus.
R.1: Renderizado del Menú Lateral: El frontend procesará recursivamente la respuesta filtrando o ignorando el menu_id = 1. Aquellos registros cuyo menu_padre_id seja NULL o igual a 1 se tratarán como secciones principales o cabeceras de grupo en el Sidebar de PrimeVue.
R.2: Comportamiento de Enrutamiento: Si el campo url es NULL, el componente actuará exclusivamente como un contenedor colapsable (deshabilitando el enrutador y manejando el estado de expansión de la interfaz).
R.3: Tratamiento del Registro Comodín: El registro con menu_id = 1 representa el nodo raíz ficticio del sistema. No es visible en la interfaz operativa. El backend bloqueará cualquier intento de modificación o eliminación de este registro para salvaguardar la integridad referencial.
R.4: Ordenación Dinámica: Las consultas de menús deben ordenarse por el nivel jerárquico y luego por el campo orden. El frontend respetará estrictamente este índice numérico para la disposición visual de los accesos.';

-- ================================================================================================

CREATE TABLE roles_menus (
    rol_menu_id BIGSERIAL PRIMARY KEY,
    rol_id BIGINT NOT NULL DEFAULT 1,
    menu_id BIGINT NOT NULL DEFAULT 1,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_rolesmenus_rol_id FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT fk_rolesmenus_menu_id FOREIGN KEY (menu_id) REFERENCES menus(menu_id),
	CONSTRAINT chk_rolesmenus_estadoid CHECK (estado_id IN (1000, 1001))
);
CREATE UNIQUE INDEX uix_rolesmenus_varios_unique ON roles_menus (rol_id, menu_id) WHERE estado_id = 1000;

COMMENT ON TABLE roles_menus IS 'Reglas de la tabla - roles_menus
R.0: La tabla roles_menus actúa ';

-- ================================================================================================

CREATE TABLE inventarios_fisicos (
    inventario_fisico_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
	ubicacion_id BIGINT NOT NULL DEFAULT 1,
    fecha_conteo DATE NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NULL,
    trabajador_responsable_id BIGINT NOT NULL DEFAULT 1,
    trabajador_supervisor_id BIGINT NOT NULL DEFAULT 1,
	observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_inventariosfisicos_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
    CONSTRAINT fk_inventariosfisicos_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_inventariosfisicos_trabajador_resp FOREIGN KEY (trabajador_responsable_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_inventariosfisicos_trabajador_sup FOREIGN KEY (trabajador_supervisor_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_inventariosfisicos_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_inventariosfisicos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_inventariosfisicos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
	CONSTRAINT chk_inventariosfisicos_fechaconteo_inicio CHECK (fecha_inicio >= fecha_conteo)
);
CREATE UNIQUE INDEX idx_inventariosfisicos_activo_unique ON inventarios_fisicos (almacen_id, ubicacion_id, fecha_conteo, trabajador_responsable_id, trabajador_supervisor_id) WHERE estado_id = 1000;
CREATE INDEX idx_inventariosfisicos_trabajadorsupid ON inventarios_fisicos(trabajador_supervisor_id);
CREATE INDEX idx_inventariosfisicos_trabajadorrespid ON inventarios_fisicos(trabajador_responsable_id);

COMMENT ON TABLE inventarios_fisicos IS 'Reglas de la tabla - inventarios_fisicos
R.0: La tabla inventarios_fisicos gestiona las cabeceras de los procesos de conteo físico, conciliaciones de inventario y auditorías de stock dentro de una sucursal o ubicación específica.';

-- ================================================================================================

CREATE TABLE clientes (
    cliente_id BIGSERIAL PRIMARY KEY,
    tipo_cliente_id SMALLINT NOT NULL DEFAULT 1150,     -- 1150=NATURAL, 1151=JURIDICA
    cliente VARCHAR(100) NOT NULL,
    nit VARCHAR(20) NULL,
	razon_social VARCHAR(150) NULL,
    documento VARCHAR(30) NOT NULL,
    documento_complemento VARCHAR(10) NULL,
    tipo_documento_id SMALLINT NOT NULL DEFAULT 2200,   -- 2200=CEDULA_IDENTIDAD, 2201=CEDULA_IDENTIDAD_EXTRANJERO, 2202=PASAPORTE, 2203=OTRO, 2204=NIT
    direccion VARCHAR(255) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    banco_base_id BIGINT NOT NULL DEFAULT 1,
    numero_cuenta VARCHAR(50) NULL,
    habilitado_ventas SMALLINT NOT NULL DEFAULT 1,
    limite_credito DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_clientes_banco_base_id FOREIGN KEY (banco_base_id) REFERENCES bancos(banco_id),
    CONSTRAINT chk_clientes_tipoclienteid CHECK (tipo_cliente_id IN (1150, 1151)),
    CONSTRAINT chk_clientes_tipodocumentoid CHECK (tipo_documento_id IN (2200, 2201, 2202, 2203, 2204)),
    CONSTRAINT chk_clientes_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_clientes_cliente_notempty CHECK (TRIM(cliente) <> ''),
    CONSTRAINT chk_clientes_cliente_minlength CHECK (LENGTH(TRIM(cliente)) >= 3),
    CONSTRAINT chk_clientes_nit_notempty CHECK (nit IS NULL OR TRIM(nit) <> ''),
    CONSTRAINT chk_clientes_razonsocial_notempty CHECK (razon_social IS NULL OR TRIM(razon_social) <> ''),
    CONSTRAINT chk_clientes_documento_notempty CHECK (TRIM(documento) <> ''),
    CONSTRAINT chk_clientes_documento_minlength CHECK (LENGTH(TRIM(documento)) >= 1),
    CONSTRAINT chk_clientes_documentocomplemento_notempty CHECK (documento_complemento IS NULL OR TRIM(documento_complemento) <> ''),
    CONSTRAINT chk_clientes_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_clientes_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_clientes_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_clientes_numerocuenta_notempty CHECK (numero_cuenta IS NULL OR TRIM(numero_cuenta) <> ''),
    CONSTRAINT chk_clientes_habilitadoventas CHECK (habilitado_ventas IN (0, 1)),
    CONSTRAINT chk_clientes_limitecredito CHECK (limite_credito >= 0.00),
    CONSTRAINT chk_clientes_coherencia CHECK (
        (limite_credito = 0.00) OR
        (limite_credito > 0.00 AND habilitado_ventas = 1)
    )
);
CREATE UNIQUE INDEX uix_clientes_tipodocumentoid_documento_unique ON clientes (tipo_documento_id, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NULL;
CREATE UNIQUE INDEX uix_clientes_varios_unique ON clientes (tipo_documento_id, documento_complemento, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NOT NULL;
CREATE INDEX idx_clientes_documento_cliente_busqueda ON clientes (documento, cliente) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_clientes_bancoid ON clientes (banco_base_id);

COMMENT ON TABLE clientes IS 'Reglas de la tabla - clientes
R.0: La tabla clientes almacena el registro maestro de los compradores, ya sean trabajadores naturales o jurídicas, y es una entidad crítica para los procesos de venta y facturación. Su propósito es proporcionar los datos fiscales y de contacto necesarios para la emisión de comprobantes electrónicos, la aplicación de descuentos por volumen y el análisis de comportamiento de compra para los módulos de inteligencia de negocio.
R.1: Tratamiento del Documento Genérico: El registro con cliente_id = 1 y documento ''0'' actúa como el cliente comodín universal (exclusivo para ventas de mostrador sin nominación de factura o "Sin Nombre"). Este registro está exento de las restricciones del índice de unicidad parcial para permitir operaciones de venta directa rápidas y masivas.
R.2: Control de Complemento de Identidad: El campo documento_complemento es mandatorio en la arquitectura de persistencia para clientes de tipo Cédula de Identidad (CI) que compartan la misma numeración base pero posean sufijos alfanuméricos de desambiguación emitidos por el ente de identificación estatal (ej. ''1A'', ''1B''). El frontend debe inicializar este campo como un string vacío '' por defecto para evitar colisiones involuntarias de nulidad.
R.3: Desacoplamiento de Entidad Bancaria para Clientes Corporativos/Aseguradoras: Los campos banco_id (apuntando por defecto a 1 - ''NINGUNO'') y numero_cuenta son obligatorios únicamente cuando se gestionan clientes de tipo institucional, convenios corporativos o aseguradoras de salud. Permiten registrar de forma nativa el canal de origen para transferencias interbancarias automáticas cuando se liquidan cuentas por cobrar o proformas consolidadas a fin de mes.
R.4: Validación de Contacto Digital (Email) para Factura en Línea: Aunque el campo email es estructuralmente opcional (NULL) para no bloquear la venta rápida en caja, el sistema de facturación electrónica del SIN exige el envío del XML/PDF al cliente. El backend deben exigir un correo electrónico válido si el cliente opta por la facturación en línea bajo la modalidad Nominada, sirviendo como canal único de notificación para la entrega del documento fiscal digitalizado.
R.5: Control de Habilitación Comercial (habilitado_ventas): El campo habilitado_ventas determina si el cliente puede realizar transacciones comerciales activas en el sistema. Los valores permitidos son estrictamente 0 (NO) y 1 (SI). Si un cliente posee el valor 0, cualquier intento de procesar una nueva venta o emisión de proforma hacia este debe ser bloqueado por la lógica de negocio y restricciones operativas.
R.6: Autorización y Límite de Crédito (limite_credito): El campo limite_credito define el monto máximo monetario acumulado que se le permite adeudar al cliente en operaciones a crédito. Para que a un cliente se le pueda asignar un límite de crédito mayor a 0.00, obligatoriamente su campo habilitado_ventas debe estar configurado en 1 (SI) y el sistema debe validar que no posea bloqueos administrativos vigentes. Un límite de 0.00 indica que opera estrictamente al contado.';

-- ================================================================================================
--AQUI MAYA 
CREATE TABLE categorias (
    categoria_id BIGSERIAL PRIMARY KEY,
	empresa_nit_id BIGINT NOT NULL DEFAULT 1,
    categoria_padre_id BIGINT NULL,
    categoria VARCHAR(100) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(500) NULL,
    nivel SMALLINT NOT NULL DEFAULT 1,
    orden SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_categorias_categoria_padre_id FOREIGN KEY (categoria_padre_id) REFERENCES categorias(categoria_id),
    CONSTRAINT chk_categorias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_categorias_categoria_notempty CHECK (TRIM(categoria) <> ''),
    CONSTRAINT chk_categorias_categoria_minlength CHECK (LENGTH(TRIM(categoria)) >= 3),
    CONSTRAINT chk_categorias_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_categorias_codigo_length CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_categorias_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_categorias_codigo_format CHECK (codigo ~ '^[A-Z0-9-]+$'),
    CONSTRAINT chk_categorias_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_categorias_nivel CHECK (nivel >= 1),
    CONSTRAINT chk_categorias_orden CHECK (orden >= 0)
);
CREATE UNIQUE INDEX uix_categorias_varios_unique ON categorias (categoria_padre_id, categoria) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_categorias_codigo_unique ON categorias (codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE categorias IS 'Reglas de la tabla - categorias
R.0: La tabla categorias implementa una taxonomía jerárquica para clasificar los productos, agrupándolos lógicamente para su organización en el catálogo. Su propósito es facilitar la navegación, búsqueda y filtrado de productos en la interfaz de usuario, así como servir como criterio de segmentación para reportes de ventas, inventario y la aplicación de promociones. Se conecta de forma autorreferencial y con la tabla productos.
R.1: El campo codigo debe ser de exactamente 3 caracteres alfanuméricos, sin espacios, y debe almacenarse en mayúsculas pero puede tener guiones (-).';

-- ================================================================================================

CREATE TABLE laboratorios (
    laboratorio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    laboratorio VARCHAR(200) NOT NULL,
    nit VARCHAR(30) NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    web VARCHAR(200) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_laboratorios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_laboratorios_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_laboratorios_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_laboratorios_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_laboratorios_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_laboratorios_laboratorio_notempty CHECK (TRIM(laboratorio) <> ''),
    CONSTRAINT chk_laboratorios_laboratorio_minlength CHECK (LENGTH(TRIM(laboratorio)) >= 3),
    CONSTRAINT chk_laboratorios_nit_notempty CHECK (nit IS NULL OR TRIM(nit) <> ''),
    CONSTRAINT chk_laboratorios_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_laboratorios_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_laboratorios_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_laboratorios_web_notempty CHECK (web IS NULL OR TRIM(web) <> '')
);
CREATE UNIQUE INDEX uix_laboratorios_codigo_unique ON laboratorios (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_laboratorios_laboratorio_unique ON laboratorios (laboratorio) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_laboratorios_nit_unique ON laboratorios (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND nit <> '';

COMMENT ON TABLE laboratorios IS 'Reglas de la tabla - laboratorios
R.0: La tabla laboratorios constituye el catálogo de fabricantes, proveedores o marcas de los productos farmacéuticos y de venta libre. Su función es gestionar la trazabilidad desde el origen del producto, facilitando la organización del catálogo, la aplicación de promociones por marca y la generación de reportes de compras y rentabilidad por laboratorio.
R.1: El registro predeterminado (laboratorio_id = 1, ''NINGUNO'') actúa como la entidad genérica del sistema para la creación obligatoria de productos magistrales, fórmulas propias o artículos de soporte que no correspondan a un fabricante farmacéutico comercial.';

-- ================================================================================================

CREATE TABLE formas (
    forma_id BIGSERIAL PRIMARY KEY,
    forma_farmaceutica VARCHAR(100) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_formas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_formas_formafarmaceutica_notempty CHECK (TRIM(forma_farmaceutica) <> ''),
    CONSTRAINT chk_formas_formafarmaceutica_minlength CHECK (LENGTH(TRIM(forma_farmaceutica)) >= 3),
    CONSTRAINT chk_formas_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_formas_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_formas_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_formas_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_formas_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_formas_codigo_unique ON formas (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_formas_formafarmaceutica_unique ON formas (forma_farmaceutica) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE formas IS 'Reglas de la tabla - formas
R.0: La tabla formas define las formas farmacéuticas de los productos (ej. tableta, jarabe, inyectable), describiendo la presentación física del medicamento. Su propósito es clasificar los productos para su correcta identificación, gestión y dispensación, así como para servir como un filtro de búsqueda avanzada y control de inventario.
R.1: El campo codigo debe ser validado por el Frontend para admitir únicamente caracteres alfanuméricos (A-Z, 0-9), restringiendo caracteres especiales, tildes o la letra "Ñ".
R.2: Al registrar una nueva forma farmacéutica, el Frontend debe convertir automáticamente la entrada a mayúsculas fijas (UPPERCASE) antes de realizar el envío al servicio API de la aplicación.
R.3: El campo descripcion se expone en la interfaz como un cuadro de texto multilínea opcional para documentar observaciones de almacenamiento o manipulación de la forma física, limitando su longitud a 500 caracteres.';

-- ================================================================================================

CREATE TABLE presentaciones (
    presentacion_id BIGSERIAL PRIMARY KEY,
    unidad_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(60) NOT NULL,
    presentacion VARCHAR(500) NOT NULL,
    cantidad_unidades INTEGER NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_presentaciones_unidad_id FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
    CONSTRAINT chk_presentaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_presentaciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_presentaciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_presentaciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_presentaciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_presentaciones_presentacion_notempty CHECK (TRIM(presentacion) <> ''),
    CONSTRAINT chk_presentaciones_presentacion_minlength CHECK (LENGTH(TRIM(presentacion)) >= 3),
    CONSTRAINT chk_presentaciones_cantidadunidades CHECK (cantidad_unidades > 0),
    CONSTRAINT chk_presentaciones_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_presentaciones_codigo_unique ON presentaciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_presentaciones_presentacion_unique ON presentaciones (presentacion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE presentaciones IS 'Reglas de la tabla - presentaciones
R.0: La tabla presentaciones gestiona la forma comercial de venta de un producto, como una caja con 10 tabletas o un frasco de 100 ml. Su propósito es estandarizar cómo se comercializa y se mide el inventario del producto, definiendo la relación entre la unidad de venta y la unidad de base (unidad de medida). Es un vínculo fundamental para calcular el costo de venta y la gestión de precios, conectándose directamente con las tablas productos y kardex_productos.
R.1: El código de presentación no puede contener espacios y debe ser validado desde el cliente UI para mantener el patrón de la letra ''X'' seguida del número de unidades equivalentes.';

-- ================================================================================================

CREATE TABLE concentraciones (
    concentracion_id BIGSERIAL PRIMARY KEY,
    unidad_base_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(60) NOT NULL,
    concentracion VARCHAR(100) NOT NULL,
    valor_numerico DECIMAL(12,2) NULL,
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_concentraciones_unidad_base_id FOREIGN KEY (unidad_base_id) REFERENCES unidades(unidad_id),
    CONSTRAINT chk_concentraciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_concentraciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_concentraciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_concentraciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_concentraciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_.-]+$'),
    CONSTRAINT chk_concentraciones_concentracion_notempty CHECK (TRIM(concentracion) <> ''),
    CONSTRAINT chk_concentraciones_concentracion_minlength CHECK (LENGTH(TRIM(concentracion)) >= 2),
    CONSTRAINT chk_concentraciones_valornumerico CHECK (valor_numerico IS NULL OR valor_numerico >= 0),
    CONSTRAINT chk_concentraciones_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_concentraciones_codigo_unique ON concentraciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_concentraciones_concentracion_unique ON concentraciones (concentracion) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_concentraciones_unidadbaseid ON concentraciones(unidad_base_id);

COMMENT ON TABLE concentraciones IS 'Reglas de la tabla - concentraciones
R.0: La tabla concentraciones define la potencia de los principios activos en un producto (ej. 500mg, 100mg/ml), describiendo la cantidad de fármaco por unidad de medida. Su propósito es identificar y diferenciar productos similares para evitar confusiones médicas y garantizar la precisión en la dispensación, siendo un atributo esencial en el catálogo de productos.
R.1: El código de la concentración no debe incluir espacios en blanco y el cliente UI debe validar obligatoriamente que concatene el valor numérico entero o decimal con la abreviatura de la unidad de medida en mayúsculas (ej. ''500MG'', ''0.5MG'').
R.2: Cuando el usuario seleccione la opción predeterminada con concentracion_id = 1 (''NINGUNA'') en el formulario de productos, el sistema en el cliente debe deshabilitar y limpiar automáticamente el campo correspondiente al valor numérico para consistencia de los datos.
R.3: Las modificaciones sobre las concentraciones activas recalculan dinámicamente las etiquetas descriptivas en la interfaz de usuario, pero el backend impedirá cualquier alteración física o lógica sobre el id 1 debido a su condición estricta de constante de control.';

-- ================================================================================================

CREATE TABLE vias (
    via_id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(500) NULL,
    requiere_ayuno SMALLINT NOT NULL DEFAULT 0,
    tiempo_efecto_minutos SMALLINT NULL,
    precauciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_vias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_vias_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_vias_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 2),
    CONSTRAINT chk_vias_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_vias_requiereayuno CHECK (requiere_ayuno IN (0, 1)),
    CONSTRAINT chk_vias_tiempoefectominutos CHECK (tiempo_efecto_minutos IS NULL OR tiempo_efecto_minutos > 0),
    CONSTRAINT chk_vias_precauciones_notempty CHECK (precauciones IS NULL OR TRIM(precauciones) <> '')
);
CREATE UNIQUE INDEX uix_vias_nombre_unique ON vias (nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE vias IS 'Reglas de la tabla - vias
R.0: La tabla vias establece las diferentes vías de administración de los medicamentos, como oral o tópica, y es crítica para la seguridad del paciente. Su propósito es almacenar información adicional sobre la administración (ayuno, tiempo de efecto) y asociarla a los productos, permitiendo al farmacéutico ofrecer la información correcta y contraindicaciones relevantes. Se conecta a través de productos_vias con la tabla productos.
R.1: requiere_ayuno: 0=No requiere ayuno, 1=Requiere ayuno.
R.2: tiempo_efecto_minutos indica el tiempo estimado en minutos para que el medicamento haga efecto.
R.3: NINGUNO (via_id = 1) es un registro comodín para uso en otros módulos.';

-- ================================================================================================

CREATE TABLE rangos_edad (
    rango_edad_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    rango VARCHAR(100) NOT NULL,
    edad_minima_meses SMALLINT NULL,
    edad_maxima_meses SMALLINT NULL,
    descripcion VARCHAR(3000) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_rangosedad_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_rangosedad_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_rangosedad_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_rangosedad_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_rangosedad_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_rangosedad_rango_notempty CHECK (TRIM(rango) <> ''),
    CONSTRAINT chk_rangosedad_rango_minlength CHECK (LENGTH(TRIM(rango)) >= 2),
    CONSTRAINT chk_rangosedad_edadminimameses CHECK (edad_minima_meses IS NULL OR edad_minima_meses >= 0),
    CONSTRAINT chk_rangosedad_edadmaximameses CHECK (edad_maxima_meses IS NULL OR edad_maxima_meses >= 0),
    CONSTRAINT chk_rangosedad_limitesedad CHECK (edad_minima_meses IS NULL OR edad_maxima_meses IS NULL OR edad_maxima_meses >= edad_minima_meses),
    CONSTRAINT chk_rangosedad_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_rangosedad_codigo_unique ON rangos_edad (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_rangosedad_rango_unique ON rangos_edad (rango) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE rangos_edad IS 'Reglas de la tabla - rangos_edad
R.0: La tabla rangos_edad define grupos etarios de pacientes (ej. lactante, adulto, geriátrico) para establecer la seguridad en la dispensación de medicamentos. Su propósito es clasificar a los pacientes y vincularlos con productos para gestionar contraindicaciones y dosificaciones recomendadas por edad, mejorando la calidad de la atención farmacéutica. Se conecta a través de productos_rangos_edad con la tabla productos.
R.1: La tabla rangos_edad clasifica los grupos etarios de pacientes para la dispensación de medicamentos, permitiendo asociar productos a rangos específicos para control de dosis y contraindicaciones.
R.2: edad_minima_meses y edad_maxima_meses definen el intervalo en meses del rango etario. Los valores son inclusivos (edad >= mínima y edad <= máxima). Si el valor es NULL, significa que el rango no tiene límite inferior o superior (ej. Adulto Mayor 780+ meses).
R.3: El registro con rango_edad_id = 1 (''NINGUNO'') actúa como el registro predeterminado para productos que no tienen un rango etario específico.
R.4: Los códigos (``codigo``) y nombres (``rango``) deben ser únicos para registros activos o históricos, garantizando que no existan duplicados semánticos en el catálogo.
R.5: El frontend debe utilizar esta tabla para filtrar y mostrar únicamente los medicamentos o productos que son seguros para la edad del paciente, ocultando aquellos cuyo rango etario no coincida.
R.6: Al asignar un producto a un rango etario, el sistema debe validar que el rango esté activo (estado_id = 1000) y que los límites de edad sean consistentes (edad_maxima_meses >= edad_minima_meses si ambos no son NULL).';

-- ================================================================================================

CREATE TABLE marcas (
    marca_id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_marcas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_marcas_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_marcas_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 2),
    CONSTRAINT chk_marcas_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_marcas_nombre_unique ON marcas (nombre) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_marcas_nombre_trgm ON marcas USING GIN (nombre gin_trgm_ops) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE marcas IS 'Reglas de la tabla - marcas
R.0: La tabla marcas almacena los fabricantes, casas editoriales (para libros) o marcas comerciales de los productos no estrictamente farmacéuticos o de consumo general que se comercializan en el sistema.
R.1: El registro con marca_id = 1 y nombre = ''NINGUNA'' es el registro predeterminado para artículos que no requieren especificar marca, se mantiene en estado HISTORICO y no puede modificarse ni eliminarse.';

-- ================================================================================================

CREATE TABLE productos (
    producto_id BIGSERIAL PRIMARY KEY,
    categoria_id BIGINT NOT NULL DEFAULT 1,
    laboratorio_id BIGINT NOT NULL DEFAULT 1,
    marca_id BIGINT NOT NULL DEFAULT 1,
    forma_id BIGINT NOT NULL DEFAULT 1,
    presentacion_id BIGINT NOT NULL DEFAULT 1,
    concentracion_id BIGINT NOT NULL DEFAULT 1,
    unidad_venta_id BIGINT NOT NULL DEFAULT 1,
    tipo_almacen_id SMALLINT NOT NULL DEFAULT 1700,        -- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    codigo VARCHAR(100) NOT NULL,
    codigo_barras VARCHAR(100) NULL,
    sku VARCHAR(60) NULL,
    isbn VARCHAR(30) NULL,
	serie VARCHAR(60) NULL,
	modelo VARCHAR(150) NULL,
    nombre VARCHAR(600) NOT NULL,
    nombre_generico VARCHAR(600) NULL,
    pcompra DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    p_factor_venta DECIMAL(12,2) NOT NULL DEFAULT 1.50,
    p_factor_facturacion DECIMAL(12,2) NOT NULL DEFAULT 1.19,
    pventa DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    pventaf DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_minimo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_maximo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    punto_reorden DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    requiere_receta SMALLINT NOT NULL DEFAULT 0,
    controlado SMALLINT NOT NULL DEFAULT 0,
    tiene_registro_sanitario SMALLINT NOT NULL DEFAULT 0,
    descripcion VARCHAR(3000) NULL,
    observacion VARCHAR(3000) NULL,
    foto1 VARCHAR(255) NULL,
    foto2 VARCHAR(255) NULL,
    foto3 VARCHAR(255) NULL,
    criticidad_medica_id SMALLINT DEFAULT 4150,         -- 4150=NORMAL, 4151=CRITICO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_productos_categoria_id FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id),
    CONSTRAINT fk_productos_laboratorio_id FOREIGN KEY (laboratorio_id) REFERENCES laboratorios(laboratorio_id),
    CONSTRAINT fk_productos_marca_id FOREIGN KEY (marca_id) REFERENCES marcas(marca_id),
    CONSTRAINT fk_productos_forma_id FOREIGN KEY (forma_id) REFERENCES formas(forma_id),
    CONSTRAINT fk_productos_presentacion_id FOREIGN KEY (presentacion_id) REFERENCES presentaciones(presentacion_id),
    CONSTRAINT fk_productos_concentracion_id FOREIGN KEY (concentracion_id) REFERENCES concentraciones(concentracion_id),
    CONSTRAINT fk_productos_unidad_venta_id FOREIGN KEY (unidad_venta_id) REFERENCES unidades(unidad_id),
    CONSTRAINT chk_productos_tipoalmacenid CHECK (tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)),
    CONSTRAINT chk_productos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_productos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_productos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_productos_codigo CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_productos_codigobarras_notempty CHECK (codigo_barras IS NULL OR TRIM(codigo_barras) <> ''),
    CONSTRAINT chk_productos_sku_notempty CHECK (sku IS NULL OR TRIM(sku) <> ''),
    CONSTRAINT chk_productos_isbn_notempty CHECK (isbn IS NULL OR TRIM(isbn) <> ''),
    CONSTRAINT chk_productos_modelo_notempty CHECK (modelo IS NULL OR TRIM(modelo) <> ''),
    CONSTRAINT chk_productos_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_productos_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_productos_nombregenerico_notempty CHECK (nombre_generico IS NULL OR TRIM(nombre_generico) <> ''),
    CONSTRAINT chk_productos_pfactorventa CHECK (p_factor_venta > 1),
    CONSTRAINT chk_productos_pfactorfacturacion CHECK (p_factor_facturacion > 1),
    CONSTRAINT chk_productos_pcompra CHECK (pcompra >= 0),
    CONSTRAINT chk_productos_pventa CHECK (pventa >= 0),
    CONSTRAINT chk_productos_pventaf CHECK (pventaf >= 0),
    CONSTRAINT chk_productos_precios CHECK (
        (producto_id = 1 AND pcompra = 0 AND pventa = 0 AND pventaf = 0) OR
        (pcompra >= 0 AND pventa >= 0 AND pventaf >= 0)
    ),
    CONSTRAINT chk_productos_stockminimo CHECK (stock_minimo >= 0),
    CONSTRAINT chk_productos_stockmaximo CHECK (stock_maximo >= 0),
    CONSTRAINT chk_productos_stockmaximo_stockminimo CHECK (stock_maximo >= stock_minimo),
    CONSTRAINT chk_productos_puntoreorden CHECK (punto_reorden >= 0),
    CONSTRAINT chk_productos_requierereceta CHECK (requiere_receta IN (0, 1)),
    CONSTRAINT chk_productos_controlado CHECK (controlado IN (0, 1)),
    CONSTRAINT chk_productos_tieneregistrosanitario CHECK (tiene_registro_sanitario IN (0, 1)),
    CONSTRAINT chk_productos_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_productos_observacion_notempty CHECK (observacion IS NULL OR TRIM(observacion) <> ''),
    CONSTRAINT chk_productos_foto1_notempty CHECK (foto1 IS NULL OR TRIM(foto1) <> ''),
    CONSTRAINT chk_productos_foto2_notempty CHECK (foto2 IS NULL OR TRIM(foto2) <> ''),
    CONSTRAINT chk_productos_foto3_notempty CHECK (foto3 IS NULL OR TRIM(foto3) <> ''),
    CONSTRAINT chk_productos_criticidadmedicaid CHECK (criticidad_medica_id IS NULL OR criticidad_medica_id IN (4150, 4151))
);
CREATE UNIQUE INDEX uix_productos_codigo_unique ON productos (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_productos_codigobarras_unique ON productos (codigo_barras) WHERE codigo_barras IS NOT NULL AND estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_productos_isbn_unique ON productos (isbn) WHERE isbn IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_productos_nombre_trgm ON productos USING GIN (nombre gin_trgm_ops) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productos_nombregenericotrgm ON productos USING GIN (nombre_generico gin_trgm_ops) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productos_varios ON productos (categoria_id, laboratorio_id, marca_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productos_tipoalmacen ON productos (tipo_almacen_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_presentaciones_unidadid ON presentaciones(unidad_id);
CREATE INDEX idx_productos_unidadventaid ON productos(unidad_venta_id);
CREATE INDEX idx_productos_formaid ON productos(forma_id);
CREATE INDEX idx_productos_presentacionid ON productos(presentacion_id);
CREATE INDEX idx_productos_concentracionid ON productos(concentracion_id);

COMMENT ON TABLE productos IS 'Reglas de la tabla - productos
R.0: La tabla productos constituye el catálogo maestro de bienes y artículos comercializables en el sistema, integrando atributos farmacológicos, comerciales, de almacenamiento y de control normativo. Su propósito es centralizar la ficha técnica de cada producto para la gestión de inventarios, compras, ventas y facturación.
R.1: Identificadores Únicos y Códigos. El campo codigo es obligatorio y único por producto activo/histórico. Los campos codigo_barras, sku e isbn son opcionales pero deben ser estrictamente únicos en el sistema cuando están presentes.
R.2: Gestión de Precios y Factores. Los precios de venta (pventa y pventaf) se calculan típicamente multiplicando el precio de compra (pcompra) por sus respectivos factores de incremento (p_factor_venta y p_factor_facturacion), aunque el usuario puede modificar directamente los precios finales según las políticas comerciales.
R.3: Control de Existencias y Reorden. Los niveles de stock (stock_minimo, stock_maximo, punto_reorden) establecen los límites operativos para la reposición automática y el control de alertas de inventario, cumpliendo la regla estricta de que el stock máximo debe ser mayor o igual al mínimo.
R.4: Restricciones de Comercialización y Seguridad. Los campos requiere_receta, controlado y tiene_registro_sanitario operan como indicadores booleanos (0 o 1) que condicionan la venta de medicamentos y productos regulados según normativas sanitarias locales.';

-- ================================================================================================

CREATE TABLE productos_vias (
    producto_via_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    via_id BIGINT NOT NULL DEFAULT 1,
    es_principal SMALLINT NOT NULL DEFAULT 1,
    observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_productosvias_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosvias_via_id FOREIGN KEY (via_id) REFERENCES vias(via_id),
    CONSTRAINT chk_productosvias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosvias_esprincipal CHECK (es_principal IN (0, 1)),
    CONSTRAINT chk_productosvias_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> '')
);
CREATE UNIQUE INDEX uix_productosvias_varios_unique ON productos_vias (producto_id, via_id) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_productosvias_principal_unique ON productos_vias (producto_id) WHERE es_principal = 1 AND estado_id = 1000;
CREATE INDEX idx_productosvias_viaid ON productos_vias (via_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_vias IS 'Reglas de la tabla - productos_vias
R.0: La tabla productos_vias es una relación polimórfica que permite asociar múltiples vías de administración a un mismo producto, identificando una de ellas como principal. Su propósito es capturar la flexibilidad de algunos medicamentos que pueden ser administrados por diferentes vías, manteniendo la integridad referencial al mismo tiempo que se impone la regla de negocio de una única vía principal por producto.
R.1: es_principal (1 = Sí, 0 = No) determina la vía de administración primaria del producto. El backend valida que exista exactamente un registro con es_principal = 1 por producto en estado ACTIVO.
R.2: Múltiples Vías por Producto. La interfaz de usuario debe permitir asociar más de una vía de administración a un mismo producto_id para dar soporte a medicamentos que pueden administrarse por diferentes vías (ej. oral y parenteral), asegurando que el frontend obligue a marcar exactamente una de ellas como la vía principal.
R.3: Validación de Vía Principal. Al insertar o actualizar registros en la tabla productos_vias, el backend debe validar que para cada producto_id exista exactamente uno y solo un registro con es_principal = 1 en estado ACTIVO. Si no existe ningún registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "El producto debe tener al menos una vía de administración marcada como principal (es_principal = 1)". Si existe más de un registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "Un producto no puede tener más de una vía de administración principal (es_principal = 1)".';

-- ================================================================================================

CREATE TABLE equivalentes (
    equivalente_id BIGSERIAL PRIMARY KEY,
    producto_base_id BIGINT NOT NULL DEFAULT 1,
    producto_alternativo_id BIGINT NOT NULL DEFAULT 1,
    grado_equivalente_id SMALLINT NOT NULL DEFAULT 3803,  -- 3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO, 3803=NINGUNO
    prioridad_recomendacion SMALLINT NOT NULL DEFAULT 1,
    observaciones VARCHAR(500) NULL,
    fecha_vigencia_desde DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vigencia_hasta DATE NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_equivalentes_producto_base_id FOREIGN KEY (producto_base_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_equivalentes_producto_alternativo_id FOREIGN KEY (producto_alternativo_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_equivalentes_gradoequivalenteid CHECK (grado_equivalente_id IN (3800, 3801, 3802, 3803)),
    CONSTRAINT chk_equivalentes_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_equivalentes_prioridadrecomendacion CHECK (prioridad_recomendacion >= 1),
    CONSTRAINT chk_equivalentes_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_equivalentes_fechas CHECK (fecha_vigencia_hasta IS NULL OR fecha_vigencia_hasta >= fecha_vigencia_desde),
    CONSTRAINT chk_equivalentes_diferentes CHECK (producto_base_id <> producto_alternativo_id OR equivalente_id = 1),
    CONSTRAINT chk_equivalentes_prodbaseid CHECK (producto_base_id >= 1),
    CONSTRAINT chk_equivalentes_prodaltid CHECK (producto_alternativo_id >= 1)
);
CREATE UNIQUE INDEX uix_equivalentes_varios_unique ON equivalentes (producto_base_id, producto_alternativo_id) WHERE estado_id IN (1000, 1002) AND NOT (producto_base_id = 1 AND producto_alternativo_id = 1);
CREATE INDEX idx_equivalentes_varios ON equivalentes (producto_base_id, fecha_vigencia_desde, fecha_vigencia_hasta) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE equivalentes IS 'Reglas de la tabla - equivalentes
R.0: La tabla equivalentes gestiona el catálogo de sustitutos farmacéuticos, vinculando un producto principal con alternativas comerciales o genéricas. Su propósito es permitir al personal de mostrador sugerir opciones viables de forma inmediata cuando el producto base está agotado o no disponible, garantizando la continuidad de la atención bajo criterios de equivalencia clínica.
R.1: Restricción de Autoreferencia. El campo producto_base_id y producto_alternativo_id deben ser estrictamente diferentes (chk_equivalentes_diferentes), impidiendo que un producto sea equivalente de sí mismo (excepto en el registro comodín inicial).
R.2: Vigencia Temporal de la Equivalencia. fecha_vigencia_desde y fecha_vigencia_hasta controlan el periodo de validez operativa de la sustitución. El índice único parcial uix_equivalentes_varios_unique asegura que no existan duplicados activos para el mismo par de productos dentro de su rango de vigencia.
R.3: Grado de Equivalencia. grado_equivalente_id clasifica el nivel de sustitución clínica (3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO, 3803=NINGUNO), ordenando las sugerencias de mayor a menor equivalencia.
R.4: Prioridad de Recomendación. prioridad_recomendacion define el orden de despliegue en la interfaz de mostrador cuando el producto base se encuentra agotado, ordenando las alternativas de menor a mayor valor numérico entero positivo.';

-- ================================================================================================

CREATE TABLE productos_rangos_edad (
    producto_rango_edad_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    rango_edad_id BIGINT NOT NULL DEFAULT 1,
    contraindicado SMALLINT NOT NULL DEFAULT 0,
    dosis_recomendada VARCHAR(200) NULL,
    observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_productosrangosedad_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosrangosedad_rango_edad_id FOREIGN KEY (rango_edad_id) REFERENCES rangos_edad(rango_edad_id),
    CONSTRAINT chk_productosrangosedad_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosrangosedad_contraindicado CHECK (contraindicado IN (0, 1)),
    CONSTRAINT chk_productosrangosedad_dosisrecomendada_notempty CHECK (dosis_recomendada IS NULL OR TRIM(dosis_recomendada) <> ''),
    CONSTRAINT chk_productosrangosedad_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> '')
);
CREATE UNIQUE INDEX uix_productosrangosedad_varios_unique ON productos_rangos_edad (producto_id, rango_edad_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosrangosedad_rangoedadid ON productos_rangos_edad (rango_edad_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_rangos_edad IS 'Reglas de la tabla - productos_rangos_edad
R.0: La tabla productos_rangos_edad es una relación polimórfica que asigna a un producto los rangos de edad para los cuales está indicado o contraindicado. Su propósito es gestionar la seguridad y el cumplimiento normativo, permitiendo al sistema filtrar automáticamente los productos adecuados según la edad del paciente y mostrando advertencias de contraindicación.
R.1: Esta tabla establece la relación entre productos y rangos de edad, permitiendo definir si un producto está contraindicado para un grupo etario específico, así como la dosis recomendada y observaciones particulares.
R.2: El campo contraindicado con valor 1 (Sí) indica que el producto no debe ser dispensado a pacientes en ese rango de edad. Valor 0 (No) indica que el producto es seguro para ese rango etario.
R.3: La combinación de producto_id y rango_edad_id debe ser única para registros activos o históricos, garantizando que no existan duplicados en las relaciones.
R.4: El frontend debe consultar esta tabla para determinar si un producto puede ser dispensado a un paciente según su edad, mostrando advertencias visuales si el producto está contraindicado para ese rango etario.
R.5: El campo dosis_recomendada almacena la dosis específica recomendada para el rango de edad, permitiendo personalizar la posología según el grupo etario del paciente.
R.6: Al asociar un rango de edad a un producto, el sistema debe validar que tanto el producto como el rango de edad estén en estado ACTIVO (estado_id = 1000) y que no exista una relación previa duplicada.';

-- ================================================================================================

CREATE TABLE productos_ubicaciones (
    producto_ubicacion_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    ubicacion_id BIGINT NOT NULL DEFAULT 1,
    prioridad_picking SMALLINT NOT NULL DEFAULT 1,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_productosubicaciones_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosubicaciones_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT chk_productosubicaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosubicaciones_prioridadpicking CHECK (prioridad_picking IN (1, 99) OR (prioridad_picking >= 1 AND prioridad_picking <= 99)),
    CONSTRAINT chk_productosubicaciones_productoid CHECK (producto_id >= 1),
    CONSTRAINT chk_productosubicaciones_ubicacionid CHECK (ubicacion_id >= 1)
);
CREATE UNIQUE INDEX uix_productosubicaciones_varios_unique ON productos_ubicaciones (producto_id, ubicacion_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosubicaciones_ubicacionid ON productos_ubicaciones (ubicacion_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_ubicaciones IS 'Reglas de la tabla - productos_ubicaciones
R.0: La tabla productos_ubicaciones mapea la ubicación física exacta de un producto dentro del almacén, definiendo la relación entre un producto y una coordenada espacial específica. Su propósito es habilitar una logística interna eficiente, optimizando las rutas de "picking" (prioridad) y controlando la capacidad máxima de almacenamiento por ubicación, lo que es esencial para la organización y el rápido despacho de mercadería.
R.1: Separación Estricta de Responsabilidades: La tabla productos_ubicaciones delega la totalidad de la información geométrica y topológica del layout físico del almacén a la entidad ubicaciones, actuando únicamente como un nodo relacional que asocia existencias con coordenadas preestablecidas.
R.2: Integridad Espacial Unívoca: Se implementa una restricción de unicidad mediante el índice uix_productosubicaciones_varios_unique, impidiendo de forma categórica que un mismo producto posea múltiples asignaciones logísticas concurrentes hacia la misma llave física espacial en estado operacional activo e histórico.
R.3: Optimización Algorítmica de Picking: El campo prioridad_picking rige de manera obligatoria el ordenamiento secuencial de las rutas automáticas de extracción generadas por el sistema (WMS), donde valores numéricos inferiores representan mayor prioridad de visitación o despacho inmediato.
R.4: Registro Comodín de Consistencia Mínima: La tupla inicial con ID igual a 1 vincula de manera explícita el producto por defecto al registro comodín de ubicaciones en estado ACTIVO (estado_id = 1000), garantizando la resolución exitosa de operaciones previas a la diagramación oficial de los centros de distribución.';

-- ================================================================================================

CREATE TABLE principios_activos (
    principio_activo_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(1000) NULL,
    es_controlado SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_principiosactivos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_principiosactivos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_principiosactivos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_principiosactivos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_principiosactivos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_principiosactivos_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_principiosactivos_nombre_mayusculas CHECK (nombre = UPPER(nombre)),
    CONSTRAINT chk_principiosactivos_escontrolado CHECK (es_controlado IN (0, 1)),
	CONSTRAINT chk_principiosactivos_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_principiosactivos_codigo_unique ON principios_activos (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_principiosactivos_nombre_unique ON principios_activos (nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE principios_activos IS 'Reglas de la tabla - principios_activos
R.0: La tabla principios_activos es un catálogo de compuestos farmacológicos que constituyen la base médica de los medicamentos. Su propósito es gestionar la información sobre sustancias activas, facilitar la búsqueda de genéricos, controlar los principios activos fiscalizados y servir como base para la clasificación médica de los productos. Se conecta a través de productos_principios con la tabla productos.
R.1: Control de Sustancias Fiscalizadas: El indicador es_controlado define las restricciones de dispensación del compuesto en el frontend; un valor de 1 (Sí) condiciona el formulario de venta para exigir la captura obligatoria de los datos de la receta médica, mientras que un valor de 0 (No) permite una salida libre de inventario.
R.2: Agrupación y Equivalencia Comercial: En el catálogo de productos, múltiples fármacos de marcas comerciales distintas pueden compartir el mismo principio_activo_id dinámicamente, lo que faculta a la pantalla de ventas a sugerir alternativas genéricas y de menor costo al paciente cuando no hay disponibilidad física de la marca solicitada.';

-- ================================================================================================

CREATE TABLE productos_principios (
    producto_principio_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    principio_activo_id BIGINT NOT NULL DEFAULT 1,
    concentracion VARCHAR(100) NOT NULL DEFAULT 'NO APLICA',
    es_principal SMALLINT NOT NULL DEFAULT 1,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_productosprincipios_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosprincipios_principio_activo_id FOREIGN KEY (principio_activo_id) REFERENCES principios_activos(principio_activo_id),
    CONSTRAINT chk_productosprincipios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosprincipios_concentracion_notempty CHECK (TRIM(concentracion) <> ''),
    CONSTRAINT chk_productosprincipios_esprincipal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_productosprincipios_principal_unique ON productos_principios (producto_id) WHERE es_principal = 1 AND estado_id = 1000;
CREATE INDEX idx_productosprincipios_principioactivoid ON productos_principios (principio_activo_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE productos_principios IS 'Reglas de la tabla - productos_principios
R.0: La tabla productos_principios es una relación polimórfica que asocia principios activos a un producto, permitiendo que un medicamento compuesto tenga múltiples sustancias activas. Su propósito es modelar la composición química de los productos, identificando el principio activo principal para su categorización médica y control, lo cual es fundamental para el cumplimiento regulatorio y la prescripción.
R.1: es_principal (1 = Sí, 0 = No) identifica al principio activo principal de la fórmula. El backend valida que exista exactamente un registro con es_principal = 1 por producto en estado ACTIVO.
R.2: Múltiples Principios Activos por Medicamento: La interfaz de usuario debe permitir asociar más de un principio activo a un mismo producto_id para dar soporte a medicamentos compuestos (multicomponentes o combinados), asegurando que el frontend obligue a marcar exactamente uno de ellos como el componente principal.
R.3: Validación de Principio Activo Principal: Al insertar o actualizar registros en la tabla productos_principios, el backend debe validar que para cada producto_id exista exactamente uno y solo un registro con es_principal = 1 en estado ACTIVO. Si no existe ningún registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "El producto debe tener al menos un principio activo marcado como principal (es_principal = 1)". Si existe más de un registro con es_principal = 1, el sistema debe rechazar la operación con el mensaje: "Un producto no puede tener más de un principio activo principal (es_principal = 1)". Esta validación aplica tanto para inserciones como para actualizaciones, incluyendo cambios de estado.';

-- ================================================================================================

CREATE TABLE registros_sanitarios (
    registro_sanitario_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    codigo_registro VARCHAR(60) NOT NULL,
    entidad_emisora VARCHAR(100) NOT NULL DEFAULT '',
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_registrossanitarios_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_registrossanitarios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_registrossanitarios_codigoregistro_notempty CHECK (TRIM(codigo_registro) <> ''),
    CONSTRAINT chk_registrossanitarios_codigoregistro_mayusculas CHECK (codigo_registro = UPPER(codigo_registro)),
    CONSTRAINT chk_registrossanitarios_entidademisora_notempty CHECK (TRIM(entidad_emisora) <> ''),
    CONSTRAINT chk_registrossanitarios_entidademisora_mayusculas CHECK (entidad_emisora = UPPER(entidad_emisora)),
    CONSTRAINT chk_registrossanitarios_fechas CHECK (fecha_vencimiento > fecha_emision)
);
CREATE UNIQUE INDEX uix_registrossanitarios_productoid_unique ON registros_sanitarios (producto_id) WHERE estado_id = 1000;
CREATE INDEX idx_registrossanitarios_codigoregistro ON registros_sanitarios (codigo_registro) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE registros_sanitarios IS 'Reglas de la tabla - registros_sanitarios
R.0: La tabla registros_sanitarios gestiona la información legal de los productos, almacenando el código de registro sanitario, su fecha de emisión y vencimiento. Su propósito es controlar la vigencia de la autorización de comercialización de cada producto, bloqueando su venta si el registro sanitario está caducado, lo que asegura el cumplimiento de la normativa sanitaria.
R.1: Control de Caducidad de Autorización: Al registrar compras o emitir ventas en el frontend, el sistema debe contrastar la fecha actual del servidor contra fecha_vencimiento; si el registro está caducado, la interfaz debe bloquear la comercialización del lote y alertar visualmente al regente farmacéutico.
R.2: Exclusividad de Registro Activo: Un producto farmacéutico (producto_id) puede poseer un historial extenso de renovaciones de licencias sanitarias, pero solo se permite un único registro con estado ''ACTIVO'' en simultáneo para garantizar la trazabilidad legal vigente.';

-- ================================================================================================

CREATE TABLE productos_controlados (
    producto_controlado_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    numero_autorizacion VARCHAR(50) NOT NULL,
    requiere_receta_retenida SMALLINT NOT NULL DEFAULT 1,
    observaciones_control VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_productoscontrolados_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_productoscontrolados_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productoscontrolados_numeroautorizacion_notempty CHECK (TRIM(numero_autorizacion) <> ''),
    CONSTRAINT chk_productoscontrolados_numeroautorizacion_mayusculas CHECK (numero_autorizacion = UPPER(numero_autorizacion)),
    CONSTRAINT chk_productoscontrolados_requiererecetaretenida CHECK (requiere_receta_retenida IN (0, 1)),
    CONSTRAINT chk_productoscontrolados_observacionescontrol_notempty CHECK (observaciones_control IS NULL OR TRIM(observaciones_control) <> '')
);
CREATE UNIQUE INDEX uix_productoscontrolados_productoid_unique ON productos_controlados (producto_id) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_productoscontrolados_numeroautorizacion_unique ON productos_controlados (numero_autorizacion) WHERE estado_id IN (1000, 1002) AND numero_autorizacion <> 'NINGUNO';

COMMENT ON TABLE productos_controlados IS 'Reglas de la tabla - productos_controlados
R.0: La tabla productos_controlados extiende la información de gestión para aquellos productos sujetos a fiscalización especial, como psicotrópicos o estupefacientes. Su propósito es imponer controles adicionales como la autorización específica y la retención obligatoria de recetas, para cumplir con las estrictas regulaciones de sustancias controladas.
R.1: Control de Retención de Recetas: Cuando la bandera requiere_receta_retenida es igual a 1 (Sí), el formulario de facturación del frontend debe bloquear la confirmación de la venta hasta que el operario registre el número de receta médica y los datos del médico colegiado. Un valor de 0 (No) exime de esta restricción.';

-- ================================================================================================

CREATE TABLE promociones (
    promocion_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
	cantidad_requerida SMALLINT NOT NULL DEFAULT 0,
	cantidad_beneficio SMALLINT NOT NULL DEFAULT 0,
    tipo_beneficio_id SMALLINT NOT NULL DEFAULT 1504,  	-- 1500=DESCUENTO, 1501=PORCENTAJE, 1502=MONTO_FIJO, 1503=CANTIDAD, 1504=NINGUNO
	valor_beneficio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_promociones_tipobeneficioid CHECK (tipo_beneficio_id IN (1500, 1501, 1502, 1503, 1504)),
    CONSTRAINT chk_promociones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_promociones_codigo_notempty CHECK (TRIM(codigo) <> ''),
	CONSTRAINT chk_promociones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_promociones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_promociones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_promociones_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_promociones_nombre_mayusculas CHECK (nombre = UPPER(nombre)),
    CONSTRAINT chk_promociones_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_promociones_valorbeneficio CHECK (valor_beneficio >= 0.00),
    CONSTRAINT chk_promociones_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_promociones_cantidades CHECK (cantidad_requerida >= 0 AND cantidad_beneficio >= 0)
);
CREATE UNIQUE INDEX uix_promociones_codigo_unique ON promociones (codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE promociones IS 'Reglas de la tabla - promociones
R.0: La tabla promociones define campañas comerciales con fechas de vigencia y un tipo de beneficio (descuento, monto fijo, etc.). Su propósito es estructurar las reglas de cálculo para aplicar descuentos en el punto de venta (POS), gestionando ofertas temporales que incentivan las ventas. Se conecta a través de promociones_productos con la tabla productos.
R.1: Validación de Coincidencia de Campañas: Al calcular la liquidación del carrito en el punto de venta, el motor del backend debe filtrar las promociones basándose en la fecha y hora del servidor actual frente a los campos fecha_inicio y fecha_fin. Aquellas campañas fuera de rango o con estado diferente a ''ACTIVO'' deben ser omitidas de manera automática sin alterar los precios base del inventario.
R.2: Tipificación del Beneficio Económico: El campo tipo_beneficio_id orienta la fórmula aritmética de descuento en la interfaz. Si está configurado como ''PORCENTAJE'', el valor del campo valor_beneficio se procesa como una tasa de descuento aplicable sobre el precio del artículo (ej. 10.00 para un 10%); si es ''MONTO_FIJO'', representa una deducción monetaria directa y constante sobre el total de la línea.
R.3: Soporte para Promociones por Volumen y Cantidad: Los campos cantidad_requerida y cantidad_beneficio estructuran las reglas para ofertas basadas en unidades (ej. mecánicas tipo "Lleve X, Pague Y" o bonificaciones por volumen). Cuando el tipo_beneficio_id corresponda a ''CANTIDAD'' (1503), el motor del POS evaluará estos umbrales para determinar las unidades bonificadas o cobradas en la transacción.
R.4: La logica de negocio esta en fn_validarCoherenciaPromocion.';

-- ================================================================================================

CREATE TABLE promociones_productos (
    promocion_producto_id BIGSERIAL PRIMARY KEY,
    promocion_id BIGINT NOT NULL DEFAULT 1,
    producto_id BIGINT NOT NULL DEFAULT 1,
    limite_por_transaccion SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_promocionesproductos_promocion_id FOREIGN KEY (promocion_id) REFERENCES promociones(promocion_id),
    CONSTRAINT fk_promocionesproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_promocionesproductos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_promocionesproductos_limiteportransaccion CHECK (limite_por_transaccion >= 0)
);
CREATE UNIQUE INDEX uix_promocionesproductos_productoid_unique ON promociones_productos (producto_id) WHERE estado_id = 1000;

COMMENT ON TABLE promociones_productos IS 'Reglas de la tabla - promociones_productos
R.0: La tabla promociones_productos es una relación intermedia (N:M) que vincula promociones con productos específicos, estableciendo límites por transacción.
R.1: Control de Racionamiento de Descuentos: El campo limite_por_transaccion restringe el número máximo de unidades de un mismo producto que pueden beneficiarse de la campaña en una única operación de venta. Un valor superior a 0 activa la validación en el punto de facturación; si el cliente excede dicha cantidad, las unidades adicionales se liquidarán automáticamente a la tarifa estándar de la lista de precios vigente. Un valor de 0 anula esta restricción, permitiendo unidades ilimitadas por ticket.
R.2: Exclusividad de Campaña Activa: Para prevenir conflictos de cálculo en cascada o márgenes negativos por doble descuento, un producto_id específico sólo puede estar asociado a una única relación de promoción en estado ''ACTIVO'' a través de esta tabla intermedia. El índice único parcial restringe la duplicidad operativa.';

-- ================================================================================================

CREATE TABLE conversiones_unidad (
    conversion_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    unidad_origen_id BIGINT NOT NULL DEFAULT 1,
    unidad_destino_id BIGINT NOT NULL DEFAULT 1,
    factor_conversion DECIMAL(10,4) NOT NULL DEFAULT 1.0000,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_conversionesunidad_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_conversionesunidad_unidad_origen_id FOREIGN KEY (unidad_origen_id) REFERENCES unidades(unidad_id),
    CONSTRAINT fk_conversionesunidad_unidad_destino_id FOREIGN KEY (unidad_destino_id) REFERENCES unidades(unidad_id),
    CONSTRAINT chk_conversionesunidad_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_conversionesunidad_factorconversion CHECK (factor_conversion > 0.0000),
    CONSTRAINT chk_conversionesunidad_varios CHECK (unidad_origen_id <> unidad_destino_id OR conversion_id = 1)
);
CREATE UNIQUE INDEX uix_conversionesunidad_varios_unique ON conversiones_unidad (producto_id, unidad_origen_id, unidad_destino_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE conversiones_unidad IS 'Reglas de la tabla - conversiones_unidad
R.0: La tabla conversiones_unidad define los factores de conversión entre diferentes unidades de medida para un mismo producto, como de caja a unidad. Su propósito es resolver la equivalencia entre unidades (factores de empaque), lo que es fundamental para operaciones de compra, venta y gestión de inventario, permitiendo registrar, por ejemplo, una compra en cajas pero vender en unidades.
R.1: El campo factor_conversion representa cuántas unidades de destino equivalen a una unidad de origen (ej. 1 Caja = 24 Tabletas). El motor de inventario utiliza este factor para fraccionar o agrupar unidades en transacciones de venta y compra.
R.2: La combinación de producto_id, unidad_origen_id y unidad_destino_id debe ser única para registros activos o históricos, evitando factores de conversión redundantes.
R.3: Las unidades de origen y destino deben ser diferentes (chk_conversionesunidad_varios) menos conversion_id=1. El sistema no permite conversiones de una unidad consigo misma para evitar bucles infinitos en el cálculo de equivalencias.';

-- ================================================================================================

CREATE TABLE proveedores (
    proveedor_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    nit VARCHAR(30) NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    rating_calidad_id SMALLINT NOT NULL DEFAULT 2055,  	-- 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
	monto_minimo_compra DECIMAL(12,2) DEFAULT 0.00,
	plazo_entrega_dias SMALLINT DEFAULT 7,
	limite_credito DECIMAL(12,2) DEFAULT 0.00,
	dias_credito SMALLINT DEFAULT 0,
	ultima_evaluacion DATE NULL,
	observaciones VARCHAR(2000) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT chk_proveedores_ratingcalidadid CHECK (rating_calidad_id IN (2050, 2051, 2052, 2053, 2054, 2055)),
    CONSTRAINT chk_proveedores_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_proveedores_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_proveedores_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_proveedores_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_proveedores_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_proveedores_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_proveedores_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_proveedores_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_proveedores_nombre_mayusculas CHECK (nombre = UPPER(nombre)),
    CONSTRAINT chk_proveedores_montomintimochk CHECK (monto_minimo_compra IS NULL OR monto_minimo_compra >= 0.00),
    CONSTRAINT chk_proveedores_plazoentregachk CHECK (plazo_entrega_dias IS NULL OR plazo_entrega_dias >= 0),
    CONSTRAINT chk_proveedores_limitecreditochk CHECK (limite_credito IS NULL OR limite_credito >= 0.00),
    CONSTRAINT chk_proveedores_diascreditochk CHECK (dias_credito IS NULL OR dias_credito >= 0)
);
CREATE UNIQUE INDEX uix_proveedores_codigo_unique ON proveedores (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_proveedores_nombre_unique ON proveedores (nombre) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_proveedores_nit_unique ON proveedores (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND TRIM(nit) <> '';

COMMENT ON TABLE proveedores IS 'Reglas de la tabla - proveedores
R.0: La tabla proveedores es el registro maestro de los suministradores de productos, almacenando su información de contacto y un rating de calidad. Su propósito es gestionar las relaciones comerciales con los laboratorios y distribuidores, sirviendo como el referente para los procesos de compras, la evaluación de desempeño de proveedores y la planificación de inventario.
R.1: El Número de Identificación Tributaria (nit) es opcional para dar soporte a proveedores extranjeros o laboratorios internacionales. Cuando se registra un valor, el índice único impide duplicados en registros activos o históricos.
R.2: El registro con proveedor_id = 1 y nombre ''NINGUNO'' representa el proveedor comodín para compras directas o donaciones; permanece en estado ACTIVO para garantizar la integridad referencial.
R.3: Los campos codigo y nombre deben almacenarse en mayúsculas y ser únicos para registros activos o históricos.
R.4: Rating de Calidad. rating_calidad_id utiliza los valores (2050-2055) para calificar el desempeño del proveedor en aspectos como cumplimiento de plazos, calidad del producto, precios, etc. El valor por defecto es REGULAR (2052). Este campo es opcional y puede ser NULL si aún no se ha evaluado al proveedor.
R.5: Suficiencia del Modelo de Proveedores. Se ratifica que la estructura actual de la tabla proveedores, complementada por el campo rating_calidad_id (referenciado a los valores 2050-2055) y la integración transversal con el kardex de compras y los módulos estratégicos del sistema, cumple de manera óptima con la evaluación de desempeño y la gestión comercial, sin requerir tablas adicionales de scoring AHP que contravengan la filosofía de simplicidad y velocidad de la arquitectura AK-47.
R.6: Control de Rating de Calidad. rating_calidad_id utiliza los valores (2050-2054).
- Si rating_calidad_id = 2050 (PESIMO), el sistema debe bloquear nuevas compras a este proveedor.
- El backend debe actualizar automáticamente el rating basado en incidencias de calidad.
R.7: Validación de Unicidad de NIT. El nit debe ser único para registros ACTIVOS o HISTORICOS. No pueden existir dos proveedores con el mismo nit.
R.8: Límite de Crédito por Proveedor. El sistema debe validar que el monto total de compras a crédito pendientes (estado_financiero_id IN (2401, 2402)) no exceda el límite de crédito configurado en parametros_globales (proveedor_limite_credito_default).
R.9: Valor Mínimo de Compra. Cada proveedor debe tener un monto mínimo de compra configurado (campo monto_minimo_compra DECIMAL(12,2) DEFAULT 0.00). El sistema debe validar que total_compra >= monto_minimo_compra.
R.10: Control de Plazos de Entrega. El campo plazo_entrega_dias define el lead time estándar del proveedor. El sistema utiliza este valor para calcular puntos de reorden y fechas estimadas de recepción.
R.11: Historial de Calificación. La tabla mantiene el historial de evaluaciones en la tabla asociada proveedores_rating para garantizar la trazabilidad del desempeño.';

-- ================================================================================================

CREATE TABLE proveedores_contactos (
    proveedor_contacto_id BIGSERIAL PRIMARY KEY,
    proveedor_id BIGINT NOT NULL DEFAULT 1,
    nombre VARCHAR(100) NOT NULL,
    cargo VARCHAR(100) NULL,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    es_principal SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_proveedorescontactos_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_proveedorescontactos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_proveedorescontactos_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_proveedorescontactos_cargo_notempty CHECK (cargo IS NULL OR TRIM(cargo) <> ''),
    CONSTRAINT chk_proveedorescontactos_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_proveedorescontactos_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_proveedorescontactos_esprincipal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_proveedorescontactos_varios_unique ON proveedores_contactos (proveedor_id) WHERE es_principal = 1 AND estado_id = 1000;

COMMENT ON TABLE proveedores_contactos IS 'Reglas de la tabla - proveedores_contactos
R.0: La tabla proveedores_contactos almacena la información de contacto asociados a cada proveedor (nombre, cargo, teléfono, email). Su propósito es gestionar los canales de comunicación y los puntos de contacto comerciales u operativos con cada suministrador.
R.1: El campo es_principal (0 o 1) indica si el contacto es el principal para el proveedor. Un índice único parcial garantiza que solo exista un contacto principal en estado ACTIVO (estado_id = 1000) por cada proveedor.
R.2: Los estados de los registros se controlan mediante estado_id, gestionando los valores estándar (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO).
R.3: Cada contacto está vinculado obligatoriamente a un proveedor mediante la llave foránea fk_proveedorescontactos_proveedor_id.';

-- ================================================================================================

CREATE TABLE proveedores_rating_historico (
    rating_historico_id BIGSERIAL PRIMARY KEY,
    proveedor_id BIGINT NOT NULL DEFAULT 1,
    rating_calidad_id SMALLINT NOT NULL,				-- 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
    motivo VARCHAR(255) NOT NULL,
    fecha_evaluacion DATE NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_proveedoresratinghistorico_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_proveedoresratinghistorico_ratingcalidadid CHECK (rating_calidad_id IN (2050, 2051, 2052, 2053, 2054, 2055)),
    CONSTRAINT chk_proveedoresratinghistorico_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_proveedoresratinghistorico_motivo_notempty CHECK (TRIM(motivo) <> '')
);
CREATE INDEX idx_proveedoresratinghistorico_varios ON proveedores_rating_historico (proveedor_id, fecha_evaluacion DESC);

COMMENT ON TABLE proveedores_rating_historico IS 'Reglas de la tabla - proveedores_rating_historico
R.0: La tabla proveedores_rating_historico almacena el historial de calificaciones de calidad asignadas a cada proveedor a lo largo del tiempo. Su propósito es mantener la trazabilidad y auditoría de las evaluaciones de desempeño (vinculadas a la regla R.11 de la tabla proveedores), permitiendo analizar el comportamiento del suministrador ante incidencias.';

-- ================================================================================================

CREATE TABLE parametros_globales (
    parametro_id BIGSERIAL PRIMARY KEY,
    clave VARCHAR(100) NOT NULL,
    valor VARCHAR(500) NOT NULL,
    tipo_dato_id SMALLINT NOT NULL DEFAULT 1800,  		-- 1800=STRING, 1801=INTEGER, 1802=DECIMAL, 1803=BOOLEAN, 1804=TIMESTAMP, 1805=JSON
    datos_json JSONB NULL,
	descripcion VARCHAR(500) NULL,
    editable SMALLINT NOT NULL DEFAULT 1,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_parametrosglobales_tipodatoid CHECK (tipo_dato_id IN (1800, 1801, 1802, 1803, 1804, 1805)),
    CONSTRAINT chk_parametrosglobales_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_parametrosglobales_clave CHECK (TRIM(clave) = clave AND clave ~ '^[a-z0-9_-]+$' AND LENGTH(clave) >= 3),
    CONSTRAINT chk_parametrosglobales_valor_notempty CHECK (TRIM(valor) <> ''),
    CONSTRAINT chk_parametrosglobales_descripcion CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_parametrosglobales_editable CHECK (editable IN (0, 1)),
	CONSTRAINT chk_parametrosglobales_jsonb_requerido CHECK ((tipo_dato_id = 1805 AND datos_json IS NOT NULL) OR (tipo_dato_id <> 1805))
);
CREATE UNIQUE INDEX uix_parametrosglobales_clave_unique ON parametros_globales (clave) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE parametros_globales IS 'Reglas de la tabla - parametros_globales
R.0: La tabla parametros_globales actúa como un almacén de configuración clave-valor, que permite parametrizar el comportamiento del sistema. Su propósito es centralizar variables de negocio y operativas (como el porcentaje de IVA, días de alerta, etc.) en un solo lugar, haciendo que los ajustes sean dinámicos y no requieran recompilación de código. No se conecta directamente con otras tablas a través de claves foráneas, pero es consumida por todos los módulos de la aplicación.
R.1: El campo editable con valor 1 indica que el parámetro puede ser modificado por usuarios autorizados; valor 0 indica que no se puede modificar.
R.2: El campo clave debe ser único, en minúsculas, sin espacios, y solo caracteres alfanuméricos y guión bajo.';

-- ================================================================================================

CREATE TABLE tareas_programadas (
    tarea_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
    tipo_tarea_id SMALLINT NOT NULL DEFAULT 3409,  	-- 3400=REPORTE, 3401=IA_MODELO, 3402=BACKUP, 3403=ALERTA, 3404=MANTENIMIENTO, 3405=FORECASTING, 3406=CLASIFICACION, 3407=OPTIMIZACION, 3408=VALIDACION, 3409=NINGUNO
    subtipo_tarea_id SMALLINT NULL DEFAULT 3461,   	-- 3450=SARIMA, 3451=SARIMAX, 3452=PROPHET, 3453=KMEANS, 3454=ROP_CALC, 3455=PATRON_CONSUMO, 3456=ALERTA_PREDICTIVA, 3457=VARIABLE_EXOGENA, 3458=METRICA_RENDIMIENTO, 3459=REENTRENAMIENTO, 3460=VALIDACION_CROSS, 3461=NINGUNO
    frecuencia_id SMALLINT NOT NULL DEFAULT 3359,  	-- 3350=MINUTOS, 3351=HORAS, 3352=DIARIO, 3353=SEMANAL, 3354=MENSUAL, 3355=ANUAL, 3356=CRON, 3357=CONTINUA, 3358=TRIGGER_EVENTO, 3359=NINGUNO
    cron_expresion VARCHAR(100) NULL,
    parametros JSONB NULL,
    ultima_ejecucion TIMESTAMPTZ NULL,
    proxima_ejecucion TIMESTAMPTZ NULL,
    ejecucion_exitosa SMALLINT NULL,
    ultimo_error VARCHAR(3000) NULL,
    intentos_fallidos SMALLINT NOT NULL DEFAULT 0,
    max_intentos SMALLINT NOT NULL DEFAULT 3,
    tarea_dependencia_id BIGINT NULL,
    ejecutar_en_cascada SMALLINT NOT NULL DEFAULT 0,
    modulo_estrategico_id SMALLINT NULL DEFAULT 2157,  	-- 2150=FLUJO_CAJA, 2151=DEMANDA_INVENTARIO, 2152=PROVEEDORES_AHP, 2153=OPERACION_MERMAS, 2154=CLIENTES_RFM, 2155=PRECIOS_ELASTICIDAD, 2156=ANOMALIAS_FRAUDE, 2157=NINGUNO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_tareasprogramadas_tarea_dependencia_id FOREIGN KEY (tarea_dependencia_id) REFERENCES tareas_programadas(tarea_id),
    CONSTRAINT chk_tareasprogramadas_tipotareaid CHECK (tipo_tarea_id IN (3400, 3401, 3402, 3403, 3404, 3405, 3406, 3407, 3408, 3409)),
    CONSTRAINT chk_tareasprogramadas_subtipotareaid CHECK (subtipo_tarea_id IS NULL OR subtipo_tarea_id IN (3450, 3451, 3452, 3453, 3454, 3455, 3456, 3457, 3458, 3459, 3460, 3461)),
    CONSTRAINT chk_tareasprogramadas_frecuenciaid CHECK (frecuencia_id IN (3350, 3351, 3352, 3353, 3354, 3355, 3356, 3357, 3358, 3359)),
    CONSTRAINT chk_tareasprogramadas_moduloestrategicoid CHECK (modulo_estrategico_id IS NULL OR modulo_estrategico_id IN (2150, 2151, 2152, 2153, 2154, 2155, 2156, 2157)),
    CONSTRAINT chk_tareasprogramadas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_tareasprogramadas_codigo_notempty CHECK (TRIM(codigo) <> ''),
	CONSTRAINT chk_tareasprogramadas_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_tareasprogramadas_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_tareasprogramadas_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_tareasprogramadas_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_tareasprogramadas_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_tareasprogramadas_cronexpresion_notempty CHECK (cron_expresion IS NULL OR TRIM(cron_expresion) <> ''),
    CONSTRAINT chk_tareasprogramadas_ejecucion_exitosa CHECK (ejecucion_exitosa IS NULL OR ejecucion_exitosa IN (0, 1)),
    CONSTRAINT chk_tareasprogramadas_ultimoerror_notempty CHECK (ultimo_error IS NULL OR TRIM(ultimo_error) <> ''),
    CONSTRAINT chk_tareasprogramadas_ejecutarencascada CHECK (ejecutar_en_cascada IN (0, 1)),
    CONSTRAINT chk_tareasprogramadas_intentosfallidos CHECK (intentos_fallidos >= 0 AND max_intentos > 0)
);
CREATE UNIQUE INDEX uix_tareasprogramadas_codigo_unique ON tareas_programadas (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_tareasprogramadas_moduloestrategicoid ON tareas_programadas (modulo_estrategico_id) WHERE modulo_estrategico_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_tareasprogramadas_tareadependenciaid ON tareas_programadas(tarea_dependencia_id);

COMMENT ON TABLE tareas_programadas IS 'Reglas de la tabla - tareas_programadas
R.0: La tabla tareas_programadas es el orquestador de procesos automáticos y batch, definiendo los job que se ejecutarán en segundo plano (backups, entrenamientos de IA, alertas). Su propósito es gestionar el ciclo de vida de las tareas (frecuencia, dependencias, reintentos) y su clasificación por módulo estratégico, garantizando la automatización del sistema y la actualización continua de la inteligencia de negocio.
R.1: Cuando una tarea falla, el sistema incrementa intentos_fallidos. Si alcanza max_intentos, el backend cambia automáticamente estado_id a 1001 (BORRADO) y registra el error en ultimo_error.
R.2: Si tarea_dependencia_id tiene valor y ejecutar_en_cascada es 1, el orquestador solo ejecuta la tarea cuando la tarea padre haya finalizado con ejecucion_exitosa = 1.
R.3: El campo estado_id utiliza los valores estándar del sistema (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). No se permiten estados personalizados como ''PAUSADO'' o ''INACTIVO''.
R.4: Campo ejecucion_exitosa.
- 1: La última ejecución de la tarea finalizó exitosamente, sin errores críticos y cumpliendo con todos los procesos definidos.
- 0: La última ejecución de la tarea falló por algún error (excepción, timeout, datos inconsistentes, etc.), registrando el detalle en ultimo_error.
- NULL: La tarea nunca ha sido ejecutada (estado inicial) o no se ha registrado el resultado de la última ejecución.
R.5: Campo ejecutar_en_cascada.
- 0 (valor por defecto): La tarea se ejecuta de forma independiente, sin esperar el resultado de la tarea dependiente (tarea_dependencia_id). Incluso si la tarea padre falla, la tarea hija se ejecutará según su propia programación.
- 1: La tarea solo se ejecutará cuando la tarea padre (tarea_dependencia_id) haya finalizado exitosamente (ejecucion_exitosa = 1). Si la tarea padre falla o no se ha ejecutado, la tarea hija se omite o se pospone hasta que la dependencia se cumpla exitosamente.';

-- ================================================================================================

CREATE TABLE control_facturas (
    control_factura_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    tipo_comprobante_id SMALLINT NOT NULL DEFAULT 1103,  -- 1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO
    numero_actual INTEGER NOT NULL DEFAULT 0,
    numero_inicial INTEGER NOT NULL DEFAULT 1,
    numero_final INTEGER NOT NULL DEFAULT 999999,
    autorizacion VARCHAR(50) NOT NULL,
    cuf VARCHAR(100) NULL,
    cufd VARCHAR(500) NULL,
    cuis VARCHAR(100) NULL,
    codigo_control VARCHAR(60) NULL,
    codigo_qr VARCHAR(500) NULL,
    fecha_autorizacion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    gestion SMALLINT NOT NULL,
    estado_operativo_id SMALLINT NOT NULL DEFAULT 3300,  -- 3300=EMITIDO, 3301=ANULADO, 3302=ANULADO_PARCIAL
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_controlfacturas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_controlfacturas_tipocomprobanteid CHECK (tipo_comprobante_id IN (1100, 1101, 1102, 1103)),
    CONSTRAINT chk_controlfacturas_estadooperativoid CHECK (estado_operativo_id IN (3300, 3301, 3302)),
    CONSTRAINT chk_controlfacturas_estadoid CHECK (estado_id IN (1000, 1001, 1002, 1003)),
    CONSTRAINT chk_controlfacturas_numeroactual CHECK (numero_actual >= 0),
    CONSTRAINT chk_controlfacturas_numeroinicial CHECK (numero_inicial > 0),
    CONSTRAINT chk_controlfacturas_numerofinal_numeroinicial CHECK (numero_final >= numero_inicial),
    CONSTRAINT chk_controlfacturas_numeroactual_numerofinal CHECK (numero_actual <= numero_final),
    CONSTRAINT chk_controlfacturas_fechas CHECK (fecha_autorizacion <= fecha_vencimiento),
    CONSTRAINT chk_controlfacturas_gestion CHECK (gestion >= 2020 AND gestion <= 2100),
    CONSTRAINT chk_controlfacturas_autorizacion CHECK (TRIM(autorizacion) <> ''),
    CONSTRAINT chk_controlfacturas_autorizacion_minlength CHECK (LENGTH(TRIM(autorizacion)) >= 3)
);
CREATE UNIQUE INDEX uix_controlfacturas_varios_unique ON control_facturas (sucursal_id, tipo_comprobante_id, gestion) WHERE estado_operativo_id = 3300 AND estado_id IN (1000, 1002);
CREATE INDEX idx_controlfacturas_varios ON control_facturas (sucursal_id, estado_operativo_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE control_facturas IS 'Reglas de la tabla - control_facturas
R.0: La tabla control_facturas gestiona los talonarios de facturación y la numeración fiscal, controlando el rango de números y las credenciales (CUF, CUIS) emitidas por el SIN. Su propósito es generar el número de factura de manera atómica y concurrente para cada transacción de venta, garantizando que el correlativo no se repita y se mantenga la integridad fiscal de la empresa.
R.1: El campo estado_operativo_id rige la disponibilidad de la dosificación. Los valores posibles son: 3300=EMITIDO (activo), 3301=ANULADO, 3302=ANULADO_PARCIAL. El sistema cambia automáticamente a ANULADO cuando numero_actual alcanza numero_final o cuando fecha_vencimiento es superada.
R.2: Los campos cuf, cufd, cuis, codigo_control y codigo_qr almacenan credenciales emitidas por el SIN. Ninguno se captura manualmente; la aplicación actúa como visor de los parámetros provistos por los middlewares de facturación.
R.3: Cada sucursal solo puede tener un registro ACTIVO por tipo de comprobante y gestión. El índice uix_controlfacturas_varios_unique garantiza esta unicidad.
R.4: Generación de Número de Factura en el Backend: El sistema genera números de factura de forma atómica y concurrente en el backend, aplicando bloqueo pesimista mediante SELECT ... FOR UPDATE y formateándolos según parámetros corporativos.';

-- ================================================================================================

CREATE TABLE kardex (
    kardex_id BIGSERIAL PRIMARY KEY,
    tipo_comprobante_id SMALLINT NOT NULL DEFAULT 1103,  -- 1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO
    motivo_anulacion_id SMALLINT NOT NULL DEFAULT 2455,  -- 2450=FACTURA_MAL_EMITIDA, 2451=ERROR_DATOS_CLIENTE, 2452=DEVOLUCION_MERCADERIA, 2453=CONTINGENCIA, 2454=OPERACION_NO_CONCRETADA, 2455=NINGUNO
    motivo_devolucion_id SMALLINT NULL DEFAULT 3506,  	 -- 3500=PRODUCTO_VENCIDO, 3501=PRODUCTO_DAÑADO, 3502=ERROR_PEDIDO, 3503=EXCESO_STOCK, 3504=DESCONTINUADO, 3505=DEVOLUCION_CLIENTE, 3506=NINGUNO, 3507=PRODUCTO_NO_SOLICITADO
	cliente_id BIGINT NOT NULL DEFAULT 1,
    proveedor_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    sucursal_destino_id BIGINT NULL,
	kardex_origen_id BIGINT NULL,
	kardex_pedido_compra_id BIGINT NULL,
    evento_id SMALLINT NOT NULL DEFAULT 1052,            -- 1050=COMPRA, 1051=VENTA, 1052=PROFORMA, 1053=EGR_TRASPASO, 1054=ING_TRASPASO, 1055=ANULACION, 1056=AJUSTE_INGRESO, 1057=AJUSTE_EGRESO, 1058=SOLICITUD_COMPRA, 1059=VENTA_RESERVA, 1060=DEV_CLIENTE, 1061=DEV_PROVEEDOR, 1062=ROBO, 1063=PERDIDA_CADUCIDAD, 1064=MERMA_ROTURA, 1065=INVENTARIO_FISICO_SOBRANTE, 1066=INVENTARIO_FISICO_FALTANTE, 1067=CONVERSION_UNIDADES, 1068=SALIDA_MUESTRA_MEDICA, 1069=INGRESO_DONACION, 1070=RETIRO_CUARENTENA
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
    validez_dias SMALLINT NULL,
    fecha_expiracion TIMESTAMPTZ NULL,
	estado_proforma_id SMALLINT NOT NULL DEFAULT 4000,		-- 4000=NO_APLICA, 4001=PENDIENTE, 4002=CONVERTIDA, 4003=EXPIRADA, 4004=ANULADA
	estado_reserva_id SMALLINT NOT NULL DEFAULT 4850, 		-- 4850=NO_APLICA, 4851=PENDIENTE, 4852=CONFIRMADA, 4853=CANCELADA, 4854=EXPIRADA
	tipo_factura_id SMALLINT NULL DEFAULT 2353,          	-- 2350=CON_FACTURA, 2351=SIN_FACTURA, 2352=NOTA_CREDITO_DEBITO, 2353=NINGUNO
    estado_traspaso_id SMALLINT NOT NULL DEFAULT 2103,   	-- 2100=EN_TRANSITO, 2101=RECIBIDO, 2102=RECHAZADO, 2103=NO_APLICA
    estado_financiero_id SMALLINT NOT NULL DEFAULT 2403,	-- 2400=CANCELADO, 2401=PENDIENTE, 2402=PARCIAL, 2403=NINGUNO
	estado_pedido_id SMALLINT NULL DEFAULT 2257,  			-- 2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO, 2257=NINGUNO
	tipo_despacho_id SMALLINT NOT NULL DEFAULT 3554,  		-- 3550=VENTA_MOSTRADOR, 3551=DOMICILIO, 3552=RETIRO, 3553=TRANSFERENCIA, 3554=NINGUNO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_kardex_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
	CONSTRAINT fk_kardex_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
	CONSTRAINT fk_kardex_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
	CONSTRAINT fk_kardex_sucursal_destino_id FOREIGN KEY (sucursal_destino_id) REFERENCES sucursales(sucursal_id),
	CONSTRAINT fk_kardex_kardex_origen_id FOREIGN KEY (kardex_origen_id) REFERENCES kardex(kardex_id),
	CONSTRAINT fk_kardex_kardex_pedido_compra_id FOREIGN KEY (kardex_pedido_compra_id) REFERENCES kardex(kardex_id),
	CONSTRAINT fk_kardex_kardex_referencia_id FOREIGN KEY (kardex_referencia_id) REFERENCES kardex(kardex_id),
    CONSTRAINT chk_kardex_tipocomprobanteid CHECK (tipo_comprobante_id IN (1100, 1101, 1102, 1103)),
    CONSTRAINT chk_kardex_motivoanulacionid CHECK (motivo_anulacion_id IN (2450, 2451, 2452, 2453, 2454, 2455)),
    CONSTRAINT chk_kardex_motivodevolucionid CHECK (motivo_devolucion_id IN (3500, 3501, 3502, 3503, 3504, 3505, 3506, 3507)),
    CONSTRAINT chk_kardex_eventoid CHECK (evento_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)),
    CONSTRAINT chk_kardex_estadoproformaid CHECK (estado_proforma_id IN (4000, 4001, 4002, 4003, 4004)),
    CONSTRAINT chk_kardex_estadoreservaid CHECK (estado_reserva_id IN (4850, 4851, 4852, 4853, 4854)),
	CONSTRAINT chk_kardex_tipofacturaid CHECK (tipo_factura_id IN (2350, 2351, 2352, 2353)),
    CONSTRAINT chk_kardex_estadotraspasoid CHECK (estado_traspaso_id IN (2100, 2101, 2102, 2103)),
    CONSTRAINT chk_kardex_estadofinancieroid CHECK (estado_financiero_id IN (2400, 2401, 2402, 2403)),
    CONSTRAINT chk_kardex_estadopedidoid CHECK (estado_pedido_id IN (2250, 2251, 2252, 2253, 2254, 2255, 2256, 2257)),
    CONSTRAINT chk_kardex_tipodespachoid CHECK (tipo_despacho_id IN (3550, 3551, 3552, 3553, 3554)),
    CONSTRAINT chk_kardex_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_kardex_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_kardex_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_kardex_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_kardex_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_kardex_totales_positivos CHECK (total_compra >= 0 AND total_venta >= 0 AND total_venta_factura >= 0 AND total_pagado >= 0 AND total_cambio >= 0 AND saldo_pendiente >= 0),
    CONSTRAINT chk_kardex_validez_dias CHECK (validez_dias >= 0)
);
CREATE UNIQUE INDEX uix_kardex_codigo_unique ON kardex (codigo) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_kardex_clienteid ON kardex (cliente_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_kardex_proveedorid ON kardex (proveedor_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_kardex_numerofactura ON kardex (numero_factura) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_kardex_varios ON kardex (sucursal_id, fecha_kardex DESC, evento_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_kardex_estadofinancieroid_sucursalid ON kardex (estado_financiero_id, sucursal_id) WHERE estado_id IN (1000, 1003) AND estado_financiero_id IN (2401, 2402);
CREATE INDEX idx_kardex_sucursaldestinoid_estadotraspasoid ON kardex (sucursal_destino_id, estado_traspaso_id) WHERE evento_id IN (1053, 1054) AND estado_traspaso_id = 2100;
CREATE INDEX idx_kardex_actividad_estadoid ON kardex (COALESCE(fecha_actualizacion, fecha_registro), estado_id);

COMMENT ON TABLE kardex IS 'Reglas de la tabla - kardex
R.0: La tabla kardex es el registro maestro de todas las transacciones que afectan el inventario y la operación comercial, como compras, ventas, traspasos y ajustes. Su propósito es centralizar y dar trazabilidad a cada movimiento, sirviendo como la cabecera que agrupa los detalles de los productos y que orquesta el flujo de caja, la facturación y la generación de documentos históricos.
R.1: Control de Estados (estado_id vs estado_financiero_id). estado_id controla el ciclo de vida lógico del registro (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO). estado_financiero_id aplica exclusivamente a créditos con proveedores (2400=CANCELADO, 2401=PENDIENTE, 2402=PARCIAL). CANCELADO obliga a que saldo_pendiente = 0.00.
R.2: Comportamiento y Obligatoriedad por Evento. El campo evento_id define la naturaleza de la transacción: COMPRA (1050)/DEVOLUCION_COMPRA/SOLICITUD_COMPRA (1058) obliga a seleccionar un proveedor; VENTA (1051)/DEVOLUCION_VENTA obliga a seleccionar un cliente; ANULACION (1055) requiere obligatoriamente un motivo_anulacion_id y muta el estado_id a 1003 (ANULADO), revirtiendo de forma automática el stock de los lotes asociados; PROFORMA (1052) requiere validez_dias; TRANSFERENCIA_SUCURSAL (1053/1054) genera pares de registros vinculados.
R.3: Gestión y Control del Correlativo Único (codigo). El campo codigo es inmutable en el frontend. El backend lo calcula de forma automática bajo el patrón [PREFIJO]-[SUCURSAL_ID]-[GESTION_ANUAL]-[CORRELATIVO], consumiendo los prefijos almacenados en el campo prefijo de la tabla kardex.
R.4: Reglas Fiscales y de Facturación. numero_factura se genera automáticamente SOLO para los eventos VENTA (1051) y DEVOLUCION_VENTA que tengan al menos un detalle con tipo_venta = ''CON_FACTURA'' en kardex_productos. Se toma de control_facturas incrementando numero_actual de forma atómica.
R.5: Automatización de Proformas y Temporalidad. Una tarea programada evalúa diariamente los registros. Si fecha_kardex + validez_dias es superada, el estado_id muta a HISTORICO. El frontend provee un botón "Transformar en Venta" que hereda los datos de la proforma vigente.
R.6: Logística de Entregas y Ajustes Internos. Para eventos VENTA (1051) y PROFORMA (1052), lugar_entrega es obligatorio si se activa el indicador de despacho a domicilio. Mermas y Ajustes restringen cliente_id = 1 y proveedor_id = 1, y exigen justificación en comprobante.
R.7: Gestión Inter-Sucursales y Recepción Física. Al emitir una TRANSFERENCIA_SUCURSAL (evento_id = 1053 EGR_TRASPASO o 1054 ING_TRASPASO), el registro destino nace con estado_id = 1000 (ACTIVO) y estado_traspaso_id = 2100 (EN_TRANSITO), pero el stock en destino solo se incrementa al presionar "Confirmar Recepción" (estado_traspaso_id = 2101 RECIBIDO).
R.8: Automatización de Expiración de Reservas (TTL). El sistema ejecuta de forma periódica (mediante la función liberar_reservas_expiradas() o tareas en el backend) la revisión de los registros con evento_id = 1059 (VENTA_RESERVA) y estado_proforma_id = 4001 (PENDIENTE) cuya fecha_expiracion sea menor a la fecha actual. Al cumplirse, la función muta el estado a 4003 (EXPIRADA) y genera un movimiento compensatorio de tipo LIBERACION_RESERVA (1070) para reintegrar de forma transparente el inventario al stock disponible, evitando bloqueos indefinidos.
R.9: Validación de Crédito a Proveedores. Al registrar una COMPRA (1050) con estado_financiero_id = 2401 (PENDIENTE) o 2402 (PARCIAL), el backend debe validar que el proveedor tenga registros activos y que la empresa cuente con la capacidad crediticia configurada en parametros_globales.
R.10: Validación del Formato del Número de Factura. numero_factura debe contener solo dígitos numéricos (0-9). La longitud debe coincidir con el parámetro global ''longitud_numero_factura'' (por defecto 7 dígitos).
R.11: Actualización Atómica del Correlativo. Al generar un número de factura, el backend debe incrementar numero_actual en control_facturas en la misma transacción donde se inserta el registro en kardex.
R.12: Validación de Stock en Ventas. Al registrar una venta, el sistema debe validar que cantidad_salida <= cantidad_actual del lote correspondiente. Si el stock es insuficiente, debe rechazar la transacción con el mensaje: "Stock insuficiente. Disponible: X.XX, Solicitado: Y.YY".
R.13: Control de Mermas. Las mermas mensuales por producto no pueden superar el 5% del stock total del mes anterior. Se exige justificación obligatoria en el campo comprobante y, si se excede el umbral, el backend debe generar una alerta automática al gerente requiriendo autorización especial.
R.14: Tipo de Factura. tipo_factura_id utiliza los valores (2350-2352): CF (2350) para factura con derecho a crédito fiscal, SF (2351) para factura sin derecho a crédito fiscal, NCD (2352) para nota de crédito-débito. Este campo complementa a tipo_comprobante_id y numero_factura para identificar el tipo de documento fiscal emitido.
R.15: Estado de Traspaso. estado_traspaso_id utiliza los valores (2100-2103): EN_TRANSITO (2100) para mercancía en movimiento entre sucursales, RECIBIDO (2101) cuando la sucursal destino confirma la recepción, RECHAZADO (2102) cuando el traspaso es cancelado o rechazado, NO_APLICA (2103) para eventos que no son traspasos. Este campo SOLO aplica para eventos de traspaso (evento_id = 1053 EGR_TRASPASO o 1054 ING_TRASPASO). Para otros eventos, debe ser 2103.
R.16: Estado de Pedido (Solicitud de Compra). estado_pedido_id utiliza los valores (2250-2256) exclusivamente para el evento SOLICITUD_COMPRA (1058). Controla el ciclo de vida del pedido: COTIZADO (2250), APROBADO (2251), EN_RUTA (2252), RECIBIDO (2253), PARCIAL (2254), RECHAZADO (2255), CANCELADO (2256). Para cualquier otro evento debe ser NULL.
R.17: Tipo de Despacho. tipo_despacho_id utiliza los valores (3550-3553) exclusivamente para el evento VENTA (1051). Define la modalidad de entrega: VENTA_MOSTRADOR (3550), DOMICILIO (3551), RETIRO (3552), TRANSFERENCIA (3553). Para eventos que no son ventas, el valor por defecto es VENTA_MOSTRADOR (3550).
R.18: Copia del límite de crédito del cliente al momento de la venta.
R.19: El campo comprobante_referencia hace referencia al comprobante en devoluciones. Mismo caso para kardex_referencia_id hace referencia a kardex_id.
R.20: Trazabilidad y Conversión de Solicitudes de Compra. Cuando una solicitud de compra (evento_id = 1058 SOLICITUD_COMPRA) con estado_pedido_id = 2251 (APROBADO) es procesada y transformada en una transacción de compra formal (evento_id = 1050 COMPRA), el backend debe establecer obligatoriamente la relación cruzada asignando el ID de la compra en el campo kardex_pedido_compra_id del registro de origen. Una solicitud aprobada que ya posea una referencia de compra vinculada no podrá ser utilizada nuevamente para generar otra compra, previniendo duplicidades y asegurando la auditoría de extremo a extremo entre el requerimiento y la adquisición.
R.21: nota_credito_debito se usa solo en DEVOLUCION_CLIENTE (evento_id = 1060). Almacena el número secuencial o código de autorización de la Nota de Crédito (o Nota de Débito) generada electrónicamente para respaldar la devolución ante el cliente y ante el ente regulador de impuestos (como el SIN). Diferencia clave: Mientras que el campo comprobante_referencia o kardex_referencia_id apunta al documento o movimiento original (la factura o venta vieja que le dio vida a la operación), el campo nota_credito_debito almacena el número del nuevo documento legal que formaliza la devolución.
R.22: fecha_expiracion Fecha y hora exacta de expiración (calculada a partir de fecha_kardex + validez_dias). Permite que el job diario o el backend evalúe de forma precisa el TTL de la reserva sin depender solo de días enteros.
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
- Si todos los ítems recibidos completamente ? 2253 (RECIBIDO)
- Si algunos ítems recibidos parcialmente ? 2254 (PARCIAL)
- Si ninguno recibido ? 2252 (EN_RUTA)
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
R.36: Generación de Número de Solicitud. Para SOLICITUD_COMPRA (1058), el backend debe generar un número de solicitud con formato: SOL-[SUCURSAL_ID]-[GESTION]-[CORRELATIVO].
R.37: Estado de Reserva. estado_reserva_id utiliza los valores (4850-4854) exclusivamente para el evento VENTA_RESERVA (1059): NO_APLICA (4850), PENDIENTE (4851), CONFIRMADA (4852), CANCELADA (4853), EXPIRADA (4854). Para cualquier otro evento debe ser 4850 (NO_APLICA).
R.38: Validación de Campo Obligatorio - fecha_expiracion.
Para los eventos PROFORMA (1052) y VENTA_RESERVA (1059), el campo fecha_expiracion es OBLIGATORIO. El backend debe validar que no sea NULL.
if (evento_id IN (1052, 1059) && fecha_expiracion === null) {
	throw new Error(fecha_expiracion es obligatoria para PROFORMA y VENTA_RESERVA);
}
Adicionalmente, debe validar que fecha_expiracion sea una fecha futura y mayor a fecha_kardex.

R.39: Validación de Campo Obligatorio - sucursal_destino_id. Para los eventos EGR_TRASPASO (1053) e ING_TRASPASO (1054), el campo sucursal_destino_id es OBLIGATORIO. El backend debe validar que no sea NULL.
if (evento_id IN (1053, 1054) && sucursal_destino_id === null) {
	throw new Error(sucursal_destino_id es obligatoria para traspasos);
}
Adicionalmente, debe validar que sucursal_destino_id sea diferente de sucursal_id y que la sucursal destino exista y esté ACTIVA.

R.40: Validación de Campo Obligatorio - estado_pedido_id.
Para el evento SOLICITUD_COMPRA (1058), el campo estado_pedido_id es OBLIGATORIO y debe iniciar en COTIZADO (2250) o APROBADO (2251).
if (evento_id === 1058 && estado_pedido_id === null) {
	throw new Error(estado_pedido_id es obligatorio para SOLICITUD_COMPRA);
}
if (evento_id === 1058 && estado_pedido_id NOT IN (2250, 2251)) {
	throw new Error(El estado inicial debe ser COTIZADO (2250) o APROBADO (2251));
}

R.41: Validación de Campo Obligatorio - estado_financiero_id.
Para el evento COMPRA (1050), el campo estado_financiero_id es OBLIGATORIO y debe ser CANCELADO (2400), PENDIENTE (2401) o PARCIAL (2402).
if (evento_id === 1050 && estado_financiero_id === null) {
	throw new Error(estado_financiero_id es obligatorio para COMPRA);
}
if (evento_id === 1050 && estado_financiero_id NOT IN (2400, 2401, 2402)) {
	throw new Error(Estado financiero inválido para compra);
}
Adicionalmente, debe validar coherencia con total_pagado según R.33.

R.42: Validación de Fecha de Expiración para PROFORMA y VENTA_RESERVA. El backend debe validar que fecha_expiracion sea mayor a fecha_kardex y que sea una fecha futura.
if (evento_id IN (1052, 1059) && fecha_expiracion <= fecha_kardex) {
	throw new Error(fecha_expiracion debe ser posterior a fecha_kardex);
}
if (evento_id IN (1052, 1059) && fecha_expiracion <= CURRENT_DATE) {
	throw new Error(fecha_expiracion debe ser una fecha futura);
}

R.43: Validación de Destino de Traspaso. El backend debe validar que la sucursal destino exista, esté ACTIVA y sea diferente de la sucursal origen.
const sucursalDestino = await sucursalRepository.findOne({
	where: { sucursal_id: sucursal_destino_id, estado_id: 1000 }
});
if (!sucursalDestino) {
	throw new Error(La sucursal destino no existe o no está activa);
}
if (sucursal_destino_id === sucursal_id) {
	throw new Error(La sucursal origen y destino no pueden ser la misma);
}

R.44: Validación de validez_dias para PROFORMA y VENTA_RESERVA. Para los eventos PROFORMA (1052) y VENTA_RESERVA (1059), validez_dias es OBLIGATORIO.
if (evento_id IN (1052, 1059) && validez_dias === null) {
	throw new Error(validez_dias es obligatorio para PROFORMA y VENTA_RESERVA);
}
if (evento_id IN (1052, 1059) && validez_dias <= 0) {
	throw new Error(validez_dias debe ser mayor a 0);
}

R.45: Validación de Coherencia entre fecha_expiracion y validez_dias. Para PROFORMA (1052) y VENTA_RESERVA (1059), fecha_expiracion debe ser igual a fecha_kardex + validez_dias.
const fechaCalculada = new Date(fecha_kardex);
fechaCalculada.setDate(fechaCalculada.getDate() + validez_dias);
if (fecha_expiracion.getTime() !== fechaCalculada.getTime()) {
	throw new Error(fecha_expiracion no coincide con fecha_kardex + validez_dias);
}

R.46: Validación de Estados Iniciales para Solicitud de Compra. Al crear una SOLICITUD_COMPRA (1058), estado_pedido_id no puede ser un estado final.
const ESTADOS_FINALES = [2253, 2255, 2256]; -- RECIBIDO, RECHAZADO, CANCELADO
if (evento_id === 1058 && estado_pedido_id IN (2253, 2255, 2256)) {
	throw new Error(No se puede crear una solicitud en estado final);
}

R.47: Validación de Límite de Crédito para Compras. Para COMPRA (1050) con estado_financiero_id IN (2401, 2402), validar que el saldo pendiente total no exceda el límite de crédito del proveedor.
const saldoTotal = await kardexRepository.sum(saldo_pendiente, {
	proveedor_id: proveedor_id,
	estado_financiero_id: In([2401, 2402]),
	estado_id: In([1000, 1002])
});
if (saldoTotal > proveedor.limite_credito) {
throw new Error(El saldo pendiente excede el límite de crédito del proveedor);
}

R.48: Validación de Monto Mínimo de Compra. Para COMPRA (1050), validar que total_compra >= proveedores.monto_minimo_compra.
if (total_compra < proveedor.monto_minimo_compra) {
	throw new Error(El monto de compra no alcanza el monto mínimo requerido por el proveedor);
}

R.49: Validación de Estado Financiero para Compras a Crédito. Para COMPRA (1050) con estado_financiero_id IN (2401, 2402), validar que el proveedor tenga rating_calidad_id diferente de PESIMO (2050).
if (proveedor.rating_calidad_id === 2050) {
	throw new Error(El proveedor tiene rating PÉSIMO. Se requiere autorización especial para compras a crédito);
}';

-- ================================================================================================

CREATE TABLE ordenes_compra (
    orden_compra_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
    proveedor_id BIGINT NOT NULL,
    numero_orden VARCHAR(50) NOT NULL,
    fecha_orden DATE NOT NULL,
    fecha_entrega_estimada DATE NULL,
    fecha_entrega_real DATE NULL,
    estado_pedido_id SMALLINT NOT NULL DEFAULT 2250,	-- 2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO
    observaciones VARCHAR(1000) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ordenescompra_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_ordenescompra_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_ordenescompra_estadopedidoid CHECK (estado_pedido_id IN (2250, 2251, 2252, 2253, 2254, 2255, 2256)),
    CONSTRAINT chk_ordenescompra_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_ordenescompra_fechas CHECK (fecha_entrega_estimada IS NULL OR fecha_orden <= fecha_entrega_estimada),
    CONSTRAINT chk_ordenescompra_fechareal CHECK (fecha_entrega_real IS NULL OR fecha_orden <= fecha_entrega_real)
);
CREATE UNIQUE INDEX uix_ordenescompra_numeroorden_unique ON ordenes_compra (numero_orden) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_ordenescompra_proveedorid ON ordenes_compra(proveedor_id);
CREATE INDEX idx_ordenescompra_kardexid ON ordenes_compra(kardex_id);

COMMENT ON TABLE ordenes_compra IS 'Reglas de la tabla - ordenes_compra
R.0: La tabla ordenes_compra registra las órdenes de compra emitidas a los proveedores para el abastecimiento de productos, enlazándose directamente con la tabla kardex y la tabla proveedores. Su propósito es controlar el ciclo de vida del pedido, desde su cotización hasta su recepción o anulación.
R.1: El número de orden (numero_orden) debe ser único para registros activos o anulados (estado_id IN (1000, 1003)), evitando duplicidades en la numeración oficial de compras.
R.2: El estado del pedido se controla mediante estado_pedido_id, vinculándose a los valores de estados de pedido (2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO).
R.3: Cada orden de compra está vinculada obligatoriamente a un registro en kardex mediante fk_oc_kardex_id y a un proveedor mediante fk_oc_proveedor_id.';

-- ================================================================================================

CREATE TABLE instituciones (
    institucion_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    institucion VARCHAR(150) NOT NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(100) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_instituciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_instituciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_instituciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_instituciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_instituciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_instituciones_institucion_notempty CHECK (TRIM(institucion) <> ''),
    CONSTRAINT chk_instituciones_institucion_mayusculas CHECK (institucion = UPPER(institucion)),
    CONSTRAINT chk_instituciones_institucion_minlength CHECK (LENGTH(TRIM(institucion)) >= 3)
);
CREATE UNIQUE INDEX uix_instituciones_codigo_unique ON instituciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_instituciones_institucion_unique ON instituciones (institucion) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE instituciones IS 'Reglas de la tabla - instituciones
R.1: La tabla instituciones almacena el catálogo de centros de salud, clínicas y hospitales donde trabajan los médicos que emiten recetas. Su propósito es normalizar y consolidar la información de las instituciones médicas para reportes y análisis gerenciales.
R.2: codigo es un identificador alfanumérico único de la institución, ingresado manualmente por el administrador. Debe estar en mayúsculas y tener al menos 3 caracteres.
R.3: nombre debe estar en mayúsculas y ser único para registros activos o históricos.
R.4: direccion y telefono son campos opcionales que permiten registrar información de contacto para futuros módulos de comunicación o verificación de institucion.
R.5: El registro con institucion_id = institucionmbre = ''NINGUNO / OTRO'' es el registro comodín que actúa como valor predeterminado para las FK que requieran una institución de referencia. Su estado_id = 1002 lo mantiene en estado HISTORICO, excluyéndolo de los combos operativos pero preservando la integridad referencial.';

-- ================================================================================================

CREATE TABLE especialidades (
    especialidad_id BIGSERIAL PRIMARY KEY,
    especialidad VARCHAR(150) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_especialidades_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_especialidades_especialidad_notempty CHECK (TRIM(especialidad) <> ''),
    CONSTRAINT chk_especialidades_especialidad_mayusculas CHECK (especialidad = UPPER(especialidad))
);
CREATE UNIQUE INDEX uix_especialidades_especialidad_unique ON especialidades (especialidad) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE especialidades IS 'Reglas de la tabla - especialidades
R.0: La especialidad se almacena en mayúsculas para garantizar uniformidad en la búsqueda y agrupación.';

-- ================================================================================================

CREATE TABLE medicos (
    medico_id BIGSERIAL PRIMARY KEY,
    medico VARCHAR(150) NOT NULL,
    matricula VARCHAR(50) NOT NULL,
    especialidad_id BIGINT NOT NULL DEFAULT 1,
    telefono VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_medicos_especialidad_id FOREIGN KEY (especialidad_id) REFERENCES especialidades(especialidad_id),
    CONSTRAINT chk_medicos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_medicos_medico_notempty CHECK (TRIM(medico) <> ''),
    CONSTRAINT chk_medicos_medico_minlength CHECK (LENGTH(TRIM(medico)) >= 3),
    CONSTRAINT chk_medicos_matricula_notempty CHECK (TRIM(matricula) <> ''),
    CONSTRAINT chk_medicos_matricula_minlength CHECK (LENGTH(TRIM(matricula)) >= 3),
    CONSTRAINT chk_medicos_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);
CREATE UNIQUE INDEX uix_medicos_medico_unique ON medicos (medico) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_medicos_matricula_unique ON medicos (matricula) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_medicos_especialidadid ON medicos (especialidad_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_medicos_estadoid ON medicos (estado_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE medicos IS 'Reglas de la tabla - medicos
R.0: La tabla medicos constituye el catálogo maestro de profesionales de la salud que prestan servicios en la farmacia, almacenando información personal, credenciales profesionales y datos de contacto. Su función principal es respaldar la prescripción de medicamentos, la emisión de recetas y la trazabilidad de los tratamientos médicos, garantizando la integridad y legalidad de las transacciones farmacéuticas.
R.1: medico almacena el nombre completo del profesional de la salud, incluyendo título profesional cuando corresponda.
R.2: matricula corresponde al número de registro profesional emitido por la autoridad competente (ej. Colegio Médico), es un identificador único para cada profesional.';

-- ================================================================================================

CREATE TABLE recetas (
    receta_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
    cliente_id BIGINT NOT NULL,
    sucursal_id BIGINT NOT NULL,
    medico_id BIGINT NOT NULL DEFAULT 1,
    institucion_id BIGINT NOT NULL DEFAULT 1,
    tipo_receta_id SMALLINT NOT NULL DEFAULT 3853,  	-- 3850=SIMPLE, 3851=ARCHIVADA, 3852=VALADA, 3853=NINGUNO
    numero_receta VARCHAR(60) NOT NULL,
    fecha_emision DATE NOT NULL,
    diagnostico VARCHAR(250) NULL,
    receta_pdf VARCHAR(100) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_recetas_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_recetas_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_recetas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_recetas_medico_id FOREIGN KEY (medico_id) REFERENCES medicos(medico_id),
    CONSTRAINT fk_recetas_institucion_id FOREIGN KEY (institucion_id) REFERENCES instituciones(institucion_id),
    CONSTRAINT chk_recetas_tiporeceaid CHECK (tipo_receta_id IN (3850, 3851, 3852, 3853)),
    CONSTRAINT chk_recetas_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_recetas_numeroreceta_notempty CHECK (TRIM(numero_receta) <> ''),
    CONSTRAINT chk_recetas_numeroreceta_minlength CHECK (LENGTH(TRIM(numero_receta)) >= 3),
    CONSTRAINT chk_recetas_fechaemision_valida CHECK (fecha_emision <= CURRENT_DATE)
);
CREATE UNIQUE INDEX uix_recetas_numeroreceta_unique ON recetas (numero_receta) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_recetas_varios_unique ON recetas (kardex_id, cliente_id, medico_id, fecha_emision) WHERE estado_id = 1000;
CREATE INDEX idx_recetas_institucionid ON recetas(institucion_id);
CREATE INDEX idx_recetas_sucursalid ON recetas(sucursal_id);

COMMENT ON TABLE recetas IS 'Reglas de la tabla - recetas
R.0: La tabla recetas constituye el registro maestro de prescripciones médicas emitidas en la farmacia, almacenando la información completa de cada receta incluyendo el médico, paciente, institución y diagnóstico asociado. Su función principal es respaldar la dispensación de medicamentos, garantizar la trazabilidad de los tratamientos y cumplir con los requisitos legales de control de medicamentos controlados.
R.1: numero_receta es un identificador alfanumérico único que puede ser generado automáticamente por el sistema o ingresado manualmente desde el formulario, según la configuración de la sucursal.
R.2: fecha_emision registra la fecha en que el médico emitió la receta. La restricción chk_rec_fecha_emision_valida garantiza que no sea una fecha futura.
R.3: receta_pdf almacena el nombre del archivo PDF que contiene la imagen digitalizada o escaneada de la receta física. El formato debe ser ''.pdf'' y el nombre solo debe contener caracteres alfanuméricos, guiones o guiones bajos.
R.4: tipo_receta_id clasifica la receta según su régimen legal: SIMPLE (medicamentos comunes), ARCHIVADA (psicotrópicos con retención obligatoria) o VALADA (estupefacientes con control estricto).
R.5: El diagnóstico es un campo descriptivo que puede contener el código CIE-10 o una descripción textual de la condición del paciente.';

-- ================================================================================================

CREATE TABLE lotes_productos (
    lote_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(60) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    cantidad_inicial DECIMAL(12,2) NOT NULL,
    cantidad_actual DECIMAL(12,2) NOT NULL,
    cantidad_reservada DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    precio_costo DECIMAL(12,2) NOT NULL,
    fecha_fabricacion DATE NULL,
    lote_proveedor VARCHAR(50) NULL,
    ubicacion_id BIGINT NULL,
    ultimo_movimiento TIMESTAMPTZ NULL,
    rating_calidad_id SMALLINT DEFAULT 2055,            -- 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
    estado_lote_id SMALLINT NOT NULL DEFAULT 2503,      -- 2500=VIGENTE, 2501=VENCIDO, 2502=AGOTADO, 2503=NINGUNO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_lotesproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_lotesproductos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
	CONSTRAINT fk_lotesproductos_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
	CONSTRAINT chk_lotesproductos_estadoloteid CHECK (estado_lote_id IN (2500, 2501, 2502, 2503)),
	CONSTRAINT chk_lotesproductos_ratingcalidadid CHECK (rating_calidad_id IN (2050, 2051, 2052, 2053, 2054, 2055)),
	CONSTRAINT chk_lotesproductos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
	CONSTRAINT chk_lotesproductos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_lotesproductos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_lotesproductos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_lotesproductos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_lotesproductos_fechavencimiento CHECK (fecha_vencimiento > '2000-01-01'),
	CONSTRAINT chk_lotesproductos_cantidadinicial CHECK (cantidad_inicial > 0),
	CONSTRAINT chk_lotesproductos_cantidadactual CHECK (cantidad_actual >= 0),
	CONSTRAINT chk_lotesproductos_cantidadreservada CHECK (cantidad_reservada >= 0),
	CONSTRAINT chk_lotesproductos_preciocosto CHECK (precio_costo >= 0),
	CONSTRAINT chk_lotesproductos_cantidadcoherencia CHECK (cantidad_actual <= cantidad_inicial),
	CONSTRAINT chk_lotesproductos_varios CHECK (cantidad_actual + cantidad_reservada <= cantidad_inicial)
);
CREATE UNIQUE INDEX uix_lotesproductos_varios_unique ON lotes_productos (producto_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lotesproductos_productoid ON lotes_productos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lotesproductos_fechavencimiento ON lotes_productos (fecha_vencimiento) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lotesproductos_ubicacionid ON lotes_productos (ubicacion_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_lotesproductos_kardexid ON lotes_productos(kardex_id);
CREATE INDEX idx_lotesproductos_actividad_estadoid ON lotes_productos (COALESCE(fecha_actualizacion, fecha_registro), estado_id);

COMMENT ON TABLE lotes_productos IS 'Reglas de la tabla - lotes_productos
R.0: La tabla lotes_productos es el núcleo del control de inventario físico, representando la llegada de una cantidad de un producto con un precio de costo, fecha de vencimiento y una existencia inicial. Su propósito es permitir la trazabilidad FIFO (primero en entrar, primero en salir), controlar el stock por lote, gestionar el costo de venta y la ubicación física, así como las alertas de vencimiento y agotamiento de inventario.
R.1: Gestión de Stock y Reservas. cantidad_actual representa el stock disponible para venta o despacho. cantidad_reservada representa el stock apartado para ventas en proceso o reservas (VENTA_RESERVA). El stock total del lote se define como stock_total = cantidad_actual + cantidad_reservada, y el sistema valida estrictamente que stock_total <= cantidad_inicial.
R.2: Control de Stock por Lote en Ventas. Al registrar una venta, el backend debe validar que la cantidad solicitada <= cantidad_actual del lote. Si el stock disponible es insuficiente, debe rechazar la transacción con el mensaje: "Stock insuficiente en lote X. Disponible: Y.YY, Solicitado: Z.ZZ".
R.3: Precios de Lote vs Producto. precio_costo es específico del lote y puede diferir del precio base del producto (productos.pcompra). El sistema utiliza el precio_costo del lote para calcular el costo_venta en kardex_productos. Los precios de venta se gestionan en productos (catálogo) y kardex_productos (transaccional).
R.4: Control de Vencimientos y Calidad. El frontend debe mostrar alertas visuales cuando fecha_vencimiento esté próxima según los parámetros globales ''dias_alerta_vencimiento_critico'' (15 días), ''dias_alerta_vencimiento_alta'' (30 días) y ''dias_alerta_vencimiento_media'' (60 días). El campo rating_calidad_id utiliza los valores (2050-2054, con 2055 por defecto como NINGUNO) para el control de calidad interna.
R.5: Inmutabilidad del Código de Lote y Trazabilidad del Proveedor. codigo se genera automáticamente por el backend al registrar una compra o ajuste de inventario y no puede ser modificado por el usuario (patrón: [PREFIJO]-[PRODUCTO_ID]-[FECHA]-[CORRELATIVO]). El campo lote_proveedor almacena el código de lote original emitido por el proveedor para facilitar la trazabilidad externa.
R.6: Bloqueo de Lotes Agotados y Estados Automáticos. Un lote con cantidad_actual = 0 se bloquea automáticamente para nuevas ventas (estado_lote_id = 2502 AGOTADO), pero permanece visible en el histórico. Solo puede reactivarse mediante un ajuste que incremente cantidad_actual. Adicionalmente, el backend gestiona la actualización automática a VENCIDO (2501) si fecha_vencimiento < CURRENT_DATE.
R.7: Fuente de Verdad del Costo. El campo precio_costo almacena el costo de adquisición del lote en el momento de su creación. Este valor es la fuente de verdad para el costo de venta y se copia al campo pcompra de kardex_productos al momento de cada transacción que afecte este lote.
R.8: Ubicación y Auditoría de Movimientos. ubicacion_id indica el depósito físico actual del lote y puede ser NULL si se encuentra en tránsito o sin asignar. El backend es responsable de mantener actualizados los campos ultimo_movimiento y fecha_actualizacion ante cualquier cambio de estado o stock.';

-- ================================================================================================

CREATE TABLE kardex_productos (
    kardex_producto_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    lote_id BIGINT NOT NULL DEFAULT 1,
    presentacion_id BIGINT NOT NULL DEFAULT 1,
    tipo_pago_id BIGINT NOT NULL DEFAULT 1400,  	-- 1400=NINGUNO, 1401=EFECTIVO, 1402=TARJETA, 1403=CHEQUE, 1404=VALE, 1405=OTROS, 1406=SIN_PAGO, 1407=TRANSFERENCIA, 1408=DEPOSITO, 1409=QR
	tipo_venta_id SMALLINT NOT NULL DEFAULT 1350,  	-- 1350=NINGUNO, 1351=CON_FACTURA, 1352=SIN_FACTURA
	kardex_producto_origen_id BIGINT NOT NULL DEFAULT 1,
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
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_kardexproductos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_kardexproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_kardexproductos_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_kardexproductos_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
    CONSTRAINT fk_kardexproductos_presentacion_id FOREIGN KEY (presentacion_id) REFERENCES presentaciones(presentacion_id),
    CONSTRAINT fk_kardexproductos_kardex_producto_origen_id FOREIGN KEY (kardex_producto_origen_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT chk_kardexproductos_tipopagoid CHECK (tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409)),
    CONSTRAINT chk_kardexproductos_tipoventaid CHECK (tipo_venta_id IN (1350, 1351, 1352)),
    CONSTRAINT chk_kardexproductos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_kardexproductos_pcompra CHECK (pcompra >= 0),
    CONSTRAINT chk_kardexproductos_factorventa CHECK (factor_venta >= 0),
    CONSTRAINT chk_kardexproductos_factorfacturacion CHECK (factor_facturacion >= 0),
    CONSTRAINT chk_kardexproductos_precioventa CHECK (precio_venta >= 0),
    CONSTRAINT chk_kardexproductos_precioventafactura CHECK (precio_venta_factura >= 0),
    CONSTRAINT chk_kardexproductos_costoventa CHECK (costo_venta >= 0),
    CONSTRAINT chk_kardexproductos_descuento CHECK (descuento >= 0),
    CONSTRAINT chk_kardexproductos_cantidades CHECK (
        (cantidad >= 0 AND cantidad_salida = 0) OR
        (cantidad = 0 AND cantidad_salida >= 0) OR
        (cantidad = 0 AND cantidad_salida = 0)
    )    
);
CREATE UNIQUE INDEX uix_kardexproductos_varios_unique ON kardex_productos (kardex_id, producto_id, lote_id) WHERE estado_id = 1000;
CREATE INDEX idx_kardexproductos_kardexid ON kardex_productos (kardex_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_kardexproductos_tipoventaid_fecharegistro ON kardex_productos (tipo_venta_id, fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_kardexproductos_loteid_sucursalid ON kardex_productos (lote_id, sucursal_id) WHERE estado_id = 1000;
CREATE INDEX idx_kardexproductos_presentacionid ON kardex_productos(presentacion_id);
CREATE INDEX idx_kardexproductos_kardexproductoorigenid ON kardex_productos (kardex_producto_origen_id) WHERE estado_id = 1000;
CREATE INDEX idx_kardexproductos_actividad_estadoid ON kardex_productos (COALESCE(fecha_actualizacion, fecha_registro), estado_id);

COMMENT ON TABLE kardex_productos IS 'Reglas de la tabla - kardex_productos
R.0: La tabla kardex_productos es el detalle transaccional de cada movimiento de inventario, registrando las cantidades de entrada o salida de un producto específico, su precio y el lote afectado. Su propósito es registrar el impacto cuantitativo y financiero de las transacciones en el inventario, permitiendo la actualización del stock, el cálculo del costo de venta y la auditoría detallada de cada ítem de compra o venta.
R.1: Destino de Flujos de Inventario. Para movimientos de entrada (COMPRA, TRANSFERENCIA_IN) las unidades se guardan exclusivamente en cantidad y cantidad_salida se fija en 0.00. Para movimientos de salida (VENTA, PROFORMA, TRANSFERENCIA_OUT, MERMA) las unidades se registran en cantidad_salida y cantidad se fija en 0.00. La restricción chk_kp_cantidades valida esta condición.
R.2: Control de Equivalencia de Unidades. cantidad_unidad_base almacena el subtotal físico del ítem transformado matemáticamente a su mínima unidad de fraccionamiento comercial (ej. tabletas sueltas o mililitros). Este valor es inyectado por el backend multiplicando la cantidad física por el factor del empaque para actualizar en tiempo real el stock consolidado de los lotes.
R.3: Metodología de Costeo Operativo. costo_venta registra el valor real de adquisición de las salidas y se determina en el backend calculando el precio de compra de origen indexado según la fracción del producto despachado. Este campo permanece estrictamente oculto para los cajeros en las vistas de ventas y se reserva de manera exclusiva para reportes gerenciales de margen y rentabilidad líquida.
R.4: Determinación de Precios por Tipo de Venta. Si tipo_venta_id = 1351 (CON FACTURA), la venta se tasa sobre precio_venta_factura y se bloquea la modificación del precio base. Si tipo_venta_id = 1352 (SIN FACTURA), los cálculos parciales se realizan sobre precio_venta. Cualquier deducción registrada en descuento se substrae del subtotal neto antes de consolidar la fila.
R.5: Cuando la cabecera transaccional corresponda al evento PROFORMA (1052), el sistema debe forzar tipo_pago_id = 1400 (NINGUNO) y tipo_venta_id = 1350 (NINGUNO) en los detalles, ya que una proforma no implica un cobro efectivo ni una venta formal.
R.6: Control de Conversión de Unidades. cantidad_unidad_base debe calcularse multiplicando la cantidad por el factor_conversion registrado en la tabla conversiones_unidad para el producto y las unidades involucradas.
R.7: Registro Inicial Comodín. El registro con kardex_producto_id = 1 es un registro de referencia con estado_id = 1000 (ACTIVO). Sirve como valor predeterminado para las FK que requieran un detalle de kardex de referencia.
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

-- ================================================================================================

CREATE TABLE inventarios_fisicos_detalle (
    inventario_fisico_detalle_id BIGSERIAL PRIMARY KEY,
    inventario_fisico_id BIGINT NOT NULL DEFAULT 1,
    producto_id BIGINT NOT NULL DEFAULT 1,
    lote_id BIGINT NOT NULL DEFAULT 1,
    ubicacion_id BIGINT NOT NULL DEFAULT 1,
    cantidad_sistema DECIMAL(12,2) NOT NULL,
    cantidad_contada DECIMAL(12,2) NOT NULL,
    diferencia DECIMAL(12,2) NOT NULL DEFAULT 0,
    observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_inventariosfisicosdetalle_inventario_fisico_id FOREIGN KEY (inventario_fisico_id) REFERENCES inventarios_fisicos(inventario_fisico_id),
	CONSTRAINT fk_inventariosfisicosdetalle_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_inventariosfisicosdetalle_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
	CONSTRAINT fk_inventariosfisicosdetalle_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
	CONSTRAINT chk_inventariosfisicosdetalle_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
	CONSTRAINT chk_inventariosfisicosdetalle_cantidades CHECK (cantidad_sistema >= 0 AND cantidad_contada >= 0)
);
CREATE UNIQUE INDEX uix_inventariosfisicosdetalle_varios_unique ON inventarios_fisicos_detalle (inventario_fisico_id, lote_id, ubicacion_id) WHERE estado_id = 1000;

COMMENT ON TABLE inventarios_fisicos_detalle IS 'Reglas de la tabla - inventarios_fisicos_detalle
R.0: Almacena el desglose ítem por ítem de cada producto, lote y ubicación contados durante un proceso de inventario físico.
R.1: Stock Teórico. cantidad_sistema refleja el stock teórico registrado en el sistema antes de iniciar el conteo físico.
R.2: Stock Físico. cantidad_contada representa la cantidad física real obtenida mediante el conteo en almacén.
R.3: Diferencia Automática. La columna diferencia se calcula de forma automática mediante la expresión almacenada (cantidad_contada - cantidad_sistema).
R.4: Acciones de Ajuste. Si la diferencia es distinta de cero (diferencia <> 0) al momento de cerrar el inventario físico, el backend debe generar automáticamente un movimiento de ajuste de inventario asociado (evento_id = 1065 para sobrantes o 1066 para faltantes).';

-- ================================================================================================

CREATE TABLE ubicaciones_movimientos (
    ubicacion_movimiento_id BIGSERIAL PRIMARY KEY,
    kardex_producto_id BIGINT NOT NULL,
    ubicacion_origen_id BIGINT NULL,
    ubicacion_destino_id BIGINT NOT NULL,
    lote_id BIGINT NOT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    tipo_ubicacion_movimiento_id SMALLINT NOT NULL DEFAULT 3200,      -- 3200=INGRESO, 3201=EGRESO
    motivo VARCHAR(500) NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ubicacionesmovimientos_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT fk_ubicacionesmovimientos_ubicacion_origen_id FOREIGN KEY (ubicacion_origen_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ubicacionesmovimientos_ubicacion_destino_id FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ubicacionesmovimientos_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
    CONSTRAINT chk_ubicacionesmovimientos_tipoubicacionmovimientoid CHECK (tipo_ubicacion_movimiento_id IN (3200, 3201)),
    CONSTRAINT chk_ubicacionesmovimientos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicacionesmovimientos_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_ubicacionesmovimientos_ubicacionesdiferentes CHECK (ubicacion_origen_id IS NULL OR ubicacion_origen_id <> ubicacion_destino_id)
);
CREATE INDEX idx_ubicacionesmovimientos_kardexproductoid ON ubicaciones_movimientos (kardex_producto_id);
CREATE INDEX idx_ubicacionesmovimientos_fechamovimiento ON ubicaciones_movimientos (fecha_movimiento DESC);
CREATE INDEX idx_ubicacionesmovimientos_ubicaciondestinoid ON ubicaciones_movimientos (ubicacion_destino_id);
CREATE INDEX idx_ubicacionesmovimientos_loteid ON ubicaciones_movimientos (lote_id);

COMMENT ON TABLE ubicaciones_movimientos IS 'Reglas de la tabla - ubicaciones_movimientos
R.0: La tabla ubicaciones_movimientos registra todos los movimientos físicos de productos entre ubicaciones, permitiendo una auditoría completa de la logística interna, la trazabilidad por lote y el control detallado de las transferencias de inventario.
R.1: Origen y Destino de las Transferencias. El campo ubicacion_origen_id representa el punto de partida de la mercancía y puede ser NULL únicamente cuando se trata de un ingreso inicial de inventario al sistema o una recepción externa sin precedentes en ubicaciones internas previas. El campo ubicacion_destino_id is obligatorio e indica el punto final donde se ubica físicamente el lote.
R.2: Validación y Actualización Automática de Stock. El backend es responsable de validar las reglas de capacidad de la ubicación de destino antes de confirmar la inserción, así como de actualizar de manera automática y transaccional el campo stock_actual tanto en la ubicación de origen (si aplica) como en la de destino.
R.3: Cantidades y Restricciones Estrictas. La columna cantidad se expresa en la unidad base del producto y debe cumplir estrictamente con la restricción de ser mayor a cero (cantidad > 0). Asimismo, se valida por restricción a nivel de base de datos que la ubicación de origen y la de destino nunca sean iguales, evitando bucles lógicos en la transferencia.
R.4: Inmutabilidad Histórica. Las filas registradas en esta tabla poseen un carácter inmutable para garantizar la integridad de las auditorías de inventario físico. No se permiten modificaciones (UPDATE) ni eliminaciones directas (DELETE) sobre los registros históricos de movimientos de ubicación.';

-- ================================================================================================

CREATE TABLE ubicaciones_historial (
    ubicacion_historial_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL,
    ubicacion_origen_id BIGINT NULL,
    ubicacion_destino_id BIGINT NOT NULL,
    kardex_producto_id BIGINT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ubicacioneshistorial_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_ubicacioneshistorial_ubicacion_origen_id FOREIGN KEY (ubicacion_origen_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ubicacioneshistorial_ubicacion_destino_id FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ubicacioneshistorial_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT fk_ubicacioneshistorial_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_ubicacioneshistorial_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicacioneshistorial_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_ubicacioneshistorial_motivo CHECK (TRIM(motivo) <> ''),
    CONSTRAINT chk_ubicacioneshistorial_ubicacionesdiferentes CHECK (ubicacion_origen_id IS NULL OR ubicacion_origen_id <> ubicacion_destino_id)
);
CREATE INDEX idx_ubicacioneshistorial_productoid ON ubicaciones_historial (producto_id);
CREATE INDEX idx_ubicacioneshistorial_fechamovimiento ON ubicaciones_historial (fecha_movimiento DESC);
CREATE INDEX idx_ubicacioneshistorial_ubicaciondestinoid ON ubicaciones_historial (ubicacion_destino_id);
CREATE INDEX idx_ubicacioneshistorial_trabajadorid ON ubicaciones_historial (trabajador_id);
CREATE INDEX idx_ubicacioneshistorial_varios ON ubicaciones_historial (trabajador_id, fecha_movimiento DESC);
CREATE INDEX idx_ubicacioneshistorial_kardexproductoid ON ubicaciones_historial(kardex_producto_id);
CREATE INDEX idx_ubicacioneshistorial_ubicacionorigenid ON ubicaciones_historial(ubicacion_origen_id);

COMMENT ON TABLE ubicaciones_historial IS 'Reglas de la tabla - ubicaciones_historial
R.0: La tabla ubicaciones_historial actúa como el registro de auditoría de todos los movimientos de productos entre ubicaciones dentro de los almacenes[cite: 1]. Su propósito es proporcionar trazabilidad completa sobre cuándo, quién (trabajador responsable) y por qué se movió un producto de una ubicación a otra[cite: 1], permitiendo análisis de eficiencia de picking, detección de errores logísticos y cumplimiento de procedimientos operativos[cite: 1].
R.1: Registro Obligatorio de Movimientos: Cada vez que un producto cambia de ubicación (ya sea por venta, reabastecimiento, ajuste de inventario o reubicación manual)[cite: 1], el sistema debe insertar automáticamente un registro en esta tabla[cite: 1]. El backend es responsable de generar este registro de forma atómica junto con la operación que origina el movimiento[cite: 1].
R.2: Vinculación con Transacciones: El campo kardex_producto_id permite asociar el movimiento de ubicación con una transacción específica (venta, compra, ajuste, traspaso)[cite: 1], proporcionando trazabilidad completa desde el documento fiscal hasta la ubicación física del producto[cite: 1].
R.3: Motivos de Movimiento: El campo motivo debe documentar claramente la razón del movimiento[cite: 1], utilizando valores estandarizados como: ''VENTA'', ''COMPRA'', ''REABASTECIMIENTO'', ''AJUSTE_INVENTARIO'', ''TRASPASO'', ''REUBICACION_MANUAL'', ''DEVOLUCION'', ''CADUCIDAD'', etc[cite: 1]. El frontend debe presentar un combo con estas opciones predefinidas para garantizar consistencia en el registro[cite: 1].
R.4: Control de Fechas y Auditoría: fecha_movimiento registra el momento exacto en que ocurrió el movimiento físico[cite: 1], mientras que fecha_registro puede diferir ligeramente por latencia de red[cite: 1]. El sistema debe utilizar fecha_movimiento como fuente de verdad para reportes de trazabilidad[cite: 1].
R.5: Cantidad y Unidades: El campo cantidad almacena la cantidad de producto movida, expresada en unidades base del producto (ej. tabletas, mililitros)[cite: 1]. Esta cantidad debe ser positiva y corresponde al total de unidades trasladadas[cite: 1].
R.6: Inmutabilidad del Historial: Los registros en esta tabla son inmutables por diseño[cite: 1]. No se permiten operaciones UPDATE o DELETE sobre registros existentes[cite: 1]. Cualquier corrección debe realizarse mediante un nuevo registro que anule o complemente el movimiento anterior[cite: 1], manteniendo la trazabilidad completa sin pérdida de información[cite: 1].
R.7: Registro Comodín: El sistema debe mantener un registro inicial con ubicacion_historial_id = 1 que sirve como valor predeterminado para las FK que requieran un historial de referencia[cite: 1]. Este registro se asocia al trabajador comodín (trabajador_id = 1), tiene estado_id = 1002 (HISTORICO) y no puede ser modificado ni eliminado[cite: 1].
R.8: Consultas y Reportes: Los índices estratégicos (idx_ubicacioneshistorial_productoid, idx_ubicacioneshistorial_fechamovimiento, idx_ubicacioneshistorial_ubicaciondestinoid, idx_ubicacioneshistorial_trabajadorid) garantizan consultas rápidas para reportes de trazabilidad, análisis de eficiencia de picking y auditorías de inventario[cite: 1].
R.9: Integración con Módulos: Esta tabla se integra con los módulos de:
- Ventas: Registra la salida de productos del almacén al cliente[cite: 1].
- Compras: Registra la entrada de productos al almacén desde proveedores[cite: 1].
- Inventario: Registra reubicaciones, ajustes y traspasos[cite: 1].
- Devoluciones: Registra movimientos de productos devueltos[cite: 1].
- Caducidad: Registra movimientos de productos vencidos a zonas de cuarentena[cite: 1].';

-- ================================================================================================

CREATE TABLE tipos_planes_pago (
    tipo_plan_pago_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    meses_plazo SMALLINT NOT NULL DEFAULT 0,
    porcentaje_recargo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    monto_fijo_recargo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    permite_personalizar SMALLINT NOT NULL DEFAULT 0,   -- 1=Sí (permite alterar cuotas y fechas), 0=No (cuotas fijas automáticas)
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_tiposplanespago_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
	CONSTRAINT chk_tiposplanespago_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_tiposplanespago_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_tiposplanespago_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_tiposplanespago_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_tiposplanespago_mesesplazo_mincero CHECK (meses_plazo >= 0),
    CONSTRAINT chk_tiposplanespago_porcentajerecargo CHECK (porcentaje_recargo >= 0),
    CONSTRAINT chk_tiposplanespago_montofijorecargo CHECK (monto_fijo_recargo >= 0),
    CONSTRAINT chk_tiposplanespago_permitepersonalizar CHECK (permite_personalizar IN (0, 1))
);
CREATE UNIQUE INDEX uix_tiposplanespago_codigo_unique ON tipos_planes_pago (codigo) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE tipos_planes_pago IS 'Reglas de la tabla - tipos_planes_pago
R.0: La tabla tipos_planes_pago define las modalidades, políticas y condiciones financieras bajo las cuales se estructuran los financiamientos o créditos otorgados en las transacciones. Su propósito es estandarizar los plazos, recargos y grados de flexibilidad permitidos al generar los cronogramas de pagos.
R.1: Identificador y Unicidad del Código. El campo codigo representa la clave única y normalizada del tipo de plan (en mayúsculas y sin espacios), garantizando que no existan duplicados entre los registros activos o históricos.
R.2: Parámetros Financieros y Recargos. Los campos meses_plazo, porcentaje_recargo y monto_fijo_recargo establecen las reglas base de cálculo para incrementar el monto total financiado según la modalidad seleccionada, validando estrictamente que no posean valores negativos.
R.3: Flexibilidad Operativa (Permite Personalizar). El campo permite_personalizar opera como indicador binario (0 o 1) que condiciona al backend en la generación del cronograma: si es 1, autoriza la alteración manual de cuotas y fechas específicas; si es 0, obliga al sistema a generar cuotas fijas y automáticas de manera estricta.';

-- ================================================================================================

CREATE TABLE planes_pagos (
    plan_pago_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    numero_cuota SMALLINT NOT NULL,
    monto_programado DECIMAL(12,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado_pago_id SMALLINT NOT NULL DEFAULT 2555,  	-- 2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO
    fecha_pago DATE NULL,
    monto_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    observaciones VARCHAR(1000) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_planespagos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT chk_planespagos_estadopagoid CHECK (estado_pago_id IN (2550, 2551, 2552, 2553, 2554, 2555)),
    CONSTRAINT chk_planespagos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_planespagos_numerocuota CHECK (numero_cuota > 0),
    CONSTRAINT chk_planespagos_montoprogramado CHECK (monto_programado >= 0),
    CONSTRAINT chk_planespagos_montopagado CHECK (monto_pagado >= 0),
    CONSTRAINT chk_planespagos_montocoherencia_coherencia CHECK (monto_pagado <= monto_programado),
    CONSTRAINT chk_planespagos_fechavencimiento CHECK (fecha_vencimiento > '2000-01-01'),
    CONSTRAINT chk_planespagos_fechapago CHECK (fecha_pago IS NULL OR fecha_pago > '2000-01-01')
);
CREATE UNIQUE INDEX uix_planespagos_varios_unique ON planes_pagos (kardex_id, numero_cuota) WHERE estado_id = 1000;
CREATE INDEX idx_planespagos_kardex ON planes_pagos (kardex_id) WHERE estado_id = 1000;
CREATE INDEX idx_planespagos_fechavencimiento ON planes_pagos (fecha_vencimiento) WHERE estado_id = 1000;

COMMENT ON TABLE planes_pagos IS 'Reglas de la tabla - planes_pagos
R.0: La tabla planes_pagos gestiona el calendario de vencimientos para las compras a crédito a proveedores, registrando las cuotas programadas y su estado de pago. Su propósito es administrar la deuda con los proveedores, facilitando la planificación financiera y el control de los pasivos, permitiendo registrar abonos parciales y ajustar automáticamente el estado de las cuotas.
R.1: Control de Ciclo de Vida y Cierre. estado_pago_id califica de manera estricta el avance transaccional de la cuota. Pasará automáticamente a 2552 (PAGADO) o 2553 (CERRADO) cuando el monto_pagado iguale al monto_programado (saldo igual a 0.00). El frontend inhabilitará de forma inmediata la edición o inserción de nuevos abonos sobre registros cuyo estado_pago_id sea distinto de 2550 (PENDIENTE) o 2551 (PARCIAL) para proteger la integridad contable.
R.2: Diferenciación de Capas. estado_id regula únicamente el borrado lógico y el comportamiento de anulación en el sistema general (''ACTIVO'', ''BORRADO'', ''ANULADO''), operando de forma independiente a los procesos de liquidación comercial controlados por estado_pago_id.
R.3: Los planes de pago solo pueden ser creados para transacciones de compra a proveedores (evento_id = 1050 ''COMPRA'' en la tabla kardex). El sistema bloquea la creación de planes de pago para cualquier otro evento, incluyendo VENTA (evento_id = 1051).
R.4: Registro Inicial Comodín. El registro con plan_pago_id = 1 es un registro con estado_id = 1000 (ACTIVO) y estado_pago_id = 2553 (CERRADO). Sirve como valor predeterminado para las FK que requieran un plan de pago de referencia.
R.5: Validación de Fechas. fecha_pago solo puede ser registrada si es posterior a ''2000-01-01''. El backend debe validar que fecha_pago >= fecha_vencimiento cuando se registre un pago.
R.6: Cálculo Automático del Estado de Pago. El backend debe actualizar estado_pago_id automáticamente al registrar abonos: si monto_pagado = monto_programado ? 2552 (PAGADO); si monto_pagado > 0 y < monto_programado ? 2551 (PARCIAL); si monto_pagado = 0 ? 2550 (PENDIENTE). CERRADO solo aplica cuando la cuota está completamente liquidada y el plan ha finalizado.
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
- monto_pagado = 0 ? 2550 (PENDIENTE)
- 0 < monto_pagado < monto_programado ? 2551 (PARCIAL)
- monto_pagado = monto_programado ? 2552 (PAGADO)';

-- ================================================================================================

CREATE TABLE comprobantes_pagos (
    comprobante_pago_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    banco_id BIGINT NOT NULL DEFAULT 1,
    tipo_pago_id SMALLINT NOT NULL DEFAULT 1400,        -- 1400=NINGUNO, 1401=EFECTIVO, 1402=TARJETA, 1403=CHEQUE, 1404=VALE, 1405=OTROS, 1406=SIN_PAGO, 1407=TRANSFERENCIA, 1408=DEPOSITO, 1409=QR
	tipo_moneda_id SMALLINT NOT NULL DEFAULT 2300,      -- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    codigo_transaccion VARCHAR(100) NOT NULL,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_pago DATE NOT NULL,
    titular_cuenta VARCHAR(150) NOT NULL DEFAULT '',
    autorizacion_nro VARCHAR(50) NULL,
    cuenta_destino VARCHAR(50) NULL,
    comprobante_digital_ruta VARCHAR(255) NULL,
    confirmado SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_comprobantespagos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_comprobantespagos_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
    CONSTRAINT chk_comprobantespagos_tipopagoid CHECK (tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409)),
    CONSTRAINT chk_comprobantespagos_tipomonedaid CHECK (tipo_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_comprobantespagos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_comprobantespagos_confirmado CHECK (confirmado IN (0, 1)),
    CONSTRAINT chk_comprobantespagos_monto CHECK (monto > 0.00),
    CONSTRAINT chk_comprobantespagos_codigotransaccion CHECK (LENGTH(TRIM(codigo_transaccion)) >= 2),
    CONSTRAINT chk_comprobantespagos_titularcuenta CHECK (TRIM(titular_cuenta) <> ''),
    CONSTRAINT chk_comprobantespagos_autorizacionnro CHECK (autorizacion_nro IS NULL OR TRIM(autorizacion_nro) <> ''),
    CONSTRAINT chk_comprobantespagos_cuentadestino CHECK (cuenta_destino IS NULL OR TRIM(cuenta_destino) <> ''),
    CONSTRAINT chk_comprobantespagos_comprobantedigital CHECK (comprobante_digital_ruta IS NULL OR TRIM(comprobante_digital_ruta) <> '')
);
CREATE UNIQUE INDEX uix_comprobantespagos_varios_unique ON comprobantes_pagos (banco_id, codigo_transaccion) WHERE estado_id = 1000;
CREATE INDEX idx_comprobantespagos_kardexid ON comprobantes_pagos (kardex_id) WHERE estado_id = 1000;
CREATE INDEX idx_comprobantespagos_tipopagoid ON comprobantes_pagos (tipo_pago_id) WHERE estado_id = 1000;
CREATE INDEX idx_comprobantespagos_fechapago ON comprobantes_pagos (fecha_pago DESC) WHERE estado_id = 1000;

COMMENT ON TABLE comprobantes_pagos IS 'Reglas de la tabla - comprobantes_pagos
R.0: La tabla comprobantes_pagos registra los comprobantes de pago asociados a transacciones de venta, compra u otras operaciones financieras. Sirve como soporte documental y de trazabilidad de los medios de pago utilizados en el sistema, permitiendo vincular cada transacción con su respectivo comprobante bancario o interno.
R.1: confirmado indica si el comprobante ha sido validado o verificado (1=Confirmado, 0=Pendiente). El sistema debe actualizar este campo manualmente o mediante procesos de conciliación bancaria.
R.2: codigo_transaccion almacena el número de operación, referencia o código único de la transacción bancaria. El campo es único por banco y debe tener al menos 2 caracteres.
R.3: tipo_pago_id define el medio de pago utilizado (EFECTIVO, CHEQUE, QR, TRANSFERENCIA, etc.). El registro con id 1400 corresponde a ''NINGUNO'' para casos de compras u operaciones que no requieren pago.
R.4: Permite la relación de uno a muchos (1 a N) con la tabla kardex mediante kardex_id, posibilitando registrar múltiples comprobantes de pago (como pagos mixtos o fraccionados con QR, transferencias o cheques) para una misma transacción comercial, manteniendo la normalización de datos sin duplicar información financiera.
R.5: Validación de Comprobantes para Pagos a Proveedores. Para pagos con tipo_pago_id = 1407 (TRANSFERENCIA) o 1408 (DEPOSITO), el comprobante_digital_ruta es obligatorio.
R.6: Confirmación de Comprobante. confirmado = 1 indica que el pago ha sido verificado por el banco. El sistema solo permite registrar pagos con comprobantes confirmados.
R.7: Unicidad de Transacción. El código de transacción debe ser único por banco.';

-- ================================================================================================

CREATE TABLE pagos (
    pago_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL DEFAULT 1,
    plan_pago_id BIGINT NOT NULL DEFAULT 1,
    tipo_pago_id SMALLINT NOT NULL DEFAULT 1400,        -- 1400=NINGUNO, 1401=EFECTIVO, 1402=TARJETA, 1403=CHEQUE, 1404=VALE, 1405=OTROS, 1406=SIN_PAGO, 1407=TRANSFERENCIA, 1408=DEPOSITO, 1409=QR
	comprobante_pago_id BIGINT NOT NULL DEFAULT 1,
	proveedor_id BIGINT NOT NULL DEFAULT 1,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    referencia VARCHAR(100) NULL,
    comprobante VARCHAR(100) NULL,
    observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pagos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_pagos_plan_pago_id FOREIGN KEY (plan_pago_id) REFERENCES planes_pagos(plan_pago_id),
    CONSTRAINT fk_pagos_comprobante_pago_id FOREIGN KEY (comprobante_pago_id) REFERENCES comprobantes_pagos(comprobante_pago_id),
    CONSTRAINT fk_pagos_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_pagos_tipopagoid CHECK (tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409)),
    CONSTRAINT chk_pagos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_pagos_monto CHECK (monto > 0),
    CONSTRAINT chk_pagos_fechapago CHECK (fecha_pago > '2000-01-01')
);
CREATE INDEX idx_pagos_kardexid ON pagos (kardex_id) WHERE estado_id = 1000;
CREATE INDEX idx_pagos_planpagoid ON pagos (plan_pago_id) WHERE estado_id = 1000;
CREATE INDEX idx_pagos_fechapago ON pagos (fecha_pago) WHERE estado_id = 1000;
CREATE INDEX idx_pagos_proveedorid ON pagos(proveedor_id);
CREATE INDEX idx_pagos_comprobantepagoid ON pagos(comprobante_pago_id);

COMMENT ON TABLE pagos IS 'Reglas de la tabla - pagos
R.0: La tabla pagos registra los abonos o liquidaciones efectuadas por los clientes para cubrir las cuotas de financiamiento generadas en la tabla planes_pagos. Su propósito es consolidar el historial de cobranza, vinculando cada transacción de pago con el plan de cuotas, el medio de pago utilizado y el comprobante bancario asociado.
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

-- ================================================================================================

CREATE TABLE cajas (
    caja_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    apertura_trabajador_id BIGINT NOT NULL DEFAULT 1,
    cierre_trabajador_id BIGINT NOT NULL DEFAULT 1,
    autorizacion_trabajador_id BIGINT NOT NULL DEFAULT 1,
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
    total_transacciones SMALLINT NOT NULL DEFAULT 0,
    total_ventas SMALLINT NOT NULL DEFAULT 0,
    total_devoluciones SMALLINT NOT NULL DEFAULT 0,
    total_retiros SMALLINT NOT NULL DEFAULT 0,
    estado_caja_id SMALLINT NOT NULL DEFAULT 2650,		-- 2650=ABIERTA, 2651=CERRADA
    observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cajas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cajas_apertura_trabajador_id FOREIGN KEY (apertura_trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_cajas_cierre_trabajador_id FOREIGN KEY (cierre_trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_cajas_autorizacion_trabajador_id FOREIGN KEY (autorizacion_trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_cajas_estadocajaid CHECK (estado_caja_id IN (2650, 2651)),
    CONSTRAINT chk_cajas_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_cajas_fechas CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_apertura),
    CONSTRAINT chk_cajas_fechas_varios CHECK (fecha_autorizacion IS NULL OR fecha_autorizacion <= fecha_apertura),
    CONSTRAINT chk_cajas_montos CHECK (
        monto_inicial >= 0.00 AND
        monto_ingresos >= 0.00 AND
        monto_egresos >= 0.00 AND
        monto_ventas >= 0.00
    ),
    CONSTRAINT chk_cajas_observaciones CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3)
);
CREATE UNIQUE INDEX uix_cajas_sucursalid_unique ON cajas (sucursal_id) WHERE estado_caja_id = 2650 AND estado_id = 1000;
CREATE INDEX idx_cajas_sucursalid_estadocajaid ON cajas (sucursal_id, estado_caja_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_cajas_fechaapertura ON cajas (fecha_apertura DESC) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_cajas_aperturatrabajadorid ON cajas (apertura_trabajador_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_cajas_cierretrabajadorid ON cajas (cierre_trabajador_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_cajas_autorizaciontrabajadorid ON cajas (autorizacion_trabajador_id) WHERE estado_id IN (1000, 1003);

COMMENT ON TABLE cajas IS 'Reglas de la tabla - cajas
R.0: La tabla cajas registra el ciclo de vida operativo y financiero de las cajas físicas de cobro por sucursal, controlando la apertura, los flujos de efectivo (ingresos, egresos, ventas), los arqueos y el cierre de turno. Su propósito es garantizar la trazabilidad del dinero en efectivo y medios de pago recibidos durante las operaciones diarias del negocio.
R.1: Apertura Única por Sucursal. El índice único parcial (uix_cajas_sucursalid_unique) garantiza que una sucursal solo puede tener una única caja abierta (estado_caja_id = 2650) de forma simultánea. No se permite abrir una nueva caja si la anterior no ha sido cerrada formalmente.
R.2: Control de Fechas y Cronología. La fecha de cierre (fecha_cierre) debe ser estrictamente posterior o igual a la fecha de apertura (fecha_apertura). Si la caja está abierta, fecha_cierre y cierre_trabajador_id deben ser obligatoriamente NULL.
R.3: Cálculo del Monto Final Esperado. Durante la operación, el backend debe calcular dinámicamente el monto final esperado mediante la fórmula: monto_final_esperado = monto_inicial + monto_ingresos + monto_ventas - monto_egresos.
R.4: Arqueo y Diferencia en Cierre. Al realizar el cierre de caja, se debe registrar el monto contado físicamente (monto_final_real). El sistema calcula automáticamente la diferencia como: diferencia = monto_final_real - monto_final_esperado (valores positivos indican sobrante, valores negativos indican faltante).
R.5: Restricción de Modificación Post-Cierre. Una vez que una caja pasa a estado_caja_id = 2651 (CERRADA), ningún usuario puede registrar nuevos pagos, ingresos o egresos asociados a dicha caja, requiriendo la apertura de una nueva sesión o una autorización especial de supervisión.';

-- ================================================================================================

CREATE TABLE movimientos (
    movimiento_id BIGSERIAL PRIMARY KEY,
    caja_id BIGINT NOT NULL DEFAULT 1,
    referencia_id BIGINT NOT NULL DEFAULT 1,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    tipo_movimiento_id SMALLINT NOT NULL DEFAULT 2600,	-- 2600=INGRESO, 2601=EGRESO
    tipo_pago_id SMALLINT NOT NULL DEFAULT 1400,        -- 1400=NINGUNO, 1401=EFECTIVO, 1402=TARJETA, 1403=CHEQUE, 1404=VALE, 1405=OTROS, 1406=SIN_PAGO, 1407=TRANSFERENCIA, 1408=DEPOSITO, 1409=QR
	monto DECIMAL(12,2) NOT NULL,
    saldo_antes DECIMAL(12,2) NOT NULL,
    saldo_despues DECIMAL(12,2) NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_movimientos_caja_id FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT fk_movimientos_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_movimientos_tipomovimientoid CHECK (tipo_movimiento_id IN (2600, 2601)),
    CONSTRAINT chk_movimientos_tipopagoid CHECK (tipo_pago_id IS NULL OR tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409)),
    CONSTRAINT chk_movimientos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_movimientos_monto CHECK (monto > 0.00),
    CONSTRAINT chk_movimientos_saldoantes CHECK (saldo_antes >= 0.00),
    CONSTRAINT chk_movimientos_saldodespues CHECK (saldo_despues >= 0.00),
    CONSTRAINT chk_movimientos_motivo_minlength CHECK (LENGTH(TRIM(motivo)) >= 3)
);
CREATE INDEX idx_movimientos_cajaid ON movimientos (caja_id) WHERE estado_id = 1000;
CREATE INDEX idx_movimientos_fechamovimiento ON movimientos (fecha_movimiento DESC) WHERE estado_id = 1000;
CREATE INDEX idx_movimientos_tipomovimientoid_cajaid ON movimientos (tipo_movimiento_id, caja_id) WHERE estado_id = 1000;
CREATE INDEX idx_movimientos_trabajadorid ON movimientos (trabajador_id) WHERE estado_id = 1000;
CREATE INDEX idx_movimientos_referenciaid ON movimientos (referencia_id) WHERE referencia_id IS NOT NULL AND estado_id = 1000;
CREATE INDEX idx_movimientos_fecharegistro ON movimientos (fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_movimientos_tipopagoid ON movimientos (tipo_pago_id) WHERE estado_id = 1000;

COMMENT ON TABLE movimientos IS 'Reglas de la tabla - movimientos
R.0: La tabla movimientos registra el libro de ingresos y egresos detallados de efectivo o medios de pago asociados directamente a una sesión de caja activa. Su propósito es garantizar la trazabilidad de cada entrada o salida de dinero que afecta los saldos y el arqueo de caja.
R.1: Validación de Caja Abierta. Los movimientos de ingreso (2600) o egreso (2601) solo pueden registrarse en cajas cuyo estado sea abierto (estado_caja_id = 2650). Está estrictamente prohibido registrar transacciones en cajas cerradas.
R.2: Control e Integridad de Saldos (Kardex de Caja). El backend debe calcular de forma transaccional los campos saldo_antes y saldo_despues basándose en el tipo de movimiento:
- Para Ingresos (2600): saldo_despues = saldo_antes + monto, y se actualiza de forma acumulativa el campo monto_ingresos en la tabla cajas.
- Para Egresos (2601): saldo_despues = saldo_antes - monto, garantizando que no se efectúen salidas mayores al saldo disponible, y se actualiza de forma acumulativa el campo monto_egresos en la tabla cajas.
R.3: Asociación Opcional por Referencia. El campo referencia_id permite vincular opcionalmente el movimiento con otra entidad externa del sistema (como una venta, una compra, un pago específico o un gasto operativo), facilitando la conciliación contable.
R.4: Inmutabilidad por Borrado Lógico. Si un movimiento es eliminado (estado_id = 1001 o fecha_baja IS NOT NULL), el backend debe aplicar un mecanismo de reversión contable para recalcular el impacto en los acumuladores de la caja asociada.';

-- ================================================================================================

CREATE TABLE arqueos_detalle (
    arqueo_detalle_id BIGSERIAL PRIMARY KEY,
    caja_id BIGINT NOT NULL DEFAULT 1,
    tipo_billete_id SMALLINT NOT NULL DEFAULT 4300,     -- 4300=NINGUNO, 4301=B200, 4302=B100, 4303=B50, 4304=B20, 4305=B10, 4306=B5, 4307=B2, 4308=B1, 4309=M050, 4310=M020, 4311=M010, 4312=M10, 4313=M5, 4314=M2, 4315=M1
    cantidad SMALLINT NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_arqueosdetalle_caja_id FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT chk_arqueosdetalle_tipobilleteid CHECK (tipo_billete_id IN (4300, 4301, 4302, 4303, 4304, 4305, 4306, 4307, 4308, 4309, 4310, 4311, 4312, 4313, 4314, 4315)),
    CONSTRAINT chk_arqueosdetalle_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_arqueosdetalle_cantidad CHECK (cantidad >= 0),
    CONSTRAINT chk_arqueosdetalle_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_arqueosdetalle_cajaid ON arqueos_detalle (caja_id) WHERE estado_id = 1000;
CREATE INDEX idx_arqueosdetalle_tipobilleteid ON arqueos_detalle (tipo_billete_id) WHERE estado_id = 1000;

COMMENT ON TABLE arqueos_detalle IS 'Reglas de la tabla - arqueos_detalle
R.0: La tabla arqueos_detalle desglosa el conteo físico de dinero en efectivo (conteo de billetes y monedas por denominación) asociado a un proceso de arqueo o cierre dentro de una sesión de caja. Su propósito es estructurar el desglose físico del efectivo para calcular con exactitud el monto real disponible en la caja.
R.1: Cálculo Obligatorio del Subtotal. Por cada tipo de billete o moneda contado, el backend debe calcular y registrar el subtotal mediante la multiplicación de la cantidad por la denominación nominal correspondiente: subtotal = cantidad * valor_denominacion (ej. 5 billetes de 100 generan un subtotal de 500.00).
R.2: Integridad con el Arqueo Global. La sumatoria de todos los subtotales activos (estado_id = 1000) de esta tabla para una caja específica debe alimentar directamente el campo monto_final_real de la tabla cajas al momento de realizar el cierre o arqueo de turno.
R.3: Restricción de Conteo Positivo. La cantidad de piezas físicas debe ser un valor entero mayor o igual a cero, prohibiendo estrictamente valores negativos. El subtotal resultante debe reflejar coherentemente esta magnitud monetaria.';

-- ================================================================================================

CREATE TABLE alertas_notificaciones (
    alerta_notificacion_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(60) NOT NULL,
    tipo_alerta_notificacion_id SMALLINT NOT NULL DEFAULT 2724,  -- 2700=SISTEMA, 2701=ALERTA_STOCK, 2702=STOCK_BAJO, 2703=STOCK_CRITICO, 2704=STOCK_EXCESO, 2705=VENCIMIENTO_PROXIMO, 2706=VENCIMIENTO_INMEDIATO, 2707=VENCIMIENTO_VENCIDO, 2708=DEMANDA_ALTA, 2709=DEMANDA_BAJA, 2710=TENDENCIA_ANOMALA, 2711=PREDICCION_ROP, 2712=PREDICCION_DEMANDA, 2713=FORECASTING, 2714=PAGOS, 2715=PAGO_VENCIDO, 2716=PAGO_PROXIMO, 2717=DOCUMENTOS, 2718=FACTURA_PENDIENTE, 2719=FACTURA_ANULADA, 2720=SEGURIDAD_ACCESO, 2721=SEGURIDAD_INTENTO_FALLIDO, 2722=SISTEMA_ERROR, 2723=SISTEMA_RENDIMIENTO, 2724=NINGUNO, 2725=RRHH_FALTAS, 2726=RRHH_CONTRATO, 2727=RRHH_PLANILLA
    subtipo_alerta_id SMALLINT NULL DEFAULT 2812,                -- 2800=SARIMA, 2801=PROPHET, 2802=KMEANS, 2803=ROP_CALC, 2804=PATRON_CONSUMO, 2805=ALERTA_PREDICTIVA, 2806=QUIEBRE_STOCK, 2807=REORDEN, 2808=EXCESO, 2809=CADUCIDAD_CRITICA, 2810=CADUCIDAD_ALTA, 2811=CADUCIDAD_MEDIA, 2812=NINGUNO
    origen_alerta_id SMALLINT NOT NULL DEFAULT 2850,             -- 2850=SISTEMA, 2851=IA, 2852=USUARIO, 2853=TAREA_PROGRAMADA, 2854=EXTERNO_TERCERO
    nivel_critico_id SMALLINT NOT NULL DEFAULT 2905,             -- 2900=CRITICO, 2901=ALTA, 2902=MEDIA, 2903=BAJA, 2904=INFORMATIVA, 2905=NINGUNO
    titulo VARCHAR(150) NOT NULL,
    mensaje VARCHAR(2000) NOT NULL,
    entidad_afectada_tipo_id SMALLINT NOT NULL DEFAULT 4111,	 -- 4100=PRODUCTOS, 4101=LOTES, 4102=VENTAS, 4103=COMPRAS, 4104=USUARIOS, 4105=SUCURSALES, 4106=PROVEEDORES, 4107=CLIENTES, 4108=FACTURAS, 4109=PAGOS, 4110=INVENTARIO, 4111=NINGUNO
    entidad_afectada_id BIGINT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    estado_alerta_id SMALLINT NOT NULL DEFAULT 2955,   			-- 2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA, 2955=NINGUNO
    prioridad_resolucion SMALLINT NOT NULL DEFAULT 3,
    trabajador_asignado_id BIGINT NOT NULL DEFAULT 1,
    fecha_asignacion TIMESTAMPTZ NULL,
    es_leido SMALLINT NOT NULL DEFAULT 0,
    fecha_lectura TIMESTAMPTZ NULL,
	trabajador_resolutor_id BIGINT NOT NULL DEFAULT 1,
    fecha_resolucion TIMESTAMPTZ NULL,
    comentarios_resolucion VARCHAR(3000) NULL,
    accion_tomada VARCHAR(50) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_alertasnotificaciones_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_alertasnotificaciones_trabajador_asignado_id FOREIGN KEY (trabajador_asignado_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_alertasnotificaciones_trabajador_resolutor_id FOREIGN KEY (trabajador_resolutor_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_alertasnotificaciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_alertasnotificaciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_alertasnotificaciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_alertasnotificaciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_alertasnotificaciones_tipoalertanotificacionid CHECK (tipo_alerta_notificacion_id IN (2700, 2701, 2702, 2703, 2704, 2705, 2706, 2707, 2708, 2709, 2710, 2711, 2712, 2713, 2714, 2715, 2716, 2717, 2718, 2719, 2720, 2721, 2722, 2723, 2724, 2725, 2726, 2727)),
    CONSTRAINT chk_alertasnotificaciones_subtipoalertaid CHECK (subtipo_alerta_id IS NULL OR subtipo_alerta_id IN (2800, 2801, 2802, 2803, 2804, 2805, 2806, 2807, 2808, 2809, 2810, 2811, 2812)),
    CONSTRAINT chk_alertasnotificaciones_origenalertaid CHECK (origen_alerta_id IN (2850, 2851, 2852, 2853, 2854)),
    CONSTRAINT chk_alertasnotificaciones_nivelcriticoid CHECK (nivel_critico_id IN (2900, 2901, 2902, 2903, 2904, 2905)),
    CONSTRAINT chk_alertasnotificaciones_entidadafectadatipoid CHECK (entidad_afectada_tipo_id IN (4100, 4101, 4102, 4103, 4104, 4105, 4106, 4107, 4108, 4109, 4110, 4111)),
    CONSTRAINT chk_alertasnotificaciones_estadoalertaid CHECK (estado_alerta_id IN (2950, 2951, 2952, 2953, 2954, 2955)),
    CONSTRAINT chk_alertasnotificaciones_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_alertasnotificaciones_esleido CHECK (es_leido IN (0, 1))
);
CREATE UNIQUE INDEX uix_alertasnotificaciones_codigo_unique ON alertas_notificaciones (codigo) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_fecharegistro ON alertas_notificaciones (fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_varios ON alertas_notificaciones (entidad_afectada_tipo_id, entidad_afectada_id) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_bandeja_consulta ON alertas_notificaciones (sucursal_id, estado_alerta_id, fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_trabajadorasignadoid ON alertas_notificaciones (trabajador_asignado_id) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_trabajadorresolutorid ON alertas_notificaciones (trabajador_resolutor_id) WHERE estado_id = 1000;

COMMENT ON TABLE alertas_notificaciones IS 'Reglas de la tabla - alertas_notificaciones
R.0: La tabla alertas_notificaciones es el centro de gestión de eventos y avisos del sistema, consolidando tanto las notificaciones operativas (stock bajo, vencimientos) como las generadas por los modelos de IA (pronósticos, anomalías). Su propósito es unificar la bandeja de entrada del usuario, proporcionando un registro auditado de eventos críticos, su nivel de urgencia, asignación y resolución, lo que permite una gestión proactiva de la farmacia.
R.1: Unificación de Eventos y Bandeja de Entrada. Esta entidad consolida tanto el registro técnico de la anomalía o predicción generada por el sistema/IA como el estado de interacción del operador asignado en una sola estructura unificada, controlando la visibilidad del mensaje en la UI a través del campo es_leido. (donde 0 = No leído y 1 = Leído).
R.2: Metadatos Flexibles con JSONB y Estructura por Defecto. El campo metadata almacena toda la información contextual específica del tipo de alerta (como modelos de IA, parámetros de automatización, resultados de acciones, etc.). Este campo es de uso obligatorio a nivel de esquema con la restricción NOT NULL DEFAULT ''{}''::jsonb, garantizando que la aplicación nunca reciba ni almacene valores nulos (NULL), facilitando el consumo directo de propiedades en el backend sin necesidad de evaluar nulos en el objeto.
R.3: Control Dual de Estados Operacionales. estado_alerta_id rige el ciclo de vida de resolución técnica del evento (2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA). estado_id controla la persistencia lógica en el repositorio de datos (1000=ACTIVO, 1001=BORRADO).
R.4: Gestión de Lectura y Auditoría Temporal. Al interactuar el usuario con la interfaz, la aplicación debe actualizar es_leido = TRUE y registrar la marca de tiempo exacta en fecha_lectura.
R.5: Niveles de Prioridad. prioridad_resolucion es un valor entre 1 y 5 donde 1 es la máxima prioridad y 5 la mínima. El frontend debe ordenar las alertas según este campo para guiar la atención del operador.
R.6: Estructura Estándar de Automatización en Metadata. Cuando la alerta involucre procesos automáticos, la información correspondiente debe almacenarse dentro del JSONB utilizando la siguiente estructura base acordada:
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

-- ================================================================================================

CREATE TABLE modelos (
    modelo_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_modelo_id SMALLINT NOT NULL DEFAULT 1456,  	-- 1450=ARIMA, 1451=SARIMA, 1452=SERIES_TEMPORALES, 1453=CLASIFICACION, 1454=OPTIMIZACION, 1455=DETECCION_ANOMALIAS, 1456=NINGUNO
	framework_version VARCHAR(20) DEFAULT '0.0.0',
    descripcion VARCHAR(500) NULL,
    framework_id SMALLINT NOT NULL DEFAULT 3004,  		-- 3000=STATSMODELS, 3001=SCIKIT_LEARN, 3002=TENSORFLOW, 3003=CUSTOM, 3004=NINGUNO
    version VARCHAR(20) NOT NULL,
    parametros_default JSONB NOT NULL DEFAULT '{}'::jsonb,
    estado_modelo_id SMALLINT NOT NULL DEFAULT 2002,  	-- 2000=SIN_DATOS, 2001=ENTRENANDO, 2002=ACTIVO, 2003=RECHAZADO, 2004=OBSOLETO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_modelos_tipomodeloid CHECK (tipo_modelo_id IN (1450, 1451, 1452, 1453, 1454, 1455, 1456)),
    CONSTRAINT chk_modelos_frameworkid CHECK (framework_id IN (3000, 3001, 3002, 3003, 3004)),
    CONSTRAINT chk_modelos_estadomodeloid CHECK (estado_modelo_id IN (2000, 2001, 2002, 2003, 2004)),
    CONSTRAINT chk_modelos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_modelos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_modelos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_modelos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_modelos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_modelos_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_modelos_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_modelos_version_minlength CHECK (LENGTH(TRIM(version)) >= 1)
);
CREATE UNIQUE INDEX uix_modelos_codigo_unique ON modelos (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_modelos_nombre_unique ON modelos (nombre) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_modelos_tipomodeloid ON modelos (tipo_modelo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_modelos_frameworkid ON modelos (framework_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_modelos_estadomodeloid ON modelos (estado_modelo_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE modelos IS 'Reglas de la tabla - modelos
R.0: La tabla modelos es el catálogo de todos los algoritmos de inteligencia artificial y aprendizaje automático disponibles en el sistema, definiendo sus parámetros de configuración y estado. Su propósito es gestionar el ciclo de vida de los modelos (activo, en entrenamiento, obsoleto), permitiendo la estandarización y el versionado de las técnicas predictivas.
R.1: Control del Ciclo de Vida. estado_id gestiona la vigencia y disponibilidad técnica del modelo en el sistema de predicción, garantizando la inmutabilidad y persistencia de configuraciones históricas.
R.2: Estructura de Hiperparámetros. parametros_default almacena la configuración base en formato JSONB para la inicialización y el entrenamiento de los algoritmos, evitando la fragmentación en múltiples tablas relacionales de variables técnicas.
R.3: Identificador Único de Modelo. codigo es un campo alfanumérico único en mayúsculas que identifica al modelo de forma abreviada. Debe tener al menos 3 caracteres y ser ingresado manualmente por el administrador del sistema.
R.4: Registro Inicial Comodín. El registro con modelo_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un modelo de referencia.
R.5: Tipos de Modelo. tipo_modelo_id utiliza los valores (1450-1455): ARIMA (1450), SARIMA (1451), SERIES_TEMPORALES (1452), CLASIFICACION (1453), OPTIMIZACION (1454), DETECCION_ANOMALIAS (1455).
R.6: Frameworks. framework_id utiliza los valores (3000-3003): statsmodels (3000), scikit-learn (3001), tensorflow (3002), custom (3003).
R.7: Estado Operativo del Modelo. estado_modelo_id utiliza los valores (2000-2004): SIN_DATOS (2000) cuando no hay suficientes datos históricos para entrenar, ENTRENANDO (2001) cuando el motor Python está calculando parámetros, ACTIVO (2002) cuando el modelo está entrenado y generando predicciones, RECHAZADO (2003) cuando el MAPE supera el umbral permitido, OBSOLETO (2004) cuando ha sido reemplazado por una versión más reciente. Este campo es independiente de estado_id y refleja el estado funcional del modelo.';

-- ================================================================================================

CREATE TABLE entrenamientos (
    entrenamiento_id BIGSERIAL PRIMARY KEY,
    modelo_id BIGINT NOT NULL DEFAULT 1,
    fecha_ejecucion TIMESTAMPTZ NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NULL,
    estado_ejecucion_id SMALLINT NOT NULL DEFAULT 3053, -- 3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO, 3053=NINGUNO
    duracion_segundos INTEGER NULL,
    registros_procesados BIGINT NULL,
    total_esperado BIGINT NULL,
    mensaje_error TEXT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_entrenamientos_modelo_id FOREIGN KEY (modelo_id) REFERENCES modelos(modelo_id),
    CONSTRAINT chk_entrenamientos_estadoejecucionid CHECK (estado_ejecucion_id IN (3050, 3051, 3052, 3053)),
    CONSTRAINT chk_entrenamientos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_entrenamientos_duracionsegundos CHECK (duracion_segundos >= 0),
    CONSTRAINT chk_entrenamientos_registrosprocesados CHECK (registros_procesados IS NULL OR registros_procesados >= 0),
    CONSTRAINT chk_entrenamientos_totalesperado CHECK (total_esperado IS NULL OR total_esperado >= 0),
    CONSTRAINT chk_entrenamientos_fechas CHECK (
        fecha_inicio <= fecha_ejecucion AND
        (fecha_fin IS NULL OR fecha_ejecucion <= fecha_fin) AND
        (fecha_fin IS NULL OR fecha_inicio <= fecha_fin)
    )
);
CREATE INDEX idx_entrenamientos_modeloid ON entrenamientos (modelo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_entrenamientos_fechaejecucion ON entrenamientos (fecha_ejecucion DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_entrenamientos_estadoejecucionid ON entrenamientos (estado_ejecucion_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE entrenamientos IS 'Reglas de la tabla - entrenamientos
R.0: La tabla entrenamientos registra la ejecución histórica de los procesos de entrenamiento de los modelos de IA, almacenando su fecha, duración y estado. Su propósito es proveer trazabilidad sobre el rendimiento y la ejecución de los modelos, permitiendo auditar el proceso de aprendizaje y vincularlo a las métricas de precisión resultantes.
R.1: Control del Flujo de Ejecución. estado_ejecucion_id administra el progreso operativo del entrenamiento del modelo (3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO), definiendo la disponibilidad de métricas en el sistema.
R.2: Registro Desconectado de Errores. Si estado_ejecucion_id = 3052 (FALLIDO), el backend persistirá el detalle del rastro técnico en mensaje_error para fines de depuración de hiperparámetros sin interrumpir la consistencia lógica de la tabla.
R.3: Registro Inicial Comodín. El registro con entrenamiento_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO) y estado_ejecucion_id = 3051 (COMPLETADO). Sirve como valor predeterminado para las FK que requieran un entrenamiento de referencia.
R.4: Validación de Fechas. fecha_inicio debe ser anterior a fecha_fin cuando el entrenamiento esté completado. fecha_ejecucion es la fecha de registro del entrenamiento en el sistema.
R.5: Métricas de Rendimiento. duracion_segundos y registros_procesados se actualizan automáticamente al finalizar el entrenamiento. El backend debe calcular duracion_segundos = EXTRACT(EPOCH FROM (fecha_fin - fecha_inicio)) cuando estado_ejecucion_id = 3051 (COMPLETADO).
R.6: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, HISTORICO). Un entrenamiento en estado HISTORICO no puede ser modificado.';

-- ================================================================================================

CREATE TABLE metricas_rendimiento (
    metrica_id BIGSERIAL PRIMARY KEY,
    entrenamiento_id BIGINT NOT NULL DEFAULT 1,
    tipo_metrica_id SMALLINT NOT NULL DEFAULT 3103,         -- 3100=REGRESION, 3101=CLASIFICACION, 3102=CLUSTERING, 3103=NINGUNO
    metrica_precision_id SMALLINT NULL DEFAULT 3600,        -- 3600=MAE, 3601=RMSE, 3602=MAPE, 3603=R2, 3604=F1
    factor_estacionalidad_id SMALLINT NULL DEFAULT 3650,	-- 3650=NONE, 3651=DIARIO, 3652=SEMANAL, 3653=MENSUAL, 3654=ANUAL, 3655=MULTIPLE
    version_metricas SMALLINT NOT NULL DEFAULT 1,
    modelo_version VARCHAR(20) NOT NULL DEFAULT '0.0.0',
    fecha_evaluacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    periodo_evaluacion DATE NOT NULL DEFAULT CURRENT_DATE,
    error_absoluto_medio DECIMAL(10,4) NULL,
    raiz_error_cuadratico_medio DECIMAL(10,4) NULL,
    score_principal DECIMAL(5,4) NULL,
    detalles_metricas JSONB NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_metricasrendimiento_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT chk_metricasrendimiento_tipometricasid CHECK (tipo_metrica_id IN (3100, 3101, 3102, 3103)),
    CONSTRAINT chk_metricasrendimiento_metricaprecisionid CHECK (metrica_precision_id IS NULL OR metrica_precision_id IN (3600, 3601, 3602, 3603, 3604)),
    CONSTRAINT chk_metricasrendimiento_factorestacionalidadid CHECK (factor_estacionalidad_id IS NULL OR factor_estacionalidad_id IN (3650, 3651, 3652, 3653, 3654, 3655)),
    CONSTRAINT chk_metricasrendimiento_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_metricasrendimiento_errorabsolutomedio CHECK (error_absoluto_medio IS NULL OR error_absoluto_medio >= 0),
    CONSTRAINT chk_metricasrendimiento_raizerrorquadraticomedio CHECK (raiz_error_cuadratico_medio IS NULL OR raiz_error_cuadratico_medio >= 0),
    CONSTRAINT chk_metricasrendimiento_scoreprincipal CHECK (score_principal IS NULL OR score_principal >= 0),
    CONSTRAINT chk_metricasrendimiento_varios CHECK (
        metrica_precision_id IS NOT NULL OR
        error_absoluto_medio IS NOT NULL OR
        raiz_error_cuadratico_medio IS NOT NULL OR
        score_principal IS NOT NULL OR
        detalles_metricas IS NOT NULL
    )
);
CREATE INDEX idx_metricasrendimiento_entrenamientoid ON metricas_rendimiento (entrenamiento_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_metricasrendimiento_tipometricasid ON metricas_rendimiento (tipo_metrica_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_metricasrendimiento_fechaevaluacion ON metricas_rendimiento (fecha_evaluacion DESC) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE metricas_rendimiento IS 'Reglas de la tabla - metricas_rendimiento
R.0: La tabla metricas_rendimiento cuantifica la precisión de los modelos de IA, almacenando indicadores clave como MAPE, RMSE, R2 y otras métricas de error. Su propósito es evaluar objetivamente el desempeño de los modelos predictivos, permitiendo la comparación entre diferentes algoritmos y versiones para elegir el mejor modelo para producción.
R.1: Trazabilidad y Versión de Métricas. Cada evaluación de rendimiento almacena explícitamente su version_metricas, modelo_version, periodo_evaluacion y fecha_evaluacion, permitiendo auditorías retrospectivas cuando los hiperparámetros o las fórmulas subyacentes de los modelos de pronóstico cambien.
R.2: Desglose Híbrido Estructurado-JSONB. Las métricas críticas para reportes rápidos (MAE, RMSE y score principal) se almacenan en columnas planas indexadas, mientras que los coeficientes complejos específicos del algoritmo residen opcionalmente en detalles_metricas.
R.3: Ciclo de Vida Lógico. La entidad utiliza estado_id para mantener el histórico de entrenamiento de la IA sin perder trazabilidad ante eliminaciones lógicas.
R.4: Estandarización de Métricas de Precisión. metrica_precision_id permite identificar el tipo de métrica de precisión utilizada (MAE, RMSE, MAPE, R2, F1), facilitando la comparación entre diferentes entrenamientos y modelos. Puede ser NULL si la métrica está definida en detalles_metricas.
R.5: factor_estacionalidad_id define el tipo de estacionalidad considerada durante la evaluación del modelo. Puede ser NULL si no aplica.
R.6: La combinación de tipo_metrica_id y metrica_precision_id debe ser coherente con el tipo de modelo evaluado. El backend valida que las métricas correspondan al tipo de problema (regresión, clasificación o clustering).';

-- ================================================================================================

CREATE TABLE patrones_consumo (
    patron_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    entrenamiento_id BIGINT NOT NULL DEFAULT 1,
    temporada_id SMALLINT NULL DEFAULT 1600,  			-- 1600=NINGUNO, 1601=ALTA, 1602=MEDIA, 1603=BAJA
    tipo_patron_id SMALLINT NOT NULL DEFAULT 4200,		-- 4200=DEMANDA
	evento VARCHAR(200) NULL,
    factor_estacional DECIMAL(5,2) NULL,
    coeficiente_tendencia DECIMAL(5,2) NULL,
    fecha_inicio DATE NULL,
    fecha_fin DATE NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_patronesconsumo_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_patronesconsumo_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_patronesconsumo_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT chk_patronesconsumo_temporadaid CHECK (temporada_id IS NULL OR temporada_id IN (1600, 1601, 1602, 1603)),
    CONSTRAINT chk_patronesconsumo_tipopatronid CHECK (tipo_patron_id IN (4200)),
    CONSTRAINT chk_patronesconsumo_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_patronesconsumo_evento_minlength CHECK (evento IS NULL OR LENGTH(TRIM(evento)) >= 3),
    CONSTRAINT chk_patronesconsumo_fechas CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_inicio <= fecha_fin)
);
CREATE UNIQUE INDEX uix_patronesconsumo_varios_unique ON patrones_consumo (producto_id, sucursal_id, entrenamiento_id, tipo_patron_id, fecha_inicio, fecha_fin) WHERE estado_id = 1000;
CREATE INDEX idx_patronesconsumo_productoid ON patrones_consumo (producto_id) WHERE estado_id = 1000;
CREATE INDEX idx_patronesconsumo_sucursalid ON patrones_consumo (sucursal_id) WHERE estado_id = 1000;
CREATE INDEX idx_patronesconsumo_temporadaid ON patrones_consumo (temporada_id) WHERE estado_id = 1000;

COMMENT ON TABLE patrones_consumo IS 'Reglas de la tabla - patrones_consumo
R.0: La tabla patrones_consumo almacena los factores estacionales y de tendencia identificados para un producto en una sucursal específica, como resultado de un entrenamiento de IA. Su propósito es capturar el comportamiento cíclico de la demanda, ajustando las predicciones futuras y los puntos de reorden para adaptarse a la realidad de cada mercado local.
R.1: Control de Elasticidad Comercial. factor_estacional y coeficiente_tendencia gestionan las fluctuaciones estacionales de la demanda, resguardando las variaciones cíclicas del mercado boliviano (ej. Feriado de San Juan o Todos Santos) de forma acumulativa y perenne.
R.2: Unicidad de Factores Multiplicadores. Para prevenir distorsiones en las proyecciones de inventario, la restricción uix_pat_producto_sucursal_entrenamiento restringe la existencia de más de un factor multiplicador activo para la misma combinación de artículo, punto de venta y ejecución analítica.
R.3: Clasificación Estacional. temporada_id utiliza los valores (1600-1603): NINGUNA (1600) para patrones sin estacionalidad definida, ALTA (1601) para temporada de demanda alta, MEDIA (1602) para demanda regular, BAJA (1603) para demanda baja.
R.4: Control de Fechas. fecha_inicio y fecha_fin definen el período de vigencia del patrón estacional. El backend debe validar que fecha_fin >= fecha_inicio cuando ambos estén definidos.
R.5: Factor Estacional. factor_estacional es un multiplicador que ajusta la demanda esperada durante el período definido. Un valor de 1.25 indica un incremento del 25% en la demanda. coeficiente_tendencia representa la tendencia lineal de largo plazo.';

-- ================================================================================================

CREATE TABLE variables_exogenas (
    variable_exogena_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    fuente_exogena_id SMALLINT NOT NULL DEFAULT 4250,    -- 4250=SENAMHI, 4251=INE, 4252=BCB, 4253=API_CLIMA, 4254=CALENDARIO_FESTIVOS, 4255=CUSTOM
    nombre_variable VARCHAR(100) NOT NULL,
    valor DECIMAL(10,4) NOT NULL,
    fecha_variable DATE NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_variablesexogenas_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_variablesexogenas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_variablesexogenas_fuenteexogenaid CHECK (fuente_exogena_id IN (4250, 4251, 4252, 4253, 4254, 4255)),
    CONSTRAINT chk_variablesexogenas_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_variablesexogenas_nombrevariable_minlength CHECK (LENGTH(TRIM(nombre_variable)) >= 3)
);
CREATE UNIQUE INDEX uix_variablesexogenas_varios_unique ON variables_exogenas (sucursal_id, producto_id, fecha_variable, nombre_variable) WHERE estado_id = 1000;
CREATE INDEX idx_variablesexogenas_varios ON variables_exogenas (sucursal_id, fecha_variable DESC) WHERE estado_id = 1000;
CREATE INDEX idx_variablesexogenas_fechavariable ON variables_exogenas (fecha_variable DESC) WHERE estado_id = 1000;

COMMENT ON TABLE variables_exogenas IS 'Reglas de la tabla - variables_exogenas
R.0: La tabla variables_exogenas almacena datos externos que influyen en la demanda de productos, como temperatura, precios de moneda o días festivos. Su propósito es enriquecer los modelos de pronóstico (como SARIMAX) con factores causales que mejoran significativamente la precisión de las predicciones de demanda.
R.1: Control Coherente de Factores Externos. El registro continuo de indicadores macroeconómicos, climáticos o ambientales se asocia de forma inalterable a estado_id para salvaguardar el histórico multivariable, alimentando el motor de predicción sin particionamiento físico por periodos anuales.
R.2: Unicidad de Variables por Período. La restricción uix_veg_sucursal_producto_fecha_variable garantiza que no existan duplicados de la misma variable para la misma combinación de sucursal, producto y fecha.
R.3: Control de Fechas. fecha_variable registra la fecha a la que corresponde el valor de la variable. El backend debe validar que fecha_variable <= CURRENT_DATE para variables históricas.
R.4: Ejemplos de Variables Exógenas. nombre_variable puede contener valores como "Temperatura Promedio C", "Precio Dolar", "Inflacion", "Festivo", etc.';

-- ================================================================================================

CREATE TABLE umbrales_configuracion (
    umbral_id BIGSERIAL PRIMARY KEY,
    tipo_umbral_id SMALLINT NOT NULL DEFAULT 3253,  	-- 3250=STOCK_MINIMO, 3251=DIAS_VENCIMIENTO, 3252=ERROR_PREDICCION, 3253=NINGUNO
    producto_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    valor_umbral DECIMAL(12,2) NOT NULL,
    nivel_urgencia_id SMALLINT NOT NULL DEFAULT 1854,  	-- 1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO
    activo SMALLINT NOT NULL DEFAULT 1,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_umbralesconfiguracion_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_umbralesconfiguracion_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_umbralesconfiguracion_tipoumbralid CHECK (tipo_umbral_id IN (3250, 3251, 3252, 3253)),
    CONSTRAINT chk_umbralesconfiguracion_nivelurgenciaid CHECK (nivel_urgencia_id IN (1850, 1851, 1852, 1853, 1854)),
    CONSTRAINT chk_umbralesconfiguracion_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_umbralesconfiguracion_activo CHECK (activo IN (0, 1)),
    CONSTRAINT chk_umbralesconfiguracion_valorumbral CHECK (valor_umbral >= 0)
);
CREATE UNIQUE INDEX uix_umbralesconfiguracion_varios_unique ON umbrales_configuracion (tipo_umbral_id, producto_id, sucursal_id) WHERE estado_id IN (1000, 1002) AND activo = 1 AND NOT (producto_id = 1 AND sucursal_id = 1);
CREATE UNIQUE INDEX uix_umbralesconfiguracion_tipoumbralid_unique ON umbrales_configuracion (tipo_umbral_id) WHERE estado_id IN (1000, 1002) AND activo = 1 AND producto_id = 1 AND sucursal_id = 1;

COMMENT ON TABLE umbrales_configuracion IS 'Reglas de la tabla - umbrales_configuracion
R.0: La tabla umbrales_configuracion define los límites operativos para alertas automáticas (stock mínimo, días de vencimiento, error de predicción) por producto y sucursal. Su propósito es parametrizar las condiciones que disparan notificaciones en el sistema, permitiendo ajustar la sensibilidad de las alarmas según la criticidad y el nivel de urgencia del negocio.
R.1: Persistencia Continua de Alertas. Los valores críticos, límites de tolerancia operativa y márgenes de desviación matemática no se segmentan temporalmente ni duplican por cierres de gestión anual, gestionando su vigencia mediante estado_id.
R.2: Unicidad de Configuración Activa. Para evitar colisiones en las alertas automáticas y notificaciones en el backend, no se permite la coexistencia de más de un parámetro configurado como vigente y activo (activo = 1) para el mismo tipo de umbral, artículo y sucursal de manera simultánea.
R.3: Registro Inicial Comodín. El registro con umbral_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un umbral de referencia.
R.4: Tipos de Umbral. tipo_umbral_id utiliza los valores (3250-3252): STOCK_MINIMO (3250) define el stock mínimo antes de generar alerta, DIAS_VENCIMIENTO (3251) define días antes del vencimiento para alerta, ERROR_PREDICCION (3252) define el error máximo permitido en predicciones.
R.5: Control de Activación. activo = 1 indica que el umbral está activo y genera alertas. activo = 0 desactiva el umbral temporalmente sin eliminar la configuración.
R.6: Valor del Umbral. valor_umbral es el valor numérico que dispara la alerta. Su interpretación depende del tipo_umbral_id: para STOCK_MINIMO es la cantidad mínima, para DIAS_VENCIMIENTO es el número de días, para ERROR_PREDICCION es el porcentaje de error máximo permitido.';

-- ================================================================================================

CREATE TABLE logs_ejecucion (
    log_id BIGSERIAL PRIMARY KEY,
    entrenamiento_id BIGINT NOT NULL DEFAULT 1,
    modulo VARCHAR(100) NOT NULL,
    nivel_log_id SMALLINT NOT NULL DEFAULT 3150,       -- 3150=INFO, 3151=WARNING, 3152=ERROR, 3153=DEBUG
    mensaje VARCHAR(3000) NOT NULL,
    detalle JSONB NOT NULL DEFAULT '{}'::jsonb,
    fecha_log TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_logsejecucion_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT chk_logsejecucion_nivellogid CHECK (nivel_log_id IN (3150, 3151, 3152, 3153)),
    CONSTRAINT chk_logsejecucion_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_logsejecucion_modulo_minlength CHECK (LENGTH(TRIM(modulo)) >= 3)
);
CREATE INDEX idx_logsejecucion_entrenamientoid ON logs_ejecucion (entrenamiento_id) WHERE estado_id = 1000;
CREATE INDEX idx_logsejecucion_nivellogid ON logs_ejecucion (nivel_log_id) WHERE estado_id = 1000;
CREATE INDEX idx_logsejecucion_varios ON logs_ejecucion (modulo, nivel_log_id) WHERE estado_id = 1000;

COMMENT ON TABLE logs_ejecucion IS 'Reglas de la tabla - logs_ejecucion
R.0: La tabla logs_ejecucion es la bitácora técnica que almacena los eventos, advertencias y errores generados durante los procesos del sistema, especialmente durante los entrenamientos de IA. Su propósito es proveer un registro detallado para la depuración, el monitoreo de la salud del sistema y la trazabilidad de los procesos batch y analíticos.
R.1: Control Continuo de Trazabilidad. El almacenamiento cronológico de la bitácora operativa y las excepciones del motor analítico se administra centralizadamente mediante estado_id, asegurando la preservación persistente del histórico técnico sin segmentación de esquemas anuales.
R.2: Estructura No Estricta de Depuración. detalle en formato JSONB resguarda de forma dinámica el contexto técnico extendido (ej. pilas de ejecución o variables internas del modelo), operando de manera desacoplada sin imponer validaciones rígidas estructurales a nivel de motor de base de datos, inicializándose por defecto como objeto vacío.
R.3: Registro Inicial Comodín. El registro con log_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un log de ejecución de referencia.
R.4: Niveles de Log. nivel_log_id utiliza los valores (3150-3153): INFO (3150) para información general, WARNING (3151) para advertencias, ERROR (3152) para errores, DEBUG (3153) para depuración.
R.5: Fecha de Log. fecha_log registra la fecha y hora exacta en que ocurrió el evento. fecha_registro es la fecha de inserción en la base de datos, que puede diferir ligeramente por latencia de red o procesamiento.';

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
    nivel_urgencia_id SMALLINT NULL DEFAULT 1854,         	-- 1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO
    punto_reorden DECIMAL(12,2) NULL,
    stock_seguridad DECIMAL(12,2) NULL,
    lead_time_dias SMALLINT NULL,
    cluster_abc SMALLINT NULL,
    fecha_clasificacion DATE NOT NULL DEFAULT CURRENT_DATE,
    puntaje_total DECIMAL(12,2) NULL,
    estado_pronostico_id SMALLINT NOT NULL DEFAULT 1553, 	-- 1550=PENDIENTE, 1551=PROCESADO, 1552=ERROR, 1553=NINGUNO
    motivo_outlier_id SMALLINT NULL DEFAULT 1907,        	-- 1900=BLOQUEO, 1901=FERIADO_LOCAL, 1902=ERROR_SISTEMA, 1903=PICO_ANORMAL, 1904=ROTURA, 1905=ROBO, 1906=SOBRANTE, 1907=NINGUNO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_analyticaproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_analyticaproductos_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_analyticaproductos_nivelurgenciaid CHECK (nivel_urgencia_id IS NULL OR nivel_urgencia_id IN (1850, 1851, 1852, 1853, 1854)),
    CONSTRAINT chk_analyticaproductos_estadopronosticoid CHECK (estado_pronostico_id IN (1550, 1551, 1552, 1553)),
    CONSTRAINT chk_analyticaproductos_motivooutlierid CHECK (motivo_outlier_id IS NULL OR motivo_outlier_id IN (1900, 1901, 1902, 1903, 1904, 1905, 1906, 1907)),
    CONSTRAINT chk_analyticaproductos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_analyticaproductos_periodo CHECK (periodo_inicio IS NULL OR periodo_fin IS NULL OR periodo_inicio <= periodo_fin)
);
CREATE INDEX idx_analyticaproductos_varios ON analitica_productos (producto_id, sucursal_id, fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_productoid ON analitica_productos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_sucursalid ON analitica_productos (sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_clusterabc ON analitica_productos (cluster_abc) WHERE cluster_abc IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_fechaclasificacion ON analitica_productos (fecha_clasificacion DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_nivelurgenciaid ON analitica_productos (nivel_urgencia_id) WHERE nivel_urgencia_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_fechavencimientocritico ON analitica_productos (fecha_vencimiento_critico) WHERE fecha_vencimiento_critico IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_estadopronosticoid ON analitica_productos (estado_pronostico_id) WHERE estado_pronostico_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_analyticaproductos_motivooutlierid ON analitica_productos (motivo_outlier_id) WHERE motivo_outlier_id IS NOT NULL AND estado_id IN (1000, 1002);

COMMENT ON TABLE analitica_productos IS 'Reglas de la tabla - analitica_productos
R.0: La tabla analitica_productos es el repositorio central de todos los resultados analíticos generados por el motor de inteligencia artificial y aprendizaje automático para cada producto y sucursal. Su propósito es consolidar en un solo lugar las predicciones de demanda, los puntos de reorden dinámicos, el stock de seguridad calculado, la clasificación ABC de inventario y las alertas de vencimiento crítico. Esta tabla actúa como el puente entre el motor de IA (entrenamientos, modelos, métricas) y la operación diaria del negocio (compras, inventario, ventas), proporcionando inteligencia accionable para la toma de decisiones estratégicas y tácticas en tiempo real.
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

-- ================================================================================================

CREATE TABLE pedidos_online (
    pedido_online_id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    sucursal_id BIGINT NOT NULL,
    kardex_id BIGINT NULL,
    codigo VARCHAR(60) NOT NULL,
    fecha_pedido TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_estimada TIMESTAMPTZ NULL,
    fecha_entrega_real TIMESTAMPTZ NULL,
    direccion_entrega VARCHAR(500) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    instrucciones_entrega VARCHAR(500) NULL,
    estado_pedido_online_id SMALLINT NOT NULL DEFAULT 3700,		-- 3700=PENDIENTE, 3701=CONFIRMADO, 3702=PREPARANDO, 3703=EN_CAMINO, 3704=ENTREGADO, 3705=CANCELADO, 3706=RECHAZADO
    estado_pago_id SMALLINT NOT NULL DEFAULT 2555,				-- 2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO
    subtotal DECIMAL(12,2) NOT NULL,
    costo_envio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuentos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12,2) NOT NULL,
    repartidor_id BIGINT NOT NULL DEFAULT 1,
    ultima_actualizacion TIMESTAMPTZ NULL,
	observacion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_pedidosonline_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_pedidosonline_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_pedidosonline_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_pedidosonline_repartidor_id FOREIGN KEY (repartidor_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_pedidosonline_estadopedidoonlineid CHECK (estado_pedido_online_id IN (3700, 3701, 3702, 3703, 3704, 3705, 3706)),
    CONSTRAINT chk_pedidosonline_estadopagoid CHECK (estado_pago_id IN (2550, 2551, 2552, 2553, 2554, 2555)),
    CONSTRAINT chk_pedidosonline_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_pedidosonline_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_pedidosonline_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_pedidosonline_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_pedidosonline_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_pedidosonline_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_pedidosonline_costoenvio CHECK (costo_envio >= 0),
    CONSTRAINT chk_pedidosonline_descuentos CHECK (descuentos >= 0),
    CONSTRAINT chk_pedidosonline_total CHECK (total >= 0)
);
CREATE UNIQUE INDEX uix_pedidosonline_codigo_unique ON pedidos_online (codigo) WHERE estado_id = 1000;
CREATE INDEX idx_pedidosonline_clienteid ON pedidos_online (cliente_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_pedidosonline_estadopedidoonlineid ON pedidos_online (estado_pedido_online_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_pedidosonline_repartidorid ON pedidos_online(repartidor_id);
CREATE INDEX idx_pedidosonline_sucursalid ON pedidos_online(sucursal_id);
CREATE INDEX idx_pedidosonline_kardexid ON pedidos_online(kardex_id);
CREATE INDEX idx_pedidosonline_actividad_estadoid ON pedidos_online (COALESCE(fecha_actualizacion, fecha_registro), estado_id);

COMMENT ON TABLE pedidos_online IS 'Reglas de la tabla - pedidos_online
R.0: La tabla pedidos_online gestiona todos los pedidos provenientes del canal digital (e-commerce, app móvil, etc.), actuando como el puente entre la tienda virtual y el sistema de ventas tradicional. Su propósito es centralizar la información de los pedidos digitales, controlar su ciclo de vida (desde la confirmación hasta la entrega) y permitir su conversión en transacciones de venta formales en el kardex cuando el pedido es confirmado y pagado.
R.1: Gestión de Estados del Pedido (Ciclo de Vida). El campo estado_pedido_online_id controla el flujo de trabajo del pedido digital utilizando los valores (3700-3706):
- 3700 (PENDIENTE): Pedido recibido, pendiente de confirmación por la farmacia.
- 3701 (CONFIRMADO): Pedido confirmado por la farmacia, se inicia la preparación.
- 3702 (PREPARANDO): Pedido en proceso de picking y empaque en el almacén.
- 3703 (EN_CAMINO): Pedido despachado, en ruta de entrega al cliente.
- 3704 (ENTREGADO): Pedido entregado exitosamente al cliente.
- 3705 (CANCELADO): Pedido cancelado por el cliente o la farmacia antes de la entrega.
- 3706 (RECHAZADO): Pedido rechazado por el cliente en el momento de la entrega (ej. producto dañado).
R.2: Control de Pagos (estado_pago_id). El campo estado_pago_id utiliza los valores (2550-2555) para gestionar el estado financiero del pedido:
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
R.11: Índices Estratégicos. Se han creado índices específicos para optimizar las consultas más frecuentes:
- idx_pedidosonline_clienteid: Consultas de historial de pedidos por cliente.
- idx_pedidosonline_estadopedidoonlineid: Filtrado de pedidos pendientes para el dashboard de preparación.
- idx_pedidosonline_actividad_estadoid: Reportes de pedidos por período y estado.
- idx_pedidosonline_sucursalid: Consultas de pedidos por sucursal para el módulo de delivery.
R.12: Tareas Programadas para Expiración. El sistema debe ejecutar diariamente una tarea que:
- Identifique pedidos en estado PENDIENTE con fecha_pedido > 30 días.
- Automáticamente los cambie a estado CANCELADO (3705).
- Registre el evento en logs_ejecucion con motivo: "PEDIDO_EXPIRADO_POR_TIEMPO".
R.13: Validación de Cliente y Sucursal. Antes de insertar un pedido, el sistema debe validar que:
- El cliente_id exista y esté ACTIVO (estado_id = 1000).
- El cliente tenga habilitado_ventas = 1.
- La sucursal_id exista, esté ACTIVA y tenga cobertura de delivery configurada.
- La sucursal tenga stock suficiente para cubrir el pedido (se valida al confirmar, no al crear).
R.14: Integración con Módulo de Alertas. Cuando un pedido permanece en estado PREPARANDO por más de 60 minutos, el sistema debe generar una alerta de tipo SISTEMA (2700) con nivel_critico_id = 2902 (MEDIA) para notificar al encargado de almacén.
R.15: Trazabilidad de Cambios de Estado. Cada cambio de estado_pedido_online_id debe registrar automáticamente la fecha_hora en el campo ultima_actualizacion y crear un registro en logs_ejecucion con:
- modulo = ''PEDIDOS_ONLINE''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Pedido {codigo} cambió de estado {estado_anterior} a {estado_nuevo}''
- detalle = { "usuario": usuario_id, "motivo": "..." }
R.16: Política de Rechazo por Stock. Si al momento de confirmar un pedido (estado CONFIRMADO) no hay suficiente stock en la sucursal asignada, el sistema debe:
1. Intentar reasignar el pedido a otra sucursal con stock disponible.
2. Si no es posible, rechazar el pedido (estado RECHAZADO = 3706).
3. Notificar al cliente vía email (usando el módulo de notificaciones).
4. Registrar el motivo en observaciones.
R.17: Gestión de Cupones y Descuentos. Los descuentos aplicados en el campo descuentos deben validarse contra la tabla cupones_descuento cuando se aplica un código promocional. La validación debe incluir:
- El cupón debe estar ACTIVO (estado_id = 1000).
- La fecha actual debe estar entre fecha_inicio y fecha_fin.
- El número de usos_realizados < uso_maximo.
- El cliente no debe haber excedido el uso_por_cliente.
R.18: Control de Cambios de Dirección y Teléfono. Si el cliente modifica su dirección o teléfono en la tabla clientes, los pedidos ya registrados mantienen su información original de entrega (desnormalización). La interfaz de usuario debe mostrar un indicador cuando la dirección de entrega difiere de la dirección principal del cliente.
R.19: Flujo de Cancelación. Para cancelar un pedido (estado CANCELADO = 3705):
- Solo se permite si el pedido está en estado PENDIENTE (3700) o CONFIRMADO (3701).
- No se permite cancelar pedidos en estado PREPARANDO (3702), EN_CAMINO (3703) o ENTREGADO (3704).
- La cancelación debe registrar un motivo obligatorio (observaciones).
- Si el pedido ya tenía kardex_id asociado (venta generada), la cancelación debe generar una ANULACION (evento_id = 1055).';

-- ================================================================================================

CREATE TABLE detalles_pedidos_online (
    detalle_pedido_online_id BIGSERIAL PRIMARY KEY,
    pedido_online_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    kardex_producto_id BIGINT NULL,
    codigo_producto VARCHAR(60) NOT NULL,
    nombre_producto VARCHAR(600) NOT NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    descuento_unitario DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12,2) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_detallespedidosonline_pedido_online_id FOREIGN KEY (pedido_online_id) REFERENCES pedidos_online(pedido_online_id),
    CONSTRAINT fk_detallespedidosonline_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_detallespedidosonline_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT chk_detallespedidosonline_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_detallespedidosonline_codigoproducto_notempty CHECK (TRIM(codigo_producto) <> ''),
    CONSTRAINT chk_detallespedidosonline_codigoproducto_minlength CHECK (LENGTH(TRIM(codigo_producto)) >= 3),
    CONSTRAINT chk_detallespedidosonline_codigoproducto_mayusculas CHECK (codigo_producto = UPPER(codigo_producto)),
    CONSTRAINT chk_detallespedidosonline_codigoproducto_formato CHECK (codigo_producto ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_detallespedidosonline_nombreproducto_notempty CHECK (TRIM(nombre_producto) <> ''),
    CONSTRAINT chk_detallespedidosonline_nombreproducto_minlength CHECK (LENGTH(TRIM(nombre_producto)) >= 3),
    CONSTRAINT chk_detallespedidosonline_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detallespedidosonline_preciounitario CHECK (precio_unitario >= 0),
    CONSTRAINT chk_detallespedidosonline_descuentounitario CHECK (descuento_unitario >= 0),
    CONSTRAINT chk_detallespedidosonline_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_detallespedidosonline_pedidoonlineid ON detalles_pedidos_online (pedido_online_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_detallespedidosonline_productoid ON detalles_pedidos_online (producto_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_detallespedidosonline_pedido_producto ON detalles_pedidos_online (pedido_online_id, producto_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_detallespedidosonline_kardexproductoid ON detalles_pedidos_online(kardex_producto_id);

COMMENT ON TABLE detalles_pedidos_online IS 'Reglas de la tabla - detalles_pedidos_online
R.0: La tabla detalles_pedidos_online almacena el detalle de productos de cada pedido digital, incluyendo información desnormalizada (nombre, código) para garantizar la inmutabilidad del pedido ante cambios en el catálogo de productos.
R.1: Desnormalización Estratégica. Los campos codigo_producto y nombre_producto se almacenan de forma redundante para preservar la foto exacta del pedido en el momento de la compra, independientemente de futuras modificaciones en la tabla productos.
R.2: Conversión a Venta (kardex_producto_id). Cuando el pedido se convierte en una venta formal, este campo se actualiza con el ID del detalle de la transacción en kardex_productos, permitiendo la trazabilidad completa.
R.3: Control de Cantidades y Precios. La cantidad debe ser mayor a 0. El precio_unitario y el subtotal no pueden ser negativos.';

-- ================================================================================================

CREATE TABLE carritos_compra (
    carrito_id BIGSERIAL PRIMARY KEY,
	sucursal_id BIGINT NOT NULL DEFAULT 1,
    cliente_id BIGINT NOT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion_carrito TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    cliente_nombre VARCHAR(200) NOT NULL,
    cliente_documento VARCHAR(30) NOT NULL,
    total_items SMALLINT NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	estado_carrito_id SMALLINT NOT NULL DEFAULT 4906,	-- 4900=PENDIENTE, 4901=PROCESADO, 4902=EXPIRADO, 4903=ABANDONADO, 4904=EN_PROCESO, 4905=RESERVADO, 4906=NINGUNO
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_carritoscompra_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_carritoscompra_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
	CONSTRAINT chk_carritoscompra_estadocarritoid CHECK (estado_carrito_id IN (4900, 4901, 4902, 4903, 4904, 4905, 4906)),
    CONSTRAINT chk_carritoscompra_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_carritoscompra_clientenombre_notempty CHECK (TRIM(cliente_nombre) <> ''),
    CONSTRAINT chk_carritoscompra_clientenombre_minlength CHECK (LENGTH(TRIM(cliente_nombre)) >= 3),
    CONSTRAINT chk_carritoscompra_clientedocumento_notempty CHECK (TRIM(cliente_documento) <> ''),
    CONSTRAINT chk_carritoscompra_clientedocumento_formato CHECK (cliente_documento ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_carritoscompra_totalitems CHECK (total_items >= 0),
    CONSTRAINT chk_carritoscompra_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_carritoscompra_fechaexpiracion CHECK (fecha_expiracion > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_carritoscompra_clienteid_unique ON carritos_compra (cliente_id) WHERE estado_id = 1000;
CREATE INDEX idx_carritoscompra_clienteid ON carritos_compra (cliente_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_carritoscompra_fechaexpiracion ON carritos_compra (fecha_expiracion) WHERE estado_id = 1000;

COMMENT ON TABLE carritos_compra IS 'Reglas de la tabla - carritos_compra
R.0: La tabla carritos_compra persiste los carritos de compra de los clientes registrados en el e-commerce, permitiendo que los usuarios retomen sus compras en diferentes sesiones.
R.1: Control de Expiración (TTL). fecha_expiracion define el tiempo de vida del carrito (configurable en parametros_globales). Una tarea programada debe eliminar o archivar carritos expirados diariamente.
R.2: Desnormalización de Datos del Cliente. cliente_nombre y cliente_documento se almacenan para preservar la información del cliente en el momento de la creación del carrito.';

-- ================================================================================================

CREATE TABLE detalles_carritos (
    detalle_carrito_id BIGSERIAL PRIMARY KEY,
    carrito_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    codigo_producto VARCHAR(60) NOT NULL,
    nombre_producto VARCHAR(600) NOT NULL,
    presentacion_producto VARCHAR(200) NULL,
    cantidad DECIMAL(12,2) NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    descuento_unitario DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12,2) NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_detallescarritos_carrito_id FOREIGN KEY (carrito_id) REFERENCES carritos_compra(carrito_id),
    CONSTRAINT fk_detallescarritos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_detallescarritos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_detallescarritos_codigoproducto_notempty CHECK (TRIM(codigo_producto) <> ''),
    CONSTRAINT chk_detallescarritos_codigoproducto_minlength CHECK (LENGTH(TRIM(codigo_producto)) >= 3),
    CONSTRAINT chk_detallescarritos_codigoproducto_mayusculas CHECK (codigo_producto = UPPER(codigo_producto)),
    CONSTRAINT chk_detallescarritos_codigoproducto_formato CHECK (codigo_producto ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_detallescarritos_nombreproducto_notempty CHECK (TRIM(nombre_producto) <> ''),
    CONSTRAINT chk_detallescarritos_nombreproducto_minlength CHECK (LENGTH(TRIM(nombre_producto)) >= 3),
    CONSTRAINT chk_detallescarritos_presentacionproducto_notempty CHECK (presentacion_producto IS NULL OR TRIM(presentacion_producto) <> ''),
    CONSTRAINT chk_detallescarritos_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detallescarritos_preciounitario CHECK (precio_unitario >= 0),
    CONSTRAINT chk_detallescarritos_descuentounitario CHECK (descuento_unitario >= 0),
    CONSTRAINT chk_detallescarritos_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_detallescarritos_carritoid ON detalles_carritos (carrito_id) WHERE estado_id = 1000;
CREATE INDEX idx_detallescarritos_productoid ON detalles_carritos (producto_id) WHERE estado_id = 1000;

COMMENT ON TABLE detalles_carritos IS 'Reglas de la tabla - detalles_carritos
R.0: La tabla detalles_carritos almacena el detalle de productos de cada carrito de compra persistente, permitiendo a los clientes retomar sus compras en diferentes sesiones. Es la tabla hija de carritos_compra.
R.1: Desnormalización Estratégica. Los campos codigo_producto, nombre_producto y presentacion_producto se almacenan de forma redundante para preservar la foto exacta del carrito en el momento de la adición, independientemente de futuras modificaciones en la tabla productos.
R.2: Control de Cantidades y Precios. La cantidad debe ser mayor a 0. El precio_unitario, descuento_unitario y subtotal no pueden ser negativos.
R.3: Cálculo Automático del Subtotal. El subtotal se calcula como: (precio_unitario - descuento_unitario) * cantidad. El backend debe garantizar que subtotal = (precio_unitario - descuento_unitario) * cantidad.
R.4: Actualización de Totales del Carrito. Cada vez que se inserta, actualiza o elimina un detalle, el backend DEBE recalcular y actualizar los campos total_items y subtotal en la tabla carritos_compra. NO se utilizan triggers en la base de datos; la lógica debe implementarse en el servicio de carritos del backend.
R.5: Registro Inicial Comodín. El sistema debe mantener un registro inicial con detalle_carrito_id = 1 que sirve como valor predeterminado para las FK que requieran un detalle de carrito de referencia. Este registro tiene estado_id = 1003 (ANULADO) y no puede ser modificado ni eliminado.
R.6: Integración con el Módulo de Precios. El precio_unitario debe obtenerse de la tabla precios_productos según la lista de precios aplicable al cliente (público, afiliado, institucional, etc.).
R.7: Control de Stock en Tiempo Real. Al agregar un producto al carrito, el sistema debe validar que la cantidad solicitada no exceda el stock disponible en la sucursal asignada. Si no hay stock suficiente, debe notificar al usuario.
R.8: Gestión de Descuentos por Cantidad. Si el producto tiene promociones activas por cantidad (ej. 2x1, 3x2), el sistema debe aplicar el descuento_unitario correspondiente según las reglas de la promoción.
R.9: Control de Cupones. Si el cliente aplica un cupón de descuento que afecta a productos específicos, el descuento_unitario debe reflejar el beneficio del cupón proporcionalmente.
R.10: Índices Estratégicos. Se han creado índices específicos para optimizar las consultas más frecuentes:
- idx_dca_carrito: Consulta rápida del contenido de un carrito.
- idx_dca_producto: Reportes de productos más agregados a carritos.
R.11: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, ANULADO). Un detalle en estado ANULADO no puede ser modificado.
R.12: Tarea de Limpieza de Carritos Huérfanos. El sistema debe ejecutar diariamente una tarea que:
- Identifique carritos en estado ACTIVO con fecha_expiracion < CURRENT_TIMESTAMP.
- Cambie su estado a ANULADO (1003).
- Los detalles asociados también deben pasar a ANULADO.
R.13: Validación de Coherencia de Totales. Al insertar o actualizar un detalle, el backend debe validar que el subtotal del detalle sea consistente con los datos de la cabecera del carrito.
R.14: Historial de Cambios. Cada modificación en la cantidad de un producto en el carrito debe registrar el evento en logs_ejecucion con:
- modulo = ''CARRITOS_COMPRA''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Carrito {carrito_id}: Producto {producto_id} cambió cantidad de {cantidad_anterior} a {cantidad_nueva}''
R.15: Límite Máximo de Items por Carrito. El sistema debe validar que un carrito no supere el límite máximo de items configurado en parametros_globales (parametro: ''limite_items_carrito''). Si se supera, debe notificar al usuario.
R.16: Control de Productos Controlados. Si el producto requiere receta (productos.requiere_receta = 1), el sistema debe mostrar un aviso al agregarlo al carrito y requerir la carga de la receta al momento del checkout.
R.17: Gestión de Lotes y Vencimientos. Al agregar un producto al carrito, el sistema debe seleccionar el lote más próximo a vencer (FEFO - First Expired, First Out) para garantizar la rotación adecuada del inventario.
R.18: Precios Especiales por Volumen. Si la cantidad del producto supera un umbral configurado en politicas_precios, el sistema debe aplicar automáticamente el precio por volumen correspondiente.
R.19: Inmutabilidad del Detalle. Una vez que el carrito se convierte en un pedido online (tabla pedidos_online), los detalles del carrito pasan a estado ANULADO y no pueden ser modificados.
R.20: Integración con el Módulo de Ventas. Cuando un carrito se convierte en pedido online, el sistema debe:
- Crear un registro en pedidos_online con los datos del carrito.
- Crear los detalles en detalles_pedidos_online copiando los datos del carrito.
- Marcar el carrito y sus detalles como ANULADO (estado_id = 1003).
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

-- ================================================================================================

CREATE TABLE listas_precios (
    lista_precio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(500) NULL,
    es_publica SMALLINT NOT NULL DEFAULT 1,
    prioridad SMALLINT NOT NULL DEFAULT 1,
    requiere_autorizacion SMALLINT NOT NULL DEFAULT 0,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_listasprecios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_listasprecios_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_listasprecios_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_listasprecios_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_listasprecios_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_listasprecios_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_listasprecios_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_listasprecios_espublica CHECK (es_publica IN (0, 1)),
    CONSTRAINT chk_listasprecios_prioridad CHECK (prioridad > 0),
    CONSTRAINT chk_listasprecios_requiereautorizacion CHECK (requiere_autorizacion IN (0, 1))
);
CREATE UNIQUE INDEX uix_listasprecios_codigo_unique ON listas_precios (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_listasprecios_nombre_unique ON listas_precios (nombre) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE listas_precios IS 'Reglas de la tabla - listas_precios
R.0: La tabla listas_precios define los diferentes catálogos de precios comerciales que utiliza la farmacia para segmentar sus ventas por tipo de cliente (público general, afiliados, instituciones, mayoristas, etc.). Su propósito es centralizar la definición de listas de precios para que los módulos de ventas (POS y e-commerce) puedan aplicar el precio correcto según el perfil del cliente.
R.1: Gestión de Prioridad. El campo prioridad define el orden de aplicación cuando un cliente califica para múltiples listas. Un valor menor indica mayor prioridad. Ejemplo: si un cliente es afiliado y también institucional, se aplica la lista con prioridad más baja (ej. prioridad 1 = Mayorista, prioridad 2 = Institucional).
R.2: Control de Visibilidad (es_publica). es_publica = 1 indica que la lista es visible en el e-commerce para que los clientes puedan ver los precios. es_publica = 0 indica que es una lista interna (ej. precios de costo, precios especiales).
R.3: Requiere Autorización (requiere_autorizacion). requiere_autorizacion = 1 indica que para aplicar esta lista de precios se necesita autorización especial de un supervisor o gerente. El sistema debe solicitar aprobación al momento de la venta.
R.4: Unicidad de Código y Nombre. codigo y nombre deben ser únicos para registros activos o históricos.
R.5: Integración con Ventas. Al momento de una venta, el sistema debe:
- Identificar el perfil del cliente (tipo_cliente_id).
- Seleccionar la lista de precios con mayor prioridad.
- Obtener el precio de precios_productos.
- Si no existe precio para la lista seleccionada, buscar en la lista por defecto (PUB).';

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
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_preciosproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_preciosproductos_lista_precio_id FOREIGN KEY (lista_precio_id) REFERENCES listas_precios(lista_precio_id),
    CONSTRAINT chk_preciosproductos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_preciosproductos_preciobase CHECK (precio_base >= 0),
    CONSTRAINT chk_preciosproductos_preciooferta CHECK (precio_oferta IS NULL OR precio_oferta >= 0),
    CONSTRAINT chk_preciosproductos_preciominimo CHECK (precio_minimo IS NULL OR precio_minimo >= 0),
    CONSTRAINT chk_preciosproductos_precios CHECK (precio_oferta IS NULL OR precio_oferta <= precio_base),
    CONSTRAINT chk_preciosproductos_precios_vacios CHECK (precio_minimo IS NULL OR precio_minimo <= precio_base),
    CONSTRAINT chk_preciosproductos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
CREATE UNIQUE INDEX uix_preciosproductos_varios_unique ON precios_productos (producto_id, lista_precio_id) WHERE estado_id = 1000;
CREATE INDEX idx_preciosproductos_productoid ON precios_productos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_preciosproductos_listaprecioid ON precios_productos (lista_precio_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_preciosproductos_fechas ON precios_productos (fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE precios_productos IS 'Reglas de la tabla - precios_productos
R.0: La tabla precios_productos almacena los precios vigentes de cada producto en cada lista de precios, permitiendo que un producto tenga diferentes precios según el canal de venta o el perfil del cliente. Su propósito es centralizar la información de precios para que los módulos de ventas (POS y e-commerce) puedan consultar el precio correcto en tiempo real.
R.1: Control de Vigencia Temporal. fecha_inicio y fecha_fin permiten programar cambios de precios con anticipación. Si fecha_fin es NULL, el precio es indefinido. El índice uix_pp_producto_lista_vigente garantiza que solo exista un precio activo por producto y lista en un momento dado.
R.2: Precio Base vs Precio Oferta. precio_base es el precio estándar de la lista. precio_oferta es un precio promocional que reemplaza al base durante un período específico. El sistema debe usar precio_oferta si está vigente y es menor que precio_base.
R.3: Precio Mínimo (precio_minimo). Define el precio mínimo al que se puede vender el producto en esa lista. El sistema debe validar que ningún descuento adicional reduzca el precio por debajo de este umbral.
R.4: Herencia de Precios. Al crear un nuevo producto, el sistema debe:
- Copiar el precio del producto base (productos.pventa o pventaf) a la lista PÚBLICO GENERAL.
- Establecer los precios de otras listas aplicando los porcentajes de descuento configurados en parametros_globales.
R.5: Actualización Masiva de Precios. El sistema debe permitir actualizaciones masivas de precios por:
- Categoría (todos los productos de una categoría).
- Laboratorio (todos los productos de un laboratorio).
- Lista de precios específica.
- Porcentaje de incremento o decremento.
R.6: Historial de Precios. Cada cambio de precio debe registrar en logs_ejecucion:
- modulo = ''PRECIOS_PRODUCTOS''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Producto {producto_id} cambió precio en lista {lista_precio_id} de {precio_anterior} a {precio_nuevo}''
- detalle = { "usuario": usuario_id, "motivo": "..." }
R.7: Integración con Kardex. Al registrar una venta, el sistema debe:
- Obtener el precio de precios_productos según el tipo de cliente.
- Si no existe precio para la lista, usar la lista PÚBLICO GENERAL.
- Si no existe precio en ninguna lista, usar productos.pventa o pventaf.
R.8: Control de Márgenes. Al establecer un precio, el sistema debe validar que el margen de utilidad esté dentro de los límites configurados en politicas_precios.
R.9: Validación de Coherencia. precio_base debe ser mayor a 0. precio_oferta y precio_minimo pueden ser NULL. Si se especifican, deben ser menores o iguales a precio_base.';

-- ================================================================================================

CREATE TABLE costos_promedio (
    costo_promedio_id BIGSERIAL PRIMARY KEY,
    producto_id BIGINT NOT NULL,
    costo_promedio DECIMAL(12,4) NOT NULL,
    costo_ultima_compra DECIMAL(12,4) NULL,
    fecha_calculo DATE NOT NULL DEFAULT CURRENT_DATE,
    metodo_calculo_id SMALLINT NOT NULL DEFAULT 3750,	-- 3750=PONDERADO, 3751=FIFO, 3752=ULTIMA_COMPRA
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_costospromedio_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_costospromedio_metodocalculoid CHECK (metodo_calculo_id IN (3750, 3751, 3752)),
    CONSTRAINT chk_costospromedio_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_costospromedio_costopromedio CHECK (costo_promedio >= 0),
    CONSTRAINT chk_costospromedio_costoultimacompra CHECK (costo_ultima_compra IS NULL OR costo_ultima_compra >= 0)
);
CREATE UNIQUE INDEX uix_costospromedio_varios_unique ON costos_promedio (producto_id, fecha_calculo) WHERE estado_id = 1000;
CREATE INDEX idx_costospromedio_productoid ON costos_promedio (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_costospromedio_fechacalculo ON costos_promedio (fecha_calculo DESC) WHERE estado_id IN (1000, 1002);

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

-- ================================================================================================

CREATE TABLE politicas_precios (
    politica_precio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_aplicacion_id SMALLINT NOT NULL DEFAULT 4350,	-- 4350=GLOBAL, 4351=CATEGORIA, 4352=LABORATORIO, 4353=PRODUCTO
    entidad_id BIGINT NULL,
    margen_minimo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    margen_maximo DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    redondeo SMALLINT NOT NULL DEFAULT 0,
    aplica_descuentos SMALLINT NOT NULL DEFAULT 1,
    descuento_maximo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_politicasprecios_tipoaplicacionid CHECK (tipo_aplicacion_id IN (4350, 4351, 4352, 4353)),
    CONSTRAINT chk_politicasprecios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_politicasprecios_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_politicasprecios_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_politicasprecios_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_politicasprecios_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_politicasprecios_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_politicasprecios_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 3),
    CONSTRAINT chk_politicasprecios_margenes CHECK (margen_minimo >= 0 AND margen_maximo >= margen_minimo),
    CONSTRAINT chk_politicasprecios_redondeo CHECK (redondeo IN (0, 1, 5)),
    CONSTRAINT chk_politicasprecios_aplicadescuentos CHECK (aplica_descuentos IN (0, 1)),
    CONSTRAINT chk_politicasprecios_descuentomaximo CHECK (descuento_maximo >= 0 AND descuento_maximo <= 100)
);
CREATE UNIQUE INDEX uix_politicasprecios_codigo_unique ON politicas_precios (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_politicasprecios_varios ON politicas_precios (tipo_aplicacion_id, entidad_id) WHERE estado_id IN (1000, 1002);

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
- 1: Redondeo al entero más cercano (ej. 12.30 ? 12, 12.50 ? 13).
- 5: Redondeo al múltiplo de 5 más cercano (ej. 12.30 ? 10, 12.50 ? 15).
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

-- ================================================================================================

CREATE TABLE asistencias (
    asistencia_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_entrada TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    hora_salida TIMESTAMPTZ NULL,
    hora_entrada_almuerzo TIMESTAMPTZ NULL,
    hora_salida_almuerzo TIMESTAMPTZ NULL,
    horas_trabajadas DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    horas_extras DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    tipo_asistencia_id SMALLINT NOT NULL DEFAULT 4400,    -- 4400=NORMAL, 4401=LICENCIA, 4402=PERMISO, 4403=JUSTIFICADA
    estado_asistencia_id SMALLINT NOT NULL DEFAULT 4450,  -- 4450=PRESENTE, 4451=AUSENTE, 4452=TARDE, 4453=FALTA_INJUSTIFICADA
    metodo_marcacion_id SMALLINT NOT NULL DEFAULT 4500,   -- 4500=MANUAL, 4501=BIOMETRICO, 4502=QR, 4503=APP
    dispositivo VARCHAR(50) NULL,
    ip_origen VARCHAR(45) NULL,
    observaciones VARCHAR(500) NULL,
    justificacion VARCHAR(1000) NULL,
    justificacion_archivo VARCHAR(255) NULL,
    usuario_registro_id BIGINT NOT NULL DEFAULT 1,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_asistencias_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_asistencias_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_asistencias_tipoasistenciaid CHECK (tipo_asistencia_id IN (4400, 4401, 4402, 4403)),
    CONSTRAINT chk_asistencias_estadoasistenciaid CHECK (estado_asistencia_id IN (4450, 4451, 4452, 4453)),
    CONSTRAINT chk_asistencias_metodomarcacionid CHECK (metodo_marcacion_id IN (4500, 4501, 4502, 4503)),
    CONSTRAINT chk_asistencias_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_asistencias_dispositivo_notempty CHECK (dispositivo IS NULL OR TRIM(dispositivo) <> ''),
    CONSTRAINT chk_asistencias_dispositivo_minlength CHECK (dispositivo IS NULL OR LENGTH(TRIM(dispositivo)) >= 3),
    CONSTRAINT chk_asistencias_iporigen_notempty CHECK (ip_origen IS NULL OR TRIM(ip_origen) <> ''),
    CONSTRAINT chk_asistencias_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_asistencias_observaciones_minlength CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3),
    CONSTRAINT chk_asistencias_justificacion_notempty CHECK (justificacion IS NULL OR TRIM(justificacion) <> ''),
    CONSTRAINT chk_asistencias_justificacion_minlength CHECK (justificacion IS NULL OR LENGTH(TRIM(justificacion)) >= 3),
    CONSTRAINT chk_asistencias_justificacionarchivo_notempty CHECK (justificacion_archivo IS NULL OR TRIM(justificacion_archivo) <> ''),
    CONSTRAINT chk_asistencias_justificacionarchivo_minlength CHECK (justificacion_archivo IS NULL OR LENGTH(TRIM(justificacion_archivo)) >= 3),
    CONSTRAINT chk_asistencias_horastrabajadas CHECK (horas_trabajadas >= 0),
    CONSTRAINT chk_asistencias_horasextras CHECK (horas_trabajadas >= 0 AND horas_extras >= 0),
    CONSTRAINT chk_asistencias_horasalida CHECK (hora_salida IS NULL OR hora_salida >= hora_entrada),
    CONSTRAINT chk_asistencias_horas CHECK (
        hora_entrada_almuerzo IS NULL OR hora_salida_almuerzo IS NULL OR
        hora_salida_almuerzo > hora_entrada_almuerzo
    )
);
CREATE UNIQUE INDEX uix_asistencias_varios_unique ON asistencias (trabajador_id, fecha) WHERE estado_id = 1000;
CREATE INDEX idx_asistencias_fecha ON asistencias (fecha DESC) WHERE estado_id = 1000;
CREATE INDEX idx_asistencias_trabajadorid ON asistencias (trabajador_id) WHERE estado_id = 1000;
CREATE INDEX idx_asistencias_estadoasistenciaid ON asistencias (estado_asistencia_id) WHERE estado_id = 1000;
CREATE INDEX idx_asistencias_sucursalid ON asistencias(sucursal_id);
CREATE INDEX idx_asistencias_usuarioregistroid ON asistencias(usuario_registro_id);

COMMENT ON TABLE asistencias IS 'Reglas de la tabla - asistencias
R.0: La tabla asistencias registra el control de presencia de los trabajadores, permitiendo la marcación de entrada y salida, el control de horas trabajadas y la gestión de permisos y licencias. Su propósito es proporcionar la base de datos para el cálculo de planillas, el control de puntualidad y la gestión del talento humano.
R.1: Control de Jornada Laboral. Las horas_trabajadas se calculan automáticamente como la diferencia entre hora_entrada y hora_salida, restando el tiempo de almuerzo si está registrado. El backend debe calcular este valor antes de insertar o actualizar.
R.2: Tipos de Asistencia. tipo_asistencia_id utiliza los valores (4400-4403): NORMAL (4400), LICENCIA (4401), PERMISO (4402), JUSTIFICADA (4403). Afecta el cálculo de planillas y la contabilidad de ausencias.
R.3: Estado de Asistencia. estado_asistencia_id utiliza los valores (4450-4453): PRESENTE (4450), AUSENTE (4451), TARDE (4452), FALTA_INJUSTIFICADA (4453). Determina si la marcación es válida para el cálculo de horas.
R.4: Método de Marcación. metodo_marcacion_id utiliza los valores (4500-4503): MANUAL (4500), BIOMETRICO (4501), QR (4502), APP (4503). Permite auditoría y control de seguridad sobre los registros de entrada/salida.
R.5: Unicidad por Trabajador y Fecha. Cada trabajador solo puede tener un registro de asistencia por día (estado_id = 1000). El backend debe validar que no exista un registro previo antes de insertar una nueva marcación.
R.6: Validación de Fechas. No se permiten asistencias con fecha posterior a la fecha actual (fecha <= CURRENT_DATE). El backend debe validar esta condición al insertar registros.
R.7: Gestión de Permisos y Licencias. Los registros con tipo_asistencia_id = 4401 (LICENCIA) o 4402 (PERMISO) requieren justificacion_archivo y justificacion_texto. El backend debe validar que estos campos estén completos.
R.8: Cálculo Automático de Horas Extras. horas_extras se calcula como las horas trabajadas que exceden la jornada laboral definida en parametros_globales (jornada_horas_diarias, por defecto 8 horas). El backend debe calcular este valor automáticamente.
R.9: Índices Estratégicos. Los índices sobre fecha y trabajador garantizan consultas rápidas para reportes de asistencia, planillas y control de ausentismo.
R.10: Integración con Planillas. La tabla asistencias es la fuente principal de datos para el cálculo de planillas mensuales, determinando los días trabajados, horas extras y ausencias.
R.11: Control de Tardanzas. Si hora_entrada > (hora_inicio_jornada + 15 minutos), el estado_asistencia_id debe ser automáticamente 4452 (TARDE). La hora_inicio_jornada se obtiene de parametros_globales.
R.12: Marcación por QR/APP. Para metodo_marcacion_id = 4502 (QR) o 4503 (APP), el campo dispositivo debe registrar el identificador único del dispositivo o el código QR escaneado.
R.13: Auditoría de Cambios. El campo usuario_registro_id registra quién valida o modifica la asistencia, permitiendo auditar correcciones manuales.
R.14: Inmutabilidad de Registros Históricos. Una vez que la asistencia pasa a estado HISTORICO (1002), no puede ser modificada. Esto preserva la integridad de los registros para cálculos de planillas y reportes.';

-- ================================================================================================

CREATE TABLE planillas (
    planilla_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    periodo_mes SMALLINT NOT NULL,
    periodo_gestion SMALLINT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_calculo DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_pago DATE NULL,
    tipo_planilla_id SMALLINT NOT NULL DEFAULT 4600,     -- 4600=SUELDOS, 4601=JORNALES, 4602=CONTRATO
    total_bruto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_descuentos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_neto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_aportes_empresa DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_aportes_trabajador DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_aguinaldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_utilidades DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado_planilla_id SMALLINT NOT NULL DEFAULT 4650,   -- 4650=BORRADOR, 4651=CALCULADA, 4652=APROBADA, 4653=PAGADA, 4654=ANULADA
    observaciones VARCHAR(1000) NULL,
    trabajador_aprobacion_id BIGINT NOT NULL DEFAULT 1,
    trabajador_pago_id BIGINT NOT NULL DEFAULT 1,
    fecha_aprobacion TIMESTAMPTZ NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_planillas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_planillas_trabajador_aprobacion_id FOREIGN KEY (trabajador_aprobacion_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_planillas_trabajador_pago_id FOREIGN KEY (trabajador_pago_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_planillas_tipoplanillaid CHECK (tipo_planilla_id IN (4600, 4601, 4602)),
    CONSTRAINT chk_planillas_estadoplanillaid CHECK (estado_planilla_id IN (4650, 4651, 4652, 4653, 4654)),
    CONSTRAINT chk_planillas_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_planillas_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_planillas_observaciones_minlength CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3),
    CONSTRAINT chk_planillas_periodomes CHECK (periodo_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_planillas_periodogestion CHECK (periodo_gestion >= 2020 AND periodo_gestion <= 2100),
    CONSTRAINT chk_planillas_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_planillas_totalbruto CHECK (total_bruto >= 0),
    CONSTRAINT chk_planillas_totaldescuentos CHECK (total_descuentos >= 0),
    CONSTRAINT chk_planillas_totalneto CHECK (total_neto >= 0),
    CONSTRAINT chk_planillas_totalaportesempresa CHECK (total_aportes_empresa >= 0),
    CONSTRAINT chk_planillas_totalaportestrabajador CHECK (total_aportes_trabajador >= 0),
    CONSTRAINT chk_planillas_totalaguinaldo CHECK (total_aguinaldo >= 0),
    CONSTRAINT chk_planillas_totalutilidades CHECK (total_utilidades >= 0),
    CONSTRAINT chk_planillas_total CHECK (total_bruto >= 0 AND total_descuentos >= 0 AND total_neto >= 0)
);
CREATE INDEX idx_planillas_fechacalculo ON planillas (fecha_calculo DESC) WHERE estado_id IN (1000);
CREATE INDEX idx_planillas_estadoplanillaid ON planillas (estado_planilla_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_planillas_periodos ON planillas (periodo_gestion, periodo_mes) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_planillas_trabajadorpagoid ON planillas(trabajador_pago_id);
CREATE INDEX idx_planillas_sucursalid ON planillas(sucursal_id);
CREATE INDEX idx_planillas_trabajadoraprobacionid ON planillas(trabajador_aprobacion_id);

COMMENT ON TABLE planillas IS 'Reglas de la tabla - planillas
R.0: La tabla planillas es la cabecera de los procesos de liquidación de sueldos y salarios, agrupando los pagos a los trabajadores por período. Su propósito es centralizar el cálculo y la gestión de las planillas mensuales, permitiendo la auditoría y el control financiero de la nómina.
R.1: Unicidad por Período. Solo puede existir una planilla por mes y gestión en cada sucursal en estado ACTIVO (no ANULADA). El índice uix_pla_sucursal_mes_gestion garantiza esta unicidad.
R.2: Ciclo de Vida de la Planilla. estado_planilla_id utiliza los valores (4650-4654): BORRADOR (inicial, editable), CALCULADA (valores calculados, pendiente de aprobación), APROBADA (aprobada por gerencia), PAGADA (pagada a los trabajadores), ANULADA (cancelada, irreversible).
R.3: Transiciones de Estado. Las transiciones de estado deben ser secuenciales: BORRADOR -> CALCULADA -> APROBADA -> PAGADA. No se permiten saltos de estado. ANULADA solo puede ser aplicada desde BORRADOR o CALCULADA.
R.4: Cálculo Automático de Totales. Los campos total_bruto, total_descuentos, total_neto, total_aportes_empresa y total_aportes_trabajador se calculan automáticamente al pasar de BORRADOR a CALCULADA. El backend debe recalcular estos valores sumando los registros de planillas_detalle.
R.5: Fechas de Corte. fecha_inicio y fecha_fin definen el período de la planilla. Generalmente, fecha_inicio = primer día del mes y fecha_fin = último día del mes. El backend debe validar que la planilla no se solape con otras planillas en la misma sucursal.
R.6: Autorización y Pago. Los campos trabajador_aprobacion_id, trabajador_pago_id, fecha_aprobacion y fecha_pago se actualizan automáticamente cuando la planilla cambia de estado a APROBADA o PAGADA.
R.7: Tipos de Planilla. tipo_planilla_id utiliza los valores (4600-4602): SUELDOS (mensual), JORNALES (diario/semanal), CONTRATO (por proyecto). Afecta el cálculo de conceptos y la periodicidad.
R.8: Gestión de Aguinaldo y Utilidades. total_aguinaldo y total_utilidades se calculan en períodos específicos (diciembre para aguinaldo, según normativa para utilidades). El backend debe validar que estos campos solo se calculen en los períodos correspondientes.
R.9: Integración con Contabilidad. Una vez que la planilla alcanza el estado PAGADA, el sistema debe generar automáticamente los asientos contables correspondientes en el módulo de contabilidad (tabla asientos_contables).
R.10: Política de Retención. Las planillas deben conservarse indefinidamente por requisitos legales. No se permite la eliminación física de planillas (estado_id = 1001). Solo pueden pasar a HISTORICO (1002) después de 5 años.
R.11: Notificación de Aprobación. Cuando una planilla pasa a estado APROBADA, el sistema debe enviar una notificación (alertas_notificaciones) al trabajador responsable de pagos.
R.12: Índices Estratégicos. Los índices sobre fecha y período garantizan consultas rápidas para reportes financieros y auditorías fiscales.
R.13: Relación con el Módulo de Caja. Al pasar a PAGADA, la planilla debe generar movimientos de egreso en la tabla movimientos (caja) por el total_neto.
R.14: Validación de Fechas de Pago. fecha_pago no puede ser anterior a fecha_calculo. El backend debe validar que el pago se realice después del cálculo.
R.15: Control de Presupuesto. Al aprobar una planilla, el sistema debe validar que total_neto no exceda el presupuesto de nómina configurado en parametros_globales (presupuesto_nomina_mensual).';

-- ================================================================================================

CREATE TABLE planillas_detalle (
    planilla_detalle_id BIGSERIAL PRIMARY KEY,
    planilla_id BIGINT NOT NULL DEFAULT 1,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    cargo_id BIGINT NOT NULL DEFAULT 1,
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
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_planillasdetalle_planilla_id FOREIGN KEY (planilla_id) REFERENCES planillas(planilla_id),
    CONSTRAINT fk_planillasdetalle_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_planillasdetalle_cargo_id FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id),
    CONSTRAINT chk_planillasdetalle_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_planillasdetalle_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_planillasdetalle_observaciones_minlength CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3),
    CONSTRAINT chk_planillasdetalle_sueldobase CHECK (sueldo_base >= 0),
    CONSTRAINT chk_planillasdetalle_diastrabajados CHECK (dias_trabajados >= 0 AND dias_trabajados <= 31),
    CONSTRAINT chk_planillasdetalle_horastrabajadas CHECK (horas_trabajadas >= 0),
    CONSTRAINT chk_planillasdetalle_horasextras CHECK (horas_extras >= 0),
    CONSTRAINT chk_planillasdetalle_valorhoraextra CHECK (valor_hora_extra >= 0),
    CONSTRAINT chk_planillasdetalle_totalhorasextras CHECK (total_horas_extras >= 0),
    CONSTRAINT chk_planillasdetalle_bonificaciones CHECK (bonificaciones >= 0),
    CONSTRAINT chk_planillasdetalle_comisiones CHECK (comisiones >= 0),
    CONSTRAINT chk_planillasdetalle_aguinaldo CHECK (aguinaldo >= 0),
    CONSTRAINT chk_planillasdetalle_utilidades CHECK (utilidades >= 0),
    CONSTRAINT chk_planillasdetalle_totalingresos CHECK (total_ingresos >= 0),
    CONSTRAINT chk_planillasdetalle_descuentoslegales CHECK (descuentos_legales >= 0),
    CONSTRAINT chk_planillasdetalle_descuentosextra CHECK (descuentos_extra >= 0),
    CONSTRAINT chk_planillasdetalle_aportesempresa CHECK (aportes_empresa >= 0),
    CONSTRAINT chk_planillasdetalle_aportestrabajador CHECK (aportes_trabajador >= 0),
    CONSTRAINT chk_planillasdetalle_netopagar CHECK (neto_pagar >= 0),
    CONSTRAINT chk_planillasdetalle_horas CHECK (horas_trabajadas >= 0 AND horas_extras >= 0),
    CONSTRAINT chk_planillasdetalle_varios CHECK (
        total_ingresos >= 0 AND descuentos_legales >= 0 AND
        descuentos_extra >= 0 AND neto_pagar >= 0
    )
);
CREATE UNIQUE INDEX uix_planillasdetalle_varios_unique ON planillas_detalle (planilla_id, trabajador_id) WHERE estado_id = 1000;
CREATE INDEX idx_planillasdetalle_trabajadorid ON planillas_detalle (trabajador_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_planillasdetalle_planillaid ON planillas_detalle (planilla_id) WHERE estado_id IN (1000, 1003);

COMMENT ON TABLE planillas_detalle IS 'Reglas de la tabla - planillas_detalle
R.0: La tabla planillas_detalle almacena el detalle de la liquidación de cada trabajador en una planilla, incluyendo sueldos, bonificaciones, descuentos y aportes. Su propósito es desglosar el cálculo de la nómina por empleado para auditoría y control.
R.1: Cálculo Automático de Totales. Los campos total_ingresos y neto_pagar se calculan automáticamente al generar la planilla. El backend debe recalcular estos valores si se modifican los conceptos base.
R.2: Cálculo del Neto a Pagar. neto_pagar = (sueldo_base + total_horas_extras + bonificaciones + comisiones + aguinaldo + utilidades) - (descuentos_legales + descuentos_extra). La restricción chk_plad_coherencia valida esta fórmula.
R.3: Cálculo de Horas Extras. total_horas_extras = horas_extras * valor_hora_extra. El valor_hora_extra se calcula como (sueldo_base / 30 / 8) * 1.5 (según normativa laboral). El backend debe calcular estos valores automáticamente.
R.4: Descuentos Legales. descuentos_legales incluye conceptos como AFP, seguridad social, impuestos, etc. El backend debe calcular estos valores según la normativa vigente en parametros_globales.
R.5: Aportes Empresa vs Trabajador. aportes_empresa y aportes_trabajador se calculan según los porcentajes definidos en parametros_globales (ej. aporte_empresa_porcentaje, aporte_trabajador_porcentaje).
R.6: Gestión de Aguinaldo y Utilidades. Los campos aguinaldo y utilidades solo se calculan en los períodos correspondientes (diciembre para aguinaldo, según normativa para utilidades). El backend debe validar que estos campos solo se llenen en los períodos correctos.
R.7: Integración con Asistencias. dias_trabajados y horas_trabajadas se calculan automáticamente a partir de la tabla asistencias para el período de la planilla. El backend debe sumar las horas y días registrados.
R.8: Inmutabilidad de Detalles. Una vez que la planilla pasa a estado CALCULADA, los detalles no pueden ser modificados directamente. Cualquier corrección debe realizarse mediante un ajuste en la planilla (descuentos_extra o bonificaciones).
R.9: Validación de Sueldo Base. sueldo_base debe ser igual al sueldo registrado en trabajadores_cargos.sueldo_base. El backend debe validar esta coherencia al generar la planilla.
R.10: Índices Estratégicos. Los índices sobre planilla y trabajador garantizan consultas rápidas para reportes de nómina y auditorías individuales.
R.11: Relación con Pagos. Al pagar una planilla, el sistema debe generar registros en pagos para cada trabajador, vinculando el planilla_detalle_id con el pago correspondiente.
R.12: Trazabilidad de Cambios. Cualquier modificación manual en una planilla detalle (por ejemplo, ajuste de descuentos_extra) debe registrar el motivo en observaciones y el usuario responsable en usuario_id_actualizacion.
R.13: Notificación de Inconsistencias. Si neto_pagar es 0 o negativo, el sistema debe generar una alerta de tipo RRHH (5200) con nivel_critico_id = 2902 (MEDIA) para revisión del supervisor.';

-- ================================================================================================

CREATE TABLE contratos (
    contrato_id BIGSERIAL PRIMARY KEY,
    trabajador_id BIGINT NOT NULL DEFAULT 1,
    tipo_contrato_id SMALLINT NOT NULL DEFAULT 4750,    -- 4750=INDEFINIDO, 4751=FIJO, 4752=EVENTUAL, 4753=PRACTICAS, 4754=CONSULTORIA
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    sueldo_base DECIMAL(12,2) NOT NULL,
    moneda_sueldo_id SMALLINT NOT NULL DEFAULT 2300,    -- 2300=BOB, 2301=USD, 2302=EUR
    tipo_jornada_id SMALLINT NOT NULL DEFAULT 4800,     -- 4800=COMPLETA, 4801=MEDIA, 4802=POR_HORAS
    horas_semanales DECIMAL(5,2) NOT NULL DEFAULT 40.00,
    estado_contrato_id SMALLINT NOT NULL DEFAULT 4700,  -- 4700=VIGENTE, 4701=FINALIZADO, 4702=RENOVADO, 4703=SUSPENDIDO
    observaciones VARCHAR(1000) NULL,
    documento_contrato VARCHAR(255) NULL,
    fecha_firma DATE NULL,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_contratos_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT chk_contratos_tipocontratoid CHECK (tipo_contrato_id IN (4750, 4751, 4752, 4753, 4754)),
    CONSTRAINT chk_contratos_monedasueldoid CHECK (moneda_sueldo_id IN (2300, 2301, 2302)),
    CONSTRAINT chk_contratos_tipojornadaid CHECK (tipo_jornada_id IN (4800, 4801, 4802)),
    CONSTRAINT chk_contratos_estadocontratoid CHECK (estado_contrato_id IN (4700, 4701, 4702, 4703)),
    CONSTRAINT chk_contratos_estadoid CHECK (estado_id IN (1000, 1001, 1003)),
    CONSTRAINT chk_contratos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_contratos_observaciones_minlength CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3),
    CONSTRAINT chk_contratos_documentocontrato_notempty CHECK (documento_contrato IS NULL OR TRIM(documento_contrato) <> ''),
    CONSTRAINT chk_contratos_documentocontrato_minlength CHECK (documento_contrato IS NULL OR LENGTH(TRIM(documento_contrato)) >= 3),
    CONSTRAINT chk_contratos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT chk_contratos_sueldobase CHECK (sueldo_base >= 0),
    CONSTRAINT chk_contratos_horassemanales CHECK (horas_semanales > 0)
);
CREATE UNIQUE INDEX uix_contratos_trabajadorid_unique ON contratos (trabajador_id) WHERE estado_contrato_id = 4750 AND estado_id = 1000;
CREATE INDEX idx_contratos_trabajadorid ON contratos (trabajador_id) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_contratos_fechas ON contratos (fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1003);
CREATE INDEX idx_contratos_estadocontratoid ON contratos (estado_contrato_id) WHERE estado_id IN (1000, 1003);

COMMENT ON TABLE contratos IS 'Reglas de la tabla - contratos
R.0: La tabla contratos gestiona el histórico de contratos laborales de los trabajadores, permitiendo controlar las fechas de vigencia, sueldos y condiciones de contratación. Su propósito es mantener un registro completo de la relación laboral para auditoría, cálculo de antigüedad y gestión de beneficios.
R.1: Unicidad de Contrato Vigente. Solo puede existir un contrato activo por trabajador (estado_contrato_id = 4700). El índice uix_con_trabajador_vigente garantiza esta unicidad.
R.2: Renovaciones Automáticas. Al renovar un contrato, el contrato anterior debe pasar a estado FINALIZADO (4701) y se crea uno nuevo con estado VIGENTE (4700). El backend debe gestionar esta transición.
R.3: Control de Fechas. fecha_inicio es obligatoria. fecha_fin puede ser NULL para contratos indefinidos o que aún no tienen fecha de término.
R.4: Gestión de Documentos. documento_contrato almacena la ruta del archivo PDF del contrato firmado. Sigue la regla R.G.8 para nomenclatura de archivos.
R.5: Tipos de Contrato. tipo_contrato_id utiliza los valores (4750-4754): INDEFINIDO, FIJO, EVENTUAL, PRACTICAS, CONSULTORIA. Afecta el cálculo de beneficios y la normativa aplicable.
R.6: Integración con Planillas. El sueldo_base del contrato vigente se utiliza como base para el cálculo de la planilla mensual. Si el trabajador tiene un contrato con moneda diferente, el backend debe aplicar el tipo de cambio vigente.
R.7: Notificación de Vencimiento. Cuando un contrato con fecha_fin definida está a 30 días de vencer, el sistema debe generar una alerta de tipo VENCIMIENTO_CONTRATO (4553 / 2726) para notificar al supervisor.
R.8: Historial de Cambios. Cada cambio de estado o actualización del contrato debe registrar el evento en logs_ejecucion para trazabilidad completa.';

-- ================================================================================================

CREATE TABLE historicos (
    historico_id BIGSERIAL PRIMARY KEY,
    kardex_id BIGINT NOT NULL,
	cliente_id BIGINT NOT NULL DEFAULT 1,
    cliente_nombre VARCHAR(200) NOT NULL,
    cliente_documento VARCHAR(30) NOT NULL,
    cliente_documento_complemento VARCHAR(10) NULL,
    cliente_tipo_documento_abreviatura VARCHAR(10) NOT NULL,
    cliente_razon_social VARCHAR(150) NULL,
    cliente_direccion VARCHAR(255) NULL,
    cliente_telefono VARCHAR(100) NULL,
    cliente_email VARCHAR(100) NULL,
	sucursal_id BIGINT NOT NULL DEFAULT 1,
    sucursal_nombre VARCHAR(2000) NOT NULL,
    sucursal_codigo VARCHAR(30) NOT NULL,
    sucursal_telefono VARCHAR(100) NULL,
    sucursal_ubicacion VARCHAR(500) NULL,
    sucursal_codigo_sin INTEGER NOT NULL,
    sucursal_punto_venta INTEGER NOT NULL,
	empresa_id BIGINT NOT NULL DEFAULT 1,
    empresa_nombre VARCHAR(200) NOT NULL,
    empresa_codigo VARCHAR(30) NOT NULL,
    empresa_nit VARCHAR(30) NOT NULL,
    empresa_autorizacion VARCHAR(50) NOT NULL,
    empresa_actividad_economica VARCHAR(200) NULL,
	numero_factura VARCHAR(60) NOT NULL,
    fecha_emision TIMESTAMPTZ NOT NULL,
    tipo_comprobante_abreviatura VARCHAR(10) NOT NULL,
    tipo_factura_abreviatura VARCHAR(10) NOT NULL,
    lugar_entrega VARCHAR(2000) NULL,
	items JSONB NOT NULL,
	subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    descuento_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    iva DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_cambio DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    metodo_pago_abreviatura VARCHAR(10) NOT NULL DEFAULT 'E',
    tipo_moneda_abreviatura VARCHAR(10) NOT NULL DEFAULT 'BOB',
    factor_cambio DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_historicos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_historicos_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_historicos_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_historicos_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT chk_historicos_estadoid CHECK (estado_id IN (1000, 1001, 1002, 1003)),
    CONSTRAINT chk_historicos_clientenombre_notempty CHECK (TRIM(cliente_nombre) <> ''),
    CONSTRAINT chk_historicos_clientenombre_minlength CHECK (LENGTH(TRIM(cliente_nombre)) >= 3),
    CONSTRAINT chk_historicos_clientedocumento_notempty CHECK (TRIM(cliente_documento) <> ''),
    CONSTRAINT chk_historicos_clientedocumentocomplemento_notempty CHECK (cliente_documento_complemento IS NULL OR TRIM(cliente_documento_complemento) <> ''),
    CONSTRAINT chk_historicos_clientetipodocumentoabreviatura_notempty CHECK (TRIM(cliente_tipo_documento_abreviatura) <> ''),
    CONSTRAINT chk_historicos_clienterazonsocial_notempty CHECK (cliente_razon_social IS NULL OR TRIM(cliente_razon_social) <> ''),
    CONSTRAINT chk_historicos_clientedireccion_notempty CHECK (cliente_direccion IS NULL OR TRIM(cliente_direccion) <> ''),
    CONSTRAINT chk_historicos_clientetelefono_notempty CHECK (cliente_telefono IS NULL OR TRIM(cliente_telefono) <> ''),
    CONSTRAINT chk_historicos_clienteemail_notempty CHECK (cliente_email IS NULL OR TRIM(cliente_email) <> ''),
    CONSTRAINT chk_historicos_sucursalnombre_notempty CHECK (TRIM(sucursal_nombre) <> ''),
    CONSTRAINT chk_historicos_sucursalnombre_minlength CHECK (LENGTH(TRIM(sucursal_nombre)) >= 3),
    CONSTRAINT chk_historicos_sucursalcodigo_notempty CHECK (TRIM(sucursal_codigo) <> ''),
    CONSTRAINT chk_historicos_sucursaltelefono_notempty CHECK (sucursal_telefono IS NULL OR TRIM(sucursal_telefono) <> ''),
    CONSTRAINT chk_historicos_sucursalubicacion_notempty CHECK (sucursal_ubicacion IS NULL OR TRIM(sucursal_ubicacion) <> ''),
    CONSTRAINT chk_historicos_empresanombre_notempty CHECK (TRIM(empresa_nombre) <> ''),
    CONSTRAINT chk_historicos_empresanombre_minlength CHECK (LENGTH(TRIM(empresa_nombre)) >= 3),
    CONSTRAINT chk_historicos_empresacodigo_notempty CHECK (TRIM(empresa_codigo) <> ''),
    CONSTRAINT chk_historicos_empresanit_notempty CHECK (TRIM(empresa_nit) <> ''),
    CONSTRAINT chk_historicos_empresaautorizacion_notempty CHECK (TRIM(empresa_autorizacion) <> ''),
    CONSTRAINT chk_historicos_empresaactividadeconomica_notempty CHECK (empresa_actividad_economica IS NULL OR TRIM(empresa_actividad_economica) <> ''),
    CONSTRAINT chk_historicos_numerofactura CHECK (TRIM(numero_factura) <> ''),
    CONSTRAINT chk_historicos_numerofactura_minlength CHECK (LENGTH(TRIM(numero_factura)) >= 3),
    CONSTRAINT chk_historicos_tipocomprobanteabreviatura_notempty CHECK (TRIM(tipo_comprobante_abreviatura) <> ''),
    CONSTRAINT chk_historicos_tipofacturaabreviatura_notempty CHECK (TRIM(tipo_factura_abreviatura) <> ''),
    CONSTRAINT chk_historicos_lugarentrega_notempty CHECK (lugar_entrega IS NULL OR TRIM(lugar_entrega) <> ''),
    CONSTRAINT chk_historicos_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_historicos_descuentototal CHECK (descuento_total >= 0),
    CONSTRAINT chk_historicos_iva CHECK (iva >= 0),
    CONSTRAINT chk_historicos_total CHECK (total >= 0),
    CONSTRAINT chk_historicos_totalpagado CHECK (total_pagado >= 0),
    CONSTRAINT chk_historicos_totalcambio CHECK (total_cambio >= 0),
    CONSTRAINT chk_historicos_metodopagoabreviatura_notempty CHECK (TRIM(metodo_pago_abreviatura) <> ''),
    CONSTRAINT chk_historicos_tipomonedaabreviatura_notempty CHECK (TRIM(tipo_moneda_abreviatura) <> ''),
    CONSTRAINT chk_historicos_factorcambio CHECK (factor_cambio > 0)
);
CREATE INDEX idx_historicos_kardexid ON historicos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_clienteid ON historicos (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_sucursalid ON historicos (sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_empresaid ON historicos (empresa_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_numerofactura ON historicos (numero_factura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_fechaemision ON historicos (fecha_emision DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_clientedocumento ON historicos (cliente_documento) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_fecharegistro ON historicos (fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_historicos_items ON historicos USING GIN (items);
CREATE INDEX idx_historicos_actividad_estadoid ON historicos (COALESCE(fecha_actualizacion, fecha_registro), estado_id);

COMMENT ON TABLE historicos IS 'Reglas de la tabla - historicos
R.0: La tabla historicos es el repositorio inmutable de los documentos fiscales emitidos, que congela toda la información contextual del momento de la transacción (cliente, productos, precios, empresa). Su propósito es garantizar la no repudiación y el cumplimiento fiscal, preservando la foto exacta de cada factura para su posterior consulta y auditoría, independientemente de los cambios que sufran las tablas maestras a lo largo del tiempo.
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

-- ================================================================================================
-- ================================================================================================

DO $$ 
DECLARE 
    r RECORD;
BEGIN
    SET session_replication_role = replica;
    
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
    
    FOR r IN (SELECT sequencename FROM pg_sequences WHERE schemaname = 'public')
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || quote_ident(r.sequencename) || ' RESTART WITH 1';
    END LOOP;
    
    SET session_replication_role = origin;
    
    RAISE NOTICE 'Todas las tablas limpiadas y secuencias reiniciadas';
END $$;

-- ================================================================================================

DELETE FROM bancos;
ALTER SEQUENCE bancos_banco_id_seq RESTART WITH 1;

INSERT INTO bancos (banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', '99', 'NIN', 1000, 1),
(2, 'BANCO NACIONAL DE BOLIVIA S.A.', '01', 'BNB', 1000, 2),
(3, 'BANCO MERCANTIL SANTA CRUZ S.A.', '02', 'BMSC', 1000, 2),
(4, 'BANCO BISA S.A.', '03', 'BISA', 1000, 2),
(5, 'BANCO DE CREDITO DE BOLIVIA S.A.', '04', 'BCB', 1000, 2),
(6, 'BANCO ECONOMICO S.A.', '05', 'BEC', 1000, 2),
(7, 'BANCO GANADERO S.A.', '06', 'BGA', 1000, 2),
(8, 'BANCO SOLIDARIO S.A.', '07', 'BSO', 1000, 2),
(9, 'BANCO UNION S.A.', '08', 'BUN', 1000, 2),
(10, 'BANCO FIE S.A.', '09', 'FIE', 1000, 2),
(11, 'BANCO PRODEM S.A.', '10', 'PRD', 1000, 2),
(12, 'BANCO PYME ECOFUTURO S.A.', '11', 'ECO', 1000, 2),
(13, 'BANCO PYME DE LA COMUNIDAD S.A.', '12', 'BCO', 1000, 2);

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

-- ================================================================================================

DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro) VALUES
(1, 2300, 2301, 1.0000, 1.0000, '2099-12-31', 1000, 1);

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro)
SELECT 
    ROW_NUMBER() OVER (ORDER BY fecha) + 1 AS tipo_cambio_id,
    2300 AS origen_moneda_id,
    2301 AS destino_moneda_id,
    6.8600 AS factor_compra,
    6.9600 AS factor_venta,
    fecha::date AS fecha_cotizacion,
    1000 AS estado_id,
    2 AS usuario_id_registro
FROM generate_series('2026-01-01'::date, '2026-12-31'::date, '1 day'::interval) AS fecha;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 0), (SELECT COUNT(*) > 0 FROM tipos_cambios));

-- ================================================================================================

DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.png', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@gmail.com', 'MAT-000', 1000, 1),
(2, 'FARMACIA SALUD Y VIDA S.R.L.', '309', '2.png', 'Tu salud es nuestra prioridad', 'Venta de medicamentos', 'LA PAZ - BOLIVIA', 'JUAN PEREZ FLORES', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '22441122', 'central@saludyvida.com.bo', 'M-356981', 1000, 2);

SELECT setval('empresas_empresa_id_seq', COALESCE((SELECT MAX(empresa_id) FROM empresas), 0), (SELECT COUNT(*) > 0 FROM empresas));

-- ================================================================================================

DELETE FROM empresas_nits;
ALTER SEQUENCE empresas_nits_empresa_nit_id_seq RESTART WITH 1;

INSERT INTO empresas_nits (empresa_nit_id, empresa_id, ambiente_id, nit, razon_social, actividad_economica_principal, etiqueta, modalidad_facturacion_id, certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id, usuario_id_registro) VALUES
(1, 1, 2751, '0000000', 'NINGUNO', 'NINGUNA', 'NINGUNO', 3900, NULL, NULL, NULL, NULL, NULL, 'ninguno@ninguno.com', 1000, 1),
(2, 2, 2750, '123456789', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE MEDICAMENTOS EN GENERAL', 'MEDICAMENTOS', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'ventas@saludyvida.com.bo', 1000, 2),
(3, 2, 2750, '987654321', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE JUGUETES Y ARTICULOS RECREATIVOS', 'JUGUETES', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'juguetes@saludyvida.com.bo', 1000, 2),
(4, 2, 2750, '456789123', 'FARMACIA SALUD Y VIDA S.R.L.', 'SERVICIOS MEDICOS Y CONSULTAS', 'MEDICOS', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'servicios@saludyvida.com.bo', 1000, 2),
(5, 2, 2750, '789123456', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE EQUIPOS ELECTRONICOS Y DISPOSITIVOS', 'ELECTRONICA', 3902, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'electronicos@saludyvida.com.bo', 1000, 2),
(6, 2, 2751, '321654987', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE MATERIAL DE ESCRITORIO Y SUMINISTROS DE OFICINA', 'ESCRITORIO', 3900, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'escritorio@saludyvida.com.bo', 1000, 2),
(7, 2, 2750, '321654988', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE LIBROS', 'LIBROS', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'libros@saludyvida.com.bo', 1000, 2);

SELECT setval('empresas_nits_empresa_nit_id_seq', COALESCE((SELECT MAX(empresa_nit_id) FROM empresas_nits), 0), (SELECT COUNT(*) > 0 FROM empresas_nits));

-- ================================================================================================

DELETE FROM empresas_cuentas;
ALTER SEQUENCE empresas_cuentas_empresa_cuenta_id_seq RESTART WITH 1;

INSERT INTO empresas_cuentas (empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 2300, '0000000000', 1755, 'NINGUNO', 1000, 1),
(2, 2, 2, 2300, '1000001234', 1750, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2),
(3, 2, 5, 2300, '4000003456', 1751, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2),
(4, 2, 4, 2301, '3000005678', 1751, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2);

SELECT setval('empresas_cuentas_empresa_cuenta_id_seq', COALESCE((SELECT MAX(empresa_cuenta_id) FROM empresas_cuentas), 0), (SELECT COUNT(*) > 0 FROM empresas_cuentas));

-- ================================================================================================

DELETE FROM sucursales;
ALTER SEQUENCE sucursales_sucursal_id_seq RESTART WITH 1;

INSERT INTO sucursales (sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', 'NIN', 0, '00000000', 'DIRECCION NINGUNA', '00:00 - 00:00', 1.50, 1.19, 1000, 1),
(2, 2, 'CASA MATRIZ - SOPOCACHI', 'FARMACIA SALUD Y VIDA - CASA MATRIZ SOPOCACHI', 'FSM', 0, '22441122', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '08:00 - 22:00', 1.50, 1.19, 1000, 2),
(3, 2, 'SUCURSAL ZONA SUR', 'FARMACIA SALUD Y VIDA - SUCURSAL ZONA SUR CALACOTO', 'FSZ', 1, '22774433', 'AV. BALLIVIAN NRO. 540, CALACOTO, LA PAZ', '08:00 - 23:00', 1.50, 1.19, 1000, 2);

SELECT setval('sucursales_sucursal_id_seq', COALESCE((SELECT MAX(sucursal_id) FROM sucursales), 0), (SELECT COUNT(*) > 0 FROM sucursales));

-- ================================================================================================

DELETE FROM puntos_venta;
ALTER SEQUENCE puntos_venta_punto_venta_id_seq RESTART WITH 1;

INSERT INTO puntos_venta (punto_venta_id, sucursal_id, codigo, nombre, tipo_punto_venta_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0, 'NINGUNO', 3950, 1000, 1),
(2, 2, 1, 'CAJA PRINCIPAL - SOPOCACHI', 3951, 1000, 2),
(3, 2, 2, 'CAJA SECUNDARIA - SOPOCACHI', 3951, 1000, 2),
(4, 3, 3, 'CAJA PRINCIPAL - ZONA SUR', 3951, 1000, 2);

SELECT setval('puntos_venta_punto_venta_id_seq', COALESCE((SELECT MAX(punto_venta_id) FROM puntos_venta), 0), (SELECT COUNT(*) > 0 FROM puntos_venta));

-- ================================================================================================

DELETE FROM cuis;
ALTER SEQUENCE cuis_cuis_id_seq RESTART WITH 1;

INSERT INTO cuis (cuis_id, sucursal_id, punto_venta_id, codigo_cuis, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1),
(2, 2, 2, 'CUIS-FSM-001', '2027-12-31 23:59:59-04', 1000, 2),
(3, 2, 3, 'CUIS-FSM-002', '2027-12-31 23:59:59-04', 1000, 2),
(4, 3, 4, 'CUIS-FSZ-001', '2027-12-31 23:59:59-04', 1000, 2);

SELECT setval('cuis_cuis_id_seq', COALESCE((SELECT MAX(cuis_id) FROM cuis), 0), (SELECT COUNT(*) > 0 FROM cuis));

-- ================================================================================================

DELETE FROM cufd;
ALTER SEQUENCE cufd_cufd_id_seq RESTART WITH 1;

INSERT INTO cufd (cufd_id, sucursal_id, punto_venta_id, codigo_cufd, codigo_control, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1),
(2, 2, 2, 'CUFD-FSM-001', 'CTRL-FSM-001', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2),
(3, 2, 3, 'CUFD-FSM-002', 'CTRL-FSM-002', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2),
(4, 3, 4, 'CUFD-FSZ-001', 'CTRL-FSZ-001', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2);

SELECT setval('cufd_cufd_id_seq', COALESCE((SELECT MAX(cufd_id) FROM cufd), 0), (SELECT COUNT(*) > 0 FROM cufd));

-- ================================================================================================

DELETE FROM unidades;
ALTER SEQUENCE unidades_unidad_id_seq RESTART WITH 1;

INSERT INTO unidades (unidad_id, codigo, codigo_sin, unidad, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 0, 'NINGUNA', 1000, 1),
(2, 'KG', 1, 'KILOGRAMO', 1000, 2),
(3, 'G', 2, 'GRAMO', 1000, 2),
(4, 'T', 3, 'TONELADA', 1000, 2),
(5, 'L', 4, 'LITRO', 1000, 2),
(6, 'ML', 5, 'MILILITRO', 1000, 2),
(7, 'M', 6, 'METRO', 1000, 2),
(8, 'CM', 7, 'CENTÍMETRO', 1000, 2),
(9, 'U', 58, 'UNIDAD', 1000, 2),
(10, 'PZ', 58, 'PIEZA', 1000, 2),
(11, 'CJ', 58, 'CAJA', 1000, 2),
(12, 'PQ', 58, 'PAQUETE', 1000, 2),
(13, 'MG', 10, 'MILIGRAMO', 1000, 2),
(14, 'MCG', 11, 'MICROGRAMO', 1000, 2),
(15, 'UI', 12, 'UNIDAD INTERNACIONAL', 1000, 2),
(16, 'MEQ', 13, 'MILIEQUIVALENTE', 1000, 2),
(17, 'MMOL', 14, 'MILIMOL', 1000, 2),
(18, 'CM2', 15, 'CENTÍMETRO CUADRADO', 1000, 2),
(19, 'MM', 16, 'MILÍMETRO', 1000, 2),
(20, 'MCG/KG', 17, 'MICROGRAMO POR KILOGRAMO', 1000, 2),
(21, 'MG/KG', 18, 'MILIGRAMO POR KILOGRAMO', 1000, 2),
(22, 'G/L', 19, 'GRAMO POR LITRO', 1000, 2),
(23, 'MG/ML', 20, 'MILIGRAMO POR MILILITRO', 1000, 2),
(24, 'MCG/ML', 21, 'MICROGRAMO POR MILILITRO', 1000, 2),
(25, 'G/MOL', 22, 'GRAMO POR MOL', 1000, 2),
(26, '%', 23, 'PORCENTAJE', 1000, 2),
(27, 'PPM', 24, 'PARTES POR MILLÓN', 1000, 2),
(28, 'PPT', 25, 'PARTES POR TRILLÓN', 1000, 2),
(29, 'GB', 26, 'GOTA', 1000, 2),
(30, 'GL', 27, 'GOTAS', 1000, 2),
(31, 'CF', 28, 'CÁPSULA', 1000, 2),
(32, 'CP', 29, 'COMPRIMIDO', 1000, 2),
(33, 'GR', 30, 'GRÁNULO', 1000, 2),
(34, 'OV', 31, 'ÓVULO', 1000, 2),
(35, 'SUP', 32, 'SUPOSITORIO', 1000, 2),
(36, 'AP', 33, 'APLICACIÓN', 1000, 2),
(37, 'DS', 34, 'DOSIS', 1000, 2),
(38, 'INH', 35, 'INHALACIÓN', 1000, 2),
(39, 'PUFF', 36, 'PUFF (INHALACIÓN)', 1000, 2),
(40, 'PAR', 37, 'PARCHE', 1000, 2),
(41, 'ML/KG', 38, 'MILILITRO POR KILOGRAMO', 1000, 2),
(42, 'U/KG', 39, 'UNIDAD POR KILOGRAMO', 1000, 2);

SELECT setval('unidades_unidad_id_seq', COALESCE((SELECT MAX(unidad_id) FROM unidades), 0), (SELECT COUNT(*) > 0 FROM unidades));

-- ================================================================================================

DELETE FROM almacenes;
ALTER SEQUENCE almacenes_almacen_id_seq RESTART WITH 1;

INSERT INTO almacenes (almacen_id,sucursal_id,almacen,codigo,tipo_almacen_id,tipo_operacion_almacen_id,descripcion,estado_id,usuario_id_registro) VALUES
	 (1,1,'NINGUNO','NIN',1700,4051,'ALMACEN COMODIN',1000,1),
	 (2,2,'ALMACEN PRINCIPAL','ALM-FSM-01',1700,4051,'ALMACEN GENERAL DE MEDICAMENTOS - VENTA DIRECTA',1000,2),
	 (3,2,'REFRIGERADOS','REF-FSM-01',1701,4051,'ALMACEN DE PRODUCTOS REFRIGERADOS (2°C A 8°C)',1000,2),
	 (4,2,'CONGELADOS','CON-FSM-01',1702,4051,'ALMACEN DE PRODUCTOS CONGELADOS (-18°C O MENOR)',1000,2),
	 (5,2,'JUGUETES Y RECREATIVOS','JUG-FSM-01',1700,4051,'ALMACEN DE JUGUETES Y ARTICULOS RECREATIVOS',1000,2),
	 (6,2,'EQUIPOS ELECTRONICOS','ELE-FSM-01',1700,4051,'ALMACEN DE EQUIPOS ELECTRONICOS Y DISPOSITIVOS',1000,2),
	 (7,2,'MATERIAL DE ESCRITORIO','MAT-FSM-01',1700,4051,'ALMACEN DE MATERIAL DE ESCRITORIO Y SUMINISTROS',1000,2),
	 (8,2,'RECEPCION','REC-FSM-01',1709,4050,'ZONA DE RECEPCION DE MERCANCIAS',1000,2),
	 (9,2,'DESPACHO','DES-FSM-01',1711,4050,'ZONA DE PREPARACION Y DESPACHO DE PEDIDOS',1000,2),
	 (10,3,'ALMACEN PRINCIPAL','ALM-FSZ-01',1700,4051,'ALMACEN GENERAL DE MEDICAMENTOS - ZONA SUR',1000,2),
	 (11,3,'REFRIGERADOS','REF-FSZ-01',1701,4051,'ALMACEN DE PRODUCTOS REFRIGERADOS ZONA SUR',1000,2),
	 (12,3,'JUGUETES Y RECREATIVOS','JUG-FSZ-01',1700,4051,'ALMACEN DE JUGUETES Y ARTICULOS RECREATIVOS ZONA SUR',1000,2);

SELECT setval('almacenes_almacen_id_seq', COALESCE((SELECT MAX(almacen_id) FROM almacenes), 0), (SELECT COUNT(*) > 0 FROM almacenes));

-- ================================================================================================

DELETE FROM ubicaciones;
ALTER SEQUENCE ubicaciones_ubicacion_id_seq RESTART WITH 1;

INSERT INTO ubicaciones (ubicacion_id, almacen_id, codigo, jerarquia, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', '{"tipo":"COMODIN","valor":"NINGUNO","camino":"COMODIN NINGUNO"}'::jsonb, 'UBICACION COMODIN', 1000, 1),
(2, 2, 'EST-A-1', '{"tipo":"ESTANTERIA","valor":"A","nivel":"1","camino":"ESTANTERIA A > NIVEL 1"}'::jsonb, 'Estantería A, Nivel 1', 1000, 2),
(3, 2, 'EST-A-2', '{"tipo":"ESTANTERIA","valor":"A","nivel":"2","camino":"ESTANTERIA A > NIVEL 2"}'::jsonb, 'Estantería A, Nivel 2', 1000, 2),
(4, 2, 'EST-A-3', '{"tipo":"ESTANTERIA","valor":"A","nivel":"3","camino":"ESTANTERIA A > NIVEL 3"}'::jsonb, 'Estantería A, Nivel 3', 1000, 2),
(5, 2, 'EST-B-1', '{"tipo":"ESTANTERIA","valor":"B","nivel":"1","camino":"ESTANTERIA B > NIVEL 1"}'::jsonb, 'Estantería B, Nivel 1', 1000, 2),
(6, 2, 'EST-B-2', '{"tipo":"ESTANTERIA","valor":"B","nivel":"2","camino":"ESTANTERIA B > NIVEL 2"}'::jsonb, 'Estantería B, Nivel 2', 1000, 2),
(7, 2, 'EST-B-3', '{"tipo":"ESTANTERIA","valor":"B","nivel":"3","camino":"ESTANTERIA B > NIVEL 3"}'::jsonb, 'Estantería B, Nivel 3', 1000, 2),
(8, 2, 'EST-C-1', '{"tipo":"ESTANTERIA","valor":"C","nivel":"1","camino":"ESTANTERIA C > NIVEL 1"}'::jsonb, 'Estantería C, Nivel 1', 1000, 2),
(9, 2, 'EST-C-2', '{"tipo":"ESTANTERIA","valor":"C","nivel":"2","camino":"ESTANTERIA C > NIVEL 2"}'::jsonb, 'Estantería C, Nivel 2', 1000, 2),
(10, 2, 'EST-C-3', '{"tipo":"ESTANTERIA","valor":"C","nivel":"3","camino":"ESTANTERIA C > NIVEL 3"}'::jsonb, 'Estantería C, Nivel 3', 1000, 2),
(11, 3, 'REF-01-1', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"1","camino":"REFRIGERADOR REF-01 > BANDEJA 1"}'::jsonb, 'Refrigerador REF-01, Bandeja 1', 1000, 2),
(12, 3, 'REF-01-2', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"2","camino":"REFRIGERADOR REF-01 > BANDEJA 2"}'::jsonb, 'Refrigerador REF-01, Bandeja 2', 1000, 2),
(13, 3, 'REF-01-3', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"3","camino":"REFRIGERADOR REF-01 > BANDEJA 3"}'::jsonb, 'Refrigerador REF-01, Bandeja 3', 1000, 2),
(14, 3, 'REF-01-4', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"4","camino":"REFRIGERADOR REF-01 > BANDEJA 4"}'::jsonb, 'Refrigerador REF-01, Bandeja 4', 1000, 2),
(15, 3, 'REF-02-1', '{"tipo":"REFRIGERADOR","valor":"REF-02","nivel":"1","camino":"REFRIGERADOR REF-02 > BANDEJA 1"}'::jsonb, 'Refrigerador REF-02, Bandeja 1', 1000, 2),
(16, 3, 'REF-02-2', '{"tipo":"REFRIGERADOR","valor":"REF-02","nivel":"2","camino":"REFRIGERADOR REF-02 > BANDEJA 2"}'::jsonb, 'Refrigerador REF-02, Bandeja 2', 1000, 2),
(17, 4, 'CON-01-1', '{"tipo":"CONGELADOR","valor":"CON-01","nivel":"1","camino":"CONGELADOR CON-01 > BANDEJA 1"}'::jsonb, 'Congelador CON-01, Bandeja 1', 1000, 2),
(18, 4, 'CON-01-2', '{"tipo":"CONGELADOR","valor":"CON-01","nivel":"2","camino":"CONGELADOR CON-01 > BANDEJA 2"}'::jsonb, 'Congelador CON-01, Bandeja 2', 1000, 2),
(19, 4, 'CON-02-1', '{"tipo":"CONGELADOR","valor":"CON-02","nivel":"1","camino":"CONGELADOR CON-02 > BANDEJA 1"}'::jsonb, 'Congelador CON-02, Bandeja 1', 1000, 2),
(20, 4, 'CON-02-2', '{"tipo":"CONGELADOR","valor":"CON-02","nivel":"2","camino":"CONGELADOR CON-02 > BANDEJA 2"}'::jsonb, 'Congelador CON-02, Bandeja 2', 1000, 2),
(21, 5, 'JUG-A', '{"tipo":"ANAQUEL","valor":"A","camino":"ANAQUEL A"}'::jsonb, 'Anaquél de Juguetes - Sección A', 1000, 2),
(22, 5, 'JUG-B', '{"tipo":"ANAQUEL","valor":"B","camino":"ANAQUEL B"}'::jsonb, 'Anaquél de Juguetes - Sección B', 1000, 2),
(23, 5, 'JUG-C', '{"tipo":"ANAQUEL","valor":"C","camino":"ANAQUEL C"}'::jsonb, 'Anaquél de Juguetes - Sección C', 1000, 2),
(24, 6, 'EXP-01', '{"tipo":"EXHIBIDOR","valor":"EXP-01","camino":"EXHIBIDOR EXP-01"}'::jsonb, 'Exhibidor de Electrónicos 01', 1000, 2),
(25, 6, 'EXP-02', '{"tipo":"EXHIBIDOR","valor":"EXP-02","camino":"EXHIBIDOR EXP-02"}'::jsonb, 'Exhibidor de Electrónicos 02', 1000, 2),
(26, 7, 'EST-D-1', '{"tipo":"ESTANTERIA","valor":"D","nivel":"1","camino":"ESTANTERIA D > NIVEL 1"}'::jsonb, 'Estantería D, Nivel 1', 1000, 2),
(27, 7, 'EST-D-2', '{"tipo":"ESTANTERIA","valor":"D","nivel":"2","camino":"ESTANTERIA D > NIVEL 2"}'::jsonb, 'Estantería D, Nivel 2', 1000, 2),
(28, 8, 'ZON-RECEPCION', '{"tipo":"ZONA","valor":"RECEPCION","camino":"ZONA RECEPCION"}'::jsonb, 'Zona de Recepción de Mercancías', 1000, 2),
(29, 9, 'ZON-DESPACHO', '{"tipo":"ZONA","valor":"DESPACHO","camino":"ZONA DESPACHO"}'::jsonb, 'Zona de Preparación y Despacho', 1000, 2),
(30, 10, 'EST-D-1', '{"tipo":"ESTANTERIA","valor":"D","nivel":"1","camino":"ESTANTERIA D > NIVEL 1"}'::jsonb, 'Estantería D, Nivel 1 - Zona Sur', 1000, 2),
(31, 10, 'EST-D-2', '{"tipo":"ESTANTERIA","valor":"D","nivel":"2","camino":"ESTANTERIA D > NIVEL 2"}'::jsonb, 'Estantería D, Nivel 2 - Zona Sur', 1000, 2),
(32, 10, 'EST-D-3', '{"tipo":"ESTANTERIA","valor":"D","nivel":"3","camino":"ESTANTERIA D > NIVEL 3"}'::jsonb, 'Estantería D, Nivel 3 - Zona Sur', 1000, 2),
(33, 11, 'REF-Z01-1', '{"tipo":"REFRIGERADOR","valor":"REF-Z01","nivel":"1","camino":"REFRIGERADOR REF-Z01 > BANDEJA 1"}'::jsonb, 'Refrigerador Zona Sur, Bandeja 1', 1000, 2),
(34, 11, 'REF-Z01-2', '{"tipo":"REFRIGERADOR","valor":"REF-Z01","nivel":"2","camino":"REFRIGERADOR REF-Z01 > BANDEJA 2"}'::jsonb, 'Refrigerador Zona Sur, Bandeja 2', 1000, 2),
(35, 12, 'JUG-Z-A', '{"tipo":"ANAQUEL","valor":"Z-A","camino":"ANAQUEL Z-A"}'::jsonb, 'Anaquél de Juguetes - Zona Sur A', 1000, 2),
(36, 12, 'JUG-Z-B', '{"tipo":"ANAQUEL","valor":"Z-B","camino":"ANAQUEL Z-B"}'::jsonb, 'Anaquél de Juguetes - Zona Sur B', 1000, 2);

SELECT setval('ubicaciones_ubicacion_id_seq', COALESCE((SELECT MAX(ubicacion_id) FROM ubicaciones), 0), (SELECT COUNT(*) > 0 FROM ubicaciones));

-- ================================================================================================

DELETE FROM almacenes_puntos_venta;
ALTER SEQUENCE almacenes_puntos_venta_almacen_punto_venta_id_seq RESTART WITH 1;

INSERT INTO almacenes_puntos_venta (almacen_punto_venta_id, sucursal_id, almacen_id, punto_venta_id, prioridad, es_principal, estado_id, usuario_id_registro) VALUES
(1,  1, 1,  1, 1, 1, 1000, 1),
(2,  2, 2,  2, 1, 1, 1000, 2),
(3,  2, 3,  2, 2, 0, 1000, 2),
(4,  2, 4,  2, 3, 0, 1000, 2),
(5,  2, 5,  2, 4, 0, 1000, 2),
(6,  2, 6,  2, 5, 0, 1000, 2),
(7,  2, 7,  2, 6, 0, 1000, 2),
(8,  2, 2,  3, 1, 1, 1000, 2),
(9,  2, 3,  3, 2, 0, 1000, 2),
(10, 2, 4,  3, 3, 0, 1000, 2),
(11, 2, 5,  3, 4, 0, 1000, 2),
(12, 2, 6,  3, 5, 0, 1000, 2),
(13, 2, 7,  3, 6, 0, 1000, 2),
(14, 3, 10, 4, 1, 1, 1000, 2),
(15, 3, 11, 4, 2, 0, 1000, 2),
(16, 3, 12, 4, 3, 0, 1000, 2);

SELECT setval('almacenes_puntos_venta_almacen_punto_venta_id_seq', COALESCE((SELECT MAX(almacen_punto_venta_id) FROM almacenes_puntos_venta), 0), (SELECT COUNT(*) > 0 FROM almacenes_puntos_venta));

-- ================================================================================================

DELETE FROM cargos;
ALTER SEQUENCE cargos_cargo_id_seq RESTART WITH 1;

INSERT INTO cargos (cargo_id, cargo, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NIN', 'CARGO COMODIN', 1000, 1),
(2, 'ADMINISTRADOR DEL SISTEMA', 'ADMIN', 'Gestión integral, configuración y control total de la plataforma.', 1000, 2),
(3, 'GERENTE GENERAL', 'GER_GEN', 'Dirección estratégica y toma de decisiones corporativas.', 1000, 2),
(4, 'ADMINISTRADOR DE SUCURSAL', 'ADMIN_SUC', 'Supervisión de inventarios, dispensación y control de almacenes.', 1000, 2),
(5, 'CONTADOR', 'CONT', 'Contabilidad.', 1000, 2),
(6, 'COMPRAS', 'COMP', 'Encargado de compras.', 1000, 2),
(7, 'VENTAS', 'VENT', 'Encargado de ventas.', 1000, 2),
(8, 'INVENTARIO', 'INV', 'Encargado del inventario.', 1000, 2),
(9, 'MENSAJERO', 'MENS', 'Encargado de mensajeria.', 1000, 2);

SELECT setval('cargos_cargo_id_seq', COALESCE((SELECT MAX(cargo_id) FROM cargos), 0), (SELECT COUNT(*) > 0 FROM cargos));

-- ================================================================================================

DELETE FROM trabajadores;
ALTER SEQUENCE trabajadores_trabajador_id_seq RESTART WITH 1;

INSERT INTO trabajadores (trabajador_id, sucursal_id, genero_id, estado_civil_id, nombres, paterno, materno, dni, telefono, email, fecha_nacimiento, fecha_contratacion, foto, qr, estado_id, usuario_id_registro) VALUES
(1,  1, 1200, 1250, 'NINGUNO', 'NINGUNO', NULL, '0000000', NULL, NULL, NULL, NULL, '1.jpg', '1.png', 1000, 1),
(2,  2, 1200, 1251, 'FRANZ', 'IBAÑEZ', NULL, '2630198', '60241524', 'franz.ibanez.c@gmail.com', '1980-06-24', '2026-01-01', '2.jpg', '2.png', 1000, 2),
(3,  2, 1200, 1250, 'PASCUAL', 'QUISPE', 'HUANCA', '4892014', '70541489', 'pascual.q.h@hotmail.com', '1982-01-27', '2026-01-01', '3.png', '3.png', 1000, 2),
(4,  2, 1201, 1301, 'GLADYS', 'ALANOCA', NULL, '3482910', '60241524', 'gladys.alanoca@gmail.com', '1980-06-24', '2026-01-01', '4.jpg', '4.png', 1000, 2),
(5,  2, 1201, 1300, 'SILVIA', 'QUISPE', NULL, '6105824', '65201478', 'silvia.quispe@outlook.com', '1976-04-01', '2026-01-01', '5.jpg', '5.png', 1000, 2),
(6,  2, 1200, 1250, 'JUAN PABLO', 'HIDALGO', 'HUANCA', '8342915', '71524311', 'jphidalgo.h@gmail.com', '1988-09-15', '2026-01-01', '6.png', '6.png', 1000, 2),
(7,  2, 1200, 1250, 'MARCELO', 'VARGAS', 'FLORES', '5920147', '72014589', 'marcelovargas.f@hotmail.com', '1985-11-03', '2026-01-01', '7.jpg', '7.png', 1000, 2),
(8,  2, 1201, 1301, 'BEATRIZ', 'MENDOZA', 'ROJAS', '12409581', '60112233', 'beatriz.mendoza.r@gmail.com', '1993-03-22', '2026-01-01', '8.png', '8.png', 1000, 2),
(9,  3, 1201, 1300, 'CARLA', 'LOPEZ', 'ESTRADA', '7301948', '60581422', 'carla.lopez.e@gmail.com', '1991-05-14', '2026-01-01', '9.jpg', '9.png', 1000, 2),
(10, 3, 1200, 1250, 'RODRIGO', 'APAZA', 'MAMANI', '4910283', '70611224', 'rodrigo.apaza@hotmail.com', '1989-12-08', '2026-01-01', '10.jpg', '10.png', 1000, 2),
(11, 3, 1200, 1251, 'HECTOR', 'CONDO', 'ALANOCA', '5432109', '71254896', 'hector.condo@gmail.com', '1984-07-19', '2026-01-01', '11.jpg', '11.png', 1000, 2),
(12, 3, 1201, 1300, 'PATRICIA', 'CHAVEZ', 'SOLIZ', '6198420', '65124578', 'patricia.chavez@outlook.com', '1995-10-02', '2026-01-01', '12.jpg', '12.png', 1000, 2),
(13, 3, 1200, 1250, 'DIEGO', 'PINTO', 'GUTIERREZ', '8412975', '73021456', 'gustavo.pinto@gmail.com', '1992-04-30', '2026-01-01', '13.jpg', '13.png', 1000, 2),
(14, 3, 1201, 1300, 'MONICA', 'SILES', 'ORELLANA', '9120843', '60145879', 'monica.siles@hotmail.com', '1990-02-15', '2026-01-01', '14.jpg', '14.png', 1000, 2),
(15, 2, 1201, 1301, 'VALERIA', 'RIVERA', 'CRUZ', '3490218', '71954823', 'valeria.rivera.c@gmail.com', '1987-11-25', '2026-01-01', '15.png', '15.png', 1000, 2),
(16, 3, 1200, 1250, 'ALEXANDER', 'QUISPE', 'CHOQUE', '7891234', '71589632', 'alexander.quispe@gmail.com', '2000-05-12', '2026-01-01', '16.jpg', '16.png', 1000, 2),
(17, 3, 1200, 1250, 'KEVIN', 'MAMANI', 'FLORES', '6547891', '72036541', 'kevin.mamani@hotmail.com', '2002-08-19', '2026-01-01', '17.jpg', '17.png', 1000, 2);

SELECT setval('trabajadores_trabajador_id_seq', COALESCE((SELECT MAX(trabajador_id) FROM trabajadores), 0), (SELECT COUNT(*) > 0 FROM trabajadores));

-- ================================================================================================

DELETE FROM trabajadores_cargos;
ALTER SEQUENCE trabajadores_cargos_trabajador_cargo_id_seq RESTART WITH 1;

INSERT INTO trabajadores_cargos (trabajador_cargo_id, trabajador_id, cargo_id, sueldo_base, tipo_moneda_id, es_activo, estado_id, 
usuario_id_registro) VALUES
(1, 1, 1, 8000.00, 2300, 1, 1000, 1),
(2, 3, 4, 6000.00, 2300, 1, 1000, 2),
(3, 4, 5, 5500.00, 2300, 1, 1000, 2),
(4, 5, 4, 6000.00, 2300, 1, 1000, 2),
(5, 6, 7, 3500.00, 2300, 1, 1000, 2),
(6, 7, 8, 4000.00, 2300, 1, 1000, 2),
(7, 8, 8, 4000.00, 2300, 1, 1000, 2),
(8, 9, 7, 3500.00, 2300, 1, 1000, 2),
(9, 10, 8, 4000.00, 2300, 1, 1000, 2),
(10, 11, 8, 4000.00, 2300, 1, 1000, 2),
(11, 12, 6, 4500.00, 2300, 1, 1000, 2),
(12, 13, 7, 3500.00, 2300, 1, 1000, 2),
(13, 14, 8, 4000.00, 2300, 1, 1000, 2),
(14, 15, 3, 15000.00, 2300, 1, 1000, 2),
(15, 16, 9, 3000.00, 2300, 1, 1000, 2),
(16, 17, 9, 3000.00, 2300, 1, 1000, 2),
(17, 2, 2, 7000.00, 2300, 1, 1000, 2);

SELECT setval('trabajadores_cargos_trabajador_cargo_id_seq', COALESCE((SELECT MAX(trabajador_cargo_id) FROM trabajadores_cargos), 0), (SELECT COUNT(*) > 0 FROM trabajadores_cargos));

-- ================================================================================================

DELETE FROM roles;
ALTER SEQUENCE roles_rol_id_seq RESTART WITH 1;

INSERT INTO roles (rol_id, es_admin, codigo, rol, descripcion, estado_id, usuario_id_registro) VALUES
(1, 0, 'NIN', 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO DEL SISTEMA', 1000, 1),
(2, 1, 'ADM', 'ADMINISTRADOR', 'Control total de la plataforma sirena acceso a todo, tiene todos los permisos', 1000, 2),
(3, 0, 'GER', 'GERENTE', 'Control y acceso a todos los modulos pero solo de lectura', 1000, 2),
(4, 0, 'SUC', 'ENCARGADO DE SUCURSAL', 'Responsable de la supervision, operaciones y arqueos de una sucursal especifica', 1000, 2),
(5, 0, 'COM', 'COMPRADOR', 'Responsable de la gestion de proveedores, ordenes de compra y adquisiciones', 1000, 2),
(6, 0, 'VEN', 'VENDEDOR', 'Responsable de la atencion a clientes, cotizaciones y registro de ventas', 1000, 2),
(7, 0, 'ALM', 'ALMACENERO', 'Responsable de la recepcion de mercaderia, control de stock, ingresos y salidas de almacen', 1000, 2),
(8, 0, 'CAJ', 'CAJERO', 'Responsable de la recepcion de pagos, facturacion y apertura/cierre de caja chica', 1000, 2);

INSERT INTO roles (rol_id, es_admin, codigo, rol, descripcion, estado_id, usuario_id_registro) VALUES
(9, 0, 'PRB', 'PRUEBA', 'Rol de prueba para validación de permisos sin privilegios de administrador', 1000, 1);

SELECT setval('roles_rol_id_seq', COALESCE((SELECT MAX(rol_id) FROM roles), 0), (SELECT COUNT(*) > 0 FROM roles));

-- ================================================================================================

DELETE FROM usuarios;
ALTER SEQUENCE usuarios_usuario_id_seq RESTART WITH 1;

INSERT INTO usuarios (usuario_id,trabajador_id,rol_id,login,contrasena,avatar,estado_id,usuario_id_registro) VALUES
(1,1,1,'SISTEMA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','1.png',1000,1),
(2,2,2,'ADMIN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','2.png',1000,2),
(3,3,4,'PASCUAL','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','3.png',1000,2),
(4,4,5,'GLADYS','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','4.png',1000,2),
(5,5,4,'SILVIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','5.png',1000,2),
(6,6,6,'JUAN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','6.png',1000,2),
(7,7,7,'MARCELO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','7.png',1000,2),
(8,8,8,'BEATRIZ','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','8.png',1000,2),
(9,9,6,'CARLA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','9.png',1000,2),
(10,10,8,'RODRIGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','10.png',1000,2),
(11,11,7,'HECTOR','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','11.png',1000,2),
(12,12,5,'PATRICIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','12.png',1000,2),
(13,13,6,'DIEGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','13.png',1000,2),
(14,14,7,'MONICA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','14.png',1000,2),
(15,15,3,'VALERIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','15.png',1000,2);

INSERT INTO usuarios (usuario_id, trabajador_id, rol_id, login, contrasena, avatar, estado_id, usuario_id_registro) VALUES
(16, 16, 9, 'PRUEBA', '$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq', '16.png', 1000, 1);

SELECT setval('usuarios_usuario_id_seq', COALESCE((SELECT MAX(usuario_id) FROM usuarios), 0), (SELECT COUNT(*) > 0 FROM usuarios));

-- ================================================================================================

DELETE FROM tablas;
ALTER SEQUENCE tablas_tabla_id_seq RESTART WITH 1;

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
(91, 'vias', 1000, 2),
(92, 'constantes', 1000, 2),
(93, 'roles_permisos_sucesos', 1000, 2),
(94, 'roles_permisos_tablas', 1000, 2),
(95, 'sucesos', 1000, 2);

SELECT setval('tablas_tabla_id_seq', COALESCE((SELECT MAX(tabla_id) FROM tablas), 0), (SELECT COUNT(*) > 0 FROM tablas));

/*
	-- No debe haber nada.
	SELECT tablename 
	FROM pg_tables 
	WHERE schemaname = 'public' 
	  AND tablename NOT IN (
		  SELECT nombre 
		  FROM tablas 
		  WHERE estado_id = 1000
	  )
	ORDER BY tablename ASC;
*/

-- ================================================================================================

DELETE FROM sucesos;

INSERT INTO sucesos (suceso_id, codigo, suceso, descripcion, tabla_id, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'Evento por defecto sin acción específica', 1, 1000, 1),
(1050, 'LOT', 'COMPRA', 'Registro de ingreso de mercadería por compra a proveedor. Afecta positivamente el stock y genera cuentas por pagar.', 2, 1000, 2),
(1051, 'VEN', 'VENTA', 'Registro de salida de mercadería por venta a cliente. Afecta negativamente el stock, genera facturación y movimiento de caja.', 2, 1000, 2),
(1052, 'PRO', 'PROFORMA', 'Cotización o presupuesto temporal que NO afecta stock ni finanzas. Solo documento informativo o estimación de precios.', 2, 1000, 2),
(1053, 'EGR', 'EGRESO_TRASPASO', 'Egreso de mercadería desde sucursal origen hacia destino. Disminuye stock en origen hasta confirmación en destino.', 2, 1000, 2),
(1054, 'ING', 'INGRESO_TRASPASO', 'Ingreso de mercadería a sucursal destino procedente de origen. Aumenta stock en destino al confirmar recepción.', 2, 1000, 2),
(1055, 'ANU', 'ANULACION', 'Cancelación de una transacción previa (compra o venta). Revierte automáticamente el stock afectado y deja registro inmutable para auditoría.', 2, 1000, 2),
(1056, 'AJI', 'AJUSTE_INGRESO', 'Incremento de stock por sobrante detectado en inventario físico. No genera transacción comercial.', 2, 1000, 2),
(1057, 'AJE', 'AJUSTE_EGRESO', 'Decremento de stock por faltante detectado en inventario físico. No genera transacción comercial.', 2, 1000, 2),
(1058, 'SOL', 'SOLICITUD_COMPRA', 'Pedido administrativo pendiente de aprobación. No afecta stock ni finanzas hasta su conversión a COMPRA (1050).', 2, 1000, 2),
(1059, 'VRE', 'VENTA_RESERVA', 'Proforma con reserva temporal de stock por tiempo limitado. Afecta negativamente el stock (lo aparta) y puede convertirse en VENTA (1051). Requiere validez_dias para definir plazo de reserva.', 2, 1000, 2),
(1060, 'DCLI', 'DEVOLUCION_CLIENTE', 'Devolución de mercadería por parte del cliente. Afecta positivamente el stock y requiere nota de crédito/débito fiscal si aplica.', 2, 1000, 2),
(1061, 'DPRO', 'DEVOLUCION_PROVEEDOR', 'Devolución de mercadería defectuosa o próxima a vencer al proveedor. Disminuye el stock y ajusta cuentas por pagar.', 2, 1000, 2),
(1062, 'ROB', 'ROBO', 'Salida extraordinaria de inventario por sustracción o robo detectado. Disminuye el stock sin contrapartida comercial y genera alerta de auditoría.', 2, 1000, 2),
(1063, 'PCAD', 'PERDIDA_CADUCIDAD', 'Baja de stock por productos vencidos o caducados detectados en control de almacén. Afecta como pérdida operativa.', 2, 1000, 2),
(1064, 'MER', 'MERMA_ROTURA', 'Salida de stock por daño físico, rotura o deterioro de medicamentos. No genera transacción comercial.', 2, 1000, 2),
(1065, 'IFSO', 'INVENTARIO_FISICO_SOBRANTE', 'Ajuste positivo por conteo físico de inventario (diferencia a favor respecto al sistema).', 2, 1000, 2),
(1066, 'IFFAL', 'INVENTARIO_FISICO_FALTANTE', 'Ajuste negativo por conteo físico de inventario (diferencia en contra o merma no identificada).', 2, 1000, 2),
(1067, 'CENV', 'CONVERSION_UNIDADES', 'Salida de productos en empaque mayor (cajas/blísteres) y reingreso automático como unidades sueltas por fraccionamiento.', 2, 1000, 2),
(1068, 'RCUA', 'RETIRO_CUARENTENA', 'Salida temporal o definitiva de stock retenido por alerta sanitaria o control de calidad. Bloquea o saca la mercadería de la disponibilidad comercial.', 2, 1000, 2),
(1069, 'DON', 'INGRESO_DONACION', 'Ingreso de mercadería por donación o recepción sin costo. Afecta positivamente el stock sin generar obligación de pago.', 2, 1000, 2),
(1070, 'LRES', 'LIBERACION_RESERVA', 'Liberación de stock retenido por expiración de tiempo o anulación de reserva. Reintegra el stock disponible.', 2, 1000, 2);

-- ================================================================================================

DELETE FROM roles_permisos_tablas;
ALTER SEQUENCE roles_permisos_tablas_rol_permiso_tabla_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - TODOS LOS PERMISOS EN 0
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 1, t.tabla_id, 1, 0, 0, 0, 0, 0, 0, 1000, 1 
FROM tablas t 
WHERE t.estado_id = 1000
AND t.tabla_id = 1;

-- ROL: ADMINISTRADOR (rol_id = 2) - PERMISO A TODO
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    2,
    t.tabla_id,
    1, 1, 1, 1, 1, 1, 1,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
    AND t.tabla_id > 1;
	
-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    3,
    t.tabla_id,
    1, 0, 0, 0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.tabla_id > 1;

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
AND t.tabla_id > 1;

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
AND t.tabla_id > 1
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
AND t.tabla_id > 1
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
AND t.tabla_id > 1
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
AND t.tabla_id > 1
AND t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'control_facturas', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle', 'bancos', 'listas_precios', 'precios_productos');

-- Insertar permisos de lectura (leer = 1) para las tablas 'sucesos', 'tablas' y 'constantes'
-- para todos los roles que no tengan ya un registro ACTIVO con esa combinación (rol_id, tabla_id)
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    r.rol_id,
    t.tabla_id,
    1, 0, 0, 0, 0, 0, 0,
    1000, 2
FROM roles r
CROSS JOIN tablas t
WHERE t.nombre IN ('sucesos', 'tablas', 'constantes')
	AND t.estado_id = 1000
	AND r.estado_id = 1000
	AND NOT EXISTS (
		SELECT 1 
		FROM roles_permisos_tablas rpt
		WHERE rpt.rol_id = r.rol_id 
			AND rpt.tabla_id = t.tabla_id
			AND rpt.estado_id = 1000
	);
	
SELECT setval('roles_permisos_tablas_rol_permiso_tabla_id_seq', COALESCE((SELECT MAX(rol_permiso_tabla_id) FROM roles_permisos_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_tablas));

-- ROL: PRUEBA (rol_id = 9) - MISMOS PERMISOS QUE ADMIN
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT
    9,
    t.tabla_id,
    1, 1, 1, 1, 1, 1, 1,
    1000, 1
FROM tablas t
WHERE t.estado_id = 1000
    AND t.tabla_id > 1;

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

-- ROL: PRUEBA (rol_id = 9) - TODOS LOS SUCESOS PERMITIDOS (igual que ADMIN)
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 1
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 9
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

SELECT setval('roles_permisos_sucesos_rol_permiso_suceso_id_seq', COALESCE((SELECT MAX(rol_permiso_suceso_id) FROM roles_permisos_sucesos), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_sucesos));

-- ================================================================================================

DELETE FROM menus;
ALTER SEQUENCE menus_menu_id_seq RESTART WITH 1;

INSERT INTO menus (menu_id,menu_padre_id,titulo,icono,url,orden,estado_id,usuario_id_registro) VALUES
	 (1,NULL,'NINGUNO',NULL,NULL,0,1000,1),
	 (2,NULL,'CONFIGURACIÓN Y SISTEMA','pi pi-cog',NULL,1,1000,2),
	 (3,2,'DATOS DE LA EMPRESA','pi pi-building','/configuracion/empresa',1,1000,2),
	 (4,2,'GESTIÓN DE NITS Y AUTORIZACIONES','pi pi-id-card','/configuracion/nits',2,1000,2),
	 (5,2,'CUENTAS BANCARIAS','pi pi-credit-card','/configuracion/cuentas-bancarias',3,1000,2),
	 (6,2,'BANCOS','pi pi-building-columns','/configuracion/bancos',4,1000,2),
	 (7,2,'SUCURSALES','pi pi-map-marker','/configuracion/sucursales',5,1000,2),
	 (8,2,'PUNTOS DE VENTA','pi pi-desktop','/configuracion/puntos-venta',6,1000,2),
	 (9,2,'CONTROL DE USUARIOS','pi pi-users','/configuracion/usuarios',7,1000,2),
	 (10,2,'ROLES Y PERMISOS','pi pi-key','/configuracion/roles',8,1000,2),
	 (11,2,'ROLES - PERMISOS TABLAS','pi pi-table','/configuracion/roles-permisos-tablas',9,1000,2),
	 (12,2,'ROLES - PERMISOS SUCESOS','pi pi-list','/configuracion/roles-permisos-sucesos',10,1000,2),
	 (13,2,'ROLES - MENÚS','pi pi-sitemap','/configuracion/roles-menus',11,1000,2),
	 (14,2,'GESTIÓN DE MENÚS','pi pi-sitemap','/configuracion/menus',12,1000,2),
	 (15,2,'TABLAS DEL SISTEMA','pi pi-database','/configuracion/tablas',13,1000,2),
	 (16,2,'SUCESOS DEL SISTEMA','pi pi-bolt','/configuracion/sucesos',14,1000,2),
	 (17,2,'PARÁMETROS GLOBALES','pi pi-sliders-h','/configuracion/parametros',15,1000,2),
	 (18,2,'TASAS DE CAMBIO','pi pi-dollar','/configuracion/tipos-cambio',16,1000,2),
	 (19,2,'TAREAS PROGRAMADAS','pi pi-calendar-clock','/configuracion/tareas',17,1000,2),
	 (20,2,'LOGS DE EJECUCIÓN','pi pi-file-code','/configuracion/logs',18,1000,2),
	 (21,2,'GESTIÓN CUIS','pi pi-key','/configuracion/cuis',19,1000,2),
	 (22,2,'GESTIÓN CUFD','pi pi-key','/configuracion/cufd',20,1000,2),
	 (23,2,'CONSULTA CUIS / CUFD','pi pi-key','/configuracion/credenciales-sin',21,1000,2),
	 (24,2,'INSTITUCIONES DE SALUD','pi pi-building','/configuracion/instituciones',22,1000,2),
	 (25,2,'ESPECIALIDADES MÉDICAS','pi pi-list','/configuracion/especialidades',23,1000,2),
	 (26,2,'MÉDICOS Y PROFESIONALES','pi pi-user-md','/configuracion/medicos',24,1000,2),
	 (27,NULL,'GESTIÓN DE PRODUCTOS','pi pi-box',NULL,2,1000,2),
	 (28,27,'CATÁLOGO DE PRODUCTOS','pi pi-shopping-bag','/productos/catalogo',1,1000,2),
	 (29,27,'CATEGORÍAS','pi pi-tags','/productos/categorias',2,1000,2),
	 (30,27,'LABORATORIOS','pi pi-percentage','/productos/laboratorios',3,1000,2),
	 (31,27,'PRINCIPIOS ACTIVOS','pi pi-info-circle','/productos/principios-activos',4,1000,2),
	 (32,27,'FORMAS FARMACÉUTICAS','pi pi-tablet','/productos/formas',5,1000,2),
	 (33,27,'PRESENTACIONES COMERCIALES','pi pi-clone','/productos/presentaciones',6,1000,2),
	 (34,27,'CONCENTRACIONES','pi pi-filter','/productos/concentraciones',7,1000,2),
	 (35,27,'REGISTROS SANITARIOS','pi pi-file','/productos/registros-sanitarios',8,1000,2),
	 (36,27,'PRODUCTOS CONTROLADOS','pi pi-exclamation-circle','/productos/controlados',9,1000,2),
	 (37,27,'VÍAS DE ADMINISTRACIÓN','pi pi-sitemap','/productos/vias',10,1000,2),
	 (38,27,'RANGOS DE EDAD','pi pi-users','/productos/rangos-edad',11,1000,2),
	 (39,27,'MARCAS','pi pi-tag','/productos/marcas',12,1000,2),
	 (40,27,'UNIDADES DE MEDIDA','pi pi-calculator','/productos/unidades',13,1000,2),
	 (41,27,'CONVERSIONES DE UNIDAD','pi pi-refresh','/productos/conversiones',14,1000,2),
	 (42,27,'EQUIVALENTES','pi pi-exchange','/productos/equivalentes',15,1000,2),
	 (43,27,'PROMOCIONES Y OFERTAS','pi pi-percentage','/productos/promociones',16,1000,2),
	 (44,27,'PRODUCTOS - VÍAS','pi pi-link','/productos/productos-vias',17,1000,2),
	 (45,27,'PRODUCTOS - PRINCIPIOS','pi pi-link','/productos/productos-principios',18,1000,2),
	 (46,27,'PRODUCTOS - RANGOS EDAD','pi pi-link','/productos/productos-rangos-edad',19,1000,2),
	 (47,27,'PROMOCIONES - PRODUCTOS','pi pi-link','/productos/promociones-productos',20,1000,2),
	 (48,NULL,'INVENTARIOS Y ALMACENES','pi pi-home',NULL,3,1000,2),
	 (49,48,'ALMACENES FÍSICOS','pi pi-map','/inventario/almacenes',1,1000,2),
	 (50,48,'UBICACIONES INTERNAS','pi pi-compass','/inventario/ubicaciones',2,1000,2),
	 (51,48,'ALMACENES - PUNTOS VENTA','pi pi-link','/inventario/almacenes-puntos',3,1000,2),
	 (52,48,'MOVIMIENTOS DE KARDEX','pi pi-list','/inventario/kardex',4,1000,2),
	 (53,48,'DETALLE DE KARDEX','pi pi-list','/inventario/kardex-detalle',5,1000,2),
	 (54,48,'DETALLE DE KARDEX POR PRODUCTO','pi pi-list','/inventario/kardex-productos',6,1000,2),
	 (55,48,'CONTROL DE LOTES','pi pi-barcode','/inventario/lotes',7,1000,2),
	 (56,48,'BAJA DE LOTES VENCIDOS','pi pi-calendar-times','/inventario/lotes-vencidos',8,1000,2),
	 (57,48,'TRASPASOS INTER-SUCURSALES','pi pi-arrow-h','/inventario/traspasos',9,1000,2),
	 (58,48,'DISTRIBUCIÓN EN ESTANTERÍAS','pi pi-server','/inventario/productos-ubicaciones',10,1000,2),
	 (59,48,'MOVIMIENTOS DE UBICACIÓN','pi pi-arrows-alt','/inventario/movimientos-ubicacion',11,1000,2),
	 (60,48,'HISTORIAL DE UBICACIONES','pi pi-history','/inventario/ubicaciones-historial',12,1000,2),
	 (61,48,'INVENTARIOS FÍSICOS','pi pi-clipboard','/inventario/inventarios-fisicos',13,1000,2),
	 (62,48,'DETALLE DE INVENTARIO FÍSICO','pi pi-list','/inventario/inventarios-fisicos-detalle',14,1000,2),
	 (63,NULL,'OPERACIONES DE KARDEX','pi pi-list',NULL,4,1000,2),
	 (64,63,'REGISTRAR COMPRA','pi pi-cart-plus','/inventario/kardex/compra',1,1000,2),
	 (65,63,'INGRESO POR TRASPASO','pi pi-arrow-down','/inventario/kardex/ingreso-traspaso',2,1000,2),
	 (66,63,'AJUSTE POR SOBRANTE','pi pi-plus','/inventario/kardex/ajuste-ingreso',3,1000,2),
	 (67,63,'INGRESO POR DONACIÓN','pi pi-gift','/inventario/kardex/donacion',4,1000,2),
	 (68,63,'REGISTRAR VENTA','pi pi-shopping-cart','/inventario/kardex/venta',5,1000,2),
	 (69,63,'EGRESO POR TRASPASO','pi pi-arrow-up','/inventario/kardex/egreso-traspaso',6,1000,2),
	 (70,63,'AJUSTE POR FALTANTE','pi pi-minus','/inventario/kardex/ajuste-egreso',7,1000,2),
	 (71,63,'DEVOLUCIÓN A PROVEEDOR','pi pi-undo','/inventario/kardex/devolucion-proveedor',8,1000,2),
	 (72,63,'PROFORMA / COTIZACIÓN','pi pi-file-edit','/inventario/kardex/proforma',9,1000,2),
	 (73,63,'VENTA CON RESERVA','pi pi-bookmark','/inventario/kardex/venta-reserva',10,1000,2),
	 (74,63,'LIBERACIÓN DE RESERVA','pi pi-bookmark-fill','/inventario/kardex/liberacion-reserva',11,1000,2),
	 (75,63,'SOLICITUD DE COMPRA','pi pi-file-plus','/inventario/kardex/solicitud-compra',12,1000,2),
	 (76,63,'ANULACIÓN DE TRANSACCIÓN','pi pi-ban','/inventario/kardex/anulacion',13,1000,2),
	 (77,63,'DEVOLUCIÓN DE CLIENTE','pi pi-replay','/inventario/kardex/devolucion-cliente',14,1000,2),
	 (78,63,'ROBO / SUSTRACCIÓN','pi pi-exclamation-triangle','/inventario/kardex/robo',15,1000,2),
	 (79,63,'PÉRDIDA POR CADUCIDAD','pi pi-calendar-times','/inventario/kardex/caducidad',16,1000,2),
	 (80,63,'MERMA POR ROTURA','pi pi-times-circle','/inventario/kardex/merma',17,1000,2),
	 (81,63,'CONVERSIÓN DE UNIDADES','pi pi-refresh','/inventario/kardex/conversion',18,1000,2),
	 (82,63,'RETIRO DE CUARENTENA','pi pi-shield','/inventario/kardex/cuarentena',19,1000,2),
	 (83,63,'SOBRANTE EN INVENTARIO FÍSICO','pi pi-clipboard','/inventario/kardex/inventario-sobrante',20,1000,2),
	 (84,63,'FALTANTE EN INVENTARIO FÍSICO','pi pi-clipboard','/inventario/kardex/inventario-faltante',21,1000,2),
	 (85,NULL,'COMPRAS Y PROVEEDORES','pi pi-shopping-cart',NULL,5,1000,2),
	 (86,85,'REGISTRO DE PROVEEDORES','pi pi-truck','/compras/proveedores',1,1000,2),
	 (87,85,'PROVEEDORES - CONTACTOS','pi pi-user-plus','/compras/proveedores-contactos',2,1000,2),
	 (88,85,'PROVEEDORES - RATING','pi pi-star','/compras/proveedores-rating',3,1000,2),
	 (89,85,'ÓRDENES Y RECEPCIONES','pi pi-plus-circle','/compras/ordenes',4,1000,2),
	 (90,85,'TIPOS DE PLANES DE PAGO','pi pi-calendar-plus','/compras/tipos-planes-pago',5,1000,2),
	 (91,85,'PLANES DE PAGO Y CRÉDITOS','pi pi-calendar','/compras/planes-pago',6,1000,2),
	 (92,85,'PAGOS A PROVEEDORES','pi pi-money-bill','/compras/pagos-proveedores',7,1000,2),
	 (93,85,'COMPROBANTES DE PAGO','pi pi-receipt','/compras/comprobantes-pago',8,1000,2),
	 (94,NULL,'VENTAS Y FACTURACIÓN','pi pi-wallet',NULL,6,1000,2),
	 (95,94,'PUNTO DE VENTA (POS)','pi pi-desktop','/ventas/pos',1,1000,2),
	 (96,94,'REGISTRO DE CLIENTES','pi pi-user-plus','/ventas/clientes',2,1000,2),
	 (97,94,'DOSIFICACIÓN Y FACTURAS (SIN)','pi pi-file-excel','/ventas/control-facturas',3,1000,2),
	 (98,94,'ANULACIÓN DE FACTURAS','pi pi-ban','/ventas/anulacion-facturas',4,1000,2),
	 (99,94,'NOTAS DE CRÉDITO / DÉBITO','pi pi-file-edit','/ventas/notas-credito-debito',5,1000,2),
	 (100,94,'REIMPRESIÓN DE COMPROBANTES','pi pi-print','/ventas/reimpresion',6,1000,2),
	 (101,94,'HISTÓRICO DE DOCUMENTOS','pi pi-folder-open','/ventas/documentos-historicos',7,1000,2),
	 (102,94,'DOCUMENTOS HISTÓRICOS INMUTABLES','pi pi-database','/ventas/historicos',8,1000,2),
	 (103,94,'COMPROBANTES DIGITALES / QR','pi pi-qrcode','/ventas/comprobantes',9,1000,2),
	 (104,94,'RECETAS MÉDICAS','pi pi-file-edit','/ventas/recetas',10,1000,2),
	 (105,94,'COBRANZA Y PAGOS DE CLIENTES','pi pi-money-bill','/ventas/cobranza',11,1000,2),
	 (106,94,'PLANES DE PAGO DE CLIENTES','pi pi-calendar','/ventas/planes-pago-clientes',12,1000,2),
	 (107,NULL,'GESTIÓN DE CAJA','pi pi-percentage',NULL,7,1000,2),
	 (108,107,'APERTURA DE CAJA','pi pi-lock-open','/caja/apertura',1,1000,2),
	 (109,107,'CIERRE DE CAJA','pi pi-lock','/caja/cierre',2,1000,2),
	 (110,107,'MOVIMIENTOS DE CAJA (VARIOS)','pi pi-sort','/caja/movimientos',3,1000,2),
	 (111,107,'ARQUEOS DE CAJA','pi pi-calculator','/caja/arqueos',4,1000,2),
	 (112,107,'ARQUEO PARCIAL','pi pi-calculator','/caja/arqueo-parcial',5,1000,2),
	 (113,107,'DETALLE DE ARQUEO','pi pi-list','/caja/arqueos-detalle',6,1000,2),
	 (114,NULL,'COMERCIO ELECTRÓNICO Y DELIVERY','pi pi-globe',NULL,8,1000,2),
	 (115,114,'PEDIDOS ONLINE','pi pi-shopping-bag','/ecommerce/pedidos',1,1000,2),
	 (116,114,'CARRITOS DE COMPRA','pi pi-shopping-cart','/ecommerce/carritos',2,1000,2),
	 (117,NULL,'PRECIOS, COSTOS Y MÁRGENES','pi pi-tags',NULL,9,1000,2),
	 (118,117,'LISTAS DE PRECIOS','pi pi-list','/precios/listas',1,1000,2),
	 (119,117,'PRECIOS DE PRODUCTOS','pi pi-dollar','/precios/productos',2,1000,2),
	 (120,117,'COSTOS PROMEDIO','pi pi-chart-line','/precios/costos',3,1000,2),
	 (121,117,'POLÍTICAS DE PRECIOS','pi pi-sliders-h','/precios/politicas',4,1000,2),
	 (122,NULL,'RECURSOS HUMANOS','pi pi-id-card',NULL,10,1000,2),
	 (123,122,'GESTIÓN DE TRABAJADORES','pi pi-users','/rrhh/trabajadores',1,1000,2),
	 (124,122,'CARGOS','pi pi-briefcase','/rrhh/cargos',2,1000,2),
	 (125,122,'TRABAJADORES - CARGOS','pi pi-user-plus','/rrhh/trabajadores-cargos',3,1000,2),
	 (126,122,'CONTROL DE ASISTENCIAS','pi pi-clock','/rrhh/asistencias',4,1000,2),
	 (127,122,'CONTRATOS DE PERSONAL','pi pi-briefcase','/rrhh/contratos',5,1000,2),
	 (128,122,'PLANILLAS DE SUELDOS','pi pi-file-pdf','/rrhh/planillas',6,1000,2),
	 (129,122,'DETALLES DE PLANILLAS','pi pi-file','/rrhh/detalles-planillas',7,1000,2),
	 (130,NULL,'NÚCLEO ANALÍTICO Y PREDICCIONES','pi pi-android',NULL,11,1000,2),
	 (131,130,'DASHBOARD DE ANALÍTICA CONSOLIDADA','pi pi-chart-bar','/ia/analitica',1,1000,2),
	 (132,130,'ANALÍTICA POR PRODUCTO','pi pi-chart-pie','/ia/analitica-productos',2,1000,2),
	 (133,130,'MODELOS ML DISPONIBLES','pi pi-share-alt','/ia/modelos',3,1000,2),
	 (134,130,'HISTORIAL DE ENTRENAMIENTOS','pi pi-sync','/ia/entrenamientos',4,1000,2),
	 (135,130,'MÉTRICAS DE RENDIMIENTO','pi pi-chart-line','/ia/metricas',5,1000,2),
	 (136,130,'VARIABLES EXÓGENAS AMBIENTALES','pi pi-cloud','/ia/variables-exogenas',6,1000,2),
	 (137,130,'PATRONES DE CONSUMO ESTACIONAL','pi pi-sliders-v','/ia/patrones-consumo',7,1000,2),
	 (138,130,'CONFIGURACIÓN DE UMBRALES PREDICTIVOS','pi pi-cog','/ia/umbrales',8,1000,2),
	 (139,NULL,'NOTIFICACIONES Y ALERTAS','pi pi-bell',NULL,12,1000,2),
	 (140,139,'BANDEJA DE NOTIFICACIONES','pi pi-inbox','/alertas/notificaciones',1,1000,2),
	 (141,139,'ALERTAS OPERATIVAS Y CRÍTICAS','pi pi-exclamation-triangle','/alertas/criticas',2,1000,2),
	 (142,NULL,'REPORTES Y DIRECCIÓN GERENCIAL','pi pi-print',NULL,13,1000,2),
	 (143,142,'CONSOLIDADOR DE REPORTES','pi pi-copy','/reportes/dashboard-unico',1,1000,2),
	 (144,142,'REPORTES DE INVENTARIO Y STOCK','pi pi-chart-scatter','/reportes/inventario',2,1000,2),
	 (145,142,'KARDEX VALORIZADO','pi pi-chart-line','/reportes/kardex-valorizado',3,1000,2),
	 (146,142,'VENTAS POR PRODUCTO','pi pi-chart-bar','/reportes/ventas-producto',4,1000,2),
	 (147,142,'ROTACIÓN DE INVENTARIO','pi pi-refresh','/reportes/rotacion-inventario',5,1000,2),
	 (148,142,'MARGEN POR PRODUCTO','pi pi-percentage','/reportes/margen-producto',6,1000,2),
	 (149,142,'VENCIMIENTOS PRÓXIMOS','pi pi-calendar-clock','/reportes/vencimientos',7,1000,2),
	 (150,142,'CLIENTES FRECUENTES (RFM)','pi pi-users','/reportes/clientes-rfm',8,1000,2),
	 (151,142,'HISTORIAL DE COSTOS Y MÁRGENES','pi pi-chart-line','/gerencia/historial-costos',9,1000,2);

SELECT setval('menus_menu_id_seq', COALESCE((SELECT MAX(menu_id) FROM menus), 0), (SELECT COUNT(*) > 0 FROM menus));

-- ================================================================================================

DELETE FROM roles_menus;
ALTER SEQUENCE roles_menus_rol_menu_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - SOLO MENÚ COMODÍN
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1000, 1);

-- ROL: ADMINISTRADOR (rol_id = 2) - TODOS LOS MENÚS
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro)
SELECT 2, m.menu_id, 1000, 2
FROM menus m
WHERE m.estado_id = 1000
ORDER BY m.menu_id;

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA / CONSULTA
-- Menús raíz de navegación + todos los hijos de consulta/reportes/analítica
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro) VALUES
-- Raíz de configuración (solo para ver datos de empresa, sucursales, etc.)
(3, 2, 1000, 2),
(3, 3, 1000, 2),   -- DATOS DE LA EMPRESA
(3, 7, 1000, 2),   -- SUCURSALES
(3, 8, 1000, 2),   -- PUNTOS DE VENTA
(3, 9, 1000, 2),   -- CONTROL DE USUARIOS (solo lectura)
(3, 10, 1000, 2),  -- ROLES Y PERMISOS (solo lectura)
(3, 17, 1000, 2),  -- PARÁMETROS GLOBALES
(3, 18, 1000, 2),  -- TASAS DE CAMBIO
-- Raíz de productos
(3, 27, 1000, 2),  -- GESTIÓN DE PRODUCTOS
(3, 28, 1000, 2),  -- CATÁLOGO
(3, 29, 1000, 2),  -- CATEGORÍAS
(3, 30, 1000, 2),  -- LABORATORIOS
(3, 31, 1000, 2),  -- PRINCIPIOS ACTIVOS
(3, 32, 1000, 2),  -- FORMAS
(3, 33, 1000, 2),  -- PRESENTACIONES
(3, 34, 1000, 2),  -- CONCENTRACIONES
(3, 35, 1000, 2),  -- REGISTROS SANITARIOS
(3, 36, 1000, 2),  -- PRODUCTOS CONTROLADOS
(3, 39, 1000, 2),  -- MARCAS
(3, 40, 1000, 2),  -- UNIDADES
(3, 43, 1000, 2),  -- PROMOCIONES
-- Raíz de inventarios
(3, 48, 1000, 2),  -- INVENTARIOS Y ALMACENES
(3, 49, 1000, 2),  -- ALMACENES
(3, 50, 1000, 2),  -- UBICACIONES
(3, 52, 1000, 2),  -- KARDEX (solo lectura)
(3, 53, 1000, 2),  -- DETALLE KARDEX
(3, 54, 1000, 2),  -- DETALLE KARDEX PRODUCTO
(3, 55, 1000, 2),  -- LOTES
(3, 56, 1000, 2),  -- BAJA LOTES VENCIDOS
(3, 61, 1000, 2),  -- INVENTARIOS FÍSICOS
(3, 62, 1000, 2),  -- DETALLE INVENTARIO FÍSICO
-- Raíz de compras
(3, 85, 1000, 2),  -- COMPRAS Y PROVEEDORES
(3, 86, 1000, 2),  -- PROVEEDORES
(3, 87, 1000, 2),  -- PROVEEDORES CONTACTOS
(3, 88, 1000, 2),  -- PROVEEDORES RATING
(3, 89, 1000, 2),  -- ÓRDENES
(3, 90, 1000, 2),  -- TIPOS PLANES PAGO
(3, 91, 1000, 2),  -- PLANES DE PAGO
(3, 92, 1000, 2),  -- PAGOS A PROVEEDORES
(3, 93, 1000, 2),  -- COMPROBANTES DE PAGO
-- Raíz de ventas
(3, 94, 1000, 2),  -- VENTAS Y FACTURACIÓN
(3, 95, 1000, 2),  -- POS (solo consulta)
(3, 96, 1000, 2),  -- CLIENTES
(3, 97, 1000, 2),  -- CONTROL FACTURAS
(3, 101, 1000, 2), -- HISTÓRICO DOCUMENTOS
(3, 102, 1000, 2), -- DOCUMENTOS HISTÓRICOS
(3, 103, 1000, 2), -- COMPROBANTES QR
(3, 104, 1000, 2), -- RECETAS
(3, 105, 1000, 2), -- COBRANZA
(3, 106, 1000, 2), -- PLANES PAGO CLIENTES
-- Raíz de caja
(3, 107, 1000, 2), -- GESTIÓN DE CAJA
(3, 111, 1000, 2), -- ARQUEOS
(3, 113, 1000, 2), -- DETALLE ARQUEO
-- Raíz de e-commerce
(3, 114, 1000, 2), -- E-COMMERCE
(3, 115, 1000, 2), -- PEDIDOS ONLINE
(3, 116, 1000, 2), -- CARRITOS
-- Raíz de precios
(3, 117, 1000, 2), -- PRECIOS
(3, 118, 1000, 2), -- LISTAS
(3, 119, 1000, 2), -- PRECIOS PRODUCTOS
(3, 120, 1000, 2), -- COSTOS PROMEDIO
(3, 121, 1000, 2), -- POLÍTICAS PRECIOS
-- Raíz de RRHH (solo lectura)
(3, 122, 1000, 2), -- RECURSOS HUMANOS
(3, 123, 1000, 2), -- TRABAJADORES
(3, 124, 1000, 2), -- CARGOS
(3, 125, 1000, 2), -- TRABAJADORES-CARGOS
(3, 126, 1000, 2), -- ASISTENCIAS
(3, 127, 1000, 2), -- CONTRATOS
(3, 128, 1000, 2), -- PLANILLAS
(3, 129, 1000, 2), -- DETALLES PLANILLAS
-- Raíz analítica
(3, 130, 1000, 2), -- NÚCLEO ANALÍTICO
(3, 131, 1000, 2), -- DASHBOARD
(3, 132, 1000, 2), -- ANALÍTICA PRODUCTO
(3, 133, 1000, 2), -- MODELOS ML
(3, 134, 1000, 2), -- ENTRENAMIENTOS
(3, 135, 1000, 2), -- MÉTRICAS
(3, 136, 1000, 2), -- VARIABLES EXÓGENAS
(3, 137, 1000, 2), -- PATRONES CONSUMO
(3, 138, 1000, 2), -- UMBRALES
-- Raíz alertas
(3, 139, 1000, 2), -- NOTIFICACIONES
(3, 140, 1000, 2), -- BANDEJA
(3, 141, 1000, 2), -- ALERTAS CRÍTICAS
-- Raíz reportes
(3, 142, 1000, 2), -- REPORTES
(3, 143, 1000, 2), -- CONSOLIDADOR
(3, 144, 1000, 2), -- REPORTES INVENTARIO
(3, 145, 1000, 2), -- KARDEX VALORIZADO
(3, 146, 1000, 2), -- VENTAS POR PRODUCTO
(3, 147, 1000, 2), -- ROTACIÓN
(3, 148, 1000, 2), -- MARGEN
(3, 149, 1000, 2), -- VENCIMIENTOS
(3, 150, 1000, 2), -- RFM
(3, 151, 1000, 2); -- HISTORIAL COSTOS

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - OPERATIVO COMPLETO DE SUCURSAL
-- Todo excepto: configuración global del sistema, RRHH, y menús técnicos de permisos
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro)
SELECT 4, m.menu_id, 1000, 2
FROM menus m
WHERE m.estado_id = 1000
  AND m.menu_id NOT IN (
    -- Excluir configuración técnica del sistema
    2, 4, 5, 6, 10, 11, 12, 13, 14, 15, 16, 19, 20, 21, 22, 23, 24, 25, 26,
    -- Excluir RRHH completo
    122, 123, 124, 125, 126, 127, 128, 129,
    -- Excluir menú NINGUNO
    1
  )
ORDER BY m.menu_id;

-- ROL: COMPRADOR (rol_id = 5) - SOLO COMPRAS, PROVEEDORES Y KARDEX DE COMPRA
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro) VALUES
-- Raíz de compras
(5, 85, 1000, 2),  -- COMPRAS Y PROVEEDORES
(5, 86, 1000, 2),  -- PROVEEDORES
(5, 87, 1000, 2),  -- PROVEEDORES CONTACTOS
(5, 88, 1000, 2),  -- PROVEEDORES RATING
(5, 89, 1000, 2),  -- ÓRDENES Y RECEPCIONES
(5, 90, 1000, 2),  -- TIPOS PLANES PAGO
(5, 91, 1000, 2),  -- PLANES DE PAGO
(5, 92, 1000, 2),  -- PAGOS A PROVEEDORES
(5, 93, 1000, 2),  -- COMPROBANTES DE PAGO
-- Raíz de operaciones de kardex (solo compra y solicitud)
(5, 63, 1000, 2),  -- OPERACIONES DE KARDEX
(5, 64, 1000, 2),  -- REGISTRAR COMPRA
(5, 71, 1000, 2),  -- DEVOLUCIÓN A PROVEEDOR
(5, 75, 1000, 2),  -- SOLICITUD DE COMPRA
-- Raíz de productos (solo lectura para consultar)
(5, 27, 1000, 2),  -- GESTIÓN DE PRODUCTOS
(5, 28, 1000, 2),  -- CATÁLOGO
(5, 30, 1000, 2),  -- LABORATORIOS
(5, 39, 1000, 2),  -- MARCAS
-- Raíz de inventarios (solo consulta de kardex)
(5, 48, 1000, 2),  -- INVENTARIOS
(5, 52, 1000, 2),  -- KARDEX
(5, 55, 1000, 2),  -- LOTES
-- Parámetros globales (consulta)
(5, 17, 1000, 2),  -- PARÁMETROS GLOBALES
(5, 19, 1000, 2);  -- TAREAS PROGRAMADAS

-- ROL: VENDEDOR (rol_id = 6) - SOLO VENTAS, CLIENTES, POS, RECETAS, E-COMMERCE
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro) VALUES
-- Raíz de ventas
(6, 94, 1000, 2),  -- VENTAS Y FACTURACIÓN
(6, 95, 1000, 2),  -- PUNTO DE VENTA (POS)
(6, 96, 1000, 2),  -- REGISTRO DE CLIENTES
(6, 97, 1000, 2),  -- DOSIFICACIÓN Y FACTURAS (SIN)
(6, 100, 1000, 2), -- REIMPRESIÓN DE COMPROBANTES
(6, 101, 1000, 2), -- HISTÓRICO DE DOCUMENTOS
(6, 103, 1000, 2), -- COMPROBANTES DIGITALES / QR
(6, 104, 1000, 2), -- RECETAS MÉDICAS
(6, 105, 1000, 2), -- COBRANZA Y PAGOS DE CLIENTES
(6, 106, 1000, 2), -- PLANES DE PAGO DE CLIENTES
-- Raíz de operaciones de kardex (solo venta, proforma, reserva)
(6, 63, 1000, 2),  -- OPERACIONES DE KARDEX
(6, 68, 1000, 2),  -- REGISTRAR VENTA
(6, 72, 1000, 2),  -- PROFORMA / COTIZACIÓN
(6, 73, 1000, 2),  -- VENTA CON RESERVA
(6, 74, 1000, 2),  -- LIBERACIÓN DE RESERVA
(6, 77, 1000, 2),  -- DEVOLUCIÓN DE CLIENTE
-- Raíz de e-commerce
(6, 114, 1000, 2), -- E-COMMERCE Y DELIVERY
(6, 115, 1000, 2), -- PEDIDOS ONLINE
(6, 116, 1000, 2), -- CARRITOS DE COMPRA
-- Raíz de precios (consulta)
(6, 117, 1000, 2), -- PRECIOS, COSTOS Y MÁRGENES
(6, 118, 1000, 2), -- LISTAS DE PRECIOS
(6, 119, 1000, 2), -- PRECIOS DE PRODUCTOS
(6, 121, 1000, 2), -- POLÍTICAS DE PRECIOS
-- Raíz de productos (consulta)
(6, 27, 1000, 2),  -- GESTIÓN DE PRODUCTOS
(6, 28, 1000, 2),  -- CATÁLOGO
(6, 29, 1000, 2),  -- CATEGORÍAS
(6, 43, 1000, 2),  -- PROMOCIONES
-- Raíz de caja (solo movimientos de su sesión)
(6, 107, 1000, 2), -- GESTIÓN DE CAJA
(6, 110, 1000, 2); -- MOVIMIENTOS DE CAJA

-- ROL: ALMACENERO (rol_id = 7) - SOLO INVENTARIO, ALMACENES, KARDEX OPERATIVO, LOTES
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro) VALUES
-- Raíz de inventarios
(7, 48, 1000, 2),  -- INVENTARIOS Y ALMACENES
(7, 49, 1000, 2),  -- ALMACENES FÍSICOS
(7, 50, 1000, 2),  -- UBICACIONES INTERNAS
(7, 51, 1000, 2),  -- ALMACENES - PUNTOS VENTA
(7, 52, 1000, 2),  -- MOVIMIENTOS DE KARDEX
(7, 53, 1000, 2),  -- DETALLE DE KARDEX
(7, 54, 1000, 2),  -- DETALLE DE KARDEX POR PRODUCTO
(7, 55, 1000, 2),  -- CONTROL DE LOTES
(7, 56, 1000, 2),  -- BAJA DE LOTES VENCIDOS
(7, 57, 1000, 2),  -- TRASPASOS INTER-SUCURSALES
(7, 58, 1000, 2),  -- DISTRIBUCIÓN EN ESTANTERÍAS
(7, 59, 1000, 2),  -- MOVIMIENTOS DE UBICACIÓN
(7, 60, 1000, 2),  -- HISTORIAL DE UBICACIONES
(7, 61, 1000, 2),  -- INVENTARIOS FÍSICOS
(7, 62, 1000, 2),  -- DETALLE DE INVENTARIO FÍSICO
-- Raíz de operaciones de kardex (todo lo operativo de almacén)
(7, 63, 1000, 2),  -- OPERACIONES DE KARDEX
(7, 64, 1000, 2),  -- REGISTRAR COMPRA
(7, 65, 1000, 2),  -- INGRESO POR TRASPASO
(7, 66, 1000, 2),  -- AJUSTE POR SOBRANTE
(7, 67, 1000, 2),  -- INGRESO POR DONACIÓN
(7, 69, 1000, 2),  -- EGRESO POR TRASPASO
(7, 70, 1000, 2),  -- AJUSTE POR FALTANTE
(7, 71, 1000, 2),  -- DEVOLUCIÓN A PROVEEDOR
(7, 75, 1000, 2),  -- SOLICITUD DE COMPRA
(7, 76, 1000, 2),  -- ANULACIÓN DE TRANSACCIÓN
(7, 78, 1000, 2),  -- ROBO / SUSTRACCIÓN
(7, 79, 1000, 2),  -- PÉRDIDA POR CADUCIDAD
(7, 80, 1000, 2),  -- MERMA POR ROTURA
(7, 81, 1000, 2),  -- CONVERSIÓN DE UNIDADES
(7, 82, 1000, 2),  -- RETIRO DE CUARENTENA
(7, 83, 1000, 2),  -- SOBRANTE EN INVENTARIO FÍSICO
(7, 84, 1000, 2),  -- FALTANTE EN INVENTARIO FÍSICO
-- Raíz de productos (consulta)
(7, 27, 1000, 2),  -- GESTIÓN DE PRODUCTOS
(7, 28, 1000, 2),  -- CATÁLOGO
(7, 40, 1000, 2),  -- UNIDADES DE MEDIDA
(7, 41, 1000, 2),  -- CONVERSIONES DE UNIDAD
-- Raíz de analítica (consulta de umbrales y predicciones)
(7, 130, 1000, 2), -- NÚCLEO ANALÍTICO
(7, 132, 1000, 2), -- ANALÍTICA POR PRODUCTO
(7, 138, 1000, 2), -- UMBRALES PREDICTIVOS
-- Raíz de alertas
(7, 139, 1000, 2), -- NOTIFICACIONES
(7, 140, 1000, 2), -- BANDEJA
(7, 141, 1000, 2); -- ALERTAS CRÍTICAS

-- ROL: CAJERO (rol_id = 8) - SOLO CAJA, POS, CLIENTES, COMPROBANTES, ARQUEOS
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro) VALUES
-- Raíz de ventas
(8, 94, 1000, 2),  -- VENTAS Y FACTURACIÓN
(8, 95, 1000, 2),  -- PUNTO DE VENTA (POS)
(8, 96, 1000, 2),  -- REGISTRO DE CLIENTES
(8, 97, 1000, 2),  -- DOSIFICACIÓN Y FACTURAS (SIN)
(8, 100, 1000, 2), -- REIMPRESIÓN DE COMPROBANTES
(8, 103, 1000, 2), -- COMPROBANTES DIGITALES / QR
(8, 105, 1000, 2), -- COBRANZA Y PAGOS DE CLIENTES
(8, 106, 1000, 2), -- PLANES DE PAGO DE CLIENTES
-- Raíz de operaciones de kardex (solo venta)
(8, 63, 1000, 2),  -- OPERACIONES DE KARDEX
(8, 68, 1000, 2),  -- REGISTRAR VENTA
-- Raíz de caja
(8, 107, 1000, 2), -- GESTIÓN DE CAJA
(8, 108, 1000, 2), -- APERTURA DE CAJA
(8, 109, 1000, 2), -- CIERRE DE CAJA
(8, 110, 1000, 2), -- MOVIMIENTOS DE CAJA
(8, 111, 1000, 2), -- ARQUEOS DE CAJA
(8, 112, 1000, 2), -- ARQUEO PARCIAL
(8, 113, 1000, 2), -- DETALLE DE ARQUEO
-- Raíz de precios (consulta)
(8, 117, 1000, 2), -- PRECIOS
(8, 118, 1000, 2), -- LISTAS DE PRECIOS
(8, 119, 1000, 2), -- PRECIOS DE PRODUCTOS
-- Raíz de productos (consulta)
(8, 27, 1000, 2),  -- GESTIÓN DE PRODUCTOS
(8, 28, 1000, 2);  -- CATÁLOGO

-- ROL: PRUEBA (rol_id = 9) - TODOS LOS MENÚS (igual que ADMIN)
INSERT INTO roles_menus (rol_id, menu_id, estado_id, usuario_id_registro)
SELECT 9, m.menu_id, 1000, 1
FROM menus m
WHERE m.estado_id = 1000
ORDER BY m.menu_id;

SELECT setval('roles_menus_rol_menu_id_seq', COALESCE((SELECT MAX(rol_menu_id) FROM roles_menus), 0), (SELECT COUNT(*) > 0 FROM roles_menus));

-- ================================================================================================

DELETE FROM inventarios_fisicos;
ALTER SEQUENCE inventarios_fisicos_inventario_fisico_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos (inventario_fisico_id,almacen_id,ubicacion_id,fecha_conteo,fecha_inicio,fecha_fin,trabajador_responsable_id,trabajador_supervisor_id,estado_id,observaciones,usuario_id_registro) VALUES
	 (1,1,1,'2026-08-31','2026-08-31 11:27:15.050412-04',NULL,1,1,1000,'REGISTRO INICIAL COMODIN DE INVENTARIO FISICO',1),
	 (2,2,2,'2026-07-01','2026-07-01 08:00:00-04','2026-07-01 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA A - NIVEL 1',2),
	 (3,2,3,'2026-07-02','2026-07-02 08:00:00-04','2026-07-02 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA A - NIVEL 2',2),
	 (4,2,4,'2026-07-03','2026-07-03 08:00:00-04','2026-07-03 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA A - NIVEL 3',2),
	 (5,2,5,'2026-07-04','2026-07-04 08:00:00-04','2026-07-04 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA B - NIVEL 1',2),
	 (6,2,6,'2026-07-05','2026-07-05 08:00:00-04','2026-07-05 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA B - NIVEL 2',2),
	 (7,2,7,'2026-07-06','2026-07-06 08:00:00-04','2026-07-06 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA B - NIVEL 3',2),
	 (8,2,8,'2026-07-07','2026-07-07 08:00:00-04','2026-07-07 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA C - NIVEL 1',2),
	 (9,2,9,'2026-07-08','2026-07-08 08:00:00-04','2026-07-08 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA C - NIVEL 2',2),
	 (10,2,10,'2026-07-09','2026-07-09 08:00:00-04','2026-07-09 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA C - NIVEL 3',2),
	 (11,3,11,'2026-07-10','2026-07-10 08:00:00-04','2026-07-10 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 1',2),
	 (12,3,12,'2026-07-11','2026-07-11 08:00:00-04','2026-07-11 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 2',2),
	 (13,3,13,'2026-07-12','2026-07-12 08:00:00-04','2026-07-12 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 3',2),
	 (14,3,14,'2026-07-13','2026-07-13 08:00:00-04','2026-07-13 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 4',2),
	 (15,3,15,'2026-07-14','2026-07-14 08:00:00-04','2026-07-14 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 02 - BANDEJA 1',2),
	 (16,3,16,'2026-07-15','2026-07-15 08:00:00-04','2026-07-15 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 02 - BANDEJA 2',2),
	 (17,4,17,'2026-07-16','2026-07-16 08:00:00-04','2026-07-16 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 01 - BANDEJA 1',2),
	 (18,4,18,'2026-07-17','2026-07-17 08:00:00-04','2026-07-17 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 01 - BANDEJA 2',2),
	 (19,4,19,'2026-07-18','2026-07-18 08:00:00-04','2026-07-18 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 02 - BANDEJA 1',2),
	 (20,4,20,'2026-07-19','2026-07-19 08:00:00-04','2026-07-19 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 02 - BANDEJA 2',2);

SELECT setval('inventarios_fisicos_inventario_fisico_id_seq', COALESCE((SELECT MAX(inventario_fisico_id) FROM inventarios_fisicos), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos));

-- ================================================================================================

DELETE FROM clientes;
ALTER SEQUENCE clientes_cliente_id_seq RESTART WITH 1;

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_base_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(1, 1150, 'NINGUNO', NULL, NULL, '0', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 1);

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_base_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(2, 1151, 'DISTRIBUIDORA FARMA BOLIVIA S.A.', '123456789012', 'DISTRIBUIDORA FARMA BOLIVIA S.A.', '123456789012', NULL, 2204, 'AV. MONTENEGRO NRO. 450, EDIF. BUSINESS CENTER, PISO 3, LA PAZ', '22889977', 'ventas@distribuidorafarma.bo', 3, '4000009876', 1, 25000.00, 1000, 2),
(3, 1151, 'LABORATORIOS BOLIVIANOS S.A.', '987654321098', 'LABORATORIOS BOLIVIANOS S.A.', '987654321098', NULL, 2204, 'CALLE MURILLO NRO. 789, ZONA INDUSTRIAL, EL ALTO, LA PAZ', '22881144', 'administracion@labbol.com.bo', 4, '3000006543', 1, 50000.00, 1000, 2);

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_base_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(4, 1150, 'MARIA ELENA GUTIERREZ LOZA', NULL, NULL, '12345678', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(5, 1150, 'JUAN CARLOS MAMANI QUISPE', NULL, NULL, '87654321', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(6, 1150, 'ANA MARIA FLORES TORREZ', NULL, NULL, '23456789', '1A', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(7, 1150, 'LUIS ALBERTO CONDORI CHAMBI', NULL, NULL, '98765432', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(8, 1150, 'CARMEN ROSA QUISPE HUANCA', NULL, NULL, '34567890', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(9, 1150, 'JOSE MANUEL RODRIGUEZ FLORES', NULL, NULL, '10987654', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(10, 1150, 'MARTHA ISABEL MAMANI HUANCA', NULL, NULL, '45678901', '2B', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(11, 1150, 'ROBERTO CARLOS CHAVEZ PINTO', NULL, NULL, '21098765', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(12, 1150, 'GLORIA ESTEFANIA SILES ORELLANA', NULL, NULL, '56789012', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(13, 1150, 'MANUEL JESUS ALANOCA APAZA', NULL, NULL, '32109876', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(14, 1150, 'FABIOLA ANDREA LOPEZ ESTRADA', NULL, NULL, '67890123', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(15, 1150, 'RAUL ANTONIO PINTO GUTIERREZ', NULL, NULL, '43210987', '3C', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(16, 1150, 'VERONICA PATRICIA CONDORI ALANOCA', NULL, NULL, '78901234', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(17, 1150, 'FERNANDO MARCELO HIDALGO HUANCA', NULL, NULL, '54321098', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(18, 1150, 'ALEJANDRA BELEN MENDOZA ROJAS', NULL, NULL, '89012345', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(19, 1150, 'HERNAN ROLANDO VARGAS FLORES', NULL, NULL, '65432109', '4D', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(20, 1150, 'PAOLA ANDREA QUIROZ CASTRO', NULL, NULL, '90123456', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(21, 1150, 'RAFAEL ENRIQUE SOLIZ HUANCA', NULL, NULL, '76543210', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2);

SELECT setval('clientes_cliente_id_seq', COALESCE((SELECT MAX(cliente_id) FROM clientes), 0), (SELECT COUNT(*) > 0 FROM clientes));

-- ================================================================================================

DELETE FROM categorias;
ALTER SEQUENCE categorias_categoria_id_seq RESTART WITH 1;

INSERT INTO categorias (categoria_id, empresa_nit_id, categoria_padre_id, categoria, codigo, descripcion, nivel, orden, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNA', 'N00', 'Categoría predeterminada para productos sin clasificar', 1, 0, 1000, 1),
(2, 2, NULL, 'MEDICAMENTOS', 'MED', 'Categoría principal para medicamentos en general', 1, 1, 1000, 2),
(3, 3, NULL, 'JUGUETES', 'JUG', 'Categoría principal para juguetes y artículos recreativos', 1, 2, 1000, 2),
(4, 4, NULL, 'SERVICIOS_MEDICOS', 'SMD', 'Categoría principal para servicios médicos y consultas', 1, 3, 1000, 2),
(5, 5, NULL, 'ELECTRONICA', 'ELEC', 'Categoría principal para equipos electrónicos y dispositivos', 1, 4, 1000, 2),
(6, 6, NULL, 'ESCRITORIO', 'ESC', 'Categoría principal para material de escritorio y suministros', 1, 5, 1000, 2),
(7, 7, NULL, 'LIBROS', 'LIB', 'Categoría principal para venta de libros', 1, 6, 1000, 2),
(8, 1, 2, 'ANALGESICOS', 'MED-1', NULL, 2, 1, 1000, 2),
(9, 1, 2, 'ANTIBIOTICOS', 'MED-2', NULL, 2, 2, 1000, 2),
(10, 1, 2, 'ANTIHISTAMINICOS', 'MED-3', NULL, 2, 3, 1000, 2),
(11, 1, 2, 'ANTIINFLAMATORIOS', 'MED-4', NULL, 2, 4, 1000, 2),
(12, 1, 2, 'ANTIACIDOS', 'MED-5', NULL, 2, 5, 1000, 2),
(13, 1, 2, 'ANTIESPASMODICOS', 'MED-6', NULL, 2, 6, 1000, 2),
(14, 1, 2, 'ANTIDEPRESIVOS', 'MED-7', NULL, 2, 7, 1000, 2),
(15, 1, 2, 'ANTIPSICOTICOS', 'MED-8', NULL, 2, 8, 1000, 2),
(16, 1, 2, 'ANTIEMETICOS', 'MED-9', NULL, 2, 9, 1000, 2),
(17, 1, 2, 'ANTIFUNGICOS', 'MED-10', NULL, 2, 10, 1000, 2),
(18, 1, 2, 'ANTIVIRALES', 'MED-11', NULL, 2, 11, 1000, 2),
(19, 1, 2, 'BRONCODILATADORES', 'MED-12', NULL, 2, 12, 1000, 2),
(20, 1, 2, 'CORTICOIDES', 'MED-13', NULL, 2, 13, 1000, 2),
(21, 1, 2, 'DIURETICOS', 'MED-14', NULL, 2, 14, 1000, 2),
(22, 1, 2, 'LAXANTES', 'MED-15', NULL, 2, 15, 1000, 2),
(23, 1, 2, 'VITAMINAS', 'MED-16', NULL, 2, 16, 1000, 2),
(24, 1, 2, 'SUPLEMENTOS', 'MED-17', NULL, 2, 17, 1000, 2),
(25, 1, 2, 'ANTIPIRETICOS', 'MED-18', NULL, 2, 18, 1000, 2),
(26, 1, 2, 'ANTITUSIVOS', 'MED-19', NULL, 2, 19, 1000, 2),
(27, 1, 2, 'EXPECTORANTES', 'MED-20', NULL, 2, 20, 1000, 2),
(28, 1, 2, 'MUCOLITICOS', 'MED-21', NULL, 2, 21, 1000, 2),
(29, 1, 2, 'ANTICONVULSIVANTES', 'MED-22', NULL, 2, 22, 1000, 2),
(30, 1, 2, 'HIPOGLUCEMIANTES', 'MED-23', NULL, 2, 23, 1000, 2),
(31, 1, 2, 'HIPOTENSORES', 'MED-24', NULL, 2, 24, 1000, 2),
(32, 1, 2, 'VASODILATADORES', 'MED-25', NULL, 2, 25, 1000, 2),
(33, 1, 2, 'ANTICOAGULANTES', 'MED-26', NULL, 2, 26, 1000, 2),
(34, 1, 2, 'ANTIAGREGANTES', 'MED-27', NULL, 2, 27, 1000, 2),
(35, 1, 2, 'ANTIANEMICOS', 'MED-28', NULL, 2, 28, 1000, 2),
(36, 1, 2, 'ANTIPARASITARIOS', 'MED-29', NULL, 2, 29, 1000, 2),
(37, 1, 2, 'ANTIPROTOZOARIOS', 'MED-30', NULL, 2, 30, 1000, 2),
(38, 1, 2, 'ANTIRRETROVIRALES', 'MED-31', NULL, 2, 31, 1000, 2),
(39, 1, 2, 'INMUNOSUPRESORES', 'MED-32', NULL, 2, 32, 1000, 2),
(40, 1, 2, 'ANTIARTRITICOS', 'MED-33', NULL, 2, 33, 1000, 2),
(41, 1, 2, 'ANTIGOTOSOS', 'MED-34', NULL, 2, 34, 1000, 2),
(42, 1, 2, 'ANTIHELMINTICOS', 'MED-35', NULL, 2, 35, 1000, 2),
(43, 1, 2, 'ANTIPRURITICOS', 'MED-36', NULL, 2, 36, 1000, 2),
(44, 1, 2, 'ANTISEPTICOS', 'MED-37', NULL, 2, 37, 1000, 2),
(45, 1, 2, 'DESINFECTANTES', 'MED-38', NULL, 2, 38, 1000, 2),
(46, 1, 2, 'ANESTESICOS', 'MED-39', NULL, 2, 39, 1000, 2),
(47, 1, 2, 'ANALGESICOS_OPIOIDES', 'MED-40', NULL, 2, 40, 1000, 2),
(48, 1, 2, 'ANALGESICOS_NO_OPIOIDES', 'MED-41', NULL, 2, 41, 1000, 2),
(49, 1, 2, 'ANTIMIGRAÑOSOS', 'MED-42', NULL, 2, 42, 1000, 2),
(50, 1, 2, 'ANTIANGINOSOS', 'MED-43', NULL, 2, 43, 1000, 2),
(51, 1, 2, 'ANTIARRITMICOS', 'MED-44', NULL, 2, 44, 1000, 2),
(52, 1, 2, 'CARDIOTONICOS', 'MED-45', NULL, 2, 45, 1000, 2),
(53, 1, 2, 'HIPOLIPEMIANTES', 'MED-46', NULL, 2, 46, 1000, 2),
(54, 1, 2, 'ANTIOBESIDAD', 'MED-47', NULL, 2, 47, 1000, 2),
(55, 1, 2, 'ANTIDIABETICOS', 'MED-48', NULL, 2, 48, 1000, 2),
(56, 1, 2, 'HORMONAS', 'MED-49', NULL, 2, 49, 1000, 2),
(57, 1, 2, 'ANTIALERGICOS', 'MED-50', NULL, 2, 50, 1000, 2),
(58, 1, 3, 'JUEGOS_DE_MESA', 'JUG-1', NULL, 2, 1, 1000, 2),
(59, 1, 3, 'JUGUETES_EDUCATIVOS', 'JUG-2', NULL, 2, 2, 1000, 2),
(60, 1, 3, 'PELUCHES', 'JUG-3', NULL, 2, 3, 1000, 2),
(61, 1, 3, 'VEHICULOS', 'JUG-4', NULL, 2, 4, 1000, 2),
(62, 1, 3, 'MUÑECAS', 'JUG-5', NULL, 2, 5, 1000, 2),
(63, 1, 4, 'INYECCIÓN', 'SMD-1', NULL, 2, 1, 1000, 2),
(64, 1, 4, 'DIAGNOSTICO', 'SMD-2', NULL, 2, 2, 1000, 2),
(65, 1, 5, 'LAPTOPS', 'ELEC-1', NULL, 2, 1, 1000, 2),
(66, 1, 5, 'TABLES', 'ELEC-2', NULL, 2, 2, 1000, 2),
(67, 1, 5, 'CELULARES', 'ELEC-3', NULL, 2, 3, 1000, 2),
(68, 1, 5, 'VIDEO', 'ELEC-4', NULL, 2, 4, 1000, 2),
(69, 1, 5, 'TECLADOS', 'ELEC-5', NULL, 2, 5, 1000, 2),
(70, 1, 6, 'PAPEL', 'ESC-1', NULL, 2, 1, 1000, 2),
(71, 1, 6, 'CUADERNOS', 'ESC-2', NULL, 2, 2, 1000, 2),
(72, 1, 6, 'BOLIGRAFOS', 'ESC-3', NULL, 2, 3, 1000, 2),
(73, 1, 6, 'ARCHIVADORES', 'ESC-4', NULL, 2, 4, 1000, 2),
(74, 1, 6, 'LAPICES', 'ESC-5', NULL, 2, 5, 1000, 2),
(75, 1, 7, 'FICCION', 'LIB-1', NULL, 2, 1, 1000, 2),
(76, 1, 7, 'TERROR', 'LIB-2', NULL, 2, 2, 1000, 2),
(77, 1, 7, 'CIENCIA', 'LIB-3', NULL, 2, 3, 1000, 2),
(80, 1, 7, 'HISTORIA', 'LIB-4', NULL, 2, 4, 1000, 2),
(81, 1, 7, 'INFANTILES', 'LIB-5', NULL, 2, 5, 1000, 2);

SELECT setval('categorias_categoria_id_seq', COALESCE((SELECT MAX(categoria_id) FROM categorias), 0), (SELECT COUNT(*) > 0 FROM categorias));

-- ================================================================================================

DELETE FROM laboratorios;
ALTER SEQUENCE laboratorios_laboratorio_id_seq RESTART WITH 1;

INSERT INTO laboratorios (laboratorio_id, codigo, laboratorio, nit, direccion, telefono, email, web, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, NULL, NULL, NULL, 1000, 1),
(2, 'INT', 'LABORATORIOS INTI S.A.', '1023456012', 'AV. JUAN PABLO II NRO. 1500, ZONA VILLA DOLORES, EL ALTO, LA PAZ', '22885566', 'info@inti.com.bo', 'www.inti.com.bo', 1000, 2),
(3, 'BAG', 'BAGÓ DE BOLIVIA S.A.', '1029876543', 'CALLE 1 NRO. 50, PARQUE INDUSTRIAL, EL ALTO, LA PAZ', '22884433', 'atencion@bago.com.bo', 'www.bago.com.bo', 1000, 2),
(4, 'FAR', 'FARMACÉUTICA BOLIVIANA S.A.', '1034567890', 'AV. MONTES NRO. 789, ZONA INDUSTRIAL, EL ALTO, LA PAZ', '22887788', 'contacto@far-bol.com.bo', 'www.far-bol.com', 1000, 2),
(5, 'MCN', 'MCNEIL BOLIVIA S.R.L.', '1045678901', 'EDIF. EMPRESARIAL, PISO 8, AV. ARCE NRO. 2121, SOPOCACHI, LA PAZ', '22445566', 'info@mcneil.com.bo', 'www.mcneil.com.bo', 1000, 2),
(6, 'ROC', 'LABORATORIOS ROCHE BOLIVIA S.A.', '1056789012', 'AV. 6 DE AGOSTO NRO. 2800, EDIF. TOWER, PISO 10, LA PAZ', '22448899', 'contacto@roche.com.bo', 'www.roche.com.bo', 1000, 2);

SELECT setval('laboratorios_laboratorio_id_seq', COALESCE((SELECT MAX(laboratorio_id) FROM laboratorios), 0), (SELECT COUNT(*) > 0 FROM laboratorios));

-- ================================================================================================

DELETE FROM formas;
ALTER SEQUENCE formas_forma_id_seq RESTART WITH 1;

INSERT INTO formas (forma_id, forma_farmaceutica, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', 'Forma farmacéutica predeterminada para productos sin clasificar', 1000, 1),
(2, 'COMPRIMIDO', 'COM', 'Forma sólida de dosificación que contiene uno o más principios activos', 1000, 2),
(3, 'CAPSULA', 'CAP', 'Envoltura gelatinosa que contiene un principio activo en polvo, gránulos o líquido', 1000, 2),
(4, 'JARABE', 'JAR', 'Solución acuosa concentrada de sacarosa con principio activo, de consistencia viscosa', 1000, 2),
(5, 'INYECTABLE', 'INY', 'Solución estéril para administración parenteral', 1000, 2),
(6, 'GOTAS', 'GOT', 'Solución líquida administrada en gotas, generalmente para uso oral u oftálmico', 1000, 2),
(7, 'CREMA', 'CRE', 'Emulsión semisólida para aplicación tópica', 1000, 2),
(8, 'UNGUENTO', 'UNG', 'Preparación semisólida de consistencia blanda para aplicación tópica', 1000, 2),
(9, 'POLVO', 'POL', 'Preparación en forma de polvo para reconstitución o administración directa', 1000, 2),
(10, 'SUPOSITORIO', 'SUP', 'Forma sólida de dosificación para administración rectal', 1000, 2),
(11, 'GEL', 'GEL', 'Sistema coloidal semisólido de consistencia firme para aplicación tópica', 1000, 2),
(12, 'SOLUCION', 'SOL', 'Preparación líquida que contiene uno o más principios activos disueltos en un solvente adecuado', 1000, 2),
(13, 'SUSPENSION', 'SUS', 'Preparación líquida que contiene partículas sólidas dispersas en un líquido', 1000, 2),
(14, 'EMULSION', 'EMU', 'Sistema disperso de dos líquidos inmiscibles, uno en forma de gotas dispersas en el otro', 1000, 2),
(15, 'POMADA', 'POM', 'Preparación semisólida de consistencia grasosa para aplicación tópica', 1000, 2),
(16, 'LOCION', 'LOC', 'Preparación líquida para aplicación tópica sin fricción', 1000, 2),
(17, 'JABON', 'JAB', 'Preparación sólida o líquida con propiedades detergentes para limpieza y desinfección', 1000, 2),
(18, 'CHAMPU', 'CHA', 'Preparación líquida con tensioactivos para limpieza del cuero cabelludo y cabello', 1000, 2),
(19, 'AEROSOL', 'AER', 'Preparación que contiene el principio activo en un sistema presurizado para liberación en forma de partículas finas', 1000, 2),
(20, 'INHALADOR', 'INH', 'Dispositivo que administra medicamento en forma de aerosol para inhalación pulmonar', 1000, 2),
(21, 'PARCHE', 'PAR', 'Sistema transdérmico que libera el principio activo a través de la piel', 1000, 2),
(22, 'GRANULADO', 'GRA', 'Agregados de partículas de polvo que forman gránulos para reconstitución o administración oral', 1000, 2),
(23, 'COMPRIMIDO RECUBIERTO', 'CORE', 'Comprimido con una capa externa que protege el principio activo o mejora la deglución', 1000, 2),
(24, 'COMPRIMIDO MASTICABLE', 'COMA', 'Comprimido diseñado para ser masticado antes de tragar', 1000, 2),
(25, 'COMPRIMIDO EFERVESCENTE', 'COEF', 'Comprimido que se disuelve en agua liberando burbujas de dióxido de carbono', 1000, 2),
(26, 'CAPSULA BLANDA', 'CBL', 'Cápsula de gelatina blanda que contiene líquidos o suspensiones', 1000, 2),
(27, 'CAPSULA DURA', 'CDU', 'Cápsula de gelatina dura que contiene polvos o gránulos', 1000, 2),
(28, 'ELIXIR', 'ELI', 'Solución hidroalcohólica dulce que contiene principios activos, generalmente para uso oral', 1000, 2),
(29, 'TINTURA', 'TIN', 'Solución hidroalcohólica obtenida por maceración o percolación de drogas vegetales', 1000, 2),
(30, 'EXTRACTO', 'EXT', 'Preparación concentrada de principios activos de origen vegetal o animal', 1000, 2),
(31, 'OVULO', 'OVU', 'Forma sólida de dosificación para administración vaginal', 1000, 2),
(32, 'ESPUMA', 'ESP', 'Dispersión de gas en un líquido con agentes tensioactivos, para aplicación tópica o vaginal', 1000, 2),
(33, 'POLVO PARA RECONSTITUIR', 'PRE', 'Polvo estéril que requiere adición de solvente antes de la administración', 1000, 2),
(34, 'LIOFILIZADO', 'LIO', 'Producto liofilizado que requiere reconstitución antes de su uso', 1000, 2),
(35, 'PASTA', 'PAS', 'Preparación semisólida con alto contenido de partículas sólidas para aplicación tópica', 1000, 2),
(36, 'CERA', 'CER', 'Preparación sólida o semisólida con base de ceras para aplicación tópica', 1000, 2),
(37, 'BAÑO', 'BAN', 'Preparación concentrada para diluir en agua de baño con fines terapéuticos', 1000, 2),
(38, 'GOMA DE MASCAR', 'GOM', 'Preparación masticable que libera principios activos durante la masticación', 1000, 2),
(39, 'PELICULA ORAL', 'PEL', 'Película delgada que se disuelve en la cavidad oral liberando el principio activo', 1000, 2),
(40, 'ESPRAY', 'ESPR', 'Solución o suspensión administrada en forma de rocío fino para aplicación oral o tópica', 1000, 2);

SELECT setval('formas_forma_id_seq', COALESCE((SELECT MAX(forma_id) FROM formas), 0), (SELECT COUNT(*) > 0 FROM formas));

-- ================================================================================================

DELETE FROM presentaciones;
ALTER SEQUENCE presentaciones_presentacion_id_seq RESTART WITH 1;

INSERT INTO presentaciones (presentacion_id, unidad_id, codigo, presentacion, cantidad_unidades, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 1, 'Presentación predeterminada para productos sin clasificar', 1000, 1),
(2, 9, 'TAB', 'TABLETA', 1, 'Tableta individual para administración oral', 1000, 2),
(3, 9, 'CAP', 'CAPSULA', 1, 'Cápsula individual para administración oral', 1000, 2),
(4, 9, 'AMP', 'AMP0LLA', 1, 'Ampolla individual para administración inyectable', 1000, 2),
(5, 9, 'FRAS', 'FRASCO', 1, 'Frasco individual para medicamentos líquidos', 1000, 2),
(6, 9, 'OVU', 'OVULO', 1, 'Óvulo individual para administración vaginal', 1000, 2),
(7, 9, 'SUP', 'SUPOSITORIO', 1, 'Supositorio individual para administración rectal', 1000, 2),
(8, 9, 'SOB', 'SOBRE', 1, 'Sobre individual para medicamentos en polvo o granulados', 1000, 2),
(9, 9, 'TUB', 'TUBO', 1, 'Tubo individual para cremas y ungüentos', 1000, 2),
(10, 11, 'CJ10', 'CAJA X 10 TABLETAS', 10, 'Caja conteniendo 10 tabletas', 1000, 2),
(11, 11, 'CJ20', 'CAJA X 20 TABLETAS', 20, 'Caja conteniendo 20 tabletas', 1000, 2),
(12, 11, 'CJ30', 'CAJA X 30 TABLETAS', 30, 'Caja conteniendo 30 tabletas', 1000, 2),
(13, 11, 'CJ50', 'CAJA X 50 TABLETAS', 50, 'Caja conteniendo 50 tabletas', 1000, 2),
(14, 11, 'CJ100', 'CAJA X 100 TABLETAS', 100, 'Caja conteniendo 100 tabletas', 1000, 2),
(15, 11, 'CJC10', 'CAJA X 10 CAPSULAS', 10, 'Caja conteniendo 10 cápsulas', 1000, 2),
(16, 11, 'CJC20', 'CAJA X 20 CAPSULAS', 20, 'Caja conteniendo 20 cápsulas', 1000, 2),
(17, 11, 'CJA10', 'CAJA X 10 AMPOLLAS', 10, 'Caja conteniendo 10 ampollas', 1000, 2),
(18, 9, 'FRX100', 'FRASCO X 100 ML', 1, 'Frasco de 100 ml para jarabes y soluciones', 1000, 2),
(19, 9, 'FRX250', 'FRASCO X 250 ML', 1, 'Frasco de 250 ml para jarabes y soluciones', 1000, 2),
(20, 9, 'TUB30', 'TUBO X 30 G', 1, 'Tubo de 30 gramos para cremas y ungüentos', 1000, 2),
(21, 9, 'TUB50', 'TUBO X 50 G', 1, 'Tubo de 50 gramos para cremas y ungüentos', 1000, 2),
(22, 11, 'CJX5', 'CAJA X 5 TABLETAS', 5, 'Caja conteniendo 5 tabletas', 1000, 2),
(23, 11, 'CJX60', 'CAJA X 60 TABLETAS', 60, 'Caja conteniendo 60 tabletas', 1000, 2),
(24, 11, 'CJX90', 'CAJA X 90 TABLETAS', 90, 'Caja conteniendo 90 tabletas', 1000, 2),
(25, 11, 'CJX120', 'CAJA X 120 TABLETAS', 120, 'Caja conteniendo 120 tabletas', 1000, 2),
(26, 11, 'CJX180', 'CAJA X 180 TABLETAS', 180, 'Caja conteniendo 180 tabletas', 1000, 2),
(27, 11, 'CJX250', 'CAJA X 250 TABLETAS', 250, 'Caja conteniendo 250 tabletas', 1000, 2),
(28, 11, 'CJX500', 'CAJA X 500 TABLETAS', 500, 'Caja conteniendo 500 tabletas', 1000, 2),
(29, 11, 'CJCX5', 'CAJA X 5 CAPSULAS', 5, 'Caja conteniendo 5 cápsulas', 1000, 2),
(30, 11, 'CJCX30', 'CAJA X 30 CAPSULAS', 30, 'Caja conteniendo 30 cápsulas', 1000, 2),
(31, 11, 'CJCX50', 'CAJA X 50 CAPSULAS', 50, 'Caja conteniendo 50 cápsulas', 1000, 2),
(32, 11, 'CJCX60', 'CAJA X 60 CAPSULAS', 60, 'Caja conteniendo 60 cápsulas', 1000, 2),
(33, 11, 'CJCX90', 'CAJA X 90 CAPSULAS', 90, 'Caja conteniendo 90 cápsulas', 1000, 2),
(34, 11, 'CJCX100', 'CAJA X 100 CAPSULAS', 100, 'Caja conteniendo 100 cápsulas', 1000, 2),
(35, 11, 'CJAX5', 'CAJA X 5 AMPOLLAS', 5, 'Caja conteniendo 5 ampollas', 1000, 2),
(36, 11, 'CJAX20', 'CAJA X 20 AMPOLLAS', 20, 'Caja conteniendo 20 ampollas', 1000, 2),
(37, 11, 'CJAX50', 'CAJA X 50 AMPOLLAS', 50, 'Caja conteniendo 50 ampollas', 1000, 2),
(38, 11, 'CJAX100', 'CAJA X 100 AMPOLLAS', 100, 'Caja conteniendo 100 ampollas', 1000, 2),
(39, 9, 'FRX15', 'FRASCO X 15 ML', 1, 'Frasco de 15 ml para soluciones oftálmicas o gotas', 1000, 2),
(40, 9, 'FRX30', 'FRASCO X 30 ML', 1, 'Frasco de 30 ml para colirios o soluciones', 1000, 2),
(41, 9, 'FRX50', 'FRASCO X 50 ML', 1, 'Frasco de 50 ml para jarabes o soluciones', 1000, 2),
(42, 9, 'FRX60', 'FRASCO X 60 ML', 1, 'Frasco de 60 ml para medicamentos líquidos', 1000, 2),
(43, 9, 'FRX120', 'FRASCO X 120 ML', 1, 'Frasco de 120 ml para jarabes', 1000, 2),
(44, 9, 'FRX200', 'FRASCO X 200 ML', 1, 'Frasco de 200 ml para soluciones orales', 1000, 2),
(45, 9, 'FRX500', 'FRASCO X 500 ML', 1, 'Frasco de 500 ml para soluciones o jarabes', 1000, 2),
(46, 9, 'FRX1000', 'FRASCO X 1000 ML', 1, 'Frasco de 1000 ml (1 litro) para soluciones', 1000, 2),
(47, 9, 'TUBX5', 'TUBO X 5 G', 1, 'Tubo de 5 gramos para cremas o ungüentos', 1000, 2),
(48, 9, 'TUBX10', 'TUBO X 10 G', 1, 'Tubo de 10 gramos para cremas', 1000, 2),
(49, 9, 'TUBX15', 'TUBO X 15 G', 1, 'Tubo de 15 gramos para cremas y ungüentos', 1000, 2),
(50, 9, 'TUBX20', 'TUBO X 20 G', 1, 'Tubo de 20 gramos para cremas', 1000, 2),
(51, 9, 'TUBX40', 'TUBO X 40 G', 1, 'Tubo de 40 gramos para cremas y ungüentos', 1000, 2),
(52, 9, 'TUBX60', 'TUBO X 60 G', 1, 'Tubo de 60 gramos para cremas', 1000, 2),
(53, 9, 'TUBX100', 'TUBO X 100 G', 1, 'Tubo de 100 gramos para cremas', 1000, 2),
(54, 9, 'SOBX5', 'SOBRE X 5 G', 1, 'Sobre de 5 gramos para polvos', 1000, 2),
(55, 9, 'SOBX10', 'SOBRE X 10 G', 1, 'Sobre de 10 gramos para polvos', 1000, 2),
(56, 9, 'SOBX15', 'SOBRE X 15 G', 1, 'Sobre de 15 gramos para polvos', 1000, 2),
(57, 9, 'SOBX20', 'SOBRE X 20 G', 1, 'Sobre de 20 gramos para polvos', 1000, 2),
(58, 9, 'SOBX30', 'SOBRE X 30 G', 1, 'Sobre de 30 gramos para polvos', 1000, 2),
(59, 11, 'CJSX5', 'CAJA X 5 SOBRES', 5, 'Caja conteniendo 5 sobres', 1000, 2),
(60, 11, 'CJSX10', 'CAJA X 10 SOBRES', 10, 'Caja conteniendo 10 sobres', 1000, 2),
(61, 11, 'CJSX20', 'CAJA X 20 SOBRES', 20, 'Caja conteniendo 20 sobres', 1000, 2),
(62, 11, 'CJSX30', 'CAJA X 30 SOBRES', 30, 'Caja conteniendo 30 sobres', 1000, 2),
(63, 9, 'POTX15', 'POTE X 15 G', 1, 'Pote de 15 gramos para cremas o pomadas', 1000, 2),
(64, 9, 'POTX30', 'POTE X 30 G', 1, 'Pote de 30 gramos para cremas', 1000, 2),
(65, 9, 'POTX50', 'POTE X 50 G', 1, 'Pote de 50 gramos para cremas o ungüentos', 1000, 2),
(66, 9, 'POTX100', 'POTE X 100 G', 1, 'Pote de 100 gramos para cremas', 1000, 2),
(67, 9, 'POTX250', 'POTE X 250 G', 1, 'Pote de 250 gramos para cremas', 1000, 2),
(68, 11, 'CJOV10', 'CAJA X 10 OVULOS', 10, 'Caja conteniendo 10 óvulos vaginales', 1000, 2),
(69, 11, 'CJSUP10', 'CAJA X 10 SUPOSITORIOS', 10, 'Caja conteniendo 10 supositorios', 1000, 2),
(70, 11, 'CJSUP12', 'CAJA X 12 SUPOSITORIOS', 12, 'Caja conteniendo 12 supositorios', 1000, 2),
(71, 11, 'CJSUP6', 'CAJA X 6 SUPOSITORIOS', 6, 'Caja conteniendo 6 supositorios', 1000, 2);

SELECT setval('presentaciones_presentacion_id_seq', COALESCE((SELECT MAX(presentacion_id) FROM presentaciones), 0), (SELECT COUNT(*) > 0 FROM presentaciones));

-- ================================================================================================

DELETE FROM concentraciones;
ALTER SEQUENCE concentraciones_concentracion_id_seq RESTART WITH 1;

INSERT INTO concentraciones (concentracion_id, unidad_base_id, codigo, concentracion, valor_numerico, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 0.00, 'Concentración predeterminada para productos sin clasificar', 1000, 1),
(2, 5, '500MG', '500 MG', 500.00, 'Concentración de 500 miligramos', 1000, 2),
(3, 5, '100MG', '100 MG', 100.00, 'Concentración de 100 miligramos', 1000, 2),
(4, 5, '50MG', '50 MG', 50.00, 'Concentración de 50 miligramos', 1000, 2),
(5, 5, '25MG', '25 MG', 25.00, 'Concentración de 25 miligramos', 1000, 2),
(6, 5, '10MG', '10 MG', 10.00, 'Concentración de 10 miligramos', 1000, 2),
(7, 5, '5MG', '5 MG', 5.00, 'Concentración de 5 miligramos', 1000, 2),
(8, 5, '750MG', '750 MG', 750.00, 'Concentración de 750 miligramos', 1000, 2),
(9, 5, '1000MG', '1000 MG', 1000.00, 'Concentración de 1000 miligramos', 1000, 2),
(10, 6, '500ML', '500 ML', 500.00, 'Concentración de 500 mililitros', 1000, 2),
(11, 6, '250ML', '250 ML', 250.00, 'Concentración de 250 mililitros', 1000, 2),
(12, 6, '100ML', '100 ML', 100.00, 'Concentración de 100 mililitros', 1000, 2),
(13, 6, '50ML', '50 ML', 50.00, 'Concentración de 50 mililitros', 1000, 2),
(14, 6, '30ML', '30 ML', 30.00, 'Concentración de 30 mililitros', 1000, 2),
(15, 6, '15ML', '15 ML', 15.00, 'Concentración de 15 mililitros', 1000, 2),
(16, 5, '200MG', '200 MG', 200.00, 'Concentración de 200 miligramos', 1000, 2),
(17, 5, '150MG', '150 MG', 150.00, 'Concentración de 150 miligramos', 1000, 2),
(18, 5, '75MG', '75 MG', 75.00, 'Concentración de 75 miligramos', 1000, 2),
(19, 5, '20MG', '20 MG', 20.00, 'Concentración de 20 miligramos', 1000, 2),
(20, 5, '2MG', '2 MG', 2.00, 'Concentración de 2 miligramos', 1000, 2),
(21, 5, '1MG', '1 MG', 1.00, 'Concentración de 1 miligramo', 1000, 2),
(22, 6, '10ML', '10 ML', 10.00, 'Concentración de 10 mililitros', 1000, 2),
(23, 6, '20ML', '20 ML', 20.00, 'Concentración de 20 mililitros', 1000, 2),
(24, 6, '60ML', '60 ML', 60.00, 'Concentración de 60 mililitros', 1000, 2),
(25, 6, '120ML', '120 ML', 120.00, 'Concentración de 120 mililitros', 1000, 2),
(26, 6, '200ML', '200 ML', 200.00, 'Concentración de 200 mililitros', 1000, 2),
(27, 6, '1000ML', '1000 ML', 1000.00, 'Concentración de 1000 mililitros (1 litro)', 1000, 2),
(28, 5, '40MG', '40 MG', 40.00, 'Concentración de 40 miligramos', 1000, 2),
(29, 5, '30MG', '30 MG', 30.00, 'Concentración de 30 miligramos', 1000, 2),
(30, 5, '15MG', '15 MG', 15.00, 'Concentración de 15 miligramos', 1000, 2),
(31, 5, '7.5MG', '7.5 MG', 7.50, 'Concentración de 7.5 miligramos', 1000, 2),
(32, 5, '2.5MG', '2.5 MG', 2.50, 'Concentración de 2.5 miligramos', 1000, 2),
(33, 5, '0.5MG', '0.5 MG', 0.50, 'Concentración de 0.5 miligramos', 1000, 2),
(34, 5, '125MG', '125 MG', 125.00, 'Concentración de 125 miligramos', 1000, 2),
(35, 5, '250MG', '250 MG', 250.00, 'Concentración de 250 miligramos', 1000, 2),
(36, 5, '375MG', '375 MG', 375.00, 'Concentración de 375 miligramos', 1000, 2),
(37, 5, '625MG', '625 MG', 625.00, 'Concentración de 625 miligramos', 1000, 2),
(38, 5, '875MG', '875 MG', 875.00, 'Concentración de 875 miligramos', 1000, 2),
(39, 5, '1200MG', '1200 MG', 1200.00, 'Concentración de 1200 miligramos', 1000, 2),
(40, 5, '1500MG', '1500 MG', 1500.00, 'Concentración de 1500 miligramos', 1000, 2),
(41, 2, '1KG', '1 KG', 1.00, 'Concentración de 1 kilogramo', 1000, 2),
(42, 2, '5KG', '5 KG', 5.00, 'Concentración de 5 kilogramos', 1000, 2),
(43, 3, '100G', '100 G', 100.00, 'Concentración de 100 gramos', 1000, 2),
(44, 3, '200G', '200 G', 200.00, 'Concentración de 200 gramos', 1000, 2),
(45, 3, '500G', '500 G', 500.00, 'Concentración de 500 gramos', 1000, 2),
(46, 14, '10MCG', '10 MCG', 10.00, 'Concentración de 10 microgramos', 1000, 2),
(47, 14, '20MCG', '20 MCG', 20.00, 'Concentración de 20 microgramos', 1000, 2),
(48, 14, '50MCG', '50 MCG', 50.00, 'Concentración de 50 microgramos', 1000, 2),
(49, 14, '100MCG', '100 MCG', 100.00, 'Concentración de 100 microgramos', 1000, 2),
(50, 14, '200MCG', '200 MCG', 200.00, 'Concentración de 200 microgramos', 1000, 2),
(51, 15, '1000UI', '1000 UI', 1000.00, 'Concentración de 1000 unidades internacionales', 1000, 2),
(52, 15, '5000UI', '5000 UI', 5000.00, 'Concentración de 5000 unidades internacionales', 1000, 2);

SELECT setval('concentraciones_concentracion_id_seq', COALESCE((SELECT MAX(concentracion_id) FROM concentraciones), 0), (SELECT COUNT(*) > 0 FROM concentraciones));

-- ================================================================================================

DELETE FROM vias;
ALTER SEQUENCE vias_via_id_seq RESTART WITH 1;

INSERT INTO vias (via_id, nombre, descripcion, requiere_ayuno, tiempo_efecto_minutos, precauciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'Vía de administración predeterminada para productos sin clasificar', 0, NULL, NULL, 1000, 1),
(2, 'ORAL', 'Administración por vía oral (tragado). La más común para medicamentos en comprimidos, cápsulas y jarabes.', 0, 30, 'Tomar con suficiente agua. No masticar comprimidos de liberación prolongada.', 1000, 2),
(3, 'SUBLINGUAL', 'Administración bajo la lengua. Absorción rápida a través de la mucosa sublingual.', 1, 5, 'No tragar, dejar disolver completamente bajo la lengua. No comer ni beber hasta su completa absorción.', 1000, 2),
(4, 'BUCAL', 'Administración en la cavidad bucal, entre la encía y la mejilla.', 0, 15, 'No masticar ni tragar. Colocar entre la encía y la mejilla hasta su completa disolución.', 1000, 2),
(5, 'TÓPICA', 'Aplicación directa sobre la piel o mucosas. Incluye cremas, ungüentos, geles y soluciones.', 0, NULL, 'Aplicar sobre piel limpia y seca. Evitar contacto con ojos, mucosas y zonas irritadas.', 1000, 2),
(6, 'TRANSDÉRMICA', 'Administración a través de la piel mediante parches adhesivos. Liberación controlada y sostenida.', 0, 120, 'Aplicar sobre piel sana y sin vello. Cambiar de sitio de aplicación para evitar irritación.', 1000, 2),
(7, 'INHALADA', 'Administración por inhalación. Utilizada en afecciones respiratorias como asma y EPOC.', 0, 5, 'Agitar el inhalador antes de usar. Mantener una técnica correcta de inhalación.', 1000, 2),
(8, 'NASAL', 'Administración por vía nasal en forma de gotas o aerosol. Para descongestión o tratamientos locales.', 0, 5, 'Limpiar la nariz antes de usar. No inclinar la cabeza hacia atrás bruscamente.', 1000, 2),
(9, 'INTRAMUSCULAR', 'Administración inyectable en el músculo. Absorción rápida y eficaz.', 1, 15, 'Solo personal capacitado. Aspirar antes de inyectar para evitar punción venosa.', 1000, 2),
(10, 'INTRAVENOSA', 'Administración inyectable directamente en el torrente sanguíneo. Efecto inmediato.', 1, 1, 'Solo personal médico calificado. Control estricto de velocidad de infusión.', 1000, 2),
(11, 'SUBCUTÁNEA', 'Administración inyectable en el tejido subcutáneo. Absorción lenta y sostenida.', 1, 20, 'Solo personal capacitado. Rotar los sitios de inyección para evitar lipodistrofia.', 1000, 2),
(12, 'RECTAL', 'Administración por vía rectal mediante supositorios o enemas. Útil cuando la vía oral no es posible.', 1, 30, 'Introducir el supositorio con el dedo, apuntando hacia el ombligo. Permanecer acostado unos minutos.', 1000, 2),
(13, 'VAGINAL', 'Administración por vía vaginal mediante óvulos, cremas o tabletas vaginales.', 0, 30, 'Usar aplicador si está incluido. Acostarse durante 15-20 minutos después de la aplicación.', 1000, 2),
(14, 'OFTÁLMICA', 'Administración en el ojo mediante gotas o ungüentos oftálmicos. Para tratar infecciones y afecciones oculares.', 0, NULL, 'Lavarse las manos antes y después. No tocar el ojo con el aplicador.', 1000, 2),
(15, 'ÓTICA', 'Administración en el oído mediante gotas óticas. Para tratar infecciones del oído externo.', 0, NULL, 'Templar el frasco antes de usar. Inclinar la cabeza y permanecer unos minutos.', 1000, 2);

SELECT setval('vias_via_id_seq', COALESCE((SELECT MAX(via_id) FROM vias), 0), (SELECT COUNT(*) > 0 FROM vias));

-- ================================================================================================

DELETE FROM rangos_edad;
ALTER SEQUENCE rangos_edad_rango_edad_id_seq RESTART WITH 1;

INSERT INTO rangos_edad (rango_edad_id, codigo, rango, edad_minima_meses, edad_maxima_meses, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'No especificado / General', NULL, NULL, 'Rango de edad predeterminado para productos sin clasificación etaria', 1000, 1),
(2, 'RECIEN', 'Recién Nacido', 0, 1, '0 a 28 días de vida. Mayor vulnerabilidad a medicamentos.', 1000, 2),
(3, 'LACTANTE_1-6M', 'Lactante 1-6 meses', 1, 6, '1 a 6 meses de edad. Sistema en desarrollo.', 1000, 2),
(4, 'LACTANTE_6-12M', 'Lactante 6-12 meses', 6, 12, '6 a 12 meses de edad. Introducción de alimentos sólidos.', 1000, 2),
(5, 'LACTANTE_1-12M', 'Lactante (1-12 meses)', 1, 12, 'De 1 mes a 1 año de edad. Etapa de rápido crecimiento.', 1000, 2),
(6, 'NINO_1-3A', 'Niño 1-3 años', 12, 36, 'De 1 a 3 años. Etapa de desarrollo motor y cognitivo.', 1000, 2),
(7, 'NINO_3-5A', 'Niño 3-5 años', 36, 72, 'De 3 a 5 años. Etapa preescolar.', 1000, 2),
(8, 'PREESCOLAR', 'Preescolar (1-5 años)', 12, 72, 'De 1 a 5 años (12 a 60 meses).', 1000, 2),
(9, 'ESCOLAR_5-12A', 'Escolar (5-12 años)', 72, 144, 'De 5 a 12 años. Etapa escolar.', 1000, 2),
(10, 'PEDIATRICO_GRAL', 'Pediátrico General', 0, 144, 'Desde recién nacido hasta los 12 años. Todos los rangos pediátricos.', 1000, 2),
(11, 'ADOLECENTE_12-15A', 'Adolescente 12-15 años', 144, 180, 'De 12 a 15 años. Pubertad y cambios hormonales.', 1000, 2),
(12, 'ADOLECENTE_15-18A', 'Adolescente 15-18 años', 180, 216, 'De 15 a 18 años. Adolescencia tardía.', 1000, 2),
(13, 'ADOLECENTE_12-18A', 'Adolescente (12-18 años)', 144, 216, 'De 12 a 18 años. Etapa de transición a la adultez.', 1000, 2),
(14, 'ADULTO_18-40A', 'Adulto 18-40 años', 216, 480, 'De 18 a 40 años. Etapa de plenitud física.', 1000, 2),
(15, 'ADULTO_40-65A', 'Adulto 40-65 años', 480, 780, 'De 40 a 65 años. Etapa de madurez.', 1000, 2),
(16, 'ADULTO_18-65A', 'Adulto (18-65 años)', 216, 780, 'De 18 a 65 años. Población adulta general.', 1000, 2),
(17, 'ADULTO_MAYOR_65-75A', 'Adulto Mayor 65-75 años', 780, 900, 'De 65 a 75 años. Tercera edad.', 1000, 2),
(18, 'ADULTO_MAYOR_75-85A', 'Adulto Mayor 75-85 años', 900, 1020, 'De 75 a 85 años. Cuarta edad.', 1000, 2),
(19, 'ADULTO_MAYOR_85A', 'Adulto Mayor 85+ años', 1020, NULL, 'Mayores de 85 años. Quinta edad.', 1000, 2),
(20, 'ADULTO_MAYOR_GERIATRICO', 'Adulto Mayor / Geriátrico', 780, NULL, 'Mayores de 65 años. Población geriátrica.', 1000, 2);

SELECT setval('rangos_edad_rango_edad_id_seq', COALESCE((SELECT MAX(rango_edad_id) FROM rangos_edad), 0), (SELECT COUNT(*) > 0 FROM rangos_edad));

-- ================================================================================================

DELETE FROM marcas;
ALTER SEQUENCE marcas_marca_id_seq RESTART WITH 1;

INSERT INTO marcas (marca_id, nombre, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'Marca predeterminada para productos genéricos o sin marca especificada', 1000, 1),
(2, 'BAYER', 'Laboratorio farmacéutico alemán, líder en medicamentos y productos de salud', 1000, 2),
(3, 'NOVARTIS', 'Laboratorio farmacéutico suizo, especializado en medicamentos de alta complejidad', 1000, 2),
(4, 'PFIZER', 'Laboratorio farmacéutico estadounidense, uno de los más grandes del mundo', 1000, 2),
(5, 'GSK', 'GlaxoSmithKline, laboratorio británico especializado en vacunas y medicamentos', 1000, 2),
(6, 'INTI', 'Laboratorio farmacéutico boliviano de medicamentos genéricos', 1000, 2),
(7, 'ROZEN', 'Marca de medicamentos de venta libre y cuidado personal', 1000, 2),
(8, 'FARMABOL', 'Marca boliviana de medicamentos genéricos y suplementos', 1000, 2),
(9, 'LABORATORIOS BAGÓ', 'Marca de medicamentos de origen argentino con presencia en Bolivia', 1000, 2),
(10, 'MCNEIL', 'Marca de productos de consumo y medicamentos OTC', 1000, 2),
(11, 'ROCHE', 'Laboratorio suizo, especialidad en oncología y medicamentos de alta complejidad', 1000, 2),
(12, 'LEGO', 'Marca danesa de juguetes de construcción y bloques', 1000, 2),
(13, 'MATTEL', 'Marca estadounidense de juguetes, incluyendo Barbie y Hot Wheels', 1000, 2),
(14, 'HASBRO', 'Marca estadounidense de juegos de mesa y juguetes', 1000, 2),
(15, 'FISHER PRICE', 'Marca de juguetes educativos y para bebés', 1000, 2),
(16, 'PLAYMOBIL', 'Marca alemana de figuras y escenarios de juego', 1000, 2),
(17, 'HP', 'Hewlett-Packard, marca de computadoras, laptops e impresoras', 1000, 2),
(18, 'DELL', 'Marca de computadoras y equipos tecnológicos', 1000, 2),
(19, 'SAMSUNG', 'Marca coreana de teléfonos, tablets y electrónica', 1000, 2),
(20, 'APPLE', 'Marca estadounidense de productos tecnológicos de alta gama', 1000, 2),
(21, 'LENOVO', 'Marca china de computadoras y dispositivos tecnológicos', 1000, 2),
(22, 'XEROX', 'Marca de fotocopiadoras, impresoras y material de oficina', 1000, 2),
(23, 'PILOT', 'Marca japonesa de lapiceros, bolígrafos y material de escritura', 1000, 2),
(24, 'BIC', 'Marca francesa de bolígrafos, encendedores y artículos de oficina', 1000, 2),
(25, 'MAPED', 'Marca francesa de material escolar y de oficina', 1000, 2),
(26, '3M', 'Marca estadounidense de productos industriales, oficina y salud', 1000, 2),
(27, 'COLGATE', 'Marca de productos de higiene personal y cuidado bucal', 1000, 2),
(28, 'PALMOLIVE', 'Marca de productos de cuidado personal y limpieza', 1000, 2),
(29, 'JOHNSON & JOHNSON', 'Marca de productos para bebés, cuidado personal y farmacéuticos', 1000, 2),
(30, 'NIVEA', 'Marca alemana de productos de cuidado personal y cosmética', 1000, 2),
(31, 'LOREAL', 'Marca francesa de cosméticos y productos de belleza', 1000, 2),
(32, 'PROCTER & GAMBLE', 'Marca de productos de limpieza, cuidado personal y del hogar', 1000, 2);

SELECT setval('marcas_marca_id_seq', COALESCE((SELECT MAX(marca_id) FROM marcas), 0), (SELECT COUNT(*) > 0 FROM marcas));

-- ================================================================================================

DELETE FROM productos;
ALTER SEQUENCE productos_producto_id_seq RESTART WITH 1;

INSERT INTO productos (producto_id,categoria_id,laboratorio_id,marca_id,forma_id,presentacion_id,concentracion_id,unidad_venta_id,tipo_almacen_id,codigo,codigo_barras,sku,isbn,serie,modelo,nombre,nombre_generico,pcompra,p_factor_venta,p_factor_facturacion,pventa,pventaf,stock_minimo,stock_maximo,punto_reorden,requiere_receta,controlado,tiene_registro_sanitario,descripcion,observacion,foto1,foto2,foto3,criticidad_medica_id,estado_id,usuario_id_registro) VALUES
	 (1,1,1,1,1,1,1,1,1700,'NIN',NULL,NULL,NULL,NULL,NULL,'NINGUNO',NULL,0.00,1.50,1.19,0.00,0.00,0.00,0.00,0.00,0,0,0,'Producto predeterminado para casos sin clasificar',NULL,NULL,NULL,NULL,4150,1000,1),
	 (2,8,2,2,2,10,2,9,1700,'SM-8-00001',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.50,1.50,1.19,3.75,2.98,10.00,200.00,25.00,0,0,1,'Alivio rápido y efectivo del dolor de cabeza, dental, muscular y fiebre. Fórmula confiable con acción antiinflamatoria.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (3,8,2,2,2,11,2,9,1700,'SM-8-00002',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.80,1.50,1.19,7.20,5.71,10.00,150.00,20.00,0,0,1,'Presentación económica en caja de 20 tabletas para el alivio de dolores leves a moderados y reducción de fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (4,8,2,2,2,12,2,9,1700,'SM-8-00003',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',6.90,1.50,1.19,10.35,8.21,10.00,120.00,15.00,0,0,1,'Caja de 30 tabletas de Aspirina 500 mg para el tratamiento sintomático del dolor y la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (5,8,2,2,2,13,2,9,1700,'SM-8-00004',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 50 TABLETAS','ACIDO ACETILSALICILICO',10.50,1.50,1.19,15.75,12.50,5.00,100.00,10.00,0,0,1,'Formato familiar de 50 tabletas de Aspirina 500 mg, ideal para uso prolongado en dolores musculares y articulares.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (6,8,6,11,2,10,7,9,1700,'SM-8-00005',NULL,NULL,NULL,NULL,NULL,'DOLO-NEUROBION 5 MG CAJA X 10 TABLETAS','DICLOFENACO SODICO',3.20,1.50,1.19,4.80,3.81,10.00,180.00,20.00,0,0,1,'Alivio del dolor neuropático y muscular con Diclofenaco 5 mg. Fórmula de rápida absorción.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (7,8,6,11,2,12,7,9,1700,'SM-8-00006',NULL,NULL,NULL,NULL,NULL,'DOLO-NEUROBION 5 MG CAJA X 30 TABLETAS','DICLOFENACO SODICO',8.50,1.50,1.19,12.75,10.12,10.00,120.00,15.00,0,0,1,'Tratamiento efectivo para el dolor agudo y crónico. Caja de 30 tabletas de 5 mg de Diclofenaco.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (8,8,3,9,2,10,3,9,1700,'SM-8-00007',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 10 TABLETAS','IBUPROFENO',2.10,1.50,1.19,3.15,2.50,10.00,200.00,25.00,0,0,1,'Antiinflamatorio no esteroideo para el alivio del dolor de cabeza, dental y muscular. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (9,8,3,9,2,11,3,9,1700,'SM-8-00008',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 20 TABLETAS','IBUPROFENO',3.80,1.50,1.19,5.70,4.52,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 100 mg para el manejo del dolor y la inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (10,8,3,9,2,12,3,9,1700,'SM-8-00009',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 30 TABLETAS','IBUPROFENO',5.40,1.50,1.19,8.10,6.43,10.00,120.00,15.00,0,0,1,'Ideal para tratamientos prolongados de dolor muscular y articular. 30 tabletas de 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (11,8,3,9,2,13,3,9,1700,'SM-8-00010',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 50 TABLETAS','IBUPROFENO',8.20,1.50,1.19,12.30,9.76,5.00,100.00,10.00,0,0,1,'Presentación económica de 50 tabletas de Ibuprofeno 100 mg para uso familiar.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (12,8,4,8,2,10,6,9,1700,'SM-8-00011',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 10 TABLETAS','PARACETAMOL',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Analgésico y antipirético de uso común. 10 mg por tableta para alivio rápido de la fiebre y el dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (13,8,4,8,2,11,6,9,1700,'SM-8-00012',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 20 TABLETAS','PARACETAMOL',3.20,1.50,1.19,4.80,3.81,10.00,150.00,20.00,0,0,1,'Alivio efectivo del dolor y la fiebre. Caja de 20 tabletas de 10 mg de Paracetamol.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (14,8,4,8,2,12,6,9,1700,'SM-8-00013',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 30 TABLETAS','PARACETAMOL',4.50,1.50,1.19,6.75,5.36,10.00,120.00,15.00,0,0,1,'Tratamiento sintomático del dolor y la fiebre. 30 tabletas de Paracetamol 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (15,8,4,8,2,13,6,9,1700,'SM-8-00014',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 50 TABLETAS','PARACETAMOL',7.00,1.50,1.19,10.50,8.33,5.00,100.00,10.00,0,0,1,'Formato familiar de 50 tabletas de Paracetamol 10 mg para el hogar.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (16,8,5,10,2,14,2,9,1700,'SM-8-00015',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 100 TABLETAS','ACIDO ACETILSALICILICO',18.50,1.50,1.19,27.75,22.02,5.00,80.00,8.00,0,0,1,'Caja de 100 tabletas de Aspirina 500 mg para uso prolongado en tratamientos cardiovasculares.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (17,9,2,2,2,10,2,9,1700,'SM-9-00001',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 10 TABLETAS','AMOXICILINA TRIHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,180.00,20.00,1,0,1,'Antibiótico de amplio espectro para infecciones respiratorias, urinarias y de piel. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (18,9,2,2,2,11,2,9,1700,'SM-9-00002',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 20 TABLETAS','AMOXICILINA TRIHIDRATO',8.00,1.50,1.19,12.00,9.52,10.00,150.00,15.00,1,0,1,'Tratamiento antibiótico de 20 tabletas de Amoxicilina 500 mg para infecciones bacterianas.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (19,9,2,2,2,12,2,9,1700,'SM-9-00003',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 30 TABLETAS','AMOXICILINA TRIHIDRATO',11.00,1.50,1.19,16.50,13.09,10.00,120.00,12.00,1,0,1,'Caja de 30 tabletas de Amoxicilina 500 mg para tratamientos prolongados de infecciones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (20,9,2,2,2,13,2,9,1700,'SM-9-00004',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 50 TABLETAS','AMOXICILINA TRIHIDRATO',17.50,1.50,1.19,26.25,20.83,5.00,100.00,10.00,1,0,1,'Antibiótico de amplio espectro en presentación de 50 tabletas de 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (21,9,2,2,3,15,2,9,1700,'SM-9-00005',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 10 CAPSULAS','AMOXICILINA TRIHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,18.00,1,0,1,'Cápsulas de Amoxicilina 500 mg para infecciones bacterianas. Fácil administración.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (22,9,2,2,3,16,2,9,1700,'SM-9-00006',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 20 CAPSULAS','AMOXICILINA TRIHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,14.00,1,0,1,'Caja de 20 cápsulas de Amoxicilina 500 mg para el tratamiento de infecciones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (23,9,2,2,3,30,2,9,1700,'SM-9-00007',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 30 CAPSULAS','AMOXICILINA TRIHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'Cápsulas de 500 mg de Amoxicilina para uso prolongado en infecciones respiratorias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (24,9,3,9,2,10,8,9,1700,'SM-9-00008',NULL,NULL,NULL,NULL,NULL,'CLARITROMICINA 750 MG CAJA X 10 TABLETAS','CLARITROMICINA',6.50,1.50,1.19,9.75,7.74,10.00,160.00,18.00,1,0,1,'Antibiótico macrólido para infecciones respiratorias y de piel. 750 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (25,9,3,9,2,11,8,9,1700,'SM-9-00009',NULL,NULL,NULL,NULL,NULL,'CLARITROMICINA 750 MG CAJA X 20 TABLETAS','CLARITROMICINA',12.00,1.50,1.19,18.00,14.28,10.00,130.00,15.00,1,0,1,'Caja de 20 tabletas de Claritromicina 750 mg para infecciones bacterianas.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (26,9,3,9,2,12,8,9,1700,'SM-9-00010',NULL,NULL,NULL,NULL,NULL,'CLARITROMICINA 750 MG CAJA X 30 TABLETAS','CLARITROMICINA',17.00,1.50,1.19,25.50,20.23,10.00,100.00,12.00,1,0,1,'Tratamiento prolongado con 30 tabletas de Claritromicina 750 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (27,9,4,8,2,10,34,9,1700,'SM-9-00011',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 10 TABLETAS','AZITROMICINA DIHIDRATADA',4.00,1.50,1.19,6.00,4.76,10.00,170.00,20.00,1,0,1,'Antibiótico de espectro extendido para infecciones respiratorias y de piel. 125 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (28,9,4,8,2,11,34,9,1700,'SM-9-00012',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 20 TABLETAS','AZITROMICINA DIHIDRATADA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Azitromicina 125 mg para tratamientos cortos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (29,9,4,8,2,12,34,9,1700,'SM-9-00013',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 30 TABLETAS','AZITROMICINA DIHIDRATADA',10.00,1.50,1.19,15.00,11.90,10.00,110.00,15.00,1,0,1,'Tratamiento de 30 tabletas de Azitromicina 125 mg para infecciones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (30,9,4,8,2,13,34,9,1700,'SM-9-00014',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 50 TABLETAS','AZITROMICINA DIHIDRATADA',16.00,1.50,1.19,24.00,19.04,5.00,90.00,10.00,1,0,1,'Formato de 50 tabletas de Azitromicina 125 mg para uso prolongado.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (31,9,6,11,2,10,35,9,1700,'SM-9-00015',NULL,NULL,NULL,NULL,NULL,'CEFALEXINA 250 MG CAJA X 10 TABLETAS','CEFALEXINA MONOHIDRATADA',3.80,1.50,1.19,5.70,4.52,10.00,180.00,20.00,1,0,1,'Cefalosporina de primera generación para infecciones respiratorias y urinarias. 250 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (32,10,2,2,2,10,7,9,1700,'SM-10-00001',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 10 TABLETAS','LORATADINA',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antihistamínico para el alivio de los síntomas de alergia estacional. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (33,10,2,2,2,11,7,9,1700,'SM-10-00002',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 20 TABLETAS','LORATADINA',3.90,1.50,1.19,5.85,4.64,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Loratadina 5 mg para alergias estacionales.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (34,10,2,2,2,12,7,9,1700,'SM-10-00003',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 30 TABLETAS','LORATADINA',5.50,1.50,1.19,8.25,6.55,10.00,130.00,18.00,0,0,1,'Alivio continuo de alergias con 30 tabletas de Loratadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (35,10,3,9,2,10,19,9,1700,'SM-10-00004',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 20 MG CAJA X 10 TABLETAS','CETIRIZINA DIHIDROCLORURO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,20.00,0,0,1,'Antihistamínico de segunda generación para el control de la rinitis alérgica. 20 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (36,10,3,9,2,11,19,9,1700,'SM-10-00005',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 20 MG CAJA X 20 TABLETAS','CETIRIZINA DIHIDROCLORURO',5.40,1.50,1.19,8.10,6.43,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Cetirizina 20 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (37,10,3,9,2,12,19,9,1700,'SM-10-00006',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 20 MG CAJA X 30 TABLETAS','CETIRIZINA DIHIDROCLORURO',7.80,1.50,1.19,11.70,9.28,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Cetirizina 20 mg para síntomas alérgicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (38,10,4,8,2,10,5,9,1700,'SM-10-00007',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 10 TABLETAS','CLORFENIRAMINA MALEATO',1.60,1.50,1.19,2.40,1.90,10.00,200.00,25.00,0,0,1,'Antihistamínico clásico para el alivio de reacciones alérgicas y picazón. 25 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (39,10,4,8,2,11,5,9,1700,'SM-10-00008',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 20 TABLETAS','CLORFENIRAMINA MALEATO',2.90,1.50,1.19,4.35,3.45,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Clorfeniramina 25 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (40,10,4,8,2,12,5,9,1700,'SM-10-00009',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 30 TABLETAS','CLORFENIRAMINA MALEATO',4.00,1.50,1.19,6.00,4.76,10.00,120.00,15.00,0,0,1,'30 tabletas de Clorfeniramina 25 mg para control de alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (41,10,5,10,2,10,21,9,1700,'SM-10-00010',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 1 MG CAJA X 10 TABLETAS','DIFENHIDRAMINA CLORHIDRATO',2.00,1.50,1.19,3.00,2.38,10.00,180.00,22.00,0,0,1,'Antihistamínico con efecto sedante para el alivio de alergias y picazón. 1 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (42,10,5,10,2,11,21,9,1700,'SM-10-00011',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 1 MG CAJA X 20 TABLETAS','DIFENHIDRAMINA CLORHIDRATO',3.60,1.50,1.19,5.40,4.28,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Difenhidramina 1 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (43,10,5,10,2,12,21,9,1700,'SM-10-00012',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 1 MG CAJA X 30 TABLETAS','DIFENHIDRAMINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,110.00,14.00,0,0,1,'30 tabletas de Difenhidramina 1 mg para el control de síntomas alérgicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (44,10,6,11,2,10,33,9,1700,'SM-10-00013',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 0.5 MG CAJA X 10 TABLETAS','DESLORATADINA',2.80,1.50,1.19,4.20,3.33,10.00,170.00,20.00,0,0,1,'Antihistamínico no sedante para rinitis alérgica. 0.5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (45,10,6,11,2,11,33,9,1700,'SM-10-00014',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 0.5 MG CAJA X 20 TABLETAS','DESLORATADINA',5.20,1.50,1.19,7.80,6.19,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Desloratadina 0.5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (46,10,6,11,2,12,33,9,1700,'SM-10-00015',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 0.5 MG CAJA X 30 TABLETAS','DESLORATADINA',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,0,0,1,'Tratamiento continuo con 30 tabletas de Desloratadina 0.5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (47,11,2,2,2,10,3,9,1700,'SM-11-00001',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 10 TABLETAS','IBUPROFENO',2.10,1.50,1.19,3.15,2.50,10.00,200.00,25.00,0,0,1,'Antiinflamatorio no esteroideo para el alivio de la inflamación y el dolor. 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (48,11,2,2,2,11,3,9,1700,'SM-11-00002',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 20 TABLETAS','IBUPROFENO',3.80,1.50,1.19,5.70,4.52,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 100 mg para dolor e inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (49,11,2,2,2,12,3,9,1700,'SM-11-00003',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 30 TABLETAS','IBUPROFENO',5.40,1.50,1.19,8.10,6.43,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Ibuprofeno 100 mg para inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (50,11,3,9,2,10,16,9,1700,'SM-11-00004',NULL,NULL,NULL,NULL,NULL,'DICLOFENACO 200 MG CAJA X 10 TABLETAS','DICLOFENACO SODICO',3.50,1.50,1.19,5.25,4.17,10.00,180.00,22.00,0,0,1,'Antiinflamatorio para artritis y dolor muscular. 200 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (51,11,3,9,2,11,16,9,1700,'SM-11-00005',NULL,NULL,NULL,NULL,NULL,'DICLOFENACO 200 MG CAJA X 20 TABLETAS','DICLOFENACO SODICO',6.40,1.50,1.19,9.60,7.62,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Diclofenaco 200 mg para inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (52,11,3,9,2,12,16,9,1700,'SM-11-00006',NULL,NULL,NULL,NULL,NULL,'DICLOFENACO 200 MG CAJA X 30 TABLETAS','DICLOFENACO SODICO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Diclofenaco 200 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (53,11,4,8,2,10,17,9,1700,'SM-11-00007',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 150 MG CAJA X 10 TABLETAS','NAPROXENO SODICO',2.80,1.50,1.19,4.20,3.33,10.00,190.00,25.00,0,0,1,'Antiinflamatorio para dolor articular y menstrual. 150 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (54,11,4,8,2,11,17,9,1700,'SM-11-00008',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 150 MG CAJA X 20 TABLETAS','NAPROXENO SODICO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Naproxeno 150 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (55,11,4,8,2,12,17,9,1700,'SM-11-00009',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 150 MG CAJA X 30 TABLETAS','NAPROXENO SODICO',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Naproxeno 150 mg para inflamación y dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (56,11,5,10,2,10,2,9,1700,'SM-11-00010',NULL,NULL,NULL,NULL,NULL,'MELOXICAM 500 MG CAJA X 10 TABLETAS','MELOXICAM',4.20,1.50,1.19,6.30,5.00,10.00,170.00,20.00,0,0,1,'Antiinflamatorio selectivo COX-2 para artritis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (57,11,5,10,2,11,2,9,1700,'SM-11-00011',NULL,NULL,NULL,NULL,NULL,'MELOXICAM 500 MG CAJA X 20 TABLETAS','MELOXICAM',7.80,1.50,1.19,11.70,9.28,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Meloxicam 500 mg para artritis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (58,11,5,10,2,12,2,9,1700,'SM-11-00012',NULL,NULL,NULL,NULL,NULL,'MELOXICAM 500 MG CAJA X 30 TABLETAS','MELOXICAM',11.00,1.50,1.19,16.50,13.09,10.00,120.00,15.00,0,0,1,'Tratamiento prolongado con 30 tabletas de Meloxicam 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (59,11,6,11,2,10,32,9,1700,'SM-11-00013',NULL,NULL,NULL,NULL,NULL,'PIROXICAM 2.5 MG CAJA X 10 TABLETAS','PIROXICAM',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,0,0,1,'Antiinflamatorio para artritis reumatoide. 2.5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (60,11,6,11,2,11,32,9,1700,'SM-11-00014',NULL,NULL,NULL,NULL,NULL,'PIROXICAM 2.5 MG CAJA X 20 TABLETAS','PIROXICAM',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Piroxicam 2.5 mg para inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (61,11,6,11,2,12,32,9,1700,'SM-11-00015',NULL,NULL,NULL,NULL,NULL,'PIROXICAM 2.5 MG CAJA X 30 TABLETAS','PIROXICAM',7.80,1.50,1.19,11.70,9.28,10.00,120.00,15.00,0,0,1,'30 tabletas de Piroxicam 2.5 mg para artritis y dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (62,12,2,2,2,10,3,9,1700,'SM-12-00001',NULL,NULL,NULL,NULL,NULL,'OMEPRAZOL 100 MG CAJA X 10 TABLETAS','OMEPRAZOL',3.00,1.50,1.19,4.50,3.57,10.00,180.00,20.00,0,0,1,'Inhibidor de la bomba de protones para el tratamiento de la úlcera gástrica. 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (63,12,2,2,2,11,3,9,1700,'SM-12-00002',NULL,NULL,NULL,NULL,NULL,'OMEPRAZOL 100 MG CAJA X 20 TABLETAS','OMEPRAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Omeprazol 100 mg para acidez estomacal.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (64,12,2,2,2,12,3,9,1700,'SM-12-00003',NULL,NULL,NULL,NULL,NULL,'OMEPRAZOL 100 MG CAJA X 30 TABLETAS','OMEPRAZOL',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Omeprazol 100 mg para reflujo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (65,12,3,9,2,10,28,9,1700,'SM-12-00004',NULL,NULL,NULL,NULL,NULL,'RANITIDINA 40 MG CAJA X 10 TABLETAS','RANITIDINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antagonista H2 para úlceras y reflujo. 40 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (66,12,3,9,2,11,28,9,1700,'SM-12-00005',NULL,NULL,NULL,NULL,NULL,'RANITIDINA 40 MG CAJA X 20 TABLETAS','RANITIDINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Ranitidina 40 mg para acidez.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (67,12,3,9,2,12,28,9,1700,'SM-12-00006',NULL,NULL,NULL,NULL,NULL,'RANITIDINA 40 MG CAJA X 30 TABLETAS','RANITIDINA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,130.00,18.00,0,0,1,'30 tabletas de Ranitidina 40 mg para el tratamiento de úlceras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (68,12,4,8,2,10,29,9,1700,'SM-12-00007',NULL,NULL,NULL,NULL,NULL,'ESOMEPRAZOL 30 MG CAJA X 10 TABLETAS','ESOMEPRAZOL MAGNESICO',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,0,0,1,'Inhibidor de la bomba de protones de última generación. 30 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (69,12,4,8,2,11,29,9,1700,'SM-12-00008',NULL,NULL,NULL,NULL,NULL,'ESOMEPRAZOL 30 MG CAJA X 20 TABLETAS','ESOMEPRAZOL MAGNESICO',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Esomeprazol 30 mg para reflujo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (70,12,4,8,2,12,29,9,1700,'SM-12-00009',NULL,NULL,NULL,NULL,NULL,'ESOMEPRAZOL 30 MG CAJA X 30 TABLETAS','ESOMEPRAZOL MAGNESICO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'Tratamiento continuo con 30 tabletas de Esomeprazol 30 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (71,12,5,10,2,10,19,9,1700,'SM-12-00010',NULL,NULL,NULL,NULL,NULL,'FAMOTIDINA 20 MG CAJA X 10 TABLETAS','FAMOTIDINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antagonista H2 para el control de la secreción ácida. 20 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (72,12,5,10,2,11,19,9,1700,'SM-12-00011',NULL,NULL,NULL,NULL,NULL,'FAMOTIDINA 20 MG CAJA X 20 TABLETAS','FAMOTIDINA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Famotidina 20 mg para úlceras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (73,12,5,10,2,12,19,9,1700,'SM-12-00012',NULL,NULL,NULL,NULL,NULL,'FAMOTIDINA 20 MG CAJA X 30 TABLETAS','FAMOTIDINA',7.00,1.50,1.19,10.50,8.33,10.00,120.00,15.00,0,0,1,'30 tabletas de Famotidina 20 mg para reflujo gastroesofágico.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (74,12,6,11,2,10,4,9,1700,'SM-12-00013',NULL,NULL,NULL,NULL,NULL,'PANTROPRAZOL 50 MG CAJA X 10 TABLETAS','PANTROPRAZOL SODICO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Inhibidor de la bomba de protones para úlceras pépticas. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (75,12,6,11,2,11,4,9,1700,'SM-12-00014',NULL,NULL,NULL,NULL,NULL,'PANTROPRAZOL 50 MG CAJA X 20 TABLETAS','PANTROPRAZOL SODICO',6.30,1.50,1.19,9.45,7.50,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Pantroprazol 50 mg para acidez.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (76,12,6,11,2,12,4,9,1700,'SM-12-00015',NULL,NULL,NULL,NULL,NULL,'PANTROPRAZOL 50 MG CAJA X 30 TABLETAS','PANTROPRAZOL SODICO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,0,0,1,'30 tabletas de Pantroprazol 50 mg para el tratamiento de úlceras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (77,13,2,2,2,10,6,9,1700,'SM-13-00001',NULL,NULL,NULL,NULL,NULL,'BUSCAPINA 10 MG CAJA X 10 TABLETAS','HIDROBROMURO DE HIOSCINA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antiespasmódico para el alivio de cólicos y espasmos gastrointestinales. 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (78,13,2,2,2,11,6,9,1700,'SM-13-00002',NULL,NULL,NULL,NULL,NULL,'BUSCAPINA 10 MG CAJA X 20 TABLETAS','HIDROBROMURO DE HIOSCINA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Buscapina 10 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (79,13,2,2,2,12,6,9,1700,'SM-13-00003',NULL,NULL,NULL,NULL,NULL,'BUSCAPINA 10 MG CAJA X 30 TABLETAS','HIDROBROMURO DE HIOSCINA',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,0,0,1,'30 tabletas de Buscapina 10 mg para el tratamiento de cólicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (80,13,3,9,2,10,3,9,1700,'SM-13-00004',NULL,NULL,NULL,NULL,NULL,'BUTILBROMURO DE HIOSCINA 100 MG CAJA X 10 TABLETAS','BUTILBROMURO DE HIOSCINA',3.80,1.50,1.19,5.70,4.52,10.00,180.00,22.00,0,0,1,'Antiespasmódico para espasmos del tracto gastrointestinal. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (81,13,3,9,2,11,3,9,1700,'SM-13-00005',NULL,NULL,NULL,NULL,NULL,'BUTILBROMURO DE HIOSCINA 100 MG CAJA X 20 TABLETAS','BUTILBROMURO DE HIOSCINA',6.80,1.50,1.19,10.20,8.09,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Butilbromuro de Hiosecina 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (82,13,3,9,2,12,3,9,1700,'SM-13-00006',NULL,NULL,NULL,NULL,NULL,'BUTILBROMURO DE HIOSCINA 100 MG CAJA X 30 TABLETAS','BUTILBROMURO DE HIOSCINA',9.50,1.50,1.19,14.25,11.31,10.00,120.00,15.00,0,0,1,'30 tabletas de Butilbromuro de Hiosecina 100 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (83,13,4,8,2,10,20,9,1700,'SM-13-00007',NULL,NULL,NULL,NULL,NULL,'DROTAVERINA 2 MG CAJA X 10 TABLETAS','DROTAVERINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antiespasmódico para el alivio de dolores abdominales. 2 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (84,13,4,8,2,11,20,9,1700,'SM-13-00008',NULL,NULL,NULL,NULL,NULL,'DROTAVERINA 2 MG CAJA X 20 TABLETAS','DROTAVERINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Drotaverina 2 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (85,13,4,8,2,12,20,9,1700,'SM-13-00009',NULL,NULL,NULL,NULL,NULL,'DROTAVERINA 2 MG CAJA X 30 TABLETAS','DROTAVERINA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,130.00,18.00,0,0,1,'30 tabletas de Drotaverina 2 mg para el alivio de cólicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (86,13,5,10,2,10,21,9,1700,'SM-13-00010',NULL,NULL,NULL,NULL,NULL,'MEPENZOLATO 1 MG CAJA X 10 TABLETAS','MEPENZOLATO BROMURO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antiespasmódico para el tratamiento de úlceras y espasmos. 1 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (87,13,5,10,2,11,21,9,1700,'SM-13-00011',NULL,NULL,NULL,NULL,NULL,'MEPENZOLATO 1 MG CAJA X 20 TABLETAS','MEPENZOLATO BROMURO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Mepenzolato 1 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (88,13,5,10,2,12,21,9,1700,'SM-13-00012',NULL,NULL,NULL,NULL,NULL,'MEPENZOLATO 1 MG CAJA X 30 TABLETAS','MEPENZOLATO BROMURO',7.00,1.50,1.19,10.50,8.33,10.00,120.00,15.00,0,0,1,'30 tabletas de Mepenzolato 1 mg para el alivio de espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (89,13,6,11,2,10,7,9,1700,'SM-13-00013',NULL,NULL,NULL,NULL,NULL,'PRIFINIO 5 MG CAJA X 10 TABLETAS','PRIFINIO BROMURO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antiespasmódico para el alivio de dolores gastrointestinales. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (90,13,6,11,2,11,7,9,1700,'SM-13-00014',NULL,NULL,NULL,NULL,NULL,'PRIFINIO 5 MG CAJA X 20 TABLETAS','PRIFINIO BROMURO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Prifinio 5 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (91,13,6,11,2,12,7,9,1700,'SM-13-00015',NULL,NULL,NULL,NULL,NULL,'PRIFINIO 5 MG CAJA X 30 TABLETAS','PRIFINIO BROMURO',5.50,1.50,1.19,8.25,6.55,10.00,130.00,18.00,0,0,1,'30 tabletas de Prifinio 5 mg para el tratamiento de espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (92,14,2,2,2,10,19,9,1700,'SM-14-00001',NULL,NULL,NULL,NULL,NULL,'FLUOXETINA 20 MG CAJA X 10 TABLETAS','FLUOXETINA CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antidepresivo ISRS para el tratamiento de la depresión y trastornos de ansiedad. 20 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (93,14,2,2,2,11,19,9,1700,'SM-14-00002',NULL,NULL,NULL,NULL,NULL,'FLUOXETINA 20 MG CAJA X 20 TABLETAS','FLUOXETINA CLORHIDRATO',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Fluoxetina 20 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (94,14,2,2,2,12,19,9,1700,'SM-14-00003',NULL,NULL,NULL,NULL,NULL,'FLUOXETINA 20 MG CAJA X 30 TABLETAS','FLUOXETINA CLORHIDRATO',14.00,1.50,1.19,21.00,16.66,10.00,120.00,15.00,1,0,1,'30 tabletas de Fluoxetina 20 mg para el tratamiento de trastornos depresivos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (95,14,3,9,2,10,3,9,1700,'SM-14-00004',NULL,NULL,NULL,NULL,NULL,'SERTRALINA 100 MG CAJA X 10 TABLETAS','SERTRALINA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antidepresivo ISRS para trastorno obsesivo-compulsivo y depresión. 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (96,14,3,9,2,11,3,9,1700,'SM-14-00005',NULL,NULL,NULL,NULL,NULL,'SERTRALINA 100 MG CAJA X 20 TABLETAS','SERTRALINA CLORHIDRATO',11.00,1.50,1.19,16.50,13.09,10.00,130.00,15.00,1,0,1,'Caja de 20 tabletas de Sertralina 100 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (97,14,3,9,2,12,3,9,1700,'SM-14-00006',NULL,NULL,NULL,NULL,NULL,'SERTRALINA 100 MG CAJA X 30 TABLETAS','SERTRALINA CLORHIDRATO',15.50,1.50,1.19,23.25,18.45,10.00,110.00,12.00,1,0,1,'30 tabletas de Sertralina 100 mg para trastornos de ansiedad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (98,14,4,8,2,10,28,9,1700,'SM-14-00007',NULL,NULL,NULL,NULL,NULL,'PAROXETINA 40 MG CAJA X 10 TABLETAS','PAROXETINA CLORHIDRATO',5.80,1.50,1.19,8.70,6.90,10.00,160.00,20.00,1,0,1,'Antidepresivo ISRS para depresión mayor y trastorno de pánico. 40 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (99,14,4,8,2,11,28,9,1700,'SM-14-00008',NULL,NULL,NULL,NULL,NULL,'PAROXETINA 40 MG CAJA X 20 TABLETAS','PAROXETINA CLORHIDRATO',10.50,1.50,1.19,15.75,12.50,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Paroxetina 40 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (100,14,4,8,2,12,28,9,1700,'SM-14-00009',NULL,NULL,NULL,NULL,NULL,'PAROXETINA 40 MG CAJA X 30 TABLETAS','PAROXETINA CLORHIDRATO',14.80,1.50,1.19,22.20,17.61,10.00,120.00,15.00,1,0,1,'30 tabletas de Paroxetina 40 mg para trastornos de ansiedad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (101,14,5,10,2,10,17,9,1700,'SM-14-00010',NULL,NULL,NULL,NULL,NULL,'CITALOPRAM 150 MG CAJA X 10 TABLETAS','CITALOPRAM HIDROBROMURO',6.20,1.50,1.19,9.30,7.38,10.00,150.00,18.00,1,0,1,'Antidepresivo ISRS para depresión y trastorno de pánico. 150 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (102,14,5,10,2,11,17,9,1700,'SM-14-00011',NULL,NULL,NULL,NULL,NULL,'CITALOPRAM 150 MG CAJA X 20 TABLETAS','CITALOPRAM HIDROBROMURO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,15.00,1,0,1,'Caja de 20 tabletas de Citalopram 150 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (103,14,5,10,2,12,17,9,1700,'SM-14-00012',NULL,NULL,NULL,NULL,NULL,'CITALOPRAM 150 MG CAJA X 30 TABLETAS','CITALOPRAM HIDROBROMURO',16.00,1.50,1.19,24.00,19.04,10.00,110.00,12.00,1,0,1,'30 tabletas de Citalopram 150 mg para trastornos depresivos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (104,14,6,11,2,10,29,9,1700,'SM-14-00013',NULL,NULL,NULL,NULL,NULL,'VENLAFAXINA 30 MG CAJA X 10 TABLETAS','VENLAFAXINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,170.00,20.00,1,0,1,'Antidepresivo dual para depresión mayor. 30 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (105,14,6,11,2,11,29,9,1700,'SM-14-00014',NULL,NULL,NULL,NULL,NULL,'VENLAFAXINA 30 MG CAJA X 20 TABLETAS','VENLAFAXINA CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Venlafaxina 30 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (106,14,6,11,2,12,29,9,1700,'SM-14-00015',NULL,NULL,NULL,NULL,NULL,'VENLAFAXINA 30 MG CAJA X 30 TABLETAS','VENLAFAXINA CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Venlafaxina 30 mg para trastornos de ansiedad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (107,15,2,2,2,10,7,9,1700,'SM-15-00001',NULL,NULL,NULL,NULL,NULL,'RISPERIDONA 5 MG CAJA X 10 TABLETAS','RISPERIDONA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,1,1,'Antipsicótico atípico para esquizofrenia y trastorno bipolar. 5 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (108,15,2,2,2,11,7,9,1700,'SM-15-00002',NULL,NULL,NULL,NULL,NULL,'RISPERIDONA 5 MG CAJA X 20 TABLETAS','RISPERIDONA',11.00,1.50,1.19,16.50,13.09,10.00,130.00,15.00,1,1,1,'Caja de 20 tabletas de Risperidona 5 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (109,15,2,2,2,12,7,9,1700,'SM-15-00003',NULL,NULL,NULL,NULL,NULL,'RISPERIDONA 5 MG CAJA X 30 TABLETAS','RISPERIDONA',15.50,1.50,1.19,23.25,18.45,10.00,110.00,12.00,1,1,1,'30 tabletas de Risperidona 5 mg para trastornos psicóticos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (110,15,3,9,2,10,6,9,1700,'SM-15-00004',NULL,NULL,NULL,NULL,NULL,'OLANZAPINA 10 MG CAJA X 10 TABLETAS','OLANZAPINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,1,1,'Antipsicótico atípico para esquizofrenia y trastorno bipolar. 10 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (111,15,3,9,2,11,6,9,1700,'SM-15-00005',NULL,NULL,NULL,NULL,NULL,'OLANZAPINA 10 MG CAJA X 20 TABLETAS','OLANZAPINA',12.50,1.50,1.19,18.75,14.88,10.00,120.00,14.00,1,1,1,'Caja de 20 tabletas de Olanzapina 10 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (112,15,3,9,2,12,6,9,1700,'SM-15-00006',NULL,NULL,NULL,NULL,NULL,'OLANZAPINA 10 MG CAJA X 30 TABLETAS','OLANZAPINA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'30 tabletas de Olanzapina 10 mg para trastornos bipolares.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (113,15,4,8,2,10,3,9,1700,'SM-15-00007',NULL,NULL,NULL,NULL,NULL,'QUETIAPINA 100 MG CAJA X 10 TABLETAS','QUETIAPINA FUMARATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,1,1,'Antipsicótico atípico para esquizofrenia y trastorno bipolar. 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (114,15,4,8,2,11,3,9,1700,'SM-15-00008',NULL,NULL,NULL,NULL,NULL,'QUETIAPINA 100 MG CAJA X 20 TABLETAS','QUETIAPINA FUMARATO',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,1,1,'Caja de 20 tabletas de Quetiapina 100 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (115,15,4,8,2,12,3,9,1700,'SM-15-00009',NULL,NULL,NULL,NULL,NULL,'QUETIAPINA 100 MG CAJA X 30 TABLETAS','QUETIAPINA FUMARATO',14.00,1.50,1.19,21.00,16.66,10.00,120.00,15.00,1,1,1,'30 tabletas de Quetiapina 100 mg para trastornos psicóticos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (116,15,5,10,2,10,19,9,1700,'SM-15-00010',NULL,NULL,NULL,NULL,NULL,'HALOPERIDOL 20 MG CAJA X 10 TABLETAS','HALOPERIDOL',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,1,1,1,'Antipsicótico típico para psicosis y trastornos de conducta. 20 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (117,15,5,10,2,11,19,9,1700,'SM-15-00011',NULL,NULL,NULL,NULL,NULL,'HALOPERIDOL 20 MG CAJA X 20 TABLETAS','HALOPERIDOL',7.20,1.50,1.19,10.80,8.57,10.00,150.00,20.00,1,1,1,'Caja de 20 tabletas de Haloperidol 20 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (118,15,5,10,2,12,19,9,1700,'SM-15-00012',NULL,NULL,NULL,NULL,NULL,'HALOPERIDOL 20 MG CAJA X 30 TABLETAS','HALOPERIDOL',10.00,1.50,1.19,15.00,11.90,10.00,130.00,18.00,1,1,1,'30 tabletas de Haloperidol 20 mg para trastornos psicóticos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (119,15,6,11,2,10,17,9,1700,'SM-15-00013',NULL,NULL,NULL,NULL,NULL,'CLOZAPINA 150 MG CAJA X 10 TABLETAS','CLOZAPINA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Antipsicótico atípico para esquizofrenia resistente. 150 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (120,15,6,11,2,11,17,9,1700,'SM-15-00014',NULL,NULL,NULL,NULL,NULL,'CLOZAPINA 150 MG CAJA X 20 TABLETAS','CLOZAPINA',14.50,1.50,1.19,21.75,17.26,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Clozapina 150 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (121,15,6,11,2,12,17,9,1700,'SM-15-00015',NULL,NULL,NULL,NULL,NULL,'CLOZAPINA 150 MG CAJA X 30 TABLETAS','CLOZAPINA',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Clozapina 150 mg para esquizofrenia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (122,16,2,2,2,10,6,9,1700,'SM-16-00001',NULL,NULL,NULL,NULL,NULL,'METOCLOPRAMIDA 10 MG CAJA X 10 TABLETAS','METOCLOPRAMIDA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antiemético para el control de náuseas y vómitos. 10 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (123,16,2,2,2,11,6,9,1700,'SM-16-00002',NULL,NULL,NULL,NULL,NULL,'METOCLOPRAMIDA 10 MG CAJA X 20 TABLETAS','METOCLOPRAMIDA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Metoclopramida 10 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (124,16,2,2,2,12,6,9,1700,'SM-16-00003',NULL,NULL,NULL,NULL,NULL,'METOCLOPRAMIDA 10 MG CAJA X 30 TABLETAS','METOCLOPRAMIDA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,120.00,15.00,0,0,1,'30 tabletas de Metoclopramida 10 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (125,16,3,9,2,10,29,9,1700,'SM-16-00004',NULL,NULL,NULL,NULL,NULL,'ONDANSETRON 30 MG CAJA X 10 TABLETAS','ONDANSETRON CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Antiemético para quimioterapia y postoperatorio. 30 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (126,16,3,9,2,11,29,9,1700,'SM-16-00005',NULL,NULL,NULL,NULL,NULL,'ONDANSETRON 30 MG CAJA X 20 TABLETAS','ONDANSETRON CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Ondansetron 30 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (127,16,3,9,2,12,29,9,1700,'SM-16-00006',NULL,NULL,NULL,NULL,NULL,'ONDANSETRON 30 MG CAJA X 30 TABLETAS','ONDANSETRON CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,0,0,1,'30 tabletas de Ondansetron 30 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (128,16,4,8,2,10,6,9,1700,'SM-16-00007',NULL,NULL,NULL,NULL,NULL,'DOMPERIDONA 10 MG CAJA X 10 TABLETAS','DOMPERIDONA',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Antiemético para el tratamiento de náuseas y vómitos. 10 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (129,16,4,8,2,11,6,9,1700,'SM-16-00008',NULL,NULL,NULL,NULL,NULL,'DOMPERIDONA 10 MG CAJA X 20 TABLETAS','DOMPERIDONA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Domperidona 10 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (130,16,4,8,2,12,6,9,1700,'SM-16-00009',NULL,NULL,NULL,NULL,NULL,'DOMPERIDONA 10 MG CAJA X 30 TABLETAS','DOMPERIDONA',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Domperidona 10 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (131,16,5,10,2,10,19,9,1700,'SM-16-00010',NULL,NULL,NULL,NULL,NULL,'GRANISETRON 20 MG CAJA X 10 TABLETAS','GRANISETRON CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Antiemético para quimioterapia. 20 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (132,16,5,10,2,11,19,9,1700,'SM-16-00011',NULL,NULL,NULL,NULL,NULL,'GRANISETRON 20 MG CAJA X 20 TABLETAS','GRANISETRON CLORHIDRATO',8.00,1.50,1.19,12.00,9.52,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Granisetron 20 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (133,16,5,10,2,12,19,9,1700,'SM-16-00012',NULL,NULL,NULL,NULL,NULL,'GRANISETRON 20 MG CAJA X 30 TABLETAS','GRANISETRON CLORHIDRATO',11.00,1.50,1.19,16.50,13.09,10.00,120.00,15.00,0,0,1,'30 tabletas de Granisetron 20 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (134,16,6,11,2,10,28,9,1700,'SM-16-00013',NULL,NULL,NULL,NULL,NULL,'APREPITANT 40 MG CAJA X 10 TABLETAS','APREPITANT',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,0,0,1,'Antiemético para quimioterapia de alta emetogenicidad. 40 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (135,16,6,11,2,11,28,9,1700,'SM-16-00014',NULL,NULL,NULL,NULL,NULL,'APREPITANT 40 MG CAJA X 20 TABLETAS','APREPITANT',11.00,1.50,1.19,16.50,13.09,10.00,130.00,15.00,0,0,1,'Caja de 20 tabletas de Aprepitant 40 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (136,16,6,11,2,12,28,9,1700,'SM-16-00015',NULL,NULL,NULL,NULL,NULL,'APREPITANT 40 MG CAJA X 30 TABLETAS','APREPITANT',15.50,1.50,1.19,23.25,18.45,10.00,110.00,12.00,0,0,1,'30 tabletas de Aprepitant 40 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (137,17,2,2,7,20,2,9,1700,'SM-17-00001',NULL,NULL,NULL,NULL,NULL,'CLOTRIMAZOL 500 MG CREMA TUBO X 30 G','CLOTRIMAZOL',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Antifúngico tópico para el tratamiento de dermatofitosis. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (138,17,2,2,7,21,2,9,1700,'SM-17-00002',NULL,NULL,NULL,NULL,NULL,'CLOTRIMAZOL 500 MG CREMA TUBO X 50 G','CLOTRIMAZOL',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Clotrimazol 500 mg para infecciones por hongos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (139,17,2,2,7,20,4,9,1700,'SM-17-00003',NULL,NULL,NULL,NULL,NULL,'CLOTRIMAZOL 50 MG CREMA TUBO X 30 G','CLOTRIMAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Crema de Clotrimazol 50 mg para el tratamiento de hongos en la piel.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (140,17,3,9,7,21,4,9,1700,'SM-17-00004',NULL,NULL,NULL,NULL,NULL,'MICONAZOL 50 MG CREMA TUBO X 50 G','MICONAZOL NITRATO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antifúngico de amplio espectro para infecciones cutáneas. 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (141,17,3,9,7,20,4,9,1700,'SM-17-00005',NULL,NULL,NULL,NULL,NULL,'MICONAZOL 50 MG CREMA TUBO X 30 G','MICONAZOL NITRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Crema de Miconazol 50 mg para el tratamiento de hongos y levaduras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (142,17,3,9,7,20,2,9,1700,'SM-17-00006',NULL,NULL,NULL,NULL,NULL,'KETOCONAZOL 500 MG CREMA TUBO X 30 G','KETOCONAZOL',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Antifúngico para dermatitis seborreica y tiña. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (143,17,3,9,7,21,2,9,1700,'SM-17-00007',NULL,NULL,NULL,NULL,NULL,'KETOCONAZOL 500 MG CREMA TUBO X 50 G','KETOCONAZOL',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Ketoconazol 500 mg para infecciones fúngicas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (144,17,4,8,7,20,5,9,1700,'SM-17-00008',NULL,NULL,NULL,NULL,NULL,'TERBINAFINA 25 MG CREMA TUBO X 30 G','TERBINAFINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,18.00,0,0,1,'Antifúngico para onicomicosis y tiña. 25 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (145,17,4,8,7,21,5,9,1700,'SM-17-00009',NULL,NULL,NULL,NULL,NULL,'TERBINAFINA 25 MG CREMA TUBO X 50 G','TERBINAFINA CLORHIDRATO',7.00,1.50,1.19,10.50,8.33,10.00,130.00,15.00,0,0,1,'Tubo de 50 g de Terbinafina 25 mg para hongos en las uñas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (146,17,4,8,7,20,2,9,1700,'SM-17-00010',NULL,NULL,NULL,NULL,NULL,'FLUCONAZOL 500 MG CREMA TUBO X 30 G','FLUCONAZOL',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Antifúngico sistémico para candidiasis. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (147,17,4,8,7,21,2,9,1700,'SM-17-00011',NULL,NULL,NULL,NULL,NULL,'FLUCONAZOL 500 MG CREMA TUBO X 50 G','FLUCONAZOL',5.80,1.50,1.19,8.70,6.90,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Fluconazol 500 mg para infecciones por hongos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (148,17,5,10,7,20,3,9,1700,'SM-17-00012',NULL,NULL,NULL,NULL,NULL,'ITRACONAZOL 100 MG CREMA TUBO X 30 G','ITRACONAZOL',4.20,1.50,1.19,6.30,5.00,10.00,150.00,18.00,0,0,1,'Antifúngico para dermatofitosis y onicomicosis. 100 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (149,17,5,10,7,21,3,9,1700,'SM-17-00013',NULL,NULL,NULL,NULL,NULL,'ITRACONAZOL 100 MG CREMA TUBO X 50 G','ITRACONAZOL',6.50,1.50,1.19,9.75,7.74,10.00,130.00,15.00,0,0,1,'Tubo de 50 g de Itraconazol 100 mg para hongos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (150,17,6,11,7,20,8,9,1700,'SM-17-00014',NULL,NULL,NULL,NULL,NULL,'VORICONAZOL 750 MG CREMA TUBO X 30 G','VORICONAZOL',5.00,1.50,1.19,7.50,5.95,10.00,140.00,16.00,0,0,1,'Antifúngico de amplio espectro para infecciones graves. 750 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (151,17,6,11,7,21,8,9,1700,'SM-17-00015',NULL,NULL,NULL,NULL,NULL,'VORICONAZOL 750 MG CREMA TUBO X 50 G','VORICONAZOL',7.80,1.50,1.19,11.70,9.28,10.00,120.00,14.00,0,0,1,'Tubo de 50 g de Voriconazol 750 mg para infecciones fúngicas graves.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (152,18,2,2,2,10,3,9,1700,'SM-18-00001',NULL,NULL,NULL,NULL,NULL,'ACICLOVIR 100 MG CAJA X 10 TABLETAS','ACICLOVIR',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Antiviral para el tratamiento del herpes simple y varicela. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (153,18,2,2,2,11,3,9,1700,'SM-18-00002',NULL,NULL,NULL,NULL,NULL,'ACICLOVIR 100 MG CAJA X 20 TABLETAS','ACICLOVIR',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Aciclovir 100 mg para herpes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (154,18,2,2,2,12,3,9,1700,'SM-18-00003',NULL,NULL,NULL,NULL,NULL,'ACICLOVIR 100 MG CAJA X 30 TABLETAS','ACICLOVIR',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Aciclovir 100 mg para herpes zoster.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (155,18,3,9,2,10,3,9,1700,'SM-18-00004',NULL,NULL,NULL,NULL,NULL,'VALACICLOVIR 100 MG CAJA X 10 TABLETAS','VALACICLOVIR CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Antiviral para el herpes labial y genital. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (156,18,3,9,2,11,3,9,1700,'SM-18-00005',NULL,NULL,NULL,NULL,NULL,'VALACICLOVIR 100 MG CAJA X 20 TABLETAS','VALACICLOVIR CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Valaciclovir 100 mg para herpes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (157,18,3,9,2,12,3,9,1700,'SM-18-00006',NULL,NULL,NULL,NULL,NULL,'VALACICLOVIR 100 MG CAJA X 30 TABLETAS','VALACICLOVIR CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Valaciclovir 100 mg para herpes zoster.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (158,18,4,8,2,10,35,9,1700,'SM-18-00007',NULL,NULL,NULL,NULL,NULL,'FAMCICLOVIR 250 MG CAJA X 10 TABLETAS','FAMCICLOVIR',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,1,0,1,'Antiviral para herpes simple y zoster. 250 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (159,18,4,8,2,11,35,9,1700,'SM-18-00008',NULL,NULL,NULL,NULL,NULL,'FAMCICLOVIR 250 MG CAJA X 20 TABLETAS','FAMCICLOVIR',8.50,1.50,1.19,12.75,10.12,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Famciclovir 250 mg para herpes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (160,18,4,8,2,12,35,9,1700,'SM-18-00009',NULL,NULL,NULL,NULL,NULL,'FAMCICLOVIR 250 MG CAJA X 30 TABLETAS','FAMCICLOVIR',12.00,1.50,1.19,18.00,14.28,10.00,120.00,15.00,1,0,1,'30 tabletas de Famciclovir 250 mg para herpes zoster.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (161,18,5,10,2,10,6,9,1700,'SM-18-00010',NULL,NULL,NULL,NULL,NULL,'RIBAVIRINA 10 MG CAJA X 10 TABLETAS','RIBAVIRINA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antiviral para hepatitis C y fiebre hemorrágica. 10 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (162,18,5,10,2,11,6,9,1700,'SM-18-00011',NULL,NULL,NULL,NULL,NULL,'RIBAVIRINA 10 MG CAJA X 20 TABLETAS','RIBAVIRINA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Ribavirina 10 mg para hepatitis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (163,18,5,10,2,12,6,9,1700,'SM-18-00012',NULL,NULL,NULL,NULL,NULL,'RIBAVIRINA 10 MG CAJA X 30 TABLETAS','RIBAVIRINA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Ribavirina 10 mg para infecciones virales.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (164,18,6,11,2,10,3,9,1700,'SM-18-00013',NULL,NULL,NULL,NULL,NULL,'OSELTAMIVIR 100 MG CAJA X 10 TABLETAS','OSELTAMIVIR FOSFATO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Antiviral para el tratamiento de la gripe tipo A y B. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (165,18,6,11,2,11,3,9,1700,'SM-18-00014',NULL,NULL,NULL,NULL,NULL,'OSELTAMIVIR 100 MG CAJA X 20 TABLETAS','OSELTAMIVIR FOSFATO',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Oseltamivir 100 mg para influenza.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (166,18,6,11,2,12,3,9,1700,'SM-18-00015',NULL,NULL,NULL,NULL,NULL,'OSELTAMIVIR 100 MG CAJA X 30 TABLETAS','OSELTAMIVIR FOSFATO',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,0,1,'30 tabletas de Oseltamivir 100 mg para el tratamiento de la gripe.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (167,19,2,2,20,19,4,9,1700,'SM-19-00001',NULL,NULL,NULL,NULL,NULL,'SALBUTAMOL 50 MG INHALADOR 200 DOSIS','SALBUTAMOL SULFATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Broncodilatador para el alivio del asma y EPOC. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (168,19,2,2,20,19,4,9,1700,'SM-19-00002',NULL,NULL,NULL,NULL,NULL,'SALBUTAMOL 50 MG INHALADOR 300 DOSIS','SALBUTAMOL SULFATO',8.50,1.50,1.19,12.75,10.12,10.00,130.00,15.00,1,0,1,'Inhalador de Salbutamol 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (169,19,3,9,20,19,4,9,1700,'SM-19-00003',NULL,NULL,NULL,NULL,NULL,'BUDESONIDA 50 MG INHALADOR 200 DOSIS','BUDESONIDA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Corticoide inhalado para el asma. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (170,19,3,9,20,19,4,9,1700,'SM-19-00004',NULL,NULL,NULL,NULL,NULL,'BUDESONIDA 50 MG INHALADOR 300 DOSIS','BUDESONIDA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,0,1,'Inhalador de Budesonida 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (171,19,4,8,20,19,4,9,1700,'SM-19-00005',NULL,NULL,NULL,NULL,NULL,'FORMOTEROL 50 MG INHALADOR 200 DOSIS','FORMOTEROL FUMARATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Broncodilatador de larga duración para EPOC. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (172,19,4,8,20,19,4,9,1700,'SM-19-00006',NULL,NULL,NULL,NULL,NULL,'FORMOTEROL 50 MG INHALADOR 300 DOSIS','FORMOTEROL FUMARATO',11.50,1.50,1.19,17.25,13.68,10.00,110.00,12.00,1,0,1,'Inhalador de Formoterol 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (173,19,5,10,20,19,5,9,1700,'SM-19-00007',NULL,NULL,NULL,NULL,NULL,'TIOTROPIO 25 MG INHALADOR 200 DOSIS','TIOTROPIO BROMURO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,0,1,'Broncodilatador de larga duración para EPOC. 25 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (174,19,5,10,20,19,5,9,1700,'SM-19-00008',NULL,NULL,NULL,NULL,NULL,'TIOTROPIO 25 MG INHALADOR 300 DOSIS','TIOTROPIO BROMURO',13.00,1.50,1.19,19.50,15.47,10.00,100.00,10.00,1,0,1,'Inhalador de Tiotropio 25 mg con 300 dosis para EPOC.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (175,19,6,11,20,19,4,9,1700,'SM-19-00009',NULL,NULL,NULL,NULL,NULL,'FLUTICASONA 50 MG INHALADOR 200 DOSIS','FLUTICASONA PROPIONATO',7.50,1.50,1.19,11.25,8.93,10.00,130.00,15.00,1,0,1,'Corticoide inhalado para asma. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (176,19,6,11,20,19,4,9,1700,'SM-19-00010',NULL,NULL,NULL,NULL,NULL,'FLUTICASONA 50 MG INHALADOR 300 DOSIS','FLUTICASONA PROPIONATO',10.50,1.50,1.19,15.75,12.50,10.00,110.00,12.00,1,0,1,'Inhalador de Fluticasona 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (177,19,2,2,20,19,3,9,1700,'SM-19-00011',NULL,NULL,NULL,NULL,NULL,'SALMETEROL 100 MG INHALADOR 200 DOSIS','SALMETEROL XINAFOATO',8.50,1.50,1.19,12.75,10.12,10.00,120.00,14.00,1,0,1,'Broncodilatador de larga duración para asma. 100 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (178,19,2,2,20,19,3,9,1700,'SM-19-00012',NULL,NULL,NULL,NULL,NULL,'SALMETEROL 100 MG INHALADOR 300 DOSIS','SALMETEROL XINAFOATO',12.00,1.50,1.19,18.00,14.28,10.00,100.00,10.00,1,0,1,'Inhalador de Salmeterol 100 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (179,19,3,9,20,19,4,9,1700,'SM-19-00013',NULL,NULL,NULL,NULL,NULL,'BECLOMETASONA 50 MG INHALADOR 200 DOSIS','BECLOMETASONA DIPROPIONATO',6.50,1.50,1.19,9.75,7.74,10.00,140.00,16.00,1,0,1,'Corticoide inhalado para asma. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (180,19,3,9,20,19,4,9,1700,'SM-19-00014',NULL,NULL,NULL,NULL,NULL,'BECLOMETASONA 50 MG INHALADOR 300 DOSIS','BECLOMETASONA DIPROPIONATO',9.50,1.50,1.19,14.25,11.31,10.00,120.00,14.00,1,0,1,'Inhalador de Beclometasona 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (181,19,4,8,20,19,3,9,1700,'SM-19-00015',NULL,NULL,NULL,NULL,NULL,'VILANTEROL 100 MG INHALADOR 200 DOSIS','VILANTEROL TRIFENATATO',10.00,1.50,1.19,15.00,11.90,10.00,110.00,12.00,1,0,1,'Broncodilatador de larga duración para EPOC. 100 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (182,20,2,2,2,10,28,9,1700,'SM-20-00001',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 40 MG CAJA X 10 TABLETAS','PREDNISONA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,20.00,1,0,1,'Corticoide para enfermedades inflamatorias y autoinmunes. 40 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (183,20,2,2,2,11,28,9,1700,'SM-20-00002',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 40 MG CAJA X 20 TABLETAS','PREDNISONA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Prednisona 40 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (184,20,2,2,2,12,28,9,1700,'SM-20-00003',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 40 MG CAJA X 30 TABLETAS','PREDNISONA',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,1,0,1,'30 tabletas de Prednisona 40 mg para enfermedades autoinmunes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (185,20,3,9,2,10,4,9,1700,'SM-20-00004',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 50 MG CAJA X 10 TABLETAS','DEXAMETASONA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,1,0,1,'Corticoide para inflamación y alergias. 50 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (186,20,3,9,2,11,4,9,1700,'SM-20-00005',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 50 MG CAJA X 20 TABLETAS','DEXAMETASONA',6.30,1.50,1.19,9.45,7.50,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Dexametasona 50 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (187,20,3,9,2,12,4,9,1700,'SM-20-00006',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 50 MG CAJA X 30 TABLETAS','DEXAMETASONA',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,1,0,1,'30 tabletas de Dexametasona 50 mg para alergias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (188,20,4,8,2,10,7,9,1700,'SM-20-00007',NULL,NULL,NULL,NULL,NULL,'METILPREDNISOLONA 5 MG CAJA X 10 TABLETAS','METILPREDNISOLONA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Corticoide para enfermedades inflamatorias. 5 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (189,20,4,8,2,11,7,9,1700,'SM-20-00008',NULL,NULL,NULL,NULL,NULL,'METILPREDNISOLONA 5 MG CAJA X 20 TABLETAS','METILPREDNISOLONA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Metilprednisolona 5 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (190,20,4,8,2,12,7,9,1700,'SM-20-00009',NULL,NULL,NULL,NULL,NULL,'METILPREDNISOLONA 5 MG CAJA X 30 TABLETAS','METILPREDNISOLONA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Metilprednisolona 5 mg para enfermedades autoinmunes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (191,20,5,10,2,10,2,9,1700,'SM-20-00010',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CAJA X 10 TABLETAS','HIDROCORTISONA',3.80,1.50,1.19,5.70,4.52,10.00,170.00,22.00,1,0,1,'Corticoide para insuficiencia suprarrenal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (192,20,5,10,2,11,2,9,1700,'SM-20-00011',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CAJA X 20 TABLETAS','HIDROCORTISONA',6.80,1.50,1.19,10.20,8.09,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Hidrocortisona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (193,20,5,10,2,12,2,9,1700,'SM-20-00012',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CAJA X 30 TABLETAS','HIDROCORTISONA',9.50,1.50,1.19,14.25,11.31,10.00,130.00,16.00,1,0,1,'30 tabletas de Hidrocortisona 500 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (194,20,6,11,2,10,4,9,1700,'SM-20-00013',NULL,NULL,NULL,NULL,NULL,'BETAMETASONA 50 MG CAJA X 10 TABLETAS','BETAMETASONA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,1,0,1,'Corticoide para alergias e inflamación. 50 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (195,20,6,11,2,11,4,9,1700,'SM-20-00014',NULL,NULL,NULL,NULL,NULL,'BETAMETASONA 50 MG CAJA X 20 TABLETAS','BETAMETASONA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Betametasona 50 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (196,20,6,11,2,12,4,9,1700,'SM-20-00015',NULL,NULL,NULL,NULL,NULL,'BETAMETASONA 50 MG CAJA X 30 TABLETAS','BETAMETASONA',8.00,1.50,1.19,12.00,9.52,10.00,120.00,15.00,1,0,1,'30 tabletas de Betametasona 50 mg para alergias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (197,21,2,2,2,10,2,9,1700,'SM-21-00001',NULL,NULL,NULL,NULL,NULL,'FUROSEMIDA 500 MG CAJA X 10 TABLETAS','FUROSEMIDA',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,1,0,1,'Diurético para el tratamiento de la hipertensión y edema. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (198,21,2,2,2,11,2,9,1700,'SM-21-00002',NULL,NULL,NULL,NULL,NULL,'FUROSEMIDA 500 MG CAJA X 20 TABLETAS','FUROSEMIDA',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Furosemida 500 mg para edema.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (199,21,2,2,2,12,2,9,1700,'SM-21-00003',NULL,NULL,NULL,NULL,NULL,'FUROSEMIDA 500 MG CAJA X 30 TABLETAS','FUROSEMIDA',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,1,0,1,'30 tabletas de Furosemida 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (200,21,3,9,2,10,3,9,1700,'SM-21-00004',NULL,NULL,NULL,NULL,NULL,'HIDROCLOROTIAZIDA 100 MG CAJA X 10 TABLETAS','HIDROCLOROTIAZIDA',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Diurético para la hipertensión. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (201,21,3,9,2,11,3,9,1700,'SM-21-00005',NULL,NULL,NULL,NULL,NULL,'HIDROCLOROTIAZIDA 100 MG CAJA X 20 TABLETAS','HIDROCLOROTIAZIDA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Hidroclorotiazida 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (202,21,3,9,2,12,3,9,1700,'SM-21-00006',NULL,NULL,NULL,NULL,NULL,'HIDROCLOROTIAZIDA 100 MG CAJA X 30 TABLETAS','HIDROCLOROTIAZIDA',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Hidroclorotiazida 100 mg para hipertensión.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (203,21,4,8,2,10,2,9,1700,'SM-21-00007',NULL,NULL,NULL,NULL,NULL,'ESPIRONOLACTONA 500 MG CAJA X 10 TABLETAS','ESPIRONOLACTONA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Diurético ahorrador de potasio para insuficiencia cardíaca. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (204,21,4,8,2,11,2,9,1700,'SM-21-00008',NULL,NULL,NULL,NULL,NULL,'ESPIRONOLACTONA 500 MG CAJA X 20 TABLETAS','ESPIRONOLACTONA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Espironolactona 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (205,21,4,8,2,12,2,9,1700,'SM-21-00009',NULL,NULL,NULL,NULL,NULL,'ESPIRONOLACTONA 500 MG CAJA X 30 TABLETAS','ESPIRONOLACTONA',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,0,0,1,'30 tabletas de Espironolactona 500 mg para edema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (206,21,5,10,2,10,2,9,1700,'SM-21-00010',NULL,NULL,NULL,NULL,NULL,'TORASEMIDA 500 MG CAJA X 10 TABLETAS','TORASEMIDA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Diurético para hipertensión y edema. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (207,21,5,10,2,11,2,9,1700,'SM-21-00011',NULL,NULL,NULL,NULL,NULL,'TORASEMIDA 500 MG CAJA X 20 TABLETAS','TORASEMIDA',6.30,1.50,1.19,9.45,7.50,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Torasemida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (208,21,5,10,2,12,2,9,1700,'SM-21-00012',NULL,NULL,NULL,NULL,NULL,'TORASEMIDA 500 MG CAJA X 30 TABLETAS','TORASEMIDA',8.80,1.50,1.19,13.20,10.47,10.00,120.00,15.00,0,0,1,'30 tabletas de Torasemida 500 mg para insuficiencia cardíaca.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (209,21,6,11,2,10,4,9,1700,'SM-21-00013',NULL,NULL,NULL,NULL,NULL,'INDAPAMIDA 50 MG CAJA X 10 TABLETAS','INDAPAMIDA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Diurético para hipertensión. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (210,21,6,11,2,11,4,9,1700,'SM-21-00014',NULL,NULL,NULL,NULL,NULL,'INDAPAMIDA 50 MG CAJA X 20 TABLETAS','INDAPAMIDA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Indapamida 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (211,21,6,11,2,12,4,9,1700,'SM-21-00015',NULL,NULL,NULL,NULL,NULL,'INDAPAMIDA 50 MG CAJA X 30 TABLETAS','INDAPAMIDA',7.00,1.50,1.19,10.50,8.33,10.00,130.00,16.00,0,0,1,'30 tabletas de Indapamida 50 mg para hipertensión.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (212,22,2,2,2,10,7,9,1700,'SM-22-00001',NULL,NULL,NULL,NULL,NULL,'BISACODILO 5 MG CAJA X 10 TABLETAS','BISACODILO',1.80,1.50,1.19,2.70,2.14,10.00,190.00,25.00,0,0,1,'Laxante para el estreñimiento ocasional. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (213,22,2,2,2,11,7,9,1700,'SM-22-00002',NULL,NULL,NULL,NULL,NULL,'BISACODILO 5 MG CAJA X 20 TABLETAS','BISACODILO',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Bisacodilo 5 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (214,22,2,2,2,12,7,9,1700,'SM-22-00003',NULL,NULL,NULL,NULL,NULL,'BISACODILO 5 MG CAJA X 30 TABLETAS','BISACODILO',4.50,1.50,1.19,6.75,5.36,10.00,130.00,18.00,0,0,1,'30 tabletas de Bisacodilo 5 mg para el estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (215,22,3,9,8,20,3,9,1700,'SM-22-00004',NULL,NULL,NULL,NULL,NULL,'LACTULOSA 100 MG UNGÜENTO TUBO X 30 G','LACTULOSA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Laxante para el estreñimiento. 100 mg en ungüento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (216,22,3,9,8,21,3,9,1700,'SM-22-00005',NULL,NULL,NULL,NULL,NULL,'LACTULOSA 100 MG UNGÜENTO TUBO X 50 G','LACTULOSA',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Lactulosa 100 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (217,22,4,8,2,10,2,9,1700,'SM-22-00006',NULL,NULL,NULL,NULL,NULL,'SENÓSIDOS 500 MG CAJA X 10 TABLETAS','SENÓSIDOS',2.20,1.50,1.19,3.30,2.62,10.00,180.00,22.00,0,0,1,'Laxante natural para el estreñimiento. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (218,22,4,8,2,11,2,9,1700,'SM-22-00007',NULL,NULL,NULL,NULL,NULL,'SENÓSIDOS 500 MG CAJA X 20 TABLETAS','SENÓSIDOS',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Senósidos 500 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (219,22,4,8,2,12,2,9,1700,'SM-22-00008',NULL,NULL,NULL,NULL,NULL,'SENÓSIDOS 500 MG CAJA X 30 TABLETAS','SENÓSIDOS',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Senósidos 500 mg para el estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (220,22,5,10,2,10,4,9,1700,'SM-22-00009',NULL,NULL,NULL,NULL,NULL,'POLIETILENGLICOL 50 MG CAJA X 10 TABLETAS','POLIETILENGLICOL',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Laxante osmótico para el estreñimiento. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (221,22,5,10,2,11,4,9,1700,'SM-22-00010',NULL,NULL,NULL,NULL,NULL,'POLIETILENGLICOL 50 MG CAJA X 20 TABLETAS','POLIETILENGLICOL',5.00,1.50,1.19,7.50,5.95,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Polietilenglicol 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (222,22,5,10,2,12,4,9,1700,'SM-22-00011',NULL,NULL,NULL,NULL,NULL,'POLIETILENGLICOL 50 MG CAJA X 30 TABLETAS','POLIETILENGLICOL',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Polietilenglicol 50 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (223,22,6,11,2,10,4,9,1700,'SM-22-00012',NULL,NULL,NULL,NULL,NULL,'PICOSULFATO 50 MG CAJA X 10 TABLETAS','PICOSULFATO SODICO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Laxante para el estreñimiento. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (224,22,6,11,2,11,4,9,1700,'SM-22-00013',NULL,NULL,NULL,NULL,NULL,'PICOSULFATO 50 MG CAJA X 20 TABLETAS','PICOSULFATO SODICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Picosulfato 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (225,22,6,11,2,12,4,9,1700,'SM-22-00014',NULL,NULL,NULL,NULL,NULL,'PICOSULFATO 50 MG CAJA X 30 TABLETAS','PICOSULFATO SODICO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Picosulfato 50 mg para el estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (226,23,2,2,2,10,2,9,1700,'SM-23-00001',NULL,NULL,NULL,NULL,NULL,'VITAMINA C 500 MG CAJA X 10 TABLETAS','ACIDO ASCORBICO',2.00,1.50,1.19,3.00,2.38,10.00,200.00,25.00,0,0,1,'Vitamina C para el sistema inmunológico. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (227,23,2,2,2,11,2,9,1700,'SM-23-00002',NULL,NULL,NULL,NULL,NULL,'VITAMINA C 500 MG CAJA X 20 TABLETAS','ACIDO ASCORBICO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Vitamina C 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (228,23,2,2,2,12,2,9,1700,'SM-23-00003',NULL,NULL,NULL,NULL,NULL,'VITAMINA C 500 MG CAJA X 30 TABLETAS','ACIDO ASCORBICO',5.00,1.50,1.19,7.50,5.95,10.00,130.00,18.00,0,0,1,'30 tabletas de Vitamina C 500 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (229,23,3,9,2,10,3,9,1700,'SM-23-00004',NULL,NULL,NULL,NULL,NULL,'VITAMINA D 100 MG CAJA X 10 TABLETAS','COLECALCIFEROL',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,0,0,1,'Vitamina D para la salud ósea. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (230,23,3,9,2,11,3,9,1700,'SM-23-00005',NULL,NULL,NULL,NULL,NULL,'VITAMINA D 100 MG CAJA X 20 TABLETAS','COLECALCIFEROL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Vitamina D 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (231,23,3,9,2,12,3,9,1700,'SM-23-00006',NULL,NULL,NULL,NULL,NULL,'VITAMINA D 100 MG CAJA X 30 TABLETAS','COLECALCIFEROL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,18.00,0,0,1,'30 tabletas de Vitamina D 100 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (232,23,4,8,2,10,3,9,1700,'SM-23-00007',NULL,NULL,NULL,NULL,NULL,'VITAMINA E 100 MG CAJA X 10 TABLETAS','ALFA TOCOFEROL',2.80,1.50,1.19,4.20,3.33,10.00,170.00,20.00,0,0,1,'Vitamina E antioxidante. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (233,23,4,8,2,11,3,9,1700,'SM-23-00008',NULL,NULL,NULL,NULL,NULL,'VITAMINA E 100 MG CAJA X 20 TABLETAS','ALFA TOCOFEROL',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Vitamina E 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (234,23,4,8,2,12,3,9,1700,'SM-23-00009',NULL,NULL,NULL,NULL,NULL,'VITAMINA E 100 MG CAJA X 30 TABLETAS','ALFA TOCOFEROL',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Vitamina E 100 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (235,23,5,10,2,10,6,9,1700,'SM-23-00010',NULL,NULL,NULL,NULL,NULL,'VITAMINA A 10 MG CAJA X 10 TABLETAS','RETINOL',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Vitamina A para la salud de la piel y visión. 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (236,23,5,10,2,11,6,9,1700,'SM-23-00011',NULL,NULL,NULL,NULL,NULL,'VITAMINA A 10 MG CAJA X 20 TABLETAS','RETINOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Vitamina A 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (237,23,5,10,2,12,6,9,1700,'SM-23-00012',NULL,NULL,NULL,NULL,NULL,'VITAMINA A 10 MG CAJA X 30 TABLETAS','RETINOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Vitamina A 10 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (238,23,6,11,2,10,4,9,1700,'SM-23-00013',NULL,NULL,NULL,NULL,NULL,'COMPLEJO B 50 MG CAJA X 10 TABLETAS','COMPLEJO DE VITAMINAS B',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,0,0,1,'Complejo B para el sistema nervioso y energía. 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (239,23,6,11,2,11,4,9,1700,'SM-23-00014',NULL,NULL,NULL,NULL,NULL,'COMPLEJO B 50 MG CAJA X 20 TABLETAS','COMPLEJO DE VITAMINAS B',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Complejo B 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (240,23,6,11,2,12,4,9,1700,'SM-23-00015',NULL,NULL,NULL,NULL,NULL,'COMPLEJO B 50 MG CAJA X 30 TABLETAS','COMPLEJO DE VITAMINAS B',8.00,1.50,1.19,12.00,9.52,10.00,130.00,18.00,0,0,1,'30 tabletas de Complejo B 50 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (241,24,2,2,2,10,3,9,1700,'SM-24-00001',NULL,NULL,NULL,NULL,NULL,'OMEGA 3 100 MG CAJA X 10 TABLETAS','ACEITE DE PESCADO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Suplemento de omega 3 para la salud cardiovascular. 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (242,24,2,2,2,11,3,9,1700,'SM-24-00002',NULL,NULL,NULL,NULL,NULL,'OMEGA 3 100 MG CAJA X 20 TABLETAS','ACEITE DE PESCADO',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Omega 3 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (243,24,2,2,2,12,3,9,1700,'SM-24-00003',NULL,NULL,NULL,NULL,NULL,'OMEGA 3 100 MG CAJA X 30 TABLETAS','ACEITE DE PESCADO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'30 tabletas de Omega 3 100 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (244,24,3,9,2,10,3,9,1700,'SM-24-00004',NULL,NULL,NULL,NULL,NULL,'GLUCOSAMINA 100 MG CAJA X 10 TABLETAS','GLUCOSAMINA SULFATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Suplemento para la salud articular. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (245,24,3,9,2,11,3,9,1700,'SM-24-00005',NULL,NULL,NULL,NULL,NULL,'GLUCOSAMINA 100 MG CAJA X 20 TABLETAS','GLUCOSAMINA SULFATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,0,0,1,'Caja de 20 tabletas de Glucosamina 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (246,24,3,9,2,12,3,9,1700,'SM-24-00006',NULL,NULL,NULL,NULL,NULL,'GLUCOSAMINA 100 MG CAJA X 30 TABLETAS','GLUCOSAMINA SULFATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,0,0,1,'30 tabletas de Glucosamina 100 mg para articulaciones.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (247,24,4,8,2,10,2,9,1700,'SM-24-00007',NULL,NULL,NULL,NULL,NULL,'MAGNESIO 500 MG CAJA X 10 TABLETAS','MAGNESIO OXIDO',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,0,0,1,'Suplemento de magnesio para el sistema nervioso. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (248,24,4,8,2,11,2,9,1700,'SM-24-00008',NULL,NULL,NULL,NULL,NULL,'MAGNESIO 500 MG CAJA X 20 TABLETAS','MAGNESIO OXIDO',5.40,1.50,1.19,8.10,6.43,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Magnesio 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (249,24,4,8,2,12,2,9,1700,'SM-24-00009',NULL,NULL,NULL,NULL,NULL,'MAGNESIO 500 MG CAJA X 30 TABLETAS','MAGNESIO OXIDO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,18.00,0,0,1,'30 tabletas de Magnesio 500 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (250,24,5,10,2,10,2,9,1700,'SM-24-00010',NULL,NULL,NULL,NULL,NULL,'ZINC 500 MG CAJA X 10 TABLETAS','ZINC GLUCONATO',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Suplemento de zinc para el sistema inmunológico. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (251,24,5,10,2,11,2,9,1700,'SM-24-00011',NULL,NULL,NULL,NULL,NULL,'ZINC 500 MG CAJA X 20 TABLETAS','ZINC GLUCONATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Zinc 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (252,24,5,10,2,12,2,9,1700,'SM-24-00012',NULL,NULL,NULL,NULL,NULL,'ZINC 500 MG CAJA X 30 TABLETAS','ZINC GLUCONATO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Zinc 500 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (253,24,6,11,2,10,4,9,1700,'SM-24-00013',NULL,NULL,NULL,NULL,NULL,'CALCIO 50 MG CAJA X 10 TABLETAS','CALCIO CARBONATO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Suplemento de calcio para la salud ósea. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (254,24,6,11,2,11,4,9,1700,'SM-24-00014',NULL,NULL,NULL,NULL,NULL,'CALCIO 50 MG CAJA X 20 TABLETAS','CALCIO CARBONATO',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Calcio 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (255,24,6,11,2,12,4,9,1700,'SM-24-00015',NULL,NULL,NULL,NULL,NULL,'CALCIO 50 MG CAJA X 30 TABLETAS','CALCIO CARBONATO',8.80,1.50,1.19,13.20,10.47,10.00,130.00,18.00,0,0,1,'30 tabletas de Calcio 50 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (256,25,2,2,2,10,2,9,1700,'SM-25-00001',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 10 TABLETAS','PARACETAMOL',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Antipirético y analgésico para el alivio de la fiebre. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (257,25,2,2,2,11,2,9,1700,'SM-25-00002',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 20 TABLETAS','PARACETAMOL',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Paracetamol 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (258,25,2,2,2,12,2,9,1700,'SM-25-00003',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 30 TABLETAS','PARACETAMOL',4.50,1.50,1.19,6.75,5.36,10.00,130.00,18.00,0,0,1,'30 tabletas de Paracetamol 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (259,25,3,9,2,10,2,9,1700,'SM-25-00004',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antipirético y antiinflamatorio. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (260,25,3,9,2,11,2,9,1700,'SM-25-00005',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Aspirina 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (261,25,3,9,2,12,2,9,1700,'SM-25-00006',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Aspirina 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (262,25,4,8,2,10,2,9,1700,'SM-25-00007',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 10 TABLETAS','METAMIZOL SODICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antipirético y analgésico para el alivio del dolor y la fiebre. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (263,25,4,8,2,11,2,9,1700,'SM-25-00008',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 20 TABLETAS','METAMIZOL SODICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Metamizol 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (264,25,4,8,2,12,2,9,1700,'SM-25-00009',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 30 TABLETAS','METAMIZOL SODICO',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Metamizol 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (265,25,5,10,2,10,2,9,1700,'SM-25-00010',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 10 TABLETAS','IBUPROFENO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antipirético y antiinflamatorio. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (266,25,5,10,2,11,2,9,1700,'SM-25-00011',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 20 TABLETAS','IBUPROFENO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (267,25,5,10,2,12,2,9,1700,'SM-25-00012',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 30 TABLETAS','IBUPROFENO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Ibuprofeno 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (268,25,6,11,2,10,2,9,1700,'SM-25-00013',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 10 TABLETAS','NAPROXENO SODICO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antipirético y antiinflamatorio. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (269,25,6,11,2,11,2,9,1700,'SM-25-00014',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 20 TABLETAS','NAPROXENO SODICO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Naproxeno 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (270,25,6,11,2,12,2,9,1700,'SM-25-00015',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 30 TABLETAS','NAPROXENO SODICO',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Naproxeno 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (271,26,2,2,4,18,3,9,1700,'SM-26-00001',NULL,NULL,NULL,NULL,NULL,'DEXTROMETORFANO 100 MG JARABE FRASCO X 100 ML','DEXTROMETORFANO HIDROBROMURO',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Antitusivo para el alivio de la tos seca. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (272,26,2,2,4,19,3,9,1700,'SM-26-00002',NULL,NULL,NULL,NULL,NULL,'DEXTROMETORFANO 100 MG JARABE FRASCO X 250 ML','DEXTROMETORFANO HIDROBROMURO',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de Dextrometorfano 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (273,26,3,9,4,18,4,9,1700,'SM-26-00003',NULL,NULL,NULL,NULL,NULL,'CLOPERASTINA 50 MG JARABE FRASCO X 100 ML','CLOPERASTINA CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Antitusivo para la tos seca. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (274,26,3,9,4,19,4,9,1700,'SM-26-00004',NULL,NULL,NULL,NULL,NULL,'CLOPERASTINA 50 MG JARABE FRASCO X 250 ML','CLOPERASTINA CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Cloperastina 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (275,26,4,8,4,18,3,9,1700,'SM-26-00005',NULL,NULL,NULL,NULL,NULL,'BENZONATATO 100 MG JARABE FRASCO X 100 ML','BENZONATATO',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Antitusivo para la tos seca. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (276,26,4,8,4,19,3,9,1700,'SM-26-00006',NULL,NULL,NULL,NULL,NULL,'BENZONATATO 100 MG JARABE FRASCO X 250 ML','BENZONATATO',6.50,1.50,1.19,9.75,7.74,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de Benzonatato 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (277,26,5,10,4,18,4,9,1700,'SM-26-00007',NULL,NULL,NULL,NULL,NULL,'LEVODROPROPIZINA 50 MG JARABE FRASCO X 100 ML','LEVODROPROPIZINA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antitusivo para la tos seca. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (278,26,5,10,4,19,4,9,1700,'SM-26-00008',NULL,NULL,NULL,NULL,NULL,'LEVODROPROPIZINA 50 MG JARABE FRASCO X 250 ML','LEVODROPROPIZINA',5.20,1.50,1.19,7.80,6.19,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Levodropropizina 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (279,26,6,11,4,18,4,9,1700,'SM-26-00009',NULL,NULL,NULL,NULL,NULL,'DROPROPIZINA 50 MG JARABE FRASCO X 100 ML','DROPROPIZINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antitusivo para la tos seca. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (280,26,6,11,4,19,4,9,1700,'SM-26-00010',NULL,NULL,NULL,NULL,NULL,'DROPROPIZINA 50 MG JARABE FRASCO X 250 ML','DROPROPIZINA',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,0,0,1,'Frasco de 250 ml de Dropropizina 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (281,27,2,2,4,18,3,9,1700,'SM-27-00001',NULL,NULL,NULL,NULL,NULL,'GUAIFENESINA 100 MG JARABE FRASCO X 100 ML','GUAIFENESINA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Expectorante para la tos productiva. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (282,27,2,2,4,19,3,9,1700,'SM-27-00002',NULL,NULL,NULL,NULL,NULL,'GUAIFENESINA 100 MG JARABE FRASCO X 250 ML','GUAIFENESINA',5.20,1.50,1.19,7.80,6.19,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Guaifenesina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (283,27,3,9,4,18,3,9,1700,'SM-27-00003',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 100 ML','BROMHEXINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Expectorante para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (284,27,3,9,4,19,3,9,1700,'SM-27-00004',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 250 ML','BROMHEXINA CLORHIDRATO',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,0,0,1,'Frasco de 250 ml de Bromhexina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (285,27,4,8,4,18,4,9,1700,'SM-27-00005',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 100 ML','AMBROXOL CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Expectorante para la tos productiva. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (286,27,4,8,4,19,4,9,1700,'SM-27-00006',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 250 ML','AMBROXOL CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Ambroxol 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (287,27,5,10,4,18,3,9,1700,'SM-27-00007',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 100 ML','N-ACETILCISTEINA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Expectorante para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (288,27,5,10,4,19,3,9,1700,'SM-27-00008',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 250 ML','N-ACETILCISTEINA',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de N-Acetilcisteina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (289,27,6,11,4,18,5,9,1700,'SM-27-00009',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 100 ML','CARBOCISTEINA',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Expectorante para la tos. 25 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (290,27,6,11,4,19,5,9,1700,'SM-27-00010',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 250 ML','CARBOCISTEINA',4.20,1.50,1.19,6.30,5.00,10.00,170.00,22.00,0,0,1,'Frasco de 250 ml de Carbocisteina 25 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (291,28,2,2,4,18,3,9,1700,'SM-28-00001',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 100 ML','BROMHEXINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Mucolítico para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (292,28,2,2,4,19,3,9,1700,'SM-28-00002',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 250 ML','BROMHEXINA CLORHIDRATO',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,0,0,1,'Frasco de 250 ml de Bromhexina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (293,28,3,9,4,18,4,9,1700,'SM-28-00003',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 100 ML','AMBROXOL CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Mucolítico para la tos productiva. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (294,28,3,9,4,19,4,9,1700,'SM-28-00004',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 250 ML','AMBROXOL CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Ambroxol 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (295,28,4,8,4,18,3,9,1700,'SM-28-00005',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 100 ML','N-ACETILCISTEINA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Mucolítico para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (296,28,4,8,4,19,3,9,1700,'SM-28-00006',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 250 ML','N-ACETILCISTEINA',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de N-Acetilcisteina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (297,28,5,10,4,18,5,9,1700,'SM-28-00007',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 100 ML','CARBOCISTEINA',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Mucolítico para la tos. 25 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (298,28,5,10,4,19,5,9,1700,'SM-28-00008',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 250 ML','CARBOCISTEINA',4.20,1.50,1.19,6.30,5.00,10.00,170.00,22.00,0,0,1,'Frasco de 250 ml de Carbocisteina 25 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (299,28,6,11,4,18,4,9,1700,'SM-28-00009',NULL,NULL,NULL,NULL,NULL,'MESNA 50 MG JARABE FRASCO X 100 ML','MESNA',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Mucolítico para la tos. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (300,28,6,11,4,19,4,9,1700,'SM-28-00010',NULL,NULL,NULL,NULL,NULL,'MESNA 50 MG JARABE FRASCO X 250 ML','MESNA',6.50,1.50,1.19,9.75,7.74,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de Mesna 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (301,29,2,2,2,10,3,9,1700,'SM-29-00001',NULL,NULL,NULL,NULL,NULL,'CARBAMAZEPINA 100 MG CAJA X 10 TABLETAS','CARBAMAZEPINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Anticonvulsivante para epilepsia y neuralgia. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (302,29,2,2,2,11,3,9,1700,'SM-29-00002',NULL,NULL,NULL,NULL,NULL,'CARBAMAZEPINA 100 MG CAJA X 20 TABLETAS','CARBAMAZEPINA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Carbamazepina 100 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (303,29,2,2,2,12,3,9,1700,'SM-29-00003',NULL,NULL,NULL,NULL,NULL,'CARBAMAZEPINA 100 MG CAJA X 30 TABLETAS','CARBAMAZEPINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Carbamazepina 100 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (304,29,3,9,2,10,6,9,1700,'SM-29-00004',NULL,NULL,NULL,NULL,NULL,'FENITOINA 10 MG CAJA X 10 TABLETAS','FENITOINA SODICA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Anticonvulsivante para epilepsia. 10 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (305,29,3,9,2,11,6,9,1700,'SM-29-00005',NULL,NULL,NULL,NULL,NULL,'FENITOINA 10 MG CAJA X 20 TABLETAS','FENITOINA SODICA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Fenitoina 10 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (306,29,3,9,2,12,6,9,1700,'SM-29-00006',NULL,NULL,NULL,NULL,NULL,'FENITOINA 10 MG CAJA X 30 TABLETAS','FENITOINA SODICA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Fenitoina 10 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (307,29,4,8,2,10,2,9,1700,'SM-29-00007',NULL,NULL,NULL,NULL,NULL,'VALPROATO 500 MG CAJA X 10 TABLETAS','VALPROATO SODICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Anticonvulsivante para epilepsia y trastorno bipolar. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (308,29,4,8,2,11,2,9,1700,'SM-29-00008',NULL,NULL,NULL,NULL,NULL,'VALPROATO 500 MG CAJA X 20 TABLETAS','VALPROATO SODICO',8.10,1.50,1.19,12.15,9.64,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Valproato 500 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (309,29,4,8,2,12,2,9,1700,'SM-29-00009',NULL,NULL,NULL,NULL,NULL,'VALPROATO 500 MG CAJA X 30 TABLETAS','VALPROATO SODICO',11.50,1.50,1.19,17.25,13.68,10.00,120.00,15.00,1,0,1,'30 tabletas de Valproato 500 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (310,29,5,10,2,10,7,9,1700,'SM-29-00010',NULL,NULL,NULL,NULL,NULL,'LAMOTRIGINA 5 MG CAJA X 10 TABLETAS','LAMOTRIGINA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Anticonvulsivante para epilepsia. 5 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (311,29,5,10,2,11,7,9,1700,'SM-29-00011',NULL,NULL,NULL,NULL,NULL,'LAMOTRIGINA 5 MG CAJA X 20 TABLETAS','LAMOTRIGINA',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Lamotrigina 5 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (312,29,5,10,2,12,7,9,1700,'SM-29-00012',NULL,NULL,NULL,NULL,NULL,'LAMOTRIGINA 5 MG CAJA X 30 TABLETAS','LAMOTRIGINA',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Lamotrigina 5 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (313,29,6,11,2,10,2,9,1700,'SM-29-00013',NULL,NULL,NULL,NULL,NULL,'TOPIRAMATO 500 MG CAJA X 10 TABLETAS','TOPIRAMATO',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,1,0,1,'Anticonvulsivante para epilepsia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (314,29,6,11,2,11,2,9,1700,'SM-29-00014',NULL,NULL,NULL,NULL,NULL,'TOPIRAMATO 500 MG CAJA X 20 TABLETAS','TOPIRAMATO',8.60,1.50,1.19,12.90,10.23,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Topiramato 500 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (315,29,6,11,2,12,2,9,1700,'SM-29-00015',NULL,NULL,NULL,NULL,NULL,'TOPIRAMATO 500 MG CAJA X 30 TABLETAS','TOPIRAMATO',12.00,1.50,1.19,18.00,14.28,10.00,120.00,15.00,1,0,1,'30 tabletas de Topiramato 500 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (316,30,2,2,2,10,2,9,1700,'SM-30-00001',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 10 TABLETAS','METFORMINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,1,0,1,'Hipoglucemiante para la diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (317,30,2,2,2,11,2,9,1700,'SM-30-00002',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 20 TABLETAS','METFORMINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Metformina 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (318,30,2,2,2,12,2,9,1700,'SM-30-00003',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 30 TABLETAS','METFORMINA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,1,0,1,'30 tabletas de Metformina 500 mg para la diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (319,30,3,9,2,10,2,9,1700,'SM-30-00004',NULL,NULL,NULL,NULL,NULL,'GLIBENCLAMIDA 500 MG CAJA X 10 TABLETAS','GLIBENCLAMIDA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (320,30,3,9,2,11,2,9,1700,'SM-30-00005',NULL,NULL,NULL,NULL,NULL,'GLIBENCLAMIDA 500 MG CAJA X 20 TABLETAS','GLIBENCLAMIDA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Glibenclamida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (321,30,3,9,2,12,2,9,1700,'SM-30-00006',NULL,NULL,NULL,NULL,NULL,'GLIBENCLAMIDA 500 MG CAJA X 30 TABLETAS','GLIBENCLAMIDA',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,1,0,1,'30 tabletas de Glibenclamida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (322,30,4,8,2,10,2,9,1700,'SM-30-00007',NULL,NULL,NULL,NULL,NULL,'GLICLAZIDA 500 MG CAJA X 10 TABLETAS','GLICLAZIDA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (323,30,4,8,2,11,2,9,1700,'SM-30-00008',NULL,NULL,NULL,NULL,NULL,'GLICLAZIDA 500 MG CAJA X 20 TABLETAS','GLICLAZIDA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Gliclazida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (324,30,4,8,2,12,2,9,1700,'SM-30-00009',NULL,NULL,NULL,NULL,NULL,'GLICLAZIDA 500 MG CAJA X 30 TABLETAS','GLICLAZIDA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,1,0,1,'30 tabletas de Gliclazida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (325,30,5,10,2,10,3,9,1700,'SM-30-00010',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 100 MG CAJA X 10 TABLETAS','PIOGLITAZONA CLORHIDRATO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (326,30,5,10,2,11,3,9,1700,'SM-30-00011',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 100 MG CAJA X 20 TABLETAS','PIOGLITAZONA CLORHIDRATO',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Pioglitazona 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (327,30,5,10,2,12,3,9,1700,'SM-30-00012',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 100 MG CAJA X 30 TABLETAS','PIOGLITAZONA CLORHIDRATO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Pioglitazona 100 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (328,30,6,11,2,10,5,9,1700,'SM-30-00013',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 25 MG CAJA X 10 TABLETAS','REPAGLINIDA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 25 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (329,30,6,11,2,11,5,9,1700,'SM-30-00014',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 25 MG CAJA X 20 TABLETAS','REPAGLINIDA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Repaglinida 25 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (330,30,6,11,2,12,5,9,1700,'SM-30-00015',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 25 MG CAJA X 30 TABLETAS','REPAGLINIDA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Repaglinida 25 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (331,31,2,2,2,10,2,9,1700,'SM-31-00001',NULL,NULL,NULL,NULL,NULL,'ENALAPRIL 500 MG CAJA X 10 TABLETAS','ENALAPRIL MALEATO',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,1,0,1,'Hipotensor para la hipertensión arterial. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (332,31,2,2,2,11,2,9,1700,'SM-31-00002',NULL,NULL,NULL,NULL,NULL,'ENALAPRIL 500 MG CAJA X 20 TABLETAS','ENALAPRIL MALEATO',5.40,1.50,1.19,8.10,6.43,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Enalapril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (333,31,2,2,2,12,2,9,1700,'SM-31-00003',NULL,NULL,NULL,NULL,NULL,'ENALAPRIL 500 MG CAJA X 30 TABLETAS','ENALAPRIL MALEATO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,18.00,1,0,1,'30 tabletas de Enalapril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (334,31,3,9,2,10,2,9,1700,'SM-31-00004',NULL,NULL,NULL,NULL,NULL,'LISINOPRIL 500 MG CAJA X 10 TABLETAS','LISINOPRIL DIHIDRATADO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,1,0,1,'Hipotensor para hipertensión y insuficiencia cardíaca. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (335,31,3,9,2,11,2,9,1700,'SM-31-00005',NULL,NULL,NULL,NULL,NULL,'LISINOPRIL 500 MG CAJA X 20 TABLETAS','LISINOPRIL DIHIDRATADO',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Lisinopril 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (336,31,3,9,2,12,2,9,1700,'SM-31-00006',NULL,NULL,NULL,NULL,NULL,'LISINOPRIL 500 MG CAJA X 30 TABLETAS','LISINOPRIL DIHIDRATADO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,1,0,1,'30 tabletas de Lisinopril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (337,31,4,8,2,10,2,9,1700,'SM-31-00007',NULL,NULL,NULL,NULL,NULL,'LOSARTAN 500 MG CAJA X 10 TABLETAS','LOSARTAN POTASICO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,1,0,1,'Hipotensor para hipertensión. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (338,31,4,8,2,11,2,9,1700,'SM-31-00008',NULL,NULL,NULL,NULL,NULL,'LOSARTAN 500 MG CAJA X 20 TABLETAS','LOSARTAN POTASICO',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Losartan 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (339,31,4,8,2,12,2,9,1700,'SM-31-00009',NULL,NULL,NULL,NULL,NULL,'LOSARTAN 500 MG CAJA X 30 TABLETAS','LOSARTAN POTASICO',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Losartan 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (340,31,5,10,2,10,2,9,1700,'SM-31-00010',NULL,NULL,NULL,NULL,NULL,'VALSARTAN 500 MG CAJA X 10 TABLETAS','VALSARTAN',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Hipotensor para hipertensión. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (341,31,5,10,2,11,2,9,1700,'SM-31-00011',NULL,NULL,NULL,NULL,NULL,'VALSARTAN 500 MG CAJA X 20 TABLETAS','VALSARTAN',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Valsartan 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (342,31,5,10,2,12,2,9,1700,'SM-31-00012',NULL,NULL,NULL,NULL,NULL,'VALSARTAN 500 MG CAJA X 30 TABLETAS','VALSARTAN',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Valsartan 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (343,31,6,11,2,10,2,9,1700,'SM-31-00013',NULL,NULL,NULL,NULL,NULL,'CAPTOPRIL 500 MG CAJA X 10 TABLETAS','CAPTOPRIL',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,1,0,1,'Hipotensor para hipertensión. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (344,31,6,11,2,11,2,9,1700,'SM-31-00014',NULL,NULL,NULL,NULL,NULL,'CAPTOPRIL 500 MG CAJA X 20 TABLETAS','CAPTOPRIL',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Captopril 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (345,31,6,11,2,12,2,9,1700,'SM-31-00015',NULL,NULL,NULL,NULL,NULL,'CAPTOPRIL 500 MG CAJA X 30 TABLETAS','CAPTOPRIL',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,1,0,1,'30 tabletas de Captopril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (346,32,2,2,2,10,2,9,1700,'SM-32-00001',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 10 TABLETAS','NITROGLICERINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Vasodilatador para la angina de pecho. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (347,32,2,2,2,11,2,9,1700,'SM-32-00002',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 20 TABLETAS','NITROGLICERINA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Nitroglicerina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (348,32,2,2,2,12,2,9,1700,'SM-32-00003',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 30 TABLETAS','NITROGLICERINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Nitroglicerina 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (349,32,3,9,2,10,2,9,1700,'SM-32-00004',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 10 TABLETAS','DINITRATO DE ISOSORBIDE',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Vasodilatador para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (350,32,3,9,2,11,2,9,1700,'SM-32-00005',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 20 TABLETAS','DINITRATO DE ISOSORBIDE',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Isosorbide 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (351,32,3,9,2,12,2,9,1700,'SM-32-00006',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 30 TABLETAS','DINITRATO DE ISOSORBIDE',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Isosorbide 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (352,32,4,8,2,10,2,9,1700,'SM-32-00007',NULL,NULL,NULL,NULL,NULL,'NITROPRUSIATO 500 MG CAJA X 10 TABLETAS','NITROPRUSIATO SODICO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Vasodilatador para crisis hipertensivas. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (353,32,4,8,2,11,2,9,1700,'SM-32-00008',NULL,NULL,NULL,NULL,NULL,'NITROPRUSIATO 500 MG CAJA X 20 TABLETAS','NITROPRUSIATO SODICO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Nitroprusiato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (354,32,4,8,2,12,2,9,1700,'SM-32-00009',NULL,NULL,NULL,NULL,NULL,'NITROPRUSIATO 500 MG CAJA X 30 TABLETAS','NITROPRUSIATO SODICO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Nitroprusiato 500 mg para emergencias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (355,32,5,10,2,10,2,9,1700,'SM-32-00010',NULL,NULL,NULL,NULL,NULL,'PENTAERITRITOL 500 MG CAJA X 10 TABLETAS','TETRANITRATO DE PENTAERITRITOL',3.80,1.50,1.19,5.70,4.52,10.00,170.00,22.00,1,0,1,'Vasodilatador para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (356,32,5,10,2,11,2,9,1700,'SM-32-00011',NULL,NULL,NULL,NULL,NULL,'PENTAERITRITOL 500 MG CAJA X 20 TABLETAS','TETRANITRATO DE PENTAERITRITOL',6.80,1.50,1.19,10.20,8.09,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Pentaeritritol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (357,32,5,10,2,12,2,9,1700,'SM-32-00012',NULL,NULL,NULL,NULL,NULL,'PENTAERITRITOL 500 MG CAJA X 30 TABLETAS','TETRANITRATO DE PENTAERITRITOL',9.50,1.50,1.19,14.25,11.31,10.00,130.00,16.00,1,0,1,'30 tabletas de Pentaeritritol 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (358,32,6,11,2,10,2,9,1700,'SM-32-00013',NULL,NULL,NULL,NULL,NULL,'NITRATO DE AMILO 500 MG CAJA X 10 TABLETAS','NITRATO DE AMILO',4.20,1.50,1.19,6.30,5.00,10.00,160.00,20.00,1,0,1,'Vasodilatador para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (359,32,6,11,2,11,2,9,1700,'SM-32-00014',NULL,NULL,NULL,NULL,NULL,'NITRATO DE AMILO 500 MG CAJA X 20 TABLETAS','NITRATO DE AMILO',7.60,1.50,1.19,11.40,9.04,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Nitrato de Amilo 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (360,32,6,11,2,12,2,9,1700,'SM-32-00015',NULL,NULL,NULL,NULL,NULL,'NITRATO DE AMILO 500 MG CAJA X 30 TABLETAS','NITRATO DE AMILO',10.50,1.50,1.19,15.75,12.50,10.00,120.00,15.00,1,0,1,'30 tabletas de Nitrato de Amilo 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (361,33,2,2,2,10,2,9,1700,'SM-33-00001',NULL,NULL,NULL,NULL,NULL,'HEPARINA 500 MG CAJA X 10 TABLETAS','HEPARINA SODICA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Anticoagulante para la prevención de trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (362,33,2,2,2,11,2,9,1700,'SM-33-00002',NULL,NULL,NULL,NULL,NULL,'HEPARINA 500 MG CAJA X 20 TABLETAS','HEPARINA SODICA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Heparina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (363,33,2,2,2,12,2,9,1700,'SM-33-00003',NULL,NULL,NULL,NULL,NULL,'HEPARINA 500 MG CAJA X 30 TABLETAS','HEPARINA SODICA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Heparina 500 mg para trombosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (364,33,3,9,2,10,2,9,1700,'SM-33-00004',NULL,NULL,NULL,NULL,NULL,'WARFARINA 500 MG CAJA X 10 TABLETAS','WARFARINA SODICA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Anticoagulante para la prevención de embolias. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (365,33,3,9,2,11,2,9,1700,'SM-33-00005',NULL,NULL,NULL,NULL,NULL,'WARFARINA 500 MG CAJA X 20 TABLETAS','WARFARINA SODICA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Warfarina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (366,33,3,9,2,12,2,9,1700,'SM-33-00006',NULL,NULL,NULL,NULL,NULL,'WARFARINA 500 MG CAJA X 30 TABLETAS','WARFARINA SODICA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Warfarina 500 mg para anticoagulación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (367,33,4,8,2,10,2,9,1700,'SM-33-00007',NULL,NULL,NULL,NULL,NULL,'ENOXAPARINA 500 MG CAJA X 10 TABLETAS','ENOXAPARINA SODICA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Anticoagulante para trombosis venosa profunda. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (368,33,4,8,2,11,2,9,1700,'SM-33-00008',NULL,NULL,NULL,NULL,NULL,'ENOXAPARINA 500 MG CAJA X 20 TABLETAS','ENOXAPARINA SODICA',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Enoxaparina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (369,33,4,8,2,12,2,9,1700,'SM-33-00009',NULL,NULL,NULL,NULL,NULL,'ENOXAPARINA 500 MG CAJA X 30 TABLETAS','ENOXAPARINA SODICA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,0,1,'30 tabletas de Enoxaparina 500 mg para trombosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (370,33,5,10,2,10,2,9,1700,'SM-33-00010',NULL,NULL,NULL,NULL,NULL,'DABIGATRAN 500 MG CAJA X 10 TABLETAS','DABIGATRAN ETEXILATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Anticoagulante para prevención de ictus. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (371,33,5,10,2,11,2,9,1700,'SM-33-00011',NULL,NULL,NULL,NULL,NULL,'DABIGATRAN 500 MG CAJA X 20 TABLETAS','DABIGATRAN ETEXILATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,0,1,'Caja de 20 tabletas de Dabigatran 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (372,33,5,10,2,12,2,9,1700,'SM-33-00012',NULL,NULL,NULL,NULL,NULL,'DABIGATRAN 500 MG CAJA X 30 TABLETAS','DABIGATRAN ETEXILATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,0,1,'30 tabletas de Dabigatran 500 mg para anticoagulación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (373,33,6,11,2,10,2,9,1700,'SM-33-00013',NULL,NULL,NULL,NULL,NULL,'RIVAROXABAN 500 MG CAJA X 10 TABLETAS','RIVAROXABAN',7.50,1.50,1.19,11.25,8.93,10.00,140.00,16.00,1,0,1,'Anticoagulante para trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (374,33,6,11,2,11,2,9,1700,'SM-33-00014',NULL,NULL,NULL,NULL,NULL,'RIVAROXABAN 500 MG CAJA X 20 TABLETAS','RIVAROXABAN',13.50,1.50,1.19,20.25,16.07,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Rivaroxaban 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (375,33,6,11,2,12,2,9,1700,'SM-33-00015',NULL,NULL,NULL,NULL,NULL,'RIVAROXABAN 500 MG CAJA X 30 TABLETAS','RIVAROXABAN',19.00,1.50,1.19,28.50,22.61,10.00,100.00,10.00,1,0,1,'30 tabletas de Rivaroxaban 500 mg para trombosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (376,34,2,2,2,10,2,9,1700,'SM-34-00001',NULL,NULL,NULL,NULL,NULL,'CLOPIDOGREL 500 MG CAJA X 10 TABLETAS','CLOPIDOGREL BISULFATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Antiagregante para la prevención de eventos cardiovasculares. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (377,34,2,2,2,11,2,9,1700,'SM-34-00002',NULL,NULL,NULL,NULL,NULL,'CLOPIDOGREL 500 MG CAJA X 20 TABLETAS','CLOPIDOGREL BISULFATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Clopidogrel 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (378,34,2,2,2,12,2,9,1700,'SM-34-00003',NULL,NULL,NULL,NULL,NULL,'CLOPIDOGREL 500 MG CAJA X 30 TABLETAS','CLOPIDOGREL BISULFATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Clopidogrel 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (379,34,3,9,2,10,2,9,1700,'SM-34-00004',NULL,NULL,NULL,NULL,NULL,'TICAGRELOR 500 MG CAJA X 10 TABLETAS','TICAGRELOR',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antiagregante para síndrome coronario agudo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (380,34,3,9,2,11,2,9,1700,'SM-34-00005',NULL,NULL,NULL,NULL,NULL,'TICAGRELOR 500 MG CAJA X 20 TABLETAS','TICAGRELOR',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Ticagrelor 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (381,34,3,9,2,12,2,9,1700,'SM-34-00006',NULL,NULL,NULL,NULL,NULL,'TICAGRELOR 500 MG CAJA X 30 TABLETAS','TICAGRELOR',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Ticagrelor 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (382,34,4,8,2,10,2,9,1700,'SM-34-00007',NULL,NULL,NULL,NULL,NULL,'PRASUGREL 500 MG CAJA X 10 TABLETAS','PRASUGREL',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antiagregante para prevención de trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (383,34,4,8,2,11,2,9,1700,'SM-34-00008',NULL,NULL,NULL,NULL,NULL,'PRASUGREL 500 MG CAJA X 20 TABLETAS','PRASUGREL',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Prasugrel 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (384,34,4,8,2,12,2,9,1700,'SM-34-00009',NULL,NULL,NULL,NULL,NULL,'PRASUGREL 500 MG CAJA X 30 TABLETAS','PRASUGREL',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Prasugrel 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (385,34,5,10,2,10,2,9,1700,'SM-34-00010',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antiagregante en dosis bajas para prevención cardiovascular. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (386,34,5,10,2,11,2,9,1700,'SM-34-00011',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Aspirina 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (387,34,5,10,2,12,2,9,1700,'SM-34-00012',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Aspirina 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (388,34,6,11,2,10,2,9,1700,'SM-34-00013',NULL,NULL,NULL,NULL,NULL,'DIPIRIDAMOL 500 MG CAJA X 10 TABLETAS','DIPIRIDAMOL',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Antiagregante para prevención de trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (389,34,6,11,2,11,2,9,1700,'SM-34-00014',NULL,NULL,NULL,NULL,NULL,'DIPIRIDAMOL 500 MG CAJA X 20 TABLETAS','DIPIRIDAMOL',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Dipiridamol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (390,34,6,11,2,12,2,9,1700,'SM-34-00015',NULL,NULL,NULL,NULL,NULL,'DIPIRIDAMOL 500 MG CAJA X 30 TABLETAS','DIPIRIDAMOL',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Dipiridamol 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (391,35,2,2,2,10,2,9,1700,'SM-35-00001',NULL,NULL,NULL,NULL,NULL,'SULFATO FERROSO 500 MG CAJA X 10 TABLETAS','SULFATO FERROSO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antianémico para la anemia ferropénica. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (392,35,2,2,2,11,2,9,1700,'SM-35-00002',NULL,NULL,NULL,NULL,NULL,'SULFATO FERROSO 500 MG CAJA X 20 TABLETAS','SULFATO FERROSO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Sulfato Ferroso 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (393,35,2,2,2,12,2,9,1700,'SM-35-00003',NULL,NULL,NULL,NULL,NULL,'SULFATO FERROSO 500 MG CAJA X 30 TABLETAS','SULFATO FERROSO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Sulfato Ferroso 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (394,35,3,9,2,10,2,9,1700,'SM-35-00004',NULL,NULL,NULL,NULL,NULL,'ACIDO FOLICO 500 MG CAJA X 10 TABLETAS','ACIDO FOLICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antianémico para la prevención de defectos del tubo neural. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (395,35,3,9,2,11,2,9,1700,'SM-35-00005',NULL,NULL,NULL,NULL,NULL,'ACIDO FOLICO 500 MG CAJA X 20 TABLETAS','ACIDO FOLICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Acido Folico 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (396,35,3,9,2,12,2,9,1700,'SM-35-00006',NULL,NULL,NULL,NULL,NULL,'ACIDO FOLICO 500 MG CAJA X 30 TABLETAS','ACIDO FOLICO',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Acido Folico 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (397,35,4,8,2,10,2,9,1700,'SM-35-00007',NULL,NULL,NULL,NULL,NULL,'VITAMINA B12 500 MG CAJA X 10 TABLETAS','CIANOCOBALAMINA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antianémico para la anemia megaloblástica. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (398,35,4,8,2,11,2,9,1700,'SM-35-00008',NULL,NULL,NULL,NULL,NULL,'VITAMINA B12 500 MG CAJA X 20 TABLETAS','CIANOCOBALAMINA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Vitamina B12 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (399,35,4,8,2,12,2,9,1700,'SM-35-00009',NULL,NULL,NULL,NULL,NULL,'VITAMINA B12 500 MG CAJA X 30 TABLETAS','CIANOCOBALAMINA',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Vitamina B12 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (400,35,5,10,2,10,2,9,1700,'SM-35-00010',NULL,NULL,NULL,NULL,NULL,'HIERRO POLIMALTOSA 500 MG CAJA X 10 TABLETAS','HIERRO POLIMALTOSA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antianémico de alta tolerancia para anemia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (401,35,5,10,2,11,2,9,1700,'SM-35-00011',NULL,NULL,NULL,NULL,NULL,'HIERRO POLIMALTOSA 500 MG CAJA X 20 TABLETAS','HIERRO POLIMALTOSA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Hierro Polimaltosa 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (402,35,5,10,2,12,2,9,1700,'SM-35-00012',NULL,NULL,NULL,NULL,NULL,'HIERRO POLIMALTOSA 500 MG CAJA X 30 TABLETAS','HIERRO POLIMALTOSA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Hierro Polimaltosa 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (403,35,6,11,2,10,2,9,1700,'SM-35-00013',NULL,NULL,NULL,NULL,NULL,'ERYTHROPOYETIN 500 MG CAJA X 10 TABLETAS','ERYTHROPOYETIN',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,0,0,1,'Antianémico para anemia renal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (404,35,6,11,2,11,2,9,1700,'SM-35-00014',NULL,NULL,NULL,NULL,NULL,'ERYTHROPOYETIN 500 MG CAJA X 20 TABLETAS','ERYTHROPOYETIN',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,0,0,1,'Caja de 20 tabletas de Erythropoyetin 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (405,35,6,11,2,12,2,9,1700,'SM-35-00015',NULL,NULL,NULL,NULL,NULL,'ERYTHROPOYETIN 500 MG CAJA X 30 TABLETAS','ERYTHROPOYETIN',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,0,0,1,'30 tabletas de Erythropoyetin 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (406,36,2,2,2,10,2,9,1700,'SM-36-00001',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 10 TABLETAS','ALBENDAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antiparasitario para lombrices y helmintos. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (407,36,2,2,2,11,2,9,1700,'SM-36-00002',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 20 TABLETAS','ALBENDAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Albendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (408,36,2,2,2,12,2,9,1700,'SM-36-00003',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 30 TABLETAS','ALBENDAZOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Albendazol 500 mg para parasitosis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (409,36,3,9,2,10,2,9,1700,'SM-36-00004',NULL,NULL,NULL,NULL,NULL,'PAMOATO DE PIRANTEL 500 MG CAJA X 10 TABLETAS','PAMOATO DE PIRANTEL',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antiparasitario para oxiuros y ascárides. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (410,36,3,9,2,11,2,9,1700,'SM-36-00005',NULL,NULL,NULL,NULL,NULL,'PAMOATO DE PIRANTEL 500 MG CAJA X 20 TABLETAS','PAMOATO DE PIRANTEL',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Pamoato de Pirantel 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (411,36,3,9,2,12,2,9,1700,'SM-36-00006',NULL,NULL,NULL,NULL,NULL,'PAMOATO DE PIRANTEL 500 MG CAJA X 30 TABLETAS','PAMOATO DE PIRANTEL',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Pamoato de Pirantel 500 mg para parásitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (412,36,4,8,2,10,2,9,1700,'SM-36-00007',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 10 TABLETAS','MEBENDAZOL',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antiparasitario para lombrices intestinales. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (413,36,4,8,2,11,2,9,1700,'SM-36-00008',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 20 TABLETAS','MEBENDAZOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Mebendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (414,36,4,8,2,12,2,9,1700,'SM-36-00009',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 30 TABLETAS','MEBENDAZOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Mebendazol 500 mg para parasitosis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (415,36,5,10,2,10,2,9,1700,'SM-36-00010',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 10 TABLETAS','TINIDAZOL',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Antiparasitario para giardiasis y amebiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (416,36,5,10,2,11,2,9,1700,'SM-36-00011',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 20 TABLETAS','TINIDAZOL',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Tinidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (417,36,5,10,2,12,2,9,1700,'SM-36-00012',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 30 TABLETAS','TINIDAZOL',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,0,0,1,'30 tabletas de Tinidazol 500 mg para parásitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (418,36,6,11,2,10,2,9,1700,'SM-36-00013',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 10 TABLETAS','NITAZOXANIDA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antiparasitario de amplio espectro. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (419,36,6,11,2,11,2,9,1700,'SM-36-00014',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 20 TABLETAS','NITAZOXANIDA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Nitazoxanida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (420,36,6,11,2,12,2,9,1700,'SM-36-00015',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 30 TABLETAS','NITAZOXANIDA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'30 tabletas de Nitazoxanida 500 mg para parasitosis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (421,37,2,2,2,10,2,9,1700,'SM-37-00001',NULL,NULL,NULL,NULL,NULL,'METRONIDAZOL 500 MG CAJA X 10 TABLETAS','METRONIDAZOL',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,1,0,1,'Antiprotozoario para amebiasis y giardiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (422,37,2,2,2,11,2,9,1700,'SM-37-00002',NULL,NULL,NULL,NULL,NULL,'METRONIDAZOL 500 MG CAJA X 20 TABLETAS','METRONIDAZOL',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Metronidazol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (423,37,2,2,2,12,2,9,1700,'SM-37-00003',NULL,NULL,NULL,NULL,NULL,'METRONIDAZOL 500 MG CAJA X 30 TABLETAS','METRONIDAZOL',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,1,0,1,'30 tabletas de Metronidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (424,37,3,9,2,10,2,9,1700,'SM-37-00004',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 10 TABLETAS','TINIDAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antiprotozoario para amebiasis y giardiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (425,37,3,9,2,11,2,9,1700,'SM-37-00005',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 20 TABLETAS','TINIDAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Tinidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (426,37,3,9,2,12,2,9,1700,'SM-37-00006',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 30 TABLETAS','TINIDAZOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Tinidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (427,37,4,8,2,10,2,9,1700,'SM-37-00007',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 10 TABLETAS','NITAZOXANIDA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,0,0,1,'Antiprotozoario de amplio espectro. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (428,37,4,8,2,11,2,9,1700,'SM-37-00008',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 20 TABLETAS','NITAZOXANIDA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Nitazoxanida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (429,37,4,8,2,12,2,9,1700,'SM-37-00009',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 30 TABLETAS','NITAZOXANIDA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,0,0,1,'30 tabletas de Nitazoxanida 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (430,37,5,10,2,10,2,9,1700,'SM-37-00010',NULL,NULL,NULL,NULL,NULL,'SECNIDAZOL 500 MG CAJA X 10 TABLETAS','SECNIDAZOL',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antiprotozoario para amebiasis y giardiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (431,37,5,10,2,11,2,9,1700,'SM-37-00011',NULL,NULL,NULL,NULL,NULL,'SECNIDAZOL 500 MG CAJA X 20 TABLETAS','SECNIDAZOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Secnidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (432,37,5,10,2,12,2,9,1700,'SM-37-00012',NULL,NULL,NULL,NULL,NULL,'SECNIDAZOL 500 MG CAJA X 30 TABLETAS','SECNIDAZOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Secnidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (433,37,6,11,2,10,2,9,1700,'SM-37-00013',NULL,NULL,NULL,NULL,NULL,'ORNIDAZOL 500 MG CAJA X 10 TABLETAS','ORNIDAZOL',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Antiprotozoario para amebiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (434,37,6,11,2,11,2,9,1700,'SM-37-00014',NULL,NULL,NULL,NULL,NULL,'ORNIDAZOL 500 MG CAJA X 20 TABLETAS','ORNIDAZOL',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Ornidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (435,37,6,11,2,12,2,9,1700,'SM-37-00015',NULL,NULL,NULL,NULL,NULL,'ORNIDAZOL 500 MG CAJA X 30 TABLETAS','ORNIDAZOL',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Ornidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (436,38,2,2,2,10,3,9,1700,'SM-38-00001',NULL,NULL,NULL,NULL,NULL,'ZIDOVUDINA 100 MG CAJA X 10 TABLETAS','ZIDOVUDINA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (437,38,2,2,2,11,3,9,1700,'SM-38-00002',NULL,NULL,NULL,NULL,NULL,'ZIDOVUDINA 100 MG CAJA X 20 TABLETAS','ZIDOVUDINA',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Zidovudina 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (438,38,2,2,2,12,3,9,1700,'SM-38-00003',NULL,NULL,NULL,NULL,NULL,'ZIDOVUDINA 100 MG CAJA X 30 TABLETAS','ZIDOVUDINA',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Zidovudina 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (439,38,3,9,2,10,3,9,1700,'SM-38-00004',NULL,NULL,NULL,NULL,NULL,'LAMIVUDINA 100 MG CAJA X 10 TABLETAS','LAMIVUDINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (440,38,3,9,2,11,3,9,1700,'SM-38-00005',NULL,NULL,NULL,NULL,NULL,'LAMIVUDINA 100 MG CAJA X 20 TABLETAS','LAMIVUDINA',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,1,1,'Caja de 20 tabletas de Lamivudina 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (441,38,3,9,2,12,3,9,1700,'SM-38-00006',NULL,NULL,NULL,NULL,NULL,'LAMIVUDINA 100 MG CAJA X 30 TABLETAS','LAMIVUDINA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'30 tabletas de Lamivudina 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (442,38,4,8,2,10,3,9,1700,'SM-38-00007',NULL,NULL,NULL,NULL,NULL,'NEVIRAPINA 100 MG CAJA X 10 TABLETAS','NEVIRAPINA',6.50,1.50,1.19,9.75,7.74,10.00,150.00,18.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (443,38,4,8,2,11,3,9,1700,'SM-38-00008',NULL,NULL,NULL,NULL,NULL,'NEVIRAPINA 100 MG CAJA X 20 TABLETAS','NEVIRAPINA',11.70,1.50,1.19,17.55,13.92,10.00,130.00,16.00,1,1,1,'Caja de 20 tabletas de Nevirapina 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (444,38,4,8,2,12,3,9,1700,'SM-38-00009',NULL,NULL,NULL,NULL,NULL,'NEVIRAPINA 100 MG CAJA X 30 TABLETAS','NEVIRAPINA',16.20,1.50,1.19,24.30,19.28,10.00,110.00,12.00,1,1,1,'30 tabletas de Nevirapina 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (445,38,5,10,2,10,3,9,1700,'SM-38-00010',NULL,NULL,NULL,NULL,NULL,'EFAVIRENZ 100 MG CAJA X 10 TABLETAS','EFAVIRENZ',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (446,38,5,10,2,11,3,9,1700,'SM-38-00011',NULL,NULL,NULL,NULL,NULL,'EFAVIRENZ 100 MG CAJA X 20 TABLETAS','EFAVIRENZ',16.20,1.50,1.19,24.30,19.28,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Efavirenz 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (447,38,5,10,2,12,3,9,1700,'SM-38-00012',NULL,NULL,NULL,NULL,NULL,'EFAVIRENZ 100 MG CAJA X 30 TABLETAS','EFAVIRENZ',22.50,1.50,1.19,33.75,26.78,10.00,90.00,9.00,1,1,1,'30 tabletas de Efavirenz 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (448,38,6,11,2,10,3,9,1700,'SM-38-00013',NULL,NULL,NULL,NULL,NULL,'DOLUTEGRAVIR 100 MG CAJA X 10 TABLETAS','DOLUTEGRAVIR',10.00,1.50,1.19,15.00,11.90,10.00,110.00,12.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (449,38,6,11,2,11,3,9,1700,'SM-38-00014',NULL,NULL,NULL,NULL,NULL,'DOLUTEGRAVIR 100 MG CAJA X 20 TABLETAS','DOLUTEGRAVIR',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Dolutegravir 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (450,38,6,11,2,12,3,9,1700,'SM-38-00015',NULL,NULL,NULL,NULL,NULL,'DOLUTEGRAVIR 100 MG CAJA X 30 TABLETAS','DOLUTEGRAVIR',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,1,1,'30 tabletas de Dolutegravir 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (451,39,2,2,2,10,2,9,1700,'SM-39-00001',NULL,NULL,NULL,NULL,NULL,'CICLOSPORINA 500 MG CAJA X 10 TABLETAS','CICLOSPORINA',15.00,1.50,1.19,22.50,17.85,10.00,100.00,10.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (452,39,2,2,2,11,2,9,1700,'SM-39-00002',NULL,NULL,NULL,NULL,NULL,'CICLOSPORINA 500 MG CAJA X 20 TABLETAS','CICLOSPORINA',27.00,1.50,1.19,40.50,32.13,10.00,90.00,9.00,1,1,1,'Caja de 20 tabletas de Ciclosporina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (453,39,2,2,2,12,2,9,1700,'SM-39-00003',NULL,NULL,NULL,NULL,NULL,'CICLOSPORINA 500 MG CAJA X 30 TABLETAS','CICLOSPORINA',38.00,1.50,1.19,57.00,45.22,10.00,80.00,8.00,1,1,1,'30 tabletas de Ciclosporina 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (454,39,3,9,2,10,2,9,1700,'SM-39-00004',NULL,NULL,NULL,NULL,NULL,'TACROLIMUS 500 MG CAJA X 10 TABLETAS','TACROLIMUS',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (455,39,3,9,2,11,2,9,1700,'SM-39-00005',NULL,NULL,NULL,NULL,NULL,'TACROLIMUS 500 MG CAJA X 20 TABLETAS','TACROLIMUS',32.40,1.50,1.19,48.60,38.56,10.00,90.00,9.00,1,1,1,'Caja de 20 tabletas de Tacrolimus 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (456,39,3,9,2,12,2,9,1700,'SM-39-00006',NULL,NULL,NULL,NULL,NULL,'TACROLIMUS 500 MG CAJA X 30 TABLETAS','TACROLIMUS',45.00,1.50,1.19,67.50,53.55,10.00,80.00,8.00,1,1,1,'30 tabletas de Tacrolimus 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (457,39,4,8,2,10,2,9,1700,'SM-39-00007',NULL,NULL,NULL,NULL,NULL,'SIROLIMUS 500 MG CAJA X 10 TABLETAS','SIROLIMUS',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (458,39,4,8,2,11,2,9,1700,'SM-39-00008',NULL,NULL,NULL,NULL,NULL,'SIROLIMUS 500 MG CAJA X 20 TABLETAS','SIROLIMUS',36.00,1.50,1.19,54.00,42.84,10.00,90.00,9.00,1,1,1,'Caja de 20 tabletas de Sirolimus 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (459,39,4,8,2,12,2,9,1700,'SM-39-00009',NULL,NULL,NULL,NULL,NULL,'SIROLIMUS 500 MG CAJA X 30 TABLETAS','SIROLIMUS',50.00,1.50,1.19,75.00,59.50,10.00,80.00,8.00,1,1,1,'30 tabletas de Sirolimus 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (460,39,5,10,2,10,2,9,1700,'SM-39-00010',NULL,NULL,NULL,NULL,NULL,'MICOFENOLATO 500 MG CAJA X 10 TABLETAS','MICOFENOLATO MOFETILO',12.00,1.50,1.19,18.00,14.28,10.00,110.00,12.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (461,39,5,10,2,11,2,9,1700,'SM-39-00011',NULL,NULL,NULL,NULL,NULL,'MICOFENOLATO 500 MG CAJA X 20 TABLETAS','MICOFENOLATO MOFETILO',21.60,1.50,1.19,32.40,25.70,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Micofenolato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (462,39,5,10,2,12,2,9,1700,'SM-39-00012',NULL,NULL,NULL,NULL,NULL,'MICOFENOLATO 500 MG CAJA X 30 TABLETAS','MICOFENOLATO MOFETILO',30.00,1.50,1.19,45.00,35.70,10.00,90.00,9.00,1,1,1,'30 tabletas de Micofenolato 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (463,39,6,11,2,10,2,9,1700,'SM-39-00013',NULL,NULL,NULL,NULL,NULL,'AZATIOPRINA 500 MG CAJA X 10 TABLETAS','AZATIOPRINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (464,39,6,11,2,11,2,9,1700,'SM-39-00014',NULL,NULL,NULL,NULL,NULL,'AZATIOPRINA 500 MG CAJA X 20 TABLETAS','AZATIOPRINA',18.00,1.50,1.19,27.00,21.42,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Azatioprina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (465,39,6,11,2,12,2,9,1700,'SM-39-00015',NULL,NULL,NULL,NULL,NULL,'AZATIOPRINA 500 MG CAJA X 30 TABLETAS','AZATIOPRINA',25.00,1.50,1.19,37.50,29.75,10.00,100.00,10.00,1,1,1,'30 tabletas de Azatioprina 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (466,40,2,2,2,10,2,9,1700,'SM-40-00001',NULL,NULL,NULL,NULL,NULL,'METOTREXATO 500 MG CAJA X 10 TABLETAS','METOTREXATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'AntiarTRITICO para artritis reumatoide. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (467,40,2,2,2,11,2,9,1700,'SM-40-00002',NULL,NULL,NULL,NULL,NULL,'METOTREXATO 500 MG CAJA X 20 TABLETAS','METOTREXATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Metotrexato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (468,40,2,2,2,12,2,9,1700,'SM-40-00003',NULL,NULL,NULL,NULL,NULL,'METOTREXATO 500 MG CAJA X 30 TABLETAS','METOTREXATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Metotrexato 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (469,40,3,9,2,10,2,9,1700,'SM-40-00004',NULL,NULL,NULL,NULL,NULL,'SULFASALAZINA 500 MG CAJA X 10 TABLETAS','SULFASALAZINA',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,1,0,1,'AntiarTRITICO para artritis reumatoide. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (470,40,3,9,2,11,2,9,1700,'SM-40-00005',NULL,NULL,NULL,NULL,NULL,'SULFASALAZINA 500 MG CAJA X 20 TABLETAS','SULFASALAZINA',7.20,1.50,1.19,10.80,8.57,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Sulfasalazina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (471,40,3,9,2,12,2,9,1700,'SM-40-00006',NULL,NULL,NULL,NULL,NULL,'SULFASALAZINA 500 MG CAJA X 30 TABLETAS','SULFASALAZINA',10.00,1.50,1.19,15.00,11.90,10.00,130.00,16.00,1,0,1,'30 tabletas de Sulfasalazina 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (472,40,4,8,2,10,2,9,1700,'SM-40-00007',NULL,NULL,NULL,NULL,NULL,'HIDROXICLOROQUINA 500 MG CAJA X 10 TABLETAS','HIDROXICLOROQUINA SULFATO',3.50,1.50,1.19,5.25,4.17,10.00,180.00,22.00,1,0,1,'AntiarTRITICO para lupus y artritis reumatoide. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (473,40,4,8,2,11,2,9,1700,'SM-40-00008',NULL,NULL,NULL,NULL,NULL,'HIDROXICLOROQUINA 500 MG CAJA X 20 TABLETAS','HIDROXICLOROQUINA SULFATO',6.30,1.50,1.19,9.45,7.50,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Hidroxicloroquina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (474,40,4,8,2,12,2,9,1700,'SM-40-00009',NULL,NULL,NULL,NULL,NULL,'HIDROXICLOROQUINA 500 MG CAJA X 30 TABLETAS','HIDROXICLOROQUINA SULFATO',8.80,1.50,1.19,13.20,10.47,10.00,140.00,18.00,1,0,1,'30 tabletas de Hidroxicloroquina 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (475,40,5,10,2,10,2,9,1700,'SM-40-00010',NULL,NULL,NULL,NULL,NULL,'LEFLUNOMIDA 500 MG CAJA X 10 TABLETAS','LEFLUNOMIDA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'AntiarTRITICO para artritis reumatoide. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (476,40,5,10,2,11,2,9,1700,'SM-40-00011',NULL,NULL,NULL,NULL,NULL,'LEFLUNOMIDA 500 MG CAJA X 20 TABLETAS','LEFLUNOMIDA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Leflunomida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (477,40,5,10,2,12,2,9,1700,'SM-40-00012',NULL,NULL,NULL,NULL,NULL,'LEFLUNOMIDA 500 MG CAJA X 30 TABLETAS','LEFLUNOMIDA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Leflunomida 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (478,40,6,11,2,10,2,9,1700,'SM-40-00013',NULL,NULL,NULL,NULL,NULL,'ETANERCEPT 500 MG CAJA X 10 TABLETAS','ETANERCEPT',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,0,1,'AntiarTRITICO biológico para artritis reumatoide. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (479,40,6,11,2,11,2,9,1700,'SM-40-00014',NULL,NULL,NULL,NULL,NULL,'ETANERCEPT 500 MG CAJA X 20 TABLETAS','ETANERCEPT',45.00,1.50,1.19,67.50,53.55,10.00,80.00,8.00,1,0,1,'Caja de 20 tabletas de Etanercept 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (480,40,6,11,2,12,2,9,1700,'SM-40-00015',NULL,NULL,NULL,NULL,NULL,'ETANERCEPT 500 MG CAJA X 30 TABLETAS','ETANERCEPT',60.00,1.50,1.19,90.00,71.40,10.00,70.00,7.00,1,0,1,'30 tabletas de Etanercept 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (481,41,2,2,2,10,2,9,1700,'SM-41-00001',NULL,NULL,NULL,NULL,NULL,'ALOPURINOL 500 MG CAJA X 10 TABLETAS','ALOPURINOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antigotoso para la prevención de ataques de gota. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (482,41,2,2,2,11,2,9,1700,'SM-41-00002',NULL,NULL,NULL,NULL,NULL,'ALOPURINOL 500 MG CAJA X 20 TABLETAS','ALOPURINOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Alopurinol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (483,41,2,2,2,12,2,9,1700,'SM-41-00003',NULL,NULL,NULL,NULL,NULL,'ALOPURINOL 500 MG CAJA X 30 TABLETAS','ALOPURINOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Alopurinol 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (484,41,3,9,2,10,2,9,1700,'SM-41-00004',NULL,NULL,NULL,NULL,NULL,'FEBUXOSTAT 500 MG CAJA X 10 TABLETAS','FEBUXOSTAT',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Antigotoso para hiperuricemia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (485,41,3,9,2,11,2,9,1700,'SM-41-00005',NULL,NULL,NULL,NULL,NULL,'FEBUXOSTAT 500 MG CAJA X 20 TABLETAS','FEBUXOSTAT',8.10,1.50,1.19,12.15,9.64,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Febuxostat 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (486,41,3,9,2,12,2,9,1700,'SM-41-00006',NULL,NULL,NULL,NULL,NULL,'FEBUXOSTAT 500 MG CAJA X 30 TABLETAS','FEBUXOSTAT',11.20,1.50,1.19,16.80,13.33,10.00,120.00,15.00,0,0,1,'30 tabletas de Febuxostat 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (487,41,4,8,2,10,2,9,1700,'SM-41-00007',NULL,NULL,NULL,NULL,NULL,'COLCHICINA 500 MG CAJA X 10 TABLETAS','COLCHICINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antigotoso para ataques agudos de gota. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (488,41,4,8,2,11,2,9,1700,'SM-41-00008',NULL,NULL,NULL,NULL,NULL,'COLCHICINA 500 MG CAJA X 20 TABLETAS','COLCHICINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Colchicina 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (489,41,4,8,2,12,2,9,1700,'SM-41-00009',NULL,NULL,NULL,NULL,NULL,'COLCHICINA 500 MG CAJA X 30 TABLETAS','COLCHICINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Colchicina 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (490,41,5,10,2,10,2,9,1700,'SM-41-00010',NULL,NULL,NULL,NULL,NULL,'PROBENECID 500 MG CAJA X 10 TABLETAS','PROBENECID',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Antigotoso para la excreción de ácido úrico. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (491,41,5,10,2,11,2,9,1700,'SM-41-00011',NULL,NULL,NULL,NULL,NULL,'PROBENECID 500 MG CAJA X 20 TABLETAS','PROBENECID',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Probenecid 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (492,41,5,10,2,12,2,9,1700,'SM-41-00012',NULL,NULL,NULL,NULL,NULL,'PROBENECID 500 MG CAJA X 30 TABLETAS','PROBENECID',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,0,0,1,'30 tabletas de Probenecid 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (493,41,6,11,2,10,2,9,1700,'SM-41-00013',NULL,NULL,NULL,NULL,NULL,'SULFINPIRAZONA 500 MG CAJA X 10 TABLETAS','SULFINPIRAZONA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antigotoso para hiperuricemia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (494,41,6,11,2,11,2,9,1700,'SM-41-00014',NULL,NULL,NULL,NULL,NULL,'SULFINPIRAZONA 500 MG CAJA X 20 TABLETAS','SULFINPIRAZONA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Sulfinpirazona 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (495,41,6,11,2,12,2,9,1700,'SM-41-00015',NULL,NULL,NULL,NULL,NULL,'SULFINPIRAZONA 500 MG CAJA X 30 TABLETAS','SULFINPIRAZONA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Sulfinpirazona 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (496,42,2,2,2,10,2,9,1700,'SM-42-00001',NULL,NULL,NULL,NULL,NULL,'PRAZIQUANTEL 500 MG CAJA X 10 TABLETAS','PRAZIQUANTEL',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antihelmíntico para esquistosomiasis y teniasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (497,42,2,2,2,11,2,9,1700,'SM-42-00002',NULL,NULL,NULL,NULL,NULL,'PRAZIQUANTEL 500 MG CAJA X 20 TABLETAS','PRAZIQUANTEL',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Praziquantel 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (498,42,2,2,2,12,2,9,1700,'SM-42-00003',NULL,NULL,NULL,NULL,NULL,'PRAZIQUANTEL 500 MG CAJA X 30 TABLETAS','PRAZIQUANTEL',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'30 tabletas de Praziquantel 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (499,42,3,9,2,10,2,9,1700,'SM-42-00004',NULL,NULL,NULL,NULL,NULL,'IVERMECTINA 500 MG CAJA X 10 TABLETAS','IVERMECTINA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Antihelmíntico para estrongiloidiasis y oncocercosis. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (500,42,3,9,2,11,2,9,1700,'SM-42-00005',NULL,NULL,NULL,NULL,NULL,'IVERMECTINA 500 MG CAJA X 20 TABLETAS','IVERMECTINA',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,0,0,1,'Caja de 20 tabletas de Ivermectina 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (501,42,3,9,2,12,2,9,1700,'SM-42-00006',NULL,NULL,NULL,NULL,NULL,'IVERMECTINA 500 MG CAJA X 30 TABLETAS','IVERMECTINA',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,0,0,1,'30 tabletas de Ivermectina 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (502,42,4,8,2,10,2,9,1700,'SM-42-00007',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 10 TABLETAS','MEBENDAZOL',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antihelmíntico para lombrices intestinales. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (503,42,4,8,2,11,2,9,1700,'SM-42-00008',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 20 TABLETAS','MEBENDAZOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Mebendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (504,42,4,8,2,12,2,9,1700,'SM-42-00009',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 30 TABLETAS','MEBENDAZOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Mebendazol 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (505,42,5,10,2,10,2,9,1700,'SM-42-00010',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 10 TABLETAS','ALBENDAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antihelmíntico para neurocisticercosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (506,42,5,10,2,11,2,9,1700,'SM-42-00011',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 20 TABLETAS','ALBENDAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Albendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (507,42,5,10,2,12,2,9,1700,'SM-42-00012',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 30 TABLETAS','ALBENDAZOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Albendazol 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (508,42,6,11,2,10,2,9,1700,'SM-42-00013',NULL,NULL,NULL,NULL,NULL,'NICLOSAMIDA 500 MG CAJA X 10 TABLETAS','NICLOSAMIDA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antihelmíntico para teniasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (509,42,6,11,2,11,2,9,1700,'SM-42-00014',NULL,NULL,NULL,NULL,NULL,'NICLOSAMIDA 500 MG CAJA X 20 TABLETAS','NICLOSAMIDA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Niclosamida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (510,42,6,11,2,12,2,9,1700,'SM-42-00015',NULL,NULL,NULL,NULL,NULL,'NICLOSAMIDA 500 MG CAJA X 30 TABLETAS','NICLOSAMIDA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Niclosamida 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (511,43,2,2,7,20,2,9,1700,'SM-43-00001',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CREMA TUBO X 30 G','HIDROCORTISONA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antiprurítico para aliviar la picazón y la inflamación. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (512,43,2,2,7,21,2,9,1700,'SM-43-00002',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CREMA TUBO X 50 G','HIDROCORTISONA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Hidrocortisona 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (513,43,3,9,7,20,2,9,1700,'SM-43-00003',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 500 MG CREMA TUBO X 30 G','DIFENHIDRAMINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antiprurítico para alergias y picazón. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (514,43,3,9,7,21,2,9,1700,'SM-43-00004',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 500 MG CREMA TUBO X 50 G','DIFENHIDRAMINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Tubo de 50 g de Difenhidramina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (515,43,4,8,7,20,2,9,1700,'SM-43-00005',NULL,NULL,NULL,NULL,NULL,'PIRIDOXINA 500 MG CREMA TUBO X 30 G','PIRIDOXINA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,0,0,1,'Antiprurítico para la picazón. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (516,43,4,8,7,21,2,9,1700,'SM-43-00006',NULL,NULL,NULL,NULL,NULL,'PIRIDOXINA 500 MG CREMA TUBO X 50 G','PIRIDOXINA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Piridoxina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (517,43,5,10,7,20,2,9,1700,'SM-43-00007',NULL,NULL,NULL,NULL,NULL,'DOXEPINA 500 MG CREMA TUBO X 30 G','DOXEPINA CLORHIDRATO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Antiprurítico para dermatitis atópica. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (518,43,5,10,7,21,2,9,1700,'SM-43-00008',NULL,NULL,NULL,NULL,NULL,'DOXEPINA 500 MG CREMA TUBO X 50 G','DOXEPINA CLORHIDRATO',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Doxepina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (519,43,6,11,7,20,2,9,1700,'SM-43-00009',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 500 MG CREMA TUBO X 30 G','CETIRIZINA CLORHIDRATO',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Antiprurítico para alergias cutáneas. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (520,43,6,11,7,21,2,9,1700,'SM-43-00010',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 500 MG CREMA TUBO X 50 G','CETIRIZINA CLORHIDRATO',6.80,1.50,1.19,10.20,8.09,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Cetirizina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (521,44,2,2,7,20,2,9,1700,'SM-44-00001',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG CREMA TUBO X 30 G','CLORHEXIDINA GLUCONATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antiséptico para la desinfección de heridas. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (522,44,2,2,7,21,2,9,1700,'SM-44-00002',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG CREMA TUBO X 50 G','CLORHEXIDINA GLUCONATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Tubo de 50 g de Clorhexidina 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (523,44,3,9,7,20,2,9,1700,'SM-44-00003',NULL,NULL,NULL,NULL,NULL,'POVIDONA YODADA 500 MG CREMA TUBO X 30 G','POVIDONA YODADA',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Antiséptico para quemaduras y heridas. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (524,44,3,9,7,21,2,9,1700,'SM-44-00004',NULL,NULL,NULL,NULL,NULL,'POVIDONA YODADA 500 MG CREMA TUBO X 50 G','POVIDONA YODADA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Povidona Yodada 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (525,44,4,8,7,20,2,9,1700,'SM-44-00005',NULL,NULL,NULL,NULL,NULL,'PEROXIDO DE BENZOILO 500 MG CREMA TUBO X 30 G','PEROXIDO DE BENZOILO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,20.00,0,0,1,'Antiséptico para el acné. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (526,44,4,8,7,21,2,9,1700,'SM-44-00006',NULL,NULL,NULL,NULL,NULL,'PEROXIDO DE BENZOILO 500 MG CREMA TUBO X 50 G','PEROXIDO DE BENZOILO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Peróxido de Benzoilo 500 mg para acné.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (527,44,5,10,7,20,2,9,1700,'SM-44-00007',NULL,NULL,NULL,NULL,NULL,'ACIDO BORICO 500 MG CREMA TUBO X 30 G','ACIDO BORICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antiséptico para infecciones leves. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (528,44,5,10,7,21,2,9,1700,'SM-44-00008',NULL,NULL,NULL,NULL,NULL,'ACIDO BORICO 500 MG CREMA TUBO X 50 G','ACIDO BORICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Tubo de 50 g de Ácido Bórico 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (529,44,6,11,7,20,2,9,1700,'SM-44-00009',NULL,NULL,NULL,NULL,NULL,'NITRATO DE PLATA 500 MG CREMA TUBO X 30 G','NITRATO DE PLATA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antiséptico para quemaduras. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (530,44,6,11,7,21,2,9,1700,'SM-44-00010',NULL,NULL,NULL,NULL,NULL,'NITRATO DE PLATA 500 MG CREMA TUBO X 50 G','NITRATO DE PLATA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Nitrato de Plata 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (531,45,2,2,12,42,2,9,1700,'SM-45-00001',NULL,NULL,NULL,NULL,NULL,'ALCOHOL 500 MG SOLUCION FRASCO X 60 ML','ALCOHOL ETILICO',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Desinfectante para la limpieza de superficies y heridas. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (532,45,2,2,12,45,2,9,1700,'SM-45-00002',NULL,NULL,NULL,NULL,NULL,'ALCOHOL 500 MG SOLUCION FRASCO X 500 ML','ALCOHOL ETILICO',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Frasco de 500 ml de Alcohol 500 mg para desinfección.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (533,45,3,9,12,42,2,9,1700,'SM-45-00003',NULL,NULL,NULL,NULL,NULL,'AGUA OXIGENADA 500 MG SOLUCION FRASCO X 60 ML','PEROXIDO DE HIDROGENO',2.00,1.50,1.19,3.00,2.38,10.00,190.00,25.00,0,0,1,'Desinfectante para heridas. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (534,45,3,9,12,45,2,9,1700,'SM-45-00004',NULL,NULL,NULL,NULL,NULL,'AGUA OXIGENADA 500 MG SOLUCION FRASCO X 500 ML','PEROXIDO DE HIDROGENO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Frasco de 500 ml de Agua Oxigenada 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (535,45,4,8,12,42,2,9,1700,'SM-45-00005',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG SOLUCION FRASCO X 60 ML','CLORHEXIDINA GLUCONATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Desinfectante para la piel. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (536,45,4,8,12,45,2,9,1700,'SM-45-00006',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG SOLUCION FRASCO X 500 ML','CLORHEXIDINA GLUCONATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,18.00,0,0,1,'Frasco de 500 ml de Clorhexidina 500 mg para desinfección.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (537,45,5,10,12,42,2,9,1700,'SM-45-00007',NULL,NULL,NULL,NULL,NULL,'YODO 500 MG SOLUCION FRASCO X 60 ML','YODO',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Desinfectante para heridas. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (538,45,5,10,12,45,2,9,1700,'SM-45-00008',NULL,NULL,NULL,NULL,NULL,'YODO 500 MG SOLUCION FRASCO X 500 ML','YODO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Frasco de 500 ml de Yodo 500 mg para desinfección.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (539,45,6,11,12,42,2,9,1700,'SM-45-00009',NULL,NULL,NULL,NULL,NULL,'AMONIO CUATERNARIO 500 MG SOLUCION FRASCO X 60 ML','AMONIO CUATERNARIO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Desinfectante para superficies. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (540,45,6,11,12,45,2,9,1700,'SM-45-00010',NULL,NULL,NULL,NULL,NULL,'AMONIO CUATERNARIO 500 MG SOLUCION FRASCO X 500 ML','AMONIO CUATERNARIO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Frasco de 500 ml de Amonio Cuaternario 500 mg para superficies.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (541,46,2,2,5,4,3,9,1700,'SM-46-00001',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 100 MG INYECTABLE AMPOLLA 1 ML','LIDOCAINA CLORHIDRATO',2.00,1.50,1.19,3.00,2.38,10.00,190.00,25.00,1,0,1,'Anestésico local para procedimientos médicos. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (542,46,2,2,5,17,3,9,1700,'SM-46-00002',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','LIDOCAINA CLORHIDRATO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,1,0,1,'Caja de 10 ampollas de Lidocaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (543,46,3,9,5,4,3,9,1700,'SM-46-00003',NULL,NULL,NULL,NULL,NULL,'BUPIVACAINA 100 MG INYECTABLE AMPOLLA 1 ML','BUPIVACAINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,1,0,1,'Anestésico local para cirugía menor. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (544,46,3,9,5,17,3,9,1700,'SM-46-00004',NULL,NULL,NULL,NULL,NULL,'BUPIVACAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','BUPIVACAINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,18.00,1,0,1,'Caja de 10 ampollas de Bupivacaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (545,46,4,8,5,4,3,9,1700,'SM-46-00005',NULL,NULL,NULL,NULL,NULL,'MEPIVACAINA 100 MG INYECTABLE AMPOLLA 1 ML','MEPIVACAINA CLORHIDRATO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,1,0,1,'Anestésico local para odontología. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (546,46,4,8,5,17,3,9,1700,'SM-46-00006',NULL,NULL,NULL,NULL,NULL,'MEPIVACAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','MEPIVACAINA CLORHIDRATO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Caja de 10 ampollas de Mepivacaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (547,46,5,10,5,4,3,9,1700,'SM-46-00007',NULL,NULL,NULL,NULL,NULL,'PROCAINA 100 MG INYECTABLE AMPOLLA 1 ML','PROCAINA CLORHIDRATO',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,1,0,1,'Anestésico local para procedimientos menores. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (548,46,5,10,5,17,3,9,1700,'SM-46-00008',NULL,NULL,NULL,NULL,NULL,'PROCAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','PROCAINA CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,1,0,1,'Caja de 10 ampollas de Procaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (549,46,6,11,5,4,3,9,1700,'SM-46-00009',NULL,NULL,NULL,NULL,NULL,'ROPIVACAINA 100 MG INYECTABLE AMPOLLA 1 ML','ROPIVACAINA CLORHIDRATO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,1,0,1,'Anestésico local para procedimientos quirúrgicos. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (550,46,6,11,5,17,3,9,1700,'SM-46-00010',NULL,NULL,NULL,NULL,NULL,'ROPIVACAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','ROPIVACAINA CLORHIDRATO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,1,0,1,'Caja de 10 ampollas de Ropivacaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (551,47,2,2,2,10,2,9,1700,'SM-47-00001',NULL,NULL,NULL,NULL,NULL,'MORFINA 500 MG CAJA X 10 TABLETAS','MORFINA SULFATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (552,47,2,2,2,11,2,9,1700,'SM-47-00002',NULL,NULL,NULL,NULL,NULL,'MORFINA 500 MG CAJA X 20 TABLETAS','MORFINA SULFATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Morfina 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (553,47,2,2,2,12,2,9,1700,'SM-47-00003',NULL,NULL,NULL,NULL,NULL,'MORFINA 500 MG CAJA X 30 TABLETAS','MORFINA SULFATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Morfina 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (554,47,3,9,2,10,2,9,1700,'SM-47-00004',NULL,NULL,NULL,NULL,NULL,'CODEINA 500 MG CAJA X 10 TABLETAS','CODEINA FOSFATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,1,1,'Analgésico opioide para dolor moderado. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (555,47,3,9,2,11,2,9,1700,'SM-47-00005',NULL,NULL,NULL,NULL,NULL,'CODEINA 500 MG CAJA X 20 TABLETAS','CODEINA FOSFATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,1,1,'Caja de 20 tabletas de Codeína 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (556,47,3,9,2,12,2,9,1700,'SM-47-00006',NULL,NULL,NULL,NULL,NULL,'CODEINA 500 MG CAJA X 30 TABLETAS','CODEINA FOSFATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,1,1,'30 tabletas de Codeína 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (557,47,4,8,2,10,2,9,1700,'SM-47-00007',NULL,NULL,NULL,NULL,NULL,'OXICODONA 500 MG CAJA X 10 TABLETAS','OXICODONA CLORHIDRATO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (558,47,4,8,2,11,2,9,1700,'SM-47-00008',NULL,NULL,NULL,NULL,NULL,'OXICODONA 500 MG CAJA X 20 TABLETAS','OXICODONA CLORHIDRATO',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de OxiCápsula 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (559,47,4,8,2,12,2,9,1700,'SM-47-00009',NULL,NULL,NULL,NULL,NULL,'OXICODONA 500 MG CAJA X 30 TABLETAS','OXICODONA CLORHIDRATO',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,1,1,'30 tabletas de OxiCápsula 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (560,47,5,10,2,10,2,9,1700,'SM-47-00010',NULL,NULL,NULL,NULL,NULL,'FENTANILO 500 MG CAJA X 10 TABLETAS','FENTANILO CITRATO',12.00,1.50,1.19,18.00,14.28,10.00,110.00,12.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (561,47,5,10,2,11,2,9,1700,'SM-47-00011',NULL,NULL,NULL,NULL,NULL,'FENTANILO 500 MG CAJA X 20 TABLETAS','FENTANILO CITRATO',21.60,1.50,1.19,32.40,25.70,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Fentanilo 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (562,47,5,10,2,12,2,9,1700,'SM-47-00012',NULL,NULL,NULL,NULL,NULL,'FENTANILO 500 MG CAJA X 30 TABLETAS','FENTANILO CITRATO',30.00,1.50,1.19,45.00,35.70,10.00,90.00,9.00,1,1,1,'30 tabletas de Fentanilo 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (563,47,6,11,2,10,2,9,1700,'SM-47-00013',NULL,NULL,NULL,NULL,NULL,'HIDROMORFONA 500 MG CAJA X 10 TABLETAS','HIDROMORFONA CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (564,47,6,11,2,11,2,9,1700,'SM-47-00014',NULL,NULL,NULL,NULL,NULL,'HIDROMORFONA 500 MG CAJA X 20 TABLETAS','HIDROMORFONA CLORHIDRATO',16.20,1.50,1.19,24.30,19.28,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Hidromorfona 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (565,47,6,11,2,12,2,9,1700,'SM-47-00015',NULL,NULL,NULL,NULL,NULL,'HIDROMORFONA 500 MG CAJA X 30 TABLETAS','HIDROMORFONA CLORHIDRATO',22.50,1.50,1.19,33.75,26.78,10.00,100.00,10.00,1,1,1,'30 tabletas de Hidromorfona 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (566,48,2,2,2,10,2,9,1700,'SM-48-00001',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 10 TABLETAS','IBUPROFENO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Analgésico no opioide para dolor leve a moderado. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (567,48,2,2,2,11,2,9,1700,'SM-48-00002',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 20 TABLETAS','IBUPROFENO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (568,48,2,2,2,12,2,9,1700,'SM-48-00003',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 30 TABLETAS','IBUPROFENO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Ibuprofeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (569,48,3,9,2,10,2,9,1700,'SM-48-00004',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 10 TABLETAS','PARACETAMOL',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Analgésico no opioide para fiebre y dolor. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (570,48,3,9,2,11,2,9,1700,'SM-48-00005',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 20 TABLETAS','PARACETAMOL',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Paracetamol 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (571,48,3,9,2,12,2,9,1700,'SM-48-00006',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 30 TABLETAS','PARACETAMOL',4.50,1.50,1.19,6.75,5.36,10.00,140.00,18.00,0,0,1,'30 tabletas de Paracetamol 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (572,48,4,8,2,10,2,9,1700,'SM-48-00007',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Analgésico no opioide para dolor y fiebre. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (573,48,4,8,2,11,2,9,1700,'SM-48-00008',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Aspirina 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (574,48,4,8,2,12,2,9,1700,'SM-48-00009',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Aspirina 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (575,48,5,10,2,10,2,9,1700,'SM-48-00010',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 10 TABLETAS','NAPROXENO SODICO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Analgésico no opioide para dolor. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (576,48,5,10,2,11,2,9,1700,'SM-48-00011',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 20 TABLETAS','NAPROXENO SODICO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Naproxeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (577,48,5,10,2,12,2,9,1700,'SM-48-00012',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 30 TABLETAS','NAPROXENO SODICO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Naproxeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (578,48,6,11,2,10,2,9,1700,'SM-48-00013',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 10 TABLETAS','METAMIZOL SODICO',2.00,1.50,1.19,3.00,2.38,10.00,190.00,25.00,0,0,1,'Analgésico no opioide para dolor y fiebre. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (579,48,6,11,2,11,2,9,1700,'SM-48-00014',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 20 TABLETAS','METAMIZOL SODICO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Metamizol 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (580,48,6,11,2,12,2,9,1700,'SM-48-00015',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 30 TABLETAS','METAMIZOL SODICO',5.00,1.50,1.19,7.50,5.95,10.00,140.00,18.00,0,0,1,'30 tabletas de Metamizol 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (581,49,2,2,2,10,2,9,1700,'SM-49-00001',NULL,NULL,NULL,NULL,NULL,'SUMATRIPTAN 500 MG CAJA X 10 TABLETAS','SUMATRIPTAN SUCCINATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Antimigrañoso para el alivio de la migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (582,49,2,2,2,11,2,9,1700,'SM-49-00002',NULL,NULL,NULL,NULL,NULL,'SUMATRIPTAN 500 MG CAJA X 20 TABLETAS','SUMATRIPTAN SUCCINATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,0,1,'Caja de 20 tabletas de Sumatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (583,49,2,2,2,12,2,9,1700,'SM-49-00003',NULL,NULL,NULL,NULL,NULL,'SUMATRIPTAN 500 MG CAJA X 30 TABLETAS','SUMATRIPTAN SUCCINATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,0,1,'30 tabletas de Sumatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (584,49,3,9,2,10,2,9,1700,'SM-49-00004',NULL,NULL,NULL,NULL,NULL,'ZOLMITRIPTAN 500 MG CAJA X 10 TABLETAS','ZOLMITRIPTAN',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,0,1,'Antimigrañoso para migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (585,49,3,9,2,11,2,9,1700,'SM-49-00005',NULL,NULL,NULL,NULL,NULL,'ZOLMITRIPTAN 500 MG CAJA X 20 TABLETAS','ZOLMITRIPTAN',16.20,1.50,1.19,24.30,19.28,10.00,100.00,10.00,1,0,1,'Caja de 20 tabletas de Zolmitriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (586,49,3,9,2,12,2,9,1700,'SM-49-00006',NULL,NULL,NULL,NULL,NULL,'ZOLMITRIPTAN 500 MG CAJA X 30 TABLETAS','ZOLMITRIPTAN',22.50,1.50,1.19,33.75,26.78,10.00,90.00,9.00,1,0,1,'30 tabletas de Zolmitriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (587,49,4,8,2,10,2,9,1700,'SM-49-00007',NULL,NULL,NULL,NULL,NULL,'RIZATRIPTAN 500 MG CAJA X 10 TABLETAS','RIZATRIPTAN BENZOATO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,16.00,1,0,1,'Antimigrañoso para migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (588,49,4,8,2,11,2,9,1700,'SM-49-00008',NULL,NULL,NULL,NULL,NULL,'RIZATRIPTAN 500 MG CAJA X 20 TABLETAS','RIZATRIPTAN BENZOATO',13.50,1.50,1.19,20.25,16.07,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Rizatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (589,49,4,8,2,12,2,9,1700,'SM-49-00009',NULL,NULL,NULL,NULL,NULL,'RIZATRIPTAN 500 MG CAJA X 30 TABLETAS','RIZATRIPTAN BENZOATO',19.00,1.50,1.19,28.50,22.61,10.00,100.00,10.00,1,0,1,'30 tabletas de Rizatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (590,49,5,10,2,10,2,9,1700,'SM-49-00010',NULL,NULL,NULL,NULL,NULL,'ERGOTAMINA 500 MG CAJA X 10 TABLETAS','ERGOTAMINA TARTRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antimigrañoso para la migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (591,49,5,10,2,11,2,9,1700,'SM-49-00011',NULL,NULL,NULL,NULL,NULL,'ERGOTAMINA 500 MG CAJA X 20 TABLETAS','ERGOTAMINA TARTRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Ergotamina 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (592,49,5,10,2,12,2,9,1700,'SM-49-00012',NULL,NULL,NULL,NULL,NULL,'ERGOTAMINA 500 MG CAJA X 30 TABLETAS','ERGOTAMINA TARTRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Ergotamina 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (593,49,6,11,2,10,2,9,1700,'SM-49-00013',NULL,NULL,NULL,NULL,NULL,'ISOMETEPTENO 500 MG CAJA X 10 TABLETAS','ISOMETEPTENO CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antimigrañoso para migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (594,49,6,11,2,11,2,9,1700,'SM-49-00014',NULL,NULL,NULL,NULL,NULL,'ISOMETEPTENO 500 MG CAJA X 20 TABLETAS','ISOMETEPTENO CLORHIDRATO',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Isometepteno 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (595,49,6,11,2,12,2,9,1700,'SM-49-00015',NULL,NULL,NULL,NULL,NULL,'ISOMETEPTENO 500 MG CAJA X 30 TABLETAS','ISOMETEPTENO CLORHIDRATO',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Isometepteno 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (596,50,2,2,2,10,2,9,1700,'SM-50-00001',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 10 TABLETAS','NITROGLICERINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Antianginoso para la angina de pecho. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (597,50,2,2,2,11,2,9,1700,'SM-50-00002',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 20 TABLETAS','NITROGLICERINA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Nitroglicerina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (598,50,2,2,2,12,2,9,1700,'SM-50-00003',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 30 TABLETAS','NITROGLICERINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Nitroglicerina 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (599,50,3,9,2,10,2,9,1700,'SM-50-00004',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 10 TABLETAS','DINITRATO DE ISOSORBIDE',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Antianginoso para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (600,50,3,9,2,11,2,9,1700,'SM-50-00005',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 20 TABLETAS','DINITRATO DE ISOSORBIDE',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Isosorbide 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (601,50,3,9,2,12,2,9,1700,'SM-50-00006',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 30 TABLETAS','DINITRATO DE ISOSORBIDE',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Isosorbide 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (602,50,4,8,2,10,2,9,1700,'SM-50-00007',NULL,NULL,NULL,NULL,NULL,'DILTIAZEM 500 MG CAJA X 10 TABLETAS','DILTIAZEM CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Antianginoso para la angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (603,50,4,8,2,11,2,9,1700,'SM-50-00008',NULL,NULL,NULL,NULL,NULL,'DILTIAZEM 500 MG CAJA X 20 TABLETAS','DILTIAZEM CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Diltiazem 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (604,50,4,8,2,12,2,9,1700,'SM-50-00009',NULL,NULL,NULL,NULL,NULL,'DILTIAZEM 500 MG CAJA X 30 TABLETAS','DILTIAZEM CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Diltiazem 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (605,50,5,10,2,10,2,9,1700,'SM-50-00010',NULL,NULL,NULL,NULL,NULL,'ATENOLOL 500 MG CAJA X 10 TABLETAS','ATENOLOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Antianginoso para la angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (606,50,5,10,2,11,2,9,1700,'SM-50-00011',NULL,NULL,NULL,NULL,NULL,'ATENOLOL 500 MG CAJA X 20 TABLETAS','ATENOLOL',8.10,1.50,1.19,12.15,9.64,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Atenolol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (607,50,5,10,2,12,2,9,1700,'SM-50-00012',NULL,NULL,NULL,NULL,NULL,'ATENOLOL 500 MG CAJA X 30 TABLETAS','ATENOLOL',11.20,1.50,1.19,16.80,13.33,10.00,120.00,15.00,1,0,1,'30 tabletas de Atenolol 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (608,50,6,11,2,10,2,9,1700,'SM-50-00013',NULL,NULL,NULL,NULL,NULL,'VERAPAMILO 500 MG CAJA X 10 TABLETAS','VERAPAMILO CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antianginoso para la angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (609,50,6,11,2,11,2,9,1700,'SM-50-00014',NULL,NULL,NULL,NULL,NULL,'VERAPAMILO 500 MG CAJA X 20 TABLETAS','VERAPAMILO CLORHIDRATO',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Verapamilo 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (610,50,6,11,2,12,2,9,1700,'SM-50-00015',NULL,NULL,NULL,NULL,NULL,'VERAPAMILO 500 MG CAJA X 30 TABLETAS','VERAPAMILO CLORHIDRATO',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Verapamilo 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (611,51,2,2,2,10,2,9,1700,'SM-51-00001',NULL,NULL,NULL,NULL,NULL,'AMIODARONA 500 MG CAJA X 10 TABLETAS','AMIODARONA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antiarrítmico para arritmias ventriculares. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (612,51,2,2,2,11,2,9,1700,'SM-51-00002',NULL,NULL,NULL,NULL,NULL,'AMIODARONA 500 MG CAJA X 20 TABLETAS','AMIODARONA CLORHIDRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Amiodarona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (613,51,2,2,2,12,2,9,1700,'SM-51-00003',NULL,NULL,NULL,NULL,NULL,'AMIODARONA 500 MG CAJA X 30 TABLETAS','AMIODARONA CLORHIDRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Amiodarona 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (614,51,3,9,2,10,2,9,1700,'SM-51-00004',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 500 MG CAJA X 10 TABLETAS','LIDOCAINA CLORHIDRATO',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,1,0,1,'Antiarrítmico para arritmias ventriculares. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (615,51,3,9,2,11,2,9,1700,'SM-51-00005',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 500 MG CAJA X 20 TABLETAS','LIDOCAINA CLORHIDRATO',5.40,1.50,1.19,8.10,6.43,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Lidocaína 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (616,51,3,9,2,12,2,9,1700,'SM-51-00006',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 500 MG CAJA X 30 TABLETAS','LIDOCAINA CLORHIDRATO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,18.00,1,0,1,'30 tabletas de Lidocaína 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (617,51,4,8,2,10,2,9,1700,'SM-51-00007',NULL,NULL,NULL,NULL,NULL,'PROCAINAMIDA 500 MG CAJA X 10 TABLETAS','PROCAINAMIDA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Antiarrítmico para arritmias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (618,51,4,8,2,11,2,9,1700,'SM-51-00008',NULL,NULL,NULL,NULL,NULL,'PROCAINAMIDA 500 MG CAJA X 20 TABLETAS','PROCAINAMIDA CLORHIDRATO',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Procainamida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (619,51,4,8,2,12,2,9,1700,'SM-51-00009',NULL,NULL,NULL,NULL,NULL,'PROCAINAMIDA 500 MG CAJA X 30 TABLETAS','PROCAINAMIDA CLORHIDRATO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Procainamida 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (620,51,5,10,2,10,2,9,1700,'SM-51-00010',NULL,NULL,NULL,NULL,NULL,'DISOPIRAMIDA 500 MG CAJA X 10 TABLETAS','DISOPIRAMIDA FOSFATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Antiarrítmico para arritmias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (621,51,5,10,2,11,2,9,1700,'SM-51-00011',NULL,NULL,NULL,NULL,NULL,'DISOPIRAMIDA 500 MG CAJA X 20 TABLETAS','DISOPIRAMIDA FOSFATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Disopiramida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (622,51,5,10,2,12,2,9,1700,'SM-51-00012',NULL,NULL,NULL,NULL,NULL,'DISOPIRAMIDA 500 MG CAJA X 30 TABLETAS','DISOPIRAMIDA FOSFATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Disopiramida 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (623,51,6,11,2,10,2,9,1700,'SM-51-00013',NULL,NULL,NULL,NULL,NULL,'FLECAINIDA 500 MG CAJA X 10 TABLETAS','FLECAINIDA ACETATO',6.50,1.50,1.19,9.75,7.74,10.00,150.00,18.00,1,0,1,'Antiarrítmico para arritmias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (624,51,6,11,2,11,2,9,1700,'SM-51-00014',NULL,NULL,NULL,NULL,NULL,'FLECAINIDA 500 MG CAJA X 20 TABLETAS','FLECAINIDA ACETATO',11.70,1.50,1.19,17.55,13.92,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Flecainida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (625,51,6,11,2,12,2,9,1700,'SM-51-00015',NULL,NULL,NULL,NULL,NULL,'FLECAINIDA 500 MG CAJA X 30 TABLETAS','FLECAINIDA ACETATO',16.20,1.50,1.19,24.30,19.28,10.00,110.00,12.00,1,0,1,'30 tabletas de Flecainida 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (626,52,2,2,2,10,2,9,1700,'SM-52-00001',NULL,NULL,NULL,NULL,NULL,'DIGOXINA 500 MG CAJA X 10 TABLETAS','DIGOXINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Cardiotónico para la insuficiencia cardíaca. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (627,52,2,2,2,11,2,9,1700,'SM-52-00002',NULL,NULL,NULL,NULL,NULL,'DIGOXINA 500 MG CAJA X 20 TABLETAS','DIGOXINA',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Digoxina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (628,52,2,2,2,12,2,9,1700,'SM-52-00003',NULL,NULL,NULL,NULL,NULL,'DIGOXINA 500 MG CAJA X 30 TABLETAS','DIGOXINA',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Digoxina 500 mg para insuficiencia cardíaca.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (629,52,3,9,2,10,2,9,1700,'SM-52-00004',NULL,NULL,NULL,NULL,NULL,'DOBUTAMINA 500 MG CAJA X 10 TABLETAS','DOBUTAMINA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Cardiotónico para insuficiencia cardíaca. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (630,52,3,9,2,11,2,9,1700,'SM-52-00005',NULL,NULL,NULL,NULL,NULL,'DOBUTAMINA 500 MG CAJA X 20 TABLETAS','DOBUTAMINA CLORHIDRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Dobutamina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (631,52,3,9,2,12,2,9,1700,'SM-52-00006',NULL,NULL,NULL,NULL,NULL,'DOBUTAMINA 500 MG CAJA X 30 TABLETAS','DOBUTAMINA CLORHIDRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Dobutamina 500 mg para insuficiencia cardíaca.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (632,52,4,8,2,10,2,9,1700,'SM-52-00007',NULL,NULL,NULL,NULL,NULL,'DOPAMINA 500 MG CAJA X 10 TABLETAS','DOPAMINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Cardiotónico para shock. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (633,52,4,8,2,11,2,9,1700,'SM-52-00008',NULL,NULL,NULL,NULL,NULL,'DOPAMINA 500 MG CAJA X 20 TABLETAS','DOPAMINA CLORHIDRATO',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Dopamina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (634,52,4,8,2,12,2,9,1700,'SM-52-00009',NULL,NULL,NULL,NULL,NULL,'DOPAMINA 500 MG CAJA X 30 TABLETAS','DOPAMINA CLORHIDRATO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Dopamina 500 mg para shock.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (635,52,5,10,2,10,2,9,1700,'SM-52-00010',NULL,NULL,NULL,NULL,NULL,'NOREPINEFRINA 500 MG CAJA X 10 TABLETAS','NOREPINEFRINA BITARTRATO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Cardiotónico para shock. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (636,52,5,10,2,11,2,9,1700,'SM-52-00011',NULL,NULL,NULL,NULL,NULL,'NOREPINEFRINA 500 MG CAJA X 20 TABLETAS','NOREPINEFRINA BITARTRATO',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Norepinefrina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (637,52,5,10,2,12,2,9,1700,'SM-52-00012',NULL,NULL,NULL,NULL,NULL,'NOREPINEFRINA 500 MG CAJA X 30 TABLETAS','NOREPINEFRINA BITARTRATO',17.50,1.50,1.19,26.25,20.83,10.00,100.00,10.00,1,0,1,'30 tabletas de Norepinefrina 500 mg para shock.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (638,52,6,11,2,10,2,9,1700,'SM-52-00013',NULL,NULL,NULL,NULL,NULL,'EPINEFRINA 500 MG CAJA X 10 TABLETAS','EPINEFRINA',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Cardiotónico para paro cardíaco. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (639,52,6,11,2,11,2,9,1700,'SM-52-00014',NULL,NULL,NULL,NULL,NULL,'EPINEFRINA 500 MG CAJA X 20 TABLETAS','EPINEFRINA',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Epinefrina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (640,52,6,11,2,12,2,9,1700,'SM-52-00015',NULL,NULL,NULL,NULL,NULL,'EPINEFRINA 500 MG CAJA X 30 TABLETAS','EPINEFRINA',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Epinefrina 500 mg para paro cardíaco.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (641,53,2,2,2,10,2,9,1700,'SM-53-00001',NULL,NULL,NULL,NULL,NULL,'ATORVASTATINA 500 MG CAJA X 10 TABLETAS','ATORVASTATINA CALCICA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Hipolipemiante para el colesterol. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (642,53,2,2,2,11,2,9,1700,'SM-53-00002',NULL,NULL,NULL,NULL,NULL,'ATORVASTATINA 500 MG CAJA X 20 TABLETAS','ATORVASTATINA CALCICA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Atorvastatina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (643,53,2,2,2,12,2,9,1700,'SM-53-00003',NULL,NULL,NULL,NULL,NULL,'ATORVASTATINA 500 MG CAJA X 30 TABLETAS','ATORVASTATINA CALCICA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Atorvastatina 500 mg para colesterol.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (644,53,3,9,2,10,2,9,1700,'SM-53-00004',NULL,NULL,NULL,NULL,NULL,'SIMVASTATINA 500 MG CAJA X 10 TABLETAS','SIMVASTATINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Hipolipemiante para colesterol. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (645,53,3,9,2,11,2,9,1700,'SM-53-00005',NULL,NULL,NULL,NULL,NULL,'SIMVASTATINA 500 MG CAJA X 20 TABLETAS','SIMVASTATINA',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Simvastatina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (646,53,3,9,2,12,2,9,1700,'SM-53-00006',NULL,NULL,NULL,NULL,NULL,'SIMVASTATINA 500 MG CAJA X 30 TABLETAS','SIMVASTATINA',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Simvastatina 500 mg para colesterol.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (647,53,4,8,2,10,2,9,1700,'SM-53-00007',NULL,NULL,NULL,NULL,NULL,'ROSUVASTATINA 500 MG CAJA X 10 TABLETAS','ROSUVASTATINA CALCICA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Hipolipemiante para colesterol. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (648,53,4,8,2,11,2,9,1700,'SM-53-00008',NULL,NULL,NULL,NULL,NULL,'ROSUVASTATINA 500 MG CAJA X 20 TABLETAS','ROSUVASTATINA CALCICA',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Rosuvastatina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (649,53,4,8,2,12,2,9,1700,'SM-53-00009',NULL,NULL,NULL,NULL,NULL,'ROSUVASTATINA 500 MG CAJA X 30 TABLETAS','ROSUVASTATINA CALCICA',17.50,1.50,1.19,26.25,20.83,10.00,100.00,10.00,1,0,1,'30 tabletas de Rosuvastatina 500 mg para colesterol.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (650,53,5,10,2,10,2,9,1700,'SM-53-00010',NULL,NULL,NULL,NULL,NULL,'FENOFIBRATO 500 MG CAJA X 10 TABLETAS','FENOFIBRATO',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Hipolipemiante para triglicéridos. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (651,53,5,10,2,11,2,9,1700,'SM-53-00011',NULL,NULL,NULL,NULL,NULL,'FENOFIBRATO 500 MG CAJA X 20 TABLETAS','FENOFIBRATO',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Fenofibrato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (652,53,5,10,2,12,2,9,1700,'SM-53-00012',NULL,NULL,NULL,NULL,NULL,'FENOFIBRATO 500 MG CAJA X 30 TABLETAS','FENOFIBRATO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Fenofibrato 500 mg para triglicéridos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (653,53,6,11,2,10,2,9,1700,'SM-53-00013',NULL,NULL,NULL,NULL,NULL,'GEMFIBROZIL 500 MG CAJA X 10 TABLETAS','GEMFIBROZIL',4.00,1.50,1.19,6.00,4.76,10.00,180.00,22.00,1,0,1,'Hipolipemiante para triglicéridos. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (654,53,6,11,2,11,2,9,1700,'SM-53-00014',NULL,NULL,NULL,NULL,NULL,'GEMFIBROZIL 500 MG CAJA X 20 TABLETAS','GEMFIBROZIL',7.20,1.50,1.19,10.80,8.57,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Gemfibrozil 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (655,53,6,11,2,12,2,9,1700,'SM-53-00015',NULL,NULL,NULL,NULL,NULL,'GEMFIBROZIL 500 MG CAJA X 30 TABLETAS','GEMFIBROZIL',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,0,1,'30 tabletas de Gemfibrozil 500 mg para triglicéridos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (656,54,2,2,2,10,2,9,1700,'SM-54-00001',NULL,NULL,NULL,NULL,NULL,'ORLISTAT 500 MG CAJA X 10 TABLETAS','ORLISTAT',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,0,0,1,'Antiobesidad para la pérdida de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (657,54,2,2,2,11,2,9,1700,'SM-54-00002',NULL,NULL,NULL,NULL,NULL,'ORLISTAT 500 MG CAJA X 20 TABLETAS','ORLISTAT',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,0,0,1,'Caja de 20 tabletas de Orlistat 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (658,54,2,2,2,12,2,9,1700,'SM-54-00003',NULL,NULL,NULL,NULL,NULL,'ORLISTAT 500 MG CAJA X 30 TABLETAS','ORLISTAT',17.50,1.50,1.19,26.25,20.83,10.00,100.00,10.00,0,0,1,'30 tabletas de Orlistat 500 mg para obesidad.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (659,54,3,9,2,10,2,9,1700,'SM-54-00004',NULL,NULL,NULL,NULL,NULL,'SIBUTRAMINA 500 MG CAJA X 10 TABLETAS','SIBUTRAMINA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,1,1,'Antiobesidad para control de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (660,54,3,9,2,11,2,9,1700,'SM-54-00005',NULL,NULL,NULL,NULL,NULL,'SIBUTRAMINA 500 MG CAJA X 20 TABLETAS','SIBUTRAMINA CLORHIDRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,1,1,'Caja de 20 tabletas de Sibutramina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (661,54,3,9,2,12,2,9,1700,'SM-54-00006',NULL,NULL,NULL,NULL,NULL,'SIBUTRAMINA 500 MG CAJA X 30 TABLETAS','SIBUTRAMINA CLORHIDRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,1,1,'30 tabletas de Sibutramina 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (662,54,4,8,2,10,2,9,1700,'SM-54-00007',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 10 TABLETAS','METFORMINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,1,0,1,'Antiobesidad para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (663,54,4,8,2,11,2,9,1700,'SM-54-00008',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 20 TABLETAS','METFORMINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Metformina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (664,54,4,8,2,12,2,9,1700,'SM-54-00009',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 30 TABLETAS','METFORMINA CLORHIDRATO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,1,0,1,'30 tabletas de Metformina 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (665,54,5,10,2,10,2,9,1700,'SM-54-00010',NULL,NULL,NULL,NULL,NULL,'LIRAGLUTIDA 500 MG CAJA X 10 TABLETAS','LIRAGLUTIDA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'Antiobesidad para control de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (666,54,5,10,2,11,2,9,1700,'SM-54-00011',NULL,NULL,NULL,NULL,NULL,'LIRAGLUTIDA 500 MG CAJA X 20 TABLETAS','LIRAGLUTIDA',27.00,1.50,1.19,40.50,32.13,10.00,90.00,9.00,1,0,1,'Caja de 20 tabletas de Liraglutida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (667,54,5,10,2,12,2,9,1700,'SM-54-00012',NULL,NULL,NULL,NULL,NULL,'LIRAGLUTIDA 500 MG CAJA X 30 TABLETAS','LIRAGLUTIDA',37.50,1.50,1.19,56.25,44.63,10.00,80.00,8.00,1,0,1,'30 tabletas de Liraglutida 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (668,54,6,11,2,10,2,9,1700,'SM-54-00013',NULL,NULL,NULL,NULL,NULL,'NALTREXONA 500 MG CAJA X 10 TABLETAS','NALTREXONA CLORHIDRATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Antiobesidad para control de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (669,54,6,11,2,11,2,9,1700,'SM-54-00014',NULL,NULL,NULL,NULL,NULL,'NALTREXONA 500 MG CAJA X 20 TABLETAS','NALTREXONA CLORHIDRATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Naltrexona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (670,54,6,11,2,12,2,9,1700,'SM-54-00015',NULL,NULL,NULL,NULL,NULL,'NALTREXONA 500 MG CAJA X 30 TABLETAS','NALTREXONA CLORHIDRATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Naltrexona 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (671,55,2,2,2,10,2,9,1700,'SM-55-00001',NULL,NULL,NULL,NULL,NULL,'INSULINA 500 MG CAJA X 10 TABLETAS','INSULINA HUMANA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,0,1,'Antidiabético para diabetes tipo 1. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (672,55,2,2,2,11,2,9,1700,'SM-55-00002',NULL,NULL,NULL,NULL,NULL,'INSULINA 500 MG CAJA X 20 TABLETAS','INSULINA HUMANA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,0,1,'Caja de 20 tabletas de Insulina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (673,55,2,2,2,12,2,9,1700,'SM-55-00003',NULL,NULL,NULL,NULL,NULL,'INSULINA 500 MG CAJA X 30 TABLETAS','INSULINA HUMANA',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,0,1,'30 tabletas de Insulina 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (674,55,3,9,2,10,2,9,1700,'SM-55-00004',NULL,NULL,NULL,NULL,NULL,'GLIMEPIRIDA 500 MG CAJA X 10 TABLETAS','GLIMEPIRIDA',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (675,55,3,9,2,11,2,9,1700,'SM-55-00005',NULL,NULL,NULL,NULL,NULL,'GLIMEPIRIDA 500 MG CAJA X 20 TABLETAS','GLIMEPIRIDA',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Glimepirida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (676,55,3,9,2,12,2,9,1700,'SM-55-00006',NULL,NULL,NULL,NULL,NULL,'GLIMEPIRIDA 500 MG CAJA X 30 TABLETAS','GLIMEPIRIDA',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Glimepirida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (677,55,4,8,2,10,2,9,1700,'SM-55-00007',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 500 MG CAJA X 10 TABLETAS','PIOGLITAZONA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (678,55,4,8,2,11,2,9,1700,'SM-55-00008',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 500 MG CAJA X 20 TABLETAS','PIOGLITAZONA CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Pioglitazona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (679,55,4,8,2,12,2,9,1700,'SM-55-00009',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 500 MG CAJA X 30 TABLETAS','PIOGLITAZONA CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Pioglitazona 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (680,55,5,10,2,10,2,9,1700,'SM-55-00010',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 500 MG CAJA X 10 TABLETAS','REPAGLINIDA',4.00,1.50,1.19,6.00,4.76,10.00,180.00,22.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (681,55,5,10,2,11,2,9,1700,'SM-55-00011',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 500 MG CAJA X 20 TABLETAS','REPAGLINIDA',7.20,1.50,1.19,10.80,8.57,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Repaglinida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (682,55,5,10,2,12,2,9,1700,'SM-55-00012',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 500 MG CAJA X 30 TABLETAS','REPAGLINIDA',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,0,1,'30 tabletas de Repaglinida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (683,55,6,11,2,10,2,9,1700,'SM-55-00013',NULL,NULL,NULL,NULL,NULL,'EXENATIDA 500 MG CAJA X 10 TABLETAS','EXENATIDA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (684,55,6,11,2,11,2,9,1700,'SM-55-00014',NULL,NULL,NULL,NULL,NULL,'EXENATIDA 500 MG CAJA X 20 TABLETAS','EXENATIDA',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,0,1,'Caja de 20 tabletas de Exenatida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (685,55,6,11,2,12,2,9,1700,'SM-55-00015',NULL,NULL,NULL,NULL,NULL,'EXENATIDA 500 MG CAJA X 30 TABLETAS','EXENATIDA',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,0,1,'30 tabletas de Exenatida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (686,56,2,2,2,10,2,9,1700,'SM-56-00001',NULL,NULL,NULL,NULL,NULL,'LEVOTIROXINA 500 MG CAJA X 10 TABLETAS','LEVOTIROXINA SODICA',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,1,0,1,'Hormona para el hipotiroidismo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (687,56,2,2,2,11,2,9,1700,'SM-56-00002',NULL,NULL,NULL,NULL,NULL,'LEVOTIROXINA 500 MG CAJA X 20 TABLETAS','LEVOTIROXINA SODICA',7.20,1.50,1.19,10.80,8.57,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Levotiroxina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (688,56,2,2,2,12,2,9,1700,'SM-56-00003',NULL,NULL,NULL,NULL,NULL,'LEVOTIROXINA 500 MG CAJA X 30 TABLETAS','LEVOTIROXINA SODICA',10.00,1.50,1.19,15.00,11.90,10.00,130.00,16.00,1,0,1,'30 tabletas de Levotiroxina 500 mg para hipotiroidismo.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (689,56,3,9,2,10,2,9,1700,'SM-56-00004',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 500 MG CAJA X 10 TABLETAS','PREDNISONA',3.50,1.50,1.19,5.25,4.17,10.00,180.00,22.00,1,0,1,'Hormona para inflamación. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (690,56,3,9,2,11,2,9,1700,'SM-56-00005',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 500 MG CAJA X 20 TABLETAS','PREDNISONA',6.30,1.50,1.19,9.45,7.50,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Prednisona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (691,56,3,9,2,12,2,9,1700,'SM-56-00006',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 500 MG CAJA X 30 TABLETAS','PREDNISONA',8.80,1.50,1.19,13.20,10.47,10.00,140.00,18.00,1,0,1,'30 tabletas de Prednisona 500 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (692,56,4,8,2,10,2,9,1700,'SM-56-00007',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 500 MG CAJA X 10 TABLETAS','DEXAMETASONA',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Hormona para inflamación y alergias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (693,56,4,8,2,11,2,9,1700,'SM-56-00008',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 500 MG CAJA X 20 TABLETAS','DEXAMETASONA',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Dexametasona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (694,56,4,8,2,12,2,9,1700,'SM-56-00009',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 500 MG CAJA X 30 TABLETAS','DEXAMETASONA',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Dexametasona 500 mg para alergias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (695,56,5,10,2,10,2,9,1700,'SM-56-00010',NULL,NULL,NULL,NULL,NULL,'ESTRADIOL 500 MG CAJA X 10 TABLETAS','ESTRADIOL',6.00,1.50,1.19,9.00,7.14,10.00,160.00,20.00,1,0,1,'Hormona para terapia hormonal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (696,56,5,10,2,11,2,9,1700,'SM-56-00011',NULL,NULL,NULL,NULL,NULL,'ESTRADIOL 500 MG CAJA X 20 TABLETAS','ESTRADIOL',10.80,1.50,1.19,16.20,12.85,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Estradiol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (697,56,5,10,2,12,2,9,1700,'SM-56-00012',NULL,NULL,NULL,NULL,NULL,'ESTRADIOL 500 MG CAJA X 30 TABLETAS','ESTRADIOL',15.00,1.50,1.19,22.50,17.85,10.00,120.00,15.00,1,0,1,'30 tabletas de Estradiol 500 mg para terapia hormonal.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (698,56,6,11,2,10,2,9,1700,'SM-56-00013',NULL,NULL,NULL,NULL,NULL,'PROGESTERONA 500 MG CAJA X 10 TABLETAS','PROGESTERONA',5.50,1.50,1.19,8.25,6.55,10.00,170.00,22.00,1,0,1,'Hormona para terapia hormonal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (699,56,6,11,2,11,2,9,1700,'SM-56-00014',NULL,NULL,NULL,NULL,NULL,'PROGESTERONA 500 MG CAJA X 20 TABLETAS','PROGESTERONA',9.90,1.50,1.19,14.85,11.78,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Progesterona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (700,56,6,11,2,12,2,9,1700,'SM-56-00015',NULL,NULL,NULL,NULL,NULL,'PROGESTERONA 500 MG CAJA X 30 TABLETAS','PROGESTERONA',13.80,1.50,1.19,20.70,16.42,10.00,130.00,16.00,1,0,1,'30 tabletas de Progesterona 500 mg para terapia hormonal.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (701,57,2,2,2,10,7,9,1700,'SM-57-00001',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 10 TABLETAS','LORATADINA',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (702,57,2,2,2,11,7,9,1700,'SM-57-00002',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 20 TABLETAS','LORATADINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Loratadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (703,57,2,2,2,12,7,9,1700,'SM-57-00003',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 30 TABLETAS','LORATADINA',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Loratadina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (704,57,3,9,2,10,7,9,1700,'SM-57-00004',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 5 MG CAJA X 10 TABLETAS','CETIRIZINA DIHIDROCLORURO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (705,57,3,9,2,11,7,9,1700,'SM-57-00005',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 5 MG CAJA X 20 TABLETAS','CETIRIZINA DIHIDROCLORURO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Cetirizina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (706,57,3,9,2,12,7,9,1700,'SM-57-00006',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 5 MG CAJA X 30 TABLETAS','CETIRIZINA DIHIDROCLORURO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Cetirizina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (707,57,4,8,2,10,7,9,1700,'SM-57-00007',NULL,NULL,NULL,NULL,NULL,'FEXOFENADINA 5 MG CAJA X 10 TABLETAS','FEXOFENADINA CLORHIDRATO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (708,57,4,8,2,11,7,9,1700,'SM-57-00008',NULL,NULL,NULL,NULL,NULL,'FEXOFENADINA 5 MG CAJA X 20 TABLETAS','FEXOFENADINA CLORHIDRATO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Fexofenadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (709,57,4,8,2,12,7,9,1700,'SM-57-00009',NULL,NULL,NULL,NULL,NULL,'FEXOFENADINA 5 MG CAJA X 30 TABLETAS','FEXOFENADINA CLORHIDRATO',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Fexofenadina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (710,57,5,10,2,10,5,9,1700,'SM-57-00010',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 10 TABLETAS','CLORFENIRAMINA MALEATO',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Antialérgico para alergias. 25 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (711,57,5,10,2,11,5,9,1700,'SM-57-00011',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 20 TABLETAS','CLORFENIRAMINA MALEATO',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Clorfeniramina 25 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (712,57,5,10,2,12,5,9,1700,'SM-57-00012',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 30 TABLETAS','CLORFENIRAMINA MALEATO',4.50,1.50,1.19,6.75,5.36,10.00,140.00,18.00,0,0,1,'30 tabletas de Clorfeniramina 25 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (713,57,6,11,2,10,7,9,1700,'SM-57-00013',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 5 MG CAJA X 10 TABLETAS','DESLORATADINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (714,57,6,11,2,11,7,9,1700,'SM-57-00014',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 5 MG CAJA X 20 TABLETAS','DESLORATADINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Desloratadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (715,57,6,11,2,12,7,9,1700,'SM-57-00015',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 5 MG CAJA X 30 TABLETAS','DESLORATADINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Desloratadina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (716,65,1,1,1,1,1,9,1700,'SM-65-00001',NULL,'LT-HP-1001','978-0-13-235088-4','SN-HP-2023-001','HP PAVILION 15','LAPTOP HP PAVILION 15.6 PULGADAS INTEL CORE I5',NULL,500.00,1.50,1.19,750.00,595.00,5.00,30.00,8.00,0,0,0,'Laptop HP Pavilion con pantalla de 15.6 pulgadas, procesador Intel Core i5, 8GB RAM y 256GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (717,65,1,1,1,1,1,9,1700,'SM-65-00002',NULL,'LT-HP-1002','978-0-13-235089-1','SN-HP-2023-002','HP ENVY X360','LAPTOP HP ENVY X360 13.3 PULGADAS',NULL,650.00,1.50,1.19,975.00,773.50,5.00,25.00,6.00,0,0,0,'Laptop convertible HP Envy x360 con pantalla táctil de 13.3 pulgadas, Intel Core i7, 16GB RAM y 512GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (718,65,1,1,1,1,1,9,1700,'SM-65-00003',NULL,'LT-DELL-2001','978-0-13-235090-7','SN-DELL-2023-001','DELL XPS 13','LAPTOP DELL XPS 13 9310',NULL,750.00,1.50,1.19,1125.00,892.50,5.00,20.00,5.00,0,0,0,'Laptop Dell XPS 13 con pantalla InfinityEdge de 13.4 pulgadas, Intel Core i7, 16GB RAM y 512GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (719,65,1,1,1,1,1,9,1700,'SM-65-00004',NULL,'LT-LEN-3001','978-0-13-235091-4','SN-LEN-2023-001','LENOVO THINKPAD X1','LAPTOP LENOVO THINKPAD X1 CARBON',NULL,600.00,1.50,1.19,900.00,714.00,5.00,25.00,6.00,0,0,0,'Laptop Lenovo ThinkPad X1 Carbon con pantalla de 14 pulgadas, Intel Core i5, 8GB RAM y 256GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (720,65,1,1,1,1,1,9,1700,'SM-65-00005',NULL,'LT-APP-4001','978-0-13-235092-1','SN-APP-2023-001','MACBOOK AIR 13','LAPTOP MACBOOK AIR 13.6 PULGADAS',NULL,850.00,1.50,1.19,1275.00,1011.50,5.00,20.00,5.00,0,0,0,'Laptop Apple MacBook Air con chip M2, pantalla de 13.6 pulgadas, 8GB RAM y 256GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (721,66,1,1,1,1,1,9,1700,'SM-66-00001',NULL,'TB-SAM-1001','978-0-13-235093-8','SN-SAM-2023-001','SAMSUNG GALAXY TAB S8','TABLET SAMSUNG GALAXY TAB S8 11 PULGADAS',NULL,400.00,1.50,1.19,600.00,476.00,5.00,30.00,8.00,0,0,0,'Tablet Samsung Galaxy Tab S8 con pantalla de 11 pulgadas, 8GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (722,66,1,1,1,1,1,9,1700,'SM-66-00002',NULL,'TB-APP-2001','978-0-13-235094-5','SN-APP-2023-002','IPAD PRO 11','TABLET IPAD PRO 11 PULGADAS M2',NULL,550.00,1.50,1.19,825.00,654.50,5.00,25.00,6.00,0,0,0,'Tablet Apple iPad Pro con chip M2, pantalla de 11 pulgadas, 8GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (723,66,1,1,1,1,1,9,1700,'SM-66-00003',NULL,'TB-SAM-1002','978-0-13-235095-2','SN-SAM-2023-002','SAMSUNG GALAXY TAB A8','TABLET SAMSUNG GALAXY TAB A8 10.5 PULGADAS',NULL,250.00,1.50,1.19,375.00,297.50,5.00,35.00,10.00,0,0,0,'Tablet Samsung Galaxy Tab A8 con pantalla de 10.5 pulgadas, 4GB RAM y 64GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (724,66,1,1,1,1,1,9,1700,'SM-66-00004',NULL,'TB-LEN-3001','978-0-13-235096-9','SN-LEN-2023-002','LENOVO TAB P11','TABLET LENOVO TAB P11 11.5 PULGADAS',NULL,300.00,1.50,1.19,450.00,357.00,5.00,30.00,8.00,0,0,0,'Tablet Lenovo Tab P11 con pantalla de 11.5 pulgadas, 6GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (725,66,1,1,1,1,1,9,1700,'SM-66-00005',NULL,'TB-HP-1001','978-0-13-235097-6','SN-HP-2023-003','HP SLATE 10','TABLET HP SLATE 10 PULGADAS',NULL,200.00,1.50,1.19,300.00,238.00,5.00,35.00,10.00,0,0,0,'Tablet HP Slate con pantalla de 10 pulgadas, 4GB RAM y 64GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (726,67,1,1,1,1,1,9,1700,'SM-67-00001',NULL,'SM-SAM-1001','978-0-13-235098-3','SN-SAM-2023-003','SAMSUNG GALAXY S23','SMARTPHONE SAMSUNG GALAXY S23 6.1 PULGADAS',NULL,450.00,1.50,1.19,675.00,535.50,5.00,30.00,8.00,0,0,0,'Smartphone Samsung Galaxy S23 con pantalla de 6.1 pulgadas, 8GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (727,67,1,1,1,1,1,9,1700,'SM-67-00002',NULL,'SM-APP-2001','978-0-13-235099-0','SN-APP-2023-003','IPHONE 15 PRO','SMARTPHONE IPHONE 15 PRO 6.1 PULGADAS',NULL,600.00,1.50,1.19,900.00,714.00,5.00,25.00,6.00,0,0,0,'Smartphone Apple iPhone 15 Pro con pantalla de 6.1 pulgadas, 8GB RAM y 256GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (728,67,1,1,1,1,1,9,1700,'SM-67-00003',NULL,'SM-SAM-1002','978-0-13-235100-3','SN-SAM-2023-004','SAMSUNG GALAXY A54','SMARTPHONE SAMSUNG GALAXY A54 6.5 PULGADAS',NULL,280.00,1.50,1.19,420.00,333.20,5.00,35.00,10.00,0,0,0,'Smartphone Samsung Galaxy A54 con pantalla de 6.5 pulgadas, 6GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (729,67,1,1,1,1,1,9,1700,'SM-67-00004',NULL,'SM-LEN-3001','978-0-13-235101-0','SN-LEN-2023-003','LENOVO PHAB 2','SMARTPHONE LENOVO PHAB 2 6.4 PULGADAS',NULL,150.00,1.50,1.19,225.00,178.50,5.00,40.00,12.00,0,0,0,'Smartphone Lenovo Phab 2 con pantalla de 6.4 pulgadas, 3GB RAM y 32GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (730,67,1,1,1,1,1,9,1700,'SM-67-00005',NULL,'SM-HP-1001','978-0-13-235102-7','SN-HP-2023-004','HP ELITE X3','SMARTPHONE HP ELITE X3 5.96 PULGADAS',NULL,180.00,1.50,1.19,270.00,214.20,5.00,35.00,10.00,0,0,0,'Smartphone HP Elite X3 con pantalla de 5.96 pulgadas, 4GB RAM y 64GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (731,68,1,1,1,1,1,9,1700,'SM-68-00001',NULL,'TV-SAM-1001','978-0-13-235103-4','SN-SAM-2023-005','SAMSUNG SMART TV 55','TELEVISOR SAMSUNG SMART TV 55 PULGADAS 4K',NULL,550.00,1.50,1.19,825.00,654.50,5.00,20.00,5.00,0,0,0,'Televisor Samsung Smart TV de 55 pulgadas con resolución 4K y tecnología HDR.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (732,68,1,1,1,1,1,9,1700,'SM-68-00002',NULL,'TV-APP-2001','978-0-13-235104-1','SN-APP-2023-004','APPLE TV 4K','TELEVISOR APPLE TV 4K 64GB',NULL,150.00,1.50,1.19,225.00,178.50,5.00,30.00,8.00,0,0,0,'Dispositivo Apple TV 4K con 64GB de almacenamiento y soporte para contenido en 4K.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (733,68,1,1,1,1,1,9,1700,'SM-68-00003',NULL,'TV-SAM-1002','978-0-13-235105-8','SN-SAM-2023-006','SAMSUNG SMART TV 43','TELEVISOR SAMSUNG SMART TV 43 PULGADAS FULL HD',NULL,350.00,1.50,1.19,525.00,416.50,5.00,25.00,6.00,0,0,0,'Televisor Samsung Smart TV de 43 pulgadas con resolución Full HD y tecnología PurColor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (734,68,1,1,1,1,1,9,1700,'SM-68-00004',NULL,'TV-LEN-3001','978-0-13-235106-5','SN-LEN-2023-004','LENOVO SMART DISPLAY','TELEVISOR LENOVO SMART DISPLAY 10 PULGADAS',NULL,120.00,1.50,1.19,180.00,142.80,5.00,35.00,10.00,0,0,0,'Dispositivo Lenovo Smart Display con pantalla de 10 pulgadas y asistente de voz integrado.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (735,68,1,1,1,1,1,9,1700,'SM-68-00005',NULL,'TV-HP-1001','978-0-13-235107-2','SN-HP-2023-005','HP MEDIA SHOW','TELEVISOR HP MEDIA SHOW 15.6 PULGADAS',NULL,130.00,1.50,1.19,195.00,154.70,5.00,30.00,8.00,0,0,0,'Monitor HP Media Show de 15.6 pulgadas para presentaciones y contenido multimedia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (736,69,1,1,1,1,1,9,1700,'SM-69-00001',NULL,'KB-SAM-1001','978-0-13-235108-9','SN-SAM-2023-007','SAMSUNG SMART KEYBOARD','TECLADO SAMSUNG SMART KEYBOARD INALÁMBRICO',NULL,45.00,1.50,1.19,67.50,53.55,10.00,50.00,15.00,0,0,0,'Teclado Samsung Smart Keyboard inalámbrico con conectividad Bluetooth y batería recargable.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (737,69,1,1,1,1,1,9,1700,'SM-69-00002',NULL,'KB-APP-2001','978-0-13-235109-6','SN-APP-2023-005','APPLE MAGIC KEYBOARD','TECLADO APPLE MAGIC KEYBOARD INALÁMBRICO',NULL,80.00,1.50,1.19,120.00,95.20,10.00,40.00,12.00,0,0,0,'Teclado Apple Magic Keyboard inalámbrico con diseño compacto y batería recargable.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (738,69,1,1,1,1,1,9,1700,'SM-69-00003',NULL,'KB-LEN-3001','978-0-13-235110-2','SN-LEN-2023-005','LENOVO WIRED KEYBOARD','TECLADO LENOVO WIRED KEYBOARD USB',NULL,25.00,1.50,1.19,37.50,29.75,10.00,60.00,20.00,0,0,0,'Teclado Lenovo con cable USB, diseño estándar y teclas de bajo perfil.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (739,69,1,1,1,1,1,9,1700,'SM-69-00004',NULL,'KB-HP-1001','978-0-13-235111-9','SN-HP-2023-006','HP WIRELESS KEYBOARD','TECLADO HP WIRELESS KEYBOARD INALÁMBRICO',NULL,35.00,1.50,1.19,52.50,41.65,10.00,50.00,15.00,0,0,0,'Teclado HP Wireless Keyboard inalámbrico con alcance de hasta 10 metros.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (740,69,1,1,1,1,1,9,1700,'SM-69-00005',NULL,'KB-DELL-2001','978-0-13-235112-6','SN-DELL-2023-002','DELL WIRELESS KEYBOARD','TECLADO DELL WIRELESS KEYBOARD INALÁMBRICO',NULL,30.00,1.50,1.19,45.00,35.70,10.00,55.00,18.00,0,0,0,'Teclado Dell Wireless Keyboard inalámbrico con diseño ergonómico y batería de larga duración.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (741,75,1,1,1,1,1,9,1700,'SM-75-00001',NULL,'LIB-1001','978-0-13-235113-3',NULL,NULL,'CIEN AÑOS DE SOLEDAD',NULL,15.00,1.50,1.19,22.50,17.85,10.00,50.00,15.00,0,0,0,'Novela de Gabriel García Márquez, una obra maestra del realismo mágico que narra la historia de la familia Buendía.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (742,75,1,1,1,1,1,9,1700,'SM-75-00002',NULL,'LIB-1002','978-0-13-235114-0',NULL,NULL,'EL AMOR EN LOS TIEMPOS DEL CÓLERA',NULL,14.00,1.50,1.19,21.00,16.66,10.00,45.00,12.00,0,0,0,'Otra gran novela de Gabriel García Márquez que explora el amor a través del tiempo y la espera.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (743,75,1,1,1,1,1,9,1700,'SM-75-00003',NULL,'LIB-1003','978-0-13-235115-7',NULL,NULL,'LA CASA DE LOS ESPÍRITUS',NULL,13.00,1.50,1.19,19.50,15.47,10.00,40.00,10.00,0,0,0,'Novela de Isabel Allende que narra la historia de la familia Trueba a través de generaciones.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (744,75,1,1,1,1,1,9,1700,'SM-75-00004',NULL,'LIB-1004','978-0-13-235116-4',NULL,NULL,'LA SOMBRA DEL VIENTO',NULL,14.50,1.50,1.19,21.75,17.26,10.00,42.00,11.00,0,0,0,'Novela de Carlos Ruiz Zafón, un thriller literario ambientado en la Barcelona de posguerra.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (745,75,1,1,1,1,1,9,1700,'SM-75-00005',NULL,'LIB-1005','978-0-13-235117-1',NULL,NULL,'EL JUEGO DE ENDER',NULL,12.00,1.50,1.19,18.00,14.28,10.00,48.00,14.00,0,0,0,'Novela de ciencia ficción de Orson Scott Card sobre un niño genio en una guerra intergaláctica.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (746,76,1,1,1,1,1,9,1700,'SM-76-00001',NULL,'LIB-2001','978-0-13-235118-8',NULL,NULL,'IT (ESO)',NULL,16.00,1.50,1.19,24.00,19.04,10.00,35.00,8.00,0,0,0,'Novela de Stephen King que narra la historia de un grupo de niños que enfrentan a un payaso malvado.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (747,76,1,1,1,1,1,9,1700,'SM-76-00002',NULL,'LIB-2002','978-0-13-235119-5',NULL,NULL,'EL RESPLANDOR',NULL,14.00,1.50,1.19,21.00,16.66,10.00,38.00,10.00,0,0,0,'Novela de terror de Stephen King sobre un hotel encantado y un escritor que enloquece.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (748,76,1,1,1,1,1,9,1700,'SM-76-00003',NULL,'LIB-2003','978-0-13-235120-1',NULL,NULL,'LA CARRETERA',NULL,12.50,1.50,1.19,18.75,14.88,10.00,40.00,12.00,0,0,0,'Novela posapocalíptica de Cormac McCarthy sobre un padre y su hijo en un mundo devastado.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (749,76,1,1,1,1,1,9,1700,'SM-76-00004',NULL,'LIB-2004','978-0-13-235121-8',NULL,NULL,'LOS JUEGOS DEL HAMBRE',NULL,13.00,1.50,1.19,19.50,15.47,10.00,45.00,13.00,0,0,0,'Novela distópica de Suzanne Collins sobre un reality show de supervivencia en un mundo futuro.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (750,76,1,1,1,1,1,9,1700,'SM-76-00005',NULL,'LIB-2005','978-0-13-235122-5',NULL,NULL,'EL PSICOANALISTA',NULL,11.50,1.50,1.19,17.25,13.68,10.00,42.00,11.00,0,0,0,'Thriller psicológico de John Katzenbach sobre un psicoanalista que recibe una amenaza anónima.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (751,77,1,1,1,1,1,9,1700,'SM-77-00001',NULL,'LIB-3001','978-0-13-235123-2',NULL,NULL,'BREVE HISTORIA DEL TIEMPO',NULL,18.00,1.50,1.19,27.00,21.42,10.00,30.00,6.00,0,0,0,'Libro de Stephen Hawking que explora los conceptos fundamentales del universo y el tiempo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (752,77,1,1,1,1,1,9,1700,'SM-77-00002',NULL,'LIB-3002','978-0-13-235124-9',NULL,NULL,'EL GEN EGOÍSTA',NULL,16.00,1.50,1.19,24.00,19.04,10.00,35.00,8.00,0,0,0,'Libro de Richard Dawkins que explica la evolución desde la perspectiva del gen.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (753,77,1,1,1,1,1,9,1700,'SM-77-00003',NULL,'LIB-3003','978-0-13-235125-6',NULL,NULL,'SAPIENS: DE ANIMALES A DIOSES',NULL,17.00,1.50,1.19,25.50,20.23,10.00,32.00,7.00,0,0,0,'Libro de Yuval Noah Harari que narra la historia de la humanidad desde la prehistoria.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (754,77,1,1,1,1,1,9,1700,'SM-77-00004',NULL,'LIB-3004','978-0-13-235126-3',NULL,NULL,'EL MUNDO Y SUS DEMONIOS',NULL,15.50,1.50,1.19,23.25,18.45,10.00,38.00,10.00,0,0,0,'Libro de Carl Sagan que promueve el pensamiento crítico y la ciencia frente a la superstición.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (755,77,1,1,1,1,1,9,1700,'SM-77-00005',NULL,'LIB-3005','978-0-13-235127-0',NULL,NULL,'LA ESTRUCTURA DE LAS REVOLUCIONES CIENTÍFICAS',NULL,14.00,1.50,1.19,21.00,16.66,10.00,40.00,12.00,0,0,0,'Libro de Thomas Kuhn que analiza los paradigmas en la historia de la ciencia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (756,80,1,1,1,1,1,9,1700,'SM-80-00001',NULL,'LIB-4001','978-0-13-235128-7',NULL,NULL,'HISTORIA DE LA SEGUNDA GUERRA MUNDIAL',NULL,20.00,1.50,1.19,30.00,23.80,10.00,25.00,5.00,0,0,0,'Libro que relata los eventos clave de la Segunda Guerra Mundial, desde sus causas hasta su final.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (757,80,1,1,1,1,1,9,1700,'SM-80-00002',NULL,'LIB-4002','978-0-13-235129-4',NULL,NULL,'LOS ORÍGENES DEL TOTALITARISMO',NULL,18.00,1.50,1.19,27.00,21.42,10.00,30.00,6.00,0,0,0,'Libro de Hannah Arendt que analiza los regímenes totalitarios del siglo XX.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (758,80,1,1,1,1,1,9,1700,'SM-80-00003',NULL,'LIB-4003','978-0-13-235130-0',NULL,NULL,'HISTORIA DE LA FILOSOFÍA OCCIDENTAL',NULL,22.00,1.50,1.19,33.00,26.18,10.00,20.00,4.00,0,0,0,'Libro de Bertrand Russell que recorre la historia del pensamiento filosófico en Occidente.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (759,80,1,1,1,1,1,9,1700,'SM-80-00004',NULL,'LIB-4004','978-0-13-235131-7',NULL,NULL,'EL ARTE DE LA GUERRA',NULL,10.00,1.50,1.19,15.00,11.90,10.00,45.00,12.00,0,0,0,'Tratado militar de Sun Tzu que aborda estrategias y tácticas para el combate.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (760,80,1,1,1,1,1,9,1700,'SM-80-00005',NULL,'LIB-4005','978-0-13-235132-4',NULL,NULL,'HISTORIA DE BOLIVIA',NULL,12.00,1.50,1.19,18.00,14.28,10.00,40.00,10.00,0,0,0,'Libro que relata la historia de Bolivia desde sus orígenes precolombinos hasta la actualidad.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (761,81,1,1,1,1,1,9,1700,'SM-81-00001',NULL,'LIB-5001','978-0-13-235133-1',NULL,NULL,'HARRY POTTER Y LA PIEDRA FILOSOFAL',NULL,12.00,1.50,1.19,18.00,14.28,10.00,50.00,15.00,0,0,0,'Primer libro de la saga de J.K. Rowling, donde Harry Potter descubre que es un mago.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (762,81,1,1,1,1,1,9,1700,'SM-81-00002',NULL,'LIB-5002','978-0-13-235134-8',NULL,NULL,'EL PRINCIPITO',NULL,8.00,1.50,1.19,12.00,9.52,10.00,60.00,20.00,0,0,0,'Clásico de Antoine de Saint-Exupéry sobre un pequeño príncipe que viaja por el universo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (763,81,1,1,1,1,1,9,1700,'SM-81-00003',NULL,'LIB-5003','978-0-13-235135-5',NULL,NULL,'LA CASA DE LOS ESPÍRITUS',NULL,13.00,1.50,1.19,19.50,15.47,10.00,45.00,12.00,0,0,0,'Novela de Isabel Allende, obra infantil-juvenil que narra aventuras de una familia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (764,81,1,1,1,1,1,9,1700,'SM-81-00004',NULL,'LIB-5004','978-0-13-235136-2',NULL,NULL,'MATILDA',NULL,9.00,1.50,1.19,13.50,10.71,10.00,55.00,18.00,0,0,0,'Novela de Roald Dahl sobre una niña prodigio con poderes especiales.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (765,81,1,1,1,1,1,9,1700,'SM-81-00005',NULL,'LIB-5005','978-0-13-235137-9',NULL,NULL,'CHARLIE Y LA FÁBRICA DE CHOCOLATE',NULL,10.00,1.50,1.19,15.00,11.90,10.00,50.00,15.00,0,0,0,'Otra obra de Roald Dahl que narra la aventura de Charlie en la fábrica de chocolate de Willy Wonka.',NULL,NULL,NULL,NULL,4150,1000,1);

SELECT setval('productos_producto_id_seq', COALESCE((SELECT MAX(producto_id) FROM productos), 0), (SELECT COUNT(*) > 0 FROM productos));

-- ================================================================================================

DELETE FROM productos_vias;
ALTER SEQUENCE productos_vias_producto_via_id_seq RESTART WITH 1;

INSERT INTO productos_vias (producto_via_id, producto_id, via_id, es_principal, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 'NINGUNO', 1000, 1);

SELECT setval('productos_vias_producto_via_id_seq', COALESCE((SELECT MAX(producto_via_id) FROM productos_vias), 0), (SELECT COUNT(*) > 0 FROM productos_vias));

-- ================================================================================================

DELETE FROM equivalentes;
ALTER SEQUENCE equivalentes_equivalente_id_seq RESTART WITH 1;

INSERT INTO equivalentes (equivalente_id, producto_base_id, producto_alternativo_id, grado_equivalente_id, prioridad_recomendacion, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 3803, 1, 'NINGUNO', 1000, 1);

SELECT setval('equivalentes_equivalente_id_seq', COALESCE((SELECT MAX(equivalente_id) FROM equivalentes), 0), (SELECT COUNT(*) > 0 FROM equivalentes));

-- ================================================================================================

DELETE FROM productos_rangos_edad;
ALTER SEQUENCE productos_rangos_edad_producto_rango_edad_id_seq RESTART WITH 1;

INSERT INTO productos_rangos_edad (producto_rango_edad_id, producto_id, rango_edad_id, contraindicado, dosis_recomendada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, NULL, NULL, 1000, 1);

SELECT setval('productos_rangos_edad_producto_rango_edad_id_seq', COALESCE((SELECT MAX(producto_rango_edad_id) FROM productos_rangos_edad), 0), (SELECT COUNT(*) > 0 FROM productos_rangos_edad));

-- ================================================================================================

DELETE FROM productos_ubicaciones;
ALTER SEQUENCE productos_ubicaciones_producto_ubicacion_id_seq RESTART WITH 1;

INSERT INTO productos_ubicaciones (producto_ubicacion_id, producto_id, ubicacion_id, prioridad_picking, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 99, 1000, 1);

SELECT setval('productos_ubicaciones_producto_ubicacion_id_seq', COALESCE((SELECT MAX(producto_ubicacion_id) FROM productos_ubicaciones), 0), (SELECT COUNT(*) > 0 FROM productos_ubicaciones));

-- ================================================================================================

DELETE FROM principios_activos;
ALTER SEQUENCE principios_activos_principio_activo_id_seq RESTART WITH 1;

INSERT INTO principios_activos (principio_activo_id, codigo, nombre, descripcion, es_controlado, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN COMPONENTE ACTIVO REGISTRADO / NO APLICA', 0, 1000, 1);

SELECT setval('principios_activos_principio_activo_id_seq', COALESCE((SELECT MAX(principio_activo_id) FROM principios_activos), 0), (SELECT COUNT(*) > 0 FROM principios_activos));

-- ================================================================================================

DELETE FROM productos_principios;
ALTER SEQUENCE productos_principios_producto_principio_id_seq RESTART WITH 1;

INSERT INTO productos_principios (producto_principio_id, producto_id, principio_activo_id, concentracion, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 0, 1000, 1);

SELECT setval('productos_principios_producto_principio_id_seq', COALESCE((SELECT MAX(producto_principio_id) FROM productos_principios), 0), (SELECT COUNT(*) > 0 FROM productos_principios));

-- ================================================================================================

DELETE FROM registros_sanitarios;
ALTER SEQUENCE registros_sanitarios_registro_sanitario_id_seq RESTART WITH 1;

INSERT INTO registros_sanitarios (registro_sanitario_id, producto_id, codigo_registro, entidad_emisora, fecha_emision, fecha_vencimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', '2000-01-01', '2001-01-01', 1000, 1);

SELECT setval('registros_sanitarios_registro_sanitario_id_seq', COALESCE((SELECT MAX(registro_sanitario_id) FROM registros_sanitarios), 0), (SELECT COUNT(*) > 0 FROM registros_sanitarios));

-- ================================================================================================

DELETE FROM productos_controlados;
ALTER SEQUENCE productos_controlados_producto_controlado_id_seq RESTART WITH 1;

INSERT INTO productos_controlados (producto_controlado_id, producto_id, numero_autorizacion, requiere_receta_retenida, observaciones_control, estado_id, usuario_id_registro) VALUES 
(1, 1, 'NINGUNO', 0, 'SIN FISCALIZACIÓN / NO APLICA', 1000, 1);

SELECT setval('productos_controlados_producto_controlado_id_seq', COALESCE((SELECT MAX(producto_controlado_id) FROM productos_controlados), 0), (SELECT COUNT(*) > 0 FROM productos_controlados));

-- ================================================================================================

DELETE FROM promociones;
ALTER SEQUENCE promociones_promocion_id_seq RESTART WITH 1;

INSERT INTO promociones (promocion_id, codigo, nombre, descripcion, tipo_beneficio_id, valor_beneficio, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN CAMPAÑA PROMOCIONAL / NO APLICA', 1504, 0.00, '2000-01-01', '2001-01-01', 1000, 1);

SELECT setval('promociones_promocion_id_seq', COALESCE((SELECT MAX(promocion_id) FROM promociones), 0), (SELECT COUNT(*) > 0 FROM promociones));

-- ================================================================================================

DELETE FROM promociones_productos;
ALTER SEQUENCE promociones_productos_promocion_producto_id_seq RESTART WITH 1;

INSERT INTO promociones_productos (promocion_producto_id, promocion_id, producto_id, limite_por_transaccion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, 1000, 1);

SELECT setval('promociones_productos_promocion_producto_id_seq', COALESCE((SELECT MAX(promocion_producto_id) FROM promociones_productos), 0), (SELECT COUNT(*) > 0 FROM promociones_productos));

-- ================================================================================================

DELETE FROM conversiones_unidad;
ALTER SEQUENCE conversiones_unidad_conversion_id_seq RESTART WITH 1;

INSERT INTO conversiones_unidad (conversion_id, producto_id, unidad_origen_id, unidad_destino_id, factor_conversion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1.0000, 1000, 1);

SELECT setval('conversiones_unidad_conversion_id_seq', COALESCE((SELECT MAX(conversion_id) FROM conversiones_unidad), 0), (SELECT COUNT(*) > 0 FROM conversiones_unidad));

-- ================================================================================================

DELETE FROM proveedores;
ALTER SEQUENCE proveedores_proveedor_id_seq RESTART WITH 1;

INSERT INTO proveedores (proveedor_id, codigo, nombre, nit, direccion, telefono, email, rating_calidad_id, monto_minimo_compra, plazo_entrega_dias, limite_credito, dias_credito, ultima_evaluacion, observaciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', NULL, NULL, NULL, NULL, 2055, 0.00, 0, 0.00, 0, NULL, 'PROVEEDOR COMODÍN PARA COMPRAS DIRECTAS O DONACIONES', 1000, 1);

SELECT setval('proveedores_proveedor_id_seq', COALESCE((SELECT MAX(proveedor_id) FROM proveedores), 0), (SELECT COUNT(*) > 0 FROM proveedores));

-- ================================================================================================

DELETE FROM proveedores_contactos;
ALTER SEQUENCE proveedores_contactos_proveedor_contacto_id_seq RESTART WITH 1;

INSERT INTO proveedores_contactos (proveedor_contacto_id, proveedor_id, nombre, cargo, telefono, email, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', NULL, NULL, 1, 1000, 1);

SELECT setval('proveedores_contactos_proveedor_contacto_id_seq', COALESCE((SELECT MAX(proveedor_contacto_id) FROM proveedores_contactos), 0), (SELECT COUNT(*) > 0 FROM proveedores_contactos));

-- ================================================================================================

DELETE FROM proveedores_rating_historico;
ALTER SEQUENCE proveedores_rating_historico_rating_historico_id_seq RESTART WITH 1;

INSERT INTO proveedores_rating_historico (rating_historico_id, proveedor_id, rating_calidad_id, motivo, fecha_evaluacion, estado_id, usuario_id_registro)
VALUES (1, 1, 2055, 'REGISTRO INICIAL COMODÍN', CURRENT_DATE, 1000, 1);

SELECT setval('proveedores_rating_historico_rating_historico_id_seq', COALESCE((SELECT MAX(rating_historico_id) FROM proveedores_rating_historico), 0), (SELECT COUNT(*) > 0 FROM proveedores_rating_historico));

-- ================================================================================================

DELETE FROM parametros_globales;
ALTER SEQUENCE parametros_globales_parametro_id_seq RESTART WITH 1;

INSERT INTO parametros_globales (parametro_id,clave,valor,tipo_dato_id,datos_json,descripcion,editable,estado_id,usuario_id_registro) VALUES
	 (1,'ninguna','comodin_sistema',1800,NULL,'Registro comodin por defecto para parametros_globales',0,1000,1),
	 (2,'moneda_principal','BOB',1800,NULL,'Moneda base del sistema boliviano',0,1000,2),
	 (3,'porcentaje_iva','13.00',1802,NULL,'Alícuota general del IVA en Bolivia',0,1000,2),
	 (4,'limite_items_proforma','50',1801,NULL,'Cantidad máxima de ítems permitidos por proforma',1,1000,2),
	 (5,'controlar_lotes_vencidos','1',1803,NULL,'Habilitar bloqueo de venta para lotes expirados (1=Si, 0=No)',1,1000,2),
	 (6,'dias_alerta_vencimiento','90',1801,NULL,'Días de anticipación para notificar la expiración de medicamentos',1,1000,2),
	 (7,'modelo_arima_p','1',1801,NULL,'Orden autorregresivo (p) para modelo ARIMA',0,1000,2),
	 (8,'modelo_arima_d','1',1801,NULL,'Orden de diferenciación (d) para modelo ARIMA',0,1000,2),
	 (9,'modelo_arima_q','1',1801,NULL,'Orden de promedio móvil (q) para modelo ARIMA',0,1000,2),
	 (10,'modelo_sarima_p','1',1801,NULL,'Orden autorregresivo estacional (P) para SARIMA',0,1000,2),
	 (11,'modelo_sarima_d','1',1801,NULL,'Orden de diferenciación estacional (D) para SARIMA',0,1000,2),
	 (12,'modelo_sarima_q','1',1801,NULL,'Orden de promedio móvil estacional (Q) para SARIMA',0,1000,2),
	 (13,'modelo_sarima_s','7',1801,NULL,'Período estacional (s) para SARIMA (7=días, 12=meses)',0,1000,2),
	 (14,'modelo_kmeans_n_clusters','3',1801,NULL,'Número de clusters para K-Means (A, B, C)',0,1000,2),
	 (15,'modelo_kmeans_random_state','42',1801,NULL,'Semilla aleatoria para reproducibilidad',0,1000,2),
	 (16,'modelo_kmeans_max_iter','300',1801,NULL,'Máximo de iteraciones para K-Means',0,1000,2),
	 (17,'modelo_rop_lead_time_default','7',1801,NULL,'Lead time por defecto en días para cálculo de ROP',0,1000,2),
	 (18,'modelo_rop_stock_seguridad_default','10',1802,NULL,'Stock de seguridad por defecto para ROP',0,1000,2),
	 (19,'modelo_rop_nivel_confianza','0.95',1802,NULL,'Nivel de confianza para intervalos de predicción',0,1000,2),
	 (20,'alerta_dias_vencimiento_critico','15',1801,NULL,'Días para alerta CRÍTICA de vencimiento',1,1000,2),
	 (21,'alerta_dias_vencimiento_alta','30',1801,NULL,'Días para alerta ALTA de vencimiento',1,1000,2),
	 (22,'alerta_dias_vencimiento_media','60',1801,NULL,'Días para alerta MEDIA de vencimiento',1,1000,2),
	 (23,'alerta_stock_quiebre','5',1801,NULL,'Stock mínimo para alerta de quiebre',1,1000,2),
	 (24,'alerta_stock_reorden','20',1801,NULL,'Stock para alerta de reorden',1,1000,2),
	 (25,'alerta_dias_ventanas_dias','90',1801,NULL,'Ventana de días para entrenar modelos',1,1000,2),
	 (26,'entrenamiento_min_registros','30',1801,NULL,'Mínimo de registros para entrenar un modelo',1,1000,2),
	 (27,'entrenamiento_test_size','0.2',1802,NULL,'Porcentaje de datos para prueba (test)',1,1000,2),
	 (28,'longitud_numero_factura','7',1801,NULL,'Cantidad de dígitos para el número de factura (con ceros a la izquierda)',1,1000,2),
	 (29,'multa_dias_gracia','10',1801,NULL,'Días de tolerancia permitidos antes de aplicar cargos por retraso en cuotas',1,1000,2),
	 (30,'multa_tipo_calculo','PORCENTAJE',1800,NULL,'Tipo de cálculo para la multa: MONTO_FIJO o PORCENTAJE sobre la cuota vencida',1,1000,2),
	 (31,'multa_valor_diario','0.50',1802,NULL,'Valor diario de la multa (monto en moneda base o porcentaje según el tipo de cálculo)',1,1000,2),
	 (32,'gestion_activa','2026-01-01 00:00:00-04:00',1804,NULL,'Fecha y hora de inicio de la gestión activa del sistema (con timezone -04:00 Bolivia)',1,1000,2),
	 (33, 'logo_config', 'LOGO_CONFIG', 1805, '{"max_size": 358400, "max_width": 1500, "max_height": 600, "default_logo": null, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de logos de empresas (tamaño máximo: 350 KB, dimensiones: 1500x600 px, formatos: PNG, JPEG, JPG)', 1, 1000, 2),
	 (34, 'factores', 'FACTORES_CONFIG', 1805, '{"factor_venta": 1.50, "factor_facturacion": 1.19}', 'Configuración agrupada de factores para venta y facturación', 1, 1000, 2);

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (35, 'foto_trabajador_config', 'default-foto-trabajador.jpg', 1805, '{"max_size": 512000, "max_width": 600, "max_height": 700, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de fotos de trabajadores en formato vertical (tamaño máximo: 500 KB, dimensiones: 600x700 px)', 1, 1000, 2),
     (36, 'qr_trabajador_config', 'QR_CONFIG', 1805, '{"width": 300, "height": 300, "margin": 2, "color_dark": "#000000", "color_light": "#FFFFFF", "format": "png", "error_correction_level": "M"}', 'Configuración para la autogeneración de códigos QR del trabajador (300x300 px, fondo blanco, PNG)', 1, 1000, 2);

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (37, 'avatar_config', 'AVATAR_CONFIG', 1805, '{"max_size": 20480, "max_width": 48, "max_height": 48, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de avatares de usuarios (tamaño máximo: 20 KB, dimensiones: 48x48 px, formatos: PNG, JPEG, JPG)', 1, 1000, 2);
	 
SELECT setval('parametros_globales_parametro_id_seq', COALESCE((SELECT MAX(parametro_id) FROM parametros_globales), 0), (SELECT COUNT(*) > 0 FROM parametros_globales));

-- ================================================================================================

DELETE FROM tareas_programadas;
ALTER SEQUENCE tareas_programadas_tarea_id_seq RESTART WITH 1;

INSERT INTO tareas_programadas (
    tarea_id, codigo, nombre, descripcion, tipo_tarea_id, subtipo_tarea_id, 
    frecuencia_id, cron_expresion, parametros, ultima_ejecucion, proxima_ejecucion, 
    ejecucion_exitosa, ultimo_error, intentos_fallidos, max_intentos, 
    tarea_dependencia_id, ejecutar_en_cascada, modulo_estrategico_id, estado_id, usuario_id_registro
) VALUES
(1, 'NIN', 'NINGUNO', 'NINGUNA', 3409, 3461, 3359, NULL, '{"ejecutar": false}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(2, 'ALERTA_VENC', 'ALERTA DE VENCIMIENTO DE LOTES', 'Identifica lotes próximos a vencer y genera notificaciones', 3403, 3461, 3352, '0 6 * * *', '{"dias_alerta_critica": 15, "dias_alerta_alta": 30, "dias_alerta_media": 60}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2153, 1000, 1),
(3, 'ALERTA_STOCK', 'ALERTA DE STOCK CRÍTICO', 'Monitorea inventario y genera alertas por debajo del punto de reorden', 3403, 3461, 3351, '0 * * * *', '{"umbral_quiebre": 5, "umbral_reorden": 20}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(4, 'ENTRENAR_SARIMA', 'ENTRENAMIENTO DE MODELO SARIMA', 'Entrena el modelo de pronóstico de demanda con datos históricos', 3405, 3450, 3353, '0 2 * * 0', '{"ventana_dias": 90, "test_size": 0.2, "p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(5, 'CLASIFICAR_ABC', 'CLASIFICACIÓN ABC DE INVENTARIO', 'Reclasifica productos en categorías A, B y C con K-Means', 3406, 3453, 3354, '0 3 1 * *', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "criterios": ["costo", "rotacion", "margen", "criticidad"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(6, 'PREDECIR_DEMANDA', 'PREDICCIÓN DE DEMANDA Y ROP', 'Calcula predicciones de demanda y actualiza puntos de reorden', 3407, 3454, 3352, '0 4 * * *', '{"dias_a_predecir": 30, "lead_time_default": 7, "stock_seguridad_default": 10}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(7, 'BACKUP_DB', 'RESPALDO AUTOMÁTICO DE BASE DE DATOS', 'Genera backup completo de PostgreSQL', 3402, 3461, 3352, '0 1 * * *', '{"retencion_dias": 30, "compresion": true, "ruta_destino": "/backups/db/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(8, 'REPORTE_VENTAS_DIA', 'REPORTE DIARIO DE VENTAS', 'Consolida ventas del día con gráficos y resúmenes', 3400, 3461, 3352, '0 23 * * *', '{"formato": "PDF", "incluir_graficos": true, "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(9, 'LIMPIEZA_NOTIFICACIONES', 'LIMPIEZA DE NOTIFICACIONES LEÍDAS', 'Archiva notificaciones leídas con más de X días', 3404, 3461, 3353, '0 5 * * 0', '{"dias_para_archivar": 90}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(13, 'ENTRENAR_PROPHET', 'ENTRENAMIENTO DE MODELO PROPHET', 'Entrena el modelo Prophet de Facebook', 3405, 3452, 3354, '0 4 1 * *', '{"ventana_dias": 180, "estacionalidad_anual": true, "estacionalidad_semanal": true}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(10, 'PREDECIR_VENCIMIENTOS', 'PREDICCIÓN DE FECHAS DE VENCIMIENTO', 'Pronostica vencimientos basados en patrones de consumo', 3405, 3452, 3353, '0 4 * * 1', '{"modelo": "PROPHET", "dias_proyeccion": 180}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2153, 1000, 1),
(11, 'ALERTA_PREDICTIVA', 'ALERTAS PREDICTIVAS DE IA', 'Evalúa riesgos futuros basados en modelos predictivos', 3403, 3456, 3352, '0 7 * * *', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2156, 1000, 1),
(12, 'ENTRENAR_SARIMAX', 'ENTRENAMIENTO SARIMAX CON VARIABLES EXÓGENAS', 'Entrena SARIMAX incorporando variables externas', 3405, 3451, 3353, '0 3 * * 0', '{"ventana_dias": 90, "incluir_festivos": true, "incluir_clima": true}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(14, 'PATRON_CONSUMO', 'DETECCIÓN DE PATRONES DE CONSUMO', 'Analiza históricos para identificar patrones estacionales', 3405, 3455, 3354, '0 5 1 * *', '{"min_datos": 90, "umbral_correlacion": 0.7}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2151, 1000, 1),
(15, 'VAR_EXOGENA', 'PROCESAMIENTO DE VARIABLES EXÓGENAS', 'Obtiene y procesa variables externas', 3405, 3457, 3352, '0 1 * * *', '{"fuentes": ["API_CLIMA", "API_FESTIVOS", "API_ECONOMIA"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(16, 'VALIDAR_MODELOS', 'VALIDACIÓN CRUZADA DE MODELOS', 'Evalúa y compara el rendimiento de todos los modelos', 3408, 3460, 3354, '0 6 15 * *', '{"k_folds": 5, "metricas": ["MAPE", "RMSE", "MAE", "R2"]}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(17, 'METRICAS_IA', 'MÉTRICAS DE RENDIMIENTO DE IA', 'Genera reporte de métricas de todos los modelos', 3400, 3458, 3354, '0 7 1 * *', '{"incluir_graficos": true, "formato": "PDF"}', NULL, NULL, NULL, NULL, 0, 3, 16, 1, 2151, 1000, 1),
(18, 'REENTRENAR_AUTO', 'REENTRENAMIENTO AUTOMÁTICO DE MODELOS', 'Reentrena automáticamente si el error supera el umbral', 3405, 3459, 3357, NULL, '{"umbral_mape": 10.0, "min_datos_nuevos": 7, "modelos": ["SARIMA", "PROPHET"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(19, 'BACKUP_MODELOS', 'RESPALDO DE MODELOS DE IA', 'Guarda versionado de todos los modelos entrenados', 3402, 3461, 3353, '0 2 * * 0', '{"retencion_version": 10, "ruta_destino": "/backups/models/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(20, 'REPORTE_PREDICCIONES', 'REPORTE DE PREDICCIONES Y PROYECCIONES', 'Reporte consolidado de todas las predicciones de IA', 3400, 3461, 3354, '0 8 1 * *', '{"incluir_graficos": true, "formato": "PDF", "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2151, 1000, 1);

SELECT setval('tareas_programadas_tarea_id_seq', COALESCE((SELECT MAX(tarea_id) FROM tareas_programadas), 0), (SELECT COUNT(*) > 0 FROM tareas_programadas));

-- ================================================================================================

DELETE FROM control_facturas;
ALTER SEQUENCE control_facturas_control_factura_id_seq RESTART WITH 1;

INSERT INTO control_facturas (control_factura_id, sucursal_id, tipo_comprobante_id, numero_actual, numero_inicial, numero_final, autorizacion, cuf, cufd, cuis, codigo_control, codigo_qr, fecha_autorizacion, fecha_vencimiento, gestion, estado_operativo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1103, 0, 1, 999999, '00000000000000000000', NULL, NULL, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 2026, 3300, 1000, 1);

SELECT setval('control_facturas_control_factura_id_seq', COALESCE((SELECT MAX(control_factura_id) FROM control_facturas), 0), (SELECT COUNT(*) > 0 FROM control_facturas));

-- ================================================================================================

DELETE FROM kardex;
ALTER SEQUENCE kardex_kardex_id_seq RESTART WITH 1;

INSERT INTO kardex (kardex_id, tipo_comprobante_id, motivo_anulacion_id, motivo_devolucion_id, cliente_id, proveedor_id, sucursal_id, sucursal_destino_id, kardex_origen_id, kardex_pedido_compra_id, evento_id, codigo, comprobante, comprobante_referencia, kardex_referencia_id, fecha_kardex, total_compra, total_venta, total_venta_factura, total_pagado, total_cambio, saldo_pendiente, lugar_entrega, numero_factura, nota_credito_debito, validez_dias, fecha_expiracion, estado_proforma_id, tipo_factura_id, estado_traspaso_id, estado_financiero_id, estado_pedido_id, tipo_despacho_id, estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja) VALUES 
(1, 1103, 2455, 3506, 1, 1, 1, NULL, NULL, NULL, 1050, 'INI-1-2026-00000000', 'REGISTRO COMODIN SISTEMA', NULL, NULL, CURRENT_TIMESTAMP, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 4000, 2353, 2103, 2403, NULL, 3554, 1000, 1, NULL, NULL, CURRENT_TIMESTAMP, NULL, NULL);

SELECT setval('kardex_kardex_id_seq', COALESCE((SELECT MAX(kardex_id) FROM kardex), 0), (SELECT COUNT(*) > 0 FROM kardex));

-- ================================================================================================

DELETE FROM ordenes_compra;
ALTER SEQUENCE ordenes_compra_orden_compra_id_seq RESTART WITH 1;

INSERT INTO ordenes_compra (orden_compra_id, kardex_id, proveedor_id, numero_orden, fecha_orden, fecha_entrega_estimada, fecha_entrega_real, estado_pedido_id, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'OC-000000', CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 2253, 'ORDEN DE COMPRA COMODÍN PARA REGISTROS INICIALES', 1000, 1);

SELECT setval('ordenes_compra_orden_compra_id_seq', COALESCE((SELECT MAX(orden_compra_id) FROM ordenes_compra), 0), (SELECT COUNT(*) > 0 FROM ordenes_compra));

-- ================================================================================================

DELETE FROM instituciones;
ALTER SEQUENCE instituciones_institucion_id_seq RESTART WITH 1;

INSERT INTO instituciones (institucion_id, codigo, institucion, direccion, telefono, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, 1000, 1);

SELECT setval('instituciones_institucion_id_seq', COALESCE((SELECT MAX(institucion_id) FROM instituciones), 0), (SELECT COUNT(*) > 0 FROM instituciones));

-- ================================================================================================

DELETE FROM especialidades;
ALTER SEQUENCE especialidades_especialidad_id_seq RESTART WITH 1;

INSERT INTO especialidades (especialidad_id, especialidad, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 1000, 1);

SELECT setval('especialidades_especialidad_id_seq', COALESCE((SELECT MAX(especialidad_id) FROM especialidades), 0), (SELECT COUNT(*) > 0 FROM especialidades));

-- ================================================================================================

DELETE FROM medicos;
ALTER SEQUENCE medicos_medico_id_seq RESTART WITH 1;

INSERT INTO medicos (medico_id, medico, matricula, especialidad_id, telefono, email, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'MAT-000', 1, NULL, NULL, 1000, 1);

SELECT setval('medicos_medico_id_seq', COALESCE((SELECT MAX(medico_id) FROM medicos), 0), (SELECT COUNT(*) > 0 FROM medicos));

-- ================================================================================================

DELETE FROM recetas;
ALTER SEQUENCE recetas_receta_id_seq RESTART WITH 1;

INSERT INTO recetas (receta_id, kardex_id, cliente_id, sucursal_id, medico_id, institucion_id, tipo_receta_id, numero_receta, fecha_emision, diagnostico, receta_pdf, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 3853, 'REC-000', CURRENT_DATE, NULL, NULL, 1000, 1);

SELECT setval('recetas_receta_id_seq', COALESCE((SELECT MAX(receta_id) FROM recetas), 0), (SELECT COUNT(*) > 0 FROM recetas));

-- ================================================================================================

DELETE FROM lotes_productos;
ALTER SEQUENCE lotes_productos_lote_id_seq RESTART WITH 1;

INSERT INTO lotes_productos (lote_id, producto_id, kardex_id, codigo, fecha_vencimiento, cantidad_inicial, cantidad_actual, cantidad_reservada, precio_costo, fecha_fabricacion, lote_proveedor, ubicacion_id, rating_calidad_id, estado_lote_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', '2099-12-31', 1.00, 0.00, 0.00, 0.00, NULL, 'NINGUNO', 1, 2055, 2503, 1000, 1);

SELECT setval('lotes_productos_lote_id_seq', COALESCE((SELECT MAX(lote_id) FROM lotes_productos), 0), (SELECT COUNT(*) > 0 FROM lotes_productos));

-- ================================================================================================

DELETE FROM kardex_productos;
ALTER SEQUENCE kardex_productos_kardex_producto_id_seq RESTART WITH 1;

INSERT INTO kardex_productos (kardex_producto_id, kardex_id, producto_id, sucursal_id, lote_id, presentacion_id, tipo_pago_id, tipo_venta_id, kardex_producto_origen_id, cantidad, cantidad_unidad_base, cantidad_salida, pcompra, factor_venta, factor_facturacion, precio_venta, precio_venta_factura, costo_venta, descuento, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1400, 1350, 1, 0.00, 0.00, 0.00, 0.00, 1.00, 1.00, 0.00, 0.00, 0.00, 0.00, 1000, 1);

SELECT setval('kardex_productos_kardex_producto_id_seq', COALESCE((SELECT MAX(kardex_producto_id) FROM kardex_productos), 0), (SELECT COUNT(*) > 0 FROM kardex_productos));

-- ================================================================================================

DELETE FROM inventarios_fisicos_detalle;
ALTER SEQUENCE inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos_detalle (inventario_fisico_detalle_id, inventario_fisico_id, producto_id, lote_id, ubicacion_id, cantidad_sistema, cantidad_contada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 0.00, 0.00, 'REGISTRO INICIAL COMODIN DE DETALLE DE INVENTARIO FISICO', 1000, 1);

SELECT setval('inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq', COALESCE((SELECT MAX(inventario_fisico_detalle_id) FROM inventarios_fisicos_detalle), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos_detalle));

-- ================================================================================================

DELETE FROM ubicaciones_movimientos;
ALTER SEQUENCE ubicaciones_movimientos_ubicacion_movimiento_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_movimientos (ubicacion_movimiento_id, kardex_producto_id, ubicacion_origen_id, ubicacion_destino_id, lote_id, cantidad, tipo_ubicacion_movimiento_id, motivo, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, 1, 1.00, 3200, 'REGISTRO INICIAL COMODIN DE MOVIMIENTO', 1000, 1);

SELECT setval('ubicaciones_movimientos_ubicacion_movimiento_id_seq', COALESCE((SELECT MAX(ubicacion_movimiento_id) FROM ubicaciones_movimientos), 0), (SELECT COUNT(*) > 0 FROM ubicaciones_movimientos));

-- ================================================================================================

DELETE FROM ubicaciones_historial;
ALTER SEQUENCE ubicaciones_historial_ubicacion_historial_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_historial (ubicacion_historial_id, producto_id, ubicacion_origen_id, ubicacion_destino_id, kardex_producto_id, cantidad, motivo, trabajador_id, estado_id, usuario_id_registro) VALUES 
(1, 1, NULL, 1, NULL, 1.00, 'REGISTRO PREDETERMINADO INICIAL DE UBICACION', 1, 1002, 1);

SELECT setval('ubicaciones_historial_ubicacion_historial_id_seq', COALESCE((SELECT MAX(ubicacion_historial_id) FROM ubicaciones_historial), 1), true);

-- ================================================================================================

DELETE FROM tipos_planes_pago;
ALTER SEQUENCE tipos_planes_pago_tipo_plan_pago_id_seq RESTART WITH 1;

INSERT INTO tipos_planes_pago (tipo_plan_pago_id, codigo, nombre, meses_plazo, porcentaje_recargo, monto_fijo_recargo, permite_personalizar, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 0, 0.00, 0.00, 0, 'Pago por defecto.', 1000, 1),
(2, '3M', 'Plan a 3 Meses', 3, 5.00, 0.00, 0, 'Fraccionado a 3 meses con un recargo financiero del 5% sobre capital.', 1000, 1),
(3, '6M', 'Plan a 6 Meses', 6, 10.00, 0.00, 0, 'Fraccionado a 6 meses con un recargo financiero del 10% sobre capital.', 1000, 1),
(4, '12M', 'Plan a 12 Meses', 12, 18.00, 0.00, 0, 'Fraccionado a 12 meses con un recargo financiero del 18% sobre capital.', 1000, 1),
(5, 'PER', 'Plan Personalizado', 0, 0.00, 0.00, 1, 'Plan a medida donde el usuario define fechas y porcentajes por cuota.', 1000, 1);

SELECT setval('tipos_planes_pago_tipo_plan_pago_id_seq', COALESCE((SELECT MAX(tipo_plan_pago_id) FROM tipos_planes_pago), 0), (SELECT COUNT(*) > 0 FROM tipos_planes_pago));

-- ================================================================================================

DELETE FROM planes_pagos;
ALTER SEQUENCE planes_pagos_plan_pago_id_seq RESTART WITH 1;

INSERT INTO planes_pagos (plan_pago_id, kardex_id, numero_cuota, monto_programado, fecha_vencimiento, estado_pago_id, fecha_pago, monto_pagado, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, '2026-01-01', 2553, '2026-01-01', 0.00, 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

SELECT setval('planes_pagos_plan_pago_id_seq', COALESCE((SELECT MAX(plan_pago_id) FROM planes_pagos), 0), (SELECT COUNT(*) > 0 FROM planes_pagos));

-- ================================================================================================

DELETE FROM comprobantes_pagos;
ALTER SEQUENCE comprobantes_pagos_comprobante_pago_id_seq RESTART WITH 1;

INSERT INTO comprobantes_pagos (comprobante_pago_id, kardex_id, banco_id, tipo_pago_id, tipo_moneda_id, codigo_transaccion, monto, fecha_pago, titular_cuenta, autorizacion_nro, cuenta_destino, comprobante_digital_ruta, confirmado, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 2300, 'SN', 0.01, CURRENT_DATE, 'NINGUNO', NULL, NULL, NULL, 0, 1000, 1);

SELECT setval('comprobantes_pagos_comprobante_pago_id_seq', COALESCE((SELECT MAX(comprobante_pago_id) FROM comprobantes_pagos), 0), (SELECT COUNT(*) > 0 FROM comprobantes_pagos));

-- ================================================================================================

DELETE FROM pagos;
ALTER SEQUENCE pagos_pago_id_seq RESTART WITH 1;

INSERT INTO pagos (pago_id, kardex_id, plan_pago_id, tipo_pago_id, comprobante_pago_id, monto, fecha_pago, referencia, comprobante, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 1, 1.00, '2026-01-01', 'NINGUNO', 'NINGUNO', 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

SELECT setval('pagos_pago_id_seq', COALESCE((SELECT MAX(pago_id) FROM pagos), 0), (SELECT COUNT(*) > 0 FROM pagos));

-- ================================================================================================

DELETE FROM cajas;
ALTER SEQUENCE cajas_caja_id_seq RESTART WITH 1;

INSERT INTO cajas (caja_id, sucursal_id, apertura_trabajador_id, cierre_trabajador_id, autorizacion_trabajador_id, fecha_apertura, fecha_cierre, fecha_autorizacion, monto_inicial, monto_ingresos, monto_egresos, monto_ventas, monto_final_esperado, monto_final_real, diferencia, total_transacciones, total_ventas, total_devoluciones, total_retiros, estado_caja_id, observaciones, estado_id, usuario_id_registro) VALUES 
(1, 1, 1, 1, 1, '2026-01-01 00:00:00-04', NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 0, 0, 0, 0, 2650, 'REGISTRO COMODIN INICIAL', 1000, 1);

SELECT setval('cajas_caja_id_seq', COALESCE((SELECT MAX(caja_id) FROM cajas), 0), (SELECT COUNT(*) > 0 FROM cajas));

-- ================================================================================================

DELETE FROM movimientos;
ALTER SEQUENCE movimientos_movimiento_id_seq RESTART WITH 1;

INSERT INTO movimientos (movimiento_id, caja_id, referencia_id, trabajador_id, tipo_movimiento_id, tipo_pago_id, monto, saldo_antes, saldo_despues, motivo, fecha_movimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 2600, 1400, 0.01, 0.00, 0.01, 'REGISTRO COMODIN OBLIGATORIO', CURRENT_TIMESTAMP, 1000, 1);

SELECT setval('movimientos_movimiento_id_seq', COALESCE((SELECT MAX(movimiento_id) FROM movimientos), 0), (SELECT COUNT(*) > 0 FROM movimientos));

-- ================================================================================================

DELETE FROM arqueos_detalle;
ALTER SEQUENCE arqueos_detalle_arqueo_detalle_id_seq RESTART WITH 1;

INSERT INTO arqueos_detalle (arqueo_detalle_id, caja_id, tipo_billete_id, cantidad, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 4300, 0, 0.00, 1000, 1);

SELECT setval('arqueos_detalle_arqueo_detalle_id_seq', COALESCE((SELECT MAX(arqueo_detalle_id) FROM arqueos_detalle), 0), (SELECT COUNT(*) > 0 FROM arqueos_detalle));

-- ================================================================================================

DELETE FROM alertas_notificaciones;
ALTER SEQUENCE alertas_notificaciones_alerta_notificacion_id_seq RESTART WITH 1;

INSERT INTO alertas_notificaciones (alerta_notificacion_id, sucursal_id, codigo, tipo_alerta_notificacion_id, subtipo_alerta_id, origen_alerta_id, nivel_critico_id, titulo, mensaje, entidad_afectada_tipo_id, entidad_afectada_id, metadata, estado_alerta_id, trabajador_asignado_id, fecha_asignacion, es_leido, fecha_lectura, trabajador_resolutor_id, fecha_resolucion, comentarios_resolucion, accion_tomada, estado_id, usuario_id_registro) VALUES
(1, 1, 'ALN-000', 2700, 2812, 2850, 2905, 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO', 4111, NULL, '{}'::jsonb, 2953, 1, NULL, 1, CURRENT_TIMESTAMP, 1, NULL, NULL, NULL, 1000, 1);

SELECT setval('alertas_notificaciones_alerta_notificacion_id_seq', COALESCE((SELECT MAX(alerta_notificacion_id) FROM alertas_notificaciones), 0), (SELECT COUNT(*) > 0 FROM alertas_notificaciones));

-- ================================================================================================

DELETE FROM modelos;
ALTER SEQUENCE modelos_modelo_id_seq RESTART WITH 1;

INSERT INTO modelos (modelo_id, codigo, nombre, tipo_modelo_id, descripcion, framework_id, framework_version, version, parametros_default, estado_modelo_id, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 1456, 'REGISTRO COMODIN POR DEFECTO', 3004, '0.0.0', '0.0.0', '{}'::jsonb, 2002, 1000, 1),
(2, 'ARIMA', 'ARIMA_CLASICO', 1450, 'Modelo ARIMA (Autoregressive Integrated Moving Average) para pronóstico de demanda sin componente estacional, útil para series temporales no estacionales', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(3, 'SARIMA', 'SARIMA_ESTACIONAL', 1451, 'Modelo SARIMA (Seasonal ARIMA) para pronóstico de demanda estacional con componentes autorregresivos, de diferenciación y promedio móvil estacional. Ideal para patrones semanales, mensuales o anuales', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(4, 'SARIMAX', 'SARIMAX_EXOGENO', 1451, 'Modelo SARIMAX (SARIMA con variables exógenas) que incorpora factores externos como clima, festivos, días especiales y campañas promocionales para mejorar la precisión del pronóstico', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "exog_variables": ["temperatura", "festivo", "dia_semana", "mes", "promocion"], "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(16, 'AUTOARIMA', 'AUTO_ARIMA', 1451, 'Modelo Auto-ARIMA que realiza búsqueda automática de los mejores parámetros (p, d, q, P, D, Q, s) utilizando criterios de información AIC/BIC. Ideal para automatizar el entrenamiento', 3000, '0.14.1', '0.14.1', '{"p_max": 5, "d_max": 2, "q_max": 5, "P_max": 2, "D_max": 1, "Q_max": 2, "s_max": 12, "criterio": "aic", "seasonal": true, "m": 7, "stepwise": true, "trace": false}'::jsonb, 2002, 1000, 1),
(5, 'PROPHET', 'PROPHET_META', 1452, 'Modelo Prophet de Facebook/Meta para detección de estacionalidades múltiples (anual, semanal, diaria) y manejo de días festivos, ideal para patrones de consumo farmacéutico con múltiples estacionalidades', 3003, '1.1.5', '1.1.5', '{"growth": "linear", "yearly_seasonality": true, "weekly_seasonality": true, "daily_seasonality": false, "seasonality_mode": "additive", "changepoint_prior_scale": 0.05, "seasonality_prior_scale": 10.0, "holidays_prior_scale": 10.0, "interval_width": 0.95}'::jsonb, 2002, 1000, 1),
(6, 'PATRON', 'PATRON_CONSUMO', 1452, 'Modelo especializado en detección de patrones de consumo estacionales y tendencias de largo plazo para medicamentos, identificando picos por enfermedades estacionales (gripe, alergias, etc.)', 3003, '1.0.0', '1.0.0', '{"min_datos_entrenamiento": 90, "umbral_correlacion": 0.7, "ventana_deteccion": 30, "nivel_confianza": 0.95, "metrica_principal": "MAPE", "enfermedades_estacionales": ["gripe", "alergia", "dengue", "infecciones"]}'::jsonb, 2002, 1000, 1),
(14, 'PREDVENC', 'PREDICTOR_VENCIMIENTOS', 1452, 'Modelo especializado en pronosticar fechas de vencimiento de lotes basado en patrones históricos de consumo y rotación de inventario. Identifica lotes con riesgo de vencerse antes de ser vendidos', 3003, '1.0.0', '1.0.0', '{"dias_proyeccion": 180, "min_datos_consumo": 60, "umbral_riesgo_alto": 0.8, "umvald_riesgo_medio": 0.5, "incluir_estacionalidad": true, "factor_estacional": 1.15}'::jsonb, 2002, 1000, 1),
(15, 'ENSEMBLE', 'ENSEMBLE_FORECAST', 1452, 'Modelo Ensemble que combina predicciones de ARIMA, SARIMA, Prophet y otros modelos para mejorar la precisión del pronóstico mediante promedio ponderado y selección dinámica del mejor modelo', 3003, '1.0.0', '1.0.0', '{"modelos_ensemble": ["ARIMA_CLASICO", "SARIMA_ESTACIONAL", "PROPHET_META", "PATRON_CONSUMO"], "pesos": [0.20, 0.30, 0.25, 0.25], "metrica_optimizacion": "MAPE", "ventana_validacion": 30, "seleccion_dinamica": true}'::jsonb, 2002, 1000, 1),
(7, 'KMEANS', 'KMEANS_ABC', 1453, 'Algoritmo K-Means Clustering para clasificación ABC de inventario multicriterio basado en costo, rotación, margen de ganancia y criticidad médica. Genera categorías A (alta prioridad), B (media) y C (baja)', 3001, '1.3.2', '1.3.2', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "n_init": 10, "algorithm": "lloyd", "criterios": ["costo", "rotacion", "margen", "criticidad"], "pesos": [0.30, 0.30, 0.20, 0.20], "etiquetas": ["A", "B", "C"]}'::jsonb, 2002, 1000, 1),
(8, 'CRITICIDAD', 'CLASIFICADOR_CRITICIDAD', 1453, 'Modelo para clasificar productos por nivel de criticidad médica basado en principios activos, uso, disponibilidad en el mercado y sustitutos disponibles', 3001, '1.3.2', '1.3.2', '{"niveles": ["CRITICO", "ALTO", "MEDIO", "BAJO"], "criterios": ["principio_activo", "frecuencia_uso", "disponibilidad", "sustitutos"], "random_state": 42, "pesos": [0.35, 0.30, 0.20, 0.15]}'::jsonb, 2002, 1000, 1),
(9, 'ROP', 'ROP_DINAMICO', 1454, 'Modelo para cálculo dinámico del Punto de Reorden (ROP) basado en demanda promedio histórica, lead time y stock de seguridad ajustable. Fórmula: ROP = (d * L) + SS', 3003, '2.0.0', '2.0.0', '{"lead_time_default": 7, "stock_seguridad_default": 10, "nivel_confianza": 0.95, "metrica_demanda": "media_movil", "ventana_dias": 30, "factor_estacional": true, "ajuste_estacional": 1.2}'::jsonb, 2002, 1000, 1),
(10, 'OPTSTOCK', 'OPTIMIZADOR_STOCK', 1454, 'Modelo de optimización de inventario que calcula niveles óptimos de stock mínimo, máximo y punto de reorden basado en costos de mantener vs. costos de quiebre (modelo EOQ adaptado)', 3003, '1.5.0', '1.5.0', '{"costo_mantener": 0.25, "costo_quiebre": 2.0, "lead_time_dias": 7, "ventana_historica": 180, "nivel_servicio": 0.95, "estacionalidad": true, "factor_estacional": 1.1}'::jsonb, 2002, 1000, 1),
(11, 'OPTCOMPRA', 'OPTIMIZADOR_COMPRAS', 1454, 'Modelo que optimiza las cantidades y fechas de compra considerando precios de proveedores, descuentos por volumen, costos de almacenamiento y restricciones de presupuesto', 3003, '1.0.0', '1.0.0', '{"ventana_optimizacion": 90, "costo_pedido": 50.0, "costo_mantener": 0.25, "descuentos_volumen": [[100, 0.05], [500, 0.10], [1000, 0.15]], "lead_time_proveedor": 5, "presupuesto_mensual": 10000.0, "minimo_pedido": 10}'::jsonb, 2002, 1000, 1),
(12, 'ANOMALIAS', 'DETECTOR_ANOMALIAS', 1455, 'Modelo para detección de anomalías en patrones de consumo, ventas y stock, identificando comportamientos atípicos que requieren atención inmediata (picos, caídas bruscas, estacionalidades rotas)', 3001, '1.3.2', '1.3.2', '{"contamination": 0.05, "n_neighbors": 20, "algorithm": "auto", "metric": "minkowski", "p": 2, "ventana_deteccion": 30, "umbral_anomalia": 0.8, "metodo": "LOF"}'::jsonb, 2002, 1000, 1),
(13, 'ALERTAS', 'ALERTAS_PREDICTIVAS', 1455, 'Modelo para generación de alertas tempranas basadas en desviaciones de los patrones esperados de demanda, stock y vencimientos. Detecta riesgo de quiebre de stock y excesos de inventario', 3003, '1.2.0', '1.2.0', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30, "ventana_historica": 90, "metricas_umbral": ["MAPE", "RMSE", "MAE"], "alertas": ["quiebre_stock", "exceso_stock", "vencimiento_proximo"]}'::jsonb, 2002, 1000, 1);

SELECT setval('modelos_modelo_id_seq', COALESCE((SELECT MAX(modelo_id) FROM modelos), 0), (SELECT COUNT(*) > 0 FROM modelos));

-- ================================================================================================

DELETE FROM entrenamientos;
ALTER SEQUENCE entrenamientos_entrenamiento_id_seq RESTART WITH 1;

INSERT INTO entrenamientos (entrenamiento_id, modelo_id, fecha_ejecucion, fecha_inicio, fecha_fin, estado_ejecucion_id, duracion_segundos, registros_procesados, total_esperado, mensaje_error, estado_id, usuario_id_registro) VALUES
(1, 1, '2026-07-16 14:00:00-04', '2026-07-16 13:55:00-04', '2026-07-16 14:00:00-04', 3051, 300, 15000, 15000, NULL, 1000, 1);

SELECT setval('entrenamientos_entrenamiento_id_seq', COALESCE((SELECT MAX(entrenamiento_id) FROM entrenamientos), 0), (SELECT COUNT(*) > 0 FROM entrenamientos));

-- ================================================================================================

DELETE FROM metricas_rendimiento;
ALTER SEQUENCE metricas_rendimiento_metrica_id_seq RESTART WITH 1;

INSERT INTO metricas_rendimiento (metrica_id, entrenamiento_id, tipo_metrica_id, metrica_precision_id, version_metricas, modelo_version, periodo_evaluacion, error_absoluto_medio, raiz_error_cuadratico_medio, score_principal, detalles_metricas, estado_id, usuario_id_registro) VALUES
(1, 1, 3103, 3600, 1, '0.0.0', CURRENT_DATE, 0.0000, 0.0000, 0.0000, '{"comodin": true}'::jsonb, 1000, 1);

SELECT setval('metricas_rendimiento_metrica_id_seq', COALESCE((SELECT MAX(metrica_id) FROM metricas_rendimiento), 0), (SELECT COUNT(*) > 0 FROM metricas_rendimiento));

-- ================================================================================================

DELETE FROM patrones_consumo;
ALTER SEQUENCE patrones_consumo_patron_id_seq RESTART WITH 1;

INSERT INTO patrones_consumo (patron_id, producto_id, sucursal_id, entrenamiento_id, temporada_id, evento, factor_estacional, coeficiente_tendencia, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1600, 'NINGUNO', 0.00, 0.00, NULL, NULL, 1000, 1);

SELECT setval('patrones_consumo_patron_id_seq', COALESCE((SELECT MAX(patron_id) FROM patrones_consumo), 0), (SELECT COUNT(*) > 0 FROM patrones_consumo));

-- ================================================================================================

DELETE FROM variables_exogenas;
ALTER SEQUENCE variables_exogenas_variable_exogena_id_seq RESTART WITH 1;

INSERT INTO variables_exogenas (variable_exogena_id, producto_id, sucursal_id, fuente_exogena_id, nombre_variable, valor, fecha_variable, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 4250, 'NINGUNO', 0.0000, '2000-01-01', 1000, 1);

SELECT setval('variables_exogenas_variable_exogena_id_seq', COALESCE((SELECT MAX(variable_exogena_id) FROM variables_exogenas), 0), (SELECT COUNT(*) > 0 FROM variables_exogenas));

-- ================================================================================================

DELETE FROM logs_ejecucion;
ALTER SEQUENCE logs_ejecucion_log_id_seq RESTART WITH 1;

INSERT INTO logs_ejecucion (log_id, entrenamiento_id, modulo, nivel_log_id, mensaje, detalle, fecha_log, estado_id, usuario_id_registro) VALUES
(1, 1, 'PROCESAMIENTO_ARIMA', 3150, 'Inicio de analisis estacional', '{"productos": 12, "duracion_seg": 45}'::jsonb, CURRENT_TIMESTAMP, 1000, 1);

SELECT setval('logs_ejecucion_log_id_seq', COALESCE((SELECT MAX(log_id) FROM logs_ejecucion), 0), (SELECT COUNT(*) > 0 FROM logs_ejecucion));

-- ================================================================================================

DELETE FROM analitica_productos;
ALTER SEQUENCE analitica_productos_analitica_id_seq RESTART WITH 1;

INSERT INTO analitica_productos (analitica_id, producto_id, sucursal_id, demanda_pronosticada, intervalo_inf, intervalo_sup, fecha_prediccion, periodo_inicio, periodo_fin, fecha_vencimiento_critico, nivel_urgencia_id, punto_reorden, stock_seguridad, lead_time_dias, cluster_abc, fecha_clasificacion, puntaje_total, estado_pronostico_id, motivo_outlier_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 120.50, 100.00, 140.00, CURRENT_TIMESTAMP, '2026-08-01', '2026-08-31', '2027-01-15', 1854, 45.00, 15.00, 5, 0, CURRENT_DATE, 85.50, 1553, NULL, 1000, 1);

SELECT setval('analitica_productos_analitica_id_seq', COALESCE((SELECT MAX(analitica_id) FROM analitica_productos), 0), (SELECT COUNT(*) > 0 FROM analitica_productos));

-- ================================================================================================

DELETE FROM pedidos_online;
ALTER SEQUENCE pedidos_online_pedido_online_id_seq RESTART WITH 1;

INSERT INTO pedidos_online (pedido_online_id, cliente_id, sucursal_id, kardex_id, codigo, fecha_pedido, fecha_entrega_estimada, fecha_entrega_real, direccion_entrega, telefono_contacto, instrucciones_entrega, estado_pedido_online_id, estado_pago_id, subtotal, costo_envio, descuentos, total, ultima_actualizacion, observacion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'WEB-0000', CURRENT_TIMESTAMP, NULL, NULL, 'NINGUNO', '00000000', NULL, 3700, 2555, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 1000, 1);

SELECT setval('pedidos_online_pedido_online_id_seq', COALESCE((SELECT MAX(pedido_online_id) FROM pedidos_online), 0), (SELECT COUNT(*) > 0 FROM pedidos_online));

-- ================================================================================================

DELETE FROM detalles_pedidos_online;
ALTER SEQUENCE detalles_pedidos_online_detalle_pedido_online_id_seq RESTART WITH 1;

INSERT INTO detalles_pedidos_online (detalle_pedido_online_id, pedido_online_id, producto_id, kardex_producto_id, codigo_producto, nombre_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'NIN', 'NINGUNO', 1.00, 0.00, 0.00, 0.00, 1000, 1);

SELECT setval('detalles_pedidos_online_detalle_pedido_online_id_seq', COALESCE((SELECT MAX(detalle_pedido_online_id) FROM detalles_pedidos_online), 0), (SELECT COUNT(*) > 0 FROM detalles_pedidos_online));

-- ================================================================================================

DELETE FROM carritos_compra;
ALTER SEQUENCE carritos_compra_carrito_id_seq RESTART WITH 1;

INSERT INTO carritos_compra (carrito_id, sucursal_id, cliente_id, fecha_creacion, fecha_actualizacion_carrito, fecha_expiracion, cliente_nombre, cliente_documento, total_items, subtotal, estado_carrito_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', 'NINGUNO', '0', 0, 0.00, 4906, 1000, 1);

SELECT setval('carritos_compra_carrito_id_seq', COALESCE((SELECT MAX(carrito_id) FROM carritos_compra), 0), (SELECT COUNT(*) > 0 FROM carritos_compra));

-- ================================================================================================

DELETE FROM detalles_carritos;
ALTER SEQUENCE detalles_carritos_detalle_carrito_id_seq RESTART WITH 1;

INSERT INTO detalles_carritos (detalle_carrito_id, carrito_id, producto_id, codigo_producto, nombre_producto, presentacion_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NIN', 'NINGUNO', NULL, 1.00, 0.00, 0.00, 0.00, 1000, 1);

SELECT setval('detalles_carritos_detalle_carrito_id_seq', COALESCE((SELECT MAX(detalle_carrito_id) FROM detalles_carritos), 0), (SELECT COUNT(*) > 0 FROM detalles_carritos));

-- ================================================================================================

DELETE FROM listas_precios;
ALTER SEQUENCE listas_precios_lista_precio_id_seq RESTART WITH 1;

INSERT INTO listas_precios (lista_precio_id, codigo, nombre, descripcion, es_publica, prioridad, requiere_autorizacion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'Lista de precios predeterminada para productos sin clasificar', 0, 999, 0, 1000, 1);

SELECT setval('listas_precios_lista_precio_id_seq', COALESCE((SELECT MAX(lista_precio_id) FROM listas_precios), 0), (SELECT COUNT(*) > 0 FROM listas_precios));

-- ================================================================================================

DELETE FROM precios_productos;
ALTER SEQUENCE precios_productos_precio_producto_id_seq RESTART WITH 1;

INSERT INTO precios_productos (precio_producto_id, producto_id, lista_precio_id, precio_base, precio_oferta, precio_minimo, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, NULL, NULL, '2000-01-01', NULL, 1000, 1);

SELECT setval('precios_productos_precio_producto_id_seq', COALESCE((SELECT MAX(precio_producto_id) FROM precios_productos), 0), (SELECT COUNT(*) > 0 FROM precios_productos));

-- ================================================================================================

DELETE FROM costos_promedio;
ALTER SEQUENCE costos_promedio_costo_promedio_id_seq RESTART WITH 1;

INSERT INTO costos_promedio (costo_promedio_id, producto_id, costo_promedio, costo_ultima_compra, fecha_calculo, metodo_calculo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0.00, NULL, '2000-01-01', 3750, 1000, 1);

SELECT setval('costos_promedio_costo_promedio_id_seq', COALESCE((SELECT MAX(costo_promedio_id) FROM costos_promedio), 0), (SELECT COUNT(*) > 0 FROM costos_promedio));

-- ================================================================================================

DELETE FROM politicas_precios;
ALTER SEQUENCE politicas_precios_politica_precio_id_seq RESTART WITH 1;

INSERT INTO politicas_precios (politica_precio_id, codigo, nombre, tipo_aplicacion_id, entidad_id, margen_minimo, margen_maximo, redondeo, aplica_descuentos, descuento_maximo, estado_id, usuario_id_registro) VALUES
(1, 'GLOBAL', 'POLÍTICA GLOBAL POR DEFECTO', 4350, NULL, 0.00, 100.00, 0, 1, 0.00, 1000, 1);

SELECT setval('politicas_precios_politica_precio_id_seq', COALESCE((SELECT MAX(politica_precio_id) FROM politicas_precios), 0), (SELECT COUNT(*) > 0 FROM politicas_precios));

-- ================================================================================================

DELETE FROM asistencias;
ALTER SEQUENCE asistencias_asistencia_id_seq RESTART WITH 1;

INSERT INTO asistencias (asistencia_id, trabajador_id, sucursal_id, fecha, hora_entrada, hora_salida, hora_entrada_almuerzo, hora_salida_almuerzo, horas_trabajadas, horas_extras, tipo_asistencia_id, estado_asistencia_id, metodo_marcacion_id, dispositivo, ip_origen, observaciones, justificacion, justificacion_archivo, usuario_registro_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, NULL, NULL, 0.00, 0.00, 4400, 4450, 4500, NULL, NULL, 'REGISTRO COMODIN INICIAL', NULL, NULL, 1, 1000, 1);

SELECT setval('asistencias_asistencia_id_seq', COALESCE((SELECT MAX(asistencia_id) FROM asistencias), 0), (SELECT COUNT(*) > 0 FROM asistencias));

-- ================================================================================================

DELETE FROM planillas;
ALTER SEQUENCE planillas_planilla_id_seq RESTART WITH 1;

INSERT INTO planillas (planilla_id, sucursal_id, periodo_mes, periodo_gestion, fecha_inicio, fecha_fin, tipo_planilla_id, estado_planilla_id, estado_id, usuario_id_registro)
VALUES (1, 1, 1, 2026, '2026-01-01', '2026-01-31', 4600, 4650, 1000, 1);

SELECT setval('planillas_planilla_id_seq', COALESCE((SELECT MAX(planilla_id) FROM planillas), 0), (SELECT COUNT(*) > 0 FROM planillas));

-- ================================================================================================

DELETE FROM planillas_detalle;
ALTER SEQUENCE planillas_detalle_planilla_detalle_id_seq RESTART WITH 1;

INSERT INTO planillas_detalle (planilla_detalle_id, planilla_id, trabajador_id, cargo_id, sueldo_base, dias_trabajados, total_ingresos, neto_pagar, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 0.00, 0, 0.00, 0.00, 1000, 1);

SELECT setval('planillas_detalle_planilla_detalle_id_seq', COALESCE((SELECT MAX(planilla_detalle_id) FROM planillas_detalle), 0), (SELECT COUNT(*) > 0 FROM planillas_detalle));

-- ================================================================================================

DELETE FROM contratos;
ALTER SEQUENCE contratos_contrato_id_seq RESTART WITH 1;

INSERT INTO contratos (contrato_id, trabajador_id, tipo_contrato_id, fecha_inicio, sueldo_base, moneda_sueldo_id, tipo_jornada_id, estado_contrato_id, estado_id, usuario_id_registro)
VALUES (1, 1, 4750, CURRENT_DATE, 0.00, 2300, 4800, 4700, 1000, 1);

SELECT setval('contratos_contrato_id_seq', COALESCE((SELECT MAX(contrato_id) FROM contratos), 0), (SELECT COUNT(*) > 0 FROM contratos));

-- ================================================================================================

DELETE FROM historicos;
ALTER SEQUENCE historicos_historico_id_seq RESTART WITH 1;

INSERT INTO historicos (historico_id, kardex_id, cliente_id, sucursal_id, empresa_id, cliente_nombre, cliente_documento, cliente_documento_complemento, cliente_tipo_documento_abreviatura, cliente_razon_social, cliente_direccion, cliente_telefono, cliente_email, sucursal_nombre, sucursal_codigo, sucursal_telefono, sucursal_ubicacion, sucursal_codigo_sin, sucursal_punto_venta, empresa_nombre, empresa_codigo, empresa_nit, empresa_autorizacion, empresa_actividad_economica, numero_factura, fecha_emision, tipo_comprobante_abreviatura, tipo_factura_abreviatura, lugar_entrega, items, subtotal, descuento_total, iva, total, total_pagado, total_cambio, metodo_pago_abreviatura, tipo_moneda_abreviatura, factor_cambio, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 'NINGUNO', '0', NULL, 'NINGUNO', NULL, NULL, NULL, NULL, 'NINGUNO', 'NIN', NULL, NULL, 0, 0, 'NINGUNA', 'NIN', '000000000', '00000000000000000000', NULL, '0000000', '2026-01-01', 'NINGUNO', 'NINGUNO', NULL, '[]'::jsonb, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 'E', 'BOB', 1.0000, 1000, 1);

SELECT setval('historicos_historico_id_seq', COALESCE((SELECT MAX(historico_id) FROM historicos), 0), (SELECT COUNT(*) > 0 FROM historicos));

-- ================================================================================================
