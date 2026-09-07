--- Resultado (SELECT command) ---
----------------------+-----------+-------------------+-----------
tabla_dependiente     |columna_fk |tabla_referenciada |columna_pk 
----------------------+-----------+-------------------+-----------
roles_permisos_tablas |tabla_id   |tablas             |tabla_id   
sucesos               |tabla_id   |tablas             |tabla_id   
----------------------+-----------+-------------------+-----------
Total de filas: 2


--- Resultado #2 (SELECT command) ---
Estado: OK
Filas afectadas: 0
--- Resultado (SELECT command) ---
-------+---------+------------------+-----------+--------------
tabla  |columna  |tipo_dato         |tipo_clave |referencia_fk 
-------+---------+------------------+-----------+--------------
tablas |tabla_id |bigint            |PK         |NULL          
tablas |nombre   |character varying |           |NULL          
-------+---------+------------------+-----------+--------------
Total de filas: 2


