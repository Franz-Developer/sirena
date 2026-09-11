--- Resultado (SELECT command) ---
-----------------------------
tablename                    
-----------------------------
alertas_notificaciones       
almacenes                    
almacenes_puntos_venta       
analitica_productos          
arqueos_detalle              
asistencias                  
bancos                       
cajas                        
cargos                       
carritos_compra              
categorias                   
clientes                     
comprobantes_pagos           
concentraciones              
contratos                    
control_facturas             
conversiones_unidad          
costos_promedio              
cufd                         
cuis                         
detalles_carritos            
detalles_pedidos_online      
empresas                     
empresas_cuentas             
empresas_nits                
entrenamientos               
equivalentes                 
especialidades               
formas                       
historicos                   
instituciones                
inventarios_fisicos          
inventarios_fisicos_detalle  
kardex                       
kardex_productos             
laboratorios                 
listas_precios               
logs_ejecucion               
lotes_productos              
marcas                       
medicos                      
menus                        
metricas_rendimiento         
modelos                      
movimientos                  
ordenes_compra               
pagos                        
parametros_globales          
patrones_consumo             
pedidos_online               
planes_pagos                 
planillas                    
planillas_detalle            
politicas_precios            
precios_productos            
presentaciones               
principios_activos           
productos                    
productos_controlados        
productos_principios         
productos_rangos_edad        
productos_ubicaciones        
productos_vias               
promociones                  
promociones_productos        
proveedores                  
proveedores_contactos        
proveedores_rating_historico 
puntos_venta                 
rangos_edad                  
recetas                      
registros_sanitarios         
roles                        
roles_menus                  
roles_permisos_sucesos       
roles_permisos_tablas        
sucesos                      
sucursales                   
tablas                       
tareas_programadas           
tipos_cambios                
tipos_planes_pago            
trabajadores                 
trabajadores_cargos          
ubicaciones                  
ubicaciones_historial        
ubicaciones_movimientos      
umbrales_configuracion       
unidades                     
usuarios                     
variables_exogenas           
vias                         
-----------------------------
Total de filas: 92


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


