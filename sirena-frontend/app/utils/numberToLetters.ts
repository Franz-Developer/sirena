// C:\sirena\sirena-frontend\app\utils\numberToLetters.ts

/**
 * Convierte un monto numérico a letras en español (formato boliviano).
 *
 * @example
 *   numberToLetters(1234.56) → "MIL DOSCIENTOS TREINTA Y CUATRO CON 56/100 Bs."
 *   numberToLetters(0)       → "CERO CON 00/100 Bs."
 *   numberToLetters(100)     → "CIEN CON 00/100 Bs."
 *   numberToLetters(101)     → "CIENTO UNO CON 00/100 Bs."
 *   numberToLetters(21)      → "VEINTIUNO CON 00/100 Bs."
 *   numberToLetters(1)       → "UNO CON 00/100 Bs."
 *   numberToLetters(1000000) → "UN MILLÓN CON 00/100 Bs."
 */
export function numberToLetters(amount: number): string {
    if (!Number.isFinite(amount) || amount < 0 || amount > 1_000_000_000) {
        throw new Error('El monto debe estar entre 0 y 1,000,000,000');
    }

    // ─────────────────────────────────────────────
    // Tablas de conversión
    // ─────────────────────────────────────────────
    const UNIDADES = [
        '', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO',
        'SEIS', 'SIETE', 'OCHO', 'NUEVE',
    ] as const;

    const ESPECIALES = [
        'DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE',
        'QUINCE', 'DIECISÉIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE',
    ] as const;

    const DECENAS = [
        '', '', 'VEINTE', 'TREINTA', 'CUARENTA',
        'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA',
    ] as const;

    const CENTENAS = [
        '', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS',
        'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS',
    ] as const;

    // ─────────────────────────────────────────────
    // Convierte un número menor a 1000 a letras
    // ─────────────────────────────────────────────
    function convertirMenorMil(n: number): string {
        if (n === 0) return '';
        if (n === 100) return 'CIEN';

        let texto = '';
        const c = Math.floor(n / 100);
        const resto = n % 100;
        const d = Math.floor(resto / 10);
        const u = resto % 10;

        // Centenas
        if (c > 0) {
            texto += CENTENAS[c] + ' ';
        }

        // Decenas y unidades
        if (resto >= 10 && resto < 20) {
            // 10-19
            texto += ESPECIALES[resto - 10];
        } else if (resto >= 20 && resto < 30) {
            // 20-29: VEINTE, VEINTIUNO, VEINTIDÓS, ...
            if (resto === 20) {
                texto += 'VEINTE';
            } else {
                texto += 'VEINTI' + UNIDADES[u];
            }
        } else if (resto >= 30) {
            // 30-99: TREINTA Y UNO, ...
            texto += DECENAS[d];
            if (u > 0) {
                texto += ' Y ' + UNIDADES[u];
            }
        } else if (resto > 0) {
            // 1-9
            texto += UNIDADES[resto];
        }

        return texto.trim();
    }

    // ─────────────────────────────────────────────
    // Convierte un número entero a letras
    // ─────────────────────────────────────────────
    function convertirNumero(n: number): string {
        if (n === 0) return 'CERO';

        let texto = '';

        const milMillones = Math.floor(n / 1_000_000_000);
        const millones = Math.floor((n % 1_000_000_000) / 1_000_000);
        const miles = Math.floor((n % 1_000_000) / 1000);
        const cientos = n % 1000;

        // Mil millones
        if (milMillones > 0) {
            if (milMillones === 1) {
                texto += 'MIL MILLONES ';
            } else {
                texto += convertirMenorMil(milMillones) + ' MIL MILLONES ';
            }
        }

        // Millones
        if (millones > 0) {
            if (millones === 1) {
                texto += 'UN MILLÓN ';
            } else {
                texto += convertirMenorMil(millones) + ' MILLONES ';
            }
        }

        // Miles
        if (miles > 0) {
            if (miles === 1) {
                texto += 'MIL ';
            } else {
                texto += convertirMenorMil(miles) + ' MIL ';
            }
        }

        // Cientos
        if (cientos > 0) {
            texto += convertirMenorMil(cientos);
        }

        return texto.trim();
    }

    // ─────────────────────────────────────────────
    // Manejo de decimales (redondeo correcto)
    // ─────────────────────────────────────────────
    // Redondeamos el monto total a 2 decimales primero para evitar
    // que 1.999 se convierta en "UNO CON 00/100" en lugar de "DOS CON 00/100".
    const redondeado = Math.round(amount * 100) / 100;
    const entero = Math.floor(redondeado);
    const decimal = Math.round((redondeado - entero) * 100);

    // ─────────────────────────────────────────────
    // Conversión
    // ─────────────────────────────────────────────
    let letras = convertirNumero(entero);

    // ─────────────────────────────────────────────
    // Ajustes finales (apócopes)
    // ─────────────────────────────────────────────
    // "VEINTIUNO" → "VEINTIÚN" (con tilde según RAE para el apócope)
    // Nota: en documentos legales bolivianos se acepta "VEINTIUN" sin tilde.
    letras = letras.replace(/VEINTIUNO\b/g, 'VEINTIÚN');

    // "UNO" → "UN" SOLO cuando va seguido de MIL, MILLÓN, MILLONES o al final
    // Ejemplos:
    //   "TREINTA Y UNO MIL" → "TREINTA Y UN MIL"
    //   "CIENTO UNO"        → "CIENTO UNO"  (NO se apocopa)
    //   "UNO" (solo)        → "UNO"          (se mantiene)
    letras = letras.replace(/\bUNO(?=\s+(?:MIL|MILLÓN|MILLONES)\b)/g, 'UN');

    // ─────────────────────────────────────────────
    // Resultado final
    // ─────────────────────────────────────────────
    const decimalStr = decimal.toString().padStart(2, '0');
    return `${letras} CON ${decimalStr}/100 Bs.`;
}
