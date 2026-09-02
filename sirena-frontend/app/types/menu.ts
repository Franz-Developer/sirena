// C:\sirena\sirena-frontend\app\types\menu.ts
export interface RawMenuItem {
    menu_id: number;
    menu_padre_id: number | null;
    titulo: string;
    icono?: string;
    url?: string;
    children?: RawMenuItem[];
}

export interface MenuItem {
    label: string;
    icon?: string;
    to?: string;
    items?: MenuItem[];
}
