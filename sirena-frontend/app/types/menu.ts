// C:\sirena\sirena-frontend\app\types\menu.ts

/**
 * Item de menú tal como lo devuelve el backend.
 * El backend devuelve menús puros: label, icon, to, items.
 * Los permisos viajan aparte, en un mapa por tabla.
 */
export interface MenuItem {
    label: string;
    icon?: string;
    to?: string | null;
    items?: MenuItem[];
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
