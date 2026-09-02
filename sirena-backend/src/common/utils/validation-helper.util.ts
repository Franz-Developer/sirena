// C:\sirena\sirena-backend\src\common\utils\validation-helper.util.ts

export function createEnumMessage<T extends number>(
    metadata: Record<number, { abreviatura: string }>,
    values: readonly T[] | T[],
    fieldName: string
): (args?: any) => string {
    return (args?: any) => {
        const validValues = values as T[];

        const invalidValue = args?.value !== undefined && args?.value !== null
            ? args.value
            : 'valor inválido';

        const formattedValues = validValues.map((id) => {
            const meta = metadata[id];
            const name = meta?.abreviatura;
            return name ? `${id}(${name})` : `${id}`;
        });

        return `${fieldName} "${invalidValue}" debe ser: ${formattedValues.join(', ')}`;
    };
}

export function getEnumValues(
    enumObject: Record<string, any>
): number[] {
    return Object.values(enumObject).filter((v) => typeof v === 'number') as number[];
}