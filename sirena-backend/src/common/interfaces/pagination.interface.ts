// C:\sirena\sirena-backend\src\common\interfaces\pagination.interface.ts

/**
 * Interfaz genérica para estructurar los resultados de una consulta paginada.
 *
 * @template T - Tipo de los elementos que contiene el arreglo de datos.
 */
export interface PaginatedResult<T> {
    /** Arreglo con los registros obtenidos en la página actual. */
    data: T[];

    /** Cantidad total de registros disponibles en la base de datos que coinciden con la consulta (sin paginación). */
    total: number;

    /** Cantidad máxima de registros que se solicitaron por página. */
    limit: number;

    /** Cantidad de registros que se omitieron al inicio de la consulta. */
    offset: number;
}
