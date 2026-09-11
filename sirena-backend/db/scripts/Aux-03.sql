@baseUrl = http://localhost:3010/api
@baseUrl_empresas_nits = {{baseUrl}}/empresas-nits
@baseUrl_empresas = {{baseUrl}}/empresas

### LISTAR POR ESTADO ACTIVOS (1000)
GET {{baseUrl_empresas}}?estado_id=1000
Authorization: Bearer {{authToken}}

{
  "data": [
    {
      "empresa_id": "6",
      "empresa": "EE SDS DSFSD",
      "codigo": "5415",
      "logo": "http://localhost:3010/api/logos/1789128990275-4eebc0.png",
      "eslogan": "DKK JFSKDF SJSDJDSJFSKFKL",
      "descripcion": null,
      "lugar": null,
      "representante": "S SDFMSD KF SDFJSDJ",
      "direccion": "ASDASDASDAS",
      "telefono": "22554125",
      "email": "franz@mail.com",
      "matricula_comercio": "SDSNF SDFS",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-11 08:16:30.343 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_id": "5",
      "empresa": "SFSDFSFDS",
      "codigo": "5412",
      "logo": "http://localhost:3010/api/logos/1789096998998-0da298.png",
      "eslogan": "A DASDAS",
      "descripcion": null,
      "lugar": null,
      "representante": "AS ADASD",
      "direccion": null,
      "telefono": null,
      "email": null,
      "matricula_comercio": "451",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 23:23:19.049 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_id": "4",
      "empresa": "NUEVA EMPRESA",
      "codigo": "305",
      "logo": "http://localhost:3010/api/logos/1789096824448-1b2495.png",
      "eslogan": "HOLA MUNDO",
      "descripcion": "asnd asdasdas",
      "lugar": "LA PAZ - BOLIVIA",
      "representante": "JUAN GOMEZ",
      "direccion": "CALLE LOS ALAMOS #206",
      "telefono": "2252147",
      "email": "franz@gmail.com",
      "matricula_comercio": "745512",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": "2",
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 23:20:24.509 -04:00",
      "fecha_actualizacion": "2026-09-10 23:21:25.996 -04:00",
      "fecha_baja": null
    },
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
      "fecha_baja": null
    },
    {
      "empresa_id": "2",
      "empresa": "FARMACIA SALUD Y VIDA S.R.L.",
      "codigo": "309",
      "logo": "",
      "eslogan": "Tu salud es nuestra prioridad",
      "descripcion": "Venta de medicamentos",
      "lugar": "LA PAZ - BOLIVIA",
      "representante": "JUAN PEREZ FLORES",
      "direccion": "AV. ARCE NRO. 2105, SOPOCACHI, LA PAZ",
      "telefono": "22441122",
      "email": "central@saludyvida.com.bo",
      "matricula_comercio": "M-356981",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.396 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    }
  ],
  "total": 5,
  "limit": 10,
  "offset": 0
}

### LISTAR TODOS (Activos + Históricos por defecto)
GET {{baseUrl_empresas_nits}}?empresa_id=2
Authorization: Bearer {{authToken}}
SALE 
{
  "data": [
    {
      "empresa_nit_id": "7",
      "empresa_id": "2",
      "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
      "empresa_codigo": "309",
      "ambiente_id": 2750,
      "ambiente": {
        "abreviatura": "PRODUCCION",
        "valor": 1,
        "prefijo": ""
      },
      "nit": "321654988",
      "razon_social": "FARMACIA SALUD Y VIDA S.R.L.",
      "actividad_economica_principal": "VENTA DE LIBROS",
      "etiqueta": "LIBROS",
      "modalidad_facturacion_id": 3901,
      "modalidad_facturacion": {
        "abreviatura": "ELECTRONICA",
        "valor": 1,
        "prefijo": "EL"
      },
      "certificado_digital": null,
      "certificado_password": null,
      "token_siat": null,
      "fecha_inicio_vigencia": "2026-01-01",
      "fecha_fin_vigencia": "2027-12-31",
      "email_fiscal": "libros@saludyvida.com.bo",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.411 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_nit_id": "6",
      "empresa_id": "2",
      "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
      "empresa_codigo": "309",
      "ambiente_id": 2751,
      "ambiente": {
        "abreviatura": "PILOTO_PRUEBAS",
        "valor": 2,
        "prefijo": ""
      },
      "nit": "321654987",
      "razon_social": "FARMACIA SALUD Y VIDA S.R.L.",
      "actividad_economica_principal": "VENTA DE MATERIAL DE ESCRITORIO Y SUMINISTROS DE OFICINA",
      "etiqueta": "ESCRITORIO",
      "modalidad_facturacion_id": 3900,
      "modalidad_facturacion": {
        "abreviatura": "NINGUNO",
        "valor": 0,
        "prefijo": "NIN"
      },
      "certificado_digital": null,
      "certificado_password": null,
      "token_siat": null,
      "fecha_inicio_vigencia": "2026-01-01",
      "fecha_fin_vigencia": "2027-12-31",
      "email_fiscal": "escritorio@saludyvida.com.bo",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.411 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_nit_id": "5",
      "empresa_id": "2",
      "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
      "empresa_codigo": "309",
      "ambiente_id": 2750,
      "ambiente": {
        "abreviatura": "PRODUCCION",
        "valor": 1,
        "prefijo": ""
      },
      "nit": "789123456",
      "razon_social": "FARMACIA SALUD Y VIDA S.R.L.",
      "actividad_economica_principal": "VENTA DE EQUIPOS ELECTRONICOS Y DISPOSITIVOS",
      "etiqueta": "ELECTRONICA",
      "modalidad_facturacion_id": 3902,
      "modalidad_facturacion": {
        "abreviatura": "COMPUTARIZADA",
        "valor": 2,
        "prefijo": "CL"
      },
      "certificado_digital": null,
      "certificado_password": null,
      "token_siat": null,
      "fecha_inicio_vigencia": "2026-01-01",
      "fecha_fin_vigencia": "2027-12-31",
      "email_fiscal": "electronicos@saludyvida.com.bo",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.411 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_nit_id": "4",
      "empresa_id": "2",
      "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
      "empresa_codigo": "309",
      "ambiente_id": 2750,
      "ambiente": {
        "abreviatura": "PRODUCCION",
        "valor": 1,
        "prefijo": ""
      },
      "nit": "456789123",
      "razon_social": "FARMACIA SALUD Y VIDA S.R.L.",
      "actividad_economica_principal": "SERVICIOS MEDICOS Y CONSULTAS",
      "etiqueta": "MEDICOS",
      "modalidad_facturacion_id": 3901,
      "modalidad_facturacion": {
        "abreviatura": "ELECTRONICA",
        "valor": 1,
        "prefijo": "EL"
      },
      "certificado_digital": null,
      "certificado_password": null,
      "token_siat": null,
      "fecha_inicio_vigencia": "2026-01-01",
      "fecha_fin_vigencia": "2027-12-31",
      "email_fiscal": "servicios@saludyvida.com.bo",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.411 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_nit_id": "3",
      "empresa_id": "2",
      "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
      "empresa_codigo": "309",
      "ambiente_id": 2750,
      "ambiente": {
        "abreviatura": "PRODUCCION",
        "valor": 1,
        "prefijo": ""
      },
      "nit": "987654321",
      "razon_social": "FARMACIA SALUD Y VIDA S.R.L.",
      "actividad_economica_principal": "VENTA DE JUGUETES Y ARTICULOS RECREATIVOS",
      "etiqueta": "JUGUETES",
      "modalidad_facturacion_id": 3901,
      "modalidad_facturacion": {
        "abreviatura": "ELECTRONICA",
        "valor": 1,
        "prefijo": "EL"
      },
      "certificado_digital": null,
      "certificado_password": null,
      "token_siat": null,
      "fecha_inicio_vigencia": "2026-01-01",
      "fecha_fin_vigencia": "2027-12-31",
      "email_fiscal": "juguetes@saludyvida.com.bo",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.411 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    },
    {
      "empresa_nit_id": "2",
      "empresa_id": "2",
      "empresa_nombre": "FARMACIA SALUD Y VIDA S.R.L.",
      "empresa_codigo": "309",
      "ambiente_id": 2750,
      "ambiente": {
        "abreviatura": "PRODUCCION",
        "valor": 1,
        "prefijo": ""
      },
      "nit": "123456789",
      "razon_social": "FARMACIA SALUD Y VIDA S.R.L.",
      "actividad_economica_principal": "VENTA DE MEDICAMENTOS EN GENERAL",
      "etiqueta": "MEDICAMENTOS",
      "modalidad_facturacion_id": 3901,
      "modalidad_facturacion": {
        "abreviatura": "ELECTRONICA",
        "valor": 1,
        "prefijo": "EL"
      },
      "certificado_digital": null,
      "certificado_password": null,
      "token_siat": null,
      "fecha_inicio_vigencia": "2026-01-01",
      "fecha_fin_vigencia": "2027-12-31",
      "email_fiscal": "ventas@saludyvida.com.bo",
      "estado_id": 1000,
      "estado_registro": "ACTIVO",
      "usuario_operacion": "ADMIN",
      "usuario_id_registro": "2",
      "usuario_id_actualizacion": null,
      "usuario_id_baja": null,
      "fecha_registro": "2026-09-10 00:18:45.411 -04:00",
      "fecha_actualizacion": null,
      "fecha_baja": null
    }
  ],
  "total": 6,
  "limit": 10,
  "offset": 0
}

para las constantes usar 
// C:\sirena\sirena-frontend\app\constants\estados.constant.ts

export interface ConstanteMetadata {
    id: number;
    abreviatura: string;
    prefijo: string | null;
    valor: number;
    descripcion: string;
}

// ==========================================
// ESTADO
export enum Estado {
    ACTIVO = 1000,
    BORRADO = 1001,
    HISTORICO = 1002,
    ANULADO = 1003,
}

export const ESTADO_ACTIVO = Estado.ACTIVO;
export const ESTADO_HISTORICO = Estado.HISTORICO;
export const ESTADO_BORRADO = Estado.BORRADO;
export const ESTADO_ANULADO = Estado.ANULADO;

export const ESTADOS_CONSULTA = [
    Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_PERMITIDOS = [
    Estado.ACTIVO,
    Estado.BORRADO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_VIVOS = [
    Estado.ACTIVO,
    Estado.HISTORICO
] as const;

export const ESTADOS_VIVOS_ESPECIAL = [
    Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO
] as const;

export const ESTADO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Estado.ACTIVO]: { id: Estado.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Estado.BORRADO]: { id: Estado.BORRADO, abreviatura: 'BORRADO', prefijo: null, valor: 0, descripcion: 'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.' },
    [Estado.HISTORICO]: { id: Estado.HISTORICO, abreviatura: 'HISTORICO', prefijo: null, valor: 0, descripcion: 'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.' },
    [Estado.ANULADO]: { id: Estado.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.' },
};

// ==========================================
// EVENTO
export enum Evento {
    COMPRA = 1050,
    VENTA = 1051,
    PROFORMA = 1052,
    EGRESO_TRASPASO = 1053,
    INGRESO_TRASPASO = 1054,
    ANULACION = 1055,
    AJUSTE_INGRESO = 1056,
    AJUSTE_EGRESO = 1057,
    SOLICITUD_COMPRA = 1058,
    VENTA_RESERVA = 1059,
    DEVOLUCION_CLIENTE = 1060,
    DEVOLUCION_PROVEEDOR = 1061,
    ROBO = 1062,
    PERDIDA_CADUCIDAD = 1063,
    MERMA_ROTURA = 1064,
    INVENTARIO_FISICO_SOBRANTE = 1065,
    INVENTARIO_FISICO_FALTANTE = 1066,
    CONVERSION_UNIDADES = 1067,
    RETIRO_CUARENTENA = 1068,
    INGRESO_DONACION = 1069,
    LIBERACION_RESERVA = 1070,
}

export const EVENTO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Evento.COMPRA]: { id: Evento.COMPRA, abreviatura: 'COMPRA', prefijo: 'LOT', valor: 0, descripcion: 'Registro de ingreso de mercadería por compra a proveedor. Afecta positivamente el stock y genera cuentas por pagar. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Evento.VENTA]: { id: Evento.VENTA, abreviatura: 'VENTA', prefijo: 'VEN', valor: 0, descripcion: 'Registro de salida de mercadería por venta a cliente. Afecta negativamente el stock, genera facturación y movimiento de caja.' },
    [Evento.PROFORMA]: { id: Evento.PROFORMA, abreviatura: 'PROFORMA', prefijo: 'PRO', valor: 0, descripcion: 'Cotización o presupuesto temporal que NO afecta stock ni finanzas. Solo documento informativo o estimación de precios.' },
    [Evento.EGRESO_TRASPASO]: { id: Evento.EGRESO_TRASPASO, abreviatura: 'EGRESO_TRASPASO', prefijo: 'EGR', valor: 0, descripcion: 'Egreso de mercadería desde sucursal origen hacia destino. Disminuye stock en origen hasta confirmación en destino.' },
    [Evento.INGRESO_TRASPASO]: { id: Evento.INGRESO_TRASPASO, abreviatura: 'INGRESO_TRASPASO', prefijo: 'ING', valor: 0, descripcion: 'Ingreso de mercadería a sucursal destino procedente de origen. Aumenta stock en destino al confirmar recepción.' },
    [Evento.ANULACION]: { id: Evento.ANULACION, abreviatura: 'ANULACION', prefijo: 'ANU', valor: 0, descripcion: 'Cancelación de una transacción previa (compra o venta). Revierte automáticamente el stock afectado y deja registro inmutable para auditoría.' },
    [Evento.AJUSTE_INGRESO]: { id: Evento.AJUSTE_INGRESO, abreviatura: 'AJUSTE_INGRESO', prefijo: 'AJI', valor: 0, descripcion: 'Incremento de stock por sobrante detectado en inventario físico. No genera transacción comercial.' },
    [Evento.AJUSTE_EGRESO]: { id: Evento.AJUSTE_EGRESO, abreviatura: 'AJUSTE_EGRESO', prefijo: 'AJE', valor: 0, descripcion: 'Decremento de stock por faltante detectado en inventario físico. No genera transacción comercial.' },
    [Evento.SOLICITUD_COMPRA]: { id: Evento.SOLICITUD_COMPRA, abreviatura: 'SOLICITUD_COMPRA', prefijo: 'SOL', valor: 0, descripcion: 'Pedido administrativo pendiente de aprobación. No afecta stock ni finanzas hasta su conversión a COMPRA (1050).' },
    [Evento.VENTA_RESERVA]: { id: Evento.VENTA_RESERVA, abreviatura: 'VENTA_RESERVA', prefijo: 'VRE', valor: 0, descripcion: 'Proforma con reserva temporal de stock por tiempo limitado. Afecta negativamente el stock (lo aparta) y puede convertirse en VENTA (1051). Requiere validez_dias para definir plazo de reserva.' },
    [Evento.DEVOLUCION_CLIENTE]: { id: Evento.DEVOLUCION_CLIENTE, abreviatura: 'DEVOLUCION_CLIENTE', prefijo: 'DCLI', valor: 0, descripcion: 'Devolución de mercadería por parte del cliente. Afecta positivamente el stock y requiere nota de crédito/débito fiscal si aplica.' },
    [Evento.DEVOLUCION_PROVEEDOR]: { id: Evento.DEVOLUCION_PROVEEDOR, abreviatura: 'DEVOLUCION_PROVEEDOR', prefijo: 'DPRO', valor: 0, descripcion: 'Devolución de mercadería defectuosa o próxima a vencer al proveedor. Disminuye el stock y ajusta cuentas por pagar.' },
    [Evento.ROBO]: { id: Evento.ROBO, abreviatura: 'ROBO', prefijo: 'ROB', valor: 0, descripcion: 'Salida extraordinaria de inventario por sustracción o robo detectado. Disminuye el stock sin contrapartida comercial y genera alerta de auditoría.' },
    [Evento.PERDIDA_CADUCIDAD]: { id: Evento.PERDIDA_CADUCIDAD, abreviatura: 'PERDIDA_CADUCIDAD', prefijo: 'PCAD', valor: 0, descripcion: 'Baja de stock por productos vencidos o caducados detectados en control de almacén. Afecta como pérdida operativa.' },
    [Evento.MERMA_ROTURA]: { id: Evento.MERMA_ROTURA, abreviatura: 'MERMA_ROTURA', prefijo: 'MER', valor: 0, descripcion: 'Salida de stock por daño físico, rotura o deterioro de medicamentos. No genera transacción comercial.' },
    [Evento.INVENTARIO_FISICO_SOBRANTE]: { id: Evento.INVENTARIO_FISICO_SOBRANTE, abreviatura: 'INVENTARIO_FISICO_SOBRANTE', prefijo: 'IFSO', valor: 0, descripcion: 'Ajuste positivo por conteo físico de inventario (diferencia a favor respecto al sistema).' },
    [Evento.INVENTARIO_FISICO_FALTANTE]: { id: Evento.INVENTARIO_FISICO_FALTANTE, abreviatura: 'INVENTARIO_FISICO_FALTANTE', prefijo: 'IFFAL', valor: 0, descripcion: 'Ajuste negativo por conteo físico de inventario (diferencia en contra o merma no identificada).' },
    [Evento.CONVERSION_UNIDADES]: { id: Evento.CONVERSION_UNIDADES, abreviatura: 'CONVERSION_UNIDADES', prefijo: 'CENV', valor: 0, descripcion: 'Salida de productos en empaque mayor (cajas/blísteres) y reingreso automático como unidades sueltas por fraccionamiento.' },
    [Evento.RETIRO_CUARENTENA]: { id: Evento.RETIRO_CUARENTENA, abreviatura: 'RETIRO_CUARENTENA', prefijo: 'RCUA', valor: 0, descripcion: 'Salida temporal o definitiva de stock retenido por alerta sanitaria o control de calidad. Bloquea o saca la mercadería de la disponibilidad comercial.' },
    [Evento.INGRESO_DONACION]: { id: Evento.INGRESO_DONACION, abreviatura: 'INGRESO_DONACION', prefijo: 'DON', valor: 0, descripcion: 'Ingreso de mercadería por donación o recepción sin costo. Afecta positivamente el stock sin generar obligación de pago.' },
    [Evento.LIBERACION_RESERVA]: { id: Evento.LIBERACION_RESERVA, abreviatura: 'LIBERACION_RESERVA', prefijo: 'LRES', valor: 0, descripcion: 'Liberación de stock retenido por expiración de tiempo o anulación de reserva. Reintegra el stock disponible.' },
};

// ==========================================
// TIPO COMPROBANTE
export enum TipoComprobante {
    FACTURA = 1100,
    RECIBO = 1101,
    OTRO = 1102,
    NINGUNO = 1103,
}

export const TIPO_COMPROBANTE_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoComprobante.FACTURA]: { id: TipoComprobante.FACTURA, abreviatura: 'FACTURA', prefijo: null, valor: 0, descripcion: 'Documento fiscal oficial emitido por el SIN. Genera obligación tributaria y derecho a crédito fiscal. Utilizado en ventas formales que requieren comprobante fiscal.', es_defecto: true },
    [TipoComprobante.RECIBO]: { id: TipoComprobante.RECIBO, abreviatura: 'RECIBO', prefijo: null, valor: 0, descripcion: 'Documento interno de pago sin valor fiscal. Utilizado para comprobantes de pago, abonos parciales o registro de ingresos/egresos operativos.' },
    [TipoComprobante.OTRO]: { id: TipoComprobante.OTRO, abreviatura: 'OTRO', prefijo: null, valor: 0, descripcion: 'Comprobante no clasificado en las categorías anteriores. Utilizado para documentos especiales o casos excepcionales.' },
    [TipoComprobante.NINGUNO]: { id: TipoComprobante.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin comprobante fiscal definido. CONSTANTE POR DEFECTO.' },
};

// ==========================================
// TIPO CLIENTE
export enum TipoCliente {
    NATURAL = 1150,
    JURIDICA = 1151,
}

export const TIPO_CLIENTE_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoCliente.NATURAL]: { id: TipoCliente.NATURAL, abreviatura: 'NATURAL', prefijo: null, valor: 0, descripcion: 'Persona física individual. Requiere documento de identidad (CI, CEX, Pasaporte) para facturación. Puede tener límite de crédito personal. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoCliente.JURIDICA]: { id: TipoCliente.JURIDICA, abreviatura: 'JURIDICA', prefijo: null, valor: 0, descripcion: 'Persona jurídica, empresa o institución. Requiere NIT y razón social obligatoria para facturación. Puede tener límite de crédito corporativo y condiciones especiales de pago.' },
};

// ==========================================
// GENERO
export enum Genero {
    MASCULINO = 1200,
    FEMENINO = 1201,
}

export const GENERO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Genero.MASCULINO]: { id: Genero.MASCULINO, abreviatura: 'MASCULINO', prefijo: null, valor: 0, descripcion: 'Género masculino. Utilizado en trabajadores y clientes. Determina el conjunto de estados civiles disponibles (1250-1254). CONSTANTE POR DEFECTO.', es_defecto: true },
    [Genero.FEMENINO]: { id: Genero.FEMENINO, abreviatura: 'FEMENINO', prefijo: null, valor: 0, descripcion: 'Género femenino. Utilizado en trabajadores y clientes. Determina el conjunto de estados civiles disponibles (1300-1304).' },
};

// ==========================================
// ESTADO CIVIL MASCULINO
export enum EstadoCivilMasculino {
    SOLTERO = 1250,
    CASADO = 1251,
    DIVORCIADO = 1252,
    VIUDO = 1253,
    UNION_LIBRE = 1254,
}

export const ESTADO_CIVIL_MASCULINO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoCivilMasculino.SOLTERO]: { id: EstadoCivilMasculino.SOLTERO, abreviatura: 'SOLTERO', prefijo: null, valor: 0, descripcion: 'Estado civil soltero para género masculino. Aplica a trabajadores y clientes de sexo masculino que no tienen vínculo conyugal legal. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoCivilMasculino.CASADO]: { id: EstadoCivilMasculino.CASADO, abreviatura: 'CASADO', prefijo: null, valor: 0, descripcion: 'Estado civil casado para género masculino. Aplica a trabajadores y clientes de sexo masculino que tienen vínculo conyugal legal registrado.' },
    [EstadoCivilMasculino.DIVORCIADO]: { id: EstadoCivilMasculino.DIVORCIADO, abreviatura: 'DIVORCIADO', prefijo: null, valor: 0, descripcion: 'Estado civil divorciado para género masculino. Aplica a trabajadores y clientes de sexo masculino que han disuelto legalmente su vínculo conyugal.' },
    [EstadoCivilMasculino.VIUDO]: { id: EstadoCivilMasculino.VIUDO, abreviatura: 'VIUDO', prefijo: null, valor: 0, descripcion: 'Estado civil viudo para género masculino. Aplica a trabajadores y clientes de sexo masculino cuyo cónyuge ha fallecido.' },
    [EstadoCivilMasculino.UNION_LIBRE]: { id: EstadoCivilMasculino.UNION_LIBRE, abreviatura: 'UNION_LIBRE', prefijo: null, valor: 0, descripcion: 'Unión libre o de hecho para género masculino. Aplica a trabajadores y clientes de sexo masculino que conviven en pareja sin vínculo matrimonial legal.' },
};

// ==========================================
// ESTADO CIVIL FEMENINO
export enum EstadoCivilFemenino {
    SOLTERA = 1300,
    CASADA = 1301,
    DIVORCIADA = 1302,
    VIUDA = 1303,
    UNION_LIBRE = 1304,
}

export const ESTADO_CIVIL_FEMENINO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoCivilFemenino.SOLTERA]: { id: EstadoCivilFemenino.SOLTERA, abreviatura: 'SOLTERA', prefijo: null, valor: 0, descripcion: 'Estado civil soltera para género femenino. Aplica a trabajadoras y clientas de sexo femenino que no tienen vínculo conyugal legal. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoCivilFemenino.CASADA]: { id: EstadoCivilFemenino.CASADA, abreviatura: 'CASADA', prefijo: null, valor: 0, descripcion: 'Estado civil casada para género femenino. Aplica a trabajadoras y clientas de sexo femenino que tienen vínculo conyugal legal registrado.' },
    [EstadoCivilFemenino.DIVORCIADA]: { id: EstadoCivilFemenino.DIVORCIADA, abreviatura: 'DIVORCIADA', prefijo: null, valor: 0, descripcion: 'Estado civil divorciada para género femenino. Aplica a trabajadoras y clientas de sexo femenino que han disuelto legalmente su vínculo conyugal.' },
    [EstadoCivilFemenino.VIUDA]: { id: EstadoCivilFemenino.VIUDA, abreviatura: 'VIUDA', prefijo: null, valor: 0, descripcion: 'Estado civil viuda para género femenino. Aplica a trabajadoras y clientas de sexo femenino cuyo cónyuge ha fallecido.' },
    [EstadoCivilFemenino.UNION_LIBRE]: { id: EstadoCivilFemenino.UNION_LIBRE, abreviatura: 'UNION_LIBRE', prefijo: null, valor: 0, descripcion: 'Unión libre o de hecho para género femenino. Aplica a trabajadoras y clientas de sexo femenino que conviven en pareja sin vínculo matrimonial legal.' },
};

// ==========================================
// TIPO VENTA
export enum TipoVenta {
    NINGUNO = 1350,
    CON_FACTURA = 1351,
    SIN_FACTURA = 1352,
}

export const TIPO_VENTA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoVenta.NINGUNO]: { id: TipoVenta.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin tipo de venta definido. Utilizado exclusivamente en transacciones de compra a proveedores, proformas y ajustes de inventario. No aplica a ventas a clientes. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoVenta.CON_FACTURA]: { id: TipoVenta.CON_FACTURA, abreviatura: 'CON_FACTURA', prefijo: 'CF', valor: 0, descripcion: 'Venta formal con emisión de factura fiscal. Genera documento válido ante el SIN, permite crédito fiscal al cliente y debe estar asociada a una dosificación vigente en facturas.' },
    [TipoVenta.SIN_FACTURA]: { id: TipoVenta.SIN_FACTURA, abreviatura: 'SIN_FACTURA', prefijo: 'SF', valor: 0, descripcion: 'Venta sin emisión de factura fiscal. Utilizada para ventas de mostrador, ventas a consumidor final sin exigencia de factura o transacciones que no requieren comprobante fiscal. No genera crédito fiscal.' },
};

// ==========================================
// TIPO PAGO
export enum TipoPago {
    NINGUNO = 1400,
    EFECTIVO = 1401,
    TARJETA = 1402,
    CHEQUE = 1403,
    VALE = 1404,
    OTROS = 1405,
    SIN_PAGO = 1406,
    TRANSFERENCIA = 1407,
    DEPOSITO = 1408,
    QR = 1409,
}

export const TIPO_PAGO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoPago.NINGUNO]: { id: TipoPago.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin medio de pago definido. Utilizado exclusivamente en transacciones que no involucran cobro o pago (compras, proformas, ajustes de inventario, traspasos). No aplica para ventas a clientes. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoPago.EFECTIVO]: { id: TipoPago.EFECTIVO, abreviatura: 'EFECTIVO', prefijo: 'EF', valor: 1, descripcion: 'Pago en efectivo en moneda local o extranjera. Aplica para ventas de mostrador y cobros inmediatos. No requiere verificación bancaria ni comprobante digital adicional.' },
    [TipoPago.TARJETA]: { id: TipoPago.TARJETA, abreviatura: 'TARJETA', prefijo: 'TA', valor: 2, descripcion: 'Pago mediante tarjeta.' },
    [TipoPago.CHEQUE]: { id: TipoPago.CHEQUE, abreviatura: 'CHEQUE', prefijo: 'CH', valor: 3, descripcion: 'Pago mediante cheque bancario. Requiere verificación de fondos y autorización previa. Debe registrarse número de cheque, banco emisor y fecha de cobro. Aplica para ventas a empresas o clientes con convenio.' },
    [TipoPago.VALE]: { id: TipoPago.VALE, abreviatura: 'VALE', prefijo: 'VL', valor: 4, descripcion: 'Pago mediante vale.' },
    [TipoPago.OTROS]: { id: TipoPago.OTROS, abreviatura: 'OTROS', prefijo: 'OT', valor: 5, descripcion: 'Otros medio de pago no contemplado en la lista. Requiere descripción detallada en el campo observaciones. Aplica para casos excepcionales, vales de salud, bonos o pagos en especie.' },
    [TipoPago.SIN_PAGO]: { id: TipoPago.SIN_PAGO, abreviatura: 'SIN_PAGO', prefijo: 'SP', valor: 6, descripcion: 'Sin Pago.' },
    [TipoPago.TRANSFERENCIA]: { id: TipoPago.TRANSFERENCIA, abreviatura: 'TRANSFERENCIA', prefijo: 'TR', valor: 7, descripcion: 'Pago mediante transferencia bancaria (electrónica o ventanilla). Requiere comprobante de transferencia para validación. Aplica para pagos interbancarios, ventas corporativas o clientes a distancia.' },
    [TipoPago.DEPOSITO]: { id: TipoPago.DEPOSITO, abreviatura: 'DEPOSITO', prefijo: 'DP', valor: 8, descripcion: 'Pago mediante depósito en cuenta bancaria de la empresa. Requiere comprobante de depósito obligatorio (voucher o captura). Aplica para pagos en ventanilla, convenios con aseguradoras o clientes sin acceso a transferencia.' },
    [TipoPago.QR]: { id: TipoPago.QR, abreviatura: 'QR', prefijo: 'QR', valor: 9, descripcion: 'Pago mediante código QR a través de plataformas de pago (SIN, QRs, Yape, etc.). Genera comprobante digital automático. Aplica para pagos electrónicos rápidos.' },
};

// ==========================================
// TIPO MODELO
export enum TipoModelo {
    ARIMA = 1450,
    SARIMA = 1451,
    SERIES_TEMPORALES = 1452,
    CLASIFICACION = 1453,
    OPTIMIZACION = 1454,
    DETECCION_ANOMALIAS = 1455,
    NINGUNO = 1456,
}

export const TIPO_MODELO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoModelo.ARIMA]: { id: TipoModelo.ARIMA, abreviatura: 'ARIMA', prefijo: null, valor: 0, descripcion: 'Modelo ARIMA (Autoregressive Integrated Moving Average) para pronóstico de demanda de productos sin componente estacional significativa. Aplica para productos de consumo regular y estable.' },
    [TipoModelo.SARIMA]: { id: TipoModelo.SARIMA, abreviatura: 'SARIMA', prefijo: null, valor: 0, descripcion: 'Modelo SARIMA (Seasonal ARIMA) para pronóstico de demanda con componente estacional semanal, mensual o anual. Aplica para productos con patrones estacionales (alergias, gripes, vacaciones).' },
    [TipoModelo.SERIES_TEMPORALES]: { id: TipoModelo.SERIES_TEMPORALES, abreviatura: 'SERIES_TEMPORALES', prefijo: null, valor: 0, descripcion: 'Modelo genérico de series temporales para análisis de tendencias y patrones de consumo. Utilizado como base para otros modelos más específicos.' },
    [TipoModelo.CLASIFICACION]: { id: TipoModelo.CLASIFICACION, abreviatura: 'CLASIFICACION', prefijo: null, valor: 0, descripcion: 'Modelo de clasificación para segmentación de productos, clientes o proveedores. Incluye técnicas como K-Means, ABC, RFM y clustering jerárquico.' },
    [TipoModelo.OPTIMIZACION]: { id: TipoModelo.OPTIMIZACION, abreviatura: 'OPTIMIZACION', prefijo: null, valor: 0, descripcion: 'Modelo de optimización para cálculo de niveles óptimos de inventario, puntos de reorden (ROP), stock de seguridad y cantidades económicas de pedido (EOQ).' },
    [TipoModelo.DETECCION_ANOMALIAS]: { id: TipoModelo.DETECCION_ANOMALIAS, abreviatura: 'DETECCION_ANOMALIAS', prefijo: null, valor: 0, descripcion: 'Modelo para detección de anomalías en patrones de consumo, ventas y stock. Identifica comportamientos atípicos, fraudes y errores operativos.' },
    [TipoModelo.NINGUNO]: { id: TipoModelo.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin modelo definido. Para productos o módulos que no requieren análisis predictivo o no tienen datos suficientes. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO BENEFICIO
export enum TipoBeneficio {
    DESCUENTO = 1500,
    PORCENTAJE = 1501,
    MONTO_FIJO = 1502,
    CANTIDAD = 1503,
    NINGUNO = 1504,
}

export const TIPO_BENEFICIO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoBeneficio.DESCUENTO]: { id: TipoBeneficio.DESCUENTO, abreviatura: 'DESCUENTO', prefijo: null, valor: 0, descripcion: 'Beneficio genérico que agrupa diferentes tipos de descuentos. Utilizado como categoría superior para promociones que reducen el precio final del producto.' },
    [TipoBeneficio.PORCENTAJE]: { id: TipoBeneficio.PORCENTAJE, abreviatura: 'PORCENTAJE', prefijo: null, valor: 0, descripcion: 'Descuento porcentual sobre el precio de venta del producto. Fórmula: PrecioFinal = PrecioBase * (1 - ValorBeneficio/100). Aplica para promociones por temporada o liquidación.' },
    [TipoBeneficio.MONTO_FIJO]: { id: TipoBeneficio.MONTO_FIJO, abreviatura: 'MONTO_FIJO', prefijo: null, valor: 0, descripcion: 'Descuento de monto fijo en moneda local sobre el precio del producto. Fórmula: PrecioFinal = PrecioBase - ValorBeneficio. Aplica para promociones por volumen o cupones de descuento.' },
    [TipoBeneficio.CANTIDAD]: { id: TipoBeneficio.CANTIDAD, abreviatura: 'CANTIDAD', prefijo: null, valor: 0, descripcion: 'Descuento basado en cantidad de unidades adquiridas (ej. 2x1, 3x2). Fórmula: Se aplica sobre la cantidad total del ítem. Aplica para promociones de incentivo por volumen.' },
    [TipoBeneficio.NINGUNO]: { id: TipoBeneficio.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin beneficio o promoción definida. Para productos sin oferta activa o cuando no se aplica descuento. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO PRONOSTICO
export enum EstadoPronostico {
    PENDIENTE = 1550,
    PROCESADO = 1551,
    ERROR = 1552,
    NINGUNO = 1553,
}

export const ESTADO_PRONOSTICO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoPronostico.PENDIENTE]: { id: EstadoPronostico.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Pronóstico en cola de espera para procesamiento. El modelo aún no ha generado la predicción. Aplica para solicitudes de pronóstico recién creadas o en espera de ejecución.' },
    [EstadoPronostico.PROCESADO]: { id: EstadoPronostico.PROCESADO, abreviatura: 'PROCESADO', prefijo: null, valor: 0, descripcion: 'Pronóstico completado exitosamente. El modelo generó la predicción y los resultados están disponibles en analitica_productos. Aplica para pronósticos que finalizaron sin errores.' },
    [EstadoPronostico.ERROR]: { id: EstadoPronostico.ERROR, abreviatura: 'ERROR', prefijo: null, valor: 0, descripcion: 'Pronóstico fallido por error en el procesamiento. Puede deberse a datos insuficientes, errores en el modelo o fallos técnicos. Requiere revisión manual y posible reentrenamiento.' },
    [EstadoPronostico.NINGUNO]: { id: EstadoPronostico.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado de pronóstico definido. Para productos que no han sido procesados por el motor de IA o que no requieren pronóstico. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TEMPORADA
export enum Temporada {
    NINGUNO = 1600,
    ALTA = 1601,
    MEDIA = 1602,
    BAJA = 1603,
}

export const TEMPORADA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Temporada.NINGUNO]: { id: Temporada.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin temporada definida o período transicional sin estacionalidad marcada. Para productos con demanda constante o cuando no hay datos suficientes para clasificar. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Temporada.ALTA]: { id: Temporada.ALTA, abreviatura: 'ALTA', prefijo: null, valor: 0, descripcion: 'Temporada de demanda alta con incremento significativo en ventas. Aplica en períodos de enfermedades estacionales (gripe, alergias, dengue), eventos especiales o campañas promocionales intensivas.' },
    [Temporada.MEDIA]: { id: Temporada.MEDIA, abreviatura: 'MEDIA', prefijo: null, valor: 0, descripcion: 'Temporada de demanda media o regular con comportamiento estable dentro de los patrones normales. Aplica en períodos intermedios sin picos ni caídas significativas.' },
    [Temporada.BAJA]: { id: Temporada.BAJA, abreviatura: 'BAJA', prefijo: null, valor: 0, descripcion: 'Temporada de demanda baja con decremento notable en ventas. Aplica en períodos de baja incidencia de enfermedades, vacaciones o cuando el consumo disminuye estacionalmente.' },
};

// ==========================================
// ESTADO FISCAL
export enum EstadoFiscal {
    ACTIVO = 1650,
    AGOTADO = 1651,
    VENCIDO = 1652,
    CANCELADO = 1653,
}

export const ESTADO_FISCAL_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoFiscal.ACTIVO]: { id: EstadoFiscal.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Dosificación fiscal vigente y operativa. Permite la emisión de facturas electrónicas con validez ante el SIN. El sistema puede generar comprobantes fiscales sin restricciones. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoFiscal.AGOTADO]: { id: EstadoFiscal.AGOTADO, abreviatura: 'AGOTADO', prefijo: null, valor: 0, descripcion: 'Rango de numeración de facturas completamente consumido. No es posible emitir más facturas con esta dosificación. Se debe solicitar una nueva autorización al SIN. Bloquea automáticamente la emisión de comprobantes.' },
    [EstadoFiscal.VENCIDO]: { id: EstadoFiscal.VENCIDO, abreviatura: 'VENCIDO', prefijo: null, valor: 0, descripcion: 'Fecha de vigencia de la dosificación superada según lo establecido por el SIN. No es posible emitir facturas con esta autorización vencida. Se debe renovar la dosificación ante el SIN.' },
    [EstadoFiscal.CANCELADO]: { id: EstadoFiscal.CANCELADO, abreviatura: 'CANCELADO', prefijo: null, valor: 0, descripcion: 'Dosificación anulada o cancelada por decisión administrativa o por disposición del SIN. No es posible emitir facturas con esta autorización. Estado irreversible que mantiene el registro histórico para auditoría.' },
};

// ==========================================
// TIPO ALMACEN
export enum TipoAlmacen {
    NORMAL = 1700,
    REFRIGERADO = 1701,
    CONGELADO = 1702,
    ESPECIAL = 1703,
    TRANSITO = 1704,
    MATERIAL_MEDICO = 1705,
    COSMETICA = 1706,
    ALIMENTOS = 1707,
    MATERIA_PRIMA = 1708,
    RECEPCION = 1709,
    DEVOLUCIONES = 1710,
    DESPACHO = 1711,
    CUARENTENA = 1712,
}

export const TIPOS_ALMACEN_VENTA_DIRECTA = [
    TipoAlmacen.NORMAL,
    TipoAlmacen.REFRIGERADO,
    TipoAlmacen.CONGELADO,
    TipoAlmacen.ESPECIAL,
    TipoAlmacen.MATERIAL_MEDICO,
    TipoAlmacen.COSMETICA,
    TipoAlmacen.ALIMENTOS,
    TipoAlmacen.MATERIA_PRIMA,
] as const;

export const TIPOS_ALMACEN_LOGISTICA_INTERNA = [
    TipoAlmacen.TRANSITO,
	TipoAlmacen.RECEPCION,
	TipoAlmacen.DEVOLUCIONES,
	TipoAlmacen.DESPACHO,
	TipoAlmacen.CUARENTENA,
] as const;

export const TIPO_ALMACEN_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoAlmacen.NORMAL]: { id: TipoAlmacen.NORMAL, abreviatura: 'NORMAL', prefijo: null, valor: 0, descripcion: 'Almacén de temperatura ambiente, para productos que no requieren condiciones especiales de conservación. Aplica para la mayoría de medicamentos de venta libre y productos de consumo regular. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoAlmacen.REFRIGERADO]: { id: TipoAlmacen.REFRIGERADO, abreviatura: 'REFRIGERADO', prefijo: null, valor: 0, descripcion: 'Almacén refrigerado con temperatura controlada. Para vacunas, insulinas, biológicos y medicamentos termolábiles que requieren cadena de frío.' },
    [TipoAlmacen.CONGELADO]: { id: TipoAlmacen.CONGELADO, abreviatura: 'CONGELADO', prefijo: null, valor: 0, descripcion: 'Almacén congelado con temperatura controlada. Para productos biológicos, hemoderivados y medicamentos que requieren congelación profunda para su conservación.' },
    [TipoAlmacen.ESPECIAL]: { id: TipoAlmacen.ESPECIAL, abreviatura: 'ESPECIAL', prefijo: null, valor: 0, descripcion: 'Almacén de alta seguridad para productos controlados (psicotrópicos, estupefacientes, sustancias fiscalizadas).' },
    [TipoAlmacen.TRANSITO]: { id: TipoAlmacen.TRANSITO, abreviatura: 'TRANSITO', prefijo: null, valor: 0, descripcion: 'Almacén temporal para mercadería en tránsito entre sucursales o en proceso de distribución. Productos con estado de "en movimiento" que no están disponibles para venta hasta su recepción en destino.' },
    [TipoAlmacen.MATERIAL_MEDICO]: { id: TipoAlmacen.MATERIAL_MEDICO, abreviatura: 'MATERIAL_MEDICO', prefijo: null, valor: 0, descripcion: 'Almacén para material médico-quirúrgico, dispositivos médicos, insumos descartables (jeringas, guantes, gasas) y equipos de diagnóstico. No requiere condiciones especiales de temperatura.' },
    [TipoAlmacen.COSMETICA]: { id: TipoAlmacen.COSMETICA, abreviatura: 'COSMETICA', prefijo: null, valor: 0, descripcion: 'Almacén para productos cosméticos, de cuidado personal, higiene y belleza. Incluye cremas, lociones, shampoos, perfumes y productos de maquillaje.' },
    [TipoAlmacen.ALIMENTOS]: { id: TipoAlmacen.ALIMENTOS, abreviatura: 'ALIMENTOS', prefijo: null, valor: 0, descripcion: 'Almacén para suplementos nutricionales, alimentos funcionales, vitaminas, minerales y productos dietéticos. Requiere condiciones de humedad controlada y protección contra contaminación cruzada.' },
    [TipoAlmacen.MATERIA_PRIMA]: { id: TipoAlmacen.MATERIA_PRIMA, abreviatura: 'MATERIA_PRIMA', prefijo: null, valor: 0, descripcion: 'Almacén para materias primas utilizadas en farmacia magistral o preparación de fórmulas personalizadas. Incluye principios activos, excipientes, vehículos y materiales de acondicionamiento.' },
    [TipoAlmacen.RECEPCION]: { id: TipoAlmacen.RECEPCION, abreviatura: 'RECEPCION', prefijo: null, valor: 0, descripcion: 'Área de recepción de mercadería y control de calidad. Zona de tránsito para productos que ingresan al sistema, pendientes de verificación, conteo y asignación a su almacén definitivo.' },
    [TipoAlmacen.DEVOLUCIONES]: { id: TipoAlmacen.DEVOLUCIONES, abreviatura: 'DEVOLUCIONES', prefijo: null, valor: 0, descripcion: 'Área para productos en proceso de devolución a proveedores o clientes. Incluye productos defectuosos, vencidos, dañados o en espera de gestión de devolución.' },
    [TipoAlmacen.DESPACHO]: { id: TipoAlmacen.DESPACHO, abreviatura: 'DESPACHO', prefijo: null, valor: 0, descripcion: 'Área de despacho, consolidación de pedidos y preparación de entregas. Productos que han sido seleccionados (picking) y están listos para distribución a clientes o traslado entre sucursales.' },
    [TipoAlmacen.CUARENTENA]: { id: TipoAlmacen.CUARENTENA, abreviatura: 'CUARENTENA', prefijo: null, valor: 0, descripcion: 'Área de cuarentena sanitaria para productos en revisión, análisis o evaluación. Incluye productos sospechosos de contaminación, lotes en investigación o productos pendientes de liberación por control de calidad.' },
};

export const TIPOS_ALMACEN_VENTA_DIRECTA_METADATA = Object.fromEntries(TIPOS_ALMACEN_VENTA_DIRECTA.map(id => [id, TIPO_ALMACEN_METADATA[id]]));
export const TIPOS_ALMACEN_LOGISTICA_INTERNA_METADATA = Object.fromEntries(TIPOS_ALMACEN_LOGISTICA_INTERNA.map(id => [id, TIPO_ALMACEN_METADATA[id]]));

// ==========================================
// TIPO CUENTA
export enum TipoCuenta {
    CUENTA_CORRIENTE = 1750,
    CAJA_AHORROS = 1751,
    AHORRO_PROGRAMADO = 1752,
    PLAZO_FIJO = 1753,
    INVERSION = 1754,
    NO_APLICA = 1755,
}

export const TIPO_CUENTA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoCuenta.CUENTA_CORRIENTE]: { id: TipoCuenta.CUENTA_CORRIENTE, abreviatura: 'CUENTA_CORRIENTE', prefijo: null, valor: 0, descripcion: 'Cuenta corriente bancaria para operaciones diarias. Permite emisión de cheques, débitos automáticos y múltiples transacciones sin límite de operaciones. Ideal para cuentas empresariales con alta rotación. Aplica para cuentas de la empresa y de clientes corporativos.' },
    [TipoCuenta.CAJA_AHORROS]: { id: TipoCuenta.CAJA_AHORROS, abreviatura: 'CAJA_AHORROS', prefijo: null, valor: 0, descripcion: 'Cuenta de ahorros para depósitos y retiros con disponibilidad inmediata. Generalmente genera intereses y tiene límite de operaciones mensuales. Ideal para ahorro personal y cuentas de clientes individuales.' },
    [TipoCuenta.AHORRO_PROGRAMADO]: { id: TipoCuenta.AHORRO_PROGRAMADO, abreviatura: 'AHORRO_PROGRAMADO', prefijo: null, valor: 0, descripcion: 'Cuenta de ahorro con depósitos programados en fechas fijas (mensuales, quincenales). Permite acumulación de fondos con propósitos específicos. Aplica para clientes con planes de ahorro o empresas que manejan fondos de reserva.' },
    [TipoCuenta.PLAZO_FIJO]: { id: TipoCuenta.PLAZO_FIJO, abreviatura: 'PLAZO_FIJO', prefijo: null, valor: 0, descripcion: 'Depósito a plazo fijo con tasa de interés definida y fecha de vencimiento determinada. No permite retiros anticipados sin penalización. Aplica para inversiones de capital de trabajo o excedentes de caja.' },
    [TipoCuenta.INVERSION]: { id: TipoCuenta.INVERSION, abreviatura: 'INVERSION', prefijo: null, valor: 0, descripcion: 'Cuenta de inversión con diferentes instrumentos financieros (acciones, bonos, fondos mutuos). Mayor rendimiento potencial con mayor riesgo asociado. Aplica para empresas con estrategias de inversión diversificadas.' },
    [TipoCuenta.NO_APLICA]: { id: TipoCuenta.NO_APLICA, abreviatura: 'NO_APLICA', prefijo: null, valor: 0, descripcion: 'No aplica. Utilizado como valor por defecto cuando no se registra información de cuenta bancaria. Aplica para clientes sin cuenta asociada, transacciones en efectivo o cuando el medio de pago no requiere cuenta bancaria. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO DATO
export enum TipoDato {
    STRING = 1800,
    INTEGER = 1801,
    DECIMAL = 1802,
    BOOLEAN = 1803,
    TIMESTAMP = 1804,
    JSONB = 1805,
}

export const TIPO_DATO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoDato.STRING]: { id: TipoDato.STRING, abreviatura: 'STRING', prefijo: null, valor: 0, descripcion: 'Tipo de dato para valores de texto. Acepta caracteres alfanuméricos, espacios y símbolos. Ejemplos: "BOB", "VEN", "CASA_MATRIZ". CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoDato.INTEGER]: { id: TipoDato.INTEGER, abreviatura: 'INTEGER', prefijo: null, valor: 0, descripcion: 'Tipo de dato para valores numéricos enteros. Acepta solo dígitos (0-9), sin puntos, comas o signos. Ejemplos: "50", "7", "365".' },
    [TipoDato.DECIMAL]: { id: TipoDato.DECIMAL, abreviatura: 'DECIMAL', prefijo: null, valor: 0, descripcion: 'Tipo de dato para valores numéricos con decimales. Acepta dígitos con punto decimal opcional. Ejemplos: "13.00", "0.95", "1.50".' },
    [TipoDato.BOOLEAN]: { id: TipoDato.BOOLEAN, abreviatura: 'BOOLEAN', prefijo: null, valor: 0, descripcion: 'Tipo de dato para valores lógicos binarios. Acepta exclusivamente "1" (VERDADERO/SI) o "0" (FALSO/NO).' },
    [TipoDato.TIMESTAMP]: { id: TipoDato.TIMESTAMP, abreviatura: 'TIMESTAMP', prefijo: null, valor: 0, descripcion: 'Tipo de dato para valores de fecha y hora con zona horaria (TIMESTAMPTZ). Acepta formato ISO 8601 con timezone. Ejemplos: "2026-01-01 00:00:00-04:00", "2026-01-01T00:00:00.000Z".' },
    [TipoDato.JSONB]: { id: TipoDato.JSONB, abreviatura: 'JSONB', prefijo: null, valor: 0, descripcion: 'Tipo de dato para objetos JSONB. Almacena estructuras complejas anidadas. Ejemplos: {"max_size": 204800, "allowed_formats": ["png", "jpeg"]}' },
};

// ==========================================
// NIVEL URGENCIA
export enum NivelUrgencia {
    BAJA = 1850,
    MEDIA = 1851,
    ALTA = 1852,
    CRITICA = 1853,
    NINGUNO = 1854,
}

export const NIVEL_URGENCIA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [NivelUrgencia.BAJA]: { id: NivelUrgencia.BAJA, abreviatura: 'BAJA', prefijo: null, valor: 0, descripcion: 'Nivel de urgencia bajo. Situación monitoreable sin acción inmediata. Tiempo de respuesta sugerido: 24-48 horas. Aplica para alertas informativas o de seguimiento sin impacto crítico en operaciones.' },
    [NivelUrgencia.MEDIA]: { id: NivelUrgencia.MEDIA, abreviatura: 'MEDIA', prefijo: null, valor: 0, descripcion: 'Nivel de urgencia medio. Requiere atención en el corto plazo pero no bloquea operaciones críticas. Tiempo de respuesta sugerido: 4-8 horas. Aplica para alertas que requieren evaluación y posible ajuste.' },
    [NivelUrgencia.ALTA]: { id: NivelUrgencia.ALTA, abreviatura: 'ALTA', prefijo: null, valor: 0, descripcion: 'Nivel de urgencia alto. Requiere atención prioritaria y puede afectar operaciones si no se aborda. Tiempo de respuesta sugerido: 1-2 horas. Aplica para alertas de stock crítico, vencimientos inminentes o desviaciones significativas.' },
    [NivelUrgencia.CRITICA]: { id: NivelUrgencia.CRITICA, abreviatura: 'CRITICA', prefijo: null, valor: 0, descripcion: 'Nivel de urgencia crítico. Requiere acción inmediata porque bloquea operaciones esenciales o representa un riesgo grave. Tiempo de respuesta sugerido: inmediato (< 30 minutos). Aplica para quiebre de stock de medicamentos esenciales, fallos en cadena de frío o alertas de seguridad.' },
    [NivelUrgencia.NINGUNO]: { id: NivelUrgencia.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin nivel de urgencia definido. Para casos donde no aplica clasificación de urgencia. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// MOTIVO OUTLIER
export enum MotivoOutlier {
    BLOQUEO = 1900,
    FERIADO_LOCAL = 1901,
    ERROR_SISTEMA = 1902,
    PICO_ANORMAL = 1903,
    ROTURA = 1904,
    ROBO = 1905,
    SOBRANTE = 1906,
    NINGUNO = 1907,
}

export const MOTIVO_OUTLIER_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [MotivoOutlier.BLOQUEO]: { id: MotivoOutlier.BLOQUEO, abreviatura: 'BLOQUEO', prefijo: null, valor: 0, descripcion: 'Anomalía por bloqueo de caminos, protestas sociales, restricciones de movilidad o desastres naturales que afectan la distribución y disponibilidad de productos. Ajusta pronósticos considerando interrupciones externas.' },
    [MotivoOutlier.FERIADO_LOCAL]: { id: MotivoOutlier.FERIADO_LOCAL, abreviatura: 'FERIADO_LOCAL', prefijo: null, valor: 0, descripcion: 'Anomalía por día festivo local no considerado en el calendario estándar. Incluye feriados departamentales, municipales o religiosos que afectan patrones de consumo y operación.' },
    [MotivoOutlier.ERROR_SISTEMA]: { id: MotivoOutlier.ERROR_SISTEMA, abreviatura: 'ERROR_SISTEMA', prefijo: null, valor: 0, descripcion: 'Anomalía por error en registro de datos, fallos en integración con otros sistemas o problemas técnicos que generan datos inconsistentes. Requiere revisión y corrección manual.' },
    [MotivoOutlier.PICO_ANORMAL]: { id: MotivoOutlier.PICO_ANORMAL, abreviatura: 'PICO_ANORMAL', prefijo: null, valor: 0, descripcion: 'Anomalía por pico anormal de demanda no repetible. Incluye eventos puntuales como epidemias, campañas de vacunación masiva o promociones extraordinarias que distorsionan el patrón histórico.' },
    [MotivoOutlier.ROTURA]: { id: MotivoOutlier.ROTURA, abreviatura: 'ROTURA', prefijo: null, valor: 0, descripcion: 'Anomalía por rotura, daño físico, deterioro o contaminación de material. Genera pérdida de inventario y requiere ajuste por merma. Aplica para productos dañados en almacén o durante el transporte.' },
    [MotivoOutlier.ROBO]: { id: MotivoOutlier.ROBO, abreviatura: 'ROBO', prefijo: null, valor: 0, descripcion: 'Anomalía por robo, hurto o sustracción de mercadería detectada en inventario. Genera pérdida de stock y requiere ajuste negativo con reporte a seguridad. Aplica para faltantes no justificados.' },
    [MotivoOutlier.SOBRANTE]: { id: MotivoOutlier.SOBRANTE, abreviatura: 'SOBRANTE', prefijo: null, valor: 0, descripcion: 'Anomalía por sobrante detectado en inventario físico. Genera ajuste positivo de stock. Generalmente ocasionado por errores de conteo previo, recepciones sin registrar o devoluciones no contabilizadas.' },
    [MotivoOutlier.NINGUNO]: { id: MotivoOutlier.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin motivo de outlier definido. Cuando no se identifica una causa específica para la anomalía o cuando el pronóstico no presenta desviaciones significativas. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// FORMATO PDF
export enum FormatoPDF {
    ESTANDAR = 1950,
    RESUMIDO = 1951,
    DETALLADO = 1952,
}

export const FORMATO_PDF_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [FormatoPDF.ESTANDAR]: { id: FormatoPDF.ESTANDAR, abreviatura: 'ESTANDAR', prefijo: null, valor: 0, descripcion: 'Formato estándar de factura con todos los datos fiscales requeridos por el SIN. Incluye información completa del emisor, receptor, detalle de productos, impuestos desglosados y códigos de control. Aplica para facturación regular. CONSTANTE POR DEFECTO.', es_defecto: true },
    [FormatoPDF.RESUMIDO]: { id: FormatoPDF.RESUMIDO, abreviatura: 'RESUMIDO', prefijo: null, valor: 0, descripcion: 'Formato resumido con información esencial y diseño compacto. Incluye solo los datos fiscales obligatorios: emisor, receptor, totales e impuestos. Omite detalles extensos. Aplica para tickets rápidos, ventas de mostrador o comprobantes internos.' },
    [FormatoPDF.DETALLADO]: { id: FormatoPDF.DETALLADO, abreviatura: 'DETALLADO', prefijo: null, valor: 0, descripcion: 'Formato extendido con información completa y adicional. Incluye todos los datos del estándar más información complementaria: desglose por lote, fechas de vencimiento, registros sanitarios, datos del laboratorio y notas adicionales. Aplica para facturas a instituciones o clientes corporativos.' },
};

// ==========================================
// ESTADO MODELO
export enum EstadoModelo {
    SIN_DATOS = 2000,
    ENTRENANDO = 2001,
    ACTIVO = 2002,
    RECHAZADO = 2003,
    OBSOLETO = 2004,
}

export const ESTADO_MODELO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoModelo.SIN_DATOS]: { id: EstadoModelo.SIN_DATOS, abreviatura: 'SIN_DATOS', prefijo: null, valor: 0, descripcion: 'Estado inicial cuando un producto no cuenta con datos históricos suficientes para entrenar el modelo. Requiere mínimo de registros configurado en parametros_globales. El modelo no genera predicciones hasta acumular datos suficientes. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoModelo.ENTRENANDO]: { id: EstadoModelo.ENTRENANDO, abreviatura: 'ENTRENANDO', prefijo: null, valor: 0, descripcion: 'Modelo en proceso de entrenamiento. El motor de IA está calculando parámetros, ajustando hiperparámetros y validando el modelo con datos históricos. No genera predicciones hasta finalizar el proceso.' },
    [EstadoModelo.ACTIVO]: { id: EstadoModelo.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Modelo entrenado exitosamente y en producción. Genera predicciones de demanda, puntos de reorden y análisis de tendencias. Se actualiza periódicamente según frecuencia configurada. Estado operativo deseado para modelos funcionales.' },
    [EstadoModelo.RECHAZADO]: { id: EstadoModelo.RECHAZADO, abreviatura: 'RECHAZADO', prefijo: null, valor: 0, descripcion: 'Modelo rechazado por error de predicción (MAPE) superior al umbral permitido. No genera predicciones hasta que se reentrene con mejores datos o se ajusten los parámetros. Requiere revisión manual.' },
    [EstadoModelo.OBSOLETO]: { id: EstadoModelo.OBSOLETO, abreviatura: 'OBSOLETO', prefijo: null, valor: 0, descripcion: 'Modelo reemplazado por una versión más reciente o mejorada. Se mantiene en histórico para trazabilidad y comparación, pero ya no se utiliza para predicciones activas. Puede reactivarse si es necesario.' },
};

// ==========================================
// CALIDAD RATING
export enum CalidadRating {
    PESIMO = 2050,
    DEFICIENTE = 2051,
    REGULAR = 2052,
    BUENO = 2053,
    EXCELENTE = 2054,
    NINGUNO = 2055,
}

export const CALIDAD_RATING_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [CalidadRating.PESIMO]: { id: CalidadRating.PESIMO, abreviatura: 'PESIMO', prefijo: null, valor: 0, descripcion: 'Calificación más baja. Proveedor con incumplimientos graves en plazos de entrega, productos defectuosos recurrentes o problemas de calidad crítica. Se recomienda evaluar discontinuación de la relación comercial.' },
    [CalidadRating.DEFICIENTE]: { id: CalidadRating.DEFICIENTE, abreviatura: 'DEFICIENTE', prefijo: null, valor: 0, descripcion: 'Calificación baja. Proveedor con incumplimientos frecuentes en calidad o plazos. Requiere supervisión estricta y seguimiento continuo. Se recomienda restringir volumen de compras.' },
    [CalidadRating.REGULAR]: { id: CalidadRating.REGULAR, abreviatura: 'REGULAR', prefijo: null, valor: 0, descripcion: 'Calificación media. Proveedor que cumple con lo mínimo esperado pero sin destacar. Presenta algunos incumplimientos ocasionales. Se recomienda monitoreo periódico y definir plan de mejora.' },
    [CalidadRating.BUENO]: { id: CalidadRating.BUENO, abreviatura: 'BUENO', prefijo: null, valor: 0, descripcion: 'Calificación alta. Proveedor confiable que cumple consistentemente con plazos y calidad. Presenta incumplimientos menores y excepcionales. Se recomienda mantener relación y considerar aumentar volumen de compras.' },
    [CalidadRating.EXCELENTE]: { id: CalidadRating.EXCELENTE, abreviatura: 'EXCELENTE', prefijo: null, valor: 0, descripcion: 'Calificación máxima. Proveedor destacado que supera expectativas en calidad, plazos, servicio y precio. Presenta incumplimientos nulos o insignificantes. Se recomienda priorizar en compras y establecer alianzas estratégicas.' },
    [CalidadRating.NINGUNO]: { id: CalidadRating.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin calificación de calidad definida. Para proveedores nuevos o cuando aún no se ha realizado evaluación formal de desempeño. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO TRASPASO
export enum EstadoTraspaso {
    EN_TRANSITO = 2100,
    RECIBIDO = 2101,
    RECHAZADO = 2102,
    NO_APLICA = 2103,
}

export const ESTADO_TRASPASO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoTraspaso.EN_TRANSITO]: { id: EstadoTraspaso.EN_TRANSITO, abreviatura: 'EN_TRANSITO', prefijo: null, valor: 0, descripcion: 'Mercancía en tránsito entre sucursales. Stock disminuido en origen pero aún no disponible en destino. El producto no está disponible para venta en ninguna de las dos sucursales durante el traslado. Estado inicial al generar el traspaso.' },
    [EstadoTraspaso.RECIBIDO]: { id: EstadoTraspaso.RECIBIDO, abreviatura: 'RECIBIDO', prefijo: null, valor: 0, descripcion: 'Mercancía recibida y confirmada en sucursal destino. Stock incrementado en destino y el producto queda disponible para venta. El traspaso se considera completado exitosamente. Estado final del flujo.' },
    [EstadoTraspaso.RECHAZADO]: { id: EstadoTraspaso.RECHAZADO, abreviatura: 'RECHAZADO', prefijo: null, valor: 0, descripcion: 'Traspaso cancelado o rechazado. Reversión automática del stock en origen (se restituye la cantidad disminuida). No se realiza incremento en destino. Aplica por falta de productos, daños en transporte o decisión administrativa.' },
    [EstadoTraspaso.NO_APLICA]: { id: EstadoTraspaso.NO_APLICA, abreviatura: 'NO_APLICA', prefijo: null, valor: 0, descripcion: 'Estado por defecto para transacciones que no son traspasos inter-sucursales. Aplica para compras, ventas, proformas, ajustes y cualquier otro evento que no involucre movimiento entre almacenes. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// MODULO ESTRATEGICO
export enum ModuloEstrategico {
    FLUJO_CAJA = 2150,
    DEMANDA_INVENTARIO = 2151,
    PROVEEDORES_AHP = 2152,
    OPERACION_MERMAS = 2153,
    CLIENTES_RFM = 2154,
    PRECIOS_ELASTICIDAD = 2155,
    ANOMALIAS_FRAUDE = 2156,
    NINGUNO = 2157,
}

export const MODULO_ESTRATEGICO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [ModuloEstrategico.FLUJO_CAJA]: { id: ModuloEstrategico.FLUJO_CAJA, abreviatura: 'FLUJO_CAJA', prefijo: null, valor: 0, descripcion: 'Módulo de análisis y pronóstico de flujo de caja e ingresos. Utiliza modelos ARIMA y LSTM para predecir ingresos, identificar estacionalidades y optimizar liquidez. Aplica para planificación financiera y gestión de tesorería.' },
    [ModuloEstrategico.DEMANDA_INVENTARIO]: { id: ModuloEstrategico.DEMANDA_INVENTARIO, abreviatura: 'DEMANDA_INVENTARIO', prefijo: null, valor: 0, descripcion: 'Módulo de pronóstico de demanda y optimización de inventario. Utiliza XGBoost para predicción de demanda y EOQ (Economic Order Quantity) para niveles óptimos de stock. Aplica para gestión de compras y reducción de quiebres.' },
    [ModuloEstrategico.PROVEEDORES_AHP]: { id: ModuloEstrategico.PROVEEDORES_AHP, abreviatura: 'PROVEEDORES_AHP', prefijo: null, valor: 0, descripcion: 'Módulo de evaluación y gestión de proveedores. Utiliza AHP (Analytic Hierarchy Process) y sistemas de scoring para calificar desempeño. Aplica para selección de proveedores, negociación y evaluación continua.' },
    [ModuloEstrategico.OPERACION_MERMAS]: { id: ModuloEstrategico.OPERACION_MERMAS, abreviatura: 'OPERACION_MERMAS', prefijo: null, valor: 0, descripcion: 'Módulo de análisis de operaciones diarias y control de mermas. Utiliza Teoría de Colas para optimizar atención y algoritmos genéticos para minimizar pérdidas. Aplica para eficiencia operativa y reducción de desperdicios.' },
    [ModuloEstrategico.CLIENTES_RFM]: { id: ModuloEstrategico.CLIENTES_RFM, abreviatura: 'CLIENTES_RFM', prefijo: null, valor: 0, descripcion: 'Módulo de segmentación y análisis de clientes. Utiliza RFM (Recencia, Frecuencia, Monto), K-Means y CLV (Customer Lifetime Value). Aplica para campañas de fidelización y marketing personalizado.' },
    [ModuloEstrategico.PRECIOS_ELASTICIDAD]: { id: ModuloEstrategico.PRECIOS_ELASTICIDAD, abreviatura: 'PRECIOS_ELASTICIDAD', prefijo: null, valor: 0, descripcion: 'Módulo de optimización de precios y análisis de márgenes. Utiliza modelos de elasticidad de demanda y reglas de asociación Apriori. Aplica para estrategias de precios y maximización de rentabilidad.' },
    [ModuloEstrategico.ANOMALIAS_FRAUDE]: { id: ModuloEstrategico.ANOMALIAS_FRAUDE, abreviatura: 'ANOMALIAS_FRAUDE', prefijo: null, valor: 0, descripcion: 'Módulo de detección de anomalías y prevención de fraude. Utiliza Isolation Forest y LOF (Local Outlier Factor). Aplica para identificación de comportamientos sospechosos en ventas, inventario y pagos.' },
    [ModuloEstrategico.NINGUNO]: { id: ModuloEstrategico.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin módulo estratégico definido. Valor por defecto para tareas y procesos que no pertenecen a un módulo específico o que aún no han sido clasificados. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO DOCUMENTO
export enum TipoDocumento {
    CEDULA_IDENTIDAD = 2200,
    CEDULA_IDENTIDAD_EXTRANJERO = 2201,
    PASAPORTE = 2202,
    OTRO = 2203,
    NIT = 2204,
}

export const TIPO_DOCUMENTO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoDocumento.CEDULA_IDENTIDAD]: { id: TipoDocumento.CEDULA_IDENTIDAD, abreviatura: 'CEDULA_IDENTIDAD', prefijo: 'CI', valor: 1, descripcion: 'Cédula de identidad boliviana. Documento nacional emitido por el SEGIP. Formato: numérico (ej. 1234567) o con complemento (ej. 1234567-1A). CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoDocumento.CEDULA_IDENTIDAD_EXTRANJERO]: { id: TipoDocumento.CEDULA_IDENTIDAD_EXTRANJERO, abreviatura: 'CEDULA_IDENTIDAD_EXTRANJERO', prefijo: 'CEX', valor: 2, descripcion: 'Cédula de identidad de extranjero. Documento para residentes no bolivianos emitido por el SEGIP. Formato: numérico con prefijo (ej. 1234567-1). Utilizado para extranjeros con residencia.' },
    [TipoDocumento.PASAPORTE]: { id: TipoDocumento.PASAPORTE, abreviatura: 'PASAPORTE', prefijo: 'PAS', valor: 3, descripcion: 'Pasaporte. Documento de identidad internacional emitido por autoridades migratorias de cada país. Formato: alfanumérico variable (ej. AB123456). Utilizado para extranjeros sin residencia.' },
    [TipoDocumento.OTRO]: { id: TipoDocumento.OTRO, abreviatura: 'OTRO', prefijo: 'OTRO', valor: 4, descripcion: 'Otro tipo de documento de identidad no contemplado en las categorías anteriores. Utilizado para casos excepcionales, documentos diplomáticos, cédulas especiales o documentos temporales.' },
    [TipoDocumento.NIT]: { id: TipoDocumento.NIT, abreviatura: 'NIT', prefijo: 'NIT', valor: 5, descripcion: 'Número de Identificación Tributaria. Emitido por el Servicio de Impuestos Nacionales (SIN). Formato: numérico de 7-10 dígitos (ej. 1023456021).' },
};

// ==========================================
// ESTADO PEDIDO
export enum EstadoPedido {
    COTIZADO = 2250,
    APROBADO = 2251,
    EN_RUTA = 2252,
    RECIBIDO = 2253,
    PARCIAL = 2254,
    RECHAZADO = 2255,
    CANCELADO = 2256,
    NINGUNO = 2257,
}

export const ESTADO_PEDIDO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoPedido.COTIZADO]: { id: EstadoPedido.COTIZADO, abreviatura: 'COTIZADO', prefijo: 'COT', valor: 1, descripcion: 'Pedido cotizado y en espera de aprobación administrativa. No afecta stock ni genera obligación de compra. Estado inicial del flujo. CONSTANTE POR DEFECTO.' },
    [EstadoPedido.APROBADO]: { id: EstadoPedido.APROBADO, abreviatura: 'APROBADO', prefijo: 'APR', valor: 2, descripcion: 'Pedido aprobado por administración y enviado al proveedor. En proceso de gestión de compra. Aún no afecta stock ni inventario.' },
    [EstadoPedido.EN_RUTA]: { id: EstadoPedido.EN_RUTA, abreviatura: 'EN_RUTA', prefijo: 'RUT', valor: 3, descripcion: 'Pedido despachado por el proveedor y en tránsito hacia la farmacia. No afecta stock hasta su recepción física. Requiere seguimiento logístico.' },
    [EstadoPedido.RECIBIDO]: { id: EstadoPedido.RECIBIDO, abreviatura: 'RECIBIDO', prefijo: 'REC', valor: 4, descripcion: 'Pedido recibido completamente en almacén. Incrementa stock según los lotes y cantidades registradas. Estado final exitoso del flujo.' },
    [EstadoPedido.PARCIAL]: { id: EstadoPedido.PARCIAL, abreviatura: 'PARCIAL', prefijo: 'PAR', valor: 5, descripcion: 'Pedido recibido de forma parcial. Parte de la mercadería fue recibida, pero faltan productos por llegar. Genera incremento parcial de stock y requiere seguimiento de pendientes.' },
    [EstadoPedido.RECHAZADO]: { id: EstadoPedido.RECHAZADO, abreviatura: 'RECHAZADO', prefijo: 'RCH', valor: 6, descripcion: 'Pedido rechazado por problemas de calidad, incumplimiento de especificaciones o condiciones. No afecta stock. Requiere gestión de devolución o reclamo al proveedor.' },
    [EstadoPedido.CANCELADO]: { id: EstadoPedido.CANCELADO, abreviatura: 'CANCELADO', prefijo: 'CAN', valor: 7, descripcion: 'Pedido cancelado por decisión del proveedor o de la farmacia antes de su recepción. No afecta stock. Estado final sin ejecución.' },
    [EstadoPedido.NINGUNO]: { id: EstadoPedido.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin estado de pedido definido. Valor por defecto para eventos que no son solicitudes de compra (COMPRA, VENTA, PROFORMA, etc.).',  es_defecto: true },
};

// ==========================================
// TIPO MONEDA
export enum TipoMoneda {
    BOLIVIANO = 2300,
    DOLAR = 2301,
    EURO = 2302,
    UFV = 2303,
}

export const TIPO_MONEDA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoMoneda.BOLIVIANO]: { id: TipoMoneda.BOLIVIANO, abreviatura: 'BOLIVIANO', prefijo: 'BOB', valor: 1, descripcion: 'Boliviano (Bs.). Moneda oficial de Bolivia. Utilizada como moneda base del sistema para todas las transacciones locales, facturación y reportes financieros. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoMoneda.DOLAR]: { id: TipoMoneda.DOLAR, abreviatura: 'DOLAR', prefijo: 'USD', valor: 2, descripcion: 'Dólar estadounidense ($). Moneda de referencia internacional. Utilizada para transacciones con proveedores internacionales, precios de referencia y operaciones en moneda extranjera.' },
    [TipoMoneda.EURO]: { id: TipoMoneda.EURO, abreviatura: 'EURO', prefijo: 'EUR', valor: 3, descripcion: 'Euro (€). Moneda oficial de la Unión Europea. Utilizada para transacciones con proveedores europeos y operaciones internacionales en esta moneda.' },
    [TipoMoneda.UFV]: { id: TipoMoneda.UFV, abreviatura: 'UFV', prefijo: 'UFV', valor: 4, descripcion: 'Unidad de Fomento a la Vivienda. Unidad de cuenta indexada a la inflación en Bolivia. Utilizada para contratos de largo plazo, ajustes de precios y operaciones indexadas.' },
};

// ==========================================
// TIPO FACTURA
export enum TipoFactura {
    CON_FACTURA = 2350,
    SIN_FACTURA = 2351,
    NOTA_CREDITO_DEBITO = 2352,
    NINGUNO = 2353,
}

export const TIPO_FACTURA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoFactura.CON_FACTURA]: { id: TipoFactura.CON_FACTURA, abreviatura: 'CON_FACTURA', prefijo: 'CF', valor: 1, descripcion: 'Factura con derecho a crédito fiscal. Documento fiscal válido ante el SIN que permite al comprador descontar el IVA pagado. Requiere NIT del cliente y dosificación fiscal activa. Aplica para ventas a empresas e instituciones.' },
    [TipoFactura.SIN_FACTURA]: { id: TipoFactura.SIN_FACTURA, abreviatura: 'SIN_FACTURA', prefijo: 'SF', valor: 2, descripcion: 'Factura sin derecho a crédito fiscal. Documento fiscal válido ante el SIN que NO permite descontar el IVA. Utilizado para ventas a consumidor final o cuando el cliente no requiere crédito fiscal.' },
    [TipoFactura.NOTA_CREDITO_DEBITO]: { id: TipoFactura.NOTA_CREDITO_DEBITO, abreviatura: 'NOTA_CREDITO_DEBITO', prefijo: 'NCD', valor: 3, descripcion: 'Nota de crédito o débito para ajustes, devoluciones o correcciones de facturas previamente emitidas. Afecta los saldos fiscales y contables de la transacción original.' },
    [TipoFactura.NINGUNO]: { id: TipoFactura.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 4, descripcion: 'Sin tipo de factura definido. Valor por defecto para transacciones que no requieren facturación fiscal, como proformas, ajustes de inventario o traspasos internos. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO FINANCIERO
export enum EstadoFinanciero {
    CANCELADO = 2400,
    PENDIENTE = 2401,
    PARCIAL = 2402,
    NINGUNO = 2403,
}

export const ESTADO_FINANCIERO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoFinanciero.CANCELADO]: { id: EstadoFinanciero.CANCELADO, abreviatura: 'CANCELADO', prefijo: null, valor: 0, descripcion: 'Transacción totalmente liquidada. El saldo pendiente es cero. Aplica para compras a proveedores totalmente pagadas o ventas al contado. No requiere acciones adicionales.' },
    [EstadoFinanciero.PENDIENTE]: { id: EstadoFinanciero.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Transacción sin abonos registrados. El saldo pendiente es igual al monto total. Aplica para compras a crédito donde aún no se ha realizado ningún pago.' },
    [EstadoFinanciero.PARCIAL]: { id: EstadoFinanciero.PARCIAL, abreviatura: 'PARCIAL', prefijo: null, valor: 0, descripcion: 'Transacción con abonos parciales registrados. El saldo pendiente es menor al monto total pero mayor a cero. Aplica para compras a crédito con pagos fraccionados.' },
    [EstadoFinanciero.NINGUNO]: { id: EstadoFinanciero.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado financiero definido. Valor por defecto para transacciones que no generan obligación financiera, como proformas, ajustes de inventario o movimientos internos. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// MOTIVO ANULACION
export enum MotivoAnulacion {
    FACTURA_MAL_EMITIDA = 2450,
    ERROR_DATOS_CLIENTE = 2451,
    DEVOLUCION_MERCADERIA = 2452,
    CONTINGENCIA = 2453,
    OPERACION_NO_CONCRETADA = 2454,
    NINGUNO = 2455,
}

export const MOTIVO_ANULACION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [MotivoAnulacion.FACTURA_MAL_EMITIDA]: { id: MotivoAnulacion.FACTURA_MAL_EMITIDA, abreviatura: 'FACTURA_MAL_EMITIDA', prefijo: 'FME', valor: 1, descripcion: 'Anulación por error en la emisión de la factura. Incluye errores en montos, productos, cantidades o datos fiscales. Requiere justificación detallada y autorización. Aplica para correcciones antes de notificar al SIN.' },
    [MotivoAnulacion.ERROR_DATOS_CLIENTE]: { id: MotivoAnulacion.ERROR_DATOS_CLIENTE, abreviatura: 'ERROR_DATOS_CLIENTE', prefijo: 'EDC', valor: 2, descripcion: 'Anulación por error en los datos del cliente. Incluye NIT incorrecto, razón social errónea o documento de identidad inválido. Aplica cuando la factura fue emitida con información fiscal incorrecta.' },
    [MotivoAnulacion.DEVOLUCION_MERCADERIA]: { id: MotivoAnulacion.DEVOLUCION_MERCADERIA, abreviatura: 'DEVOLUCION_MERCADERIA', prefijo: 'DM', valor: 3, descripcion: 'Anulación por devolución de mercadería por parte del cliente. Revierte el stock y el valor de la transacción. Aplica para ventas anuladas por productos defectuosos, vencidos o devoluciones voluntarias.' },
    [MotivoAnulacion.CONTINGENCIA]: { id: MotivoAnulacion.CONTINGENCIA, abreviatura: 'CONTINGENCIA', prefijo: 'CON', valor: 4, descripcion: 'Anulación por contingencia operativa o técnica. Incluye fallos en el sistema de facturación, problemas de conectividad con el SIN o situaciones excepcionales. Requiere documentación de respaldo.' },
    [MotivoAnulacion.OPERACION_NO_CONCRETADA]: { id: MotivoAnulacion.OPERACION_NO_CONCRETADA, abreviatura: 'OPERACION_NO_CONCRETADA', prefijo: 'ONC', valor: 5, descripcion: 'Anulación por operación que no se concretó. Incluye ventas abortadas, clientes que no completaron el pago o transacciones canceladas por acuerdo mutuo. No afecta stock si no hubo despacho.' },
    [MotivoAnulacion.NINGUNO]: { id: MotivoAnulacion.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin motivo de anulación definido. Valor por defecto para casos donde no se requiere justificación o cuando la anulación es automática por sistema (ej. expiración de reservas). CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO LOTE
export enum EstadoLote {
    VIGENTE = 2500,
    VENCIDO = 2501,
    AGOTADO = 2502,
    NINGUNO = 2503,
}

export const ESTADO_LOTE_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoLote.VIGENTE]: { id: EstadoLote.VIGENTE, abreviatura: 'VIGENTE', prefijo: null, valor: 0, descripcion: 'Lote con producto en buen estado y dentro de su fecha de vencimiento. Disponible para venta y despacho. Estado operativo normal del lote.' },
    [EstadoLote.VENCIDO]: { id: EstadoLote.VENCIDO, abreviatura: 'VENCIDO', prefijo: null, valor: 0, descripcion: 'Lote cuya fecha de vencimiento ha sido superada. No disponible para venta ni despacho. Requiere gestión de baja o devolución. Se excluye automáticamente de transacciones de venta.' },
    [EstadoLote.AGOTADO]: { id: EstadoLote.AGOTADO, abreviatura: 'AGOTADO', prefijo: null, valor: 0, descripcion: 'Lote con cantidad_actual igual a cero. No disponible para venta. Permanece en histórico para trazabilidad pero ya no tiene stock físico. Puede reactivarse solo mediante ajuste de inventario.' },
    [EstadoLote.NINGUNO]: { id: EstadoLote.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado de lote definido. Valor por defecto para el registro comodín o casos excepcionales donde no se requiere clasificación de estado. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO PAGO
export enum EstadoPago {
    PENDIENTE = 2550,
    PARCIAL = 2551,
    PAGADO = 2552,
    CERRADO = 2553,
    EN_VERIFICACION = 2554,
    NINGUNO = 2555,
}

export const ESTADO_PAGO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoPago.PENDIENTE]: { id: EstadoPago.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Estado de pago pendiente' },
    [EstadoPago.PARCIAL]: { id: EstadoPago.PARCIAL, abreviatura: 'PARCIAL', prefijo: null, valor: 0, descripcion: 'Estado de pago parcial' },
    [EstadoPago.PAGADO]: { id: EstadoPago.PAGADO, abreviatura: 'PAGADO', prefijo: null, valor: 0, descripcion: 'Estado de pago pagado' },
    [EstadoPago.CERRADO]: { id: EstadoPago.CERRADO, abreviatura: 'CERRADO', prefijo: null, valor: 0, descripcion: 'Estado de pago cerrado' },
    [EstadoPago.EN_VERIFICACION]: { id: EstadoPago.EN_VERIFICACION, abreviatura: 'EN_VERIFICACION', prefijo: null, valor: 0, descripcion: 'Pago en proceso de verificación bancaria' },
    [EstadoPago.NINGUNO]: { id: EstadoPago.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado de pago definido. Valor por defecto para registros comodín o cuando no aplica un estado específico. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO MOVIMIENTO
export enum TipoMovimiento {
    INGRESO = 2600,
    EGRESO = 2601,
}

export const TIPO_MOVIMIENTO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoMovimiento.INGRESO]: { id: TipoMovimiento.INGRESO, abreviatura: 'INGRESO', prefijo: null, valor: 0, descripcion: 'Movimiento que incrementa el saldo de caja. Aplica para cobros, ventas, depósitos, devoluciones de clientes y cualquier entrada de dinero. Aumenta el monto_ingresos de la caja. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoMovimiento.EGRESO]: { id: TipoMovimiento.EGRESO, abreviatura: 'EGRESO', prefijo: null, valor: 0, descripcion: 'Movimiento que disminuye el saldo de caja. Aplica para pagos, compras, retiros, devoluciones a proveedores y cualquier salida de dinero. Aumenta el monto_egresos de la caja.' },
};

// ==========================================
// ESTADO CAJA
export enum EstadoCaja {
    ABIERTA = 2650,
    CERRADA = 2651,
}

export const ESTADO_CAJA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoCaja.ABIERTA]: { id: EstadoCaja.ABIERTA, abreviatura: 'ABIERTA', prefijo: null, valor: 0, descripcion: 'Caja operativa y disponible para recibir transacciones. Permite registrar ventas, cobros, pagos y movimientos de efectivo. Estado activo durante la jornada laboral. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoCaja.CERRADA]: { id: EstadoCaja.CERRADA, abreviatura: 'CERRADA', prefijo: null, valor: 0, descripcion: 'Caja finalizada y cerrada. No permite registrar nuevas transacciones. Requiere arqueo físico y conciliación de montos. Estado final de la jornada.' },
};

// ==========================================
// TIPO ALERTA NOTIFICACION
export enum TipoAlertaNotificacion {
    SISTEMA = 2700,
    ALERTA_STOCK = 2701,
    STOCK_BAJO = 2702,
    STOCK_CRITICO = 2703,
    STOCK_EXCESO = 2704,
    VENCIMIENTO_PROXIMO = 2705,
    VENCIMIENTO_INMEDIATO = 2706,
    VENCIMIENTO_VENCIDO = 2707,
    DEMANDA_ALTA = 2708,
    DEMANDA_BAJA = 2709,
    TENDENCIA_ANOMALA = 2710,
    PREDICCION_ROP = 2711,
    PREDICCION_DEMANDA = 2712,
    FORECASTING = 2713,
    PAGOS = 2714,
    PAGO_VENCIDO = 2715,
    PAGO_PROXIMO = 2716,
    DOCUMENTOS = 2717,
    FACTURA_PENDIENTE = 2718,
    FACTURA_ANULADA = 2719,
    SEGURIDAD_ACCESO = 2720,
    SEGURIDAD_INTENTO_FALLIDO = 2721,
    SISTEMA_ERROR = 2722,
    SISTEMA_RENDIMIENTO = 2723,
    NINGUNO = 2724,
    RRHH_FALTAS = 2725,
    RRHH_CONTRATO = 2726,
    RRHH_PLANILLA = 2727,
}

export const TIPO_ALERTA_NOTIFICACION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoAlertaNotificacion.SISTEMA]: { id: TipoAlertaNotificacion.SISTEMA, abreviatura: 'SISTEMA', prefijo: null, valor: 0, descripcion: 'Alerta general del sistema. Notificaciones sobre eventos operativos, mantenimiento programado o cambios en la configuración. Origen: sistema.' },
    [TipoAlertaNotificacion.ALERTA_STOCK]: { id: TipoAlertaNotificacion.ALERTA_STOCK, abreviatura: 'ALERTA_STOCK', prefijo: null, valor: 0, descripcion: 'Alerta relacionada con niveles de inventario. Agrupa todas las notificaciones de stock bajo, crítico o excesivo. Origen: sistema/IA.' },
    [TipoAlertaNotificacion.STOCK_BAJO]: { id: TipoAlertaNotificacion.STOCK_BAJO, abreviatura: 'STOCK_BAJO', prefijo: null, valor: 0, descripcion: 'Alerta por stock bajo. El inventario ha caído por debajo del punto de reorden. Requiere evaluación de reposición. Acción: generar orden de compra.' },
    [TipoAlertaNotificacion.STOCK_CRITICO]: { id: TipoAlertaNotificacion.STOCK_CRITICO, abreviatura: 'STOCK_CRITICO', prefijo: null, valor: 0, descripcion: 'Alerta por stock crítico. El inventario está por debajo del stock mínimo de seguridad. Riesgo de quiebre inminente. Acción: compra urgente o traspaso.' },
    [TipoAlertaNotificacion.STOCK_EXCESO]: { id: TipoAlertaNotificacion.STOCK_EXCESO, abreviatura: 'STOCK_EXCESO', prefijo: null, valor: 0, descripcion: 'Alerta por exceso de stock. El inventario supera el stock máximo permitido. Riesgo de sobre-inversión y vencimientos. Acción: revisar compras y promocionar salida.' },
    [TipoAlertaNotificacion.VENCIMIENTO_PROXIMO]: { id: TipoAlertaNotificacion.VENCIMIENTO_PROXIMO, abreviatura: 'VENCIMIENTO_PROXIMO', prefijo: null, valor: 0, descripcion: 'Alerta por vencimiento próximo (30-60 días). Productos que caducarán en el mediano plazo. Acción: planificar promociones o devoluciones.' },
    [TipoAlertaNotificacion.VENCIMIENTO_INMEDIATO]: { id: TipoAlertaNotificacion.VENCIMIENTO_INMEDIATO, abreviatura: 'VENCIMIENTO_INMEDIATO', prefijo: null, valor: 0, descripcion: 'Alerta por vencimiento inmediato (menos de 30 días). Productos que caducarán pronto. Acción: priorizar venta, promociones agresivas o gestionar devolución.' },
    [TipoAlertaNotificacion.VENCIMIENTO_VENCIDO]: { id: TipoAlertaNotificacion.VENCIMIENTO_VENCIDO, abreviatura: 'VENCIMIENTO_VENCIDO', prefijo: null, valor: 0, descripcion: 'Alerta por producto vencido. Lotes que han superado su fecha de vencimiento. Acción: dar de baja, gestionar devolución o disposición final.' },
    [TipoAlertaNotificacion.DEMANDA_ALTA]: { id: TipoAlertaNotificacion.DEMANDA_ALTA, abreviatura: 'DEMANDA_ALTA', prefijo: null, valor: 0, descripcion: 'Alerta por demanda alta inusual. Incremento significativo en ventas que podría generar quiebre de stock. Acción: evaluar reposición anticipada. Origen: IA.' },
    [TipoAlertaNotificacion.DEMANDA_BAJA]: { id: TipoAlertaNotificacion.DEMANDA_BAJA, abreviatura: 'DEMANDA_BAJA', prefijo: null, valor: 0, descripcion: 'Alerta por demanda baja inusual. Caída significativa en ventas que podría indicar problemas de mercado. Acción: revisar precios o promociones. Origen: IA.' },
    [TipoAlertaNotificacion.TENDENCIA_ANOMALA]: { id: TipoAlertaNotificacion.TENDENCIA_ANOMALA, abreviatura: 'TENDENCIA_ANOMALA', prefijo: null, valor: 0, descripcion: 'Alerta por tendencia anómala detectada. Comportamiento inusual en patrones de consumo que no corresponde a estacionalidad esperada. Acción: investigar causa. Origen: IA.' },
    [TipoAlertaNotificacion.PREDICCION_ROP]: { id: TipoAlertaNotificacion.PREDICCION_ROP, abreviatura: 'PREDICCION_ROP', prefijo: null, valor: 0, descripcion: 'Alerta sobre punto de reorden (ROP) calculado. Actualización del nivel óptimo de reorden basado en nuevas predicciones. Acción: revisar configuración de umbrales. Origen: IA.' },
    [TipoAlertaNotificacion.PREDICCION_DEMANDA]: { id: TipoAlertaNotificacion.PREDICCION_DEMANDA, abreviatura: 'PREDICCION_DEMANDA', prefijo: null, valor: 0, descripcion: 'Alerta sobre predicción de demanda. Resultados del pronóstico disponibles para revisión. Acción: revisar proyecciones en dashboard. Origen: IA.' },
    [TipoAlertaNotificacion.FORECASTING]: { id: TipoAlertaNotificacion.FORECASTING, abreviatura: 'FORECASTING', prefijo: null, valor: 0, descripcion: 'Alerta sobre resultados de forecasting. Actualización de proyecciones de ventas y tendencias. Acción: revisar reportes de pronóstico. Origen: IA.' },
    [TipoAlertaNotificacion.PAGOS]: { id: TipoAlertaNotificacion.PAGOS, abreviatura: 'PAGOS', prefijo: null, valor: 0, descripcion: 'Alerta relacionada con pagos y cuentas por cobrar/pagar. Agrupa notificaciones de vencimientos y estados de pago. Origen: sistema.' },
    [TipoAlertaNotificacion.PAGO_VENCIDO]: { id: TipoAlertaNotificacion.PAGO_VENCIDO, abreviatura: 'PAGO_VENCIDO', prefijo: null, valor: 0, descripcion: 'Alerta por pago vencido. Cuota o factura con fecha de vencimiento superada sin pago registrado. Acción: gestionar cobranza o aplicar multas. Origen: sistema.' },
    [TipoAlertaNotificacion.PAGO_PROXIMO]: { id: TipoAlertaNotificacion.PAGO_PROXIMO, abreviatura: 'PAGO_PROXIMO', prefijo: null, valor: 0, descripcion: 'Alerta por pago próximo. Cuota o factura que vence en los próximos días (según configuración). Acción: preparar pago o notificar al cliente. Origen: sistema.' },
    [TipoAlertaNotificacion.DOCUMENTOS]: { id: TipoAlertaNotificacion.DOCUMENTOS, abreviatura: 'DOCUMENTOS', prefijo: null, valor: 0, descripcion: 'Alerta relacionada con documentos fiscales y administrativos. Agrupa notificaciones sobre facturas y comprobantes. Origen: sistema.' },
    [TipoAlertaNotificacion.FACTURA_PENDIENTE]: { id: TipoAlertaNotificacion.FACTURA_PENDIENTE, abreviatura: 'FACTURA_PENDIENTE', prefijo: null, valor: 0, descripcion: 'Alerta por factura pendiente de emisión o envío. Documentos fiscales que requieren atención. Acción: completar facturación. Origen: sistema.' },
    [TipoAlertaNotificacion.FACTURA_ANULADA]: { id: TipoAlertaNotificacion.FACTURA_ANULADA, abreviatura: 'FACTURA_ANULADA', prefijo: null, valor: 0, descripcion: 'Alerta por factura anulada. Notificación de anulación de documento fiscal. Acción: verificar motivo y documentar. Origen: sistema.' },
    [TipoAlertaNotificacion.SEGURIDAD_ACCESO]: { id: TipoAlertaNotificacion.SEGURIDAD_ACCESO, abreviatura: 'SEGURIDAD_ACCESO', prefijo: null, valor: 0, descripcion: 'Alerta por evento de seguridad de acceso. Incluye inicios de sesión desde ubicaciones desconocidas o fuera de horario. Acción: verificar actividad sospechosa. Origen: sistema.' },
    [TipoAlertaNotificacion.SEGURIDAD_INTENTO_FALLIDO]: { id: TipoAlertaNotificacion.SEGURIDAD_INTENTO_FALLIDO, abreviatura: 'SEGURIDAD_INTENTO_FALLIDO', prefijo: null, valor: 0, descripcion: 'Alerta por intentos fallidos de acceso. Múltiples fallos en autenticación que podrían indicar ataque de fuerza bruta. Acción: bloquear usuario o IP. Origen: sistema.' },
    [TipoAlertaNotificacion.SISTEMA_ERROR]: { id: TipoAlertaNotificacion.SISTEMA_ERROR, abreviatura: 'SISTEMA_ERROR', prefijo: null, valor: 0, descripcion: 'Alerta por error crítico del sistema. Fallos en procesos, servicios o integraciones que requieren intervención técnica. Acción: revisar logs y solucionar. Origen: sistema.' },
    [TipoAlertaNotificacion.SISTEMA_RENDIMIENTO]: { id: TipoAlertaNotificacion.SISTEMA_RENDIMIENTO, abreviatura: 'SISTEMA_RENDIMIENTO', prefijo: null, valor: 0, descripcion: 'Alerta por problemas de rendimiento del sistema. Tiempos de respuesta elevados, uso excesivo de recursos o cuellos de botella. Acción: optimizar o escalar recursos. Origen: sistema.' },
    [TipoAlertaNotificacion.NINGUNO]: { id: TipoAlertaNotificacion.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin tipo de alerta definido. Valor por defecto para registros comodín o casos donde no se requiere clasificación de alerta. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoAlertaNotificacion.RRHH_FALTAS]: { id: TipoAlertaNotificacion.RRHH_FALTAS, abreviatura: 'RRHH_FALTAS', prefijo: null, valor: 0, descripcion: 'Alerta por faltas consecutivas del trabajador. Acción: contactar al trabajador.' },
    [TipoAlertaNotificacion.RRHH_CONTRATO]: { id: TipoAlertaNotificacion.RRHH_CONTRATO, abreviatura: 'RRHH_CONTRATO', prefijo: null, valor: 0, descripcion: 'Alerta por vencimiento de contrato. Acción: gestionar renovación.' },
    [TipoAlertaNotificacion.RRHH_PLANILLA]: { id: TipoAlertaNotificacion.RRHH_PLANILLA, abreviatura: 'RRHH_PLANILLA', prefijo: null, valor: 0, descripcion: 'Alerta relacionada con planillas de sueldos. Acción: revisar estado de planilla.' },
};

// ==========================================
// AMBIENTE
export enum Ambiente {
    PRODUCCION = 2750,
    PILOTO_PRUEBAS = 2751,
}

export const AMBIENTE_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Ambiente.PRODUCCION]: { id: Ambiente.PRODUCCION, abreviatura: 'PRODUCCION', prefijo: null, valor: 1, descripcion: 'Ambiente del sistema en producción.' },
    [Ambiente.PILOTO_PRUEBAS]: { id: Ambiente.PILOTO_PRUEBAS, abreviatura: 'PILOTO_PRUEBAS', prefijo: null, valor: 2, descripcion: 'Ambiente del sistema en piloto ó pruebas. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// SUBTIPO ALERTA
export enum SubtipoAlerta {
    SARIMA = 2800,
    PROPHET = 2801,
    KMEANS = 2802,
    ROP_CALC = 2803,
    PATRON_CONSUMO = 2804,
    ALERTA_PREDICTIVA = 2805,
    QUIEBRE_STOCK = 2806,
    REORDEN = 2807,
    EXCESO = 2808,
    CADUCIDAD_CRITICA = 2809,
    CADUCIDAD_ALTA = 2810,
    CADUCIDAD_MEDIA = 2811,
    NINGUNO = 2812,
}

export const SUBTIPO_ALERTA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [SubtipoAlerta.SARIMA]: { id: SubtipoAlerta.SARIMA, abreviatura: 'SARIMA', prefijo: null, valor: 0, descripcion: 'Subtipo SARIMA', es_defecto: true },
    [SubtipoAlerta.PROPHET]: { id: SubtipoAlerta.PROPHET, abreviatura: 'PROPHET', prefijo: null, valor: 0, descripcion: 'Subtipo PROPHET' },
    [SubtipoAlerta.KMEANS]: { id: SubtipoAlerta.KMEANS, abreviatura: 'KMEANS', prefijo: null, valor: 0, descripcion: 'Subtipo KMEANS' },
    [SubtipoAlerta.ROP_CALC]: { id: SubtipoAlerta.ROP_CALC, abreviatura: 'ROP_CALC', prefijo: null, valor: 0, descripcion: 'Subtipo ROP_CALC' },
    [SubtipoAlerta.PATRON_CONSUMO]: { id: SubtipoAlerta.PATRON_CONSUMO, abreviatura: 'PATRON_CONSUMO', prefijo: null, valor: 0, descripcion: 'Subtipo PATRON_CONSUMO' },
    [SubtipoAlerta.ALERTA_PREDICTIVA]: { id: SubtipoAlerta.ALERTA_PREDICTIVA, abreviatura: 'ALERTA_PREDICTIVA', prefijo: null, valor: 0, descripcion: 'Subtipo ALERTA_PREDICTIVA' },
    [SubtipoAlerta.QUIEBRE_STOCK]: { id: SubtipoAlerta.QUIEBRE_STOCK, abreviatura: 'QUIEBRE_STOCK', prefijo: null, valor: 0, descripcion: 'Subtipo QUIEBRE_STOCK' },
    [SubtipoAlerta.REORDEN]: { id: SubtipoAlerta.REORDEN, abreviatura: 'REORDEN', prefijo: null, valor: 0, descripcion: 'Subtipo REORDEN' },
    [SubtipoAlerta.EXCESO]: { id: SubtipoAlerta.EXCESO, abreviatura: 'EXCESO', prefijo: null, valor: 0, descripcion: 'Subtipo EXCESO' },
    [SubtipoAlerta.CADUCIDAD_CRITICA]: { id: SubtipoAlerta.CADUCIDAD_CRITICA, abreviatura: 'CADUCIDAD_CRITICA', prefijo: null, valor: 0, descripcion: 'Subtipo CADUCIDAD_CRITICA' },
    [SubtipoAlerta.CADUCIDAD_ALTA]: { id: SubtipoAlerta.CADUCIDAD_ALTA, abreviatura: 'CADUCIDAD_ALTA', prefijo: null, valor: 0, descripcion: 'Subtipo CADUCIDAD_ALTA' },
    [SubtipoAlerta.CADUCIDAD_MEDIA]: { id: SubtipoAlerta.CADUCIDAD_MEDIA, abreviatura: 'CADUCIDAD_MEDIA', prefijo: null, valor: 0, descripcion: 'Subtipo CADUCIDAD_MEDIA' },
    [SubtipoAlerta.NINGUNO]: { id: SubtipoAlerta.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin subtipo de alerta definido o no aplica. CONSTANTE POR DEFECTO.' },
};

// ==========================================
// ORIGEN ALERTA
export enum OrigenAlerta {
    SISTEMA = 2850,
    IA = 2851,
    USUARIO = 2852,
    TAREA_PROGRAMADA = 2853,
}

export const ORIGEN_ALERTA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [OrigenAlerta.SISTEMA]: { id: OrigenAlerta.SISTEMA, abreviatura: 'SISTEMA', prefijo: null, valor: 0, descripcion: 'Alerta generada por el sistema operativo o módulos internos. Incluye eventos de seguridad, errores de procesos y notificaciones automáticas. Origen más común. CONSTANTE POR DEFECTO.', es_defecto: true },
    [OrigenAlerta.IA]: { id: OrigenAlerta.IA, abreviatura: 'IA', prefijo: null, valor: 0, descripcion: 'Alerta generada por el motor de Inteligencia Artificial. Incluye predicciones de demanda, detección de anomalías y análisis de tendencias. Basada en modelos de aprendizaje automático.' },
    [OrigenAlerta.USUARIO]: { id: OrigenAlerta.USUARIO, abreviatura: 'USUARIO', prefijo: null, valor: 0, descripcion: 'Alerta generada manualmente por un usuario del sistema. Incluye reportes de incidencias, solicitudes de revisión o notificaciones creadas por operadores.' },
    [OrigenAlerta.TAREA_PROGRAMADA]: { id: OrigenAlerta.TAREA_PROGRAMADA, abreviatura: 'TAREA_PROGRAMADA', prefijo: null, valor: 0, descripcion: 'Alerta generada por tareas programadas automáticas. Incluye resultados de procesos batch, ejecución de jobs y monitoreo periódico. Ejecutada según frecuencia configurada.' },
};

// ==========================================
// NIVEL CRITICO
export enum NivelCritico {
    CRITICO = 2900,
    ALTA = 2901,
    MEDIA = 2902,
    BAJA = 2903,
    INFORMATIVA = 2904,
    NINGUNO = 2905,
}

export const NIVEL_CRITICO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [NivelCritico.CRITICO]: { id: NivelCritico.CRITICO, abreviatura: 'CRITICO', prefijo: null, valor: 0, descripcion: 'Nivel crítico. Impacto máximo en operaciones. Requiere acción inmediata. Aplica para quiebre de stock de medicamentos esenciales, fallos de seguridad o errores que detienen el sistema.' },
    [NivelCritico.ALTA]: { id: NivelCritico.ALTA, abreviatura: 'ALTA', prefijo: null, valor: 0, descripcion: 'Nivel alto de criticidad. Impacto significativo en operaciones. Requiere atención prioritaria en el corto plazo. Aplica para vencimientos inminentes o desviaciones importantes.' },
    [NivelCritico.MEDIA]: { id: NivelCritico.MEDIA, abreviatura: 'MEDIA', prefijo: null, valor: 0, descripcion: 'Nivel medio de criticidad. Impacto moderado en operaciones. Requiere atención planificada. Aplica para stock bajo, alertas de rendimiento o desviaciones menores.' },
    [NivelCritico.BAJA]: { id: NivelCritico.BAJA, abreviatura: 'BAJA', prefijo: null, valor: 0, descripcion: 'Nivel bajo de criticidad. Impacto mínimo en operaciones. Requiere monitoreo sin acción inmediata. Aplica para alertas informativas o seguimiento de tendencias.' },
    [NivelCritico.INFORMATIVA]: { id: NivelCritico.INFORMATIVA, abreviatura: 'INFORMATIVA', prefijo: null, valor: 0, descripcion: 'Nivel informativo. No representa una criticidad operativa. Solo proporciona información para conocimiento del usuario. Aplica para notificaciones de sistema y reportes.' },
    [NivelCritico.NINGUNO]: { id: NivelCritico.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin nivel crítico definido. Valor por defecto para casos donde no aplica clasificación de criticidad. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO ALERTA
export enum EstadoAlerta {
    PENDIENTE = 2950,
    EN_PROCESO = 2951,
    RESUELTA = 2952,
    IGNORADA = 2953,
    ESCALADA = 2954,
    NINGUNO = 2955,
}

export const ESTADO_ALERTA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoAlerta.PENDIENTE]: { id: EstadoAlerta.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Alerta pendiente de atención. No se ha iniciado ningún proceso de resolución. Estado inicial de toda alerta. Requiere asignación de responsable.' },
    [EstadoAlerta.EN_PROCESO]: { id: EstadoAlerta.EN_PROCESO, abreviatura: 'EN_PROCESO', prefijo: null, valor: 0, descripcion: 'Alerta en proceso de resolución. Se ha asignado responsable y se están tomando acciones. La investigación o corrección está en curso. Requiere seguimiento activo.' },
    [EstadoAlerta.RESUELTA]: { id: EstadoAlerta.RESUELTA, abreviatura: 'RESUELTA', prefijo: null, valor: 0, descripcion: 'Alerta resuelta completamente. La causa ha sido identificada y corregida. No requiere acciones adicionales. Estado final exitoso de la alerta.' },
    [EstadoAlerta.IGNORADA]: { id: EstadoAlerta.IGNORADA, abreviatura: 'IGNORADA', prefijo: null, valor: 0, descripcion: 'Alerta ignorada. Se ha decidido no tomar acción por considerarse no relevante o de bajo impacto. Requiere justificación documentada. Estado final sin resolución.' },
    [EstadoAlerta.ESCALADA]: { id: EstadoAlerta.ESCALADA, abreviatura: 'ESCALADA', prefijo: null, valor: 0, descripcion: 'Alerta escalada a nivel superior. No pudo ser resuelta en el nivel actual y requiere intervención de gerencia o soporte especializado. Requiere seguimiento priorizado.' },
    [EstadoAlerta.NINGUNO]: { id: EstadoAlerta.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado de alerta definido. Valor por defecto para registros comodín o cuando no aplica clasificación de estado de alerta. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// FRAMEWORK
export enum Framework {
    STATSMODELS = 3000,
    SCIKIT_LEARN = 3001,
    TENSORFLOW = 3002,
    CUSTOM = 3003,
    NINGUNO = 3004,
}

export const FRAMEWORK_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Framework.STATSMODELS]: { id: Framework.STATSMODELS, abreviatura: 'STATSMODELS', prefijo: null, valor: 0, descripcion: 'Framework estadístico para modelos de series temporales y econometría. Ideal para ARIMA, SARIMA y modelos lineales. Compatible con Python.' },
    [Framework.SCIKIT_LEARN]: { id: Framework.SCIKIT_LEARN, abreviatura: 'SCIKIT_LEARN', prefijo: null, valor: 0, descripcion: 'Framework de aprendizaje automático para clasificación, regresión y clustering. Incluye K-Means, Random Forest y SVM. Compatible con Python.' },
    [Framework.TENSORFLOW]: { id: Framework.TENSORFLOW, abreviatura: 'TENSORFLOW', prefijo: null, valor: 0, descripcion: 'Framework de deep learning para redes neuronales y modelos avanzados. Incluye LSTM, CNN y Transformers. Compatible con Python.' },
    [Framework.CUSTOM]: { id: Framework.CUSTOM, abreviatura: 'CUSTOM', prefijo: null, valor: 0, descripcion: 'Framework personalizado o propietario. Desarrollado específicamente para necesidades particulares del sistema. No es un framework estándar.' },
    [Framework.NINGUNO]: { id: Framework.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin framework definido. Valor por defecto para modelos que no utilizan un framework específico o cuando no aplica. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// ESTADO EJECUCION
export enum EstadoEjecucion {
    EN_PROCESO = 3050,
    COMPLETADO = 3051,
    FALLIDO = 3052,
    NINGUNO = 3053,
}

export const ESTADO_EJECUCION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoEjecucion.EN_PROCESO]: { id: EstadoEjecucion.EN_PROCESO, abreviatura: 'EN_PROCESO', prefijo: null, valor: 0, descripcion: 'Ejecución en curso. El proceso está activo y en ejecución. No hay resultados disponibles hasta su finalización. Aplica para entrenamientos de IA y procesos batch.' },
    [EstadoEjecucion.COMPLETADO]: { id: EstadoEjecucion.COMPLETADO, abreviatura: 'COMPLETADO', prefijo: null, valor: 0, descripcion: 'Ejecución finalizada exitosamente. El proceso ha concluido sin errores. Los resultados están disponibles para su uso. Aplica para tareas programadas y entrenamientos exitosos.' },
    [EstadoEjecucion.FALLIDO]: { id: EstadoEjecucion.FALLIDO, abreviatura: 'FALLIDO', prefijo: null, valor: 0, descripcion: 'Ejecución fallida. El proceso ha terminado con errores. Requiere revisión de logs para identificar la causa. Aplica para entrenamientos fallidos y tareas con errores.' },
    [EstadoEjecucion.NINGUNO]: { id: EstadoEjecucion.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado de ejecución definido. Valor por defecto para registros comodín o cuando no se ha registrado estado de ejecución. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO METRICAS
export enum TipoMetrica {
    REGRESION = 3100,
    CLASIFICACION = 3101,
    CLUSTERING = 3102,
    NINGUNO = 3103,
}

export const TIPO_METRICA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoMetrica.REGRESION]: { id: TipoMetrica.REGRESION, abreviatura: 'REGRESION', prefijo: null, valor: 0, descripcion: 'Métricas para modelos de regresión. Incluye MAE, RMSE, MAPE, R2 y otras métricas que evalúan la precisión de predicciones numéricas. Aplica para pronósticos de demanda y series temporales.' },
    [TipoMetrica.CLASIFICACION]: { id: TipoMetrica.CLASIFICACION, abreviatura: 'CLASIFICACION', prefijo: null, valor: 0, descripcion: 'Métricas para modelos de clasificación. Incluye F1 Score, precisión, sensibilidad y exactitud. Aplica para segmentación de clientes, clasificación de productos y detección de anomalías.' },
    [TipoMetrica.CLUSTERING]: { id: TipoMetrica.CLUSTERING, abreviatura: 'CLUSTERING', prefijo: null, valor: 0, descripcion: 'Métricas para modelos de clustering. Incluye coeficiente de silueta, índice de Davies-Bouldin y otras métricas de calidad de agrupamiento. Aplica para segmentación ABC y agrupación de datos.' },
    [TipoMetrica.NINGUNO]: { id: TipoMetrica.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin tipo de métrica definido. Valor por defecto para casos donde no se requiere clasificación específica de métricas. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// NIVEL LOG
export enum NivelLog {
    INFO = 3150,
    WARNING = 3151,
    ERROR = 3152,
    DEBUG = 3153,
}

export const NIVEL_LOG_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [NivelLog.INFO]: { id: NivelLog.INFO, abreviatura: 'INFO', prefijo: null, valor: 0, descripcion: 'Log informativo. Registra eventos normales del sistema, procesos exitosos y cambios de estado. No requiere acción. Utilizado para trazabilidad operativa. CONSTANTE POR DEFECTO.', es_defecto: true },
    [NivelLog.WARNING]: { id: NivelLog.WARNING, abreviatura: 'WARNING', prefijo: null, valor: 0, descripcion: 'Log de advertencia. Indica condiciones anormales que no son críticas pero requieren atención. Puede preceder a errores. Requiere monitoreo y posible acción preventiva.' },
    [NivelLog.ERROR]: { id: NivelLog.ERROR, abreviatura: 'ERROR', prefijo: null, valor: 0, descripcion: 'Log de error. Indica fallos en procesos, excepciones o condiciones que impiden la ejecución normal. Requiere acción correctiva inmediata y análisis de causa raíz.' },
    [NivelLog.DEBUG]: { id: NivelLog.DEBUG, abreviatura: 'DEBUG', prefijo: null, valor: 0, descripcion: 'Log de depuración. Registro detallado para desarrollo y diagnóstico. Incluye variables internas, trazas de ejecución y datos de depuración. No debe activarse en producción.' },
};

// ==========================================
// TIPO UBICACION MOVIMIENTO
export enum TipoUbicacionMovimiento {
    INGRESO = 3200,
    EGRESO = 3201,
}

export const TIPO_UBICACION_MOVIMIENTO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoUbicacionMovimiento.INGRESO]: { id: TipoUbicacionMovimiento.INGRESO, abreviatura: 'INGRESO', prefijo: null, valor: 0, descripcion: 'Movimiento que representa la entrada o ingreso físico de productos a una ubicación de almacenamiento (estantería, almacén o depósito). Incrementa el stock_actual de la ubicación de destino. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoUbicacionMovimiento.EGRESO]: { id: TipoUbicacionMovimiento.EGRESO, abreviatura: 'EGRESO', prefijo: null, valor: 0, descripcion: 'Movimiento que representa la salida o egreso físico de productos desde una ubicación de almacenamiento hacia otra área, despacho o proceso. Disminuye el stock_actual de la ubicación de origen.' },
};

// ==========================================
// TIPO UMBRAL
export enum TipoUmbral {
    STOCK_MINIMO = 3250,
    DIAS_VENCIMIENTO = 3251,
    ERROR_PREDICCION = 3252,
    NINGUNO = 3253,
}

export const TIPO_UMBRAL_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoUmbral.STOCK_MINIMO]: { id: TipoUmbral.STOCK_MINIMO, abreviatura: 'STOCK_MINIMO', prefijo: null, valor: 0, descripcion: 'Umbral de stock mínimo. Define el nivel mínimo de inventario permitido para un producto. Cuando el stock cae por debajo de este valor, se activa una alerta de reposición. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoUmbral.DIAS_VENCIMIENTO]: { id: TipoUmbral.DIAS_VENCIMIENTO, abreviatura: 'DIAS_VENCIMIENTO', prefijo: null, valor: 0, descripcion: 'Umbral de días de vencimiento. Define el número de días antes del vencimiento para activar una alerta. Aplica para control de caducidad y planificación de promociones.' },
    [TipoUmbral.ERROR_PREDICCION]: { id: TipoUmbral.ERROR_PREDICCION, abreviatura: 'ERROR_PREDICCION', prefijo: null, valor: 0, descripcion: 'Umbral de error de predicción. Define el porcentaje máximo de error permitido en pronósticos de demanda (MAPE). Si se supera, el modelo se considera rechazado y requiere reentrenamiento.' },
    [TipoUmbral.NINGUNO]: { id: TipoUmbral.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin tipo de umbral definido. Valor por defecto para configuraciones que no requieren clasificación específica de umbral.' },
};

// ==========================================
// ESTADO DOCUMENTO
export enum EstadoDocumento {
    EMITIDO = 3300,
    ANULADO = 3301,
    ANULADO_PARCIAL = 3302,
}

export const ESTADO_DOCUMENTO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoDocumento.EMITIDO]: { id: EstadoDocumento.EMITIDO, abreviatura: 'EMITIDO', prefijo: null, valor: 0, descripcion: 'Documento emitido y vigente. El comprobante fiscal ha sido generado y registrado correctamente. Es válido ante el SIN. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoDocumento.ANULADO]: { id: EstadoDocumento.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Documento anulado completamente. El comprobante fiscal ha sido cancelado en su totalidad. No tiene validez fiscal. Se mantiene en histórico para auditoría.' },
    [EstadoDocumento.ANULADO_PARCIAL]: { id: EstadoDocumento.ANULADO_PARCIAL, abreviatura: 'ANULADO_PARCIAL', prefijo: null, valor: 0, descripcion: 'Documento anulado parcialmente. Solo parte del comprobante fiscal ha sido cancelado (ej. devolución de algunos ítems). Afecta parcialmente la validez fiscal del documento.' },
};

// ==========================================
// FRECUENCIA
export enum Frecuencia {
    MINUTOS = 3350,
    HORAS = 3351,
    DIARIO = 3352,
    SEMANAL = 3353,
    MENSUAL = 3354,
    ANUAL = 3355,
    CRON = 3356,
    CONTINUA = 3357,
    TRIGGER_EVENTO = 3358,
    NINGUNO = 3359,
}

export const FRECUENCIA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Frecuencia.MINUTOS]: { id: Frecuencia.MINUTOS, abreviatura: 'MINUTOS', prefijo: null, valor: 0, descripcion: 'Ejecución programada en intervalos de minutos. Aplica para tareas que requieren monitoreo frecuente o actualizaciones rápidas. Configurable en parametros_globales.' },
    [Frecuencia.HORAS]: { id: Frecuencia.HORAS, abreviatura: 'HORAS', prefijo: null, valor: 0, descripcion: 'Ejecución programada en intervalos de horas. Aplica para tareas de sincronización, actualización de datos o procesos batch cortos.' },
    [Frecuencia.DIARIO]: { id: Frecuencia.DIARIO, abreviatura: 'DIARIO', prefijo: null, valor: 0, descripcion: 'Ejecución programada una vez al día. Aplica para tareas de generación de reportes diarios, respaldos y actualizaciones de inventario. Frecuencia más común.' },
    [Frecuencia.SEMANAL]: { id: Frecuencia.SEMANAL, abreviatura: 'SEMANAL', prefijo: null, valor: 0, descripcion: 'Ejecución programada una vez por semana. Aplica para tareas de consolidación semanal, reportes gerenciales y análisis de tendencias.' },
    [Frecuencia.MENSUAL]: { id: Frecuencia.MENSUAL, abreviatura: 'MENSUAL', prefijo: null, valor: 0, descripcion: 'Ejecución programada una vez al mes. Aplica para tareas de cierre contable, reportes mensuales y análisis de rendimiento de modelos.' },
    [Frecuencia.ANUAL]: { id: Frecuencia.ANUAL, abreviatura: 'ANUAL', prefijo: null, valor: 0, descripcion: 'Ejecución programada una vez al año. Aplica para tareas de cierre fiscal, auditorías anuales y mantenimiento mayor del sistema.' },
    [Frecuencia.CRON]: { id: Frecuencia.CRON, abreviatura: 'CRON', prefijo: null, valor: 0, descripcion: 'Ejecución programada mediante expresión CRON. Permite configuración flexible de fechas y horas. Aplica para tareas con programación compleja o personalizada.' },
    [Frecuencia.CONTINUA]: { id: Frecuencia.CONTINUA, abreviatura: 'CONTINUA', prefijo: null, valor: 0, descripcion: 'Ejecución continua sin interrupción. Aplica para tareas de monitoreo en tiempo real, servicios de background o procesos que requieren ejecución permanente.' },
    [Frecuencia.TRIGGER_EVENTO]: { id: Frecuencia.TRIGGER_EVENTO, abreviatura: 'TRIGGER_EVENTO', prefijo: null, valor: 0, descripcion: 'Ejecución disparada por un evento específico. Aplica para tareas que se activan ante condiciones o acciones particulares (ej. cambio de estado, fin de proceso).' },
    [Frecuencia.NINGUNO]: { id: Frecuencia.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin frecuencia definida. Valor por defecto para tareas que no requieren programación automática o que se ejecutan de forma manual. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO TAREA
export enum TipoTarea {
    REPORTE = 3400,
    IA_MODELO = 3401,
    BACKUP = 3402,
    ALERTA = 3403,
    MANTENIMIENTO = 3404,
    FORECASTING = 3405,
    CLASIFICACION = 3406,
    OPTIMIZACION = 3407,
    VALIDACION = 3408,
    NINGUNO = 3409,
}

export const TIPO_TAREA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoTarea.REPORTE]: { id: TipoTarea.REPORTE, abreviatura: 'REPORTE', prefijo: null, valor: 0, descripcion: 'Tarea de generación de reportes y documentos. Incluye reportes operativos, financieros, de inventario y gerenciales. Puede generar archivos PDF, Excel o CSV.' },
    [TipoTarea.IA_MODELO]: { id: TipoTarea.IA_MODELO, abreviatura: 'IA_MODELO', prefijo: null, valor: 0, descripcion: 'Tarea de ejecución y gestión de modelos de IA. Incluye entrenamiento, predicción y actualización de modelos. Asociada a subtipos específicos de modelos.' },
    [TipoTarea.BACKUP]: { id: TipoTarea.BACKUP, abreviatura: 'BACKUP', prefijo: null, valor: 0, descripcion: 'Tarea de respaldo y copia de seguridad. Incluye backup de base de datos, archivos del sistema y modelos de IA. Programada para ejecución periódica.' },
    [TipoTarea.ALERTA]: { id: TipoTarea.ALERTA, abreviatura: 'ALERTA', prefijo: null, valor: 0, descripcion: 'Tarea de generación y gestión de alertas. Incluye monitoreo de condiciones críticas y envío de notificaciones. Puede ser operativa o predictiva.' },
    [TipoTarea.MANTENIMIENTO]: { id: TipoTarea.MANTENIMIENTO, abreviatura: 'MANTENIMIENTO', prefijo: null, valor: 0, descripcion: 'Tarea de mantenimiento del sistema. Incluye limpieza de logs, archivado de datos y optimización de rendimiento. Ejecución programada o bajo demanda.' },
    [TipoTarea.FORECASTING]: { id: TipoTarea.FORECASTING, abreviatura: 'FORECASTING', prefijo: null, valor: 0, descripcion: 'Tarea de pronóstico y predicción. Incluye modelos ARIMA, SARIMA, Prophet y otros para predicción de demanda. Genera proyecciones futuras.' },
    [TipoTarea.CLASIFICACION]: { id: TipoTarea.CLASIFICACION, abreviatura: 'CLASIFICACION', prefijo: null, valor: 0, descripcion: 'Tarea de clasificación y segmentación. Incluye K-Means, RFM y clustering. Utilizada para clasificación ABC y segmentación de clientes.' },
    [TipoTarea.OPTIMIZACION]: { id: TipoTarea.OPTIMIZACION, abreviatura: 'OPTIMIZACION', prefijo: null, valor: 0, descripcion: 'Tarea de optimización de procesos. Incluye cálculo de ROP, EOQ y niveles óptimos de inventario. Busca minimizar costos y maximizar eficiencia.' },
    [TipoTarea.VALIDACION]: { id: TipoTarea.VALIDACION, abreviatura: 'VALIDACION', prefijo: null, valor: 0, descripcion: 'Tarea de validación y evaluación de modelos. Incluye validación cruzada, comparación de métricas y análisis de rendimiento. Asegura calidad de los modelos.' },
    [TipoTarea.NINGUNO]: { id: TipoTarea.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin tipo de tarea definido. Valor por defecto para tareas no clasificadas o cuando no aplica tipo específico. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// SUBTIPO TAREA
export enum SubtipoTarea {
    SARIMA = 3450,
    SARIMAX = 3451,
    PROPHET = 3452,
    KMEANS = 3453,
    ROP_CALC = 3454,
    PATRON_CONSUMO = 3455,
    ALERTA_PREDICTIVA = 3456,
    VARIABLE_EXOGENA = 3457,
    METRICA_RENDIMIENTO = 3458,
    REENTRENAMIENTO = 3459,
    VALIDACION_CROSS = 3460,
    NINGUNO = 3461,
}

export const SUBTIPO_TAREA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [SubtipoTarea.SARIMA]: { id: SubtipoTarea.SARIMA, abreviatura: 'SARIMA', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de entrenamiento y ejecución del modelo SARIMA (Seasonal ARIMA). Utilizado para pronósticos de demanda con componente estacional. Asociado a TipoTarea: FORECASTING, IA_MODELO.' },
    [SubtipoTarea.SARIMAX]: { id: SubtipoTarea.SARIMAX, abreviatura: 'SARIMAX', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de entrenamiento y ejecución del modelo SARIMAX (SARIMA con variables exógenas). Incorpora factores externos al pronóstico. Asociado a TipoTarea: FORECASTING, IA_MODELO.' },
    [SubtipoTarea.PROPHET]: { id: SubtipoTarea.PROPHET, abreviatura: 'PROPHET', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de entrenamiento y ejecución del modelo Prophet de Meta. Detecta estacionalidades múltiples y días festivos. Asociado a TipoTarea: FORECASTING, IA_MODELO.' },
    [SubtipoTarea.KMEANS]: { id: SubtipoTarea.KMEANS, abreviatura: 'KMEANS', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de clustering y clasificación con K-Means. Utilizado para segmentación ABC de inventario y clasificación de clientes. Asociado a TipoTarea: CLASIFICACION, IA_MODELO.' },
    [SubtipoTarea.ROP_CALC]: { id: SubtipoTarea.ROP_CALC, abreviatura: 'ROP_CALC', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de cálculo de Punto de Reorden (ROP). Determina niveles óptimos de reorden basados en demanda y lead time. Asociado a TipoTarea: OPTIMIZACION, FORECASTING.' },
    [SubtipoTarea.PATRON_CONSUMO]: { id: SubtipoTarea.PATRON_CONSUMO, abreviatura: 'PATRON_CONSUMO', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de detección y análisis de patrones de consumo. Identifica estacionalidades y tendencias en datos históricos. Asociado a TipoTarea: FORECASTING, ANALISIS.' },
    [SubtipoTarea.ALERTA_PREDICTIVA]: { id: SubtipoTarea.ALERTA_PREDICTIVA, abreviatura: 'ALERTA_PREDICTIVA', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de generación de alertas predictivas. Evalúa riesgos futuros basados en modelos de IA. Asociado a TipoTarea: ALERTA, IA_MODELO.' },
    [SubtipoTarea.VARIABLE_EXOGENA]: { id: SubtipoTarea.VARIABLE_EXOGENA, abreviatura: 'VARIABLE_EXOGENA', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de procesamiento y actualización de variables exógenas. Obtiene datos externos (clima, festivos, economía). Asociado a TipoTarea: IA_MODELO, MANTENIMIENTO.' },
    [SubtipoTarea.METRICA_RENDIMIENTO]: { id: SubtipoTarea.METRICA_RENDIMIENTO, abreviatura: 'METRICA_RENDIMIENTO', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de cálculo y actualización de métricas de rendimiento de modelos IA. Genera reportes de precisión. Asociado a TipoTarea: REPORTE, VALIDACION.' },
    [SubtipoTarea.REENTRENAMIENTO]: { id: SubtipoTarea.REENTRENAMIENTO, abreviatura: 'REENTRENAMIENTO', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de reentrenamiento automático de modelos. Ejecuta cuando el error supera el umbral configurado. Asociado a TipoTarea: IA_MODELO, MANTENIMIENTO.' },
    [SubtipoTarea.VALIDACION_CROSS]: { id: SubtipoTarea.VALIDACION_CROSS, abreviatura: 'VALIDACION_CROSS', prefijo: null, valor: 0, descripcion: 'Subtipo para tareas de validación cruzada de modelos. Evalúa y compara el rendimiento de diferentes modelos. Asociado a TipoTarea: VALIDACION, IA_MODELO.' },
    [SubtipoTarea.NINGUNO]: { id: SubtipoTarea.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin subtipo de tarea definido. Valor por defecto para tareas que no requieren clasificación específica o cuando no aplica subtipo. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// MOTIVO DEVOLUCION
export enum MotivoDevolucion {
    PRODUCTO_VENCIDO = 3500,
    PRODUCTO_DAÑADO = 3501,
    ERROR_PEDIDO = 3502,
    EXCESO_STOCK = 3503,
    DESCONTINUADO = 3504,
    DEVOLUCION_CLIENTE = 3505,
    NINGUNO = 3506,
    PRODUCTO_NO_SOLICITADO = 3507,
}

export const MOTIVO_DEVOLUCION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [MotivoDevolucion.PRODUCTO_VENCIDO]: { id: MotivoDevolucion.PRODUCTO_VENCIDO, abreviatura: 'PRODUCTO_VENCIDO', prefijo: 'PV', valor: 1, descripcion: 'Devolución por producto vencido. El producto ha superado su fecha de vencimiento y no puede ser comercializado. Aplica para devoluciones a proveedores o baja de inventario.' },
    [MotivoDevolucion.PRODUCTO_DAÑADO]: { id: MotivoDevolucion.PRODUCTO_DAÑADO, abreviatura: 'PRODUCTO_DAÑADO', prefijo: 'PD', valor: 2, descripcion: 'Devolución por producto dañado o roto. Incluye envases deteriorados, productos derramados o con daños físicos. No apto para la venta.' },
    [MotivoDevolucion.ERROR_PEDIDO]: { id: MotivoDevolucion.ERROR_PEDIDO, abreviatura: 'ERROR_PEDIDO', prefijo: 'EP', valor: 3, descripcion: 'Devolución por error en el pedido. Producto incorrecto, cantidad errónea o especificaciones no coincidentes. Aplica para devoluciones a proveedores por errores de despacho.' },
    [MotivoDevolucion.EXCESO_STOCK]: { id: MotivoDevolucion.EXCESO_STOCK, abreviatura: 'EXCESO_STOCK', prefijo: 'ES', valor: 4, descripcion: 'Devolución por exceso de stock. Producto con inventario sobrepasado que no tiene rotación esperada. Aplica para devoluciones planificadas para liberar espacio.' },
    [MotivoDevolucion.DESCONTINUADO]: { id: MotivoDevolucion.DESCONTINUADO, abreviatura: 'DESCONTINUADO', prefijo: 'DES', valor: 5, descripcion: 'Devolución por producto descontinuado. Producto que ya no es fabricado o comercializado. Aplica para devoluciones de productos que serán retirados del catálogo.' },
    [MotivoDevolucion.DEVOLUCION_CLIENTE]: { id: MotivoDevolucion.DEVOLUCION_CLIENTE, abreviatura: 'DEVOLUCION_CLIENTE', prefijo: 'DC', valor: 6, descripcion: 'Devolución por cliente. Producto devuelto voluntariamente por el comprador por insatisfacción, cambio de opinión o producto no deseado. Aplica para devoluciones de ventas.' },
    [MotivoDevolucion.NINGUNO]: { id: MotivoDevolucion.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin motivo de devolución definido. Valor por defecto para transacciones que no requieren clasificación de devolución o cuando no aplica motivo específico. CONSTANTE POR DEFECTO.', es_defecto: true },
    [MotivoDevolucion.PRODUCTO_NO_SOLICITADO]: { id: MotivoDevolucion.PRODUCTO_NO_SOLICITADO, abreviatura: 'PRODUCTO_NO_SOLICITADO', prefijo: null, valor: 0, descripcion: 'Devolución por producto no solicitado o error en el pedido' },
};

// ==========================================
// TIPO DESPACHO
export enum TipoDespacho {
    VENTA_MOSTRADOR = 3550,
    DOMICILIO = 3551,
    RETIRO = 3552,
    TRANSFERENCIA = 3553,
    NINGUNO = 3554,
}

export const TIPO_DESPACHO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoDespacho.VENTA_MOSTRADOR]: { id: TipoDespacho.VENTA_MOSTRADOR, abreviatura: 'VENTA_MOSTRADOR', prefijo: 'VM', valor: 1, descripcion: 'Venta realizada directamente en el mostrador de la farmacia. El cliente recibe el producto en el punto de venta. No requiere logística de entrega. Modalidad más común.' },
    [TipoDespacho.DOMICILIO]: { id: TipoDespacho.DOMICILIO, abreviatura: 'DOMICILIO', prefijo: 'DOM', valor: 2, descripcion: 'Despacho a domicilio del cliente. El producto es entregado en la dirección indicada por el comprador. Requiere logística de reparto y gestión de tiempos de entrega.' },
    [TipoDespacho.RETIRO]: { id: TipoDespacho.RETIRO, abreviatura: 'RETIRO', prefijo: 'RET', valor: 3, descripcion: 'Cliente retira el producto en la sucursal después de haber realizado el pedido. Aplica para pedidos por teléfono, web o aplicación. El producto es reservado para el cliente.' },
    [TipoDespacho.TRANSFERENCIA]: { id: TipoDespacho.TRANSFERENCIA, abreviatura: 'TRANSFERENCIA', prefijo: 'TRF', valor: 4, descripcion: 'Transferencia de producto entre sucursales para cumplir con un pedido. El cliente retira en una sucursal diferente a la que originó el pedido. Requiere coordinación logística.' },
    [TipoDespacho.NINGUNO]: { id: TipoDespacho.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin tipo de despacho definido. Valor por defecto para transacciones que não requieren clasificación de despacho, como compras a proveedores, ajustes de inventario o movimientos internos. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// METRICA PRECISION
export enum MetricaPrecision {
    MAE = 3600,
    RMSE = 3601,
    MAPE = 3602,
    R2 = 3603,
    F1 = 3604,
    NINGUNO = 3605,
}

export const METRICA_PRECISION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [MetricaPrecision.MAE]: { id: MetricaPrecision.MAE, abreviatura: 'MAE', prefijo: 'MAE', valor: 1, descripcion: 'Mean Absolute Error (Error Absoluto Medio). Mide la magnitud promedio de los errores en un conjunto de predicciones, sin considerar su dirección. Útil para modelos de regresión.' },
    [MetricaPrecision.RMSE]: { id: MetricaPrecision.RMSE, abreviatura: 'RMSE', prefijo: 'RMSE', valor: 2, descripcion: 'Root Mean Square Error (Raíz del Error Cuadrático Medio). Penaliza errores grandes más que MAE. Útil para modelos de regresión donde se quiere evitar errores extremos.' },
    [MetricaPrecision.MAPE]: { id: MetricaPrecision.MAPE, abreviatura: 'MAPE', prefijo: 'MAPE', valor: 3, descripcion: 'Mean Absolute Percentage Error (Error Porcentual Absoluto Medio). Expresa el error en porcentaje, facilitando la interpretación. Útil para comparar precisión entre diferentes escalas.' },
    [MetricaPrecision.R2]: { id: MetricaPrecision.R2, abreviatura: 'R2', prefijo: 'R2', valor: 4, descripcion: 'R-squared (Coeficiente de Determinación). Mide la proporción de varianza explicada por el modelo. Valores cercanos a 1 indican mejor ajuste. Útil para modelos de regresión.' },
    [MetricaPrecision.F1]: { id: MetricaPrecision.F1, abreviatura: 'F1', prefijo: 'F1', valor: 5, descripcion: 'F1 Score (Puntuación F1). Media armónica entre precisión y sensibilidad. Útil para modelos de clasificación con clases desbalanceadas.' },
    [MetricaPrecision.NINGUNO]: { id: MetricaPrecision.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin métrica de precisión definida. Valor por defecto para modelos que no han sido evaluados o cuando no aplica métrica específica. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// FACTOR ESTACIONALIDAD
export enum FactorEstacionalidad {
    NONE = 3650,
    DIARIO = 3651,
    SEMANAL = 3652,
    MENSUAL = 3653,
    ANUAL = 3654,
    MULTIPLE = 3655,
}

export const FACTOR_ESTACIONALIDAD_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [FactorEstacionalidad.NONE]: { id: FactorEstacionalidad.NONE, abreviatura: 'NONE', prefijo: 'NON', valor: 0, descripcion: 'Sin componente estacional. El modelo no considera estacionalidad en el pronóstico. Aplica para productos con demanda constante o cuando la estacionalidad no es significativa. CONSTANTE POR DEFECTO.', es_defecto: true },
    [FactorEstacionalidad.DIARIO]: { id: FactorEstacionalidad.DIARIO, abreviatura: 'DIARIO', prefijo: 'DIA', valor: 1, descripcion: 'Estacionalidad con patrón diario recurrente. El comportamiento de demanda se repite cada día. Aplica para productos con horarios de consumo específicos (ej. medicamentos para el desayuno, almuerzo o cena).' },
    [FactorEstacionalidad.SEMANAL]: { id: FactorEstacionalidad.SEMANAL, abreviatura: 'SEMANAL', prefijo: 'SEM', valor: 2, descripcion: 'Estacionalidad con patrón semanal recurrente. El comportamiento de demanda se repite cada semana. Aplica para productos con mayor consumo en días específicos (ej. fines de semana, días de consulta médica).' },
    [FactorEstacionalidad.MENSUAL]: { id: FactorEstacionalidad.MENSUAL, abreviatura: 'MENSUAL', prefijo: 'MEN', valor: 3, descripcion: 'Estacionalidad con patrón mensual recurrente. El comportamiento de demanda se repite cada mes. Aplica para productos con consumo vinculado a ciclos mensuales (ej. medicamentos de prescripción mensual, productos de planificación familiar).' },
    [FactorEstacionalidad.ANUAL]: { id: FactorEstacionalidad.ANUAL, abreviatura: 'ANUAL', prefijo: 'ANU', valor: 4, descripcion: 'Estacionalidad con patrón anual recurrente. El comportamiento de demanda se repite cada año. Aplica para productos con consumo estacional (ej. antigripales en invierno, antialérgicos en primavera, vacunas en campañas anuales).' },
    [FactorEstacionalidad.MULTIPLE]: { id: FactorEstacionalidad.MULTIPLE, abreviatura: 'MULTIPLE', prefijo: 'MUL', valor: 5, descripcion: 'Estacionalidad con múltiples patrones combinados (ej. semanal + anual, mensual + anual). El comportamiento de demanda tiene más de una componente estacional significativa. Aplica para productos con estacionalidad compleja.' },
};

// ==========================================
// ESTADO PEDIDO ONLINE
export enum EstadoPedidoOnline {
    PENDIENTE = 3700,
    CONFIRMADO = 3701,
    PREPARANDO = 3702,
    EN_CAMINO = 3703,
    ENTREGADO = 3704,
    CANCELADO = 3705,
    RECHAZADO = 3706,
}

export const ESTADO_PEDIDO_ONLINE_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoPedidoOnline.PENDIENTE]: { id: EstadoPedidoOnline.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Pedido recibido, pendiente de confirmación. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoPedidoOnline.CONFIRMADO]: { id: EstadoPedidoOnline.CONFIRMADO, abreviatura: 'CONFIRMADO', prefijo: null, valor: 1, descripcion: 'Pedido confirmado por la farmacia' },
    [EstadoPedidoOnline.PREPARANDO]: { id: EstadoPedidoOnline.PREPARANDO, abreviatura: 'PREPARANDO', prefijo: null, valor: 2, descripcion: 'Pedido en proceso de preparación' },
    [EstadoPedidoOnline.EN_CAMINO]: { id: EstadoPedidoOnline.EN_CAMINO, abreviatura: 'EN_CAMINO', prefijo: null, valor: 3, descripcion: 'Pedido despachado, en ruta de entrega' },
    [EstadoPedidoOnline.ENTREGADO]: { id: EstadoPedidoOnline.ENTREGADO, abreviatura: 'ENTREGADO', prefijo: null, valor: 4, descripcion: 'Pedido entregado al cliente' },
    [EstadoPedidoOnline.CANCELADO]: { id: EstadoPedidoOnline.CANCELADO, abreviatura: 'CANCELADO', prefijo: null, valor: 5, descripcion: 'Pedido cancelado por el cliente o la farmacia' },
    [EstadoPedidoOnline.RECHAZADO]: { id: EstadoPedidoOnline.RECHAZADO, abreviatura: 'RECHAZADO', prefijo: null, valor: 6, descripcion: 'Pedido rechazado por el cliente' },
};

// ==========================================
// METODO CALCULO
export enum MetodoCalculo {
    PONDERADO = 3750,
    FIFO = 3751,
    ULTIMA_COMPRA = 3752,
}

export const METODO_CALCULO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [MetodoCalculo.PONDERADO]: { id: MetodoCalculo.PONDERADO, abreviatura: 'PONDERADO', prefijo: null, valor: 0, descripcion: 'Costo promedio ponderado: (stock_actual * costo_anterior + cantidad_comprada * costo_compra) / (stock_actual + cantidad_comprada). CONSTANTE POR DEFECTO.', es_defecto: true },
    [MetodoCalculo.FIFO]: { id: MetodoCalculo.FIFO, abreviatura: 'FIFO', prefijo: null, valor: 0, descripcion: 'Primeras en entrar, primeras en salir. Se venden primero los lotes más antiguos.' },
    [MetodoCalculo.ULTIMA_COMPRA]: { id: MetodoCalculo.ULTIMA_COMPRA, abreviatura: 'ULTIMA_COMPRA', prefijo: null, valor: 0, descripcion: 'Usa el costo del último lote comprado como referencia.' },
};

// ==========================================
// GRADO EQUIVALENCIA
export enum GradoEquivalencia {
    TOTAL = 3800,
    PARCIAL = 3801,
    TERAPEUTICO = 3802,
    NINGUNO = 3803,
}

export const GRADO_EQUIVALENCIA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [GradoEquivalencia.TOTAL]: { id: GradoEquivalencia.TOTAL, abreviatura: 'TOTAL', prefijo: null, valor: 1, descripcion: 'Mismo principio activo, misma concentración, misma forma farmacéutica. Intercambio directo y seguro. No requiere ajuste de dosis ni evaluación médica adicional.' },
    [GradoEquivalencia.PARCIAL]: { id: GradoEquivalencia.PARCIAL, abreviatura: 'PARCIAL', prefijo: null, valor: 2, descripcion: 'Mismo principio activo, diferente concentración o forma farmacéutica. Requiere ajuste de dosis por parte del profesional de salud. No es intercambio directo.' },
    [GradoEquivalencia.TERAPEUTICO]: { id: GradoEquivalencia.TERAPEUTICO, abreviatura: 'TERAPEUTICO', prefijo: null, valor: 3, descripcion: 'Diferente principio activo pero mismo efecto terapéutico. Requiere evaluación médica obligatoria antes del intercambio. No es intercambio directo.' },
    [GradoEquivalencia.NINGUNO]: { id: GradoEquivalencia.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 4, descripcion: 'Sin grado de equivalencia definido. Valor por defecto para productos sin equivalencia registrada o cuando no aplica clasificación. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// TIPO RECETA
export enum TipoReceta {
    SIMPLE = 3850,
    ARCHIVADA = 3851,
    VALADA = 3852,
    NINGUNO = 3853,
}

export const TIPO_RECETA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoReceta.SIMPLE]: { id: TipoReceta.SIMPLE, abreviatura: 'SIMPLE', prefijo: 'SIM', valor: 1, descripcion: 'Receta médica estándar para medicamentos de venta libre,  antibióticos comunes y medicamentos que no requieren control especial. No requiere retención física en farmacia.' },
    [TipoReceta.ARCHIVADA]: { id: TipoReceta.ARCHIVADA, abreviatura: 'ARCHIVADA', prefijo: 'ARC', valor: 2, descripcion: 'Receta retenida obligatoriamente en farmacia. Aplica para medicamentos psicotrópicos y sustancias fiscalizadas que requieren control de dispensación. Se debe conservar por el tiempo establecido por normativa.' },
    [TipoReceta.VALADA]: { id: TipoReceta.VALADA, abreviatura: 'VALADA', prefijo: 'VAL', valor: 3, descripcion: 'Receta oficial valorada y timbrada por autoridad competente. Aplica para estupefacientes y medicamentos de control estricto. Requiere registro especial y cumplimiento riguroso de normativa.' },
    [TipoReceta.NINGUNO]: { id: TipoReceta.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 4, descripcion: 'Sin tipo de receta definido. Valor por defecto para casos donde no se requiere receta médica (venta libre, productos OTC, dispositivos médicos) o cuando no aplica el control por receta. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// MODALIDAD FACTURACION
export enum ModalidadFacturacion {
    NINGUNO = 3900,
    ELECTRONICA = 3901,
    COMPUTARIZADA = 3902,
    MANUAL = 3903,
}

export const MODALIDAD_FACTURACION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [ModalidadFacturacion.NINGUNO]: { id: ModalidadFacturacion.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Modalidad de facturación ninguno. CONSTANTE POR DEFECTO.', es_defecto: true },
    [ModalidadFacturacion.ELECTRONICA]: { id: ModalidadFacturacion.ELECTRONICA, abreviatura: 'ELECTRONICA', prefijo: 'EL', valor: 1, descripcion: 'Electrónica en Línea' },
    [ModalidadFacturacion.COMPUTARIZADA]: { id: ModalidadFacturacion.COMPUTARIZADA, abreviatura: 'COMPUTARIZADA', prefijo: 'CL', valor: 2, descripcion: 'Computarizada en Línea' },
    [ModalidadFacturacion.MANUAL]: { id: ModalidadFacturacion.MANUAL, abreviatura: 'MANUAL', prefijo: 'MN', valor: 3, descripcion: 'Manual' },
};

// ==========================================
// TIPO PUNTO VENTA
export enum TipoPuntoVenta {
    NINGUNO = 3950,
    CAJA = 3951,
}

export const TIPO_PUNTO_VENTA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoPuntoVenta.NINGUNO]: { id: TipoPuntoVenta.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Tipo punto venta ninguno. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoPuntoVenta.CAJA]: { id: TipoPuntoVenta.CAJA, abreviatura: 'CAJA', prefijo: 'CAJ', valor: 1, descripcion: 'Punto de venta caja.' },
};

// ==========================================
// ESTADO PROFORMA
export enum EstadoProforma {
    NO_APLICA = 4000,
    PENDIENTE = 4001,
    CONVERTIDA = 4002,
    EXPIRADA = 4003,
    ANULADA = 4004,
}

export const ESTADO_PROFORMA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoProforma.NO_APLICA]: { id: EstadoProforma.NO_APLICA, abreviatura: 'NO_APLICA', prefijo: null, valor: 0, descripcion: 'Proforma por default. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoProforma.PENDIENTE]: { id: EstadoProforma.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Proforma o reserva emitida y pendiente de resolución o cobro. ', },
    [EstadoProforma.CONVERTIDA]: { id: EstadoProforma.CONVERTIDA, abreviatura: 'CONVERTIDA', prefijo: null, valor: 1, descripcion: 'Proforma o reserva convertida exitosamente en venta definitiva.' },
    [EstadoProforma.EXPIRADA]: { id: EstadoProforma.EXPIRADA, abreviatura: 'EXPIRADA', prefijo: null, valor: 2, descripcion: 'Reserva cancelada automáticamente por tiempo vencido (TTL) liberando el stock.' },
    [EstadoProforma.ANULADA]: { id: EstadoProforma.ANULADA, abreviatura: 'ANULADA', prefijo: null, valor: 3, descripcion: 'Proforma o reserva anulada manualmente por el operador.' },
};

// ==========================================
// TIPO OPERACION ALMACEN
export enum TipoOperacionAlmacen {
    LOGISTICA_INTERNA = 4050,
    VENTA_DIRECTA = 4051,
}

export const TIPO_OPERACION_ALMACEN_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoOperacionAlmacen.LOGISTICA_INTERNA]: { id: TipoOperacionAlmacen.LOGISTICA_INTERNA, abreviatura: 'LOGISTICA_INTERNA', prefijo: 'LI', valor: 0, descripcion: 'Almacén destinado a depósito general, tránsito o reabastecimiento interno sin venta directa. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoOperacionAlmacen.VENTA_DIRECTA]: { id: TipoOperacionAlmacen.VENTA_DIRECTA, abreviatura: 'VENTA_DIRECTA', prefijo: 'VD', valor: 1, descripcion: 'Almacén vinculado a un punto de venta donde las transacciones afectan directamente el stock operativo.' },
};

// ==========================================
// ENTIDAD AFECTADA
export enum EntidadAfectada {
    PRODUCTOS = 4100,
    LOTES = 4101,
    VENTAS = 4102,
    COMPRAS = 4103,
    USUARIOS = 4104,
    SUCURSALES = 4105,
    PROVEEDORES = 4106,
    CLIENTES = 4107,
    FACTURAS = 4108,
    PAGOS = 4109,
    INVENTARIO = 4110,
    NINGUNO = 4111,
}

export const ENTIDAD_AFECTADA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EntidadAfectada.PRODUCTOS]: { id: EntidadAfectada.PRODUCTOS, abreviatura: 'PRODUCTOS', prefijo: 'PROD', valor: 0, descripcion: 'Productos del catalogo general. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EntidadAfectada.LOTES]: { id: EntidadAfectada.LOTES, abreviatura: 'LOTES', prefijo: 'LOT', valor: 0, descripcion: 'Lotes de inventario y fechas de vencimiento.' },
    [EntidadAfectada.VENTAS]: { id: EntidadAfectada.VENTAS, abreviatura: 'VENTAS', prefijo: 'VEN', valor: 0, descripcion: 'Transacciones de venta realizadas.' },
    [EntidadAfectada.COMPRAS]: { id: EntidadAfectada.COMPRAS, abreviatura: 'COMPRAS', prefijo: 'COM', valor: 0, descripcion: 'Transacciones de compra a proveedores.' },
    [EntidadAfectada.USUARIOS]: { id: EntidadAfectada.USUARIOS, abreviatura: 'USUARIOS', prefijo: 'USR', valor: 0, descripcion: 'Usuarios del sistema registrados.' },
    [EntidadAfectada.SUCURSALES]: { id: EntidadAfectada.SUCURSALES, abreviatura: 'SUCURSALES', prefijo: 'SUC', valor: 0, descripcion: 'Sucursales operativas de la empresa.' },
    [EntidadAfectada.PROVEEDORES]: { id: EntidadAfectada.PROVEEDORES, abreviatura: 'PROVEEDORES', prefijo: 'PROV', valor: 0, descripcion: 'Proveedores comerciales registrados.' },
    [EntidadAfectada.CLIENTES]: { id: EntidadAfectada.CLIENTES, abreviatura: 'CLIENTES', prefijo: 'CLI', valor: 0, descripcion: 'Clientes del sistema o compradores.' },
    [EntidadAfectada.FACTURAS]: { id: EntidadAfectada.FACTURAS, abreviatura: 'FACTURAS', prefijo: 'FAC', valor: 0, descripcion: 'Documentos fiscales y facturación.' },
    [EntidadAfectada.PAGOS]: { id: EntidadAfectada.PAGOS, abreviatura: 'PAGOS', prefijo: 'PAG', valor: 0, descripcion: 'Pagos, abonos y transacciones financieras.' },
    [EntidadAfectada.INVENTARIO]: { id: EntidadAfectada.INVENTARIO, abreviatura: 'INVENTARIO', prefijo: 'INV', valor: 0, descripcion: 'Movimientos generales de inventario y stock.' },
    [EntidadAfectada.NINGUNO]: { id: EntidadAfectada.NINGUNO, abreviatura: 'NINGUNO', prefijo: 'NIN', valor: 0, descripcion: 'Sin entidad afectada o registro neutral. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// CRITICIDAD MEDICA
export enum CriticidadMedica {
    NORMAL = 4150,
    CRITICO = 4151,
}

export const CRITICIDAD_MEDICA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [CriticidadMedica.NORMAL]: { id: CriticidadMedica.NORMAL, abreviatura: 'NORMAL', prefijo: null, valor: 0, descripcion: 'Producto sin criticidad medica especial. CONSTANTE POR DEFECTO.', es_defecto: true },
    [CriticidadMedica.CRITICO]: { id: CriticidadMedica.CRITICO, abreviatura: 'CRITICO', prefijo: null, valor: 0, descripcion: 'Producto critico para la salud' },
};

// ==========================================
// TIPO PATRON
export enum TipoPatron {
    DEMANDA = 4200,
}

export const TIPO_PATRON_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoPatron.DEMANDA]: { id: TipoPatron.DEMANDA, abreviatura: 'DEMANDA', prefijo: 'DEM', valor: 0, descripcion: 'Patrón basado en la demanda histórica. CONSTANTE POR DEFECTO.', es_defecto: true },
};

// ==========================================
// FUENTE EXOGENA
export enum FuenteExogena {
    SENAMHI = 4250,
    INE = 4251,
    BCB = 4252,
    API_CLIMA = 4253,
    CALENDARIO_FESTIVOS = 4254,
    CUSTOM = 4255,
}

export const FUENTE_EXOGENA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [FuenteExogena.SENAMHI]: { id: FuenteExogena.SENAMHI, abreviatura: 'SENAMHI', prefijo: null, valor: 0, descripcion: 'Servicio Nacional de Meteorologia e Hidrologia. CONSTANTE POR DEFECTO.', es_defecto: true },
    [FuenteExogena.INE]: { id: FuenteExogena.INE, abreviatura: 'INE', prefijo: null, valor: 0, descripcion: 'Instituto Nacional de Estadistica' },
    [FuenteExogena.BCB]: { id: FuenteExogena.BCB, abreviatura: 'BCB', prefijo: null, valor: 0, descripcion: 'Banco Central de Bolivia' },
    [FuenteExogena.API_CLIMA]: { id: FuenteExogena.API_CLIMA, abreviatura: 'API_CLIMA', prefijo: null, valor: 0, descripcion: 'API de clima externa' },
    [FuenteExogena.CALENDARIO_FESTIVOS]: { id: FuenteExogena.CALENDARIO_FESTIVOS, abreviatura: 'CALENDARIO_FESTIVOS', prefijo: null, valor: 0, descripcion: 'Calendario oficial de festivos' },
    [FuenteExogena.CUSTOM]: { id: FuenteExogena.CUSTOM, abreviatura: 'CUSTOM', prefijo: null, valor: 0, descripcion: 'Fuente personalizada definida por el usuario' },
};

// ==========================================
// TIPO BILLETE MONEDA
export enum TipoBilleteMoneda {
    NINGUNO = 4300,
    B200 = 4301,
    B100 = 4302,
    B50 = 4303,
    B20 = 4304,
    B10 = 4305,
    B5 = 4306,
    B2 = 4307,
    B1 = 4308,
    M050 = 4309,
    M020 = 4310,
    M010 = 4311,
    M10 = 4312,
    M5 = 4313,
    M2 = 4314,
    M1 = 4315,
}

export const TIPO_BILLETE_MONEDA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoBilleteMoneda.NINGUNO]: { id: TipoBilleteMoneda.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Registro comodín para arqueos. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoBilleteMoneda.B200]: { id: TipoBilleteMoneda.B200, abreviatura: 'B200', prefijo: null, valor: 0, descripcion: 'Billete de 200 Bs' },
    [TipoBilleteMoneda.B100]: { id: TipoBilleteMoneda.B100, abreviatura: 'B100', prefijo: null, valor: 0, descripcion: 'Billete de 100 Bs' },
    [TipoBilleteMoneda.B50]: { id: TipoBilleteMoneda.B50, abreviatura: 'B50', prefijo: null, valor: 0, descripcion: 'Billete de 50 Bs' },
    [TipoBilleteMoneda.B20]: { id: TipoBilleteMoneda.B20, abreviatura: 'B20', prefijo: null, valor: 0, descripcion: 'Billete de 20 Bs' },
    [TipoBilleteMoneda.B10]: { id: TipoBilleteMoneda.B10, abreviatura: 'B10', prefijo: null, valor: 0, descripcion: 'Billete de 10 Bs' },
    [TipoBilleteMoneda.B5]: { id: TipoBilleteMoneda.B5, abreviatura: 'B5', prefijo: null, valor: 0, descripcion: 'Billete de 5 Bs' },
    [TipoBilleteMoneda.B2]: { id: TipoBilleteMoneda.B2, abreviatura: 'B2', prefijo: null, valor: 0, descripcion: 'Billete de 2 Bs' },
    [TipoBilleteMoneda.B1]: { id: TipoBilleteMoneda.B1, abreviatura: 'B1', prefijo: null, valor: 0, descripcion: 'Billete de 1 Bs' },
    [TipoBilleteMoneda.M050]: { id: TipoBilleteMoneda.M050, abreviatura: 'M050', prefijo: null, valor: 0, descripcion: 'Moneda de 50 centavos' },
    [TipoBilleteMoneda.M020]: { id: TipoBilleteMoneda.M020, abreviatura: 'M020', prefijo: null, valor: 0, descripcion: 'Moneda de 20 centavos' },
    [TipoBilleteMoneda.M010]: { id: TipoBilleteMoneda.M010, abreviatura: 'M010', prefijo: null, valor: 0, descripcion: 'Moneda de 10 centavos' },
    [TipoBilleteMoneda.M10]: { id: TipoBilleteMoneda.M10, abreviatura: 'M10', prefijo: null, valor: 0, descripcion: 'Moneda de 10 Bs' },
    [TipoBilleteMoneda.M5]: { id: TipoBilleteMoneda.M5, abreviatura: 'M5', prefijo: null, valor: 0, descripcion: 'Moneda de 5 Bs' },
    [TipoBilleteMoneda.M2]: { id: TipoBilleteMoneda.M2, abreviatura: 'M2', prefijo: null, valor: 0, descripcion: 'Moneda de 2 Bs' },
    [TipoBilleteMoneda.M1]: { id: TipoBilleteMoneda.M1, abreviatura: 'M1', prefijo: null, valor: 0, descripcion: 'Moneda de 1 Bs' },
};

// ==========================================
// TIPO APLICACION
export enum TipoAplicacion {
    GLOBAL = 4350,
    CATEGORIA = 4351,
    LABORATORIO = 4352,
    PRODUCTO = 4353,
}

export const TIPO_APLICACION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoAplicacion.GLOBAL]: { id: TipoAplicacion.GLOBAL, abreviatura: 'GLOBAL', prefijo: null, valor: 0, descripcion: 'Política que aplica a todos los productos sin excepción. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoAplicacion.CATEGORIA]: { id: TipoAplicacion.CATEGORIA, abreviatura: 'CATEGORIA', prefijo: null, valor: 0, descripcion: 'Política que aplica solo a productos de una categoría específica.' },
    [TipoAplicacion.LABORATORIO]: { id: TipoAplicacion.LABORATORIO, abreviatura: 'LABORATORIO', prefijo: null, valor: 0, descripcion: 'Política que aplica solo a productos de un laboratorio específico.' },
    [TipoAplicacion.PRODUCTO]: { id: TipoAplicacion.PRODUCTO, abreviatura: 'PRODUCTO', prefijo: null, valor: 0, descripcion: 'Política que aplica solo a un producto específico.' },
};

// ==========================================
// TIPO ASISTENCIA
export enum TipoAsistencia {
    NORMAL = 4400,
    LICENCIA = 4401,
    PERMISO = 4402,
    JUSTIFICADA = 4403,
}

export const TIPO_ASISTENCIA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoAsistencia.NORMAL]: { id: TipoAsistencia.NORMAL, abreviatura: 'NORMAL', prefijo: null, valor: 0, descripcion: 'Asistencia regular sin incidencias. Marcación de entrada y salida estándar. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoAsistencia.LICENCIA]: { id: TipoAsistencia.LICENCIA, abreviatura: 'LICENCIA', prefijo: null, valor: 1, descripcion: 'Ausencia justificada por licencia médica, vacaciones, estudio o personal. Requiere documentación respaldo.' },
    [TipoAsistencia.PERMISO]: { id: TipoAsistencia.PERMISO, abreviatura: 'PERMISO', prefijo: null, valor: 2, descripcion: 'Permiso por horas o días con autorización del supervisor. Afecta el cálculo de horas trabajadas.' },
    [TipoAsistencia.JUSTIFICADA]: { id: TipoAsistencia.JUSTIFICADA, abreviatura: 'JUSTIFICADA', prefijo: null, valor: 3, descripcion: 'Ausencia justificada sin goce de sueldo (ej. emergencia familiar).' },
};

// ==========================================
// ESTADO ASISTENCIA
export enum EstadoAsistencia {
    PRESENTE = 4450,
    AUSENTE = 4451,
    TARDE = 4452,
    FALTA_INJUSTIFICADA = 4453,
}

export const ESTADO_ASISTENCIA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoAsistencia.PRESENTE]: { id: EstadoAsistencia.PRESENTE, abreviatura: 'PRESENTE', prefijo: null, valor: 0, descripcion: 'Trabajador asistió puntualmente y cumplió su jornada laboral completa. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoAsistencia.AUSENTE]: { id: EstadoAsistencia.AUSENTE, abreviatura: 'AUSENTE', prefijo: null, valor: 1, descripcion: 'Trabajador no asistió a su jornada laboral. Sin justificación o sin registrar marcación.' },
    [EstadoAsistencia.TARDE]: { id: EstadoAsistencia.TARDE, abreviatura: 'TARDE', prefijo: null, valor: 2, descripcion: 'Trabajador llegó después de la hora de inicio de jornada (más de 15 minutos de retraso).' },
    [EstadoAsistencia.FALTA_INJUSTIFICADA]: { id: EstadoAsistencia.FALTA_INJUSTIFICADA, abreviatura: 'FALTA_INJUSTIFICADA', prefijo: null, valor: 3, descripcion: 'Ausencia sin justificación válida. Afecta el cálculo de sueldo y puede generar sanciones.' },
};

// ==========================================
// METODO MARCACION
export enum MetodoMarcacion {
    MANUAL = 4500,
    BIOMETRICO = 4501,
    QR = 4502,
    APP = 4503,
}

export const METODO_MARCACION_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [MetodoMarcacion.MANUAL]: { id: MetodoMarcacion.MANUAL, abreviatura: 'MANUAL', prefijo: null, valor: 0, descripcion: 'Registro manual por parte del supervisor o administrador. Requiere validación. CONSTANTE POR DEFECTO.', es_defecto: true },
    [MetodoMarcacion.BIOMETRICO]: { id: MetodoMarcacion.BIOMETRICO, abreviatura: 'BIOMETRICO', prefijo: null, valor: 1, descripcion: 'Marcación mediante dispositivo biométrico (huella digital, reconocimiento facial). Método más seguro.' },
    [MetodoMarcacion.QR]: { id: MetodoMarcacion.QR, abreviatura: 'QR', prefijo: null, valor: 2, descripcion: 'Marcación mediante escaneo de código QR en el punto de acceso. Aplicable para control de acceso.' },
    [MetodoMarcacion.APP]: { id: MetodoMarcacion.APP, abreviatura: 'APP', prefijo: null, valor: 3, descripcion: 'Marcación desde aplicación móvil con geolocalización. Permite registro remoto.' },
};

// ==========================================
// TIPO ALERTA RRHH
export enum TipoAlertaRRHH {
    RRHH = 4550,
    FALTAS_CONSECUTIVAS = 4551,
    BAJA_RENDIMIENTO = 4552,
    VENCIMIENTO_CONTRATO = 4553,
    CUMPLEANOS = 4554,
}

export const TIPO_ALERTA_RRHH_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoAlertaRRHH.RRHH]: { id: TipoAlertaRRHH.RRHH, abreviatura: 'RRHH', prefijo: null, valor: 0, descripcion: 'Alerta relacionada con el módulo de Recursos Humanos. Agrupa notificaciones de asistencia, planillas y personal. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoAlertaRRHH.FALTAS_CONSECUTIVAS]: { id: TipoAlertaRRHH.FALTAS_CONSECUTIVAS, abreviatura: 'FALTAS_CONSECUTIVAS', prefijo: null, valor: 1, descripcion: 'Alerta por faltas consecutivas del trabajador. Requiere atención del supervisor.' },
    [TipoAlertaRRHH.BAJA_RENDIMIENTO]: { id: TipoAlertaRRHH.BAJA_RENDIMIENTO, abreviatura: 'BAJA_RENDIMIENTO', prefijo: null, valor: 2, descripcion: 'Alerta por bajo rendimiento del trabajador. Requiere evaluación de desempeño.' },
    [TipoAlertaRRHH.VENCIMIENTO_CONTRATO]: { id: TipoAlertaRRHH.VENCIMIENTO_CONTRATO, abreviatura: 'VENCIMIENTO_CONTRATO', prefijo: null, valor: 3, descripcion: 'Alerta por vencimiento de contrato del trabajador. Requiere renovación o finalización.' },
    [TipoAlertaRRHH.CUMPLEANOS]: { id: TipoAlertaRRHH.CUMPLEANOS, abreviatura: 'CUMPLEANOS', prefijo: null, valor: 4, descripcion: 'Alerta por cumpleaños del trabajador. Notificación para área de RRHH.' },
};

// ==========================================
// TIPO PLANILLA
export enum TipoPlanilla {
    SUELDOS = 4600,
    JORNALES = 4601,
    CONTRATO = 4602,
}

export const TIPO_PLANILLA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoPlanilla.SUELDOS]: { id: TipoPlanilla.SUELDOS, abreviatura: 'SUELDOS', prefijo: null, valor: 0, descripcion: 'Planilla mensual de sueldos para trabajadores con contrato indefinido o fijo. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoPlanilla.JORNALES]: { id: TipoPlanilla.JORNALES, abreviatura: 'JORNALES', prefijo: null, valor: 1, descripcion: 'Planilla por jornales para trabajadores eventuales o temporales.' },
    [TipoPlanilla.CONTRATO]: { id: TipoPlanilla.CONTRATO, abreviatura: 'CONTRATO', prefijo: null, valor: 2, descripcion: 'Planilla por contrato de servicios profesionales (consultores, asesores).' },
};

// ==========================================
// ESTADO PLANILLA
export enum EstadoPlanilla {
    BORRADOR = 4650,
    CALCULADA = 4651,
    APROBADA = 4652,
    PAGADA = 4653,
    ANULADA = 4654,
}

export const ESTADO_PLANILLA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoPlanilla.BORRADOR]: { id: EstadoPlanilla.BORRADOR, abreviatura: 'BORRADOR', prefijo: null, valor: 0, descripcion: 'Planilla en edición. Los valores pueden ser modificados. No está lista para aprobación. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoPlanilla.CALCULADA]: { id: EstadoPlanilla.CALCULADA, abreviatura: 'CALCULADA', prefijo: null, valor: 1, descripcion: 'Planilla calculada automáticamente por el sistema. Pendiente de aprobación por gerencia.' },
    [EstadoPlanilla.APROBADA]: { id: EstadoPlanilla.APROBADA, abreviatura: 'APROBADA', prefijo: null, valor: 2, descripcion: 'Planilla aprobada por gerencia. Lista para pago a los trabajadores.' },
    [EstadoPlanilla.PAGADA]: { id: EstadoPlanilla.PAGADA, abreviatura: 'PAGADA', prefijo: null, valor: 3, descripcion: 'Planilla pagada completamente a los trabajadores. Registro cerrado y contabilizado.' },
    [EstadoPlanilla.ANULADA]: { id: EstadoPlanilla.ANULADA, abreviatura: 'ANULADA', prefijo: null, valor: 4, descripcion: 'Planilla anulada irreversiblemente. Solo permitido desde BORRADOR o CALCULADA.' },
};

// ==========================================
// ESTADO CONTRATO
export enum EstadoContrato {
    VIGENTE = 4700,
    FINALIZADO = 4701,
    RENOVADO = 4702,
    SUSPENDIDO = 4703,
}

export const ESTADO_CONTRATO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoContrato.VIGENTE]: { id: EstadoContrato.VIGENTE, abreviatura: 'VIGENTE', prefijo: null, valor: 0, descripcion: 'Contrato activo y operativo. El trabajador se encuentra en funciones. CONSTANTE POR DEFECTO.', es_defecto: true },
    [EstadoContrato.FINALIZADO]: { id: EstadoContrato.FINALIZADO, abreviatura: 'FINALIZADO', prefijo: null, valor: 1, descripcion: 'Contrato finalizado por cumplimiento de plazo o decisión del trabajador.' },
    [EstadoContrato.RENOVADO]: { id: EstadoContrato.RENOVADO, abreviatura: 'RENOVADO', prefijo: null, valor: 2, descripcion: 'Contrato renovado por un nuevo período.' },
    [EstadoContrato.SUSPENDIDO]: { id: EstadoContrato.SUSPENDIDO, abreviatura: 'SUSPENDIDO', prefijo: null, valor: 3, descripcion: 'Contrato suspendido temporalmente por licencia o situación especial.' },
};

// ==========================================
// TIPO CONTRATO
export enum TipoContrato {
    INDEFINIDO = 4750,
    FIJO = 4751,
    EVENTUAL = 4752,
    PRACTICAS = 4753,
    CONSULTORIA = 4754,
}

export const TIPO_CONTRATO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoContrato.INDEFINIDO]: { id: TipoContrato.INDEFINIDO, abreviatura: 'INDEFINIDO', prefijo: null, valor: 0, descripcion: 'Contrato sin fecha de término definida. Establece relación laboral permanente. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoContrato.FIJO]: { id: TipoContrato.FIJO, abreviatura: 'FIJO', prefijo: null, valor: 1, descripcion: 'Contrato con fecha de inicio y fin definidas. Se renueva automáticamente o finaliza.' },
    [TipoContrato.EVENTUAL]: { id: TipoContrato.EVENTUAL, abreviatura: 'EVENTUAL', prefijo: null, valor: 2, descripcion: 'Contrato por tiempo determinado para proyectos específicos o temporada.' },
    [TipoContrato.PRACTICAS]: { id: TipoContrato.PRACTICAS, abreviatura: 'PRACTICAS', prefijo: null, valor: 3, descripcion: 'Contrato de prácticas profesionales o pasantías para estudiantes.' },
    [TipoContrato.CONSULTORIA]: { id: TipoContrato.CONSULTORIA, abreviatura: 'CONSULTORIA', prefijo: null, valor: 4, descripcion: 'Contrato de servicios profesionales para consultores o asesores externos.' },
};

// ==========================================
// TIPO JORNADA
export enum TipoJornada {
    COMPLETA = 4800,
    MEDIA = 4801,
    POR_HORAS = 4802,
}

export const TIPO_JORNADA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoJornada.COMPLETA]: { id: TipoJornada.COMPLETA, abreviatura: 'COMPLETA', prefijo: null, valor: 0, descripcion: 'Jornada laboral completa (40 horas semanales). CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoJornada.MEDIA]: { id: TipoJornada.MEDIA, abreviatura: 'MEDIA', prefijo: null, valor: 1, descripcion: 'Jornada laboral media (20 horas semanales).' },
    [TipoJornada.POR_HORAS]: { id: TipoJornada.POR_HORAS, abreviatura: 'POR_HORAS', prefijo: null, valor: 2, descripcion: 'Jornada laboral por horas (trabajo por horas).' },
};

// ==========================================
// ESTADO RESERVA
export enum EstadoReserva {
    NO_APLICA = 4850,
    PENDIENTE = 4851,
    CONFIRMADA = 4852,
    CANCELADA = 4853,
    EXPIRADA = 4854,
}

export const ESTADO_RESERVA_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoReserva.NO_APLICA]: { id: EstadoReserva.NO_APLICA, abreviatura: 'NO_APLICA', prefijo: null, valor: 0, descripcion: 'Sin estado de reserva definido. Valor por defecto para transacciones que no son reservas.', es_defecto: true },
    [EstadoReserva.PENDIENTE]: { id: EstadoReserva.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Reserva creada y pendiente de confirmación por el cliente o de conversión a venta.' },
    [EstadoReserva.CONFIRMADA]: { id: EstadoReserva.CONFIRMADA, abreviatura: 'CONFIRMADA', prefijo: null, valor: 0, descripcion: 'Reserva confirmada por el cliente. El stock está apartado y se procederá a la venta.' },
    [EstadoReserva.CANCELADA]: { id: EstadoReserva.CANCELADA, abreviatura: 'CANCELADA', prefijo: null, valor: 0, descripcion: 'Reserva cancelada manualmente por el operador o por solicitud del cliente. Libera el stock automáticamente.' },
    [EstadoReserva.EXPIRADA]: { id: EstadoReserva.EXPIRADA, abreviatura: 'EXPIRADA', prefijo: null, valor: 0, descripcion: 'Reserva expirada por tiempo de validez superado (TTL). Libera el stock automáticamente.' },
};

// ==========================================
// ESTADO CARRITO
export enum EstadoCarrito {
    PENDIENTE = 4900,
    PROCESADO = 4901,
    EXPIRADO = 4902,
    ABANDONADO = 4903,
    EN_PROCESO = 4904,
    RESERVADO = 4905,
    NINGUNO = 4906,
}

export const ESTADO_CARRITO_METADATA: Record<number, ConstanteMetadata & { es_defecto?: boolean }> = {
    [EstadoCarrito.PENDIENTE]: { id: EstadoCarrito.PENDIENTE, abreviatura: 'PENDIENTE', prefijo: null, valor: 0, descripcion: 'Carrito activo pendiente de procesamiento. El cliente puede agregar o quitar productos.' },
    [EstadoCarrito.PROCESADO]: { id: EstadoCarrito.PROCESADO, abreviatura: 'PROCESADO', prefijo: null, valor: 0, descripcion: 'Carrito ya convertido en pedido. No se pueden modificar sus productos.' },
    [EstadoCarrito.EXPIRADO]: { id: EstadoCarrito.EXPIRADO, abreviatura: 'EXPIRADO', prefijo: null, valor: 0, descripcion: 'Carrito expirado por tiempo de inactividad (TTL).' },
    [EstadoCarrito.ABANDONADO]: { id: EstadoCarrito.ABANDONADO, abreviatura: 'ABANDONADO', prefijo: null, valor: 0, descripcion: 'Carrito abandonado activamente por el cliente (cerró sesión, vació carrito, canceló).' },
    [EstadoCarrito.EN_PROCESO]: { id: EstadoCarrito.EN_PROCESO, abreviatura: 'EN_PROCESO', prefijo: null, valor: 0, descripcion: 'Carrito en proceso de checkout. El cliente está en medio del flujo de compra.' },
    [EstadoCarrito.RESERVADO]: { id: EstadoCarrito.RESERVADO, abreviatura: 'RESERVADO', prefijo: null, valor: 0, descripcion: 'Carrito con stock apartado. Pendiente de confirmación final.' },
    [EstadoCarrito.NINGUNO]: { id: EstadoCarrito.NINGUNO, abreviatura: 'NINGUNO', prefijo: null, valor: 0, descripcion: 'Sin estado de carrito definido. Valor por defecto para registros comodín o casos excepcionales.', es_defecto: true },
};

// ==========================================

