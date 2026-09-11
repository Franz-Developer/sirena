// C:\sirena\sirena-backend\src\common\utils\menu-parser.util.ts

export interface MenuItemEstructurado {
    label: string;
    icon: string | null;
    to: string | null;
    items: MenuItemEstructurado[];
}

/**
 * Transforma un arreglo plano de registros de menú relacionales
 * en una estructura jerárquica de árbol.
 */
export function estructurarMenu(rows: any[]): MenuItemEstructurado[] {
    const map = new Map<number, MenuItemEstructurado>();
    const menuTree: MenuItemEstructurado[] = [];

    // 1. Crear el mapa de nodos
    rows.forEach(row => {
        map.set(row.menu_id, {
            label: row.titulo,
            icon: row.icono || null,
            to: row.url || null,
            items: [],
        });
    });

    // 2. Construir el árbol jerárquico
    rows.forEach(row => {
        const nodo = map.get(row.menu_id);
        if (!nodo) return;

        if (row.menu_padre_id !== null) {
            const padre = map.get(row.menu_padre_id);
            if (padre) {
                padre.items.push(nodo);
            }
        } else {
            menuTree.push(nodo);
        }
    });

    return menuTree;
}
