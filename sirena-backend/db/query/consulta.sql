-- ================================================================================================
-- OTORGAR TODOS LOS PERMISOS EN LA TABLA 'bancos' AL ROL COMPRADOR (rol_id = 5)
-- ================================================================================================

-- ================================================================================================
-- 1. OTORGAR PERMISOS EN LAS TABLAS QUE AÚN NO TIENEN REGISTRO PARA EL ROL COMPRADOR (rol_id = 5)
-- ================================================================================================

INSERT INTO roles_permisos_tablas (
    rol_id,
    tabla_id,
    leer,
    crear,
    editar,
    eliminar,
    anular,
    archivar,
    desarchivar,
    estado_id,
    usuario_id_registro
)
SELECT
    5,                  -- ROL COMPRADOR
    t.tabla_id,         -- Recorre las tablas activas
    1,                  -- leer
    1,                  -- crear
    1,                  -- editar
    1,                  -- eliminar
    1,                  -- anular
    1,                  -- archivar
    1,                  -- desarchivar
    1000,               -- estado_id ACTIVO
    2                   -- usuario_id_registro
FROM tablas t
WHERE t.estado_id = 1000
  AND NOT EXISTS (
      SELECT 1
      FROM roles_permisos_tablas rpt_exist
      WHERE rpt_exist.rol_id = 5
        AND rpt_exist.tabla_id = t.tabla_id
        AND rpt_exist.estado_id = 1000
  );


-- ================================================================================================
-- 2. OTORGAR SUCESOS ACTIVOS QUE AÚN NO ESTÉN ASOCIADOS A LOS PERMISOS DEL ROL COMPRADOR (rol_id = 5)
-- ================================================================================================

INSERT INTO roles_permisos_sucesos (
    rol_permiso_tabla_id,
    suceso_id,
    estado_id,
    usuario_id_registro
)
SELECT
    rpt.rol_permiso_tabla_id,
    s.suceso_id,
    1000,
    2
FROM roles_permisos_tablas rpt
CROSS JOIN sucesos s
WHERE rpt.rol_id = 5
  AND rpt.estado_id = 1000
  AND s.estado_id = 1000
  AND NOT EXISTS (
      SELECT 1
      FROM roles_permisos_sucesos rps_exist
      WHERE rps_exist.rol_permiso_tabla_id = rpt.rol_permiso_tabla_id
        AND rps_exist.suceso_id = s.suceso_id
        AND rps_exist.estado_id = 1000
  );


-- ================================================================================================
-- 3. ACTUALIZAR SECUENCIAS
-- ================================================================================================

SELECT setval('roles_permisos_tablas_rol_permiso_tabla_id_seq', COALESCE((SELECT MAX(rol_permiso_tabla_id) FROM roles_permisos_tablas), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_tablas));
SELECT setval('roles_permisos_sucesos_rol_permiso_suceso_id_seq', COALESCE((SELECT MAX(rol_permiso_suceso_id) FROM roles_permisos_sucesos), 0), (SELECT COUNT(*) > 0 FROM roles_permisos_sucesos));

SELECT *
FROM roles_permisos_tablas
;


            SELECT
                u.usuario_id,
                u.login,
                u.sucursal_id,
                u.avatar,
                u.rol_id,
                u.contrasena,
                p.trabajador_id AS trabajador_id,
                p.nombres,
                r.codigo AS rol_codigo,
                r.rol AS rol_nombre,
                c.cargo_id AS cargo_id,
                c.cargo AS cargo_nombre,
                c.codigo AS cargo_codigo,
                TRIM(p.nombres || ' ' || p.paterno || ' ' || COALESCE(p.materno, '')) AS trabajador_nombre_completo,
                p.nombres AS trabajador_nombres,
                p.paterno AS trabajador_paterno,
                p.materno AS trabajador_materno,
                p.dni AS trabajador_dni,
                s.sucursal AS sucursal_nombre,
                s.codigo AS sucursal_codigo,
                e.empresa_id AS empresa_id,
                e.empresa AS empresa_nombre,
                e.codigo AS empresa_codigo
            FROM usuarios u
            INNER JOIN roles r ON r.rol_id = u.rol_id
            INNER JOIN trabajadores p ON p.trabajador_id = u.trabajador_id
            INNER JOIN trabajadores_cargos tc ON tc.trabajador_id = p.trabajador_id
                AND tc.es_activo = 1
                AND tc.estado_id = 1000
            INNER JOIN cargos c ON c.cargo_id = tc.cargo_id
            INNER JOIN sucursales s ON s.sucursal_id = u.sucursal_id
            INNER JOIN empresas e ON e.empresa_id = s.empresa_id
            WHERE u.login = 'ADMIN'
                AND u.estado_id = 1000
