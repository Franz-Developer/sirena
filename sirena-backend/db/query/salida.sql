// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts

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

export const ESTADO_METADATA: Record<Estado, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Estado.ACTIVO]: { id: Estado.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Estado.BORRADO]: { id: Estado.BORRADO, abreviatura: 'BORRADO', prefijo: null, valor: 0, descripcion: 'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.' },
    [Estado.HISTORICO]: { id: Estado.HISTORICO, abreviatura: 'HISTORICO', prefijo: null, valor: 0, descripcion: 'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.' },
    [Estado.ANULADO]: { id: Estado.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.' },
};

// ==========================================
// TIPO CLIENTE
export enum TipoCliente {
    NATURAL = 1150,
    JURIDICA = 1151,
}

export const TIPO_CLIENTE_METADATA: Record<TipoCliente, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoCliente.NATURAL]: { id: TipoCliente.NATURAL, abreviatura: 'NATURAL', prefijo: null, valor: 0, descripcion: 'Persona física individual. Requiere documento de identidad (CI, CEX, Pasaporte) para facturación. Puede tener límite de crédito personal. CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoCliente.JURIDICA]: { id: TipoCliente.JURIDICA, abreviatura: 'JURIDICA', prefijo: null, valor: 0, descripcion: 'Persona jurídica, empresa o institución. Requiere NIT y razón social obligatoria para facturación. Puede tener límite de crédito corporativo y condiciones especiales de pago.' },
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

export const TIPO_DOCUMENTO_METADATA: Record<TipoDocumento, ConstanteMetadata & { es_defecto?: boolean }> = {
    [TipoDocumento.CEDULA_IDENTIDAD]: { id: TipoDocumento.CEDULA_IDENTIDAD, abreviatura: 'CEDULA_IDENTIDAD', prefijo: 'CI', valor: 1, descripcion: 'Cédula de identidad boliviana. Documento nacional emitido por el SEGIP. Formato: numérico (ej. 1234567) o con complemento (ej. 1234567-1A). CONSTANTE POR DEFECTO.', es_defecto: true },
    [TipoDocumento.CEDULA_IDENTIDAD_EXTRANJERO]: { id: TipoDocumento.CEDULA_IDENTIDAD_EXTRANJERO, abreviatura: 'CEDULA_IDENTIDAD_EXTRANJERO', prefijo: 'CEX', valor: 2, descripcion: 'Cédula de identidad de extranjero. Documento para residentes no bolivianos emitido por el SEGIP. Formato: numérico con prefijo (ej. 1234567-1). Utilizado para extranjeros con residencia.' },
    [TipoDocumento.PASAPORTE]: { id: TipoDocumento.PASAPORTE, abreviatura: 'PASAPORTE', prefijo: 'PAS', valor: 3, descripcion: 'Pasaporte. Documento de identidad internacional emitido por autoridades migratorias de cada país. Formato: alfanumérico variable (ej. AB123456). Utilizado para extranjeros sin residencia.' },
    [TipoDocumento.OTRO]: { id: TipoDocumento.OTRO, abreviatura: 'OTRO', prefijo: 'OTRO', valor: 4, descripcion: 'Otro tipo de documento de identidad no contemplado en las categorías anteriores. Utilizado para casos excepcionales, documentos diplomáticos, cédulas especiales o documentos temporales.' },
    [TipoDocumento.NIT]: { id: TipoDocumento.NIT, abreviatura: 'NIT', prefijo: 'NIT', valor: 5, descripcion: 'Número de Identificación Tributaria. Emitido por el Servicio de Impuestos Nacionales (SIN). Formato: numérico de 7-10 dígitos (ej. 1023456021).' },
};
