--- Resultado (SELECT command) ---
------------------+-----------+-------------------+-----------
tabla_dependiente |columna_fk |tabla_referenciada |columna_pk 
------------------+-----------+-------------------+-----------
carritos_compra   |cliente_id |clientes           |cliente_id 
historicos        |cliente_id |clientes           |cliente_id 
kardex            |cliente_id |clientes           |cliente_id 
pedidos_online    |cliente_id |clientes           |cliente_id 
recetas           |cliente_id |clientes           |cliente_id 
------------------+-----------+-------------------+-----------
Total de filas: 5


--- Resultado (SELECT command) ---
--------------+----------------------+------------------+-----------+--------------
tabla_destino |columna_sin_auditoria |tipo_dato         |tipo_clave |referencia_fk 
--------------+----------------------+------------------+-----------+--------------
bancos        |banco_id              |bigint            |PK         |NULL          
bancos        |banco                 |character varying |           |NULL          
bancos        |codigo_asfi           |character         |           |NULL          
bancos        |abreviatura           |character varying |           |NULL          
bancos        |descripcion           |character varying |           |NULL          
--------------+----------------------+------------------+-----------+--------------
Total de filas: 5


--- Resultado (SELECT command) ---
---------+----------------------+------------------+-----------+----------------
tabla    |columna               |tipo_dato         |tipo_clave |referencia_fk   
---------+----------------------+------------------+-----------+----------------
bancos   |banco_id              |bigint            |PK         |NULL            
bancos   |banco                 |character varying |           |NULL            
bancos   |codigo_asfi           |character         |           |NULL            
bancos   |abreviatura           |character varying |           |NULL            
bancos   |descripcion           |character varying |           |NULL            
clientes |cliente_id            |bigint            |PK         |NULL            
clientes |tipo_cliente_id       |smallint          |           |NULL            
clientes |cliente               |character varying |           |NULL            
clientes |nit                   |character varying |           |NULL            
clientes |razon_social          |character varying |           |NULL            
clientes |documento             |character varying |           |NULL            
clientes |documento_complemento |character varying |           |NULL            
clientes |tipo_documento_id     |smallint          |           |NULL            
clientes |direccion             |character varying |           |NULL            
clientes |telefono              |character varying |           |NULL            
clientes |email                 |character varying |           |NULL            
clientes |banco_base_id         |bigint            |FK         |bancos.banco_id 
clientes |numero_cuenta         |character varying |           |NULL            
clientes |habilitado_ventas     |smallint          |           |NULL            
clientes |limite_credito        |numeric           |           |NULL            
---------+----------------------+------------------+-----------+----------------
Total de filas: 20


