SELECT rol_id, es_admin, codigo, rol, descripcion, estado_id, usuario_id_registro
FROM roles 
WHERE rol_id = 2
ORDER BY rol_id ASC;
rol_id|es_admin|codigo|rol          |descripcion                                                                  |estado_id|usuario_id_registro|
------+--------+------+-------------+-----------------------------------------------------------------------------+---------+-------------------+
     2|       1|ADM   |ADMINISTRADOR|Control total de la plataforma sirena acceso a todo, tiene todos los permisos|     1000|                  2|
	 
	 