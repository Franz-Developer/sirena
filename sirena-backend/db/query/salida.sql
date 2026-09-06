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




