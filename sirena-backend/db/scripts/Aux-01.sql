Quiero que alalices a profundidad 
QUiero que encuentres 
codigo muerto.
errores de logica 
funciones que se puede optimizar 
cuello de botella 
HAS UNA LISTA de observaciones No. XXX 
Explicacion 
Archivo y funcion 
----------------------------------------------------------------------------------
-- 1. Valida que el código ASFI no se repita entre bancos activos o históricos
CREATE UNIQUE INDEX uix_bancos_codigoasfi_unique 
ON bancos (codigo_asfi) 
WHERE estado_id IN (1000, 1002);

-- 2. Valida que la combinación de empresa, banco, número de cuenta, moneda y tipo de cuenta sea única por empresa activa/histórica
CREATE UNIQUE INDEX uix_empresascuentas_varios_unique 
ON empresas_cuentas (empresa_id, banco_id, nro_cuenta, tipo_moneda_id, tipo_cuenta_id) 
WHERE estado_id IN (1000, 1002);

-- 3. Valida que la combinación de origen, destino y fecha de cotización no se duplique para tipos de cambio vigentes
CREATE UNIQUE INDEX uix_tiposcambios_varios_unique 
ON tipos_cambios (origen_moneda_id, destino_moneda_id, fecha_cotizacion) 
WHERE estado_id IN (1000, 1002);

----------------------------------------------------------------------------------
@Injectable()
export class EmpresasNitsService extends BaseService {
    protected config: BaseServiceConfig = {
        tableName: 'empresas_nits',
        pkField: 'empresa_nit_id',
        joins: [
            {
                table: 'empresas',
                alias: 'emp',
                // Aquí utilizas la columna real de la tabla empresas_nits
                onCondition: 't.empresa_base_id = emp.empresa_id', 
                type: 'LEFT',
                selectColumns: [
                    'emp.empresa AS empresa_nombre', 
                    'emp.codigo AS empresa_codigo',
                    'emp.logo AS empresa_logo'
                ]
            }
        ],
        searchColumns: ['nit', 'razon_social', 'etiqueta', 'email_fiscal'],
        responseDto: EmpresaNitResponseDto,
    };

    constructor(dataSource: DataSource, tablaValidador: TablaValidadorService) {
        super(dataSource, tablaValidador);
    }
}
----------------------------------------------------------------------------------

Actúa como un Arquitecto de Bases de Datos Senior. Genera un diccionario de datos (Lista de tablas) ultra compacto para las tablas proporcionadas, estrictamente sin saltos de línea internos por tabla, tampoco con un salto de línea entre tabla y tabla. Sigue este formato exacto:
Tabla NOMBRE_TABLA: Descripción corta pero clara de la tabla. (La descripción tiene que ser exacatemnte la R.0, pero sin R.0 solo texto)  Sus campos son: campo1 (opciones/detalles), campo2, ..., campoN. Índices Únicos: nombre_idx (columnas) condición. Índices de Búsqueda: nombre_idx (columnas) condición.
Reglas de exclusión obligatorias: Omite por completo los siguientes campos de auditoría y control en todas las tablas, ya que son comunes y se sobreentienden:
        usuario_id_registro
        usuario_id_actualizacion
        usuario_id_baja
        fecha_registro
        fecha_actualizacion
        fecha_baja
Asegúrate de incluir explícitamente los comentarios de opciones o dominios inline dentro de cada campo Por ejemplo: estado_traspaso_id (2100=EN_TRANSITO, 2101=RECIBIDO) tal como se definen en el esquema original.
Sin salto de línea entre tabla y tabla.
La lista de tablas debe ser en orden de creacion.

EJEMPLOS:
Tabla dominios: Catálogo paramétrico del sistema. Sus campos son: dominio_id, dominio, abreviatura, prefijo, valor, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_dom_unique (dominio, abreviatura) WHERE estado_id IN (1000, 1002).
Tabla entidades_financieras: Catálogo de bancos y financieras. Sus campos son: entidad_financiera_id, entidad, codigo_asfi, abreviatura, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_efi_codigo_asfi (codigo_asfi) WHERE estado_id IN (1000, 1002); uix_efi_abreviatura (abreviatura) WHERE estado_id IN (1000, 1002).
Tabla tipos_cambios: Tasas de cambio entre monedas. Sus campos son: tipo_cambio_id, moneda_origen_id (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV), moneda_destino_id (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV), entidad_financiera_id, factor_compra, factor_venta, fecha_cotizacion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_tpc_cotizacion_vigente (moneda_origen_id, moneda_destino_id, entidad_financiera_id, fecha_cotizacion) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_tpc_busqueda (moneda_origen_id, moneda_destino_id, entidad_financiera_id, fecha_cotizacion DESC) WHERE estado_id IN (1000, 1002).

-- ************************************
SOLO Quiero una lista de dominio_id, dominio, abreviatura, valor, es_protegido ordenado por dominio_id
NADA MAS 
-- ************************************
Rol: Actúa como un Arquitecto de Bases de Datos Senior.
Tarea: Analizar el esquema/DDL proporcionado y generar una lista ordenada de las tablas que contienen campos de tipo fecha de negocio.
Reglas de Filtrado e Inclusión:
    Exclusiones de Tablas: Omite por completo cualquier tabla que NO contenga campos de tipo fecha.
    Exclusiones de Campos Auditables: Omite estrictamente los siguientes campos de auditoría/sistema:
        fecha_registro
        fecha_actualizacion
        fecha_baja
    Criterio de Inclusión: Si una tabla solo contiene campos de auditoría (y ningún otro campo de fecha), debe ser omitida por completo.
Orden de Salida:
    Presenta las tablas estrictamente en orden jerárquico de creación (respetando las dependencias de clave foránea / FKs, listando primero las tablas padre).
Formato de Salida Requerido:
Por cada tabla que cumpla los criterios, muestra únicamente:
    Tabla: Nombre de la tabla
    Lista de sus campos de fecha válidos con su tipo exacto (DATE o TIMESTAMPTZ) y sus restricciones.
	Regla: R.0 sin hacer ningun cambio.
Regla de Formateo:
    Agrega un salto de línea en blanco entre cada grupo/bloque de tabla para separarlos claramente.

-- ************************************
[ROL Y OBJETIVO]
Actúa como un Arquitecto de Bases de Datos Senior y Analista de Negocio. Tu objetivo es analizar el script de una base de datos junto con sus reglas específicas por tabla y sus reglas generales, para definir con claridad la "Regla 0" (R.0) de cada tabla, además de estructurar su propósito dentro del sistema.

[DEFINICIÓN DE REGLA 0 (R.0)]
La "Regla 0" (R.0) es la regla madre o razón de ser de la tabla. Debe responder claramente a:
1. ¿Por qué existe esta tabla en el modelo?
2. ¿Qué problema del negocio resuelve o qué proceso soporta?
3. ¿Qué valor aporta guardar estos datos y cómo interactúa con el resto del sistema?
4. Debe ser un solo parrafo.
5. R.0: Debe explicar que hace la tabla. 
6. Usar lenguaje tecnico, formal e impersonal.

[INSTRUCCIONES DE ANÁLISIS]
1. Lee el script SQL/DDL adjunto.
2. Cruza la información del diseño de cada tabla con:
   - Sus reglas específicas adjuntas.
   - Las reglas generales del sistema.
3. Sintetiza la información para extraer la R.0 de forma concisa pero completa (no te limites a listar campos, explica la lógica de negocio).
4. Presenta el análisis con un formato uniforme para cada tabla.

[FORMATO DE SALIDA REQUERIDO]
Por cada tabla de la base de datos, genera la siguiente estructura:

### Tabla: [nombre_de_la_tabla]
R.0: [Explicación detallada de la razón de ser, objetivo principal y utilidad práctica de la tabla en el negocio]. [Breve mención de las tablas principales con las que se conecta y por qué]

[INFORMACIÓN DE ENTRADA]
--- REGLAS GENERALES DEL SISTEMA ---
[Pega aquí tus reglas generales]
--- SCRIPT DE LA BASE DE DATOS Y REGLAS ESPECÍFICAS ---
[Pega aquí el script SQL con los comentarios/reglas específicas de cada tabla]

-- ***************************************************************************************************************************
-- Lista de tablas en orden de creación de la base de datos dbvalkiria

Todas las tablas tienen en comun estos campos 
usuario_id_registro BIGINT NOT NULL DEFAULT 1,
usuario_id_actualizacion BIGINT NULL,
usuario_id_baja BIGINT NULL,
fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
fecha_actualizacion TIMESTAMPTZ NULL,
fecha_baja TIMESTAMPTZ NULL,

Tabla dominios: Catálogo paramétrico del sistema. Sus campos son: dominio_id, dominio, abreviatura, prefijo, valor, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_dom_unique (dominio, abreviatura) WHERE estado_id IN (1000, 1002).
Tabla bancos: Catálogo de entidades financieras. Sus campos son: banco_id, banco, codigo_asfi, abreviatura, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_efi_codigo_asfi (codigo_asfi) WHERE estado_id IN (1000, 1002); uix_efi_abreviatura (abreviatura) WHERE estado_id IN (1000, 1002).
Tabla tipos_cambios: Tasas de cambio entre monedas. Sus campos son: tipo_cambio_id, origen_moneda_id (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV), destino_moneda_id (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV), factor_compra, factor_venta, fecha_cotizacion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_tpc_cotizacion_vigente (origen_moneda_id, destino_moneda_id, fecha_cotizacion) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_tpc_busqueda (origen_moneda_id, destino_moneda_id, fecha_cotizacion DESC) WHERE estado_id IN (1000, 1002).
Tabla empresas: Nodo raíz de la estructura organizacional. Sus campos son: empresa_id, empresa, codigo, codigo_sistema, logo, eslogan, descripcion, lugar, representante, direccion, telefono, email, matricula_comercio, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_emp_empresa_unique (empresa) WHERE estado_id IN (1000, 1002); uix_emp_codigo_unique (codigo) WHERE estado_id IN (1000, 1002); uix_emp_matricula_unique (matricula_comercio) WHERE estado_id IN (1000, 1002).
Tabla empresas_nits: Información de dosificación fiscal y NIT de la empresa. Sus campos son: empresa_nit_id, empresa_id, ambiente_id (2750=PRODUCCION, 2751=PILOTO_PRUEBAS), nit, razon_social, actividad_economica_principal, modalidad_facturacion_id (3900=NINGUNO, 3901=ELECTRONICA, 3902=COMPUTARIZADA, 3903=MANUAL), certificado_digital, certificado_password, token_siat, fecha_inicio_vigencia, fecha_fin_vigencia, email_fiscal, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_en_nit_activo (nit) WHERE estado_id=1000; uix_en_nit_historico (nit, fecha_inicio_vigencia, fecha_fin_vigencia) WHERE estado_id=1002.
Tabla empresas_cuentas: Cuentas bancarias operativas de la empresa. Sus campos son: empresa_cuenta_id, empresa_id, banco_id, tipo_moneda_id (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV), nro_cuenta, tipo_cuenta_id (1750=CUENTA_CORRIENTE, 1751=CAJA_AHORROS, 1752=AHORRO_PROGRAMADO, 1753=PLAZO_FIJO, 1754=INVERSION, 1755=NO_APLICA), titular, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_ecb_cuenta_unica (banco_id, nro_cuenta) WHERE estado_id IN (1000, 1002).
Tabla sucursales: Puntos de venta y estructura operativa de la empresa. Sus campos son: sucursal_id, empresa_id, sucursal, sucursal_largo, codigo, codigo_sin, punto_venta, telefono, ubicacion, horario_atencion, factor_venta, factor_facturacion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_suc_sucursal (empresa_id, sucursal) WHERE estado_id IN (1000, 1002); uix_suc_codigo (empresa_id, codigo) WHERE estado_id IN (1000, 1002); uix_suc_punto_venta (empresa_id, codigo_sin, punto_venta) WHERE estado_id IN (1000, 1002).
Tabla puntos_venta: Puntos de emisión de comprobantes dentro de cada sucursal. Sus campos son: punto_venta_id, sucursal_id, codigo_punto_venta, descripcion, tipo_punto_venta_id (3950=NINGUNO, 3951=CAJA), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pv_codigo_punto (sucursal_id, codigo_punto_venta) WHERE estado_id IN (1000, 1002).
Tabla cuis: Código Único de Identificación del Sistema (CUIS) otorgado por el SIN. Sus campos son: cuis_id, sucursal_id, punto_venta_id, cuis, fecha_vigencia, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cuis_activo (sucursal_id, COALESCE(punto_venta_id, 0)) WHERE estado_id=1000.
Tabla cufd: Código Único de Facturación Diaria (CUFD) otorgado por el SIN. Sus campos son: cufd_id, sucursal_id, punto_venta_id, cufd, codigo_control, fecha_vigencia, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cufd_activo (sucursal_id, COALESCE(punto_venta_id, 0)) WHERE estado_id=1000.
Tabla almacenes: Áreas o depósitos físicos dentro de cada sucursal. Sus campos son: almacen_id, sucursal_id, almacen, codigo, tipo_almacen_id (1700=NORMAL, 1701=REFRIGERADO, 1702=CONGELADO, 1703=ESPECIAL, 1704=TRANSITO, 1705=MATERIAL_MEDICO, 1706=COSMETICA, 1707=ALIMENTOS, 1708=MATERIA_PRIMA, 1709=RECEPCION, 1710=DEVOLUCIONES, 1711=DESPACHO, 1712=CUARENTENA), descripcion, es_venta_directa (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_alm_almacen (sucursal_id, almacen) WHERE estado_id IN (1000, 1002); uix_alm_codigo (sucursal_id, codigo) WHERE estado_id IN (1000, 1002).
Tabla ubicaciones: Grilla geoespacial detallada dentro de cada almacén. Sus campos son: ubicacion_id, almacen_id, codigo, pasillo, estanteria, gaveta, vitrina, refrigerador, congelador, nivel, posicion, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_uba_codigo_unique (almacen_id, codigo) WHERE estado_id IN (1000, 1002).
Tabla cargos: Definición de puestos de trabajo. Sus campos son: cargo_id, cargo, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_car_cargo_unique (cargo) WHERE estado_id IN (1000, 1002).
Tabla trabajadores: Registro maestro de individuos. Sus campos son: trabajador_id, genero_id (1200=MASCULINO, 1201=FEMENINO), estado_civil_id (1250=SOLTERO, 1251=CASADO, 1252=DIVORCIADO, 1253=VIUDO, 1254=UNION_LIBRE / 1300=SOLTERA, 1301=CASADA, 1302=DIVORCIADA, 1303=VIUDA, 1304=UNION_LIBRE), nombres, paterno, materno, dni, telefono, direccion, email, fecha_nacimiento, fecha_contratacion, foto, qr, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_tra_dni_unique (dni) WHERE estado_id IN (1000, 1002).
Tabla trabajadores_cargos: Asignación de cargos a trabajadores. Sus campos son: trabajador_cargo_id, trabajador_id, cargo_id, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_trc_trabajador_cargo_unique (trabajador_id, cargo_id) WHERE estado_id=1000.
Tabla roles: Perfiles de acceso y autorización del sistema. Sus campos son: rol_id, codigo, rol, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_rol_codigo_unique (codigo) WHERE estado_id IN (1000, 1002); uix_rol_rol_unique (rol) WHERE estado_id IN (1000, 1002).
Tabla usuarios: Credenciales de acceso al sistema. Sus campos son: usuario_id, trabajador_id, sucursal_id, rol_id, login, contrasena, avatar, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_usu_login_unique (login) WHERE estado_id IN (1000, 1002).
Tabla menus: Estructura jerárquica de navegación de la interfaz. Sus campos son: menu_id, menu_padre_id, titulo, icono, url, orden, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_men_titulo_orden_unique (menu_padre_id, titulo, orden) WHERE estado_id IN (1000, 1002).
Tabla roles_menus: Permisos granulares por rol y menú. Sus campos son: rol_menu_id, rol_id, menu_id, crear (0=No, 1=Sí), editar (0=No, 1=Sí), eliminar (0=No, 1=Sí), archivar (0=No, 1=Sí), desarchivar (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_rm_rol_menu_vigente (rol_id, menu_id) WHERE estado_id=1000.
Tabla clientes: Registro maestro de compradores. Sus campos son: cliente_id, tipo_cliente_id (1150=NATURAL, 1151=JURIDICA), cliente, nit, razon_social, documento, documento_complemento, tipo_documento_id (2200=CEDULA_IDENTIDAD, 2201=CEDULA_IDENTIDAD_EXTRANJERO, 2202=PASAPORTE, 2203=OTRO, 2204=NIT), direccion, telefono, email, banco_id, numero_cuenta, habilitado_ventas (0=No, 1=Sí), limite_credito, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cli_documento_vigente_null (tipo_documento_id, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NULL; uix_cli_documento_vigente_not_null (tipo_documento_id, documento_complemento, documento) WHERE estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NOT NULL. Índices de Búsqueda: idx_clientes_busqueda (documento, cliente) WHERE estado_id IN (1000, 1002).
Tabla categorias: Taxonomía jerárquica para clasificar productos. Sus campos son: categoria_id, categoria_padre_id, categoria, codigo, descripcion, nivel, orden, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cat_padre_nombre (categoria_padre_id, categoria) WHERE estado_id IN (1000, 1002); uix_cat_codigo_activo (codigo) WHERE estado_id IN (1000, 1002).
Tabla unidades: Catálogo de unidades de medida. Sus campos son: unidad_id, codigo, codigo_sin, unidad, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_uni_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_uni_unidad (unidad) WHERE estado_id IN (1000, 1002).
Tabla laboratorios: Catálogo de fabricantes o marcas de productos. Sus campos son: laboratorio_id, codigo, laboratorio, nit, direccion, telefono, email, web, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_lab_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_lab_laboratorio (laboratorio) WHERE estado_id IN (1000, 1002); uix_lab_nit (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND nit <> ''.
Tabla formas: Definición de formas farmacéuticas. Sus campos son: forma_id, forma_farmaceutica, codigo, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_f_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_f_forma (forma_farmaceutica) WHERE estado_id IN (1000, 1002).
Tabla presentaciones: Forma comercial de venta de un producto. Sus campos son: presentacion_id, unidad_id, codigo, presentacion, cantidad_unidades, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pre_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_pre_presentacion (presentacion) WHERE estado_id IN (1000, 1002).
Tabla concentraciones: Potencia de los principios activos. Sus campos son: concentracion_id, unidad_base_id, codigo, concentracion, valor_numerico, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_con_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_con_concentracion (concentracion) WHERE estado_id IN (1000, 1002).
Tabla vias: Vías de administración de medicamentos. Sus campos son: via_id, nombre, descripcion, requiere_ayuno (0=No, 1=Sí), tiempo_efecto_minutos, precauciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_via_nombre (nombre) WHERE estado_id IN (1000, 1002).
Tabla rangos_edad: Clasificación de grupos etarios de pacientes. Sus campos son: rango_edad_id, codigo, rango, edad_minima_meses, edad_maxima_meses, descripcion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_ran_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_ran_rango (rango) WHERE estado_id IN (1000, 1002).
Tabla productos: Núcleo del catálogo de inventario y ventas. Sus campos son: producto_id, categoria_id, laboratorio_id, forma_id, presentacion_id, concentracion_id, unidad_venta_id, codigo, nombre, nombre_generico, pcompra, p_factor_venta, p_factor_facturacion, pventa, pventaf, stock_minimo, stock_maximo, punto_reorden, requiere_receta (0=No, 1=Sí), controlado (0=No, 1=Sí), tiene_registro_sanitario (0=No, 1=Sí), descripcion, observacion, foto1, foto2, foto3, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pro_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_pro_medicamento_unico (nombre_generico, concentracion_id, forma_id, laboratorio_id) WHERE estado_id IN (1000, 1002) AND nombre_generico IS NOT NULL. Índices de Búsqueda: idx_productos_busqueda (nombre, nombre_generico, codigo) WHERE estado_id IN (1000, 1002).
Tabla productos_vias: Relación entre productos y vías de administración. Sus campos son: producto_via_id, producto_id, via_id, es_principal (0=No, 1=Sí), observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pv_relacion_unica (producto_id, via_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_pv_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_pv_via (via_id) WHERE estado_id IN (1000, 1002).
Tabla equivalentes: Sustitutos farmacéuticos para productos. Sus campos son: equivalente_id, producto_base_id, producto_alternativo_id, grado_equivalente (3800=TOTAL, 3801=PARCIAL, 3802=TERAPEUTICO, 3803=NINGUNO), prioridad_recomendacion, observaciones, fecha_vigencia_desde, fecha_vigencia_hasta, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_eq_base_alternativo_vigente (producto_base_id, producto_alternativo_id) WHERE estado_id IN (1000, 1002) AND NOT (producto_base_id=1 AND producto_alternativo_id=1). Índices de Búsqueda: idx_eq_producto_base (producto_base_id) WHERE estado_id=1000; idx_eq_grado_equivalencia (grado_equivalente) WHERE estado_id=1000.
Tabla productos_rangos_edad: Relación entre productos y rangos de edad. Sus campos son: producto_rango_edad_id, producto_id, rango_edad_id, contraindicado (0=No, 1=Sí), dosis_recomendada, observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pre_relacion_unica (producto_id, rango_edad_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_pre_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_pre_rango_edad (rango_edad_id) WHERE estado_id IN (1000, 1002).
Tabla productos_ubicaciones: Ubicación física de productos en almacenes. Sus campos son: producto_ubicacion_id, producto_id, ubicacion_id, prioridad_picking, capacidad_maxima, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pru_producto_posicion_unica (producto_id, ubicacion_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_productos_ubicaciones_producto (producto_id) WHERE estado_id IN (1000, 1002); idx_pru_ubicacion_busqueda_rapida (ubicacion_id) WHERE estado_id IN (1000, 1002).
Tabla principios_activos: Catálogo de compuestos farmacológicos. Sus campos son: principio_activo_id, codigo, nombre, descripcion, es_controlado (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pri_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_pri_nombre (nombre) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_principios_activos_busqueda (nombre, codigo) WHERE estado_id IN (1000, 1002).
Tabla productos_principios: Asociación de principios activos a productos. Sus campos son: producto_principio_id, producto_id, principio_activo_id, concentracion, es_principal (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_ppa_relacion_unica (producto_id, principio_activo_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_productos_principios_producto (producto_id) WHERE estado_id IN (1000, 1002); idx_productos_principios_principio (principio_activo_id) WHERE estado_id IN (1000, 1002).
Tabla registros_sanitarios: Información legal de autorización sanitaria de productos. Sus campos son: registro_sanitario_id, producto_id, codigo_registro, entidad_emisora, fecha_emision, fecha_vencimiento, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_res_codigo_registro (codigo_registro) WHERE estado_id IN (1000, 1002); uix_res_producto_vigente (producto_id) WHERE estado_id=1000. Índices de Búsqueda: idx_registros_sanitarios_producto (producto_id) WHERE estado_id IN (1000, 1002).
Tabla productos_controlados: Control especial para sustancias fiscalizadas. Sus campos son: producto_controlado_id, producto_id, numero_autorizacion, stock_maximo_permitido, requiere_receta_retenida (0=No, 1=Sí), observaciones_control, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_prc_producto_activo (producto_id) WHERE estado_id=1000; uix_prc_numero_autorizacion (numero_autorizacion) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_productos_controlados_producto (producto_id) WHERE estado_id IN (1000, 1002).
Tabla promociones: Campañas comerciales con fechas de vigencia. Sus campos son: promocion_id, codigo, nombre, descripcion, tipo_beneficio_id (1500=DESCUENTO, 1501=PORCENTAJE, 1502=MONTO_FIJO, 1503=CANTIDAD, 1504=NINGUNO), valor_beneficio, fecha_inicio, fecha_fin, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_prom_codigo (codigo) WHERE estado_id IN (1000, 1002).
Tabla promociones_productos: Vinculación de promociones con productos específicos. Sus campos son: promocion_producto_id, promocion_id, producto_id, limite_por_transaccion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_prp_producto_activo (producto_id) WHERE estado_id=1000.
Tabla conversiones_unidad: Factores de conversión entre unidades de medida. Sus campos son: conversion_id, producto_id, unidad_origen_id, unidad_destino_id, factor_conversion, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cv_unique (producto_id, unidad_origen_id, unidad_destino_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_cv_producto (producto_id) WHERE estado_id IN (1000, 1002).
Tabla proveedores: Registro maestro de suministradores de productos. Sus campos son: proveedor_id, codigo, nombre, nit, direccion, telefono, email, contacto, rating_calidad_id (2050=PESIMO, 2051=DEFICIENTE, 2052=REGULAR, 2053=BUENO, 2054=EXCELENTE, 2055=NINGUNO), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_prov_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_prov_nombre (nombre) WHERE estado_id IN (1000, 1002); uix_prov_nit (nit) WHERE estado_id IN (1000, 1002) AND nit IS NOT NULL AND TRIM(nit) <> ''.
Tabla parametros_globales: Almacén de configuración clave-valor del sistema. Sus campos son: parametro_id, clave, valor, tipo_dato_id (1800=STRING, 1801=INTEGER, 1802=DECIMAL, 1803=BOOLEAN), descripcion, editable (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pg_clave (clave) WHERE estado_id IN (1000, 1002).
Tabla tareas_programadas: Orquestador de procesos automáticos y batch. Sus campos son: tarea_id, codigo, nombre, descripcion, tipo_tarea_id (3400=REPORTE, 3401=IA_MODELO, 3402=BACKUP, 3403=ALERTA, 3404=MANTENIMIENTO, 3405=FORECASTING, 3406=CLASIFICACION, 3407=OPTIMIZACION, 3408=VALIDACION, 3409=NINGUNO), subtipo_tarea_id (3450=SARIMA, 3451=SARIMAX, 3452=PROPHET, 3453=KMEANS, 3454=ROP_CALC, 3455=PATRON_CONSUMO, 3456=ALERTA_PREDICTIVA, 3457=VARIABLE_EXOGENA, 3458=METRICA_RENDIMIENTO, 3459=REENTRENAMIENTO, 3460=VALIDACION_CROSS, 3461=NINGUNO), frecuencia_id (3350=MINUTOS, 3351=HORAS, 3352=DIARIO, 3353=SEMANAL, 3354=MENSUAL, 3355=ANUAL, 3356=CRON, 3357=CONTINUA, 3358=TRIGGER_EVENTO, 3359=NINGUNO), cron_expresion, parametros (JSONB), ultima_ejecucion, proxima_ejecucion, ejecucion_exitosa (0=No, 1=Sí), ultimo_error, intentos_fallidos, max_intentos, tarea_dependencia_id, ejecutar_en_cascada (0=No, 1=Sí), modulo_estrategico_id (2150=FLUJO_CAJA, 2151=DEMANDA_INVENTARIO, 2152=PROVEEDORES_AHP, 2153=OPERACION_MERMAS, 2154=CLIENTES_RFM, 2155=PRECIOS_ELASTICIDAD, 2156=ANOMALIAS_FRAUDE, 2157=NINGUNO), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_tar_codigo (codigo) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_tar_modulo_estrategico (modulo_estrategico_id) WHERE modulo_estrategico_id IS NOT NULL AND estado_id IN (1000, 1002).
Tabla facturas: Gestión de talonarios y numeración fiscal. Sus campos son: factura_id, sucursal_id, tipo_comprobante_id (1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO), numero_actual, numero_inicial, numero_final, autorizacion, cuf, cufd, cuis, codigo_control, codigo_qr, fecha_autorizacion, fecha_vencimiento, gestion, estado_operativo_id (3300=EMITIDO, 3301=ANULADO, 3302=ANULADO_PARCIAL), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cf_sucursal_tipo_gestion (sucursal_id, tipo_comprobante_id, gestion) WHERE estado_operativo_id=3300 AND estado_id IN (1000, 1002). Índices de Búsqueda: idx_cf_sucursal_estado (sucursal_id, estado_operativo_id) WHERE estado_id IN (1000, 1002).
Tabla kardex: Registro maestro de todas las transacciones que afectan el inventario. Sus campos son: kardex_id, tipo_comprobante_id (1100=FACTURA, 1101=RECIBO, 1102=OTRO, 1103=NINGUNO), motivo_anulacion_id (2450=FACTURA_MAL_EMITIDA, 2451=ERROR_DATOS_CLIENTE, 2452=DEVOLUCION_MERCADERIA, 2453=CONTINGENCIA, 2454=OPERACION_NO_CONCRETADA, 2455=NINGUNO), cliente_id, proveedor_id, sucursal_id, sucursal_destino_id, kardex_origen_id, evento_id (1050=COMPRA, 1051=VENTA, 1052=PROFORMA, 1053=EGR_TRASPASO, 1054=ING_TRASPASO, 1055=ANULACION, 1056=AJUSTE_INGRESO, 1057=AJUSTE_EGRESO, 1058=SOLICITUD_COMPRA), codigo, comprobante, fecha_kardex, total_compra, total_venta, total_venta_factura, total_pagado, total_cambio, saldo_pendiente, lugar_entrega, numero_factura, validez_dias, receta_pdf, tipo_factura_id (2350=CON_FACTURA, 2351=SIN_FACTURA, 2352=NOTA_CREDITO_DEBITO, 2353=NINGUNO), estado_traspaso_id (2100=EN_TRANSITO, 2101=RECIBIDO, 2102=RECHAZADO, 2103=NO_APLICA), estado_financiero_id (2400=CANCELADO, 2401=PENDIENTE, 2402=PARCIAL, 2403=NINGUNO), estado_pedido_id (2250=COTIZADO, 2251=APROBADO, 2252=EN_RUTA, 2253=RECIBIDO, 2254=PARCIAL, 2255=RECHAZADO, 2256=CANCELADO), tipo_despacho_id (3550=VENTA_MOSTRADOR, 3551=DOMICILIO, 3552=RETIRO, 3553=TRANSFERENCIA, 3554=NINGUNO), cliente_limite_credito, fecha_vencimiento_credito, estado_credito_cliente_id (3700=NINGUNO, 3701=AL_DIA, 3702=PENDIENTE, 3703=PARCIAL, 3704=VENCIDO, 3705=CASTIGADO), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO, 1003=ANULADO). Índices Únicos: uix_kar_codigo (codigo) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_kar_cliente_id (cliente_id) WHERE estado_id IN (1000, 1002); idx_kar_proveedor_id (proveedor_id) WHERE estado_id IN (1000, 1002); idx_kar_numero_factura (numero_factura) WHERE estado_id IN (1000, 1002); idx_kar_kardex_origen_id (kardex_origen_id) WHERE kardex_origen_id IS NOT NULL; idx_kar_sucursal_fecha (sucursal_id, fecha_kardex DESC, evento_id) WHERE estado_id IN (1000, 1002); idx_kar_estado_financiero (estado_financiero_id, sucursal_id) WHERE estado_id IN (1000, 1002) AND estado_financiero_id IN (3501, 3502); idx_kar_estado_traspaso (sucursal_destino_id, estado_traspaso_id) WHERE evento_id IN (1053, 1054) AND estado_traspaso_id=2100.
Tabla instituciones: Catálogo de centros de salud y clínicas. Sus campos son: institucion_id, codigo, institucion, direccion, telefono, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_inst_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_inst_institucion (institucion) WHERE estado_id IN (1000, 1002).
Tabla especialidades: Especialidades médicas. Sus campos son: especialidad_id, especialidad, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_esp_especialidad (especialidad) WHERE estado_id IN (1000, 1002).
Tabla medicos: Catálogo de profesionales de la salud. Sus campos son: medico_id, medico, matricula, especialidad_id, telefono, email, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_med_medico (medico) WHERE estado_id IN (1000, 1002); uix_med_matricula (matricula) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_med_especialidad (especialidad_id) WHERE estado_id IN (1000, 1002); idx_med_estado (estado_id) WHERE estado_id IN (1000, 1002).
Tabla recetas: Registro de prescripciones médicas. Sus campos son: receta_id, kardex_id, cliente_id, sucursal_id, medico_id, institucion_id, tipo_receta_id (3850=SIMPLE, 3851=ARCHIVADA, 3852=VALADA, 3853=NINGUNO), numero_receta, fecha_emision, diagnostico, receta_pdf, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_rec_numero_receta (numero_receta) WHERE estado_id IN (1000, 1002); uix_rec_kardex_cliente_medico_fecha (kardex_id, cliente_id, medico_id, fecha_emision) WHERE estado_id IN (1000, 1002).
Tabla lotes_productos: Control de inventario por lote. Sus campos son: lote_id, producto_id, kardex_id, codigo_lote, fecha_vencimiento, cantidad_inicial, cantidad_actual, precio_costo, estado_lote_id (2500=VIGENTE, 2501=VENCIDO, 2502=AGOTADO, 2503=NINGUNO), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_lp_codigo_lote (producto_id, codigo_lote) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_lp_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_lp_fecha_vencimiento (fecha_vencimiento) WHERE estado_id IN (1000, 1002); idx_lp_kardex_id (kardex_id) WHERE estado_id IN (1000, 1002).
Tabla kardex_productos: Detalle transaccional de cada movimiento de inventario. Sus campos son: kardex_producto_id, kardex_id, producto_id, sucursal_id, lote_id, presentacion_id, tipo_pago_id (1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO), tipo_venta_id (1350=NINGUNO, 1351=CON_FACTURA, 1352=SIN_FACTURA), cantidad, cantidad_unidad_base, cantidad_salida, pcompra, factor_venta, factor_facturacion, precio_venta, precio_venta_factura, costo_venta, descuento, motivo_devolucion_id (3500=PRODUCTO_VENCIDO, 3501=PRODUCTO_DAÑADO, 3502=ERROR_PEDIDO, 3503=EXCESO_STOCK, 3504=DESCONTINUADO, 3505=DEVOLUCION_CLIENTE, 3506=NINGUNO), total_compra, total_venta, total_venta_factura, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_kp_kardex_producto_unique (kardex_id, producto_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_kp_tipo_venta (tipo_venta_id) WHERE estado_id IN (1000, 1002); idx_kp_presentacion (presentacion_id) WHERE estado_id IN (1000, 1002); idx_kp_fecha_registro (fecha_registro DESC) WHERE estado_id IN (1000, 1002); idx_kp_tipo_venta_fecha (tipo_venta_id, fecha_registro DESC) WHERE estado_id IN (1000, 1002); idx_kp_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_kp_kardex_id (kardex_id) WHERE estado_id IN (1000, 1002); idx_kp_lote_id (lote_id) WHERE estado_id IN (1000, 1002).
Tabla planes_pagos: Calendario de vencimientos para compras a crédito a proveedores. Sus campos son: plan_pago_id, kardex_id, numero_cuota, monto_programado, fecha_vencimiento, estado_pago_id (2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION, 2555=NINGUNO), fecha_pago, monto_pagado, observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pp_cuota_kardex (kardex_id, numero_cuota) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_pp_kardex_id (kardex_id) WHERE estado_id IN (1000, 1002); idx_pp_fecha_vencimiento (fecha_vencimiento) WHERE estado_id IN (1000, 1002).
Tabla comprobantes_pagos: Comprobantes de pago asociados a transacciones. Sus campos son: comprobante_pago_id, banco_id, tipo_pago_id (1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO), tipo_moneda_id (2300=BOLIVIANO, 2301=DOLAR, 2302=EURO, 2303=UFV), codigo_transaccion, monto, fecha_pago, titular_cuenta, autorizacion_nro, cuenta_destino, comprobante_digital_ruta, confirmado (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cpp_transaccion_unica (banco_id, codigo_transaccion) WHERE estado_id IN (1000, 1002) AND codigo_transaccion <> 'SN'. Índices de Búsqueda: idx_cpp_tipo_pago (tipo_pago_id) WHERE estado_id IN (1000, 1002); idx_cpp_fecha_pago (fecha_pago DESC) WHERE estado_id IN (1000, 1002).
Tabla pagos: Abonos o liquidaciones efectuadas por clientes para cubrir cuotas. Sus campos son: pago_id, kardex_id, plan_pago_id, tipo_pago_id (1400=NINGUNO, 1401=EFECTIVO, 1402=CHEQUE, 1403=QR, 1404=TRANSFERENCIA, 1405=DEPOSITO, 1406=OTRO), comprobante_pago_id, monto, fecha_pago, referencia, comprobante, observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_p_kardex_id (kardex_id) WHERE estado_id IN (1000, 1002); idx_p_plan_pago_id (plan_pago_id) WHERE estado_id IN (1000, 1002); idx_p_fecha_pago (fecha_pago) WHERE estado_id IN (1000, 1002).
Tabla planes_pagos_clientes: Calendario de vencimientos para ventas a crédito a clientes. Sus campos son: plan_pago_cliente_id, kardex_id, cliente_id, sucursal_id, numero_cuota, monto_programado, fecha_vencimiento, estado_pago_id (2550=PENDIENTE, 2551=PARCIAL, 2552=PAGADO, 2553=CERRADO, 2554=EN_VERIFICACION), fecha_pago, monto_pagado, observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_ppc_cuota_kardex (kardex_id, numero_cuota) WHERE estado_id IN (1000, 1002).
Tabla multas_retrasos_ventas: Penalizaciones por retraso en pagos de clientes. Sus campos son: multa_id, kardex_id, plan_pago_cliente_id, monto_multa, dias_retraso, porcentaje_aplicado, fecha_generacion, estado_multa_id (3750=PENDIENTE, 3751=PAGADA, 3752=CONDONADA, 3753=ANULADA, 3754=NINGUNO), observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_mrv_kardex_id (kardex_id) WHERE estado_id IN (1000, 1002); idx_mrv_plan_pago_id (plan_pago_cliente_id) WHERE estado_id IN (1000, 1002); idx_mrv_fecha_gen (fecha_generacion) WHERE estado_id IN (1000, 1002).
Tabla cajas: Sesiones de caja diarias por sucursal. Sus campos son: caja_id, sucursal_id, usuario_id_apertura, usuario_id_cierre, fecha_apertura, fecha_cierre, monto_inicial, monto_ventas, monto_ingresos, monto_egresos, monto_final_esperado, monto_final_real, diferencia, estado_caja_id (2650=ABIERTA, 2651=CERRADA), observaciones, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cja_sucursal_usuario_abierta (sucursal_id, usuario_id_apertura) WHERE estado_caja_id=2650 AND estado_id IN (1000, 1002). Índices de Búsqueda: idx_cja_sucursal_estado (sucursal_id, estado_caja_id) WHERE estado_id IN (1000, 1002); idx_cja_fecha_apertura (fecha_apertura DESC) WHERE estado_id IN (1000, 1002); idx_cja_usuario_apertura (usuario_id_apertura) WHERE estado_id IN (1000, 1002).
Tabla movimientos: Registro atómico de cada ingreso o egreso de caja. Sus campos son: movimiento_id, caja_id, referencia_id, usuario_id, tipo_movimiento_id (2600=INGRESO, 2601=EGRESO), monto, motivo, fecha_movimiento, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_mov_caja_id (caja_id) WHERE estado_id IN (1000, 1002); idx_mov_fecha (fecha_movimiento DESC) WHERE estado_id IN (1000, 1002); idx_mov_tipo (tipo_movimiento_id, caja_id) WHERE estado_id IN (1000, 1002); idx_mov_usuario (usuario_id) WHERE estado_id IN (1000, 1002); idx_mov_referencia (referencia_id) WHERE referencia_id IS NOT NULL AND estado_id IN (1000, 1002); idx_mov_fecha_registro (fecha_registro DESC) WHERE estado_id IN (1000, 1002).
Tabla alertas_notificaciones: Centro de gestión de eventos y avisos del sistema. Sus campos son: alerta_notificacion_id, sucursal_id, codigo, tipo_alerta_notificacion_id (2700=SISTEMA, 2701=ALERTA_STOCK, 2702=STOCK_BAJO, 2703=STOCK_CRITICO, 2704=STOCK_EXCESO, 2705=VENCIMIENTO_PROXIMO, 2706=VENCIMIENTO_INMEDIATO, 2707=VENCIMIENTO_VENCIDO, 2708=DEMANDA_ALTA, 2709=DEMANDA_BAJA, 2710=TENDENCIA_ANOMALA, 2711=PREDICCION_ROP, 2712=PREDICCION_DEMANDA, 2713=FORECASTING, 2714=PAGOS, 2715=PAGO_VENCIDO, 2716=PAGO_PROXIMO, 2717=DOCUMENTOS, 2718=FACTURA_PENDIENTE, 2719=FACTURA_ANULADA, 2720=SEGURIDAD_ACCESO, 2721=SEGURIDAD_INTENTO_FALLIDO, 2722=SISTEMA_ERROR, 2723=SISTEMA_RENDIMIENTO, 2724=NINGUNO), subtipo_alerta_id (2800=SARIMA, 2801=PROPHET, 2802=KMEANS, 2803=ROP_CALC, 2804=PATRON_CONSUMO, 2805=ALERTA_PREDICTIVA, 2806=QUIEBRE_STOCK, 2807=REORDEN, 2808=EXCESO, 2809=CADUCIDAD_CRITICA, 2810=CADUCIDAD_ALTA, 2811=CADUCIDAD_MEDIA, 2812=NINGUNO), origen_id (2850=SISTEMA, 2851=IA, 2852=USUARIO, 2853=TAREA_PROGRAMADA), nivel_critico_id (2900=CRITICO, 2901=ALTA, 2902=MEDIA, 2903=BAJA, 2904=INFORMATIVA, 2905=NINGUNO), titulo, mensaje, entidad_afectada_tipo, entidad_afectada_id, valor_actual, valor_umbral, metadata (JSONB), estado_alerta_id (2950=PENDIENTE, 2951=EN_PROCESO, 2952=RESUELTA, 2953=IGNORADA, 2954=ESCALADA, 2955=NINGUNO), prioridad_resolucion, usuario_asignado_id, fecha_asignacion, es_leido (0=No, 1=Sí), fecha_lectura, usuario_resolutor_id, fecha_resolucion, comentarios_resolucion, accion_tomada, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_aln_codigo (codigo) WHERE estado_id=1000. Índices de Búsqueda: idx_aln_sucursal_estado (sucursal_id, estado_alerta_id) WHERE estado_id=1000; idx_aln_fecha_deteccion (fecha_registro DESC) WHERE estado_id=1000; idx_aln_usuario_asignado (usuario_asignado_id) WHERE estado_id=1000; idx_aln_entidad_afectada (entidad_afectada_tipo, entidad_afectada_id) WHERE estado_id=1000; idx_aln_metadata_gin (metadata) USING gin.
Tabla modelos: Catálogo de algoritmos de IA y ML disponibles. Sus campos son: modelo_id, codigo, nombre, tipo_modelo_id (1450=ARIMA, 1451=SARIMA, 1452=SERIES_TEMPORALES, 1453=CLASIFICACION, 1454=OPTIMIZACION, 1455=DETECCION_ANOMALIAS, 1456=NINGUNO), descripcion, framework_id (3000=STATSMODELS, 3001=SCIKIT_LEARN, 3002=TENSORFLOW, 3003=CUSTOM, 3004=NINGUNO), version, parametros_default (JSONB), estado_modelo_id (2000=SIN_DATOS, 2001=ENTRENANDO, 2002=ACTIVO, 2003=RECHAZADO, 2004=OBSOLETO), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_mod_codigo (codigo) WHERE estado_id IN (1000, 1002); uix_mod_nombre (nombre) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_mod_tipo_modelo (tipo_modelo_id) WHERE estado_id IN (1000, 1002); idx_mod_framework (framework_id) WHERE estado_id IN (1000, 1002); idx_mod_estado_modelo (estado_modelo_id) WHERE estado_id IN (1000, 1002).
Tabla entrenamientos: Registro histórico de ejecuciones de entrenamiento de modelos de IA. Sus campos son: entrenamiento_id, modelo_id, fecha_ejecucion, fecha_inicio, fecha_fin, estado_ejecucion_id (3050=EN_PROCESO, 3051=COMPLETADO, 3052=FALLIDO, 3053=NINGUNO), duracion_segundos, registros_procesados, mensaje_error, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_ent_modelo_id (modelo_id) WHERE estado_id IN (1000, 1002); idx_ent_fecha_ejecucion (fecha_ejecucion DESC) WHERE estado_id IN (1000, 1002); idx_ent_estado_ejecucion (estado_ejecucion_id) WHERE estado_id IN (1000, 1002).
Tabla metricas_rendimiento: Cuantificación de la precisión de los modelos de IA. Sus campos son: metrica_id, entrenamiento_id, tipo_metricas_id (3100=REGRESION, 3101=CLASIFICACION, 3102=CLUSTERING, 3103=NINGUNO), metrica_precision_id (3600=MAE, 3601=RMSE, 3602=MAPE, 3603=R2, 3604=F1), factor_estacionalidad_id (3650=NONE, 3651=DIARIO, 3652=SEMANAL, 3653=MENSUAL, 3654=ANUAL, 3655=MULTIPLE), version_metricas, fecha_evaluacion, error_absoluto_medio, raiz_error_cuadratico_medio, score_principal, monto_error_promedio, detalles_metricas (JSONB), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_met_entrenamiento_id (entrenamiento_id) WHERE estado_id IN (1000, 1002); idx_met_tipo_metricas (tipo_metricas_id) WHERE estado_id IN (1000, 1002); idx_met_fecha_evaluacion (fecha_evaluacion DESC) WHERE estado_id IN (1000, 1002); idx_met_detalles_gin (detalles_metricas) USING gin.
Tabla patrones_consumo: Factores estacionales y de tendencia de demanda por producto y sucursal. Sus campos son: patron_id, producto_id, sucursal_id, entrenamiento_id, temporada_id (1600=NINGUNO, 1601=ALTA, 1602=MEDIA, 1603=BAJA), evento, factor_estacional, coeficiente_tendencia, fecha_inicio, fecha_fin, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_pat_producto_sucursal_entrenamiento (producto_id, sucursal_id, entrenamiento_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_pat_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_pat_sucursal_id (sucursal_id) WHERE estado_id IN (1000, 1002); idx_pat_temporada (temporada_id) WHERE estado_id IN (1000, 1002).
Tabla variables_exogenas: Datos externos que influyen en la demanda de productos. Sus campos son: variable_exogena_id, producto_id, sucursal_id, nombre_variable, valor, fecha_variable, fuente, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_veg_sucursal_producto_fecha_variable (sucursal_id, producto_id, fecha_variable, nombre_variable) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_veg_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_veg_sucursal_id (sucursal_id) WHERE estado_id IN (1000, 1002); idx_veg_fecha_variable (fecha_variable DESC) WHERE estado_id IN (1000, 1002).
Tabla umbrales_configuracion: Límites operativos para alertas automáticas. Sus campos son: umbral_id, tipo_umbral_id (3250=STOCK_MINIMO, 3251=DIAS_VENCIMIENTO, 3252=ERROR_PREDICCION, 3253=NINGUNO), producto_id, sucursal_id, valor_umbral, nivel_urgencia_id (1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO), activo (0=No, 1=Sí), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_umb_tipo_producto_sucursal_activo (tipo_umbral_id, producto_id, sucursal_id) WHERE estado_id IN (1000, 1002) AND activo=1.
Tabla logs_ejecucion: Bitácora técnica de eventos y errores del sistema. Sus campos son: log_id, entrenamiento_id, modulo, nivel_log_id (3150=INFO, 3151=WARNING, 3152=ERROR, 3153=DEBUG), mensaje, detalle (JSONB), fecha_log, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_log_entrenamiento_id (entrenamiento_id) WHERE estado_id IN (1000, 1002); idx_log_fecha_log (fecha_log DESC) WHERE estado_id IN (1000, 1002); idx_log_nivel_log (nivel_log_id) WHERE estado_id IN (1000, 1002).
Tabla auditorias: Registro inmutable de todas las operaciones de modificación de datos. Sus campos son: auditoria_id, tabla_afectada, registro_id, accion_realizada_id (3200=INSERT, 3201=UPDATE, 3202=DELETE), valores_anteriores (JSONB), valores_nuevos (JSONB), estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_aud_tabla_afectada (tabla_afectada) WHERE estado_id IN (1000, 1002); idx_aud_registro_id (registro_id) WHERE estado_id IN (1000, 1002); idx_aud_fecha_registro (fecha_registro DESC) WHERE estado_id IN (1000, 1002); idx_aud_accion_realizada (accion_realizada_id) WHERE estado_id IN (1000, 1002); idx_aud_usuario_id_registro (usuario_id_registro) WHERE estado_id IN (1000, 1002).
Tabla analitica_productos: Repositorio consolidado de resultados del motor de inteligencia de negocio. Sus campos son: analitica_id, producto_id, sucursal_id, demanda_pronosticada, intervalo_inf, intervalo_sup, fecha_prediccion, periodo_inicio, periodo_fin, fecha_vencimiento_critico, nivel_urgencia_id (1850=BAJA, 1851=MEDIA, 1852=ALTA, 1853=CRITICA, 1854=NINGUNO), punto_reorden, stock_seguridad, lead_time_dias, cluster_abc (0=Clase A, 1=Clase B, 2=Clase C), puntaje_total, criticidad_medica (0=Normal, 1=Crítico), estado_pronostico_id (1550=PENDIENTE, 1551=PROCESADO, 1552=ERROR, 1553=NINGUNO), motivo_outlier_id (1900=BLOQUEO, 1901=FERIADO_LOCAL, 1902=ERROR_SISTEMA, 1903=PICO_ANORMAL, 1904=ROTURA, 1905=ROBO, 1906=SOBRANTE, 1907=NINGUNO), valor_esperado, valor_real, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_an_producto_sucursal_activo (producto_id, sucursal_id) WHERE estado_id IN (1000, 1002). Índices de Búsqueda: idx_an_producto_id (producto_id) WHERE estado_id IN (1000, 1002); idx_an_sucursal_id (sucursal_id) WHERE estado_id IN (1000, 1002); idx_an_fecha_registro (fecha_registro DESC) WHERE estado_id IN (1000, 1002); idx_an_cluster (cluster_abc) WHERE cluster_abc IS NOT NULL AND estado_id IN (1000, 1002); idx_an_nivel_urgencia (nivel_urgencia_id) WHERE nivel_urgencia_id IS NOT NULL AND estado_id IN (1000, 1002); idx_an_vencimiento (fecha_vencimiento_critico) WHERE fecha_vencimiento_critico IS NOT NULL AND estado_id IN (1000, 1002); idx_an_estado_pronostico (estado_pronostico_id) WHERE estado_pronostico_id IS NOT NULL AND estado_id IN (1000, 1002); idx_an_motivo_outlier (motivo_outlier_id) WHERE motivo_outlier_id IS NOT NULL AND estado_id IN (1000, 1002).
Tabla historicos: Repositorio inmutable de documentos fiscales emitidos. Sus campos son: historico_id, kardex_id, cliente_id, sucursal_id, empresa_id, cliente_nombre, cliente_documento, cliente_documento_complemento, cliente_tipo_documento_abreviatura, cliente_razon_social, cliente_direccion, cliente_telefono, cliente_email, sucursal_nombre, sucursal_codigo, sucursal_telefono, sucursal_ubicacion, sucursal_codigo_sin, sucursal_punto_venta, empresa_nombre, empresa_codigo, empresa_nit, empresa_autorizacion, empresa_actividad_economica, numero_factura, fecha_emision, tipo_comprobante_abreviatura, tipo_factura_abreviatura, lugar_entrega, items (JSONB), subtotal, descuento_total, iva, total, total_pagado, total_cambio, metodo_pago_abreviatura, tipo_moneda_abreviatura, factor_cambio, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices de Búsqueda: idx_dh_kardex_id (kardex_id) WHERE estado_id IN (1000, 1002); idx_dh_cliente_id (cliente_id) WHERE estado_id IN (1000, 1002); idx_dh_sucursal_id (sucursal_id) WHERE estado_id IN (1000, 1002); idx_dh_empresa_id (empresa_id) WHERE estado_id IN (1000, 1002); idx_dh_numero_factura (numero_factura) WHERE estado_id IN (1000, 1002); idx_dh_fecha_emision (fecha_emision DESC) WHERE estado_id IN (1000, 1002); idx_dh_cliente_documento (cliente_documento) WHERE estado_id IN (1000, 1002); idx_dh_fecha_registro (fecha_registro DESC) WHERE estado_id IN (1000, 1002); idx_dh_items (items) USING gin.
Tabla configuraciones: Preferencias de personalización de la interfaz y documentos por empresa. Sus campos son: configuracion_id, empresa_id, formato_pdf_id (1950=ESTANDAR, 1951=RESUMIDO, 1952=DETALLADO), pie_pagina, logo_secundario, mensaje_agradecimiento, estado_id (1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO). Índices Únicos: uix_cfg_empresa_unique (empresa_id) WHERE estado_id IN (1000, 1002).

Lista de Dominios. El valor es integer su interpretacion depende del dominio. Si es 0 para todos los que pertenecen a un grupo de dominio significa que no tiene uso.

| dominio_id | dominio | abreviatura | valor |
| :--- | :--- | :--- | :--- |
| 1000 | EstadoID | ACTIVO | 0 |
| 1001 | EstadoID | BORRADO | 0 |
| 1002 | EstadoID | HISTORICO | 0 |
| 1003 | EstadoID | ANULADO | 0 |
| 1050 | EventoID | COMPRA | 0 |
| 1051 | EventoID | VENTA | 0 |
| 1052 | EventoID | PROFORMA | 0 |
| 1053 | EventoID | EGR_TRASPASO | 0 |
| 1054 | EventoID | ING_TRASPASO | 0 |
| 1055 | EventoID | ANULACION | 0 |
| 1056 | EventoID | AJUSTE_INGRESO | 0 |
| 1057 | EventoID | AJUSTE_EGRESO | 0 |
| 1058 | EventoID | SOLICITUD_COMPRA | 0 |
| 1059 | EventoID | VENTA_RESERVA | 0 |
| 1060 | EventoID | DEV_CLIENTE | 0 |
| 1061 | EventoID | DEV_PROVEEDOR | 0 |
| 1062 | EventoID | ROBO | 0 |
| 1063 | EventoID | PERDIDA_CADUCIDAD | 0 |
| 1064 | EventoID | MERMA_ROTURA | 0 |
| 1065 | EventoID | INVENTARIO_FISICO_SOBRANTE | 0 |
| 1066 | EventoID | INVENTARIO_FISICO_FALTANTE | 0 |
| 1067 | EventoID | CONVERSION_UNIDADES | 0 |
| 1068 | EventoID | SALIDA_MUESTRA_MEDICA | 0 |
| 1069 | EventoID | INGRESO_DONACION | 0 |
| 1070 | EventoID | RETIRO_CUARENTENA | 0 |
| 1100 | TipoComprobanteID | FACTURA | 0 |
| 1101 | TipoComprobanteID | RECIBO | 0 |
| 1102 | TipoComprobanteID | OTRO | 0 |
| 1103 | TipoComprobanteID | NINGUNO | 0 |
| 1150 | TipoClienteID | NATURAL | 0 |
| 1151 | TipoClienteID | JURIDICA | 0 |
| 1200 | GeneroID | MASCULINO | 0 |
| 1201 | GeneroID | FEMENINO | 0 |
| 1250 | EstadoCivilMasculinoID | SOLTERO | 0 |
| 1251 | EstadoCivilMasculinoID | CASADO | 0 |
| 1252 | EstadoCivilMasculinoID | DIVORCIADO | 0 |
| 1253 | EstadoCivilMasculinoID | VIUDO | 0 |
| 1254 | EstadoCivilMasculinoID | UNION_LIBRE | 0 |
| 1300 | EstadoCivilFemeninoID | SOLTERA | 0 |
| 1301 | EstadoCivilFemeninoID | CASADA | 0 |
| 1302 | EstadoCivilFemeninoID | DIVORCIADA | 0 |
| 1303 | EstadoCivilFemeninoID | VIUDA | 0 |
| 1304 | EstadoCivilFemeninoID | UNION_LIBRE | 0 |
| 1350 | TipoVentaID | NINGUNO | 0 |
| 1351 | TipoVentaID | CON_FACTURA | 0 |
| 1352 | TipoVentaID | SIN_FACTURA | 0 |
| 1400 | TipoPagoID | NINGUNO | 0 |
| 1401 | TipoPagoID | EFECTIVO | 1 |
| 1402 | TipoPagoID | TARJETA | 2 |
| 1403 | TipoPagoID | CHEQUE | 3 |
| 1404 | TipoPagoID | VALE | 4 |
| 1405 | TipoPagoID | OTROS | 5 |
| 1406 | TipoPagoID | SIN_PAGO | 6 |
| 1407 | TipoPagoID | TRANSFERENCIA | 7 |
| 1408 | TipoPagoID | DEPOSITO | 8 |
| 1409 | TipoPagoID | QR | 9 |
| 1450 | TipoModeloID | ARIMA | 0 |
| 1451 | TipoModeloID | SARIMA | 0 |
| 1452 | TipoModeloID | SERIES_TEMPORALES | 0 |
| 1453 | TipoModeloID | CLASIFICACION | 0 |
| 1454 | TipoModeloID | OPTIMIZACION | 0 |
| 1455 | TipoModeloID | DETECCION_ANOMALIAS | 0 |
| 1456 | TipoModeloID | NINGUNO | 0 |
| 1500 | TipoBeneficioID | DESCUENTO | 0 |
| 1501 | TipoBeneficioID | PORCENTAJE | 0 |
| 1502 | TipoBeneficioID | MONTO_FIJO | 0 |
| 1503 | TipoBeneficioID | CANTIDAD | 0 |
| 1504 | TipoBeneficioID | NINGUNO | 0 |
| 1550 | EstadoPronosticoID | PENDIENTE | 0 |
| 1551 | EstadoPronosticoID | PROCESADO | 0 |
| 1552 | EstadoPronosticoID | ERROR | 0 |
| 1553 | EstadoPronosticoID | NINGUNO | 0 |
| 1600 | TemporadaID | NINGUNO | 0 |
| 1601 | TemporadaID | ALTA | 0 |
| 1602 | TemporadaID | MEDIA | 0 |
| 1603 | TemporadaID | BAJA | 0 |
| 1650 | EstadoFiscalID | ACTIVO | 0 |
| 1651 | EstadoFiscalID | AGOTADO | 0 |
| 1652 | EstadoFiscalID | VENCIDO | 0 |
| 1653 | EstadoFiscalID | CANCELADO | 0 |
| 1700 | TipoAlmacenID | NORMAL | 0 |
| 1701 | TipoAlmacenID | REFRIGERADO | 0 |
| 1702 | TipoAlmacenID | CONGELADO | 0 |
| 1703 | TipoAlmacenID | ESPECIAL | 0 |
| 1704 | TipoAlmacenID | TRANSITO | 0 |
| 1705 | TipoAlmacenID | MATERIAL_MEDICO | 0 |
| 1706 | TipoAlmacenID | COSMETICA | 0 |
| 1707 | TipoAlmacenID | ALIMENTOS | 0 |
| 1708 | TipoAlmacenID | MATERIA_PRIMA | 0 |
| 1709 | TipoAlmacenID | RECEPCION | 0 |
| 1710 | TipoAlmacenID | DEVOLUCIONES | 0 |
| 1711 | TipoAlmacenID | DESPACHO | 0 |
| 1712 | TipoAlmacenID | CUARENTENA | 0 |
| 1750 | TipoCuentaID | CUENTA_CORRIENTE | 0 |
| 1751 | TipoCuentaID | CAJA_AHORROS | 0 |
| 1752 | TipoCuentaID | AHORRO_PROGRAMADO | 0 |
| 1753 | TipoCuentaID | PLAZO_FIJO | 0 |
| 1754 | TipoCuentaID | INVERSION | 0 |
| 1755 | TipoCuentaID | NO_APLICA | 0 |
| 1800 | TipoDatoID | STRING | 0 |
| 1801 | TipoDatoID | INTEGER | 0 |
| 1802 | TipoDatoID | DECIMAL | 0 |
| 1803 | TipoDatoID | BOOLEAN | 0 |
| 1850 | NivelUrgenciaID | BAJA | 0 |
| 1851 | NivelUrgenciaID | MEDIA | 0 |
| 1852 | NivelUrgenciaID | ALTA | 0 |
| 1853 | NivelUrgenciaID | CRITICA | 0 |
| 1854 | NivelUrgenciaID | NINGUNO | 0 |
| 1900 | MotivoOutlierID | BLOQUEO | 0 |
| 1901 | MotivoOutlierID | FERIADO_LOCAL | 0 |
| 1902 | MotivoOutlierID | ERROR_SISTEMA | 0 |
| 1903 | MotivoOutlierID | PICO_ANORMAL | 0 |
| 1904 | MotivoOutlierID | ROTURA | 0 |
| 1905 | MotivoOutlierID | ROBO | 0 |
| 1906 | MotivoOutlierID | SOBRANTE | 0 |
| 1907 | MotivoOutlierID | NINGUNO | 0 |
| 1950 | FormatoPDFID | ESTANDAR | 0 |
| 1951 | FormatoPDFID | RESUMIDO | 0 |
| 1952 | FormatoPDFID | DETALLADO | 0 |
| 2000 | EstadoModeloID | SIN_DATOS | 0 |
| 2001 | EstadoModeloID | ENTRENANDO | 0 |
| 2002 | EstadoModeloID | ACTIVO | 0 |
| 2003 | EstadoModeloID | RECHAZADO | 0 |
| 2004 | EstadoModeloID | OBSOLETO | 0 |
| 2050 | CalidadRatingID | PESIMO | 0 |
| 2051 | CalidadRatingID | DEFICIENTE | 0 |
| 2052 | CalidadRatingID | REGULAR | 0 |
| 2053 | CalidadRatingID | BUENO | 0 |
| 2054 | CalidadRatingID | EXCELENTE | 0 |
| 2055 | CalidadRatingID | NINGUNO | 0 |
| 2100 | EstadoTraspasoID | EN_TRANSITO | 0 |
| 2101 | EstadoTraspasoID | RECIBIDO | 0 |
| 2102 | EstadoTraspasoID | RECHAZADO | 0 |
| 2103 | EstadoTraspasoID | NO_APLICA | 0 |
| 2150 | ModuloEstrategicoID | FLUJO_CAJA | 0 |
| 2151 | ModuloEstrategicoID | DEMANDA_INVENTARIO | 0 |
| 2152 | ModuloEstrategicoID | PROVEEDORES_AHP | 0 |
| 2153 | ModuloEstrategicoID | OPERACION_MERMAS | 0 |
| 2154 | ModuloEstrategicoID | CLIENTES_RFM | 0 |
| 2155 | ModuloEstrategicoID | PRECIOS_ELASTICIDAD | 0 |
| 2156 | ModuloEstrategicoID | ANOMALIAS_FRAUDE | 0 |
| 2157 | ModuloEstrategicoID | NINGUNO | 0 |
| 2200 | TipoDocumentoID | CEDULA_IDENTIDAD | 1 |
| 2201 | TipoDocumentoID | CEDULA_IDENTIDAD_EXTRANJERO | 2 |
| 2202 | TipoDocumentoID | PASAPORTE | 3 |
| 2203 | TipoDocumentoID | OTRO | 4 |
| 2204 | TipoDocumentoID | NIT | 5 |
| 2250 | EstadoPedidoID | COTIZADO | 1 |
| 2251 | EstadoPedidoID | APROBADO | 2 |
| 2252 | EstadoPedidoID | EN_RUTA | 3 |
| 2253 | EstadoPedidoID | RECIBIDO | 4 |
| 2254 | EstadoPedidoID | PARCIAL | 5 |
| 2255 | EstadoPedidoID | RECHAZADO | 6 |
| 2256 | EstadoPedidoID | CANCELADO | 7 |
| 2300 | TipoMonedaID | BOLIVIANO | 1 |
| 2301 | TipoMonedaID | DOLAR | 2 |
| 2302 | TipoMonedaID | EURO | 3 |
| 2303 | TipoMonedaID | UFV | 4 |
| 2350 | TipoFacturaID | CON_FACTURA | 1 |
| 2351 | TipoFacturaID | SIN_FACTURA | 2 |
| 2352 | TipoFacturaID | NOTA_CREDITO_DEBITO | 3 |
| 2353 | TipoFacturaID | NINGUNO | 4 |
| 2400 | EstadoFinancieroID | CANCELADO | 0 |
| 2401 | EstadoFinancieroID | PENDIENTE | 0 |
| 2402 | EstadoFinancieroID | PARCIAL | 0 |
| 2403 | EstadoFinancieroID | NINGUNO | 0 |
| 2450 | MotivoAnulacionID | FACTURA_MAL_EMITIDA | 1 |
| 2451 | MotivoAnulacionID | ERROR_DATOS_CLIENTE | 2 |
| 2452 | MotivoAnulacionID | DEVOLUCION_MERCADERIA | 3 |
| 2453 | MotivoAnulacionID | CONTINGENCIA | 4 |
| 2454 | MotivoAnulacionID | OPERACION_NO_CONCRETADA | 5 |
| 2455 | MotivoAnulacionID | NINGUNO | 0 |
| 2500 | EstadoLoteID | VIGENTE | 0 |
| 2501 | EstadoLoteID | VENCIDO | 0 |
| 2502 | EstadoLoteID | AGOTADO | 0 |
| 2503 | EstadoLoteID | NINGUNO | 0 |
| 2550 | EstadoPagoID | PENDIENTE | 0 |
| 2551 | EstadoPagoID | PARCIAL | 0 |
| 2552 | EstadoPagoID | PAGADO | 0 |
| 2553 | EstadoPagoID | CERRADO | 0 |
| 2554 | EstadoPagoID | EN_VERIFICACION | 0 |
| 2555 | EstadoPagoID | NINGUNO | 0 |
| 2600 | TipoMovimientoID | INGRESO | 0 |
| 2601 | TipoMovimientoID | EGRESO | 0 |
| 2650 | EstadoCajaID | ABIERTA | 0 |
| 2651 | EstadoCajaID | CERRADA | 0 |
| 2700 | TipoAlertaNotificacionID | SISTEMA | 0 |
| 2701 | TipoAlertaNotificacionID | ALERTA_STOCK | 0 |
| 2702 | TipoAlertaNotificacionID | STOCK_BAJO | 0 |
| 2703 | TipoAlertaNotificacionID | STOCK_CRITICO | 0 |
| 2704 | TipoAlertaNotificacionID | STOCK_EXCESO | 0 |
| 2705 | TipoAlertaNotificacionID | VENCIMIENTO_PROXIMO | 0 |
| 2706 | TipoAlertaNotificacionID | VENCIMIENTO_INMEDIATO | 0 |
| 2707 | TipoAlertaNotificacionID | VENCIMIENTO_VENCIDO | 0 |
| 2708 | TipoAlertaNotificacionID | DEMANDA_ALTA | 0 |
| 2709 | TipoAlertaNotificacionID | DEMANDA_BAJA | 0 |
| 2710 | TipoAlertaNotificacionID | TENDENCIA_ANOMALA | 0 |
| 2711 | TipoAlertaNotificacionID | PREDICCION_ROP | 0 |
| 2712 | TipoAlertaNotificacionID | PREDICCION_DEMANDA | 0 |
| 2713 | TipoAlertaNotificacionID | FORECASTING | 0 |
| 2714 | TipoAlertaNotificacionID | PAGOS | 0 |
| 2715 | TipoAlertaNotificacionID | PAGO_VENCIDO | 0 |
| 2716 | TipoAlertaNotificacionID | PAGO_PROXIMO | 0 |
| 2717 | TipoAlertaNotificacionID | DOCUMENTOS | 0 |
| 2718 | TipoAlertaNotificacionID | FACTURA_PENDIENTE | 0 |
| 2719 | TipoAlertaNotificacionID | FACTURA_ANULADA | 0 |
| 2720 | TipoAlertaNotificacionID | SEGURIDAD_ACCESO | 0 |
| 2721 | TipoAlertaNotificacionID | SEGURIDAD_INTENTO_FALLIDO | 0 |
| 2722 | TipoAlertaNotificacionID | SISTEMA_ERROR | 0 |
| 2723 | TipoAlertaNotificacionID | SISTEMA_RENDIMIENTO | 0 |
| 2724 | TipoAlertaNotificacionID | NINGUNO | 0 |
| 2750 | AmbienteID | PRODUCCION | 1 |
| 2751 | AmbienteID | PILOTO_PRUEBAS | 2 |
| 2800 | SubtipoAlertaID | SARIMA | 0 |
| 2801 | SubtipoAlertaID | PROPHET | 0 |
| 2802 | SubtipoAlertaID | KMEANS | 0 |
| 2803 | SubtipoAlertaID | ROP_CALC | 0 |
| 2804 | SubtipoAlertaID | PATRON_CONSUMO | 0 |
| 2805 | SubtipoAlertaID | ALERTA_PREDICTIVA | 0 |
| 2806 | SubtipoAlertaID | QUIEBRE_STOCK | 0 |
| 2807 | SubtipoAlertaID | REORDEN | 0 |
| 2808 | SubtipoAlertaID | EXCESO | 0 |
| 2809 | SubtipoAlertaID | CADUCIDAD_CRITICA | 0 |
| 2810 | SubtipoAlertaID | CADUCIDAD_ALTA | 0 |
| 2811 | SubtipoAlertaID | CADUCIDAD_MEDIA | 0 |
| 2812 | SubtipoAlertaID | NINGUNO | 0 |
| 2850 | OrigenAlertaID | SISTEMA | 0 |
| 2851 | OrigenAlertaID | IA | 0 |
| 2852 | OrigenAlertaID | USUARIO | 0 |
| 2853 | OrigenAlertaID | TAREA_PROGRAMADA | 0 |
| 2900 | NivelCriticoID | CRITICO | 0 |
| 2901 | NivelCriticoID | ALTA | 0 |
| 2902 | NivelCriticoID | MEDIA | 0 |
| 2903 | NivelCriticoID | BAJA | 0 |
| 2904 | NivelCriticoID | INFORMATIVA | 0 |
| 2905 | NivelCriticoID | NINGUNO | 0 |
| 2950 | EstadoAlertaID | PENDIENTE | 0 |
| 2951 | EstadoAlertaID | EN_PROCESO | 0 |
| 2952 | EstadoAlertaID | RESUELTA | 0 |
| 2953 | EstadoAlertaID | IGNORADA | 0 |
| 2954 | EstadoAlertaID | ESCALADA | 0 |
| 2955 | EstadoAlertaID | NINGUNO | 0 |
| 3000 | FrameworkID | STATSMODELS | 0 |
| 3001 | FrameworkID | SCIKIT_LEARN | 0 |
| 3002 | FrameworkID | TENSORFLOW | 0 |
| 3003 | FrameworkID | CUSTOM | 0 |
| 3004 | FrameworkID | NINGUNO | 0 |
| 3050 | EstadoEjecucionID | EN_PROCESO | 0 |
| 3051 | EstadoEjecucionID | COMPLETADO | 0 |
| 3052 | EstadoEjecucionID | FALLIDO | 0 |
| 3053 | EstadoEjecucionID | NINGUNO | 0 |
| 3100 | TipoMetricasID | REGRESION | 0 |
| 3101 | TipoMetricasID | CLASIFICACION | 0 |
| 3102 | TipoMetricasID | CLUSTERING | 0 |
| 3103 | TipoMetricasID | NINGUNO | 0 |
| 3150 | NivelLogID | INFO | 0 |
| 3151 | NivelLogID | WARNING | 0 |
| 3152 | NivelLogID | ERROR | 0 |
| 3153 | NivelLogID | DEBUG | 0 |
| 3200 | AccionRealizadaID | INSERT | 0 |
| 3201 | AccionRealizadaID | UPDATE | 0 |
| 3202 | AccionRealizadaID | DELETE | 0 |
| 3250 | TipoUmbralID | STOCK_MINIMO | 0 |
| 3251 | TipoUmbralID | DIAS_VENCIMIENTO | 0 |
| 3252 | TipoUmbralID | ERROR_PREDICCION | 0 |
| 3253 | TipoUmbralID | NINGUNO | 0 |
| 3300 | EstadoDocumentoID | EMITIDO | 0 |
| 3301 | EstadoDocumentoID | ANULADO | 0 |
| 3302 | EstadoDocumentoID | ANULADO_PARCIAL | 0 |
| 3350 | FrecuenciaID | MINUTOS | 0 |
| 3351 | FrecuenciaID | HORAS | 0 |
| 3352 | FrecuenciaID | DIARIO | 0 |
| 3353 | FrecuenciaID | SEMANAL | 0 |
| 3354 | FrecuenciaID | MENSUAL | 0 |
| 3355 | FrecuenciaID | ANUAL | 0 |
| 3356 | FrecuenciaID | CRON | 0 |
| 3357 | FrecuenciaID | CONTINUA | 0 |
| 3358 | FrecuenciaID | TRIGGER_EVENTO | 0 |
| 3359 | FrecuenciaID | NINGUNO | 0 |
| 3400 | TipoTareaID | REPORTE | 0 |
| 3401 | TipoTareaID | IA_MODELO | 0 |
| 3402 | TipoTareaID | BACKUP | 0 |
| 3403 | TipoTareaID | ALERTA | 0 |
| 3404 | TipoTareaID | MANTENIMIENTO | 0 |
| 3405 | TipoTareaID | FORECASTING | 0 |
| 3406 | TipoTareaID | CLASIFICACION | 0 |
| 3407 | TipoTareaID | OPTIMIZACION | 0 |
| 3408 | TipoTareaID | VALIDACION | 0 |
| 3409 | TipoTareaID | NINGUNO | 0 |
| 3450 | SubtipoTareaID | SARIMA | 0 |
| 3451 | SubtipoTareaID | SARIMAX | 0 |
| 3452 | SubtipoTareaID | PROPHET | 0 |
| 3453 | SubtipoTareaID | KMEANS | 0 |
| 3454 | SubtipoTareaID | ROP_CALC | 0 |
| 3455 | SubtipoTareaID | PATRON_CONSUMO | 0 |
| 3456 | SubtipoTareaID | ALERTA_PREDICTIVA | 0 |
| 3457 | SubtipoTareaID | VARIABLE_EXOGENA | 0 |
| 3458 | SubtipoTareaID | METRICA_RENDIMIENTO | 0 |
| 3459 | SubtipoTareaID | REENTRENAMIENTO | 0 |
| 3460 | SubtipoTareaID | VALIDACION_CROSS | 0 |
| 3461 | SubtipoTareaID | NINGUNO | 0 |
| 3500 | MotivoDevolucionID | PRODUCTO_VENCIDO | 1 |
| 3501 | MotivoDevolucionID | PRODUCTO_DAÑADO | 2 |
| 3502 | MotivoDevolucionID | ERROR_PEDIDO | 3 |
| 3503 | MotivoDevolucionID | EXCESO_STOCK | 4 |
| 3504 | MotivoDevolucionID | DESCONTINUADO | 5 |
| 3505 | MotivoDevolucionID | DEVOLUCION_CLIENTE | 6 |
| 3506 | MotivoDevolucionID | NINGUNO | 0 |
| 3550 | TipoDespachoID | VENTA_MOSTRADOR | 1 |
| 3551 | TipoDespachoID | DOMICILIO | 2 |
| 3552 | TipoDespachoID | RETIRO | 3 |
| 3553 | TipoDespachoID | TRANSFERENCIA | 4 |
| 3554 | TipoDespachoID | NINGUNO | 0 |
| 3600 | MetricaPrecisionID | MAE | 1 |
| 3601 | MetricaPrecisionID | RMSE | 2 |
| 3602 | MetricaPrecisionID | MAPE | 3 |
| 3603 | MetricaPrecisionID | R2 | 4 |
| 3604 | MetricaPrecisionID | F1 | 5 |
| 3605 | MetricaPrecisionID | NINGUNO | 0 |
| 3650 | FactorEstacionalidadID | NONE | 0 |
| 3651 | FactorEstacionalidadID | DIARIO | 1 |
| 3652 | FactorEstacionalidadID | SEMANAL | 2 |
| 3653 | FactorEstacionalidadID | MENSUAL | 3 |
| 3654 | FactorEstacionalidadID | ANUAL | 4 |
| 3655 | FactorEstacionalidadID | MULTIPLE | 5 |
| 3700 | EstadoCreditoClienteID | NINGUNO | 0 |
| 3701 | EstadoCreditoClienteID | AL_DIA | 0 |
| 3702 | EstadoCreditoClienteID | PENDIENTE | 0 |
| 3703 | EstadoCreditoClienteID | PARCIAL | 0 |
| 3704 | EstadoCreditoClienteID | VENCIDO | 0 |
| 3705 | EstadoCreditoClienteID | CASTIGADO | 0 |
| 3750 | EstadoMultaID | PENDIENTE | 0 |
| 3751 | EstadoMultaID | PAGADA | 0 |
| 3752 | EstadoMultaID | CONDONADA | 0 |
| 3753 | EstadoMultaID | ANULADA | 0 |
| 3754 | EstadoMultaID | NINGUNO | 0 |
| 3800 | GradoEquivalenciaID | TOTAL | 1 |
| 3801 | GradoEquivalenciaID | PARCIAL | 2 |
| 3802 | GradoEquivalenciaID | TERAPEUTICO | 3 |
| 3803 | GradoEquivalenciaID | NINGUNO | 4 |
| 3850 | TipoRecetaID | SIMPLE | 1 |
| 3851 | TipoRecetaID | ARCHIVADA | 2 |
| 3852 | TipoRecetaID | VALADA | 3 |
| 3853 | TipoRecetaID | NINGUNO | 4 |
| 3900 | ModalidadFacturacionID | NINGUNO | 0 |
| 3901 | ModalidadFacturacionID | ELECTRONICA | 1 |
| 3902 | ModalidadFacturacionID | COMPUTARIZADA | 2 |
| 3903 | ModalidadFacturacionID | MANUAL | 2 |
| 3950 | TipoPuntoVentaID | NINGUNO | 0 |
| 3951 | TipoPuntoVentaID | CAJA | 1 |

escáner automotriz o herramienta de diagnóstico
Software: El Lenguaje y la Lógica

Aquí está la "inteligencia" del sistema. Necesitarás programas para programar el cerebro y aplicaciones para interactuar con él.

    Entornos de Programación: Son las herramientas para escribir el código que irá en tu microcontrolador.

        Para ESP32/Arduino: PlatformIO o el IDE de Arduino. Usan principalmente C++.

        Para Raspberry Pi: Se puede usar Python con librerías como pythonCAN. 

    Librerías de Comunicación: Son bloques de código ya escritos que facilitan la tarea.

        Para el módulo MCP2515, la librería mcp_can.h para Arduino es muy popular.

        Para el ELM327, se comunica por comandos estándar (como AT y 01 0C para pedir las RPM). 

    Protocolos a Implementar: Debes programar tu software para "hablar" los protocolos OBD-II.

        Deberás implementar la lógica para enviar PIDs (Parameter IDs) , que son preguntas estandarizadas (ej. "¿Cuál es la velocidad?" o "¿Hay códigos de falla?").

        Para vehículos más complejos, quizás necesites comunicarte por el protocolo ISO 14230 (K-Line) , aunque la mayoría de los autos modernos usan CAN Bus.

🔧 Herramientas de Prueba y Validación

Para asegurarte de que tu creación funciona bien y no daña el auto, necesitarás herramientas para "ver" lo que está pasando en el cable.

    Analizador de Bus CAN: Un dispositivo profesional que te permite "escuchar" todo el tráfico de datos en el bus CAN del auto para ver si tu escáner está enviando y recibiendo la información correcta.

    Osciloscopio o Analizador Lógico: Esenciales para visualizar las señales eléctricas (como los voltajes en CAN_H y CAN_L) y verificar que la comunicación física sea correcta. 

💡 Resumen y Estrategia para tu Tesis

Para un proyecto de tesis, se recomienda optar por un enfoque de desarrollo basado en un microcontrolador (como ESP32 o STM32) y un módulo transceptor CAN Bus (como el MCP2515+TJA1050) . Esta ruta te obliga a comprender en profundidad cómo funciona la comunicación OBD-II (desde el nivel eléctrico hasta el de los datos), lo cual es un tema mucho más robusto y académicamente valioso que simplemente usar un adaptador ELM327 ya hecho .

La elección de los componentes debe justificarse en tu tesis. Por ejemplo, el ESP32 es una excelente opción porque es potente, tiene WiFi y Bluetooth integrados, y te permite desarrollar aplicaciones más avanzadas, como el diagnóstico remoto por Internet . El módulo MCP2515 es un estándar de la industria, muy documentado y con librerías disponibles, y el TJA1050 es el transceptor encargado de manejar los niveles de voltaje específicos del bus CAN del auto .

Espero que este desglose te sirva como punto de partida para planificar tu proyecto. Si necesitas más detalles sobre algún componente en concreto, aquí estoy para ayudarte.
puedo usa mi laptop ???
Read 12 web pages

Sí, puedes usar tu laptop sin ningún problema. De hecho, es una de las formas más comunes y potentes de hacer diagnóstico automotriz .

Para convertir tu laptop en un escáner, necesitas dos cosas:

    Un adaptador que conecte tu laptop al auto: Este se enchufa al puerto de diagnóstico del vehículo y al puerto USB de tu computadora (o vía Bluetooth). El más conocido usa el chip ELM327 . Un adaptador por USB es más estable y rápido .

    Un software de diagnóstico en tu laptop: Es el programa que se comunica con el adaptador y te muestra la información en la pantalla. Algunos vienen incluidos con el adaptador, y hay muchas opciones gratuitas .

🛠️ Componentes clave para tu proyecto

Si esto es para una tesis, te resultará útil entender el "por qué" de cada pieza. Aquí tienes los detalles de lo que necesitarías:
Componente	Función Principal	Detalles para tu Tesis
Adaptador OBD-II a USB (ej. ELM327)	Traduce la información del auto a un formato que tu laptop entienda .	Busca uno de buena calidad, como el OBDLink SX o el vLinker FS USB, que son más fiables y estables . Evita clones chinos muy baratos.
Conexión Inalámbrica (Opcional)	Para no depender de un cable USB .	Si usas Bluetooth, asegúrate de que tu laptop lo tenga. Es útil, pero menos fiable que el USB para transmitir muchos datos .
Software de Diagnóstico	La "cara" del escáner. Muestra los códigos de fallo, datos en tiempo real, etc. .	OBDwiz es muy popular y suele venir con adaptadores como el OBDLink SX . FORScan es excelente para coches Ford/Mazda .
Software de Código Abierto (Opcional)	Te permite programar y personalizar tu propio software .	Herramientas como pyobd (en Python) son perfectas para una tesis, ya que puedes modificar y estudiar el código fuente a fondo .
💡 Consejos para tu tesis

    Opta por USB: Para un proyecto de tesis, donde la fiabilidad de los datos es clave, se recomienda una conexión USB por su estabilidad y velocidad .

    Documenta la comunicación: Si eliges un proyecto más profundo, puedes programar el software tú mismo usando librerías como python-OBD o freediag . Esto te permitirá entender a bajo nivel cómo se comunican la laptop y el auto.

    Verifica la compatibilidad: Asegúrate de que el auto que vas a usar sea compatible con el estándar OBD-II (en EE. UU. desde 1996, en Europa desde 2001) .

En resumen, tu laptop es una excelente base para este proyecto. El "secreto" está en elegir un buen adaptador y el software que mejor se adapte a tus objetivos, ya sea una solución lista para usar o un desarrollo propio desde cero.
