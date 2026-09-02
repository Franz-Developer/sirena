// C:\sirena\sirena-backend\src\common\helpers\ubicaciones.helper.ts
import { TIPO_UBICACION, CODIGO_TIPO_UBICACION, TipoUbicacion, CodigoTipoUbicacion, JerarquiaUbicacion, CONFIG_GENERACION_POR_TIPO } from '../constants/ubicaciones.constants';

// FUNCIONES DE GENERACIÓN DE VALORES.
export function generarValoresLetras(cantidad: number, maxCombinaciones: number = 2): string[] {
    const valores: string[] = [];
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    function generarCombinaciones(prefix: string, length: number) {
        if (length === 0) {
            if (prefix) valores.push(prefix);
            return;
        }
        for (const letra of letras) {
            generarCombinaciones(prefix + letra, length - 1);
        }
    }

    for (let i = 1; i <= maxCombinaciones; i++) {
        if (valores.length >= cantidad) break;
        generarCombinaciones('', i);
    }

    return valores.slice(0, cantidad);
}

export function generarValoresConPrefijo(
    cantidad: number,
    prefijo: string,
    longitudMinima: number = 2,
): string[] {
    const valores: string[] = [];
    for (let i = 1; i <= cantidad; i++) {
        const numero = String(i).padStart(longitudMinima, '0');
        valores.push(`${prefijo}${numero}`);
    }
    return valores;
}

export function obtenerValoresPredefinidos(tipo: TipoUbicacion): string[] | null {
    const config = CONFIG_GENERACION_POR_TIPO[tipo];
    if (config.tipoSecuencia === 'DESCRIPTIVO') {
        return config.valoresPredefinidos || null;
    }
    return null;
}

export function generarValoresParaTipo(tipo: TipoUbicacion, cantidad: number): string[] {
    const config = CONFIG_GENERACION_POR_TIPO[tipo];

    switch (config.tipoSecuencia) {
        case 'LETRAS':
            return generarValoresLetras(cantidad, config.maxCombinaciones || 2);

        case 'PREFIJO_NUMERO':
            return generarValoresConPrefijo(cantidad, config.prefijo || '', config.longitudMinima || 2);

        case 'DESCRIPTIVO':
            const predefinidos = config.valoresPredefinidos || [];
            if (cantidad <= predefinidos.length) {
                return predefinidos.slice(0, cantidad);
            }
            const extras = cantidad - predefinidos.length;
            const codigoTipo = CODIGO_TIPO_UBICACION[tipo];
            const adicionales = generarValoresConPrefijo(extras, `${codigoTipo}-`, 2);
            return [...predefinidos, ...adicionales];

        default:
            return [];
    }
}

// FUNCIONES DE GENERACIÓN DE CÓDIGO Y JERARQUÍA (TIPADAS).
export function generarCodigoUbicacion(
    tipo: TipoUbicacion,
    valor: string,
    nivel?: number,
): string {
    const prefijo = CODIGO_TIPO_UBICACION[tipo];
    const valorLimpio = valor.replace(/^[A-Z]+-/, '');
    let codigo = `${prefijo}-${valorLimpio}`;

    if (nivel !== undefined && nivel !== null) {
        codigo += `-${nivel}`;
    }

    return codigo;
}

export function generarJerarquiaUbicacion(
    tipo: TipoUbicacion,
    valor: string,
    nivel?: number,
): JerarquiaUbicacion {
    const jerarquia: JerarquiaUbicacion = {
        tipo: tipo,
        valor: valor,
        camino: '',
    };

    if (nivel !== undefined && nivel !== null) {
        jerarquia.nivel = nivel.toString();
    }

    let camino = `${tipo} ${valor}`;
    if (nivel) {
        camino += ` > NIVEL ${nivel}`;
    }
    jerarquia.camino = camino;

    return jerarquia;
}

// Genera jerarquía con estructura de niveles para JSONB (para ubicaciones complejas).
export function generarJerarquiaConNiveles(
    tipo: TipoUbicacion,
    valor: string,
    niveles: Array<{ tipo: string; valor: string }>,
): JerarquiaUbicacion {
    const nivelesCopia = niveles.map(n => ({ tipo: n.tipo, valor: n.valor }));

    const jerarquia: JerarquiaUbicacion = {
        tipo: tipo,
        valor: valor,
        niveles: nivelesCopia,
        camino: `${tipo} ${valor} > ${niveles.map(n => `${n.tipo} ${n.valor}`).join(' > ')}`,
    };
    return jerarquia;
}

// FUNCIONES DE VALIDACIÓN.
export function esTipoUbicacionValido(tipo: string): boolean {
    return Object.values(TIPO_UBICACION).includes(tipo as TipoUbicacion);
}

export function esCodigoTipoValido(codigo: string): boolean {
    return Object.values(CODIGO_TIPO_UBICACION).includes(codigo as CodigoTipoUbicacion);
}

export function esJerarquiaValida(jerarquia: JerarquiaUbicacion): boolean {
    if (!jerarquia.tipo || !jerarquia.valor || !jerarquia.camino) {
        return false;
    }
    if (!esTipoUbicacionValido(jerarquia.tipo)) {
        return false;
    }
    return true;
}

// FUNCIONES PARA OBTENER LISTAS (PARA COMBOBOX).
export function obtenerTiposUbicacion(): { label: string; value: string }[] {
    return Object.entries(TIPO_UBICACION).map(([key, value]) => ({
        label: key.charAt(0) + key.slice(1).toLowerCase().replace('_', ' '),
        value: value,
    }));
}

export function obtenerCodigosTipo(): { label: string; value: string }[] {
    return Object.entries(CODIGO_TIPO_UBICACION).map(([key, value]) => ({
        label: key.charAt(0) + key.slice(1).toLowerCase().replace('_', ' '),
        value: value,
    }));
}
