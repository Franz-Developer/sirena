-- ================================================================================================

DO $$ 
DECLARE 
    r RECORD;
BEGIN
    SET session_replication_role = replica;
    
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
    
    FOR r IN (SELECT sequencename FROM pg_sequences WHERE schemaname = 'public')
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || quote_ident(r.sequencename) || ' RESTART WITH 1';
    END LOOP;
    
    SET session_replication_role = origin;
    
    RAISE NOTICE '✅ Todas las tablas limpiadas y secuencias reiniciadas';
END $$;

-- ================================================================================================

DELETE FROM bancos;
ALTER SEQUENCE bancos_banco_id_seq RESTART WITH 1;

INSERT INTO bancos (banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', '99', 'NIN', 1000, 1),
(2, 'BANCO NACIONAL DE BOLIVIA S.A.', '01', 'BNB', 1000, 2),
(3, 'BANCO MERCANTIL SANTA CRUZ S.A.', '02', 'BMSC', 1000, 2),
(4, 'BANCO BISA S.A.', '03', 'BISA', 1000, 2),
(5, 'BANCO DE CREDITO DE BOLIVIA S.A.', '04', 'BCB', 1000, 2),
(6, 'BANCO ECONOMICO S.A.', '05', 'BEC', 1000, 2),
(7, 'BANCO GANADERO S.A.', '06', 'BGA', 1000, 2),
(8, 'BANCO SOLIDARIO S.A.', '07', 'BSO', 1000, 2),
(9, 'BANCO UNION S.A.', '08', 'BUN', 1000, 2),
(10, 'BANCO FIE S.A.', '09', 'FIE', 1000, 2),
(11, 'BANCO PRODEM S.A.', '10', 'PRD', 1000, 2),
(12, 'BANCO PYME ECOFUTURO S.A.', '11', 'ECO', 1000, 2),
(13, 'BANCO PYME DE LA COMUNIDAD S.A.', '12', 'BCO', 1000, 2);

UPDATE bancos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE bancos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

-- ================================================================================================

DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro) VALUES
(1, 2300, 2301, 1.0000, 1.0000, '2099-12-31', 1000, 1);

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro)
SELECT -
    ROW_NUMBER() OVER (ORDER BY fecha) + 1 AS tipo_cambio_id,
    2300 AS origen_moneda_id,
    2301 AS destino_moneda_id,
    6.8600 AS factor_compra,
    6.9600 AS factor_venta,
    fecha::date AS fecha_cotizacion,
    1000 AS estado_id,
    1 AS usuario_id_registro
FROM generate_series('2026-07-01'::date, '2026-12-31'::date, '1 day'::interval) AS fecha;

UPDATE tipos_cambios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_cambios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 0), (SELECT COUNT(*) > 0 FROM tipos_cambios));

-- ================================================================================================

DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.jpg', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@gmail.com', 'MAT-000', 1000, 1),
(2, 'FARMACIA SALUD Y VIDA S.R.L.', '309', '2.jpg', 'Tu salud es nuestra prioridad', 'Venta de medicamentos', 'LA PAZ - BOLIVIA', 'JUAN PEREZ FLORES', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '22441122', 'central@saludyvida.com.bo', 'M-356981', 1000, 2);

UPDATE empresas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_empresa_id_seq', COALESCE((SELECT MAX(empresa_id) FROM empresas), 0), (SELECT COUNT(*) > 0 FROM empresas));

-- ================================================================================================

DELETE FROM empresas_nits;
ALTER SEQUENCE empresas_nits_empresa_nit_id_seq RESTART WITH 1;

INSERT INTO empresas_nits (empresa_nit_id, empresa_id, ambiente_id, nit, razon_social, actividad_economica_principal, etiqueta, modalidad_facturacion_id, certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id, usuario_id_registro) VALUES
(1, 1, 2751, '0000000', 'NINGUNO', 'NINGUNA', 'NINGUNO', 3900, NULL, NULL, NULL, NULL, NULL, 'ninguno@ninguno.com', 1000, 1),
(2, 2, 2750, '123456789', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE MEDICAMENTOS EN GENERAL', 'MEDICAMENTOS', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'ventas@saludyvida.com.bo', 1000, 2),
(3, 2, 2750, '987654321', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE JUGUETES Y ARTICULOS RECREATIVOS', 'JUGUETES', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'juguetes@saludyvida.com.bo', 1000, 2),
(4, 2, 2750, '456789123', 'FARMACIA SALUD Y VIDA S.R.L.', 'SERVICIOS MEDICOS Y CONSULTAS', 'MEDICOS', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'servicios@saludyvida.com.bo', 1000, 2),
(5, 2, 2750, '789123456', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE EQUIPOS ELECTRONICOS Y DISPOSITIVOS', 'ELECTRONICA', 3902, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'electronicos@saludyvida.com.bo', 1000, 2),
(6, 2, 2751, '321654987', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE MATERIAL DE ESCRITORIO Y SUMINISTROS DE OFICINA', 'ESCRITORIO', 3900, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'escritorio@saludyvida.com.bo', 1000, 2);

UPDATE empresas_nits SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_nits SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_nits_empresa_nit_id_seq', COALESCE((SELECT MAX(empresa_nit_id) FROM empresas_nits), 0), (SELECT COUNT(*) > 0 FROM empresas_nits));

-- ================================================================================================

DELETE FROM empresas_cuentas;
ALTER SEQUENCE empresas_cuentas_empresa_cuenta_id_seq RESTART WITH 1;

INSERT INTO empresas_cuentas (empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 2300, '0000000000', 1755, 'NINGUNO', 1000, 1),
(2, 2, 2, 2300, '1000001234', 1750, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2),
(3, 2, 5, 2300, '4000003456', 1751, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2),
(4, 2, 4, 2301, '3000005678', 1751, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2);

UPDATE empresas_cuentas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_cuentas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_cuentas_empresa_cuenta_id_seq', COALESCE((SELECT MAX(empresa_cuenta_id) FROM empresas_cuentas), 0), (SELECT COUNT(*) > 0 FROM empresas_cuentas));

-- ================================================================================================

DELETE FROM sucursales;
ALTER SEQUENCE sucursales_sucursal_id_seq RESTART WITH 1;

INSERT INTO sucursales (sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', 'NIN', 0, '00000000', 'DIRECCION NINGUNA', '00:00 - 00:00', 1.50, 1.19, 1000, 1),
(2, 2, 'CASA MATRIZ - SOPOCACHI', 'FARMACIA SALUD Y VIDA - CASA MATRIZ SOPOCACHI', 'FSM', 0, '22441122', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '08:00 - 22:00', 1.50, 1.19, 1000, 2),
(3, 2, 'SUCURSAL ZONA SUR', 'FARMACIA SALUD Y VIDA - SUCURSAL ZONA SUR CALACOTO', 'FSZ', 1, '22774433', 'AV. BALLIVIAN NRO. 540, CALACOTO, LA PAZ', '08:00 - 23:00', 1.50, 1.19, 1000, 2);

UPDATE sucursales SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE sucursales SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('sucursales_sucursal_id_seq', COALESCE((SELECT MAX(sucursal_id) FROM sucursales), 0), (SELECT COUNT(*) > 0 FROM sucursales));

-- ================================================================================================

DELETE FROM puntos_venta;
ALTER SEQUENCE puntos_venta_punto_venta_id_seq RESTART WITH 1;

INSERT INTO puntos_venta (punto_venta_id, sucursal_id, codigo_punto_venta, descripcion, tipo_punto_venta_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0, 'NINGUNO', 3950, 1000, 1),
(2, 2, 0, 'CAJA PRINCIPAL - SOPOCACHI', 3951, 1000, 2),
(3, 2, 1, 'CAJA SECUNDARIA - SOPOCACHI', 3951, 1000, 2),
(4, 3, 0, 'CAJA PRINCIPAL - ZONA SUR', 3951, 1000, 2);

UPDATE puntos_venta SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE puntos_venta SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('puntos_venta_punto_venta_id_seq', COALESCE((SELECT MAX(punto_venta_id) FROM puntos_venta), 0), (SELECT COUNT(*) > 0 FROM puntos_venta));

-- ================================================================================================

DELETE FROM cuis;
ALTER SEQUENCE cuis_cuis_id_seq RESTART WITH 1;

INSERT INTO cuis (cuis_id, sucursal_id, punto_venta_id, codigo_cuis, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1),
(2, 2, 2, 'CUIS-FSM-001', '2027-12-31 23:59:59-04', 1000, 2),
(3, 2, 3, 'CUIS-FSM-002', '2027-12-31 23:59:59-04', 1000, 2),
(4, 3, 4, 'CUIS-FSZ-001', '2027-12-31 23:59:59-04', 1000, 2);

UPDATE cuis SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cuis SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cuis_cuis_id_seq', COALESCE((SELECT MAX(cuis_id) FROM cuis), 0), (SELECT COUNT(*) > 0 FROM cuis));

-- ================================================================================================

DELETE FROM cufd;
ALTER SEQUENCE cufd_cufd_id_seq RESTART WITH 1;

INSERT INTO cufd (cufd_id, sucursal_id, punto_venta_id, codigo_cufd, codigo_control, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1),
(2, 2, 2, 'CUFD-FSM-001', 'CTRL-FSM-001', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2),
(3, 2, 3, 'CUFD-FSM-002', 'CTRL-FSM-002', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2),
(4, 3, 4, 'CUFD-FSZ-001', 'CTRL-FSZ-001', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2);

UPDATE cufd SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cufd SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cufd_cufd_id_seq', COALESCE((SELECT MAX(cufd_id) FROM cufd), 0), (SELECT COUNT(*) > 0 FROM cufd));

-- ================================================================================================

DELETE FROM unidades;
ALTER SEQUENCE unidades_unidad_id_seq RESTART WITH 1;

INSERT INTO unidades (unidad_id, codigo, codigo_sin, unidad, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 0, 'NINGUNA', 1000, 1),
(2, 'KG', 1, 'KILOGRAMO', 1000, 2),
(3, 'G', 2, 'GRAMO', 1000, 2),
(4, 'T', 3, 'TONELADA', 1000, 2),
(5, 'L', 4, 'LITRO', 1000, 2),
(6, 'ML', 5, 'MILILITRO', 1000, 2),
(7, 'M', 6, 'METRO', 1000, 2),
(8, 'CM', 7, 'CENTÍMETRO', 1000, 2),
(9, 'U', 58, 'UNIDAD', 1000, 2),
(10, 'PZ', 58, 'PIEZA', 1000, 2),
(11, 'CJ', 58, 'CAJA', 1000, 2),
(12, 'PQ', 58, 'PAQUETE', 1000, 2);

UPDATE unidades SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE unidades SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('unidades_unidad_id_seq', COALESCE((SELECT MAX(unidad_id) FROM unidades), 0), (SELECT COUNT(*) > 0 FROM unidades));

-- ================================================================================================

DELETE FROM almacenes;
ALTER SEQUENCE almacenes_almacen_id_seq RESTART WITH 1;

INSERT INTO almacenes (almacen_id, sucursal_id, almacen, codigo, tipo_almacen_id, tipo_operacion_almacen_id, descripcion, temperatura_min, temperatura_max, humedad_min, humedad_max, unidad_temperatura_id, unidad_humedad_id, estado_id, usuario_id_registro) VALUES 
(1, 1, 'NINGUNO', 'NIN', 1700, 4050, 'ALMACEN COMODIN', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 1),
(2, 2, 'ALMACEN PRINCIPAL', 'ALM-FSM-01', 1700, 4051, 'ALMACEN GENERAL DE MEDICAMENTOS - VENTA DIRECTA', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(3, 2, 'REFRIGERADOS', 'REF-FSM-01', 1701, 4051, 'ALMACEN DE PRODUCTOS REFRIGERADOS (2°C A 8°C)', 2.00, 8.00, NULL, NULL, 4850, 4900, 1000, 2),
(4, 2, 'CONGELADOS', 'CON-FSM-01', 1702, 4051, 'ALMACEN DE PRODUCTOS CONGELADOS (-18°C O MENOR)', -18.00, -18.00, NULL, NULL, 4850, 4900, 1000, 2),
(5, 2, 'JUGUETES Y RECREATIVOS', 'JUG-FSM-01', 1700, 4051, 'ALMACEN DE JUGUETES Y ARTICULOS RECREATIVOS', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(6, 2, 'EQUIPOS ELECTRONICOS', 'ELE-FSM-01', 1700, 4051, 'ALMACEN DE EQUIPOS ELECTRONICOS Y DISPOSITIVOS', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(7, 2, 'MATERIAL DE ESCRITORIO', 'MAT-FSM-01', 1700, 4051, 'ALMACEN DE MATERIAL DE ESCRITORIO Y SUMINISTROS', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(8, 2, 'RECEPCION', 'REC-FSM-01', 1709, 4050, 'ZONA DE RECEPCION DE MERCANCIAS', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(9, 2, 'DESPACHO', 'DES-FSM-01', 1711, 4050, 'ZONA DE PREPARACION Y DESPACHO DE PEDIDOS', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(10, 3, 'ALMACEN PRINCIPAL', 'ALM-FSZ-01', 1700, 4051, 'ALMACEN GENERAL DE MEDICAMENTOS - ZONA SUR', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2),
(11, 3, 'REFRIGERADOS', 'REF-FSZ-01', 1701, 4051, 'ALMACEN DE PRODUCTOS REFRIGERADOS ZONA SUR', 2.00, 8.00, NULL, NULL, 4850, 4900, 1000, 2),
(12, 3, 'JUGUETES Y RECREATIVOS', 'JUG-FSZ-01', 1700, 4051, 'ALMACEN DE JUGUETES Y ARTICULOS RECREATIVOS ZONA SUR', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 2);

UPDATE almacenes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_almacen_id_seq', COALESCE((SELECT MAX(almacen_id) FROM almacenes), 0), (SELECT COUNT(*) > 0 FROM almacenes));

-- ================================================================================================

DELETE FROM ubicaciones;
ALTER SEQUENCE ubicaciones_ubicacion_id_seq RESTART WITH 1;

INSERT INTO ubicaciones (ubicacion_id, almacen_id, unidad_id, codigo, jerarquia, descripcion, capacidad_maxima, stock_actual, umbral_minimo, metadata, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NIN', '{"simplificado": true, "valor": "COMODIN", "camino": "COMODIN"}'::jsonb, 'UBICACION COMODIN', 0.00, 0.00, 0.00, NULL, 1000, 1),
(2, 2, 10, 'EST-A01', '{"niveles": [{"tipo": "PASILLO", "valor": "A"}, {"tipo": "ESTANTERIA", "valor": "01"}, {"tipo": "NIVEL", "valor": "1"}], "camino": "PASILLO A > ESTANTERIA 01 > NIVEL 1"}'::jsonb, 'ESTANTERIA PRINCIPAL - PASILLO A', 500.00, 0.00, 50.00, NULL, 1000, 2),
(3, 2, 10, 'EST-A02', '{"niveles": [{"tipo": "PASILLO", "valor": "A"}, {"tipo": "ESTANTERIA", "valor": "02"}, {"tipo": "NIVEL", "valor": "2"}], "camino": "PASILLO A > ESTANTERIA 02 > NIVEL 2"}'::jsonb, 'ESTANTERIA SECUNDARIA - PASILLO A', 500.00, 0.00, 50.00, NULL, 1000, 2),
(4, 2, 10, 'EST-B01', '{"niveles": [{"tipo": "PASILLO", "valor": "B"}, {"tipo": "ESTANTERIA", "valor": "01"}, {"tipo": "NIVEL", "valor": "1"}], "camino": "PASILLO B > ESTANTERIA 01 > NIVEL 1"}'::jsonb, 'ESTANTERIA PRINCIPAL - PASILLO B', 500.00, 0.00, 50.00, NULL, 1000, 2),
(5, 2, 10, 'EST-B02', '{"niveles": [{"tipo": "PASILLO", "valor": "B"}, {"tipo": "ESTANTERIA", "valor": "02"}, {"tipo": "NIVEL", "valor": "2"}], "camino": "PASILLO B > ESTANTERIA 02 > NIVEL 2"}'::jsonb, 'ESTANTERIA SECUNDARIA - PASILLO B', 500.00, 0.00, 50.00, NULL, 1000, 2),
(6, 3, 10, 'REF-01', '{"niveles": [{"tipo": "REFRIGERADOR", "valor": "REF-01"}, {"tipo": "BANDEJA", "valor": "1"}, {"tipo": "POSICION", "valor": "A"}], "camino": "REFRIGERADOR REF-01 > BANDEJA 1 > POSICION A"}'::jsonb, 'REFRIGERADOR 1 - BANDEJA 1', 100.00, 0.00, 20.00, '{"temperatura_min": 2, "temperatura_max": 8}'::jsonb, 1000, 2),
(7, 3, 10, 'REF-02', '{"niveles": [{"tipo": "REFRIGERADOR", "valor": "REF-02"}, {"tipo": "BANDEJA", "valor": "2"}, {"tipo": "POSICION", "valor": "B"}], "camino": "REFRIGERADOR REF-02 > BANDEJA 2 > POSICION B"}'::jsonb, 'REFRIGERADOR 2 - BANDEJA 2', 100.00, 0.00, 20.00, '{"temperatura_min": 2, "temperatura_max": 8}'::jsonb, 1000, 2),
(8, 4, 10, 'CON-01', '{"niveles": [{"tipo": "CONGELADOR", "valor": "CON-01"}, {"tipo": "BANDEJA", "valor": "1"}], "camino": "CONGELADOR CON-01 > BANDEJA 1"}'::jsonb, 'CONGELADOR 1 - BANDEJA 1', 80.00, 0.00, 10.00, '{"temperatura_min": -18}'::jsonb, 1000, 2),
(9, 4, 10, 'CON-02', '{"niveles": [{"tipo": "CONGELADOR", "valor": "CON-02"}, {"tipo": "BANDEJA", "valor": "2"}], "camino": "CONGELADOR CON-02 > BANDEJA 2"}'::jsonb, 'CONGELADOR 2 - BANDEJA 2', 80.00, 0.00, 10.00, '{"temperatura_min": -18}'::jsonb, 1000, 2),
(10, 5, 10, 'JUG-A01', '{"simplificado": true, "valor": "JUGUETES-A01", "camino": "JUGUETES A01"}'::jsonb, 'ESTANTERIA DE JUGUETES - SECCION A', 300.00, 0.00, 30.00, NULL, 1000, 2),
(11, 5, 10, 'JUG-A02', '{"simplificado": true, "valor": "JUGUETES-A02", "camino": "JUGUETES A02"}'::jsonb, 'ESTANTERIA DE JUGUETES - SECCION B', 300.00, 0.00, 30.00, NULL, 1000, 2),
(12, 6, 10, 'ELE-A01', '{"simplificado": true, "valor": "ELECTRONICOS-A01", "camino": "ELECTRONICOS A01"}'::jsonb, 'ESTANTERIA DE ELECTRONICOS - SECCION A', 200.00, 0.00, 20.00, NULL, 1000, 2),
(13, 6, 10, 'ELE-A02', '{"simplificado": true, "valor": "ELECTRONICOS-A02", "camino": "ELECTRONICOS A02"}'::jsonb, 'ESTANTERIA DE ELECTRONICOS - SECCION B', 200.00, 0.00, 20.00, NULL, 1000, 2),
(14, 7, 10, 'MAT-A01', '{"simplificado": true, "valor": "ESCRITORIO-A01", "camino": "ESCRITORIO A01"}'::jsonb, 'ESTANTERIA DE ESCRITORIO - SECCION A', 300.00, 0.00, 30.00, NULL, 1000, 2),
(15, 7, 10, 'MAT-A02', '{"simplificado": true, "valor": "ESCRITORIO-A02", "camino": "ESCRITORIO A02"}'::jsonb, 'ESTANTERIA DE ESCRITORIO - SECCION B', 300.00, 0.00, 30.00, NULL, 1000, 2),
(16, 10, 10, 'EST-C01', '{"niveles": [{"tipo": "PASILLO", "valor": "C"}, {"tipo": "ESTANTERIA", "valor": "01"}, {"tipo": "NIVEL", "valor": "1"}], "camino": "PASILLO C > ESTANTERIA 01 > NIVEL 1"}'::jsonb, 'ESTANTERIA PRINCIPAL - PASILLO C', 500.00, 0.00, 50.00, NULL, 1000, 2),
(17, 10, 10, 'EST-C02', '{"niveles": [{"tipo": "PASILLO", "valor": "C"}, {"tipo": "ESTANTERIA", "valor": "02"}, {"tipo": "NIVEL", "valor": "2"}], "camino": "PASILLO C > ESTANTERIA 02 > NIVEL 2"}'::jsonb, 'ESTANTERIA SECUNDARIA - PASILLO C', 500.00, 0.00, 50.00, NULL, 1000, 2),
(18, 11, 10, 'REF-Z01', '{"niveles": [{"tipo": "REFRIGERADOR", "valor": "REF-Z01"}, {"tipo": "BANDEJA", "valor": "1"}, {"tipo": "POSICION", "valor": "A"}], "camino": "REFRIGERADOR REF-Z01 > BANDEJA 1 > POSICION A"}'::jsonb, 'REFRIGERADOR ZONA SUR - BANDEJA 1', 100.00, 0.00, 20.00, '{"temperatura_min": 2, "temperatura_max": 8}'::jsonb, 1000, 2),
(19, 12, 10, 'JUG-Z01', '{"simplificado": true, "valor": "JUGUETES-Z01", "camino": "JUGUETES Z01"}'::jsonb, 'ESTANTERIA DE JUGUETES ZONA SUR', 300.00, 0.00, 30.00, NULL, 1000, 2);

UPDATE ubicaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_ubicacion_id_seq', COALESCE((SELECT MAX(ubicacion_id) FROM ubicaciones), 0), (SELECT COUNT(*) > 0 FROM ubicaciones));

-- ================================================================================================

DELETE FROM almacenes_puntos_venta;
ALTER SEQUENCE almacenes_puntos_venta_almacen_punto_venta_id_seq RESTART WITH 1;

INSERT INTO almacenes_puntos_venta (almacen_punto_venta_id, almacen_id, punto_venta_id, prioridad, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1000, 1),
(2, 2, 2, 1, 1, 1000, 2),
(3, 3, 2, 2, 0, 1000, 2),
(4, 4, 2, 3, 0, 1000, 2),
(5, 5, 2, 4, 0, 1000, 2),
(6, 6, 2, 5, 0, 1000, 2),
(7, 7, 2, 6, 0, 1000, 2),
(8, 2, 3, 1, 1, 1000, 2),
(9, 3, 3, 2, 0, 1000, 2),
(10, 4, 3, 3, 0, 1000, 2),
(11, 5, 3, 4, 0, 1000, 2),
(12, 6, 3, 5, 0, 1000, 2),
(13, 7, 3, 6, 0, 1000, 2),
(14, 10, 4, 1, 1, 1000, 2),
(15, 11, 4, 2, 0, 1000, 2),
(16, 12, 4, 3, 0, 1000, 2);

UPDATE almacenes_puntos_venta SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes_puntos_venta SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_puntos_venta_almacen_punto_venta_id_seq', COALESCE((SELECT MAX(almacen_punto_venta_id) FROM almacenes_puntos_venta), 0), (SELECT COUNT(*) > 0 FROM almacenes_puntos_venta));

-- ================================================================================================

DELETE FROM cargos;
ALTER SEQUENCE cargos_cargo_id_seq RESTART WITH 1;

INSERT INTO cargos (cargo_id, cargo, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NIN', 'CARGO COMODIN', 1000, 1),
(2, 'ADMINISTRADOR DEL SISTEMA', 'ADMIN', 'Gestión integral, configuración y control total de la plataforma.', 1000, 2),
(3, 'GERENTE GENERAL', 'GER_GEN', 'Dirección estratégica y toma de decisiones corporativas.', 1000, 2),
(4, 'ADMINISTRADOR DE SUCURSAL', 'ADMIN_SUC', 'Supervisión de inventarios, dispensación y control de almacenes.', 1000, 2),
(5, 'CONTADOR', 'CONT', 'Contabilidad.', 1000, 2),
(6, 'COMPRAS', 'COMP', 'Encargado de compras.', 1000, 2),
(7, 'VENTAS', 'VENT', 'Encargado de ventas.', 1000, 2),
(8, 'INVENTARIO', 'INV', 'Encargado del inventario.', 1000, 2),
(9, 'MENSAJERO', 'MENS', 'Encargado de mensajeria.', 1000, 2);

UPDATE cargos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cargos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cargos_cargo_id_seq', COALESCE((SELECT MAX(cargo_id) FROM cargos), 0), (SELECT COUNT(*) > 0 FROM cargos));

-- ================================================================================================

DELETE FROM trabajadores;
ALTER SEQUENCE trabajadores_trabajador_id_seq RESTART WITH 1;

INSERT INTO trabajadores (trabajador_id, genero_id, estado_civil_id, nombres, paterno, materno, dni, telefono, email, fecha_nacimiento, fecha_contratacion, foto, qr, estado_id, usuario_id_registro) VALUES
(1, 1200, 1250, 'NINGUNO', 'NINGUNO', NULL, '0000000', NULL, NULL, NULL, NULL, '1.jpg', '1.png', 1000, 1),
(2, 1200, 1251, 'FRANZ', 'IBAÑEZ', NULL, '2630198', '60241524', 'franz.ibanez.c@gmail.com', '1980-06-24', NULL, '2.jpg', '2.png', 1000, 2),
(3, 1200, 1250, 'PASCUAL', 'QUISPE', 'HUANCA', '4892014', '70541489', 'pascual.q.h@hotmail.com', '1982-01-27', NULL, '3.png', '3.png', 1000, 2),
(4, 1201, 1301, 'GLADYS', 'ALANOCA', NULL, '3482910', '60241524', 'gladys.alanoca@gmail.com', '1980-06-24', NULL, '4.jpg', '4.png', 1000, 2),
(5, 1201, 1300, 'SILVIA', 'QUISPE', NULL, '6105824', '65201478', 'silvia.quispe@outlook.com', '1976-04-01', NULL, '5.jpg', '5.png', 1000, 2),
(6, 1200, 1250, 'JUAN PABLO', 'HIDALGO', 'HUANCA', '8342915', '71524311', 'jphidalgo.h@gmail.com', '1988-09-15', NULL, '6.jpg', '6.png', 1000, 2),
(7, 1200, 1250, 'MARCELO', 'VARGAS', 'FLORES', '5920147', '72014589', 'marcelovargas.f@hotmail.com', '1985-11-03', NULL, '7.jpg', '7.png', 1000, 2),
(8, 1201, 1301, 'BEATRIZ', 'MENDOZA', 'ROJAS', '12409581', '60112233', 'beatriz.mendoza.r@gmail.com', '1993-03-22', NULL, '8.png', '8.png', 1000, 2),
(9, 1201, 1300, 'CARLA', 'LOPEZ', 'ESTRADA', '7301948', '60581422', 'carla.lopez.e@gmail.com', '1991-05-14', NULL, '9.jpg', '9.png', 1000, 2),
(10, 1200, 1250, 'RODRIGO', 'APAZA', 'MAMANI', '4910283', '70611224', 'rodrigo.apaza@hotmail.com', '1989-12-08', NULL, '10.jpg', '10.png', 1000, 2),
(11, 1200, 1251, 'HECTOR', 'CONDO', 'ALANOCA', '5432109', '71254896', 'hector.condo@gmail.com', '1984-07-19', NULL, '11.jpg', '11.png', 1000, 2),
(12, 1201, 1300, 'PATRICIA', 'CHAVEZ', 'SOLIZ', '6198420', '65124578', 'patricia.chavez@outlook.com', '1995-10-02', NULL, '12.jpg', '12.png', 1000, 2),
(13, 1200, 1250, 'DIEGO', 'PINTO', 'GUTIERREZ', '8412975', '73021456', 'gustavo.pinto@gmail.com', '1992-04-30', NULL, '13.jpg', '13.png', 1000, 2),
(14, 1201, 1300, 'MONICA', 'SILES', 'ORELLANA', '9120843', '60145879', 'monica.siles@hotmail.com', '1990-02-15', NULL, '14.jpg', '14.png', 1000, 2),
(15, 1201, 1301, 'VALERIA', 'RIVERA', 'CRUZ', '3490218', '71954823', 'valeria.rivera.c@gmail.com', '1987-11-25', NULL, '15.png', '15.png', 1000, 2),
(16, 1200, 1250, 'ALEXANDER', 'QUISPE', 'CHOQUE', '7891234', '71589632', 'alexander.quispe@gmail.com', '2000-05-12', NULL, '16.jpg', '16.png', 1000, 2),
(17, 1200, 1250, 'KEVIN', 'MAMANI', 'FLORES', '6547891', '72036541', 'kevin.mamani@hotmail.com', '2002-08-19', NULL, '17.jpg', '17.png', 1000, 2);

UPDATE trabajadores SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE trabajadores SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('trabajadores_trabajador_id_seq', COALESCE((SELECT MAX(trabajador_id) FROM trabajadores), 0), (SELECT COUNT(*) > 0 FROM trabajadores));

-- ================================================================================================

DELETE FROM trabajadores_cargos;
ALTER SEQUENCE trabajadores_cargos_trabajador_cargo_id_seq RESTART WITH 1;

INSERT INTO trabajadores_cargos (trabajador_cargo_id, trabajador_id, cargo_id, sueldo_base, tipo_moneda_id, es_activo, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 8000.00, 2300, 1, 1000, 1),
(2, 3, 4, 6000.00, 2300, 1, 1000, 2),
(3, 4, 5, 5500.00, 2300, 1, 1000, 2),
(4, 5, 4, 6000.00, 2300, 1, 1000, 2),
(5, 6, 7, 3500.00, 2300, 1, 1000, 2),
(6, 7, 8, 4000.00, 2300, 1, 1000, 2),
(7, 8, 8, 4000.00, 2300, 1, 1000, 2),
(8, 9, 7, 3500.00, 2300, 1, 1000, 2),
(9, 10, 8, 4000.00, 2300, 1, 1000, 2),
(10, 11, 8, 4000.00, 2300, 1, 1000, 2),
(11, 12, 6, 4500.00, 2300, 1, 1000, 2),
(12, 13, 7, 3500.00, 2300, 1, 1000, 2),
(13, 14, 8, 4000.00, 2300, 1, 1000, 2),
(14, 15, 3, 15000.00, 2300, 1, 1000, 2),
(15, 16, 9, 3000.00, 2300, 1, 1000, 2),
(16, 17, 9, 3000.00, 2300, 1, 1000, 2);

UPDATE trabajadores_cargos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE trabajadores_cargos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('trabajadores_cargos_trabajador_cargo_id_seq', COALESCE((SELECT MAX(trabajador_cargo_id) FROM trabajadores_cargos), 0), (SELECT COUNT(*) > 0 FROM trabajadores_cargos));

-- ================================================================================================

DELETE FROM roles;
ALTER SEQUENCE roles_rol_id_seq RESTART WITH 1;

INSERT INTO roles (rol_id, codigo, rol, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO DEL SISTEMA', 1000, 1),
(2, 'ADM', 'ADMINISTRADOR', 'Control total de la plataforma sirena acceso a todo, tiene todos los permisos', 1000, 2),
(3, 'GER', 'GERENTE', 'Control y acceso a todos los modulos pero solo de lectura', 1000, 2),
(4, 'SUC', 'ENCARGADO DE SUCURSAL', 'Responsable de la supervision, operaciones y arqueos de una sucursal especifica', 1000, 2),
(5, 'COM', 'COMPRADOR', 'Responsable de la gestion de proveedores, ordenes de compra y adquisiciones', 1000, 2),
(6, 'VEN', 'VENDEDOR', 'Responsable de la atencion a clientes, cotizaciones y registro de ventas', 1000, 2),
(7, 'ALM', 'ALMACENERO', 'Responsable de la recepcion de mercaderia, control de stock, ingresos y salidas de almacen', 1000, 2),
(8, 'CAJ', 'CAJERO', 'Responsable de la recepcion de pagos, facturacion y apertura/cierre de caja chica', 1000, 2);

UPDATE roles SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_rol_id_seq', COALESCE((SELECT MAX(rol_id) FROM roles), 0), (SELECT COUNT(*) > 0 FROM roles));

-- ================================================================================================

DELETE FROM usuarios;
ALTER SEQUENCE usuarios_usuario_id_seq RESTART WITH 1;

INSERT INTO usuarios (usuario_id,trabajador_id,sucursal_id,rol_id,login,contrasena,avatar,estado_id,usuario_id_registro) VALUES
(1,1,1,1,'SISTEMA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','1.png',1000,1),
(2,2,2,2,'ADMIN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','2.png',1000,1),
(3,3,2,4,'PASCUAL','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','3.png',1000,1),
(4,4,2,5,'GLADYS','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','4.png',1000,1),
(5,5,2,4,'SILVIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','5.png',1000,1),
(6,6,2,6,'JUAN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','6.png',1000,1),
(7,7,2,7,'MARCELO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','7.png',1000,1),
(8,8,2,8,'BEATRIZ','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','8.png',1000,1),
(9,9,3,6,'CARLA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','9.png',1000,1),
(10,10,3,8,'RODRIGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','10.png',1000,1),
(11,11,3,7,'HECTOR','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','11.png',1000,1),
(12,12,3,5,'PATRICIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','12.png',1000,1),
(13,13,3,6,'DIEGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','13.png',1000,1),
(14,14,3,7,'MONICA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','14.png',1000,1),
(15,15,2,3,'VALERIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','15.png',1000,1);
	 
UPDATE usuarios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE usuarios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('usuarios_usuario_id_seq', COALESCE((SELECT MAX(usuario_id) FROM usuarios), 0), (SELECT COUNT(*) > 0 FROM usuarios));

-- ================================================================================================

DELETE FROM roles_tablas;
ALTER SEQUENCE roles_tablas_rol_tabla_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - TODOS LOS PERMISOS EN 0
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
VALUES (1, 'ninguno', 0, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: ADMINISTRADOR (rol_id = 2) - PERMISOS GENERALES Y RESTRICCIONES CRÍTICAS APLICADAS
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    2, 
    t.tabla, 
    1, 1, 1, 1, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    1,
    1,
    CASE WHEN t.tabla = 'kardex' THEN '{"crear": [1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070], "editar": [1050,1051], "anular": [1055]}'::jsonb ELSE '{}'::jsonb END,
    1000, 2 
FROM (
    VALUES 
    ('constantes'), ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones')
) AS t(tabla);

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    3, 
    t.tabla, 
    1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2 
FROM (
    VALUES 
    ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones'), ('tablas')
) AS t(tabla);

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - OPERATIVO CON RESTRICCIONES EXCLUSIVAS DE ANULACIÓN/ARCHIVO
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    4, 
    t.tabla, 
    1, 1, 1, 1, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla IN ('kardex', 'ordenes_compra', 'control_facturas') THEN 1 ELSE 0 END, 
    CASE WHEN t.tabla = 'kardex' THEN '{"crear": [1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070], "editar": [1050,1051], "anular": [1055]}'::jsonb ELSE '{}'::jsonb END,
    1000, 2 
FROM (
    VALUES 
    ('constantes'), ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones'), ('tablas')
) AS t(tabla);

-- ROL: COMPRADOR (rol_id = 5) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(5, 'proveedores', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'proveedores_contactos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'proveedores_rating_historico', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1050, 1058], "editar": []}'::jsonb, 1000, 2),
(5, 'ordenes_compra', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'parametros_globales', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'tareas_programadas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'tipos_planes_pago', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'planes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'comprobantes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(5, 'pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2);

-- ROL: VENDEDOR (rol_id = 6) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(6, 'clientes', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'productos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1051, 1052, 1059], "editar": [1051]}'::jsonb, 1000, 2),
(6, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'pedidos_online', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'detalles_pedidos_online', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'carritos_compra', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'detalles_carritos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'listas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'precios_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'politicas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'cajas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(6, 'movimientos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2);

-- ROL: ALMACENERO (rol_id = 7) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(7, 'almacenes', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'ubicaciones', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'almacenes_puntos_venta', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'productos_ubicaciones', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1053, 1054, 1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070], "editar": []}'::jsonb, 1000, 2),
(7, 'lotes_productos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'ubicaciones_movimientos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'ubicaciones_historial', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'inventarios_fisicos_detalle', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'inventarios_fisicos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'umbrales_configuracion', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(7, 'analitica_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2);

-- ROL: CAJERO (rol_id = 8) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(8, 'clientes', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1051], "editar": []}'::jsonb, 1000, 2),
(8, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'control_facturas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'comprobantes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'cajas', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'movimientos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'arqueos_detalle', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'bancos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'listas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2),
(8, 'precios_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 2);

UPDATE roles_tablas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles_tablas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_tablas_rol_tabla_id_seq', COALESCE((SELECT MAX(rol_tabla_id) FROM roles_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_tablas));

-- ================================================================================================

DELETE FROM menus;
ALTER SEQUENCE menus_menu_id_seq RESTART WITH 1;

INSERT INTO menus (menu_id, menu_padre_id, titulo, icono, url, orden, estado_id, usuario_id_registro) VALUES
(1, NULL, 'NINGUNO', NULL, NULL, 0, 1000, 1),
(2, NULL, 'CONFIGURACIÓN Y SISTEMA', 'pi pi-cog', NULL, 1, 1000, 2),
(3, 2, 'DATOS DE LA EMPRESA', 'pi pi-building', '/configuracion/empresa', 1, 1000, 2),
(4, 2, 'GESTIÓN DE NITS Y AUTORIZACIONES', 'pi pi-id-card', '/configuracion/nits', 2, 1000, 2),
(5, 2, 'CUENTAS BANCARIAS', 'pi pi-credit-card', '/configuracion/cuentas-bancarias', 3, 1000, 2),
(6, 2, 'SUCURSALES Y PUNTOS', 'pi pi-map-marker', '/configuracion/sucursales', 4, 1000, 2),
(7, 2, 'CONTROL DE USUARIOS', 'pi pi-users', '/configuracion/usuarios', 5, 1000, 2),
(8, 2, 'ROLES Y PERMISOS', 'pi pi-key', '/configuracion/roles', 6, 1000, 2),
(9, 2, 'PARÁMETROS GLOBALES', 'pi pi-sliders-h', '/configuracion/parametros', 7, 1000, 2),
(10, 2, 'TASAS DE CAMBIO', 'pi pi-dollar', '/configuracion/tipos-cambio', 8, 1000, 2),
(11, 2, 'TAREAS PROGRAMADAS', 'pi pi-calendar-clock', '/configuracion/tareas', 9, 1000, 2),
(12, 2, 'LOGS DE EJECUCIÓN', 'pi pi-file-code', '/configuracion/logs', 10, 1000, 2),
(13, 2, 'AUDITORÍA DE DATOS', 'pi pi-eye', '/configuracion/auditoria', 11, 1000, 2),
(14, 2, 'RESPALDOS DE DATOS (BACKUP)', 'pi pi-cloud-upload', '/configuracion/backup', 12, 1000, 2),
(15, NULL, 'GESTIÓN DE PRODUCTOS', 'pi pi-box', NULL, 2, 1000, 2),
(16, 15, 'CATÁLOGO DE PRODUCTOS', 'pi pi-shopping-bag', '/productos/catalogo', 1, 1000, 2),
(17, 15, 'CATEGORÍAS', 'pi pi-tags', '/productos/categorias', 2, 1000, 2),
(18, 15, 'LABORATORIOS', 'pi pi-percentage', '/productos/laboratorios', 3, 1000, 2),
(19, 15, 'PRINCIPIOS ACTIVOS', 'pi pi-info-circle', '/productos/principios-activos', 4, 1000, 2),
(20, 15, 'FORMAS FARMACÉUTICAS', 'pi pi-tablet', '/productos/formas', 5, 1000, 2),
(21, 15, 'PRESENTACIONES COMERCIALES', 'pi pi-clone', '/productos/presentaciones', 6, 1000, 2),
(22, 15, 'CONCENTRACIONES', 'pi pi-filter', '/productos/concentraciones', 7, 1000, 2),
(23, 15, 'REGISTROS SANITARIOS', 'pi pi-file', '/productos/registros-sanitarios', 8, 1000, 2),
(24, 15, 'PRODUCTOS CONTROLADOS', 'pi pi-exclamation-circle', '/productos/controlados', 9, 1000, 2),
(25, 15, 'UNIDADES DE MEDIDA', 'pi pi-calculator', '/productos/unidades', 10, 1000, 2),
(26, 15, 'CONVERSIONES DE UNIDAD', 'pi pi-refresh', '/productos/conversiones', 11, 1000, 2),
(27, 15, 'PROMOCIONES Y OFERTAS', 'pi pi-percentage', '/productos/promociones', 12, 1000, 2),
(28, NULL, 'INVENTARIOS Y ALMACENES', 'pi pi-home', NULL, 3, 1000, 2),
(29, 28, 'ALMACENES FÍSICOS', 'pi pi-map', '/inventario/almacenes', 1, 1000, 2),
(30, 28, 'UBICACIONES INTERNAS', 'pi pi-compass', '/inventario/ubicaciones', 2, 1000, 2),
(31, 28, 'MOVIMIENTOS DE KARDEX', 'pi pi-list', '/inventario/kardex', 3, 1000, 2),
(32, 28, 'CONTROL DE LOTES', 'pi pi-barcode', '/inventario/lotes', 4, 1000, 2),
(33, 28, 'TRASPASOS INTER-SUCURSALES', 'pi pi-arrow-h', '/inventario/traspasos', 5, 1000, 2),
(34, 28, 'DISTRIBUCIÓN EN ESTANTERÍAS', 'pi pi-server', '/inventario/productos-ubicaciones', 6, 1000, 2),
(35, NULL, 'COMPRAS Y PROVEEDORES', 'pi pi-shopping-cart', NULL, 4, 1000, 2),
(36, 35, 'REGISTRO DE PROVEEDORES', 'pi pi-truck', '/compras/proveedores', 1, 1000, 2),
(37, 35, 'ÓRDENES Y RECEPCIONES', 'pi pi-plus-circle', '/compras/ordenes', 2, 1000, 2),
(38, 35, 'PLANES DE PAGO Y CRÉDITOS', 'pi pi-calendar', '/compras/planes-pago', 3, 1000, 2),
(39, 35, 'GESTIÓN DE CRÉDITOS A PROVEEDORES', 'pi pi-money-bill', '/compras/pagos', 4, 1000, 2),
(40, NULL, 'VENTAS Y FACTURACIÓN', 'pi pi-wallet', NULL, 5, 1000, 2),
(41, 40, 'PUNTO DE VENTA (POS)', 'pi pi-desktop', '/ventas/pos', 1, 1000, 2),
(42, 40, 'REGISTRO DE CLIENTES', 'pi pi-user-plus', '/ventas/clientes', 2, 1000, 2),
(43, 40, 'DOSIFICACIÓN Y FACTURAS (SIN)', 'pi pi-file-excel', '/ventas/control-facturas', 3, 1000, 2),
(44, 40, 'HISTÓRICO DE DOCUMENTOS', 'pi pi-folder-open', '/ventas/documentos-historicos', 4, 1000, 2),
(45, 40, 'COMPROBANTES DIGITALES / QR', 'pi pi-qrcode', '/ventas/comprobantes', 5, 1000, 2),
(46, NULL, 'GESTIÓN DE CAJA', 'pi pi-percentage', NULL, 6, 1000, 2),
(47, 46, 'APERTURA Y CIERRE', 'pi pi-lock', '/caja/sesiones', 1, 1000, 2),
(48, 46, 'MOVIMIENTOS DE CAJA (VARIOS)', 'pi pi-sort', '/caja/movimientos', 2, 1000, 2),
(49, NULL, 'COMERCIO ELECTRÓNICO Y DELIVERY', 'pi pi-globe', NULL, 7, 1000, 2),
(50, 49, 'PEDIDOS ONLINE', 'pi pi-shopping-bag', '/ecommerce/pedidos', 1, 1000, 2),
(51, 49, 'CARRITOS DE COMPRA', 'pi pi-shopping-cart', '/ecommerce/carritos', 2, 1000, 2),
(52, NULL, 'PRECIOS, COSTOS Y MÁRGENES', 'pi pi-tags', NULL, 8, 1000, 2),
(53, 52, 'LISTAS DE PRECIOS', 'pi pi-list', '/precios/listas', 1, 1000, 2),
(54, 52, 'PRECIOS DE PRODUCTOS', 'pi pi-dollar', '/precios/productos', 2, 1000, 2),
(55, 52, 'COSTOS PROMEDIO', 'pi pi-chart-line', '/precios/costos', 3, 1000, 2),
(56, 52, 'POLÍTICAS DE PRECIOS', 'pi pi-sliders-h', '/precios/politicas', 4, 1000, 2),
(57, NULL, 'RECURSOS HUMANOS', 'pi pi-id-card', NULL, 9, 1000, 2),
(58, 57, 'GESTIÓN DE TRABAJADORES', 'pi pi-users', '/rrhh/trabajadores', 1, 1000, 2),
(59, 57, 'CONTROL DE ASISTENCIAS', 'pi pi-clock', '/rrhh/asistencias', 2, 1000, 2),
(60, 57, 'PLANILLAS DE SUELDOS', 'pi pi-file-pdf', '/rrhh/planillas', 3, 1000, 2),
(61, 57, 'CONTRATOS DE PERSONAL', 'pi pi-briefcase', '/rrhh/contratos', 4, 1000, 2),
(62, NULL, 'NÚCLEO ANALÍTICO Y PREDICCIONES', 'pi pi-android', NULL, 10, 1000, 2),
(63, 62, 'DASHBOARD DE ANALÍTICA CONSOLIDADA', 'pi pi-chart-bar', '/ia/analitica', 1, 1000, 2),
(64, 62, 'MODELOS ML DISPONIBLES', 'pi pi-share-alt', '/ia/modelos', 2, 1000, 2),
(65, 62, 'HISTORIAL DE ENTRENAMIENTOS', 'pi pi-sync', '/ia/entrenamientos', 3, 1000, 2),
(66, 62, 'MÉTRICAS DE RENDIMIENTO', 'pi pi-chart-line', '/ia/metricas', 4, 1000, 2),
(67, 62, 'VARIABLES EXÓGENAS AMBIENTALES', 'pi pi-cloud', '/ia/variables-exogenas', 5, 1000, 2),
(68, 62, 'PATRONES DE CONSUMO ESTACIONAL', 'pi pi-sliders-v', '/ia/patrones-consumo', 6, 1000, 2),
(69, 62, 'CONFIGURACIÓN DE UMBRALES PREDICTIVOS', 'pi pi-cog', '/ia/umbrales', 7, 1000, 2),
(70, NULL, 'NOTIFICACIONES Y ALERTAS', 'pi pi-bell', NULL, 11, 1000, 2),
(71, 70, 'BANDEJA DE NOTIFICACIONES', 'pi pi-inbox', '/alertas/notificaciones', 1, 1000, 2),
(72, 70, 'ALERTAS OPERATIVAS Y CRÍTICAS', 'pi pi-exclamation-triangle', '/alertas/criticas', 2, 1000, 2),
(73, NULL, 'REPORTES Y DIRECCIÓN GERENCIAL', 'pi pi-print', NULL, 12, 1000, 2),
(74, 73, 'CONSOLIDADOR DE REPORTES', 'pi pi-copy', '/reportes/dashboard-unico', 1, 1000, 2),
(75, 73, 'REPORTES DE INVENTARIO Y STOCK', 'pi pi-chart-scatter', '/reportes/inventario', 2, 1000, 2),
(76, 73, 'PANEL DE CONTROL FINANCIERO', 'pi pi-percentage', '/gerencia/reportes-financieros', 3, 1000, 2),
(77, 73, 'HISTORIAL DE COSTOS Y MÁRGENES', 'pi pi-chart-line', '/gerencia/historial-costos', 4, 1000, 2),
(78, 73, 'MONITOR DE ALERTAS DE RIESGO', 'pi pi-bolt', '/gerencia/alertas-criticas', 5, 1000, 2);

UPDATE menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('menus_menu_id_seq', COALESCE((SELECT MAX(menu_id) FROM menus), 0), (SELECT COUNT(*) > 0 FROM menus));

-- ================================================================================================

DELETE FROM roles_menus;
ALTER SEQUENCE roles_menus_rol_menu_id_seq RESTART WITH 1;

INSERT INTO roles_menus (rol_menu_id, rol_id, menu_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1000, 1),
(2, 2, 1, 1000, 2),
(3, 2, 2, 1000, 2),
(4, 2, 3, 1000, 2),
(5, 2, 4, 1000, 2),
(6, 2, 5, 1000, 2),
(7, 2, 6, 1000, 2),
(8, 2, 7, 1000, 2),
(9, 2, 8, 1000, 2),
(10, 2, 9, 1000, 2),
(11, 2, 10, 1000, 2),
(12, 2, 11, 1000, 2),
(13, 2, 12, 1000, 2),
(14, 2, 13, 1000, 2),
(15, 2, 14, 1000, 2),
(16, 2, 15, 1000, 2),
(17, 2, 16, 1000, 2),
(18, 2, 17, 1000, 2),
(19, 2, 18, 1000, 2),
(20, 2, 19, 1000, 2),
(21, 2, 20, 1000, 2),
(22, 2, 21, 1000, 2),
(23, 2, 22, 1000, 2),
(24, 2, 23, 1000, 2),
(25, 2, 24, 1000, 2),
(26, 2, 25, 1000, 2),
(27, 2, 26, 1000, 2),
(28, 2, 27, 1000, 2),
(29, 2, 28, 1000, 2),
(30, 2, 29, 1000, 2),
(31, 2, 30, 1000, 2),
(32, 2, 31, 1000, 2),
(33, 2, 32, 1000, 2),
(34, 2, 33, 1000, 2),
(35, 2, 34, 1000, 2),
(36, 2, 35, 1000, 2),
(37, 2, 36, 1000, 2),
(38, 2, 37, 1000, 2),
(39, 2, 38, 1000, 2),
(40, 2, 39, 1000, 2),
(41, 2, 40, 1000, 2),
(42, 2, 41, 1000, 2),
(43, 2, 42, 1000, 2),
(44, 2, 43, 1000, 2),
(45, 2, 44, 1000, 2),
(46, 2, 45, 1000, 2),
(47, 2, 46, 1000, 2),
(48, 2, 47, 1000, 2),
(49, 2, 48, 1000, 2),
(50, 2, 49, 1000, 2),
(51, 2, 50, 1000, 2),
(52, 2, 51, 1000, 2),
(53, 2, 52, 1000, 2),
(54, 2, 53, 1000, 2),
(55, 2, 54, 1000, 2),
(56, 2, 55, 1000, 2),
(57, 2, 56, 1000, 2),
(58, 2, 57, 1000, 2),
(59, 2, 58, 1000, 2),
(60, 2, 59, 1000, 2),
(61, 2, 60, 1000, 2),
(62, 2, 61, 1000, 2),
(63, 2, 62, 1000, 2),
(64, 2, 63, 1000, 2),
(65, 2, 64, 1000, 2),
(66, 2, 65, 1000, 2),
(67, 2, 66, 1000, 2),
(68, 3, 50, 1000, 2),
(69, 3, 51, 1000, 2),
(70, 3, 61, 1000, 2),
(71, 3, 62, 1000, 2),
(72, 3, 63, 1000, 2),
(73, 3, 64, 1000, 2),
(74, 3, 65, 1000, 2),
(75, 3, 66, 1000, 2),
(76, 6, 40, 1000, 2),
(77, 6, 41, 1000, 2),
(78, 6, 42, 1000, 2),
(79, 6, 44, 1000, 2),
(80, 6, 46, 1000, 2);

UPDATE roles_menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles_menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_menus_rol_menu_id_seq', COALESCE((SELECT MAX(rol_menu_id) FROM roles_menus), 0), (SELECT COUNT(*) > 0 FROM roles_menus));

-- ================================================================================================

DELETE FROM inventarios_fisicos;
ALTER SEQUENCE inventarios_fisicos_inventario_fisico_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos (inventario_fisico_id, sucursal_id, ubicacion_id, fecha_conteo, fecha_inicio, fecha_fin, usuario_registro_id, usuario_supervisor_id, estado_id, observaciones, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, 1, 1, 1000, 'REGISTRO INICIAL COMODIN DE INVENTARIO FISICO', 1),
(2, 2, 2, '2026-07-01', '2026-07-01 08:00:00-04', '2026-07-01 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA PRINCIPAL PASILLO A', 2),
(3, 2, 3, '2026-07-02', '2026-07-02 08:00:00-04', '2026-07-02 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA SECUNDARIA PASILLO A', 2),
(4, 2, 4, '2026-07-03', '2026-07-03 08:00:00-04', '2026-07-03 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA PRINCIPAL PASILLO B', 2),
(5, 2, 5, '2026-07-04', '2026-07-04 08:00:00-04', '2026-07-04 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA SECUNDARIA PASILLO B', 2),
(6, 2, 6, '2026-07-05', '2026-07-05 08:00:00-04', '2026-07-05 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - REFRIGERADOR 1 BANDEJA 1', 2),
(7, 2, 7, '2026-07-06', '2026-07-06 08:00:00-04', '2026-07-06 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - REFRIGERADOR 2 BANDEJA 2', 2),
(8, 2, 8, '2026-07-07', '2026-07-07 08:00:00-04', '2026-07-07 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - CONGELADOR 1 BANDEJA 1', 2),
(9, 2, 9, '2026-07-08', '2026-07-08 08:00:00-04', '2026-07-08 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - CONGELADOR 2 BANDEJA 2', 2),
(10, 2, 10, '2026-07-09', '2026-07-09 08:00:00-04', '2026-07-09 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - JUGUETES SECCION A', 2),
(11, 2, 11, '2026-07-10', '2026-07-10 08:00:00-04', '2026-07-10 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - JUGUETES SECCION B', 2),
(12, 2, 12, '2026-07-11', '2026-07-11 08:00:00-04', '2026-07-11 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ELECTRONICOS SECCION A', 2),
(13, 2, 13, '2026-07-12', '2026-07-12 08:00:00-04', '2026-07-12 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ELECTRONICOS SECCION B', 2),
(14, 2, 14, '2026-07-13', '2026-07-13 08:00:00-04', '2026-07-13 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESCRITORIO SECCION A', 2),
(15, 2, 15, '2026-07-14', '2026-07-14 08:00:00-04', '2026-07-14 17:00:00-04', 2, 3, 1000, 'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESCRITORIO SECCION B', 2),
(16, 3, 16, '2026-07-15', '2026-07-15 08:00:00-04', '2026-07-15 17:00:00-04', 2, 4, 1000, 'INVENTARIO FISICO MENSUAL - ZONA SUR - ESTANTERIA PRINCIPAL PASILLO C', 2),
(17, 3, 17, '2026-07-16', '2026-07-16 08:00:00-04', '2026-07-16 17:00:00-04', 2, 4, 1000, 'INVENTARIO FISICO MENSUAL - ZONA SUR - ESTANTERIA SECUNDARIA PASILLO C', 2),
(18, 3, 18, '2026-07-17', '2026-07-17 08:00:00-04', '2026-07-17 17:00:00-04', 2, 4, 1000, 'INVENTARIO FISICO MENSUAL - ZONA SUR - REFRIGERADOR BANDEJA 1', 2),
(19, 3, 19, '2026-07-18', '2026-07-18 08:00:00-04', '2026-07-18 17:00:00-04', 2, 4, 1000, 'INVENTARIO FISICO MENSUAL - ZONA SUR - JUGUETES', 2);

UPDATE inventarios_fisicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE inventarios_fisicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('inventarios_fisicos_inventario_fisico_id_seq', COALESCE((SELECT MAX(inventario_fisico_id) FROM inventarios_fisicos), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos));

-- ================================================================================================

DELETE FROM clientes;
ALTER SEQUENCE clientes_cliente_id_seq RESTART WITH 1;

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(1, 1150, 'NINGUNO', NULL, NULL, '0', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 1);

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(2, 1151, 'DISTRIBUIDORA FARMA BOLIVIA S.A.', '123456789012', 'DISTRIBUIDORA FARMA BOLIVIA S.A.', '123456789012', NULL, 2204, 'AV. MONTENEGRO NRO. 450, EDIF. BUSINESS CENTER, PISO 3, LA PAZ', '22889977', 'ventas@distribuidorafarma.bo', 3, '4000009876', 1, 25000.00, 1000, 2),
(3, 1151, 'LABORATORIOS BOLIVIANOS S.A.', '987654321098', 'LABORATORIOS BOLIVIANOS S.A.', '987654321098', NULL, 2204, 'CALLE MURILLO NRO. 789, ZONA INDUSTRIAL, EL ALTO, LA PAZ', '22881144', 'administracion@labbol.com.bo', 4, '3000006543', 1, 50000.00, 1000, 2);

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(4, 1150, 'MARIA ELENA GUTIERREZ LOZA', NULL, NULL, '12345678', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(5, 1150, 'JUAN CARLOS MAMANI QUISPE', NULL, NULL, '87654321', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(6, 1150, 'ANA MARIA FLORES TORREZ', NULL, NULL, '23456789', '1A', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(7, 1150, 'LUIS ALBERTO CONDORI CHAMBI', NULL, NULL, '98765432', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(8, 1150, 'CARMEN ROSA QUISPE HUANCA', NULL, NULL, '34567890', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(9, 1150, 'JOSE MANUEL RODRIGUEZ FLORES', NULL, NULL, '10987654', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(10, 1150, 'MARTHA ISABEL MAMANI HUANCA', NULL, NULL, '45678901', '2B', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(11, 1150, 'ROBERTO CARLOS CHAVEZ PINTO', NULL, NULL, '21098765', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(12, 1150, 'GLORIA ESTEFANIA SILES ORELLANA', NULL, NULL, '56789012', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(13, 1150, 'MANUEL JESUS ALANOCA APAZA', NULL, NULL, '32109876', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(14, 1150, 'FABIOLA ANDREA LOPEZ ESTRADA', NULL, NULL, '67890123', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(15, 1150, 'RAUL ANTONIO PINTO GUTIERREZ', NULL, NULL, '43210987', '3C', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(16, 1150, 'VERONICA PATRICIA CONDORI ALANOCA', NULL, NULL, '78901234', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(17, 1150, 'FERNANDO MARCELO HIDALGO HUANCA', NULL, NULL, '54321098', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(18, 1150, 'ALEJANDRA BELEN MENDOZA ROJAS', NULL, NULL, '89012345', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2),
(19, 1150, 'HERNAN ROLANDO VARGAS FLORES', NULL, NULL, '65432109', '4D', 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(20, 1150, 'PAOLA ANDREA QUIROZ CASTRO', NULL, NULL, '90123456', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 2),
(21, 1150, 'RAFAEL ENRIQUE SOLIZ HUANCA', NULL, NULL, '76543210', NULL, 2200, NULL, NULL, NULL, 1, NULL, 0, 0.00, 1000, 2);

UPDATE clientes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE clientes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('clientes_cliente_id_seq', COALESCE((SELECT MAX(cliente_id) FROM clientes), 0), (SELECT COUNT(*) > 0 FROM clientes));

-- ================================================================================================

DELETE FROM categorias;
ALTER SEQUENCE categorias_categoria_id_seq RESTART WITH 1;

INSERT INTO categorias (categoria_id, empresa_nit_id, categoria_padre_id, categoria, codigo, descripcion, nivel, orden, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNA', 'N00', 'Categoría predeterminada para productos sin clasificar', 1, 0, 1000, 1),
(2, 2, NULL, 'MEDICAMENTOS', 'M01', 'Categoría principal para medicamentos en general', 1, 1, 1000, 2),
(3, 3, NULL, 'JUGUETES', 'J02', 'Categoría principal para juguetes y artículos recreativos', 1, 2, 1000, 2),
(4, 4, NULL, 'MEDICOS', 'M03', 'Categoría principal para servicios médicos y consultas', 1, 3, 1000, 2),
(5, 5, NULL, 'ELECTRONICA', 'E04', 'Categoría principal para equipos electrónicos y dispositivos', 1, 4, 1000, 2),
(6, 6, NULL, 'ESCRITORIO', 'E05', 'Categoría principal para material de escritorio y suministros', 1, 5, 1000, 2),
(7, 2, 2, 'ANALGESICOS', 'M0101', 'Subcategoría de analgésicos y antifebriles', 2, 1, 1000, 2),
(8, 2, 2, 'ANTIBIOTICOS', 'M0102', 'Subcategoría de antibióticos y antimicrobianos', 2, 2, 1000, 2),
(9, 2, 2, 'VITAMINAS', 'M0103', 'Subcategoría de vitaminas y suplementos nutricionales', 2, 3, 1000, 2),
(10, 3, 3, 'JUGUETES EDUCATIVOS', 'J0201', 'Subcategoría de juguetes educativos y didácticos', 2, 1, 1000, 2),
(11, 3, 3, 'JUGUETES DE ACCION', 'J0202', 'Subcategoría de figuras de acción y muñecos', 2, 2, 1000, 2),
(12, 3, 3, 'JUEGOS DE MESA', 'J0203', 'Subcategoría de juegos de mesa y destreza', 2, 3, 1000, 2),
(13, 4, 4, 'CONSULTAS', 'M0301', 'Subcategoría de servicios de consulta médica general y especializada', 2, 1, 1000, 2),
(14, 4, 4, 'EXAMENES', 'M0302', 'Subcategoría de exámenes de laboratorio y diagnósticos', 2, 2, 1000, 2),
(15, 5, 5, 'COMPUTACION', 'E0401', 'Subcategoría de computadoras, laptops y accesorios', 2, 1, 1000, 2),
(16, 5, 5, 'TELEFONIA', 'E0402', 'Subcategoría de teléfonos inteligentes y dispositivos móviles', 2, 2, 1000, 2),
(17, 6, 6, 'PAPELERIA', 'E0501', 'Subcategoría de papeles, cuadernos y blocs', 2, 1, 1000, 2),
(18, 6, 6, 'UTILES ESCOLARES', 'E0502', 'Subcategoría de bolígrafos, lápices y borradores', 2, 2, 1000, 2),
(19, 2, 7, 'EN TABLETAS', 'M010101', 'Analgésicos en presentación de tabletas y cápsulas', 3, 1, 1000, 2),
(20, 2, 7, 'EN JARABE', 'M010102', 'Analgésicos en presentación líquida y jarabe', 3, 2, 1000, 2),
(21, 2, 8, 'ORALES', 'M010201', 'Antibióticos de administración oral', 3, 1, 1000, 2),
(22, 2, 8, 'INYECTABLES', 'M010202', 'Antibióticos de administración inyectable', 3, 2, 1000, 2),
(23, 3, 10, 'CIENCIA Y TECNOLOGIA', 'J020101', 'Kits de ciencia, física y tecnología', 3, 1, 1000, 2),
(24, 3, 10, 'ARMO Y CONSTRUYO', 'J020102', 'Bloques para armar y construcción', 3, 2, 1000, 2),
(25, 3, 11, 'SUPERHEROES', 'J020201', 'Figuras y accesorios de superhéroes', 3, 1, 1000, 2),
(26, 3, 11, 'VEHICULOS A ESCALA', 'J020202', 'Carritos, pistas y vehículos', 3, 2, 1000, 2),
(27, 3, 12, 'ESTRATEGIA', 'J020301', 'Juegos de mesa de estrategia y rol', 3, 1, 1000, 2),
(28, 3, 12, 'FAMILIARES', 'J020302', 'Juegos de mesa para toda la familia', 3, 2, 1000, 2),
(29, 5, 15, 'LAPTOPS', 'E040101', 'Computadoras portátiles y notebooks', 3, 1, 1000, 2),
(30, 5, 15, 'ACCESORIOS', 'E040102', 'Teclados, mouses y periféricos', 3, 2, 1000, 2),
(31, 6, 17, 'HOJAS BOND', 'E050101', 'Papel bond tamaño carta y oficio', 3, 1, 1000, 2),
(32, 6, 17, 'CUADERNOS', 'E050102', 'Cuadernos empastados y espiralados', 3, 2, 1000, 2);

UPDATE categorias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE categorias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('categorias_categoria_id_seq', COALESCE((SELECT MAX(categoria_id) FROM categorias), 0), (SELECT COUNT(*) > 0 FROM categorias));

-- ================================================================================================

CREATE TABLE laboratorios (
    laboratorio_id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL,
    laboratorio VARCHAR(200) NOT NULL,
    nit VARCHAR(30) NULL,
    direccion VARCHAR(500) NULL,
    telefono VARCHAR(50) NULL,
    email VARCHAR(100) NULL,
    web VARCHAR(200) NULL,
	estado_id INTEGER NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    fts_laboratorios_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(codigo, ''))), 'B') ||
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(laboratorio, ''))), 'A') ||
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(nit, ''))), 'B') ||
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(direccion, ''))), 'C') ||
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(telefono, ''))), 'C') ||
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(email, ''))), 'B') ||
        setweight(to_tsvector('simple', fn_unaccent_immutable(COALESCE(web, ''))), 'C')
    ) STORED,
	CONSTRAINT chk_laboratorios_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_laboratorios_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_laboratorios_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_laboratorios_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_laboratorios_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_laboratorios_laboratorio_notempty CHECK (TRIM(laboratorio) <> ''),
    CONSTRAINT chk_laboratorios_laboratorio_minlength CHECK (LENGTH(TRIM(laboratorio)) >= 3),
    CONSTRAINT chk_laboratorios_nit_notempty CHECK (nit IS NULL OR TRIM(nit) <> ''),
    CONSTRAINT chk_laboratorios_direccion_notempty CHECK (direccion IS NULL OR TRIM(direccion) <> ''),
    CONSTRAINT chk_laboratorios_telefono_notempty CHECK (telefono IS NULL OR TRIM(telefono) <> ''),
    CONSTRAINT chk_laboratorios_email_formato CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_laboratorios_web_notempty CHECK (web IS NULL OR TRIM(web) <> '')
);
CREATE UNIQUE INDEX uix_laboratorios_codigo_unique ON laboratorios (codigo) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_laboratorios_laboratorio_unique ON laboratorios (laboratorio) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_laboratorios_nit_unique ON laboratorios (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND nit <> '';
CREATE INDEX idx_laboratorios_fts ON laboratorios USING GIN (fts_laboratorios_vector) WHERE fecha_baja IS NULL;

COMMENT ON TABLE laboratorios IS 'Reglas de la tabla - laboratorios
R.0: La tabla laboratorios constituye el catálogo de fabricantes, proveedores o marcas de los productos farmacéuticos y de venta libre. Su función es gestionar la trazabilidad desde el origen del producto, facilitando la organización del catálogo, la aplicación de promociones por marca y la generación de reportes de compras y rentabilidad por laboratorio.
R.1: El registro predeterminado (laboratorio_id = 1, ''NINGUNO'') actúa como la entidad genérica del sistema para la creación obligatoria de productos magistrales, fórmulas propias o artículos de soporte que no correspondan a un fabricante farmacéutico comercial.';

DELETE FROM laboratorios;
ALTER SEQUENCE laboratorios_laboratorio_id_seq RESTART WITH 1;

INSERT INTO laboratorios (laboratorio_id, codigo, laboratorio, nit, direccion, telefono, email, web, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, NULL, NULL, NULL, 1000, 1);

UPDATE laboratorios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE laboratorios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('laboratorios_laboratorio_id_seq', COALESCE((SELECT MAX(laboratorio_id) FROM laboratorios), 0), (SELECT COUNT(*) > 0 FROM laboratorios));


puedes crear 5 laboratorios que parescan reales 

-- ================================================================================================


-- ================================================================================================

-- ================================================================================================


