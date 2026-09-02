
CREATE TABLE ubicaciones (
    ubicacion_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
	codigo VARCHAR(60) NOT NULL,
    jerarquia JSONB NOT NULL DEFAULT '{}'::jsonb,
    descripcion VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_ubicaciones_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
	CONSTRAINT chk_ubicaciones_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_ubicaciones_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_ubicaciones_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
	CONSTRAINT chk_ubicaciones_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_ubicaciones_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_ubicaciones_jerarquia_estructura CHECK (
        jerarquia IS NULL OR
        jsonb_typeof(jerarquia) = 'object' AND
        (jerarquia ? 'niveles' OR jerarquia ? 'camino')
    )
);
CREATE UNIQUE INDEX uix_ubicaciones_varios_unique ON ubicaciones (almacen_id, codigo) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_ubicaciones_jerarquia ON ubicaciones USING GIN (jerarquia);

INSERT INTO ubicaciones (ubicacion_id, almacen_id, codigo, jerarquia, descripcion, estado_id, usuario_id_registro) VALUES
(1, 1, 'NIN', '{"tipo":"COMODIN","valor":"NINGUNO","camino":"COMODIN NINGUNO"}'::jsonb, 'UBICACION COMODIN', 1000, 1),
(2, 2, 'EST-A-1', '{"tipo":"ESTANTERIA","valor":"A","nivel":"1","camino":"ESTANTERIA A > NIVEL 1"}'::jsonb, 'Estanter¨ªa A, Nivel 1', 1000, 2),
(3, 2, 'EST-A-2', '{"tipo":"ESTANTERIA","valor":"A","nivel":"2","camino":"ESTANTERIA A > NIVEL 2"}'::jsonb, 'Estanter¨ªa A, Nivel 2', 1000, 2),
(4, 2, 'EST-A-3', '{"tipo":"ESTANTERIA","valor":"A","nivel":"3","camino":"ESTANTERIA A > NIVEL 3"}'::jsonb, 'Estanter¨ªa A, Nivel 3', 1000, 2),
(5, 2, 'EST-B-1', '{"tipo":"ESTANTERIA","valor":"B","nivel":"1","camino":"ESTANTERIA B > NIVEL 1"}'::jsonb, 'Estanter¨ªa B, Nivel 1', 1000, 2),
(6, 2, 'EST-B-2', '{"tipo":"ESTANTERIA","valor":"B","nivel":"2","camino":"ESTANTERIA B > NIVEL 2"}'::jsonb, 'Estanter¨ªa B, Nivel 2', 1000, 2),
(7, 2, 'EST-B-3', '{"tipo":"ESTANTERIA","valor":"B","nivel":"3","camino":"ESTANTERIA B > NIVEL 3"}'::jsonb, 'Estanter¨ªa B, Nivel 3', 1000, 2),
(8, 2, 'EST-C-1', '{"tipo":"ESTANTERIA","valor":"C","nivel":"1","camino":"ESTANTERIA C > NIVEL 1"}'::jsonb, 'Estanter¨ªa C, Nivel 1', 1000, 2),
(9, 2, 'EST-C-2', '{"tipo":"ESTANTERIA","valor":"C","nivel":"2","camino":"ESTANTERIA C > NIVEL 2"}'::jsonb, 'Estanter¨ªa C, Nivel 2', 1000, 2),
(10, 2, 'EST-C-3', '{"tipo":"ESTANTERIA","valor":"C","nivel":"3","camino":"ESTANTERIA C > NIVEL 3"}'::jsonb, 'Estanter¨ªa C, Nivel 3', 1000, 2),
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
(21, 5, 'JUG-A', '{"tipo":"ANAQUEL","valor":"A","camino":"ANAQUEL A"}'::jsonb, 'Anaqu¨¦l de Juguetes - Secci¨®n A', 1000, 2),
(22, 5, 'JUG-B', '{"tipo":"ANAQUEL","valor":"B","camino":"ANAQUEL B"}'::jsonb, 'Anaqu¨¦l de Juguetes - Secci¨®n B', 1000, 2),
(23, 5, 'JUG-C', '{"tipo":"ANAQUEL","valor":"C","camino":"ANAQUEL C"}'::jsonb, 'Anaqu¨¦l de Juguetes - Secci¨®n C', 1000, 2),
(24, 6, 'EXP-01', '{"tipo":"EXHIBIDOR","valor":"EXP-01","camino":"EXHIBIDOR EXP-01"}'::jsonb, 'Exhibidor de Electr¨®nicos 01', 1000, 2),
(25, 6, 'EXP-02', '{"tipo":"EXHIBIDOR","valor":"EXP-02","camino":"EXHIBIDOR EXP-02"}'::jsonb, 'Exhibidor de Electr¨®nicos 02', 1000, 2),
(26, 7, 'EST-D-1', '{"tipo":"ESTANTERIA","valor":"D","nivel":"1","camino":"ESTANTERIA D > NIVEL 1"}'::jsonb, 'Estanter¨ªa D, Nivel 1', 1000, 2),
(27, 7, 'EST-D-2', '{"tipo":"ESTANTERIA","valor":"D","nivel":"2","camino":"ESTANTERIA D > NIVEL 2"}'::jsonb, 'Estanter¨ªa D, Nivel 2', 1000, 2),
(28, 8, 'ZON-RECEPCION', '{"tipo":"ZONA","valor":"RECEPCION","camino":"ZONA RECEPCION"}'::jsonb, 'Zona de Recepci¨®n de Mercanc¨ªas', 1000, 2),
(29, 9, 'ZON-DESPACHO', '{"tipo":"ZONA","valor":"DESPACHO","camino":"ZONA DESPACHO"}'::jsonb, 'Zona de Preparaci¨®n y Despacho', 1000, 2),
(30, 10, 'EST-D-1', '{"tipo":"ESTANTERIA","valor":"D","nivel":"1","camino":"ESTANTERIA D > NIVEL 1"}'::jsonb, 'Estanter¨ªa D, Nivel 1 - Zona Sur', 1000, 2),
(31, 10, 'EST-D-2', '{"tipo":"ESTANTERIA","valor":"D","nivel":"2","camino":"ESTANTERIA D > NIVEL 2"}'::jsonb, 'Estanter¨ªa D, Nivel 2 - Zona Sur', 1000, 2),
(32, 10, 'EST-D-3', '{"tipo":"ESTANTERIA","valor":"D","nivel":"3","camino":"ESTANTERIA D > NIVEL 3"}'::jsonb, 'Estanter¨ªa D, Nivel 3 - Zona Sur', 1000, 2),
(33, 11, 'REF-Z01-1', '{"tipo":"REFRIGERADOR","valor":"REF-Z01","nivel":"1","camino":"REFRIGERADOR REF-Z01 > BANDEJA 1"}'::jsonb, 'Refrigerador Zona Sur, Bandeja 1', 1000, 2),
(34, 11, 'REF-Z01-2', '{"tipo":"REFRIGERADOR","valor":"REF-Z01","nivel":"2","camino":"REFRIGERADOR REF-Z01 > BANDEJA 2"}'::jsonb, 'Refrigerador Zona Sur, Bandeja 2', 1000, 2),
(35, 12, 'JUG-Z-A', '{"tipo":"ANAQUEL","valor":"Z-A","camino":"ANAQUEL Z-A"}'::jsonb, 'Anaqu¨¦l de Juguetes - Zona Sur A', 1000, 2),
(36, 12, 'JUG-Z-B', '{"tipo":"ANAQUEL","valor":"Z-B","camino":"ANAQUEL Z-B"}'::jsonb, 'Anaqu¨¦l de Juguetes - Zona Sur B', 1000, 2);

CREATE TABLE inventarios_fisicos (
    inventario_fisico_id BIGSERIAL PRIMARY KEY,
    almacen_id BIGINT NOT NULL DEFAULT 1,
	ubicacion_id BIGINT NOT NULL DEFAULT 1,
    fecha_conteo DATE NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NULL,
    trabajador_responsable_id BIGINT NOT NULL DEFAULT 1,
    trabajador_supervisor_id BIGINT NOT NULL DEFAULT 1,
	observaciones VARCHAR(500) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_inventariosfisicos_almacen_id FOREIGN KEY (almacen_id) REFERENCES almacenes(almacen_id),
    CONSTRAINT fk_inventariosfisicos_ubicacion_id FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(ubicacion_id),
    CONSTRAINT fk_inventariosfisicos_trabajador_resp FOREIGN KEY (trabajador_responsable_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_inventariosfisicos_trabajador_sup FOREIGN KEY (trabajador_supervisor_id) REFERENCES trabajadores(trabajador_id),
    CONSTRAINT fk_inventariosfisicos_usuarioregistro_id FOREIGN KEY (usuario_id_registro) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_inventariosfisicos_usuarioactualizacion_id FOREIGN KEY (usuario_id_actualizacion) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_inventariosfisicos_usuariobaja_id FOREIGN KEY (usuario_id_baja) REFERENCES usuarios(usuario_id),
    CONSTRAINT chk_inventariosfisicos_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_inventariosfisicos_observaciones_notempty CHECK (observaciones IS NULL OR TRIM(observaciones) <> ''),
    CONSTRAINT chk_inventariosfisicos_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
	CONSTRAINT chk_inventariosfisicos_fechaconteo_inicio CHECK (fecha_inicio >= fecha_conteo)
);
CREATE UNIQUE INDEX idx_inventariosfisicos_activo_unique ON inventarios_fisicos (almacen_id, ubicacion_id, fecha_conteo, trabajador_responsable_id, trabajador_supervisor_id) WHERE estado_id = 1000;
CREATE INDEX idx_inventariosfisicos_trabajadorsupid ON inventarios_fisicos(trabajador_supervisor_id);
CREATE INDEX idx_inventariosfisicos_trabajadorrespid ON inventarios_fisicos(trabajador_responsable_id);

INSERT INTO inventarios_fisicos (inventario_fisico_id,almacen_id,ubicacion_id,fecha_conteo,fecha_inicio,fecha_fin,trabajador_responsable_id,trabajador_supervisor_id,estado_id,observaciones,usuario_id_registro) VALUES
	 (1,1,1,'2026-08-31','2026-08-31 11:27:15.050412-04',NULL,1,1,1000,'REGISTRO INICIAL COMODIN DE INVENTARIO FISICO',1),
	 (2,2,2,'2026-07-01','2026-07-01 08:00:00-04','2026-07-01 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA PRINCIPAL PASILLO A',2),
	 (3,2,3,'2026-07-02','2026-07-02 08:00:00-04','2026-07-02 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA SECUNDARIA PASILLO A',2),
	 (4,2,4,'2026-07-03','2026-07-03 08:00:00-04','2026-07-03 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA PRINCIPAL PASILLO B',2),
	 (5,2,5,'2026-07-04','2026-07-04 08:00:00-04','2026-07-04 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESTANTERIA SECUNDARIA PASILLO B',2),
	 (6,3,6,'2026-07-05','2026-07-05 08:00:00-04','2026-07-05 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - REFRIGERADOR 1 BANDEJA 1',2),
	 (7,3,7,'2026-07-06','2026-07-06 08:00:00-04','2026-07-06 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - REFRIGERADOR 2 BANDEJA 2',2),
	 (8,4,8,'2026-07-07','2026-07-07 08:00:00-04','2026-07-07 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - CONGELADOR 1 BANDEJA 1',2),
	 (9,4,9,'2026-07-08','2026-07-08 08:00:00-04','2026-07-08 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - CONGELADOR 2 BANDEJA 2',2),
	 (10,5,10,'2026-07-09','2026-07-09 08:00:00-04','2026-07-09 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - JUGUETES SECCION A',2),
	 (11,5,11,'2026-07-10','2026-07-10 08:00:00-04','2026-07-10 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - JUGUETES SECCION B',2),
	 (12,6,12,'2026-07-11','2026-07-11 08:00:00-04','2026-07-11 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ELECTRONICOS SECCION A',2),
	 (13,6,13,'2026-07-12','2026-07-12 08:00:00-04','2026-07-12 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ELECTRONICOS SECCION B',2),
	 (14,7,14,'2026-07-13','2026-07-13 08:00:00-04','2026-07-13 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESCRITORIO SECCION A',2),
	 (15,7,15,'2026-07-14','2026-07-14 08:00:00-04','2026-07-14 17:00:00-04',2,3,1000,'INVENTARIO FISICO MENSUAL - CASA MATRIZ - ESCRITORIO SECCION B',2),
	 (16,10,16,'2026-07-15','2026-07-15 08:00:00-04','2026-07-15 17:00:00-04',2,4,1000,'INVENTARIO FISICO MENSUAL - ZONA SUR - ESTANTERIA PRINCIPAL PASILLO C',2),
	 (17,10,17,'2026-07-16','2026-07-16 08:00:00-04','2026-07-16 17:00:00-04',2,4,1000,'INVENTARIO FISICO MENSUAL - ZONA SUR - ESTANTERIA SECUNDARIA PASILLO C',2),
	 (18,11,18,'2026-07-17','2026-07-17 08:00:00-04','2026-07-17 17:00:00-04',2,4,1000,'INVENTARIO FISICO MENSUAL - ZONA SUR - REFRIGERADOR BANDEJA 1',2),
	 (19,12,19,'2026-07-18','2026-07-18 08:00:00-04','2026-07-18 17:00:00-04',2,4,1000,'INVENTARIO FISICO MENSUAL - ZONA SUR - JUGUETES',2);

esta bien con INSERT INTO inventarios_fisicos es coherente con ubicaciones 
