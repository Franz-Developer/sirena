// C:\sirena\sirena-backend\src\common\utils\typeorm-transformers.util.ts

/**
 * Transformador para columnas de tipo BIGINT en PostgreSQL.
 *
 * Maneja la conversión entre el tipo `bigint` de PostgreSQL (que retorna como string)
 * y el tipo `number` de TypeScript.
 */
export const bigintTransformer = {
    to: (value: number): number => value,
    from: (value: string | null): number | null =>
        (value !== null && value !== undefined) ? parseInt(value, 10) : null
};
