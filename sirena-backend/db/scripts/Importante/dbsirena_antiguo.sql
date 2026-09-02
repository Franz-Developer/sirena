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
	R.G.9: Todas las tablas deben tener FULL-TEXT SEARCH para todos los campos que sean texto 

		
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
	WHERE n.nspname = 'dbsirena' -- O el esquema donde se encuentre tu tabla
		AND c.relname = 'bancos';

	
*/

-- ================================================================================================

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

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
    fts_bancos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(banco, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo_asfi, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(abreviatura, '')), 'C')
    ) STORED,
    CONSTRAINT chk_bancos_banco_minlength CHECK (LENGTH(TRIM(banco)) >= 3),
    CONSTRAINT chk_bancos_abreviatura_minlength CHECK (LENGTH(TRIM(abreviatura)) >= 2),
    CONSTRAINT chk_bancos_abreviatura_mayusculas CHECK (abreviatura = UPPER(abreviatura)),
	CONSTRAINT chk_bancos_codigoasfi_numerico CHECK (codigo_asfi ~ '^[0-9]{2}$'),
	CONSTRAINT chk_bancos_abreviatura_formato CHECK (abreviatura ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_bancos_banco_mayusculas CHECK (banco = UPPER(banco)),
	CONSTRAINT chk_bancos_estadoid CHECK (estado_id IN (1000, 1001, 1002))
);
CREATE UNIQUE INDEX uix_bancos_codigoasfi_unique ON bancos (codigo_asfi) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_abreviatura_unique ON bancos (abreviatura) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_banco_unique ON bancos (banco) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_bancos_fts ON bancos USING GIN (fts_bancos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE bancos IS 'Reglas de la tabla - bancos
R.0: La tabla bancos constituye el catálogo estandarizado de entidades financieras que operan en el sistema, almacenando tanto el nombre comercial como el código regulador oficial de la ASFI. Su función principal es respaldar los procesos contables y de pagos, permitiendo la asociación de cuentas bancarias propias (empresas_cuentas), de clientes (clientes), y de comprobantes de pago (comprobantes_pagos), garantizando la trazabilidad de las transacciones financieras.
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
    origen_moneda_id INTEGER NOT NULL DEFAULT 2300,      -- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    destino_moneda_id INTEGER NOT NULL DEFAULT 2300,     -- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
    factor_compra DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    factor_venta DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    fecha_cotizacion DATE NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
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
    codigo VARCHAR(60) NOT NULL,
    logo VARCHAR(255) NOT NULL,
    eslogan VARCHAR(150) NULL,
    descripcion VARCHAR(1500) NULL,
    lugar VARCHAR(100) NULL,
    representante VARCHAR(100) NULL,
    direccion VARCHAR(3000) NULL,
    telefono VARCHAR(200) NULL,
    email VARCHAR(100) NULL,
    matricula_comercio VARCHAR(50) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_empresas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(empresa, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(logo, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(eslogan, '')), 'D') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'D') ||
        setweight(to_tsvector('spanish', COALESCE(lugar, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(representante, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(direccion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(matricula_comercio, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_empresas_fts ON empresas USING GIN (fts_empresas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE empresas IS 'Reglas de la tabla - empresas
R.0: La tabla empresas actúa como el nodo raíz de la estructura organizacional, almacenando la información corporativa general de la o las compañías que operan la plataforma sirena. Su función es centralizar la identidad corporativa, incluyendo razón social, logotipo, eslogan y datos de contacto, para personalizar la interfaz de usuario y, más críticamente, para proveer los datos base en la emisión de documentos fiscales y la configuración de sucursales. Se conecta jerárquicamente con sucursales, y a través de empresas_nits y empresas_cuentas con la información tributaria y bancaria de la organización.
R.1: El campo codigo es alfanumérico y corresponde a un dato maestro ingresado manualmente por el usuario desde el formulario; el sistema no genera este código de forma automática.
R.2: La columna logo almacena únicamente el nombre del archivo y su extensión (ej. ''2.jpg''). La resolución de la URL absoluta para el renderizado en el frontend se realiza mediante variable de entorno.
R.3: El campo empresa registra el nombre comercial de la empresa.';

DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.jpg', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@gmail.com', 'MAT-000', 1000, 1),
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
    fts_empresasnits_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(razon_social, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(actividad_economica_principal, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(nit, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(email_fiscal, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(certificado_digital, '')), 'D') ||
        setweight(to_tsvector('simple', COALESCE(token_siat, '')), 'D')
    ) STORED,
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
    CONSTRAINT chk_empresasnits_emailfiscal_formato CHECK (email_fiscal ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_empresasnits_emailfiscal_notempty CHECK (TRIM(email_fiscal) <> ''),
    CONSTRAINT chk_empresasnits_fechas CHECK (fecha_inicio_vigencia IS NULL OR fecha_fin_vigencia IS NULL OR fecha_inicio_vigencia <= fecha_fin_vigencia)
);
CREATE UNIQUE INDEX uix_empresasnits_nit_unique ON empresas_nits (nit) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_empresasnits_varios_unique ON empresas_nits (nit, fecha_inicio_vigencia, fecha_fin_vigencia) NULLS NOT DISTINCT WHERE estado_id = 1002;
CREATE INDEX idx_empresasnits_fts ON empresas_nits USING GIN (fts_empresasnits_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE empresas_nits IS 'Reglas de la tabla - empresas_nits
R.0: La tabla empresas_nits almacena la información de dosificación fiscal de la empresa, incluyendo el NIT, número de autorización y fechas de vigencia, necesaria para el cumplimiento de las obligaciones tributarias ante el Servicio de Impuestos Nacionales (SIN). Su propósito es controlar los rangos de numeración de facturas y la vigencia de los talonarios fiscales, asegurando que la emisión de comprobantes electrónicos se realice con credenciales válidas y activas.
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
    fts_empresascuentas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(nro_cuenta, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(titular, '')), 'A')
    ) STORED,
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
CREATE INDEX idx_empresascuentas_fts ON empresas_cuentas USING GIN (fts_empresascuentas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE empresas_cuentas IS 'Reglas de la tabla - empresas_cuentas
R.0: La tabla empresas_cuentas gestiona el catálogo de cuentas bancarias operativas de la empresa, registrando la entidad financiera, el tipo de cuenta, la moneda y el titular. Su función es proporcionar la información de las cuentas de destino para la recepción de pagos de clientes, la realización de transferencias y la conciliación bancaria de los movimientos de caja.
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
    codigo VARCHAR(60) NOT NULL,
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
    fts_sucursales_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(sucursal, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(sucursal_largo, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(ubicacion, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(horario_atencion, '')), 'D')
    ) STORED,
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
CREATE UNIQUE INDEX uix_sucursales_empresaid_codigo_unique ON sucursales (empresa_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_sucursales_empresaid_codigosin_unique ON sucursales (empresa_id, codigo_sin) WHERE estado_id = 1000;
CREATE INDEX idx_sucursales_fts ON sucursales USING GIN (fts_sucursales_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE sucursales IS 'Reglas de la tabla - sucursales
R.0: La tabla sucursales define los puntos de venta operativos de la empresa, mapeando su estructura legal, geográfica y fiscal (código, número de punto de venta). Su propósito es segmentar la operación del negocio por ubicación física, controlando los factores de precio (factor_venta, factor_facturacion) que se heredan a los productos y sirviendo como eje central para los procesos de inventario, ventas, facturación (números de autorización) y asignación de personal.
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
    tipo_punto_venta_id INTEGER NOT NULL DEFAULT 3950,	-- 3950=NINGUNO, 3951=CAJA
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_puntosventa_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'A')
    ) STORED,
    CONSTRAINT fk_puntosventa_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_puntosventa_tipopuntoventaid CHECK (tipo_punto_venta_id IN (3950, 3951)),
    CONSTRAINT chk_puntosventa_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_puntosventa_codigopuntoventa CHECK (codigo_punto_venta >= 0),
    CONSTRAINT chk_puntosventa_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_puntosventa_varios_unique ON puntos_venta (sucursal_id, codigo_punto_venta) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_puntosventa_fts ON puntos_venta USING GIN (fts_puntosventa_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE puntos_venta IS 'Reglas de la tabla - puntos_venta
R.0: La tabla puntos_venta define los puntos de venta específicos dentro de cada sucursal, permitiendo segmentar operaciones por cajas, mostradores o módulos de atención. Su función es identificar cada punto de emisión de comprobantes fiscales y controlar la asignación de turnos, cajeros y flujo de caja.
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
    codigo_cuis VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,               -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_cuis_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(codigo_cuis, '')), 'A')
    ) STORED,
	CONSTRAINT fk_cuis_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cuis_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_cuis_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_cuis_codigo_notempty CHECK (TRIM(codigo_cuis) <> ''),
    CONSTRAINT chk_cuis_fechavigencia CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cuis_varios_unique ON cuis (sucursal_id, COALESCE(punto_venta_id, 0)) WHERE estado_id = 1000;
CREATE INDEX idx_cuis_fts ON cuis USING GIN (fts_cuis_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE cuis IS 'Reglas de la tabla - cuis
R.0: La tabla cuis almacena el Código Único de Identificación del Sistema (CUIS) otorgado por el SIN para la facturación electrónica. Cada sucursal y punto de venta requiere un CUIS vigente para la emisión de comprobantes fiscales. Su propósito es gestionar la validez de los códigos de autorización y controlar la caducidad de los mismos para garantizar la continuidad operativa.
R.1: fecha_vigencia almacena la fecha y hora de expiración del CUIS devuelta por el SIN. Solo los registros con fecha_vigencia > CURRENT_TIMESTAMP y estado_id = 1000 son considerados vigentes para facturación.
R.2: El índice uix_cuis_activo garantiza que solo exista un CUIS activo por sucursal y punto de venta, utilizando COALESCE para tratar NULL como 0 en puntos_venta a nivel de sucursal.';

DELETE FROM cuis;
ALTER SEQUENCE cuis_cuis_id_seq RESTART WITH 1;

INSERT INTO cuis (cuis_id, sucursal_id, punto_venta_id, codigo_cuis, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1);

UPDATE cuis SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cuis SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cuis_cuis_id_seq', COALESCE((SELECT MAX(cuis_id) FROM cuis), 1));

-- ================================================================================================

CREATE TABLE cufd (
    cufd_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL,
    punto_venta_id BIGINT NULL,
    codigo_cufd VARCHAR(500) NOT NULL,
    codigo_control VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,              -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_cufd_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo_cufd, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo_control, '')), 'B')
    ) STORED,
	CONSTRAINT fk_cufd_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cufd_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_cufd_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_cufd_codigocufd_notempty CHECK (TRIM(codigo_cufd) <> ''),
    CONSTRAINT chk_cufd_codigocontrol_notempty CHECK (TRIM(codigo_control) <> ''),
    CONSTRAINT chk_cufd_fechavigencia CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cufd_varios_unique ON cufd (sucursal_id, COALESCE(punto_venta_id, 0)) WHERE estado_id = 1000;
CREATE INDEX idx_cufd_fts ON cufd USING GIN (fts_cufd_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE cufd IS 'Reglas de la tabla - cufd
R.0: La tabla cufd almacena el Código Único de Facturación Diaria (CUFD) otorgado por el SIN, necesario para la emisión de comprobantes fiscales electrónicos. Cada sucursal y punto de venta requiere un CUFD vigente con validez de 24 horas para la generación de facturas. Su propósito es gestionar los códigos de autorización diarios y controlar su caducidad para garantizar la continuidad operativa en la facturación electrónica.
R.1: fecha_vigencia almacena la fecha y hora de expiración del CUFD devuelta por el SIN (vigencia de 24 horas). Solo los registros con fecha_vigencia > CURRENT_TIMESTAMP y estado_id = 1000 son considerados vigentes para la emisión de facturas.
R.2: codigo_control almacena el código de control asociado al CUFD, utilizado para la validación y generación de la firma digital de los comprobantes fiscales.
R.3: El índice uix_cufd_activo garantiza que solo exista un CUFD activo por sucursal y punto de venta, utilizando COALESCE para tratar NULL como 0 en puntos_venta a nivel de sucursal.';

DELETE FROM cufd;
ALTER SEQUENCE cufd_cufd_id_seq RESTART WITH 1;

INSERT INTO cufd (cufd_id, sucursal_id, punto_venta_id, codigo_cufd, codigo_control, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNO', 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1);

UPDATE cufd SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cufd SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cufd_cufd_id_seq', COALESCE((SELECT MAX(cufd_id) FROM cufd), 1));

-- ================================================================================================

CREATE TABLE almacenes (
    almacen_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    almacen VARCHAR(200) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    tipo_almacen_id INTEGER NOT NULL DEFAULT 1700,              -- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    tipo_operacion_almacen_id INTEGER NOT NULL DEFAULT 4050,    -- 4050=LOGISTICA_INTERNA, 4051=VENTA_DIRECTA
    descripcion VARCHAR(1500) NULL,
    temperatura_min DECIMAL(5,2) NULL,
    temperatura_max DECIMAL(5,2) NULL,
    humedad_min DECIMAL(5,2) NULL,
    humedad_max DECIMAL(5,2) NULL,
    unidad_temperatura_id INTEGER NOT NULL DEFAULT 4850,        -- 4850=CELSIUS, 4851=FAHRENHEIT, 4852=KELVIN
    unidad_humedad_id INTEGER NOT NULL DEFAULT 4900,            -- 4900=PORCENTAJE, 4901=G_M3
    estado_id INTEGER NOT NULL DEFAULT 1000,            		-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_almacenes_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(almacen, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
    CONSTRAINT fk_almacenes_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_almacenes_tipoalmacenid CHECK (tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)),
    CONSTRAINT chk_almacenes_tipooperacionalmacenid CHECK (tipo_operacion_almacen_id IN (4050, 4051)),
    CONSTRAINT chk_almacenes_unidadtemperaturaid CHECK (unidad_temperatura_id IN (4850, 4851, 4852)),
    CONSTRAINT chk_almacenes_unidadhumedadid CHECK (unidad_humedad_id IN (4900, 4901)),
    CONSTRAINT chk_almacenes_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_almacenes_almacen_notempty CHECK (TRIM(almacen) <> ''),
    CONSTRAINT chk_almacenes_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_almacenes_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_almacenes_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_almacenes_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_almacenes_temperatura CHECK (
        (temperatura_min IS NULL AND temperatura_max IS NULL) OR
        (temperatura_min IS NOT NULL AND temperatura_max IS NOT NULL AND temperatura_max >= temperatura_min)
    ),
    CONSTRAINT chk_almacenes_humedad CHECK (
        (humedad_min IS NULL AND humedad_max IS NULL) OR
        (humedad_min IS NOT NULL AND humedad_max IS NOT NULL AND humedad_max >= humedad_min)
    )
);

CREATE UNIQUE INDEX uix_almacenes_sucursalid_almacen_unique ON almacenes (sucursal_id, almacen) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_almacenes_sucursalid_codigo_unique ON almacenes (sucursal_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_almacenes_fts ON almacenes USING GIN (fts_almacenes_vector) WHERE fecha_baja IS NULL;
COMMENT ON TABLE almacenes IS 'Reglas de la tabla - almacenes
R.0: La tabla almacenes representa las áreas o depósitos físicos dentro de cada sucursal, categorizados por tipo (normal, refrigerado, controlado). Su propósito es organizar el inventario de manera lógica y física, permitiendo la gestión de stock diferenciado por tipo de producto y condición de almacenamiento. Actúa como el contenedor principal para la asignación de ubicaciones y para los movimientos de inventario, asegurando la trazabilidad de la mercancía.
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

INSERT INTO almacenes (almacen_id, sucursal_id, almacen, codigo, tipo_almacen_id, tipo_operacion_almacen_id, descripcion, temperatura_min, temperatura_max, humedad_min, humedad_max, unidad_temperatura_id, unidad_humedad_id, estado_id, usuario_id_registro) VALUES 
(1, 1, 'NINGUNO', 'NIN', 1700, 4050, 'ALMACEN COMODIN', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 1);

UPDATE almacenes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_almacen_id_seq', COALESCE((SELECT MAX(almacen_id) FROM almacenes), 1));

-- ================================================================================================

CREATE TABLE ubicaciones (
    ubicacion_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
    codigo VARCHAR(60) NOT NULL,
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
    fts_ubicaciones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
	CONSTRAINT fk_ubicaciones_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
    CONSTRAINT chk_ubicaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicaciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_ubicaciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
	CONSTRAINT chk_ubicaciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_ubicaciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_ubicaciones_capacidadmaxima CHECK (capacidad_maxima >= 0),
    CONSTRAINT chk_ubicaciones_stockactual CHECK (stock_actual >= 0),
    CONSTRAINT chk_ubicaciones_umbralminimo CHECK (umbral_minimo >= 0),
    CONSTRAINT chk_ubicaciones_stock_noexcedecapacidad CHECK (capacidad_maxima = 0 OR stock_actual <= capacidad_maxima),
    CONSTRAINT chk_ubicaciones_jerarquia_estructura CHECK (
        jerarquia IS NULL OR
        jsonb_typeof(jerarquia) = 'object' AND
        (jerarquia ? 'niveles' OR jerarquia ? 'camino')
    )
);
CREATE UNIQUE INDEX uix_ubicaciones_varios_unique ON ubicaciones (almacen_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ubicaciones_jerarquia ON ubicaciones USING GIN (jerarquia);
CREATE INDEX idx_ubicaciones_fts ON ubicaciones USING GIN (fts_ubicaciones_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE ubicaciones IS 'Reglas de la tabla - ubicaciones
R.0: La tabla ubicaciones define la estructura detallada dentro de cada almacén utilizando un esquema jerárquico flexible en formato JSONB. Su propósito principal es optimizar los procesos de picking y el control de inventario al permitir una localización precisa de los productos físicos sin la rigidez de columnas fijas.
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
    CONSTRAINT fk_almacenespuntosventa_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
    CONSTRAINT fk_almacenespuntosventa_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_almacenespuntosventa_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_almacenespuntosventa_esprincipal CHECK (es_principal IN (0, 1)),
    CONSTRAINT chk_almacenespuntosventa_prioridad CHECK (prioridad > 0)
);
CREATE UNIQUE INDEX uix_almacenespuntosventa_varios_unique ON almacenes_puntos_venta (almacen_id, punto_venta_id) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_almacenespuntosventa_puntoventaid_unique ON almacenes_puntos_venta (punto_venta_id) WHERE es_principal = 1 AND estado_id = 1000;

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
    codigo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(1000) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_cargos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(cargo, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_cargos_fts ON cargos USING GIN (fts_cargos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE cargos IS 'Reglas de la tabla - cargos
R.0: La tabla cargos define los puestos de trabajo o roles laborales dentro de la organización, sirviendo para clasificar al personal y definir jerarquías operativas.';

DELETE FROM cargos;
ALTER SEQUENCE cargos_cargo_id_seq RESTART WITH 1;

INSERT INTO cargos (cargo_id, cargo, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NIN', 'CARGO COMODIN', 1000, 1),
(2, 'ADMINISTRADOR DEL SISTEMA', 'ADMIN', 'Gestión integral, configuración y control total de la plataforma.', 1000, 1),
(3, 'GERENTE GENERAL', 'GER_GEN', 'Dirección estratégica y toma de decisiones corporativas.', 1000, 1),
(4, 'ADMINISTRADOR DE SUCURSAL', 'ADMIN_SUC', 'Supervisión de inventarios, dispensación y control de almacenes.', 1000, 1),
(5, 'CONTADOR', 'CONT', 'Contabilidad.', 1000, 1),
(6, 'COMPRAS', 'COMP', 'Encargado de compras.', 1000, 1),
(7, 'VENTAS', 'VENT', 'Encargado de ventas.', 1000, 1),
(8, 'INVENTARIO', 'INV', 'Encargado del inventario.', 1000, 1),
(9, 'MENSAJERO', 'MENS', 'Encargado de mensajeria.', 1000, 1);

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
    fts_trabajadores_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(nombres, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(paterno, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(materno, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(dni, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(direccion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(foto, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(qr, '')), 'C')
    ) STORED,
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
    CONSTRAINT chk_trabajadores_dni_notempty CHECK (TRIM(dni) <> ''),
    CONSTRAINT chk_trabajadores_dni_minlength CHECK (LENGTH(TRIM(dni)) >= 5),
    CONSTRAINT chk_trabajadores_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_trabajadores_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_trabajadores_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_trabajadores_foto_notempty CHECK (TRIM(foto) <> ''),
    CONSTRAINT chk_trabajadores_qr_notempty CHECK (TRIM(qr) <> ''),
    CONSTRAINT chk_trabajadores_fechanacimiento CHECK (fecha_nacimiento IS NULL OR fecha_nacimiento <= CURRENT_DATE),
    CONSTRAINT chk_trabajadores_fechacontratacion CHECK (fecha_contratacion IS NULL OR fecha_contratacion <= CURRENT_DATE)
);
CREATE UNIQUE INDEX uix_trabajadores_dni_unique ON trabajadores (dni) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_trabajadores_fts ON trabajadores USING GIN (fts_trabajadores_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE trabajadores IS 'Reglas de la tabla - trabajadores
R.0: La tabla trabajadores actúa como el registro maestro de individuos, centralizando la información demográfica básica de todos los actores del sistema, incluyendo empleados, clientes eventuales y contactos. Su propósito es servir como la entidad raíz de identificación personal, evitando la duplicación de datos y proporcionando una base de datos unificada para la creación de usuarios del sistema, gestión de clientes y cualquier otra interacción que requiera datos personales.
R.1: Prerrequisito Operativo Maestro. El registro completo y validado de un individuo en esta tabla es un requerimiento técnico obligatorio antes de que el sistema le pueda asignar credenciales de acceso, roles o vincularlo como operador activo en cualquier sucursal.
R.2: qr el backend debe generar la imagen de qr con datos del trabajador nombres, paterno, materno, dni, telefono.
R.3: Gestión de Archivos y Metadatos Digitales. Los campos foto y qr almacenan exclusivamente las rutas lógicas de los archivos correspondientes en el servidor. La generación del código QR y el procesamiento de la imagen se realizan de forma asíncrona en el backend. Siguiendo la regla general R.G.4, la desactivación de un registro no elimina físicamente estos recursos del disco.
R.4: Consistencia de Identidad Única. La restricción de unicidad sobre el documento de identidad (dni) se aplica de forma estricta sobre registros con estado ACTIVO e HISTORICO. Esto impide la duplicidad de trabajadores vigentes dentro de la plataforma, permitiendo la reutilización del valor únicamente si el registro previo ha sido modificado al estado BORRADO.
R.5: Integridad de Estado Civil y Género. El sistema utiliza dos grupos de valores independientes para el estado civil: Identificadores masculinos (1250-1254) para el género MASCULINO y identificadores femeninos (1300-1304) para el género FEMENINO. El frontend debe filtrar las opciones de estado civil según el género seleccionado, mostrando SOLTERO/CASADO/DIVORCIADO/VIUDO/UNION LIBRE para MASCULINO y SOLTERA/CASADA/DIVORCIADA/VIUDA/UNION LIBRE para FEMENINO.
R.6: El campo foto almacena el nombre del archivo fisico de la imagen de perfil del trabajador. La imagen puede ser subida por el usuario o, si no se proporciona, se asigna una imagen por defecto. El backend controla la creación y el reemplazo del archivo según la R.G.4.
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
    fts_trabajadorescargos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
	CONSTRAINT fk_trabajadorescargos_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_trabajadorescargos_cargo_id FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id),
    CONSTRAINT chk_trabajadorescargos_tipomonedaid CHECK (tipo_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_trabajadorescargos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_trabajadorescargos_sueldobase CHECK (sueldo_base >= 0),
    CONSTRAINT chk_trabajadorescargos_esactivo CHECK (es_activo IN (0, 1)),
    CONSTRAINT chk_trabajadorescargos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_trabajadorescargos_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta >= fecha_desde)
);
CREATE UNIQUE INDEX uix_trabajadorescargos_varios_unique ON trabajadores_cargos (trabajador_id, cargo_id) WHERE es_activo = 1 AND estado_id = 1000;
CREATE INDEX idx_trabajadorescargos_fts ON trabajadores_cargos USING GIN (fts_trabajadorescargos_vector) WHERE fecha_baja IS NULL;

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
    rol VARCHAR(60) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
	descripcion VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_roles_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(rol, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
	CONSTRAINT chk_roles_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_roles_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_roles_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_roles_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_roles_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_roles_rol_not_empty CHECK (TRIM(rol) <> ''),
    CONSTRAINT chk_roles_rol_minlength CHECK (LENGTH(TRIM(rol)) >= 3),
    CONSTRAINT chk_roles_rol_mayusculas CHECK (rol = UPPER(rol)),
    CONSTRAINT chk_roles_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_roles_codigo_unique ON roles (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_roles_rol_unique ON roles (rol) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_roles_fts ON roles USING GIN (fts_roles_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE roles IS 'Reglas de la tabla - roles
R.0: La tabla roles define los perfiles de acceso y autorización dentro del sistema, estableciendo las categorías jerárquicas de usuarios (Administrador, Gerente, Vendedor). Su propósito es estructurar el modelo de seguridad y control de acceso basado en roles (RBAC), simplificando la gestión de permisos al agrupar operaciones y menús bajo un único perfil que se asigna a los usuarios, garantizando que cada operador tenga acceso únicamente a las funcionalidades pertinentes a su función.
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
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_usuarios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(login, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(avatar, '')), 'B')
    ) STORED,
	CONSTRAINT fk_usuarios_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_usuarios_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
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
CREATE INDEX idx_usuarios_fts ON usuarios USING GIN (fts_usuarios_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE usuarios IS 'Reglas de la tabla - usuarios
R.0: La tabla usuarios gestiona las credenciales de acceso al sistema, vinculando a un trabajador con un rol específico y una sucursal operativa. Su propósito es autenticar y autorizar a los operadores de la plataforma, controlando el inicio de sesión y, mediante el rol_id asociado, determinando los menús y acciones permitidas para cada usuario.
R.1: Restricción Estricta de Identidad (login). El identificador login debe registrarse obligatoriamente en mayúsculas sostenidas, con una longitud mínima de 4 caracteres. Se permiten únicamente letras, números, puntos (.) y guiones bajos (_), prohibiendo espacios o caracteres especiales mediante expresiones regulares nativas.
R.3: Criptografía Asimétrica Obligatoria. Toda contraseña debe ser procesada y almacenada mandatoriamente utilizando funciones de hash seguras de una sola vía (como Bcrypt con un factor de costo mínimo de 10 o Argon2) en el servidor backend, quedando estrictamente prohibido el almacenamiento en texto plano.
R.4: Inmutabilidad del Superusuario Técnico. Las credenciales de la cuenta con identificador ADMIN (vinculadas a la infraestructura central) están protegidas mediante restricciones lógicas en la capa de servicios, impidiendo su eliminación física o la transición de su estado operativo a BORRADO o HISTORICO.
R.5: Vinculación Directa de Perfil (Rol). La cuenta de usuario posee un rol estructural único asignado mediante la propiedad rol_id, el cual determina directamente su perfil operativo en el sistema. A través de este rol único, la plataforma valida de forma unívoca los permisos y opciones de menú habilitados para el operador, simplificando la arquitectura de autenticación.
R:6: Un usuario no se puede BORRAR solo se cambia a HISTORICO';

DELETE FROM usuarios;
ALTER SEQUENCE usuarios_usuario_id_seq RESTART WITH 1;

INSERT INTO usuarios (usuario_id,trabajador_id,sucursal_id,rol_id,login,contrasena,avatar,estado_id,usuario_id_registro) VALUES
	 (1,1,1,1,'SISTEMA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','1.png',1000,1),
	 (2,2,2,2,'ADMIN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','2.png',1000,1),
	 (3,3,2,4,'PASCUAL','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','3.png',1000,1),
	 (4,4,2,5,'GLADYS','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','4.png',1000,1),
	 (5,5,2,4,'SILVIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','5.png',1000,1),
	 (6,6,2,6,'JUAN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','6.png',1000,1),
	 (7,7,2,7,'MARCELO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','7.png',1000,1),
	 (8,8,2,8,'BEATRIZ','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','8.png',1000,1),
	 (9,9,3,6,'CARLA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','9.png',1000,1),
	 (10,10,3,8,'RODRIGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','10.png',1000,1),
	 (11,11,3,7,'HECTOR','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','11.png',1000,1),
	 (12,12,3,5,'PATRICIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','12.png',1000,1),
	 (13,13,3,6,'DIEGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','13.png',1000,1),
	 (14,14,3,7,'MONICA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','14.png',1000,1),
	 (15,15,2,3,'VALERIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','15.png',1000,1);
	 
UPDATE usuarios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE usuarios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('usuarios_usuario_id_seq', COALESCE((SELECT MAX(usuario_id) FROM usuarios), 1));

-- ================================================================================================

CREATE TABLE roles_tablas (
    rol_tabla_id BIGSERIAL PRIMARY KEY,
    rol_id BIGINT NOT NULL DEFAULT 1,
    tabla VARCHAR(100) NOT NULL DEFAULT '',
    leer SMALLINT NOT NULL DEFAULT 0,
    crear SMALLINT NOT NULL DEFAULT 0,
    editar SMALLINT NOT NULL DEFAULT 0,
    eliminar SMALLINT NOT NULL DEFAULT 0,
    anular SMALLINT NOT NULL DEFAULT 0,
    archivar SMALLINT NOT NULL DEFAULT 0,
    desarchivar SMALLINT NOT NULL DEFAULT 0,
    eventos_permitidos JSONB NOT NULL DEFAULT '{}'::jsonb,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_rolestablas_rol_id FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT chk_rolestablas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_rolestablas_leer CHECK (leer IN (0, 1)),
    CONSTRAINT chk_rolestablas_crear CHECK (crear IN (0, 1)),
    CONSTRAINT chk_rolestablas_editar CHECK (editar IN (0, 1)),
    CONSTRAINT chk_rolestablas_eliminar CHECK (eliminar IN (0, 1)),
    CONSTRAINT chk_rolestablas_anular CHECK (anular IN (0, 1)),
    CONSTRAINT chk_rolestablas_archivar CHECK (archivar IN (0, 1)),
    CONSTRAINT chk_rolestablas_desarchivar CHECK (desarchivar IN (0, 1)),
    CONSTRAINT chk_rolestablas_tabla_notempty CHECK (TRIM(tabla) <> ''),
    CONSTRAINT chk_rolestablas_tabla_formato CHECK (tabla = LOWER(TRIM(tabla))AND tabla ~ '^[a-z][a-z0-9_]*$'),
    CONSTRAINT chk_rolestablas_eventos_objeto CHECK (jsonb_typeof(eventos_permitidos) = 'object')
);
CREATE UNIQUE INDEX uix_rolestablas_activo ON roles_tablas (rol_id, tabla) WHERE estado_id = 1000;
CREATE INDEX idx_rolestablas_rol ON roles_tablas (rol_id) WHERE estado_id = 1000;

COMMENT ON TABLE roles_tablas IS 'Reglas de la tabla - roles_tablas
R.0: La tabla roles_tablas define los permisos granulares que cada rol tiene sobre cada tabla del sistema.
R.1: Los permisos operativos generales son leer, crear, editar y eliminar sobre las tablas asignadas.
R.2: El rol ADMINISTRADOR (rol_id=2) tiene todos los permisos operativos generales sobre todas las tablas. Las acciones críticas de anular, archivar y desarchivar se restringen estrictamente a kardex, ordenes_compra y control_facturas, y ÚNICAMENTE pueden ser ejecutadas por los roles ADMINISTRADOR (2) y ENCARGADO DE SUCURSAL (4).
R.3: El rol GERENTE (rol_id=3) solo tiene permisos de lectura (leer=1) sobre todas las tablas.
R.4: El rol ENCARGADO DE SUCURSAL (rol_id=4) posee esquema operativo completo, con anulación, archivo y desarchivo restringidos exclusivamente a kardex, ordenes_compra y control_facturas (compartiendo exclusividad con el Administrador). El acotamiento por sucursal se valida en la lógica de negocio.
R.5: La tabla kardex maneja múltiples eventos de negocio cuya autorización fina se valida en JSONB mediante eventos_permitidos.';

DELETE FROM roles_tablas;
ALTER SEQUENCE roles_tablas_rol_tabla_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - TODOS LOS PERMISOS EN 0
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
VALUES (1, 'ninguno', 0, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: ADMINISTRADOR (rol_id = 2) - PERMISOS GENERALES Y RESTRICCIONES CRÍTICAS APLICADAS
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    2, 
    t.tabla, 
    1, 1, 1, 1, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla = 'kardex' THEN '{"crear": [1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070], "editar": [1050,1051], "anular": [1055]}'::jsonb ELSE '{}'::jsonb END,
    1000, 1 
FROM (
    VALUES 
    ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones'), ('tablas')
) AS t(tabla);

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    3, 
    t.tabla, 
    1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1 
FROM (
    VALUES 
    ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones'), ('tablas')
) AS t(tabla);

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - OPERATIVO CON RESTRICCIONES EXCLUSIVAS DE ANULACIÓN/ARCHIVO
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    4, 
    t.tabla, 
    1, 1, 1, 1, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla = 'kardex' THEN '{"crear": [1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070], "editar": [1050,1051], "anular": [1055]}'::jsonb ELSE '{}'::jsonb END,
    1000, 1 
FROM (
    VALUES 
    ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones'), ('tablas')
) AS t(tabla);

-- ROL: COMPRADOR (rol_id = 5) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(5, 'proveedores', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'proveedores_contactos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'proveedores_rating_historico', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1050, 1058], "editar": []}'::jsonb, 1000, 1),
(5, 'ordenes_compra', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'parametros_globales', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'tareas_programadas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'tipos_planes_pago', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'planes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'comprobantes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: VENDEDOR (rol_id = 6) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(6, 'clientes', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'productos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1051, 1052, 1059], "editar": [1051]}'::jsonb, 1000, 1),
(6, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'pedidos_online', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'detalles_pedidos_online', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'carritos_compra', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'detalles_carritos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'listas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'precios_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'politicas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'cajas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'movimientos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: ALMACENERO (rol_id = 7) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(7, 'almacenes', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'ubicaciones', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'almacenes_puntos_venta', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'productos_ubicaciones', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1053, 1054, 1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070], "editar": []}'::jsonb, 1000, 1),
(7, 'lotes_productos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'ubicaciones_movimientos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'ubicaciones_historial', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'inventarios_fisicos_detalle', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'inventarios_fisicos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'umbrales_configuracion', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'analitica_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: CAJERO (rol_id = 8) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(8, 'clientes', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1051], "editar": []}'::jsonb, 1000, 1),
(8, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'control_facturas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'comprobantes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'cajas', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'movimientos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'arqueos_detalle', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'bancos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'listas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'precios_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

UPDATE roles_tablas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles_tablas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_tablas_rol_tabla_id_seq', COALESCE((SELECT MAX(rol_tabla_id) FROM roles_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_tablas));

-- ================================================================================================

CREATE TABLE menus (
    menu_id BIGSERIAL PRIMARY KEY,
    menu_padre_id BIGINT NULL,
    titulo VARCHAR(150) NOT NULL,
    icono VARCHAR(50) NULL,
    url VARCHAR(255) NULL,
    orden INTEGER NOT NULL DEFAULT 0,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_menus_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(titulo, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(icono, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(url, '')), 'B')
    ) STORED,
    CONSTRAINT fk_menus_menu_padre_id FOREIGN KEY (menu_padre_id) REFERENCES menus(menu_id),
    CONSTRAINT chk_menus_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_menus_titulo_notempty CHECK (TRIM(titulo) <> ''),
    CONSTRAINT chk_menus_titulo_minlength CHECK (LENGTH(TRIM(titulo)) >= 3),
    CONSTRAINT chk_menus_icono_notempty CHECK (icono IS NULL OR TRIM(icono) <> ''),
    CONSTRAINT chk_menus_url_notempty CHECK (url IS NULL OR TRIM(url) <> ''),
    CONSTRAINT chk_menus_orden CHECK (orden >= 0)
);
CREATE UNIQUE INDEX uix_menus_varios_unique ON menus (menu_padre_id, titulo, orden) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_menus_orden ON menus (orden ASC) WHERE estado_id = 1000;
CREATE INDEX idx_menus_fts ON menus USING GIN (fts_menus_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE menus IS 'Reglas de la tabla - menus
R.0: La tabla menus define la estructura jerárquica y navegacional de la interfaz de usuario, agrupando las funcionalidades del sistema en un árbol de navegación dinámico. Su propósito es construir el menú lateral de la aplicación para cada usuario, basándose en la asignación de permisos de la tabla roles_menus, y de esta manera, presentar únicamente las opciones correspondientes al rol del usuario. Se conecta de forma autorreferencial (menu_padre_id) para formar la jerarquía y con la tabla roles_menus.
R.1: Renderizado del Menú Lateral: El frontend procesará recursivamente la respuesta filtrando o ignorando el menu_id = 1. Aquellos registros cuyo menu_padre_id seja NULL o igual a 1 se tratarán como secciones principales o cabeceras de grupo en el Sidebar de PrimeVue.
R.2: Comportamiento de Enrutamiento: Si el campo url es NULL, el componente actuará exclusivamente como un contenedor colapsable (deshabilitando el enrutador y manejando el estado de expansión de la interfaz).
R.3: Tratamiento del Registro Comodín: El registro con menu_id = 1 representa el nodo raíz ficticio del sistema. No es visible en la interfaz operativa. El backend bloqueará cualquier intento de modificación o eliminación de este registro para salvaguardar la integridad referencial.
R.4: Ordenación Dinámica: Las consultas de menús deben ordenarse por el nivel jerárquico y luego por el campo orden. El frontend respetará estrictamente este índice numérico para la disposición visual de los accesos.';

DELETE FROM menus;
ALTER SEQUENCE menus_menu_id_seq RESTART WITH 1;

INSERT INTO menus (menu_id, menu_padre_id, titulo, icono, url, orden, estado_id, usuario_id_registro) VALUES
(1, NULL, 'NINGUNO', NULL, NULL, 0, 1000, 1),
(2, NULL, 'CONFIGURACIÓN Y SISTEMA', 'pi pi-cog', NULL, 1, 1000, 1),
(3, 2, 'DATOS DE LA EMPRESA', 'pi pi-building', '/configuracion/empresa', 1, 1000, 1),
(4, 2, 'GESTIÓN DE NITS Y AUTORIZACIONES', 'pi pi-id-card', '/configuracion/nits', 2, 1000, 1),
(5, 2, 'CUENTAS BANCARIAS', 'pi pi-credit-card', '/configuracion/cuentas-bancarias', 3, 1000, 1),
(6, 2, 'SUCURSALES Y PUNTOS', 'pi pi-map-marker', '/configuracion/sucursales', 4, 1000, 1),
(7, 2, 'CONTROL DE USUARIOS', 'pi pi-users', '/configuracion/usuarios', 5, 1000, 1),
(8, 2, 'ROLES Y PERMISOS', 'pi pi-key', '/configuracion/roles', 6, 1000, 1),
(9, 2, 'PARÁMETROS GLOBALES', 'pi pi-sliders-h', '/configuracion/parametros', 7, 1000, 1),
(10, 2, 'TASAS DE CAMBIO', 'pi pi-dollar', '/configuracion/tipos-cambio', 8, 1000, 1),
(11, 2, 'TAREAS PROGRAMADAS', 'pi pi-calendar-clock', '/configuracion/tareas', 9, 1000, 1),
(12, 2, 'LOGS DE EJECUCIÓN', 'pi pi-file-code', '/configuracion/logs', 10, 1000, 1),
(13, 2, 'AUDITORÍA DE DATOS', 'pi pi-eye', '/configuracion/auditoria', 11, 1000, 1),
(14, 2, 'RESPALDOS DE DATOS (BACKUP)', 'pi pi-cloud-upload', '/configuracion/backup', 12, 1000, 1),
(15, NULL, 'GESTIÓN DE PRODUCTOS', 'pi pi-box', NULL, 2, 1000, 1),
(16, 15, 'CATÁLOGO DE PRODUCTOS', 'pi pi-shopping-bag', '/productos/catalogo', 1, 1000, 1),
(17, 15, 'CATEGORÍAS', 'pi pi-tags', '/productos/categorias', 2, 1000, 1),
(18, 15, 'LABORATORIOS', 'pi pi-percentage', '/productos/laboratorios', 3, 1000, 1),
(19, 15, 'PRINCIPIOS ACTIVOS', 'pi pi-info-circle', '/productos/principios-activos', 4, 1000, 1),
(20, 15, 'FORMAS FARMACÉUTICAS', 'pi pi-tablet', '/productos/formas', 5, 1000, 1),
(21, 15, 'PRESENTACIONES COMERCIALES', 'pi pi-clone', '/productos/presentaciones', 6, 1000, 1),
(22, 15, 'CONCENTRACIONES', 'pi pi-filter', '/productos/concentraciones', 7, 1000, 1),
(23, 15, 'REGISTROS SANITARIOS', 'pi pi-file', '/productos/registros-sanitarios', 8, 1000, 1),
(24, 15, 'PRODUCTOS CONTROLADOS', 'pi pi-exclamation-circle', '/productos/controlados', 9, 1000, 1),
(25, 15, 'UNIDADES DE MEDIDA', 'pi pi-calculator', '/productos/unidades', 10, 1000, 1),
(26, 15, 'CONVERSIONES DE UNIDAD', 'pi pi-refresh', '/productos/conversiones', 11, 1000, 1),
(27, 15, 'PROMOCIONES Y OFERTAS', 'pi pi-percentage', '/productos/promociones', 12, 1000, 1),
(28, NULL, 'INVENTARIOS Y ALMACENES', 'pi pi-home', NULL, 3, 1000, 1),
(29, 28, 'ALMACENES FÍSICOS', 'pi pi-map', '/inventario/almacenes', 1, 1000, 1),
(30, 28, 'UBICACIONES INTERNAS', 'pi pi-compass', '/inventario/ubicaciones', 2, 1000, 1),
(31, 28, 'MOVIMIENTOS DE KARDEX', 'pi pi-list', '/inventario/kardex', 3, 1000, 1),
(32, 28, 'CONTROL DE LOTES', 'pi pi-barcode', '/inventario/lotes', 4, 1000, 1),
(33, 28, 'TRASPASOS INTER-SUCURSALES', 'pi pi-arrow-h', '/inventario/traspasos', 5, 1000, 1),
(34, 28, 'DISTRIBUCIÓN EN ESTANTERÍAS', 'pi pi-server', '/inventario/productos-ubicaciones', 6, 1000, 1),
(35, NULL, 'COMPRAS Y PROVEEDORES', 'pi pi-shopping-cart', NULL, 4, 1000, 1),
(36, 35, 'REGISTRO DE PROVEEDORES', 'pi pi-truck', '/compras/proveedores', 1, 1000, 1),
(37, 35, 'ÓRDENES Y RECEPCIONES', 'pi pi-plus-circle', '/compras/ordenes', 2, 1000, 1),
(38, 35, 'PLANES DE PAGO Y CRÉDITOS', 'pi pi-calendar', '/compras/planes-pago', 3, 1000, 1),
(39, 35, 'GESTIÓN DE CRÉDITOS A PROVEEDORES', 'pi pi-money-bill', '/compras/pagos', 4, 1000, 1),
(40, NULL, 'VENTAS Y FACTURACIÓN', 'pi pi-wallet', NULL, 5, 1000, 1),
(41, 40, 'PUNTO DE VENTA (POS)', 'pi pi-desktop', '/ventas/pos', 1, 1000, 1),
(42, 40, 'REGISTRO DE CLIENTES', 'pi pi-user-plus', '/ventas/clientes', 2, 1000, 1),
(43, 40, 'DOSIFICACIÓN Y FACTURAS (SIN)', 'pi pi-file-excel', '/ventas/control-facturas', 3, 1000, 1),
(44, 40, 'HISTÓRICO DE DOCUMENTOS', 'pi pi-folder-open', '/ventas/documentos-historicos', 4, 1000, 1),
(45, 40, 'COMPROBANTES DIGITALES / QR', 'pi pi-qrcode', '/ventas/comprobantes', 5, 1000, 1),
(46, NULL, 'GESTIÓN DE CAJA', 'pi pi-percentage', NULL, 6, 1000, 1),
(47, 46, 'APERTURA Y CIERRE', 'pi pi-lock', '/caja/sesiones', 1, 1000, 1),
(48, 46, 'MOVIMIENTOS DE CAJA (VARIOS)', 'pi pi-sort', '/caja/movimientos', 2, 1000, 1),
(49, NULL, 'COMERCIO ELECTRÓNICO Y DELIVERY', 'pi pi-globe', NULL, 7, 1000, 1),
(50, 49, 'PEDIDOS ONLINE', 'pi pi-shopping-bag', '/ecommerce/pedidos', 1, 1000, 1),
(51, 49, 'CARRITOS DE COMPRA', 'pi pi-shopping-cart', '/ecommerce/carritos', 2, 1000, 1),
(52, NULL, 'PRECIOS, COSTOS Y MÁRGENES', 'pi pi-tags', NULL, 8, 1000, 1),
(53, 52, 'LISTAS DE PRECIOS', 'pi pi-list', '/precios/listas', 1, 1000, 1),
(54, 52, 'PRECIOS DE PRODUCTOS', 'pi pi-dollar', '/precios/productos', 2, 1000, 1),
(55, 52, 'COSTOS PROMEDIO', 'pi pi-chart-line', '/precios/costos', 3, 1000, 1),
(56, 52, 'POLÍTICAS DE PRECIOS', 'pi pi-sliders-h', '/precios/politicas', 4, 1000, 1),
(57, NULL, 'RECURSOS HUMANOS', 'pi pi-id-card', NULL, 9, 1000, 1),
(58, 57, 'GESTIÓN DE TRABAJADORES', 'pi pi-users', '/rrhh/trabajadores', 1, 1000, 1),
(59, 57, 'CONTROL DE ASISTENCIAS', 'pi pi-clock', '/rrhh/asistencias', 2, 1000, 1),
(60, 57, 'PLANILLAS DE SUELDOS', 'pi pi-file-pdf', '/rrhh/planillas', 3, 1000, 1),
(61, 57, 'CONTRATOS DE PERSONAL', 'pi pi-briefcase', '/rrhh/contratos', 4, 1000, 1),
(62, NULL, 'NÚCLEO ANALÍTICO Y PREDICCIONES', 'pi pi-android', NULL, 10, 1000, 1),
(63, 62, 'DASHBOARD DE ANALÍTICA CONSOLIDADA', 'pi pi-chart-bar', '/ia/analitica', 1, 1000, 1),
(64, 62, 'MODELOS ML DISPONIBLES', 'pi pi-share-alt', '/ia/modelos', 2, 1000, 1),
(65, 62, 'HISTORIAL DE ENTRENAMIENTOS', 'pi pi-sync', '/ia/entrenamientos', 3, 1000, 1),
(66, 62, 'MÉTRICAS DE RENDIMIENTO', 'pi pi-chart-line', '/ia/metricas', 4, 1000, 1),
(67, 62, 'VARIABLES EXÓGENAS AMBIENTALES', 'pi pi-cloud', '/ia/variables-exogenas', 5, 1000, 1),
(68, 62, 'PATRONES DE CONSUMO ESTACIONAL', 'pi pi-sliders-v', '/ia/patrones-consumo', 6, 1000, 1),
(69, 62, 'CONFIGURACIÓN DE UMBRALES PREDICTIVOS', 'pi pi-cog', '/ia/umbrales', 7, 1000, 1),
(70, NULL, 'NOTIFICACIONES Y ALERTAS', 'pi pi-bell', NULL, 11, 1000, 1),
(71, 70, 'BANDEJA DE NOTIFICACIONES', 'pi pi-inbox', '/alertas/notificaciones', 1, 1000, 1),
(72, 70, 'ALERTAS OPERATIVAS Y CRÍTICAS', 'pi pi-exclamation-triangle', '/alertas/criticas', 2, 1000, 1),
(73, NULL, 'REPORTES Y DIRECCIÓN GERENCIAL', 'pi pi-print', NULL, 12, 1000, 1),
(74, 73, 'CONSOLIDADOR DE REPORTES', 'pi pi-copy', '/reportes/dashboard-unico', 1, 1000, 1),
(75, 73, 'REPORTES DE INVENTARIO Y STOCK', 'pi pi-chart-scatter', '/reportes/inventario', 2, 1000, 1),
(76, 73, 'PANEL DE CONTROL FINANCIERO', 'pi pi-percentage', '/gerencia/reportes-financieros', 3, 1000, 1),
(77, 73, 'HISTORIAL DE COSTOS Y MÁRGENES', 'pi pi-chart-line', '/gerencia/historial-costos', 4, 1000, 1),
(78, 73, 'MONITOR DE ALERTAS DE RIESGO', 'pi pi-bolt', '/gerencia/alertas-criticas', 5, 1000, 1);

UPDATE menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('menus_menu_id_seq', COALESCE((SELECT MAX(menu_id) FROM menus), 1));

-- ================================================================================================

CREATE TABLE roles_menus (
    rol_menu_id BIGSERIAL PRIMARY KEY,
    rol_id BIGINT NOT NULL DEFAULT 1,
    menu_id BIGINT NOT NULL DEFAULT 1,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
	CONSTRAINT fk_rolesmenus_rol_id FOREIGN KEY (rol_id) REFERENCES roles(rol_id),
    CONSTRAINT fk_rolesmenus_menu_id FOREIGN KEY (menu_id) REFERENCES menus(menu_id),
	CONSTRAINT chk_rolesmenus_estadoid CHECK (estado_id IN (1000, 1001, 1002))
);
CREATE UNIQUE INDEX uix_rolesmenus_varios_unique ON roles_menus (rol_id, menu_id) WHERE estado_id = 1000;

COMMENT ON TABLE roles_menus IS 'Reglas de la tabla - roles_menus
R.0: La tabla roles_menus actúa ';

DELETE FROM roles_menus;
ALTER SEQUENCE roles_menus_rol_menu_id_seq RESTART WITH 1;

INSERT INTO roles_menus (rol_menu_id, rol_id, menu_id, estado_id, usuario_id_registro) VALUES
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
    fts_inventariosfisicos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
    CONSTRAINT fk_inventariosfisicos_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_inventariosfisicos_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_inventariosfisicos_usuario_registro_id FOREIGN KEY (usuario_registro_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_inventariosfisicos_usuario_supervisor_id FOREIGN KEY (usuario_supervisor_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_inventariosfisicos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_inventariosfisicos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_inventariosfisicos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
CREATE INDEX idx_inventariosfisicos_varios ON inventarios_fisicos (sucursal_id, ubicacion_id) WHERE estado_id = 1000;
CREATE INDEX idx_inventariosfisicos_fts ON inventarios_fisicos USING GIN (fts_inventariosfisicos_vector) WHERE fecha_baja IS NULL;

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
    fts_clientes_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(cliente, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(nit, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(razon_social, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(documento, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(documento_complemento, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(direccion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(numero_cuenta, '')), 'C')
    ) STORED,
    CONSTRAINT fk_clientes_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
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
CREATE INDEX idx_clientes_fts ON clientes USING GIN (fts_clientes_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE clientes IS 'Reglas de la tabla - clientes
R.0: La tabla clientes almacena el registro maestro de los compradores, ya sean trabajadores naturales o jurídicas, y es una entidad crítica para los procesos de venta y facturación. Su propósito es proporcionar los datos fiscales y de contacto necesarios para la emisión de comprobantes electrónicos, la aplicación de descuentos por volumen y el análisis de comportamiento de compra para los módulos de inteligencia de negocio.
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
    codigo VARCHAR(60) NOT NULL,
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
    fts_categorias_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(categoria, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
    CONSTRAINT fk_categorias_categoria_padre_id FOREIGN KEY (categoria_padre_id) REFERENCES categorias(categoria_id),
    CONSTRAINT chk_categorias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_categorias_categoria_notempty CHECK (TRIM(categoria) <> ''),
    CONSTRAINT chk_categorias_categoria_minlength CHECK (LENGTH(TRIM(categoria)) >= 3),
    CONSTRAINT chk_categorias_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_categorias_codigo_length CHECK (LENGTH(TRIM(codigo)) = 3),
    CONSTRAINT chk_categorias_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_categorias_codigo_format CHECK (codigo ~ '^[A-Z0-9-]+$'),
    CONSTRAINT chk_categorias_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_categorias_nivel CHECK (nivel >= 1),
    CONSTRAINT chk_categorias_orden CHECK (orden >= 0)
);
CREATE UNIQUE INDEX uix_categorias_varios_unique ON categorias (categoria_padre_id, categoria) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_categorias_codigo_unique ON categorias (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_categorias_fts ON categorias USING GIN (fts_categorias_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
    codigo_sin INTEGER NOT NULL,
    unidad VARCHAR(100) NOT NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_unidades_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(unidad, '')), 'A')
    ) STORED,
    CONSTRAINT chk_unidades_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_unidades_unidad_notempty CHECK (TRIM(unidad) <> ''),
    CONSTRAINT chk_unidades_unidad_minlength CHECK (LENGTH(TRIM(unidad)) >= 1),
    CONSTRAINT chk_unidades_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_unidades_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 1),
    CONSTRAINT chk_unidades_codigosin CHECK (codigo_sin >= 0)
);
CREATE UNIQUE INDEX uix_unidades_codigo_unique ON unidades (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_unidades_unidad_unique ON unidades (unidad) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_unidades_fts ON unidades USING GIN (fts_unidades_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE unidades IS 'Reglas de la tabla - unidades
R.0: La tabla unidades define el catálogo de unidades de medida (físicas y fiscales) utilizadas en el sistema, sirviendo como base para todas las operaciones que involucran cantidades. Su propósito es estandarizar la gestión de inventario, las compras y las ventas, proporcionando una referencia inequívoca (con código numérico para el SIN) para medir productos, y permitir conversiones de unidades a través de la tabla conversiones_unidad.
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
    codigo VARCHAR(60) NOT NULL,
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
    fts_laboratorios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(laboratorio, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(nit, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(direccion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(web, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_laboratorios_fts ON laboratorios USING GIN (fts_laboratorios_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE laboratorios IS 'Reglas de la tabla - laboratorios
R.0: La tabla laboratorios constituye el catálogo de fabricantes, proveedores o marcas de los productos farmacéuticos y de venta libre. Su función es gestionar la trazabilidad desde el origen del producto, facilitando la organización del catálogo, la aplicación de promociones por marca y la generación de reportes de compras y rentabilidad por laboratorio.
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
    codigo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(1000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_formas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(forma_farmaceutica, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_formas_fts ON formas USING GIN (fts_formas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE formas IS 'Reglas de la tabla - formas
R.0: La tabla formas define las formas farmacéuticas de los productos (ej. tableta, jarabe, inyectable), describiendo la presentación física del medicamento. Su propósito es clasificar los productos para su correcta identificación, gestión y dispensación, así como para servir como un filtro de búsqueda avanzada y control de inventario.
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
    codigo VARCHAR(60) NOT NULL,
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
    fts_presentaciones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(presentacion, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_presentaciones_fts ON presentaciones USING GIN (fts_presentaciones_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_concentraciones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(concentracion, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
    CONSTRAINT fk_concentraciones_unidad_base_id FOREIGN KEY (unidad_base_id) REFERENCES unidades(unidad_id),
    CONSTRAINT chk_concentraciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_concentraciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_concentraciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 2),
    CONSTRAINT chk_concentraciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_concentraciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_concentraciones_concentracion_notempty CHECK (TRIM(concentracion) <> ''),
    CONSTRAINT chk_concentraciones_concentracion_minlength CHECK (LENGTH(TRIM(concentracion)) >= 2),
    CONSTRAINT chk_concentraciones_valornumerico CHECK (valor_numerico IS NULL OR valor_numerico >= 0),
    CONSTRAINT chk_concentraciones_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_concentraciones_codigo_unique ON concentraciones (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_concentraciones_concentracion_unique ON concentraciones (concentracion) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_concentraciones_fts ON concentraciones USING GIN (fts_concentraciones_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE concentraciones IS 'Reglas de la tabla - concentraciones
R.0: La tabla concentraciones define la potencia de los principios activos en un producto (ej. 500mg, 100mg/ml), describiendo la cantidad de fármaco por unidad de medida. Su propósito es identificar y diferenciar productos similares para evitar confusiones médicas y garantizar la precisión en la dispensación, siendo un atributo esencial en el catálogo de productos.
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
    fts_vias_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(precauciones, '')), 'C')
    ) STORED,
	CONSTRAINT chk_vias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_vias_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_vias_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 2),
    CONSTRAINT chk_vias_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_vias_requiereayuno CHECK (requiere_ayuno IN (0, 1)),
    CONSTRAINT chk_vias_tiempoefectominutos CHECK (tiempo_efecto_minutos IS NULL OR tiempo_efecto_minutos > 0),
    CONSTRAINT chk_vias_precauciones_notempty CHECK (precauciones IS NULL OR TRIM(precauciones) <> '')
);
CREATE UNIQUE INDEX uix_vias_nombre_unique ON vias (nombre) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_vias_fts ON vias USING GIN (fts_vias_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_rangosedad_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(rango, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_rangosedad_fts ON rangos_edad USING GIN (fts_rangosedad_vector) WHERE fecha_baja IS NULL;

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

CREATE TABLE marcas (
    marca_id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_marcas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B')
    ) STORED,
    CONSTRAINT chk_marcas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_marcas_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_marcas_nombre_minlength CHECK (LENGTH(TRIM(nombre)) >= 2),
    CONSTRAINT chk_marcas_descripcion_notempty CHECK (descripcion IS NULL OR TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_marcas_nombre_unique ON marcas (nombre) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_marcas_nombre_trgm ON marcas USING GIN (nombre gin_trgm_ops) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_marcas_fts ON marcas USING GIN (fts_marcas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE marcas IS 'Reglas de la tabla - marcas
R.0: La tabla marcas almacena los fabricantes, casas editoriales (para libros) o marcas comerciales de los productos no estrictamente farmacéuticos o de consumo general que se comercializan en el sistema.
R.1: El registro con marca_id = 1 y nombre = ''NINGUNA'' es el registro predeterminado para artículos que no requieren especificar marca, se mantiene en estado HISTORICO y no puede modificarse ni eliminarse.';

DELETE FROM marcas;
ALTER SEQUENCE marcas_marca_id_seq RESTART WITH 1;

INSERT INTO marcas (marca_id, nombre, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'Marca predeterminada para productos genéricos o sin marca especificada', 1000, 1);

UPDATE marcas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE marcas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('marcas_marca_id_seq', COALESCE((SELECT MAX(marca_id) FROM marcas), 1));

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
    tipo_almacen_id INTEGER NOT NULL DEFAULT 1700,        -- 1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA
    codigo VARCHAR(60) NOT NULL,
    codigo_barras VARCHAR(100) NULL,
    sku VARCHAR(60) NULL,
    isbn VARCHAR(30) NULL,
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
    requiere_receta INTEGER NOT NULL DEFAULT 0,
    controlado INTEGER NOT NULL DEFAULT 0,
    tiene_registro_sanitario INTEGER NOT NULL DEFAULT 0,
    descripcion VARCHAR(3000) NULL,
    observacion VARCHAR(3000) NULL,
    foto1 VARCHAR(255) NULL,
    foto2 VARCHAR(255) NULL,
    foto3 VARCHAR(255) NULL,
    criticidad_medica_id INTEGER DEFAULT 4150,          -- 4150=NORMAL, 4151=CRITICO
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_productos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(codigo_barras, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(sku, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(isbn, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre_generico, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(marca_id::text, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(modelo, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(observacion, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_productos_fts ON productos USING GIN (fts_productos_vector) WHERE fecha_baja IS NULL;

DELETE FROM productos;
ALTER SEQUENCE productos_producto_id_seq RESTART WITH 1;

INSERT INTO productos (producto_id, categoria_id, laboratorio_id, marca_id, forma_id, presentacion_id, concentracion_id, unidad_venta_id, codigo, codigo_barras, sku, isbn, modelo, nombre, nombre_generico, pcompra, p_factor_venta, p_factor_facturacion, pventa, pventaf, stock_minimo, stock_maximo, punto_reorden, requiere_receta, controlado, tiene_registro_sanitario, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1, 1, 'NIN', NULL, NULL, NULL, NULL, 'NINGUNO', NULL, 0.00, 1.50, 1.19, 0.00, 0.00, 0.00, 1.00, 0.00, 0, 0, 0, 'Producto predeterminado para casos sin clasificar', 1000, 1);

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
    fts_productosvias_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
	CONSTRAINT fk_productosvias_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosvias_via_id FOREIGN KEY (via_id) REFERENCES vias(via_id),
    CONSTRAINT chk_productosvias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosvias_esprincipal CHECK (es_principal IN (0, 1)),
    CONSTRAINT chk_productosvias_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> '')
);
CREATE UNIQUE INDEX uix_productosvias_varios_unique ON productos_vias (producto_id, via_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosvias_viaid ON productos_vias (via_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosvias_fts ON productos_vias USING GIN (fts_productosvias_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE productos_vias IS 'Reglas de la tabla - productos_vias
R.0: La tabla productos_vias es una relación polimórfica que permite asociar múltiples vías de administración a un mismo producto, identificando una de ellas como principal. Su propósito es capturar la flexibilidad de algunos medicamentos que pueden ser administrados por diferentes vías, manteniendo la integridad referencial al mismo tiempo que se impone la regla de negocio de una única vía principal por producto.
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
    fts_equivalentes_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
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
CREATE INDEX idx_equivalentes_fts ON equivalentes USING GIN (fts_equivalentes_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE equivalentes IS 'Reglas de la tabla - equivalentes
R.0: La tabla equivalentes gestiona el catálogo de sustitutos farmacéuticos, vinculando un producto principal con alternativas comerciales o genéricas. Su propósito es permitir al personal de mostrador sugerir opciones viables de forma inmediata cuando el producto base está agotado o no disponible, garantizando la continuidad de la atención bajo criterios de equivalencia clínica.
R.1: Restricción de Autoreferencia. El campo producto_base_id y producto_alternativo_id deben ser estrictamente diferentes (chk_equivalentes_diferentes), impidiendo que un producto sea equivalente de sí mismo (excepto en el registro comodín inicial).
R.2: Vigencia Temporal de la Equivalencia. fecha_vigencia_desde y fecha_vigencia_hasta controlan el periodo de validez operativa de la sustitución. El índice único parcial uix_equivalentes_varios_unique asegura que no existan duplicados activos para el mismo par de productos dentro de su rango de vigencia.
R.3: Grado de Equivalencia. grado_equivalente_id clasifica el nivel de sustitución clínica (3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO, 3803=NINGUNO), ordenando las sugerencias de mayor a menor equivalencia.
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
    fts_productosrangosedad_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(dosis_recomendada, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'B')
    ) STORED,
    CONSTRAINT fk_productosrangosedad_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosrangosedad_rango_edad_id FOREIGN KEY (rango_edad_id) REFERENCES rangos_edad(rango_edad_id),
    CONSTRAINT chk_productosrangosedad_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosrangosedad_contraindicado CHECK (contraindicado IN (0, 1)),
    CONSTRAINT chk_productosrangosedad_dosisrecomendada_notempty CHECK (dosis_recomendada IS NULL OR TRIM(dosis_recomendada) <> ''),
    CONSTRAINT chk_productosrangosedad_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> '')
);
CREATE UNIQUE INDEX uix_productosrangosedad_varios_unique ON productos_rangos_edad (producto_id, rango_edad_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosrangosedad_rangoedadid ON productos_rangos_edad (rango_edad_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosrangosedad_fts ON productos_rangos_edad USING GIN (fts_productosrangosedad_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE productos_rangos_edad IS 'Reglas de la tabla - productos_rangos_edad
R.0: La tabla productos_rangos_edad es una relación polimórfica que asigna a un producto los rangos de edad para los cuales está indicado o contraindicado. Su propósito es gestionar la seguridad y el cumplimiento normativo, permitiendo al sistema filtrar automáticamente los productos adecuados según la edad del paciente y mostrando advertencias de contraindicación.
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
    codigo VARCHAR(60) NOT NULL,
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
    fts_principiosactivos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
	CONSTRAINT chk_principiosactivos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_principiosactivos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_principiosactivos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_principiosactivos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_principiosactivos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_principiosactivos_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_principiosactivos_nombre_mayusculas CHECK (nombre = UPPER(nombre)),
    CONSTRAINT chk_principiosactivos_escontrolado CHECK (es_controlado IN (0, 1))
);
CREATE UNIQUE INDEX uix_principiosactivos_codigo_unique ON principios_activos (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_principiosactivos_nombre_unique ON principios_activos (nombre) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_principiosactivos_fts ON principios_activos USING GIN (fts_principiosactivos_vector) WHERE fecha_baja IS NULL;

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
    fts_productosprincipios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(concentracion, '')), 'A')
    ) STORED,
	CONSTRAINT fk_productosprincipios_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_productosprincipios_principio_activo_id FOREIGN KEY (principio_activo_id) REFERENCES principios_activos(principio_activo_id),
    CONSTRAINT chk_productosprincipios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productosprincipios_concentracion_notempty CHECK (TRIM(concentracion) <> ''),
    CONSTRAINT chk_productosprincipios_esprincipal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_productosprincipios_varios_unique ON productos_principios (producto_id, principio_activo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosprincipios_principioactivoid ON productos_principios (principio_activo_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productosprincipios_fts ON productos_principios USING GIN (fts_productosprincipios_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE productos_principios IS 'Reglas de la tabla - productos_principios
R.0: La tabla productos_principios es una relación polimórfica que asocia principios activos a un producto, permitiendo que un medicamento compuesto tenga múltiples sustancias activas. Su propósito es modelar la composición química de los productos, identificando el principio activo principal para su categorización médica y control, lo cual es fundamental para el cumplimiento regulatorio y la prescripción.
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
    codigo_registro VARCHAR(60) NOT NULL,
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
    fts_registrossanitarios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo_registro, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(entidad_emisora, '')), 'B')
    ) STORED,
	CONSTRAINT fk_registrossanitarios_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_registrossanitarios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_registrossanitarios_codigoregistro_notempty CHECK (TRIM(codigo_registro) <> ''),
    CONSTRAINT chk_registrossanitarios_codigoregistro_mayusculas CHECK (codigo_registro = UPPER(codigo_registro)),
    CONSTRAINT chk_registrossanitarios_entidademisora_notempty CHECK (TRIM(entidad_emisora) <> ''),
    CONSTRAINT chk_registrossanitarios_entidademisora_mayusculas CHECK (entidad_emisora = UPPER(entidad_emisora)),
    CONSTRAINT chk_registrossanitarios_fechas CHECK (fecha_vencimiento > fecha_emision)
);
CREATE UNIQUE INDEX uix_registrossanitarios_productoid_unique ON registros_sanitarios (producto_id) WHERE estado_id = 1000;
CREATE INDEX idx_registrossanitarios_fts ON registros_sanitarios USING GIN (fts_registrossanitarios_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE registros_sanitarios IS 'Reglas de la tabla - registros_sanitarios
R.0: La tabla registros_sanitarios gestiona la información legal de los productos, almacenando el código de registro sanitario, su fecha de emisión y vencimiento. Su propósito es controlar la vigencia de la autorización de comercialización de cada producto, bloqueando su venta si el registro sanitario está caducado, lo que asegura el cumplimiento de la normativa sanitaria.
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
    fts_productoscontrolados_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(numero_autorizacion, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(observaciones_control, '')), 'B')
    ) STORED,
	CONSTRAINT fk_productoscontrolados_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_productoscontrolados_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_productoscontrolados_numeroautorizacion_notempty CHECK (TRIM(numero_autorizacion) <> ''),
    CONSTRAINT chk_productoscontrolados_numeroautorizacion_mayusculas CHECK (numero_autorizacion = UPPER(numero_autorizacion)),
    CONSTRAINT chk_productoscontrolados_requiererecetaretenida CHECK (requiere_receta_retenida IN (0, 1)),
    CONSTRAINT chk_productoscontrolados_observacionescontrol_notempty CHECK (observaciones_control IS NULL OR TRIM(observaciones_control) <> '')
);
CREATE UNIQUE INDEX uix_productoscontrolados_productoid_unique ON productos_controlados (producto_id) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_productoscontrolados_numeroautorizacion_unique ON productos_controlados (numero_autorizacion) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_productoscontrolados_fts ON productos_controlados USING GIN (fts_productoscontrolados_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE productos_controlados IS 'Reglas de la tabla - productos_controlados
R.0: La tabla productos_controlados extiende la información de gestión para aquellos productos sujetos a fiscalización especial, como psicotrópicos o estupefacientes. Su propósito es imponer controles adicionales como la autorización específica, el stock máximo permitido y la retención obligatoria de recetas, para cumplir con las estrictas regulaciones de sustancias controladas.
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
    codigo VARCHAR(60) NOT NULL,
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
    fts_promociones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
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
    CONSTRAINT chk_promociones_fechas CHECK (fecha_fin > fecha_inicio),
    CONSTRAINT chk_promociones_cantidades CHECK (cantidad_requerida >= 0 AND cantidad_beneficio >= 0)
);
CREATE UNIQUE INDEX uix_promociones_codigo_unique ON promociones (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_promociones_fts ON promociones USING GIN (fts_promociones_vector) WHERE fecha_baja IS NULL;

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
	CONSTRAINT fk_promocionesproductos_promocion_id FOREIGN KEY (promocion_id) REFERENCES promociones(promocion_id),
    CONSTRAINT fk_promocionesproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_promocionesproductos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_promocionesproductos_limiteportransaccion CHECK (limite_por_transaccion >= 0)
);
CREATE UNIQUE INDEX uix_promocionesproductos_productoid_unique ON promociones_productos (producto_id) WHERE estado_id = 1000;

COMMENT ON TABLE promociones_productos IS 'Reglas de la tabla - promociones_productos
R.0: La tabla promociones_productos es una relación polimórfica que vincula promociones con productos específicos, estableciendo límites por transacción. Su propósito es permitir que una promoción se aplique a un subconjunto de productos y controlar la cantidad de unidades que pueden ser beneficiadas, asegurando que la lógica de descuento sea transparente y no genere pérdidas.
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
	CONSTRAINT fk_conversionesunidad_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_conversionesunidad_unidad_origen_id FOREIGN KEY (unidad_origen_id) REFERENCES unidades(unidad_id),
    CONSTRAINT fk_conversionesunidad_unidad_destino_id FOREIGN KEY (unidad_destino_id) REFERENCES unidades(unidad_id),
    CONSTRAINT chk_conversionesunidad_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_conversionesunidad_factorconversion CHECK (factor_conversion > 0.0000),
    CONSTRAINT chk_conversionesunidad_varios CHECK (unidad_origen_id <> unidad_destino_id OR conversion_id = 1)
);
CREATE UNIQUE INDEX uix_conversionesunidad_varios_unique ON conversiones_unidad (producto_id, unidad_origen_id, unidad_destino_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_conversionesunidad_productoid ON conversiones_unidad (producto_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE conversiones_unidad IS 'Reglas de la tabla - conversiones_unidad
R.0: La tabla conversiones_unidad define los factores de conversión entre diferentes unidades de medida para un mismo producto, como de caja a unidad. Su propósito es resolver la equivalencia entre unidades (factores de empaque), lo que es fundamental para operaciones de compra, venta y gestión de inventario, permitiendo registrar, por ejemplo, una compra en cajas pero vender en unidades.
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
    codigo VARCHAR(60) NOT NULL,
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
	fts_proveedores_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(nit, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(direccion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'D')
    ) STORED,
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
CREATE INDEX idx_proveedores_fts ON proveedores USING GIN (fts_proveedores_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE proveedores IS 'Reglas de la tabla - proveedores
R.0: La tabla proveedores es el registro maestro de los suministradores de productos, almacenando su información de contacto y un rating de calidad. Su propósito es gestionar las relaciones comerciales con los laboratorios y distribuidores, sirviendo como el referente para los procesos de compras, la evaluación de desempeño de proveedores y la planificación de inventario.
R.1: El Número de Identificación Tributaria (nit) es opcional para dar soporte a proveedores extranjeros o laboratorios internacionales. Cuando se registra un valor, el índice único impide duplicados en registros activos o históricos.
R.2: El registro con proveedor_id = 1 y nombre ''NINGUNO'' representa el proveedor comodín para compras directas o donaciones; permanece en estado HISTORICO para garantizar la integridad referencial.
R.3: Los campos codigo y nombre deben almacenarse en mayúsculas y ser únicos para registros activos o históricos.
R.4: Rating de Calidad. rating_calidad_id utiliza los valores (2050-2054) para calificar el desempeño del proveedor en aspectos como cumplimiento de plazos, calidad del producto, precios, etc. El valor por defecto es REGULAR (2052). Este campo es opcional y puede ser NULL si aún no se ha evaluado al proveedor.
R.5: Suficiencia del Modelo de Proveedores. Se ratifica que la estructura actual de la tabla proveedores, complementada por el campo rating_calidad_id (referenciado a los valores 2050-2055) y la integración transversal con el kardex de compras y los módulos estratégicos del sistema, cumple de manera óptima con la evaluación de desempeño y la gestión comercial, sin requerir tablas adicionales de scoring AHP que contravengan la filosofía de simplicidad y velocidad de la arquitectura AK-47.
R.6: Control de Rating de Calidad. rating_calidad_id utiliza los valores (2050-2054).
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
    fts_proveedorescontactos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(cargo, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B')
    ) STORED,
	CONSTRAINT fk_proveedorescontactos_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_proveedorescontactos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_proveedorescontactos_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_proveedorescontactos_cargo_notempty CHECK (cargo IS NULL OR TRIM(cargo) <> ''),
    CONSTRAINT chk_proveedorescontactos_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_proveedorescontactos_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_proveedorescontactos_esprincipal CHECK (es_principal IN (0, 1))
);
CREATE UNIQUE INDEX uix_proveedorescontactos_varios_unique ON proveedores_contactos (proveedor_id) WHERE es_principal = 1 AND estado_id = 1000;
CREATE INDEX idx_proveedorescontactos_fts ON proveedores_contactos USING GIN (fts_proveedorescontactos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE proveedores_contactos IS 'Reglas de la tabla - proveedores_contactos
R.0: La tabla proveedores_contactos almacena la información de contacto asociados a cada proveedor (nombre, cargo, teléfono, email). Su propósito es gestionar los canales de comunicación y los puntos de contacto comerciales u operativos con cada suministrador.
R.1: El campo es_principal (INTEGER, 0 o 1) indica si el contacto es el principal para el proveedor. Un índice único parcial garantiza que solo exista un contacto principal en estado ACTIVO (estado_id = 1000) por cada proveedor.
R.2: Los estados de los registros se controlan mediante estado_id, gestionando los valores estándar (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO).
R.3: Cada contacto está vinculado obligatoriamente a un proveedor mediante la llave foránea fk_proveedorescontactos_proveedor_id.';

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
    fts_proveedoresratinghistorico_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(motivo, '')), 'A')
    ) STORED,
	CONSTRAINT fk_proveedoresratinghistorico_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_proveedoresratinghistorico_ratingcalidadid CHECK (rating_calidad_id IN (2050, 2051, 2052, 2053, 2054, 2055)),
    CONSTRAINT chk_proveedoresratinghistorico_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_proveedoresratinghistorico_motivo_notempty CHECK (TRIM(motivo) <> '')
);
CREATE INDEX idx_proveedoresratinghistorico_varios ON proveedores_rating_historico (proveedor_id, fecha_evaluacion DESC);
CREATE INDEX idx_proveedoresratinghistorico_fts ON proveedores_rating_historico USING GIN (fts_proveedoresratinghistorico_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE proveedores_rating_historico IS 'Reglas de la tabla - proveedores_rating_historico
R.0: La tabla proveedores_rating_historico almacena el historial de calificaciones de calidad asignadas a cada proveedor a lo largo del tiempo. Su propósito es mantener la trazabilidad y auditoría de las evaluaciones de desempeño (vinculadas a la regla R.11 de la tabla proveedores), permitiendo analizar el comportamiento del suministrador ante incidencias.
R.2: Se incluye un índice compuesto (idx_rh_proveedor_fecha) sobre proveedor_id y fecha_evaluacion en orden descendente para optimizar las consultas del historial más reciente por cada proveedor.';

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
    fts_parametrosglobales_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(clave, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(valor, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
	CONSTRAINT chk_parametrosglobales_tipodatoid CHECK (tipo_dato_id IN (1800, 1801, 1802, 1803)),
    CONSTRAINT chk_parametrosglobales_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_parametrosglobales_clave CHECK (TRIM(clave) = clave AND clave ~ '^[a-z0-9_-]+$' AND LENGTH(clave) >= 3),
    CONSTRAINT chk_parametrosglobales_valor_notempty CHECK (TRIM(valor) <> ''),
    CONSTRAINT chk_parametrosglobales_descripcion CHECK (descripcion IS NULL OR TRIM(descripcion) <> ''),
    CONSTRAINT chk_parametrosglobales_editable CHECK (editable IN (0, 1))
);
CREATE UNIQUE INDEX uix_parametrosglobales_clave_unique ON parametros_globales (clave) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_parametrosglobales_fts ON parametros_globales USING GIN (fts_parametrosglobales_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_tareasprogramadas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cron_expresion, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(ultimo_error, '')), 'D')
    ) STORED,
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
CREATE INDEX idx_tareasprogramadas_fts ON tareas_programadas USING GIN (fts_tareasprogramadas_vector) WHERE fecha_baja IS NULL;

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
    codigo_control VARCHAR(60) NULL,
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
    fts_controlfacturas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(autorizacion, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(cuf, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(cufd, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cuis, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(codigo_control, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(codigo_qr, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_controlfacturas_fts ON control_facturas USING GIN (fts_controlfacturas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE control_facturas IS 'Reglas de la tabla - control_facturas
R.0: La tabla control_facturas gestiona los talonarios de facturación y la numeración fiscal, controlando el rango de números y las credenciales (CUF, CUIS) emitidas por el SIN. Su propósito es generar el número de factura de manera atómica y concurrente para cada transacción de venta, garantizando que el correlativo no se repita y se mantenga la integridad fiscal de la empresa.
R.1: El campo estado_operativo_id rige la disponibilidad de la dosificación. Los valores posibles son: 3300=EMITIDO (activo), 3301=ANULADO, 3302=ANULADO_PARCIAL. El sistema cambia automáticamente a ANULADO cuando numero_actual alcanza numero_final o cuando fecha_vencimiento es superada.
R.2: Los campos cuf, cufd, cuis, codigo_control y codigo_qr almacenan credenciales emitidas por el SIN. Ninguno se captura manualmente; la aplicación actúa como visor de los parámetros provistos por los middlewares de facturación.
R.3: Cada sucursal solo puede tener un registro ACTIVO por tipo de comprobante y gestión. El índice uix_cf_sucursal_tipo_gestion garantiza esta unicidad.
R.4: Generación de Número de Factura en el Backend: El sistema genera números de factura de forma atómica y concurrente en el backend, aplicando bloqueo pesimista mediante SELECT ... FOR UPDATE y formateándolos según parámetros corporativos.';

DELETE FROM control_facturas;
ALTER SEQUENCE control_facturas_control_factura_id_seq RESTART WITH 1;

INSERT INTO control_facturas (control_factura_id, sucursal_id, tipo_comprobante_id, numero_actual, numero_inicial, numero_final, autorizacion, cuf, cufd, cuis, codigo_control, codigo_qr, fecha_autorizacion, fecha_vencimiento, gestion, estado_operativo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1103, 0, 1, 999999, '00000000000000000000', NULL, NULL, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 2026, 3300, 1000, 1);

UPDATE control_facturas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE control_facturas SET usuario_id_actualizacion = 1, fecha_actualizacion = NOW(), usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

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
    fts_kardex_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(comprobante, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(comprobante_referencia, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(lugar_entrega, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(numero_factura, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(nota_credito_debito, '')), 'B')
    ) STORED,
	CONSTRAINT chk_kardex_tipocomprobanteid CHECK (tipo_comprobante_id IN (1100, 1101, 1102, 1103)),
    CONSTRAINT chk_kardex_motivoanulacionid CHECK (motivo_anulacion_id IN (2450, 2451, 2452, 2453, 2454, 2455)),
    CONSTRAINT chk_kardex_motivodevolucionid CHECK (motivo_devolucion_id IN (3500, 3501, 3502, 3503, 3504, 3505, 3506, 3507)),
    CONSTRAINT chk_kardex_eventoid CHECK (evento_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)),
    CONSTRAINT chk_kardex_estadoproformaid CHECK (estado_proforma_id IN (4000, 4001, 4002, 4003, 4004)),
    CONSTRAINT chk_kardex_tipofacturaid CHECK (tipo_factura_id IN (2350, 2351, 2352, 2353)),
    CONSTRAINT chk_kardex_estadotraspasoid CHECK (estado_traspaso_id IN (2100, 2101, 2102, 2103)),
    CONSTRAINT chk_kardex_estadofinancieroid CHECK (estado_financiero_id IN (2400, 2401, 2402, 2403)),
    CONSTRAINT chk_kardex_estadopedidoid CHECK (estado_pedido_id IN (2250, 2251, 2252, 2253, 2254, 2255, 2256)),
    CONSTRAINT chk_kardex_tipodespachoid CHECK (tipo_despacho_id IN (3550, 3551, 3552, 3553, 3554)),
    CONSTRAINT chk_kardex_estadoid CHECK (estado_id IN (1000, 1001, 1002, 1003)),
    CONSTRAINT chk_kardex_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_kardex_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_kardex_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
	CONSTRAINT chk_kardex_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
	CONSTRAINT chk_kardex_totales_positivos CHECK (total_compra >= 0 AND total_venta >= 0 AND total_venta_factura >= 0 AND total_pagado >= 0 AND total_cambio >= 0 AND saldo_pendiente >= 0),
    CONSTRAINT chk_kardex_validez_dias CHECK (validez_dias >= 0)
);
CREATE UNIQUE INDEX uix_kardex_codigo_unique ON kardex (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardex_clienteid ON kardex (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardex_proveedorid ON kardex (proveedor_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardex_numerofactura ON kardex (numero_factura) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardex_varios ON kardex (sucursal_id, fecha_kardex DESC, evento_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardex_estadofinancieroid_sucursalid ON kardex (estado_financiero_id, sucursal_id) WHERE estado_id IN (1000, 1002) AND estado_financiero_id IN (3501, 3502);
CREATE INDEX idx_kardex_sucursaldestinoid_estadotraspasoid ON kardex (sucursal_destino_id, estado_traspaso_id) WHERE evento_id IN (1053, 1054) AND estado_traspaso_id = 2100;
CREATE INDEX idx_kardex_fts ON kardex USING GIN (fts_kardex_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE kardex IS 'Reglas de la tabla - kardex
R.0: La tabla kardex es el registro maestro de todas las transacciones que afectan el inventario y la operación comercial, como compras, ventas, traspasos y ajustes. Su propósito es centralizar y dar trazabilidad a cada movimiento, sirviendo como la cabecera que agrupa los detalles de los productos y que orquesta el flujo de caja, la facturación y la generación de documentos históricos.
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
R.14: Tipo de Factura. tipo_factura_id utiliza los valores (2350-2352): CF (2350) para factura con derecho a crédito fiscal, SF (2351) para factura sin derecho a crédito fiscal, NCD (2352) para nota de crédito-débito. Este campo complementa a tipo_comprobante_id y numero_factura para identificar el tipo de documento fiscal emitido.
R.15: Estado de Traspaso. estado_traspaso_id utiliza los valores (2100-2103): EN_TRANSITO (2100) para mercancía en movimiento entre sucursales, RECIBIDO (2101) cuando la sucursal destino confirma la recepción, RECHAZADO (2102) cuando el traspaso es cancelado o rechazado, NO_APLICA (2103) para eventos que no son traspasos. Este campo SOLO aplica para eventos de traspaso (evento_id = 1053 EGR_TRASPASO o 1054 ING_TRASPASO). Para otros eventos, debe ser 2103.
R.16: Estado de Pedido (Solicitud de Compra). estado_pedido_id utiliza los valores (2250-2256) exclusivamente para el evento SOLICITUD_COMPRA (1058). Controla el ciclo de vida del pedido: COTIZADO (2250), APROBADO (2251), EN_RUTA (2252), RECIBIDO (2253), PARCIAL (2254), RECHAZADO (2255), CANCELADO (2256). Para cualquier otro evento debe ser NULL.
R.17: Tipo de Despacho. tipo_despacho_id utiliza los valores (3550-3553) exclusivamente para el evento VENTA (1051). Define la modalidad de entrega: VENTA_MOSTRADOR (3550), DOMICILIO (3551), RETIRO (3552), TRANSFERENCIA (3553). Para eventos que no son ventas, el valor por defecto es VENTA_MOSTRADOR (3550).
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
R.36: Generación de Número de Solicitud. Para SOLICITUD_COMPRA (1058), el backend debe generar un número de solicitud con formato: SOL-[SUCURSAL_ID]-[GESTION]-[CORRELATIVO].';

DELETE FROM kardex;
ALTER SEQUENCE kardex_kardex_id_seq RESTART WITH 1;

INSERT INTO kardex (kardex_id, tipo_comprobante_id, motivo_anulacion_id, motivo_devolucion_id, cliente_id, proveedor_id, sucursal_id, sucursal_destino_id, kardex_origen_id, kardex_pedido_compra_id, evento_id, codigo, comprobante, comprobante_referencia, kardex_referencia_id, fecha_kardex, total_compra, total_venta, total_venta_factura, total_pagado, total_cambio, saldo_pendiente, lugar_entrega, numero_factura, nota_credito_debito, validez_dias, fecha_expiracion, estado_proforma_id, tipo_factura_id, estado_traspaso_id, estado_financiero_id, estado_pedido_id, tipo_despacho_id, estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja) VALUES 
(1, 1103, 2455, 3506, 1, 1, 1, NULL, NULL, NULL, 1050, 'INI-1-2026-00000000', 'REGISTRO COMODIN SISTEMA', NULL, NULL, CURRENT_TIMESTAMP, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 4000, 2353, 2103, 2403, NULL, 3554, 1000, 1, NULL, NULL, CURRENT_TIMESTAMP, NULL, NULL);

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
    fts_ordenescompra_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(numero_orden, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'B')
    ) STORED,
    CONSTRAINT fk_ordenescompra_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_ordenescompra_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_ordenescompra_estadopedidoid CHECK (estado_pedido_id IN (2250, 2251, 2252, 2253, 2254, 2255, 2256)),
    CONSTRAINT chk_ordenescompra_estadoid CHECK (estado_id IN (1000, 1001, 1002, 1003)),
    CONSTRAINT chk_ordenescompra_fechas CHECK (fecha_entrega_estimada IS NULL OR fecha_orden <= fecha_entrega_estimada),
    CONSTRAINT chk_ordenescompra_fechareal CHECK (fecha_entrega_real IS NULL OR fecha_orden <= fecha_entrega_real)
);
CREATE UNIQUE INDEX uix_ordenescompra_numeroorden_unique ON ordenes_compra (numero_orden) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ordenescompra_fts ON ordenes_compra USING GIN (fts_ordenescompra_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE ordenes_compra IS 'Reglas de la tabla - ordenes_compra
R.0: La tabla ordenes_compra registra las órdenes de compra emitidas a los proveedores para el abastecimiento de productos, enlazándose directamente con la tabla kardex y la tabla proveedores. Su propósito es controlar el ciclo de vida del pedido, desde su cotización hasta su recepción o anulación.
R.1: El número de orden (numero_orden) debe ser único para registros activos o históricos (estado_id IN (1000, 1002)), evitando duplicidades en la numeración oficial de compras.
R.2: El estado del pedido se controla mediante estado_pedido_id, vinculándose a los valores de estados de pedido (2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO).
R.3: Cada orden de compra está vinculada obligatoriamente a un registro en kardex mediante fk_oc_kardex_id y a un proveedor mediante fk_oc_proveedor_id.';

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_instituciones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(institucion, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(direccion, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_instituciones_fts ON instituciones USING GIN (fts_instituciones_vector) WHERE fecha_baja IS NULL;

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
    fts_especialidades_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(especialidad, '')), 'A')
    ) STORED,
    CONSTRAINT chk_especialidades_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_especialidades_especialidad_notempty CHECK (TRIM(especialidad) <> ''),
    CONSTRAINT chk_especialidades_especialidad_mayusculas CHECK (especialidad = UPPER(especialidad))
);
CREATE UNIQUE INDEX uix_especialidades_especialidad_unique ON especialidades (especialidad) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_especialidades_fts ON especialidades USING GIN (fts_especialidades_vector) WHERE fecha_baja IS NULL;

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
    fts_medicos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(medico, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(matricula, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(email, '')), 'B')
		) STORED,
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
CREATE INDEX idx_medicos_fts ON medicos USING GIN (fts_medicos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE medicos IS 'Reglas de la tabla - medicos
R.0: La tabla medicos constituye el catálogo maestro de profesionales de la salud que prestan servicios en la farmacia, almacenando información personal, credenciales profesionales y datos de contacto. Su función principal es respaldar la prescripción de medicamentos, la emisión de recetas y la trazabilidad de los tratamientos médicos, garantizando la integridad y legalidad de las transacciones farmacéuticas.
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
    fts_recetas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(numero_receta, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(diagnostico, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(receta_pdf, '')), 'C')
    ) STORED,
	CONSTRAINT fk_recetas_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_recetas_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_recetas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_recetas_medico_id FOREIGN KEY (medico_id) REFERENCES medicos(medico_id),
    CONSTRAINT fk_recetas_institucion_id FOREIGN KEY (institucion_id) REFERENCES instituciones(institucion_id),
    CONSTRAINT chk_recetas_tiporeceaid CHECK (tipo_receta_id IN (3850, 3851, 3852, 3853)),
    CONSTRAINT chk_recetas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_recetas_numeroreceta_notempty CHECK (TRIM(numero_receta) <> ''),
    CONSTRAINT chk_recetas_numeroreceta_minlength CHECK (LENGTH(TRIM(numero_receta)) >= 3),
    CONSTRAINT chk_recetas_fechaemision_valida CHECK (fecha_emision <= CURRENT_DATE)
);
CREATE UNIQUE INDEX uix_recetas_numeroreceta_unique ON recetas (numero_receta) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_recetas_varios_unique ON recetas (kardex_id, cliente_id, medico_id, fecha_emision) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_recetas_fts ON recetas USING GIN (fts_recetas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE recetas IS 'Reglas de la tabla - recetas
R.0: La tabla recetas constituye el registro maestro de prescripciones médicas emitidas en la farmacia, almacenando la información completa de cada receta incluyendo el médico, paciente, institución y diagnóstico asociado. Su función principal es respaldar la dispensación de medicamentos, garantizar la trazabilidad de los tratamientos y cumplir con los requisitos legales de control de medicamentos controlados.
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
    rating_calidad_id INTEGER DEFAULT 2055,             -- 2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO
    estado_lote_id INTEGER NOT NULL DEFAULT 2503,       -- 2500=VIGENTE, 2501=VENCIDO, 2502=AGOTADO, 2503=NINGUNO
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_lotesproductos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(lote_proveedor, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_lotesproductos_fts ON lotes_productos USING GIN (fts_lotesproductos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE lotes_productos IS 'Reglas de la tabla - lotes_productos
R.0: La tabla lotes_productos es el núcleo del control de inventario físico, representando la llegada de una cantidad de un producto con un precio de costo, fecha de vencimiento y una existencia inicial. Su propósito es permitir la trazabilidad FIFO (primero en entrar, primero en salir), controlar el stock por lote, gestionar el costo de venta y la ubicación física, así como las alertas de vencimiento y agotamiento de inventario.
R.1: Gestión de Stock y Reservas. cantidad_actual representa el stock disponible para venta o despacho. cantidad_reservada representa el stock apartado para ventas en proceso o reservas (VENTA_RESERVA). El stock total del lote se define como stock_total = cantidad_actual + cantidad_reservada, y el sistema valida estrictamente que stock_total <= cantidad_inicial.
R.2: Control de Stock por Lote en Ventas. Al registrar una venta, el backend debe validar que la cantidad solicitada <= cantidad_actual del lote. Si el stock disponible es insuficiente, debe rechazar la transacción con el mensaje: "Stock insuficiente en lote X. Disponible: Y.YY, Solicitado: Z.ZZ".
R.3: Registro Inicial Comodín. El lote con lote_id = 1 es un registro histórico con cantidad_actual = 0, estado_lote_id = 2503 (NINGUNO) y estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un lote de referencia.
R.4: Precios de Lote vs Producto. precio_costo es específico del lote y puede diferir del precio base del producto (productos.pcompra). El sistema utiliza el precio_costo del lote para calcular el costo_venta en kardex_productos. Los precios de venta se gestionan en productos (catálogo) y kardex_productos (transaccional).
R.5: Control de Vencimientos y Calidad. El frontend debe mostrar alertas visuales cuando fecha_vencimiento esté próxima según los parámetros globales ''dias_alerta_vencimiento_critico'' (15 días), ''dias_alerta_vencimiento_alta'' (30 días) y ''dias_alerta_vencimiento_media'' (60 días). El campo rating_calidad_id utiliza los valores (2050-2054, con 2055 por defecto como NINGUNO) para el control de calidad interna.
R.6: Inmutabilidad del Código de Lote y Trazabilidad del Proveedor. codigo se genera automáticamente por el backend al registrar una compra o ajuste de inventario y no puede ser modificado por el usuario (patrón: [PREFIJO]-[PRODUCTO_ID]-[FECHA]-[CORRELATIVO]). El campo lote_proveedor almacena el código de lote original emitido por el proveedor para facilitar la trazabilidad externa.
R.7: Bloqueo de Lotes Agotados y Estados Automáticos. Un lote con cantidad_actual = 0 se bloquea automáticamente para nuevas ventas (estado_lote_id = 2502 AGOTADO), pero permanece visible en el histórico. Solo puede reactivarse mediante un ajuste que incremente cantidad_actual. Adicionalmente, el backend gestiona la actualización automática a VENCIDO (2501) si fecha_vencimiento < CURRENT_DATE.
R.8: Fuente de Verdad del Costo. El campo precio_costo almacena el costo de adquisición del lote en el momento de su creación. Este valor es la fuente de verdad para el costo de venta y se copia al campo pcompra de kardex_productos al momento de cada transacción que afecte este lote.
R.9: Ubicación y Auditoría de Movimientos. ubicacion_id indica el depósito físico actual del lote y puede ser NULL si se encuentra en tránsito o sin asignar. El backend es responsable de mantener actualizados los campos ultimo_movimiento y fecha_actualizacion ante cualquier cambio de estado o stock.';

DELETE FROM lotes_productos;
ALTER SEQUENCE lotes_productos_lote_id_seq RESTART WITH 1;

INSERT INTO lotes_productos (lote_id, producto_id, kardex_id, codigo, fecha_vencimiento, cantidad_inicial, cantidad_actual, cantidad_reservada, precio_costo, fecha_fabricacion, lote_proveedor, ubicacion_id, rating_calidad_id, estado_lote_id, estado_id, usuario_id_registro)
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
	CONSTRAINT fk_kardexproductos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
	CONSTRAINT fk_kardexproductos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_kardexproductos_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
	CONSTRAINT fk_kardexproductos_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
	CONSTRAINT fk_kardexproductos_presentacion_id FOREIGN KEY (presentacion_id) REFERENCES presentaciones(presentacion_id),
	CONSTRAINT fk_kardexproductos_kardex_producto_origen_id FOREIGN KEY (kardex_producto_origen_id) REFERENCES kardex_productos(kardex_producto_id),
	CONSTRAINT chk_kardexproductos_tipopagoid CHECK (tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406)),
	CONSTRAINT chk_kardexproductos_tipoventaid CHECK (tipo_venta_id IN (1350, 1351, 1352)),
	CONSTRAINT chk_kardexproductos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE UNIQUE INDEX uix_kardexproductos_varios_unique ON kardex_productos (kardex_id, producto_id, lote_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardexproductos_kardexid ON kardex_productos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardexproductos_tipoventaid_fecharegistro ON kardex_productos (tipo_venta_id, fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardexproductos_loteid_sucursalid ON kardex_productos (lote_id, sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_kardexproductos_kardexproductoorigenid ON kardex_productos (kardex_producto_origen_id) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE kardex_productos IS 'Reglas de la tabla - kardex_productos
R.0: La tabla kardex_productos es el detalle transaccional de cada movimiento de inventario, registrando las cantidades de entrada o salida de un producto específico, su precio y el lote afectado. Su propósito es registrar el impacto cuantitativo y financiero de las transacciones en el inventario, permitiendo la actualización del stock, el cálculo del costo de venta y la auditoría detallada de cada ítem de compra o venta.
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
    fts_inventariosfisicosdetalle_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
	CONSTRAINT fk_inventariosfisicosdetalle_inventario_fisico_id FOREIGN KEY (inventario_fisico_id) REFERENCES inventarios_fisicos(inventario_fisico_id),
	CONSTRAINT fk_inventariosfisicosdetalle_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
	CONSTRAINT fk_inventariosfisicosdetalle_lote_id FOREIGN KEY (lote_id) REFERENCES lotes_productos(lote_id),
	CONSTRAINT fk_inventariosfisicosdetalle_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
	CONSTRAINT chk_inventariosfisicosdetalle_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
	CONSTRAINT chk_inventariosfisicosdetalle_cantidades CHECK (cantidad_sistema >= 0 AND cantidad_contada >= 0)
);
CREATE UNIQUE INDEX uix_inventariosfisicosdetalle_varios_unique ON inventarios_fisicos_detalle (inventario_fisico_id, lote_id, ubicacion_id) WHERE estado_id = 1000;
CREATE INDEX idx_inventariosfisicosdetalle_fts ON inventarios_fisicos_detalle USING GIN (fts_inventariosfisicosdetalle_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE inventarios_fisicos_detalle IS 'Reglas de la tabla - inventarios_fisicos_detalle
R.0: Almacena el desglose ítem por ítem de cada producto, lote y ubicación contados durante un proceso de inventario físico.
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
    fts_ubicacionesmovimientos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(motivo, '')), 'A')
    ) STORED,
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
CREATE INDEX idx_ubicacionesmovimientos_fts ON ubicaciones_movimientos USING GIN (fts_ubicacionesmovimientos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE ubicaciones_movimientos IS 'Reglas de la tabla - ubicaciones_movimientos
R.0: La tabla ubicaciones_movimientos registra todos los movimientos físicos de productos entre ubicaciones, permitiendo una auditoría completa de la logística interna, la trazabilidad por lote y el control detallado de las transferencias de inventario.
R.1: Origen y Destino de las Transferencias. El campo ubicacion_origen_id representa el punto de partida de la mercancía y puede ser NULL únicamente cuando se trata de un ingreso inicial de inventario al sistema o una recepción externa sin precedentes en ubicaciones internas previas. El campo ubicacion_destino_id is obligatorio e indica el punto final donde se ubica físicamente el lote.
R.2: Validación y Actualización Automática de Stock. El backend es responsable de validar las reglas de capacidad de la ubicación de destino antes de confirmar la inserción, así como de actualizar de manera automática y transaccional el campo stock_actual tanto en la ubicación de origen (si aplica) como en la de destino.
R.3: Cantidades y Restricciones Estrictas. La columna cantidad se expresa en la unidad base del producto y debe cumplir estrictamente con la restricción de ser mayor a cero (cantidad > 0). Asimismo, se valida por restricción a nivel de base de datos que la ubicación de origen y la de destino nunca sean iguales, evitando bucles lógicos en la transferencia.
R.4: Inmutabilidad Histórica. Las filas registradas en esta tabla poseen un carácter inmutable para garantizar la integridad de las auditorías de inventario físico. No se permiten modificaciones (UPDATE) ni eliminaciones directas (DELETE) sobre los registros históricos de movimientos de ubicación.';

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
    fts_ubicacioneshistorial_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(motivo, '')), 'A')
    ) STORED,	
	CONSTRAINT fk_ubicacioneshistorial_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_ubicacioneshistorial_ubicacion_origen_id FOREIGN KEY (ubicacion_origen_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ubicacioneshistorial_ubicacion_destino_id FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_ubicacioneshistorial_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT fk_ubicacioneshistorial_usuario_id FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_ubicacioneshistorial_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicacioneshistorial_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_ubicacioneshistorial_motivo CHECK (TRIM(motivo) <> ''),
    CONSTRAINT chk_ubicacioneshistorial_ubicacionesdiferentes CHECK (ubicacion_origen_id IS NULL OR ubicacion_origen_id <> ubicacion_destino_id)
);
CREATE INDEX idx_ubicacioneshistorial_productoid ON ubicaciones_historial (producto_id);
CREATE INDEX idx_ubicacioneshistorial_fechamovimiento ON ubicaciones_historial (fecha_movimiento DESC);
CREATE INDEX idx_ubicacioneshistorial_ubicaciondestinoid ON ubicaciones_historial (ubicacion_destino_id);
CREATE INDEX idx_ubicacioneshistorial_usuarioid ON ubicaciones_historial (usuario_id);
CREATE INDEX idx_ubicacioneshistorial_varios ON ubicaciones_historial (usuario_id, fecha_movimiento DESC);
CREATE INDEX idx_ubicacioneshistorial_fts ON ubicaciones_historial USING GIN (fts_ubicacioneshistorial_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_tiposplanespago_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_tiposplanespago_fts ON tipos_planes_pago USING GIN (fts_tiposplanespago_vector) WHERE fecha_baja IS NULL;

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
    fts_planespagos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
	CONSTRAINT fk_planespagos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT chk_planespagos_estadopagoid CHECK (estado_pago_id IN (2550, 2551, 2552, 2553, 2554, 2555)),
    CONSTRAINT chk_planespagos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_planespagos_numerocuota CHECK (numero_cuota > 0),
    CONSTRAINT chk_planespagos_montoprogramado CHECK (monto_programado >= 0),
    CONSTRAINT chk_planespagos_montopagado CHECK (monto_pagado >= 0),
    CONSTRAINT chk_planespagos_montocoherencia_coherencia CHECK (monto_pagado <= monto_programado),
    CONSTRAINT chk_planespagos_fechavencimiento CHECK (fecha_vencimiento > '2000-01-01'),
    CONSTRAINT chk_planespagos_fechapago CHECK (fecha_pago IS NULL OR fecha_pago > '2000-01-01')
);
CREATE UNIQUE INDEX uix_planespagos_varios_unique ON planes_pagos (kardex_id, numero_cuota) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planespagos_kardex ON planes_pagos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planespagos_fechavencimiento ON planes_pagos (fecha_vencimiento) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planespagos_fts ON planes_pagos USING GIN (fts_planespagos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE planes_pagos IS 'Reglas de la tabla - planes_pagos
R.0: La tabla planes_pagos gestiona el calendario de vencimientos para las compras a crédito a proveedores, registrando las cuotas programadas y su estado de pago. Su propósito es administrar la deuda con los proveedores, facilitando la planificación financiera y el control de los pasivos, permitiendo registrar abonos parciales y ajustar automáticamente el estado de las cuotas.
R.1: Control de Ciclo de Vida y Cierre. estado_pago_id califica de manera estricta el avance transaccional de la cuota. Pasará automáticamente a 2552 (PAGADO) o 2553 (CERRADO) cuando el monto_pagado iguale al monto_programado (saldo igual a 0.00). El frontend inhabilitará de forma inmediata la edición o inserción de nuevos abonos sobre registros cuyo estado_pago_id sea distinto de 2550 (PENDIENTE) o 2551 (PARCIAL) para proteger la integridad contable.
R.2: Diferenciación de Capas. estado_id regula únicamente el borrado lógico y el comportamiento histórico en el sistema general (''ACTIVO'', ''BORRADO'', ''HISTORICO'', ''ANULADO''), operando de forma independiente a los procesos de liquidación comercial controlados por estado_pago_id.
R.3: Los planes de pago solo pueden ser creados para transacciones de compra a proveedores (evento_id = 1050 ''COMPRA'' en la tabla kardex). El sistema bloquea la creación de planes de pago para cualquier otro evento, incluyendo VENTA (evento_id = 1051).
R.4: Registro Inicial Comodín. El registro con plan_pago_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO) y estado_pago_id = 2553 (CERRADO). Sirve como valor predeterminado para las FK que requieran un plan de pago de referencia.
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
    fts_comprobantespagos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo_transaccion, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(titular_cuenta, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(autorizacion_nro, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cuenta_destino, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(comprobante_digital_ruta, '')), 'D')
    ) STORED,
    CONSTRAINT fk_comprobantespagos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_comprobantespagos_banco_id FOREIGN KEY (banco_id) REFERENCES bancos(banco_id),
    CONSTRAINT chk_comprobantespagos_tipopagoid CHECK (tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406)),
    CONSTRAINT chk_comprobantespagos_tipomonedaid CHECK (tipo_moneda_id IN (2300, 2301, 2302, 2303)),
    CONSTRAINT chk_comprobantespagos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_comprobantespagos_confirmado CHECK (confirmado IN (0, 1)),
    CONSTRAINT chk_comprobantespagos_monto CHECK (monto > 0.00),
    CONSTRAINT chk_comprobantespagos_codigotransaccion CHECK (LENGTH(TRIM(codigo_transaccion)) >= 2),
    CONSTRAINT chk_comprobantespagos_titularcuenta CHECK (TRIM(titular_cuenta) <> ''),
    CONSTRAINT chk_comprobantespagos_autorizacionnro CHECK (autorizacion_nro IS NULL OR TRIM(autorizacion_nro) <> ''),
    CONSTRAINT chk_comprobantespagos_cuentadestino CHECK (cuenta_destino IS NULL OR TRIM(cuenta_destino) <> ''),
    CONSTRAINT chk_comprobantespagos_comprobantedigital CHECK (comprobante_digital_ruta IS NULL OR TRIM(comprobante_digital_ruta) <> '')
);
CREATE UNIQUE INDEX uix_comprobantespagos_varios_unique ON comprobantes_pagos (banco_id, codigo_transaccion) WHERE estado_id IN (1000, 1002) AND codigo_transaccion <> 'SN';
CREATE INDEX idx_comprobantespagos_kardexid ON comprobantes_pagos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_comprobantespagos_tipopagoid ON comprobantes_pagos (tipo_pago_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_comprobantespagos_fechapago ON comprobantes_pagos (fecha_pago DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_comprobantespagos_fts ON comprobantes_pagos USING GIN (fts_comprobantespagos_vector) WHERE fecha_baja IS NULL;

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
    fts_pagos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(referencia, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(comprobante, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'C')
    ) STORED,
	CONSTRAINT fk_pagos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_pagos_plan_pago_id FOREIGN KEY (plan_pago_id) REFERENCES planes_pagos(plan_pago_id),
    CONSTRAINT fk_pagos_comprobante_pago_id FOREIGN KEY (comprobante_pago_id) REFERENCES comprobantes_pagos(comprobante_pago_id),
    CONSTRAINT fk_pagos_proveedor_id FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
    CONSTRAINT chk_pagos_tipopagoid CHECK (tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406)),
    CONSTRAINT chk_pagos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_pagos_monto CHECK (monto > 0),
    CONSTRAINT chk_pagos_fechapago CHECK (fecha_pago > '2000-01-01')
);
CREATE INDEX idx_pagos_kardexid ON pagos (kardex_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pagos_planpagoid ON pagos (plan_pago_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pagos_fechapago ON pagos (fecha_pago) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pagos_fts ON pagos USING GIN (fts_pagos_vector) WHERE fecha_baja IS NULL;

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
    apertura_usuario_id BIGINT NOT NULL,
    cierre_usuario_id BIGINT NULL,
    autorizacion_usuario_id BIGINT NULL,
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
    fts_cajas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'A')
    ) STORED,
    CONSTRAINT fk_cajas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cajas_apertura_usuario_id FOREIGN KEY (apertura_usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_cajas_cierre_usuario_id FOREIGN KEY (cierre_usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_cajas_autorizacion_usuario_id FOREIGN KEY (autorizacion_usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_cajas_estadocajaid CHECK (estado_caja_id IN (2650, 2651)),
    CONSTRAINT chk_cajas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE INDEX idx_cajas_sucursalid_estadocajaid ON cajas (sucursal_id, estado_caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cajas_fechaapertura ON cajas (fecha_apertura DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cajas_aperturausuarioid ON cajas (apertura_usuario_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cajas_varios ON cajas (estado_caja_id, fecha_apertura DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cajas_fts ON cajas USING GIN (fts_cajas_vector) WHERE fecha_baja IS NULL;

DELETE FROM cajas;
ALTER SEQUENCE cajas_caja_id_seq RESTART WITH 1;

INSERT INTO cajas (caja_id, sucursal_id, apertura_usuario_id, cierre_usuario_id, autorizacion_usuario_id, fecha_apertura, fecha_cierre, fecha_autorizacion, monto_inicial, monto_ingresos, monto_egresos, monto_ventas, monto_final_esperado, monto_final_real, diferencia, total_transacciones, total_ventas, total_devoluciones, total_retiros, estado_caja_id, observaciones, estado_id, usuario_id_registro) VALUES
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
    fts_movimientos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(motivo, '')), 'A')
    ) STORED,
	CONSTRAINT fk_movimientos_caja_id FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT fk_movimientos_usuario_id FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_movimientos_tipomovimientoid CHECK (tipo_movimiento_id IN (2600, 2601)),
    CONSTRAINT chk_movimientos_tipopagoid CHECK (tipo_pago_id IS NULL OR tipo_pago_id IN (1400, 1401, 1402, 1403, 1404, 1405, 1406)),
    CONSTRAINT chk_movimientos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_movimientos_monto CHECK (monto > 0.00),
    CONSTRAINT chk_movimientos_saldoantes CHECK (saldo_antes >= 0.00),
    CONSTRAINT chk_movimientos_saldodespues CHECK (saldo_despues >= 0.00),
    CONSTRAINT chk_movimientos_motivo_minlength CHECK (LENGTH(TRIM(motivo)) >= 3)
);
CREATE INDEX idx_movimientos_cajaid ON movimientos (caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_fechamovimiento ON movimientos (fecha_movimiento DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_tipomovimientoid_cajaid ON movimientos (tipo_movimiento_id, caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_usuarioid ON movimientos (usuario_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_referenciaid ON movimientos (referencia_id) WHERE referencia_id IS NOT NULL AND estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_fecharegistro ON movimientos (fecha_registro DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_tipopagoid ON movimientos (tipo_pago_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_movimientos_fts ON movimientos USING GIN (fts_movimientos_vector) WHERE fecha_baja IS NULL;

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
	CONSTRAINT fk_arqueosdetalle_caja_id FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT chk_arqueosdetalle_tipobilleteid CHECK (tipo_billete_id IN (4300, 4301, 4302, 4303, 4304, 4305, 4306, 4307, 4308, 4309, 4310, 4311, 4312, 4313, 4314, 4315)),
    CONSTRAINT chk_arqueosdetalle_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_arqueosdetalle_cantidad CHECK (cantidad >= 0),
    CONSTRAINT chk_arqueosdetalle_subtotal CHECK (subtotal >= 0)
);
CREATE INDEX idx_arqueosdetalle_cajaid ON arqueos_detalle (caja_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_arqueosdetalle_tipobilleteid ON arqueos_detalle (tipo_billete_id) WHERE estado_id IN (1000, 1002);

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_alertasnotificaciones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(titulo, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(mensaje, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(comentarios_resolucion, '')), 'D') ||
        setweight(to_tsvector('simple', COALESCE(accion_tomada, '')), 'D')
    ) STORED,
	CONSTRAINT fk_alertasnotificaciones_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_alertasnotificaciones_usuario_asignado_id FOREIGN KEY (usuario_asignado_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_alertasnotificaciones_usuario_resolutor_id FOREIGN KEY (usuario_resolutor_id) REFERENCES usuarios(usuario_id),
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
    CONSTRAINT chk_alertasnotificaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_alertasnotificaciones_esleido CHECK (es_leido IN (0, 1))
);
CREATE UNIQUE INDEX uix_alertasnotificaciones_codigo_unique ON alertas_notificaciones (codigo) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_fecharegistro ON alertas_notificaciones (fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_varios ON alertas_notificaciones (entidad_afectada_tipo_id, entidad_afectada_id) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_bandeja_consulta ON alertas_notificaciones (sucursal_id, estado_alerta_id, fecha_registro DESC) WHERE estado_id = 1000;
CREATE INDEX idx_alertasnotificaciones_fts ON alertas_notificaciones USING GIN (fts_alertasnotificaciones_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE alertas_notificaciones IS 'Reglas de la tabla - alertas_notificaciones
R.0: La tabla alertas_notificaciones es el centro de gestión de eventos y avisos del sistema, consolidando tanto las notificaciones operativas (stock bajo, vencimientos) como las generadas por los modelos de IA (pronósticos, anomalías). Su propósito es unificar la bandeja de entrada del usuario, proporcionando un registro auditado de eventos críticos, su nivel de urgencia, asignación y resolución, lo que permite una gestión proactiva de la farmacia.
R.1: Unificación de Eventos y Bandeja de Entrada. Esta entidad consolida tanto el registro técnico de la anomalía o predicción generada por el sistema/IA como el estado de interacción del operador asignado en una sola estructura unificada, controlando la visibilidad del mensaje en la UI a través del campo es_leido. Donde el campo es_leido está definido en la tabla como un INTEGER NOT NULL DEFAULT 0 (donde 0 = No leído y 1 = Leído).
R.2: Metadatos Flexibles con JSONB y Estructura por Defecto. El campo metadata almacena toda la información contextual específica del tipo de alerta (como modelos de IA, parámetros de automatización, resultados de acciones, etc.). Este campo es de uso obligatorio a nivel de esquema con la restricción NOT NULL DEFAULT ''{}''::jsonb, garantizando que la aplicación nunca reciba ni almacene valores nulos (NULL), facilitando el consumo directo de propiedades en el backend sin necesidad de evaluar nulos en el objeto.
R.3: Control Dual de Estados Operacionales. estado_alerta_id rige el ciclo de vida de resolución técnica del evento (2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA). estado_id controla la persistencia lógica en el repositorio de datos (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO).
R.4: Gestión de Lectura y Auditoría Temporal. Al interactuar el usuario con la interfaz, la aplicación debe actualizar es_leido = TRUE y registrar la marca de tiempo exacta en fecha_lectura.
R.5: Registro Inicial Comodín. El registro con alerta_notificacion_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran una alerta de referencia.
R.6: Niveles de Prioridad. prioridad_resolucion es un valor entre 1 y 5 donde 1 es la máxima prioridad y 5 la mínima. El frontend debe ordenar las alertas según este campo para guiar la atención del operador.
R.7: Estructura Estándar de Automatización en Metadata. Cuando la alerta involucre procesos automáticos, la información correspondiente debe almacenarse dentro del JSONB utilizando la siguiente estructura base acordada:
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
    codigo VARCHAR(60) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_modelo_id INTEGER NOT NULL DEFAULT 1456,  		-- 1450=ARIMA, 1451=SARIMA, 1452=SERIES_TEMPORALES, 1453=CLASIFICACION, 1454=OPTIMIZACION, 1455=DETECCION_ANOMALIAS, 1456=NINGUNO
	framework_version VARCHAR(20) DEFAULT '0.0.0',
    descripcion VARCHAR(3000) NULL,
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
    fts_modelos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_modelos_fts ON modelos USING GIN (fts_modelos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE modelos IS 'Reglas de la tabla - modelos
R.0: La tabla modelos es el catálogo de todos los algoritmos de inteligencia artificial y aprendizaje automático disponibles en el sistema, definiendo sus parámetros de configuración y estado. Su propósito es gestionar el ciclo de vida de los modelos (activo, en entrenamiento, obsoleto), permitiendo la estandarización y el versionado de las técnicas predictivas.
R.1: Control del Ciclo de Vida. estado_id gestiona la vigencia y disponibilidad técnica del modelo en el sistema de predicción, garantizando la inmutabilidad y persistencia de configuraciones históricas.
R.2: Estructura de Hiperparámetros. parametros_default almacena la configuración base en formato JSONB para la inicialización y el entrenamiento de los algoritmos, evitando la fragmentación en múltiples tablas relacionales de variables técnicas.
R.3: Identificador Único de Modelo. codigo es un campo alfanumérico único en mayúsculas que identifica al modelo de forma abreviada. Debe tener al menos 3 caracteres y ser ingresado manualmente por el administrador del sistema.
R.4: Registro Inicial Comodín. El registro con modelo_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un modelo de referencia.
R.5: Tipos de Modelo. tipo_modelo_id utiliza los valores (1450-1455): ARIMA (1450), SARIMA (1451), SERIES_TEMPORALES (1452), CLASIFICACION (1453), OPTIMIZACION (1454), DETECCION_ANOMALIAS (1455).
R.6: Frameworks. framework_id utiliza los valores (3000-3003): statsmodels (3000), scikit-learn (3001), tensorflow (3002), custom (3003).
R.7: Estado Operativo del Modelo. estado_modelo_id utiliza los valores (2000-2004): SIN_DATOS (2000) cuando no hay suficientes datos históricos para entrenar, ENTRENANDO (2001) cuando el motor Python está calculando parámetros, ACTIVO (2002) cuando el modelo está entrenado y generando predicciones, RECHAZADO (2003) cuando el MAPE supera el umbral permitido, OBSOLETO (2004) cuando ha sido reemplazado por una versión más reciente. Este campo es independiente de estado_id y refleja el estado funcional del modelo.';

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
    fts_entrenamientos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(mensaje_error, '')), 'A')
    ) STORED,
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
CREATE INDEX idx_entrenamientos_fts ON entrenamientos USING GIN (fts_entrenamientos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE entrenamientos IS 'Reglas de la tabla - entrenamientos
R.0: La tabla entrenamientos registra la ejecución histórica de los procesos de entrenamiento de los modelos de IA, almacenando su fecha, duración y estado. Su propósito es proveer trazabilidad sobre el rendimiento y la ejecución de los modelos, permitiendo auditar el proceso de aprendizaje y vincularlo a las métricas de precisión resultantes.
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
    CONSTRAINT fk_metricasrendimiento_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT chk_metricasrendimiento_tipometricasid CHECK (tipo_metricas_id IN (3100, 3101, 3102, 3103)),
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
CREATE INDEX idx_metricasrendimiento_tipometricasid ON metricas_rendimiento (tipo_metricas_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_metricasrendimiento_fechaevaluacion ON metricas_rendimiento (fecha_evaluacion DESC) WHERE estado_id IN (1000, 1002);

COMMENT ON TABLE metricas_rendimiento IS 'Reglas de la tabla - metricas_rendimiento
R.0: La tabla metricas_rendimiento cuantifica la precisión de los modelos de IA, almacenando indicadores clave como MAPE, RMSE, R2 y otras métricas de error. Su propósito es evaluar objetivamente el desempeño de los modelos predictivos, permitiendo la comparación entre diferentes algoritmos y versiones para elegir el mejor modelo para producción.
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
    fts_patronesconsumo_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(evento, '')), 'A')
    ) STORED,
    CONSTRAINT fk_patronesconsumo_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_patronesconsumo_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_patronesconsumo_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT chk_patronesconsumo_temporadaid CHECK (temporada_id IS NULL OR temporada_id IN (1600, 1601, 1602, 1603)),
    CONSTRAINT chk_patronesconsumo_tipopatronid CHECK (tipo_patron_id IN (4200)),
    CONSTRAINT chk_patronesconsumo_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_patronesconsumo_evento_minlength CHECK (evento IS NULL OR LENGTH(TRIM(evento)) >= 3),
    CONSTRAINT chk_patronesconsumo_fechas CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_inicio <= fecha_fin)
);
CREATE UNIQUE INDEX uix_patronesconsumo_varios_unique ON patrones_consumo (producto_id, sucursal_id, entrenamiento_id, tipo_patron_id, fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_patronesconsumo_productoid ON patrones_consumo (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_patronesconsumo_sucursalid ON patrones_consumo (sucursal_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_patronesconsumo_temporadaid ON patrones_consumo (temporada_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_patronesconsumo_fts ON patrones_consumo USING GIN (fts_patronesconsumo_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE patrones_consumo IS 'Reglas de la tabla - patrones_consumo
R.0: La tabla patrones_consumo almacena los factores estacionales y de tendencia identificados para un producto en una sucursal específica, como resultado de un entrenamiento de IA. Su propósito es capturar el comportamiento cíclico de la demanda, ajustando las predicciones futuras y los puntos de reorden para adaptarse a la realidad de cada mercado local.
R.1: Control de Elasticidad Comercial. factor_estacional y coeficiente_tendencia gestionan las fluctuaciones estacionales de la demanda, resguardando las variaciones cíclicas del mercado boliviano (ej. Feriado de San Juan o Todos Santos) de forma acumulativa y perenne.
R.2: Unicidad de Factores Multiplicadores. Para prevenir distorsiones en las proyecciones de inventario, la restricción uix_pat_producto_sucursal_entrenamiento restringe la existencia de más de un factor multiplicador activo para la misma combinación de artículo, punto de venta y ejecución analítica.
R.3: Registro Inicial Comodín. El registro con patron_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un patrón de consumo de referencia.
R.4: Clasificación Estacional. temporada_id utiliza los valores (1600-1603): NINGUNA (1600) para patrones sin estacionalidad definida, ALTA (1601) para temporada de demanda alta, MEDIA (1602) para demanda regular, BAJA (1603) para demanda baja.
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
    fts_variablesexogenas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(nombre_variable, '')), 'A')
    ) STORED,
	CONSTRAINT fk_variablesexogenas_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_variablesexogenas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT chk_variablesexogenas_fuenteexogenaid CHECK (fuente_exogena_id IN (4250, 4251, 4252, 4253, 4254, 4255)),
    CONSTRAINT chk_variablesexogenas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_variablesexogenas_nombrevariable_minlength CHECK (LENGTH(TRIM(nombre_variable)) >= 3)
);
CREATE UNIQUE INDEX uix_variablesexogenas_varios_unique ON variables_exogenas (sucursal_id, producto_id, fecha_variable, nombre_variable) WHERE estado_id IN (1000, 1002) AND producto_id != 1;
CREATE INDEX idx_variablesexogenas_varios ON variables_exogenas (sucursal_id, fecha_variable DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_variablesexogenas_fechavariable ON variables_exogenas (fecha_variable DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_variablesexogenas_fts ON variables_exogenas USING GIN (fts_variablesexogenas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE variables_exogenas IS 'Reglas de la tabla - variables_exogenas
R.0: La tabla variables_exogenas almacena datos externos que influyen en la demanda de productos, como temperatura, precios de moneda o días festivos. Su propósito es enriquecer los modelos de pronóstico (como SARIMAX) con factores causales que mejoran significativamente la precisión de las predicciones de demanda.
R.1: Control Coherente de Factores Externos. El registro continuo de indicadores macroeconómicos, climáticos o ambientales se asocia de forma inalterable a estado_id para salvaguardar el histórico multivariable, alimentando el motor de predicción sin particionamiento físico por periodos anuales.
R.2: Registro Inicial Comodín. El registro con variable_exogena_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran una variable exógena de referencia.
R.3: Unicidad de Variables por Período. La restricción uix_veg_sucursal_producto_fecha_variable garantiza que no existan duplicados de la misma variable para la misma combinación de sucursal, producto y fecha.
R.4: Control de Fechas. fecha_variable registra la fecha a la que corresponde el valor de la variable. El backend debe validar que fecha_variable <= CURRENT_DATE para variables históricas.
R.5: Ejemplos de Variables Exógenas. nombre_variable puede contener valores como "Temperatura Promedio C", "Precio Dolar", "Inflacion", "Festivo", etc.
R.6: Control de Estados. estado_id gestiona el ciclo de vida del registro en el sistema (ACTIVO, BORRADO, HISTORICO).';

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
    mensaje VARCHAR(3000) NOT NULL,
    detalle JSONB NOT NULL DEFAULT '{}'::jsonb,
    fecha_log TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_id INTEGER NOT NULL DEFAULT 1000,            -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_logsejecucion_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(modulo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(mensaje, '')), 'B')
    ) STORED,
    CONSTRAINT fk_logsejecucion_entrenamiento_id FOREIGN KEY (entrenamiento_id) REFERENCES entrenamientos(entrenamiento_id),
    CONSTRAINT chk_logsejecucion_nivellogid CHECK (nivel_log_id IN (3150, 3151, 3152, 3153)),
    CONSTRAINT chk_logsejecucion_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_logsejecucion_modulo_minlength CHECK (LENGTH(TRIM(modulo)) >= 3)
);
CREATE INDEX idx_logsejecucion_entrenamientoid ON logs_ejecucion (entrenamiento_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_logsejecucion_nivellogid ON logs_ejecucion (nivel_log_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_logsejecucion_varios ON logs_ejecucion (modulo, nivel_log_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_logsejecucion_fts ON logs_ejecucion USING GIN (fts_logsejecucion_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE logs_ejecucion IS 'Reglas de la tabla - logs_ejecucion
R.0: La tabla logs_ejecucion es la bitácora técnica que almacena los eventos, advertencias y errores generados durante los procesos del sistema, especialmente durante los entrenamientos de IA. Su propósito es proveer un registro detallado para la depuración, el monitoreo de la salud del sistema y la trazabilidad de los procesos batch y analíticos.
R.1: Control Continuo de Trazabilidad. El almacenamiento cronológico de la bitácora operativa y las excepciones del motor analítico se administra centralizadamente mediante estado_id, asegurando la preservación persistente del histórico técnico sin segmentación de esquemas anuales.
R.2: Estructura No Estricta de Depuración. detalle en formato JSONB resguarda de forma dinámica el contexto técnico extendido (ej. pilas de ejecución o variables internas del modelo), operando de manera desacoplada sin imponer validaciones rígidas estructurales a nivel de motor de base de datos, inicializándose por defecto como objeto vacío.
R.3: Registro Inicial Comodín. El registro con log_id = 1 es un registro histórico con estado_id = 1002 (HISTORICO). Sirve como valor predeterminado para las FK que requieran un log de ejecución de referencia.
R.4: Niveles de Log. nivel_log_id utiliza los valores (3150-3153): INFO (3150) para información general, WARNING (3151) para advertencias, ERROR (3152) para errores, DEBUG (3153) para depuración.
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

DELETE FROM analitica_productos;
ALTER SEQUENCE analitica_productos_analitica_id_seq RESTART WITH 1;

INSERT INTO analitica_productos (analitica_id, producto_id, sucursal_id, demanda_pronosticada, intervalo_inf, intervalo_sup, fecha_prediccion, periodo_inicio, periodo_fin, fecha_vencimiento_critico, nivel_urgencia_id, punto_reorden, stock_seguridad, lead_time_dias, cluster_abc, fecha_clasificacion, puntaje_total, estado_pronostico_id, motivo_outlier_id, estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja) VALUES
(1, 1, 1, 120.50, 100.00, 140.00, CURRENT_TIMESTAMP, '2026-08-01', '2026-08-31', '2027-01-15', 1854, 45.00, 15.00, 5, 0, CURRENT_DATE, 85.50, 1553, NULL, 1000, 1, NULL, NULL, CURRENT_TIMESTAMP, NULL, NULL);

UPDATE analitica_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE analitica_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('analitica_productos_analitica_id_seq', COALESCE((SELECT MAX(analitica_id) FROM analitica_productos), 1));

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
    fts_pedidosonline_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(direccion_entrega, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(telefono_contacto, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(instrucciones_entrega, '')), 'C')
    ) STORED,
	CONSTRAINT fk_pedidosonline_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_pedidosonline_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_pedidosonline_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_pedidosonline_repartidor_id FOREIGN KEY (repartidor_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_pedidosonline_estadopedidoonlineid CHECK (estado_pedido_online_id IN (3700, 3701, 3702, 3703, 3704, 3705, 3706)),
    CONSTRAINT chk_pedidosonline_estadopagoid CHECK (estado_pago_id IN (2550, 2551, 2552, 2553, 2554, 2555)),
    CONSTRAINT chk_pedidosonline_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_pedidosonline_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_pedidosonline_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_pedidosonline_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_pedidosonline_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_pedidosonline_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_pedidosonline_costoenvio CHECK (costo_envio >= 0),
    CONSTRAINT chk_pedidosonline_descuentos CHECK (descuentos >= 0),
    CONSTRAINT chk_pedidosonline_total CHECK (total >= 0)
);
CREATE UNIQUE INDEX uix_pedidosonline_codigo_unique ON pedidos_online (codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pedidosonline_clienteid ON pedidos_online (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pedidosonline_estadopedidoonlineid ON pedidos_online (estado_pedido_online_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_pedidosonline_fts ON pedidos_online USING GIN (fts_pedidosonline_vector) WHERE fecha_baja IS NULL;

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
    codigo_producto VARCHAR(60) NOT NULL,
    nombre_producto VARCHAR(600) NOT NULL,
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
    fts_detallespedidosonline_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo_producto, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre_producto, '')), 'B')
    ) STORED,
	CONSTRAINT fk_detallespedidosonline_pedido_online_id FOREIGN KEY (pedido_online_id) REFERENCES pedidos_online(pedido_online_id),
    CONSTRAINT fk_detallespedidosonline_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT fk_detallespedidosonline_kardex_producto_id FOREIGN KEY (kardex_producto_id) REFERENCES kardex_productos(kardex_producto_id),
    CONSTRAINT chk_detallespedidosonline_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE INDEX idx_detallespedidosonline_pedidoonlineid ON detalles_pedidos_online (pedido_online_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_detallespedidosonline_productoid ON detalles_pedidos_online (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_detallespedidosonline_fts ON detalles_pedidos_online USING GIN (fts_detallespedidosonline_vector) WHERE fecha_baja IS NULL;

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
    fts_carritoscompra_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(cliente_nombre, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(cliente_documento, '')), 'B')
    ) STORED,
	CONSTRAINT fk_carritoscompra_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT chk_carritoscompra_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_carritoscompra_clientenombre_notempty CHECK (TRIM(cliente_nombre) <> ''),
    CONSTRAINT chk_carritoscompra_clientenombre_minlength CHECK (LENGTH(TRIM(cliente_nombre)) >= 3),
    CONSTRAINT chk_carritoscompra_clientedocumento_notempty CHECK (TRIM(cliente_documento) <> ''),
    CONSTRAINT chk_carritoscompra_clientedocumento_formato CHECK (cliente_documento ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_carritoscompra_totalitems CHECK (total_items >= 0),
    CONSTRAINT chk_carritoscompra_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_carritoscompra_fechaexpiracion CHECK (fecha_expiracion > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_carritoscompra_clienteid_unique ON carritos_compra (cliente_id) WHERE estado_id = 1000;
CREATE INDEX idx_carritoscompra_clienteid ON carritos_compra (cliente_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_carritoscompra_fechaexpiracion ON carritos_compra (fecha_expiracion) WHERE estado_id = 1000;
CREATE INDEX idx_carritoscompra_fts ON carritos_compra USING GIN (fts_carritoscompra_vector) WHERE fecha_baja IS NULL;

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
    codigo_producto VARCHAR(60) NOT NULL,
    nombre_producto VARCHAR(600) NOT NULL,
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
    fts_detallescarritos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo_producto, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre_producto, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(presentacion_producto, '')), 'C')
    ) STORED,
	CONSTRAINT fk_detallescarritos_carrito_id FOREIGN KEY (carrito_id) REFERENCES carritos_compra(carrito_id),
    CONSTRAINT fk_detallescarritos_producto_id FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT chk_detallescarritos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE INDEX idx_detallescarritos_carritoid ON detalles_carritos (carrito_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_detallescarritos_productoid ON detalles_carritos (producto_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_detallescarritos_fts ON detalles_carritos USING GIN (fts_detallescarritos_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_listasprecios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(descripcion, '')), 'C')
    ) STORED,
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
CREATE INDEX idx_listasprecios_fts ON listas_precios USING GIN (fts_listasprecios_vector) WHERE fecha_baja IS NULL;

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
    codigo VARCHAR(60) NOT NULL,
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
    fts_politicasprecios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE(codigo, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(nombre, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_politicasprecios_fts ON politicas_precios USING GIN (fts_politicasprecios_vector) WHERE fecha_baja IS NULL;

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
    fts_asistencias_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(dispositivo, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(ip_origen, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(justificacion, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(justificacion_archivo, '')), 'C')
    ) STORED,
    CONSTRAINT fk_asistencias_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_asistencias_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_asistencias_usuario_registro_id FOREIGN KEY (usuario_registro_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_asistencias_tipoasistenciaid CHECK (tipo_asistencia_id IN (4400, 4401, 4402, 4403)),
    CONSTRAINT chk_asistencias_estadoasistenciaid CHECK (estado_asistencia_id IN (4450, 4451, 4452, 4453)),
    CONSTRAINT chk_asistencias_metodomarcacionid CHECK (metodo_marcacion_id IN (4500, 4501, 4502, 4503)),
    CONSTRAINT chk_asistencias_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE INDEX idx_asistencias_fecha ON asistencias (fecha DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_asistencias_trabajadorid ON asistencias (trabajador_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_asistencias_estadoasistenciaid ON asistencias (estado_asistencia_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_asistencias_fts ON asistencias USING GIN (fts_asistencias_vector) WHERE fecha_baja IS NULL;

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
    fts_planillas_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'B')
    ) STORED,
    CONSTRAINT fk_planillas_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_planillas_usuario_aprobacion_id FOREIGN KEY (usuario_aprobacion_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_planillas_usuario_pago_id FOREIGN KEY (usuario_pago_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_planillas_tipoplanillaid CHECK (tipo_planilla_id IN (4600, 4601, 4602)),
    CONSTRAINT chk_planillas_estadoplanillaid CHECK (estado_planilla_id IN (4650, 4651, 4652, 4653, 4654)),
    CONSTRAINT chk_planillas_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE INDEX idx_planillas_fechacalculo ON planillas (fecha_calculo DESC) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planillas_estadoplanillaid ON planillas (estado_planilla_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planillas_periodos ON planillas (periodo_gestion, periodo_mes) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planillas_fts ON planillas USING GIN (fts_planillas_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE planillas IS 'Reglas de la tabla - planillas
R.0: La tabla planillas es la cabecera de los procesos de liquidación de sueldos y salarios, agrupando los pagos a los trabajadores por período. Su propósito es centralizar el cálculo y la gestión de las planillas mensuales, permitiendo la auditoría y el control financiero de la nómina.
R.1: Unicidad por Período. Solo puede existir una planilla por mes y gestión en cada sucursal en estado ACTIVO (no ANULADA). El índice uix_pla_sucursal_mes_gestion garantiza esta unicidad.
R.2: Ciclo de Vida de la Planilla. estado_planilla_id utiliza los valores (4650-4654): BORRADOR (inicial, editable), CALCULADA (valores calculados, pendiente de aprobación), APROBADA (aprobada por gerencia), PAGADA (pagada a los trabajadores), ANULADA (cancelada, irreversible).
R.3: Transiciones de Estado. Las transiciones de estado deben ser secuenciales: BORRADOR -> CALCULADA -> APROBADA -> PAGADA. No se permiten saltos de estado. ANULADA solo puede ser aplicada desde BORRADOR o CALCULADA.
R.4: Cálculo Automático de Totales. Los campos total_bruto, total_descuentos, total_neto, total_aportes_empresa y total_aportes_trabajador se calculan automáticamente al pasar de BORRADOR a CALCULADA. El backend debe recalcular estos valores sumando los registros de planillas_detalle.
R.5: Fechas de Corte. fecha_inicio y fecha_fin definen el período de la planilla. Generalmente, fecha_inicio = primer día del mes y fecha_fin = último día del mes. El backend debe validar que la planilla no se solape con otras planillas en la misma sucursal.
R.6: Autorización y Pago. Los campos usuario_aprobacion_id, usuario_pago_id, fecha_aprobacion y fecha_pago se actualizan automáticamente cuando la planilla cambia de estado a APROBADA o PAGADA.
R.7: Tipos de Planilla. tipo_planilla_id utiliza los valores (4600-4602): SUELDOS (mensual), JORNALES (diario/semanal), CONTRATO (por proyecto). Afecta el cálculo de conceptos y la periodicidad.
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
    fts_planillasdetalle_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'B')
    ) STORED,
    CONSTRAINT fk_planillasdetalle_planilla_id FOREIGN KEY (planilla_id) REFERENCES planillas(planilla_id),
    CONSTRAINT fk_planillasdetalle_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_planillasdetalle_cargo_id FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id),
    CONSTRAINT chk_planillasdetalle_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
    ),
    CONSTRAINT chk_planillasdetalle_coherencia CHECK (
        neto_pagar = (sueldo_base + total_horas_extras + bonificaciones + comisiones) -
        (descuentos_legales + descuentos_extra)
    )
);
CREATE UNIQUE INDEX uix_planillasdetalle_varios_unique ON planillas_detalle (planilla_id, trabajador_id) WHERE estado_id = 1000;
CREATE INDEX idx_planillasdetalle_trabajadorid ON planillas_detalle (trabajador_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planillasdetalle_planillaid ON planillas_detalle (planilla_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_planillasdetalle_fts ON planillas_detalle USING GIN (fts_planillasdetalle_vector) WHERE fecha_baja IS NULL;

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
    fts_contratos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(observaciones, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(documento_contrato, '')), 'C')
    ) STORED,
	CONSTRAINT fk_contratos_trabajador_id FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_contratos_usuario_firma_id FOREIGN KEY (usuario_firma_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_contratos_tipocontratoid CHECK (tipo_contrato_id IN (4750, 4751, 4752, 4753, 4754)),
    CONSTRAINT chk_contratos_monedasueldoid CHECK (moneda_sueldo_id IN (2300, 2301, 2302)),
    CONSTRAINT chk_contratos_tipojornadaid CHECK (tipo_jornada_id IN (4800, 4801, 4802)),
    CONSTRAINT chk_contratos_estadocontratoid CHECK (estado_contrato_id IN (4700, 4701, 4702, 4703)),
    CONSTRAINT chk_contratos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_contratos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_contratos_observaciones_minlength CHECK (observaciones IS NULL OR LENGTH(TRIM(observaciones)) >= 3),
    CONSTRAINT chk_contratos_documentocontrato_notempty CHECK (documento_contrato IS NULL OR TRIM(documento_contrato) <> ''),
    CONSTRAINT chk_contratos_documentocontrato_minlength CHECK (documento_contrato IS NULL OR LENGTH(TRIM(documento_contrato)) >= 3),
    CONSTRAINT chk_contratos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT chk_contratos_sueldobase CHECK (sueldo_base >= 0),
    CONSTRAINT chk_contratos_horassemanales CHECK (horas_semanales > 0)
);
CREATE UNIQUE INDEX uix_contratos_trabajadorid_unique ON contratos (trabajador_id) WHERE estado_contrato_id = 4750 AND estado_id = 1000;
CREATE INDEX idx_contratos_trabajadorid ON contratos (trabajador_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_contratos_fechas ON contratos (fecha_inicio, fecha_fin) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_contratos_estadocontratoid ON contratos (estado_contrato_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_contratos_fts ON contratos USING GIN (fts_contratos_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE contratos IS 'Reglas de la tabla - contratos
R.0: La tabla contratos gestiona el histórico de contratos laborales de los trabajadores, permitiendo controlar las fechas de vigencia, sueldos y condiciones de contratación. Su propósito es mantener un registro completo de la relación laboral para auditoría, cálculo de antigüedad y gestión de beneficios.
R.1: Unicidad de Contrato Vigente. Solo puede existir un contrato activo por trabajador (estado_contrato_id = 4700). El índice uix_con_trabajador_vigente garantiza esta unicidad.
R.2: Renovaciones Automáticas. Al renovar un contrato, el contrato anterior debe pasar a estado FINALIZADO (4701) y se crea uno nuevo con estado VIGENTE (4700). El backend debe gestionar esta transición.
R.3: Control de Fechas. fecha_inicio es obligatoria. fecha_fin puede ser NULL para contratos indefinidos o que aún no tienen fecha de término.
R.4: Gestión de Documentos. documento_contrato almacena la ruta del archivo PDF del contrato firmado. Sigue la regla R.G.8 para nomenclatura de archivos.
R.5: Tipos de Contrato. tipo_contrato_id utiliza los valores (4750-4754): INDEFINIDO, FIJO, EVENTUAL, PRACTICAS, CONSULTORIA. Afecta el cálculo de beneficios y la normativa aplicable.
R.6: Registro Comodín. El sistema debe mantener un registro inicial con contrato_id = 1 que sirve como valor predeterminado para las FK que requieran un contrato de referencia.
R.7: Integración con Planillas. El sueldo_base del contrato vigente se utiliza como base para el cálculo de la planilla mensual. Si el trabajador tiene un contrato con moneda diferente, el backend debe aplicar el tipo de cambio vigente.
R.8: Notificación de Vencimiento. Cuando un contrato con fecha_fin definida está a 30 días de vencer, el sistema debe generar una alerta de tipo VENCIMIENTO_CONTRATO (4553 / 2726) para notificar al supervisor.
R.9: Historial de Cambios. Cada cambio de estado o actualización del contrato debe registrar el evento en logs_ejecucion para trazabilidad completa.';

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
    empresa_codigo VARCHAR(30) NOT NULL,
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
	fts_historicos_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(cliente_nombre, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(cliente_documento, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cliente_documento_complemento, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cliente_tipo_documento_abreviatura, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(cliente_razon_social, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(cliente_direccion, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cliente_telefono, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(cliente_email, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(sucursal_nombre, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(sucursal_codigo, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(sucursal_telefono, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(sucursal_ubicacion, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(empresa_nombre, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(empresa_codigo, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(empresa_nit, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(empresa_autorizacion, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(empresa_actividad_economica, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(numero_factura, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(tipo_comprobante_abreviatura, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(tipo_factura_abreviatura, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(lugar_entrega, '')), 'C')
    ) STORED,
	CONSTRAINT fk_historicos_kardex_id FOREIGN KEY (kardex_id) REFERENCES kardex(kardex_id),
    CONSTRAINT fk_historicos_cliente_id FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_historicos_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_historicos_empresa_id FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    CONSTRAINT chk_historicos_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
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
CREATE INDEX idx_historicos_fts ON historicos USING GIN (fts_historicos_vector) WHERE fecha_baja IS NULL;

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
    fts_configuraciones_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', COALESCE(pie_pagina, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(logo_secundario, '')), 'C') ||
        setweight(to_tsvector('spanish', COALESCE(mensaje_agradecimiento, '')), 'B')
    ) STORED,
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
CREATE INDEX idx_configuraciones_fts ON configuraciones USING GIN (fts_configuraciones_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE configuraciones IS 'Reglas de la tabla - configuraciones
R.0: La tabla configuraciones almacena las preferencias de personalización de la interfaz de usuario para cada empresa, como el formato de los PDFs de facturación y los mensajes de agradecimiento. Su propósito es permitir la customización de la imagen corporativa y el formato de los documentos emitidos, mejorando la experiencia del cliente y la uniformidad de la marca.
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
 *   -- Consultar el login del último usuario que operó sobre el banco con ID 2
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
