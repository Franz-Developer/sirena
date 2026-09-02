// C:\sirena\sirena-backend\src\common\constants\ubicaciones.constants.ts

export const TIPO_UBICACION = {
    ESTANTERIA: 'ESTANTERIA',
    RACK: 'RACK',
    VITRINA: 'VITRINA',
    REFRIGERADOR: 'REFRIGERADOR',
    CONGELADOR: 'CONGELADOR',
    ARMARIO: 'ARMARIO',
    CAJA_FUERTE: 'CAJA_FUERTE',
    GAVETA: 'GAVETA',
    ZONA: 'ZONA',
    PALETIZADO: 'PALETIZADO',
    ANAQUEL: 'ANAQUEL',
    EXHIBIDOR: 'EXHIBIDOR',
    BANDEJA: 'BANDEJA',
} as const;

export type TipoUbicacion = typeof TIPO_UBICACION[keyof typeof TIPO_UBICACION];

export const CODIGO_TIPO_UBICACION = {
    ESTANTERIA: 'EST',
    RACK: 'RCK',
    VITRINA: 'VIT',
    REFRIGERADOR: 'REF',
    CONGELADOR: 'CON',
    ARMARIO: 'ARM',
    CAJA_FUERTE: 'CF',
    GAVETA: 'GAV',
    ZONA: 'ZON',
    PALETIZADO: 'PAL',
    ANAQUEL: 'ANA',
    EXHIBIDOR: 'EXP',
    BANDEJA: 'BAN',
} as const;

export type CodigoTipoUbicacion = typeof CODIGO_TIPO_UBICACION[keyof typeof CODIGO_TIPO_UBICACION];

export interface NivelJerarquia {
    tipo: string;
    valor: string;
}

export interface JerarquiaUbicacion {
    tipo: string;
    valor: string;
    nivel?: string;
    camino: string;
    niveles?: NivelJerarquia[];
}

interface GeneracionConfig {
    tipoSecuencia: 'LETRAS' | 'NUMEROS' | 'PREFIJO_NUMERO' | 'DESCRIPTIVO';
    prefijo?: string;
    longitudMinima?: number;
    valoresPredefinidos?: string[];
    maxCombinaciones?: number;
}

export const CONFIG_GENERACION_POR_TIPO: Record<TipoUbicacion, GeneracionConfig> = {
    ESTANTERIA: {
        tipoSecuencia: 'LETRAS',
        maxCombinaciones: 3,
    },
    RACK: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'R-',
        longitudMinima: 2,
    },
    REFRIGERADOR: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'REF-',
        longitudMinima: 2,
    },
    CONGELADOR: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'CON-',
        longitudMinima: 2,
    },
    VITRINA: {
        tipoSecuencia: 'DESCRIPTIVO',
        valoresPredefinidos: [],
    },
    ARMARIO: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'ARM-',
        longitudMinima: 2,
    },
    CAJA_FUERTE: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'CF-',
        longitudMinima: 2,
    },
    GAVETA: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'GAV-',
        longitudMinima: 2,
    },
    ZONA: {
        tipoSecuencia: 'DESCRIPTIVO',
        valoresPredefinidos: [],
    },
    PALETIZADO: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'PAL-',
        longitudMinima: 2,
    },
    ANAQUEL: {
        tipoSecuencia: 'LETRAS',
        maxCombinaciones: 2,
    },
    EXHIBIDOR: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'EXP-',
        longitudMinima: 2,
    },
    BANDEJA: {
        tipoSecuencia: 'PREFIJO_NUMERO',
        prefijo: 'BAN-',
        longitudMinima: 2,
    },
};

export interface TipoUbicacionMetadata {
    tipo: string;
    codigo: string;
    descripcion: string;
    config: GeneracionConfig;
}

export const TIPO_UBICACION_METADATA: Record<TipoUbicacion, TipoUbicacionMetadata> = {
    ESTANTERIA: {
        tipo: 'ESTANTERIA',
        codigo: 'EST',
        descripcion: 'Estanterías estándar para almacenamiento general de productos. Ideales para medicamentos, cosméticos y productos de consumo regular.',
        config: CONFIG_GENERACION_POR_TIPO.ESTANTERIA,
    },
    RACK: {
        tipo: 'RACK',
        codigo: 'RCK',
        descripcion: 'Racks industriales para carga pesada y almacenamiento de productos voluminosos. Utilizados para materiales médicos, equipos y productos de gran tamaño.',
        config: CONFIG_GENERACION_POR_TIPO.RACK,
    },
    VITRINA: {
        tipo: 'VITRINA',
        codigo: 'VIT',
        descripcion: 'Exhibidores visibles al cliente para productos de alta rotación, cosmética, perfumería y artículos promocionales. Diseñados para atraer la atención del cliente.',
        config: CONFIG_GENERACION_POR_TIPO.VITRINA,
    },
    REFRIGERADOR: {
        tipo: 'REFRIGERADOR',
        codigo: 'REF',
        descripcion: 'Equipos de refrigeración (2°C a 8°C) para vacunas, insulinas, biológicos y medicamentos termolábiles que requieren cadena de frío controlada.',
        config: CONFIG_GENERACION_POR_TIPO.REFRIGERADOR,
    },
    CONGELADOR: {
        tipo: 'CONGELADOR',
        codigo: 'CON',
        descripcion: 'Equipos de congelación (-18°C o menor) para productos biológicos, hemoderivados y medicamentos que requieren congelación profunda para su conservación.',
        config: CONFIG_GENERACION_POR_TIPO.CONGELADOR,
    },
    ARMARIO: {
        tipo: 'ARMARIO',
        codigo: 'ARM',
        descripcion: 'Armarios con puertas para almacenamiento cerrado de productos que requieren protección contra luz, polvo o humedad. Incluye medicamentos controlados y material médico.',
        config: CONFIG_GENERACION_POR_TIPO.ARMARIO,
    },
    CAJA_FUERTE: {
        tipo: 'CAJA_FUERTE',
        codigo: 'CF',
        descripcion: 'Almacenamiento de alta seguridad para medicamentos controlados, psicotrópicos, estupefacientes y sustancias fiscalizadas que requieren control estricto de acceso.',
        config: CONFIG_GENERACION_POR_TIPO.CAJA_FUERTE,
    },
    GAVETA: {
        tipo: 'GAVETA',
        codigo: 'GAV',
        descripcion: 'Cajones o gavetas para almacenamiento de productos pequeños, medicamentos en dosis unitarias, material de oficina y suministros de tamaño reducido.',
        config: CONFIG_GENERACION_POR_TIPO.GAVETA,
    },
    ZONA: {
        tipo: 'ZONA',
        codigo: 'ZON',
        descripcion: 'Áreas operativas sin estructura física definida. Utilizadas para zonas de recepción, despacho, cuarentena, tránsito o áreas de trabajo que no requieren ubicaciones físicas específicas.',
        config: CONFIG_GENERACION_POR_TIPO.ZONA,
    },
    PALETIZADO: {
        tipo: 'PALETIZADO',
        codigo: 'PAL',
        descripcion: 'Productos almacenados en pallets. Utilizado para mercadería a granel, productos de alta rotación o material que se maneja en unidades de carga completa.',
        config: CONFIG_GENERACION_POR_TIPO.PALETIZADO,
    },
    ANAQUEL: {
        tipo: 'ANAQUEL',
        codigo: 'ANA',
        descripcion: 'Anaqueles pequeños para productos ligeros, juguetes, libros, material de oficina y artículos de consumo que no requieren grandes espacios de almacenamiento.',
        config: CONFIG_GENERACION_POR_TIPO.ANAQUEL,
    },
    EXHIBIDOR: {
        tipo: 'EXHIBIDOR',
        codigo: 'EXP',
        descripcion: 'Exhibidores promocionales en punto de venta para campañas especiales, lanzamiento de productos, ofertas y material de merchandising. Diseñados para maximizar visibilidad.',
        config: CONFIG_GENERACION_POR_TIPO.EXHIBIDOR,
    },
    BANDEJA: {
        tipo: 'BANDEJA',
        codigo: 'BAN',
        descripcion: 'Bandejas dentro de refrigeradores o congeladores para organizar productos termolábiles por lotes, medicamentos o categorías. Optimiza el espacio en equipos de frío.',
        config: CONFIG_GENERACION_POR_TIPO.BANDEJA,
    },
};

// Obtiene la descripción de un tipo de ubicación.
export function getDescripcionTipo(tipo: TipoUbicacion): string {
    return TIPO_UBICACION_METADATA[tipo]?.descripcion || 'Tipo de ubicación sin descripción';
}

// Obtiene el código de un tipo de ubicación.
export function getCodigoTipo(tipo: TipoUbicacion): string {
    return TIPO_UBICACION_METADATA[tipo]?.codigo || CODIGO_TIPO_UBICACION[tipo] || 'NIN';
}

// Obtiene todos los tipos de ubicación con sus metadatos
export function obtenerTodosLosTiposUbicacion(): TipoUbicacionMetadata[] {
    return Object.values(TIPO_UBICACION_METADATA);
}

// Obtiene los tipos de ubicación para combos (frontend).
export function obtenerTiposUbicacionParaCombos(): { label: string; value: string; codigo: string; descripcion: string }[] {
    return Object.values(TIPO_UBICACION_METADATA).map(meta => ({
        label: meta.tipo.charAt(0) + meta.tipo.slice(1).toLowerCase().replace('_', ' '),
        value: meta.tipo,
        codigo: meta.codigo,
        descripcion: meta.descripcion,
    }));
}
