// C:\sirena\sirena-frontend\app\types\menu.ts

/**
 * Item de menú tal como lo devuelve el backend.
 * Acepta alias por compatibilidad: titulo, icono, url.
 * El backend puede enviar `null` en `to`/`url`, pero aquí se acepta.
 */
export interface MenuItemBackend {
    label?: string;
    icon?: string;
    to?: string | null;
    items?: MenuItemBackend[];
    titulo?: string;
    icono?: string;
    url?: string | null;
}

/**
 * Item de menú normalizado para la UI (compatible con PrimeVue PanelMenu).
 *
 * IMPORTANTE: `to` y `url` son `string | undefined` (SIN null)
 * porque PrimeVue no acepta `null`. El store se encarga de convertir
 * cualquier `null` del backend a `undefined`.
 */
export interface MenuItem {
    label: string;
    icon?: string;
    to?: string;
    url?: string;
    key?: string;
    items?: MenuItem[];

    // Extras compatibles con PrimeVue (opcionales)
    command?: (event: any) => void;
    disabled?: boolean;
    visible?: boolean;
    target?: string;
    class?: string;
    style?: string;
}

/**
 * Permisos granulares por tabla.
 * Clave = nombre de la tabla (ej: 'empresas', 'kardex', 'clientes').
 */
export interface PermisosTabla {
    crear: boolean;
    editar: boolean;
    eliminar: boolean;
    leer: boolean;
    anular: boolean;
    archivar: boolean;
    desarchivar: boolean;
}

export interface PermisosMap {
    [nombreTabla: string]: PermisosTabla;
}
