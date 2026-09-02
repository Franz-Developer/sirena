Protocolo General de Optimización y Depuración de Tablas SE USA PostgreSQL 15.13

NO INVENTARSE NINGUN CAMPO
Todo el código generado debe ir en las comillas invertidas de Markdown o backticks

-- CREATE TABLE
1. Todas las tablas deben tener estos campos
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
LOS campos en create tienen un comentario como -- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO se debe respetar
origen_moneda_id INTEGER NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
destino_moneda_id INTEGER NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
ESTOS COMENTARIOS SE DEBEN RESPETAR los comentarios en CREATE TABLE SE DEBE RESPETAR
2. Todas las columnas, según su naturaleza y dominio semántico, deben estar sujetas a restricciones CHECK que validen los valores permitidos, garantizando así la integridad de los datos a nivel de base de datos. Estas restricciones aplican sobre rangos numéricos, formatos de cadenas, valores de catálogo, o condiciones de consistencia entre columnas, y su definición debe ser documentada explícitamente en el diccionario de datos para asegurar trazabilidad y mantenibilidad del esquema.
3. No puede haber campos tipo CONSTRAINT chk_en_estado_fiscal CHECK (estado_fiscal IN ('ACTIVO', 'AGOTADO', 'VENCIDO', 'CANCELADO')), debe haber el campo estado_fiscal_id INTEGER NOT NULL DEFAULT XXX, y ese campo estado_fiscal_id debe ser fk a la tabla dominios
4. Debe haber control de UNIQUE para los campos que son unicos.
5. En la estructura CREATE TABLE no debe haber espacios vacios que dividan el CREATE TABLE, ni comentarios tipo /* */
6. No debe haber un espacio vacio entre ); y la creacion de Index.
7. NO debe tener comentarios
8. Los campos que son fk a dominios deben tener un valor por defecto y un comentario que muestre todas las opciones en dominios solo abreviatura.
Ej. genero_id INTEGER NOT NULL DEFAULT 1200,  -- 1200=MASCULINO, 1201=FEMENINO
PERO ESTOS comentarios se deben aplicar a estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
9. El nombre de la tabla en plural y el primary key en singular con _id lo mismo los fk.
10. NO PUEDE HABER un campo asi tipo_cuenta VARCHAR(30) NOT NULL DEFAULT 'CUENTA CORRIENTE', deberia ser tipo_cuenta_id INTERGER y ser un FK de dominios si no existe el dominio se debe solicitar el nuevo dominio
11. TODOS los campos que son FK a la tabla dominios debe tener DEFAULT y debe apuntar al dominio_id por defecto. Todos los dominios deben apuntar al dominio por defecto por cada grupo de dominio siempre dice en su descripcion DOMINIO POR DEFECTO.
12. TODOS los CONSTRAINT , CREATE UNIQUE INDEX, CREATE INDEX, DELETE FROM, ALTER SEQUENCE, UPDATE deben ser una linea sin saltos de linea.
13. Se debe controlar que los campos por su importancia deben tener check


-- LISTA DE dominios que son por defecto:
EventoID: `COMPRA` (ID: 1050)
TipoComprobanteID: `NINGUNO` (ID: 1103)
TipoClienteID: `NATURAL` (ID: 1150)
GeneroID: `MASCULINO` (ID: 1200)
EstadoCivilMasculinoID: `SOLTERO` (ID: 1250)
EstadoCivilFemeninoID: `SOLTERA` (ID: 1300)
TipoVentaID: `NINGUNO` (ID: 1350)
TipoPagoID: `NINGUNO` (ID: 1400)
TipoModeloID: `NINGUNO` (ID: 1456)
TipoBeneficioID: `NINGUNO` (ID: 1504)
EstadoPronosticoID: `NINGUNO` (ID: 1553)
TemporadaID: `NINGUNO` (ID: 1600)
EstadoFiscalID: `ACTIVO` (ID: 1650)
TipoAlmacenID: `NORMAL` (ID: 1700)
TipoCuentaID: `NO_APLICA` (ID: 1755)
TipoDatoID: `STRING` (ID: 1800)
NivelUrgenciaID: `NINGUNO` (ID: 1854)
MotivoOutlierID: `NINGUNO` (ID: 1907)
FormatoPDFID: `ESTANDAR` (ID: 1950)
EstadoModeloID: `SIN_DATOS` (ID: 2000)
CalidadRatingID: `NINGUNO` (ID: 2055)
EstadoTraspasoID: `NO_APLICA` (ID: 2103)
ModuloEstrategicoID: `NINGUNO` (ID: 2157)
TipoDocumentoID: `CEDULA_IDENTIDAD` (ID: 2200)
EstadoPedidoID: `COTIZADO` (ID: 2250)
TipoMonedaID: `BOLIVIANO` (ID: 2300)
TipoFacturaID: `NINGUNO` (ID: 2353)
EstadoFinancieroID: `NINGUNO` (ID: 2403)
MotivoAnulacionID: `NINGUNO` (ID: 2455)
EstadoLoteID: `NINGUNO` (ID: 2503)
EstadoPagoID: `NINGUNO` (ID: 2555)
TipoMovimientoID: `INGRESO` (ID: 2600)
EstadoCajaID: `ABIERTA` (ID: 2650)
TipoAlertaNotificacionID: `NINGUNO` (ID: 2724)
AmbienteID: `PILOTO_PRUEBAS` (ID: 2751)
SubtipoAlertaID: `NINGUNO` (ID: 2812)
OrigenAlertaID: `SISTEMA` (ID: 2850)
NivelCriticoID: `NINGUNO` (ID: 2905)
EstadoAlertaID: `NINGUNO` (ID: 2955)
FrameworkID: `NINGUNO` (ID: 3004)
EstadoEjecucionID: `NINGUNO` (ID: 3053)
TipoMetricasID: `NINGUNO` (ID: 3103)
NivelLogID: `INFO` (ID: 3150)
AccionRealizadaID: `INSERT` (ID: 3200)
TipoUmbralID: `STOCK_MINIMO` (ID: 3250)
EstadoDocumentoID: `EMITIDO` (ID: 3300)
FrecuenciaID: `NINGUNO` (ID: 3359)
TipoTareaID: `NINGUNO` (ID: 3409)
SubtipoTareaID: `NINGUNO` (ID: 3461)
MotivoDevolucionID: `NINGUNO` (ID: 3506)
TipoDespachoID: `NINGUNO` (ID: 3554)
MetricaPrecisionID: `NINGUNO` (ID: 3605)
FactorEstacionalidadID: `NONE` (ID: 3650)
EstadoCreditoClienteID: `NINGUNO` (ID: 3700)
EstadoMultaID: `NINGUNO` (ID: 3754)
GradoEquivalenciaID: `NINGUNO` (ID: 3803)
TipoRecetaID: `NINGUNO` (ID: 3853)

-- INSERT INTO
1. El comando se debe escribir utilizando una sola cabecera de columnas (un solo INSERT INTO ... VALUES), seguido de una lista donde cada registro ocupa una sola línea independiente, separados por comas y finalizando la última línea con punto y coma (;).
2. El orden de pk_id, campo_1, campo_2, .... campo_n debe ser el mismo orden del CREATE TABLE
3. El registro inicial con pk_id = 1 tiene un propósito técnico y de negocio crítico en el sistema (R.G.1: Registro Inicial Comodín.). Se reserva para guardar valores genéricos como 'NINGUNO', 'NO APLICA' o 'GENERAL'. su estado_id = 1000
Todos los campos que aparecen en INSERT INTO pk_id = 1 si son fk a dominios debe apuntar al dominio por defecto, pero si es fk debe apuntar a 1.
4. Para los INSERT INTO debe tener usuario_id_registro con valor 1.
4.1. El estado_id del pk_id=1 debe ser 1000.
5. El INSERT INTO No debe tener comentarios de ningun tipo. respetar los espacios vacios.
6. Antes de empezar INSERT INTO debe haber dos espacios vacios despues del final de CREATE TABLE y comenzar con
ANTES de DELETE FROM debe haber dos espacios vacios.
DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;
y terminar con

UPDATE tipos_cambios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_cambios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 1));

Ej:
DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro) VALUES
(1, 2300, 2300, 1.0000, 1.0000, '2026-07-01 00:00:00-04', 1000, 1);
(2, 2300, 2301, 6.8600, 6.9600, '2026-07-01 00:00:00-04', 1000, 1),
...
(32, 2300, 2301, 6.8600, 6.9600, '2026-07-31 00:00:00-04', 1000, 1);

UPDATE tipos_cambios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_cambios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 1));

-- SQL
1. Toda tabla debe finalizar con un bloque de comentarios multilínea delimitado por `/*` y `*/`. Debe estar a un espacio vacio despues que termina INSERT INTO.
2. Antes de `/*` debe existir exactamente una línea vacía.
3. Dentro del bloque siempre debe existir la sección `-- 1. SQL GENERAL.`.
4. El título `-- 1. SQL GENERAL.` siempre debe terminar con punto final (`.`).
5. Después del título `-- 1. SQL GENERAL.` no debe existir ninguna línea vacía; el `SELECT` debe comenzar inmediatamente en la siguiente línea.
6. El SQL GENERAL debe estar compuesto exactamente por cuatro líneas SQL:
* SELECT
* FROM
* WHERE
* ORDER BY
7. El SQL GENERAL debe existir tanto en tablas con claves foráneas como en tablas sin claves foráneas.
8. El SQL GENERAL nunca debe utilizar: * AS * JOIN * INNER JOIN * LEFT JOIN * RIGHT JOIN * FULL JOIN * alias de tablas * subconsultas
9. El SELECT del SQL GENERAL debe incluir todos los campos físicos de la tabla.
10. Los campos del SELECT deben respetar exactamente el mismo orden definido en el CREATE TABLE.
Después de usuario_id_registro y antes de usuario_id_actualizacion debe haber  --, para que los ultimos registros sean comentarios
Ej: pk_id, campo1, campo2, ... campon, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
11. No se permite omitir campos.
12. No se permite agregar campos calculados.
13. La cláusula FROM debe utilizar únicamente el nombre real de la tabla.
14. La cláusula WHERE debe utilizar la clave primaria de la tabla con el formato: `WHERE campo_pk >= 1`
15. La cláusula ORDER BY debe utilizar la clave primaria de la tabla con el formato: `ORDER BY campo_pk ASC;`
16. Si la tabla posee una o más claves foráneas debe generarse además la sección `-- 2. SQL COMPLETO.`.
17. El título `-- 2. SQL COMPLETO.` siempre debe terminar con punto final (`.`).
18. Antes del título `-- 2. SQL COMPLETO.` deben existir exactamente dos líneas vacías después del `ORDER BY` del SQL GENERAL.
19. Después del título `-- 2. SQL COMPLETO.` no debe existir ninguna línea vacía; el `SELECT` debe comenzar inmediatamente en la siguiente línea.
20. El SQL COMPLETO debe utilizar alias para la tabla principal y para todas las tablas relacionadas.
21. El SQL COMPLETO debe utilizar INNER JOIN.
22. Si corresponde se puede usar LEFT JOIN.
23. Nunca se debe utilizar FULL JOIN.
24. Nunca se debe utilizar RIGHT JOIN.
25. En el SQL COMPLETO los campos de la tabla principal deben aparecer exactamente en el mismo orden definido en el CREATE TABLE.
26. Cada vez que aparezca una clave foránea en el SELECT del SQL COMPLETO, inmediatamente después deben agregarse los campos descriptivos de la tabla referenciada.
27. Los campos descriptivos de una FK nunca pueden colocarse al final del SELECT ni en otra posición distinta a la inmediatamente posterior a la FK correspondiente.
Pero se omite para el usuario que creo, actualizo o se dio de baja.
28. Los campos descriptivos provenientes de tablas relacionadas deben utilizar AS.
29. Los alias descriptivos deben escribirse entre comillas dobles.
30. Los alias descriptivos deben seguir el patrón: `nombreFK + NombreCampoRelacionado`
Ejemplos:
`empresaNombre`
`empresaCodigo`
`tipoMonedaDescripcion`
`tipoMonedaAbreviatura`
31. La cláusula WHERE del SQL COMPLETO debe utilizar la clave primaria de la tabla principal con el formato: `WHERE alias.pk >= 1`
32. La cláusula ORDER BY del SQL COMPLETO debe utilizar la clave primaria de la tabla principal con el formato: `ORDER BY alias.pk ASC;` Luego debe haber un salto de linea vacia antes de */
33. Las palabras reservadas SELECT, FROM, WHERE, ORDER BY, INNER JOIN y ASC deben escribirse siempre en mayúsculas.
34. El punto y coma (`;`) únicamente debe colocarse al final de la cláusula ORDER BY.
35. Después del último ORDER BY debe existir exactamente una línea vacía antes de `*/`.
36. La estructura de saltos de línea debe mantenerse idéntica en todas las tablas.
37. El registro cuya clave primaria es igual a 1 representa el registro histórico predeterminado de la tabla.
38. El registro con clave primaria igual a 1 debe tener `estado_id = 1002 'HISTORICO'`.
39. Ninguna consulta de referencia debe excluir el registro histórico.
40. Todas las consultas deben ser completamente determinísticas y respetar estrictamente la estructura definida en estas reglas.

EJEMPLO:
/*
	-- 1. SQL GENERAL.
	SELECT empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
	FROM empresas
	WHERE empresa_id >= 1
	ORDER BY empresa_id ASC;


	-- 2. SQL COMPLETO.
	SELECT
		e.empresa_id,
		e.empresa,
		e.codigo,
		e.logo,
		e.eslogan,
		e.descripcion,
		e.lugar,
		e.representante,
		e.direccion,
		e.telefono,
		e.email,
		e.matricula_comercio,
		e.estado_id,
		d.abreviatura AS "estadoAbreviatura",
		e.usuario_id_registro
		e.usuario_id_actualizacion,
		e.usuario_id_baja,
		e.fecha_registro,
		e.fecha_actualizacion,
		e.fecha_baja
	FROM empresas e
	INNER JOIN dominios d ON d.dominio_id = e.estado_id AND d.estado_id IN (1000, 1002)
	WHERE e.empresa_id >= 1
	ORDER BY e.empresa_id ASC;

*/

-- Definicion de las reglas.
NO TE OLVIDES DE LAS REGLAS
Todas las tablas deben tener sus reglas particulares.
Las reglas deben informar ó aclarar lo que la tabla no informe, las reglas deben ser cortas pero claras, deben empezar en R.1.
Si la tabla ya tiene un campo que tiene un check no es necesario tener una regla que explique que hace el campo.
Las reglas particulares de una tabla no debe duplicar a las reglas generales ni duplicarse entre ellas.
Si la tabla tiene el campo codigo y codigo_fisico las reglas deben explicar cual es la diferencia.
Si el campo tiene un nombre que ambiguo como es_principal INTEGER NOT NULL DEFAULT 0, y existe el check CONSTRAINT chk_sdf_es_principal CHECK (es_principal IN (0, 1)), las reglas debe explicar que representa 0 y que representa 1.
Si la tabla tiene el campo qr VARCHAR(100) NULL, la regla debe explicar que debe contener el qr o si es metido por el usuario.
Las reglas deben explicar si es necesario el comportamientos del frontend pero no debe explicar como.
Las reglas no deben especificar algo que la tabla ya define por ejemplo:
Si la tabla tiene el campo
estado_pronostico_id INTEGER NOT NULL DEFAULT 1553, -- 1550=PENDIENTE, 1551=PROCESADO, 1552=ERROR, 1553=NINGUNO
CONSTRAINT fk_an_estado_pronostico_id FOREIGN KEY (estado_pronostico_id) REFERENCES dominios(dominio_id),

No puede haber una regla que diga:
R.6: Estado del Pronóstico. estado_pronostico_id (1550=PENDIENTE, 1551=PROCESADO, 1552=ERROR, 1553=NINGUNO) refleja el estado del cálculo analítico para cada producto-sucursal.
Lo correcto seria:
R.6: Estado del Pronóstico. estado_pronostico_id refleja el estado del cálculo analítico para cada producto-sucursal.

MIS reglas generales son:

-- ================================================================================================
-- REGLAS GENERALES. - SE APLICA A TODAS LAS TABLAS.

R.G.1: Registro Inicial Comodín: Casi todas las tablas tienen un registro inicial con llave primaria pk = 1 y valores genéricos como 'NINGUNO', ó 'NO APLICA' bajo el estado_id = 1000 'ACTIVO'. Este registro no se puede modificar, eliminar, archivar, desarchivar.
Los registros pk_id=1 no se puede modificar, eliminar, archivar, desarchivar.
Sirve como valor predeterminado (DEFAULT 1) para las llaves foráneas (FK), permitiendo la adaptabilidad automática del sistema a cualquier flujo sin requerir valores nulos (NULL) y manteniendo la consistencia e integridad referencial.
Debe aparecer en Combos de seleccion pero no debe aparecer en tables. Pero esta regla no se aplica a -- 1. SQL GENERAL. y -- 2. SQL COMPLETO.

R.G.2: Control de Estados: Todos los registros del sistema incorporan de forma obligatoria el campo estado_id (valores permitidos: 1000='ACTIVO', 1001='BORRADO', 1002='HISTORICO', 1003='ANULADO').
1000=ACTIVO: El registro está plenamente operativo y contiene información vigente. Estado operativo por defecto. Corresponde al registro vigente que permite todas las operaciones de modificación y eliminación lógica (BORRADO) sobre su entidad. Es el único estado habilitado para aparecer en componentes de selección (combos, dropdowns) y constituye el filtro predeterminado en las consultas de la capa de presentación. Los registros activos se visualizan en listados (grillas, tablas), participan en el cálculo de totales y métricas, y son los únicos susceptibles de transicionar a los estados Histórico, Anulado o Borrado.
1001=BORRADO: Estado que aplica la baja lógica definitiva del registro. Solo los registros en estado_id 1000 (ACTIVO) pueden cambiar a BORRADO, siempre y cuando se valide en el backend que todos sus registros dependientes (hijos) se encuentren previamente en estado_id BORRADO o HISTORICO (evitando la orfandad de datos). Una vez asignado, el registro se inhabilita de forma permanente, impidiendo cualquier modificación posterior y excluyéndolo por completo de la interfaz de usuario, listados (grillas), componentes de selección (combos), reportes operativos y cálculos de totales. Si el registro cuenta con archivos físicos vinculados (ej. fotos almacenadas como <pk_id>.jpg), el archivo no se elimina del disco físico para preservar la integridad de respaldos históricos y auditorías retrospectivas.
1002=HISTÓRICO: Estado que representa el archivo inmutable de un registro que ha finalizado su ciclo operativo (ej. lotes de medicamentos agotados o procesos consolidados). Una vez en este estado, el registro no admite modificación ni eliminación; sin embargo, es reversible y puede ser reactivado (retornar a Activo). Los registros históricos se incluyen en listados (grillas) y en cálculos de totales, pero se excluyen automáticamente de los componentes de selección (combos) para prevenir su uso en nuevas transacciones. Un registro puede pasar a Histórico independientemente del estado operativo de sus relaciones o hijos (activos, históricos o borrados).
1003=ANULADO: Estado de naturaleza transaccional y exclusivo de la tabla kardex y comprobantes que afectan el inventario físico (ej. ventas o compras abortadas). Representa una operación cancelada que actúa como testigo permanente de auditoría, por lo que su condición es irreversible e inmutable: no permite modificación, eliminación ni reactivación. Un registro anulado revierte automáticamente el stock físico sobre los lotes afectados, pero mantiene intacta la huella de la transacción para fines de trazabilidad, consultas históricas y procesamiento en modelos de datos (IA en Python). Se visualiza en listados (grillas) y totales, pero queda excluido de todo componente de selección y de los flujos operativos activos.

R.G.3: Estructura de Auditoría Común: Por estrictas razones de cumplimiento comercial y seguridad, todas las tablas de la base de datos incorporan de forma obligatoria los siguientes campos al final de su definición:
	estado_id INTEGER NOT NULL DEFAULT 1000,						# Estado operativo del registro según la tabla dominios.
	usuario_id_registro BIGINT NOT NULL DEFAULT 1,					# id del ususuario que creó el registro.
	usuario_id_actualizacion BIGINT NULL,							# id del ususuario que actualizo el registro, sobrescribe el valor anterior. Se actualiza cada vez que se ejecuta UPDATE menos cuando se BORRA.
	usuario_id_baja BIGINT NULL,									# id del ususuario que dio de baja el registro.
	fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,	# Fecha de creación.
	fecha_actualizacion TIMESTAMPTZ NULL,							# Fecha de actualización, sobrescribe el valor anterior. Se actualizar cuando se ejecuta UPDATE menos cuando se BORRA.
	fecha_baja TIMESTAMPTZ NULL,									# Fecha de baja.

R.G.4: Reemplazo Controlado de Archivos Multimedia: Al modificar un registro que posea un archivo físico asociado (ej. la imagen de un producto o el logo de una sucursal), si el usuario carga un nuevo archivo multimedia, el sistema sobreescribirá el archivo anterior en el servidor utilizando el mismo identificador único para no duplicar almacenamiento en disco. Si no se sube un nuevo archivo, el sistema mantendrá intacto el enlace y el archivo previamente cargado.

R.G.5: Documentación.
Todas las tablas deben tener sus reglas particulares.
Las reglas deben informar ó aclarar lo que la tabla no informe, las reglas deben ser cortas pero claras, deben empezar en R.1.
Si la tabla ya tiene un campo que tiene un check no es necesario tener una regla que explique que hace el campo.
Las reglas particulares de una tabla no debe duplicar a las reglas generales ni duplicarse entre ellas.
Si la tabla tiene el campo codigo y codigo_fisico las reglas deben explicar cual es la diferencia.
Si el campo tiene un nombre que ambiguo como es_principal INTEGER NOT NULL DEFAULT 0, y existe el check CONSTRAINT chk_sdf_es_principal CHECK (es_principal IN (0, 1)), las reglas debe explicar que representa 0 y que representa 1.
Si la tabla tiene el campo qr VARCHAR(100) NULL, la regla debe explicar que debe contener el qr o si es metido por el usuario.
Las reglas deben explicar si es necesario el comportamientos del frontend pero no debe explicar como.

R.G.6: Archivos dependientes por defecto.
Todos los archivos(fisicos) que son dependientes a un registro que es PRIMARY_KEY_ID=1 o que sean por defecto el backend debe controlar su existencia el frontend debe dar el aviso de alarma hasta que no se resuelva no se debe permitir el acceso a los modulos.

R.G.7: Los campos que son fk a la tabla dominios sus dominios no deben estar en un check por que un dominio en el futuro puede ser HISTORICO y BORRADO. si es necesario validar en una tabla el dominio_id debe ser explicado mediante una regla de la siguiente manera R.XX: (REGLA DE NEGOCIO) Descripcion.

R.G.8: Los campos que guardaran el nombre de un archivo dependiente como ser foto, avatar, debe ser VARCHAR(255) y su nombre desde el Backend se generara según el Patrón de Nomenclatura: {timestamp}-{random}.{extension}

Los campos que tiene en CREATE TABLE comentarios como ser
estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
origen_moneda_id INTEGER NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
destino_moneda_id INTEGER NOT NULL DEFAULT 2300,  	-- 2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV
ESOS comentarios se deben respatar

-- ================================================================================================

EJEMPLOS y los DOMINIOS


CREATE TABLE dominios (
    dominio_id BIGSERIAL PRIMARY KEY,
    dominio VARCHAR(255) NOT NULL,
    abreviatura VARCHAR(50) NOT NULL,
    prefijo VARCHAR(50) NULL,
	valor INTEGER NOT NULL DEFAULT 0,
	es_protegido INTEGER NOT NULL DEFAULT 0,
	descripcion VARCHAR(3000) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
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

/*
	Reglas de Tabla - dominios

	R.0: La tabla dominios actúa como el diccionario de datos maestro y paramétrico del sistema, centralizando todos los catálogos de valores fijos que gobiernan el comportamiento de la aplicación, como estados, tipos de documento, eventos y parámetros de configuración. Su propósito es garantizar la consistencia semántica y la integridad referencial de los datos operativos, evitando la proliferación de valores mágicos ("hard-coded") y proporcionando una única fuente de verdad para las restricciones CHECK y las listas de selección (combos, dropdowns) en la interfaz de usuario. Se conecta a través de claves foráneas con la práctica totalidad de las tablas maestras y transaccionales del sistema, sirviendo como la columna vertebral de la parametrización dinámica.

	R.1: Los registros de esta tabla alimentan de forma dinámica los componentes de selección paramétrica del negocio.

	R.2: El campo valor actúa como un código o identificador contextual cuya interpretación y formato dependen enteramente del dominio al que pertenece. Puede almacenar desde números secuenciales de orden interno hasta códigos alfanuméricos normalizados de sistemas externos (por ejemplo, los códigos de catálogos oficiales del SIAT para documentos, monedas, métodos de pago o motivos de anulación). Su propósito es servir de puente lógico para interfaces, interoperabilidad y reglas de negocio específicas sin alterar la estructura del diccionario.

	R.3: Prefijo su interpretación depende del dominio. en el caso del dominio EventoID el prefijo ayuda a generar el codigo del evento. También puede ser usado como una abreviatura de abreviación.

	R.4: La descripción debe explicar o definir la abreviatura.

	R.5: El valor del campo dominio actúa como el nombre lógico del catálogo maestro (ej. 'EstadoID', 'EventoID', 'MonedaID'). Por estricta convención arquitectónica, cualquier columna en las tablas maestras o transaccionales que actúe como clave foránea hacia este diccionario debe nombrarse utilizando la raíz del nombre del dominio en minúsculas seguida del sufijo _id (por ejemplo, el dominio 'EstadoID' se vincula mediante la columna estado_id). Excepción de Múltiples Relaciones: En escenarios donde una tabla requiera más de una clave foránea hacia el mismo dominio (por ejemplo, origen y destino), se permite anteponer un sufijo o prefijo descriptivo que precise su rol funcional (ej. origen_moneda_id y destino_moneda_id), siempre y cuando la raíz del dominio permanezca identificable para garantizar la predictibilidad del esquema y la integridad referencial.

	R.6: El campo es_protegido actúa como un indicador booleano de seguridad (0 = No protegido, 1 = Protegido). Cuando su valor es 1, el registro pertenece al núcleo paramétrico del sistema y cuenta con protección no se edita, ni elimina.

*/


DELETE FROM dominios;
ALTER SEQUENCE dominios_dominio_id_seq RESTART WITH 1000;

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
(1068,'EventoID','RETIRO_CUARENTENA','RCUA',0,1,'Salida temporal o definitiva de stock retenido por alerta sanitaria o control de calidad. Bloquea o saca la mercadería de la disponibilidad comercial.',1000,1);

-- 1100: TipoComprobanteID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(1100,'TipoComprobanteID','FACTURA',NULL,0,1,'Documento fiscal oficial emitido por el SIN. Genera obligación tributaria y derecho a crédito fiscal. Utilizado en ventas formales que requieren comprobante fiscal.',1000,1),
(1101,'TipoComprobanteID','RECIBO',NULL,0,1,'Documento interno de pago sin valor fiscal. Utilizado para comprobantes de pago, abonos parciales o registro de ingresos/egresos operativos.',1000,1),
(1102,'TipoComprobanteID','OTRO',NULL,0,1,'Comprobante no clasificado en las categorías anteriores. Utilizado para documentos especiales o casos excepcionales.',1000,1),
(1103,'TipoComprobanteID','NINGUNO',NULL,0,1,'Sin comprobante fiscal definido. DOMINIO POR DEFECTO.',1000,1);


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
(1603,'TemporadaID','BAJA',NULL,0,0,'Temporada de demanda baja con decremento notable en ventas. Aplica en períodos de baja incidencia de enfermedades, vacaciones o cuando el consumo disminuye estacionalmente.',1000,1),
(1650,'EstadoFiscalID','ACTIVO',NULL,0,0,'Dosificación fiscal vigente y operativa. Permite la emisión de facturas electrónicas con validez ante el SIN. El sistema puede generar comprobantes fiscales sin restricciones. DOMINIO POR DEFECTO.',1000,1);

-- 1650: EstadoFiscalID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
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
(2724,'TipoAlertaNotificacionID','NINGUNO',NULL,0,0,'Sin tipo de alerta definido. Valor por defecto para registros comodín o casos donde no se requiere clasificación de alerta. DOMINIO POR DEFECTO.',1000,1);

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

-- 3200: AccionRealizadaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3200,'AccionRealizadaID','INSERT',NULL,0,0,'Operación de inserción de un nuevo registro en el sistema. Se registra en auditoria con valores_nuevos. Aplica para creación de cualquier entidad. DOMINIO POR DEFECTO.',1000,1),
(3201,'AccionRealizadaID','UPDATE',NULL,0,0,'Operación de modificación de un registro existente. Se registra en auditoria con valores_anteriores y valores_nuevos para trazabilidad de cambios. Aplica para actualizaciones de datos.',1000,1),
(3202,'AccionRealizadaID','DELETE',NULL,0,0,'Operación de eliminación lógica de un registro. Se registra en auditoria con valores_anteriores para conservar el historial. Aplica para bajas de registros.',1000,1);

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
(3506,'MotivoDevolucionID','NINGUNO','NIN',0,0,'Sin motivo de devolución definido. Valor por defecto para transacciones que no requieren clasificación de devolución o cuando no aplica motivo específico. DOMINIO POR DEFECTO.',1000,1);

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

-- 3700: EstadoCreditoClienteID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3700,'EstadoCreditoClienteID','NINGUNO',NULL,0,0,'Sin estado de crédito definido. Valor por defecto para clientes que no tienen historial crediticio o cuando no aplica evaluación de crédito. DOMINIO POR DEFECTO.',1000,1),
(3701,'EstadoCreditoClienteID','AL_DIA',NULL,0,0,'Cliente con crédito al día. No tiene deuda pendiente y cumple con sus obligaciones de pago. Puede acceder a nuevos créditos sin restricciones.',1000,1),
(3702,'EstadoCreditoClienteID','PENDIENTE',NULL,0,0,'Cliente con crédito pendiente de pago. La deuda está dentro del plazo establecido. Puede acceder a nuevos créditos con evaluación previa.',1000,1),
(3703,'EstadoCreditoClienteID','PARCIAL',NULL,0,0,'Cliente con crédito con abono parcial. Ha realizado pagos pero aún tiene saldo pendiente. Puede acceder a nuevos créditos con restricciones.',1000,1),
(3704,'EstadoCreditoClienteID','VENCIDO',NULL,0,0,'Cliente con crédito vencido sin pagar. La deuda ha superado la fecha de vencimiento sin pago. Bloquea nuevos créditos hasta regularización. Requiere gestión de cobranza.',1000,1),
(3705,'EstadoCreditoClienteID','CASTIGADO',NULL,0,0,'Cliente con crédito incobrable. La deuda ha sido castigada contablemente por inviabilidad de cobro. Bloquea nuevos créditos permanentemente hasta autorización especial.',1000,1);

-- 3750: EstadoMultaID
INSERT INTO dominios (dominio_id,dominio,abreviatura,prefijo,valor,es_protegido,descripcion,estado_id,usuario_id_registro) VALUES
(3750,'EstadoMultaID','PENDIENTE',NULL,0,0,'Multa generada por mora, pendiente de pago por el cliente. El monto está registrado pero aún no ha sido cancelado. Estado inicial de la multa.',1000,1),
(3751,'EstadoMultaID','PAGADA',NULL,0,0,'Multa cancelada y liquidada totalmente en caja. El cliente ha realizado el pago completo. Estado final exitoso de la multa.',1000,1),
(3752,'EstadoMultaID','CONDONADA',NULL,0,0,'Multa perdonada total o parcialmente por autorización de administración. No requiere pago por parte del cliente. Requiere justificación documentada.',1000,1),
(3753,'EstadoMultaID','ANULADA',NULL,0,0,'Multa anulada por error operativo en el cálculo o en la fecha de emisión. No genera obligación de pago. Requiere corrección del cálculo original.',1000,1),
(3754,'EstadoMultaID','NINGUNO',NULL,0,0,'Sin estado de multa definido. Valor por defecto para registros comodín o casos donde no aplica clasificación de estado de multa. DOMINIO POR DEFECTO.',1000,1);

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

UPDATE dominios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE dominios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('dominios_dominio_id_seq', COALESCE((SELECT MAX(dominio_id) FROM dominios), 1));


/*
	-- 1. SQL GENERAL.
	SELECT dominio_id, dominio, abreviatura, prefijo, valor, descripcion, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
	FROM dominios
	WHERE dominio_id >= 1
	ORDER BY dominio_id ASC;


    -- 2. SQL COMPLETO.
    SELECT
        d.dominio_id,
        d.dominio,
        d.abreviatura,
        d.prefijo,
        d.valor,
        d.es_protegido,
        d.descripcion,
        d.estado_id,
        de.abreviatura AS "estadoAbreviatura",
        de.prefijo AS "estadoPrefijo",
        de.valor AS "estadoValor",
        de.es_protegido AS "estadoEsProtegido",
        d.usuario_id_registro,
        d.usuario_id_actualizacion,
        d.usuario_id_baja,
        d.fecha_registro,
        d.fecha_actualizacion,
        d.fecha_baja
    FROM dominios d
    INNER JOIN dominios de ON de.dominio_id = d.estado_id AND de.estado_id IN (1000, 1002)
    WHERE d.dominio_id >= 1
    ORDER BY d.dominio_id ASC;

*/

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
	CONSTRAINT fk_efi_estado FOREIGN KEY (estado_id) REFERENCES dominios(dominio_id),
	CONSTRAINT chk_efi_banco_min_longitud CHECK (LENGTH(TRIM(banco)) >= 3),
    CONSTRAINT chk_efi_abreviatura_min_longitud CHECK (LENGTH(TRIM(abreviatura)) >= 2),
    CONSTRAINT chk_efi_abreviatura_mayusculas CHECK (abreviatura = UPPER(abreviatura))
);
CREATE UNIQUE INDEX uix_efi_codigo_asfi ON bancos (codigo_asfi) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_efi_abreviatura ON bancos (abreviatura) WHERE estado_id IN (1000, 1002);

/*
	Reglas de Tabla - bancos

	R.0: La tabla bancos constituye el catálogo estandarizado de entidades financieras que operan en el sistema, almacenando tanto el nombre comercial como el código regulador oficial de la ASFI. Su función principal es respaldar los procesos contables y de pagos, permitiendo la asociación de cuentas bancarias propias (empresas_cuentas), de clientes (clientes), y de comprobantes de pago (comprobantes_pagos), garantizando la trazabilidad de las transacciones financieras. Se conecta directamente con las tablas empresas_cuentas, clientes, comprobantes_pagos y tipos_cambios.

	R.1: codigo_asfi almacena el código oficial asignado por la ASFI (Autoridad de Supervisión del Sistema Financiero) para identificación regulatoria.

	R.3: abreviatura debe almacenarse en mayúsculas y representa el identificador corto de la entidad financiera.

	R.4: El campo banco almacena el nombre comercial.

*/


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


/*
	-- 1. SQL GENERAL.
	SELECT banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
	FROM bancos
	WHERE banco_id >= 1
	ORDER BY banco_id ASC;


	-- 2. SQL COMPLETO.
	SELECT
		b.banco_id,
		b.banco,
		b.codigo_asfi,
		b.abreviatura,
		b.estado_id,
		d.abreviatura AS "estadoAbreviatura",
		d.prefijo AS "estadoPrefijo",
        d.valor AS "estadoValor",
        d.es_protegido AS "estadoEsProtegido",
		b.usuario_id_registro,
		b.usuario_id_actualizacion,
		b.usuario_id_baja,
		b.fecha_registro,
		b.fecha_actualizacion,
		b.fecha_baja
	FROM bancos b
	INNER JOIN dominios d ON d.dominio_id = b.estado_id AND d.estado_id IN (1000, 1002)
	WHERE b.banco_id >= 1
	ORDER BY b.banco_id ASC;

*/

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

/*
	Reglas de Tabla - tipos_cambios

	R.0: La tabla tipos_cambios gestiona el registro histórico y actualizado de las tasas de cambio entre las diferentes monedas soportadas por el sistema, como el Boliviano (BOB) y el Dólar (USD). Su propósito es respaldar las operaciones de compra y venta en múltiples divisas, proporcionando factores de compra y venta oficiales para la correcta valuación de transacciones financieras, facturación y reportes gerenciales. Se conecta directamente con la tabla bancos para identificar la entidad emisora de la cotización y con dominios para las monedas.

	R.1: La restricción chk_tpc_monedas_diferentes valida que para cualquier registro operativo (estado_id = 1000), origen_moneda_id sea diferente de destino_moneda_id, rechazando la transacción si ambas monedas son iguales.

	R.2: fecha_cotizacion registra la fecha de vigencia de la tasa de cambio. El índice uix_tpc_cotizacion_vigente garantiza unicidad por combinación de origen_moneda_id, destino_moneda_id y fecha_cotizacion para registros activos o históricos.

*/


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


/*
	-- 1. SQL GENERAL.
	SELECT tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
	FROM tipos_cambios
	WHERE tipo_cambio_id >= 1
	ORDER BY tipo_cambio_id ASC;


	-- 2. SQL COMPLETO.
	SELECT
		tc.tipo_cambio_id,
		tc.origen_moneda_id,
		om.abreviatura AS "origenMonedaAbreviatura",
		om.prefijo AS "origenMonedaPrefijo",
		om.valor AS "origenMonedaValor",
		om.es_protegido AS "origenMonedaEsProtegido",
		tc.destino_moneda_id,
		dm.abreviatura AS "destinoMonedaAbreviatura",
		dm.prefijo AS "destinoMonedaPrefijo",
		dm.valor AS "destinoMonedaValor",
		dm.es_protegido AS "destinoMonedaEsProtegido",
		tc.factor_compra,
		tc.factor_venta,
		tc.fecha_cotizacion,
		tc.estado_id,
		d.abreviatura AS "estadoAbreviatura",
		d.prefijo AS "estadoPrefijo",
        d.valor AS "estadoValor",
        d.es_protegido AS "estadoEsProtegido",
		tc.usuario_id_registro,
		tc.usuario_id_actualizacion,
		tc.usuario_id_baja,
		tc.fecha_registro,
		tc.fecha_actualizacion,
		tc.fecha_baja
	FROM tipos_cambios tc
	INNER JOIN dominios om ON om.dominio_id = tc.origen_moneda_id AND om.estado_id IN (1000, 1002)
	INNER JOIN dominios dm ON dm.dominio_id = tc.destino_moneda_id AND dm.estado_id IN (1000, 1002)
	INNER JOIN dominios d ON d.dominio_id = tc.estado_id AND d.estado_id IN (1000, 1002)
	WHERE tc.tipo_cambio_id >= 1
	ORDER BY tc.tipo_cambio_id ASC;

*/

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
    CONSTRAINT chk_emp_empresa_not_empty CHECK (TRIM(empresa) <> ''),
    CONSTRAINT chk_emp_empresa_mayusculas CHECK (empresa = UPPER(empresa)),
    CONSTRAINT chk_emp_empresa_min_length CHECK (LENGTH(TRIM(empresa)) >= 3),
    CONSTRAINT chk_emp_email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_emp_logo_not_empty CHECK (TRIM(logo) <> '')
);
CREATE UNIQUE INDEX uix_emp_empresa_unique ON empresas (empresa) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_emp_codigo_unique ON empresas (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_emp_matricula_unique ON empresas (matricula_comercio) WHERE estado_id IN (1000, 1002);

/*
    Reglas de Tabla - empresas

    R.0: La tabla empresas actúa como el nodo raíz de la estructura organizacional, almacenando la información corporativa general de la o las compañías que operan la plataforma sirena. Su función es centralizar la identidad corporativa, incluyendo razón social, logotipo, eslogan y datos de contacto, para personalizar la interfaz de usuario y, más críticamente, para proveer los datos base en la emisión de documentos fiscales y la configuración de sucursales. Se conecta jerárquicamente con sucursales, y a través de empresas_nits y empresas_cuentas con la información tributaria y bancaria de la organización.

    R.1: El campo codigo es alfanumérico y corresponde a un dato maestro ingresado manualmente por el usuario desde el formulario; el sistema no genera este código de forma automática.

    R.2: La columna logo almacena únicamente el nombre del archivo y su extensión (ej. '2.jpg'). La resolución de la URL absoluta para el renderizado en el frontend se realiza mediante variable de entorno.

    R.3: El campo empresa registra el nombre comercial de la empresa.

*/


DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.jpg', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@dominio.com', 'MAT-000', 1000, 1),
(2, 'FARMACIA SALUD Y VIDA S.R.L.', '309', '2.jpg', 'Tu salud es nuestra prioridad', 'Venta de medicamentos', 'LA PAZ - BOLIVIA', 'JUAN PEREZ FLORES', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '22441122', 'central@saludyvida.com.bo', 'M-356981', 1000, 1);

UPDATE empresas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_empresa_id_seq', COALESCE((SELECT MAX(empresa_id) FROM empresas), 1));


/*
    -- 1. SQL GENERAL.
    SELECT empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
    FROM empresas
    WHERE empresa_id >= 1
    ORDER BY empresa_id ASC;


    -- 2. SQL COMPLETO.
    SELECT
        e.empresa_id,
        e.empresa,
        e.codigo,
        e.logo,
        e.eslogan,
        e.descripcion,
        e.lugar,
        e.representante,
        e.direccion,
        e.telefono,
        e.email,
        e.matricula_comercio,
        e.estado_id,
        d.abreviatura AS "estadoAbreviatura",
		d.prefijo AS "estadoPrefijo",
        d.valor AS "estadoValor",
        d.es_protegido AS "estadoEsProtegido",
        e.usuario_id_registro,
        e.usuario_id_actualizacion,
        e.usuario_id_baja,
        e.fecha_registro,
        e.fecha_actualizacion,
        e.fecha_baja
    FROM empresas e
    INNER JOIN dominios d ON d.dominio_id = e.estado_id AND d.estado_id IN (1000, 1002)
    WHERE e.empresa_id >= 1
    ORDER BY e.empresa_id ASC;

*/

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

/*
    Reglas de Tabla - empresas_nits

    R.0: La tabla empresas_nits almacena la información de dosificación fiscal de la empresa, incluyendo el NIT, número de autorización y fechas de vigencia, necesaria para el cumplimiento de las obligaciones tributarias ante el Servicio de Impuestos Nacionales (SIN). Su propósito es controlar los rangos de numeración de facturas y la vigencia de los talonarios fiscales, asegurando que la emisión de comprobantes electrónicos se realice con credenciales válidas y activas. Se conecta directamente con la tabla empresas.

    R.1: Una misma empresa (empresa_id) puede operar con el mismo número de nit bajo distintas modalidades de facturación y ambientes dependiendo de la sucursal o punto de venta asignado. El frontend debe desplegar las descripciones de la actividad económica de forma segmentada según la dosificación seleccionada.

    R.2: El campo modalidad_facturacion_id controla el tipo de facturación autorizada por el SIN: ELECTRONICA, COMPUTARIZADA o MANUAL, afectando el flujo de emisión de comprobantes.

    R.3: El campo ambiente_id define si el NIT se utiliza en entorno de producción (2750) o en piloto/pruebas (2751), permitiendo validaciones sin afectar documentos fiscales reales.

    R.4: Los campos certificado_digital y certificado_password almacenan la ruta del archivo .p12 y su contraseña para la firma digital de documentos electrónicos. El token_siat contiene el token de acceso a los Web Services del SIN.

*/


DELETE FROM empresas_nits;
ALTER SEQUENCE empresas_nits_empresa_nit_id_seq RESTART WITH 1;

INSERT INTO empresas_nits (empresa_nit_id, empresa_id, ambiente_id, nit, razon_social, actividad_economica_principal, modalidad_facturacion_id, certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id, usuario_id_registro) VALUES
(1, 1, 2751, '0000000', 'NINGUNO', 'NINGUNA', 3900, NULL, NULL, NULL, NULL, NULL, 'ninguno@ninguno.com', 1000, 1);

UPDATE empresas_nits SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_nits SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_nits_empresa_nit_id_seq', COALESCE((SELECT MAX(empresa_nit_id) FROM empresas_nits), 1));


/*
    -- 1. SQL GENERAL.
    SELECT empresa_nit_id, empresa_id, ambiente_id, nit, razon_social, actividad_economica_principal, modalidad_facturacion_id, certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
    FROM empresas_nits
    WHERE empresa_nit_id >= 1
    ORDER BY empresa_nit_id ASC;


    -- 2. SQL COMPLETO.
    SELECT
        en.empresa_nit_id,
        en.empresa_id,
        e.empresa AS "empresaEmpresa",
        e.codigo AS "empresaCodigo",
        en.ambiente_id,
        da.abreviatura AS "ambienteAbreviatura",
		da.prefijo AS "ambientePrefijo",
		da.valor AS "ambienteValor",
		da.es_protegido AS "ambienteEsProtegido",
        en.nit,
        en.razon_social,
        en.actividad_economica_principal,
        en.modalidad_facturacion_id,
        dm.abreviatura AS "modalidadFacturacionAbreviatura",
		dm.prefijo AS "modalidadFacturacionPrefijo",
		dm.valor AS "modalidadFacturacionValor",
		dm.es_protegido AS "modalidadFacturacionEsProtegido",
        en.certificado_digital,
        en.certificado_password,
        en.token_siat,
        en.fecha_inicio_vigencia,
        en.fecha_fin_vigencia,
        en.email_fiscal,
        en.estado_id,
        d.abreviatura AS "estadoAbreviatura",
		d.prefijo AS "estadoPrefijo",
        d.valor AS "estadoValor",
        d.es_protegido AS "estadoEsProtegido",
        en.usuario_id_registro,
        en.usuario_id_actualizacion,
        en.usuario_id_baja,
        en.fecha_registro,
        en.fecha_actualizacion,
        en.fecha_baja
    FROM empresas_nits en
    INNER JOIN empresas e ON e.empresa_id = en.empresa_id AND e.estado_id IN (1000, 1002)
    INNER JOIN dominios da ON da.dominio_id = en.ambiente_id AND da.estado_id IN (1000, 1002)
    INNER JOIN dominios dm ON dm.dominio_id = en.modalidad_facturacion_id AND dm.estado_id IN (1000, 1002)
    INNER JOIN dominios d ON d.dominio_id = en.estado_id AND d.estado_id IN (1000, 1002)
    WHERE en.empresa_nit_id >= 1
    ORDER BY en.empresa_nit_id ASC;

*/

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

/*
	Reglas de Tabla - empresas_cuentas

	R.0: La tabla empresas_cuentas gestiona el catálogo de cuentas bancarias operativas de la empresa, registrando la entidad financiera, el tipo de cuenta, la moneda y el titular. Su función es proporcionar la información de las cuentas de destino para la recepción de pagos de clientes, la realización de transferencias y la conciliación bancaria de los movimientos de caja. Se conecta directamente con las tablas empresas y bancos.

	R.1: titular almacena la razón social o persona autorizada para las operaciones bancarias.

	R.2: tipo_cuenta_id define la naturaleza de la cuenta bancaria (CUENTA_CORRIENTE, CAJA_AHORROS, AHORRO_PROGRAMADO, PLAZO_FIJO, INVERSION o NO_APLICA), afectando la disponibilidad de fondos y los tipos de transacciones permitidas.

	R.3: La restricción uix_ecb_cuenta_unica garantiza que no existan cuentas duplicadas para el mismo banco y número de cuenta en registros activos o históricos.

*/


DELETE FROM empresas_cuentas;
ALTER SEQUENCE empresas_cuentas_empresa_cuenta_id_seq RESTART WITH 1;

INSERT INTO empresas_cuentas (empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 2300, '0000000000', 1755, 'NINGUNO', 1000, 1);

UPDATE empresas_cuentas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_cuentas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_cuentas_empresa_cuenta_id_seq', COALESCE((SELECT MAX(empresa_cuenta_id) FROM empresas_cuentas), 1));


/*
	-- 1. SQL GENERAL.
	SELECT empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
	FROM empresas_cuentas
	WHERE empresa_cuenta_id >= 1
	ORDER BY empresa_cuenta_id ASC;


	-- 2. SQL COMPLETO.
	SELECT
		ec.empresa_cuenta_id,
		ec.empresa_id,
		e.empresa AS "empresaEmpresa",
		e.codigo AS "empresaCodigo",
		ec.banco_id,
		b.banco AS "bancoBanco",
		b.codigo_asfi AS "bancoCodigoAsfi",
		ec.tipo_moneda_id,
		tm.abreviatura AS "tipoMonedaAbreviatura",
		tm.prefijo AS "tipoMonedaPrefijo",
		tm.valor AS "tipoMonedaValor",
		tm.es_protegido AS "tipoMonedaEsProtegido",
		ec.nro_cuenta,
		ec.tipo_cuenta_id,
		tc.abreviatura AS "tipoCuentaAbreviatura",
		tc.prefijo AS "tipoCuentaPrefijo",
		tc.valor AS "tipoCuentaValor",
		tc.es_protegido AS "tipoCuentaEsProtegido",
		ec.titular,
		ec.estado_id,
		d.abreviatura AS "estadoAbreviatura",
		d.prefijo AS "estadoPrefijo",
        d.valor AS "estadoValor",
        d.es_protegido AS "estadoEsProtegido",
		ec.usuario_id_registro,
		ec.usuario_id_actualizacion,
		ec.usuario_id_baja,
		ec.fecha_registro,
		ec.fecha_actualizacion,
		ec.fecha_baja
	FROM empresas_cuentas ec
	INNER JOIN empresas e ON e.empresa_id = ec.empresa_id AND e.estado_id IN (1000, 1002)
	INNER JOIN bancos b ON b.banco_id = ec.banco_id AND b.estado_id IN (1000, 1002)
	INNER JOIN dominios tm ON tm.dominio_id = ec.tipo_moneda_id AND tm.estado_id IN (1000, 1002)
	INNER JOIN dominios tc ON tc.dominio_id = ec.tipo_cuenta_id AND tc.estado_id IN (1000, 1002)
	INNER JOIN dominios d ON d.dominio_id = ec.estado_id AND d.estado_id IN (1000, 1002)
	WHERE ec.empresa_cuenta_id >= 1
	ORDER BY ec.empresa_cuenta_id ASC;

*/

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

/*
	Reglas de Tabla - sucursales

	R.0: La tabla sucursales define los puntos de venta operativos de la empresa, mapeando su estructura legal, geográfica y fiscal (código, número de punto de venta). Su propósito es segmentar la operación del negocio por ubicación física, controlando los factores de precio (factor_venta, factor_facturacion) que se heredan a los productos y sirviendo como eje central para los procesos de inventario, ventas, facturación (números de autorización) y asignación de personal. Se conecta directamente con las tablas almacenes, usuarios, facturas, kardex, cajas y analitica_productos.

	R.1: Siempre se debe cumplir debe cumplir precio_compra < precio_venta_sin_factura < precio_venta_con_factura. el campo precio_compra esta en la tabla productos.

	R.2: codigo_sin representa codigo_sucursal_sin es secuencial por empresa. 0=Casa Matriz, 1,2,3...

	R.3: factor_venta y factor_facturacion son valores iniciales que se heredan al crear un producto. Precio Sin Factura = Costo × factor_venta. Precio Con Factura = Costo × factor_venta × factor_facturacion.

	R.4: Cada producto preserva sus propios factores de forma independiente, rompiendo la herencia de la sucursal sin afectarla.

	R.5: Los nombres sucursal (nombre corto generalmente para reportes) y sucursal_largo (nombre legal).

*/


DELETE FROM sucursales;
ALTER SEQUENCE sucursales_sucursal_id_seq RESTART WITH 1;

INSERT INTO sucursales (sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', 'NIN', 0, '00000000', 'DIRECCION NINGUNA', '00:00 - 00:00', 1.50, 1.19, 1000, 1),
(2, 2, 'CASA MATRIZ - SOPOCACHI', 'FARMACIA SALUD Y VIDA - CASA MATRIZ SOPOCACHI', 'FSM', 0, '22441122', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '08:00 - 22:00', 1.50, 1.19, 1000, 1),
(3, 2, 'SUCURSAL ZONA SUR', 'FARMACIA SALUD Y VIDA - SUCURSAL ZONA SUR CALACOTO', 'FSZ', 1, '22774433', 'AV. BALLIVIAN NRO. 540, CALACOTO, LA PAZ', '08:00 - 23:00', 1.50, 1.19, 1000, 1);

UPDATE sucursales SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE sucursales SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('sucursales_sucursal_id_seq', COALESCE((SELECT MAX(sucursal_id) FROM sucursales), 1));


/*
	-- 1. SQL GENERAL.
	SELECT sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro --, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja
	FROM sucursales
	WHERE sucursal_id >= 1
	ORDER BY sucursal_id ASC;


	-- 2. SQL COMPLETO.
	SELECT
		s.sucursal_id,
		s.empresa_id,
		e.empresa AS "empresaEmpresa",
		e.codigo AS "empresaCodigo",
		s.sucursal,
		s.sucursal_largo,
		s.codigo,
		s.codigo_sin,
		s.telefono,
		s.ubicacion,
		s.horario_atencion,
		s.factor_venta,
		s.factor_facturacion,
		s.estado_id,
		d.abreviatura AS "estadoAbreviatura",
		d.prefijo AS "estadoPrefijo",
        d.valor AS "estadoValor",
        d.es_protegido AS "estadoEsProtegido",
		s.usuario_id_registro,
		s.usuario_id_actualizacion,
		s.usuario_id_baja,
		s.fecha_registro,
		s.fecha_actualizacion,
		s.fecha_baja
	FROM sucursales s
	INNER JOIN empresas e ON e.empresa_id = s.empresa_id AND e.estado_id IN (1000, 1002)
	INNER JOIN dominios d ON d.dominio_id = s.estado_id AND d.estado_id IN (1000, 1002)
	WHERE s.sucursal_id >= 1
	ORDER BY s.sucursal_id ASC;

*/

-- ================================================================================================
