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
-------
setval 
-------
481    
-------
Total de filas: 1


--- Resultado #4 (INSERT command) ---
Estado: OK
Filas afectadas: 151
Tabla: roles_menus
--- Resultado (SELECT command) ---
-------
setval 
-------
632    
-------
Total de filas: 1


--- Resultado (SELECT command) ---
------------+-------+--------+----------+--------------------+-------------------------+----------------+-------------------------------+--------------------+-----------
rol_menu_id |rol_id |menu_id |estado_id |usuario_id_registro |usuario_id_actualizacion |usuario_id_baja |fecha_registro                 |fecha_actualizacion |fecha_baja 
------------+-------+--------+----------+--------------------+-------------------------+----------------+-------------------------------+--------------------+-----------
1           |1      |1       |1000      |1                   |NULL                     |NULL            |2026-09-10 00:18:45.863 -04:00 |NULL                |NULL       
2           |2      |1       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
3           |2      |2       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
4           |2      |3       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
5           |2      |4       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
6           |2      |5       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
7           |2      |6       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
8           |2      |7       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
9           |2      |8       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
10          |2      |9       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
11          |2      |10      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
12          |2      |11      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
13          |2      |12      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
14          |2      |13      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
15          |2      |14      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
16          |2      |15      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
17          |2      |16      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
18          |2      |17      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
19          |2      |18      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
20          |2      |19      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
21          |2      |20      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
22          |2      |21      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
23          |2      |22      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
24          |2      |23      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
25          |2      |24      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
26          |2      |25      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
27          |2      |26      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
28          |2      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
29          |2      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
30          |2      |29      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
31          |2      |30      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
32          |2      |31      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
33          |2      |32      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
34          |2      |33      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
35          |2      |34      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
36          |2      |35      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
37          |2      |36      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
38          |2      |37      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
39          |2      |38      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
40          |2      |39      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
41          |2      |40      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
42          |2      |41      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
43          |2      |42      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
44          |2      |43      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
45          |2      |44      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
46          |2      |45      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
47          |2      |46      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
48          |2      |47      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
49          |2      |48      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
50          |2      |49      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
51          |2      |50      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
52          |2      |51      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
53          |2      |52      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
54          |2      |53      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
55          |2      |54      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
56          |2      |55      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
57          |2      |56      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
58          |2      |57      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
59          |2      |58      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
60          |2      |59      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
61          |2      |60      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
62          |2      |61      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
63          |2      |62      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
64          |2      |63      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
65          |2      |64      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
66          |2      |65      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
67          |2      |66      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
68          |2      |67      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
69          |2      |68      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
70          |2      |69      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
71          |2      |70      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
72          |2      |71      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
73          |2      |72      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
74          |2      |73      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
75          |2      |74      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
76          |2      |75      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
77          |2      |76      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
78          |2      |77      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
79          |2      |78      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
80          |2      |79      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
81          |2      |80      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
82          |2      |81      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
83          |2      |82      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
84          |2      |83      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
85          |2      |84      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
86          |2      |85      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
87          |2      |86      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
88          |2      |87      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
89          |2      |88      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
90          |2      |89      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
91          |2      |90      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
92          |2      |91      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
93          |2      |92      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
94          |2      |93      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
95          |2      |94      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
96          |2      |95      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
97          |2      |96      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
98          |2      |97      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
99          |2      |98      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
100         |2      |99      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
101         |2      |100     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
102         |2      |101     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
103         |2      |102     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
104         |2      |103     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
105         |2      |104     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
106         |2      |105     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
107         |2      |106     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
108         |2      |107     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
109         |2      |108     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
110         |2      |109     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
111         |2      |110     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
112         |2      |111     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
113         |2      |112     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
114         |2      |113     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
115         |2      |114     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
116         |2      |115     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
117         |2      |116     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
118         |2      |117     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
119         |2      |118     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
120         |2      |119     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
121         |2      |120     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
122         |2      |121     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
123         |2      |122     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
124         |2      |123     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
125         |2      |124     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
126         |2      |125     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
127         |2      |126     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
128         |2      |127     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
129         |2      |128     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
130         |2      |129     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
131         |2      |130     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
132         |2      |131     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
133         |2      |132     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
134         |2      |133     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
135         |2      |134     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
136         |2      |135     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
137         |2      |136     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
138         |2      |137     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
139         |2      |138     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
140         |2      |139     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
141         |2      |140     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
142         |2      |141     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
143         |2      |142     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
144         |2      |143     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
145         |2      |144     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
146         |2      |145     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
147         |2      |146     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
148         |2      |147     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
149         |2      |148     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
150         |2      |149     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
151         |2      |150     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
152         |2      |151     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.865 -04:00 |NULL                |NULL       
153         |3      |2       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
154         |3      |3       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
155         |3      |7       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
156         |3      |8       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
157         |3      |9       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
158         |3      |10      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
159         |3      |17      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
160         |3      |18      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
161         |3      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
162         |3      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
163         |3      |29      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
164         |3      |30      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
165         |3      |31      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
166         |3      |32      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
167         |3      |33      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
168         |3      |34      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
169         |3      |35      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
170         |3      |36      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
171         |3      |39      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
172         |3      |40      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
173         |3      |43      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
174         |3      |48      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
175         |3      |49      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
176         |3      |50      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
177         |3      |52      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
178         |3      |53      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
179         |3      |54      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
180         |3      |55      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
181         |3      |56      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
182         |3      |61      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
183         |3      |62      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
184         |3      |85      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
185         |3      |86      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
186         |3      |87      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
187         |3      |88      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
188         |3      |89      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
189         |3      |90      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
190         |3      |91      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
191         |3      |92      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
192         |3      |93      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
193         |3      |94      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
194         |3      |95      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
195         |3      |96      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
196         |3      |97      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
197         |3      |101     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
198         |3      |102     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
199         |3      |103     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
200         |3      |104     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
201         |3      |105     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
202         |3      |106     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
203         |3      |107     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
204         |3      |111     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
205         |3      |113     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
206         |3      |114     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
207         |3      |115     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
208         |3      |116     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
209         |3      |117     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
210         |3      |118     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
211         |3      |119     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
212         |3      |120     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
213         |3      |121     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
214         |3      |122     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
215         |3      |123     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
216         |3      |124     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
217         |3      |125     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
218         |3      |126     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
219         |3      |127     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
220         |3      |128     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
221         |3      |129     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
222         |3      |130     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
223         |3      |131     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
224         |3      |132     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
225         |3      |133     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
226         |3      |134     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
227         |3      |135     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
228         |3      |136     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
229         |3      |137     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
230         |3      |138     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
231         |3      |139     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
232         |3      |140     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
233         |3      |141     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
234         |3      |142     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
235         |3      |143     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
236         |3      |144     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
237         |3      |145     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
238         |3      |146     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
239         |3      |147     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
240         |3      |148     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
241         |3      |149     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
242         |3      |150     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
243         |3      |151     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.877 -04:00 |NULL                |NULL       
244         |4      |3       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
245         |4      |7       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
246         |4      |8       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
247         |4      |9       |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
248         |4      |17      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
249         |4      |18      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
250         |4      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
251         |4      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
252         |4      |29      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
253         |4      |30      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
254         |4      |31      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
255         |4      |32      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
256         |4      |33      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
257         |4      |34      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
258         |4      |35      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
259         |4      |36      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
260         |4      |37      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
261         |4      |38      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
262         |4      |39      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
263         |4      |40      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
264         |4      |41      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
265         |4      |42      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
266         |4      |43      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
267         |4      |44      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
268         |4      |45      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
269         |4      |46      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
270         |4      |47      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
271         |4      |48      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
272         |4      |49      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
273         |4      |50      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
274         |4      |51      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
275         |4      |52      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
276         |4      |53      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
277         |4      |54      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
278         |4      |55      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
279         |4      |56      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
280         |4      |57      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
281         |4      |58      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
282         |4      |59      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
283         |4      |60      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
284         |4      |61      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
285         |4      |62      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
286         |4      |63      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
287         |4      |64      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
288         |4      |65      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
289         |4      |66      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
290         |4      |67      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
291         |4      |68      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
292         |4      |69      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
293         |4      |70      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
294         |4      |71      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
295         |4      |72      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
296         |4      |73      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
297         |4      |74      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
298         |4      |75      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
299         |4      |76      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
300         |4      |77      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
301         |4      |78      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
302         |4      |79      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
303         |4      |80      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
304         |4      |81      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
305         |4      |82      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
306         |4      |83      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
307         |4      |84      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
308         |4      |85      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
309         |4      |86      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
310         |4      |87      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
311         |4      |88      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
312         |4      |89      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
313         |4      |90      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
314         |4      |91      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
315         |4      |92      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
316         |4      |93      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
317         |4      |94      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
318         |4      |95      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
319         |4      |96      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
320         |4      |97      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
321         |4      |98      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
322         |4      |99      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
323         |4      |100     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
324         |4      |101     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
325         |4      |102     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
326         |4      |103     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
327         |4      |104     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
328         |4      |105     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
329         |4      |106     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
330         |4      |107     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
331         |4      |108     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
332         |4      |109     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
333         |4      |110     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
334         |4      |111     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
335         |4      |112     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
336         |4      |113     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
337         |4      |114     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
338         |4      |115     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
339         |4      |116     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
340         |4      |117     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
341         |4      |118     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
342         |4      |119     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
343         |4      |120     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
344         |4      |121     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
345         |4      |130     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
346         |4      |131     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
347         |4      |132     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
348         |4      |133     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
349         |4      |134     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
350         |4      |135     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
351         |4      |136     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
352         |4      |137     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
353         |4      |138     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
354         |4      |139     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
355         |4      |140     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
356         |4      |141     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
357         |4      |142     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
358         |4      |143     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
359         |4      |144     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
360         |4      |145     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
361         |4      |146     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
362         |4      |147     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
363         |4      |148     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
364         |4      |149     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
365         |4      |150     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
366         |4      |151     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.885 -04:00 |NULL                |NULL       
367         |5      |85      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
368         |5      |86      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
369         |5      |87      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
370         |5      |88      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
371         |5      |89      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
372         |5      |90      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
373         |5      |91      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
374         |5      |92      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
375         |5      |93      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
376         |5      |63      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
377         |5      |64      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
378         |5      |71      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
379         |5      |75      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
380         |5      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
381         |5      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
382         |5      |30      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
383         |5      |39      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
384         |5      |48      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
385         |5      |52      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
386         |5      |55      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
387         |5      |17      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
388         |5      |19      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.893 -04:00 |NULL                |NULL       
389         |6      |94      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
390         |6      |95      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
391         |6      |96      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
392         |6      |97      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
393         |6      |100     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
394         |6      |101     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
395         |6      |103     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
396         |6      |104     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
397         |6      |105     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
398         |6      |106     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
399         |6      |63      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
400         |6      |68      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
401         |6      |72      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
402         |6      |73      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
403         |6      |74      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
404         |6      |77      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
405         |6      |114     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
406         |6      |115     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
407         |6      |116     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
408         |6      |117     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
409         |6      |118     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
410         |6      |119     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
411         |6      |121     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
412         |6      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
413         |6      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
414         |6      |29      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
415         |6      |43      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
416         |6      |107     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
417         |6      |110     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.896 -04:00 |NULL                |NULL       
418         |7      |48      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
419         |7      |49      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
420         |7      |50      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
421         |7      |51      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
422         |7      |52      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
423         |7      |53      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
424         |7      |54      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
425         |7      |55      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
426         |7      |56      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
427         |7      |57      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
428         |7      |58      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
429         |7      |59      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
430         |7      |60      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
431         |7      |61      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
432         |7      |62      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
433         |7      |63      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
434         |7      |64      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
435         |7      |65      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
436         |7      |66      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
437         |7      |67      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
438         |7      |69      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
439         |7      |70      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
440         |7      |71      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
441         |7      |75      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
442         |7      |76      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
443         |7      |78      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
444         |7      |79      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
445         |7      |80      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
446         |7      |81      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
447         |7      |82      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
448         |7      |83      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
449         |7      |84      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
450         |7      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
451         |7      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
452         |7      |40      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
453         |7      |41      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
454         |7      |130     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
455         |7      |132     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
456         |7      |138     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
457         |7      |139     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
458         |7      |140     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
459         |7      |141     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.902 -04:00 |NULL                |NULL       
460         |8      |94      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
461         |8      |95      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
462         |8      |96      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
463         |8      |97      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
464         |8      |100     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
465         |8      |103     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
466         |8      |105     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
467         |8      |106     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
468         |8      |63      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
469         |8      |68      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
470         |8      |107     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
471         |8      |108     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
472         |8      |109     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
473         |8      |110     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
474         |8      |111     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
475         |8      |112     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
476         |8      |113     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
477         |8      |117     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
478         |8      |118     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
479         |8      |119     |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
480         |8      |27      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
481         |8      |28      |1000      |2                   |NULL                     |NULL            |2026-09-10 00:18:45.906 -04:00 |NULL                |NULL       
482         |9      |1       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
483         |9      |2       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
484         |9      |3       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
485         |9      |4       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
486         |9      |5       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
487         |9      |6       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
488         |9      |7       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
489         |9      |8       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
490         |9      |9       |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
491         |9      |10      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
492         |9      |11      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
493         |9      |12      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
494         |9      |13      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
495         |9      |14      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
496         |9      |15      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
497         |9      |16      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
498         |9      |17      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
499         |9      |18      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
500         |9      |19      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
501         |9      |20      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
502         |9      |21      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
503         |9      |22      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
504         |9      |23      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
505         |9      |24      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
506         |9      |25      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
507         |9      |26      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
508         |9      |27      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
509         |9      |28      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
510         |9      |29      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
511         |9      |30      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
512         |9      |31      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
513         |9      |32      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
514         |9      |33      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
515         |9      |34      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
516         |9      |35      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
517         |9      |36      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
518         |9      |37      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
519         |9      |38      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
520         |9      |39      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
521         |9      |40      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
522         |9      |41      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
523         |9      |42      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
524         |9      |43      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
525         |9      |44      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
526         |9      |45      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
527         |9      |46      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
528         |9      |47      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
529         |9      |48      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
530         |9      |49      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
531         |9      |50      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
532         |9      |51      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
533         |9      |52      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
534         |9      |53      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
535         |9      |54      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
536         |9      |55      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
537         |9      |56      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
538         |9      |57      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
539         |9      |58      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
540         |9      |59      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
541         |9      |60      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
542         |9      |61      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
543         |9      |62      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
544         |9      |63      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
545         |9      |64      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
546         |9      |65      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
547         |9      |66      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
548         |9      |67      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
549         |9      |68      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
550         |9      |69      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
551         |9      |70      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
552         |9      |71      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
553         |9      |72      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
554         |9      |73      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
555         |9      |74      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
556         |9      |75      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
557         |9      |76      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
558         |9      |77      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
559         |9      |78      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
560         |9      |79      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
561         |9      |80      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
562         |9      |81      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
563         |9      |82      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
564         |9      |83      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
565         |9      |84      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
566         |9      |85      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
567         |9      |86      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
568         |9      |87      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
569         |9      |88      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
570         |9      |89      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
571         |9      |90      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
572         |9      |91      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
573         |9      |92      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
574         |9      |93      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
575         |9      |94      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
576         |9      |95      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
577         |9      |96      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
578         |9      |97      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
579         |9      |98      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
580         |9      |99      |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
581         |9      |100     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
582         |9      |101     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
583         |9      |102     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
584         |9      |103     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
585         |9      |104     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
586         |9      |105     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
587         |9      |106     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
588         |9      |107     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
589         |9      |108     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
590         |9      |109     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
591         |9      |110     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
592         |9      |111     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
593         |9      |112     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
594         |9      |113     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
595         |9      |114     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
596         |9      |115     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
597         |9      |116     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
598         |9      |117     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
599         |9      |118     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
600         |9      |119     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
601         |9      |120     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
602         |9      |121     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
603         |9      |122     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
604         |9      |123     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
605         |9      |124     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
606         |9      |125     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
607         |9      |126     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
608         |9      |127     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
609         |9      |128     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
610         |9      |129     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
611         |9      |130     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
612         |9      |131     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
613         |9      |132     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
614         |9      |133     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
615         |9      |134     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
616         |9      |135     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
617         |9      |136     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
618         |9      |137     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
619         |9      |138     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
620         |9      |139     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
621         |9      |140     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
622         |9      |141     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
623         |9      |142     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
624         |9      |143     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
625         |9      |144     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
626         |9      |145     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
627         |9      |146     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
628         |9      |147     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
629         |9      |148     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
630         |9      |149     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
631         |9      |150     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
632         |9      |151     |1000      |1                   |NULL                     |NULL            |2026-09-13 23:10:22.131 -04:00 |NULL                |NULL       
------------+-------+--------+----------+--------------------+-------------------------+----------------+-------------------------------+--------------------+-----------
Total de filas: 632


