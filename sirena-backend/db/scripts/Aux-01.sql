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
    AND ccu.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND ccu.table_name = 'bancos'
ORDER BY kcu.table_name;

--- Resultado (SELECT command) ---
-------------------+--------------+-------------------+-----------+------------------------------
tabla_dependiente  |columna_fk    |tabla_referenciada |columna_pk |nombre_restriccion            
-------------------+--------------+-------------------+-----------+------------------------------
clientes           |banco_base_id |bancos             |banco_id   |fk_clientes_banco_base_id     
comprobantes_pagos |banco_id      |bancos             |banco_id   |fk_comprobantespagos_banco_id 
empresas_cuentas   |banco_id      |bancos             |banco_id   |fk_empresascuentas_banco_id   
-------------------+--------------+-------------------+-----------+------------------------------

Total de filas: 3
