
/*
UPDATE trabajadores SET fecha_contratacion = '2026-01-01' WHERE trabajador_id >=1;

UPDATE trabajadores SET qr='1.png' WHERE trabajador_id = 1;
UPDATE trabajadores SET qr='2.png' WHERE trabajador_id = 2;
UPDATE trabajadores SET qr='3.png' WHERE trabajador_id = 3;
UPDATE trabajadores SET qr='4.png' WHERE trabajador_id = 4;
UPDATE trabajadores SET qr='5.png' WHERE trabajador_id = 5;
UPDATE trabajadores SET qr='6.png' WHERE trabajador_id = 6;
UPDATE trabajadores SET qr='7.png' WHERE trabajador_id = 7;
UPDATE trabajadores SET qr='8.png' WHERE trabajador_id = 8;
UPDATE trabajadores SET qr='9.png' WHERE trabajador_id = 9;
UPDATE trabajadores SET qr='10.png' WHERE trabajador_id = 10;
UPDATE trabajadores SET qr='11.png' WHERE trabajador_id = 11;
UPDATE trabajadores SET qr='12.png' WHERE trabajador_id = 12;
UPDATE trabajadores SET qr='13.png' WHERE trabajador_id = 13;
UPDATE trabajadores SET qr='14.png' WHERE trabajador_id = 14;
UPDATE trabajadores SET qr='15.png' WHERE trabajador_id = 15;
UPDATE trabajadores SET qr='16.png' WHERE trabajador_id = 16;
UPDATE trabajadores SET qr='17.png' WHERE trabajador_id = 17;
*/

-- DELETE FROM trabajadores WHERE trabajador_id > 17;

SELECT
    trabajador_id,
    genero_id,
    CASE genero_id
        WHEN 1200 THEN 'MASCULINO'
        WHEN 1201 THEN 'FEMENINO'
        ELSE 'NO ESPECIFICADO'
    END AS genero,
    estado_civil_id,
    nombres,
    paterno,
    materno,
    dni,
    telefono,
    email,
    fecha_nacimiento,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, fecha_nacimiento))::INT AS edad,
    fecha_contratacion,
    foto,
    qr,
    estado_id,
    usuario_id_registro
FROM trabajadores
WHERE trabajador_id >= 1
ORDER BY trabajador_id ASC;


SELECT contrasena, usuario_id
FROM usuarios
ORDER BY usuario_id ASC;

/*
SELECT *
FROM almacenes_puntos_venta
WHERE sucursal_id = 4
ORDER BY almacen_punto_venta_id DESC;
*/

/*INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (35, 'foto_trabajador_config', 'FOTO_CONFIG', 1805, '{"max_size": 512000, "max_width": 600, "max_height": 700, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de fotos de trabajadores en formato vertical (tamaño máximo: 500 KB, dimensiones: 600x700 px)', 1, 1000, 2),
     (36, 'qr_trabajador_config', 'QR_CONFIG', 1805, '{"width": 300, "height": 300, "margin": 2, "color_dark": "#000000", "color_light": "#FFFFFF", "format": "png", "error_correction_level": "M"}', 'Configuración para la autogeneración de códigos QR del trabajador (300x300 px, fondo blanco, PNG)', 1, 1000, 2);

UPDATE trabajadores SET foto = '3.jpg' WHERE trabajador_id=3;
UPDATE trabajadores SET foto = '4.png' WHERE trabajador_id=4;
UPDATE trabajadores SET foto = '6.jpg' WHERE trabajador_id=6;
UPDATE trabajadores SET foto = '8.jpg' WHERE trabajador_id=8;
UPDATE trabajadores SET foto = '15.jpg' WHERE trabajador_id=15;
UPDATE trabajadores SET foto = '16.png' WHERE trabajador_id=16;
*/

/*
UPDATE parametros_globales SET valor = 'default-foto-trabajador.jpg' WHERE parametro_id = 35;


SELECT *
FROM parametros_globales
ORDER BY parametro_id ASC;
*/

ALTER TABLE trabajadores DROP CONSTRAINT chk_trabajadores_qr_notempty;

-- 2. Modificar la columna para que permita NULL (por defecto ya suele permitirlo si no tiene NOT NULL, pero aseguramos la definición)
ALTER TABLE trabajadores ALTER COLUMN qr DROP NOT NULL;

ALTER TABLE trabajadores ALTER COLUMN qr NULL;

-- 3. Crear una nueva restricción CHECK que acepte NULL o cadenas que no estén vacías
ALTER TABLE trabajadores ADD CONSTRAINT chk_trabajadores_qr_notempty
    CHECK (qr IS NULL OR TRIM(qr) <> '');



SELECT
    parametro_id,
    clave,
    valor,
    tipo_dato_id,
    datos_json,
    descripcion,
    editable,
    estado_id,
    CASE estado_id
        WHEN 1000 THEN 'ACTIVO'
        WHEN 1001 THEN 'BORRADO'
        WHEN 1002 THEN 'HISTORICO'
        WHEN 1003 THEN 'ANULADO'
    END AS estado_registro,
    fn_obtener_login_para_operacion('parametros_globales', 'parametro_id', parametro_id) AS usuario_operacion,
    usuario_id_registro
FROM parametros_globales
WHERE 1=1
AND editable=1
ORDER BY parametro_id DESC;


SELECT COUNT(*) AS total
FROM tipos_cambios t
WHERE 1=1
AND t.tipo_cambio_id > 1
AND t.estado_id IN (1000, 1002, 1003)
AND (
    t.fecha_registro >= '2026-01-01T04:00:00.000Z'
    OR (t.fecha_actualizacion IS NOT NULL AND t.fecha_actualizacion >= $4)
            )
         AND t.fecha_cotizacion >= '2026-08-24' AND t.fecha_cotizacion <= '2026-09-30'
         ;

SELECT
    t.empresa_cuenta_id,
    t.empresa_id,
    e.empresa AS empresa_nombre,
    e.codigo AS empresa_codigo,
    t.banco_id,
    b.banco AS banco_nombre,
    b.codigo_asfi AS banco_codigo_asfi,
    b.abreviatura AS banco_abreviatura,

    -- TIPO MONEDA (Datos expandidos)
    t.tipo_moneda_id,
    tm.abreviatura AS tipo_moneda_abreviatura,
    tm.prefijo AS tipo_moneda_prefijo,
    tm.valor AS tipo_moneda_valor,

    t.nro_cuenta,

    -- TIPO CUENTA (Datos expandidos)
    t.tipo_cuenta_id,
    tc.abreviatura AS tipo_cuenta_abreviatura,
    tc.prefijo AS tipo_cuenta_prefijo,
    tc.valor AS tipo_cuenta_valor,

    t.titular,
    t.estado_id,
    CASE t.estado_id
        WHEN 1000 THEN 'ACTIVO'
        WHEN 1001 THEN 'BORRADO'
        WHEN 1002 THEN 'HISTORICO'
        WHEN 1003 THEN 'ANULADO'
    END AS estado_registro,
    fn_obtener_login_para_operacion('empresas_cuentas', 'empresa_cuenta_id', t.empresa_cuenta_id) AS usuario_operacion,
    t.usuario_id_registro,
    t.usuario_id_actualizacion,
    t.usuario_id_baja,
    t.fecha_registro,
    t.fecha_actualizacion,
    t.fecha_baja
FROM empresas_cuentas t
JOIN empresas e ON e.empresa_id = t.empresa_id AND e.estado_id IN (1000, 1002)
JOIN bancos b ON b.banco_id = t.banco_id AND b.estado_id IN (1000, 1002)
-- Mapeo estructurado para Tipo Moneda
INNER JOIN (
    VALUES
        (2300, 'BOLIVIANO', 'BOB', 1),
        (2301, 'DOLAR', 'USD', 2),
        (2302, 'EURO', 'EUR', 3),
        (2303, 'UFV', 'UFV', 4)
) AS tm(id, abreviatura, prefijo, valor) ON tm.id = t.tipo_moneda_id
-- Mapeo estructurado para Tipo Cuenta
INNER JOIN (
    VALUES
        (1750, 'CUENTA_CORRIENTE', NULL::TEXT, 0),
        (1751, 'CAJA_AHORROS', NULL::TEXT, 0),
        (1752, 'AHORRO_PROGRAMADO', NULL::TEXT, 0),
        (1753, 'PLAZO_FIJO', NULL::TEXT, 0),
        (1754, 'INVERSION', NULL::TEXT, 0),
        (1755, 'NO_APLICA', NULL::TEXT, 0)
) AS tc(id, abreviatura, prefijo, valor) ON tc.id = t.tipo_cuenta_id
WHERE 1=1
AND t.empresa_cuenta_id > 1
AND t.estado_id IN (1000, 1002)
AND t.empresa_id = 3
ORDER BY t.empresa_cuenta_id DESC;
