// C:\sirena\sirena-backend\src\common\utils\date-formatter.util.ts

/**
 * Formatea marcas de tiempo con zona horaria (TIMESTAMPTZ) para la API,
 * aplicando la zona horaria de Bolivia ('America/La_Paz'), milisegundos y el offset real.
 *
 * @param value - Valor de fecha a formatear (puede ser string, objeto Date o timestamp).
 * @returns La fecha y hora formateada en formato `YYYY-MM-DD HH:mm:ss.SSS ±HH:MM`, o `null` si el valor es inválido.
 */
export const formatLocalDate = (value: any): string | null => {
    if (!value) return null;

    const date = new Date(value);
    if (isNaN(date.getTime())) return null;

    // 1. Usar Intl para formatear la fecha según America/La_Paz
    const formatter = new Intl.DateTimeFormat('sv-SE', {
        timeZone: 'America/La_Paz',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
    });

    const parts = formatter.formatToParts(date);
    const get = (type: string) => parts.find(p => p.type === type)?.value ?? '';
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');

    const fecha = `${get('year')}-${get('month')}-${get('day')} ${get('hour')}:${get('minute')}:${get('second')}.${milliseconds}`;

    // 2. ✅ Cálculo dinámico del offset REAL
    const timezoneOffset = -date.getTimezoneOffset();
    const offsetSign = timezoneOffset >= 0 ? '+' : '-';
    const offsetHours = String(Math.floor(Math.abs(timezoneOffset) / 60)).padStart(2, '0');
    const offsetMinutes = String(Math.abs(timezoneOffset) % 60).padStart(2, '0');

    return `${fecha} ${offsetSign}${offsetHours}:${offsetMinutes}`;
};

/**
 * Formatea campos exclusivamente de FECHA (DATE: YYYY-MM-DD),
 * evitando desfases indeseados provocados por la conversión de zona horaria.
 *
 * @param value - Valor de fecha a formatear (string `YYYY-MM-DD`, objeto Date o timestamp).
 * @returns La fecha limpia en formato `YYYY-MM-DD`, o `null` si el valor es inválido.
 */
export const formatOnlyDate = (value: any): string | null => {
    if (!value) return null;
    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
        return value;
    }
    const date = new Date(value);
    if (isNaN(date.getTime())) return null;

    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};
