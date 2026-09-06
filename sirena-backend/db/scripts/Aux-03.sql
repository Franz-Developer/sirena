como seria un prompt para que genere los archivos
C:\sirena\sirena-backend\src\modules\clientes\clientes.service.ts
C:\sirena\sirena-backend\src\modules\clientes\dto\find-clientes-query.dto.ts
C:\sirena\sirena-backend\src\modules\clientes\dto\cliente-response.dto.ts

EL PROMPT debe explicar primero que ANALIZA en produndidad el DDL y estados.constant.ts y unicidad-validador.service.ts

SE LE PASARA EL DDL DE LA TABLA 
LAS CONSTANTES 

se le pasara las tablas dependientes en este formato
------------------+-----------+-------------------+-----------
tabla_dependiente |columna_fk |tabla_referenciada |columna_pk 
------------------+-----------+-------------------+-----------
carritos_compra   |cliente_id |clientes           |cliente_id 
historicos        |cliente_id |clientes           |cliente_id 
kardex            |cliente_id |clientes           |cliente_id 
pedidos_online    |cliente_id |clientes           |cliente_id 
recetas           |cliente_id |clientes           |cliente_id 
------------------+-----------+-------------------+-----------

SE LE pasara todas las tablas que se requiere en cliente-response.dto.ts y find-clientes-query.dto.ts  En este formato.




Se le pasara el DDL y todos las constantes C:\sirena\sirena-backend\src\common\constants\estados.constant.ts
se le pasara el archivo completo C:\sirena\sirena-backend\src\common\validators\unicidad-validador.service.ts

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
