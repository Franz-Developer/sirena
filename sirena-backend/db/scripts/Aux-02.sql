
CREATE TABLE bancos (
    banco_id BIGSERIAL PRIMARY KEY,
    banco VARCHAR(60) NOT NULL,
    codigo_asfi CHAR(2) NOT NULL,
    abreviatura VARCHAR(20) NOT NULL,
	descripcion VARCHAR(255) NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_bancos_banco_minlength CHECK (LENGTH(TRIM(banco)) >= 3),
    CONSTRAINT chk_bancos_abreviatura_minlength CHECK (LENGTH(TRIM(abreviatura)) >= 2),
    CONSTRAINT chk_bancos_codigoasfi_numerico CHECK (codigo_asfi ~ '^[0-9]{2}$'),
	CONSTRAINT chk_bancos_banco_mayusculas CHECK (banco = UPPER(banco)),
	CONSTRAINT chk_bancos_estadoid CHECK (estado_id IN (1000, 1001, 1002))
);
CREATE UNIQUE INDEX uix_bancos_codigoasfi_unique ON bancos (codigo_asfi) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_abreviatura_unique ON bancos (abreviatura) WHERE estado_id IN (1000, 1002);
CREATE UNIQUE INDEX uix_bancos_banco_unique ON bancos (banco) WHERE estado_id IN (1000, 1002);


SELECT setval('bancos_banco_id_seq', COALESCE((SELECT MAX(banco_id) FROM bancos), 0), (SELECT COUNT(*) > 0 FROM bancos));

SELECT banco_id, banco, codigo_asfi, abreviatura, estado_id, usuario_id_registro
FROM bancos
ORDER BY banco_id ASC;
SALE 
---------+---------------------------------+------------+------------+----------+--------------------
banco_id |banco                            |codigo_asfi |abreviatura |estado_id |usuario_id_registro 
---------+---------------------------------+------------+------------+----------+--------------------
1        |NINGUNO                          |99          |NIN         |1000      |1                   
2        |BANCO NACIONAL DE BOLIVIA S.A.   |01          |BNB         |1000      |2                   
3        |BANCO MERCANTIL SANTA CRUZ S.A.  |02          |BMSC        |1000      |2                   
4        |BANCO BISA S.A.                  |03          |BISA        |1002      |2                   
5        |BANCO DE CREDITO DE BOLIVIA S.A. |04          |BCB         |1002      |2                   
6        |BANCO ECONOMICO S.A.             |05          |BEC         |1000      |2                   
7        |BANCO GANADERO S.A.              |06          |BGA         |1000      |2                   
8        |BANCO SOLIDARIO S.A.             |07          |BSO         |1000      |2                   
9        |BANCO UNION S.A.                 |08          |BUN         |1000      |2                   
10       |BANCO FIE S.A.                   |09          |FIE         |1000      |2                   
11       |BANCO PRODEM S.A.                |10          |PRD         |1000      |2                   
12       |BANCO PYME ECOFUTURO S.A.        |11          |ECO         |1000      |2                   
13       |BANCO PYME DE LA COMUNIDAD S.A.  |12          |BCO         |1000      |2                   
14       |BANCO NIÑOS                      |13          |BBB         |1001      |2                   
15       |BANCO PRUEBA                     |14          |B1          |1001      |2                   
16       |BANCO DE PRUEBA                  |15          |MM          |1001      |2                   
17       |BANCO DE PRUEBA 2                |16          |MM2         |1001      |2                   
18       |BANCO HOLA                       |17          |MNS         |1001      |2                   
19       |BANCO LINDO                      |18          |MMM3        |1002      |2                   
20       |ADJAS D ADHAS                    |34          |4551        |1000      |2                   
---------+---------------------------------+------------+------------+----------+--------------------
Total de filas: 20

Puedes crear 30 bancos de prueba cualquier nombre 
