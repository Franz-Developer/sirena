
-- ================================================================================================
DELETE FROM bancos;
ALTER SEQUENCE bancos_banco_id_seq RESTART WITH 1;

INSERT INTO bancos (banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', '99', 'NIN', 1000, 1),
(2, 'BANCO NACIONAL DE BOLIVIA S.A.', '01', 'BNB', 1000, 1),
(3, 'BANCO MERCANTIL SANTA CRUZ S.A.', '02', 'BMSC', 1000, 1),
(4, 'BANCO BISA S.A.', '03', 'BISA', 1000, 1),
(5, 'BANCO DE CREDITO DE BOLIVIA S.A.', '04', 'BCB', 1000, 1),
(6, 'BANCO ECONOMICO S.A.', '05', 'BEC', 1000, 1),
(7, 'BANCO GANADERO S.A.', '06', 'BGA', 1000, 1),
(8, 'BANCO SOLIDARIO S.A.', '07', 'BSO', 1000, 1),
(9, 'BANCO UNION S.A.', '08', 'BUN', 1000, 1),
(10, 'BANCO FIE S.A.', '09', 'FIE', 1000, 1),
(11, 'BANCO PRODEM S.A.', '10', 'PRD', 1000, 1),
(12, 'BANCO PYME ECOFUTURO S.A.', '11', 'ECO', 1000, 1),
(13, 'BANCO PYME DE LA COMUNIDAD S.A.', '12', 'BCO', 1000, 1);

UPDATE bancos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE bancos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

-- ================================================================================================
DELETE FROM tipos_cambios;
ALTER SEQUENCE tipos_cambios_tipo_cambio_id_seq RESTART WITH 1;

INSERT INTO tipos_cambios (tipo_cambio_id, origen_moneda_id, destino_moneda_id, factor_compra, factor_venta, fecha_cotizacion, estado_id, usuario_id_registro) VALUES
(1, 2300, 2301, 1.0000, 1.0000, '2099-12-31', 1000, 1),
(2, 2300, 2301, 6.8600, 6.9600, '2026-07-01', 1000, 1),
(3, 2300, 2301, 6.8600, 6.9600, '2026-07-02', 1000, 1),
(4, 2300, 2301, 6.8600, 6.9600, '2026-07-03', 1000, 1),
(5, 2300, 2301, 6.8600, 6.9600, '2026-07-04', 1000, 1),
(6, 2300, 2301, 6.8600, 6.9600, '2026-07-05', 1000, 1),
(7, 2300, 2301, 6.8600, 6.9600, '2026-07-06', 1000, 1),
(8, 2300, 2301, 6.8600, 6.9600, '2026-07-07', 1000, 1),
(9, 2300, 2301, 6.8600, 6.9600, '2026-07-08', 1000, 1),
(10, 2300, 2301, 6.8600, 6.9600, '2026-07-09', 1000, 1),
(11, 2300, 2301, 6.8600, 6.9600, '2026-07-10', 1000, 1),
(12, 2300, 2301, 6.8600, 6.9600, '2026-07-11', 1000, 1),
(13, 2300, 2301, 6.8600, 6.9600, '2026-07-12', 1000, 1),
(14, 2300, 2301, 6.8600, 6.9600, '2026-07-13', 1000, 1),
(15, 2300, 2301, 6.8600, 6.9600, '2026-07-14', 1000, 1),
(16, 2300, 2301, 6.8600, 6.9600, '2026-07-15', 1000, 1),
(17, 2300, 2301, 6.8600, 6.9600, '2026-07-16', 1000, 1),
(18, 2300, 2301, 6.8600, 6.9600, '2026-07-17', 1000, 1),
(19, 2300, 2301, 6.8600, 6.9600, '2026-07-18', 1000, 1),
(20, 2300, 2301, 6.8600, 6.9600, '2026-07-19', 1000, 1),
(21, 2300, 2301, 6.8600, 6.9600, '2026-07-20', 1000, 1),
(22, 2300, 2301, 6.8600, 6.9600, '2026-07-21', 1000, 1),
(23, 2300, 2301, 6.8600, 6.9600, '2026-07-22', 1000, 1),
(24, 2300, 2301, 6.8600, 6.9600, '2026-07-23', 1000, 1),
(25, 2300, 2301, 6.8600, 6.9600, '2026-07-24', 1000, 1),
(26, 2300, 2301, 6.8600, 6.9600, '2026-07-25', 1000, 1),
(27, 2300, 2301, 6.8600, 6.9600, '2026-07-26', 1000, 1),
(28, 2300, 2301, 6.8600, 6.9600, '2026-07-27', 1000, 1),
(29, 2300, 2301, 6.8600, 6.9600, '2026-07-28', 1000, 1),
(30, 2300, 2301, 6.8600, 6.9600, '2026-07-29', 1000, 1),
(31, 2300, 2301, 6.8600, 6.9600, '2026-07-30', 1000, 1),
(32, 2300, 2301, 6.8600, 6.9600, '2026-07-31', 1000, 1);

UPDATE tipos_cambios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_cambios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_cambios_tipo_cambio_id_seq', COALESCE((SELECT MAX(tipo_cambio_id) FROM tipos_cambios), 0), (SELECT COUNT(*) > 0 FROM tipos_cambios));

-- ================================================================================================
DELETE FROM empresas;
ALTER SEQUENCE empresas_empresa_id_seq RESTART WITH 1;

INSERT INTO empresas (empresa_id, empresa, codigo, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', '1.jpg', NULL, NULL, NULL, 'ADMIN', 'DIRECCION NINGUNA', '00000000', 'ninguna@gmail.com', 'MAT-000', 1000, 1),
(2, 'FARMACIA SALUD Y VIDA S.R.L.', '309', '2.jpg', 'Tu salud es nuestra prioridad', 'Venta de medicamentos', 'LA PAZ - BOLIVIA', 'JUAN PEREZ FLORES', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '22441122', 'central@saludyvida.com.bo', 'M-356981', 1000, 1);

UPDATE empresas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_empresa_id_seq', COALESCE((SELECT MAX(empresa_id) FROM empresas), 0), (SELECT COUNT(*) > 0 FROM empresas));

-- ================================================================================================
DELETE FROM empresas_nits;
ALTER SEQUENCE empresas_nits_empresa_nit_id_seq RESTART WITH 1;

INSERT INTO empresas_nits (empresa_nit_id, empresa_id, ambiente_id, nit, razon_social, actividad_economica_principal, modalidad_facturacion_id, certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id, usuario_id_registro) VALUES
(1, 1, 2751, '0000000', 'NINGUNO', 'NINGUNA', 3900, NULL, NULL, NULL, NULL, NULL, 'ninguno@ninguno.com', 1000, 1);

UPDATE empresas_nits SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_nits SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_nits_empresa_nit_id_seq', COALESCE((SELECT MAX(empresa_nit_id) FROM empresas_nits), 0), (SELECT COUNT(*) > 0 FROM empresas_nits));

-- ================================================================================================
DELETE FROM empresas_cuentas;
ALTER SEQUENCE empresas_cuentas_empresa_cuenta_id_seq RESTART WITH 1;

INSERT INTO empresas_cuentas (empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id, nro_cuenta, tipo_cuenta_id, titular, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 2300, '0000000000', 1755, 'NINGUNO', 1000, 1);

UPDATE empresas_cuentas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE empresas_cuentas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('empresas_cuentas_empresa_cuenta_id_seq', COALESCE((SELECT MAX(empresa_cuenta_id) FROM empresas_cuentas), 0), (SELECT COUNT(*) > 0 FROM empresas_cuentas));

-- ================================================================================================
DELETE FROM sucursales;
ALTER SEQUENCE sucursales_sucursal_id_seq RESTART WITH 1;

INSERT INTO sucursales (sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', 'NIN', 0, '00000000', 'DIRECCION NINGUNA', '00:00 - 00:00', 1.50, 1.19, 1000, 1),
(2, 2, 'CASA MATRIZ - SOPOCACHI', 'FARMACIA SALUD Y VIDA - CASA MATRIZ SOPOCACHI', 'FSM', 0, '22441122', 'AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ', '08:00 - 22:00', 1.50, 1.19, 1000, 1),
(3, 2, 'SUCURSAL ZONA SUR', 'FARMACIA SALUD Y VIDA - SUCURSAL ZONA SUR CALACOTO', 'FSZ', 1, '22774433', 'AV. BALLIVIAN NRO. 540, CALACOTO, LA PAZ', '08:00 - 23:00', 1.50, 1.19, 1000, 1);

UPDATE sucursales SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE sucursales SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('sucursales_sucursal_id_seq', COALESCE((SELECT MAX(sucursal_id) FROM sucursales), 0), (SELECT COUNT(*) > 0 FROM sucursales));

-- ================================================================================================
DELETE FROM puntos_venta;
ALTER SEQUENCE puntos_venta_punto_venta_id_seq RESTART WITH 1;

INSERT INTO puntos_venta (punto_venta_id, sucursal_id, codigo_punto_venta, descripcion, tipo_punto_venta_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0, 'NINGUNO', 3950, 1000, 1),
(2, 2, 0, 'CAJA PRINCIPAL - SOPOCACHI', 3951, 1000, 1),
(3, 2, 1, 'CAJA SECUNDARIA - SOPOCACHI', 3951, 1000, 1),
(4, 3, 0, 'CAJA PRINCIPAL - ZONA SUR', 3951, 1000, 1);

UPDATE puntos_venta SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE puntos_venta SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('puntos_venta_punto_venta_id_seq', COALESCE((SELECT MAX(punto_venta_id) FROM puntos_venta), 0), (SELECT COUNT(*) > 0 FROM puntos_venta));

-- ================================================================================================
DELETE FROM cuis;
ALTER SEQUENCE cuis_cuis_id_seq RESTART WITH 1;

INSERT INTO cuis (cuis_id, sucursal_id, punto_venta_id, codigo_cuis, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1);

UPDATE cuis SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cuis SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cuis_cuis_id_seq', COALESCE((SELECT MAX(cuis_id) FROM cuis), 0), (SELECT COUNT(*) > 0 FROM cuis));

-- ================================================================================================
DELETE FROM cufd;
ALTER SEQUENCE cufd_cufd_id_seq RESTART WITH 1;

INSERT INTO cufd (cufd_id, sucursal_id, punto_venta_id, codigo_cufd, codigo_control, fecha_vigencia, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 'NINGUNO', 'NINGUNO', '2099-12-31 23:59:59-04', 1000, 1);

UPDATE cufd SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cufd SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cufd_cufd_id_seq', COALESCE((SELECT MAX(cufd_id) FROM cufd), 0), (SELECT COUNT(*) > 0 FROM cufd));

-- ================================================================================================
DELETE FROM almacenes;
ALTER SEQUENCE almacenes_almacen_id_seq RESTART WITH 1;

INSERT INTO almacenes (almacen_id, sucursal_id, almacen, codigo, tipo_almacen_id, tipo_operacion_almacen_id, descripcion, temperatura_min, temperatura_max, humedad_min, humedad_max, unidad_temperatura_id, unidad_humedad_id, estado_id, usuario_id_registro) VALUES 
(1, 1, 'NINGUNO', 'NIN', 1700, 4050, 'ALMACEN COMODIN', NULL, NULL, NULL, NULL, 4850, 4900, 1000, 1);

UPDATE almacenes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_almacen_id_seq', COALESCE((SELECT MAX(almacen_id) FROM almacenes), 0), (SELECT COUNT(*) > 0 FROM almacenes));

-- ================================================================================================

- Ubicación en estantería:
  {
    "niveles": [
      {"tipo": "PASILLO", "valor": "01"},
      {"tipo": "ESTANTERIA", "valor": "B"},
      {"tipo": "NIVEL", "valor": "03"},
      {"tipo": "POSICION", "valor": "A"}
    ],
    "camino": "PASILLO 01 > ESTANTERIA B > NIVEL 03 > POSICION A"
  }
- Ubicación en refrigerador:
  {
    "niveles": [
      {"tipo": "REFRIGERADOR", "valor": "REF-01"},
      {"tipo": "BANDEJA", "valor": "02"},
      {"tipo": "POSICION", "valor": "CENTRAL"}
    ],
    "camino": "REFRIGERADOR REF-01 > BANDEJA 02 > POSICION CENTRAL"
  }
- Ubicación simple (sin jerarquía):
  {
    "simplificado": true,
    "valor": "VITRINA-A-01"
  }
La estructura debe cumplir con el formato definido. El backend es responsable de validar la coherencia de la jerarquía y de generar el campo "camino" para la visualización rápida en el frontend.

DELETE FROM ubicaciones;
ALTER SEQUENCE ubicaciones_ubicacion_id_seq RESTART WITH 1;

INSERT INTO ubicaciones (ubicacion_id, almacen_id, codigo, jerarquia, descripcion, capacidad_maxima, stock_actual, umbral_minimo, metadata, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', '{"simplificado": true, "valor": "COMODIN", "camino": "COMODIN"}'::jsonb, 'UBICACION COMODIN', 0.00, 0.00, 0.00, NULL, 1000, 1);

UPDATE ubicaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_ubicacion_id_seq', COALESCE((SELECT MAX(ubicacion_id) FROM ubicaciones), 0), (SELECT COUNT(*) > 0 FROM ubicaciones));

-- ================================================================================================

DELETE FROM almacenes_puntos_venta;
ALTER SEQUENCE almacenes_puntos_venta_almacen_punto_venta_id_seq RESTART WITH 1;

INSERT INTO almacenes_puntos_venta (almacen_punto_venta_id, almacen_id, punto_venta_id, prioridad, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1000, 1);

UPDATE almacenes_puntos_venta SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE almacenes_puntos_venta SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('almacenes_puntos_venta_almacen_punto_venta_id_seq', COALESCE((SELECT MAX(almacen_punto_venta_id) FROM almacenes_puntos_venta), 0), (SELECT COUNT(*) > 0 FROM almacenes_puntos_venta));

-- ================================================================================================

DELETE FROM cargos;
ALTER SEQUENCE cargos_cargo_id_seq RESTART WITH 1;

INSERT INTO cargos (cargo_id, cargo, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NIN', 'CARGO COMODIN', 1000, 1),
(2, 'ADMINISTRADOR DEL SISTEMA', 'ADMIN', 'Gestión integral, configuración y control total de la plataforma.', 1000, 1),
(3, 'GERENTE GENERAL', 'GER_GEN', 'Dirección estratégica y toma de decisiones corporativas.', 1000, 1),
(4, 'ADMINISTRADOR DE SUCURSAL', 'ADMIN_SUC', 'Supervisión de inventarios, dispensación y control de almacenes.', 1000, 1),
(5, 'CONTADOR', 'CONT', 'Contabilidad.', 1000, 1),
(6, 'COMPRAS', 'COMP', 'Encargado de compras.', 1000, 1),
(7, 'VENTAS', 'VENT', 'Encargado de ventas.', 1000, 1),
(8, 'INVENTARIO', 'INV', 'Encargado del inventario.', 1000, 1),
(9, 'MENSAJERO', 'MENS', 'Encargado de mensajeria.', 1000, 1);

UPDATE cargos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cargos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cargos_cargo_id_seq', COALESCE((SELECT MAX(cargo_id) FROM cargos), 0), (SELECT COUNT(*) > 0 FROM cargos));

-- ================================================================================================

DELETE FROM trabajadores;
ALTER SEQUENCE trabajadores_trabajador_id_seq RESTART WITH 1;

INSERT INTO trabajadores (trabajador_id, genero_id, estado_civil_id, nombres, paterno, materno, dni, telefono, email, fecha_nacimiento, fecha_contratacion, foto, qr, estado_id, usuario_id_registro) VALUES
(1, 1200, 1250, 'NINGUNO', 'NINGUNO', NULL, '0000000', NULL, NULL, NULL, NULL, '1.jpg', '1.png', 1000, 1),
(2, 1200, 1251, 'FRANZ', 'IBAÑEZ', NULL, '2630198', '60241524', 'franz.ibanez.c@gmail.com', '1980-06-24', NULL, '2.jpg', '2.png', 1000, 1),
(3, 1200, 1250, 'PASCUAL', 'QUISPE', 'HUANCA', '4892014', '70541489', 'pascual.q.h@hotmail.com', '1982-01-27', NULL, '3.png', '3.png', 1000, 1),
(4, 1201, 1301, 'GLADYS', 'ALANOCA', NULL, '3482910', '60241524', 'gladys.alanoca@gmail.com', '1980-06-24', NULL, '4.jpg', '4.png', 1000, 1),
(5, 1201, 1300, 'SILVIA', 'QUISPE', NULL, '6105824', '65201478', 'silvia.quispe@outlook.com', '1976-04-01', NULL, '5.jpg', '5.png', 1000, 1),
(6, 1200, 1250, 'JUAN PABLO', 'HIDALGO', 'HUANCA', '8342915', '71524311', 'jphidalgo.h@gmail.com', '1988-09-15', NULL, '6.jpg', '6.png', 1000, 1),
(7, 1200, 1250, 'MARCELO', 'VARGAS', 'FLORES', '5920147', '72014589', 'marcelovargas.f@hotmail.com', '1985-11-03', NULL, '7.jpg', '7.png', 1000, 1),
(8, 1201, 1301, 'BEATRIZ', 'MENDOZA', 'ROJAS', '12409581', '60112233', 'beatriz.mendoza.r@gmail.com', '1993-03-22', NULL, '8.png', '8.png', 1000, 1),
(9, 1201, 1300, 'CARLA', 'LOPEZ', 'ESTRADA', '7301948', '60581422', 'carla.lopez.e@gmail.com', '1991-05-14', NULL, '9.jpg', '9.png', 1000, 1),
(10, 1200, 1250, 'RODRIGO', 'APAZA', 'MAMANI', '4910283', '70611224', 'rodrigo.apaza@hotmail.com', '1989-12-08', NULL, '10.jpg', '10.png', 1000, 1),
(11, 1200, 1251, 'HECTOR', 'CONDO', 'ALANOCA', '5432109', '71254896', 'hector.condo@gmail.com', '1984-07-19', NULL, '11.jpg', '11.png', 1000, 1),
(12, 1201, 1300, 'PATRICIA', 'CHAVEZ', 'SOLIZ', '6198420', '65124578', 'patricia.chavez@outlook.com', '1995-10-02', NULL, '12.jpg', '12.png', 1000, 1),
(13, 1200, 1250, 'DIEGO', 'PINTO', 'GUTIERREZ', '8412975', '73021456', 'gustavo.pinto@gmail.com', '1992-04-30', NULL, '13.jpg', '13.png', 1000, 1),
(14, 1201, 1300, 'MONICA', 'SILES', 'ORELLANA', '9120843', '60145879', 'monica.siles@hotmail.com', '1990-02-15', NULL, '14.jpg', '14.png', 1000, 1),
(15, 1201, 1301, 'VALERIA', 'RIVERA', 'CRUZ', '3490218', '71954823', 'valeria.rivera.c@gmail.com', '1987-11-25', NULL, '15.png', '15.png', 1000, 1),
(16, 1200, 1250, 'ALEXANDER', 'QUISPE', 'CHOQUE', '7891234', '71589632', 'alexander.quispe@gmail.com', '2000-05-12', NULL, '16.jpg', '16.png', 1000, 1),
(17, 1200, 1250, 'KEVIN', 'MAMANI', 'FLORES', '6547891', '72036541', 'kevin.mamani@hotmail.com', '2002-08-19', NULL, '17.jpg', '17.png', 1000, 1);

UPDATE trabajadores SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE trabajadores SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('trabajadores_trabajador_id_seq', COALESCE((SELECT MAX(trabajador_id) FROM trabajadores), 0), (SELECT COUNT(*) > 0 FROM trabajadores));

-- ================================================================================================

DELETE FROM trabajadores_cargos;
ALTER SEQUENCE trabajadores_cargos_trabajador_cargo_id_seq RESTART WITH 1;

INSERT INTO trabajadores_cargos (trabajador_cargo_id, trabajador_id, cargo_id, sueldo_base, tipo_moneda_id, es_activo, estado_id, usuario_id_registro) VALUES
(1, 2, 2, 8000.00, 2300, 1, 1000, 1),
(2, 3, 4, 6000.00, 2300, 1, 1000, 1),
(3, 4, 5, 5500.00, 2300, 1, 1000, 1),
(4, 5, 4, 6000.00, 2300, 1, 1000, 1),
(5, 6, 7, 3500.00, 2300, 1, 1000, 1),
(6, 7, 8, 4000.00, 2300, 1, 1000, 1),
(7, 8, 8, 4000.00, 2300, 1, 1000, 1),
(8, 9, 7, 3500.00, 2300, 1, 1000, 1),
(9, 10, 8, 4000.00, 2300, 1, 1000, 1),
(10, 11, 8, 4000.00, 2300, 1, 1000, 1),
(11, 12, 6, 4500.00, 2300, 1, 1000, 1),
(12, 13, 7, 3500.00, 2300, 1, 1000, 1),
(13, 14, 8, 4000.00, 2300, 1, 1000, 1),
(14, 15, 3, 15000.00, 2300, 1, 1000, 1),
(15, 16, 9, 3000.00, 2300, 1, 1000, 1),
(16, 17, 9, 3000.00, 2300, 1, 1000, 1);

UPDATE trabajadores_cargos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE trabajadores_cargos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('trabajadores_cargos_trabajador_cargo_id_seq', COALESCE((SELECT MAX(trabajador_cargo_id) FROM trabajadores_cargos), 0), (SELECT COUNT(*) > 0 FROM trabajadores_cargos));

-- ================================================================================================

DELETE FROM roles;
ALTER SEQUENCE roles_rol_id_seq RESTART WITH 1;

INSERT INTO roles (rol_id, codigo, rol, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO DEL SISTEMA', 1000, 1),
(2, 'ADM', 'ADMINISTRADOR', 'Control total de la plataforma sirena acceso a todo, tiene todos los permisos', 1000, 1),
(3, 'GER', 'GERENTE', 'Control y acceso a todos los modulos pero solo de lectura', 1000, 1),
(4, 'SUC', 'ENCARGADO DE SUCURSAL', 'Responsable de la supervision, operaciones y arqueos de una sucursal especifica', 1000, 1),
(5, 'COM', 'COMPRADOR', 'Responsable de la gestion de proveedores, ordenes de compra y adquisiciones', 1000, 1),
(6, 'VEN', 'VENDEDOR', 'Responsable de la atencion a clientes, cotizaciones y registro de ventas', 1000, 1),
(7, 'ALM', 'ALMACENERO', 'Responsable de la recepcion de mercaderia, control de stock, ingresos y salidas de almacen', 1000, 1),
(8, 'CAJ', 'CAJERO', 'Responsable de la recepcion de pagos, facturacion y apertura/cierre de caja chica', 1000, 1);

UPDATE roles SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_rol_id_seq', COALESCE((SELECT MAX(rol_id) FROM roles), 0), (SELECT COUNT(*) > 0 FROM roles));

-- ================================================================================================

R:6: Un usuario no se puede BORRAR solo se cambia a HISTORICO';

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
    1000, 1 
FROM (
    VALUES 
    ('constantes'), ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones')
) AS t(tabla);

-- ROL: GERENTE (rol_id = 3) - SOLO LECTURA
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro)
SELECT 
    3, 
    t.tabla, 
    1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1 
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
    1000, 1 
FROM (
    VALUES 
    ('constantes'), ('bancos'), ('tipos_cambios'), ('empresas'), ('empresas_nits'), ('empresas_cuentas'), ('sucursales'), ('puntos_venta'), ('cuis'), ('cufd'), ('almacenes'), ('ubicaciones'), ('almacenes_puntos_venta'), ('cargos'), ('trabajadores'), ('trabajadores_cargos'), ('roles'), ('usuarios'), ('menus'), ('roles_menus'), ('inventarios_fisicos'), ('clientes'), ('categorias'), ('unidades'), ('laboratorios'), ('formas'), ('presentaciones'), ('concentraciones'), ('vias'), ('rangos_edad'), ('marcas'), ('productos'), ('productos_vias'), ('equivalentes'), ('productos_rangos_edad'), ('productos_ubicaciones'), ('principios_activos'), ('productos_principios'), ('registros_sanitarios'), ('productos_controlados'), ('promociones'), ('promociones_productos'), ('conversiones_unidad'), ('proveedores'), ('proveedores_contactos'), ('proveedores_rating_historico'), ('parametros_globales'), ('tareas_programadas'), ('control_facturas'), ('kardex'), ('ordenes_compra'), ('instituciones'), ('especialidades'), ('medicos'), ('recetas'), ('lotes_productos'), ('kardex_productos'), ('inventarios_fisicos_detalle'), ('ubicaciones_movimientos'), ('ubicaciones_historial'), ('tipos_planes_pago'), ('planes_pagos'), ('comprobantes_pagos'), ('pagos'), ('cajas'), ('movimientos'), ('arqueos_detalle'), ('alertas_notificaciones'), ('modelos'), ('entrenamientos'), ('metricas_rendimiento'), ('patrones_consumo'), ('variables_exogenas'), ('umbrales_configuracion'), ('logs_ejecucion'), ('analitica_productos'), ('pedidos_online'), ('detalles_pedidos_online'), ('carritos_compra'), ('detalles_carritos'), ('listas_precios'), ('precios_productos'), ('costos_promedio'), ('politicas_precios'), ('asistencias'), ('planillas'), ('planillas_detalle'), ('contratos'), ('historicos'), ('configuraciones'), ('tablas')
) AS t(tabla);

-- ROL: COMPRADOR (rol_id = 5) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(5, 'proveedores', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'proveedores_contactos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'proveedores_rating_historico', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1050, 1058], "editar": []}'::jsonb, 1000, 1),
(5, 'ordenes_compra', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'parametros_globales', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'tareas_programadas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'tipos_planes_pago', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'planes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'comprobantes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(5, 'pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: VENDEDOR (rol_id = 6) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(6, 'clientes', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'productos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1051, 1052, 1059], "editar": [1051]}'::jsonb, 1000, 1),
(6, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'pedidos_online', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'detalles_pedidos_online', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'carritos_compra', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'detalles_carritos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'listas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'precios_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'politicas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'cajas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(6, 'movimientos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: ALMACENERO (rol_id = 7) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(7, 'almacenes', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'ubicaciones', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'almacenes_puntos_venta', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'productos_ubicaciones', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1053, 1054, 1056, 1057, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070], "editar": []}'::jsonb, 1000, 1),
(7, 'lotes_productos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'ubicaciones_movimientos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'ubicaciones_historial', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'inventarios_fisicos_detalle', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'inventarios_fisicos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'umbrales_configuracion', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(7, 'analitica_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

-- ROL: CAJERO (rol_id = 8) - SIN ANULAR
INSERT INTO roles_tablas (rol_id, tabla, leer, crear, editar, eliminar, anular, archivar, desarchivar, eventos_permitidos, estado_id, usuario_id_registro) VALUES
(8, 'clientes', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'kardex', 1, 1, 0, 0, 0, 0, 0, '{"crear": [1051], "editar": []}'::jsonb, 1000, 1),
(8, 'kardex_productos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'control_facturas', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'comprobantes_pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'pagos', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'cajas', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'movimientos', 1, 1, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'arqueos_detalle', 1, 1, 1, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'bancos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'listas_precios', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1),
(8, 'precios_productos', 1, 0, 0, 0, 0, 0, 0, '{}'::jsonb, 1000, 1);

UPDATE roles_tablas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles_tablas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_tablas_rol_tabla_id_seq', COALESCE((SELECT MAX(rol_tabla_id) FROM roles_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_tablas));

-- ================================================================================================

DELETE FROM menus;
ALTER SEQUENCE menus_menu_id_seq RESTART WITH 1;

INSERT INTO menus (menu_id, menu_padre_id, titulo, icono, url, orden, estado_id, usuario_id_registro) VALUES
(1, NULL, 'NINGUNO', NULL, NULL, 0, 1000, 1),
(2, NULL, 'CONFIGURACIÓN Y SISTEMA', 'pi pi-cog', NULL, 1, 1000, 1),
(3, 2, 'DATOS DE LA EMPRESA', 'pi pi-building', '/configuracion/empresa', 1, 1000, 1),
(4, 2, 'GESTIÓN DE NITS Y AUTORIZACIONES', 'pi pi-id-card', '/configuracion/nits', 2, 1000, 1),
(5, 2, 'CUENTAS BANCARIAS', 'pi pi-credit-card', '/configuracion/cuentas-bancarias', 3, 1000, 1),
(6, 2, 'SUCURSALES Y PUNTOS', 'pi pi-map-marker', '/configuracion/sucursales', 4, 1000, 1),
(7, 2, 'CONTROL DE USUARIOS', 'pi pi-users', '/configuracion/usuarios', 5, 1000, 1),
(8, 2, 'ROLES Y PERMISOS', 'pi pi-key', '/configuracion/roles', 6, 1000, 1),
(9, 2, 'PARÁMETROS GLOBALES', 'pi pi-sliders-h', '/configuracion/parametros', 7, 1000, 1),
(10, 2, 'TASAS DE CAMBIO', 'pi pi-dollar', '/configuracion/tipos-cambio', 8, 1000, 1),
(11, 2, 'TAREAS PROGRAMADAS', 'pi pi-calendar-clock', '/configuracion/tareas', 9, 1000, 1),
(12, 2, 'LOGS DE EJECUCIÓN', 'pi pi-file-code', '/configuracion/logs', 10, 1000, 1),
(13, 2, 'AUDITORÍA DE DATOS', 'pi pi-eye', '/configuracion/auditoria', 11, 1000, 1),
(14, 2, 'RESPALDOS DE DATOS (BACKUP)', 'pi pi-cloud-upload', '/configuracion/backup', 12, 1000, 1),
(15, NULL, 'GESTIÓN DE PRODUCTOS', 'pi pi-box', NULL, 2, 1000, 1),
(16, 15, 'CATÁLOGO DE PRODUCTOS', 'pi pi-shopping-bag', '/productos/catalogo', 1, 1000, 1),
(17, 15, 'CATEGORÍAS', 'pi pi-tags', '/productos/categorias', 2, 1000, 1),
(18, 15, 'LABORATORIOS', 'pi pi-percentage', '/productos/laboratorios', 3, 1000, 1),
(19, 15, 'PRINCIPIOS ACTIVOS', 'pi pi-info-circle', '/productos/principios-activos', 4, 1000, 1),
(20, 15, 'FORMAS FARMACÉUTICAS', 'pi pi-tablet', '/productos/formas', 5, 1000, 1),
(21, 15, 'PRESENTACIONES COMERCIALES', 'pi pi-clone', '/productos/presentaciones', 6, 1000, 1),
(22, 15, 'CONCENTRACIONES', 'pi pi-filter', '/productos/concentraciones', 7, 1000, 1),
(23, 15, 'REGISTROS SANITARIOS', 'pi pi-file', '/productos/registros-sanitarios', 8, 1000, 1),
(24, 15, 'PRODUCTOS CONTROLADOS', 'pi pi-exclamation-circle', '/productos/controlados', 9, 1000, 1),
(25, 15, 'UNIDADES DE MEDIDA', 'pi pi-calculator', '/productos/unidades', 10, 1000, 1),
(26, 15, 'CONVERSIONES DE UNIDAD', 'pi pi-refresh', '/productos/conversiones', 11, 1000, 1),
(27, 15, 'PROMOCIONES Y OFERTAS', 'pi pi-percentage', '/productos/promociones', 12, 1000, 1),
(28, NULL, 'INVENTARIOS Y ALMACENES', 'pi pi-home', NULL, 3, 1000, 1),
(29, 28, 'ALMACENES FÍSICOS', 'pi pi-map', '/inventario/almacenes', 1, 1000, 1),
(30, 28, 'UBICACIONES INTERNAS', 'pi pi-compass', '/inventario/ubicaciones', 2, 1000, 1),
(31, 28, 'MOVIMIENTOS DE KARDEX', 'pi pi-list', '/inventario/kardex', 3, 1000, 1),
(32, 28, 'CONTROL DE LOTES', 'pi pi-barcode', '/inventario/lotes', 4, 1000, 1),
(33, 28, 'TRASPASOS INTER-SUCURSALES', 'pi pi-arrow-h', '/inventario/traspasos', 5, 1000, 1),
(34, 28, 'DISTRIBUCIÓN EN ESTANTERÍAS', 'pi pi-server', '/inventario/productos-ubicaciones', 6, 1000, 1),
(35, NULL, 'COMPRAS Y PROVEEDORES', 'pi pi-shopping-cart', NULL, 4, 1000, 1),
(36, 35, 'REGISTRO DE PROVEEDORES', 'pi pi-truck', '/compras/proveedores', 1, 1000, 1),
(37, 35, 'ÓRDENES Y RECEPCIONES', 'pi pi-plus-circle', '/compras/ordenes', 2, 1000, 1),
(38, 35, 'PLANES DE PAGO Y CRÉDITOS', 'pi pi-calendar', '/compras/planes-pago', 3, 1000, 1),
(39, 35, 'GESTIÓN DE CRÉDITOS A PROVEEDORES', 'pi pi-money-bill', '/compras/pagos', 4, 1000, 1),
(40, NULL, 'VENTAS Y FACTURACIÓN', 'pi pi-wallet', NULL, 5, 1000, 1),
(41, 40, 'PUNTO DE VENTA (POS)', 'pi pi-desktop', '/ventas/pos', 1, 1000, 1),
(42, 40, 'REGISTRO DE CLIENTES', 'pi pi-user-plus', '/ventas/clientes', 2, 1000, 1),
(43, 40, 'DOSIFICACIÓN Y FACTURAS (SIN)', 'pi pi-file-excel', '/ventas/control-facturas', 3, 1000, 1),
(44, 40, 'HISTÓRICO DE DOCUMENTOS', 'pi pi-folder-open', '/ventas/documentos-historicos', 4, 1000, 1),
(45, 40, 'COMPROBANTES DIGITALES / QR', 'pi pi-qrcode', '/ventas/comprobantes', 5, 1000, 1),
(46, NULL, 'GESTIÓN DE CAJA', 'pi pi-percentage', NULL, 6, 1000, 1),
(47, 46, 'APERTURA Y CIERRE', 'pi pi-lock', '/caja/sesiones', 1, 1000, 1),
(48, 46, 'MOVIMIENTOS DE CAJA (VARIOS)', 'pi pi-sort', '/caja/movimientos', 2, 1000, 1),
(49, NULL, 'COMERCIO ELECTRÓNICO Y DELIVERY', 'pi pi-globe', NULL, 7, 1000, 1),
(50, 49, 'PEDIDOS ONLINE', 'pi pi-shopping-bag', '/ecommerce/pedidos', 1, 1000, 1),
(51, 49, 'CARRITOS DE COMPRA', 'pi pi-shopping-cart', '/ecommerce/carritos', 2, 1000, 1),
(52, NULL, 'PRECIOS, COSTOS Y MÁRGENES', 'pi pi-tags', NULL, 8, 1000, 1),
(53, 52, 'LISTAS DE PRECIOS', 'pi pi-list', '/precios/listas', 1, 1000, 1),
(54, 52, 'PRECIOS DE PRODUCTOS', 'pi pi-dollar', '/precios/productos', 2, 1000, 1),
(55, 52, 'COSTOS PROMEDIO', 'pi pi-chart-line', '/precios/costos', 3, 1000, 1),
(56, 52, 'POLÍTICAS DE PRECIOS', 'pi pi-sliders-h', '/precios/politicas', 4, 1000, 1),
(57, NULL, 'RECURSOS HUMANOS', 'pi pi-id-card', NULL, 9, 1000, 1),
(58, 57, 'GESTIÓN DE TRABAJADORES', 'pi pi-users', '/rrhh/trabajadores', 1, 1000, 1),
(59, 57, 'CONTROL DE ASISTENCIAS', 'pi pi-clock', '/rrhh/asistencias', 2, 1000, 1),
(60, 57, 'PLANILLAS DE SUELDOS', 'pi pi-file-pdf', '/rrhh/planillas', 3, 1000, 1),
(61, 57, 'CONTRATOS DE PERSONAL', 'pi pi-briefcase', '/rrhh/contratos', 4, 1000, 1),
(62, NULL, 'NÚCLEO ANALÍTICO Y PREDICCIONES', 'pi pi-android', NULL, 10, 1000, 1),
(63, 62, 'DASHBOARD DE ANALÍTICA CONSOLIDADA', 'pi pi-chart-bar', '/ia/analitica', 1, 1000, 1),
(64, 62, 'MODELOS ML DISPONIBLES', 'pi pi-share-alt', '/ia/modelos', 2, 1000, 1),
(65, 62, 'HISTORIAL DE ENTRENAMIENTOS', 'pi pi-sync', '/ia/entrenamientos', 3, 1000, 1),
(66, 62, 'MÉTRICAS DE RENDIMIENTO', 'pi pi-chart-line', '/ia/metricas', 4, 1000, 1),
(67, 62, 'VARIABLES EXÓGENAS AMBIENTALES', 'pi pi-cloud', '/ia/variables-exogenas', 5, 1000, 1),
(68, 62, 'PATRONES DE CONSUMO ESTACIONAL', 'pi pi-sliders-v', '/ia/patrones-consumo', 6, 1000, 1),
(69, 62, 'CONFIGURACIÓN DE UMBRALES PREDICTIVOS', 'pi pi-cog', '/ia/umbrales', 7, 1000, 1),
(70, NULL, 'NOTIFICACIONES Y ALERTAS', 'pi pi-bell', NULL, 11, 1000, 1),
(71, 70, 'BANDEJA DE NOTIFICACIONES', 'pi pi-inbox', '/alertas/notificaciones', 1, 1000, 1),
(72, 70, 'ALERTAS OPERATIVAS Y CRÍTICAS', 'pi pi-exclamation-triangle', '/alertas/criticas', 2, 1000, 1),
(73, NULL, 'REPORTES Y DIRECCIÓN GERENCIAL', 'pi pi-print', NULL, 12, 1000, 1),
(74, 73, 'CONSOLIDADOR DE REPORTES', 'pi pi-copy', '/reportes/dashboard-unico', 1, 1000, 1),
(75, 73, 'REPORTES DE INVENTARIO Y STOCK', 'pi pi-chart-scatter', '/reportes/inventario', 2, 1000, 1),
(76, 73, 'PANEL DE CONTROL FINANCIERO', 'pi pi-percentage', '/gerencia/reportes-financieros', 3, 1000, 1),
(77, 73, 'HISTORIAL DE COSTOS Y MÁRGENES', 'pi pi-chart-line', '/gerencia/historial-costos', 4, 1000, 1),
(78, 73, 'MONITOR DE ALERTAS DE RIESGO', 'pi pi-bolt', '/gerencia/alertas-criticas', 5, 1000, 1);

UPDATE menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('menus_menu_id_seq', COALESCE((SELECT MAX(menu_id) FROM menus), 0), (SELECT COUNT(*) > 0 FROM menus));

-- ================================================================================================

DELETE FROM roles_menus;
ALTER SEQUENCE roles_menus_rol_menu_id_seq RESTART WITH 1;

INSERT INTO roles_menus (rol_menu_id, rol_id, menu_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1000, 1),
(2, 2, 1, 1000, 1),
(3, 2, 2, 1000, 1),
(4, 2, 3, 1000, 1),
(5, 2, 4, 1000, 1),
(6, 2, 5, 1000, 1),
(7, 2, 6, 1000, 1),
(8, 2, 7, 1000, 1),
(9, 2, 8, 1000, 1),
(10, 2, 9, 1000, 1),
(11, 2, 10, 1000, 1),
(12, 2, 11, 1000, 1),
(13, 2, 12, 1000, 1),
(14, 2, 13, 1000, 1),
(15, 2, 14, 1000, 1),
(16, 2, 15, 1000, 1),
(17, 2, 16, 1000, 1),
(18, 2, 17, 1000, 1),
(19, 2, 18, 1000, 1),
(20, 2, 19, 1000, 1),
(21, 2, 20, 1000, 1),
(22, 2, 21, 1000, 1),
(23, 2, 22, 1000, 1),
(24, 2, 23, 1000, 1),
(25, 2, 24, 1000, 1),
(26, 2, 25, 1000, 1),
(27, 2, 26, 1000, 1),
(28, 2, 27, 1000, 1),
(29, 2, 28, 1000, 1),
(30, 2, 29, 1000, 1),
(31, 2, 30, 1000, 1),
(32, 2, 31, 1000, 1),
(33, 2, 32, 1000, 1),
(34, 2, 33, 1000, 1),
(35, 2, 34, 1000, 1),
(36, 2, 35, 1000, 1),
(37, 2, 36, 1000, 1),
(38, 2, 37, 1000, 1),
(39, 2, 38, 1000, 1),
(40, 2, 39, 1000, 1),
(41, 2, 40, 1000, 1),
(42, 2, 41, 1000, 1),
(43, 2, 42, 1000, 1),
(44, 2, 43, 1000, 1),
(45, 2, 44, 1000, 1),
(46, 2, 45, 1000, 1),
(47, 2, 46, 1000, 1),
(48, 2, 47, 1000, 1),
(49, 2, 48, 1000, 1),
(50, 2, 49, 1000, 1),
(51, 2, 50, 1000, 1),
(52, 2, 51, 1000, 1),
(53, 2, 52, 1000, 1),
(54, 2, 53, 1000, 1),
(55, 2, 54, 1000, 1),
(56, 2, 55, 1000, 1),
(57, 2, 56, 1000, 1),
(58, 2, 57, 1000, 1),
(59, 2, 58, 1000, 1),
(60, 2, 59, 1000, 1),
(61, 2, 60, 1000, 1),
(62, 2, 61, 1000, 1),
(63, 2, 62, 1000, 1),
(64, 2, 63, 1000, 1),
(65, 2, 64, 1000, 1),
(66, 2, 65, 1000, 1),
(67, 2, 66, 1000, 1),
(68, 3, 50, 1000, 1),
(69, 3, 51, 1000, 1),
(70, 3, 61, 1000, 1),
(71, 3, 62, 1000, 1),
(72, 3, 63, 1000, 1),
(73, 3, 64, 1000, 1),
(74, 3, 65, 1000, 1),
(75, 3, 66, 1000, 1),
(76, 6, 40, 1000, 1),
(77, 6, 41, 1000, 1),
(78, 6, 42, 1000, 1),
(79, 6, 44, 1000, 1),
(80, 6, 46, 1000, 1);

UPDATE roles_menus SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE roles_menus SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('roles_menus_rol_menu_id_seq', COALESCE((SELECT MAX(rol_menu_id) FROM roles_menus), 0), (SELECT COUNT(*) > 0 FROM roles_menus));

-- ================================================================================================

DELETE FROM inventarios_fisicos;
ALTER SEQUENCE inventarios_fisicos_inventario_fisico_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos (inventario_fisico_id, sucursal_id, ubicacion_id, fecha_conteo, fecha_inicio, fecha_fin, usuario_registro_id, usuario_supervisor_id, estado_id, observaciones, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, 1, NULL, 1000, 'REGISTRO INICIAL COMODIN DE INVENTARIO FISICO', 1);

UPDATE inventarios_fisicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE inventarios_fisicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('inventarios_fisicos_inventario_fisico_id_seq', COALESCE((SELECT MAX(inventario_fisico_id) FROM inventarios_fisicos), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos));

-- ================================================================================================

DELETE FROM clientes;
ALTER SEQUENCE clientes_cliente_id_seq RESTART WITH 1;

INSERT INTO clientes (cliente_id, tipo_cliente_id, cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id, direccion, telefono, email, banco_id, numero_cuenta, habilitado_ventas, limite_credito, estado_id, usuario_id_registro) VALUES
(1, 1150, 'NINGUNO', NULL, NULL, '0', NULL, 2200, NULL, NULL, NULL, 1, NULL, 1, 0.00, 1000, 1),
(2, 1150, 'FRANZ IBAÑEZ', NULL, NULL, '2630198', NULL, 2200, 'Av. Arce No. 123', '71234567', 'franz@email.com', 2, '1000001234', 1, 1000.00, 1000, 1),
(3, 1151, 'JUAN PEREZ', '1020304025', 'DROGUERIA INTI S.A.', '1020304025', NULL, 2204, 'Zona Industrial El Alto', '22841414', 'contacto@inti.com.bo', 3, '4010005678', 1, 5000.00, 1000, 1);

UPDATE clientes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE clientes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('clientes_cliente_id_seq', COALESCE((SELECT MAX(cliente_id) FROM clientes), 0), (SELECT COUNT(*) > 0 FROM clientes));

-- ================================================================================================

DELETE FROM categorias;
ALTER SEQUENCE categorias_categoria_id_seq RESTART WITH 1;

INSERT INTO categorias (categoria_id, categoria_padre_id, categoria, codigo, descripcion, nivel, orden, estado_id, usuario_id_registro) VALUES
(1, NULL, 'NINGUNA', 'NIN', 'Categoría predeterminada para productos sin clasificar', 1, 0, 1000, 1);

UPDATE categorias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE categorias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('categorias_categoria_id_seq', COALESCE((SELECT MAX(categoria_id) FROM categorias), 0), (SELECT COUNT(*) > 0 FROM categorias));

-- ================================================================================================

DELETE FROM unidades;
ALTER SEQUENCE unidades_unidad_id_seq RESTART WITH 1;

INSERT INTO unidades (unidad_id, codigo, codigo_sin, unidad, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 0, 'NINGUNA', 1000, 1),
(2, 'KG', 1, 'KILOGRAMO', 1000, 1),
(3, 'G', 2, 'GRAMO', 1000, 1),
(4, 'T', 3, 'TONELADA', 1000, 1),
(5, 'L', 4, 'LITRO', 1000, 1),
(6, 'ML', 5, 'MILILITRO', 1000, 1),
(7, 'M', 6, 'METRO', 1000, 1),
(8, 'CM', 7, 'CENTÍMETRO', 1000, 1),
(9, 'U', 58, 'UNIDAD', 1000, 1),
(10, 'PZ', 58, 'PIEZA', 1000, 1),
(11, 'CJ', 58, 'CAJA', 1000, 1),
(12, 'PQ', 58, 'PAQUETE', 1000, 1);

UPDATE unidades SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE unidades SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('unidades_unidad_id_seq', COALESCE((SELECT MAX(unidad_id) FROM unidades), 0), (SELECT COUNT(*) > 0 FROM unidades));

-- ================================================================================================

DELETE FROM laboratorios;
ALTER SEQUENCE laboratorios_laboratorio_id_seq RESTART WITH 1;

INSERT INTO laboratorios (laboratorio_id, codigo, laboratorio, nit, direccion, telefono, email, web, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, NULL, NULL, NULL, 1000, 1);

UPDATE laboratorios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE laboratorios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('laboratorios_laboratorio_id_seq', COALESCE((SELECT MAX(laboratorio_id) FROM laboratorios), 0), (SELECT COUNT(*) > 0 FROM laboratorios));

-- ================================================================================================

DELETE FROM formas;
ALTER SEQUENCE formas_forma_id_seq RESTART WITH 1;

INSERT INTO formas (forma_id, forma_farmaceutica, codigo, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'NIN', 'Forma farmacéutica predeterminada para productos sin clasificar', 1000, 1);

UPDATE formas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE formas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('formas_forma_id_seq', COALESCE((SELECT MAX(forma_id) FROM formas), 0), (SELECT COUNT(*) > 0 FROM formas));

-- ================================================================================================

DELETE FROM presentaciones;
ALTER SEQUENCE presentaciones_presentacion_id_seq RESTART WITH 1;

INSERT INTO presentaciones (presentacion_id, unidad_id, codigo, presentacion, cantidad_unidades, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 1, 'Presentación predeterminada para productos sin clasificar', 1000, 1);

UPDATE presentaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE presentaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('presentaciones_presentacion_id_seq', COALESCE((SELECT MAX(presentacion_id) FROM presentaciones), 0), (SELECT COUNT(*) > 0 FROM presentaciones));

-- ================================================================================================

DELETE FROM concentraciones;
ALTER SEQUENCE concentraciones_concentracion_id_seq RESTART WITH 1;

INSERT INTO concentraciones (concentracion_id, unidad_base_id, codigo, concentracion, valor_numerico, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', 'NINGUNA', 0.00, 'Concentración predeterminada para productos sin clasificar', 1000, 1);

UPDATE concentraciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE concentraciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('concentraciones_concentracion_id_seq', COALESCE((SELECT MAX(concentracion_id) FROM concentraciones), 0), (SELECT COUNT(*) > 0 FROM concentraciones));

-- ================================================================================================

DELETE FROM vias;
ALTER SEQUENCE vias_via_id_seq RESTART WITH 1;

INSERT INTO vias (via_id, nombre, descripcion, requiere_ayuno, tiempo_efecto_minutos, precauciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'Vía de administración predeterminada', 0, NULL, NULL, 1000, 1),
(2, 'ORAL', 'Administración por vía oral (tragado)', 0, 30, 'Tomar con suficiente agua', 1000, 1),
(3, 'TÓPICA', 'Aplicación sobre la piel o mucosas', 0, NULL, 'Evitar contacto con ojos y mucosas', 1000, 1),
(4, 'INHALADA', 'Administración por inhalación', 0, 5, 'Mantener el inhalador limpio', 1000, 1),
(5, 'PARENTERAL', 'Administración por vía inyectable', 1, 15, 'Solo personal capacitado', 1000, 1),
(6, 'RECTAL', 'Administración por vía rectal', 1, 30, NULL, 1000, 1),
(7, 'ÓTICA', 'Administración en el oído', 0, NULL, 'No usar si el tímpano está perforado', 1000, 1),
(8, 'OFTÁLMICA', 'Administración en el ojo', 0, NULL, 'Lavarse las manos antes y después', 1000, 1),
(9, 'NASAL', 'Administración por vía nasal', 0, 5, 'Limpiar la nariz antes de usar', 1000, 1),
(10, 'VAGINAL', 'Administración por vía vaginal', 0, 30, 'Usar aplicador si está incluido', 1000, 1),
(11, 'SUBLINGUAL', 'Administración bajo la lengua', 1, 5, 'No tragar, dejar disolver completamente', 1000, 1);

UPDATE vias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE vias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('vias_via_id_seq', COALESCE((SELECT MAX(via_id) FROM vias), 0), (SELECT COUNT(*) > 0 FROM vias));

-- ================================================================================================

DELETE FROM rangos_edad;
ALTER SEQUENCE rangos_edad_rango_edad_id_seq RESTART WITH 1;

INSERT INTO rangos_edad (rango_edad_id, codigo, rango, edad_minima_meses, edad_maxima_meses, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'No especificado / General', NULL, NULL, 'Rango predeterminado o no aplicable', 1000, 1),
(2, 'REC', 'Recién Nacido', 0, 1, 'De 0 a 28 días de vida', 1000, 1),
(3, 'LAC', 'Lactante', 1, 12, 'De 1 mes a 1 año', 1000, 1),
(4, 'PRE', 'Preescolar', 12, 72, 'De 1 año a 5 años (60 meses)', 1000, 1),
(5, 'PED', 'Pediátrico (General)', 0, 144, 'Desde recién nacido hasta los 12 años', 1000, 1),
(6, 'ADO', 'Adolescente', 144, 216, 'De 12 a 18 años', 1000, 1),
(7, 'ADU', 'Adulto', 216, 780, 'De 18 a 65 años', 1000, 1),
(8, 'GER', 'Adulto Mayor / Geriátrico', 780, NULL, 'Mayores de 65 años', 1000, 1);

UPDATE rangos_edad SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE rangos_edad SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('rangos_edad_rango_edad_id_seq', COALESCE((SELECT MAX(rango_edad_id) FROM rangos_edad), 0), (SELECT COUNT(*) > 0 FROM rangos_edad));

-- ================================================================================================

DELETE FROM marcas;
ALTER SEQUENCE marcas_marca_id_seq RESTART WITH 1;

INSERT INTO marcas (marca_id, nombre, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNA', 'Marca predeterminada para productos genéricos o sin marca especificada', 1000, 1);

UPDATE marcas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE marcas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('marcas_marca_id_seq', COALESCE((SELECT MAX(marca_id) FROM marcas), 0), (SELECT COUNT(*) > 0 FROM marcas));

-- ================================================================================================

DELETE FROM productos;
ALTER SEQUENCE productos_producto_id_seq RESTART WITH 1;

INSERT INTO productos (producto_id, categoria_id, laboratorio_id, marca_id, forma_id, presentacion_id, concentracion_id, unidad_venta_id, codigo, codigo_barras, sku, isbn, modelo, nombre, nombre_generico, pcompra, p_factor_venta, p_factor_facturacion, pventa, pventaf, stock_minimo, stock_maximo, punto_reorden, requiere_receta, controlado, tiene_registro_sanitario, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1, 1, 'NIN', NULL, NULL, NULL, NULL, 'NINGUNO', NULL, 0.00, 1.50, 1.19, 0.00, 0.00, 0.00, 1.00, 0.00, 0, 0, 0, 'Producto predeterminado para casos sin clasificar', 1000, 1);

UPDATE productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_producto_id_seq', COALESCE((SELECT MAX(producto_id) FROM productos), 0), (SELECT COUNT(*) > 0 FROM productos));

-- ================================================================================================

DELETE FROM productos_vias;
ALTER SEQUENCE productos_vias_producto_via_id_seq RESTART WITH 1;

INSERT INTO productos_vias (producto_via_id, producto_id, via_id, es_principal, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 'NINGUNO', 1000, 1);

UPDATE productos_vias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_vias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_vias_producto_via_id_seq', COALESCE((SELECT MAX(producto_via_id) FROM productos_vias), 0), (SELECT COUNT(*) > 0 FROM productos_vias));

-- ================================================================================================

DELETE FROM equivalentes;
ALTER SEQUENCE equivalentes_equivalente_id_seq RESTART WITH 1;

INSERT INTO equivalentes (equivalente_id, producto_base_id, producto_alternativo_id, grado_equivalente_id, prioridad_recomendacion, observaciones) VALUES
(1, 1, 1, 3803, 1, 'Sustituto directo');

UPDATE equivalentes SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE equivalentes SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('equivalentes_equivalente_id_seq', COALESCE((SELECT MAX(equivalente_id) FROM equivalentes), 0), (SELECT COUNT(*) > 0 FROM equivalentes));

-- ================================================================================================

DELETE FROM productos_rangos_edad;
ALTER SEQUENCE productos_rangos_edad_producto_rango_edad_id_seq RESTART WITH 1;

INSERT INTO productos_rangos_edad (producto_rango_edad_id, producto_id, rango_edad_id, contraindicado, dosis_recomendada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, NULL, NULL, 1000, 1);

UPDATE productos_rangos_edad SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_rangos_edad SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_rangos_edad_producto_rango_edad_id_seq', COALESCE((SELECT MAX(producto_rango_edad_id) FROM productos_rangos_edad), 0), (SELECT COUNT(*) > 0 FROM productos_rangos_edad));

-- ================================================================================================

DELETE FROM productos_ubicaciones;
ALTER SEQUENCE productos_ubicaciones_producto_ubicacion_id_seq RESTART WITH 1;

INSERT INTO productos_ubicaciones (producto_ubicacion_id, producto_id, ubicacion_id, prioridad_picking, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 99, 1000, 1);

UPDATE productos_ubicaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_ubicaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_ubicaciones_producto_ubicacion_id_seq', COALESCE((SELECT MAX(producto_ubicacion_id) FROM productos_ubicaciones), 0), (SELECT COUNT(*) > 0 FROM productos_ubicaciones));

-- ================================================================================================

DELETE FROM principios_activos;
ALTER SEQUENCE principios_activos_principio_activo_id_seq RESTART WITH 1;

INSERT INTO principios_activos (principio_activo_id, codigo, nombre, descripcion, es_controlado, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN COMPONENTE ACTIVO REGISTRADO / NO APLICA', 0, 1000, 1);

UPDATE principios_activos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE principios_activos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('principios_activos_principio_activo_id_seq', COALESCE((SELECT MAX(principio_activo_id) FROM principios_activos), 0), (SELECT COUNT(*) > 0 FROM principios_activos));

-- ================================================================================================

DELETE FROM productos_principios;
ALTER SEQUENCE productos_principios_producto_principio_id_seq RESTART WITH 1;

INSERT INTO productos_principios (producto_principio_id, producto_id, principio_activo_id, concentracion, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NINGUNO', 0, 1000, 1);

UPDATE productos_principios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_principios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_principios_producto_principio_id_seq', COALESCE((SELECT MAX(producto_principio_id) FROM productos_principios), 0), (SELECT COUNT(*) > 0 FROM productos_principios));

-- ================================================================================================

DELETE FROM registros_sanitarios;
ALTER SEQUENCE registros_sanitarios_registro_sanitario_id_seq RESTART WITH 1;

INSERT INTO registros_sanitarios (registro_sanitario_id, producto_id, codigo_registro, entidad_emisora, fecha_emision, fecha_vencimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', '2000-01-01', '2001-01-01', 1000, 1);

UPDATE registros_sanitarios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE registros_sanitarios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('registros_sanitarios_registro_sanitario_id_seq', COALESCE((SELECT MAX(registro_sanitario_id) FROM registros_sanitarios), 0), (SELECT COUNT(*) > 0 FROM registros_sanitarios));

-- ================================================================================================

DELETE FROM productos_controlados;
ALTER SEQUENCE productos_controlados_producto_controlado_id_seq RESTART WITH 1;

INSERT INTO productos_controlados (producto_controlado_id, producto_id, numero_autorizacion, requiere_receta_retenida, observaciones_control, estado_id, usuario_id_registro) VALUES 
(1, 1, 'NINGUNO', 0, 'SIN FISCALIZACIÓN / NO APLICA', 1000, 1);

UPDATE productos_controlados SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE productos_controlados SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('productos_controlados_producto_controlado_id_seq', COALESCE((SELECT MAX(producto_controlado_id) FROM productos_controlados), 0), (SELECT COUNT(*) > 0 FROM productos_controlados));

-- ================================================================================================

DELETE FROM promociones;
ALTER SEQUENCE promociones_promocion_id_seq RESTART WITH 1;

INSERT INTO promociones (promocion_id, codigo, nombre, descripcion, tipo_beneficio_id, valor_beneficio, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', 'SIN CAMPAÑA PROMOCIONAL / NO APLICA', 1504, 0.00, '2000-01-01', '2001-01-01', 1000, 1);

UPDATE promociones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE promociones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('promociones_promocion_id_seq', COALESCE((SELECT MAX(promocion_id) FROM promociones), 0), (SELECT COUNT(*) > 0 FROM promociones));

-- ================================================================================================

DELETE FROM promociones_productos;
ALTER SEQUENCE promociones_productos_promocion_producto_id_seq RESTART WITH 1;

INSERT INTO promociones_productos (promocion_producto_id, promocion_id, producto_id, limite_por_transaccion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0, 1000, 1);

UPDATE promociones_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE promociones_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('promociones_productos_promocion_producto_id_seq', COALESCE((SELECT MAX(promocion_producto_id) FROM promociones_productos), 0), (SELECT COUNT(*) > 0 FROM promociones_productos));

-- ================================================================================================

DELETE FROM conversiones_unidad;
ALTER SEQUENCE conversiones_unidad_conversion_id_seq RESTART WITH 1;

INSERT INTO conversiones_unidad (conversion_id, producto_id, unidad_origen_id, unidad_destino_id, factor_conversion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1.0000, 1000, 1);

UPDATE conversiones_unidad SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE conversiones_unidad SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('conversiones_unidad_conversion_id_seq', COALESCE((SELECT MAX(conversion_id) FROM conversiones_unidad), 0), (SELECT COUNT(*) > 0 FROM conversiones_unidad));

-- ================================================================================================

- Si rating_calidad_id = 2050 (PESIMO), el sistema debe bloquear nuevas compras a este proveedor.
- El backend debe actualizar automáticamente el rating basado en incidencias de calidad.

DELETE FROM proveedores;
ALTER SEQUENCE proveedores_proveedor_id_seq RESTART WITH 1;

INSERT INTO proveedores (proveedor_id, codigo, nombre, nit, direccion, telefono, email, rating_calidad_id, monto_minimo_compra, plazo_entrega_dias, limite_credito, dias_credito, ultima_evaluacion, observaciones, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'NINGUNO', NULL, NULL, NULL, NULL, 2055, 0.00, 0, 0.00, 0, NULL, 'PROVEEDOR COMODÍN PARA COMPRAS DIRECTAS O DONACIONES', 1000, 1);

UPDATE proveedores SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE proveedores SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('proveedores_proveedor_id_seq', COALESCE((SELECT MAX(proveedor_id) FROM proveedores), 0), (SELECT COUNT(*) > 0 FROM proveedores));

-- ================================================================================================

DELETE FROM proveedores_contactos;
ALTER SEQUENCE proveedores_contactos_proveedor_contacto_id_seq RESTART WITH 1;

INSERT INTO proveedores_contactos (proveedor_contacto_id, proveedor_id, nombre, cargo, telefono, email, es_principal, estado_id, usuario_id_registro) VALUES
(1, 1, 'NINGUNO', 'NINGUNO', NULL, NULL, 1, 1000, 1);

UPDATE proveedores_contactos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE proveedores_contactos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1000;

SELECT setval('proveedores_contactos_proveedor_contacto_id_seq', COALESCE((SELECT MAX(proveedor_contacto_id) FROM proveedores_contactos), 0), (SELECT COUNT(*) > 0 FROM proveedores_contactos));

-- ================================================================================================

DELETE FROM proveedores_rating_historico;
ALTER SEQUENCE proveedores_rating_historico_rating_historico_id_seq RESTART WITH 1;

INSERT INTO proveedores_rating_historico (rating_historico_id, proveedor_id, rating_calidad_id, motivo, fecha_evaluacion, estado_id, usuario_id_registro) VALUES 
(1, 1, 2055, 'REGISTRO INICIAL COMODÍN', CURRENT_DATE, 1000, 1);

UPDATE proveedores_rating_historico SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE proveedores_rating_historico SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1000;

SELECT setval('proveedores_rating_historico_rating_historico_id_seq', COALESCE((SELECT MAX(rating_historico_id) FROM proveedores_rating_historico), 0), (SELECT COUNT(*) > 0 FROM proveedores_rating_historico));

-- ================================================================================================

DELETE FROM parametros_globales;
ALTER SEQUENCE parametros_globales_parametro_id_seq RESTART WITH 1;

INSERT INTO parametros_globales (parametro_id,clave,valor,tipo_dato_id,valor_json,descripcion,editable,estado_id,usuario_id_registro) VALUES
(1,'ninguna','comodin_sistema',1800,NULL,'Registro comodin por defecto para parametros_globales',0,1000,1),
(2,'moneda_principal','BOB',1800,NULL,'Moneda base del sistema boliviano',1,1000,1),
(3,'porcentaje_iva','13.00',1802,NULL,'Alícuota general del IVA en Bolivia',1,1000,1),
(4,'limite_items_proforma','50',1801,NULL,'Cantidad máxima de ítems permitidos por proforma',1,1000,1),
(5,'controlar_lotes_vencidos','1',1803,NULL,'Habilitar bloqueo de venta para lotes expirados (1=Si, 0=No)',1,1000,1),
(6,'dias_alerta_vencimiento','90',1801,NULL,'Días de anticipación para notificar la expiración de medicamentos',1,1000,1),
(7,'modelo_arima_p','1',1801,NULL,'Orden autorregresivo (p) para modelo ARIMA',1,1000,1),
(8,'modelo_arima_d','1',1801,NULL,'Orden de diferenciación (d) para modelo ARIMA',1,1000,1),
(9,'modelo_arima_q','1',1801,NULL,'Orden de promedio móvil (q) para modelo ARIMA',1,1000,1),
(10,'modelo_sarima_p','1',1801,NULL,'Orden autorregresivo estacional (P) para SARIMA',1,1000,1),
(11,'modelo_sarima_d','1',1801,NULL,'Orden de diferenciación estacional (D) para SARIMA',1,1000,1),
(12,'modelo_sarima_q','1',1801,NULL,'Orden de promedio móvil estacional (Q) para SARIMA',1,1000,1),
(13,'modelo_sarima_s','7',1801,NULL,'Período estacional (s) para SARIMA (7=días, 12=meses)',1,1000,1),
(14,'modelo_kmeans_n_clusters','3',1801,NULL,'Número de clusters para K-Means (A, B, C)',1,1000,1),
(15,'modelo_kmeans_random_state','42',1801,NULL,'Semilla aleatoria para reproducibilidad',1,1000,1),
(16,'modelo_kmeans_max_iter','300',1801,NULL,'Máximo de iteraciones para K-Means',1,1000,1),
(17,'modelo_rop_lead_time_default','7',1801,NULL,'Lead time por defecto en días para cálculo de ROP',1,1000,1),
(18,'modelo_rop_stock_seguridad_default','10',1802,NULL,'Stock de seguridad por defecto para ROP',1,1000,1),
(19,'modelo_rop_nivel_confianza','0.95',1802,NULL,'Nivel de confianza para intervalos de predicción',1,1000,1),
(20,'alerta_dias_vencimiento_critico','15',1801,NULL,'Días para alerta CRÍTICA de vencimiento',1,1000,1),
(21,'alerta_dias_vencimiento_alta','30',1801,NULL,'Días para alerta ALTA de vencimiento',1,1000,1),
(22,'alerta_dias_vencimiento_media','60',1801,NULL,'Días para alerta MEDIA de vencimiento',1,1000,1),
(23,'alerta_stock_quiebre','5',1801,NULL,'Stock mínimo para alerta de quiebre',1,1000,1),
(24,'alerta_stock_reorden','20',1801,NULL,'Stock para alerta de reorden',1,1000,1),
(25,'alerta_dias_ventanas_dias','90',1801,NULL,'Ventana de días para entrenar modelos',1,1000,1),
(26,'entrenamiento_min_registros','30',1801,NULL,'Mínimo de registros para entrenar un modelo',1,1000,1),
(27,'entrenamiento_test_size','0.2',1802,NULL,'Porcentaje de datos para prueba (test)',1,1000,1),
(28,'longitud_numero_factura','7',1801,NULL,'Cantidad de dígitos para el número de factura (con ceros a la izquierda)',1,1000,1),
(29,'multa_dias_gracia','10',1801,NULL,'Días de tolerancia permitidos antes de aplicar cargos por retraso en cuotas',1,1000,1),
(30,'multa_tipo_calculo','PORCENTAJE',1800,NULL,'Tipo de cálculo para la multa: MONTO_FIJO o PORCENTAJE sobre la cuota vencida',1,1000,1),
(31,'multa_valor_diario','0.50',1802,NULL,'Valor diario de la multa (monto en moneda base o porcentaje según el tipo de cálculo)',1,1000,1),
(32,'gestion_activa','2026-01-01 00:00:00-04:00',1804,NULL,'Fecha y hora de inicio de la gestión activa del sistema (con timezone -04:00 Bolivia)',1,1000,1),
(33,'logo_config','LOGO_CONFIG',1805,'{"max_size": 358400, "max_width": 1500, "max_height": 600, "default_logo": null, "retention_days": 1, "allowed_formats": ["png", "jpeg", "jpg"], "allowed_extensions": ["png", "jpg", "jpeg"]}','Configuración de logos de empresas (tamaño máximo: 350 KB, dimensiones: 1500x600 px, formatos: PNG, JPEG, JPG)',1,1000,1);

UPDATE parametros_globales SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE parametros_globales SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('parametros_globales_parametro_id_seq', COALESCE((SELECT MAX(parametro_id) FROM parametros_globales), 0), (SELECT COUNT(*) > 0 FROM parametros_globales));

-- ================================================================================================

- 1: La última ejecución de la tarea finalizó exitosamente, sin errores críticos y cumpliendo con todos los procesos definidos.
- 0: La última ejecución de la tarea falló por algún error (excepción, timeout, datos inconsistentes, etc.), registrando el detalle en ultimo_error.
- NULL: La tarea nunca ha sido ejecutada (estado inicial) o no se ha registrado el resultado de la última ejecución.
- 0 (valor por defecto): La tarea se ejecuta de forma independiente, sin esperar el resultado de la tarea dependiente (tarea_dependencia_id). Incluso si la tarea padre falla, la tarea hija se ejecutará según su propia programación.
- 1: La tarea solo se ejecutará cuando la tarea padre (tarea_dependencia_id) haya finalizado exitosamente (ejecucion_exitosa = 1). Si la tarea padre falla o no se ha ejecutado, la tarea hija se omite o se pospone hasta que la dependencia se cumpla exitosamente.';

DELETE FROM tareas_programadas;
ALTER SEQUENCE tareas_programadas_tarea_id_seq RESTART WITH 1;

INSERT INTO tareas_programadas (tarea_id, codigo, nombre, descripcion, tipo_tarea_id, subtipo_tarea_id, frecuencia_id, cron_expresion, parametros, ultima_ejecucion, proxima_ejecucion, ejecucion_exitosa, ultimo_error, intentos_fallidos, max_intentos, tarea_dependencia_id, ejecutar_en_cascada, modulo_estrategico_id, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'NINGUNA', 3409, 3461, 3359, NULL, '{"ejecutar": false}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(2, 'ALERTA_VENC', 'ALERTA DE VENCIMIENTO DE LOTES', 'Identifica lotes próximos a vencer y genera notificaciones', 3403, 3461, 3352, '0 6 * * *', '{"dias_alerta_critica": 15, "dias_alerta_alta": 30, "dias_alerta_media": 60}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2153, 1000, 1),
(3, 'ALERTA_STOCK', 'ALERTA DE STOCK CRÍTICO', 'Monitorea inventario y genera alertas por debajo del punto de reorden', 3403, 3461, 3351, '0 * * * *', '{"umbral_quiebre": 5, "umbral_reorden": 20}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(4, 'ENTRENAR_SARIMA', 'ENTRENAMIENTO DE MODELO SARIMA', 'Entrena el modelo de pronóstico de demanda con datos históricos', 3405, 3450, 3353, '0 2 * * 0', '{"ventana_dias": 90, "test_size": 0.2, "p": 1, "d": 1, "q": 1, "P": 1, "D": 1, "Q": 1, "s": 7}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(5, 'CLASIFICAR_ABC', 'CLASIFICACIÓN ABC DE INVENTARIO', 'Reclasifica productos en categorías A, B y C con K-Means', 3406, 3453, 3354, '0 3 1 * *', '{"n_clusters": 3, "random_state": 42, "max_iter": 300, "criterios": ["costo", "rotacion", "margen", "criticidad"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(6, 'PREDECIR_DEMANDA', 'PREDICCIÓN DE DEMANDA Y ROP', 'Calcula predicciones de demanda y actualiza puntos de reorden', 3407, 3454, 3352, '0 4 * * *', '{"dias_a_predecir": 30, "lead_time_default": 7, "stock_seguridad_default": 10}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(7, 'BACKUP_DB', 'RESPALDO AUTOMÁTICO DE BASE DE DATOS', 'Genera backup completo de PostgreSQL', 3402, 3461, 3352, '0 1 * * *', '{"retencion_dias": 30, "compresion": true, "ruta_destino": "/backups/db/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(8, 'REPORTE_VENTAS_DIA', 'REPORTE DIARIO DE VENTAS', 'Consolida ventas del día con gráficos y resúmenes', 3400, 3461, 3352, '0 23 * * *', '{"formato": "PDF", "incluir_graficos": true, "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2157, 1000, 1),
(9, 'LIMPIEZA_NOTIFICACIONES', 'LIMPIEZA DE NOTIFICACIONES LEÍDAS', 'Archiva notificaciones leídas con más de X días', 3404, 3461, 3353, '0 5 * * 0', '{"dias_para_archivar": 90}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(10, 'PREDECIR_VENCIMIENTOS', 'PREDICCIÓN DE FECHAS DE VENCIMIENTO', 'Pronostica vencimientos basados en patrones de consumo', 3405, 3452, 3353, '0 4 * * 1', '{"modelo": "PROPHET", "dias_proyeccion": 180}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2153, 1000, 1),
(11, 'ALERTA_PREDICTIVA', 'ALERTAS PREDICTIVAS DE IA', 'Evalúa riesgos futuros basados en modelos predictivos', 3403, 3456, 3352, '0 7 * * *', '{"umbral_riesgo_alto": 0.8, "umbral_riesgo_medio": 0.5, "dias_proyeccion": 30}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2156, 1000, 1),
(12, 'ENTRENAR_SARIMAX', 'ENTRENAMIENTO SARIMAX CON VARIABLES EXÓGENAS', 'Entrena SARIMAX incorporando variables externas', 3405, 3451, 3353, '0 3 * * 0', '{"ventana_dias": 90, "incluir_festivos": true, "incluir_clima": true}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(13, 'ENTRENAR_PROPHET', 'ENTRENAMIENTO DE MODELO PROPHET', 'Entrena el modelo Prophet de Facebook', 3405, 3452, 3354, '0 4 1 * *', '{"ventana_dias": 180, "estacionalidad_anual": true, "estacionalidad_semanal": true}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(14, 'PATRON_CONSUMO', 'DETECCIÓN DE PATRONES DE CONSUMO', 'Analiza históricos para identificar patrones estacionales', 3405, 3455, 3354, '0 5 1 * *', '{"min_datos": 90, "umbral_correlacion": 0.7}', NULL, NULL, NULL, NULL, 0, 3, 13, 1, 2151, 1000, 1),
(15, 'VAR_EXOGENA', 'PROCESAMIENTO DE VARIABLES EXÓGENAS', 'Obtiene y procesa variables externas', 3405, 3457, 3352, '0 1 * * *', '{"fuentes": ["API_CLIMA", "API_FESTIVOS", "API_ECONOMIA"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(16, 'VALIDAR_MODELOS', 'VALIDACIÓN CRUZADA DE MODELOS', 'Evalúa y compara el rendimiento de todos los modelos', 3408, 3460, 3354, '0 6 15 * *', '{"k_folds": 5, "metricas": ["MAPE", "RMSE", "MAE", "R2"]}', NULL, NULL, NULL, NULL, 0, 3, 4, 1, 2151, 1000, 1),
(17, 'METRICAS_IA', 'MÉTRICAS DE RENDIMIENTO DE IA', 'Genera reporte de métricas de todos los modelos', 3400, 3458, 3354, '0 7 1 * *', '{"incluir_graficos": true, "formato": "PDF"}', NULL, NULL, NULL, NULL, 0, 3, 16, 1, 2151, 1000, 1),
(18, 'REENTRENAR_AUTO', 'REENTRENAMIENTO AUTOMÁTICO DE MODELOS', 'Reentrena automáticamente si el error supera el umbral', 3405, 3459, 3357, NULL, '{"umbral_mape": 10.0, "min_datos_nuevos": 7, "modelos": ["SARIMA", "PROPHET"]}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, 2151, 1000, 1),
(19, 'BACKUP_MODELOS', 'RESPALDO DE MODELOS DE IA', 'Guarda versionado de todos los modelos entrenados', 3402, 3461, 3353, '0 2 * * 0', '{"retencion_version": 10, "ruta_destino": "/backups/models/"}', NULL, NULL, NULL, NULL, 0, 3, NULL, 0, NULL, 1000, 1),
(20, 'REPORTE_PREDICCIONES', 'REPORTE DE PREDICCIONES Y PROYECCIONES', 'Reporte consolidado de todas las predicciones de IA', 3400, 3461, 3354, '0 8 1 * *', '{"incluir_graficos": true, "formato": "PDF", "destino_email": "gerencia@farmacia.com"}', NULL, NULL, NULL, NULL, 0, 3, 6, 1, 2151, 1000, 1);

UPDATE tareas_programadas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tareas_programadas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tareas_programadas_tarea_id_seq', COALESCE((SELECT MAX(tarea_id) FROM tareas_programadas), 0), (SELECT COUNT(*) > 0 FROM tareas_programadas));

-- ================================================================================================

DELETE FROM control_facturas;
ALTER SEQUENCE control_facturas_control_factura_id_seq RESTART WITH 1;

INSERT INTO control_facturas (control_factura_id, sucursal_id, tipo_comprobante_id, numero_actual, numero_inicial, numero_final, autorizacion, cuf, cufd, cuis, codigo_control, codigo_qr, fecha_autorizacion, fecha_vencimiento, gestion, estado_operativo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1103, 0, 1, 999999, '00000000000000000000', NULL, NULL, NULL, NULL, NULL, '2026-01-01', '2027-12-31', 2026, 3300, 1000, 1);

UPDATE control_facturas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE control_facturas SET usuario_id_actualizacion = 1, fecha_actualizacion = NOW(), usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('control_facturas_control_factura_id_seq', COALESCE((SELECT MAX(control_factura_id) FROM control_facturas), 0), (SELECT COUNT(*) > 0 FROM control_facturas));

-- ================================================================================================

- 1. Inserta un nuevo registro en kardex con evento_id = 1051 (VENTA), vinculando el campo kardex_origen_id con el ID de la proforma o reserva original.
- 2. Inserta los ítems correspondientes en kardex_productos, ejecutando la descarga definitiva del stock físico de los lotes.
- 3. Actualiza el registro de origen cambiando su estado_proforma_id a 4002 (CONVERTIDA) e invoca la lógica de compensación de stock reservado si el evento de origen fue una VENTA_RESERVA (1059), previniendo cualquier doble afectación o descuento duplicado en inventarios.
Reglas de la tabla - kardex (Sección Compras)
- Si todos los ítems recibidos completamente ? 2253 (RECIBIDO)
- Si algunos ítems recibidos parcialmente ? 2254 (PARCIAL)
- Si ninguno recibido ? 2252 (EN_RUTA)
- Si estado_financiero_id = 2400 (CANCELADO), total_pagado = total_compra.
- Si estado_financiero_id = 2401 (PENDIENTE), total_pagado = 0.
- Si estado_financiero_id = 2402 (PARCIAL), 0 < total_pagado < total_compra.
- kardex_referencia_id debe apuntar a la compra original (1050).
- motivo_devolucion_id debe ser distinto de 3506 (NINGUNO).
- total_compra de la devolución debe ser <= total_compra de la compra original.
- El sistema debe generar una nota de crédito si aplica.

DELETE FROM kardex;
ALTER SEQUENCE kardex_kardex_id_seq RESTART WITH 1;

INSERT INTO kardex (kardex_id, tipo_comprobante_id, motivo_anulacion_id, motivo_devolucion_id, cliente_id, proveedor_id, sucursal_id, sucursal_destino_id, kardex_origen_id, kardex_pedido_compra_id, evento_id, codigo, comprobante, comprobante_referencia, kardex_referencia_id, fecha_kardex, total_compra, total_venta, total_venta_factura, total_pagado, total_cambio, saldo_pendiente, lugar_entrega, numero_factura, nota_credito_debito, validez_dias, fecha_expiracion, estado_proforma_id, tipo_factura_id, estado_traspaso_id, estado_financiero_id, estado_pedido_id, tipo_despacho_id, estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja) VALUES 
(1, 1103, 2455, 3506, 1, 1, 1, NULL, NULL, NULL, 1050, 'INI-1-2026-00000000', 'REGISTRO COMODIN SISTEMA', NULL, NULL, CURRENT_TIMESTAMP, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 4000, 2353, 2103, 2403, NULL, 3554, 1000, 1, NULL, NULL, CURRENT_TIMESTAMP, NULL, NULL);

UPDATE kardex SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE kardex SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('kardex_kardex_id_seq', COALESCE((SELECT MAX(kardex_id) FROM kardex), 0), (SELECT COUNT(*) > 0 FROM kardex));

-- ================================================================================================

DELETE FROM ordenes_compra;
ALTER SEQUENCE ordenes_compra_orden_compra_id_seq RESTART WITH 1;

INSERT INTO ordenes_compra (orden_compra_id, kardex_id, proveedor_id, numero_orden, fecha_orden, fecha_entrega_estimada, fecha_entrega_real, estado_pedido_id, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'OC-000000', CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, 2253, 'ORDEN DE COMPRA COMODÍN PARA REGISTROS INICIALES', 1000, 1);

UPDATE ordenes_compra SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ordenes_compra SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1000;

SELECT setval('ordenes_compra_orden_compra_id_seq', COALESCE((SELECT MAX(orden_compra_id) FROM ordenes_compra), 0), (SELECT COUNT(*) > 0 FROM ordenes_compra));

-- ================================================================================================

DELETE FROM instituciones;
ALTER SEQUENCE instituciones_institucion_id_seq RESTART WITH 1;

INSERT INTO instituciones (institucion_id, codigo, institucion, direccion, telefono, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', NULL, NULL, 1000, 1);

UPDATE instituciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE instituciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('instituciones_institucion_id_seq', COALESCE((SELECT MAX(institucion_id) FROM instituciones), 0), (SELECT COUNT(*) > 0 FROM instituciones));

-- ================================================================================================

DELETE FROM especialidades;
ALTER SEQUENCE especialidades_especialidad_id_seq RESTART WITH 1;

INSERT INTO especialidades (especialidad_id, especialidad, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 1000, 1);

UPDATE especialidades SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE especialidades SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('especialidades_especialidad_id_seq', COALESCE((SELECT MAX(especialidad_id) FROM especialidades), 0), (SELECT COUNT(*) > 0 FROM especialidades));

-- ================================================================================================

DELETE FROM medicos;
ALTER SEQUENCE medicos_medico_id_seq RESTART WITH 1;

INSERT INTO medicos (medico_id, medico, matricula, especialidad_id, telefono, email, estado_id, usuario_id_registro) VALUES
(1, 'NINGUNO', 'MAT-000', 1, NULL, NULL, 1000, 1);

UPDATE medicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE medicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('medicos_medico_id_seq', COALESCE((SELECT MAX(medico_id) FROM medicos), 0), (SELECT COUNT(*) > 0 FROM medicos));

-- ================================================================================================

DELETE FROM recetas;
ALTER SEQUENCE recetas_receta_id_seq RESTART WITH 1;

INSERT INTO recetas (receta_id, kardex_id, cliente_id, sucursal_id, medico_id, institucion_id, tipo_receta_id, numero_receta, fecha_emision, diagnostico, receta_pdf, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 3853, 'REC-000', '2024-01-01', NULL, NULL, 1000, 1);

UPDATE recetas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE recetas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('recetas_receta_id_seq', COALESCE((SELECT MAX(receta_id) FROM recetas), 0), (SELECT COUNT(*) > 0 FROM recetas));

-- ================================================================================================

DELETE FROM lotes_productos;
ALTER SEQUENCE lotes_productos_lote_id_seq RESTART WITH 1;

INSERT INTO lotes_productos (lote_id, producto_id, kardex_id, codigo, fecha_vencimiento, cantidad_inicial, cantidad_actual, cantidad_reservada, precio_costo, fecha_fabricacion, lote_proveedor, ubicacion_id, rating_calidad_id, estado_lote_id, estado_id, usuario_id_registro) VALUES 
(1, 1, 1, 'NINGUNO', '2099-12-31', 1.00, 0.00, 0.00, 0.00, NULL, NULL, 1, 2055, 2503, 1000, 1);

UPDATE lotes_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE lotes_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('lotes_productos_lote_id_seq', COALESCE((SELECT MAX(lote_id) FROM lotes_productos), 0), (SELECT COUNT(*) > 0 FROM lotes_productos));

-- ================================================================================================

Reglas de la tabla - kardex_productos (Sección Compras)
- Cada detalle debe tener cantidad > 0.
- El lote_id debe ser nuevo (creado automáticamente al insertar la compra).
- precio_costo del lote debe ser igual a pcompra del detalle.
- La sumatoria de cantidades_salida de todos los detalles debe ser < cantidad_total_solicitada.
- Debe existir al menos un detalle con cantidad_salida > 0.
- cantidad_salida > 0.
- cantidad_salida <= cantidad disponible en el lote original.
- La sumatoria de cantidades devueltas no puede exceder la cantidad comprada original.';

DELETE FROM kardex_productos;
ALTER SEQUENCE kardex_productos_kardex_producto_id_seq RESTART WITH 1;

INSERT INTO kardex_productos (kardex_producto_id, kardex_id, producto_id, sucursal_id, lote_id, presentacion_id, tipo_pago_id, tipo_venta_id, cantidad, cantidad_unidad_base, cantidad_salida, pcompra, factor_venta, factor_facturacion, precio_venta, precio_venta_factura, costo_venta, descuento, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 1, 1400, 1350, 0.00, 0.00, 0.00, 0.00, 1.00, 1.00, 0.00, 0.00, 0.00, 0.00, 1000, 1);

UPDATE kardex_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE kardex_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('kardex_productos_kardex_producto_id_seq', COALESCE((SELECT MAX(kardex_producto_id) FROM kardex_productos), 0), (SELECT COUNT(*) > 0 FROM kardex_productos));

-- ================================================================================================

DELETE FROM inventarios_fisicos_detalle;
ALTER SEQUENCE inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq RESTART WITH 1;

INSERT INTO inventarios_fisicos_detalle (inventario_fisico_detalle_id, inventario_fisico_id, producto_id, lote_id, ubicacion_id, cantidad_sistema, cantidad_contada, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 0.00, 0.00, 'REGISTRO INICIAL COMODIN DE DETALLE DE INVENTARIO FISICO', 1000, 1);

UPDATE inventarios_fisicos_detalle SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE inventarios_fisicos_detalle SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('inventarios_fisicos_detalle_inventario_fisico_detalle_id_seq', COALESCE((SELECT MAX(inventario_fisico_detalle_id) FROM inventarios_fisicos_detalle), 0), (SELECT COUNT(*) > 0 FROM inventarios_fisicos_detalle));

-- ================================================================================================

DELETE FROM ubicaciones_movimientos;
ALTER SEQUENCE ubicaciones_movimientos_ubicacion_movimiento_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_movimientos (ubicacion_movimiento_id, kardex_producto_id, ubicacion_origen_id, ubicacion_destino_id, lote_id, cantidad, tipo_ubicacion_movimiento_id, motivo, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, 1, 1.00, 3200, 'REGISTRO INICIAL COMODIN DE MOVIMIENTO', 1000, 1);

UPDATE ubicaciones_movimientos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones_movimientos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_movimientos_ubicacion_movimiento_id_seq', COALESCE((SELECT MAX(ubicacion_movimiento_id) FROM ubicaciones_movimientos), 0), (SELECT COUNT(*) > 0 FROM ubicaciones_movimientos));

-- ================================================================================================

- Ventas: Registra la salida de productos del almacén al cliente.
- Compras: Registra la entrada de productos al almacén desde proveedores.
- Inventario: Registra reubicaciones, ajustes y traspasos.
- Devoluciones: Registra movimientos de productos devueltos.
- Caducidad: Registra movimientos de productos vencidos a zonas de cuarentena.';

DELETE FROM ubicaciones_historial;
ALTER SEQUENCE ubicaciones_historial_ubicacion_historial_id_seq RESTART WITH 1;

INSERT INTO ubicaciones_historial (ubicacion_historial_id, producto_id, ubicacion_origen_id, ubicacion_destino_id, kardex_producto_id, cantidad, motivo, usuario_id, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, NULL, 1.00, 'Registro predeterminado inicial de ubicación', 1, 1000, 1);

UPDATE ubicaciones_historial SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE ubicaciones_historial SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('ubicaciones_historial_ubicacion_historial_id_seq', COALESCE((SELECT MAX(ubicacion_historial_id) FROM ubicaciones_historial), 0), (SELECT COUNT(*) > 0 FROM ubicaciones_historial));

-- ================================================================================================

DELETE FROM tipos_planes_pago;
ALTER SEQUENCE tipos_planes_pago_tipo_plan_pago_id_seq RESTART WITH 1;

INSERT INTO tipos_planes_pago (tipo_plan_pago_id, codigo, nombre, meses_plazo, porcentaje_recargo, monto_fijo_recargo, permite_personalizar, descripcion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 0, 0.00, 0.00, 0, 'Pago por defecto.', 1000, 1),
(2, '3M', 'Plan a 3 Meses', 3, 5.00, 0.00, 0, 'Fraccionado a 3 meses con un recargo financiero del 5% sobre capital.', 1000, 1),
(3, '6M', 'Plan a 6 Meses', 6, 10.00, 0.00, 0, 'Fraccionado a 6 meses con un recargo financiero del 10% sobre capital.', 1000, 1),
(4, '12M', 'Plan a 12 Meses', 12, 18.00, 0.00, 0, 'Fraccionado a 12 meses con un recargo financiero del 18% sobre capital.', 1000, 1),
(5, 'PER', 'Plan Personalizado', 0, 0.00, 0.00, 1, 'Plan a medida donde el usuario define fechas y porcentajes por cuota.', 1000, 1);

UPDATE tipos_planes_pago SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE tipos_planes_pago SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('tipos_planes_pago_tipo_plan_pago_id_seq', COALESCE((SELECT MAX(tipo_plan_pago_id) FROM tipos_planes_pago), 0), (SELECT COUNT(*) > 0 FROM tipos_planes_pago));

-- ================================================================================================

Reglas de la tabla - planes_pagos (Sección Compras)
- El backend debe generar automáticamente las cuotas mensuales.
- La primera cuota vence a los 30 días de fecha_kardex.
- Las siguientes cuotas vencen cada 30 días.
- El monto_programado de cada cuota = (total_compra + recargo) / meses_plazo.
- permite_personalizar = 1.
- El usuario puede definir montos y fechas de vencimiento individuales.
- La suma de los montos_programado debe ser igual a total_compra + recargo.
- monto_pagado = 0 ? 2550 (PENDIENTE)
- 0 < monto_pagado < monto_programado ? 2551 (PARCIAL)
- monto_pagado = monto_programado ? 2552 (PAGADO)';

DELETE FROM planes_pagos;
ALTER SEQUENCE planes_pagos_plan_pago_id_seq RESTART WITH 1;

INSERT INTO planes_pagos (plan_pago_id, kardex_id, numero_cuota, monto_programado, fecha_vencimiento, estado_pago_id, fecha_pago, monto_pagado, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, '2026-01-01', 2553, '2026-01-01', 0.00, 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

UPDATE planes_pagos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE planes_pagos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('planes_pagos_plan_pago_id_seq', COALESCE((SELECT MAX(plan_pago_id) FROM planes_pagos), 0), (SELECT COUNT(*) > 0 FROM planes_pagos));

-- ================================================================================================

DELETE FROM comprobantes_pagos;
ALTER SEQUENCE comprobantes_pagos_comprobante_pago_id_seq RESTART WITH 1;

INSERT INTO comprobantes_pagos (comprobante_pago_id, kardex_id, banco_id, tipo_pago_id, tipo_moneda_id, codigo_transaccion, monto, fecha_pago, titular_cuenta, autorizacion_nro, cuenta_destino, comprobante_digital_ruta, confirmado, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 2300, 'SN', 0.01, CURRENT_DATE, 'NINGUNO', NULL, NULL, NULL, 0, 1000, 1);

UPDATE comprobantes_pagos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE comprobantes_pagos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('comprobantes_pagos_comprobante_pago_id_seq', COALESCE((SELECT MAX(comprobante_pago_id) FROM comprobantes_pagos), 0), (SELECT COUNT(*) > 0 FROM comprobantes_pagos));

-- ================================================================================================

Reglas de la tabla - pagos (Sección Compras)
- Se actualiza total_pagado en kardex.
- Se actualiza saldo_pendiente = total_compra - total_pagado.
- Si saldo_pendiente = 0, estado_financiero_id = 2400 (CANCELADO).
- Si saldo_pendiente > 0, estado_financiero_id = 2402 (PARCIAL).

DELETE FROM pagos;
ALTER SEQUENCE pagos_pago_id_seq RESTART WITH 1;

INSERT INTO pagos (pago_id, kardex_id, plan_pago_id, tipo_pago_id, comprobante_pago_id, monto, fecha_pago, referencia, comprobante, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1400, 1, 1.00, '2026-01-01', 'NINGUNO', 'NINGUNO', 'REGISTRO COMODIN OBLIGATORIO', 1000, 1);

UPDATE pagos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE pagos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('pagos_pago_id_seq', COALESCE((SELECT MAX(pago_id) FROM pagos), 0), (SELECT COUNT(*) > 0 FROM pagos));

-- ================================================================================================

DELETE FROM cajas;
ALTER SEQUENCE cajas_caja_id_seq RESTART WITH 1;

INSERT INTO cajas (caja_id, sucursal_id, apertura_usuario_id, cierre_usuario_id, autorizacion_usuario_id, fecha_apertura, fecha_cierre, fecha_autorizacion, monto_inicial, monto_ingresos, monto_egresos, monto_ventas, monto_final_esperado, monto_final_real, diferencia, total_transacciones, total_ventas, total_devoluciones, total_retiros, estado_caja_id, observaciones, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, NULL, '2026-01-01 00:00:00-04', NULL, NULL, 0.00, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 0, 0, 0, 0, 2650, 'COMODIN INICIAL DE SISTEMA', 1000, 1);

UPDATE cajas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE cajas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('cajas_caja_id_seq', COALESCE((SELECT MAX(caja_id) FROM cajas), 0), (SELECT COUNT(*) > 0 FROM cajas));

-- ================================================================================================

DELETE FROM movimientos;
ALTER SEQUENCE movimientos_movimiento_id_seq RESTART WITH 1;

INSERT INTO movimientos (movimiento_id, caja_id, referencia_id, usuario_id, tipo_movimiento_id, tipo_pago_id, monto, saldo_antes, saldo_despues, motivo, fecha_movimiento, estado_id, usuario_id_registro) VALUES
(1, 1, NULL, 1, 2600, 1400, 0.01, 0.00, 0.01, 'REGISTRO COMODIN OBLIGATORIO', CURRENT_TIMESTAMP, 1000, 1);

UPDATE movimientos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE movimientos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('movimientos_movimiento_id_seq', COALESCE((SELECT MAX(movimiento_id) FROM movimientos), 0), (SELECT COUNT(*) > 0 FROM movimientos));

-- ================================================================================================

DELETE FROM arqueos_detalle;
ALTER SEQUENCE arqueos_detalle_arqueo_detalle_id_seq RESTART WITH 1;

INSERT INTO arqueos_detalle (arqueo_detalle_id, caja_id, tipo_billete_id, cantidad, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 4300, 0, 0.00, 1000, 1);

UPDATE arqueos_detalle SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE arqueos_detalle SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('arqueos_detalle_arqueo_detalle_id_seq', COALESCE((SELECT MAX(arqueo_detalle_id) FROM arqueos_detalle), 0), (SELECT COUNT(*) > 0 FROM arqueos_detalle));

-- ================================================================================================

{
    "automatizacion": {
        "frecuencia_minutos": 60,
        "repeticiones": 3,
        "ultima_repeticion": "2026-07-24T10:00:00Z",
        "accion": {
            "nombre": "ENVIAR_CORREO",
            "fecha_ejecucion": "2026-07-24T10:05:00Z",
            "exitosa": true,
            "resultado": "Correo enviado exitosamente"
        }
    }
}';

DELETE FROM alertas_notificaciones;
ALTER SEQUENCE alertas_notificaciones_alerta_notificacion_id_seq RESTART WITH 1;

INSERT INTO alertas_notificaciones (alerta_notificacion_id, sucursal_id, codigo, tipo_alerta_notificacion_id, subtipo_alerta_id, origen_alerta_id, nivel_critico_id, titulo, mensaje, entidad_afectada_tipo_id, entidad_afectada_id, metadata, estado_alerta_id, usuario_asignado_id, fecha_asignacion, es_leido, fecha_lectura, usuario_resolutor_id, fecha_resolucion, comentarios_resolucion, accion_tomada, estado_id, usuario_id_registro) VALUES
(1, 1, 'ALN-000', 2700, 2812, 2850, 2905, 'NINGUNO', 'REGISTRO COMODIN POR DEFECTO', 4111, NULL, '{}'::jsonb, 2953, 1, NULL, 1, CURRENT_TIMESTAMP, 1, NULL, NULL, NULL, 1000, 1);

UPDATE alertas_notificaciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE alertas_notificaciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

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

UPDATE modelos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE modelos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('modelos_modelo_id_seq', COALESCE((SELECT MAX(modelo_id) FROM modelos), 0), (SELECT COUNT(*) > 0 FROM modelos));

-- ================================================================================================

DELETE FROM entrenamientos;
ALTER SEQUENCE entrenamientos_entrenamiento_id_seq RESTART WITH 1;

INSERT INTO entrenamientos (entrenamiento_id, modelo_id, fecha_ejecucion, fecha_inicio, fecha_fin, estado_ejecucion_id, duracion_segundos, registros_procesados, total_esperado, mensaje_error, estado_id, usuario_id_registro) VALUES
(1, 1, '2026-07-16 14:00:00-04', '2026-07-16 13:55:00-04', '2026-07-16 14:00:00-04', 3051, 300, 15000, 15000, NULL, 1000, 1);

UPDATE entrenamientos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE entrenamientos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('entrenamientos_entrenamiento_id_seq', COALESCE((SELECT MAX(entrenamiento_id) FROM entrenamientos), 0), (SELECT COUNT(*) > 0 FROM entrenamientos));

-- ================================================================================================

DELETE FROM metricas_rendimiento;
ALTER SEQUENCE metricas_rendimiento_metrica_id_seq RESTART WITH 1;

INSERT INTO metricas_rendimiento (metrica_id, entrenamiento_id, tipo_metricas_id, metrica_precision_id, version_metricas, modelo_version, periodo_evaluacion, error_absoluto_medio, raiz_error_cuadratico_medio, score_principal, detalles_metricas, estado_id, usuario_id_registro) VALUES
(1, 1, 3103, 3600, 1, '0.0.0', CURRENT_DATE, 0.0000, 0.0000, 0.0000, '{"comodin": true}'::jsonb, 1000, 1);

UPDATE metricas_rendimiento SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE metricas_rendimiento SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('metricas_rendimiento_metrica_id_seq', COALESCE((SELECT MAX(metrica_id) FROM metricas_rendimiento), 0), (SELECT COUNT(*) > 0 FROM metricas_rendimiento));

-- ================================================================================================

DELETE FROM patrones_consumo;
ALTER SEQUENCE patrones_consumo_patron_id_seq RESTART WITH 1;

INSERT INTO patrones_consumo (patron_id, producto_id, sucursal_id, entrenamiento_id, temporada_id, evento, factor_estacional, coeficiente_tendencia, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1600, 'NINGUNO', 0.00, 0.00, NULL, NULL, 1000, 1);

UPDATE patrones_consumo SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE patrones_consumo SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('patrones_consumo_patron_id_seq', COALESCE((SELECT MAX(patron_id) FROM patrones_consumo), 0), (SELECT COUNT(*) > 0 FROM patrones_consumo));

-- ================================================================================================

DELETE FROM variables_exogenas;
ALTER SEQUENCE variables_exogenas_variable_exogena_id_seq RESTART WITH 1;

INSERT INTO variables_exogenas (variable_exogena_id, producto_id, sucursal_id, fuente_exogena_id, nombre_variable, valor, fecha_variable, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 4250, 'NINGUNO', 0.0000, '2000-01-01', 1000, 1);

UPDATE variables_exogenas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE variables_exogenas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('variables_exogenas_variable_exogena_id_seq', COALESCE((SELECT MAX(variable_exogena_id) FROM variables_exogenas), 0), (SELECT COUNT(*) > 0 FROM variables_exogenas));

-- ================================================================================================

DELETE FROM umbrales_configuracion;
ALTER SEQUENCE umbrales_configuracion_umbral_id_seq RESTART WITH 1;

INSERT INTO umbrales_configuracion (umbral_id, tipo_umbral_id, producto_id, sucursal_id, valor_umbral, nivel_urgencia_id, activo, estado_id, usuario_id_registro) VALUES
(1, 3253, 1, 1, 0.00, 1854, 0, 1000, 1);

UPDATE umbrales_configuracion SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE umbrales_configuracion SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('umbrales_configuracion_umbral_id_seq', COALESCE((SELECT MAX(umbral_id) FROM umbrales_configuracion), 0), (SELECT COUNT(*) > 0 FROM umbrales_configuracion));

-- ================================================================================================

DELETE FROM logs_ejecucion;
ALTER SEQUENCE logs_ejecucion_log_id_seq RESTART WITH 1;

INSERT INTO logs_ejecucion (log_id, entrenamiento_id, modulo, nivel_log_id, mensaje, detalle, fecha_log, estado_id, usuario_id_registro) VALUES
(1, 1, 'PROCESAMIENTO_ARIMA', 3150, 'Inicio de analisis estacional', '{"productos": 12, "duracion_seg": 45}'::jsonb, CURRENT_TIMESTAMP, 1000, 1);

UPDATE logs_ejecucion SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE logs_ejecucion SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('logs_ejecucion_log_id_seq', COALESCE((SELECT MAX(log_id) FROM logs_ejecucion), 0), (SELECT COUNT(*) > 0 FROM logs_ejecucion));

-- ================================================================================================

- 1550 (PENDIENTE): Pronóstico en cola de espera o en proceso de cálculo. No debe mostrarse en dashboards operativos.
- 1551 (PROCESADO): Pronóstico completado exitosamente con todos los datos calculados (demanda, ROP, stock, etc.). Es el estado operativo para consumo en el negocio.
- 1552 (ERROR): Pronóstico fallido. Puede deberse a datos insuficientes, errores en el modelo o fallos técnicos. Requiere revisión manual en logs_ejecucion.
- 1553 (NINGUNO): Estado por defecto para registros comodín o productos que no han sido procesados por el motor de IA.
El backend debe cambiar automáticamente el estado a PROCESADO al finalizar exitosamente el entrenamiento y a ERROR si ocurre alguna excepción durante el proceso.
- 1: Productos de categoría A (alta prioridad, alta rotación, alto valor, críticos para el negocio)
- 2: Productos de categoría B (prioridad media, rotación regular, valor moderado)
- 3: Productos de categoría C (baja prioridad, baja rotación, bajo valor)
- 0: Sin clasificar o cuando la clasificación no ha sido generada aún
Este campo se actualiza periódicamente (generalmente mensualmente) mediante tareas programadas y sirve como base para estrategias de compras, promociones y gestión de inventario.
- Demanda promedio histórica (ventana configurable)
- Lead time (tiempo de entrega del proveedor)
- Nivel de servicio deseado (configurable en parametros_globales)
- Estacionalidad detectada en patrones_consumo
- Desviación estándar de la demanda
El sistema debe actualizar estos valores automáticamente y generar alertas cuando el stock actual caiga por debajo del punto_reorden (a través de alertas_notificaciones).
- Específico por producto/sucursal (calculado históricamente)
- Heredado del proveedor principal (proveedores.plazo_entrega_dias)
- Valor por defecto de parametros_globales (modelo_rop_lead_time_default)
El sistema debe usar este valor para calcular el punto de reorden y las fechas estimadas de llegada de nuevas compras.
- Calcular automáticamente esta fecha a partir de lotes_productos.fecha_vencimiento
- Actualizar el campo cuando se registren nuevas compras o se vendan lotes
- Generar alertas según los umbrales configurados (dias_alerta_vencimiento_critico, etc.)
- Si fecha_vencimiento_critico < CURRENT_DATE + 15 días, nivel_urgencia_id debe ser 1853 (CRITICA) automáticamente
- 1854 (NINGUNO): Producto sin urgencia o sin análisis
- 1853 (CRITICA): Quiebre de stock inminente, vencimiento inmediato (15 días), demanda alta inusual
- 1852 (ALTA): Stock bajo (cerca del punto de reorden), vencimiento próximo (30 días)
- 1851 (MEDIA): Producto con tendencia de consumo creciente, vencimiento moderado (60 días)
- 1850 (BAJA): Producto con demanda estable, stock suficiente, vencimiento lejano
El sistema debe calcular automáticamente este valor durante cada ejecución analítica y actualizarlo en función de las alertas generadas.
- 1900 (BLOQUEO): Bloqueo de caminos, protestas, desastres naturales
- 1901 (FERIADO_LOCAL): Día festivo no considerado en el calendario estándar
- 1902 (ERROR_SISTEMA): Fallos en integración de datos, registros inconsistentes
- 1903 (PICO_ANORMAL): Evento puntual de demanda excepcional (epidemia, campaña)
- 1904 (ROTURA): Producto dañado o deteriorado
- 1905 (ROBO): Sustracción de mercadería
- 1906 (SOBRANTE): Excedente detectado en inventario físico
- 1907 (NINGUNO): Sin motivo o cuando no se aplica
Este campo es obligatorio cuando estado_pronostico_id = 1552 (ERROR) y debe ser registrado por el sistema o por el usuario encargado.
- Rotación del producto (cantidad vendida por período)
- Margen de ganancia (precio_venta - pcompra)
- Criticidad médica (criticidad_medica_id)
- Frecuencia de quiebres de stock (alertas generadas)
- Importancia estratégica para la sucursal
Este puntaje se utiliza para priorizar acciones de compra, promociones y asignación de recursos.
- periodo_inicio <= periodo_fin (validado por chk_an_periodo)
- El período de predicción no supere el límite configurado en parametros_globales (dias_proyeccion)
- Los campos pueden ser NULL si la predicción es puntual (sin horizonte definido)
- Para predicciones mensuales, periodo_inicio = primer día del mes y periodo_fin = último día del mes
- tareas_programadas: Las tareas de tipo FORECASTING generan registros automáticos en esta tabla
- entrenamientos: Cada ejecución de entrenamiento actualiza los registros en analitica_productos
- metricas_rendimiento: Las métricas calculadas se asocian a los pronósticos generados
- alertas_notificaciones: Los umbrales y niveles de urgencia disparan alertas automáticas
- umbrales_configuracion: Los valores de umbral (stock mínimo, error, etc.) definen los límites de actuación
- patrones_consumo: Los patrones estacionales detectados influyen en los cálculos de demanda y ROP
- Mantener datos de los últimos 12 meses en estado ACTIVO
- Históricos de 12-36 meses en estado HISTORICO (accesibles para reporting)
- Datos de más de 36 meses pueden ser archivados o eliminados después de validación
- Esta política debe ser configurable en parametros_globales
- Actualizar productos.punto_reorden con el valor calculado (si es mayor que el actual)
- Actualizar productos.stock_minimo con el valor de stock_seguridad
- Si el punto_reorden recomendado supera el stock_minimo actual, generar una alerta en alertas_notificaciones
- Registrar el cambio en logs_ejecucion para trazabilidad
- demanda_pronosticada >= 0
- intervalo_inf >= 0 y intervalo_sup >= 0
- punto_reorden >= 0 y stock_seguridad >= 0
- lead_time_dias > 0 (si es calculado)
- Si intervalo_inf > intervalo_sup, intercambiar automáticamente los valores o rechazar el registro
- Si demanda_pronosticada = 0, configurar automáticamente punto_reorden = 0 y stock_seguridad = 0
- Crear automáticamente un registro en analitica_productos con estado_pronostico_id = 1553 (NINGUNO)
- No generar predicciones hasta que el producto tenga al menos 30 días de datos históricos (parametros_globales.entrenamiento_min_registros)
- Una vez superado el umbral de datos, incluir el producto en la próxima ejecución de entrenamiento
- Dashboard de inteligencia de negocio (módulo NÚCLEO ANALÍTICO Y PREDICCIONES)
- Reportes de proyección de ventas (REPORTE_PREDICCIONES)
- Panel de control de inventario (punto_reorden, stock_seguridad vs stock_actual)
- Alertas de vencimiento y quiebre de stock
- Análisis de eficiencia de modelos (comparando predicciones vs ventas reales)
- idx_an_producto_sucursal_fecha: Indexa por producto, sucursal y fecha descendente para consultas de último pronóstico
- idx_an_producto_id: Indexa por producto para búsquedas rápidas
- idx_an_sucursal_id: Indexa por sucursal para análisis de cadena
- idx_an_cluster: Indexa por clasificación ABC para filtrado y segmentación
- idx_an_fecha_clasificacion: Indexa por fecha para reportes históricos
- idx_an_nivel_urgencia: Indexa por nivel de urgencia para bandejas de alertas
- idx_an_vencimiento: Indexa por fecha de vencimiento crítico para alertas tempranas
- idx_an_estado_pronostico: Indexa por estado para filtrar pronósticos pendientes o en error
- idx_an_motivo_outlier: Indexa por motivo de outlier para análisis de causas de error';

DELETE FROM analitica_productos;
ALTER SEQUENCE analitica_productos_analitica_id_seq RESTART WITH 1;

INSERT INTO analitica_productos (analitica_id, producto_id, sucursal_id, demanda_pronosticada, intervalo_inf, intervalo_sup, fecha_prediccion, periodo_inicio, periodo_fin, fecha_vencimiento_critico, nivel_urgencia_id, punto_reorden, stock_seguridad, lead_time_dias, cluster_abc, fecha_clasificacion, puntaje_total, estado_pronostico_id, motivo_outlier_id, estado_id, usuario_id_registro, usuario_id_actualizacion, usuario_id_baja, fecha_registro, fecha_actualizacion, fecha_baja) VALUES
(1, 1, 1, 120.50, 100.00, 140.00, CURRENT_TIMESTAMP, '2026-08-01', '2026-08-31', '2027-01-15', 1854, 45.00, 15.00, 5, 0, CURRENT_DATE, 85.50, 1553, NULL, 1000, 1, NULL, NULL, CURRENT_TIMESTAMP, NULL, NULL);

UPDATE analitica_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE analitica_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('analitica_productos_analitica_id_seq', COALESCE((SELECT MAX(analitica_id) FROM analitica_productos), 0), (SELECT COUNT(*) > 0 FROM analitica_productos));

-- ================================================================================================

- 3700 (PENDIENTE): Pedido recibido, pendiente de confirmación por la farmacia.
- 3701 (CONFIRMADO): Pedido confirmado por la farmacia, se inicia la preparación.
- 3702 (PREPARANDO): Pedido en proceso de picking y empaque en el almacén.
- 3703 (EN_CAMINO): Pedido despachado, en ruta de entrega al cliente.
- 3704 (ENTREGADO): Pedido entregado exitosamente al cliente.
- 3705 (CANCELADO): Pedido cancelado por el cliente o la farmacia antes de la entrega.
- 3706 (RECHAZADO): Pedido rechazado por el cliente en el momento de la entrega (ej. producto dañado).
- 2550 (PENDIENTE): Pedido sin abonos registrados, esperando pago.
- 2551 (PARCIAL): Pedido con abonos parciales (ej. anticipo).
- 2552 (PAGADO): Pedido totalmente pagado.
- 2553 (CERRADO): Pedido cerrado contablemente.
- 2554 (EN_VERIFICACION): Pago en proceso de verificación bancaria.
- 2555 (NINGUNO): Sin estado de pago definido (para pedidos sin pago previo).
- Generar una transacción de VENTA (evento_id = 1051) en la tabla kardex.
- Registrar el ID de la transacción en el campo kardex_id.
- Descontar el stock de los lotes correspondientes.
- Actualizar el estado del pedido a CONFIRMADO (3701) o PREPARANDO (3702).
El campo kardex_id permanece NULL mientras el pedido esté en estado PENDIENTE o no se haya convertido en venta.
- fecha_pedido: Momento en que el cliente realiza el pedido.
- fecha_entrega_estimada: Calculada por el sistema según la disponibilidad de stock y la ubicación del cliente.
- fecha_entrega_real: Se actualiza automáticamente cuando el pedido alcanza el estado ENTREGADO (3704) o RECHAZADO (3706).
- La ubicación del cliente (cercanía).
- La disponibilidad de stock en la sucursal.
- La configuración de cobertura de entregas de cada sucursal.
La sucursal asignada es responsable del despacho y la entrega.
- subtotal >= 0 (suma de los precios unitarios por cantidad).
- costo_envio >= 0 (puede ser 0 para pedidos que superen un monto mínimo).
- descuentos >= 0 (descuentos aplicados por cupones o promociones).
- total >= 0 (total a pagar por el cliente).
1. El cliente realiza el pedido en la tienda virtual (estado PENDIENTE).
2. La farmacia confirma el pedido y verifica stock (estado CONFIRMADO).
3. El personal prepara el pedido en el almacén (estado PREPARANDO).
4. Se asigna un repartidor y se despacha el pedido (estado EN_CAMINO).
5. El repartidor entrega el pedido (estado ENTREGADO) o lo rechaza (RECHAZADO).
6. El pedido se convierte en una transacción de VENTA en el kardex (kardex_id se actualiza con el ID de la venta).
7. El pedido se archiva en HISTORICO para conservar la trazabilidad.
- idx_peo_cliente: Consultas de historial de pedidos por cliente.
- idx_peo_estado: Filtrado de pedidos pendientes para el dashboard de preparación.
- idx_peo_fecha_pedido: Reportes de pedidos por período.
- idx_peo_sucursal_estado: Consultas de pedidos por sucursal para el módulo de delivery.
- Identifique pedidos en estado PENDIENTE con fecha_pedido > 30 días.
- Automáticamente los cambie a estado CANCELADO (3705).
- Registre el evento en logs_ejecucion con motivo: "PEDIDO_EXPIRADO_POR_TIEMPO".
- El cliente_id exista y esté ACTIVO (estado_id = 1000).
- El cliente tenga habilitado_ventas = 1.
- La sucursal_id exista, esté ACTIVA y tenga cobertura de delivery configurada.
- La sucursal tenga stock suficiente para cubrir el pedido (se valida al confirmar, no al crear).
- modulo = ''PEDIDOS_ONLINE''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Pedido {codigo} cambió de estado {estado_anterior} a {estado_nuevo}''
- detalle = { "usuario": usuario_id, "motivo": "..." }
1. Intentar reasignar el pedido a otra sucursal con stock disponible.
2. Si no es posible, rechazar el pedido (estado RECHAZADO = 3706).
3. Notificar al cliente vía email (usando el módulo de notificaciones).
4. Registrar el motivo en observaciones.
- El cupón debe estar ACTIVO (estado_id = 1000).
- La fecha actual debe estar entre fecha_inicio y fecha_fin.
- El número de usos_realizados < uso_maximo.
- El cliente no debe haber excedido el uso_por_cliente.
- Solo se permite si el pedido está en estado PENDIENTE (3700) o CONFIRMADO (3701).
- No se permite cancelar pedidos en estado PREPARANDO (3702), EN_CAMINO (3703) o ENTREGADO (3704).
- La cancelación debe registrar un motivo obligatorio (observaciones).
- Si el pedido ya tenía kardex_id asociado (venta generada), la cancelación debe generar una ANULACION (evento_id = 1055).';

DELETE FROM pedidos_online;
ALTER SEQUENCE pedidos_online_pedido_online_id_seq RESTART WITH 1;

INSERT INTO pedidos_online (pedido_online_id, cliente_id, sucursal_id, kardex_id, codigo, fecha_pedido, fecha_entrega_estimada, fecha_entrega_real, direccion_entrega, telefono_contacto, instrucciones_entrega, estado_pedido_online_id, estado_pago_id, subtotal, costo_envio, descuentos, total, repartidor_id, ultima_actualizacion, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'WEB-0000', CURRENT_TIMESTAMP, NULL, NULL, 'NINGUNO', '00000000', NULL, 3700, 2555, 0.00, 0.00, 0.00, 0.00, NULL, NULL, 1000, 1);

UPDATE pedidos_online SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE pedidos_online SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('pedidos_online_pedido_online_id_seq', COALESCE((SELECT MAX(pedido_online_id) FROM pedidos_online), 0), (SELECT COUNT(*) > 0 FROM pedidos_online));

-- ================================================================================================

INSERT INTO detalles_pedidos_online (detalle_pedido_online_id, pedido_online_id, producto_id, kardex_producto_id, codigo_producto, nombre_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, NULL, 'NIN', 'NINGUNO', 1.00, 0.00, 0.00, 0.00, 1000, 1);

UPDATE detalles_pedidos_online SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE detalles_pedidos_online SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('detalles_pedidos_online_detalle_pedido_online_id_seq', COALESCE((SELECT MAX(detalle_pedido_online_id) FROM detalles_pedidos_online), 0), (SELECT COUNT(*) > 0 FROM detalles_pedidos_online));

-- ================================================================================================

INSERT INTO carritos_compra (carrito_id, cliente_id, fecha_creacion, fecha_actualizacion_carrito, fecha_expiracion, cliente_nombre, cliente_documento, total_items, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', 'NINGUNO', '0', 0, 0.00, 1000, 1);

UPDATE carritos_compra SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE carritos_compra SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('carritos_compra_carrito_id_seq', COALESCE((SELECT MAX(carrito_id) FROM carritos_compra), 0), (SELECT COUNT(*) > 0 FROM carritos_compra));

-- ================================================================================================

- idx_dca_carrito: Consulta rápida del contenido de un carrito.
- idx_dca_producto: Reportes de productos más agregados a carritos.
- Identifique carritos en estado ACTIVO con fecha_expiracion < CURRENT_TIMESTAMP.
- Cambie su estado a HISTORICO (1002).
- Los detalles asociados también deben pasar a HISTORICO.
- modulo = ''CARRITOS_COMPRA''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Carrito {carrito_id}: Producto {producto_id} cambió cantidad de {cantidad_anterior} a {cantidad_nueva}''
- Crear un registro en pedidos_online con los datos del carrito.
- Crear los detalles en detalles_pedidos_online copiando los datos del carrito.
- Marcar el carrito y sus detalles como HISTORICO (estado_id = 1002).
- async recalcularTotales(carritoId: number): Promise<void>
- Este método debe calcular la suma de cantidad y subtotal de todos los detalles ACTIVOS del carrito.
- Debe actualizar los campos total_items y subtotal en la tabla carritos_compra.
- Debe actualizar la fecha_actualizacion_carrito y fecha_actualizacion con CURRENT_TIMESTAMP.
- Este método debe ser llamado después de cada INSERT, UPDATE o DELETE sobre detalles_carritos.
- modulo = ''CARRITOS_COMPRA''
- nivel_log_id = 3150 (INFO) para operaciones normales, 3151 (WARNING) para advertencias, 3152 (ERROR) para errores.
- mensaje = Descripción clara de la operación realizada.
- detalle = JSON con los datos afectados (antes/después).';

DELETE FROM detalles_carritos;
ALTER SEQUENCE detalles_carritos_detalle_carrito_id_seq RESTART WITH 1;

INSERT INTO detalles_carritos (detalle_carrito_id, carrito_id, producto_id, codigo_producto, nombre_producto, presentacion_producto, cantidad, precio_unitario, descuento_unitario, subtotal, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 'NIN', 'NINGUNO', NULL, 1.00, 0.00, 0.00, 0.00, 1000, 1);

UPDATE detalles_carritos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE detalles_carritos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('detalles_carritos_detalle_carrito_id_seq', COALESCE((SELECT MAX(detalle_carrito_id) FROM detalles_carritos), 0), (SELECT COUNT(*) > 0 FROM detalles_carritos));

-- ================================================================================================

- Identificar el perfil del cliente (tipo_cliente_id).
- Seleccionar la lista de precios con mayor prioridad.
- Obtener el precio de precios_productos.
- Si no existe precio para la lista seleccionada, buscar en la lista por defecto (PUB).';

DELETE FROM listas_precios;
ALTER SEQUENCE listas_precios_lista_precio_id_seq RESTART WITH 1;

INSERT INTO listas_precios (lista_precio_id, codigo, nombre, descripcion, es_publica, prioridad, requiere_autorizacion, estado_id, usuario_id_registro) VALUES
(1, 'NIN', 'NINGUNO', 'Lista de precios predeterminada para productos sin clasificar', 0, 999, 0, 1000, 1);

UPDATE listas_precios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE listas_precios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('listas_precios_lista_precio_id_seq', COALESCE((SELECT MAX(lista_precio_id) FROM listas_precios), 0), (SELECT COUNT(*) > 0 FROM listas_precios));

-- ================================================================================================

- Copiar el precio del producto base (productos.pventa o pventaf) a la lista PÚBLICO GENERAL.
- Establecer los precios de otras listas aplicando los porcentajes de descuento configurados en parametros_globales.
- Categoría (todos los productos de una categoría).
- Laboratorio (todos los productos de un laboratorio).
- Lista de precios específica.
- Porcentaje de incremento o decremento.
- modulo = ''PRECIOS_PRODUCTOS''
- nivel_log_id = 3150 (INFO)
- mensaje = ''Producto {producto_id} cambió precio en lista {lista_precio_id} de {precio_anterior} a {precio_nuevo}''
- detalle = { "usuario": usuario_id, "motivo": "..." }
- Obtener el precio de precios_productos según el tipo de cliente.
- Si no existe precio para la lista, usar la lista PÚBLICO GENERAL.
- Si no existe precio en ninguna lista, usar productos.pventa o pventaf.

DELETE FROM precios_productos;
ALTER SEQUENCE precios_productos_precio_producto_id_seq RESTART WITH 1;

INSERT INTO precios_productos (precio_producto_id, producto_id, lista_precio_id, precio_base, precio_oferta, precio_minimo, fecha_inicio, fecha_fin, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 0.00, NULL, NULL, '2000-01-01', NULL, 1000, 1);

UPDATE precios_productos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE precios_productos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('precios_productos_precio_producto_id_seq', COALESCE((SELECT MAX(precio_producto_id) FROM precios_productos), 0), (SELECT COUNT(*) > 0 FROM precios_productos));

-- ================================================================================================

- PONDERADO: Costo promedio = (stock_actual * costo_anterior + cantidad_comprada * costo_compra) / (stock_actual + cantidad_comprada).
- FIFO: Primeras en entrar, primeras en salir (primero se venden los lotes más antiguos).
- ULTIMA_COMPRA: Usa el costo del último lote comprado.
- Obtener el costo_promedio actual del producto.
- Calcular el nuevo costo_promedio según el método configurado.
- Insertar un nuevo registro en costos_promedio con la fecha de cálculo.
- Margen bruto = (precio_venta - costo_promedio) / precio_venta * 100.
- Rentabilidad por producto, categoría y laboratorio.

DELETE FROM costos_promedio;
ALTER SEQUENCE costos_promedio_costo_promedio_id_seq RESTART WITH 1;

INSERT INTO costos_promedio (costo_promedio_id, producto_id, costo_promedio, costo_ultima_compra, fecha_calculo, metodo_calculo_id, estado_id, usuario_id_registro) VALUES
(1, 1, 0.00, NULL, '2000-01-01', 3750, 1000, 1);

UPDATE costos_promedio SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE costos_promedio SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('costos_promedio_costo_promedio_id_seq', COALESCE((SELECT MAX(costo_promedio_id) FROM costos_promedio), 0), (SELECT COUNT(*) > 0 FROM costos_promedio));

-- ================================================================================================

- GLOBAL: Aplica a todos los productos.
- CATEGORIA: Aplica solo a productos de una categoría específica (entidad_id = categoria_id).
- LABORATORIO: Aplica solo a productos de un laboratorio específico (entidad_id = laboratorio_id).
- PRODUCTO: Aplica solo a un producto específico (entidad_id = producto_id).
1. PRODUCTO (más específica)
2. CATEGORIA
3. LABORATORIO
4. GLOBAL (menos específica)
- 0: Sin redondeo (precio exacto).
- 1: Redondeo al entero más cercano (ej. 12.30 ? 12, 12.50 ? 13).
- 5: Redondeo al múltiplo de 5 más cercano (ej. 12.30 ? 10, 12.50 ? 15).
- Obtener la política aplicable al producto.
- Calcular el precio máximo y mínimo permitido.
- Validar que el precio ingresado esté dentro del rango.
- Aplicar el redondeo configurado.
- Crear o actualizar precios en precios_productos.
- Calcular descuentos en el punto de venta (POS).
- Generar ofertas y promociones.';

DELETE FROM politicas_precios;
ALTER SEQUENCE politicas_precios_politica_precio_id_seq RESTART WITH 1;

INSERT INTO politicas_precios (politica_precio_id, codigo, nombre, tipo_aplicacion_id, entidad_id, margen_minimo, margen_maximo, redondeo, aplica_descuentos, descuento_maximo, estado_id, usuario_id_registro) VALUES
(1, 'GLOBAL', 'POLÍTICA GLOBAL POR DEFECTO', 4350, NULL, 0.00, 100.00, 0, 1, 0.00, 1000, 1);

UPDATE politicas_precios SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE politicas_precios SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('politicas_precios_politica_precio_id_seq', COALESCE((SELECT MAX(politica_precio_id) FROM politicas_precios), 0), (SELECT COUNT(*) > 0 FROM politicas_precios));

-- ================================================================================================

DELETE FROM asistencias;
ALTER SEQUENCE asistencias_asistencia_id_seq RESTART WITH 1;

INSERT INTO asistencias (asistencia_id, trabajador_id, sucursal_id, fecha, hora_entrada, hora_salida, hora_entrada_almuerzo, hora_salida_almuerzo, horas_trabajadas, horas_extras, tipo_asistencia_id, estado_asistencia_id, metodo_marcacion_id, dispositivo, ip_origen, observaciones, justificacion, justificacion_archivo, usuario_registro_id, estado_id, usuario_id_registro) VALUES
(1, 1, 1, CURRENT_DATE, CURRENT_TIMESTAMP, NULL, NULL, NULL, 0.00, 0.00, 4400, 4450, 4500, NULL, NULL, 'REGISTRO COMODIN INICIAL', NULL, NULL, 1, 1000, 1);

UPDATE asistencias SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE asistencias SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('asistencias_asistencia_id_seq', COALESCE((SELECT MAX(asistencia_id) FROM asistencias), 0), (SELECT COUNT(*) > 0 FROM asistencias));

-- ================================================================================================

DELETE FROM planillas;
ALTER SEQUENCE planillas_planilla_id_seq RESTART WITH 1;

INSERT INTO planillas (planilla_id, sucursal_id, periodo_mes, periodo_gestion, fecha_inicio, fecha_fin, tipo_planilla_id, estado_planilla_id, estado_id, usuario_id_registro)
VALUES (1, 1, 1, 2026, '2026-01-01', '2026-01-31', 4600, 4650, 1000, 1);

UPDATE planillas SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE planillas SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('planillas_planilla_id_seq', COALESCE((SELECT MAX(planilla_id) FROM planillas), 0), (SELECT COUNT(*) > 0 FROM planillas));

-- ================================================================================================

DELETE FROM planillas_detalle;
ALTER SEQUENCE planillas_detalle_planilla_detalle_id_seq RESTART WITH 1;

INSERT INTO planillas_detalle (planilla_detalle_id, planilla_id, trabajador_id, cargo_id, sueldo_base, dias_trabajados, total_ingresos, neto_pagar, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 0.00, 0, 0.00, 0.00, 1000, 1);

UPDATE planillas_detalle SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE planillas_detalle SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('planillas_detalle_planilla_detalle_id_seq', COALESCE((SELECT MAX(planilla_detalle_id) FROM planillas_detalle), 0), (SELECT COUNT(*) > 0 FROM planillas_detalle));

-- ================================================================================================

DELETE FROM contratos;
ALTER SEQUENCE contratos_contrato_id_seq RESTART WITH 1;

INSERT INTO contratos (contrato_id, trabajador_id, tipo_contrato_id, fecha_inicio, sueldo_base, moneda_sueldo_id, tipo_jornada_id, estado_contrato_id, estado_id, usuario_id_registro)
VALUES (1, 1, 4750, CURRENT_DATE, 0.00, 2300, 4800, 4700, 1000, 1);

UPDATE contratos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE contratos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('contratos_contrato_id_seq', COALESCE((SELECT MAX(contrato_id) FROM contratos), 0), (SELECT COUNT(*) > 0 FROM contratos));

-- ================================================================================================

[
    {
        "producto_id": 1,
        "codigo": "PARA500",
        "nombre": "Paracetamol 500 mg",
        "lote": "L2026001",
        "fecha_vencimiento": "2028-05-31",
        "cantidad": 2,
        "precio_unitario": 3.50,
        "descuento": 0,
        "subtotal": 7.00,
        "total": 7.00,
        "unidad_medida": "Caja",
        "registro_sanitario": "RS-123456",
        "laboratorio": "INTI",
        "concentracion": "500 mg",
        "presentacion": "CAJA X 10",
        "forma_farmaceutica": "Tableta"
    }
]

DELETE FROM historicos;
ALTER SEQUENCE historicos_historico_id_seq RESTART WITH 1;

INSERT INTO historicos (historico_id, kardex_id, cliente_id, sucursal_id, empresa_id, cliente_nombre, cliente_documento, cliente_documento_complemento, cliente_tipo_documento_abreviatura, cliente_razon_social, cliente_direccion, cliente_telefono, cliente_email, sucursal_nombre, sucursal_codigo, sucursal_telefono, sucursal_ubicacion, sucursal_codigo_sin, sucursal_punto_venta, empresa_nombre, empresa_codigo, empresa_nit, empresa_autorizacion, empresa_actividad_economica, numero_factura, fecha_emision, tipo_comprobante_abreviatura, tipo_factura_abreviatura, lugar_entrega, items, subtotal, descuento_total, iva, total, total_pagado, total_cambio, metodo_pago_abreviatura, tipo_moneda_abreviatura, factor_cambio, estado_id, usuario_id_registro) VALUES
(1, 1, 1, 1, 1, 'NINGUNO', '0', NULL, 'NINGUNO', NULL, NULL, NULL, NULL, 'NINGUNO', 'NIN', NULL, NULL, 0, 0, 'NINGUNA', 'NIN', '000000000', '00000000000000000000', NULL, '0000000', '2026-01-01', 'NINGUNO', 'NINGUNO', NULL, '[]'::jsonb, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 'E', 'BOB', 1.0000, 1000, 1);

UPDATE historicos SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE historicos SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('historicos_historico_id_seq', COALESCE((SELECT MAX(historico_id) FROM historicos), 0), (SELECT COUNT(*) > 0 FROM historicos));

-- ================================================================================================

DELETE FROM configuraciones;
ALTER SEQUENCE configuraciones_configuracion_id_seq RESTART WITH 1;

INSERT INTO configuraciones (configuracion_id, empresa_id, formato_pdf_id, pie_pagina, logo_secundario, mensaje_agradecimiento, estado_id, usuario_id_registro) VALUES
(1, 1, 1950, NULL, NULL, NULL, 1000, 1);

UPDATE configuraciones SET usuario_id_actualizacion = NULL, fecha_actualizacion = NULL, usuario_id_baja = 1, fecha_baja = CURRENT_TIMESTAMP WHERE estado_id = 1001;
UPDATE configuraciones SET usuario_id_actualizacion = 1, fecha_actualizacion = CURRENT_TIMESTAMP, usuario_id_baja = NULL, fecha_baja = NULL WHERE estado_id = 1002;

SELECT setval('configuraciones_configuracion_id_seq', COALESCE((SELECT MAX(configuracion_id) FROM configuraciones), 0), (SELECT COUNT(*) > 0 FROM configuraciones));

-- ================================================================================================
