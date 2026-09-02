// C:\sirena\sirena-backend\src\common\utils\string.util.ts

/**
 * Genera una expresión SQL para normalizar texto para búsquedas.
 *
 * Reglas:
 * - ignora mayúsculas/minúsculas;
 * - ignora acentos;
 * - conserva la diferencia entre n y ñ;
 * - elimina espacios externos.
 *
 * Requiere la función PostgreSQL fn_normalize_search().
 */
export const SQL_NORMALIZE_SEARCH = (column: string): string => {
    return `fn_normalize_search(TRIM(${column}))`;
};
