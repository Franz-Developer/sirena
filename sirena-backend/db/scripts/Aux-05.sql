SQL MAESTRA=
SELECT
    ccu.table_name AS tabla_destino,
    c.column_name AS columna_sin_auditoria,
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
            JOIN information_schema.key_column_usage kcu_fk
                ON tc_fk.constraint_name = kcu_fk.constraint_name
                AND tc_fk.table_schema = kcu_fk.table_schema
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
        JOIN information_schema.key_column_usage kcu_ref
            ON tc_ref.constraint_name = kcu_ref.constraint_name
            AND tc_ref.table_schema = kcu_ref.table_schema
        JOIN information_schema.constraint_column_usage ccu_ref
            ON ccu_ref.constraint_name = tc_ref.constraint_name
            AND ccu_ref.table_schema = tc_ref.table_schema
        WHERE tc_ref.constraint_type = 'FOREIGN KEY'
          AND tc_ref.table_schema = c.table_schema
          AND tc_ref.table_name = c.table_name
          AND kcu_ref.column_name = c.column_name
        LIMIT 1
    ) AS referencia_fk
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.columns AS c
    ON c.table_name = ccu.table_name
    AND c.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name = 'usuarios'
    AND c.column_name NOT IN (
        'estado_id',
        'usuario_id_registro',
        'usuario_id_actualizacion',
        'usuario_id_baja',
        'fecha_registro',
        'fecha_actualizacion',
        'fecha_baja'
    )
ORDER BY ccu.table_name, c.ordinal_position;

SALE 
--- Resultado (SELECT command) ---
--------------+----------------------+------------------+-----------+-----------------------
tabla_destino |columna_sin_auditoria |tipo_dato         |tipo_clave |referencia_fk          
--------------+----------------------+------------------+-----------+-----------------------
roles         |rol_id                |bigint            |PK         |NULL                   
roles         |rol                   |character varying |           |NULL                   
roles         |codigo                |character varying |           |NULL                   
roles         |descripcion           |character varying |           |NULL                   
roles         |es_admin              |smallint          |           |NULL                   
trabajadores  |trabajador_id         |bigint            |PK         |NULL                   
trabajadores  |sucursal_id           |bigint            |FK         |sucursales.sucursal_id 
trabajadores  |genero_id             |smallint          |           |NULL                   
trabajadores  |estado_civil_id       |smallint          |           |NULL                   
trabajadores  |nombres               |character varying |           |NULL                   
trabajadores  |paterno               |character varying |           |NULL                   
trabajadores  |materno               |character varying |           |NULL                   
trabajadores  |dni                   |character varying |           |NULL                   
trabajadores  |telefono              |character varying |           |NULL                   
trabajadores  |direccion             |character varying |           |NULL                   
trabajadores  |email                 |character varying |           |NULL                   
trabajadores  |fecha_nacimiento      |date              |           |NULL                   
trabajadores  |fecha_contratacion    |date              |           |NULL                   
trabajadores  |foto                  |character varying |           |NULL                   
trabajadores  |qr                    |character varying |           |NULL                   
--------------+----------------------+------------------+-----------+-----------------------
Total de filas: 20



a la SQL MAESTRA= se puede adicionar 'trabajadores_cargos', 'cargos', 'sucursales', 'empresas' 
y que me muestre estas tablas 'trabajadores_cargos', 'cargos', 'sucursales', 'empresas'  y sus campos 