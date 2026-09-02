// C:\sirena\sirena-backend\src\common\utils\menu-parser.util.ts

/**
 * Transforma un arreglo plano de registros de menú relacionales en una estructura jerárquica de árbol.
 *
 * Itera sobre las filas proporcionadas, mapeando cada elemento con sus respectivas propiedades,
 * permisos y submenús (`items`), relacionando los nodos hijos con sus padres mediante `menu_padre_id`.
 *
 * @param rows - Arreglo plano de objetos con la información de los menús obtenidos de la base de datos.
 * @returns Un arreglo con los nodos raíz (`menuTree`) que contienen la estructura anidada de menús e hijos.
 */
export function estructurarMenu(rows: any[]) {
    const map: any = {};
    const menuTree: any[] = [];

    rows.forEach(row => {
        map[row.menu_id] = {
            label: row.titulo,
            icon: row.icono,
            to: row.url || null,
            items: [],
            permissions: {
                crear: row.crear === 1,
                editar: row.editar === 1,
                eliminar: row.eliminar === 1
            }
        };
    });

    rows.forEach(row => {
        if (row.menu_padre_id !== null) {
            if (map[row.menu_padre_id]) {
                map[row.menu_padre_id].items.push(map[row.menu_id]);
            }
        } else {
                menuTree.push(map[row.menu_id]);
        }
    });
    return menuTree;
}
