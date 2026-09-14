--- Resultado (SELECT command) ---
-----------------------+--------------------+-------------------+------------
tabla_dependiente      |columna_fk          |tabla_referenciada |columna_pk  
-----------------------+--------------------+-------------------+------------
alertas_notificaciones |sucursal_id         |sucursales         |sucursal_id 
almacenes              |sucursal_id         |sucursales         |sucursal_id 
analitica_productos    |sucursal_id         |sucursales         |sucursal_id 
asistencias            |sucursal_id         |sucursales         |sucursal_id 
cajas                  |sucursal_id         |sucursales         |sucursal_id 
carritos_compra        |sucursal_id         |sucursales         |sucursal_id 
control_facturas       |sucursal_id         |sucursales         |sucursal_id 
cufd                   |sucursal_id         |sucursales         |sucursal_id 
cuis                   |sucursal_id         |sucursales         |sucursal_id 
historicos             |sucursal_id         |sucursales         |sucursal_id 
kardex                 |sucursal_destino_id |sucursales         |sucursal_id 
kardex                 |sucursal_id         |sucursales         |sucursal_id 
kardex_productos       |sucursal_id         |sucursales         |sucursal_id 
patrones_consumo       |sucursal_id         |sucursales         |sucursal_id 
pedidos_online         |sucursal_id         |sucursales         |sucursal_id 
planillas              |sucursal_id         |sucursales         |sucursal_id 
puntos_venta           |sucursal_id         |sucursales         |sucursal_id 
recetas                |sucursal_id         |sucursales         |sucursal_id 
trabajadores           |sucursal_id         |sucursales         |sucursal_id 
umbrales_configuracion |sucursal_id         |sucursales         |sucursal_id 
variables_exogenas     |sucursal_id         |sucursales         |sucursal_id 
-----------------------+--------------------+-------------------+------------
Total de filas: 21


--- Resultado (SELECT command) ---
-----------+-------------------+------------------+-----------+--------------------
tabla      |columna            |tipo_dato         |tipo_clave |referencia_fk       
-----------+-------------------+------------------+-----------+--------------------
empresas   |empresa_id         |bigint            |PK         |NULL                
empresas   |empresa            |character varying |           |NULL                
empresas   |codigo             |character varying |           |NULL                
empresas   |logo               |character varying |           |NULL                
empresas   |eslogan            |character varying |           |NULL                
empresas   |descripcion        |character varying |           |NULL                
empresas   |lugar              |character varying |           |NULL                
empresas   |representante      |character varying |           |NULL                
empresas   |direccion          |character varying |           |NULL                
empresas   |telefono           |character varying |           |NULL                
empresas   |email              |character varying |           |NULL                
empresas   |matricula_comercio |character varying |           |NULL                
sucursales |sucursal_id        |bigint            |PK         |NULL                
sucursales |empresa_id         |bigint            |FK         |empresas.empresa_id 
sucursales |sucursal           |character varying |           |NULL                
sucursales |sucursal_largo     |character varying |           |NULL                
sucursales |codigo             |character varying |           |NULL                
sucursales |codigo_sin         |integer           |           |NULL                
sucursales |telefono           |character varying |           |NULL                
sucursales |ubicacion          |character varying |           |NULL                
sucursales |horario_atencion   |character varying |           |NULL                
sucursales |factor_venta       |numeric           |           |NULL                
sucursales |factor_facturacion |numeric           |           |NULL                
-----------+-------------------+------------------+-----------+--------------------
Total de filas: 23


--- Resultado (SELECT command) ---
-----------------------------
table_name                   
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


