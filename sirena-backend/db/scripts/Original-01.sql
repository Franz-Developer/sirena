### LISTAR TODOS (Activos + Históricos por defecto)
GET {{baseUrl_empresas_cuentas}}?empresa_id=2&banco_id=2&tipo_moneda_id=2300&tipo_cuenta_id=1750
Authorization: Bearer {{authToken}}

SALE 
findAll - empresas_cuentas
════════════════════════════════════════════════════════════════════════════════

                SELECT
                    t.*
                    
                , CASE t.estado_id
                    WHEN 1000 THEN 'ACTIVO'
WHEN 1001 THEN 'BORRADO'
WHEN 1002 THEN 'HISTORICO'
WHEN 1003 THEN 'ANULADO'
                  END AS estado_registro
            
                    , e.empresa AS empresa_nombre, e.codigo AS empresa_codigo, b.banco AS banco_nombre, b.codigo_asfi AS banco_codigo_asfi, b.abreviatura AS banco_abreviatura,
                    fn_obtener_login_para_operacion('empresas_cuentas', 10000, t.empresa_cuenta_id) AS usuario_operacion
                FROM empresas_cuentas t
                 INNER JOIN empresas e ON e.empresa_id = t.empresa_id AND e.estado_id IN (1000, 1002, 1003) INNER JOIN bancos b ON b.banco_id = t.banco_id AND b.estado_id IN (1000, 1002, 1003)
                
            WHERE 1=1
            AND t.empresa_cuenta_id > 1
            AND t.estado_id IN (
                $1, 1002, 1003
            )
        
            AND (
                t.fecha_registro >= '2026-01-01T04:00:00.000Z'
                OR (
                    t.fecha_actualizacion IS NOT NULL
                    AND t.fecha_actualizacion >= $4
                )
            )
         AND t.empresa_id = 2 AND t.banco_id = 2 AND t.tipo_moneda_id = 2300 AND t.tipo_cuenta_id = 1750
		 AND t.fecha_inicio_vigencia_desde >= '2026-01-01'
		 AND t.fecha_inicio_vigencia_hasta >= '2026-02-01'
                ORDER BY "t"."empresa_cuenta_id" DESC
                LIMIT 10 OFFSET 0
   