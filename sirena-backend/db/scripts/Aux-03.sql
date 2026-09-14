
### 1.b OBTENER TOKEN USUARIO 3
# @name loginUser3
POST {{baseUrl}}/auth/validar
Content-Type: application/json

{
    "username": "PRUEBA",
    "password": "12345678"
}

### 2.b GUARDAR TOKEN USUARIO 3
@authToken = {{loginUser3.response.body.token}}

SALE 
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNiIsInVzZXJuYW1lIjoiUFJVRUJBIiwicm9sX2lkIjoiOSIsImlhdCI6MTc4OTM1NTg3NywiZXhwIjoxNzg5Mzg0Njc3fQ.HZHr9MoTZ12A0iXnfFZrSEjoSfCgisH2YzRaHliSHUH6hWlXTJI3g4ygbLTRMxKnFBmggYgDo0TK8D7J5-47FOeyTv-7XXLOYIZGyahURV4JOylwyXXDz-DPXUfYJs9tQ8kd3J8k8dA-0DcdrU6jvCDvAddmsaQFOgFKV3P3Bk6DTHhxSRVMzbE5qp2h10UiFkPE5vayFc_A3cVTjolJYAh8wrOJjkOLxBgVC9oYm_gxTbDpSpei6vOU-nXsznVzbmEKy4w-pCG_djW_dHDGp8IZAsalzfiWbZR2nH47OV90ne2zmkvb3u0zAtMrnRkuE6DzYjsLbLgZt-CZszbrww",
  "usuario": {
    "usuario_id": "16",
    "trabajador_id": "16",
    "trabajador_nombre_completo": "ALEXANDER QUISPE CHOQUE",
    "trabajador_nombres": "ALEXANDER",
    "trabajador_paterno": "QUISPE",
    "trabajador_materno": "CHOQUE",
    "trabajador_dni": "7891234",
    "empresa_id": "2",
    "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
    "empresa_codigo": "309",
    "sucursal_id": "3",
    "sucursal_nombre": "SUCURSAL ZONA SUR",
    "sucursal_codigo": "FSZ",
    "sucursal_codigo_sin": 1,
    "rol_id": "9",
    "rol_nombre": "PRUEBA",
    "rol_codigo": "PRB",
    "cargo_id": "9",
    "cargo_nombre": "MENSAJERO",
    "cargo_codigo": "MENS",
    "login": "PRUEBA",
    "avatar": "16.png",
    "estado_registro": "",
    "fecha_registro": null,
    "fecha_actualizacion": null,
    "fecha_baja": null
  },
  "menu": [
    {
      "label": "CONFIGURACIÓN Y SISTEMA",
      "icon": "pi pi-cog",
      "to": null,
      "items": [
        {
          "label": "DATOS DE LA EMPRESA",
          "icon": "pi pi-building",
          "to": "/configuracion/empresa",
          "items": []
        },
        {
          "label": "GESTIÓN DE NITS Y AUTORIZACIONES",
          "icon": "pi pi-id-card",
          "to": "/configuracion/nits",
          "items": []
        },
        {
          "label": "CUENTAS BANCARIAS",
          "icon": "pi pi-credit-card",
          "to": "/configuracion/cuentas-bancarias",
          "items": []
        },
        {
          "label": "BANCOS",
          "icon": "pi pi-building-columns",
          "to": "/configuracion/bancos",
          "items": []
        },
        {
          "label": "SUCURSALES",
          "icon": "pi pi-map-marker",
          "to": "/configuracion/sucursales",
          "items": []
        },
        {
          "label": "PUNTOS DE VENTA",
          "icon": "pi pi-desktop",
          "to": "/configuracion/puntos-venta",
          "items": []
        },
        {
          "label": "CONTROL DE USUARIOS",
          "icon": "pi pi-users",
          "to": "/configuracion/usuarios",
          "items": []
        },
        {
          "label": "ROLES Y PERMISOS",
          "icon": "pi pi-key",
          "to": "/configuracion/roles",
          "items": []
        },
        {
          "label": "ROLES - PERMISOS TABLAS",
          "icon": "pi pi-table",
          "to": "/configuracion/roles-permisos-tablas",
          "items": []
        },
        {
          "label": "ROLES - PERMISOS SUCESOS",
          "icon": "pi pi-list",
          "to": "/configuracion/roles-permisos-sucesos",
          "items": []
        },
        {
          "label": "ROLES - MENÚS",
          "icon": "pi pi-sitemap",
          "to": "/configuracion/roles-menus",
          "items": []
        },
        {
          "label": "GESTIÓN DE MENÚS",
          "icon": "pi pi-sitemap",
          "to": "/configuracion/menus",
          "items": []
        },
        {
          "label": "TABLAS DEL SISTEMA",
          "icon": "pi pi-database",
          "to": "/configuracion/tablas",
          "items": []
        },
        {
          "label": "SUCESOS DEL SISTEMA",
          "icon": "pi pi-bolt",
          "to": "/configuracion/sucesos",
          "items": []
        },
        {
          "label": "PARÁMETROS GLOBALES",
          "icon": "pi pi-sliders-h",
          "to": "/configuracion/parametros",
          "items": []
        },
        {
          "label": "TASAS DE CAMBIO",
          "icon": "pi pi-dollar",
          "to": "/configuracion/tipos-cambio",
          "items": []
        },
        {
          "label": "TAREAS PROGRAMADAS",
          "icon": "pi pi-calendar-clock",
          "to": "/configuracion/tareas",
          "items": []
        },
        {
          "label": "LOGS DE EJECUCIÓN",
          "icon": "pi pi-file-code",
          "to": "/configuracion/logs",
          "items": []
        },
        {
          "label": "GESTIÓN CUIS",
          "icon": "pi pi-key",
          "to": "/configuracion/cuis",
          "items": []
        },
        {
          "label": "GESTIÓN CUFD",
          "icon": "pi pi-key",
          "to": "/configuracion/cufd",
          "items": []
        },
        {
          "label": "CONSULTA CUIS / CUFD",
          "icon": "pi pi-key",
          "to": "/configuracion/credenciales-sin",
          "items": []
        },
        {
          "label": "INSTITUCIONES DE SALUD",
          "icon": "pi pi-building",
          "to": "/configuracion/instituciones",
          "items": []
        },
        {
          "label": "ESPECIALIDADES MÉDICAS",
          "icon": "pi pi-list",
          "to": "/configuracion/especialidades",
          "items": []
        },
        {
          "label": "MÉDICOS Y PROFESIONALES",
          "icon": "pi pi-user-md",
          "to": "/configuracion/medicos",
          "items": []
        }
      ]
    },
    {
      "label": "GESTIÓN DE PRODUCTOS",
      "icon": "pi pi-box",
      "to": null,
      "items": [
        {
          "label": "CATÁLOGO DE PRODUCTOS",
          "icon": "pi pi-shopping-bag",
          "to": "/productos/catalogo",
          "items": []
        },
        {
          "label": "CATEGORÍAS",
          "icon": "pi pi-tags",
          "to": "/productos/categorias",
          "items": []
        },
        {
          "label": "LABORATORIOS",
          "icon": "pi pi-percentage",
          "to": "/productos/laboratorios",
          "items": []
        },
        {
          "label": "PRINCIPIOS ACTIVOS",
          "icon": "pi pi-info-circle",
          "to": "/productos/principios-activos",
          "items": []
        },
        {
          "label": "FORMAS FARMACÉUTICAS",
          "icon": "pi pi-tablet",
          "to": "/productos/formas",
          "items": []
        },
        {
          "label": "PRESENTACIONES COMERCIALES",
          "icon": "pi pi-clone",
          "to": "/productos/presentaciones",
          "items": []
        },
        {
          "label": "CONCENTRACIONES",
          "icon": "pi pi-filter",
          "to": "/productos/concentraciones",
          "items": []
        },
        {
          "label": "REGISTROS SANITARIOS",
          "icon": "pi pi-file",
          "to": "/productos/registros-sanitarios",
          "items": []
        },
        {
          "label": "PRODUCTOS CONTROLADOS",
          "icon": "pi pi-exclamation-circle",
          "to": "/productos/controlados",
          "items": []
        },
        {
          "label": "VÍAS DE ADMINISTRACIÓN",
          "icon": "pi pi-sitemap",
          "to": "/productos/vias",
          "items": []
        },
        {
          "label": "RANGOS DE EDAD",
          "icon": "pi pi-users",
          "to": "/productos/rangos-edad",
          "items": []
        },
        {
          "label": "MARCAS",
          "icon": "pi pi-tag",
          "to": "/productos/marcas",
          "items": []
        },
        {
          "label": "UNIDADES DE MEDIDA",
          "icon": "pi pi-calculator",
          "to": "/productos/unidades",
          "items": []
        },
        {
          "label": "CONVERSIONES DE UNIDAD",
          "icon": "pi pi-refresh",
          "to": "/productos/conversiones",
          "items": []
        },
        {
          "label": "EQUIVALENTES",
          "icon": "pi pi-exchange",
          "to": "/productos/equivalentes",
          "items": []
        },
        {
          "label": "PROMOCIONES Y OFERTAS",
          "icon": "pi pi-percentage",
          "to": "/productos/promociones",
          "items": []
        },
        {
          "label": "PRODUCTOS - VÍAS",
          "icon": "pi pi-link",
          "to": "/productos/productos-vias",
          "items": []
        },
        {
          "label": "PRODUCTOS - PRINCIPIOS",
          "icon": "pi pi-link",
          "to": "/productos/productos-principios",
          "items": []
        },
        {
          "label": "PRODUCTOS - RANGOS EDAD",
          "icon": "pi pi-link",
          "to": "/productos/productos-rangos-edad",
          "items": []
        },
        {
          "label": "PROMOCIONES - PRODUCTOS",
          "icon": "pi pi-link",
          "to": "/productos/promociones-productos",
          "items": []
        }
      ]
    },
    {
      "label": "INVENTARIOS Y ALMACENES",
      "icon": "pi pi-home",
      "to": null,
      "items": [
        {
          "label": "ALMACENES FÍSICOS",
          "icon": "pi pi-map",
          "to": "/inventario/almacenes",
          "items": []
        },
        {
          "label": "UBICACIONES INTERNAS",
          "icon": "pi pi-compass",
          "to": "/inventario/ubicaciones",
          "items": []
        },
        {
          "label": "ALMACENES - PUNTOS VENTA",
          "icon": "pi pi-link",
          "to": "/inventario/almacenes-puntos",
          "items": []
        },
        {
          "label": "MOVIMIENTOS DE KARDEX",
          "icon": "pi pi-list",
          "to": "/inventario/kardex",
          "items": []
        },
        {
          "label": "DETALLE DE KARDEX",
          "icon": "pi pi-list",
          "to": "/inventario/kardex-detalle",
          "items": []
        },
        {
          "label": "DETALLE DE KARDEX POR PRODUCTO",
          "icon": "pi pi-list",
          "to": "/inventario/kardex-productos",
          "items": []
        },
        {
          "label": "CONTROL DE LOTES",
          "icon": "pi pi-barcode",
          "to": "/inventario/lotes",
          "items": []
        },
        {
          "label": "BAJA DE LOTES VENCIDOS",
          "icon": "pi pi-calendar-times",
          "to": "/inventario/lotes-vencidos",
          "items": []
        },
        {
          "label": "TRASPASOS INTER-SUCURSALES",
          "icon": "pi pi-arrow-h",
          "to": "/inventario/traspasos",
          "items": []
        },
        {
          "label": "DISTRIBUCIÓN EN ESTANTERÍAS",
          "icon": "pi pi-server",
          "to": "/inventario/productos-ubicaciones",
          "items": []
        },
        {
          "label": "MOVIMIENTOS DE UBICACIÓN",
          "icon": "pi pi-arrows-alt",
          "to": "/inventario/movimientos-ubicacion",
          "items": []
        },
        {
          "label": "HISTORIAL DE UBICACIONES",
          "icon": "pi pi-history",
          "to": "/inventario/ubicaciones-historial",
          "items": []
        },
        {
          "label": "INVENTARIOS FÍSICOS",
          "icon": "pi pi-clipboard",
          "to": "/inventario/inventarios-fisicos",
          "items": []
        },
        {
          "label": "DETALLE DE INVENTARIO FÍSICO",
          "icon": "pi pi-list",
          "to": "/inventario/inventarios-fisicos-detalle",
          "items": []
        }
      ]
    },
    {
      "label": "OPERACIONES DE KARDEX",
      "icon": "pi pi-list",
      "to": null,
      "items": [
        {
          "label": "REGISTRAR COMPRA",
          "icon": "pi pi-cart-plus",
          "to": "/inventario/kardex/compra",
          "items": []
        },
        {
          "label": "INGRESO POR TRASPASO",
          "icon": "pi pi-arrow-down",
          "to": "/inventario/kardex/ingreso-traspaso",
          "items": []
        },
        {
          "label": "AJUSTE POR SOBRANTE",
          "icon": "pi pi-plus",
          "to": "/inventario/kardex/ajuste-ingreso",
          "items": []
        },
        {
          "label": "INGRESO POR DONACIÓN",
          "icon": "pi pi-gift",
          "to": "/inventario/kardex/donacion",
          "items": []
        },
        {
          "label": "REGISTRAR VENTA",
          "icon": "pi pi-shopping-cart",
          "to": "/inventario/kardex/venta",
          "items": []
        },
        {
          "label": "EGRESO POR TRASPASO",
          "icon": "pi pi-arrow-up",
          "to": "/inventario/kardex/egreso-traspaso",
          "items": []
        },
        {
          "label": "AJUSTE POR FALTANTE",
          "icon": "pi pi-minus",
          "to": "/inventario/kardex/ajuste-egreso",
          "items": []
        },
        {
          "label": "DEVOLUCIÓN A PROVEEDOR",
          "icon": "pi pi-undo",
          "to": "/inventario/kardex/devolucion-proveedor",
          "items": []
        },
        {
          "label": "PROFORMA / COTIZACIÓN",
          "icon": "pi pi-file-edit",
          "to": "/inventario/kardex/proforma",
          "items": []
        },
        {
          "label": "VENTA CON RESERVA",
          "icon": "pi pi-bookmark",
          "to": "/inventario/kardex/venta-reserva",
          "items": []
        },
        {
          "label": "LIBERACIÓN DE RESERVA",
          "icon": "pi pi-bookmark-fill",
          "to": "/inventario/kardex/liberacion-reserva",
          "items": []
        },
        {
          "label": "SOLICITUD DE COMPRA",
          "icon": "pi pi-file-plus",
          "to": "/inventario/kardex/solicitud-compra",
          "items": []
        },
        {
          "label": "ANULACIÓN DE TRANSACCIÓN",
          "icon": "pi pi-ban",
          "to": "/inventario/kardex/anulacion",
          "items": []
        },
        {
          "label": "DEVOLUCIÓN DE CLIENTE",
          "icon": "pi pi-replay",
          "to": "/inventario/kardex/devolucion-cliente",
          "items": []
        },
        {
          "label": "ROBO / SUSTRACCIÓN",
          "icon": "pi pi-exclamation-triangle",
          "to": "/inventario/kardex/robo",
          "items": []
        },
        {
          "label": "PÉRDIDA POR CADUCIDAD",
          "icon": "pi pi-calendar-times",
          "to": "/inventario/kardex/caducidad",
          "items": []
        },
        {
          "label": "MERMA POR ROTURA",
          "icon": "pi pi-times-circle",
          "to": "/inventario/kardex/merma",
          "items": []
        },
        {
          "label": "CONVERSIÓN DE UNIDADES",
          "icon": "pi pi-refresh",
          "to": "/inventario/kardex/conversion",
          "items": []
        },
        {
          "label": "RETIRO DE CUARENTENA",
          "icon": "pi pi-shield",
          "to": "/inventario/kardex/cuarentena",
          "items": []
        },
        {
          "label": "SOBRANTE EN INVENTARIO FÍSICO",
          "icon": "pi pi-clipboard",
          "to": "/inventario/kardex/inventario-sobrante",
          "items": []
        },
        {
          "label": "FALTANTE EN INVENTARIO FÍSICO",
          "icon": "pi pi-clipboard",
          "to": "/inventario/kardex/inventario-faltante",
          "items": []
        }
      ]
    },
    {
      "label": "COMPRAS Y PROVEEDORES",
      "icon": "pi pi-shopping-cart",
      "to": null,
      "items": [
        {
          "label": "REGISTRO DE PROVEEDORES",
          "icon": "pi pi-truck",
          "to": "/compras/proveedores",
          "items": []
        },
        {
          "label": "PROVEEDORES - CONTACTOS",
          "icon": "pi pi-user-plus",
          "to": "/compras/proveedores-contactos",
          "items": []
        },
        {
          "label": "PROVEEDORES - RATING",
          "icon": "pi pi-star",
          "to": "/compras/proveedores-rating",
          "items": []
        },
        {
          "label": "ÓRDENES Y RECEPCIONES",
          "icon": "pi pi-plus-circle",
          "to": "/compras/ordenes",
          "items": []
        },
        {
          "label": "TIPOS DE PLANES DE PAGO",
          "icon": "pi pi-calendar-plus",
          "to": "/compras/tipos-planes-pago",
          "items": []
        },
        {
          "label": "PLANES DE PAGO Y CRÉDITOS",
          "icon": "pi pi-calendar",
          "to": "/compras/planes-pago",
          "items": []
        },
        {
          "label": "PAGOS A PROVEEDORES",
          "icon": "pi pi-money-bill",
          "to": "/compras/pagos-proveedores",
          "items": []
        },
        {
          "label": "COMPROBANTES DE PAGO",
          "icon": "pi pi-receipt",
          "to": "/compras/comprobantes-pago",
          "items": []
        }
      ]
    },
    {
      "label": "VENTAS Y FACTURACIÓN",
      "icon": "pi pi-wallet",
      "to": null,
      "items": [
        {
          "label": "PUNTO DE VENTA (POS)",
          "icon": "pi pi-desktop",
          "to": "/ventas/pos",
          "items": []
        },
        {
          "label": "REGISTRO DE CLIENTES",
          "icon": "pi pi-user-plus",
          "to": "/ventas/clientes",
          "items": []
        },
        {
          "label": "DOSIFICACIÓN Y FACTURAS (SIN)",
          "icon": "pi pi-file-excel",
          "to": "/ventas/control-facturas",
          "items": []
        },
        {
          "label": "ANULACIÓN DE FACTURAS",
          "icon": "pi pi-ban",
          "to": "/ventas/anulacion-facturas",
          "items": []
        },
        {
          "label": "NOTAS DE CRÉDITO / DÉBITO",
          "icon": "pi pi-file-edit",
          "to": "/ventas/notas-credito-debito",
          "items": []
        },
        {
          "label": "REIMPRESIÓN DE COMPROBANTES",
          "icon": "pi pi-print",
          "to": "/ventas/reimpresion",
          "items": []
        },
        {
          "label": "HISTÓRICO DE DOCUMENTOS",
          "icon": "pi pi-folder-open",
          "to": "/ventas/documentos-historicos",
          "items": []
        },
        {
          "label": "DOCUMENTOS HISTÓRICOS INMUTABLES",
          "icon": "pi pi-database",
          "to": "/ventas/historicos",
          "items": []
        },
        {
          "label": "COMPROBANTES DIGITALES / QR",
          "icon": "pi pi-qrcode",
          "to": "/ventas/comprobantes",
          "items": []
        },
        {
          "label": "RECETAS MÉDICAS",
          "icon": "pi pi-file-edit",
          "to": "/ventas/recetas",
          "items": []
        },
        {
          "label": "COBRANZA Y PAGOS DE CLIENTES",
          "icon": "pi pi-money-bill",
          "to": "/ventas/cobranza",
          "items": []
        },
        {
          "label": "PLANES DE PAGO DE CLIENTES",
          "icon": "pi pi-calendar",
          "to": "/ventas/planes-pago-clientes",
          "items": []
        }
      ]
    },
    {
      "label": "GESTIÓN DE CAJA",
      "icon": "pi pi-percentage",
      "to": null,
      "items": [
        {
          "label": "APERTURA DE CAJA",
          "icon": "pi pi-lock-open",
          "to": "/caja/apertura",
          "items": []
        },
        {
          "label": "CIERRE DE CAJA",
          "icon": "pi pi-lock",
          "to": "/caja/cierre",
          "items": []
        },
        {
          "label": "MOVIMIENTOS DE CAJA (VARIOS)",
          "icon": "pi pi-sort",
          "to": "/caja/movimientos",
          "items": []
        },
        {
          "label": "ARQUEOS DE CAJA",
          "icon": "pi pi-calculator",
          "to": "/caja/arqueos",
          "items": []
        },
        {
          "label": "ARQUEO PARCIAL",
          "icon": "pi pi-calculator",
          "to": "/caja/arqueo-parcial",
          "items": []
        },
        {
          "label": "DETALLE DE ARQUEO",
          "icon": "pi pi-list",
          "to": "/caja/arqueos-detalle",
          "items": []
        }
      ]
    },
    {
      "label": "COMERCIO ELECTRÓNICO Y DELIVERY",
      "icon": "pi pi-globe",
      "to": null,
      "items": [
        {
          "label": "PEDIDOS ONLINE",
          "icon": "pi pi-shopping-bag",
          "to": "/ecommerce/pedidos",
          "items": []
        },
        {
          "label": "CARRITOS DE COMPRA",
          "icon": "pi pi-shopping-cart",
          "to": "/ecommerce/carritos",
          "items": []
        }
      ]
    },
    {
      "label": "PRECIOS, COSTOS Y MÁRGENES",
      "icon": "pi pi-tags",
      "to": null,
      "items": [
        {
          "label": "LISTAS DE PRECIOS",
          "icon": "pi pi-list",
          "to": "/precios/listas",
          "items": []
        },
        {
          "label": "PRECIOS DE PRODUCTOS",
          "icon": "pi pi-dollar",
          "to": "/precios/productos",
          "items": []
        },
        {
          "label": "COSTOS PROMEDIO",
          "icon": "pi pi-chart-line",
          "to": "/precios/costos",
          "items": []
        },
        {
          "label": "POLÍTICAS DE PRECIOS",
          "icon": "pi pi-sliders-h",
          "to": "/precios/politicas",
          "items": []
        }
      ]
    },
    {
      "label": "RECURSOS HUMANOS",
      "icon": "pi pi-id-card",
      "to": null,
      "items": [
        {
          "label": "GESTIÓN DE TRABAJADORES",
          "icon": "pi pi-users",
          "to": "/rrhh/trabajadores",
          "items": []
        },
        {
          "label": "CARGOS",
          "icon": "pi pi-briefcase",
          "to": "/rrhh/cargos",
          "items": []
        },
        {
          "label": "TRABAJADORES - CARGOS",
          "icon": "pi pi-user-plus",
          "to": "/rrhh/trabajadores-cargos",
          "items": []
        },
        {
          "label": "CONTROL DE ASISTENCIAS",
          "icon": "pi pi-clock",
          "to": "/rrhh/asistencias",
          "items": []
        },
        {
          "label": "CONTRATOS DE PERSONAL",
          "icon": "pi pi-briefcase",
          "to": "/rrhh/contratos",
          "items": []
        },
        {
          "label": "PLANILLAS DE SUELDOS",
          "icon": "pi pi-file-pdf",
          "to": "/rrhh/planillas",
          "items": []
        },
        {
          "label": "DETALLES DE PLANILLAS",
          "icon": "pi pi-file",
          "to": "/rrhh/detalles-planillas",
          "items": []
        }
      ]
    },
    {
      "label": "NÚCLEO ANALÍTICO Y PREDICCIONES",
      "icon": "pi pi-android",
      "to": null,
      "items": [
        {
          "label": "DASHBOARD DE ANALÍTICA CONSOLIDADA",
          "icon": "pi pi-chart-bar",
          "to": "/ia/analitica",
          "items": []
        },
        {
          "label": "ANALÍTICA POR PRODUCTO",
          "icon": "pi pi-chart-pie",
          "to": "/ia/analitica-productos",
          "items": []
        },
        {
          "label": "MODELOS ML DISPONIBLES",
          "icon": "pi pi-share-alt",
          "to": "/ia/modelos",
          "items": []
        },
        {
          "label": "HISTORIAL DE ENTRENAMIENTOS",
          "icon": "pi pi-sync",
          "to": "/ia/entrenamientos",
          "items": []
        },
        {
          "label": "MÉTRICAS DE RENDIMIENTO",
          "icon": "pi pi-chart-line",
          "to": "/ia/metricas",
          "items": []
        },
        {
          "label": "VARIABLES EXÓGENAS AMBIENTALES",
          "icon": "pi pi-cloud",
          "to": "/ia/variables-exogenas",
          "items": []
        },
        {
          "label": "PATRONES DE CONSUMO ESTACIONAL",
          "icon": "pi pi-sliders-v",
          "to": "/ia/patrones-consumo",
          "items": []
        },
        {
          "label": "CONFIGURACIÓN DE UMBRALES PREDICTIVOS",
          "icon": "pi pi-cog",
          "to": "/ia/umbrales",
          "items": []
        }
      ]
    },
    {
      "label": "NOTIFICACIONES Y ALERTAS",
      "icon": "pi pi-bell",
      "to": null,
      "items": [
        {
          "label": "BANDEJA DE NOTIFICACIONES",
          "icon": "pi pi-inbox",
          "to": "/alertas/notificaciones",
          "items": []
        },
        {
          "label": "ALERTAS OPERATIVAS Y CRÍTICAS",
          "icon": "pi pi-exclamation-triangle",
          "to": "/alertas/criticas",
          "items": []
        }
      ]
    },
    {
      "label": "REPORTES Y DIRECCIÓN GERENCIAL",
      "icon": "pi pi-print",
      "to": null,
      "items": [
        {
          "label": "CONSOLIDADOR DE REPORTES",
          "icon": "pi pi-copy",
          "to": "/reportes/dashboard-unico",
          "items": []
        },
        {
          "label": "REPORTES DE INVENTARIO Y STOCK",
          "icon": "pi pi-chart-scatter",
          "to": "/reportes/inventario",
          "items": []
        },
        {
          "label": "KARDEX VALORIZADO",
          "icon": "pi pi-chart-line",
          "to": "/reportes/kardex-valorizado",
          "items": []
        },
        {
          "label": "VENTAS POR PRODUCTO",
          "icon": "pi pi-chart-bar",
          "to": "/reportes/ventas-producto",
          "items": []
        },
        {
          "label": "ROTACIÓN DE INVENTARIO",
          "icon": "pi pi-refresh",
          "to": "/reportes/rotacion-inventario",
          "items": []
        },
        {
          "label": "MARGEN POR PRODUCTO",
          "icon": "pi pi-percentage",
          "to": "/reportes/margen-producto",
          "items": []
        },
        {
          "label": "VENCIMIENTOS PRÓXIMOS",
          "icon": "pi pi-calendar-clock",
          "to": "/reportes/vencimientos",
          "items": []
        },
        {
          "label": "CLIENTES FRECUENTES (RFM)",
          "icon": "pi pi-users",
          "to": "/reportes/clientes-rfm",
          "items": []
        },
        {
          "label": "HISTORIAL DE COSTOS Y MÁRGENES",
          "icon": "pi pi-chart-line",
          "to": "/gerencia/historial-costos",
          "items": []
        }
      ]
    }
  ],
  "permisos": {
    "alertas_notificaciones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "almacenes": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "almacenes_puntos_venta": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "analitica_productos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "arqueos_detalle": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "asistencias": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "bancos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "cajas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "cargos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "carritos_compra": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "categorias": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "clientes": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "comprobantes_pagos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "concentraciones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "contratos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "control_facturas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "conversiones_unidad": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "costos_promedio": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "cufd": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "cuis": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "detalles_carritos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "detalles_pedidos_online": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "empresas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "empresas_cuentas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "empresas_nits": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "entrenamientos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "equivalentes": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "especialidades": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "formas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "historicos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "instituciones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "inventarios_fisicos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "inventarios_fisicos_detalle": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "kardex": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "kardex_productos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "laboratorios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "listas_precios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "logs_ejecucion": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "lotes_productos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "marcas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "medicos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "menus": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "metricas_rendimiento": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "modelos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "movimientos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "ordenes_compra": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "pagos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "parametros_globales": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "patrones_consumo": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "pedidos_online": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "planes_pagos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "planillas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "planillas_detalle": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "politicas_precios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "precios_productos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "presentaciones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "principios_activos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "productos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "productos_controlados": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "productos_principios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "productos_rangos_edad": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "productos_ubicaciones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "productos_vias": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "promociones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "promociones_productos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "proveedores": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "proveedores_contactos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "proveedores_rating_historico": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "puntos_venta": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "rangos_edad": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "recetas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "registros_sanitarios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "roles": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "roles_menus": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "roles_tablas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "sucursales": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "tablas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "tareas_programadas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "tipos_cambios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "tipos_planes_pago": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "trabajadores": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "trabajadores_cargos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "ubicaciones": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "ubicaciones_historial": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "ubicaciones_movimientos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "umbrales_configuracion": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "unidades": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "usuarios": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "variables_exogenas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "vias": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "constantes": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "roles_permisos_sucesos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "roles_permisos_tablas": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    },
    "sucesos": {
      "crear": true,
      "editar": true,
      "eliminar": true,
      "leer": true,
      "anular": true,
      "archivar": true,
      "desarchivar": true
    }
  }
}

###
GET {{baseUrl_empresas}}/3
Authorization: Bearer {{authToken}}
SALE 
{
  "empresa_id": "3",
  "empresa": "SEGIND GUARDIAN",
  "codigo": "310",
  "logo": "http://localhost:3010/api/logos/1789093918303-0eb4fc.jpg",
  "eslogan": "HOLA MUNDO",
  "descripcion": "HOLA MUNDO",
  "lugar": "LA PAZ - BOLIVIA",
  "representante": "JUAN CARLOS GOMEZ",
  "direccion": "CALLE LOS ALAMOS #206",
  "telefono": "2252147",
  "email": "franz@gmail.com",
  "matricula_comercio": "4524",
  "estado_id": 1000,
  "estado_registro": "ACTIVO",
  "usuario_operacion": "ADMIN",
  "usuario_id_registro": "2",
  "usuario_id_actualizacion": null,
  "usuario_id_baja": null,
  "fecha_registro": "2026-09-10 22:31:58.360 -04:00",
  "fecha_actualizacion": null,
  "fecha_baja": null,
  "tiene_dependencias": true,
  "campos_protegidos": [
    "empresa",
    "codigo",
    "matricula_comercio"
  ]
}


### ACTUALIZAR TODOS LOS CAMPOS
PATCH {{baseUrl_empresas}}/3
Authorization: Bearer {{authToken}}
Content-Type: application/json

{
    "empresa": "FARMACIA SALUD Y VIDA S.A. BBB",
    "codigo": "3215",
    "eslogan": "SALUD PARA TODOS BUENOS HOLA HOLA",
    "descripcion": "Cadena de farmacias la mejor",
    "lugar": "SANTA CRUZ DE LA SIERRA - BOLIVIA",
    "representante": "JUAN PEREZ GARCIA OROPEZA",
    "direccion": "AV. ARCE NRO. 2105, SOPOCACHI, CALLE BENI",
    "telefono": "22441122",
    "email": "info@saludyvida.com.bo",
    "matricula_comercio": "M-35699241"
}

SALE 
{
  "empresa_id": "3",
  "empresa": "SEGIND GUARDIAN",
  "codigo": "310",
  "logo": "http://localhost:3010/api/logos/1789093918303-0eb4fc.jpg",
  "eslogan": "SALUD PARA TODOS BUENOS HOLA HOLA",
  "descripcion": "Cadena de farmacias la mejor",
  "lugar": "SANTA CRUZ DE LA SIERRA - BOLIVIA",
  "representante": "JUAN PEREZ GARCIA OROPEZA",
  "direccion": "AV. ARCE NRO. 2105, SOPOCACHI, CALLE BENI",
  "telefono": "22441122",
  "email": "info@saludyvida.com.bo",
  "matricula_comercio": "4524",
  "estado_id": 1000,
  "estado_registro": "ACTIVO",
  "usuario_operacion": "PRUEBA",
  "usuario_id_registro": "2",
  "usuario_id_actualizacion": "16",
  "usuario_id_baja": null,
  "fecha_registro": "2026-09-10 22:31:58.360 -04:00",
  "fecha_actualizacion": "2026-09-13 23:20:48.397 -04:00",
  "fecha_baja": null,
  "tiene_dependencias": true,
  "campos_protegidos": [
    "empresa",
    "codigo",
    "matricula_comercio"
  ]
}
