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
    
    RAISE NOTICE 'Todas las tablas limpiadas y secuencias reiniciadas';
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

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

-- ================================================================================================

DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro) VALUES
(1, 2300, 2301, 1.0000, 1.0000, '2099-12-31', 1000, 1);

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro)
SELECT 
    ROW_NUMBER() OVER (ORDER BY fecha) + 1 AS tipo_cambio_id,
    2300 AS origen_moneda_id,
    2301 AS destino_moneda_id,
    6.8600 AS factor_compra,
    6.9600 AS factor_venta,
    fecha::date AS fecha_cotizacion,
    1000 AS estado_id,
    2 AS usuario_id_registro
FROM generate_series('2026-01-01'::date, '2026-12-31'::date, '1 day'::interval) AS fecha;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 0), (SELECT COUNT(*) > 0 FROM tipos_cambios));

-- ================================================================================================

DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.png', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@gmail.com', 'MAT-000', 1000, 1),
(2, 'FARMACIA SALUD Y VIDA S.R.L.', '309', '2.png', 'Tu salud es nuestra prioridad', 'Venta de medicamentos', 'LA PAZ - BOLIVIA', 'JUAN PEREZ FLORES', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '22441122', 'central@saludyvida.com.bo', 'M-356981', 1000, 2);

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
(6, 2, 2751, '321654987', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE MATERIAL DE ESCRITORIO Y SUMINISTROS DE OFICINA', 'ESCRITORIO', 3900, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'escritorio@saludyvida.com.bo', 1000, 2),
(7, 2, 2750, '321654988', 'FARMACIA SALUD Y VIDA S.R.L.', 'VENTA DE LIBROS', 'LIBROS', 3901, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 'libros@saludyvida.com.bo', 1000, 2);

SELECT setval('empresas_nits_empresa_nit_id_seq', COALESCE((SELECT MAX(empresa_nit_id) FROM empresas_nits), 0), (SELECT COUNT(*) > 0 FROM empresas_nits));

-- ================================================================================================

DELETE FROM empresas_cuentas;
ALTER SEQUENCE empresas_cuentas_empresa_cuenta_id_seq RESTART WITH 1;

INSERT INTO empresas_cuentas (empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 2300, '0000000000', 1755, 'NINGUNO', 1000, 1),
(2, 2, 2, 2300, '1000001234', 1750, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2),
(3, 2, 5, 2300, '4000003456', 1751, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2),
(4, 2, 4, 2301, '3000005678', 1751, 'FARMACIA SALUD Y VIDA S.R.L.', 1000, 2);

SELECT setval('empresas_cuentas_empresa_cuenta_id_seq', COALESCE((SELECT MAX(empresa_cuenta_id) FROM empresas_cuentas), 0), (SELECT COUNT(*) > 0 FROM empresas_cuentas));

-- ================================================================================================

DELETE FROM sucursales;
ALTER SEQUENCE sucursales_sucursal_id_seq RESTART WITH 1;

INSERT INTO sucursales (sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', 'NIN', 0, '00000000', 'DIRECCION NINGUNA', '00:00 - 00:00', 1.50, 1.19, 1000, 1),
(2, 2, 'CASA MATRIZ - SOPOCACHI', 'FARMACIA SALUD Y VIDA - CASA MATRIZ SOPOCACHI', 'FSM', 0, '22441122', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '08:00 - 22:00', 1.50, 1.19, 1000, 2),
(3, 2, 'SUCURSAL ZONA SUR', 'FARMACIA SALUD Y VIDA - SUCURSAL ZONA SUR CALACOTO', 'FSZ', 1, '22774433', 'AV. BALLIVIAN NRO. 540, CALACOTO, LA PAZ', '08:00 - 23:00', 1.50, 1.19, 1000, 2);

SELECT setval('sucursales_sucursal_id_seq', COALESCE((SELECT MAX(sucursal_id) FROM sucursales), 0), (SELECT COUNT(*) > 0 FROM sucursales));

-- ================================================================================================

DELETE FROM puntos_venta;
ALTER SEQUENCE puntos_venta_punto_venta_id_seq RESTART WITH 1;

INSERT INTO puntos_venta (punto_venta_id, sucursal_id, codigo, nombre, tipo_punto_venta_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0, 'NINGUNO', 3950, 1000, 1),
(2, 2, 1, 'CAJA PRINCIPAL - SOPOCACHI', 3951, 1000, 2),
(3, 2, 2, 'CAJA SECUNDARIA - SOPOCACHI', 3951, 1000, 2),
(4, 3, 3, 'CAJA PRINCIPAL - ZONA SUR', 3951, 1000, 2);

SELECT setval('puntos_venta_punto_venta_id_seq', COALESCE((SELECT MAX(punto_venta_id) FROM puntos_venta), 0), (SELECT COUNT(*) > 0 FROM puntos_venta));

-- ================================================================================================

DELETE FROM cuis;
ALTER SEQUENCE cuis_cuis_id_seq RESTART WITH 1;

INSERT INTO cuis (cuis_id, sucursal_id, punto_venta_id, codigo_cuis, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1),
(2, 2, 2, 'CUIS-FSM-001', '2027-12-31 23:59:59-04', 1000, 2),
(3, 2, 3, 'CUIS-FSM-002', '2027-12-31 23:59:59-04', 1000, 2),
(4, 3, 4, 'CUIS-FSZ-001', '2027-12-31 23:59:59-04', 1000, 2);

SELECT setval('cuis_cuis_id_seq', COALESCE((SELECT MAX(cuis_id) FROM cuis), 0), (SELECT COUNT(*) > 0 FROM cuis));

-- ================================================================================================

DELETE FROM cufd;
ALTER SEQUENCE cufd_cufd_id_seq RESTART WITH 1;

INSERT INTO cufd (cufd_id, sucursal_id, punto_venta_id, codigo_cufd, codigo_control, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1),
(2, 2, 2, 'CUFD-FSM-001', 'CTRL-FSM-001', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2),
(3, 2, 3, 'CUFD-FSM-002', 'CTRL-FSM-002', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2),
(4, 3, 4, 'CUFD-FSZ-001', 'CTRL-FSZ-001', CURRENT_TIMESTAMP + INTERVAL '24 hours', 1000, 2);

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
(12, 'PQ', 58, 'PAQUETE', 1000, 2),
(13, 'MG', 10, 'MILIGRAMO', 1000, 2),
(14, 'MCG', 11, 'MICROGRAMO', 1000, 2),
(15, 'UI', 12, 'UNIDAD INTERNACIONAL', 1000, 2),
(16, 'MEQ', 13, 'MILIEQUIVALENTE', 1000, 2),
(17, 'MMOL', 14, 'MILIMOL', 1000, 2),
(18, 'CM2', 15, 'CENTÍMETRO CUADRADO', 1000, 2),
(19, 'MM', 16, 'MILÍMETRO', 1000, 2),
(20, 'MCG/KG', 17, 'MICROGRAMO POR KILOGRAMO', 1000, 2),
(21, 'MG/KG', 18, 'MILIGRAMO POR KILOGRAMO', 1000, 2),
(22, 'G/L', 19, 'GRAMO POR LITRO', 1000, 2),
(23, 'MG/ML', 20, 'MILIGRAMO POR MILILITRO', 1000, 2),
(24, 'MCG/ML', 21, 'MICROGRAMO POR MILILITRO', 1000, 2),
(25, 'G/MOL', 22, 'GRAMO POR MOL', 1000, 2),
(26, '%', 23, 'PORCENTAJE', 1000, 2),
(27, 'PPM', 24, 'PARTES POR MILLÓN', 1000, 2),
(28, 'PPT', 25, 'PARTES POR TRILLÓN', 1000, 2),
(29, 'GB', 26, 'GOTA', 1000, 2),
(30, 'GL', 27, 'GOTAS', 1000, 2),
(31, 'CF', 28, 'CÁPSULA', 1000, 2),
(32, 'CP', 29, 'COMPRIMIDO', 1000, 2),
(33, 'GR', 30, 'GRÁNULO', 1000, 2),
(34, 'OV', 31, 'ÓVULO', 1000, 2),
(35, 'SUP', 32, 'SUPOSITORIO', 1000, 2),
(36, 'AP', 33, 'APLICACIÓN', 1000, 2),
(37, 'DS', 34, 'DOSIS', 1000, 2),
(38, 'INH', 35, 'INHALACIÓN', 1000, 2),
(39, 'PUFF', 36, 'PUFF (INHALACIÓN)', 1000, 2),
(40, 'PAR', 37, 'PARCHE', 1000, 2),
(41, 'ML/KG', 38, 'MILILITRO POR KILOGRAMO', 1000, 2),
(42, 'U/KG', 39, 'UNIDAD POR KILOGRAMO', 1000, 2);

SELECT setval('unidades_unidad_id_seq', COALESCE((SELECT MAX(unidad_id) FROM unidades), 0), (SELECT COUNT(*) > 0 FROM unidades));

-- ================================================================================================

DELETE FROM almacenes;
ALTER SEQUENCE almacenes_almacen_id_seq RESTART WITH 1;

INSERT INTO almacenes (almacen_id,sucursal_id,almacen,codigo,tipo_almacen_id,tipo_operacion_almacen_id,descripcion,estado_id,usuario_id_registro) VALUES
	 (1,1,'NINGUNO','NIN',1700,4051,'ALMACEN COMODIN',1000,1),
	 (2,2,'ALMACEN PRINCIPAL','ALM-FSM-01',1700,4051,'ALMACEN GENERAL DE MEDICAMENTOS - VENTA DIRECTA',1000,2),
	 (3,2,'REFRIGERADOS','REF-FSM-01',1701,4051,'ALMACEN DE PRODUCTOS REFRIGERADOS (2°C A 8°C)',1000,2),
	 (4,2,'CONGELADOS','CON-FSM-01',1702,4051,'ALMACEN DE PRODUCTOS CONGELADOS (-18°C O MENOR)',1000,2),
	 (5,2,'JUGUETES Y RECREATIVOS','JUG-FSM-01',1700,4051,'ALMACEN DE JUGUETES Y ARTICULOS RECREATIVOS',1000,2),
	 (6,2,'EQUIPOS ELECTRONICOS','ELE-FSM-01',1700,4051,'ALMACEN DE EQUIPOS ELECTRONICOS Y DISPOSITIVOS',1000,2),
	 (7,2,'MATERIAL DE ESCRITORIO','MAT-FSM-01',1700,4051,'ALMACEN DE MATERIAL DE ESCRITORIO Y SUMINISTROS',1000,2),
	 (8,2,'RECEPCION','REC-FSM-01',1709,4050,'ZONA DE RECEPCION DE MERCANCIAS',1000,2),
	 (9,2,'DESPACHO','DES-FSM-01',1711,4050,'ZONA DE PREPARACION Y DESPACHO DE PEDIDOS',1000,2),
	 (10,3,'ALMACEN PRINCIPAL','ALM-FSZ-01',1700,4051,'ALMACEN GENERAL DE MEDICAMENTOS - ZONA SUR',1000,2),
	 (11,3,'REFRIGERADOS','REF-FSZ-01',1701,4051,'ALMACEN DE PRODUCTOS REFRIGERADOS ZONA SUR',1000,2),
	 (12,3,'JUGUETES Y RECREATIVOS','JUG-FSZ-01',1700,4051,'ALMACEN DE JUGUETES Y ARTICULOS RECREATIVOS ZONA SUR',1000,2);

SELECT setval('almacenes_almacen_id_seq', COALESCE((SELECT MAX(almacen_id) FROM almacenes), 0), (SELECT COUNT(*) > 0 FROM almacenes));

-- ================================================================================================

DELETE FROM ubicaciones;
ALTER SEQUENCE ubicaciones_ubicacion_id_seq RESTART WITH 1;

INSERT INTO ubicaciones (ubicacion_id, almacen_id, codigo, jerarquia, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', '{"tipo":"COMODIN","valor":"NINGUNO","camino":"COMODIN NINGUNO"}'::jsonb, 'UBICACION COMODIN', 1000, 1),
(2, 2, 'EST-A-1', '{"tipo":"ESTANTERIA","valor":"A","nivel":"1","camino":"ESTANTERIA A > NIVEL 1"}'::jsonb, 'Estantería A, Nivel 1', 1000, 2),
(3, 2, 'EST-A-2', '{"tipo":"ESTANTERIA","valor":"A","nivel":"2","camino":"ESTANTERIA A > NIVEL 2"}'::jsonb, 'Estantería A, Nivel 2', 1000, 2),
(4, 2, 'EST-A-3', '{"tipo":"ESTANTERIA","valor":"A","nivel":"3","camino":"ESTANTERIA A > NIVEL 3"}'::jsonb, 'Estantería A, Nivel 3', 1000, 2),
(5, 2, 'EST-B-1', '{"tipo":"ESTANTERIA","valor":"B","nivel":"1","camino":"ESTANTERIA B > NIVEL 1"}'::jsonb, 'Estantería B, Nivel 1', 1000, 2),
(6, 2, 'EST-B-2', '{"tipo":"ESTANTERIA","valor":"B","nivel":"2","camino":"ESTANTERIA B > NIVEL 2"}'::jsonb, 'Estantería B, Nivel 2', 1000, 2),
(7, 2, 'EST-B-3', '{"tipo":"ESTANTERIA","valor":"B","nivel":"3","camino":"ESTANTERIA B > NIVEL 3"}'::jsonb, 'Estantería B, Nivel 3', 1000, 2),
(8, 2, 'EST-C-1', '{"tipo":"ESTANTERIA","valor":"C","nivel":"1","camino":"ESTANTERIA C > NIVEL 1"}'::jsonb, 'Estantería C, Nivel 1', 1000, 2),
(9, 2, 'EST-C-2', '{"tipo":"ESTANTERIA","valor":"C","nivel":"2","camino":"ESTANTERIA C > NIVEL 2"}'::jsonb, 'Estantería C, Nivel 2', 1000, 2),
(10, 2, 'EST-C-3', '{"tipo":"ESTANTERIA","valor":"C","nivel":"3","camino":"ESTANTERIA C > NIVEL 3"}'::jsonb, 'Estantería C, Nivel 3', 1000, 2),
(11, 3, 'REF-01-1', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"1","camino":"REFRIGERADOR REF-01 > BANDEJA 1"}'::jsonb, 'Refrigerador REF-01, Bandeja 1', 1000, 2),
(12, 3, 'REF-01-2', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"2","camino":"REFRIGERADOR REF-01 > BANDEJA 2"}'::jsonb, 'Refrigerador REF-01, Bandeja 2', 1000, 2),
(13, 3, 'REF-01-3', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"3","camino":"REFRIGERADOR REF-01 > BANDEJA 3"}'::jsonb, 'Refrigerador REF-01, Bandeja 3', 1000, 2),
(14, 3, 'REF-01-4', '{"tipo":"REFRIGERADOR","valor":"REF-01","nivel":"4","camino":"REFRIGERADOR REF-01 > BANDEJA 4"}'::jsonb, 'Refrigerador REF-01, Bandeja 4', 1000, 2),
(15, 3, 'REF-02-1', '{"tipo":"REFRIGERADOR","valor":"REF-02","nivel":"1","camino":"REFRIGERADOR REF-02 > BANDEJA 1"}'::jsonb, 'Refrigerador REF-02, Bandeja 1', 1000, 2),
(16, 3, 'REF-02-2', '{"tipo":"REFRIGERADOR","valor":"REF-02","nivel":"2","camino":"REFRIGERADOR REF-02 > BANDEJA 2"}'::jsonb, 'Refrigerador REF-02, Bandeja 2', 1000, 2),
(17, 4, 'CON-01-1', '{"tipo":"CONGELADOR","valor":"CON-01","nivel":"1","camino":"CONGELADOR CON-01 > BANDEJA 1"}'::jsonb, 'Congelador CON-01, Bandeja 1', 1000, 2),
(18, 4, 'CON-01-2', '{"tipo":"CONGELADOR","valor":"CON-01","nivel":"2","camino":"CONGELADOR CON-01 > BANDEJA 2"}'::jsonb, 'Congelador CON-01, Bandeja 2', 1000, 2),
(19, 4, 'CON-02-1', '{"tipo":"CONGELADOR","valor":"CON-02","nivel":"1","camino":"CONGELADOR CON-02 > BANDEJA 1"}'::jsonb, 'Congelador CON-02, Bandeja 1', 1000, 2),
(20, 4, 'CON-02-2', '{"tipo":"CONGELADOR","valor":"CON-02","nivel":"2","camino":"CONGELADOR CON-02 > BANDEJA 2"}'::jsonb, 'Congelador CON-02, Bandeja 2', 1000, 2),
(21, 5, 'JUG-A', '{"tipo":"ANAQUEL","valor":"A","camino":"ANAQUEL A"}'::jsonb, 'Anaquél de Juguetes - Sección A', 1000, 2),
(22, 5, 'JUG-B', '{"tipo":"ANAQUEL","valor":"B","camino":"ANAQUEL B"}'::jsonb, 'Anaquél de Juguetes - Sección B', 1000, 2),
(23, 5, 'JUG-C', '{"tipo":"ANAQUEL","valor":"C","camino":"ANAQUEL C"}'::jsonb, 'Anaquél de Juguetes - Sección C', 1000, 2),
(24, 6, 'EXP-01', '{"tipo":"EXHIBIDOR","valor":"EXP-01","camino":"EXHIBIDOR EXP-01"}'::jsonb, 'Exhibidor de Electrónicos 01', 1000, 2),
(25, 6, 'EXP-02', '{"tipo":"EXHIBIDOR","valor":"EXP-02","camino":"EXHIBIDOR EXP-02"}'::jsonb, 'Exhibidor de Electrónicos 02', 1000, 2),
(26, 7, 'EST-D-1', '{"tipo":"ESTANTERIA","valor":"D","nivel":"1","camino":"ESTANTERIA D > NIVEL 1"}'::jsonb, 'Estantería D, Nivel 1', 1000, 2),
(27, 7, 'EST-D-2', '{"tipo":"ESTANTERIA","valor":"D","nivel":"2","camino":"ESTANTERIA D > NIVEL 2"}'::jsonb, 'Estantería D, Nivel 2', 1000, 2),
(28, 8, 'ZON-RECEPCION', '{"tipo":"ZONA","valor":"RECEPCION","camino":"ZONA RECEPCION"}'::jsonb, 'Zona de Recepción de Mercancías', 1000, 2),
(29, 9, 'ZON-DESPACHO', '{"tipo":"ZONA","valor":"DESPACHO","camino":"ZONA DESPACHO"}'::jsonb, 'Zona de Preparación y Despacho', 1000, 2),
(30, 10, 'EST-D-1', '{"tipo":"ESTANTERIA","valor":"D","nivel":"1","camino":"ESTANTERIA D > NIVEL 1"}'::jsonb, 'Estantería D, Nivel 1 - Zona Sur', 1000, 2),
(31, 10, 'EST-D-2', '{"tipo":"ESTANTERIA","valor":"D","nivel":"2","camino":"ESTANTERIA D > NIVEL 2"}'::jsonb, 'Estantería D, Nivel 2 - Zona Sur', 1000, 2),
(32, 10, 'EST-D-3', '{"tipo":"ESTANTERIA","valor":"D","nivel":"3","camino":"ESTANTERIA D > NIVEL 3"}'::jsonb, 'Estantería D, Nivel 3 - Zona Sur', 1000, 2),
(33, 11, 'REF-Z01-1', '{"tipo":"REFRIGERADOR","valor":"REF-Z01","nivel":"1","camino":"REFRIGERADOR REF-Z01 > BANDEJA 1"}'::jsonb, 'Refrigerador Zona Sur, Bandeja 1', 1000, 2),
(34, 11, 'REF-Z01-2', '{"tipo":"REFRIGERADOR","valor":"REF-Z01","nivel":"2","camino":"REFRIGERADOR REF-Z01 > BANDEJA 2"}'::jsonb, 'Refrigerador Zona Sur, Bandeja 2', 1000, 2),
(35, 12, 'JUG-Z-A', '{"tipo":"ANAQUEL","valor":"Z-A","camino":"ANAQUEL Z-A"}'::jsonb, 'Anaquél de Juguetes - Zona Sur A', 1000, 2),
(36, 12, 'JUG-Z-B', '{"tipo":"ANAQUEL","valor":"Z-B","camino":"ANAQUEL Z-B"}'::jsonb, 'Anaquél de Juguetes - Zona Sur B', 1000, 2);

SELECT setval('ubicaciones_ubicacion_id_seq', COALESCE((SELECT MAX(ubicacion_id) FROM ubicaciones), 0), (SELECT COUNT(*) > 0 FROM ubicaciones));

-- ================================================================================================

DELETE FROM almacenes_puntos_venta;
ALTER SEQUENCE almacenes_puntos_venta_almacen_punto_venta_id_seq RESTART WITH 1;

INSERT INTO almacenes_puntos_venta (almacen_punto_venta_id, sucursal_id, almacen_id, punto_venta_id, prioridad, es_principal, estado_id, usuario_id_registro) VALUES
(1,  1, 1,  1, 1, 1, 1000, 1),
(2,  2, 2,  2, 1, 1, 1000, 2),
(3,  2, 3,  2, 2, 0, 1000, 2),
(4,  2, 4,  2, 3, 0, 1000, 2),
(5,  2, 5,  2, 4, 0, 1000, 2),
(6,  2, 6,  2, 5, 0, 1000, 2),
(7,  2, 7,  2, 6, 0, 1000, 2),
(8,  2, 2,  3, 1, 1, 1000, 2),
(9,  2, 3,  3, 2, 0, 1000, 2),
(10, 2, 4,  3, 3, 0, 1000, 2),
(11, 2, 5,  3, 4, 0, 1000, 2),
(12, 2, 6,  3, 5, 0, 1000, 2),
(13, 2, 7,  3, 6, 0, 1000, 2),
(14, 3, 10, 4, 1, 1, 1000, 2),
(15, 3, 11, 4, 2, 0, 1000, 2),
(16, 3, 12, 4, 3, 0, 1000, 2);

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

SELECT setval('cargos_cargo_id_seq', COALESCE((SELECT MAX(cargo_id) FROM cargos), 0), (SELECT COUNT(*) > 0 FROM cargos));

-- ================================================================================================

DELETE FROM trabajadores;
ALTER SEQUENCE trabajadores_trabajador_id_seq RESTART WITH 1;

INSERT INTO trabajadores (trabajador_id, sucursal_id, genero_id, estado_civil_id, nombres, paterno, materno, dni, telefono, email, fecha_nacimiento, fecha_contratacion, foto, qr, estado_id, usuario_id_registro) VALUES
(1,  1, 1200, 1250, 'NINGUNO', 'NINGUNO', NULL, '0000000', NULL, NULL, NULL, NULL, '1.jpg', '1.png', 1000, 1),
(2,  2, 1200, 1251, 'FRANZ', 'IBAÑEZ', NULL, '2630198', '60241524', 'franz.ibanez.c@gmail.com', '1980-06-24', '2026-01-01', '2.jpg', '2.png', 1000, 2),
(3,  2, 1200, 1250, 'PASCUAL', 'QUISPE', 'HUANCA', '4892014', '70541489', 'pascual.q.h@hotmail.com', '1982-01-27', '2026-01-01', '3.png', '3.png', 1000, 2),
(4,  2, 1201, 1301, 'GLADYS', 'ALANOCA', NULL, '3482910', '60241524', 'gladys.alanoca@gmail.com', '1980-06-24', '2026-01-01', '4.jpg', '4.png', 1000, 2),
(5,  2, 1201, 1300, 'SILVIA', 'QUISPE', NULL, '6105824', '65201478', 'silvia.quispe@outlook.com', '1976-04-01', '2026-01-01', '5.jpg', '5.png', 1000, 2),
(6,  2, 1200, 1250, 'JUAN PABLO', 'HIDALGO', 'HUANCA', '8342915', '71524311', 'jphidalgo.h@gmail.com', '1988-09-15', '2026-01-01', '6.png', '6.png', 1000, 2),
(7,  2, 1200, 1250, 'MARCELO', 'VARGAS', 'FLORES', '5920147', '72014589', 'marcelovargas.f@hotmail.com', '1985-11-03', '2026-01-01', '7.jpg', '7.png', 1000, 2),
(8,  2, 1201, 1301, 'BEATRIZ', 'MENDOZA', 'ROJAS', '12409581', '60112233', 'beatriz.mendoza.r@gmail.com', '1993-03-22', '2026-01-01', '8.png', '8.png', 1000, 2),
(9,  3, 1201, 1300, 'CARLA', 'LOPEZ', 'ESTRADA', '7301948', '60581422', 'carla.lopez.e@gmail.com', '1991-05-14', '2026-01-01', '9.jpg', '9.png', 1000, 2),
(10, 3, 1200, 1250, 'RODRIGO', 'APAZA', 'MAMANI', '4910283', '70611224', 'rodrigo.apaza@hotmail.com', '1989-12-08', '2026-01-01', '10.jpg', '10.png', 1000, 2),
(11, 3, 1200, 1251, 'HECTOR', 'CONDO', 'ALANOCA', '5432109', '71254896', 'hector.condo@gmail.com', '1984-07-19', '2026-01-01', '11.jpg', '11.png', 1000, 2),
(12, 3, 1201, 1300, 'PATRICIA', 'CHAVEZ', 'SOLIZ', '6198420', '65124578', 'patricia.chavez@outlook.com', '1995-10-02', '2026-01-01', '12.jpg', '12.png', 1000, 2),
(13, 3, 1200, 1250, 'DIEGO', 'PINTO', 'GUTIERREZ', '8412975', '73021456', 'gustavo.pinto@gmail.com', '1992-04-30', '2026-01-01', '13.jpg', '13.png', 1000, 2),
(14, 3, 1201, 1300, 'MONICA', 'SILES', 'ORELLANA', '9120843', '60145879', 'monica.siles@hotmail.com', '1990-02-15', '2026-01-01', '14.jpg', '14.png', 1000, 2),
(15, 2, 1201, 1301, 'VALERIA', 'RIVERA', 'CRUZ', '3490218', '71954823', 'valeria.rivera.c@gmail.com', '1987-11-25', '2026-01-01', '15.png', '15.png', 1000, 2),
(16, 3, 1200, 1250, 'ALEXANDER', 'QUISPE', 'CHOQUE', '7891234', '71589632', 'alexander.quispe@gmail.com', '2000-05-12', '2026-01-01', '16.jpg', '16.png', 1000, 2),
(17, 3, 1200, 1250, 'KEVIN', 'MAMANI', 'FLORES', '6547891', '72036541', 'kevin.mamani@hotmail.com', '2002-08-19', '2026-01-01', '17.jpg', '17.png', 1000, 2);

SELECT setval('trabajadores_trabajador_id_seq', COALESCE((SELECT MAX(trabajador_id) FROM trabajadores), 0), (SELECT COUNT(*) > 0 FROM trabajadores));

-- ================================================================================================

DELETE FROM trabajadores_cargos;
ALTER SEQUENCE trabajadores_cargos_trabajador_cargo_id_seq RESTART WITH 1;

INSERT INTO trabajadores_cargos (trabajador_cargo_id, trabajador_id, cargo_id, sueldo_base, tipo_moneda_id, es_activo, estado_id, 
usuario_id_registro) VALUES
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
(16, 17, 9, 3000.00, 2300, 1, 1000, 2),
(17, 2, 2, 7000.00, 2300, 1, 1000, 2);

SELECT setval('trabajadores_cargos_trabajador_cargo_id_seq', COALESCE((SELECT MAX(trabajador_cargo_id) FROM trabajadores_cargos), 0), (SELECT COUNT(*) > 0 FROM trabajadores_cargos));

-- ================================================================================================

DELETE FROM roles;
ALTER SEQUENCE roles_rol_id_seq RESTART WITH 1;

INSERT INTO roles (rol_id, es_admin, codigo, rol, descripcion, estado_id, usuario_id_registro) VALUES
(1, 0, 'NIN', 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO DEL SISTEMA', 1000, 1),
(2, 1, 'ADM', 'ADMINISTRADOR', 'Control total de la plataforma sirena acceso a todo, tiene todos los permisos', 1000, 2),
(3, 0, 'GER', 'GERENTE', 'Control y acceso a todos los modulos pero solo de lectura', 1000, 2),
(4, 0, 'SUC', 'ENCARGADO DE SUCURSAL', 'Responsable de la supervision, operaciones y arqueos de una sucursal especifica', 1000, 2),
(5, 0, 'COM', 'COMPRADOR', 'Responsable de la gestion de proveedores, ordenes de compra y adquisiciones', 1000, 2),
(6, 0, 'VEN', 'VENDEDOR', 'Responsable de la atencion a clientes, cotizaciones y registro de ventas', 1000, 2),
(7, 0, 'ALM', 'ALMACENERO', 'Responsable de la recepcion de mercaderia, control de stock, ingresos y salidas de almacen', 1000, 2),
(8, 0, 'CAJ', 'CAJERO', 'Responsable de la recepcion de pagos, facturacion y apertura/cierre de caja chica', 1000, 2);

SELECT setval('roles_rol_id_seq', COALESCE((SELECT MAX(rol_id) FROM roles), 0), (SELECT COUNT(*) > 0 FROM roles));

-- ================================================================================================

DELETE FROM usuarios;
ALTER SEQUENCE usuarios_usuario_id_seq RESTART WITH 1;

INSERT INTO usuarios (usuario_id,trabajador_id,rol_id,login,contrasena,avatar,estado_id,usuario_id_registro) VALUES
(1,1,1,'SISTEMA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','1.png',1000,1),
(2,2,2,'ADMIN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','2.png',1000,1),
(3,3,4,'PASCUAL','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','3.png',1000,1),
(4,4,5,'GLADYS','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','4.png',1000,1),
(5,5,4,'SILVIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','5.png',1000,1),
(6,6,6,'JUAN','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','6.png',1000,1),
(7,7,7,'MARCELO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','7.png',1000,1),
(8,8,8,'BEATRIZ','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','8.png',1000,1),
(9,9,6,'CARLA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','9.png',1000,1),
(10,10,8,'RODRIGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','10.png',1000,1),
(11,11,7,'HECTOR','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','11.png',1000,1),
(12,12,5,'PATRICIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','12.png',1000,1),
(13,13,6,'DIEGO','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','13.png',1000,1),
(14,14,7,'MONICA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','14.png',1000,1),
(15,15,3,'VALERIA','$2b$12$gq0CYwa7ZfRvKiD/oMD3eO2Hn/n4L2lXOaH6DjAtvVkohhpPjnWMq','15.png',1000,1);

SELECT setval('usuarios_usuario_id_seq', COALESCE((SELECT MAX(usuario_id) FROM usuarios), 0), (SELECT COUNT(*) > 0 FROM usuarios));

-- ================================================================================================

DELETE FROM tablas;
ALTER SEQUENCE tablas_tabla_id_seq RESTART WITH 1;

INSERT INTO tablas (tabla_id, nombre, estado_id, usuario_id_registro) VALUES
(1, 'ninguno', 1000, 1),
(2, 'alertas_notificaciones', 1000, 2),
(3, 'almacenes', 1000, 2),
(4, 'almacenes_puntos_venta', 1000, 2),
(5, 'analitica_productos', 1000, 2),
(6, 'arqueos_detalle', 1000, 2),
(7, 'asistencias', 1000, 2),
(8, 'bancos', 1000, 2),
(9, 'cajas', 1000, 2),
(10, 'cargos', 1000, 2),
(11, 'carritos_compra', 1000, 2),
(12, 'categorias', 1000, 2),
(13, 'clientes', 1000, 2),
(14, 'comprobantes_pagos', 1000, 2),
(15, 'concentraciones', 1000, 2),
(16, 'contratos', 1000, 2),
(17, 'control_facturas', 1000, 2),
(18, 'conversiones_unidad', 1000, 2),
(19, 'costos_promedio', 1000, 2),
(20, 'cufd', 1000, 2),
(21, 'cuis', 1000, 2),
(22, 'detalles_carritos', 1000, 2),
(23, 'detalles_pedidos_online', 1000, 2),
(24, 'empresas', 1000, 2),
(25, 'empresas_cuentas', 1000, 2),
(26, 'empresas_nits', 1000, 2),
(27, 'entrenamientos', 1000, 2),
(28, 'equivalentes', 1000, 2),
(29, 'especialidades', 1000, 2),
(30, 'formas', 1000, 2),
(31, 'historicos', 1000, 2),
(32, 'instituciones', 1000, 2),
(33, 'inventarios_fisicos', 1000, 2),
(34, 'inventarios_fisicos_detalle', 1000, 2),
(35, 'kardex', 1000, 2),
(36, 'kardex_productos', 1000, 2),
(37, 'laboratorios', 1000, 2),
(38, 'listas_precios', 1000, 2),
(39, 'logs_ejecucion', 1000, 2),
(40, 'lotes_productos', 1000, 2),
(41, 'marcas', 1000, 2),
(42, 'medicos', 1000, 2),
(43, 'menus', 1000, 2),
(44, 'metricas_rendimiento', 1000, 2),
(45, 'modelos', 1000, 2),
(46, 'movimientos', 1000, 2),
(47, 'ordenes_compra', 1000, 2),
(48, 'pagos', 1000, 2),
(49, 'parametros_globales', 1000, 2),
(50, 'patrones_consumo', 1000, 2),
(51, 'pedidos_online', 1000, 2),
(52, 'planes_pagos', 1000, 2),
(53, 'planillas', 1000, 2),
(54, 'planillas_detalle', 1000, 2),
(55, 'politicas_precios', 1000, 2),
(56, 'precios_productos', 1000, 2),
(57, 'presentaciones', 1000, 2),
(58, 'principios_activos', 1000, 2),
(59, 'productos', 1000, 2),
(60, 'productos_controlados', 1000, 2),
(61, 'productos_principios', 1000, 2),
(62, 'productos_rangos_edad', 1000, 2),
(63, 'productos_ubicaciones', 1000, 2),
(64, 'productos_vias', 1000, 2),
(65, 'promociones', 1000, 2),
(66, 'promociones_productos', 1000, 2),
(67, 'proveedores', 1000, 2),
(68, 'proveedores_contactos', 1000, 2),
(69, 'proveedores_rating_historico', 1000, 2),
(70, 'puntos_venta', 1000, 2),
(71, 'rangos_edad', 1000, 2),
(72, 'recetas', 1000, 2),
(73, 'registros_sanitarios', 1000, 2),
(74, 'roles', 1000, 2),
(75, 'roles_menus', 1000, 2),
(76, 'roles_tablas', 1000, 2),
(77, 'sucursales', 1000, 2),
(78, 'tablas', 1000, 2),
(79, 'tareas_programadas', 1000, 2),
(80, 'tipos_cambios', 1000, 2),
(81, 'tipos_planes_pago', 1000, 2),
(82, 'trabajadores', 1000, 2),
(83, 'trabajadores_cargos', 1000, 2),
(84, 'ubicaciones', 1000, 2),
(85, 'ubicaciones_historial', 1000, 2),
(86, 'ubicaciones_movimientos', 1000, 2),
(87, 'umbrales_configuracion', 1000, 2),
(88, 'unidades', 1000, 2),
(89, 'usuarios', 1000, 2),
(90, 'variables_exogenas', 1000, 2),
(91, 'vias', 1000, 2);

SELECT setval('tablas_tabla_id_seq', COALESCE((SELECT MAX(tabla_id) FROM tablas), 0), (SELECT COUNT(*) > 0 FROM tablas));

-- ================================================================================================

DELETE FROM sucesos;

INSERT INTO sucesos (suceso_id, codigo, suceso, descripcion, tabla_id, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'Evento por defecto sin acción específica', 1, 1000, 1),
(1050, 'LOT', 'COMPRA', 'Registro de ingreso de mercadería por compra a proveedor. Afecta positivamente el stock y genera cuentas por pagar.', 2, 1000, 2),
(1051, 'VEN', 'VENTA', 'Registro de salida de mercadería por venta a cliente. Afecta negativamente el stock, genera facturación y movimiento de caja.', 2, 1000, 2),
(1052, 'PRO', 'PROFORMA', 'Cotización o presupuesto temporal que NO afecta stock ni finanzas. Solo documento informativo o estimación de precios.', 2, 1000, 2),
(1053, 'EGR', 'EGRESO_TRASPASO', 'Egreso de mercadería desde sucursal origen hacia destino. Disminuye stock en origen hasta confirmación en destino.', 2, 1000, 2),
(1054, 'ING', 'INGRESO_TRASPASO', 'Ingreso de mercadería a sucursal destino procedente de origen. Aumenta stock en destino al confirmar recepción.', 2, 1000, 2),
(1055, 'ANU', 'ANULACION', 'Cancelación de una transacción previa (compra o venta). Revierte automáticamente el stock afectado y deja registro inmutable para auditoría.', 2, 1000, 2),
(1056, 'AJI', 'AJUSTE_INGRESO', 'Incremento de stock por sobrante detectado en inventario físico. No genera transacción comercial.', 2, 1000, 2),
(1057, 'AJE', 'AJUSTE_EGRESO', 'Decremento de stock por faltante detectado en inventario físico. No genera transacción comercial.', 2, 1000, 2),
(1058, 'SOL', 'SOLICITUD_COMPRA', 'Pedido administrativo pendiente de aprobación. No afecta stock ni finanzas hasta su conversión a COMPRA (1050).', 2, 1000, 2),
(1059, 'VRE', 'VENTA_RESERVA', 'Proforma con reserva temporal de stock por tiempo limitado. Afecta negativamente el stock (lo aparta) y puede convertirse en VENTA (1051). Requiere validez_dias para definir plazo de reserva.', 2, 1000, 2),
(1060, 'DCLI', 'DEVOLUCION_CLIENTE', 'Devolución de mercadería por parte del cliente. Afecta positivamente el stock y requiere nota de crédito/débito fiscal si aplica.', 2, 1000, 2),
(1061, 'DPRO', 'DEVOLUCION_PROVEEDOR', 'Devolución de mercadería defectuosa o próxima a vencer al proveedor. Disminuye el stock y ajusta cuentas por pagar.', 2, 1000, 2),
(1062, 'ROB', 'ROBO', 'Salida extraordinaria de inventario por sustracción o robo detectado. Disminuye el stock sin contrapartida comercial y genera alerta de auditoría.', 2, 1000, 2),
(1063, 'PCAD', 'PERDIDA_CADUCIDAD', 'Baja de stock por productos vencidos o caducados detectados en control de almacén. Afecta como pérdida operativa.', 2, 1000, 2),
(1064, 'MER', 'MERMA_ROTURA', 'Salida de stock por daño físico, rotura o deterioro de medicamentos. No genera transacción comercial.', 2, 1000, 2),
(1065, 'IFSO', 'INVENTARIO_FISICO_SOBRANTE', 'Ajuste positivo por conteo físico de inventario (diferencia a favor respecto al sistema).', 2, 1000, 2),
(1066, 'IFFAL', 'INVENTARIO_FISICO_FALTANTE', 'Ajuste negativo por conteo físico de inventario (diferencia en contra o merma no identificada).', 2, 1000, 2),
(1067, 'CENV', 'CONVERSION_UNIDADES', 'Salida de productos en empaque mayor (cajas/blísteres) y reingreso automático como unidades sueltas por fraccionamiento.', 2, 1000, 2),
(1068, 'RCUA', 'RETIRO_CUARENTENA', 'Salida temporal o definitiva de stock retenido por alerta sanitaria o control de calidad. Bloquea o saca la mercadería de la disponibilidad comercial.', 2, 1000, 2),
(1069, 'DON', 'INGRESO_DONACION', 'Ingreso de mercadería por donación o recepción sin costo. Afecta positivamente el stock sin generar obligación de pago.', 2, 1000, 2),
(1070, 'LRES', 'LIBERACION_RESERVA', 'Liberación de stock retenido por expiración de tiempo o anulación de reserva. Reintegra el stock disponible.', 2, 1000, 2);

-- ================================================================================================

DELETE FROM roles_permisos_tablas;
ALTER SEQUENCE roles_permisos_tablas_rol_permiso_tabla_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - TODOS LOS PERMISOS EN 0
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 1, t.tabla_id, 1, 0, 0, 0, 0, 0, 0, 1000, 1 
FROM tablas t 
WHERE t.estado_id = 1000;

-- ROL: ADMINISTRADOR (rol_id = 2) - PERMISOS GENERALES Y RESTRICCIONES CRÍTICAS
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    2,
    t.tabla_id,
    1, 1, 1, 1, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END, 
    1, 1,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre NOT IN ('roles_permisos_tablas', 'ninguno');

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    3,
    t.tabla_id,
    1, 0, 0, 0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre NOT IN ('roles_permisos_tablas', 'ninguno');

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - OPERATIVO CON RESTRICCIONES
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    4,
    t.tabla_id,
    1, 1, 1, 1, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END, 
    CASE 
        WHEN t.nombre IN ('kardex', 'ordenes_compra', 'control_facturas', 'lotes_productos', 'kardex_productos', 'planes_pagos', 'pagos', 'comprobantes_pagos') THEN 1 
        ELSE 0 
    END,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre NOT IN ('roles_permisos_tablas', 'ninguno');

-- ROL: COMPRADOR (rol_id = 5) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    5,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('proveedores', 'proveedores_contactos', 'ordenes_compra', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos') THEN 1
        WHEN t.nombre IN ('proveedores_rating_historico', 'parametros_globales', 'tareas_programadas') THEN 1
        WHEN t.nombre IN ('kardex', 'kardex_productos', 'lotes_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('proveedores', 'proveedores_contactos', 'ordenes_compra', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos') THEN 1
        WHEN t.nombre IN ('kardex', 'kardex_productos', 'lotes_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('proveedores', 'proveedores_contactos', 'ordenes_compra', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('proveedores', 'proveedores_contactos', 'proveedores_rating_historico', 'kardex', 'kardex_productos', 'lotes_productos', 'ordenes_compra', 'parametros_globales', 'tareas_programadas', 'tipos_planes_pago', 'planes_pagos', 'comprobantes_pagos', 'pagos');

-- ROL: VENDEDOR (rol_id = 6) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    6,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('clientes', 'productos', 'kardex', 'kardex_productos', 'lotes_productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos') THEN 1
        WHEN t.nombre IN ('listas_precios', 'precios_productos', 'politicas_precios', 'cajas', 'movimientos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('clientes', 'productos', 'kardex', 'kardex_productos', 'lotes_productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('clientes', 'productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('clientes', 'productos', 'kardex', 'kardex_productos', 'lotes_productos', 'pedidos_online', 'detalles_pedidos_online', 'carritos_compra', 'detalles_carritos', 'listas_precios', 'precios_productos', 'politicas_precios', 'cajas', 'movimientos');

-- ROL: ALMACENERO (rol_id = 7) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    7,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos_ubicaciones', 'kardex', 'lotes_productos', 'kardex_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos') THEN 1
        WHEN t.nombre IN ('productos', 'umbrales_configuracion', 'analitica_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos_ubicaciones', 'kardex', 'lotes_productos', 'kardex_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos_ubicaciones', 'lotes_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('almacenes', 'ubicaciones', 'almacenes_puntos_venta', 'productos', 'productos_ubicaciones', 'kardex', 'lotes_productos', 'kardex_productos', 'ubicaciones_movimientos', 'ubicaciones_historial', 'inventarios_fisicos_detalle', 'inventarios_fisicos', 'umbrales_configuracion', 'analitica_productos');

-- ROL: CAJERO (rol_id = 8) - SIN ANULAR
INSERT INTO roles_permisos_tablas (rol_id, tabla_id, leer, crear, editar, eliminar, anular, archivar, desarchivar, estado_id, usuario_id_registro)
SELECT 
    8,
    t.tabla_id,
    CASE 
        WHEN t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle') THEN 1
        WHEN t.nombre IN ('control_facturas', 'bancos', 'listas_precios', 'precios_productos') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle') THEN 1
        ELSE 0
    END,
    CASE 
        WHEN t.nombre IN ('comprobantes_pagos', 'pagos', 'cajas', 'arqueos_detalle') THEN 1
        ELSE 0
    END,
    0, 0, 0, 0,
    1000, 2
FROM tablas t
WHERE t.estado_id = 1000
AND t.nombre IN ('clientes', 'kardex', 'kardex_productos', 'lotes_productos', 'control_facturas', 'comprobantes_pagos', 'pagos', 'cajas', 'movimientos', 'arqueos_detalle', 'bancos', 'listas_precios', 'precios_productos');

SELECT setval('roles_permisos_tablas_rol_permiso_tabla_id_seq', COALESCE((SELECT MAX(rol_permiso_tabla_id) FROM roles_permisos_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_tablas));

-- ================================================================================================

DELETE FROM roles_permisos_sucesos;
ALTER SEQUENCE roles_permisos_sucesos_rol_permiso_suceso_id_seq RESTART WITH 1;

-- ROL: NINGUNO (rol_id = 1) - SIN PERMISOS DE SUCESOS
-- No se insertan registros para NINGUNO

-- ROL: ADMINISTRADOR (rol_id = 2) - TODOS LOS SUCESOS PERMITIDOS
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 2
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA, SIN SUCESOS
-- No se insertan registros para GERENTE (solo lectura)

-- ROL: ENCARGADO DE SUCURSAL (rol_id = 4) - TODOS LOS SUCESOS PERMITIDOS
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 4
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: COMPRADOR (rol_id = 5) - SOLO SUCESOS DE COMPRA Y SOLICITUD_COMPRA
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 5
AND t.nombre = 'kardex'
AND s.suceso_id IN (1050, 1058)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: VENDEDOR (rol_id = 6) - SUCESOS DE VENTA, PROFORMA Y VENTA_RESERVA
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 6
AND t.nombre = 'kardex'
AND s.suceso_id IN (1051, 1052, 1059)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: ALMACENERO (rol_id = 7) - SUCESOS DE TRASPASOS, AJUSTES, INVENTARIO FISICO, ETC
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 7
AND t.nombre = 'kardex'
AND s.suceso_id IN (1053, 1054, 1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

-- ROL: CAJERO (rol_id = 8) - SOLO SUCESO DE VENTA
INSERT INTO roles_permisos_sucesos (rol_permiso_tabla_id, suceso_id, estado_id, usuario_id_registro)
SELECT 
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000, 2
FROM roles_permisos_tablas rpt
INNER JOIN tablas t ON rpt.tabla_id = t.tabla_id
CROSS JOIN sucesos s
WHERE rpt.rol_id = 8
AND t.nombre = 'kardex'
AND s.suceso_id IN (1051)
AND rpt.estado_id = 1000
AND s.estado_id = 1000;

SELECT setval('roles_permisos_sucesos_rol_permiso_suceso_id_seq', COALESCE((SELECT MAX(rol_permiso_suceso_id) FROM roles_permisos_sucesos), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_sucesos));

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

SELECT setval('roles_menus_rol_menu_id_seq', COALESCE((SELECT MAX(rol_menu_id) FROM roles_menus), 0), (SELECT COUNT(*) > 0 FROM roles_menus));

-- ================================================================================================

DELETE FROM inventarios_fisicos;
ALTER SEQUENCE inventarios_fisicos_inventario_fisico_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos (inventario_fisico_id,almacen_id,ubicacion_id,fecha_conteo,fecha_inicio,fecha_fin,trabajador_responsable_id,trabajador_supervisor_id,estado_id,observaciones,usuario_id_registro) VALUES
	 (1,1,1,'2026-08-31','2026-08-31 11:27:15.050412-04',NULL,1,1,1000,'REGISTRO INICIAL COMODIN DE INVENTARIO FISICO',1),
	 (2,2,2,'2026-07-01','2026-07-01 08:00:00-04','2026-07-01 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA A - NIVEL 1',2),
	 (3,2,3,'2026-07-02','2026-07-02 08:00:00-04','2026-07-02 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA A - NIVEL 2',2),
	 (4,2,4,'2026-07-03','2026-07-03 08:00:00-04','2026-07-03 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA A - NIVEL 3',2),
	 (5,2,5,'2026-07-04','2026-07-04 08:00:00-04','2026-07-04 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA B - NIVEL 1',2),
	 (6,2,6,'2026-07-05','2026-07-05 08:00:00-04','2026-07-05 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA B - NIVEL 2',2),
	 (7,2,7,'2026-07-06','2026-07-06 08:00:00-04','2026-07-06 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA B - NIVEL 3',2),
	 (8,2,8,'2026-07-07','2026-07-07 08:00:00-04','2026-07-07 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA C - NIVEL 1',2),
	 (9,2,9,'2026-07-08','2026-07-08 08:00:00-04','2026-07-08 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA C - NIVEL 2',2),
	 (10,2,10,'2026-07-09','2026-07-09 08:00:00-04','2026-07-09 17:00:00-04',2,3,1000,'INVENTARIO FISICO - ESTANTERIA C - NIVEL 3',2),
	 (11,3,11,'2026-07-10','2026-07-10 08:00:00-04','2026-07-10 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 1',2),
	 (12,3,12,'2026-07-11','2026-07-11 08:00:00-04','2026-07-11 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 2',2),
	 (13,3,13,'2026-07-12','2026-07-12 08:00:00-04','2026-07-12 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 3',2),
	 (14,3,14,'2026-07-13','2026-07-13 08:00:00-04','2026-07-13 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 01 - BANDEJA 4',2),
	 (15,3,15,'2026-07-14','2026-07-14 08:00:00-04','2026-07-14 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 02 - BANDEJA 1',2),
	 (16,3,16,'2026-07-15','2026-07-15 08:00:00-04','2026-07-15 17:00:00-04',2,3,1000,'INVENTARIO FISICO - REFRIGERADOR 02 - BANDEJA 2',2),
	 (17,4,17,'2026-07-16','2026-07-16 08:00:00-04','2026-07-16 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 01 - BANDEJA 1',2),
	 (18,4,18,'2026-07-17','2026-07-17 08:00:00-04','2026-07-17 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 01 - BANDEJA 2',2),
	 (19,4,19,'2026-07-18','2026-07-18 08:00:00-04','2026-07-18 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 02 - BANDEJA 1',2),
	 (20,4,20,'2026-07-19','2026-07-19 08:00:00-04','2026-07-19 17:00:00-04',2,3,1000,'INVENTARIO FISICO - CONGELADOR 02 - BANDEJA 2',2);

SELECT setval('inventarios_fisicos_inventario_fisico_id_seq', COALESCE((SELECT MAX(inventario_fisico_id) FROM inventarios_fisicos), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos));

-- ================================================================================================

DELETE FROM clientes;
ALTER SEQUENCE clientes_cliente_id_seq RESTART WITH 1;

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_base_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(1, 1150, 'NINGUNO', NULL, NULL, '0', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 1);

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_base_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(2, 1151, 'DISTRIBUIDORA FARMA BOLIVIA S.A.', '123456789012', 'DISTRIBUIDORA FARMA BOLIVIA S.A.', '123456789012', NULL, 2204, 'AV. MONTENEGRO NRO. 450, EDIF. BUSINESS CENTER, PISO 3, LA PAZ', '22889977', 'ventas@distribuidorafarma.bo', 3, '4000009876', 1, 25000.00, 1000, 2),
(3, 1151, 'LABORATORIOS BOLIVIANOS S.A.', '987654321098', 'LABORATORIOS BOLIVIANOS S.A.', '987654321098', NULL, 2204, 'CALLE MURILLO NRO. 789, ZONA INDUSTRIAL, EL ALTO, LA PAZ', '22881144', 'administracion@labbol.com.bo', 4, '3000006543', 1, 50000.00, 1000, 2);

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_base_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
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

SELECT setval('clientes_cliente_id_seq', COALESCE((SELECT MAX(cliente_id) FROM clientes), 0), (SELECT COUNT(*) > 0 FROM clientes));

-- ================================================================================================

DELETE FROM categorias;
ALTER SEQUENCE categorias_categoria_id_seq RESTART WITH 1;

INSERT INTO categorias (categoria_id, empresa_nit_id, categoria_padre_id, categoria, codigo, descripcion, nivel, orden, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNA', 'N00', 'Categoría predeterminada para productos sin clasificar', 1, 0, 1000, 1),
(2, 2, NULL, 'MEDICAMENTOS', 'MED', 'Categoría principal para medicamentos en general', 1, 1, 1000, 2),
(3, 3, NULL, 'JUGUETES', 'JUG', 'Categoría principal para juguetes y artículos recreativos', 1, 2, 1000, 2),
(4, 4, NULL, 'SERVICIOS_MEDICOS', 'SMD', 'Categoría principal para servicios médicos y consultas', 1, 3, 1000, 2),
(5, 5, NULL, 'ELECTRONICA', 'ELEC', 'Categoría principal para equipos electrónicos y dispositivos', 1, 4, 1000, 2),
(6, 6, NULL, 'ESCRITORIO', 'ESC', 'Categoría principal para material de escritorio y suministros', 1, 5, 1000, 2),
(7, 7, NULL, 'LIBROS', 'LIB', 'Categoría principal para venta de libros', 1, 6, 1000, 2),
(8, 1, 2, 'ANALGESICOS', 'MED-1', NULL, 2, 1, 1000, 2),
(9, 1, 2, 'ANTIBIOTICOS', 'MED-2', NULL, 2, 2, 1000, 2),
(10, 1, 2, 'ANTIHISTAMINICOS', 'MED-3', NULL, 2, 3, 1000, 2),
(11, 1, 2, 'ANTIINFLAMATORIOS', 'MED-4', NULL, 2, 4, 1000, 2),
(12, 1, 2, 'ANTIACIDOS', 'MED-5', NULL, 2, 5, 1000, 2),
(13, 1, 2, 'ANTIESPASMODICOS', 'MED-6', NULL, 2, 6, 1000, 2),
(14, 1, 2, 'ANTIDEPRESIVOS', 'MED-7', NULL, 2, 7, 1000, 2),
(15, 1, 2, 'ANTIPSICOTICOS', 'MED-8', NULL, 2, 8, 1000, 2),
(16, 1, 2, 'ANTIEMETICOS', 'MED-9', NULL, 2, 9, 1000, 2),
(17, 1, 2, 'ANTIFUNGICOS', 'MED-10', NULL, 2, 10, 1000, 2),
(18, 1, 2, 'ANTIVIRALES', 'MED-11', NULL, 2, 11, 1000, 2),
(19, 1, 2, 'BRONCODILATADORES', 'MED-12', NULL, 2, 12, 1000, 2),
(20, 1, 2, 'CORTICOIDES', 'MED-13', NULL, 2, 13, 1000, 2),
(21, 1, 2, 'DIURETICOS', 'MED-14', NULL, 2, 14, 1000, 2),
(22, 1, 2, 'LAXANTES', 'MED-15', NULL, 2, 15, 1000, 2),
(23, 1, 2, 'VITAMINAS', 'MED-16', NULL, 2, 16, 1000, 2),
(24, 1, 2, 'SUPLEMENTOS', 'MED-17', NULL, 2, 17, 1000, 2),
(25, 1, 2, 'ANTIPIRETICOS', 'MED-18', NULL, 2, 18, 1000, 2),
(26, 1, 2, 'ANTITUSIVOS', 'MED-19', NULL, 2, 19, 1000, 2),
(27, 1, 2, 'EXPECTORANTES', 'MED-20', NULL, 2, 20, 1000, 2),
(28, 1, 2, 'MUCOLITICOS', 'MED-21', NULL, 2, 21, 1000, 2),
(29, 1, 2, 'ANTICONVULSIVANTES', 'MED-22', NULL, 2, 22, 1000, 2),
(30, 1, 2, 'HIPOGLUCEMIANTES', 'MED-23', NULL, 2, 23, 1000, 2),
(31, 1, 2, 'HIPOTENSORES', 'MED-24', NULL, 2, 24, 1000, 2),
(32, 1, 2, 'VASODILATADORES', 'MED-25', NULL, 2, 25, 1000, 2),
(33, 1, 2, 'ANTICOAGULANTES', 'MED-26', NULL, 2, 26, 1000, 2),
(34, 1, 2, 'ANTIAGREGANTES', 'MED-27', NULL, 2, 27, 1000, 2),
(35, 1, 2, 'ANTIANEMICOS', 'MED-28', NULL, 2, 28, 1000, 2),
(36, 1, 2, 'ANTIPARASITARIOS', 'MED-29', NULL, 2, 29, 1000, 2),
(37, 1, 2, 'ANTIPROTOZOARIOS', 'MED-30', NULL, 2, 30, 1000, 2),
(38, 1, 2, 'ANTIRRETROVIRALES', 'MED-31', NULL, 2, 31, 1000, 2),
(39, 1, 2, 'INMUNOSUPRESORES', 'MED-32', NULL, 2, 32, 1000, 2),
(40, 1, 2, 'ANTIARTRITICOS', 'MED-33', NULL, 2, 33, 1000, 2),
(41, 1, 2, 'ANTIGOTOSOS', 'MED-34', NULL, 2, 34, 1000, 2),
(42, 1, 2, 'ANTIHELMINTICOS', 'MED-35', NULL, 2, 35, 1000, 2),
(43, 1, 2, 'ANTIPRURITICOS', 'MED-36', NULL, 2, 36, 1000, 2),
(44, 1, 2, 'ANTISEPTICOS', 'MED-37', NULL, 2, 37, 1000, 2),
(45, 1, 2, 'DESINFECTANTES', 'MED-38', NULL, 2, 38, 1000, 2),
(46, 1, 2, 'ANESTESICOS', 'MED-39', NULL, 2, 39, 1000, 2),
(47, 1, 2, 'ANALGESICOS_OPIOIDES', 'MED-40', NULL, 2, 40, 1000, 2),
(48, 1, 2, 'ANALGESICOS_NO_OPIOIDES', 'MED-41', NULL, 2, 41, 1000, 2),
(49, 1, 2, 'ANTIMIGRAÑOSOS', 'MED-42', NULL, 2, 42, 1000, 2),
(50, 1, 2, 'ANTIANGINOSOS', 'MED-43', NULL, 2, 43, 1000, 2),
(51, 1, 2, 'ANTIARRITMICOS', 'MED-44', NULL, 2, 44, 1000, 2),
(52, 1, 2, 'CARDIOTONICOS', 'MED-45', NULL, 2, 45, 1000, 2),
(53, 1, 2, 'HIPOLIPEMIANTES', 'MED-46', NULL, 2, 46, 1000, 2),
(54, 1, 2, 'ANTIOBESIDAD', 'MED-47', NULL, 2, 47, 1000, 2),
(55, 1, 2, 'ANTIDIABETICOS', 'MED-48', NULL, 2, 48, 1000, 2),
(56, 1, 2, 'HORMONAS', 'MED-49', NULL, 2, 49, 1000, 2),
(57, 1, 2, 'ANTIALERGICOS', 'MED-50', NULL, 2, 50, 1000, 2),
(58, 1, 3, 'JUEGOS_DE_MESA', 'JUG-1', NULL, 2, 1, 1000, 2),
(59, 1, 3, 'JUGUETES_EDUCATIVOS', 'JUG-2', NULL, 2, 2, 1000, 2),
(60, 1, 3, 'PELUCHES', 'JUG-3', NULL, 2, 3, 1000, 2),
(61, 1, 3, 'VEHICULOS', 'JUG-4', NULL, 2, 4, 1000, 2),
(62, 1, 3, 'MUÑECAS', 'JUG-5', NULL, 2, 5, 1000, 2),
(63, 1, 4, 'INYECCIÓN', 'SMD-1', NULL, 2, 1, 1000, 2),
(64, 1, 4, 'DIAGNOSTICO', 'SMD-2', NULL, 2, 2, 1000, 2),
(65, 1, 5, 'LAPTOPS', 'ELEC-1', NULL, 2, 1, 1000, 2),
(66, 1, 5, 'TABLES', 'ELEC-2', NULL, 2, 2, 1000, 2),
(67, 1, 5, 'CELULARES', 'ELEC-3', NULL, 2, 3, 1000, 2),
(68, 1, 5, 'VIDEO', 'ELEC-4', NULL, 2, 4, 1000, 2),
(69, 1, 5, 'TECLADOS', 'ELEC-5', NULL, 2, 5, 1000, 2),
(70, 1, 6, 'PAPEL', 'ESC-1', NULL, 2, 1, 1000, 2),
(71, 1, 6, 'CUADERNOS', 'ESC-2', NULL, 2, 2, 1000, 2),
(72, 1, 6, 'BOLIGRAFOS', 'ESC-3', NULL, 2, 3, 1000, 2),
(73, 1, 6, 'ARCHIVADORES', 'ESC-4', NULL, 2, 4, 1000, 2),
(74, 1, 6, 'LAPICES', 'ESC-5', NULL, 2, 5, 1000, 2),
(75, 1, 7, 'FICCION', 'LIB-1', NULL, 2, 1, 1000, 2),
(76, 1, 7, 'TERROR', 'LIB-2', NULL, 2, 2, 1000, 2),
(77, 1, 7, 'CIENCIA', 'LIB-3', NULL, 2, 3, 1000, 2),
(80, 1, 7, 'HISTORIA', 'LIB-4', NULL, 2, 4, 1000, 2),
(81, 1, 7, 'INFANTILES', 'LIB-5', NULL, 2, 5, 1000, 2);

SELECT setval('categorias_categoria_id_seq', COALESCE((SELECT MAX(categoria_id) FROM categorias), 0), (SELECT COUNT(*) > 0 FROM categorias));

-- ================================================================================================

DELETE FROM laboratorios;
ALTER SEQUENCE laboratorios_laboratorio_id_seq RESTART WITH 1;

INSERT INTO laboratorios (laboratorio_id, codigo, laboratorio, nit, direccion, telefono, email, web, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, NULL, NULL, NULL, 1000, 1),
(2, 'INT', 'LABORATORIOS INTI S.A.', '1023456012', 'AV. JUAN PABLO II NRO. 1500, ZONA VILLA DOLORES, EL ALTO, LA PAZ', '22885566', 'info@inti.com.bo', 'www.inti.com.bo', 1000, 2),
(3, 'BAG', 'BAGÓ DE BOLIVIA S.A.', '1029876543', 'CALLE 1 NRO. 50, PARQUE INDUSTRIAL, EL ALTO, LA PAZ', '22884433', 'atencion@bago.com.bo', 'www.bago.com.bo', 1000, 2),
(4, 'FAR', 'FARMACÉUTICA BOLIVIANA S.A.', '1034567890', 'AV. MONTES NRO. 789, ZONA INDUSTRIAL, EL ALTO, LA PAZ', '22887788', 'contacto@far-bol.com.bo', 'www.far-bol.com', 1000, 2),
(5, 'MCN', 'MCNEIL BOLIVIA S.R.L.', '1045678901', 'EDIF. EMPRESARIAL, PISO 8, AV. ARCE NRO. 2121, SOPOCACHI, LA PAZ', '22445566', 'info@mcneil.com.bo', 'www.mcneil.com.bo', 1000, 2),
(6, 'ROC', 'LABORATORIOS ROCHE BOLIVIA S.A.', '1056789012', 'AV. 6 DE AGOSTO NRO. 2800, EDIF. TOWER, PISO 10, LA PAZ', '22448899', 'contacto@roche.com.bo', 'www.roche.com.bo', 1000, 2);

SELECT setval('laboratorios_laboratorio_id_seq', COALESCE((SELECT MAX(laboratorio_id) FROM laboratorios), 0), (SELECT COUNT(*) > 0 FROM laboratorios));

-- ================================================================================================

DELETE FROM formas;
ALTER SEQUENCE formas_forma_id_seq RESTART WITH 1;

INSERT INTO formas (forma_id, forma_farmaceutica, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', 'Forma farmacéutica predeterminada para productos sin clasificar', 1000, 1),
(2, 'COMPRIMIDO', 'COM', 'Forma sólida de dosificación que contiene uno o más principios activos', 1000, 2),
(3, 'CAPSULA', 'CAP', 'Envoltura gelatinosa que contiene un principio activo en polvo, gránulos o líquido', 1000, 2),
(4, 'JARABE', 'JAR', 'Solución acuosa concentrada de sacarosa con principio activo, de consistencia viscosa', 1000, 2),
(5, 'INYECTABLE', 'INY', 'Solución estéril para administración parenteral', 1000, 2),
(6, 'GOTAS', 'GOT', 'Solución líquida administrada en gotas, generalmente para uso oral u oftálmico', 1000, 2),
(7, 'CREMA', 'CRE', 'Emulsión semisólida para aplicación tópica', 1000, 2),
(8, 'UNGUENTO', 'UNG', 'Preparación semisólida de consistencia blanda para aplicación tópica', 1000, 2),
(9, 'POLVO', 'POL', 'Preparación en forma de polvo para reconstitución o administración directa', 1000, 2),
(10, 'SUPOSITORIO', 'SUP', 'Forma sólida de dosificación para administración rectal', 1000, 2),
(11, 'GEL', 'GEL', 'Sistema coloidal semisólido de consistencia firme para aplicación tópica', 1000, 2),
(12, 'SOLUCION', 'SOL', 'Preparación líquida que contiene uno o más principios activos disueltos en un solvente adecuado', 1000, 2),
(13, 'SUSPENSION', 'SUS', 'Preparación líquida que contiene partículas sólidas dispersas en un líquido', 1000, 2),
(14, 'EMULSION', 'EMU', 'Sistema disperso de dos líquidos inmiscibles, uno en forma de gotas dispersas en el otro', 1000, 2),
(15, 'POMADA', 'POM', 'Preparación semisólida de consistencia grasosa para aplicación tópica', 1000, 2),
(16, 'LOCION', 'LOC', 'Preparación líquida para aplicación tópica sin fricción', 1000, 2),
(17, 'JABON', 'JAB', 'Preparación sólida o líquida con propiedades detergentes para limpieza y desinfección', 1000, 2),
(18, 'CHAMPU', 'CHA', 'Preparación líquida con tensioactivos para limpieza del cuero cabelludo y cabello', 1000, 2),
(19, 'AEROSOL', 'AER', 'Preparación que contiene el principio activo en un sistema presurizado para liberación en forma de partículas finas', 1000, 2),
(20, 'INHALADOR', 'INH', 'Dispositivo que administra medicamento en forma de aerosol para inhalación pulmonar', 1000, 2),
(21, 'PARCHE', 'PAR', 'Sistema transdérmico que libera el principio activo a través de la piel', 1000, 2),
(22, 'GRANULADO', 'GRA', 'Agregados de partículas de polvo que forman gránulos para reconstitución o administración oral', 1000, 2),
(23, 'COMPRIMIDO RECUBIERTO', 'CORE', 'Comprimido con una capa externa que protege el principio activo o mejora la deglución', 1000, 2),
(24, 'COMPRIMIDO MASTICABLE', 'COMA', 'Comprimido diseñado para ser masticado antes de tragar', 1000, 2),
(25, 'COMPRIMIDO EFERVESCENTE', 'COEF', 'Comprimido que se disuelve en agua liberando burbujas de dióxido de carbono', 1000, 2),
(26, 'CAPSULA BLANDA', 'CBL', 'Cápsula de gelatina blanda que contiene líquidos o suspensiones', 1000, 2),
(27, 'CAPSULA DURA', 'CDU', 'Cápsula de gelatina dura que contiene polvos o gránulos', 1000, 2),
(28, 'ELIXIR', 'ELI', 'Solución hidroalcohólica dulce que contiene principios activos, generalmente para uso oral', 1000, 2),
(29, 'TINTURA', 'TIN', 'Solución hidroalcohólica obtenida por maceración o percolación de drogas vegetales', 1000, 2),
(30, 'EXTRACTO', 'EXT', 'Preparación concentrada de principios activos de origen vegetal o animal', 1000, 2),
(31, 'OVULO', 'OVU', 'Forma sólida de dosificación para administración vaginal', 1000, 2),
(32, 'ESPUMA', 'ESP', 'Dispersión de gas en un líquido con agentes tensioactivos, para aplicación tópica o vaginal', 1000, 2),
(33, 'POLVO PARA RECONSTITUIR', 'PRE', 'Polvo estéril que requiere adición de solvente antes de la administración', 1000, 2),
(34, 'LIOFILIZADO', 'LIO', 'Producto liofilizado que requiere reconstitución antes de su uso', 1000, 2),
(35, 'PASTA', 'PAS', 'Preparación semisólida con alto contenido de partículas sólidas para aplicación tópica', 1000, 2),
(36, 'CERA', 'CER', 'Preparación sólida o semisólida con base de ceras para aplicación tópica', 1000, 2),
(37, 'BAÑO', 'BAN', 'Preparación concentrada para diluir en agua de baño con fines terapéuticos', 1000, 2),
(38, 'GOMA DE MASCAR', 'GOM', 'Preparación masticable que libera principios activos durante la masticación', 1000, 2),
(39, 'PELICULA ORAL', 'PEL', 'Película delgada que se disuelve en la cavidad oral liberando el principio activo', 1000, 2),
(40, 'ESPRAY', 'ESPR', 'Solución o suspensión administrada en forma de rocío fino para aplicación oral o tópica', 1000, 2);

SELECT setval('formas_forma_id_seq', COALESCE((SELECT MAX(forma_id) FROM formas), 0), (SELECT COUNT(*) > 0 FROM formas));

-- ================================================================================================

DELETE FROM presentaciones;
ALTER SEQUENCE presentaciones_presentacion_id_seq RESTART WITH 1;

INSERT INTO presentaciones (presentacion_id, unidad_id, codigo, presentacion, cantidad_unidades, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 1, 'Presentación predeterminada para productos sin clasificar', 1000, 1),
(2, 9, 'TAB', 'TABLETA', 1, 'Tableta individual para administración oral', 1000, 2),
(3, 9, 'CAP', 'CAPSULA', 1, 'Cápsula individual para administración oral', 1000, 2),
(4, 9, 'AMP', 'AMP0LLA', 1, 'Ampolla individual para administración inyectable', 1000, 2),
(5, 9, 'FRAS', 'FRASCO', 1, 'Frasco individual para medicamentos líquidos', 1000, 2),
(6, 9, 'OVU', 'OVULO', 1, 'Óvulo individual para administración vaginal', 1000, 2),
(7, 9, 'SUP', 'SUPOSITORIO', 1, 'Supositorio individual para administración rectal', 1000, 2),
(8, 9, 'SOB', 'SOBRE', 1, 'Sobre individual para medicamentos en polvo o granulados', 1000, 2),
(9, 9, 'TUB', 'TUBO', 1, 'Tubo individual para cremas y ungüentos', 1000, 2),
(10, 11, 'CJ10', 'CAJA X 10 TABLETAS', 10, 'Caja conteniendo 10 tabletas', 1000, 2),
(11, 11, 'CJ20', 'CAJA X 20 TABLETAS', 20, 'Caja conteniendo 20 tabletas', 1000, 2),
(12, 11, 'CJ30', 'CAJA X 30 TABLETAS', 30, 'Caja conteniendo 30 tabletas', 1000, 2),
(13, 11, 'CJ50', 'CAJA X 50 TABLETAS', 50, 'Caja conteniendo 50 tabletas', 1000, 2),
(14, 11, 'CJ100', 'CAJA X 100 TABLETAS', 100, 'Caja conteniendo 100 tabletas', 1000, 2),
(15, 11, 'CJC10', 'CAJA X 10 CAPSULAS', 10, 'Caja conteniendo 10 cápsulas', 1000, 2),
(16, 11, 'CJC20', 'CAJA X 20 CAPSULAS', 20, 'Caja conteniendo 20 cápsulas', 1000, 2),
(17, 11, 'CJA10', 'CAJA X 10 AMPOLLAS', 10, 'Caja conteniendo 10 ampollas', 1000, 2),
(18, 9, 'FRX100', 'FRASCO X 100 ML', 1, 'Frasco de 100 ml para jarabes y soluciones', 1000, 2),
(19, 9, 'FRX250', 'FRASCO X 250 ML', 1, 'Frasco de 250 ml para jarabes y soluciones', 1000, 2),
(20, 9, 'TUB30', 'TUBO X 30 G', 1, 'Tubo de 30 gramos para cremas y ungüentos', 1000, 2),
(21, 9, 'TUB50', 'TUBO X 50 G', 1, 'Tubo de 50 gramos para cremas y ungüentos', 1000, 2),
(22, 11, 'CJX5', 'CAJA X 5 TABLETAS', 5, 'Caja conteniendo 5 tabletas', 1000, 2),
(23, 11, 'CJX60', 'CAJA X 60 TABLETAS', 60, 'Caja conteniendo 60 tabletas', 1000, 2),
(24, 11, 'CJX90', 'CAJA X 90 TABLETAS', 90, 'Caja conteniendo 90 tabletas', 1000, 2),
(25, 11, 'CJX120', 'CAJA X 120 TABLETAS', 120, 'Caja conteniendo 120 tabletas', 1000, 2),
(26, 11, 'CJX180', 'CAJA X 180 TABLETAS', 180, 'Caja conteniendo 180 tabletas', 1000, 2),
(27, 11, 'CJX250', 'CAJA X 250 TABLETAS', 250, 'Caja conteniendo 250 tabletas', 1000, 2),
(28, 11, 'CJX500', 'CAJA X 500 TABLETAS', 500, 'Caja conteniendo 500 tabletas', 1000, 2),
(29, 11, 'CJCX5', 'CAJA X 5 CAPSULAS', 5, 'Caja conteniendo 5 cápsulas', 1000, 2),
(30, 11, 'CJCX30', 'CAJA X 30 CAPSULAS', 30, 'Caja conteniendo 30 cápsulas', 1000, 2),
(31, 11, 'CJCX50', 'CAJA X 50 CAPSULAS', 50, 'Caja conteniendo 50 cápsulas', 1000, 2),
(32, 11, 'CJCX60', 'CAJA X 60 CAPSULAS', 60, 'Caja conteniendo 60 cápsulas', 1000, 2),
(33, 11, 'CJCX90', 'CAJA X 90 CAPSULAS', 90, 'Caja conteniendo 90 cápsulas', 1000, 2),
(34, 11, 'CJCX100', 'CAJA X 100 CAPSULAS', 100, 'Caja conteniendo 100 cápsulas', 1000, 2),
(35, 11, 'CJAX5', 'CAJA X 5 AMPOLLAS', 5, 'Caja conteniendo 5 ampollas', 1000, 2),
(36, 11, 'CJAX20', 'CAJA X 20 AMPOLLAS', 20, 'Caja conteniendo 20 ampollas', 1000, 2),
(37, 11, 'CJAX50', 'CAJA X 50 AMPOLLAS', 50, 'Caja conteniendo 50 ampollas', 1000, 2),
(38, 11, 'CJAX100', 'CAJA X 100 AMPOLLAS', 100, 'Caja conteniendo 100 ampollas', 1000, 2),
(39, 9, 'FRX15', 'FRASCO X 15 ML', 1, 'Frasco de 15 ml para soluciones oftálmicas o gotas', 1000, 2),
(40, 9, 'FRX30', 'FRASCO X 30 ML', 1, 'Frasco de 30 ml para colirios o soluciones', 1000, 2),
(41, 9, 'FRX50', 'FRASCO X 50 ML', 1, 'Frasco de 50 ml para jarabes o soluciones', 1000, 2),
(42, 9, 'FRX60', 'FRASCO X 60 ML', 1, 'Frasco de 60 ml para medicamentos líquidos', 1000, 2),
(43, 9, 'FRX120', 'FRASCO X 120 ML', 1, 'Frasco de 120 ml para jarabes', 1000, 2),
(44, 9, 'FRX200', 'FRASCO X 200 ML', 1, 'Frasco de 200 ml para soluciones orales', 1000, 2),
(45, 9, 'FRX500', 'FRASCO X 500 ML', 1, 'Frasco de 500 ml para soluciones o jarabes', 1000, 2),
(46, 9, 'FRX1000', 'FRASCO X 1000 ML', 1, 'Frasco de 1000 ml (1 litro) para soluciones', 1000, 2),
(47, 9, 'TUBX5', 'TUBO X 5 G', 1, 'Tubo de 5 gramos para cremas o ungüentos', 1000, 2),
(48, 9, 'TUBX10', 'TUBO X 10 G', 1, 'Tubo de 10 gramos para cremas', 1000, 2),
(49, 9, 'TUBX15', 'TUBO X 15 G', 1, 'Tubo de 15 gramos para cremas y ungüentos', 1000, 2),
(50, 9, 'TUBX20', 'TUBO X 20 G', 1, 'Tubo de 20 gramos para cremas', 1000, 2),
(51, 9, 'TUBX40', 'TUBO X 40 G', 1, 'Tubo de 40 gramos para cremas y ungüentos', 1000, 2),
(52, 9, 'TUBX60', 'TUBO X 60 G', 1, 'Tubo de 60 gramos para cremas', 1000, 2),
(53, 9, 'TUBX100', 'TUBO X 100 G', 1, 'Tubo de 100 gramos para cremas', 1000, 2),
(54, 9, 'SOBX5', 'SOBRE X 5 G', 1, 'Sobre de 5 gramos para polvos', 1000, 2),
(55, 9, 'SOBX10', 'SOBRE X 10 G', 1, 'Sobre de 10 gramos para polvos', 1000, 2),
(56, 9, 'SOBX15', 'SOBRE X 15 G', 1, 'Sobre de 15 gramos para polvos', 1000, 2),
(57, 9, 'SOBX20', 'SOBRE X 20 G', 1, 'Sobre de 20 gramos para polvos', 1000, 2),
(58, 9, 'SOBX30', 'SOBRE X 30 G', 1, 'Sobre de 30 gramos para polvos', 1000, 2),
(59, 11, 'CJSX5', 'CAJA X 5 SOBRES', 5, 'Caja conteniendo 5 sobres', 1000, 2),
(60, 11, 'CJSX10', 'CAJA X 10 SOBRES', 10, 'Caja conteniendo 10 sobres', 1000, 2),
(61, 11, 'CJSX20', 'CAJA X 20 SOBRES', 20, 'Caja conteniendo 20 sobres', 1000, 2),
(62, 11, 'CJSX30', 'CAJA X 30 SOBRES', 30, 'Caja conteniendo 30 sobres', 1000, 2),
(63, 9, 'POTX15', 'POTE X 15 G', 1, 'Pote de 15 gramos para cremas o pomadas', 1000, 2),
(64, 9, 'POTX30', 'POTE X 30 G', 1, 'Pote de 30 gramos para cremas', 1000, 2),
(65, 9, 'POTX50', 'POTE X 50 G', 1, 'Pote de 50 gramos para cremas o ungüentos', 1000, 2),
(66, 9, 'POTX100', 'POTE X 100 G', 1, 'Pote de 100 gramos para cremas', 1000, 2),
(67, 9, 'POTX250', 'POTE X 250 G', 1, 'Pote de 250 gramos para cremas', 1000, 2),
(68, 11, 'CJOV10', 'CAJA X 10 OVULOS', 10, 'Caja conteniendo 10 óvulos vaginales', 1000, 2),
(69, 11, 'CJSUP10', 'CAJA X 10 SUPOSITORIOS', 10, 'Caja conteniendo 10 supositorios', 1000, 2),
(70, 11, 'CJSUP12', 'CAJA X 12 SUPOSITORIOS', 12, 'Caja conteniendo 12 supositorios', 1000, 2),
(71, 11, 'CJSUP6', 'CAJA X 6 SUPOSITORIOS', 6, 'Caja conteniendo 6 supositorios', 1000, 2);

SELECT setval('presentaciones_presentacion_id_seq', COALESCE((SELECT MAX(presentacion_id) FROM presentaciones), 0), (SELECT COUNT(*) > 0 FROM presentaciones));

-- ================================================================================================

DELETE FROM concentraciones;
ALTER SEQUENCE concentraciones_concentracion_id_seq RESTART WITH 1;

INSERT INTO concentraciones (concentracion_id, unidad_base_id, codigo, concentracion, valor_numerico, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 0.00, 'Concentración predeterminada para productos sin clasificar', 1000, 1),
(2, 5, '500MG', '500 MG', 500.00, 'Concentración de 500 miligramos', 1000, 2),
(3, 5, '100MG', '100 MG', 100.00, 'Concentración de 100 miligramos', 1000, 2),
(4, 5, '50MG', '50 MG', 50.00, 'Concentración de 50 miligramos', 1000, 2),
(5, 5, '25MG', '25 MG', 25.00, 'Concentración de 25 miligramos', 1000, 2),
(6, 5, '10MG', '10 MG', 10.00, 'Concentración de 10 miligramos', 1000, 2),
(7, 5, '5MG', '5 MG', 5.00, 'Concentración de 5 miligramos', 1000, 2),
(8, 5, '750MG', '750 MG', 750.00, 'Concentración de 750 miligramos', 1000, 2),
(9, 5, '1000MG', '1000 MG', 1000.00, 'Concentración de 1000 miligramos', 1000, 2),
(10, 6, '500ML', '500 ML', 500.00, 'Concentración de 500 mililitros', 1000, 2),
(11, 6, '250ML', '250 ML', 250.00, 'Concentración de 250 mililitros', 1000, 2),
(12, 6, '100ML', '100 ML', 100.00, 'Concentración de 100 mililitros', 1000, 2),
(13, 6, '50ML', '50 ML', 50.00, 'Concentración de 50 mililitros', 1000, 2),
(14, 6, '30ML', '30 ML', 30.00, 'Concentración de 30 mililitros', 1000, 2),
(15, 6, '15ML', '15 ML', 15.00, 'Concentración de 15 mililitros', 1000, 2),
(16, 5, '200MG', '200 MG', 200.00, 'Concentración de 200 miligramos', 1000, 2),
(17, 5, '150MG', '150 MG', 150.00, 'Concentración de 150 miligramos', 1000, 2),
(18, 5, '75MG', '75 MG', 75.00, 'Concentración de 75 miligramos', 1000, 2),
(19, 5, '20MG', '20 MG', 20.00, 'Concentración de 20 miligramos', 1000, 2),
(20, 5, '2MG', '2 MG', 2.00, 'Concentración de 2 miligramos', 1000, 2),
(21, 5, '1MG', '1 MG', 1.00, 'Concentración de 1 miligramo', 1000, 2),
(22, 6, '10ML', '10 ML', 10.00, 'Concentración de 10 mililitros', 1000, 2),
(23, 6, '20ML', '20 ML', 20.00, 'Concentración de 20 mililitros', 1000, 2),
(24, 6, '60ML', '60 ML', 60.00, 'Concentración de 60 mililitros', 1000, 2),
(25, 6, '120ML', '120 ML', 120.00, 'Concentración de 120 mililitros', 1000, 2),
(26, 6, '200ML', '200 ML', 200.00, 'Concentración de 200 mililitros', 1000, 2),
(27, 6, '1000ML', '1000 ML', 1000.00, 'Concentración de 1000 mililitros (1 litro)', 1000, 2),
(28, 5, '40MG', '40 MG', 40.00, 'Concentración de 40 miligramos', 1000, 2),
(29, 5, '30MG', '30 MG', 30.00, 'Concentración de 30 miligramos', 1000, 2),
(30, 5, '15MG', '15 MG', 15.00, 'Concentración de 15 miligramos', 1000, 2),
(31, 5, '7.5MG', '7.5 MG', 7.50, 'Concentración de 7.5 miligramos', 1000, 2),
(32, 5, '2.5MG', '2.5 MG', 2.50, 'Concentración de 2.5 miligramos', 1000, 2),
(33, 5, '0.5MG', '0.5 MG', 0.50, 'Concentración de 0.5 miligramos', 1000, 2),
(34, 5, '125MG', '125 MG', 125.00, 'Concentración de 125 miligramos', 1000, 2),
(35, 5, '250MG', '250 MG', 250.00, 'Concentración de 250 miligramos', 1000, 2),
(36, 5, '375MG', '375 MG', 375.00, 'Concentración de 375 miligramos', 1000, 2),
(37, 5, '625MG', '625 MG', 625.00, 'Concentración de 625 miligramos', 1000, 2),
(38, 5, '875MG', '875 MG', 875.00, 'Concentración de 875 miligramos', 1000, 2),
(39, 5, '1200MG', '1200 MG', 1200.00, 'Concentración de 1200 miligramos', 1000, 2),
(40, 5, '1500MG', '1500 MG', 1500.00, 'Concentración de 1500 miligramos', 1000, 2),
(41, 2, '1KG', '1 KG', 1.00, 'Concentración de 1 kilogramo', 1000, 2),
(42, 2, '5KG', '5 KG', 5.00, 'Concentración de 5 kilogramos', 1000, 2),
(43, 3, '100G', '100 G', 100.00, 'Concentración de 100 gramos', 1000, 2),
(44, 3, '200G', '200 G', 200.00, 'Concentración de 200 gramos', 1000, 2),
(45, 3, '500G', '500 G', 500.00, 'Concentración de 500 gramos', 1000, 2),
(46, 14, '10MCG', '10 MCG', 10.00, 'Concentración de 10 microgramos', 1000, 2),
(47, 14, '20MCG', '20 MCG', 20.00, 'Concentración de 20 microgramos', 1000, 2),
(48, 14, '50MCG', '50 MCG', 50.00, 'Concentración de 50 microgramos', 1000, 2),
(49, 14, '100MCG', '100 MCG', 100.00, 'Concentración de 100 microgramos', 1000, 2),
(50, 14, '200MCG', '200 MCG', 200.00, 'Concentración de 200 microgramos', 1000, 2),
(51, 15, '1000UI', '1000 UI', 1000.00, 'Concentración de 1000 unidades internacionales', 1000, 2),
(52, 15, '5000UI', '5000 UI', 5000.00, 'Concentración de 5000 unidades internacionales', 1000, 2);

SELECT setval('concentraciones_concentracion_id_seq', COALESCE((SELECT MAX(concentracion_id) FROM concentraciones), 0), (SELECT COUNT(*) > 0 FROM concentraciones));

-- ================================================================================================

DELETE FROM vias;
ALTER SEQUENCE vias_via_id_seq RESTART WITH 1;

INSERT INTO vias (via_id, nombre, descripcion, requiere_ayuno, tiempo_efecto_minutos, precauciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'Vía de administración predeterminada para productos sin clasificar', 0, NULL, NULL, 1000, 1),
(2, 'ORAL', 'Administración por vía oral (tragado). La más común para medicamentos en comprimidos, cápsulas y jarabes.', 0, 30, 'Tomar con suficiente agua. No masticar comprimidos de liberación prolongada.', 1000, 2),
(3, 'SUBLINGUAL', 'Administración bajo la lengua. Absorción rápida a través de la mucosa sublingual.', 1, 5, 'No tragar, dejar disolver completamente bajo la lengua. No comer ni beber hasta su completa absorción.', 1000, 2),
(4, 'BUCAL', 'Administración en la cavidad bucal, entre la encía y la mejilla.', 0, 15, 'No masticar ni tragar. Colocar entre la encía y la mejilla hasta su completa disolución.', 1000, 2),
(5, 'TÓPICA', 'Aplicación directa sobre la piel o mucosas. Incluye cremas, ungüentos, geles y soluciones.', 0, NULL, 'Aplicar sobre piel limpia y seca. Evitar contacto con ojos, mucosas y zonas irritadas.', 1000, 2),
(6, 'TRANSDÉRMICA', 'Administración a través de la piel mediante parches adhesivos. Liberación controlada y sostenida.', 0, 120, 'Aplicar sobre piel sana y sin vello. Cambiar de sitio de aplicación para evitar irritación.', 1000, 2),
(7, 'INHALADA', 'Administración por inhalación. Utilizada en afecciones respiratorias como asma y EPOC.', 0, 5, 'Agitar el inhalador antes de usar. Mantener una técnica correcta de inhalación.', 1000, 2),
(8, 'NASAL', 'Administración por vía nasal en forma de gotas o aerosol. Para descongestión o tratamientos locales.', 0, 5, 'Limpiar la nariz antes de usar. No inclinar la cabeza hacia atrás bruscamente.', 1000, 2),
(9, 'INTRAMUSCULAR', 'Administración inyectable en el músculo. Absorción rápida y eficaz.', 1, 15, 'Solo personal capacitado. Aspirar antes de inyectar para evitar punción venosa.', 1000, 2),
(10, 'INTRAVENOSA', 'Administración inyectable directamente en el torrente sanguíneo. Efecto inmediato.', 1, 1, 'Solo personal médico calificado. Control estricto de velocidad de infusión.', 1000, 2),
(11, 'SUBCUTÁNEA', 'Administración inyectable en el tejido subcutáneo. Absorción lenta y sostenida.', 1, 20, 'Solo personal capacitado. Rotar los sitios de inyección para evitar lipodistrofia.', 1000, 2),
(12, 'RECTAL', 'Administración por vía rectal mediante supositorios o enemas. Útil cuando la vía oral no es posible.', 1, 30, 'Introducir el supositorio con el dedo, apuntando hacia el ombligo. Permanecer acostado unos minutos.', 1000, 2),
(13, 'VAGINAL', 'Administración por vía vaginal mediante óvulos, cremas o tabletas vaginales.', 0, 30, 'Usar aplicador si está incluido. Acostarse durante 15-20 minutos después de la aplicación.', 1000, 2),
(14, 'OFTÁLMICA', 'Administración en el ojo mediante gotas o ungüentos oftálmicos. Para tratar infecciones y afecciones oculares.', 0, NULL, 'Lavarse las manos antes y después. No tocar el ojo con el aplicador.', 1000, 2),
(15, 'ÓTICA', 'Administración en el oído mediante gotas óticas. Para tratar infecciones del oído externo.', 0, NULL, 'Templar el frasco antes de usar. Inclinar la cabeza y permanecer unos minutos.', 1000, 2);

SELECT setval('vias_via_id_seq', COALESCE((SELECT MAX(via_id) FROM vias), 0), (SELECT COUNT(*) > 0 FROM vias));

-- ================================================================================================

DELETE FROM rangos_edad;
ALTER SEQUENCE rangos_edad_rango_edad_id_seq RESTART WITH 1;

INSERT INTO rangos_edad (rango_edad_id, codigo, rango, edad_minima_meses, edad_maxima_meses, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'No especificado / General', NULL, NULL, 'Rango de edad predeterminado para productos sin clasificación etaria', 1000, 1),
(2, 'RECIEN', 'Recién Nacido', 0, 1, '0 a 28 días de vida. Mayor vulnerabilidad a medicamentos.', 1000, 2),
(3, 'LACTANTE_1-6M', 'Lactante 1-6 meses', 1, 6, '1 a 6 meses de edad. Sistema en desarrollo.', 1000, 2),
(4, 'LACTANTE_6-12M', 'Lactante 6-12 meses', 6, 12, '6 a 12 meses de edad. Introducción de alimentos sólidos.', 1000, 2),
(5, 'LACTANTE_1-12M', 'Lactante (1-12 meses)', 1, 12, 'De 1 mes a 1 año de edad. Etapa de rápido crecimiento.', 1000, 2),
(6, 'NINO_1-3A', 'Niño 1-3 años', 12, 36, 'De 1 a 3 años. Etapa de desarrollo motor y cognitivo.', 1000, 2),
(7, 'NINO_3-5A', 'Niño 3-5 años', 36, 72, 'De 3 a 5 años. Etapa preescolar.', 1000, 2),
(8, 'PREESCOLAR', 'Preescolar (1-5 años)', 12, 72, 'De 1 a 5 años (12 a 60 meses).', 1000, 2),
(9, 'ESCOLAR_5-12A', 'Escolar (5-12 años)', 72, 144, 'De 5 a 12 años. Etapa escolar.', 1000, 2),
(10, 'PEDIATRICO_GRAL', 'Pediátrico General', 0, 144, 'Desde recién nacido hasta los 12 años. Todos los rangos pediátricos.', 1000, 2),
(11, 'ADOLECENTE_12-15A', 'Adolescente 12-15 años', 144, 180, 'De 12 a 15 años. Pubertad y cambios hormonales.', 1000, 2),
(12, 'ADOLECENTE_15-18A', 'Adolescente 15-18 años', 180, 216, 'De 15 a 18 años. Adolescencia tardía.', 1000, 2),
(13, 'ADOLECENTE_12-18A', 'Adolescente (12-18 años)', 144, 216, 'De 12 a 18 años. Etapa de transición a la adultez.', 1000, 2),
(14, 'ADULTO_18-40A', 'Adulto 18-40 años', 216, 480, 'De 18 a 40 años. Etapa de plenitud física.', 1000, 2),
(15, 'ADULTO_40-65A', 'Adulto 40-65 años', 480, 780, 'De 40 a 65 años. Etapa de madurez.', 1000, 2),
(16, 'ADULTO_18-65A', 'Adulto (18-65 años)', 216, 780, 'De 18 a 65 años. Población adulta general.', 1000, 2),
(17, 'ADULTO_MAYOR_65-75A', 'Adulto Mayor 65-75 años', 780, 900, 'De 65 a 75 años. Tercera edad.', 1000, 2),
(18, 'ADULTO_MAYOR_75-85A', 'Adulto Mayor 75-85 años', 900, 1020, 'De 75 a 85 años. Cuarta edad.', 1000, 2),
(19, 'ADULTO_MAYOR_85A', 'Adulto Mayor 85+ años', 1020, NULL, 'Mayores de 85 años. Quinta edad.', 1000, 2),
(20, 'ADULTO_MAYOR_GERIATRICO', 'Adulto Mayor / Geriátrico', 780, NULL, 'Mayores de 65 años. Población geriátrica.', 1000, 2);

SELECT setval('rangos_edad_rango_edad_id_seq', COALESCE((SELECT MAX(rango_edad_id) FROM rangos_edad), 0), (SELECT COUNT(*) > 0 FROM rangos_edad));

-- ================================================================================================

DELETE FROM marcas;
ALTER SEQUENCE marcas_marca_id_seq RESTART WITH 1;

INSERT INTO marcas (marca_id, nombre, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'Marca predeterminada para productos genéricos o sin marca especificada', 1000, 1),
(2, 'BAYER', 'Laboratorio farmacéutico alemán, líder en medicamentos y productos de salud', 1000, 2),
(3, 'NOVARTIS', 'Laboratorio farmacéutico suizo, especializado en medicamentos de alta complejidad', 1000, 2),
(4, 'PFIZER', 'Laboratorio farmacéutico estadounidense, uno de los más grandes del mundo', 1000, 2),
(5, 'GSK', 'GlaxoSmithKline, laboratorio británico especializado en vacunas y medicamentos', 1000, 2),
(6, 'INTI', 'Laboratorio farmacéutico boliviano de medicamentos genéricos', 1000, 2),
(7, 'ROZEN', 'Marca de medicamentos de venta libre y cuidado personal', 1000, 2),
(8, 'FARMABOL', 'Marca boliviana de medicamentos genéricos y suplementos', 1000, 2),
(9, 'LABORATORIOS BAGÓ', 'Marca de medicamentos de origen argentino con presencia en Bolivia', 1000, 2),
(10, 'MCNEIL', 'Marca de productos de consumo y medicamentos OTC', 1000, 2),
(11, 'ROCHE', 'Laboratorio suizo, especialidad en oncología y medicamentos de alta complejidad', 1000, 2),
(12, 'LEGO', 'Marca danesa de juguetes de construcción y bloques', 1000, 2),
(13, 'MATTEL', 'Marca estadounidense de juguetes, incluyendo Barbie y Hot Wheels', 1000, 2),
(14, 'HASBRO', 'Marca estadounidense de juegos de mesa y juguetes', 1000, 2),
(15, 'FISHER PRICE', 'Marca de juguetes educativos y para bebés', 1000, 2),
(16, 'PLAYMOBIL', 'Marca alemana de figuras y escenarios de juego', 1000, 2),
(17, 'HP', 'Hewlett-Packard, marca de computadoras, laptops e impresoras', 1000, 2),
(18, 'DELL', 'Marca de computadoras y equipos tecnológicos', 1000, 2),
(19, 'SAMSUNG', 'Marca coreana de teléfonos, tablets y electrónica', 1000, 2),
(20, 'APPLE', 'Marca estadounidense de productos tecnológicos de alta gama', 1000, 2),
(21, 'LENOVO', 'Marca china de computadoras y dispositivos tecnológicos', 1000, 2),
(22, 'XEROX', 'Marca de fotocopiadoras, impresoras y material de oficina', 1000, 2),
(23, 'PILOT', 'Marca japonesa de lapiceros, bolígrafos y material de escritura', 1000, 2),
(24, 'BIC', 'Marca francesa de bolígrafos, encendedores y artículos de oficina', 1000, 2),
(25, 'MAPED', 'Marca francesa de material escolar y de oficina', 1000, 2),
(26, '3M', 'Marca estadounidense de productos industriales, oficina y salud', 1000, 2),
(27, 'COLGATE', 'Marca de productos de higiene personal y cuidado bucal', 1000, 2),
(28, 'PALMOLIVE', 'Marca de productos de cuidado personal y limpieza', 1000, 2),
(29, 'JOHNSON & JOHNSON', 'Marca de productos para bebés, cuidado personal y farmacéuticos', 1000, 2),
(30, 'NIVEA', 'Marca alemana de productos de cuidado personal y cosmética', 1000, 2),
(31, 'LOREAL', 'Marca francesa de cosméticos y productos de belleza', 1000, 2),
(32, 'PROCTER & GAMBLE', 'Marca de productos de limpieza, cuidado personal y del hogar', 1000, 2);

SELECT setval('marcas_marca_id_seq', COALESCE((SELECT MAX(marca_id) FROM marcas), 0), (SELECT COUNT(*) > 0 FROM marcas));

-- ================================================================================================

DELETE FROM productos;
ALTER SEQUENCE productos_producto_id_seq RESTART WITH 1;

INSERT INTO productos (producto_id,categoria_id,laboratorio_id,marca_id,forma_id,presentacion_id,concentracion_id,unidad_venta_id,tipo_almacen_id,codigo,codigo_barras,sku,isbn,serie,modelo,nombre,nombre_generico,pcompra,p_factor_venta,p_factor_facturacion,pventa,pventaf,stock_minimo,stock_maximo,punto_reorden,requiere_receta,controlado,tiene_registro_sanitario,descripcion,observacion,foto1,foto2,foto3,criticidad_medica_id,estado_id,usuario_id_registro) VALUES
	 (1,1,1,1,1,1,1,1,1700,'NIN',NULL,NULL,NULL,NULL,NULL,'NINGUNO',NULL,0.00,1.50,1.19,0.00,0.00,0.00,0.00,0.00,0,0,0,'Producto predeterminado para casos sin clasificar',NULL,NULL,NULL,NULL,4150,1000,1),
	 (2,8,2,2,2,10,2,9,1700,'SM-8-00001',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.50,1.50,1.19,3.75,2.98,10.00,200.00,25.00,0,0,1,'Alivio rápido y efectivo del dolor de cabeza, dental, muscular y fiebre. Fórmula confiable con acción antiinflamatoria.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (3,8,2,2,2,11,2,9,1700,'SM-8-00002',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.80,1.50,1.19,7.20,5.71,10.00,150.00,20.00,0,0,1,'Presentación económica en caja de 20 tabletas para el alivio de dolores leves a moderados y reducción de fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (4,8,2,2,2,12,2,9,1700,'SM-8-00003',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',6.90,1.50,1.19,10.35,8.21,10.00,120.00,15.00,0,0,1,'Caja de 30 tabletas de Aspirina 500 mg para el tratamiento sintomático del dolor y la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (5,8,2,2,2,13,2,9,1700,'SM-8-00004',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 50 TABLETAS','ACIDO ACETILSALICILICO',10.50,1.50,1.19,15.75,12.50,5.00,100.00,10.00,0,0,1,'Formato familiar de 50 tabletas de Aspirina 500 mg, ideal para uso prolongado en dolores musculares y articulares.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (6,8,6,11,2,10,7,9,1700,'SM-8-00005',NULL,NULL,NULL,NULL,NULL,'DOLO-NEUROBION 5 MG CAJA X 10 TABLETAS','DICLOFENACO SODICO',3.20,1.50,1.19,4.80,3.81,10.00,180.00,20.00,0,0,1,'Alivio del dolor neuropático y muscular con Diclofenaco 5 mg. Fórmula de rápida absorción.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (7,8,6,11,2,12,7,9,1700,'SM-8-00006',NULL,NULL,NULL,NULL,NULL,'DOLO-NEUROBION 5 MG CAJA X 30 TABLETAS','DICLOFENACO SODICO',8.50,1.50,1.19,12.75,10.12,10.00,120.00,15.00,0,0,1,'Tratamiento efectivo para el dolor agudo y crónico. Caja de 30 tabletas de 5 mg de Diclofenaco.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (8,8,3,9,2,10,3,9,1700,'SM-8-00007',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 10 TABLETAS','IBUPROFENO',2.10,1.50,1.19,3.15,2.50,10.00,200.00,25.00,0,0,1,'Antiinflamatorio no esteroideo para el alivio del dolor de cabeza, dental y muscular. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (9,8,3,9,2,11,3,9,1700,'SM-8-00008',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 20 TABLETAS','IBUPROFENO',3.80,1.50,1.19,5.70,4.52,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 100 mg para el manejo del dolor y la inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (10,8,3,9,2,12,3,9,1700,'SM-8-00009',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 30 TABLETAS','IBUPROFENO',5.40,1.50,1.19,8.10,6.43,10.00,120.00,15.00,0,0,1,'Ideal para tratamientos prolongados de dolor muscular y articular. 30 tabletas de 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (11,8,3,9,2,13,3,9,1700,'SM-8-00010',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 50 TABLETAS','IBUPROFENO',8.20,1.50,1.19,12.30,9.76,5.00,100.00,10.00,0,0,1,'Presentación económica de 50 tabletas de Ibuprofeno 100 mg para uso familiar.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (12,8,4,8,2,10,6,9,1700,'SM-8-00011',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 10 TABLETAS','PARACETAMOL',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Analgésico y antipirético de uso común. 10 mg por tableta para alivio rápido de la fiebre y el dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (13,8,4,8,2,11,6,9,1700,'SM-8-00012',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 20 TABLETAS','PARACETAMOL',3.20,1.50,1.19,4.80,3.81,10.00,150.00,20.00,0,0,1,'Alivio efectivo del dolor y la fiebre. Caja de 20 tabletas de 10 mg de Paracetamol.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (14,8,4,8,2,12,6,9,1700,'SM-8-00013',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 30 TABLETAS','PARACETAMOL',4.50,1.50,1.19,6.75,5.36,10.00,120.00,15.00,0,0,1,'Tratamiento sintomático del dolor y la fiebre. 30 tabletas de Paracetamol 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (15,8,4,8,2,13,6,9,1700,'SM-8-00014',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 10 MG CAJA X 50 TABLETAS','PARACETAMOL',7.00,1.50,1.19,10.50,8.33,5.00,100.00,10.00,0,0,1,'Formato familiar de 50 tabletas de Paracetamol 10 mg para el hogar.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (16,8,5,10,2,14,2,9,1700,'SM-8-00015',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 100 TABLETAS','ACIDO ACETILSALICILICO',18.50,1.50,1.19,27.75,22.02,5.00,80.00,8.00,0,0,1,'Caja de 100 tabletas de Aspirina 500 mg para uso prolongado en tratamientos cardiovasculares.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (17,9,2,2,2,10,2,9,1700,'SM-9-00001',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 10 TABLETAS','AMOXICILINA TRIHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,180.00,20.00,1,0,1,'Antibiótico de amplio espectro para infecciones respiratorias, urinarias y de piel. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (18,9,2,2,2,11,2,9,1700,'SM-9-00002',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 20 TABLETAS','AMOXICILINA TRIHIDRATO',8.00,1.50,1.19,12.00,9.52,10.00,150.00,15.00,1,0,1,'Tratamiento antibiótico de 20 tabletas de Amoxicilina 500 mg para infecciones bacterianas.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (19,9,2,2,2,12,2,9,1700,'SM-9-00003',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 30 TABLETAS','AMOXICILINA TRIHIDRATO',11.00,1.50,1.19,16.50,13.09,10.00,120.00,12.00,1,0,1,'Caja de 30 tabletas de Amoxicilina 500 mg para tratamientos prolongados de infecciones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (20,9,2,2,2,13,2,9,1700,'SM-9-00004',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 50 TABLETAS','AMOXICILINA TRIHIDRATO',17.50,1.50,1.19,26.25,20.83,5.00,100.00,10.00,1,0,1,'Antibiótico de amplio espectro en presentación de 50 tabletas de 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (21,9,2,2,3,15,2,9,1700,'SM-9-00005',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 10 CAPSULAS','AMOXICILINA TRIHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,18.00,1,0,1,'Cápsulas de Amoxicilina 500 mg para infecciones bacterianas. Fácil administración.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (22,9,2,2,3,16,2,9,1700,'SM-9-00006',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 20 CAPSULAS','AMOXICILINA TRIHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,14.00,1,0,1,'Caja de 20 cápsulas de Amoxicilina 500 mg para el tratamiento de infecciones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (23,9,2,2,3,30,2,9,1700,'SM-9-00007',NULL,NULL,NULL,NULL,NULL,'AMOXICILINA 500 MG CAJA X 30 CAPSULAS','AMOXICILINA TRIHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'Cápsulas de 500 mg de Amoxicilina para uso prolongado en infecciones respiratorias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (24,9,3,9,2,10,8,9,1700,'SM-9-00008',NULL,NULL,NULL,NULL,NULL,'CLARITROMICINA 750 MG CAJA X 10 TABLETAS','CLARITROMICINA',6.50,1.50,1.19,9.75,7.74,10.00,160.00,18.00,1,0,1,'Antibiótico macrólido para infecciones respiratorias y de piel. 750 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (25,9,3,9,2,11,8,9,1700,'SM-9-00009',NULL,NULL,NULL,NULL,NULL,'CLARITROMICINA 750 MG CAJA X 20 TABLETAS','CLARITROMICINA',12.00,1.50,1.19,18.00,14.28,10.00,130.00,15.00,1,0,1,'Caja de 20 tabletas de Claritromicina 750 mg para infecciones bacterianas.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (26,9,3,9,2,12,8,9,1700,'SM-9-00010',NULL,NULL,NULL,NULL,NULL,'CLARITROMICINA 750 MG CAJA X 30 TABLETAS','CLARITROMICINA',17.00,1.50,1.19,25.50,20.23,10.00,100.00,12.00,1,0,1,'Tratamiento prolongado con 30 tabletas de Claritromicina 750 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (27,9,4,8,2,10,34,9,1700,'SM-9-00011',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 10 TABLETAS','AZITROMICINA DIHIDRATADA',4.00,1.50,1.19,6.00,4.76,10.00,170.00,20.00,1,0,1,'Antibiótico de espectro extendido para infecciones respiratorias y de piel. 125 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (28,9,4,8,2,11,34,9,1700,'SM-9-00012',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 20 TABLETAS','AZITROMICINA DIHIDRATADA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Azitromicina 125 mg para tratamientos cortos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (29,9,4,8,2,12,34,9,1700,'SM-9-00013',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 30 TABLETAS','AZITROMICINA DIHIDRATADA',10.00,1.50,1.19,15.00,11.90,10.00,110.00,15.00,1,0,1,'Tratamiento de 30 tabletas de Azitromicina 125 mg para infecciones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (30,9,4,8,2,13,34,9,1700,'SM-9-00014',NULL,NULL,NULL,NULL,NULL,'AZITROMICINA 125 MG CAJA X 50 TABLETAS','AZITROMICINA DIHIDRATADA',16.00,1.50,1.19,24.00,19.04,5.00,90.00,10.00,1,0,1,'Formato de 50 tabletas de Azitromicina 125 mg para uso prolongado.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (31,9,6,11,2,10,35,9,1700,'SM-9-00015',NULL,NULL,NULL,NULL,NULL,'CEFALEXINA 250 MG CAJA X 10 TABLETAS','CEFALEXINA MONOHIDRATADA',3.80,1.50,1.19,5.70,4.52,10.00,180.00,20.00,1,0,1,'Cefalosporina de primera generación para infecciones respiratorias y urinarias. 250 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (32,10,2,2,2,10,7,9,1700,'SM-10-00001',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 10 TABLETAS','LORATADINA',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antihistamínico para el alivio de los síntomas de alergia estacional. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (33,10,2,2,2,11,7,9,1700,'SM-10-00002',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 20 TABLETAS','LORATADINA',3.90,1.50,1.19,5.85,4.64,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Loratadina 5 mg para alergias estacionales.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (34,10,2,2,2,12,7,9,1700,'SM-10-00003',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 30 TABLETAS','LORATADINA',5.50,1.50,1.19,8.25,6.55,10.00,130.00,18.00,0,0,1,'Alivio continuo de alergias con 30 tabletas de Loratadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (35,10,3,9,2,10,19,9,1700,'SM-10-00004',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 20 MG CAJA X 10 TABLETAS','CETIRIZINA DIHIDROCLORURO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,20.00,0,0,1,'Antihistamínico de segunda generación para el control de la rinitis alérgica. 20 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (36,10,3,9,2,11,19,9,1700,'SM-10-00005',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 20 MG CAJA X 20 TABLETAS','CETIRIZINA DIHIDROCLORURO',5.40,1.50,1.19,8.10,6.43,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Cetirizina 20 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (37,10,3,9,2,12,19,9,1700,'SM-10-00006',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 20 MG CAJA X 30 TABLETAS','CETIRIZINA DIHIDROCLORURO',7.80,1.50,1.19,11.70,9.28,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Cetirizina 20 mg para síntomas alérgicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (38,10,4,8,2,10,5,9,1700,'SM-10-00007',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 10 TABLETAS','CLORFENIRAMINA MALEATO',1.60,1.50,1.19,2.40,1.90,10.00,200.00,25.00,0,0,1,'Antihistamínico clásico para el alivio de reacciones alérgicas y picazón. 25 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (39,10,4,8,2,11,5,9,1700,'SM-10-00008',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 20 TABLETAS','CLORFENIRAMINA MALEATO',2.90,1.50,1.19,4.35,3.45,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Clorfeniramina 25 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (40,10,4,8,2,12,5,9,1700,'SM-10-00009',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 30 TABLETAS','CLORFENIRAMINA MALEATO',4.00,1.50,1.19,6.00,4.76,10.00,120.00,15.00,0,0,1,'30 tabletas de Clorfeniramina 25 mg para control de alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (41,10,5,10,2,10,21,9,1700,'SM-10-00010',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 1 MG CAJA X 10 TABLETAS','DIFENHIDRAMINA CLORHIDRATO',2.00,1.50,1.19,3.00,2.38,10.00,180.00,22.00,0,0,1,'Antihistamínico con efecto sedante para el alivio de alergias y picazón. 1 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (42,10,5,10,2,11,21,9,1700,'SM-10-00011',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 1 MG CAJA X 20 TABLETAS','DIFENHIDRAMINA CLORHIDRATO',3.60,1.50,1.19,5.40,4.28,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Difenhidramina 1 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (43,10,5,10,2,12,21,9,1700,'SM-10-00012',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 1 MG CAJA X 30 TABLETAS','DIFENHIDRAMINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,110.00,14.00,0,0,1,'30 tabletas de Difenhidramina 1 mg para el control de síntomas alérgicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (44,10,6,11,2,10,33,9,1700,'SM-10-00013',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 0.5 MG CAJA X 10 TABLETAS','DESLORATADINA',2.80,1.50,1.19,4.20,3.33,10.00,170.00,20.00,0,0,1,'Antihistamínico no sedante para rinitis alérgica. 0.5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (45,10,6,11,2,11,33,9,1700,'SM-10-00014',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 0.5 MG CAJA X 20 TABLETAS','DESLORATADINA',5.20,1.50,1.19,7.80,6.19,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Desloratadina 0.5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (46,10,6,11,2,12,33,9,1700,'SM-10-00015',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 0.5 MG CAJA X 30 TABLETAS','DESLORATADINA',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,0,0,1,'Tratamiento continuo con 30 tabletas de Desloratadina 0.5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (47,11,2,2,2,10,3,9,1700,'SM-11-00001',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 10 TABLETAS','IBUPROFENO',2.10,1.50,1.19,3.15,2.50,10.00,200.00,25.00,0,0,1,'Antiinflamatorio no esteroideo para el alivio de la inflamación y el dolor. 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (48,11,2,2,2,11,3,9,1700,'SM-11-00002',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 20 TABLETAS','IBUPROFENO',3.80,1.50,1.19,5.70,4.52,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 100 mg para dolor e inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (49,11,2,2,2,12,3,9,1700,'SM-11-00003',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 100 MG CAJA X 30 TABLETAS','IBUPROFENO',5.40,1.50,1.19,8.10,6.43,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Ibuprofeno 100 mg para inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (50,11,3,9,2,10,16,9,1700,'SM-11-00004',NULL,NULL,NULL,NULL,NULL,'DICLOFENACO 200 MG CAJA X 10 TABLETAS','DICLOFENACO SODICO',3.50,1.50,1.19,5.25,4.17,10.00,180.00,22.00,0,0,1,'Antiinflamatorio para artritis y dolor muscular. 200 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (51,11,3,9,2,11,16,9,1700,'SM-11-00005',NULL,NULL,NULL,NULL,NULL,'DICLOFENACO 200 MG CAJA X 20 TABLETAS','DICLOFENACO SODICO',6.40,1.50,1.19,9.60,7.62,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Diclofenaco 200 mg para inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (52,11,3,9,2,12,16,9,1700,'SM-11-00006',NULL,NULL,NULL,NULL,NULL,'DICLOFENACO 200 MG CAJA X 30 TABLETAS','DICLOFENACO SODICO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Diclofenaco 200 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (53,11,4,8,2,10,17,9,1700,'SM-11-00007',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 150 MG CAJA X 10 TABLETAS','NAPROXENO SODICO',2.80,1.50,1.19,4.20,3.33,10.00,190.00,25.00,0,0,1,'Antiinflamatorio para dolor articular y menstrual. 150 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (54,11,4,8,2,11,17,9,1700,'SM-11-00008',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 150 MG CAJA X 20 TABLETAS','NAPROXENO SODICO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Naproxeno 150 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (55,11,4,8,2,12,17,9,1700,'SM-11-00009',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 150 MG CAJA X 30 TABLETAS','NAPROXENO SODICO',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Naproxeno 150 mg para inflamación y dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (56,11,5,10,2,10,2,9,1700,'SM-11-00010',NULL,NULL,NULL,NULL,NULL,'MELOXICAM 500 MG CAJA X 10 TABLETAS','MELOXICAM',4.20,1.50,1.19,6.30,5.00,10.00,170.00,20.00,0,0,1,'Antiinflamatorio selectivo COX-2 para artritis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (57,11,5,10,2,11,2,9,1700,'SM-11-00011',NULL,NULL,NULL,NULL,NULL,'MELOXICAM 500 MG CAJA X 20 TABLETAS','MELOXICAM',7.80,1.50,1.19,11.70,9.28,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Meloxicam 500 mg para artritis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (58,11,5,10,2,12,2,9,1700,'SM-11-00012',NULL,NULL,NULL,NULL,NULL,'MELOXICAM 500 MG CAJA X 30 TABLETAS','MELOXICAM',11.00,1.50,1.19,16.50,13.09,10.00,120.00,15.00,0,0,1,'Tratamiento prolongado con 30 tabletas de Meloxicam 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (59,11,6,11,2,10,32,9,1700,'SM-11-00013',NULL,NULL,NULL,NULL,NULL,'PIROXICAM 2.5 MG CAJA X 10 TABLETAS','PIROXICAM',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,0,0,1,'Antiinflamatorio para artritis reumatoide. 2.5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (60,11,6,11,2,11,32,9,1700,'SM-11-00014',NULL,NULL,NULL,NULL,NULL,'PIROXICAM 2.5 MG CAJA X 20 TABLETAS','PIROXICAM',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Piroxicam 2.5 mg para inflamación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (61,11,6,11,2,12,32,9,1700,'SM-11-00015',NULL,NULL,NULL,NULL,NULL,'PIROXICAM 2.5 MG CAJA X 30 TABLETAS','PIROXICAM',7.80,1.50,1.19,11.70,9.28,10.00,120.00,15.00,0,0,1,'30 tabletas de Piroxicam 2.5 mg para artritis y dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (62,12,2,2,2,10,3,9,1700,'SM-12-00001',NULL,NULL,NULL,NULL,NULL,'OMEPRAZOL 100 MG CAJA X 10 TABLETAS','OMEPRAZOL',3.00,1.50,1.19,4.50,3.57,10.00,180.00,20.00,0,0,1,'Inhibidor de la bomba de protones para el tratamiento de la úlcera gástrica. 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (63,12,2,2,2,11,3,9,1700,'SM-12-00002',NULL,NULL,NULL,NULL,NULL,'OMEPRAZOL 100 MG CAJA X 20 TABLETAS','OMEPRAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Omeprazol 100 mg para acidez estomacal.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (64,12,2,2,2,12,3,9,1700,'SM-12-00003',NULL,NULL,NULL,NULL,NULL,'OMEPRAZOL 100 MG CAJA X 30 TABLETAS','OMEPRAZOL',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,0,0,1,'Tratamiento de 30 tabletas de Omeprazol 100 mg para reflujo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (65,12,3,9,2,10,28,9,1700,'SM-12-00004',NULL,NULL,NULL,NULL,NULL,'RANITIDINA 40 MG CAJA X 10 TABLETAS','RANITIDINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antagonista H2 para úlceras y reflujo. 40 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (66,12,3,9,2,11,28,9,1700,'SM-12-00005',NULL,NULL,NULL,NULL,NULL,'RANITIDINA 40 MG CAJA X 20 TABLETAS','RANITIDINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Ranitidina 40 mg para acidez.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (67,12,3,9,2,12,28,9,1700,'SM-12-00006',NULL,NULL,NULL,NULL,NULL,'RANITIDINA 40 MG CAJA X 30 TABLETAS','RANITIDINA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,130.00,18.00,0,0,1,'30 tabletas de Ranitidina 40 mg para el tratamiento de úlceras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (68,12,4,8,2,10,29,9,1700,'SM-12-00007',NULL,NULL,NULL,NULL,NULL,'ESOMEPRAZOL 30 MG CAJA X 10 TABLETAS','ESOMEPRAZOL MAGNESICO',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,0,0,1,'Inhibidor de la bomba de protones de última generación. 30 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (69,12,4,8,2,11,29,9,1700,'SM-12-00008',NULL,NULL,NULL,NULL,NULL,'ESOMEPRAZOL 30 MG CAJA X 20 TABLETAS','ESOMEPRAZOL MAGNESICO',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Esomeprazol 30 mg para reflujo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (70,12,4,8,2,12,29,9,1700,'SM-12-00009',NULL,NULL,NULL,NULL,NULL,'ESOMEPRAZOL 30 MG CAJA X 30 TABLETAS','ESOMEPRAZOL MAGNESICO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'Tratamiento continuo con 30 tabletas de Esomeprazol 30 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (71,12,5,10,2,10,19,9,1700,'SM-12-00010',NULL,NULL,NULL,NULL,NULL,'FAMOTIDINA 20 MG CAJA X 10 TABLETAS','FAMOTIDINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antagonista H2 para el control de la secreción ácida. 20 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (72,12,5,10,2,11,19,9,1700,'SM-12-00011',NULL,NULL,NULL,NULL,NULL,'FAMOTIDINA 20 MG CAJA X 20 TABLETAS','FAMOTIDINA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Famotidina 20 mg para úlceras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (73,12,5,10,2,12,19,9,1700,'SM-12-00012',NULL,NULL,NULL,NULL,NULL,'FAMOTIDINA 20 MG CAJA X 30 TABLETAS','FAMOTIDINA',7.00,1.50,1.19,10.50,8.33,10.00,120.00,15.00,0,0,1,'30 tabletas de Famotidina 20 mg para reflujo gastroesofágico.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (74,12,6,11,2,10,4,9,1700,'SM-12-00013',NULL,NULL,NULL,NULL,NULL,'PANTROPRAZOL 50 MG CAJA X 10 TABLETAS','PANTROPRAZOL SODICO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Inhibidor de la bomba de protones para úlceras pépticas. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (75,12,6,11,2,11,4,9,1700,'SM-12-00014',NULL,NULL,NULL,NULL,NULL,'PANTROPRAZOL 50 MG CAJA X 20 TABLETAS','PANTROPRAZOL SODICO',6.30,1.50,1.19,9.45,7.50,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Pantroprazol 50 mg para acidez.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (76,12,6,11,2,12,4,9,1700,'SM-12-00015',NULL,NULL,NULL,NULL,NULL,'PANTROPRAZOL 50 MG CAJA X 30 TABLETAS','PANTROPRAZOL SODICO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,0,0,1,'30 tabletas de Pantroprazol 50 mg para el tratamiento de úlceras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (77,13,2,2,2,10,6,9,1700,'SM-13-00001',NULL,NULL,NULL,NULL,NULL,'BUSCAPINA 10 MG CAJA X 10 TABLETAS','HIDROBROMURO DE HIOSCINA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antiespasmódico para el alivio de cólicos y espasmos gastrointestinales. 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (78,13,2,2,2,11,6,9,1700,'SM-13-00002',NULL,NULL,NULL,NULL,NULL,'BUSCAPINA 10 MG CAJA X 20 TABLETAS','HIDROBROMURO DE HIOSCINA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Buscapina 10 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (79,13,2,2,2,12,6,9,1700,'SM-13-00003',NULL,NULL,NULL,NULL,NULL,'BUSCAPINA 10 MG CAJA X 30 TABLETAS','HIDROBROMURO DE HIOSCINA',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,0,0,1,'30 tabletas de Buscapina 10 mg para el tratamiento de cólicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (80,13,3,9,2,10,3,9,1700,'SM-13-00004',NULL,NULL,NULL,NULL,NULL,'BUTILBROMURO DE HIOSCINA 100 MG CAJA X 10 TABLETAS','BUTILBROMURO DE HIOSCINA',3.80,1.50,1.19,5.70,4.52,10.00,180.00,22.00,0,0,1,'Antiespasmódico para espasmos del tracto gastrointestinal. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (81,13,3,9,2,11,3,9,1700,'SM-13-00005',NULL,NULL,NULL,NULL,NULL,'BUTILBROMURO DE HIOSCINA 100 MG CAJA X 20 TABLETAS','BUTILBROMURO DE HIOSCINA',6.80,1.50,1.19,10.20,8.09,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Butilbromuro de Hiosecina 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (82,13,3,9,2,12,3,9,1700,'SM-13-00006',NULL,NULL,NULL,NULL,NULL,'BUTILBROMURO DE HIOSCINA 100 MG CAJA X 30 TABLETAS','BUTILBROMURO DE HIOSCINA',9.50,1.50,1.19,14.25,11.31,10.00,120.00,15.00,0,0,1,'30 tabletas de Butilbromuro de Hiosecina 100 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (83,13,4,8,2,10,20,9,1700,'SM-13-00007',NULL,NULL,NULL,NULL,NULL,'DROTAVERINA 2 MG CAJA X 10 TABLETAS','DROTAVERINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antiespasmódico para el alivio de dolores abdominales. 2 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (84,13,4,8,2,11,20,9,1700,'SM-13-00008',NULL,NULL,NULL,NULL,NULL,'DROTAVERINA 2 MG CAJA X 20 TABLETAS','DROTAVERINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Drotaverina 2 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (85,13,4,8,2,12,20,9,1700,'SM-13-00009',NULL,NULL,NULL,NULL,NULL,'DROTAVERINA 2 MG CAJA X 30 TABLETAS','DROTAVERINA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,130.00,18.00,0,0,1,'30 tabletas de Drotaverina 2 mg para el alivio de cólicos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (86,13,5,10,2,10,21,9,1700,'SM-13-00010',NULL,NULL,NULL,NULL,NULL,'MEPENZOLATO 1 MG CAJA X 10 TABLETAS','MEPENZOLATO BROMURO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antiespasmódico para el tratamiento de úlceras y espasmos. 1 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (87,13,5,10,2,11,21,9,1700,'SM-13-00011',NULL,NULL,NULL,NULL,NULL,'MEPENZOLATO 1 MG CAJA X 20 TABLETAS','MEPENZOLATO BROMURO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Mepenzolato 1 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (88,13,5,10,2,12,21,9,1700,'SM-13-00012',NULL,NULL,NULL,NULL,NULL,'MEPENZOLATO 1 MG CAJA X 30 TABLETAS','MEPENZOLATO BROMURO',7.00,1.50,1.19,10.50,8.33,10.00,120.00,15.00,0,0,1,'30 tabletas de Mepenzolato 1 mg para el alivio de espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (89,13,6,11,2,10,7,9,1700,'SM-13-00013',NULL,NULL,NULL,NULL,NULL,'PRIFINIO 5 MG CAJA X 10 TABLETAS','PRIFINIO BROMURO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antiespasmódico para el alivio de dolores gastrointestinales. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (90,13,6,11,2,11,7,9,1700,'SM-13-00014',NULL,NULL,NULL,NULL,NULL,'PRIFINIO 5 MG CAJA X 20 TABLETAS','PRIFINIO BROMURO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Prifinio 5 mg para espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (91,13,6,11,2,12,7,9,1700,'SM-13-00015',NULL,NULL,NULL,NULL,NULL,'PRIFINIO 5 MG CAJA X 30 TABLETAS','PRIFINIO BROMURO',5.50,1.50,1.19,8.25,6.55,10.00,130.00,18.00,0,0,1,'30 tabletas de Prifinio 5 mg para el tratamiento de espasmos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (92,14,2,2,2,10,19,9,1700,'SM-14-00001',NULL,NULL,NULL,NULL,NULL,'FLUOXETINA 20 MG CAJA X 10 TABLETAS','FLUOXETINA CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antidepresivo ISRS para el tratamiento de la depresión y trastornos de ansiedad. 20 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (93,14,2,2,2,11,19,9,1700,'SM-14-00002',NULL,NULL,NULL,NULL,NULL,'FLUOXETINA 20 MG CAJA X 20 TABLETAS','FLUOXETINA CLORHIDRATO',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Fluoxetina 20 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (94,14,2,2,2,12,19,9,1700,'SM-14-00003',NULL,NULL,NULL,NULL,NULL,'FLUOXETINA 20 MG CAJA X 30 TABLETAS','FLUOXETINA CLORHIDRATO',14.00,1.50,1.19,21.00,16.66,10.00,120.00,15.00,1,0,1,'30 tabletas de Fluoxetina 20 mg para el tratamiento de trastornos depresivos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (95,14,3,9,2,10,3,9,1700,'SM-14-00004',NULL,NULL,NULL,NULL,NULL,'SERTRALINA 100 MG CAJA X 10 TABLETAS','SERTRALINA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antidepresivo ISRS para trastorno obsesivo-compulsivo y depresión. 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (96,14,3,9,2,11,3,9,1700,'SM-14-00005',NULL,NULL,NULL,NULL,NULL,'SERTRALINA 100 MG CAJA X 20 TABLETAS','SERTRALINA CLORHIDRATO',11.00,1.50,1.19,16.50,13.09,10.00,130.00,15.00,1,0,1,'Caja de 20 tabletas de Sertralina 100 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (97,14,3,9,2,12,3,9,1700,'SM-14-00006',NULL,NULL,NULL,NULL,NULL,'SERTRALINA 100 MG CAJA X 30 TABLETAS','SERTRALINA CLORHIDRATO',15.50,1.50,1.19,23.25,18.45,10.00,110.00,12.00,1,0,1,'30 tabletas de Sertralina 100 mg para trastornos de ansiedad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (98,14,4,8,2,10,28,9,1700,'SM-14-00007',NULL,NULL,NULL,NULL,NULL,'PAROXETINA 40 MG CAJA X 10 TABLETAS','PAROXETINA CLORHIDRATO',5.80,1.50,1.19,8.70,6.90,10.00,160.00,20.00,1,0,1,'Antidepresivo ISRS para depresión mayor y trastorno de pánico. 40 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (99,14,4,8,2,11,28,9,1700,'SM-14-00008',NULL,NULL,NULL,NULL,NULL,'PAROXETINA 40 MG CAJA X 20 TABLETAS','PAROXETINA CLORHIDRATO',10.50,1.50,1.19,15.75,12.50,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Paroxetina 40 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (100,14,4,8,2,12,28,9,1700,'SM-14-00009',NULL,NULL,NULL,NULL,NULL,'PAROXETINA 40 MG CAJA X 30 TABLETAS','PAROXETINA CLORHIDRATO',14.80,1.50,1.19,22.20,17.61,10.00,120.00,15.00,1,0,1,'30 tabletas de Paroxetina 40 mg para trastornos de ansiedad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (101,14,5,10,2,10,17,9,1700,'SM-14-00010',NULL,NULL,NULL,NULL,NULL,'CITALOPRAM 150 MG CAJA X 10 TABLETAS','CITALOPRAM HIDROBROMURO',6.20,1.50,1.19,9.30,7.38,10.00,150.00,18.00,1,0,1,'Antidepresivo ISRS para depresión y trastorno de pánico. 150 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (102,14,5,10,2,11,17,9,1700,'SM-14-00011',NULL,NULL,NULL,NULL,NULL,'CITALOPRAM 150 MG CAJA X 20 TABLETAS','CITALOPRAM HIDROBROMURO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,15.00,1,0,1,'Caja de 20 tabletas de Citalopram 150 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (103,14,5,10,2,12,17,9,1700,'SM-14-00012',NULL,NULL,NULL,NULL,NULL,'CITALOPRAM 150 MG CAJA X 30 TABLETAS','CITALOPRAM HIDROBROMURO',16.00,1.50,1.19,24.00,19.04,10.00,110.00,12.00,1,0,1,'30 tabletas de Citalopram 150 mg para trastornos depresivos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (104,14,6,11,2,10,29,9,1700,'SM-14-00013',NULL,NULL,NULL,NULL,NULL,'VENLAFAXINA 30 MG CAJA X 10 TABLETAS','VENLAFAXINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,170.00,20.00,1,0,1,'Antidepresivo dual para depresión mayor. 30 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (105,14,6,11,2,11,29,9,1700,'SM-14-00014',NULL,NULL,NULL,NULL,NULL,'VENLAFAXINA 30 MG CAJA X 20 TABLETAS','VENLAFAXINA CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Venlafaxina 30 mg para depresión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (106,14,6,11,2,12,29,9,1700,'SM-14-00015',NULL,NULL,NULL,NULL,NULL,'VENLAFAXINA 30 MG CAJA X 30 TABLETAS','VENLAFAXINA CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Venlafaxina 30 mg para trastornos de ansiedad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (107,15,2,2,2,10,7,9,1700,'SM-15-00001',NULL,NULL,NULL,NULL,NULL,'RISPERIDONA 5 MG CAJA X 10 TABLETAS','RISPERIDONA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,1,1,'Antipsicótico atípico para esquizofrenia y trastorno bipolar. 5 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (108,15,2,2,2,11,7,9,1700,'SM-15-00002',NULL,NULL,NULL,NULL,NULL,'RISPERIDONA 5 MG CAJA X 20 TABLETAS','RISPERIDONA',11.00,1.50,1.19,16.50,13.09,10.00,130.00,15.00,1,1,1,'Caja de 20 tabletas de Risperidona 5 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (109,15,2,2,2,12,7,9,1700,'SM-15-00003',NULL,NULL,NULL,NULL,NULL,'RISPERIDONA 5 MG CAJA X 30 TABLETAS','RISPERIDONA',15.50,1.50,1.19,23.25,18.45,10.00,110.00,12.00,1,1,1,'30 tabletas de Risperidona 5 mg para trastornos psicóticos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (110,15,3,9,2,10,6,9,1700,'SM-15-00004',NULL,NULL,NULL,NULL,NULL,'OLANZAPINA 10 MG CAJA X 10 TABLETAS','OLANZAPINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,1,1,'Antipsicótico atípico para esquizofrenia y trastorno bipolar. 10 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (111,15,3,9,2,11,6,9,1700,'SM-15-00005',NULL,NULL,NULL,NULL,NULL,'OLANZAPINA 10 MG CAJA X 20 TABLETAS','OLANZAPINA',12.50,1.50,1.19,18.75,14.88,10.00,120.00,14.00,1,1,1,'Caja de 20 tabletas de Olanzapina 10 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (112,15,3,9,2,12,6,9,1700,'SM-15-00006',NULL,NULL,NULL,NULL,NULL,'OLANZAPINA 10 MG CAJA X 30 TABLETAS','OLANZAPINA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'30 tabletas de Olanzapina 10 mg para trastornos bipolares.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (113,15,4,8,2,10,3,9,1700,'SM-15-00007',NULL,NULL,NULL,NULL,NULL,'QUETIAPINA 100 MG CAJA X 10 TABLETAS','QUETIAPINA FUMARATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,1,1,'Antipsicótico atípico para esquizofrenia y trastorno bipolar. 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (114,15,4,8,2,11,3,9,1700,'SM-15-00008',NULL,NULL,NULL,NULL,NULL,'QUETIAPINA 100 MG CAJA X 20 TABLETAS','QUETIAPINA FUMARATO',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,1,1,'Caja de 20 tabletas de Quetiapina 100 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (115,15,4,8,2,12,3,9,1700,'SM-15-00009',NULL,NULL,NULL,NULL,NULL,'QUETIAPINA 100 MG CAJA X 30 TABLETAS','QUETIAPINA FUMARATO',14.00,1.50,1.19,21.00,16.66,10.00,120.00,15.00,1,1,1,'30 tabletas de Quetiapina 100 mg para trastornos psicóticos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (116,15,5,10,2,10,19,9,1700,'SM-15-00010',NULL,NULL,NULL,NULL,NULL,'HALOPERIDOL 20 MG CAJA X 10 TABLETAS','HALOPERIDOL',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,1,1,1,'Antipsicótico típico para psicosis y trastornos de conducta. 20 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (117,15,5,10,2,11,19,9,1700,'SM-15-00011',NULL,NULL,NULL,NULL,NULL,'HALOPERIDOL 20 MG CAJA X 20 TABLETAS','HALOPERIDOL',7.20,1.50,1.19,10.80,8.57,10.00,150.00,20.00,1,1,1,'Caja de 20 tabletas de Haloperidol 20 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (118,15,5,10,2,12,19,9,1700,'SM-15-00012',NULL,NULL,NULL,NULL,NULL,'HALOPERIDOL 20 MG CAJA X 30 TABLETAS','HALOPERIDOL',10.00,1.50,1.19,15.00,11.90,10.00,130.00,18.00,1,1,1,'30 tabletas de Haloperidol 20 mg para trastornos psicóticos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (119,15,6,11,2,10,17,9,1700,'SM-15-00013',NULL,NULL,NULL,NULL,NULL,'CLOZAPINA 150 MG CAJA X 10 TABLETAS','CLOZAPINA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Antipsicótico atípico para esquizofrenia resistente. 150 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (120,15,6,11,2,11,17,9,1700,'SM-15-00014',NULL,NULL,NULL,NULL,NULL,'CLOZAPINA 150 MG CAJA X 20 TABLETAS','CLOZAPINA',14.50,1.50,1.19,21.75,17.26,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Clozapina 150 mg para psicosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (121,15,6,11,2,12,17,9,1700,'SM-15-00015',NULL,NULL,NULL,NULL,NULL,'CLOZAPINA 150 MG CAJA X 30 TABLETAS','CLOZAPINA',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Clozapina 150 mg para esquizofrenia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (122,16,2,2,2,10,6,9,1700,'SM-16-00001',NULL,NULL,NULL,NULL,NULL,'METOCLOPRAMIDA 10 MG CAJA X 10 TABLETAS','METOCLOPRAMIDA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antiemético para el control de náuseas y vómitos. 10 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (123,16,2,2,2,11,6,9,1700,'SM-16-00002',NULL,NULL,NULL,NULL,NULL,'METOCLOPRAMIDA 10 MG CAJA X 20 TABLETAS','METOCLOPRAMIDA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Metoclopramida 10 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (124,16,2,2,2,12,6,9,1700,'SM-16-00003',NULL,NULL,NULL,NULL,NULL,'METOCLOPRAMIDA 10 MG CAJA X 30 TABLETAS','METOCLOPRAMIDA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,120.00,15.00,0,0,1,'30 tabletas de Metoclopramida 10 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (125,16,3,9,2,10,29,9,1700,'SM-16-00004',NULL,NULL,NULL,NULL,NULL,'ONDANSETRON 30 MG CAJA X 10 TABLETAS','ONDANSETRON CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Antiemético para quimioterapia y postoperatorio. 30 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (126,16,3,9,2,11,29,9,1700,'SM-16-00005',NULL,NULL,NULL,NULL,NULL,'ONDANSETRON 30 MG CAJA X 20 TABLETAS','ONDANSETRON CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Ondansetron 30 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (127,16,3,9,2,12,29,9,1700,'SM-16-00006',NULL,NULL,NULL,NULL,NULL,'ONDANSETRON 30 MG CAJA X 30 TABLETAS','ONDANSETRON CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,0,0,1,'30 tabletas de Ondansetron 30 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (128,16,4,8,2,10,6,9,1700,'SM-16-00007',NULL,NULL,NULL,NULL,NULL,'DOMPERIDONA 10 MG CAJA X 10 TABLETAS','DOMPERIDONA',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Antiemético para el tratamiento de náuseas y vómitos. 10 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (129,16,4,8,2,11,6,9,1700,'SM-16-00008',NULL,NULL,NULL,NULL,NULL,'DOMPERIDONA 10 MG CAJA X 20 TABLETAS','DOMPERIDONA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Domperidona 10 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (130,16,4,8,2,12,6,9,1700,'SM-16-00009',NULL,NULL,NULL,NULL,NULL,'DOMPERIDONA 10 MG CAJA X 30 TABLETAS','DOMPERIDONA',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Domperidona 10 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (131,16,5,10,2,10,19,9,1700,'SM-16-00010',NULL,NULL,NULL,NULL,NULL,'GRANISETRON 20 MG CAJA X 10 TABLETAS','GRANISETRON CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Antiemético para quimioterapia. 20 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (132,16,5,10,2,11,19,9,1700,'SM-16-00011',NULL,NULL,NULL,NULL,NULL,'GRANISETRON 20 MG CAJA X 20 TABLETAS','GRANISETRON CLORHIDRATO',8.00,1.50,1.19,12.00,9.52,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Granisetron 20 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (133,16,5,10,2,12,19,9,1700,'SM-16-00012',NULL,NULL,NULL,NULL,NULL,'GRANISETRON 20 MG CAJA X 30 TABLETAS','GRANISETRON CLORHIDRATO',11.00,1.50,1.19,16.50,13.09,10.00,120.00,15.00,0,0,1,'30 tabletas de Granisetron 20 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (134,16,6,11,2,10,28,9,1700,'SM-16-00013',NULL,NULL,NULL,NULL,NULL,'APREPITANT 40 MG CAJA X 10 TABLETAS','APREPITANT',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,0,0,1,'Antiemético para quimioterapia de alta emetogenicidad. 40 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (135,16,6,11,2,11,28,9,1700,'SM-16-00014',NULL,NULL,NULL,NULL,NULL,'APREPITANT 40 MG CAJA X 20 TABLETAS','APREPITANT',11.00,1.50,1.19,16.50,13.09,10.00,130.00,15.00,0,0,1,'Caja de 20 tabletas de Aprepitant 40 mg para náuseas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (136,16,6,11,2,12,28,9,1700,'SM-16-00015',NULL,NULL,NULL,NULL,NULL,'APREPITANT 40 MG CAJA X 30 TABLETAS','APREPITANT',15.50,1.50,1.19,23.25,18.45,10.00,110.00,12.00,0,0,1,'30 tabletas de Aprepitant 40 mg para el control de vómitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (137,17,2,2,7,20,2,9,1700,'SM-17-00001',NULL,NULL,NULL,NULL,NULL,'CLOTRIMAZOL 500 MG CREMA TUBO X 30 G','CLOTRIMAZOL',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Antifúngico tópico para el tratamiento de dermatofitosis. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (138,17,2,2,7,21,2,9,1700,'SM-17-00002',NULL,NULL,NULL,NULL,NULL,'CLOTRIMAZOL 500 MG CREMA TUBO X 50 G','CLOTRIMAZOL',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Clotrimazol 500 mg para infecciones por hongos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (139,17,2,2,7,20,4,9,1700,'SM-17-00003',NULL,NULL,NULL,NULL,NULL,'CLOTRIMAZOL 50 MG CREMA TUBO X 30 G','CLOTRIMAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Crema de Clotrimazol 50 mg para el tratamiento de hongos en la piel.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (140,17,3,9,7,21,4,9,1700,'SM-17-00004',NULL,NULL,NULL,NULL,NULL,'MICONAZOL 50 MG CREMA TUBO X 50 G','MICONAZOL NITRATO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antifúngico de amplio espectro para infecciones cutáneas. 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (141,17,3,9,7,20,4,9,1700,'SM-17-00005',NULL,NULL,NULL,NULL,NULL,'MICONAZOL 50 MG CREMA TUBO X 30 G','MICONAZOL NITRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Crema de Miconazol 50 mg para el tratamiento de hongos y levaduras.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (142,17,3,9,7,20,2,9,1700,'SM-17-00006',NULL,NULL,NULL,NULL,NULL,'KETOCONAZOL 500 MG CREMA TUBO X 30 G','KETOCONAZOL',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Antifúngico para dermatitis seborreica y tiña. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (143,17,3,9,7,21,2,9,1700,'SM-17-00007',NULL,NULL,NULL,NULL,NULL,'KETOCONAZOL 500 MG CREMA TUBO X 50 G','KETOCONAZOL',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Ketoconazol 500 mg para infecciones fúngicas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (144,17,4,8,7,20,5,9,1700,'SM-17-00008',NULL,NULL,NULL,NULL,NULL,'TERBINAFINA 25 MG CREMA TUBO X 30 G','TERBINAFINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,18.00,0,0,1,'Antifúngico para onicomicosis y tiña. 25 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (145,17,4,8,7,21,5,9,1700,'SM-17-00009',NULL,NULL,NULL,NULL,NULL,'TERBINAFINA 25 MG CREMA TUBO X 50 G','TERBINAFINA CLORHIDRATO',7.00,1.50,1.19,10.50,8.33,10.00,130.00,15.00,0,0,1,'Tubo de 50 g de Terbinafina 25 mg para hongos en las uñas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (146,17,4,8,7,20,2,9,1700,'SM-17-00010',NULL,NULL,NULL,NULL,NULL,'FLUCONAZOL 500 MG CREMA TUBO X 30 G','FLUCONAZOL',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Antifúngico sistémico para candidiasis. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (147,17,4,8,7,21,2,9,1700,'SM-17-00011',NULL,NULL,NULL,NULL,NULL,'FLUCONAZOL 500 MG CREMA TUBO X 50 G','FLUCONAZOL',5.80,1.50,1.19,8.70,6.90,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Fluconazol 500 mg para infecciones por hongos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (148,17,5,10,7,20,3,9,1700,'SM-17-00012',NULL,NULL,NULL,NULL,NULL,'ITRACONAZOL 100 MG CREMA TUBO X 30 G','ITRACONAZOL',4.20,1.50,1.19,6.30,5.00,10.00,150.00,18.00,0,0,1,'Antifúngico para dermatofitosis y onicomicosis. 100 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (149,17,5,10,7,21,3,9,1700,'SM-17-00013',NULL,NULL,NULL,NULL,NULL,'ITRACONAZOL 100 MG CREMA TUBO X 50 G','ITRACONAZOL',6.50,1.50,1.19,9.75,7.74,10.00,130.00,15.00,0,0,1,'Tubo de 50 g de Itraconazol 100 mg para hongos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (150,17,6,11,7,20,8,9,1700,'SM-17-00014',NULL,NULL,NULL,NULL,NULL,'VORICONAZOL 750 MG CREMA TUBO X 30 G','VORICONAZOL',5.00,1.50,1.19,7.50,5.95,10.00,140.00,16.00,0,0,1,'Antifúngico de amplio espectro para infecciones graves. 750 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (151,17,6,11,7,21,8,9,1700,'SM-17-00015',NULL,NULL,NULL,NULL,NULL,'VORICONAZOL 750 MG CREMA TUBO X 50 G','VORICONAZOL',7.80,1.50,1.19,11.70,9.28,10.00,120.00,14.00,0,0,1,'Tubo de 50 g de Voriconazol 750 mg para infecciones fúngicas graves.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (152,18,2,2,2,10,3,9,1700,'SM-18-00001',NULL,NULL,NULL,NULL,NULL,'ACICLOVIR 100 MG CAJA X 10 TABLETAS','ACICLOVIR',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Antiviral para el tratamiento del herpes simple y varicela. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (153,18,2,2,2,11,3,9,1700,'SM-18-00002',NULL,NULL,NULL,NULL,NULL,'ACICLOVIR 100 MG CAJA X 20 TABLETAS','ACICLOVIR',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Aciclovir 100 mg para herpes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (154,18,2,2,2,12,3,9,1700,'SM-18-00003',NULL,NULL,NULL,NULL,NULL,'ACICLOVIR 100 MG CAJA X 30 TABLETAS','ACICLOVIR',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Aciclovir 100 mg para herpes zoster.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (155,18,3,9,2,10,3,9,1700,'SM-18-00004',NULL,NULL,NULL,NULL,NULL,'VALACICLOVIR 100 MG CAJA X 10 TABLETAS','VALACICLOVIR CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Antiviral para el herpes labial y genital. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (156,18,3,9,2,11,3,9,1700,'SM-18-00005',NULL,NULL,NULL,NULL,NULL,'VALACICLOVIR 100 MG CAJA X 20 TABLETAS','VALACICLOVIR CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Valaciclovir 100 mg para herpes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (157,18,3,9,2,12,3,9,1700,'SM-18-00006',NULL,NULL,NULL,NULL,NULL,'VALACICLOVIR 100 MG CAJA X 30 TABLETAS','VALACICLOVIR CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Valaciclovir 100 mg para herpes zoster.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (158,18,4,8,2,10,35,9,1700,'SM-18-00007',NULL,NULL,NULL,NULL,NULL,'FAMCICLOVIR 250 MG CAJA X 10 TABLETAS','FAMCICLOVIR',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,1,0,1,'Antiviral para herpes simple y zoster. 250 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (159,18,4,8,2,11,35,9,1700,'SM-18-00008',NULL,NULL,NULL,NULL,NULL,'FAMCICLOVIR 250 MG CAJA X 20 TABLETAS','FAMCICLOVIR',8.50,1.50,1.19,12.75,10.12,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Famciclovir 250 mg para herpes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (160,18,4,8,2,12,35,9,1700,'SM-18-00009',NULL,NULL,NULL,NULL,NULL,'FAMCICLOVIR 250 MG CAJA X 30 TABLETAS','FAMCICLOVIR',12.00,1.50,1.19,18.00,14.28,10.00,120.00,15.00,1,0,1,'30 tabletas de Famciclovir 250 mg para herpes zoster.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (161,18,5,10,2,10,6,9,1700,'SM-18-00010',NULL,NULL,NULL,NULL,NULL,'RIBAVIRINA 10 MG CAJA X 10 TABLETAS','RIBAVIRINA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antiviral para hepatitis C y fiebre hemorrágica. 10 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (162,18,5,10,2,11,6,9,1700,'SM-18-00011',NULL,NULL,NULL,NULL,NULL,'RIBAVIRINA 10 MG CAJA X 20 TABLETAS','RIBAVIRINA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Ribavirina 10 mg para hepatitis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (163,18,5,10,2,12,6,9,1700,'SM-18-00012',NULL,NULL,NULL,NULL,NULL,'RIBAVIRINA 10 MG CAJA X 30 TABLETAS','RIBAVIRINA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Ribavirina 10 mg para infecciones virales.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (164,18,6,11,2,10,3,9,1700,'SM-18-00013',NULL,NULL,NULL,NULL,NULL,'OSELTAMIVIR 100 MG CAJA X 10 TABLETAS','OSELTAMIVIR FOSFATO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Antiviral para el tratamiento de la gripe tipo A y B. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (165,18,6,11,2,11,3,9,1700,'SM-18-00014',NULL,NULL,NULL,NULL,NULL,'OSELTAMIVIR 100 MG CAJA X 20 TABLETAS','OSELTAMIVIR FOSFATO',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Oseltamivir 100 mg para influenza.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (166,18,6,11,2,12,3,9,1700,'SM-18-00015',NULL,NULL,NULL,NULL,NULL,'OSELTAMIVIR 100 MG CAJA X 30 TABLETAS','OSELTAMIVIR FOSFATO',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,0,1,'30 tabletas de Oseltamivir 100 mg para el tratamiento de la gripe.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (167,19,2,2,20,19,4,9,1700,'SM-19-00001',NULL,NULL,NULL,NULL,NULL,'SALBUTAMOL 50 MG INHALADOR 200 DOSIS','SALBUTAMOL SULFATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Broncodilatador para el alivio del asma y EPOC. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (168,19,2,2,20,19,4,9,1700,'SM-19-00002',NULL,NULL,NULL,NULL,NULL,'SALBUTAMOL 50 MG INHALADOR 300 DOSIS','SALBUTAMOL SULFATO',8.50,1.50,1.19,12.75,10.12,10.00,130.00,15.00,1,0,1,'Inhalador de Salbutamol 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (169,19,3,9,20,19,4,9,1700,'SM-19-00003',NULL,NULL,NULL,NULL,NULL,'BUDESONIDA 50 MG INHALADOR 200 DOSIS','BUDESONIDA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Corticoide inhalado para el asma. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (170,19,3,9,20,19,4,9,1700,'SM-19-00004',NULL,NULL,NULL,NULL,NULL,'BUDESONIDA 50 MG INHALADOR 300 DOSIS','BUDESONIDA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,0,1,'Inhalador de Budesonida 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (171,19,4,8,20,19,4,9,1700,'SM-19-00005',NULL,NULL,NULL,NULL,NULL,'FORMOTEROL 50 MG INHALADOR 200 DOSIS','FORMOTEROL FUMARATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Broncodilatador de larga duración para EPOC. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (172,19,4,8,20,19,4,9,1700,'SM-19-00006',NULL,NULL,NULL,NULL,NULL,'FORMOTEROL 50 MG INHALADOR 300 DOSIS','FORMOTEROL FUMARATO',11.50,1.50,1.19,17.25,13.68,10.00,110.00,12.00,1,0,1,'Inhalador de Formoterol 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (173,19,5,10,20,19,5,9,1700,'SM-19-00007',NULL,NULL,NULL,NULL,NULL,'TIOTROPIO 25 MG INHALADOR 200 DOSIS','TIOTROPIO BROMURO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,0,1,'Broncodilatador de larga duración para EPOC. 25 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (174,19,5,10,20,19,5,9,1700,'SM-19-00008',NULL,NULL,NULL,NULL,NULL,'TIOTROPIO 25 MG INHALADOR 300 DOSIS','TIOTROPIO BROMURO',13.00,1.50,1.19,19.50,15.47,10.00,100.00,10.00,1,0,1,'Inhalador de Tiotropio 25 mg con 300 dosis para EPOC.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (175,19,6,11,20,19,4,9,1700,'SM-19-00009',NULL,NULL,NULL,NULL,NULL,'FLUTICASONA 50 MG INHALADOR 200 DOSIS','FLUTICASONA PROPIONATO',7.50,1.50,1.19,11.25,8.93,10.00,130.00,15.00,1,0,1,'Corticoide inhalado para asma. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (176,19,6,11,20,19,4,9,1700,'SM-19-00010',NULL,NULL,NULL,NULL,NULL,'FLUTICASONA 50 MG INHALADOR 300 DOSIS','FLUTICASONA PROPIONATO',10.50,1.50,1.19,15.75,12.50,10.00,110.00,12.00,1,0,1,'Inhalador de Fluticasona 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (177,19,2,2,20,19,3,9,1700,'SM-19-00011',NULL,NULL,NULL,NULL,NULL,'SALMETEROL 100 MG INHALADOR 200 DOSIS','SALMETEROL XINAFOATO',8.50,1.50,1.19,12.75,10.12,10.00,120.00,14.00,1,0,1,'Broncodilatador de larga duración para asma. 100 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (178,19,2,2,20,19,3,9,1700,'SM-19-00012',NULL,NULL,NULL,NULL,NULL,'SALMETEROL 100 MG INHALADOR 300 DOSIS','SALMETEROL XINAFOATO',12.00,1.50,1.19,18.00,14.28,10.00,100.00,10.00,1,0,1,'Inhalador de Salmeterol 100 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (179,19,3,9,20,19,4,9,1700,'SM-19-00013',NULL,NULL,NULL,NULL,NULL,'BECLOMETASONA 50 MG INHALADOR 200 DOSIS','BECLOMETASONA DIPROPIONATO',6.50,1.50,1.19,9.75,7.74,10.00,140.00,16.00,1,0,1,'Corticoide inhalado para asma. 50 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (180,19,3,9,20,19,4,9,1700,'SM-19-00014',NULL,NULL,NULL,NULL,NULL,'BECLOMETASONA 50 MG INHALADOR 300 DOSIS','BECLOMETASONA DIPROPIONATO',9.50,1.50,1.19,14.25,11.31,10.00,120.00,14.00,1,0,1,'Inhalador de Beclometasona 50 mg con 300 dosis para asma.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (181,19,4,8,20,19,3,9,1700,'SM-19-00015',NULL,NULL,NULL,NULL,NULL,'VILANTEROL 100 MG INHALADOR 200 DOSIS','VILANTEROL TRIFENATATO',10.00,1.50,1.19,15.00,11.90,10.00,110.00,12.00,1,0,1,'Broncodilatador de larga duración para EPOC. 100 mg por inhalación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (182,20,2,2,2,10,28,9,1700,'SM-20-00001',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 40 MG CAJA X 10 TABLETAS','PREDNISONA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,20.00,1,0,1,'Corticoide para enfermedades inflamatorias y autoinmunes. 40 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (183,20,2,2,2,11,28,9,1700,'SM-20-00002',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 40 MG CAJA X 20 TABLETAS','PREDNISONA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Prednisona 40 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (184,20,2,2,2,12,28,9,1700,'SM-20-00003',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 40 MG CAJA X 30 TABLETAS','PREDNISONA',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,1,0,1,'30 tabletas de Prednisona 40 mg para enfermedades autoinmunes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (185,20,3,9,2,10,4,9,1700,'SM-20-00004',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 50 MG CAJA X 10 TABLETAS','DEXAMETASONA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,1,0,1,'Corticoide para inflamación y alergias. 50 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (186,20,3,9,2,11,4,9,1700,'SM-20-00005',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 50 MG CAJA X 20 TABLETAS','DEXAMETASONA',6.30,1.50,1.19,9.45,7.50,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Dexametasona 50 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (187,20,3,9,2,12,4,9,1700,'SM-20-00006',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 50 MG CAJA X 30 TABLETAS','DEXAMETASONA',9.00,1.50,1.19,13.50,10.71,10.00,120.00,15.00,1,0,1,'30 tabletas de Dexametasona 50 mg para alergias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (188,20,4,8,2,10,7,9,1700,'SM-20-00007',NULL,NULL,NULL,NULL,NULL,'METILPREDNISOLONA 5 MG CAJA X 10 TABLETAS','METILPREDNISOLONA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Corticoide para enfermedades inflamatorias. 5 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (189,20,4,8,2,11,7,9,1700,'SM-20-00008',NULL,NULL,NULL,NULL,NULL,'METILPREDNISOLONA 5 MG CAJA X 20 TABLETAS','METILPREDNISOLONA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Metilprednisolona 5 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (190,20,4,8,2,12,7,9,1700,'SM-20-00009',NULL,NULL,NULL,NULL,NULL,'METILPREDNISOLONA 5 MG CAJA X 30 TABLETAS','METILPREDNISOLONA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Metilprednisolona 5 mg para enfermedades autoinmunes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (191,20,5,10,2,10,2,9,1700,'SM-20-00010',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CAJA X 10 TABLETAS','HIDROCORTISONA',3.80,1.50,1.19,5.70,4.52,10.00,170.00,22.00,1,0,1,'Corticoide para insuficiencia suprarrenal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (192,20,5,10,2,11,2,9,1700,'SM-20-00011',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CAJA X 20 TABLETAS','HIDROCORTISONA',6.80,1.50,1.19,10.20,8.09,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Hidrocortisona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (193,20,5,10,2,12,2,9,1700,'SM-20-00012',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CAJA X 30 TABLETAS','HIDROCORTISONA',9.50,1.50,1.19,14.25,11.31,10.00,130.00,16.00,1,0,1,'30 tabletas de Hidrocortisona 500 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (194,20,6,11,2,10,4,9,1700,'SM-20-00013',NULL,NULL,NULL,NULL,NULL,'BETAMETASONA 50 MG CAJA X 10 TABLETAS','BETAMETASONA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,1,0,1,'Corticoide para alergias e inflamación. 50 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (195,20,6,11,2,11,4,9,1700,'SM-20-00014',NULL,NULL,NULL,NULL,NULL,'BETAMETASONA 50 MG CAJA X 20 TABLETAS','BETAMETASONA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Betametasona 50 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (196,20,6,11,2,12,4,9,1700,'SM-20-00015',NULL,NULL,NULL,NULL,NULL,'BETAMETASONA 50 MG CAJA X 30 TABLETAS','BETAMETASONA',8.00,1.50,1.19,12.00,9.52,10.00,120.00,15.00,1,0,1,'30 tabletas de Betametasona 50 mg para alergias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (197,21,2,2,2,10,2,9,1700,'SM-21-00001',NULL,NULL,NULL,NULL,NULL,'FUROSEMIDA 500 MG CAJA X 10 TABLETAS','FUROSEMIDA',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,1,0,1,'Diurético para el tratamiento de la hipertensión y edema. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (198,21,2,2,2,11,2,9,1700,'SM-21-00002',NULL,NULL,NULL,NULL,NULL,'FUROSEMIDA 500 MG CAJA X 20 TABLETAS','FUROSEMIDA',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Furosemida 500 mg para edema.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (199,21,2,2,2,12,2,9,1700,'SM-21-00003',NULL,NULL,NULL,NULL,NULL,'FUROSEMIDA 500 MG CAJA X 30 TABLETAS','FUROSEMIDA',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,1,0,1,'30 tabletas de Furosemida 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (200,21,3,9,2,10,3,9,1700,'SM-21-00004',NULL,NULL,NULL,NULL,NULL,'HIDROCLOROTIAZIDA 100 MG CAJA X 10 TABLETAS','HIDROCLOROTIAZIDA',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Diurético para la hipertensión. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (201,21,3,9,2,11,3,9,1700,'SM-21-00005',NULL,NULL,NULL,NULL,NULL,'HIDROCLOROTIAZIDA 100 MG CAJA X 20 TABLETAS','HIDROCLOROTIAZIDA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Hidroclorotiazida 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (202,21,3,9,2,12,3,9,1700,'SM-21-00006',NULL,NULL,NULL,NULL,NULL,'HIDROCLOROTIAZIDA 100 MG CAJA X 30 TABLETAS','HIDROCLOROTIAZIDA',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Hidroclorotiazida 100 mg para hipertensión.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (203,21,4,8,2,10,2,9,1700,'SM-21-00007',NULL,NULL,NULL,NULL,NULL,'ESPIRONOLACTONA 500 MG CAJA X 10 TABLETAS','ESPIRONOLACTONA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Diurético ahorrador de potasio para insuficiencia cardíaca. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (204,21,4,8,2,11,2,9,1700,'SM-21-00008',NULL,NULL,NULL,NULL,NULL,'ESPIRONOLACTONA 500 MG CAJA X 20 TABLETAS','ESPIRONOLACTONA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Espironolactona 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (205,21,4,8,2,12,2,9,1700,'SM-21-00009',NULL,NULL,NULL,NULL,NULL,'ESPIRONOLACTONA 500 MG CAJA X 30 TABLETAS','ESPIRONOLACTONA',7.50,1.50,1.19,11.25,8.93,10.00,120.00,15.00,0,0,1,'30 tabletas de Espironolactona 500 mg para edema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (206,21,5,10,2,10,2,9,1700,'SM-21-00010',NULL,NULL,NULL,NULL,NULL,'TORASEMIDA 500 MG CAJA X 10 TABLETAS','TORASEMIDA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Diurético para hipertensión y edema. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (207,21,5,10,2,11,2,9,1700,'SM-21-00011',NULL,NULL,NULL,NULL,NULL,'TORASEMIDA 500 MG CAJA X 20 TABLETAS','TORASEMIDA',6.30,1.50,1.19,9.45,7.50,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Torasemida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (208,21,5,10,2,12,2,9,1700,'SM-21-00012',NULL,NULL,NULL,NULL,NULL,'TORASEMIDA 500 MG CAJA X 30 TABLETAS','TORASEMIDA',8.80,1.50,1.19,13.20,10.47,10.00,120.00,15.00,0,0,1,'30 tabletas de Torasemida 500 mg para insuficiencia cardíaca.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (209,21,6,11,2,10,4,9,1700,'SM-21-00013',NULL,NULL,NULL,NULL,NULL,'INDAPAMIDA 50 MG CAJA X 10 TABLETAS','INDAPAMIDA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Diurético para hipertensión. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (210,21,6,11,2,11,4,9,1700,'SM-21-00014',NULL,NULL,NULL,NULL,NULL,'INDAPAMIDA 50 MG CAJA X 20 TABLETAS','INDAPAMIDA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Indapamida 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (211,21,6,11,2,12,4,9,1700,'SM-21-00015',NULL,NULL,NULL,NULL,NULL,'INDAPAMIDA 50 MG CAJA X 30 TABLETAS','INDAPAMIDA',7.00,1.50,1.19,10.50,8.33,10.00,130.00,16.00,0,0,1,'30 tabletas de Indapamida 50 mg para hipertensión.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (212,22,2,2,2,10,7,9,1700,'SM-22-00001',NULL,NULL,NULL,NULL,NULL,'BISACODILO 5 MG CAJA X 10 TABLETAS','BISACODILO',1.80,1.50,1.19,2.70,2.14,10.00,190.00,25.00,0,0,1,'Laxante para el estreñimiento ocasional. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (213,22,2,2,2,11,7,9,1700,'SM-22-00002',NULL,NULL,NULL,NULL,NULL,'BISACODILO 5 MG CAJA X 20 TABLETAS','BISACODILO',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Bisacodilo 5 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (214,22,2,2,2,12,7,9,1700,'SM-22-00003',NULL,NULL,NULL,NULL,NULL,'BISACODILO 5 MG CAJA X 30 TABLETAS','BISACODILO',4.50,1.50,1.19,6.75,5.36,10.00,130.00,18.00,0,0,1,'30 tabletas de Bisacodilo 5 mg para el estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (215,22,3,9,8,20,3,9,1700,'SM-22-00004',NULL,NULL,NULL,NULL,NULL,'LACTULOSA 100 MG UNGÜENTO TUBO X 30 G','LACTULOSA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Laxante para el estreñimiento. 100 mg en ungüento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (216,22,3,9,8,21,3,9,1700,'SM-22-00005',NULL,NULL,NULL,NULL,NULL,'LACTULOSA 100 MG UNGÜENTO TUBO X 50 G','LACTULOSA',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Lactulosa 100 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (217,22,4,8,2,10,2,9,1700,'SM-22-00006',NULL,NULL,NULL,NULL,NULL,'SENÓSIDOS 500 MG CAJA X 10 TABLETAS','SENÓSIDOS',2.20,1.50,1.19,3.30,2.62,10.00,180.00,22.00,0,0,1,'Laxante natural para el estreñimiento. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (218,22,4,8,2,11,2,9,1700,'SM-22-00007',NULL,NULL,NULL,NULL,NULL,'SENÓSIDOS 500 MG CAJA X 20 TABLETAS','SENÓSIDOS',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Senósidos 500 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (219,22,4,8,2,12,2,9,1700,'SM-22-00008',NULL,NULL,NULL,NULL,NULL,'SENÓSIDOS 500 MG CAJA X 30 TABLETAS','SENÓSIDOS',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Senósidos 500 mg para el estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (220,22,5,10,2,10,4,9,1700,'SM-22-00009',NULL,NULL,NULL,NULL,NULL,'POLIETILENGLICOL 50 MG CAJA X 10 TABLETAS','POLIETILENGLICOL',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Laxante osmótico para el estreñimiento. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (221,22,5,10,2,11,4,9,1700,'SM-22-00010',NULL,NULL,NULL,NULL,NULL,'POLIETILENGLICOL 50 MG CAJA X 20 TABLETAS','POLIETILENGLICOL',5.00,1.50,1.19,7.50,5.95,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Polietilenglicol 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (222,22,5,10,2,12,4,9,1700,'SM-22-00011',NULL,NULL,NULL,NULL,NULL,'POLIETILENGLICOL 50 MG CAJA X 30 TABLETAS','POLIETILENGLICOL',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Polietilenglicol 50 mg para estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (223,22,6,11,2,10,4,9,1700,'SM-22-00012',NULL,NULL,NULL,NULL,NULL,'PICOSULFATO 50 MG CAJA X 10 TABLETAS','PICOSULFATO SODICO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Laxante para el estreñimiento. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (224,22,6,11,2,11,4,9,1700,'SM-22-00013',NULL,NULL,NULL,NULL,NULL,'PICOSULFATO 50 MG CAJA X 20 TABLETAS','PICOSULFATO SODICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Picosulfato 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (225,22,6,11,2,12,4,9,1700,'SM-22-00014',NULL,NULL,NULL,NULL,NULL,'PICOSULFATO 50 MG CAJA X 30 TABLETAS','PICOSULFATO SODICO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Picosulfato 50 mg para el estreñimiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (226,23,2,2,2,10,2,9,1700,'SM-23-00001',NULL,NULL,NULL,NULL,NULL,'VITAMINA C 500 MG CAJA X 10 TABLETAS','ACIDO ASCORBICO',2.00,1.50,1.19,3.00,2.38,10.00,200.00,25.00,0,0,1,'Vitamina C para el sistema inmunológico. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (227,23,2,2,2,11,2,9,1700,'SM-23-00002',NULL,NULL,NULL,NULL,NULL,'VITAMINA C 500 MG CAJA X 20 TABLETAS','ACIDO ASCORBICO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Vitamina C 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (228,23,2,2,2,12,2,9,1700,'SM-23-00003',NULL,NULL,NULL,NULL,NULL,'VITAMINA C 500 MG CAJA X 30 TABLETAS','ACIDO ASCORBICO',5.00,1.50,1.19,7.50,5.95,10.00,130.00,18.00,0,0,1,'30 tabletas de Vitamina C 500 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (229,23,3,9,2,10,3,9,1700,'SM-23-00004',NULL,NULL,NULL,NULL,NULL,'VITAMINA D 100 MG CAJA X 10 TABLETAS','COLECALCIFEROL',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,0,0,1,'Vitamina D para la salud ósea. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (230,23,3,9,2,11,3,9,1700,'SM-23-00005',NULL,NULL,NULL,NULL,NULL,'VITAMINA D 100 MG CAJA X 20 TABLETAS','COLECALCIFEROL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,20.00,0,0,1,'Caja de 20 tabletas de Vitamina D 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (231,23,3,9,2,12,3,9,1700,'SM-23-00006',NULL,NULL,NULL,NULL,NULL,'VITAMINA D 100 MG CAJA X 30 TABLETAS','COLECALCIFEROL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,18.00,0,0,1,'30 tabletas de Vitamina D 100 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (232,23,4,8,2,10,3,9,1700,'SM-23-00007',NULL,NULL,NULL,NULL,NULL,'VITAMINA E 100 MG CAJA X 10 TABLETAS','ALFA TOCOFEROL',2.80,1.50,1.19,4.20,3.33,10.00,170.00,20.00,0,0,1,'Vitamina E antioxidante. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (233,23,4,8,2,11,3,9,1700,'SM-23-00008',NULL,NULL,NULL,NULL,NULL,'VITAMINA E 100 MG CAJA X 20 TABLETAS','ALFA TOCOFEROL',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Vitamina E 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (234,23,4,8,2,12,3,9,1700,'SM-23-00009',NULL,NULL,NULL,NULL,NULL,'VITAMINA E 100 MG CAJA X 30 TABLETAS','ALFA TOCOFEROL',7.00,1.50,1.19,10.50,8.33,10.00,130.00,18.00,0,0,1,'30 tabletas de Vitamina E 100 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (235,23,5,10,2,10,6,9,1700,'SM-23-00010',NULL,NULL,NULL,NULL,NULL,'VITAMINA A 10 MG CAJA X 10 TABLETAS','RETINOL',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Vitamina A para la salud de la piel y visión. 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (236,23,5,10,2,11,6,9,1700,'SM-23-00011',NULL,NULL,NULL,NULL,NULL,'VITAMINA A 10 MG CAJA X 20 TABLETAS','RETINOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Vitamina A 10 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (237,23,5,10,2,12,6,9,1700,'SM-23-00012',NULL,NULL,NULL,NULL,NULL,'VITAMINA A 10 MG CAJA X 30 TABLETAS','RETINOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Vitamina A 10 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (238,23,6,11,2,10,4,9,1700,'SM-23-00013',NULL,NULL,NULL,NULL,NULL,'COMPLEJO B 50 MG CAJA X 10 TABLETAS','COMPLEJO DE VITAMINAS B',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,0,0,1,'Complejo B para el sistema nervioso y energía. 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (239,23,6,11,2,11,4,9,1700,'SM-23-00014',NULL,NULL,NULL,NULL,NULL,'COMPLEJO B 50 MG CAJA X 20 TABLETAS','COMPLEJO DE VITAMINAS B',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Complejo B 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (240,23,6,11,2,12,4,9,1700,'SM-23-00015',NULL,NULL,NULL,NULL,NULL,'COMPLEJO B 50 MG CAJA X 30 TABLETAS','COMPLEJO DE VITAMINAS B',8.00,1.50,1.19,12.00,9.52,10.00,130.00,18.00,0,0,1,'30 tabletas de Complejo B 50 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (241,24,2,2,2,10,3,9,1700,'SM-24-00001',NULL,NULL,NULL,NULL,NULL,'OMEGA 3 100 MG CAJA X 10 TABLETAS','ACEITE DE PESCADO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Suplemento de omega 3 para la salud cardiovascular. 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (242,24,2,2,2,11,3,9,1700,'SM-24-00002',NULL,NULL,NULL,NULL,NULL,'OMEGA 3 100 MG CAJA X 20 TABLETAS','ACEITE DE PESCADO',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Omega 3 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (243,24,2,2,2,12,3,9,1700,'SM-24-00003',NULL,NULL,NULL,NULL,NULL,'OMEGA 3 100 MG CAJA X 30 TABLETAS','ACEITE DE PESCADO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'30 tabletas de Omega 3 100 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (244,24,3,9,2,10,3,9,1700,'SM-24-00004',NULL,NULL,NULL,NULL,NULL,'GLUCOSAMINA 100 MG CAJA X 10 TABLETAS','GLUCOSAMINA SULFATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Suplemento para la salud articular. 100 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (245,24,3,9,2,11,3,9,1700,'SM-24-00005',NULL,NULL,NULL,NULL,NULL,'GLUCOSAMINA 100 MG CAJA X 20 TABLETAS','GLUCOSAMINA SULFATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,0,0,1,'Caja de 20 tabletas de Glucosamina 100 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (246,24,3,9,2,12,3,9,1700,'SM-24-00006',NULL,NULL,NULL,NULL,NULL,'GLUCOSAMINA 100 MG CAJA X 30 TABLETAS','GLUCOSAMINA SULFATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,0,0,1,'30 tabletas de Glucosamina 100 mg para articulaciones.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (247,24,4,8,2,10,2,9,1700,'SM-24-00007',NULL,NULL,NULL,NULL,NULL,'MAGNESIO 500 MG CAJA X 10 TABLETAS','MAGNESIO OXIDO',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,0,0,1,'Suplemento de magnesio para el sistema nervioso. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (248,24,4,8,2,11,2,9,1700,'SM-24-00008',NULL,NULL,NULL,NULL,NULL,'MAGNESIO 500 MG CAJA X 20 TABLETAS','MAGNESIO OXIDO',5.40,1.50,1.19,8.10,6.43,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Magnesio 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (249,24,4,8,2,12,2,9,1700,'SM-24-00009',NULL,NULL,NULL,NULL,NULL,'MAGNESIO 500 MG CAJA X 30 TABLETAS','MAGNESIO OXIDO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,18.00,0,0,1,'30 tabletas de Magnesio 500 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (250,24,5,10,2,10,2,9,1700,'SM-24-00010',NULL,NULL,NULL,NULL,NULL,'ZINC 500 MG CAJA X 10 TABLETAS','ZINC GLUCONATO',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Suplemento de zinc para el sistema inmunológico. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (251,24,5,10,2,11,2,9,1700,'SM-24-00011',NULL,NULL,NULL,NULL,NULL,'ZINC 500 MG CAJA X 20 TABLETAS','ZINC GLUCONATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Zinc 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (252,24,5,10,2,12,2,9,1700,'SM-24-00012',NULL,NULL,NULL,NULL,NULL,'ZINC 500 MG CAJA X 30 TABLETAS','ZINC GLUCONATO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Zinc 500 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (253,24,6,11,2,10,4,9,1700,'SM-24-00013',NULL,NULL,NULL,NULL,NULL,'CALCIO 50 MG CAJA X 10 TABLETAS','CALCIO CARBONATO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Suplemento de calcio para la salud ósea. 50 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (254,24,6,11,2,11,4,9,1700,'SM-24-00014',NULL,NULL,NULL,NULL,NULL,'CALCIO 50 MG CAJA X 20 TABLETAS','CALCIO CARBONATO',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Calcio 50 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (255,24,6,11,2,12,4,9,1700,'SM-24-00015',NULL,NULL,NULL,NULL,NULL,'CALCIO 50 MG CAJA X 30 TABLETAS','CALCIO CARBONATO',8.80,1.50,1.19,13.20,10.47,10.00,130.00,18.00,0,0,1,'30 tabletas de Calcio 50 mg para la salud.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (256,25,2,2,2,10,2,9,1700,'SM-25-00001',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 10 TABLETAS','PARACETAMOL',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Antipirético y analgésico para el alivio de la fiebre. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (257,25,2,2,2,11,2,9,1700,'SM-25-00002',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 20 TABLETAS','PARACETAMOL',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Paracetamol 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (258,25,2,2,2,12,2,9,1700,'SM-25-00003',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 30 TABLETAS','PARACETAMOL',4.50,1.50,1.19,6.75,5.36,10.00,130.00,18.00,0,0,1,'30 tabletas de Paracetamol 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (259,25,3,9,2,10,2,9,1700,'SM-25-00004',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antipirético y antiinflamatorio. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (260,25,3,9,2,11,2,9,1700,'SM-25-00005',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Aspirina 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (261,25,3,9,2,12,2,9,1700,'SM-25-00006',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Aspirina 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (262,25,4,8,2,10,2,9,1700,'SM-25-00007',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 10 TABLETAS','METAMIZOL SODICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antipirético y analgésico para el alivio del dolor y la fiebre. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (263,25,4,8,2,11,2,9,1700,'SM-25-00008',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 20 TABLETAS','METAMIZOL SODICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Metamizol 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (264,25,4,8,2,12,2,9,1700,'SM-25-00009',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 30 TABLETAS','METAMIZOL SODICO',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Metamizol 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (265,25,5,10,2,10,2,9,1700,'SM-25-00010',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 10 TABLETAS','IBUPROFENO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antipirético y antiinflamatorio. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (266,25,5,10,2,11,2,9,1700,'SM-25-00011',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 20 TABLETAS','IBUPROFENO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (267,25,5,10,2,12,2,9,1700,'SM-25-00012',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 30 TABLETAS','IBUPROFENO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Ibuprofeno 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (268,25,6,11,2,10,2,9,1700,'SM-25-00013',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 10 TABLETAS','NAPROXENO SODICO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antipirético y antiinflamatorio. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (269,25,6,11,2,11,2,9,1700,'SM-25-00014',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 20 TABLETAS','NAPROXENO SODICO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Naproxeno 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (270,25,6,11,2,12,2,9,1700,'SM-25-00015',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 30 TABLETAS','NAPROXENO SODICO',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Naproxeno 500 mg para el alivio de la fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (271,26,2,2,4,18,3,9,1700,'SM-26-00001',NULL,NULL,NULL,NULL,NULL,'DEXTROMETORFANO 100 MG JARABE FRASCO X 100 ML','DEXTROMETORFANO HIDROBROMURO',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Antitusivo para el alivio de la tos seca. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (272,26,2,2,4,19,3,9,1700,'SM-26-00002',NULL,NULL,NULL,NULL,NULL,'DEXTROMETORFANO 100 MG JARABE FRASCO X 250 ML','DEXTROMETORFANO HIDROBROMURO',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de Dextrometorfano 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (273,26,3,9,4,18,4,9,1700,'SM-26-00003',NULL,NULL,NULL,NULL,NULL,'CLOPERASTINA 50 MG JARABE FRASCO X 100 ML','CLOPERASTINA CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Antitusivo para la tos seca. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (274,26,3,9,4,19,4,9,1700,'SM-26-00004',NULL,NULL,NULL,NULL,NULL,'CLOPERASTINA 50 MG JARABE FRASCO X 250 ML','CLOPERASTINA CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Cloperastina 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (275,26,4,8,4,18,3,9,1700,'SM-26-00005',NULL,NULL,NULL,NULL,NULL,'BENZONATATO 100 MG JARABE FRASCO X 100 ML','BENZONATATO',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Antitusivo para la tos seca. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (276,26,4,8,4,19,3,9,1700,'SM-26-00006',NULL,NULL,NULL,NULL,NULL,'BENZONATATO 100 MG JARABE FRASCO X 250 ML','BENZONATATO',6.50,1.50,1.19,9.75,7.74,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de Benzonatato 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (277,26,5,10,4,18,4,9,1700,'SM-26-00007',NULL,NULL,NULL,NULL,NULL,'LEVODROPROPIZINA 50 MG JARABE FRASCO X 100 ML','LEVODROPROPIZINA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antitusivo para la tos seca. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (278,26,5,10,4,19,4,9,1700,'SM-26-00008',NULL,NULL,NULL,NULL,NULL,'LEVODROPROPIZINA 50 MG JARABE FRASCO X 250 ML','LEVODROPROPIZINA',5.20,1.50,1.19,7.80,6.19,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Levodropropizina 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (279,26,6,11,4,18,4,9,1700,'SM-26-00009',NULL,NULL,NULL,NULL,NULL,'DROPROPIZINA 50 MG JARABE FRASCO X 100 ML','DROPROPIZINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antitusivo para la tos seca. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (280,26,6,11,4,19,4,9,1700,'SM-26-00010',NULL,NULL,NULL,NULL,NULL,'DROPROPIZINA 50 MG JARABE FRASCO X 250 ML','DROPROPIZINA',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,0,0,1,'Frasco de 250 ml de Dropropizina 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (281,27,2,2,4,18,3,9,1700,'SM-27-00001',NULL,NULL,NULL,NULL,NULL,'GUAIFENESINA 100 MG JARABE FRASCO X 100 ML','GUAIFENESINA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Expectorante para la tos productiva. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (282,27,2,2,4,19,3,9,1700,'SM-27-00002',NULL,NULL,NULL,NULL,NULL,'GUAIFENESINA 100 MG JARABE FRASCO X 250 ML','GUAIFENESINA',5.20,1.50,1.19,7.80,6.19,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Guaifenesina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (283,27,3,9,4,18,3,9,1700,'SM-27-00003',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 100 ML','BROMHEXINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Expectorante para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (284,27,3,9,4,19,3,9,1700,'SM-27-00004',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 250 ML','BROMHEXINA CLORHIDRATO',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,0,0,1,'Frasco de 250 ml de Bromhexina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (285,27,4,8,4,18,4,9,1700,'SM-27-00005',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 100 ML','AMBROXOL CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Expectorante para la tos productiva. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (286,27,4,8,4,19,4,9,1700,'SM-27-00006',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 250 ML','AMBROXOL CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Ambroxol 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (287,27,5,10,4,18,3,9,1700,'SM-27-00007',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 100 ML','N-ACETILCISTEINA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Expectorante para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (288,27,5,10,4,19,3,9,1700,'SM-27-00008',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 250 ML','N-ACETILCISTEINA',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de N-Acetilcisteina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (289,27,6,11,4,18,5,9,1700,'SM-27-00009',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 100 ML','CARBOCISTEINA',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Expectorante para la tos. 25 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (290,27,6,11,4,19,5,9,1700,'SM-27-00010',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 250 ML','CARBOCISTEINA',4.20,1.50,1.19,6.30,5.00,10.00,170.00,22.00,0,0,1,'Frasco de 250 ml de Carbocisteina 25 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (291,28,2,2,4,18,3,9,1700,'SM-28-00001',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 100 ML','BROMHEXINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Mucolítico para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (292,28,2,2,4,19,3,9,1700,'SM-28-00002',NULL,NULL,NULL,NULL,NULL,'BROMHEXINA 100 MG JARABE FRASCO X 250 ML','BROMHEXINA CLORHIDRATO',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,0,0,1,'Frasco de 250 ml de Bromhexina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (293,28,3,9,4,18,4,9,1700,'SM-28-00003',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 100 ML','AMBROXOL CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Mucolítico para la tos productiva. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (294,28,3,9,4,19,4,9,1700,'SM-28-00004',NULL,NULL,NULL,NULL,NULL,'AMBROXOL 50 MG JARABE FRASCO X 250 ML','AMBROXOL CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,150.00,18.00,0,0,1,'Frasco de 250 ml de Ambroxol 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (295,28,4,8,4,18,3,9,1700,'SM-28-00005',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 100 ML','N-ACETILCISTEINA',3.50,1.50,1.19,5.25,4.17,10.00,160.00,20.00,0,0,1,'Mucolítico para la tos. 100 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (296,28,4,8,4,19,3,9,1700,'SM-28-00006',NULL,NULL,NULL,NULL,NULL,'N-ACETILCISTEINA 100 MG JARABE FRASCO X 250 ML','N-ACETILCISTEINA',6.00,1.50,1.19,9.00,7.14,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de N-Acetilcisteina 100 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (297,28,5,10,4,18,5,9,1700,'SM-28-00007',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 100 ML','CARBOCISTEINA',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Mucolítico para la tos. 25 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (298,28,5,10,4,19,5,9,1700,'SM-28-00008',NULL,NULL,NULL,NULL,NULL,'CARBOCISTEINA 25 MG JARABE FRASCO X 250 ML','CARBOCISTEINA',4.20,1.50,1.19,6.30,5.00,10.00,170.00,22.00,0,0,1,'Frasco de 250 ml de Carbocisteina 25 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (299,28,6,11,4,18,4,9,1700,'SM-28-00009',NULL,NULL,NULL,NULL,NULL,'MESNA 50 MG JARABE FRASCO X 100 ML','MESNA',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Mucolítico para la tos. 50 mg en jarabe.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (300,28,6,11,4,19,4,9,1700,'SM-28-00010',NULL,NULL,NULL,NULL,NULL,'MESNA 50 MG JARABE FRASCO X 250 ML','MESNA',6.50,1.50,1.19,9.75,7.74,10.00,140.00,18.00,0,0,1,'Frasco de 250 ml de Mesna 50 mg para la tos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (301,29,2,2,2,10,3,9,1700,'SM-29-00001',NULL,NULL,NULL,NULL,NULL,'CARBAMAZEPINA 100 MG CAJA X 10 TABLETAS','CARBAMAZEPINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Anticonvulsivante para epilepsia y neuralgia. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (302,29,2,2,2,11,3,9,1700,'SM-29-00002',NULL,NULL,NULL,NULL,NULL,'CARBAMAZEPINA 100 MG CAJA X 20 TABLETAS','CARBAMAZEPINA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Carbamazepina 100 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (303,29,2,2,2,12,3,9,1700,'SM-29-00003',NULL,NULL,NULL,NULL,NULL,'CARBAMAZEPINA 100 MG CAJA X 30 TABLETAS','CARBAMAZEPINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Carbamazepina 100 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (304,29,3,9,2,10,6,9,1700,'SM-29-00004',NULL,NULL,NULL,NULL,NULL,'FENITOINA 10 MG CAJA X 10 TABLETAS','FENITOINA SODICA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Anticonvulsivante para epilepsia. 10 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (305,29,3,9,2,11,6,9,1700,'SM-29-00005',NULL,NULL,NULL,NULL,NULL,'FENITOINA 10 MG CAJA X 20 TABLETAS','FENITOINA SODICA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Fenitoina 10 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (306,29,3,9,2,12,6,9,1700,'SM-29-00006',NULL,NULL,NULL,NULL,NULL,'FENITOINA 10 MG CAJA X 30 TABLETAS','FENITOINA SODICA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Fenitoina 10 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (307,29,4,8,2,10,2,9,1700,'SM-29-00007',NULL,NULL,NULL,NULL,NULL,'VALPROATO 500 MG CAJA X 10 TABLETAS','VALPROATO SODICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Anticonvulsivante para epilepsia y trastorno bipolar. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (308,29,4,8,2,11,2,9,1700,'SM-29-00008',NULL,NULL,NULL,NULL,NULL,'VALPROATO 500 MG CAJA X 20 TABLETAS','VALPROATO SODICO',8.10,1.50,1.19,12.15,9.64,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Valproato 500 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (309,29,4,8,2,12,2,9,1700,'SM-29-00009',NULL,NULL,NULL,NULL,NULL,'VALPROATO 500 MG CAJA X 30 TABLETAS','VALPROATO SODICO',11.50,1.50,1.19,17.25,13.68,10.00,120.00,15.00,1,0,1,'30 tabletas de Valproato 500 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (310,29,5,10,2,10,7,9,1700,'SM-29-00010',NULL,NULL,NULL,NULL,NULL,'LAMOTRIGINA 5 MG CAJA X 10 TABLETAS','LAMOTRIGINA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Anticonvulsivante para epilepsia. 5 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (311,29,5,10,2,11,7,9,1700,'SM-29-00011',NULL,NULL,NULL,NULL,NULL,'LAMOTRIGINA 5 MG CAJA X 20 TABLETAS','LAMOTRIGINA',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Lamotrigina 5 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (312,29,5,10,2,12,7,9,1700,'SM-29-00012',NULL,NULL,NULL,NULL,NULL,'LAMOTRIGINA 5 MG CAJA X 30 TABLETAS','LAMOTRIGINA',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Lamotrigina 5 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (313,29,6,11,2,10,2,9,1700,'SM-29-00013',NULL,NULL,NULL,NULL,NULL,'TOPIRAMATO 500 MG CAJA X 10 TABLETAS','TOPIRAMATO',4.80,1.50,1.19,7.20,5.71,10.00,160.00,20.00,1,0,1,'Anticonvulsivante para epilepsia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (314,29,6,11,2,11,2,9,1700,'SM-29-00014',NULL,NULL,NULL,NULL,NULL,'TOPIRAMATO 500 MG CAJA X 20 TABLETAS','TOPIRAMATO',8.60,1.50,1.19,12.90,10.23,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Topiramato 500 mg para convulsiones.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (315,29,6,11,2,12,2,9,1700,'SM-29-00015',NULL,NULL,NULL,NULL,NULL,'TOPIRAMATO 500 MG CAJA X 30 TABLETAS','TOPIRAMATO',12.00,1.50,1.19,18.00,14.28,10.00,120.00,15.00,1,0,1,'30 tabletas de Topiramato 500 mg para epilepsia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (316,30,2,2,2,10,2,9,1700,'SM-30-00001',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 10 TABLETAS','METFORMINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,1,0,1,'Hipoglucemiante para la diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (317,30,2,2,2,11,2,9,1700,'SM-30-00002',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 20 TABLETAS','METFORMINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Metformina 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (318,30,2,2,2,12,2,9,1700,'SM-30-00003',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 30 TABLETAS','METFORMINA CLORHIDRATO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,1,0,1,'30 tabletas de Metformina 500 mg para la diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (319,30,3,9,2,10,2,9,1700,'SM-30-00004',NULL,NULL,NULL,NULL,NULL,'GLIBENCLAMIDA 500 MG CAJA X 10 TABLETAS','GLIBENCLAMIDA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (320,30,3,9,2,11,2,9,1700,'SM-30-00005',NULL,NULL,NULL,NULL,NULL,'GLIBENCLAMIDA 500 MG CAJA X 20 TABLETAS','GLIBENCLAMIDA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Glibenclamida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (321,30,3,9,2,12,2,9,1700,'SM-30-00006',NULL,NULL,NULL,NULL,NULL,'GLIBENCLAMIDA 500 MG CAJA X 30 TABLETAS','GLIBENCLAMIDA',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,1,0,1,'30 tabletas de Glibenclamida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (322,30,4,8,2,10,2,9,1700,'SM-30-00007',NULL,NULL,NULL,NULL,NULL,'GLICLAZIDA 500 MG CAJA X 10 TABLETAS','GLICLAZIDA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (323,30,4,8,2,11,2,9,1700,'SM-30-00008',NULL,NULL,NULL,NULL,NULL,'GLICLAZIDA 500 MG CAJA X 20 TABLETAS','GLICLAZIDA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Gliclazida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (324,30,4,8,2,12,2,9,1700,'SM-30-00009',NULL,NULL,NULL,NULL,NULL,'GLICLAZIDA 500 MG CAJA X 30 TABLETAS','GLICLAZIDA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,1,0,1,'30 tabletas de Gliclazida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (325,30,5,10,2,10,3,9,1700,'SM-30-00010',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 100 MG CAJA X 10 TABLETAS','PIOGLITAZONA CLORHIDRATO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (326,30,5,10,2,11,3,9,1700,'SM-30-00011',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 100 MG CAJA X 20 TABLETAS','PIOGLITAZONA CLORHIDRATO',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Pioglitazona 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (327,30,5,10,2,12,3,9,1700,'SM-30-00012',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 100 MG CAJA X 30 TABLETAS','PIOGLITAZONA CLORHIDRATO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Pioglitazona 100 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (328,30,6,11,2,10,5,9,1700,'SM-30-00013',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 25 MG CAJA X 10 TABLETAS','REPAGLINIDA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Hipoglucemiante para diabetes tipo 2. 25 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (329,30,6,11,2,11,5,9,1700,'SM-30-00014',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 25 MG CAJA X 20 TABLETAS','REPAGLINIDA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Repaglinida 25 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (330,30,6,11,2,12,5,9,1700,'SM-30-00015',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 25 MG CAJA X 30 TABLETAS','REPAGLINIDA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Repaglinida 25 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (331,31,2,2,2,10,2,9,1700,'SM-31-00001',NULL,NULL,NULL,NULL,NULL,'ENALAPRIL 500 MG CAJA X 10 TABLETAS','ENALAPRIL MALEATO',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,1,0,1,'Hipotensor para la hipertensión arterial. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (332,31,2,2,2,11,2,9,1700,'SM-31-00002',NULL,NULL,NULL,NULL,NULL,'ENALAPRIL 500 MG CAJA X 20 TABLETAS','ENALAPRIL MALEATO',5.40,1.50,1.19,8.10,6.43,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Enalapril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (333,31,2,2,2,12,2,9,1700,'SM-31-00003',NULL,NULL,NULL,NULL,NULL,'ENALAPRIL 500 MG CAJA X 30 TABLETAS','ENALAPRIL MALEATO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,18.00,1,0,1,'30 tabletas de Enalapril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (334,31,3,9,2,10,2,9,1700,'SM-31-00004',NULL,NULL,NULL,NULL,NULL,'LISINOPRIL 500 MG CAJA X 10 TABLETAS','LISINOPRIL DIHIDRATADO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,1,0,1,'Hipotensor para hipertensión y insuficiencia cardíaca. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (335,31,3,9,2,11,2,9,1700,'SM-31-00005',NULL,NULL,NULL,NULL,NULL,'LISINOPRIL 500 MG CAJA X 20 TABLETAS','LISINOPRIL DIHIDRATADO',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Lisinopril 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (336,31,3,9,2,12,2,9,1700,'SM-31-00006',NULL,NULL,NULL,NULL,NULL,'LISINOPRIL 500 MG CAJA X 30 TABLETAS','LISINOPRIL DIHIDRATADO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,1,0,1,'30 tabletas de Lisinopril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (337,31,4,8,2,10,2,9,1700,'SM-31-00007',NULL,NULL,NULL,NULL,NULL,'LOSARTAN 500 MG CAJA X 10 TABLETAS','LOSARTAN POTASICO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,1,0,1,'Hipotensor para hipertensión. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (338,31,4,8,2,11,2,9,1700,'SM-31-00008',NULL,NULL,NULL,NULL,NULL,'LOSARTAN 500 MG CAJA X 20 TABLETAS','LOSARTAN POTASICO',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Losartan 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (339,31,4,8,2,12,2,9,1700,'SM-31-00009',NULL,NULL,NULL,NULL,NULL,'LOSARTAN 500 MG CAJA X 30 TABLETAS','LOSARTAN POTASICO',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Losartan 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (340,31,5,10,2,10,2,9,1700,'SM-31-00010',NULL,NULL,NULL,NULL,NULL,'VALSARTAN 500 MG CAJA X 10 TABLETAS','VALSARTAN',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Hipotensor para hipertensión. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (341,31,5,10,2,11,2,9,1700,'SM-31-00011',NULL,NULL,NULL,NULL,NULL,'VALSARTAN 500 MG CAJA X 20 TABLETAS','VALSARTAN',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Valsartan 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (342,31,5,10,2,12,2,9,1700,'SM-31-00012',NULL,NULL,NULL,NULL,NULL,'VALSARTAN 500 MG CAJA X 30 TABLETAS','VALSARTAN',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Valsartan 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (343,31,6,11,2,10,2,9,1700,'SM-31-00013',NULL,NULL,NULL,NULL,NULL,'CAPTOPRIL 500 MG CAJA X 10 TABLETAS','CAPTOPRIL',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,1,0,1,'Hipotensor para hipertensión. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (344,31,6,11,2,11,2,9,1700,'SM-31-00014',NULL,NULL,NULL,NULL,NULL,'CAPTOPRIL 500 MG CAJA X 20 TABLETAS','CAPTOPRIL',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Captopril 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (345,31,6,11,2,12,2,9,1700,'SM-31-00015',NULL,NULL,NULL,NULL,NULL,'CAPTOPRIL 500 MG CAJA X 30 TABLETAS','CAPTOPRIL',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,1,0,1,'30 tabletas de Captopril 500 mg para hipertensión.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (346,32,2,2,2,10,2,9,1700,'SM-32-00001',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 10 TABLETAS','NITROGLICERINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Vasodilatador para la angina de pecho. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (347,32,2,2,2,11,2,9,1700,'SM-32-00002',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 20 TABLETAS','NITROGLICERINA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Nitroglicerina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (348,32,2,2,2,12,2,9,1700,'SM-32-00003',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 30 TABLETAS','NITROGLICERINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Nitroglicerina 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (349,32,3,9,2,10,2,9,1700,'SM-32-00004',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 10 TABLETAS','DINITRATO DE ISOSORBIDE',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Vasodilatador para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (350,32,3,9,2,11,2,9,1700,'SM-32-00005',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 20 TABLETAS','DINITRATO DE ISOSORBIDE',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Isosorbide 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (351,32,3,9,2,12,2,9,1700,'SM-32-00006',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 30 TABLETAS','DINITRATO DE ISOSORBIDE',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Isosorbide 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (352,32,4,8,2,10,2,9,1700,'SM-32-00007',NULL,NULL,NULL,NULL,NULL,'NITROPRUSIATO 500 MG CAJA X 10 TABLETAS','NITROPRUSIATO SODICO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Vasodilatador para crisis hipertensivas. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (353,32,4,8,2,11,2,9,1700,'SM-32-00008',NULL,NULL,NULL,NULL,NULL,'NITROPRUSIATO 500 MG CAJA X 20 TABLETAS','NITROPRUSIATO SODICO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Nitroprusiato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (354,32,4,8,2,12,2,9,1700,'SM-32-00009',NULL,NULL,NULL,NULL,NULL,'NITROPRUSIATO 500 MG CAJA X 30 TABLETAS','NITROPRUSIATO SODICO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Nitroprusiato 500 mg para emergencias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (355,32,5,10,2,10,2,9,1700,'SM-32-00010',NULL,NULL,NULL,NULL,NULL,'PENTAERITRITOL 500 MG CAJA X 10 TABLETAS','TETRANITRATO DE PENTAERITRITOL',3.80,1.50,1.19,5.70,4.52,10.00,170.00,22.00,1,0,1,'Vasodilatador para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (356,32,5,10,2,11,2,9,1700,'SM-32-00011',NULL,NULL,NULL,NULL,NULL,'PENTAERITRITOL 500 MG CAJA X 20 TABLETAS','TETRANITRATO DE PENTAERITRITOL',6.80,1.50,1.19,10.20,8.09,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Pentaeritritol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (357,32,5,10,2,12,2,9,1700,'SM-32-00012',NULL,NULL,NULL,NULL,NULL,'PENTAERITRITOL 500 MG CAJA X 30 TABLETAS','TETRANITRATO DE PENTAERITRITOL',9.50,1.50,1.19,14.25,11.31,10.00,130.00,16.00,1,0,1,'30 tabletas de Pentaeritritol 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (358,32,6,11,2,10,2,9,1700,'SM-32-00013',NULL,NULL,NULL,NULL,NULL,'NITRATO DE AMILO 500 MG CAJA X 10 TABLETAS','NITRATO DE AMILO',4.20,1.50,1.19,6.30,5.00,10.00,160.00,20.00,1,0,1,'Vasodilatador para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (359,32,6,11,2,11,2,9,1700,'SM-32-00014',NULL,NULL,NULL,NULL,NULL,'NITRATO DE AMILO 500 MG CAJA X 20 TABLETAS','NITRATO DE AMILO',7.60,1.50,1.19,11.40,9.04,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Nitrato de Amilo 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (360,32,6,11,2,12,2,9,1700,'SM-32-00015',NULL,NULL,NULL,NULL,NULL,'NITRATO DE AMILO 500 MG CAJA X 30 TABLETAS','NITRATO DE AMILO',10.50,1.50,1.19,15.75,12.50,10.00,120.00,15.00,1,0,1,'30 tabletas de Nitrato de Amilo 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (361,33,2,2,2,10,2,9,1700,'SM-33-00001',NULL,NULL,NULL,NULL,NULL,'HEPARINA 500 MG CAJA X 10 TABLETAS','HEPARINA SODICA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Anticoagulante para la prevención de trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (362,33,2,2,2,11,2,9,1700,'SM-33-00002',NULL,NULL,NULL,NULL,NULL,'HEPARINA 500 MG CAJA X 20 TABLETAS','HEPARINA SODICA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Heparina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (363,33,2,2,2,12,2,9,1700,'SM-33-00003',NULL,NULL,NULL,NULL,NULL,'HEPARINA 500 MG CAJA X 30 TABLETAS','HEPARINA SODICA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Heparina 500 mg para trombosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (364,33,3,9,2,10,2,9,1700,'SM-33-00004',NULL,NULL,NULL,NULL,NULL,'WARFARINA 500 MG CAJA X 10 TABLETAS','WARFARINA SODICA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Anticoagulante para la prevención de embolias. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (365,33,3,9,2,11,2,9,1700,'SM-33-00005',NULL,NULL,NULL,NULL,NULL,'WARFARINA 500 MG CAJA X 20 TABLETAS','WARFARINA SODICA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Warfarina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (366,33,3,9,2,12,2,9,1700,'SM-33-00006',NULL,NULL,NULL,NULL,NULL,'WARFARINA 500 MG CAJA X 30 TABLETAS','WARFARINA SODICA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Warfarina 500 mg para anticoagulación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (367,33,4,8,2,10,2,9,1700,'SM-33-00007',NULL,NULL,NULL,NULL,NULL,'ENOXAPARINA 500 MG CAJA X 10 TABLETAS','ENOXAPARINA SODICA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Anticoagulante para trombosis venosa profunda. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (368,33,4,8,2,11,2,9,1700,'SM-33-00008',NULL,NULL,NULL,NULL,NULL,'ENOXAPARINA 500 MG CAJA X 20 TABLETAS','ENOXAPARINA SODICA',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Enoxaparina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (369,33,4,8,2,12,2,9,1700,'SM-33-00009',NULL,NULL,NULL,NULL,NULL,'ENOXAPARINA 500 MG CAJA X 30 TABLETAS','ENOXAPARINA SODICA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,0,1,'30 tabletas de Enoxaparina 500 mg para trombosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (370,33,5,10,2,10,2,9,1700,'SM-33-00010',NULL,NULL,NULL,NULL,NULL,'DABIGATRAN 500 MG CAJA X 10 TABLETAS','DABIGATRAN ETEXILATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Anticoagulante para prevención de ictus. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (371,33,5,10,2,11,2,9,1700,'SM-33-00011',NULL,NULL,NULL,NULL,NULL,'DABIGATRAN 500 MG CAJA X 20 TABLETAS','DABIGATRAN ETEXILATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,0,1,'Caja de 20 tabletas de Dabigatran 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (372,33,5,10,2,12,2,9,1700,'SM-33-00012',NULL,NULL,NULL,NULL,NULL,'DABIGATRAN 500 MG CAJA X 30 TABLETAS','DABIGATRAN ETEXILATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,0,1,'30 tabletas de Dabigatran 500 mg para anticoagulación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (373,33,6,11,2,10,2,9,1700,'SM-33-00013',NULL,NULL,NULL,NULL,NULL,'RIVAROXABAN 500 MG CAJA X 10 TABLETAS','RIVAROXABAN',7.50,1.50,1.19,11.25,8.93,10.00,140.00,16.00,1,0,1,'Anticoagulante para trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (374,33,6,11,2,11,2,9,1700,'SM-33-00014',NULL,NULL,NULL,NULL,NULL,'RIVAROXABAN 500 MG CAJA X 20 TABLETAS','RIVAROXABAN',13.50,1.50,1.19,20.25,16.07,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Rivaroxaban 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (375,33,6,11,2,12,2,9,1700,'SM-33-00015',NULL,NULL,NULL,NULL,NULL,'RIVAROXABAN 500 MG CAJA X 30 TABLETAS','RIVAROXABAN',19.00,1.50,1.19,28.50,22.61,10.00,100.00,10.00,1,0,1,'30 tabletas de Rivaroxaban 500 mg para trombosis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (376,34,2,2,2,10,2,9,1700,'SM-34-00001',NULL,NULL,NULL,NULL,NULL,'CLOPIDOGREL 500 MG CAJA X 10 TABLETAS','CLOPIDOGREL BISULFATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Antiagregante para la prevención de eventos cardiovasculares. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (377,34,2,2,2,11,2,9,1700,'SM-34-00002',NULL,NULL,NULL,NULL,NULL,'CLOPIDOGREL 500 MG CAJA X 20 TABLETAS','CLOPIDOGREL BISULFATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Clopidogrel 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (378,34,2,2,2,12,2,9,1700,'SM-34-00003',NULL,NULL,NULL,NULL,NULL,'CLOPIDOGREL 500 MG CAJA X 30 TABLETAS','CLOPIDOGREL BISULFATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Clopidogrel 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (379,34,3,9,2,10,2,9,1700,'SM-34-00004',NULL,NULL,NULL,NULL,NULL,'TICAGRELOR 500 MG CAJA X 10 TABLETAS','TICAGRELOR',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antiagregante para síndrome coronario agudo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (380,34,3,9,2,11,2,9,1700,'SM-34-00005',NULL,NULL,NULL,NULL,NULL,'TICAGRELOR 500 MG CAJA X 20 TABLETAS','TICAGRELOR',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Ticagrelor 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (381,34,3,9,2,12,2,9,1700,'SM-34-00006',NULL,NULL,NULL,NULL,NULL,'TICAGRELOR 500 MG CAJA X 30 TABLETAS','TICAGRELOR',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Ticagrelor 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (382,34,4,8,2,10,2,9,1700,'SM-34-00007',NULL,NULL,NULL,NULL,NULL,'PRASUGREL 500 MG CAJA X 10 TABLETAS','PRASUGREL',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antiagregante para prevención de trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (383,34,4,8,2,11,2,9,1700,'SM-34-00008',NULL,NULL,NULL,NULL,NULL,'PRASUGREL 500 MG CAJA X 20 TABLETAS','PRASUGREL',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Prasugrel 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (384,34,4,8,2,12,2,9,1700,'SM-34-00009',NULL,NULL,NULL,NULL,NULL,'PRASUGREL 500 MG CAJA X 30 TABLETAS','PRASUGREL',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Prasugrel 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (385,34,5,10,2,10,2,9,1700,'SM-34-00010',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antiagregante en dosis bajas para prevención cardiovascular. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (386,34,5,10,2,11,2,9,1700,'SM-34-00011',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Aspirina 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (387,34,5,10,2,12,2,9,1700,'SM-34-00012',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Aspirina 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (388,34,6,11,2,10,2,9,1700,'SM-34-00013',NULL,NULL,NULL,NULL,NULL,'DIPIRIDAMOL 500 MG CAJA X 10 TABLETAS','DIPIRIDAMOL',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Antiagregante para prevención de trombosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (389,34,6,11,2,11,2,9,1700,'SM-34-00014',NULL,NULL,NULL,NULL,NULL,'DIPIRIDAMOL 500 MG CAJA X 20 TABLETAS','DIPIRIDAMOL',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Dipiridamol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (390,34,6,11,2,12,2,9,1700,'SM-34-00015',NULL,NULL,NULL,NULL,NULL,'DIPIRIDAMOL 500 MG CAJA X 30 TABLETAS','DIPIRIDAMOL',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Dipiridamol 500 mg para antiagregación.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (391,35,2,2,2,10,2,9,1700,'SM-35-00001',NULL,NULL,NULL,NULL,NULL,'SULFATO FERROSO 500 MG CAJA X 10 TABLETAS','SULFATO FERROSO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antianémico para la anemia ferropénica. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (392,35,2,2,2,11,2,9,1700,'SM-35-00002',NULL,NULL,NULL,NULL,NULL,'SULFATO FERROSO 500 MG CAJA X 20 TABLETAS','SULFATO FERROSO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Sulfato Ferroso 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (393,35,2,2,2,12,2,9,1700,'SM-35-00003',NULL,NULL,NULL,NULL,NULL,'SULFATO FERROSO 500 MG CAJA X 30 TABLETAS','SULFATO FERROSO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Sulfato Ferroso 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (394,35,3,9,2,10,2,9,1700,'SM-35-00004',NULL,NULL,NULL,NULL,NULL,'ACIDO FOLICO 500 MG CAJA X 10 TABLETAS','ACIDO FOLICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antianémico para la prevención de defectos del tubo neural. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (395,35,3,9,2,11,2,9,1700,'SM-35-00005',NULL,NULL,NULL,NULL,NULL,'ACIDO FOLICO 500 MG CAJA X 20 TABLETAS','ACIDO FOLICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Acido Folico 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (396,35,3,9,2,12,2,9,1700,'SM-35-00006',NULL,NULL,NULL,NULL,NULL,'ACIDO FOLICO 500 MG CAJA X 30 TABLETAS','ACIDO FOLICO',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Acido Folico 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (397,35,4,8,2,10,2,9,1700,'SM-35-00007',NULL,NULL,NULL,NULL,NULL,'VITAMINA B12 500 MG CAJA X 10 TABLETAS','CIANOCOBALAMINA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antianémico para la anemia megaloblástica. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (398,35,4,8,2,11,2,9,1700,'SM-35-00008',NULL,NULL,NULL,NULL,NULL,'VITAMINA B12 500 MG CAJA X 20 TABLETAS','CIANOCOBALAMINA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Vitamina B12 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (399,35,4,8,2,12,2,9,1700,'SM-35-00009',NULL,NULL,NULL,NULL,NULL,'VITAMINA B12 500 MG CAJA X 30 TABLETAS','CIANOCOBALAMINA',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Vitamina B12 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (400,35,5,10,2,10,2,9,1700,'SM-35-00010',NULL,NULL,NULL,NULL,NULL,'HIERRO POLIMALTOSA 500 MG CAJA X 10 TABLETAS','HIERRO POLIMALTOSA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antianémico de alta tolerancia para anemia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (401,35,5,10,2,11,2,9,1700,'SM-35-00011',NULL,NULL,NULL,NULL,NULL,'HIERRO POLIMALTOSA 500 MG CAJA X 20 TABLETAS','HIERRO POLIMALTOSA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Hierro Polimaltosa 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (402,35,5,10,2,12,2,9,1700,'SM-35-00012',NULL,NULL,NULL,NULL,NULL,'HIERRO POLIMALTOSA 500 MG CAJA X 30 TABLETAS','HIERRO POLIMALTOSA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Hierro Polimaltosa 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (403,35,6,11,2,10,2,9,1700,'SM-35-00013',NULL,NULL,NULL,NULL,NULL,'ERYTHROPOYETIN 500 MG CAJA X 10 TABLETAS','ERYTHROPOYETIN',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,0,0,1,'Antianémico para anemia renal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (404,35,6,11,2,11,2,9,1700,'SM-35-00014',NULL,NULL,NULL,NULL,NULL,'ERYTHROPOYETIN 500 MG CAJA X 20 TABLETAS','ERYTHROPOYETIN',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,0,0,1,'Caja de 20 tabletas de Erythropoyetin 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (405,35,6,11,2,12,2,9,1700,'SM-35-00015',NULL,NULL,NULL,NULL,NULL,'ERYTHROPOYETIN 500 MG CAJA X 30 TABLETAS','ERYTHROPOYETIN',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,0,0,1,'30 tabletas de Erythropoyetin 500 mg para anemia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (406,36,2,2,2,10,2,9,1700,'SM-36-00001',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 10 TABLETAS','ALBENDAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antiparasitario para lombrices y helmintos. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (407,36,2,2,2,11,2,9,1700,'SM-36-00002',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 20 TABLETAS','ALBENDAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Albendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (408,36,2,2,2,12,2,9,1700,'SM-36-00003',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 30 TABLETAS','ALBENDAZOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Albendazol 500 mg para parasitosis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (409,36,3,9,2,10,2,9,1700,'SM-36-00004',NULL,NULL,NULL,NULL,NULL,'PAMOATO DE PIRANTEL 500 MG CAJA X 10 TABLETAS','PAMOATO DE PIRANTEL',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antiparasitario para oxiuros y ascárides. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (410,36,3,9,2,11,2,9,1700,'SM-36-00005',NULL,NULL,NULL,NULL,NULL,'PAMOATO DE PIRANTEL 500 MG CAJA X 20 TABLETAS','PAMOATO DE PIRANTEL',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Pamoato de Pirantel 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (411,36,3,9,2,12,2,9,1700,'SM-36-00006',NULL,NULL,NULL,NULL,NULL,'PAMOATO DE PIRANTEL 500 MG CAJA X 30 TABLETAS','PAMOATO DE PIRANTEL',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Pamoato de Pirantel 500 mg para parásitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (412,36,4,8,2,10,2,9,1700,'SM-36-00007',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 10 TABLETAS','MEBENDAZOL',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antiparasitario para lombrices intestinales. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (413,36,4,8,2,11,2,9,1700,'SM-36-00008',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 20 TABLETAS','MEBENDAZOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Mebendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (414,36,4,8,2,12,2,9,1700,'SM-36-00009',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 30 TABLETAS','MEBENDAZOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Mebendazol 500 mg para parasitosis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (415,36,5,10,2,10,2,9,1700,'SM-36-00010',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 10 TABLETAS','TINIDAZOL',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Antiparasitario para giardiasis y amebiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (416,36,5,10,2,11,2,9,1700,'SM-36-00011',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 20 TABLETAS','TINIDAZOL',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Tinidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (417,36,5,10,2,12,2,9,1700,'SM-36-00012',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 30 TABLETAS','TINIDAZOL',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,0,0,1,'30 tabletas de Tinidazol 500 mg para parásitos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (418,36,6,11,2,10,2,9,1700,'SM-36-00013',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 10 TABLETAS','NITAZOXANIDA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antiparasitario de amplio espectro. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (419,36,6,11,2,11,2,9,1700,'SM-36-00014',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 20 TABLETAS','NITAZOXANIDA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Nitazoxanida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (420,36,6,11,2,12,2,9,1700,'SM-36-00015',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 30 TABLETAS','NITAZOXANIDA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'30 tabletas de Nitazoxanida 500 mg para parasitosis.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (421,37,2,2,2,10,2,9,1700,'SM-37-00001',NULL,NULL,NULL,NULL,NULL,'METRONIDAZOL 500 MG CAJA X 10 TABLETAS','METRONIDAZOL',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,1,0,1,'Antiprotozoario para amebiasis y giardiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (422,37,2,2,2,11,2,9,1700,'SM-37-00002',NULL,NULL,NULL,NULL,NULL,'METRONIDAZOL 500 MG CAJA X 20 TABLETAS','METRONIDAZOL',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Metronidazol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (423,37,2,2,2,12,2,9,1700,'SM-37-00003',NULL,NULL,NULL,NULL,NULL,'METRONIDAZOL 500 MG CAJA X 30 TABLETAS','METRONIDAZOL',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,1,0,1,'30 tabletas de Metronidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (424,37,3,9,2,10,2,9,1700,'SM-37-00004',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 10 TABLETAS','TINIDAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antiprotozoario para amebiasis y giardiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (425,37,3,9,2,11,2,9,1700,'SM-37-00005',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 20 TABLETAS','TINIDAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Tinidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (426,37,3,9,2,12,2,9,1700,'SM-37-00006',NULL,NULL,NULL,NULL,NULL,'TINIDAZOL 500 MG CAJA X 30 TABLETAS','TINIDAZOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Tinidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (427,37,4,8,2,10,2,9,1700,'SM-37-00007',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 10 TABLETAS','NITAZOXANIDA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,0,0,1,'Antiprotozoario de amplio espectro. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (428,37,4,8,2,11,2,9,1700,'SM-37-00008',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 20 TABLETAS','NITAZOXANIDA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Nitazoxanida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (429,37,4,8,2,12,2,9,1700,'SM-37-00009',NULL,NULL,NULL,NULL,NULL,'NITAZOXANIDA 500 MG CAJA X 30 TABLETAS','NITAZOXANIDA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,0,0,1,'30 tabletas de Nitazoxanida 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (430,37,5,10,2,10,2,9,1700,'SM-37-00010',NULL,NULL,NULL,NULL,NULL,'SECNIDAZOL 500 MG CAJA X 10 TABLETAS','SECNIDAZOL',2.50,1.50,1.19,3.75,2.98,10.00,190.00,25.00,0,0,1,'Antiprotozoario para amebiasis y giardiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (431,37,5,10,2,11,2,9,1700,'SM-37-00011',NULL,NULL,NULL,NULL,NULL,'SECNIDAZOL 500 MG CAJA X 20 TABLETAS','SECNIDAZOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Secnidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (432,37,5,10,2,12,2,9,1700,'SM-37-00012',NULL,NULL,NULL,NULL,NULL,'SECNIDAZOL 500 MG CAJA X 30 TABLETAS','SECNIDAZOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Secnidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (433,37,6,11,2,10,2,9,1700,'SM-37-00013',NULL,NULL,NULL,NULL,NULL,'ORNIDAZOL 500 MG CAJA X 10 TABLETAS','ORNIDAZOL',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Antiprotozoario para amebiasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (434,37,6,11,2,11,2,9,1700,'SM-37-00014',NULL,NULL,NULL,NULL,NULL,'ORNIDAZOL 500 MG CAJA X 20 TABLETAS','ORNIDAZOL',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Ornidazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (435,37,6,11,2,12,2,9,1700,'SM-37-00015',NULL,NULL,NULL,NULL,NULL,'ORNIDAZOL 500 MG CAJA X 30 TABLETAS','ORNIDAZOL',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Ornidazol 500 mg para protozoos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (436,38,2,2,2,10,3,9,1700,'SM-38-00001',NULL,NULL,NULL,NULL,NULL,'ZIDOVUDINA 100 MG CAJA X 10 TABLETAS','ZIDOVUDINA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (437,38,2,2,2,11,3,9,1700,'SM-38-00002',NULL,NULL,NULL,NULL,NULL,'ZIDOVUDINA 100 MG CAJA X 20 TABLETAS','ZIDOVUDINA',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Zidovudina 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (438,38,2,2,2,12,3,9,1700,'SM-38-00003',NULL,NULL,NULL,NULL,NULL,'ZIDOVUDINA 100 MG CAJA X 30 TABLETAS','ZIDOVUDINA',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Zidovudina 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (439,38,3,9,2,10,3,9,1700,'SM-38-00004',NULL,NULL,NULL,NULL,NULL,'LAMIVUDINA 100 MG CAJA X 10 TABLETAS','LAMIVUDINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (440,38,3,9,2,11,3,9,1700,'SM-38-00005',NULL,NULL,NULL,NULL,NULL,'LAMIVUDINA 100 MG CAJA X 20 TABLETAS','LAMIVUDINA',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,1,1,'Caja de 20 tabletas de Lamivudina 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (441,38,3,9,2,12,3,9,1700,'SM-38-00006',NULL,NULL,NULL,NULL,NULL,'LAMIVUDINA 100 MG CAJA X 30 TABLETAS','LAMIVUDINA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'30 tabletas de Lamivudina 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (442,38,4,8,2,10,3,9,1700,'SM-38-00007',NULL,NULL,NULL,NULL,NULL,'NEVIRAPINA 100 MG CAJA X 10 TABLETAS','NEVIRAPINA',6.50,1.50,1.19,9.75,7.74,10.00,150.00,18.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (443,38,4,8,2,11,3,9,1700,'SM-38-00008',NULL,NULL,NULL,NULL,NULL,'NEVIRAPINA 100 MG CAJA X 20 TABLETAS','NEVIRAPINA',11.70,1.50,1.19,17.55,13.92,10.00,130.00,16.00,1,1,1,'Caja de 20 tabletas de Nevirapina 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (444,38,4,8,2,12,3,9,1700,'SM-38-00009',NULL,NULL,NULL,NULL,NULL,'NEVIRAPINA 100 MG CAJA X 30 TABLETAS','NEVIRAPINA',16.20,1.50,1.19,24.30,19.28,10.00,110.00,12.00,1,1,1,'30 tabletas de Nevirapina 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (445,38,5,10,2,10,3,9,1700,'SM-38-00010',NULL,NULL,NULL,NULL,NULL,'EFAVIRENZ 100 MG CAJA X 10 TABLETAS','EFAVIRENZ',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (446,38,5,10,2,11,3,9,1700,'SM-38-00011',NULL,NULL,NULL,NULL,NULL,'EFAVIRENZ 100 MG CAJA X 20 TABLETAS','EFAVIRENZ',16.20,1.50,1.19,24.30,19.28,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Efavirenz 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (447,38,5,10,2,12,3,9,1700,'SM-38-00012',NULL,NULL,NULL,NULL,NULL,'EFAVIRENZ 100 MG CAJA X 30 TABLETAS','EFAVIRENZ',22.50,1.50,1.19,33.75,26.78,10.00,90.00,9.00,1,1,1,'30 tabletas de Efavirenz 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (448,38,6,11,2,10,3,9,1700,'SM-38-00013',NULL,NULL,NULL,NULL,NULL,'DOLUTEGRAVIR 100 MG CAJA X 10 TABLETAS','DOLUTEGRAVIR',10.00,1.50,1.19,15.00,11.90,10.00,110.00,12.00,1,1,1,'Antirretroviral para el VIH. 100 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (449,38,6,11,2,11,3,9,1700,'SM-38-00014',NULL,NULL,NULL,NULL,NULL,'DOLUTEGRAVIR 100 MG CAJA X 20 TABLETAS','DOLUTEGRAVIR',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Dolutegravir 100 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (450,38,6,11,2,12,3,9,1700,'SM-38-00015',NULL,NULL,NULL,NULL,NULL,'DOLUTEGRAVIR 100 MG CAJA X 30 TABLETAS','DOLUTEGRAVIR',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,1,1,'30 tabletas de Dolutegravir 100 mg para VIH.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (451,39,2,2,2,10,2,9,1700,'SM-39-00001',NULL,NULL,NULL,NULL,NULL,'CICLOSPORINA 500 MG CAJA X 10 TABLETAS','CICLOSPORINA',15.00,1.50,1.19,22.50,17.85,10.00,100.00,10.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (452,39,2,2,2,11,2,9,1700,'SM-39-00002',NULL,NULL,NULL,NULL,NULL,'CICLOSPORINA 500 MG CAJA X 20 TABLETAS','CICLOSPORINA',27.00,1.50,1.19,40.50,32.13,10.00,90.00,9.00,1,1,1,'Caja de 20 tabletas de Ciclosporina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (453,39,2,2,2,12,2,9,1700,'SM-39-00003',NULL,NULL,NULL,NULL,NULL,'CICLOSPORINA 500 MG CAJA X 30 TABLETAS','CICLOSPORINA',38.00,1.50,1.19,57.00,45.22,10.00,80.00,8.00,1,1,1,'30 tabletas de Ciclosporina 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (454,39,3,9,2,10,2,9,1700,'SM-39-00004',NULL,NULL,NULL,NULL,NULL,'TACROLIMUS 500 MG CAJA X 10 TABLETAS','TACROLIMUS',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (455,39,3,9,2,11,2,9,1700,'SM-39-00005',NULL,NULL,NULL,NULL,NULL,'TACROLIMUS 500 MG CAJA X 20 TABLETAS','TACROLIMUS',32.40,1.50,1.19,48.60,38.56,10.00,90.00,9.00,1,1,1,'Caja de 20 tabletas de Tacrolimus 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (456,39,3,9,2,12,2,9,1700,'SM-39-00006',NULL,NULL,NULL,NULL,NULL,'TACROLIMUS 500 MG CAJA X 30 TABLETAS','TACROLIMUS',45.00,1.50,1.19,67.50,53.55,10.00,80.00,8.00,1,1,1,'30 tabletas de Tacrolimus 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (457,39,4,8,2,10,2,9,1700,'SM-39-00007',NULL,NULL,NULL,NULL,NULL,'SIROLIMUS 500 MG CAJA X 10 TABLETAS','SIROLIMUS',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (458,39,4,8,2,11,2,9,1700,'SM-39-00008',NULL,NULL,NULL,NULL,NULL,'SIROLIMUS 500 MG CAJA X 20 TABLETAS','SIROLIMUS',36.00,1.50,1.19,54.00,42.84,10.00,90.00,9.00,1,1,1,'Caja de 20 tabletas de Sirolimus 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (459,39,4,8,2,12,2,9,1700,'SM-39-00009',NULL,NULL,NULL,NULL,NULL,'SIROLIMUS 500 MG CAJA X 30 TABLETAS','SIROLIMUS',50.00,1.50,1.19,75.00,59.50,10.00,80.00,8.00,1,1,1,'30 tabletas de Sirolimus 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (460,39,5,10,2,10,2,9,1700,'SM-39-00010',NULL,NULL,NULL,NULL,NULL,'MICOFENOLATO 500 MG CAJA X 10 TABLETAS','MICOFENOLATO MOFETILO',12.00,1.50,1.19,18.00,14.28,10.00,110.00,12.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (461,39,5,10,2,11,2,9,1700,'SM-39-00011',NULL,NULL,NULL,NULL,NULL,'MICOFENOLATO 500 MG CAJA X 20 TABLETAS','MICOFENOLATO MOFETILO',21.60,1.50,1.19,32.40,25.70,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Micofenolato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (462,39,5,10,2,12,2,9,1700,'SM-39-00012',NULL,NULL,NULL,NULL,NULL,'MICOFENOLATO 500 MG CAJA X 30 TABLETAS','MICOFENOLATO MOFETILO',30.00,1.50,1.19,45.00,35.70,10.00,90.00,9.00,1,1,1,'30 tabletas de Micofenolato 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (463,39,6,11,2,10,2,9,1700,'SM-39-00013',NULL,NULL,NULL,NULL,NULL,'AZATIOPRINA 500 MG CAJA X 10 TABLETAS','AZATIOPRINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,1,1,'Inmunosupresor para trasplantes. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (464,39,6,11,2,11,2,9,1700,'SM-39-00014',NULL,NULL,NULL,NULL,NULL,'AZATIOPRINA 500 MG CAJA X 20 TABLETAS','AZATIOPRINA',18.00,1.50,1.19,27.00,21.42,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Azatioprina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (465,39,6,11,2,12,2,9,1700,'SM-39-00015',NULL,NULL,NULL,NULL,NULL,'AZATIOPRINA 500 MG CAJA X 30 TABLETAS','AZATIOPRINA',25.00,1.50,1.19,37.50,29.75,10.00,100.00,10.00,1,1,1,'30 tabletas de Azatioprina 500 mg para trasplantes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (466,40,2,2,2,10,2,9,1700,'SM-40-00001',NULL,NULL,NULL,NULL,NULL,'METOTREXATO 500 MG CAJA X 10 TABLETAS','METOTREXATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'AntiarTRITICO para artritis reumatoide. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (467,40,2,2,2,11,2,9,1700,'SM-40-00002',NULL,NULL,NULL,NULL,NULL,'METOTREXATO 500 MG CAJA X 20 TABLETAS','METOTREXATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Metotrexato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (468,40,2,2,2,12,2,9,1700,'SM-40-00003',NULL,NULL,NULL,NULL,NULL,'METOTREXATO 500 MG CAJA X 30 TABLETAS','METOTREXATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Metotrexato 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (469,40,3,9,2,10,2,9,1700,'SM-40-00004',NULL,NULL,NULL,NULL,NULL,'SULFASALAZINA 500 MG CAJA X 10 TABLETAS','SULFASALAZINA',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,1,0,1,'AntiarTRITICO para artritis reumatoide. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (470,40,3,9,2,11,2,9,1700,'SM-40-00005',NULL,NULL,NULL,NULL,NULL,'SULFASALAZINA 500 MG CAJA X 20 TABLETAS','SULFASALAZINA',7.20,1.50,1.19,10.80,8.57,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Sulfasalazina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (471,40,3,9,2,12,2,9,1700,'SM-40-00006',NULL,NULL,NULL,NULL,NULL,'SULFASALAZINA 500 MG CAJA X 30 TABLETAS','SULFASALAZINA',10.00,1.50,1.19,15.00,11.90,10.00,130.00,16.00,1,0,1,'30 tabletas de Sulfasalazina 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (472,40,4,8,2,10,2,9,1700,'SM-40-00007',NULL,NULL,NULL,NULL,NULL,'HIDROXICLOROQUINA 500 MG CAJA X 10 TABLETAS','HIDROXICLOROQUINA SULFATO',3.50,1.50,1.19,5.25,4.17,10.00,180.00,22.00,1,0,1,'AntiarTRITICO para lupus y artritis reumatoide. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (473,40,4,8,2,11,2,9,1700,'SM-40-00008',NULL,NULL,NULL,NULL,NULL,'HIDROXICLOROQUINA 500 MG CAJA X 20 TABLETAS','HIDROXICLOROQUINA SULFATO',6.30,1.50,1.19,9.45,7.50,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Hidroxicloroquina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (474,40,4,8,2,12,2,9,1700,'SM-40-00009',NULL,NULL,NULL,NULL,NULL,'HIDROXICLOROQUINA 500 MG CAJA X 30 TABLETAS','HIDROXICLOROQUINA SULFATO',8.80,1.50,1.19,13.20,10.47,10.00,140.00,18.00,1,0,1,'30 tabletas de Hidroxicloroquina 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (475,40,5,10,2,10,2,9,1700,'SM-40-00010',NULL,NULL,NULL,NULL,NULL,'LEFLUNOMIDA 500 MG CAJA X 10 TABLETAS','LEFLUNOMIDA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'AntiarTRITICO para artritis reumatoide. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (476,40,5,10,2,11,2,9,1700,'SM-40-00011',NULL,NULL,NULL,NULL,NULL,'LEFLUNOMIDA 500 MG CAJA X 20 TABLETAS','LEFLUNOMIDA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Leflunomida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (477,40,5,10,2,12,2,9,1700,'SM-40-00012',NULL,NULL,NULL,NULL,NULL,'LEFLUNOMIDA 500 MG CAJA X 30 TABLETAS','LEFLUNOMIDA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Leflunomida 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (478,40,6,11,2,10,2,9,1700,'SM-40-00013',NULL,NULL,NULL,NULL,NULL,'ETANERCEPT 500 MG CAJA X 10 TABLETAS','ETANERCEPT',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,0,1,'AntiarTRITICO biológico para artritis reumatoide. 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (479,40,6,11,2,11,2,9,1700,'SM-40-00014',NULL,NULL,NULL,NULL,NULL,'ETANERCEPT 500 MG CAJA X 20 TABLETAS','ETANERCEPT',45.00,1.50,1.19,67.50,53.55,10.00,80.00,8.00,1,0,1,'Caja de 20 tabletas de Etanercept 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (480,40,6,11,2,12,2,9,1700,'SM-40-00015',NULL,NULL,NULL,NULL,NULL,'ETANERCEPT 500 MG CAJA X 30 TABLETAS','ETANERCEPT',60.00,1.50,1.19,90.00,71.40,10.00,70.00,7.00,1,0,1,'30 tabletas de Etanercept 500 mg para artritis.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (481,41,2,2,2,10,2,9,1700,'SM-41-00001',NULL,NULL,NULL,NULL,NULL,'ALOPURINOL 500 MG CAJA X 10 TABLETAS','ALOPURINOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antigotoso para la prevención de ataques de gota. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (482,41,2,2,2,11,2,9,1700,'SM-41-00002',NULL,NULL,NULL,NULL,NULL,'ALOPURINOL 500 MG CAJA X 20 TABLETAS','ALOPURINOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Alopurinol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (483,41,2,2,2,12,2,9,1700,'SM-41-00003',NULL,NULL,NULL,NULL,NULL,'ALOPURINOL 500 MG CAJA X 30 TABLETAS','ALOPURINOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Alopurinol 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (484,41,3,9,2,10,2,9,1700,'SM-41-00004',NULL,NULL,NULL,NULL,NULL,'FEBUXOSTAT 500 MG CAJA X 10 TABLETAS','FEBUXOSTAT',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Antigotoso para hiperuricemia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (485,41,3,9,2,11,2,9,1700,'SM-41-00005',NULL,NULL,NULL,NULL,NULL,'FEBUXOSTAT 500 MG CAJA X 20 TABLETAS','FEBUXOSTAT',8.10,1.50,1.19,12.15,9.64,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Febuxostat 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (486,41,3,9,2,12,2,9,1700,'SM-41-00006',NULL,NULL,NULL,NULL,NULL,'FEBUXOSTAT 500 MG CAJA X 30 TABLETAS','FEBUXOSTAT',11.20,1.50,1.19,16.80,13.33,10.00,120.00,15.00,0,0,1,'30 tabletas de Febuxostat 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (487,41,4,8,2,10,2,9,1700,'SM-41-00007',NULL,NULL,NULL,NULL,NULL,'COLCHICINA 500 MG CAJA X 10 TABLETAS','COLCHICINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antigotoso para ataques agudos de gota. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (488,41,4,8,2,11,2,9,1700,'SM-41-00008',NULL,NULL,NULL,NULL,NULL,'COLCHICINA 500 MG CAJA X 20 TABLETAS','COLCHICINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Colchicina 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (489,41,4,8,2,12,2,9,1700,'SM-41-00009',NULL,NULL,NULL,NULL,NULL,'COLCHICINA 500 MG CAJA X 30 TABLETAS','COLCHICINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Colchicina 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (490,41,5,10,2,10,2,9,1700,'SM-41-00010',NULL,NULL,NULL,NULL,NULL,'PROBENECID 500 MG CAJA X 10 TABLETAS','PROBENECID',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,0,0,1,'Antigotoso para la excreción de ácido úrico. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (491,41,5,10,2,11,2,9,1700,'SM-41-00011',NULL,NULL,NULL,NULL,NULL,'PROBENECID 500 MG CAJA X 20 TABLETAS','PROBENECID',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Probenecid 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (492,41,5,10,2,12,2,9,1700,'SM-41-00012',NULL,NULL,NULL,NULL,NULL,'PROBENECID 500 MG CAJA X 30 TABLETAS','PROBENECID',8.00,1.50,1.19,12.00,9.52,10.00,130.00,16.00,0,0,1,'30 tabletas de Probenecid 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (493,41,6,11,2,10,2,9,1700,'SM-41-00013',NULL,NULL,NULL,NULL,NULL,'SULFINPIRAZONA 500 MG CAJA X 10 TABLETAS','SULFINPIRAZONA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antigotoso para hiperuricemia. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (494,41,6,11,2,11,2,9,1700,'SM-41-00014',NULL,NULL,NULL,NULL,NULL,'SULFINPIRAZONA 500 MG CAJA X 20 TABLETAS','SULFINPIRAZONA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Sulfinpirazona 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (495,41,6,11,2,12,2,9,1700,'SM-41-00015',NULL,NULL,NULL,NULL,NULL,'SULFINPIRAZONA 500 MG CAJA X 30 TABLETAS','SULFINPIRAZONA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Sulfinpirazona 500 mg para gota.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (496,42,2,2,2,10,2,9,1700,'SM-42-00001',NULL,NULL,NULL,NULL,NULL,'PRAZIQUANTEL 500 MG CAJA X 10 TABLETAS','PRAZIQUANTEL',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antihelmíntico para esquistosomiasis y teniasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (497,42,2,2,2,11,2,9,1700,'SM-42-00002',NULL,NULL,NULL,NULL,NULL,'PRAZIQUANTEL 500 MG CAJA X 20 TABLETAS','PRAZIQUANTEL',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Caja de 20 tabletas de Praziquantel 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (498,42,2,2,2,12,2,9,1700,'SM-42-00003',NULL,NULL,NULL,NULL,NULL,'PRAZIQUANTEL 500 MG CAJA X 30 TABLETAS','PRAZIQUANTEL',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,0,0,1,'30 tabletas de Praziquantel 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (499,42,3,9,2,10,2,9,1700,'SM-42-00004',NULL,NULL,NULL,NULL,NULL,'IVERMECTINA 500 MG CAJA X 10 TABLETAS','IVERMECTINA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Antihelmíntico para estrongiloidiasis y oncocercosis. 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (500,42,3,9,2,11,2,9,1700,'SM-42-00005',NULL,NULL,NULL,NULL,NULL,'IVERMECTINA 500 MG CAJA X 20 TABLETAS','IVERMECTINA',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,0,0,1,'Caja de 20 tabletas de Ivermectina 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (501,42,3,9,2,12,2,9,1700,'SM-42-00006',NULL,NULL,NULL,NULL,NULL,'IVERMECTINA 500 MG CAJA X 30 TABLETAS','IVERMECTINA',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,0,0,1,'30 tabletas de Ivermectina 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (502,42,4,8,2,10,2,9,1700,'SM-42-00007',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 10 TABLETAS','MEBENDAZOL',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antihelmíntico para lombrices intestinales. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (503,42,4,8,2,11,2,9,1700,'SM-42-00008',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 20 TABLETAS','MEBENDAZOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Mebendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (504,42,4,8,2,12,2,9,1700,'SM-42-00009',NULL,NULL,NULL,NULL,NULL,'Mebendazol 500 MG CAJA X 30 TABLETAS','MEBENDAZOL',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Mebendazol 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (505,42,5,10,2,10,2,9,1700,'SM-42-00010',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 10 TABLETAS','ALBENDAZOL',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antihelmíntico para neurocisticercosis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (506,42,5,10,2,11,2,9,1700,'SM-42-00011',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 20 TABLETAS','ALBENDAZOL',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Albendazol 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (507,42,5,10,2,12,2,9,1700,'SM-42-00012',NULL,NULL,NULL,NULL,NULL,'ALBENDAZOL 500 MG CAJA X 30 TABLETAS','ALBENDAZOL',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Albendazol 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (508,42,6,11,2,10,2,9,1700,'SM-42-00013',NULL,NULL,NULL,NULL,NULL,'NICLOSAMIDA 500 MG CAJA X 10 TABLETAS','NICLOSAMIDA',3.50,1.50,1.19,5.25,4.17,10.00,170.00,20.00,0,0,1,'Antihelmíntico para teniasis. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (509,42,6,11,2,11,2,9,1700,'SM-42-00014',NULL,NULL,NULL,NULL,NULL,'NICLOSAMIDA 500 MG CAJA X 20 TABLETAS','NICLOSAMIDA',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Niclosamida 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (510,42,6,11,2,12,2,9,1700,'SM-42-00015',NULL,NULL,NULL,NULL,NULL,'NICLOSAMIDA 500 MG CAJA X 30 TABLETAS','NICLOSAMIDA',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,0,0,1,'30 tabletas de Niclosamida 500 mg para helmintos.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (511,43,2,2,7,20,2,9,1700,'SM-43-00001',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CREMA TUBO X 30 G','HIDROCORTISONA',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antiprurítico para aliviar la picazón y la inflamación. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (512,43,2,2,7,21,2,9,1700,'SM-43-00002',NULL,NULL,NULL,NULL,NULL,'HIDROCORTISONA 500 MG CREMA TUBO X 50 G','HIDROCORTISONA',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Hidrocortisona 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (513,43,3,9,7,20,2,9,1700,'SM-43-00003',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 500 MG CREMA TUBO X 30 G','DIFENHIDRAMINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antiprurítico para alergias y picazón. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (514,43,3,9,7,21,2,9,1700,'SM-43-00004',NULL,NULL,NULL,NULL,NULL,'DIFENHIDRAMINA 500 MG CREMA TUBO X 50 G','DIFENHIDRAMINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Tubo de 50 g de Difenhidramina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (515,43,4,8,7,20,2,9,1700,'SM-43-00005',NULL,NULL,NULL,NULL,NULL,'PIRIDOXINA 500 MG CREMA TUBO X 30 G','PIRIDOXINA',3.20,1.50,1.19,4.80,3.81,10.00,170.00,20.00,0,0,1,'Antiprurítico para la picazón. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (516,43,4,8,7,21,2,9,1700,'SM-43-00006',NULL,NULL,NULL,NULL,NULL,'PIRIDOXINA 500 MG CREMA TUBO X 50 G','PIRIDOXINA',5.80,1.50,1.19,8.70,6.90,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Piridoxina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (517,43,5,10,7,20,2,9,1700,'SM-43-00007',NULL,NULL,NULL,NULL,NULL,'DOXEPINA 500 MG CREMA TUBO X 30 G','DOXEPINA CLORHIDRATO',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,0,0,1,'Antiprurítico para dermatitis atópica. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (518,43,5,10,7,21,2,9,1700,'SM-43-00008',NULL,NULL,NULL,NULL,NULL,'DOXEPINA 500 MG CREMA TUBO X 50 G','DOXEPINA CLORHIDRATO',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Doxepina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (519,43,6,11,7,20,2,9,1700,'SM-43-00009',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 500 MG CREMA TUBO X 30 G','CETIRIZINA CLORHIDRATO',3.80,1.50,1.19,5.70,4.52,10.00,160.00,20.00,0,0,1,'Antiprurítico para alergias cutáneas. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (520,43,6,11,7,21,2,9,1700,'SM-43-00010',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 500 MG CREMA TUBO X 50 G','CETIRIZINA CLORHIDRATO',6.80,1.50,1.19,10.20,8.09,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Cetirizina 500 mg para picazón.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (521,44,2,2,7,20,2,9,1700,'SM-44-00001',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG CREMA TUBO X 30 G','CLORHEXIDINA GLUCONATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antiséptico para la desinfección de heridas. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (522,44,2,2,7,21,2,9,1700,'SM-44-00002',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG CREMA TUBO X 50 G','CLORHEXIDINA GLUCONATO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Tubo de 50 g de Clorhexidina 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (523,44,3,9,7,20,2,9,1700,'SM-44-00003',NULL,NULL,NULL,NULL,NULL,'POVIDONA YODADA 500 MG CREMA TUBO X 30 G','POVIDONA YODADA',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Antiséptico para quemaduras y heridas. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (524,44,3,9,7,21,2,9,1700,'SM-44-00004',NULL,NULL,NULL,NULL,NULL,'POVIDONA YODADA 500 MG CREMA TUBO X 50 G','POVIDONA YODADA',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Povidona Yodada 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (525,44,4,8,7,20,2,9,1700,'SM-44-00005',NULL,NULL,NULL,NULL,NULL,'PEROXIDO DE BENZOILO 500 MG CREMA TUBO X 30 G','PEROXIDO DE BENZOILO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,20.00,0,0,1,'Antiséptico para el acné. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (526,44,4,8,7,21,2,9,1700,'SM-44-00006',NULL,NULL,NULL,NULL,NULL,'PEROXIDO DE BENZOILO 500 MG CREMA TUBO X 50 G','PEROXIDO DE BENZOILO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Tubo de 50 g de Peróxido de Benzoilo 500 mg para acné.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (527,44,5,10,7,20,2,9,1700,'SM-44-00007',NULL,NULL,NULL,NULL,NULL,'ACIDO BORICO 500 MG CREMA TUBO X 30 G','ACIDO BORICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antiséptico para infecciones leves. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (528,44,5,10,7,21,2,9,1700,'SM-44-00008',NULL,NULL,NULL,NULL,NULL,'ACIDO BORICO 500 MG CREMA TUBO X 50 G','ACIDO BORICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Tubo de 50 g de Ácido Bórico 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (529,44,6,11,7,20,2,9,1700,'SM-44-00009',NULL,NULL,NULL,NULL,NULL,'NITRATO DE PLATA 500 MG CREMA TUBO X 30 G','NITRATO DE PLATA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Antiséptico para quemaduras. 500 mg en crema.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (530,44,6,11,7,21,2,9,1700,'SM-44-00010',NULL,NULL,NULL,NULL,NULL,'NITRATO DE PLATA 500 MG CREMA TUBO X 50 G','NITRATO DE PLATA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,0,0,1,'Tubo de 50 g de Nitrato de Plata 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (531,45,2,2,12,42,2,9,1700,'SM-45-00001',NULL,NULL,NULL,NULL,NULL,'ALCOHOL 500 MG SOLUCION FRASCO X 60 ML','ALCOHOL ETILICO',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Desinfectante para la limpieza de superficies y heridas. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (532,45,2,2,12,45,2,9,1700,'SM-45-00002',NULL,NULL,NULL,NULL,NULL,'ALCOHOL 500 MG SOLUCION FRASCO X 500 ML','ALCOHOL ETILICO',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Frasco de 500 ml de Alcohol 500 mg para desinfección.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (533,45,3,9,12,42,2,9,1700,'SM-45-00003',NULL,NULL,NULL,NULL,NULL,'AGUA OXIGENADA 500 MG SOLUCION FRASCO X 60 ML','PEROXIDO DE HIDROGENO',2.00,1.50,1.19,3.00,2.38,10.00,190.00,25.00,0,0,1,'Desinfectante para heridas. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (534,45,3,9,12,45,2,9,1700,'SM-45-00004',NULL,NULL,NULL,NULL,NULL,'AGUA OXIGENADA 500 MG SOLUCION FRASCO X 500 ML','PEROXIDO DE HIDROGENO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Frasco de 500 ml de Agua Oxigenada 500 mg para heridas.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (535,45,4,8,12,42,2,9,1700,'SM-45-00005',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG SOLUCION FRASCO X 60 ML','CLORHEXIDINA GLUCONATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Desinfectante para la piel. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (536,45,4,8,12,45,2,9,1700,'SM-45-00006',NULL,NULL,NULL,NULL,NULL,'CLORHEXIDINA 500 MG SOLUCION FRASCO X 500 ML','CLORHEXIDINA GLUCONATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,18.00,0,0,1,'Frasco de 500 ml de Clorhexidina 500 mg para desinfección.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (537,45,5,10,12,42,2,9,1700,'SM-45-00007',NULL,NULL,NULL,NULL,NULL,'YODO 500 MG SOLUCION FRASCO X 60 ML','YODO',2.80,1.50,1.19,4.20,3.33,10.00,170.00,22.00,0,0,1,'Desinfectante para heridas. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (538,45,5,10,12,45,2,9,1700,'SM-45-00008',NULL,NULL,NULL,NULL,NULL,'YODO 500 MG SOLUCION FRASCO X 500 ML','YODO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,0,0,1,'Frasco de 500 ml de Yodo 500 mg para desinfección.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (539,45,6,11,12,42,2,9,1700,'SM-45-00009',NULL,NULL,NULL,NULL,NULL,'AMONIO CUATERNARIO 500 MG SOLUCION FRASCO X 60 ML','AMONIO CUATERNARIO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Desinfectante para superficies. 500 mg en solución.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (540,45,6,11,12,45,2,9,1700,'SM-45-00010',NULL,NULL,NULL,NULL,NULL,'AMONIO CUATERNARIO 500 MG SOLUCION FRASCO X 500 ML','AMONIO CUATERNARIO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Frasco de 500 ml de Amonio Cuaternario 500 mg para superficies.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (541,46,2,2,5,4,3,9,1700,'SM-46-00001',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 100 MG INYECTABLE AMPOLLA 1 ML','LIDOCAINA CLORHIDRATO',2.00,1.50,1.19,3.00,2.38,10.00,190.00,25.00,1,0,1,'Anestésico local para procedimientos médicos. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (542,46,2,2,5,17,3,9,1700,'SM-46-00002',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','LIDOCAINA CLORHIDRATO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,1,0,1,'Caja de 10 ampollas de Lidocaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (543,46,3,9,5,4,3,9,1700,'SM-46-00003',NULL,NULL,NULL,NULL,NULL,'BUPIVACAINA 100 MG INYECTABLE AMPOLLA 1 ML','BUPIVACAINA CLORHIDRATO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,1,0,1,'Anestésico local para cirugía menor. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (544,46,3,9,5,17,3,9,1700,'SM-46-00004',NULL,NULL,NULL,NULL,NULL,'BUPIVACAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','BUPIVACAINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,150.00,18.00,1,0,1,'Caja de 10 ampollas de Bupivacaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (545,46,4,8,5,4,3,9,1700,'SM-46-00005',NULL,NULL,NULL,NULL,NULL,'MEPIVACAINA 100 MG INYECTABLE AMPOLLA 1 ML','MEPIVACAINA CLORHIDRATO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,1,0,1,'Anestésico local para odontología. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (546,46,4,8,5,17,3,9,1700,'SM-46-00006',NULL,NULL,NULL,NULL,NULL,'MEPIVACAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','MEPIVACAINA CLORHIDRATO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Caja de 10 ampollas de Mepivacaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (547,46,5,10,5,4,3,9,1700,'SM-46-00007',NULL,NULL,NULL,NULL,NULL,'PROCAINA 100 MG INYECTABLE AMPOLLA 1 ML','PROCAINA CLORHIDRATO',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,1,0,1,'Anestésico local para procedimientos menores. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (548,46,5,10,5,17,3,9,1700,'SM-46-00008',NULL,NULL,NULL,NULL,NULL,'PROCAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','PROCAINA CLORHIDRATO',3.20,1.50,1.19,4.80,3.81,10.00,170.00,22.00,1,0,1,'Caja de 10 ampollas de Procaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (549,46,6,11,5,4,3,9,1700,'SM-46-00009',NULL,NULL,NULL,NULL,NULL,'ROPIVACAINA 100 MG INYECTABLE AMPOLLA 1 ML','ROPIVACAINA CLORHIDRATO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,1,0,1,'Anestésico local para procedimientos quirúrgicos. 100 mg en ampolla.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (550,46,6,11,5,17,3,9,1700,'SM-46-00010',NULL,NULL,NULL,NULL,NULL,'ROPIVACAINA 100 MG INYECTABLE CAJA X 10 AMPOLLAS','ROPIVACAINA CLORHIDRATO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,1,0,1,'Caja de 10 ampollas de Ropivacaína 100 mg para anestesia.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (551,47,2,2,2,10,2,9,1700,'SM-47-00001',NULL,NULL,NULL,NULL,NULL,'MORFINA 500 MG CAJA X 10 TABLETAS','MORFINA SULFATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (552,47,2,2,2,11,2,9,1700,'SM-47-00002',NULL,NULL,NULL,NULL,NULL,'MORFINA 500 MG CAJA X 20 TABLETAS','MORFINA SULFATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Morfina 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (553,47,2,2,2,12,2,9,1700,'SM-47-00003',NULL,NULL,NULL,NULL,NULL,'MORFINA 500 MG CAJA X 30 TABLETAS','MORFINA SULFATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Morfina 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (554,47,3,9,2,10,2,9,1700,'SM-47-00004',NULL,NULL,NULL,NULL,NULL,'CODEINA 500 MG CAJA X 10 TABLETAS','CODEINA FOSFATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,1,1,'Analgésico opioide para dolor moderado. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (555,47,3,9,2,11,2,9,1700,'SM-47-00005',NULL,NULL,NULL,NULL,NULL,'CODEINA 500 MG CAJA X 20 TABLETAS','CODEINA FOSFATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,1,1,'Caja de 20 tabletas de Codeína 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (556,47,3,9,2,12,2,9,1700,'SM-47-00006',NULL,NULL,NULL,NULL,NULL,'CODEINA 500 MG CAJA X 30 TABLETAS','CODEINA FOSFATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,1,1,'30 tabletas de Codeína 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (557,47,4,8,2,10,2,9,1700,'SM-47-00007',NULL,NULL,NULL,NULL,NULL,'OXICODONA 500 MG CAJA X 10 TABLETAS','OXICODONA CLORHIDRATO',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (558,47,4,8,2,11,2,9,1700,'SM-47-00008',NULL,NULL,NULL,NULL,NULL,'OXICODONA 500 MG CAJA X 20 TABLETAS','OXICODONA CLORHIDRATO',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de OxiCápsula 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (559,47,4,8,2,12,2,9,1700,'SM-47-00009',NULL,NULL,NULL,NULL,NULL,'OXICODONA 500 MG CAJA X 30 TABLETAS','OXICODONA CLORHIDRATO',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,1,1,'30 tabletas de OxiCápsula 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (560,47,5,10,2,10,2,9,1700,'SM-47-00010',NULL,NULL,NULL,NULL,NULL,'FENTANILO 500 MG CAJA X 10 TABLETAS','FENTANILO CITRATO',12.00,1.50,1.19,18.00,14.28,10.00,110.00,12.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (561,47,5,10,2,11,2,9,1700,'SM-47-00011',NULL,NULL,NULL,NULL,NULL,'FENTANILO 500 MG CAJA X 20 TABLETAS','FENTANILO CITRATO',21.60,1.50,1.19,32.40,25.70,10.00,100.00,10.00,1,1,1,'Caja de 20 tabletas de Fentanilo 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (562,47,5,10,2,12,2,9,1700,'SM-47-00012',NULL,NULL,NULL,NULL,NULL,'FENTANILO 500 MG CAJA X 30 TABLETAS','FENTANILO CITRATO',30.00,1.50,1.19,45.00,35.70,10.00,90.00,9.00,1,1,1,'30 tabletas de Fentanilo 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (563,47,6,11,2,10,2,9,1700,'SM-47-00013',NULL,NULL,NULL,NULL,NULL,'HIDROMORFONA 500 MG CAJA X 10 TABLETAS','HIDROMORFONA CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,1,1,'Analgésico opioide para dolor severo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (564,47,6,11,2,11,2,9,1700,'SM-47-00014',NULL,NULL,NULL,NULL,NULL,'HIDROMORFONA 500 MG CAJA X 20 TABLETAS','HIDROMORFONA CLORHIDRATO',16.20,1.50,1.19,24.30,19.28,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Hidromorfona 500 mg para dolor.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (565,47,6,11,2,12,2,9,1700,'SM-47-00015',NULL,NULL,NULL,NULL,NULL,'HIDROMORFONA 500 MG CAJA X 30 TABLETAS','HIDROMORFONA CLORHIDRATO',22.50,1.50,1.19,33.75,26.78,10.00,100.00,10.00,1,1,1,'30 tabletas de Hidromorfona 500 mg para dolor crónico.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (566,48,2,2,2,10,2,9,1700,'SM-48-00001',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 10 TABLETAS','IBUPROFENO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Analgésico no opioide para dolor leve a moderado. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (567,48,2,2,2,11,2,9,1700,'SM-48-00002',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 20 TABLETAS','IBUPROFENO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Ibuprofeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (568,48,2,2,2,12,2,9,1700,'SM-48-00003',NULL,NULL,NULL,NULL,NULL,'IBUPROFENO 500 MG CAJA X 30 TABLETAS','IBUPROFENO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Ibuprofeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (569,48,3,9,2,10,2,9,1700,'SM-48-00004',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 10 TABLETAS','PARACETAMOL',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Analgésico no opioide para fiebre y dolor. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (570,48,3,9,2,11,2,9,1700,'SM-48-00005',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 20 TABLETAS','PARACETAMOL',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Paracetamol 500 mg para fiebre.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (571,48,3,9,2,12,2,9,1700,'SM-48-00006',NULL,NULL,NULL,NULL,NULL,'PARACETAMOL 500 MG CAJA X 30 TABLETAS','PARACETAMOL',4.50,1.50,1.19,6.75,5.36,10.00,140.00,18.00,0,0,1,'30 tabletas de Paracetamol 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (572,48,4,8,2,10,2,9,1700,'SM-48-00007',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 10 TABLETAS','ACIDO ACETILSALICILICO',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Analgésico no opioide para dolor y fiebre. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (573,48,4,8,2,11,2,9,1700,'SM-48-00008',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 20 TABLETAS','ACIDO ACETILSALICILICO',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Aspirina 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (574,48,4,8,2,12,2,9,1700,'SM-48-00009',NULL,NULL,NULL,NULL,NULL,'ASPIRINA 500 MG CAJA X 30 TABLETAS','ACIDO ACETILSALICILICO',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Aspirina 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (575,48,5,10,2,10,2,9,1700,'SM-48-00010',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 10 TABLETAS','NAPROXENO SODICO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Analgésico no opioide para dolor. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (576,48,5,10,2,11,2,9,1700,'SM-48-00011',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 20 TABLETAS','NAPROXENO SODICO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Naproxeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (577,48,5,10,2,12,2,9,1700,'SM-48-00012',NULL,NULL,NULL,NULL,NULL,'NAPROXENO 500 MG CAJA X 30 TABLETAS','NAPROXENO SODICO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Naproxeno 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (578,48,6,11,2,10,2,9,1700,'SM-48-00013',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 10 TABLETAS','METAMIZOL SODICO',2.00,1.50,1.19,3.00,2.38,10.00,190.00,25.00,0,0,1,'Analgésico no opioide para dolor y fiebre. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (579,48,6,11,2,11,2,9,1700,'SM-48-00014',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 20 TABLETAS','METAMIZOL SODICO',3.60,1.50,1.19,5.40,4.28,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Metamizol 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (580,48,6,11,2,12,2,9,1700,'SM-48-00015',NULL,NULL,NULL,NULL,NULL,'METAMIZOL 500 MG CAJA X 30 TABLETAS','METAMIZOL SODICO',5.00,1.50,1.19,7.50,5.95,10.00,140.00,18.00,0,0,1,'30 tabletas de Metamizol 500 mg para dolor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (581,49,2,2,2,10,2,9,1700,'SM-49-00001',NULL,NULL,NULL,NULL,NULL,'SUMATRIPTAN 500 MG CAJA X 10 TABLETAS','SUMATRIPTAN SUCCINATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Antimigrañoso para el alivio de la migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (582,49,2,2,2,11,2,9,1700,'SM-49-00002',NULL,NULL,NULL,NULL,NULL,'SUMATRIPTAN 500 MG CAJA X 20 TABLETAS','SUMATRIPTAN SUCCINATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,0,1,'Caja de 20 tabletas de Sumatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (583,49,2,2,2,12,2,9,1700,'SM-49-00003',NULL,NULL,NULL,NULL,NULL,'SUMATRIPTAN 500 MG CAJA X 30 TABLETAS','SUMATRIPTAN SUCCINATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,0,1,'30 tabletas de Sumatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (584,49,3,9,2,10,2,9,1700,'SM-49-00004',NULL,NULL,NULL,NULL,NULL,'ZOLMITRIPTAN 500 MG CAJA X 10 TABLETAS','ZOLMITRIPTAN',9.00,1.50,1.19,13.50,10.71,10.00,120.00,14.00,1,0,1,'Antimigrañoso para migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (585,49,3,9,2,11,2,9,1700,'SM-49-00005',NULL,NULL,NULL,NULL,NULL,'ZOLMITRIPTAN 500 MG CAJA X 20 TABLETAS','ZOLMITRIPTAN',16.20,1.50,1.19,24.30,19.28,10.00,100.00,10.00,1,0,1,'Caja de 20 tabletas de Zolmitriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (586,49,3,9,2,12,2,9,1700,'SM-49-00006',NULL,NULL,NULL,NULL,NULL,'ZOLMITRIPTAN 500 MG CAJA X 30 TABLETAS','ZOLMITRIPTAN',22.50,1.50,1.19,33.75,26.78,10.00,90.00,9.00,1,0,1,'30 tabletas de Zolmitriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (587,49,4,8,2,10,2,9,1700,'SM-49-00007',NULL,NULL,NULL,NULL,NULL,'RIZATRIPTAN 500 MG CAJA X 10 TABLETAS','RIZATRIPTAN BENZOATO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,16.00,1,0,1,'Antimigrañoso para migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (588,49,4,8,2,11,2,9,1700,'SM-49-00008',NULL,NULL,NULL,NULL,NULL,'RIZATRIPTAN 500 MG CAJA X 20 TABLETAS','RIZATRIPTAN BENZOATO',13.50,1.50,1.19,20.25,16.07,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Rizatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (589,49,4,8,2,12,2,9,1700,'SM-49-00009',NULL,NULL,NULL,NULL,NULL,'RIZATRIPTAN 500 MG CAJA X 30 TABLETAS','RIZATRIPTAN BENZOATO',19.00,1.50,1.19,28.50,22.61,10.00,100.00,10.00,1,0,1,'30 tabletas de Rizatriptan 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (590,49,5,10,2,10,2,9,1700,'SM-49-00010',NULL,NULL,NULL,NULL,NULL,'ERGOTAMINA 500 MG CAJA X 10 TABLETAS','ERGOTAMINA TARTRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antimigrañoso para la migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (591,49,5,10,2,11,2,9,1700,'SM-49-00011',NULL,NULL,NULL,NULL,NULL,'ERGOTAMINA 500 MG CAJA X 20 TABLETAS','ERGOTAMINA TARTRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Ergotamina 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (592,49,5,10,2,12,2,9,1700,'SM-49-00012',NULL,NULL,NULL,NULL,NULL,'ERGOTAMINA 500 MG CAJA X 30 TABLETAS','ERGOTAMINA TARTRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Ergotamina 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (593,49,6,11,2,10,2,9,1700,'SM-49-00013',NULL,NULL,NULL,NULL,NULL,'ISOMETEPTENO 500 MG CAJA X 10 TABLETAS','ISOMETEPTENO CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antimigrañoso para migraña. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (594,49,6,11,2,11,2,9,1700,'SM-49-00014',NULL,NULL,NULL,NULL,NULL,'ISOMETEPTENO 500 MG CAJA X 20 TABLETAS','ISOMETEPTENO CLORHIDRATO',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Isometepteno 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (595,49,6,11,2,12,2,9,1700,'SM-49-00015',NULL,NULL,NULL,NULL,NULL,'ISOMETEPTENO 500 MG CAJA X 30 TABLETAS','ISOMETEPTENO CLORHIDRATO',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Isometepteno 500 mg para migraña.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (596,50,2,2,2,10,2,9,1700,'SM-50-00001',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 10 TABLETAS','NITROGLICERINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,1,0,1,'Antianginoso para la angina de pecho. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (597,50,2,2,2,11,2,9,1700,'SM-50-00002',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 20 TABLETAS','NITROGLICERINA',7.20,1.50,1.19,10.80,8.57,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Nitroglicerina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (598,50,2,2,2,12,2,9,1700,'SM-50-00003',NULL,NULL,NULL,NULL,NULL,'NITROGLICERINA 500 MG CAJA X 30 TABLETAS','NITROGLICERINA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,15.00,1,0,1,'30 tabletas de Nitroglicerina 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (599,50,3,9,2,10,2,9,1700,'SM-50-00004',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 10 TABLETAS','DINITRATO DE ISOSORBIDE',3.50,1.50,1.19,5.25,4.17,10.00,170.00,22.00,1,0,1,'Antianginoso para angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (600,50,3,9,2,11,2,9,1700,'SM-50-00005',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 20 TABLETAS','DINITRATO DE ISOSORBIDE',6.30,1.50,1.19,9.45,7.50,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Isosorbide 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (601,50,3,9,2,12,2,9,1700,'SM-50-00006',NULL,NULL,NULL,NULL,NULL,'ISOSORBIDE 500 MG CAJA X 30 TABLETAS','DINITRATO DE ISOSORBIDE',8.80,1.50,1.19,13.20,10.47,10.00,130.00,16.00,1,0,1,'30 tabletas de Isosorbide 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (602,50,4,8,2,10,2,9,1700,'SM-50-00007',NULL,NULL,NULL,NULL,NULL,'DILTIAZEM 500 MG CAJA X 10 TABLETAS','DILTIAZEM CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,150.00,18.00,1,0,1,'Antianginoso para la angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (603,50,4,8,2,11,2,9,1700,'SM-50-00008',NULL,NULL,NULL,NULL,NULL,'DILTIAZEM 500 MG CAJA X 20 TABLETAS','DILTIAZEM CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Diltiazem 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (604,50,4,8,2,12,2,9,1700,'SM-50-00009',NULL,NULL,NULL,NULL,NULL,'DILTIAZEM 500 MG CAJA X 30 TABLETAS','DILTIAZEM CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,110.00,12.00,1,0,1,'30 tabletas de Diltiazem 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (605,50,5,10,2,10,2,9,1700,'SM-50-00010',NULL,NULL,NULL,NULL,NULL,'ATENOLOL 500 MG CAJA X 10 TABLETAS','ATENOLOL',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,1,0,1,'Antianginoso para la angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (606,50,5,10,2,11,2,9,1700,'SM-50-00011',NULL,NULL,NULL,NULL,NULL,'ATENOLOL 500 MG CAJA X 20 TABLETAS','ATENOLOL',8.10,1.50,1.19,12.15,9.64,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Atenolol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (607,50,5,10,2,12,2,9,1700,'SM-50-00012',NULL,NULL,NULL,NULL,NULL,'ATENOLOL 500 MG CAJA X 30 TABLETAS','ATENOLOL',11.20,1.50,1.19,16.80,13.33,10.00,120.00,15.00,1,0,1,'30 tabletas de Atenolol 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (608,50,6,11,2,10,2,9,1700,'SM-50-00013',NULL,NULL,NULL,NULL,NULL,'VERAPAMILO 500 MG CAJA X 10 TABLETAS','VERAPAMILO CLORHIDRATO',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Antianginoso para la angina. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (609,50,6,11,2,11,2,9,1700,'SM-50-00014',NULL,NULL,NULL,NULL,NULL,'VERAPAMILO 500 MG CAJA X 20 TABLETAS','VERAPAMILO CLORHIDRATO',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Verapamilo 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (610,50,6,11,2,12,2,9,1700,'SM-50-00015',NULL,NULL,NULL,NULL,NULL,'VERAPAMILO 500 MG CAJA X 30 TABLETAS','VERAPAMILO CLORHIDRATO',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Verapamilo 500 mg para angina.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (611,51,2,2,2,10,2,9,1700,'SM-51-00001',NULL,NULL,NULL,NULL,NULL,'AMIODARONA 500 MG CAJA X 10 TABLETAS','AMIODARONA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Antiarrítmico para arritmias ventriculares. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (612,51,2,2,2,11,2,9,1700,'SM-51-00002',NULL,NULL,NULL,NULL,NULL,'AMIODARONA 500 MG CAJA X 20 TABLETAS','AMIODARONA CLORHIDRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Amiodarona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (613,51,2,2,2,12,2,9,1700,'SM-51-00003',NULL,NULL,NULL,NULL,NULL,'AMIODARONA 500 MG CAJA X 30 TABLETAS','AMIODARONA CLORHIDRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Amiodarona 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (614,51,3,9,2,10,2,9,1700,'SM-51-00004',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 500 MG CAJA X 10 TABLETAS','LIDOCAINA CLORHIDRATO',3.00,1.50,1.19,4.50,3.57,10.00,180.00,22.00,1,0,1,'Antiarrítmico para arritmias ventriculares. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (615,51,3,9,2,11,2,9,1700,'SM-51-00005',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 500 MG CAJA X 20 TABLETAS','LIDOCAINA CLORHIDRATO',5.40,1.50,1.19,8.10,6.43,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Lidocaína 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (616,51,3,9,2,12,2,9,1700,'SM-51-00006',NULL,NULL,NULL,NULL,NULL,'LIDOCAINA 500 MG CAJA X 30 TABLETAS','LIDOCAINA CLORHIDRATO',7.50,1.50,1.19,11.25,8.93,10.00,140.00,18.00,1,0,1,'30 tabletas de Lidocaína 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (617,51,4,8,2,10,2,9,1700,'SM-51-00007',NULL,NULL,NULL,NULL,NULL,'PROCAINAMIDA 500 MG CAJA X 10 TABLETAS','PROCAINAMIDA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Antiarrítmico para arritmias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (618,51,4,8,2,11,2,9,1700,'SM-51-00008',NULL,NULL,NULL,NULL,NULL,'PROCAINAMIDA 500 MG CAJA X 20 TABLETAS','PROCAINAMIDA CLORHIDRATO',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Procainamida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (619,51,4,8,2,12,2,9,1700,'SM-51-00009',NULL,NULL,NULL,NULL,NULL,'PROCAINAMIDA 500 MG CAJA X 30 TABLETAS','PROCAINAMIDA CLORHIDRATO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Procainamida 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (620,51,5,10,2,10,2,9,1700,'SM-51-00010',NULL,NULL,NULL,NULL,NULL,'DISOPIRAMIDA 500 MG CAJA X 10 TABLETAS','DISOPIRAMIDA FOSFATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Antiarrítmico para arritmias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (621,51,5,10,2,11,2,9,1700,'SM-51-00011',NULL,NULL,NULL,NULL,NULL,'DISOPIRAMIDA 500 MG CAJA X 20 TABLETAS','DISOPIRAMIDA FOSFATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Disopiramida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (622,51,5,10,2,12,2,9,1700,'SM-51-00012',NULL,NULL,NULL,NULL,NULL,'DISOPIRAMIDA 500 MG CAJA X 30 TABLETAS','DISOPIRAMIDA FOSFATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Disopiramida 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (623,51,6,11,2,10,2,9,1700,'SM-51-00013',NULL,NULL,NULL,NULL,NULL,'FLECAINIDA 500 MG CAJA X 10 TABLETAS','FLECAINIDA ACETATO',6.50,1.50,1.19,9.75,7.74,10.00,150.00,18.00,1,0,1,'Antiarrítmico para arritmias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (624,51,6,11,2,11,2,9,1700,'SM-51-00014',NULL,NULL,NULL,NULL,NULL,'FLECAINIDA 500 MG CAJA X 20 TABLETAS','FLECAINIDA ACETATO',11.70,1.50,1.19,17.55,13.92,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Flecainida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (625,51,6,11,2,12,2,9,1700,'SM-51-00015',NULL,NULL,NULL,NULL,NULL,'FLECAINIDA 500 MG CAJA X 30 TABLETAS','FLECAINIDA ACETATO',16.20,1.50,1.19,24.30,19.28,10.00,110.00,12.00,1,0,1,'30 tabletas de Flecainida 500 mg para arritmias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (626,52,2,2,2,10,2,9,1700,'SM-52-00001',NULL,NULL,NULL,NULL,NULL,'DIGOXINA 500 MG CAJA X 10 TABLETAS','DIGOXINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Cardiotónico para la insuficiencia cardíaca. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (627,52,2,2,2,11,2,9,1700,'SM-52-00002',NULL,NULL,NULL,NULL,NULL,'DIGOXINA 500 MG CAJA X 20 TABLETAS','DIGOXINA',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Digoxina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (628,52,2,2,2,12,2,9,1700,'SM-52-00003',NULL,NULL,NULL,NULL,NULL,'DIGOXINA 500 MG CAJA X 30 TABLETAS','DIGOXINA',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Digoxina 500 mg para insuficiencia cardíaca.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (629,52,3,9,2,10,2,9,1700,'SM-52-00004',NULL,NULL,NULL,NULL,NULL,'DOBUTAMINA 500 MG CAJA X 10 TABLETAS','DOBUTAMINA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Cardiotónico para insuficiencia cardíaca. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (630,52,3,9,2,11,2,9,1700,'SM-52-00005',NULL,NULL,NULL,NULL,NULL,'DOBUTAMINA 500 MG CAJA X 20 TABLETAS','DOBUTAMINA CLORHIDRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Dobutamina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (631,52,3,9,2,12,2,9,1700,'SM-52-00006',NULL,NULL,NULL,NULL,NULL,'DOBUTAMINA 500 MG CAJA X 30 TABLETAS','DOBUTAMINA CLORHIDRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Dobutamina 500 mg para insuficiencia cardíaca.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (632,52,4,8,2,10,2,9,1700,'SM-52-00007',NULL,NULL,NULL,NULL,NULL,'DOPAMINA 500 MG CAJA X 10 TABLETAS','DOPAMINA CLORHIDRATO',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Cardiotónico para shock. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (633,52,4,8,2,11,2,9,1700,'SM-52-00008',NULL,NULL,NULL,NULL,NULL,'DOPAMINA 500 MG CAJA X 20 TABLETAS','DOPAMINA CLORHIDRATO',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Dopamina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (634,52,4,8,2,12,2,9,1700,'SM-52-00009',NULL,NULL,NULL,NULL,NULL,'DOPAMINA 500 MG CAJA X 30 TABLETAS','DOPAMINA CLORHIDRATO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Dopamina 500 mg para shock.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (635,52,5,10,2,10,2,9,1700,'SM-52-00010',NULL,NULL,NULL,NULL,NULL,'NOREPINEFRINA 500 MG CAJA X 10 TABLETAS','NOREPINEFRINA BITARTRATO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Cardiotónico para shock. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (636,52,5,10,2,11,2,9,1700,'SM-52-00011',NULL,NULL,NULL,NULL,NULL,'NOREPINEFRINA 500 MG CAJA X 20 TABLETAS','NOREPINEFRINA BITARTRATO',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Norepinefrina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (637,52,5,10,2,12,2,9,1700,'SM-52-00012',NULL,NULL,NULL,NULL,NULL,'NOREPINEFRINA 500 MG CAJA X 30 TABLETAS','NOREPINEFRINA BITARTRATO',17.50,1.50,1.19,26.25,20.83,10.00,100.00,10.00,1,0,1,'30 tabletas de Norepinefrina 500 mg para shock.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (638,52,6,11,2,10,2,9,1700,'SM-52-00013',NULL,NULL,NULL,NULL,NULL,'EPINEFRINA 500 MG CAJA X 10 TABLETAS','EPINEFRINA',5.50,1.50,1.19,8.25,6.55,10.00,160.00,20.00,1,0,1,'Cardiotónico para paro cardíaco. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (639,52,6,11,2,11,2,9,1700,'SM-52-00014',NULL,NULL,NULL,NULL,NULL,'EPINEFRINA 500 MG CAJA X 20 TABLETAS','EPINEFRINA',9.90,1.50,1.19,14.85,11.78,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Epinefrina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (640,52,6,11,2,12,2,9,1700,'SM-52-00015',NULL,NULL,NULL,NULL,NULL,'EPINEFRINA 500 MG CAJA X 30 TABLETAS','EPINEFRINA',13.80,1.50,1.19,20.70,16.42,10.00,120.00,15.00,1,0,1,'30 tabletas de Epinefrina 500 mg para paro cardíaco.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (641,53,2,2,2,10,2,9,1700,'SM-53-00001',NULL,NULL,NULL,NULL,NULL,'ATORVASTATINA 500 MG CAJA X 10 TABLETAS','ATORVASTATINA CALCICA',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,0,1,'Hipolipemiante para el colesterol. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (642,53,2,2,2,11,2,9,1700,'SM-53-00002',NULL,NULL,NULL,NULL,NULL,'ATORVASTATINA 500 MG CAJA X 20 TABLETAS','ATORVASTATINA CALCICA',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,0,1,'Caja de 20 tabletas de Atorvastatina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (643,53,2,2,2,12,2,9,1700,'SM-53-00003',NULL,NULL,NULL,NULL,NULL,'ATORVASTATINA 500 MG CAJA X 30 TABLETAS','ATORVASTATINA CALCICA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'30 tabletas de Atorvastatina 500 mg para colesterol.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (644,53,3,9,2,10,2,9,1700,'SM-53-00004',NULL,NULL,NULL,NULL,NULL,'SIMVASTATINA 500 MG CAJA X 10 TABLETAS','SIMVASTATINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Hipolipemiante para colesterol. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (645,53,3,9,2,11,2,9,1700,'SM-53-00005',NULL,NULL,NULL,NULL,NULL,'SIMVASTATINA 500 MG CAJA X 20 TABLETAS','SIMVASTATINA',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Simvastatina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (646,53,3,9,2,12,2,9,1700,'SM-53-00006',NULL,NULL,NULL,NULL,NULL,'SIMVASTATINA 500 MG CAJA X 30 TABLETAS','SIMVASTATINA',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Simvastatina 500 mg para colesterol.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (647,53,4,8,2,10,2,9,1700,'SM-53-00007',NULL,NULL,NULL,NULL,NULL,'ROSUVASTATINA 500 MG CAJA X 10 TABLETAS','ROSUVASTATINA CALCICA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,1,0,1,'Hipolipemiante para colesterol. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (648,53,4,8,2,11,2,9,1700,'SM-53-00008',NULL,NULL,NULL,NULL,NULL,'ROSUVASTATINA 500 MG CAJA X 20 TABLETAS','ROSUVASTATINA CALCICA',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,1,0,1,'Caja de 20 tabletas de Rosuvastatina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (649,53,4,8,2,12,2,9,1700,'SM-53-00009',NULL,NULL,NULL,NULL,NULL,'ROSUVASTATINA 500 MG CAJA X 30 TABLETAS','ROSUVASTATINA CALCICA',17.50,1.50,1.19,26.25,20.83,10.00,100.00,10.00,1,0,1,'30 tabletas de Rosuvastatina 500 mg para colesterol.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (650,53,5,10,2,10,2,9,1700,'SM-53-00010',NULL,NULL,NULL,NULL,NULL,'FENOFIBRATO 500 MG CAJA X 10 TABLETAS','FENOFIBRATO',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Hipolipemiante para triglicéridos. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (651,53,5,10,2,11,2,9,1700,'SM-53-00011',NULL,NULL,NULL,NULL,NULL,'FENOFIBRATO 500 MG CAJA X 20 TABLETAS','FENOFIBRATO',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Fenofibrato 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (652,53,5,10,2,12,2,9,1700,'SM-53-00012',NULL,NULL,NULL,NULL,NULL,'FENOFIBRATO 500 MG CAJA X 30 TABLETAS','FENOFIBRATO',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Fenofibrato 500 mg para triglicéridos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (653,53,6,11,2,10,2,9,1700,'SM-53-00013',NULL,NULL,NULL,NULL,NULL,'GEMFIBROZIL 500 MG CAJA X 10 TABLETAS','GEMFIBROZIL',4.00,1.50,1.19,6.00,4.76,10.00,180.00,22.00,1,0,1,'Hipolipemiante para triglicéridos. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (654,53,6,11,2,11,2,9,1700,'SM-53-00014',NULL,NULL,NULL,NULL,NULL,'GEMFIBROZIL 500 MG CAJA X 20 TABLETAS','GEMFIBROZIL',7.20,1.50,1.19,10.80,8.57,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Gemfibrozil 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (655,53,6,11,2,12,2,9,1700,'SM-53-00015',NULL,NULL,NULL,NULL,NULL,'GEMFIBROZIL 500 MG CAJA X 30 TABLETAS','GEMFIBROZIL',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,0,1,'30 tabletas de Gemfibrozil 500 mg para triglicéridos.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (656,54,2,2,2,10,2,9,1700,'SM-54-00001',NULL,NULL,NULL,NULL,NULL,'ORLISTAT 500 MG CAJA X 10 TABLETAS','ORLISTAT',7.00,1.50,1.19,10.50,8.33,10.00,140.00,16.00,0,0,1,'Antiobesidad para la pérdida de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (657,54,2,2,2,11,2,9,1700,'SM-54-00002',NULL,NULL,NULL,NULL,NULL,'ORLISTAT 500 MG CAJA X 20 TABLETAS','ORLISTAT',12.60,1.50,1.19,18.90,14.99,10.00,120.00,14.00,0,0,1,'Caja de 20 tabletas de Orlistat 500 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (658,54,2,2,2,12,2,9,1700,'SM-54-00003',NULL,NULL,NULL,NULL,NULL,'ORLISTAT 500 MG CAJA X 30 TABLETAS','ORLISTAT',17.50,1.50,1.19,26.25,20.83,10.00,100.00,10.00,0,0,1,'30 tabletas de Orlistat 500 mg para obesidad.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (659,54,3,9,2,10,2,9,1700,'SM-54-00004',NULL,NULL,NULL,NULL,NULL,'SIBUTRAMINA 500 MG CAJA X 10 TABLETAS','SIBUTRAMINA CLORHIDRATO',6.00,1.50,1.19,9.00,7.14,10.00,150.00,18.00,1,1,1,'Antiobesidad para control de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (660,54,3,9,2,11,2,9,1700,'SM-54-00005',NULL,NULL,NULL,NULL,NULL,'SIBUTRAMINA 500 MG CAJA X 20 TABLETAS','SIBUTRAMINA CLORHIDRATO',10.80,1.50,1.19,16.20,12.85,10.00,130.00,16.00,1,1,1,'Caja de 20 tabletas de Sibutramina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (661,54,3,9,2,12,2,9,1700,'SM-54-00006',NULL,NULL,NULL,NULL,NULL,'SIBUTRAMINA 500 MG CAJA X 30 TABLETAS','SIBUTRAMINA CLORHIDRATO',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,1,1,'30 tabletas de Sibutramina 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (662,54,4,8,2,10,2,9,1700,'SM-54-00007',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 10 TABLETAS','METFORMINA CLORHIDRATO',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,1,0,1,'Antiobesidad para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (663,54,4,8,2,11,2,9,1700,'SM-54-00008',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 20 TABLETAS','METFORMINA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Metformina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (664,54,4,8,2,12,2,9,1700,'SM-54-00009',NULL,NULL,NULL,NULL,NULL,'METFORMINA 500 MG CAJA X 30 TABLETAS','METFORMINA CLORHIDRATO',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,1,0,1,'30 tabletas de Metformina 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (665,54,5,10,2,10,2,9,1700,'SM-54-00010',NULL,NULL,NULL,NULL,NULL,'LIRAGLUTIDA 500 MG CAJA X 10 TABLETAS','LIRAGLUTIDA',15.00,1.50,1.19,22.50,17.85,10.00,110.00,12.00,1,0,1,'Antiobesidad para control de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (666,54,5,10,2,11,2,9,1700,'SM-54-00011',NULL,NULL,NULL,NULL,NULL,'LIRAGLUTIDA 500 MG CAJA X 20 TABLETAS','LIRAGLUTIDA',27.00,1.50,1.19,40.50,32.13,10.00,90.00,9.00,1,0,1,'Caja de 20 tabletas de Liraglutida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (667,54,5,10,2,12,2,9,1700,'SM-54-00012',NULL,NULL,NULL,NULL,NULL,'LIRAGLUTIDA 500 MG CAJA X 30 TABLETAS','LIRAGLUTIDA',37.50,1.50,1.19,56.25,44.63,10.00,80.00,8.00,1,0,1,'30 tabletas de Liraglutida 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (668,54,6,11,2,10,2,9,1700,'SM-54-00013',NULL,NULL,NULL,NULL,NULL,'NALTREXONA 500 MG CAJA X 10 TABLETAS','NALTREXONA CLORHIDRATO',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,1,1,'Antiobesidad para control de peso. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (669,54,6,11,2,11,2,9,1700,'SM-54-00014',NULL,NULL,NULL,NULL,NULL,'NALTREXONA 500 MG CAJA X 20 TABLETAS','NALTREXONA CLORHIDRATO',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,1,1,'Caja de 20 tabletas de Naltrexona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (670,54,6,11,2,12,2,9,1700,'SM-54-00015',NULL,NULL,NULL,NULL,NULL,'NALTREXONA 500 MG CAJA X 30 TABLETAS','NALTREXONA CLORHIDRATO',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,1,1,'30 tabletas de Naltrexona 500 mg para obesidad.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (671,55,2,2,2,10,2,9,1700,'SM-55-00001',NULL,NULL,NULL,NULL,NULL,'INSULINA 500 MG CAJA X 10 TABLETAS','INSULINA HUMANA',10.00,1.50,1.19,15.00,11.90,10.00,120.00,14.00,1,0,1,'Antidiabético para diabetes tipo 1. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (672,55,2,2,2,11,2,9,1700,'SM-55-00002',NULL,NULL,NULL,NULL,NULL,'INSULINA 500 MG CAJA X 20 TABLETAS','INSULINA HUMANA',18.00,1.50,1.19,27.00,21.42,10.00,100.00,10.00,1,0,1,'Caja de 20 tabletas de Insulina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (673,55,2,2,2,12,2,9,1700,'SM-55-00003',NULL,NULL,NULL,NULL,NULL,'INSULINA 500 MG CAJA X 30 TABLETAS','INSULINA HUMANA',25.00,1.50,1.19,37.50,29.75,10.00,90.00,9.00,1,0,1,'30 tabletas de Insulina 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (674,55,3,9,2,10,2,9,1700,'SM-55-00004',NULL,NULL,NULL,NULL,NULL,'GLIMEPIRIDA 500 MG CAJA X 10 TABLETAS','GLIMEPIRIDA',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (675,55,3,9,2,11,2,9,1700,'SM-55-00005',NULL,NULL,NULL,NULL,NULL,'GLIMEPIRIDA 500 MG CAJA X 20 TABLETAS','GLIMEPIRIDA',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Glimepirida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (676,55,3,9,2,12,2,9,1700,'SM-55-00006',NULL,NULL,NULL,NULL,NULL,'GLIMEPIRIDA 500 MG CAJA X 30 TABLETAS','GLIMEPIRIDA',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Glimepirida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (677,55,4,8,2,10,2,9,1700,'SM-55-00007',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 500 MG CAJA X 10 TABLETAS','PIOGLITAZONA CLORHIDRATO',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (678,55,4,8,2,11,2,9,1700,'SM-55-00008',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 500 MG CAJA X 20 TABLETAS','PIOGLITAZONA CLORHIDRATO',9.00,1.50,1.19,13.50,10.71,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Pioglitazona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (679,55,4,8,2,12,2,9,1700,'SM-55-00009',NULL,NULL,NULL,NULL,NULL,'PIOGLITAZONA 500 MG CAJA X 30 TABLETAS','PIOGLITAZONA CLORHIDRATO',12.50,1.50,1.19,18.75,14.88,10.00,120.00,15.00,1,0,1,'30 tabletas de Pioglitazona 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (680,55,5,10,2,10,2,9,1700,'SM-55-00010',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 500 MG CAJA X 10 TABLETAS','REPAGLINIDA',4.00,1.50,1.19,6.00,4.76,10.00,180.00,22.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (681,55,5,10,2,11,2,9,1700,'SM-55-00011',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 500 MG CAJA X 20 TABLETAS','REPAGLINIDA',7.20,1.50,1.19,10.80,8.57,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Repaglinida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (682,55,5,10,2,12,2,9,1700,'SM-55-00012',NULL,NULL,NULL,NULL,NULL,'REPAGLINIDA 500 MG CAJA X 30 TABLETAS','REPAGLINIDA',10.00,1.50,1.19,15.00,11.90,10.00,140.00,18.00,1,0,1,'30 tabletas de Repaglinida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (683,55,6,11,2,10,2,9,1700,'SM-55-00013',NULL,NULL,NULL,NULL,NULL,'EXENATIDA 500 MG CAJA X 10 TABLETAS','EXENATIDA',8.00,1.50,1.19,12.00,9.52,10.00,130.00,15.00,1,0,1,'Antidiabético para diabetes tipo 2. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (684,55,6,11,2,11,2,9,1700,'SM-55-00014',NULL,NULL,NULL,NULL,NULL,'EXENATIDA 500 MG CAJA X 20 TABLETAS','EXENATIDA',14.40,1.50,1.19,21.60,17.14,10.00,110.00,12.00,1,0,1,'Caja de 20 tabletas de Exenatida 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (685,55,6,11,2,12,2,9,1700,'SM-55-00015',NULL,NULL,NULL,NULL,NULL,'EXENATIDA 500 MG CAJA X 30 TABLETAS','EXENATIDA',20.00,1.50,1.19,30.00,23.80,10.00,100.00,10.00,1,0,1,'30 tabletas de Exenatida 500 mg para diabetes.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (686,56,2,2,2,10,2,9,1700,'SM-56-00001',NULL,NULL,NULL,NULL,NULL,'LEVOTIROXINA 500 MG CAJA X 10 TABLETAS','LEVOTIROXINA SODICA',4.00,1.50,1.19,6.00,4.76,10.00,170.00,22.00,1,0,1,'Hormona para el hipotiroidismo. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (687,56,2,2,2,11,2,9,1700,'SM-56-00002',NULL,NULL,NULL,NULL,NULL,'LEVOTIROXINA 500 MG CAJA X 20 TABLETAS','LEVOTIROXINA SODICA',7.20,1.50,1.19,10.80,8.57,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Levotiroxina 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (688,56,2,2,2,12,2,9,1700,'SM-56-00003',NULL,NULL,NULL,NULL,NULL,'LEVOTIROXINA 500 MG CAJA X 30 TABLETAS','LEVOTIROXINA SODICA',10.00,1.50,1.19,15.00,11.90,10.00,130.00,16.00,1,0,1,'30 tabletas de Levotiroxina 500 mg para hipotiroidismo.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (689,56,3,9,2,10,2,9,1700,'SM-56-00004',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 500 MG CAJA X 10 TABLETAS','PREDNISONA',3.50,1.50,1.19,5.25,4.17,10.00,180.00,22.00,1,0,1,'Hormona para inflamación. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (690,56,3,9,2,11,2,9,1700,'SM-56-00005',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 500 MG CAJA X 20 TABLETAS','PREDNISONA',6.30,1.50,1.19,9.45,7.50,10.00,160.00,20.00,1,0,1,'Caja de 20 tabletas de Prednisona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (691,56,3,9,2,12,2,9,1700,'SM-56-00006',NULL,NULL,NULL,NULL,NULL,'PREDNISONA 500 MG CAJA X 30 TABLETAS','PREDNISONA',8.80,1.50,1.19,13.20,10.47,10.00,140.00,18.00,1,0,1,'30 tabletas de Prednisona 500 mg para inflamación.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (692,56,4,8,2,10,2,9,1700,'SM-56-00007',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 500 MG CAJA X 10 TABLETAS','DEXAMETASONA',4.50,1.50,1.19,6.75,5.36,10.00,170.00,22.00,1,0,1,'Hormona para inflamación y alergias. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (693,56,4,8,2,11,2,9,1700,'SM-56-00008',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 500 MG CAJA X 20 TABLETAS','DEXAMETASONA',8.10,1.50,1.19,12.15,9.64,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Dexametasona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (694,56,4,8,2,12,2,9,1700,'SM-56-00009',NULL,NULL,NULL,NULL,NULL,'DEXAMETASONA 500 MG CAJA X 30 TABLETAS','DEXAMETASONA',11.20,1.50,1.19,16.80,13.33,10.00,130.00,16.00,1,0,1,'30 tabletas de Dexametasona 500 mg para alergias.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (695,56,5,10,2,10,2,9,1700,'SM-56-00010',NULL,NULL,NULL,NULL,NULL,'ESTRADIOL 500 MG CAJA X 10 TABLETAS','ESTRADIOL',6.00,1.50,1.19,9.00,7.14,10.00,160.00,20.00,1,0,1,'Hormona para terapia hormonal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (696,56,5,10,2,11,2,9,1700,'SM-56-00011',NULL,NULL,NULL,NULL,NULL,'ESTRADIOL 500 MG CAJA X 20 TABLETAS','ESTRADIOL',10.80,1.50,1.19,16.20,12.85,10.00,140.00,18.00,1,0,1,'Caja de 20 tabletas de Estradiol 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (697,56,5,10,2,12,2,9,1700,'SM-56-00012',NULL,NULL,NULL,NULL,NULL,'ESTRADIOL 500 MG CAJA X 30 TABLETAS','ESTRADIOL',15.00,1.50,1.19,22.50,17.85,10.00,120.00,15.00,1,0,1,'30 tabletas de Estradiol 500 mg para terapia hormonal.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (698,56,6,11,2,10,2,9,1700,'SM-56-00013',NULL,NULL,NULL,NULL,NULL,'PROGESTERONA 500 MG CAJA X 10 TABLETAS','PROGESTERONA',5.50,1.50,1.19,8.25,6.55,10.00,170.00,22.00,1,0,1,'Hormona para terapia hormonal. 500 mg por tableta.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (699,56,6,11,2,11,2,9,1700,'SM-56-00014',NULL,NULL,NULL,NULL,NULL,'PROGESTERONA 500 MG CAJA X 20 TABLETAS','PROGESTERONA',9.90,1.50,1.19,14.85,11.78,10.00,150.00,18.00,1,0,1,'Caja de 20 tabletas de Progesterona 500 mg.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (700,56,6,11,2,12,2,9,1700,'SM-56-00015',NULL,NULL,NULL,NULL,NULL,'PROGESTERONA 500 MG CAJA X 30 TABLETAS','PROGESTERONA',13.80,1.50,1.19,20.70,16.42,10.00,130.00,16.00,1,0,1,'30 tabletas de Progesterona 500 mg para terapia hormonal.',NULL,NULL,NULL,NULL,4151,1000,1),
	 (701,57,2,2,2,10,7,9,1700,'SM-57-00001',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 10 TABLETAS','LORATADINA',2.20,1.50,1.19,3.30,2.62,10.00,190.00,25.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (702,57,2,2,2,11,7,9,1700,'SM-57-00002',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 20 TABLETAS','LORATADINA',4.00,1.50,1.19,6.00,4.76,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Loratadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (703,57,2,2,2,12,7,9,1700,'SM-57-00003',NULL,NULL,NULL,NULL,NULL,'LORATADINA 5 MG CAJA X 30 TABLETAS','LORATADINA',5.50,1.50,1.19,8.25,6.55,10.00,140.00,18.00,0,0,1,'30 tabletas de Loratadina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (704,57,3,9,2,10,7,9,1700,'SM-57-00004',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 5 MG CAJA X 10 TABLETAS','CETIRIZINA DIHIDROCLORURO',2.50,1.50,1.19,3.75,2.98,10.00,180.00,22.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (705,57,3,9,2,11,7,9,1700,'SM-57-00005',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 5 MG CAJA X 20 TABLETAS','CETIRIZINA DIHIDROCLORURO',4.50,1.50,1.19,6.75,5.36,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Cetirizina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (706,57,3,9,2,12,7,9,1700,'SM-57-00006',NULL,NULL,NULL,NULL,NULL,'CETIRIZINA 5 MG CAJA X 30 TABLETAS','CETIRIZINA DIHIDROCLORURO',6.20,1.50,1.19,9.30,7.38,10.00,140.00,18.00,0,0,1,'30 tabletas de Cetirizina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (707,57,4,8,2,10,7,9,1700,'SM-57-00007',NULL,NULL,NULL,NULL,NULL,'FEXOFENADINA 5 MG CAJA X 10 TABLETAS','FEXOFENADINA CLORHIDRATO',3.00,1.50,1.19,4.50,3.57,10.00,170.00,22.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (708,57,4,8,2,11,7,9,1700,'SM-57-00008',NULL,NULL,NULL,NULL,NULL,'FEXOFENADINA 5 MG CAJA X 20 TABLETAS','FEXOFENADINA CLORHIDRATO',5.40,1.50,1.19,8.10,6.43,10.00,150.00,18.00,0,0,1,'Caja de 20 tabletas de Fexofenadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (709,57,4,8,2,12,7,9,1700,'SM-57-00009',NULL,NULL,NULL,NULL,NULL,'FEXOFENADINA 5 MG CAJA X 30 TABLETAS','FEXOFENADINA CLORHIDRATO',7.50,1.50,1.19,11.25,8.93,10.00,130.00,16.00,0,0,1,'30 tabletas de Fexofenadina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (710,57,5,10,2,10,5,9,1700,'SM-57-00010',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 10 TABLETAS','CLORFENIRAMINA MALEATO',1.80,1.50,1.19,2.70,2.14,10.00,200.00,25.00,0,0,1,'Antialérgico para alergias. 25 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (711,57,5,10,2,11,5,9,1700,'SM-57-00011',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 20 TABLETAS','CLORFENIRAMINA MALEATO',3.20,1.50,1.19,4.80,3.81,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Clorfeniramina 25 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (712,57,5,10,2,12,5,9,1700,'SM-57-00012',NULL,NULL,NULL,NULL,NULL,'CLORFENIRAMINA 25 MG CAJA X 30 TABLETAS','CLORFENIRAMINA MALEATO',4.50,1.50,1.19,6.75,5.36,10.00,140.00,18.00,0,0,1,'30 tabletas de Clorfeniramina 25 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (713,57,6,11,2,10,7,9,1700,'SM-57-00013',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 5 MG CAJA X 10 TABLETAS','DESLORATADINA',2.80,1.50,1.19,4.20,3.33,10.00,180.00,22.00,0,0,1,'Antialérgico para rinitis alérgica. 5 mg por tableta.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (714,57,6,11,2,11,7,9,1700,'SM-57-00014',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 5 MG CAJA X 20 TABLETAS','DESLORATADINA',5.00,1.50,1.19,7.50,5.95,10.00,160.00,20.00,0,0,1,'Caja de 20 tabletas de Desloratadina 5 mg.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (715,57,6,11,2,12,7,9,1700,'SM-57-00015',NULL,NULL,NULL,NULL,NULL,'DESLORATADINA 5 MG CAJA X 30 TABLETAS','DESLORATADINA',7.00,1.50,1.19,10.50,8.33,10.00,140.00,18.00,0,0,1,'30 tabletas de Desloratadina 5 mg para alergias.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (716,65,1,1,1,1,1,9,1700,'SM-65-00001',NULL,'LT-HP-1001','978-0-13-235088-4','SN-HP-2023-001','HP PAVILION 15','LAPTOP HP PAVILION 15.6 PULGADAS INTEL CORE I5',NULL,500.00,1.50,1.19,750.00,595.00,5.00,30.00,8.00,0,0,0,'Laptop HP Pavilion con pantalla de 15.6 pulgadas, procesador Intel Core i5, 8GB RAM y 256GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (717,65,1,1,1,1,1,9,1700,'SM-65-00002',NULL,'LT-HP-1002','978-0-13-235089-1','SN-HP-2023-002','HP ENVY X360','LAPTOP HP ENVY X360 13.3 PULGADAS',NULL,650.00,1.50,1.19,975.00,773.50,5.00,25.00,6.00,0,0,0,'Laptop convertible HP Envy x360 con pantalla táctil de 13.3 pulgadas, Intel Core i7, 16GB RAM y 512GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (718,65,1,1,1,1,1,9,1700,'SM-65-00003',NULL,'LT-DELL-2001','978-0-13-235090-7','SN-DELL-2023-001','DELL XPS 13','LAPTOP DELL XPS 13 9310',NULL,750.00,1.50,1.19,1125.00,892.50,5.00,20.00,5.00,0,0,0,'Laptop Dell XPS 13 con pantalla InfinityEdge de 13.4 pulgadas, Intel Core i7, 16GB RAM y 512GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (719,65,1,1,1,1,1,9,1700,'SM-65-00004',NULL,'LT-LEN-3001','978-0-13-235091-4','SN-LEN-2023-001','LENOVO THINKPAD X1','LAPTOP LENOVO THINKPAD X1 CARBON',NULL,600.00,1.50,1.19,900.00,714.00,5.00,25.00,6.00,0,0,0,'Laptop Lenovo ThinkPad X1 Carbon con pantalla de 14 pulgadas, Intel Core i5, 8GB RAM y 256GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (720,65,1,1,1,1,1,9,1700,'SM-65-00005',NULL,'LT-APP-4001','978-0-13-235092-1','SN-APP-2023-001','MACBOOK AIR 13','LAPTOP MACBOOK AIR 13.6 PULGADAS',NULL,850.00,1.50,1.19,1275.00,1011.50,5.00,20.00,5.00,0,0,0,'Laptop Apple MacBook Air con chip M2, pantalla de 13.6 pulgadas, 8GB RAM y 256GB SSD.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (721,66,1,1,1,1,1,9,1700,'SM-66-00001',NULL,'TB-SAM-1001','978-0-13-235093-8','SN-SAM-2023-001','SAMSUNG GALAXY TAB S8','TABLET SAMSUNG GALAXY TAB S8 11 PULGADAS',NULL,400.00,1.50,1.19,600.00,476.00,5.00,30.00,8.00,0,0,0,'Tablet Samsung Galaxy Tab S8 con pantalla de 11 pulgadas, 8GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (722,66,1,1,1,1,1,9,1700,'SM-66-00002',NULL,'TB-APP-2001','978-0-13-235094-5','SN-APP-2023-002','IPAD PRO 11','TABLET IPAD PRO 11 PULGADAS M2',NULL,550.00,1.50,1.19,825.00,654.50,5.00,25.00,6.00,0,0,0,'Tablet Apple iPad Pro con chip M2, pantalla de 11 pulgadas, 8GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (723,66,1,1,1,1,1,9,1700,'SM-66-00003',NULL,'TB-SAM-1002','978-0-13-235095-2','SN-SAM-2023-002','SAMSUNG GALAXY TAB A8','TABLET SAMSUNG GALAXY TAB A8 10.5 PULGADAS',NULL,250.00,1.50,1.19,375.00,297.50,5.00,35.00,10.00,0,0,0,'Tablet Samsung Galaxy Tab A8 con pantalla de 10.5 pulgadas, 4GB RAM y 64GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (724,66,1,1,1,1,1,9,1700,'SM-66-00004',NULL,'TB-LEN-3001','978-0-13-235096-9','SN-LEN-2023-002','LENOVO TAB P11','TABLET LENOVO TAB P11 11.5 PULGADAS',NULL,300.00,1.50,1.19,450.00,357.00,5.00,30.00,8.00,0,0,0,'Tablet Lenovo Tab P11 con pantalla de 11.5 pulgadas, 6GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (725,66,1,1,1,1,1,9,1700,'SM-66-00005',NULL,'TB-HP-1001','978-0-13-235097-6','SN-HP-2023-003','HP SLATE 10','TABLET HP SLATE 10 PULGADAS',NULL,200.00,1.50,1.19,300.00,238.00,5.00,35.00,10.00,0,0,0,'Tablet HP Slate con pantalla de 10 pulgadas, 4GB RAM y 64GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (726,67,1,1,1,1,1,9,1700,'SM-67-00001',NULL,'SM-SAM-1001','978-0-13-235098-3','SN-SAM-2023-003','SAMSUNG GALAXY S23','SMARTPHONE SAMSUNG GALAXY S23 6.1 PULGADAS',NULL,450.00,1.50,1.19,675.00,535.50,5.00,30.00,8.00,0,0,0,'Smartphone Samsung Galaxy S23 con pantalla de 6.1 pulgadas, 8GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (727,67,1,1,1,1,1,9,1700,'SM-67-00002',NULL,'SM-APP-2001','978-0-13-235099-0','SN-APP-2023-003','IPHONE 15 PRO','SMARTPHONE IPHONE 15 PRO 6.1 PULGADAS',NULL,600.00,1.50,1.19,900.00,714.00,5.00,25.00,6.00,0,0,0,'Smartphone Apple iPhone 15 Pro con pantalla de 6.1 pulgadas, 8GB RAM y 256GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (728,67,1,1,1,1,1,9,1700,'SM-67-00003',NULL,'SM-SAM-1002','978-0-13-235100-3','SN-SAM-2023-004','SAMSUNG GALAXY A54','SMARTPHONE SAMSUNG GALAXY A54 6.5 PULGADAS',NULL,280.00,1.50,1.19,420.00,333.20,5.00,35.00,10.00,0,0,0,'Smartphone Samsung Galaxy A54 con pantalla de 6.5 pulgadas, 6GB RAM y 128GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (729,67,1,1,1,1,1,9,1700,'SM-67-00004',NULL,'SM-LEN-3001','978-0-13-235101-0','SN-LEN-2023-003','LENOVO PHAB 2','SMARTPHONE LENOVO PHAB 2 6.4 PULGADAS',NULL,150.00,1.50,1.19,225.00,178.50,5.00,40.00,12.00,0,0,0,'Smartphone Lenovo Phab 2 con pantalla de 6.4 pulgadas, 3GB RAM y 32GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (730,67,1,1,1,1,1,9,1700,'SM-67-00005',NULL,'SM-HP-1001','978-0-13-235102-7','SN-HP-2023-004','HP ELITE X3','SMARTPHONE HP ELITE X3 5.96 PULGADAS',NULL,180.00,1.50,1.19,270.00,214.20,5.00,35.00,10.00,0,0,0,'Smartphone HP Elite X3 con pantalla de 5.96 pulgadas, 4GB RAM y 64GB de almacenamiento.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (731,68,1,1,1,1,1,9,1700,'SM-68-00001',NULL,'TV-SAM-1001','978-0-13-235103-4','SN-SAM-2023-005','SAMSUNG SMART TV 55','TELEVISOR SAMSUNG SMART TV 55 PULGADAS 4K',NULL,550.00,1.50,1.19,825.00,654.50,5.00,20.00,5.00,0,0,0,'Televisor Samsung Smart TV de 55 pulgadas con resolución 4K y tecnología HDR.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (732,68,1,1,1,1,1,9,1700,'SM-68-00002',NULL,'TV-APP-2001','978-0-13-235104-1','SN-APP-2023-004','APPLE TV 4K','TELEVISOR APPLE TV 4K 64GB',NULL,150.00,1.50,1.19,225.00,178.50,5.00,30.00,8.00,0,0,0,'Dispositivo Apple TV 4K con 64GB de almacenamiento y soporte para contenido en 4K.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (733,68,1,1,1,1,1,9,1700,'SM-68-00003',NULL,'TV-SAM-1002','978-0-13-235105-8','SN-SAM-2023-006','SAMSUNG SMART TV 43','TELEVISOR SAMSUNG SMART TV 43 PULGADAS FULL HD',NULL,350.00,1.50,1.19,525.00,416.50,5.00,25.00,6.00,0,0,0,'Televisor Samsung Smart TV de 43 pulgadas con resolución Full HD y tecnología PurColor.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (734,68,1,1,1,1,1,9,1700,'SM-68-00004',NULL,'TV-LEN-3001','978-0-13-235106-5','SN-LEN-2023-004','LENOVO SMART DISPLAY','TELEVISOR LENOVO SMART DISPLAY 10 PULGADAS',NULL,120.00,1.50,1.19,180.00,142.80,5.00,35.00,10.00,0,0,0,'Dispositivo Lenovo Smart Display con pantalla de 10 pulgadas y asistente de voz integrado.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (735,68,1,1,1,1,1,9,1700,'SM-68-00005',NULL,'TV-HP-1001','978-0-13-235107-2','SN-HP-2023-005','HP MEDIA SHOW','TELEVISOR HP MEDIA SHOW 15.6 PULGADAS',NULL,130.00,1.50,1.19,195.00,154.70,5.00,30.00,8.00,0,0,0,'Monitor HP Media Show de 15.6 pulgadas para presentaciones y contenido multimedia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (736,69,1,1,1,1,1,9,1700,'SM-69-00001',NULL,'KB-SAM-1001','978-0-13-235108-9','SN-SAM-2023-007','SAMSUNG SMART KEYBOARD','TECLADO SAMSUNG SMART KEYBOARD INALÁMBRICO',NULL,45.00,1.50,1.19,67.50,53.55,10.00,50.00,15.00,0,0,0,'Teclado Samsung Smart Keyboard inalámbrico con conectividad Bluetooth y batería recargable.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (737,69,1,1,1,1,1,9,1700,'SM-69-00002',NULL,'KB-APP-2001','978-0-13-235109-6','SN-APP-2023-005','APPLE MAGIC KEYBOARD','TECLADO APPLE MAGIC KEYBOARD INALÁMBRICO',NULL,80.00,1.50,1.19,120.00,95.20,10.00,40.00,12.00,0,0,0,'Teclado Apple Magic Keyboard inalámbrico con diseño compacto y batería recargable.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (738,69,1,1,1,1,1,9,1700,'SM-69-00003',NULL,'KB-LEN-3001','978-0-13-235110-2','SN-LEN-2023-005','LENOVO WIRED KEYBOARD','TECLADO LENOVO WIRED KEYBOARD USB',NULL,25.00,1.50,1.19,37.50,29.75,10.00,60.00,20.00,0,0,0,'Teclado Lenovo con cable USB, diseño estándar y teclas de bajo perfil.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (739,69,1,1,1,1,1,9,1700,'SM-69-00004',NULL,'KB-HP-1001','978-0-13-235111-9','SN-HP-2023-006','HP WIRELESS KEYBOARD','TECLADO HP WIRELESS KEYBOARD INALÁMBRICO',NULL,35.00,1.50,1.19,52.50,41.65,10.00,50.00,15.00,0,0,0,'Teclado HP Wireless Keyboard inalámbrico con alcance de hasta 10 metros.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (740,69,1,1,1,1,1,9,1700,'SM-69-00005',NULL,'KB-DELL-2001','978-0-13-235112-6','SN-DELL-2023-002','DELL WIRELESS KEYBOARD','TECLADO DELL WIRELESS KEYBOARD INALÁMBRICO',NULL,30.00,1.50,1.19,45.00,35.70,10.00,55.00,18.00,0,0,0,'Teclado Dell Wireless Keyboard inalámbrico con diseño ergonómico y batería de larga duración.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (741,75,1,1,1,1,1,9,1700,'SM-75-00001',NULL,'LIB-1001','978-0-13-235113-3',NULL,NULL,'CIEN AÑOS DE SOLEDAD',NULL,15.00,1.50,1.19,22.50,17.85,10.00,50.00,15.00,0,0,0,'Novela de Gabriel García Márquez, una obra maestra del realismo mágico que narra la historia de la familia Buendía.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (742,75,1,1,1,1,1,9,1700,'SM-75-00002',NULL,'LIB-1002','978-0-13-235114-0',NULL,NULL,'EL AMOR EN LOS TIEMPOS DEL CÓLERA',NULL,14.00,1.50,1.19,21.00,16.66,10.00,45.00,12.00,0,0,0,'Otra gran novela de Gabriel García Márquez que explora el amor a través del tiempo y la espera.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (743,75,1,1,1,1,1,9,1700,'SM-75-00003',NULL,'LIB-1003','978-0-13-235115-7',NULL,NULL,'LA CASA DE LOS ESPÍRITUS',NULL,13.00,1.50,1.19,19.50,15.47,10.00,40.00,10.00,0,0,0,'Novela de Isabel Allende que narra la historia de la familia Trueba a través de generaciones.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (744,75,1,1,1,1,1,9,1700,'SM-75-00004',NULL,'LIB-1004','978-0-13-235116-4',NULL,NULL,'LA SOMBRA DEL VIENTO',NULL,14.50,1.50,1.19,21.75,17.26,10.00,42.00,11.00,0,0,0,'Novela de Carlos Ruiz Zafón, un thriller literario ambientado en la Barcelona de posguerra.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (745,75,1,1,1,1,1,9,1700,'SM-75-00005',NULL,'LIB-1005','978-0-13-235117-1',NULL,NULL,'EL JUEGO DE ENDER',NULL,12.00,1.50,1.19,18.00,14.28,10.00,48.00,14.00,0,0,0,'Novela de ciencia ficción de Orson Scott Card sobre un niño genio en una guerra intergaláctica.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (746,76,1,1,1,1,1,9,1700,'SM-76-00001',NULL,'LIB-2001','978-0-13-235118-8',NULL,NULL,'IT (ESO)',NULL,16.00,1.50,1.19,24.00,19.04,10.00,35.00,8.00,0,0,0,'Novela de Stephen King que narra la historia de un grupo de niños que enfrentan a un payaso malvado.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (747,76,1,1,1,1,1,9,1700,'SM-76-00002',NULL,'LIB-2002','978-0-13-235119-5',NULL,NULL,'EL RESPLANDOR',NULL,14.00,1.50,1.19,21.00,16.66,10.00,38.00,10.00,0,0,0,'Novela de terror de Stephen King sobre un hotel encantado y un escritor que enloquece.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (748,76,1,1,1,1,1,9,1700,'SM-76-00003',NULL,'LIB-2003','978-0-13-235120-1',NULL,NULL,'LA CARRETERA',NULL,12.50,1.50,1.19,18.75,14.88,10.00,40.00,12.00,0,0,0,'Novela posapocalíptica de Cormac McCarthy sobre un padre y su hijo en un mundo devastado.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (749,76,1,1,1,1,1,9,1700,'SM-76-00004',NULL,'LIB-2004','978-0-13-235121-8',NULL,NULL,'LOS JUEGOS DEL HAMBRE',NULL,13.00,1.50,1.19,19.50,15.47,10.00,45.00,13.00,0,0,0,'Novela distópica de Suzanne Collins sobre un reality show de supervivencia en un mundo futuro.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (750,76,1,1,1,1,1,9,1700,'SM-76-00005',NULL,'LIB-2005','978-0-13-235122-5',NULL,NULL,'EL PSICOANALISTA',NULL,11.50,1.50,1.19,17.25,13.68,10.00,42.00,11.00,0,0,0,'Thriller psicológico de John Katzenbach sobre un psicoanalista que recibe una amenaza anónima.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (751,77,1,1,1,1,1,9,1700,'SM-77-00001',NULL,'LIB-3001','978-0-13-235123-2',NULL,NULL,'BREVE HISTORIA DEL TIEMPO',NULL,18.00,1.50,1.19,27.00,21.42,10.00,30.00,6.00,0,0,0,'Libro de Stephen Hawking que explora los conceptos fundamentales del universo y el tiempo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (752,77,1,1,1,1,1,9,1700,'SM-77-00002',NULL,'LIB-3002','978-0-13-235124-9',NULL,NULL,'EL GEN EGOÍSTA',NULL,16.00,1.50,1.19,24.00,19.04,10.00,35.00,8.00,0,0,0,'Libro de Richard Dawkins que explica la evolución desde la perspectiva del gen.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (753,77,1,1,1,1,1,9,1700,'SM-77-00003',NULL,'LIB-3003','978-0-13-235125-6',NULL,NULL,'SAPIENS: DE ANIMALES A DIOSES',NULL,17.00,1.50,1.19,25.50,20.23,10.00,32.00,7.00,0,0,0,'Libro de Yuval Noah Harari que narra la historia de la humanidad desde la prehistoria.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (754,77,1,1,1,1,1,9,1700,'SM-77-00004',NULL,'LIB-3004','978-0-13-235126-3',NULL,NULL,'EL MUNDO Y SUS DEMONIOS',NULL,15.50,1.50,1.19,23.25,18.45,10.00,38.00,10.00,0,0,0,'Libro de Carl Sagan que promueve el pensamiento crítico y la ciencia frente a la superstición.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (755,77,1,1,1,1,1,9,1700,'SM-77-00005',NULL,'LIB-3005','978-0-13-235127-0',NULL,NULL,'LA ESTRUCTURA DE LAS REVOLUCIONES CIENTÍFICAS',NULL,14.00,1.50,1.19,21.00,16.66,10.00,40.00,12.00,0,0,0,'Libro de Thomas Kuhn que analiza los paradigmas en la historia de la ciencia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (756,80,1,1,1,1,1,9,1700,'SM-80-00001',NULL,'LIB-4001','978-0-13-235128-7',NULL,NULL,'HISTORIA DE LA SEGUNDA GUERRA MUNDIAL',NULL,20.00,1.50,1.19,30.00,23.80,10.00,25.00,5.00,0,0,0,'Libro que relata los eventos clave de la Segunda Guerra Mundial, desde sus causas hasta su final.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (757,80,1,1,1,1,1,9,1700,'SM-80-00002',NULL,'LIB-4002','978-0-13-235129-4',NULL,NULL,'LOS ORÍGENES DEL TOTALITARISMO',NULL,18.00,1.50,1.19,27.00,21.42,10.00,30.00,6.00,0,0,0,'Libro de Hannah Arendt que analiza los regímenes totalitarios del siglo XX.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (758,80,1,1,1,1,1,9,1700,'SM-80-00003',NULL,'LIB-4003','978-0-13-235130-0',NULL,NULL,'HISTORIA DE LA FILOSOFÍA OCCIDENTAL',NULL,22.00,1.50,1.19,33.00,26.18,10.00,20.00,4.00,0,0,0,'Libro de Bertrand Russell que recorre la historia del pensamiento filosófico en Occidente.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (759,80,1,1,1,1,1,9,1700,'SM-80-00004',NULL,'LIB-4004','978-0-13-235131-7',NULL,NULL,'EL ARTE DE LA GUERRA',NULL,10.00,1.50,1.19,15.00,11.90,10.00,45.00,12.00,0,0,0,'Tratado militar de Sun Tzu que aborda estrategias y tácticas para el combate.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (760,80,1,1,1,1,1,9,1700,'SM-80-00005',NULL,'LIB-4005','978-0-13-235132-4',NULL,NULL,'HISTORIA DE BOLIVIA',NULL,12.00,1.50,1.19,18.00,14.28,10.00,40.00,10.00,0,0,0,'Libro que relata la historia de Bolivia desde sus orígenes precolombinos hasta la actualidad.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (761,81,1,1,1,1,1,9,1700,'SM-81-00001',NULL,'LIB-5001','978-0-13-235133-1',NULL,NULL,'HARRY POTTER Y LA PIEDRA FILOSOFAL',NULL,12.00,1.50,1.19,18.00,14.28,10.00,50.00,15.00,0,0,0,'Primer libro de la saga de J.K. Rowling, donde Harry Potter descubre que es un mago.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (762,81,1,1,1,1,1,9,1700,'SM-81-00002',NULL,'LIB-5002','978-0-13-235134-8',NULL,NULL,'EL PRINCIPITO',NULL,8.00,1.50,1.19,12.00,9.52,10.00,60.00,20.00,0,0,0,'Clásico de Antoine de Saint-Exupéry sobre un pequeño príncipe que viaja por el universo.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (763,81,1,1,1,1,1,9,1700,'SM-81-00003',NULL,'LIB-5003','978-0-13-235135-5',NULL,NULL,'LA CASA DE LOS ESPÍRITUS',NULL,13.00,1.50,1.19,19.50,15.47,10.00,45.00,12.00,0,0,0,'Novela de Isabel Allende, obra infantil-juvenil que narra aventuras de una familia.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (764,81,1,1,1,1,1,9,1700,'SM-81-00004',NULL,'LIB-5004','978-0-13-235136-2',NULL,NULL,'MATILDA',NULL,9.00,1.50,1.19,13.50,10.71,10.00,55.00,18.00,0,0,0,'Novela de Roald Dahl sobre una niña prodigio con poderes especiales.',NULL,NULL,NULL,NULL,4150,1000,1),
	 (765,81,1,1,1,1,1,9,1700,'SM-81-00005',NULL,'LIB-5005','978-0-13-235137-9',NULL,NULL,'CHARLIE Y LA FÁBRICA DE CHOCOLATE',NULL,10.00,1.50,1.19,15.00,11.90,10.00,50.00,15.00,0,0,0,'Otra obra de Roald Dahl que narra la aventura de Charlie en la fábrica de chocolate de Willy Wonka.',NULL,NULL,NULL,NULL,4150,1000,1);

SELECT setval('productos_producto_id_seq', COALESCE((SELECT MAX(producto_id) FROM productos), 0), (SELECT COUNT(*) > 0 FROM productos));

-- ================================================================================================

DELETE FROM productos_vias;
ALTER SEQUENCE productos_vias_producto_via_id_seq RESTART WITH 1;

INSERT INTO productos_vias (producto_via_id, producto_id, via_id, es_principal, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 'NINGUNO', 1000, 1);

SELECT setval('productos_vias_producto_via_id_seq', COALESCE((SELECT MAX(producto_via_id) FROM productos_vias), 0), (SELECT COUNT(*) > 0 FROM productos_vias));

-- ================================================================================================

DELETE FROM equivalentes;
ALTER SEQUENCE equivalentes_equivalente_id_seq RESTART WITH 1;

INSERT INTO equivalentes (equivalente_id, producto_base_id, producto_alternativo_id, grado_equivalente_id, prioridad_recomendacion, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 3803, 1, 'NINGUNO', 1000, 1);

SELECT setval('equivalentes_equivalente_id_seq', COALESCE((SELECT MAX(equivalente_id) FROM equivalentes), 0), (SELECT COUNT(*) > 0 FROM equivalentes));

-- ================================================================================================

DELETE FROM productos_rangos_edad;
ALTER SEQUENCE productos_rangos_edad_producto_rango_edad_id_seq RESTART WITH 1;

INSERT INTO productos_rangos_edad (producto_rango_edad_id, producto_id, rango_edad_id, contraindicado, dosis_recomendada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, NULL, NULL, 1000, 1);

SELECT setval('productos_rangos_edad_producto_rango_edad_id_seq', COALESCE((SELECT MAX(producto_rango_edad_id) FROM productos_rangos_edad), 0), (SELECT COUNT(*) > 0 FROM productos_rangos_edad));

-- ================================================================================================

DELETE FROM productos_ubicaciones;
ALTER SEQUENCE productos_ubicaciones_producto_ubicacion_id_seq RESTART WITH 1;

INSERT INTO productos_ubicaciones (producto_ubicacion_id, producto_id, ubicacion_id, prioridad_picking, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 99, 1000, 1);

SELECT setval('productos_ubicaciones_producto_ubicacion_id_seq', COALESCE((SELECT MAX(producto_ubicacion_id) FROM productos_ubicaciones), 0), (SELECT COUNT(*) > 0 FROM productos_ubicaciones));

-- ================================================================================================

DELETE FROM principios_activos;
ALTER SEQUENCE principios_activos_principio_activo_id_seq RESTART WITH 1;

INSERT INTO principios_activos (principio_activo_id, codigo, nombre, descripcion, es_controlado, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN COMPONENTE ACTIVO REGISTRADO / NO APLICA', 0, 1000, 1);

SELECT setval('principios_activos_principio_activo_id_seq', COALESCE((SELECT MAX(principio_activo_id) FROM principios_activos), 0), (SELECT COUNT(*) > 0 FROM principios_activos));

-- ================================================================================================

DELETE FROM productos_principios;
ALTER SEQUENCE productos_principios_producto_principio_id_seq RESTART WITH 1;

INSERT INTO productos_principios (producto_principio_id, producto_id, principio_activo_id, concentracion, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 0, 1000, 1);

SELECT setval('productos_principios_producto_principio_id_seq', COALESCE((SELECT MAX(producto_principio_id) FROM productos_principios), 0), (SELECT COUNT(*) > 0 FROM productos_principios));

-- ================================================================================================

DELETE FROM registros_sanitarios;
ALTER SEQUENCE registros_sanitarios_registro_sanitario_id_seq RESTART WITH 1;

INSERT INTO registros_sanitarios (registro_sanitario_id, producto_id, codigo_registro, entidad_emisora, fecha_emision, fecha_vencimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', '2000-01-01', '2001-01-01', 1000, 1);

SELECT setval('registros_sanitarios_registro_sanitario_id_seq', COALESCE((SELECT MAX(registro_sanitario_id) FROM registros_sanitarios), 0), (SELECT COUNT(*) > 0 FROM registros_sanitarios));

-- ================================================================================================

DELETE FROM productos_controlados;
ALTER SEQUENCE productos_controlados_producto_controlado_id_seq RESTART WITH 1;

INSERT INTO productos_controlados (producto_controlado_id, producto_id, numero_autorizacion, requiere_receta_retenida, observaciones_control, estado_id, usuario_id_registro) VALUES 
(1, 1, 'NINGUNO', 0, 'SIN FISCALIZACIÓN / NO APLICA', 1000, 1);

SELECT setval('productos_controlados_producto_controlado_id_seq', COALESCE((SELECT MAX(producto_controlado_id) FROM productos_controlados), 0), (SELECT COUNT(*) > 0 FROM productos_controlados));

-- ================================================================================================

DELETE FROM promociones;
ALTER SEQUENCE promociones_promocion_id_seq RESTART WITH 1;

INSERT INTO promociones (promocion_id, codigo, nombre, descripcion, tipo_beneficio_id, valor_beneficio, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN CAMPAÑA PROMOCIONAL / NO APLICA', 1504, 0.00, '2000-01-01', '2001-01-01', 1000, 1);

SELECT setval('promociones_promocion_id_seq', COALESCE((SELECT MAX(promocion_id) FROM promociones), 0), (SELECT COUNT(*) > 0 FROM promociones));

-- ================================================================================================

DELETE FROM promociones_productos;
ALTER SEQUENCE promociones_productos_promocion_producto_id_seq RESTART WITH 1;

INSERT INTO promociones_productos (promocion_producto_id, promocion_id, producto_id, limite_por_transaccion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, 1000, 1);

SELECT setval('promociones_productos_promocion_producto_id_seq', COALESCE((SELECT MAX(promocion_producto_id) FROM promociones_productos), 0), (SELECT COUNT(*) > 0 FROM promociones_productos));

-- ================================================================================================

DELETE FROM conversiones_unidad;
ALTER SEQUENCE conversiones_unidad_conversion_id_seq RESTART WITH 1;

INSERT INTO conversiones_unidad (conversion_id, producto_id, unidad_origen_id, unidad_destino_id, factor_conversion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1.0000, 1000, 1);

SELECT setval('conversiones_unidad_conversion_id_seq', COALESCE((SELECT MAX(conversion_id) FROM conversiones_unidad), 0), (SELECT COUNT(*) > 0 FROM conversiones_unidad));

-- ================================================================================================

DELETE FROM proveedores;
ALTER SEQUENCE proveedores_proveedor_id_seq RESTART WITH 1;

INSERT INTO proveedores (proveedor_id, codigo, nombre, nit, direccion, telefono, email, rating_calidad_id, monto_minimo_compra, plazo_entrega_dias, limite_credito, dias_credito, ultima_evaluacion, observaciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', NULL, NULL, NULL, NULL, 2055, 0.00, 0, 0.00, 0, NULL, 'PROVEEDOR COMODÍN PARA COMPRAS DIRECTAS O DONACIONES', 1000, 1);

SELECT setval('proveedores_proveedor_id_seq', COALESCE((SELECT MAX(proveedor_id) FROM proveedores), 0), (SELECT COUNT(*) > 0 FROM proveedores));

-- ================================================================================================

DELETE FROM proveedores_contactos;
ALTER SEQUENCE proveedores_contactos_proveedor_contacto_id_seq RESTART WITH 1;

INSERT INTO proveedores_contactos (proveedor_contacto_id, proveedor_id, nombre, cargo, telefono, email, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', NULL, NULL, 1, 1000, 1);

SELECT setval('proveedores_contactos_proveedor_contacto_id_seq', COALESCE((SELECT MAX(proveedor_contacto_id) FROM proveedores_contactos), 0), (SELECT COUNT(*) > 0 FROM proveedores_contactos));

-- ================================================================================================

DELETE FROM proveedores_rating_historico;
ALTER SEQUENCE proveedores_rating_historico_rating_historico_id_seq RESTART WITH 1;

INSERT INTO proveedores_rating_historico (rating_historico_id, proveedor_id, rating_calidad_id, motivo, fecha_evaluacion, estado_id, usuario_id_registro)
VALUES (1, 1, 2055, 'REGISTRO INICIAL COMODÍN', CURRENT_DATE, 1000, 1);

SELECT setval('proveedores_rating_historico_rating_historico_id_seq', COALESCE((SELECT MAX(rating_historico_id) FROM proveedores_rating_historico), 0), (SELECT COUNT(*) > 0 FROM proveedores_rating_historico));

-- ================================================================================================

DELETE FROM parametros_globales;
ALTER SEQUENCE parametros_globales_parametro_id_seq RESTART WITH 1;

INSERT INTO parametros_globales (parametro_id,clave,valor,tipo_dato_id,datos_json,descripcion,editable,estado_id,usuario_id_registro) VALUES
	 (1,'ninguna','comodin_sistema',1800,NULL,'Registro comodin por defecto para parametros_globales',0,1000,1),
	 (2,'moneda_principal','BOB',1800,NULL,'Moneda base del sistema boliviano',0,1000,2),
	 (3,'porcentaje_iva','13.00',1802,NULL,'Alícuota general del IVA en Bolivia',0,1000,2),
	 (4,'limite_items_proforma','50',1801,NULL,'Cantidad máxima de ítems permitidos por proforma',1,1000,2),
	 (5,'controlar_lotes_vencidos','1',1803,NULL,'Habilitar bloqueo de venta para lotes expirados (1=Si, 0=No)',1,1000,2),
	 (6,'dias_alerta_vencimiento','90',1801,NULL,'Días de anticipación para notificar la expiración de medicamentos',1,1000,2),
	 (7,'modelo_arima_p','1',1801,NULL,'Orden autorregresivo (p) para modelo ARIMA',0,1000,2),
	 (8,'modelo_arima_d','1',1801,NULL,'Orden de diferenciación (d) para modelo ARIMA',0,1000,2),
	 (9,'modelo_arima_q','1',1801,NULL,'Orden de promedio móvil (q) para modelo ARIMA',0,1000,2),
	 (10,'modelo_sarima_p','1',1801,NULL,'Orden autorregresivo estacional (P) para SARIMA',0,1000,2),
	 (11,'modelo_sarima_d','1',1801,NULL,'Orden de diferenciación estacional (D) para SARIMA',0,1000,2),
	 (12,'modelo_sarima_q','1',1801,NULL,'Orden de promedio móvil estacional (Q) para SARIMA',0,1000,2),
	 (13,'modelo_sarima_s','7',1801,NULL,'Período estacional (s) para SARIMA (7=días, 12=meses)',0,1000,2),
	 (14,'modelo_kmeans_n_clusters','3',1801,NULL,'Número de clusters para K-Means (A, B, C)',0,1000,2),
	 (15,'modelo_kmeans_random_state','42',1801,NULL,'Semilla aleatoria para reproducibilidad',0,1000,2),
	 (16,'modelo_kmeans_max_iter','300',1801,NULL,'Máximo de iteraciones para K-Means',0,1000,2),
	 (17,'modelo_rop_lead_time_default','7',1801,NULL,'Lead time por defecto en días para cálculo de ROP',0,1000,2),
	 (18,'modelo_rop_stock_seguridad_default','10',1802,NULL,'Stock de seguridad por defecto para ROP',0,1000,2),
	 (19,'modelo_rop_nivel_confianza','0.95',1802,NULL,'Nivel de confianza para intervalos de predicción',0,1000,2),
	 (20,'alerta_dias_vencimiento_critico','15',1801,NULL,'Días para alerta CRÍTICA de vencimiento',1,1000,2),
	 (21,'alerta_dias_vencimiento_alta','30',1801,NULL,'Días para alerta ALTA de vencimiento',1,1000,2),
	 (22,'alerta_dias_vencimiento_media','60',1801,NULL,'Días para alerta MEDIA de vencimiento',1,1000,2),
	 (23,'alerta_stock_quiebre','5',1801,NULL,'Stock mínimo para alerta de quiebre',1,1000,2),
	 (24,'alerta_stock_reorden','20',1801,NULL,'Stock para alerta de reorden',1,1000,2),
	 (25,'alerta_dias_ventanas_dias','90',1801,NULL,'Ventana de días para entrenar modelos',1,1000,2),
	 (26,'entrenamiento_min_registros','30',1801,NULL,'Mínimo de registros para entrenar un modelo',1,1000,2),
	 (27,'entrenamiento_test_size','0.2',1802,NULL,'Porcentaje de datos para prueba (test)',1,1000,2),
	 (28,'longitud_numero_factura','7',1801,NULL,'Cantidad de dígitos para el número de factura (con ceros a la izquierda)',1,1000,2),
	 (29,'multa_dias_gracia','10',1801,NULL,'Días de tolerancia permitidos antes de aplicar cargos por retraso en cuotas',1,1000,2),
	 (30,'multa_tipo_calculo','PORCENTAJE',1800,NULL,'Tipo de cálculo para la multa: MONTO_FIJO o PORCENTAJE sobre la cuota vencida',1,1000,2),
	 (31,'multa_valor_diario','0.50',1802,NULL,'Valor diario de la multa (monto en moneda base o porcentaje según el tipo de cálculo)',1,1000,2),
	 (32,'gestion_activa','2026-01-01 00:00:00-04:00',1804,NULL,'Fecha y hora de inicio de la gestión activa del sistema (con timezone -04:00 Bolivia)',1,1000,2),
	 (33, 'logo_config', 'LOGO_CONFIG', 1805, '{"max_size": 358400, "max_width": 1500, "max_height": 600, "default_logo": null, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de logos de empresas (tamaño máximo: 350 KB, dimensiones: 1500x600 px, formatos: PNG, JPEG, JPG)', 1, 1000, 2),
	 (34, 'factores', 'FACTORES_CONFIG', 1805, '{"factor_venta": 1.50, "factor_facturacion": 1.19}', 'Configuración agrupada de factores para venta y facturación', 1, 1000, 2);

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (35, 'foto_trabajador_config', 'default-foto-trabajador.jpg', 1805, '{"max_size": 512000, "max_width": 600, "max_height": 700, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de fotos de trabajadores en formato vertical (tamaño máximo: 500 KB, dimensiones: 600x700 px)', 1, 1000, 2),
     (36, 'qr_trabajador_config', 'QR_CONFIG', 1805, '{"width": 300, "height": 300, "margin": 2, "color_dark": "#000000", "color_light": "#FFFFFF", "format": "png", "error_correction_level": "M"}', 'Configuración para la autogeneración de códigos QR del trabajador (300x300 px, fondo blanco, PNG)', 1, 1000, 2);

INSERT INTO parametros_globales (parametro_id, clave, valor, tipo_dato_id, datos_json, descripcion, editable, estado_id, usuario_id_registro) VALUES
     (37, 'avatar_config', 'AVATAR_CONFIG', 1805, '{"max_size": 20480, "max_width": 48, "max_height": 48, "retention_days": 1, "allowed_formats": ["png", "jpeg"], "allowed_extensions": ["png", "jpg", "jpeg"]}', 'Configuración de avatares de usuarios (tamaño máximo: 20 KB, dimensiones: 48x48 px, formatos: PNG, JPEG, JPG)', 1, 1000, 2);
	 
SELECT setval('parametros_globales_parametro_id_seq', COALESCE((SELECT MAX(parametro_id) FROM parametros_globales), 0), (SELECT COUNT(*) > 0 FROM parametros_globales));

-- ================================================================================================

DELETE FROM tareas_programadas;
ALTER SEQUENCE tareas_programadas_tarea_id_seq RESTART WITH 1;

INSERT INTO tareas_programadas (
    tarea_id, codigo, nombre, descripcion, tipo_tarea_id, subtipo_tarea_id, 
    frecuencia_id, cron_expresion, parametros, ultima_ejecucion, proxima_ejecucion, 
    ejecucion_exitosa, ultimo_error, intentos_fallidos, max_intentos, 
    tarea_dependencia_id, ejecutar_en_cascada, modulo_estrategico_id, estado_id, usuario_id_registro
) VALUES
(1, 'NIN', 'NINGUNO', 'NINGUNA', 3409, 3461, 3359, NULL, '{"ejecutar": false}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(2, 'ALERTA_VENC', 'ALERTA DE VENCIMIENTO DE LOTES', 'Identifica lotes próximos a vencer y genera notificaciones', 3403, 3461, 3352, '0 6 * * *', '{"dias_alerta_critica": 15, "dias_alerta_alta": 30, "dias_alerta_media": 60}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2153, 1000, 1),
(3, 'ALERTA_STOCK', 'ALERTA DE STOCK CRÍTICO', 'Monitorea inventario y genera alertas por debajo del punto de reorden', 3403, 3461, 3351, '0 * * * *', '{"umbral_quiebre": 5, "umbral_reorden": 20}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(4, 'ENTRENAR_SARIMA', 'ENTRENAMIENTO DE MODELO SARIMA', 'Entrena el modelo de pronóstico de demanda con datos históricos', 3405, 3450, 3353, '0 2 * * 0', '{"ventana_dias": 90, "test_size": 0.2, "p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(5, 'CLASIFICAR_ABC', 'CLASIFICACIÓN ABC DE INVENTARIO', 'Reclasifica productos en categorías A, B y C con K-Means', 3406, 3453, 3354, '0 3 1 * *', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "criterios": ["costo", "rotacion", "margen", "criticidad"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(6, 'PREDECIR_DEMANDA', 'PREDICCIÓN DE DEMANDA Y ROP', 'Calcula predicciones de demanda y actualiza puntos de reorden', 3407, 3454, 3352, '0 4 * * *', '{"dias_a_predecir": 30, "lead_time_default": 7, "stock_seguridad_default": 10}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(7, 'BACKUP_DB', 'RESPALDO AUTOMÁTICO DE BASE DE DATOS', 'Genera backup completo de PostgreSQL', 3402, 3461, 3352, '0 1 * * *', '{"retencion_dias": 30, "compresion": true, "ruta_destino": "/backups/db/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(8, 'REPORTE_VENTAS_DIA', 'REPORTE DIARIO DE VENTAS', 'Consolida ventas del día con gráficos y resúmenes', 3400, 3461, 3352, '0 23 * * *', '{"formato": "PDF", "incluir_graficos": true, "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(9, 'LIMPIEZA_NOTIFICACIONES', 'LIMPIEZA DE NOTIFICACIONES LEÍDAS', 'Archiva notificaciones leídas con más de X días', 3404, 3461, 3353, '0 5 * * 0', '{"dias_para_archivar": 90}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(13, 'ENTRENAR_PROPHET', 'ENTRENAMIENTO DE MODELO PROPHET', 'Entrena el modelo Prophet de Facebook', 3405, 3452, 3354, '0 4 1 * *', '{"ventana_dias": 180, "estacionalidad_anual": true, "estacionalidad_semanal": true}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(10, 'PREDECIR_VENCIMIENTOS', 'PREDICCIÓN DE FECHAS DE VENCIMIENTO', 'Pronostica vencimientos basados en patrones de consumo', 3405, 3452, 3353, '0 4 * * 1', '{"modelo": "PROPHET", "dias_proyeccion": 180}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2153, 1000, 1),
(11, 'ALERTA_PREDICTIVA', 'ALERTAS PREDICTIVAS DE IA', 'Evalúa riesgos futuros basados en modelos predictivos', 3403, 3456, 3352, '0 7 * * *', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2156, 1000, 1),
(12, 'ENTRENAR_SARIMAX', 'ENTRENAMIENTO SARIMAX CON VARIABLES EXÓGENAS', 'Entrena SARIMAX incorporando variables externas', 3405, 3451, 3353, '0 3 * * 0', '{"ventana_dias": 90, "incluir_festivos": true, "incluir_clima": true}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(14, 'PATRON_CONSUMO', 'DETECCIÓN DE PATRONES DE CONSUMO', 'Analiza históricos para identificar patrones estacionales', 3405, 3455, 3354, '0 5 1 * *', '{"min_datos": 90, "umbral_correlacion": 0.7}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2151, 1000, 1),
(15, 'VAR_EXOGENA', 'PROCESAMIENTO DE VARIABLES EXÓGENAS', 'Obtiene y procesa variables externas', 3405, 3457, 3352, '0 1 * * *', '{"fuentes": ["API_CLIMA", "API_FESTIVOS", "API_ECONOMIA"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(16, 'VALIDAR_MODELOS', 'VALIDACIÓN CRUZADA DE MODELOS', 'Evalúa y compara el rendimiento de todos los modelos', 3408, 3460, 3354, '0 6 15 * *', '{"k_folds": 5, "metricas": ["MAPE", "RMSE", "MAE", "R2"]}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(17, 'METRICAS_IA', 'MÉTRICAS DE RENDIMIENTO DE IA', 'Genera reporte de métricas de todos los modelos', 3400, 3458, 3354, '0 7 1 * *', '{"incluir_graficos": true, "formato": "PDF"}', NULL, NULL, NULL, NULL, 0, 3, 16, 1, 2151, 1000, 1),
(18, 'REENTRENAR_AUTO', 'REENTRENAMIENTO AUTOMÁTICO DE MODELOS', 'Reentrena automáticamente si el error supera el umbral', 3405, 3459, 3357, NULL, '{"umbral_mape": 10.0, "min_datos_nuevos": 7, "modelos": ["SARIMA", "PROPHET"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(19, 'BACKUP_MODELOS', 'RESPALDO DE MODELOS DE IA', 'Guarda versionado de todos los modelos entrenados', 3402, 3461, 3353, '0 2 * * 0', '{"retencion_version": 10, "ruta_destino": "/backups/models/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(20, 'REPORTE_PREDICCIONES', 'REPORTE DE PREDICCIONES Y PROYECCIONES', 'Reporte consolidado de todas las predicciones de IA', 3400, 3461, 3354, '0 8 1 * *', '{"incluir_graficos": true, "formato": "PDF", "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2151, 1000, 1);

SELECT setval('tareas_programadas_tarea_id_seq', COALESCE((SELECT MAX(tarea_id) FROM tareas_programadas), 0), (SELECT COUNT(*) > 0 FROM tareas_programadas));

-- ================================================================================================

DELETE FROM control_facturas;
ALTER SEQUENCE control_facturas_control_factura_id_seq RESTART WITH 1;

INSERT INTO control_facturas (control_factura_id, sucursal_id, tipo_comprobante_id, numero_actual, numero_inicial, numero_final, autorizacion, cuf, cufd, cuis, codigo_control, codigo_qr, fecha_autorizacion, fecha_vencimiento, gestion, estado_operativo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1103, 0, 1, 999999, '00000000000000000000', NULL, NULL, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 2026, 3300, 1000, 1);

SELECT setval('control_facturas_control_factura_id_seq', COALESCE((SELECT MAX(control_factura_id) FROM control_facturas), 0), (SELECT COUNT(*) > 0 FROM control_facturas));

-- ================================================================================================

DELETE FROM kardex;
ALTER SEQUENCE kardex_kardex_id_seq RESTART WITH 1;

INSERT INTO kardex (kardex_id, tipo_comprobante_id, motivo_anulacion_id, motivo_devolucion_id, cliente_id, proveedor_id, sucursal_id, sucursal_destino_id, kardex_origen_id, kardex_pedido_compra_id, evento_id, codigo, comprobante, comprobante_referencia, kardex_referencia_id, fecha_kardex, total_compra, total_venta, total_venta_factura, total_pagado, total_cambio, saldo_pendiente, lugar_entrega, numero_factura, nota_credito_debito, validez_dias, fecha_expiracion, estado_proforma_id, tipo_factura_id, estado_traspaso_id, estado_financiero_id, estado_pedido_id, tipo_despacho_id, estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja) VALUES 
(1, 1103, 2455, 3506, 1, 1, 1, NULL, NULL, NULL, 1050, 'INI-1-2026-00000000', 'REGISTRO COMODIN SISTEMA', NULL, NULL, CURRENT_TIMESTAMP, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 4000, 2353, 2103, 2403, NULL, 3554, 1000, 1, NULL, NULL, CURRENT_TIMESTAMP, NULL, NULL);

SELECT setval('kardex_kardex_id_seq', COALESCE((SELECT MAX(kardex_id) FROM kardex), 0), (SELECT COUNT(*) > 0 FROM kardex));

-- ================================================================================================

DELETE FROM ordenes_compra;
ALTER SEQUENCE ordenes_compra_orden_compra_id_seq RESTART WITH 1;

INSERT INTO ordenes_compra (orden_compra_id, kardex_id, proveedor_id, numero_orden, fecha_orden, fecha_entrega_estimada, fecha_entrega_real, estado_pedido_id, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'OC-000000', CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 2253, 'ORDEN DE COMPRA COMODÍN PARA REGISTROS INICIALES', 1000, 1);

SELECT setval('ordenes_compra_orden_compra_id_seq', COALESCE((SELECT MAX(orden_compra_id) FROM ordenes_compra), 0), (SELECT COUNT(*) > 0 FROM ordenes_compra));

-- ================================================================================================

DELETE FROM instituciones;
ALTER SEQUENCE instituciones_institucion_id_seq RESTART WITH 1;

INSERT INTO instituciones (institucion_id, codigo, institucion, direccion, telefono, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, 1000, 1);

SELECT setval('instituciones_institucion_id_seq', COALESCE((SELECT MAX(institucion_id) FROM instituciones), 0), (SELECT COUNT(*) > 0 FROM instituciones));

-- ================================================================================================

DELETE FROM especialidades;
ALTER SEQUENCE especialidades_especialidad_id_seq RESTART WITH 1;

INSERT INTO especialidades (especialidad_id, especialidad, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 1000, 1);

SELECT setval('especialidades_especialidad_id_seq', COALESCE((SELECT MAX(especialidad_id) FROM especialidades), 0), (SELECT COUNT(*) > 0 FROM especialidades));

-- ================================================================================================

DELETE FROM medicos;
ALTER SEQUENCE medicos_medico_id_seq RESTART WITH 1;

INSERT INTO medicos (medico_id, medico, matricula, especialidad_id, telefono, email, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'MAT-000', 1, NULL, NULL, 1000, 1);

SELECT setval('medicos_medico_id_seq', COALESCE((SELECT MAX(medico_id) FROM medicos), 0), (SELECT COUNT(*) > 0 FROM medicos));

-- ================================================================================================

DELETE FROM recetas;
ALTER SEQUENCE recetas_receta_id_seq RESTART WITH 1;

INSERT INTO recetas (receta_id, kardex_id, cliente_id, sucursal_id, medico_id, institucion_id, tipo_receta_id, numero_receta, fecha_emision, diagnostico, receta_pdf, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 3853, 'REC-000', CURRENT_DATE, NULL, NULL, 1000, 1);

SELECT setval('recetas_receta_id_seq', COALESCE((SELECT MAX(receta_id) FROM recetas), 0), (SELECT COUNT(*) > 0 FROM recetas));

-- ================================================================================================

DELETE FROM lotes_productos;
ALTER SEQUENCE lotes_productos_lote_id_seq RESTART WITH 1;

INSERT INTO lotes_productos (lote_id, producto_id, kardex_id, codigo, fecha_vencimiento, cantidad_inicial, cantidad_actual, cantidad_reservada, precio_costo, fecha_fabricacion, lote_proveedor, ubicacion_id, rating_calidad_id, estado_lote_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', '2099-12-31', 1.00, 0.00, 0.00, 0.00, NULL, 'NINGUNO', 1, 2055, 2503, 1000, 1);

SELECT setval('lotes_productos_lote_id_seq', COALESCE((SELECT MAX(lote_id) FROM lotes_productos), 0), (SELECT COUNT(*) > 0 FROM lotes_productos));

-- ================================================================================================

DELETE FROM kardex_productos;
ALTER SEQUENCE kardex_productos_kardex_producto_id_seq RESTART WITH 1;

INSERT INTO kardex_productos (kardex_producto_id, kardex_id, producto_id, sucursal_id, lote_id, presentacion_id, tipo_pago_id, tipo_venta_id, kardex_producto_origen_id, cantidad, cantidad_unidad_base, cantidad_salida, pcompra, factor_venta, factor_facturacion, precio_venta, precio_venta_factura, costo_venta, descuento, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1400, 1350, 1, 0.00, 0.00, 0.00, 0.00, 1.00, 1.00, 0.00, 0.00, 0.00, 0.00, 1000, 1);

SELECT setval('kardex_productos_kardex_producto_id_seq', COALESCE((SELECT MAX(kardex_producto_id) FROM kardex_productos), 0), (SELECT COUNT(*) > 0 FROM kardex_productos));

-- ================================================================================================

DELETE FROM inventarios_fisicos_detalle;
ALTER SEQUENCE inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos_detalle (inventario_fisico_detalle_id, inventario_fisico_id, producto_id, lote_id, ubicacion_id, cantidad_sistema, cantidad_contada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 0.00, 0.00, 'REGISTRO INICIAL COMODIN DE DETALLE DE INVENTARIO FISICO', 1000, 1);

SELECT setval('inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq', COALESCE((SELECT MAX(inventario_fisico_detalle_id) FROM inventarios_fisicos_detalle), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos_detalle));

-- ================================================================================================

DELETE FROM ubicaciones_movimientos;
ALTER SEQUENCE ubicaciones_movimientos_ubicacion_movimiento_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_movimientos (ubicacion_movimiento_id, kardex_producto_id, ubicacion_origen_id, ubicacion_destino_id, lote_id, cantidad, tipo_ubicacion_movimiento_id, motivo, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, 1, 1.00, 3200, 'REGISTRO INICIAL COMODIN DE MOVIMIENTO', 1000, 1);

SELECT setval('ubicaciones_movimientos_ubicacion_movimiento_id_seq', COALESCE((SELECT MAX(ubicacion_movimiento_id) FROM ubicaciones_movimientos), 0), (SELECT COUNT(*) > 0 FROM ubicaciones_movimientos));

-- ================================================================================================

DELETE FROM ubicaciones_historial;
ALTER SEQUENCE ubicaciones_historial_ubicacion_historial_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_historial (ubicacion_historial_id, producto_id, ubicacion_origen_id, ubicacion_destino_id, kardex_producto_id, cantidad, motivo, trabajador_id, estado_id, usuario_id_registro) VALUES 
(1, 1, NULL, 1, NULL, 1.00, 'REGISTRO PREDETERMINADO INICIAL DE UBICACION', 1, 1002, 1);

SELECT setval('ubicaciones_historial_ubicacion_historial_id_seq', COALESCE((SELECT MAX(ubicacion_historial_id) FROM ubicaciones_historial), 1), true);

-- ================================================================================================

DELETE FROM tipos_planes_pago;
ALTER SEQUENCE tipos_planes_pago_tipo_plan_pago_id_seq RESTART WITH 1;

INSERT INTO tipos_planes_pago (tipo_plan_pago_id, codigo, nombre, meses_plazo, porcentaje_recargo, monto_fijo_recargo, permite_personalizar, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 0, 0.00, 0.00, 0, 'Pago por defecto.', 1000, 1),
(2, '3M', 'Plan a 3 Meses', 3, 5.00, 0.00, 0, 'Fraccionado a 3 meses con un recargo financiero del 5% sobre capital.', 1000, 1),
(3, '6M', 'Plan a 6 Meses', 6, 10.00, 0.00, 0, 'Fraccionado a 6 meses con un recargo financiero del 10% sobre capital.', 1000, 1),
(4, '12M', 'Plan a 12 Meses', 12, 18.00, 0.00, 0, 'Fraccionado a 12 meses con un recargo financiero del 18% sobre capital.', 1000, 1),
(5, 'PER', 'Plan Personalizado', 0, 0.00, 0.00, 1, 'Plan a medida donde el usuario define fechas y porcentajes por cuota.', 1000, 1);

SELECT setval('tipos_planes_pago_tipo_plan_pago_id_seq', COALESCE((SELECT MAX(tipo_plan_pago_id) FROM tipos_planes_pago), 0), (SELECT COUNT(*) > 0 FROM tipos_planes_pago));

-- ================================================================================================

DELETE FROM planes_pagos;
ALTER SEQUENCE planes_pagos_plan_pago_id_seq RESTART WITH 1;

INSERT INTO planes_pagos (plan_pago_id, kardex_id, numero_cuota, monto_programado, fecha_vencimiento, estado_pago_id, fecha_pago, monto_pagado, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, '2026-01-01', 2553, '2026-01-01', 0.00, 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

SELECT setval('planes_pagos_plan_pago_id_seq', COALESCE((SELECT MAX(plan_pago_id) FROM planes_pagos), 0), (SELECT COUNT(*) > 0 FROM planes_pagos));

-- ================================================================================================

DELETE FROM comprobantes_pagos;
ALTER SEQUENCE comprobantes_pagos_comprobante_pago_id_seq RESTART WITH 1;

INSERT INTO comprobantes_pagos (comprobante_pago_id, kardex_id, banco_id, tipo_pago_id, tipo_moneda_id, codigo_transaccion, monto, fecha_pago, titular_cuenta, autorizacion_nro, cuenta_destino, comprobante_digital_ruta, confirmado, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 2300, 'SN', 0.01, CURRENT_DATE, 'NINGUNO', NULL, NULL, NULL, 0, 1000, 1);

SELECT setval('comprobantes_pagos_comprobante_pago_id_seq', COALESCE((SELECT MAX(comprobante_pago_id) FROM comprobantes_pagos), 0), (SELECT COUNT(*) > 0 FROM comprobantes_pagos));

-- ================================================================================================

DELETE FROM pagos;
ALTER SEQUENCE pagos_pago_id_seq RESTART WITH 1;

INSERT INTO pagos (pago_id, kardex_id, plan_pago_id, tipo_pago_id, comprobante_pago_id, monto, fecha_pago, referencia, comprobante, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 1, 1.00, '2026-01-01', 'NINGUNO', 'NINGUNO', 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

SELECT setval('pagos_pago_id_seq', COALESCE((SELECT MAX(pago_id) FROM pagos), 0), (SELECT COUNT(*) > 0 FROM pagos));

-- ================================================================================================

DELETE FROM cajas;
ALTER SEQUENCE cajas_caja_id_seq RESTART WITH 1;

INSERT INTO cajas (caja_id, sucursal_id, apertura_trabajador_id, cierre_trabajador_id, autorizacion_trabajador_id, fecha_apertura, fecha_cierre, fecha_autorizacion, monto_inicial, monto_ingresos, monto_egresos, monto_ventas, monto_final_esperado, monto_final_real, diferencia, total_transacciones, total_ventas, total_devoluciones, total_retiros, estado_caja_id, observaciones, estado_id, usuario_id_registro) VALUES 
(1, 1, 1, 1, 1, '2026-01-01 00:00:00-04', NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 0, 0, 0, 0, 2650, 'REGISTRO COMODIN INICIAL', 1000, 1);

SELECT setval('cajas_caja_id_seq', COALESCE((SELECT MAX(caja_id) FROM cajas), 0), (SELECT COUNT(*) > 0 FROM cajas));

-- ================================================================================================

DELETE FROM movimientos;
ALTER SEQUENCE movimientos_movimiento_id_seq RESTART WITH 1;

INSERT INTO movimientos (movimiento_id, caja_id, referencia_id, trabajador_id, tipo_movimiento_id, tipo_pago_id, monto, saldo_antes, saldo_despues, motivo, fecha_movimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 2600, 1400, 0.01, 0.00, 0.01, 'REGISTRO COMODIN OBLIGATORIO', CURRENT_TIMESTAMP, 1000, 1);

SELECT setval('movimientos_movimiento_id_seq', COALESCE((SELECT MAX(movimiento_id) FROM movimientos), 0), (SELECT COUNT(*) > 0 FROM movimientos));

-- ================================================================================================

DELETE FROM arqueos_detalle;
ALTER SEQUENCE arqueos_detalle_arqueo_detalle_id_seq RESTART WITH 1;

INSERT INTO arqueos_detalle (arqueo_detalle_id, caja_id, tipo_billete_id, cantidad, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 4300, 0, 0.00, 1000, 1);

SELECT setval('arqueos_detalle_arqueo_detalle_id_seq', COALESCE((SELECT MAX(arqueo_detalle_id) FROM arqueos_detalle), 0), (SELECT COUNT(*) > 0 FROM arqueos_detalle));

-- ================================================================================================

DELETE FROM alertas_notificaciones;
ALTER SEQUENCE alertas_notificaciones_alerta_notificacion_id_seq RESTART WITH 1;

INSERT INTO alertas_notificaciones (alerta_notificacion_id, sucursal_id, codigo, tipo_alerta_notificacion_id, subtipo_alerta_id, origen_alerta_id, nivel_critico_id, titulo, mensaje, entidad_afectada_tipo_id, entidad_afectada_id, metadata, estado_alerta_id, trabajador_asignado_id, fecha_asignacion, es_leido, fecha_lectura, trabajador_resolutor_id, fecha_resolucion, comentarios_resolucion, accion_tomada, estado_id, usuario_id_registro) VALUES
(1, 1, 'ALN-000', 2700, 2812, 2850, 2905, 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO', 4111, NULL, '{}'::jsonb, 2953, 1, NULL, 1, CURRENT_TIMESTAMP, 1, NULL, NULL, NULL, 1000, 1);

SELECT setval('alertas_notificaciones_alerta_notificacion_id_seq', COALESCE((SELECT MAX(alerta_notificacion_id) FROM alertas_notificaciones), 0), (SELECT COUNT(*) > 0 FROM alertas_notificaciones));

-- ================================================================================================

DELETE FROM modelos;
ALTER SEQUENCE modelos_modelo_id_seq RESTART WITH 1;

INSERT INTO modelos (modelo_id, codigo, nombre, tipo_modelo_id, descripcion, framework_id, framework_version, version, parametros_default, estado_modelo_id, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 1456, 'REGISTRO COMODIN POR DEFECTO', 3004, '0.0.0', '0.0.0', '{}'::jsonb, 2002, 1000, 1),
(2, 'ARIMA', 'ARIMA_CLASICO', 1450, 'Modelo ARIMA (Autoregressive Integrated Moving Average) para pronóstico de demanda sin componente estacional, útil para series temporales no estacionales', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(3, 'SARIMA', 'SARIMA_ESTACIONAL', 1451, 'Modelo SARIMA (Seasonal ARIMA) para pronóstico de demanda estacional con componentes autorregresivos, de diferenciación y promedio móvil estacional. Ideal para patrones semanales, mensuales o anuales', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(4, 'SARIMAX', 'SARIMAX_EXOGENO', 1451, 'Modelo SARIMAX (SARIMA con variables exógenas) que incorpora factores externos como clima, festivos, días especiales y campañas promocionales para mejorar la precisión del pronóstico', 3000, '0.14.1', '0.14.1', '{"p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7, "trend": "c", "enforce_stationarity": false, "enforce_invertibility": false, "exog_variables": ["temperatura", "festivo", "dia_semana", "mes", "promocion"], "metrica_optimizacion": "AIC"}'::jsonb, 2002, 1000, 1),
(16, 'AUTOARIMA', 'AUTO_ARIMA', 1451, 'Modelo Auto-ARIMA que realiza búsqueda automática de los mejores parámetros (p, d, q, P, D, Q, s) utilizando criterios de información AIC/BIC. Ideal para automatizar el entrenamiento', 3000, '0.14.1', '0.14.1', '{"p_max": 5, "d_max": 2, "q_max": 5, "P_max": 2, "D_max": 1, "Q_max": 2, "s_max": 12, "criterio": "aic", "seasonal": true, "m": 7, "stepwise": true, "trace": false}'::jsonb, 2002, 1000, 1),
(5, 'PROPHET', 'PROPHET_META', 1452, 'Modelo Prophet de Facebook/Meta para detección de estacionalidades múltiples (anual, semanal, diaria) y manejo de días festivos, ideal para patrones de consumo farmacéutico con múltiples estacionalidades', 3003, '1.1.5', '1.1.5', '{"growth": "linear", "yearly_seasonality": true, "weekly_seasonality": true, "daily_seasonality": false, "seasonality_mode": "additive", "changepoint_prior_scale": 0.05, "seasonality_prior_scale": 10.0, "holidays_prior_scale": 10.0, "interval_width": 0.95}'::jsonb, 2002, 1000, 1),
(6, 'PATRON', 'PATRON_CONSUMO', 1452, 'Modelo especializado en detección de patrones de consumo estacionales y tendencias de largo plazo para medicamentos, identificando picos por enfermedades estacionales (gripe, alergias, etc.)', 3003, '1.0.0', '1.0.0', '{"min_datos_entrenamiento": 90, "umbral_correlacion": 0.7, "ventana_deteccion": 30, "nivel_confianza": 0.95, "metrica_principal": "MAPE", "enfermedades_estacionales": ["gripe", "alergia", "dengue", "infecciones"]}'::jsonb, 2002, 1000, 1),
(14, 'PREDVENC', 'PREDICTOR_VENCIMIENTOS', 1452, 'Modelo especializado en pronosticar fechas de vencimiento de lotes basado en patrones históricos de consumo y rotación de inventario. Identifica lotes con riesgo de vencerse antes de ser vendidos', 3003, '1.0.0', '1.0.0', '{"dias_proyeccion": 180, "min_datos_consumo": 60, "umbral_riesgo_alto": 0.8, "umvald_riesgo_medio": 0.5, "incluir_estacionalidad": true, "factor_estacional": 1.15}'::jsonb, 2002, 1000, 1),
(15, 'ENSEMBLE', 'ENSEMBLE_FORECAST', 1452, 'Modelo Ensemble que combina predicciones de ARIMA, SARIMA, Prophet y otros modelos para mejorar la precisión del pronóstico mediante promedio ponderado y selección dinámica del mejor modelo', 3003, '1.0.0', '1.0.0', '{"modelos_ensemble": ["ARIMA_CLASICO", "SARIMA_ESTACIONAL", "PROPHET_META", "PATRON_CONSUMO"], "pesos": [0.20, 0.30, 0.25, 0.25], "metrica_optimizacion": "MAPE", "ventana_validacion": 30, "seleccion_dinamica": true}'::jsonb, 2002, 1000, 1),
(7, 'KMEANS', 'KMEANS_ABC', 1453, 'Algoritmo K-Means Clustering para clasificación ABC de inventario multicriterio basado en costo, rotación, margen de ganancia y criticidad médica. Genera categorías A (alta prioridad), B (media) y C (baja)', 3001, '1.3.2', '1.3.2', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "n_init": 10, "algorithm": "lloyd", "criterios": ["costo", "rotacion", "margen", "criticidad"], "pesos": [0.30, 0.30, 0.20, 0.20], "etiquetas": ["A", "B", "C"]}'::jsonb, 2002, 1000, 1),
(8, 'CRITICIDAD', 'CLASIFICADOR_CRITICIDAD', 1453, 'Modelo para clasificar productos por nivel de criticidad médica basado en principios activos, uso, disponibilidad en el mercado y sustitutos disponibles', 3001, '1.3.2', '1.3.2', '{"niveles": ["CRITICO", "ALTO", "MEDIO", "BAJO"], "criterios": ["principio_activo", "frecuencia_uso", "disponibilidad", "sustitutos"], "random_state": 42, "pesos": [0.35, 0.30, 0.20, 0.15]}'::jsonb, 2002, 1000, 1),
(9, 'ROP', 'ROP_DINAMICO', 1454, 'Modelo para cálculo dinámico del Punto de Reorden (ROP) basado en demanda promedio histórica, lead time y stock de seguridad ajustable. Fórmula: ROP = (d * L) + SS', 3003, '2.0.0', '2.0.0', '{"lead_time_default": 7, "stock_seguridad_default": 10, "nivel_confianza": 0.95, "metrica_demanda": "media_movil", "ventana_dias": 30, "factor_estacional": true, "ajuste_estacional": 1.2}'::jsonb, 2002, 1000, 1),
(10, 'OPTSTOCK', 'OPTIMIZADOR_STOCK', 1454, 'Modelo de optimización de inventario que calcula niveles óptimos de stock mínimo, máximo y punto de reorden basado en costos de mantener vs. costos de quiebre (modelo EOQ adaptado)', 3003, '1.5.0', '1.5.0', '{"costo_mantener": 0.25, "costo_quiebre": 2.0, "lead_time_dias": 7, "ventana_historica": 180, "nivel_servicio": 0.95, "estacionalidad": true, "factor_estacional": 1.1}'::jsonb, 2002, 1000, 1),
(11, 'OPTCOMPRA', 'OPTIMIZADOR_COMPRAS', 1454, 'Modelo que optimiza las cantidades y fechas de compra considerando precios de proveedores, descuentos por volumen, costos de almacenamiento y restricciones de presupuesto', 3003, '1.0.0', '1.0.0', '{"ventana_optimizacion": 90, "costo_pedido": 50.0, "costo_mantener": 0.25, "descuentos_volumen": [[100, 0.05], [500, 0.10], [1000, 0.15]], "lead_time_proveedor": 5, "presupuesto_mensual": 10000.0, "minimo_pedido": 10}'::jsonb, 2002, 1000, 1),
(12, 'ANOMALIAS', 'DETECTOR_ANOMALIAS', 1455, 'Modelo para detección de anomalías en patrones de consumo, ventas y stock, identificando comportamientos atípicos que requieren atención inmediata (picos, caídas bruscas, estacionalidades rotas)', 3001, '1.3.2', '1.3.2', '{"contamination": 0.05, "n_neighbors": 20, "algorithm": "auto", "metric": "minkowski", "p": 2, "ventana_deteccion": 30, "umbral_anomalia": 0.8, "metodo": "LOF"}'::jsonb, 2002, 1000, 1),
(13, 'ALERTAS', 'ALERTAS_PREDICTIVAS', 1455, 'Modelo para generación de alertas tempranas basadas en desviaciones de los patrones esperados de demanda, stock y vencimientos. Detecta riesgo de quiebre de stock y excesos de inventario', 3003, '1.2.0', '1.2.0', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30, "ventana_historica": 90, "metricas_umbral": ["MAPE", "RMSE", "MAE"], "alertas": ["quiebre_stock", "exceso_stock", "vencimiento_proximo"]}'::jsonb, 2002, 1000, 1);

SELECT setval('modelos_modelo_id_seq', COALESCE((SELECT MAX(modelo_id) FROM modelos), 0), (SELECT COUNT(*) > 0 FROM modelos));

-- ================================================================================================

DELETE FROM entrenamientos;
ALTER SEQUENCE entrenamientos_entrenamiento_id_seq RESTART WITH 1;

INSERT INTO entrenamientos (entrenamiento_id, modelo_id, fecha_ejecucion, fecha_inicio, fecha_fin, estado_ejecucion_id, duracion_segundos, registros_procesados, total_esperado, mensaje_error, estado_id, usuario_id_registro) VALUES
(1, 1, '2026-07-16 14:00:00-04', '2026-07-16 13:55:00-04', '2026-07-16 14:00:00-04', 3051, 300, 15000, 15000, NULL, 1000, 1);

SELECT setval('entrenamientos_entrenamiento_id_seq', COALESCE((SELECT MAX(entrenamiento_id) FROM entrenamientos), 0), (SELECT COUNT(*) > 0 FROM entrenamientos));

-- ================================================================================================

DELETE FROM metricas_rendimiento;
ALTER SEQUENCE metricas_rendimiento_metrica_id_seq RESTART WITH 1;

INSERT INTO metricas_rendimiento (metrica_id, entrenamiento_id, tipo_metrica_id, metrica_precision_id, version_metricas, modelo_version, periodo_evaluacion, error_absoluto_medio, raiz_error_cuadratico_medio, score_principal, detalles_metricas, estado_id, usuario_id_registro) VALUES
(1, 1, 3103, 3600, 1, '0.0.0', CURRENT_DATE, 0.0000, 0.0000, 0.0000, '{"comodin": true}'::jsonb, 1000, 1);

SELECT setval('metricas_rendimiento_metrica_id_seq', COALESCE((SELECT MAX(metrica_id) FROM metricas_rendimiento), 0), (SELECT COUNT(*) > 0 FROM metricas_rendimiento));

-- ================================================================================================

DELETE FROM patrones_consumo;
ALTER SEQUENCE patrones_consumo_patron_id_seq RESTART WITH 1;

INSERT INTO patrones_consumo (patron_id, producto_id, sucursal_id, entrenamiento_id, temporada_id, evento, factor_estacional, coeficiente_tendencia, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1600, 'NINGUNO', 0.00, 0.00, NULL, NULL, 1000, 1);

SELECT setval('patrones_consumo_patron_id_seq', COALESCE((SELECT MAX(patron_id) FROM patrones_consumo), 0), (SELECT COUNT(*) > 0 FROM patrones_consumo));

-- ================================================================================================

DELETE FROM variables_exogenas;
ALTER SEQUENCE variables_exogenas_variable_exogena_id_seq RESTART WITH 1;

INSERT INTO variables_exogenas (variable_exogena_id, producto_id, sucursal_id, fuente_exogena_id, nombre_variable, valor, fecha_variable, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 4250, 'NINGUNO', 0.0000, '2000-01-01', 1000, 1);

SELECT setval('variables_exogenas_variable_exogena_id_seq', COALESCE((SELECT MAX(variable_exogena_id) FROM variables_exogenas), 0), (SELECT COUNT(*) > 0 FROM variables_exogenas));

-- ================================================================================================

DELETE FROM logs_ejecucion;
ALTER SEQUENCE logs_ejecucion_log_id_seq RESTART WITH 1;

INSERT INTO logs_ejecucion (log_id, entrenamiento_id, modulo, nivel_log_id, mensaje, detalle, fecha_log, estado_id, usuario_id_registro) VALUES
(1, 1, 'PROCESAMIENTO_ARIMA', 3150, 'Inicio de analisis estacional', '{"productos": 12, "duracion_seg": 45}'::jsonb, CURRENT_TIMESTAMP, 1000, 1);

SELECT setval('logs_ejecucion_log_id_seq', COALESCE((SELECT MAX(log_id) FROM logs_ejecucion), 0), (SELECT COUNT(*) > 0 FROM logs_ejecucion));

-- ================================================================================================

DELETE FROM analitica_productos;
ALTER SEQUENCE analitica_productos_analitica_id_seq RESTART WITH 1;

INSERT INTO analitica_productos (analitica_id, producto_id, sucursal_id, demanda_pronosticada, intervalo_inf, intervalo_sup, fecha_prediccion, periodo_inicio, periodo_fin, fecha_vencimiento_critico, nivel_urgencia_id, punto_reorden, stock_seguridad, lead_time_dias, cluster_abc, fecha_clasificacion, puntaje_total, estado_pronostico_id, motivo_outlier_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 120.50, 100.00, 140.00, CURRENT_TIMESTAMP, '2026-08-01', '2026-08-31', '2027-01-15', 1854, 45.00, 15.00, 5, 0, CURRENT_DATE, 85.50, 1553, NULL, 1000, 1);

SELECT setval('analitica_productos_analitica_id_seq', COALESCE((SELECT MAX(analitica_id) FROM analitica_productos), 0), (SELECT COUNT(*) > 0 FROM analitica_productos));

-- ================================================================================================

DELETE FROM pedidos_online;
ALTER SEQUENCE pedidos_online_pedido_online_id_seq RESTART WITH 1;

INSERT INTO pedidos_online (pedido_online_id, cliente_id, sucursal_id, kardex_id, codigo, fecha_pedido, fecha_entrega_estimada, fecha_entrega_real, direccion_entrega, telefono_contacto, instrucciones_entrega, estado_pedido_online_id, estado_pago_id, subtotal, costo_envio, descuentos, total, ultima_actualizacion, observacion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'WEB-0000', CURRENT_TIMESTAMP, NULL, NULL, 'NINGUNO', '00000000', NULL, 3700, 2555, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 1000, 1);

SELECT setval('pedidos_online_pedido_online_id_seq', COALESCE((SELECT MAX(pedido_online_id) FROM pedidos_online), 0), (SELECT COUNT(*) > 0 FROM pedidos_online));

-- ================================================================================================

DELETE FROM detalles_pedidos_online;
ALTER SEQUENCE detalles_pedidos_online_detalle_pedido_online_id_seq RESTART WITH 1;

INSERT INTO detalles_pedidos_online (detalle_pedido_online_id, pedido_online_id, producto_id, kardex_producto_id, codigo_producto, nombre_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'NIN', 'NINGUNO', 1.00, 0.00, 0.00, 0.00, 1000, 1);

SELECT setval('detalles_pedidos_online_detalle_pedido_online_id_seq', COALESCE((SELECT MAX(detalle_pedido_online_id) FROM detalles_pedidos_online), 0), (SELECT COUNT(*) > 0 FROM detalles_pedidos_online));

-- ================================================================================================

DELETE FROM carritos_compra;
ALTER SEQUENCE carritos_compra_carrito_id_seq RESTART WITH 1;

INSERT INTO carritos_compra (carrito_id, sucursal_id, cliente_id, fecha_creacion, fecha_actualizacion_carrito, fecha_expiracion, cliente_nombre, cliente_documento, total_items, subtotal, estado_carrito_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', 'NINGUNO', '0', 0, 0.00, 4906, 1000, 1);

SELECT setval('carritos_compra_carrito_id_seq', COALESCE((SELECT MAX(carrito_id) FROM carritos_compra), 0), (SELECT COUNT(*) > 0 FROM carritos_compra));

-- ================================================================================================

DELETE FROM detalles_carritos;
ALTER SEQUENCE detalles_carritos_detalle_carrito_id_seq RESTART WITH 1;

INSERT INTO detalles_carritos (detalle_carrito_id, carrito_id, producto_id, codigo_producto, nombre_producto, presentacion_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NIN', 'NINGUNO', NULL, 1.00, 0.00, 0.00, 0.00, 1000, 1);

SELECT setval('detalles_carritos_detalle_carrito_id_seq', COALESCE((SELECT MAX(detalle_carrito_id) FROM detalles_carritos), 0), (SELECT COUNT(*) > 0 FROM detalles_carritos));

-- ================================================================================================

DELETE FROM listas_precios;
ALTER SEQUENCE listas_precios_lista_precio_id_seq RESTART WITH 1;

INSERT INTO listas_precios (lista_precio_id, codigo, nombre, descripcion, es_publica, prioridad, requiere_autorizacion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'Lista de precios predeterminada para productos sin clasificar', 0, 999, 0, 1000, 1);

SELECT setval('listas_precios_lista_precio_id_seq', COALESCE((SELECT MAX(lista_precio_id) FROM listas_precios), 0), (SELECT COUNT(*) > 0 FROM listas_precios));

-- ================================================================================================

DELETE FROM precios_productos;
ALTER SEQUENCE precios_productos_precio_producto_id_seq RESTART WITH 1;

INSERT INTO precios_productos (precio_producto_id, producto_id, lista_precio_id, precio_base, precio_oferta, precio_minimo, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, NULL, NULL, '2000-01-01', NULL, 1000, 1);

SELECT setval('precios_productos_precio_producto_id_seq', COALESCE((SELECT MAX(precio_producto_id) FROM precios_productos), 0), (SELECT COUNT(*) > 0 FROM precios_productos));

-- ================================================================================================

DELETE FROM costos_promedio;
ALTER SEQUENCE costos_promedio_costo_promedio_id_seq RESTART WITH 1;

INSERT INTO costos_promedio (costo_promedio_id, producto_id, costo_promedio, costo_ultima_compra, fecha_calculo, metodo_calculo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0.00, NULL, '2000-01-01', 3750, 1000, 1);

SELECT setval('costos_promedio_costo_promedio_id_seq', COALESCE((SELECT MAX(costo_promedio_id) FROM costos_promedio), 0), (SELECT COUNT(*) > 0 FROM costos_promedio));

-- ================================================================================================

DELETE FROM politicas_precios;
ALTER SEQUENCE politicas_precios_politica_precio_id_seq RESTART WITH 1;

INSERT INTO politicas_precios (politica_precio_id, codigo, nombre, tipo_aplicacion_id, entidad_id, margen_minimo, margen_maximo, redondeo, aplica_descuentos, descuento_maximo, estado_id, usuario_id_registro) VALUES
(1, 'GLOBAL', 'POLÍTICA GLOBAL POR DEFECTO', 4350, NULL, 0.00, 100.00, 0, 1, 0.00, 1000, 1);

SELECT setval('politicas_precios_politica_precio_id_seq', COALESCE((SELECT MAX(politica_precio_id) FROM politicas_precios), 0), (SELECT COUNT(*) > 0 FROM politicas_precios));

-- ================================================================================================

DELETE FROM asistencias;
ALTER SEQUENCE asistencias_asistencia_id_seq RESTART WITH 1;

INSERT INTO asistencias (asistencia_id, trabajador_id, sucursal_id, fecha, hora_entrada, hora_salida, hora_entrada_almuerzo, hora_salida_almuerzo, horas_trabajadas, horas_extras, tipo_asistencia_id, estado_asistencia_id, metodo_marcacion_id, dispositivo, ip_origen, observaciones, justificacion, justificacion_archivo, usuario_registro_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, NULL, NULL, 0.00, 0.00, 4400, 4450, 4500, NULL, NULL, 'REGISTRO COMODIN INICIAL', NULL, NULL, 1, 1000, 1);

SELECT setval('asistencias_asistencia_id_seq', COALESCE((SELECT MAX(asistencia_id) FROM asistencias), 0), (SELECT COUNT(*) > 0 FROM asistencias));

-- ================================================================================================

DELETE FROM planillas;
ALTER SEQUENCE planillas_planilla_id_seq RESTART WITH 1;

INSERT INTO planillas (planilla_id, sucursal_id, periodo_mes, periodo_gestion, fecha_inicio, fecha_fin, tipo_planilla_id, estado_planilla_id, estado_id, usuario_id_registro)
VALUES (1, 1, 1, 2026, '2026-01-01', '2026-01-31', 4600, 4650, 1000, 1);

SELECT setval('planillas_planilla_id_seq', COALESCE((SELECT MAX(planilla_id) FROM planillas), 0), (SELECT COUNT(*) > 0 FROM planillas));

-- ================================================================================================

DELETE FROM planillas_detalle;
ALTER SEQUENCE planillas_detalle_planilla_detalle_id_seq RESTART WITH 1;

INSERT INTO planillas_detalle (planilla_detalle_id, planilla_id, trabajador_id, cargo_id, sueldo_base, dias_trabajados, total_ingresos, neto_pagar, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 0.00, 0, 0.00, 0.00, 1000, 1);

SELECT setval('planillas_detalle_planilla_detalle_id_seq', COALESCE((SELECT MAX(planilla_detalle_id) FROM planillas_detalle), 0), (SELECT COUNT(*) > 0 FROM planillas_detalle));

-- ================================================================================================

DELETE FROM contratos;
ALTER SEQUENCE contratos_contrato_id_seq RESTART WITH 1;

INSERT INTO contratos (contrato_id, trabajador_id, tipo_contrato_id, fecha_inicio, sueldo_base, moneda_sueldo_id, tipo_jornada_id, estado_contrato_id, estado_id, usuario_id_registro)
VALUES (1, 1, 4750, CURRENT_DATE, 0.00, 2300, 4800, 4700, 1000, 1);

SELECT setval('contratos_contrato_id_seq', COALESCE((SELECT MAX(contrato_id) FROM contratos), 0), (SELECT COUNT(*) > 0 FROM contratos));

-- ================================================================================================

DELETE FROM historicos;
ALTER SEQUENCE historicos_historico_id_seq RESTART WITH 1;

INSERT INTO historicos (historico_id, kardex_id, cliente_id, sucursal_id, empresa_id, cliente_nombre, cliente_documento, cliente_documento_complemento, cliente_tipo_documento_abreviatura, cliente_razon_social, cliente_direccion, cliente_telefono, cliente_email, sucursal_nombre, sucursal_codigo, sucursal_telefono, sucursal_ubicacion, sucursal_codigo_sin, sucursal_punto_venta, empresa_nombre, empresa_codigo, empresa_nit, empresa_autorizacion, empresa_actividad_economica, numero_factura, fecha_emision, tipo_comprobante_abreviatura, tipo_factura_abreviatura, lugar_entrega, items, subtotal, descuento_total, iva, total, total_pagado, total_cambio, metodo_pago_abreviatura, tipo_moneda_abreviatura, factor_cambio, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 'NINGUNO', '0', NULL, 'NINGUNO', NULL, NULL, NULL, NULL, 'NINGUNO', 'NIN', NULL, NULL, 0, 0, 'NINGUNA', 'NIN', '000000000', '00000000000000000000', NULL, '0000000', '2026-01-01', 'NINGUNO', 'NINGUNO', NULL, '[]'::jsonb, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 'E', 'BOB', 1.0000, 1000, 1);

SELECT setval('historicos_historico_id_seq', COALESCE((SELECT MAX(historico_id) FROM historicos), 0), (SELECT COUNT(*) > 0 FROM historicos));

-- ================================================================================================
