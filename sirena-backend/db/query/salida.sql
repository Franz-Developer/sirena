--- Resultado #1 (SELECT command) ---
Estado: OK
Filas afectadas: 0
--- Resultado (SELECT command) ---
--------------+----------------------+------------------+-----------+-----------------------
tabla_destino |columna_sin_auditoria |tipo_dato         |tipo_clave |referencia_fk          
--------------+----------------------+------------------+-----------+-----------------------
puntos_venta  |punto_venta_id        |bigint            |PK         |NULL                   
puntos_venta  |sucursal_id           |bigint            |FK         |sucursales.sucursal_id 
puntos_venta  |codigo                |integer           |           |NULL                   
puntos_venta  |nombre                |character varying |           |NULL                   
puntos_venta  |tipo_punto_venta_id   |smallint          |           |NULL                   
sucursales    |sucursal_id           |bigint            |PK         |NULL                   
sucursales    |empresa_id            |bigint            |FK         |empresas.empresa_id    
sucursales    |sucursal              |character varying |           |NULL                   
sucursales    |sucursal_largo        |character varying |           |NULL                   
sucursales    |codigo                |character varying |           |NULL                   
sucursales    |codigo_sin            |integer           |           |NULL                   
sucursales    |telefono              |character varying |           |NULL                   
sucursales    |ubicacion             |character varying |           |NULL                   
sucursales    |horario_atencion      |character varying |           |NULL                   
sucursales    |factor_venta          |numeric           |           |NULL                   
sucursales    |factor_facturacion    |numeric           |           |NULL                   
--------------+----------------------+------------------+-----------+-----------------------
Total de filas: 16


--- Resultado (SELECT command) ---
-------------+--------------------+------------------+-----------+-----------------------
tabla        |columna             |tipo_dato         |tipo_clave |referencia_fk          
-------------+--------------------+------------------+-----------+-----------------------
puntos_venta |punto_venta_id      |bigint            |PK         |NULL                   
puntos_venta |sucursal_id         |bigint            |FK         |sucursales.sucursal_id 
puntos_venta |codigo              |integer           |           |NULL                   
puntos_venta |nombre              |character varying |           |NULL                   
puntos_venta |tipo_punto_venta_id |smallint          |           |NULL                   
sucursales   |sucursal_id         |bigint            |PK         |NULL                   
sucursales   |empresa_id          |bigint            |FK         |empresas.empresa_id    
sucursales   |sucursal            |character varying |           |NULL                   
sucursales   |sucursal_largo      |character varying |           |NULL                   
sucursales   |codigo              |character varying |           |NULL                   
sucursales   |codigo_sin          |integer           |           |NULL                   
sucursales   |telefono            |character varying |           |NULL                   
sucursales   |ubicacion           |character varying |           |NULL                   
sucursales   |horario_atencion    |character varying |           |NULL                   
sucursales   |factor_venta        |numeric           |           |NULL                   
sucursales   |factor_facturacion  |numeric           |           |NULL                   
-------------+--------------------+------------------+-----------+-----------------------
Total de filas: 16


