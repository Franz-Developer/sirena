/*
-- TABLAS DEPENDIENTES.
SELECT
    kcu.table_name AS tabla_dependiente,
    kcu.column_name AS columna_fk,
    ccu.table_name AS tabla_referenciada,
    ccu.column_name AS columna_pk
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND ccu.table_name = 'clientes'
ORDER BY kcu.table_name;




SELECT
    c.table_name AS tabla,
    c.column_name AS columna,
    c.data_type AS tipo_dato,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.table_constraints tc_pk
            JOIN information_schema.key_column_usage kcu_pk
                ON tc_pk.constraint_name = kcu_pk.constraint_name
                AND tc_pk.table_schema = kcu_pk.table_schema
            WHERE tc_pk.constraint_type = 'PRIMARY KEY'
              AND tc_pk.table_schema = c.table_schema
              AND tc_pk.table_name = c.table_name
              AND kcu_pk.column_name = c.column_name
        )
        THEN 'PK'
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.table_constraints tc_fk
            JOIN information_schema.key_column_usage kcu_fk ON tc_fk.constraint_name = kcu_fk.constraint_name AND tc_fk.table_schema = kcu_fk.table_schema
            WHERE tc_fk.constraint_type = 'FOREIGN KEY'
                AND tc_fk.table_schema = c.table_schema
                AND tc_fk.table_name = c.table_name
                AND kcu_fk.column_name = c.column_name
        )
        THEN 'FK'
        ELSE ''
    END AS tipo_clave,
    (
        SELECT
            ccu_ref.table_name || '.' || ccu_ref.column_name
        FROM information_schema.table_constraints tc_ref
        JOIN information_schema.key_column_usage kcu_ref ON tc_ref.constraint_name = kcu_ref.constraint_name AND tc_ref.table_schema = kcu_ref.table_schema
        JOIN information_schema.constraint_column_usage ccu_ref ON ccu_ref.constraint_name = tc_ref.constraint_name AND ccu_ref.table_schema = tc_ref.table_schema
        WHERE tc_ref.constraint_type = 'FOREIGN KEY'
            AND tc_ref.table_schema = c.table_schema
            AND tc_ref.table_name = c.table_name
            AND kcu_ref.column_name = c.column_name
        LIMIT 1
    ) AS referencia_fk
FROM information_schema.columns AS c
WHERE c.table_schema = 'public'
    AND c.table_name IN (
        'clientes',
        'bancos'
    )
    AND c.column_name NOT IN (
        'estado_id',
        'usuario_id_registro',
        'usuario_id_actualizacion',
        'usuario_id_baja',
        'fecha_registro',
        'fecha_actualizacion',
        'fecha_baja'
    )
ORDER BY c.table_name, c.ordinal_position;
*/

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

INSERT INTO bancos (banco, codigo_asfi, abreviatura, descripcion, estado_id, usuario_id_registro) VALUES
('BANCO UNION ANDINO S.A.',           '20', 'BUA',  'Banco de prueba', 1000, 2),
('BANCO DEL SUR S.A.',                '21', 'BDS',  'Banco de prueba', 1000, 2),
('BANCO CENTRAL ANDINO S.A.',         '22', 'BCA',  'Banco de prueba', 1000, 2),
('BANCO DE INVERSIONES DEL NORTE',    '23', 'BIN',  'Banco de prueba', 1000, 2),
('BANCO EMPRESARIAL DEL ORIENTE',     '24', 'BEO',  'Banco de prueba', 1000, 2),
('BANCO AGRICOLA DEL VALLE',          '25', 'BAV',  'Banco de prueba', 1000, 2),
('BANCO HIPOTECARIO NACIONAL',        '26', 'BHN',  'Banco de prueba', 1000, 2),
('BANCO COMERCIAL DEL ALTIPLANO',     '27', 'BAL',  'Banco de prueba', 1000, 2),  -- ← CAMBIO AQUÍ
('BANCO MICROCREDITO DEL SUR',        '28', 'BMS',  'Banco de prueba', 1000, 2),
('BANCO DE DESARROLLO PRODUCTIVO',    '29', 'BDP',  'Banco de prueba', 1000, 2),
('BANCO DE LA FAMILIA S.A.',          '30', 'BFA',  'Banco de prueba', 1000, 2),
('BANCO DE COMERCIO EXTERIOR',        '31', 'BCE',  'Banco de prueba', 1000, 2),
('BANCO DE AHORRO Y CREDITO',         '32', 'BAC',  'Banco de prueba', 1000, 2),
('BANCO DE SERVICIOS FINANCIEROS',    '33', 'BSF',  'Banco de prueba', 1000, 2),
('BANCO DE LA PRODUCCION S.A.',       '35', 'BPS',  'Banco de prueba', 1000, 2),
('BANCO DE VIVIENDA Y URBANISMO',     '36', 'BVU',  'Banco de prueba', 1000, 2),
('BANCO DE CREDITO HIPOTECARIO',      '37', 'BCH',  'Banco de prueba', 1000, 2),
('BANCO DE INVERSION Y FOMENTO',      '38', 'BIF',  'Banco de prueba', 1000, 2),
('BANCO DE LA MICROEMPRESA S.A.',     '39', 'BEM',  'Banco de prueba', 1000, 2),
('BANCO DE CAPITAL PRIVADO',          '40', 'BCP',  'Banco de prueba', 1000, 2),
('BANCO DE CAPITAL MIXTO',            '41', 'BCM',  'Banco de prueba', 1000, 2),
('BANCO DE FOMENTO REGIONAL',         '42', 'BFR',  'Banco de prueba', 1000, 2),
('BANCO DE CREDITO AGRICOLA',         '43', 'BCG',  'Banco de prueba', 1000, 2),
('BANCO DE LA INDUSTRIA S.A.',        '44', 'BIS',  'Banco de prueba', 1000, 2),
('BANCO DE LA CONSTRUCCION S.A.',     '45', 'BCN',  'Banco de prueba', 1000, 2),
('BANCO DE LA MINERIA S.A.',          '46', 'BMN',  'Banco de prueba', 1000, 2),
('BANCO DE TELECOMUNICACIONES',       '47', 'BTL',  'Banco de prueba', 1000, 2),
('BANCO DE ENERGIA Y RECURSOS',       '48', 'BER',  'Banco de prueba', 1000, 2),
('BANCO DE TRANSPORTE Y LOGISTICA',   '49', 'BTLG', 'Banco de prueba', 1000, 2),
('BANCO DE SEGUROS Y REASEGUROS',     '50', 'BSR',  'Banco de prueba', 1000, 2);

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

SELECT banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro
FROM bancos
ORDER BY banco_id ASC;
