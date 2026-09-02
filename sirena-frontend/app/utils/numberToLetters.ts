// C:\sirena\sirena-frontend\app\utils\numberToLetters.ts
export function numberToLetters(amount: number): string {
    if (amount < 0 || amount > 1000000000) {
        throw new Error('El monto debe estar entre 0 y 1,000,000,000');
    }

    const unidades = ['', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE'] as const;
    const especiales = ['DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE', 'DIECISÉIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE'] as const;
    const decenas = ['', '', 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'] as const;
    const centenas = ['', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'] as const;

    function convertirMenorMil(n: number): string {
        if (n === 0) { return ''; }
        if (n === 100) { return 'CIEN'; }

        let texto = '';
        const c = Math.floor(n / 100);
        const d = Math.floor((n % 100) / 10);
        const u = n % 10;
        if (c > 0) { texto += (centenas[c] ?? '') + ' '; }
        const resto = n % 100;
        if (resto >= 10 && resto < 20) {
            texto += especiales[resto - 10] ?? '';
        } else if (resto >= 20 && resto < 30) {
            if (resto === 20) { texto += 'VEINTE'; }
            else { texto += 'VEINTI' + (unidades[u] ?? ''); }
        } else {
            if (d > 0) {
                texto += decenas[d] ?? '';
                if (u > 0) { texto += ' Y '; }
            }
            if (u > 0) { texto += unidades[u] ?? ''; }
        }
        return texto.trim();
    }

    function convertirNumero(n: number): string {
        if (n === 0) { return 'CERO'; }
        let texto = '';
        const milMillones = Math.floor(n / 1000000000);
        const millones = Math.floor((n % 1000000000) / 1000000);
        const miles = Math.floor((n % 1000000) / 1000);
        const cientos = n % 1000;

        if (milMillones > 0) {
            if (milMillones === 1) { texto += 'MIL MILLONES '; }
            else { texto += convertirMenorMil(milMillones) + ' MIL MILLONES '; }
        }

        if (millones > 0) {
            if (millones === 1) { texto += 'UN MILLÓN '; }
            else { texto += convertirMenorMil(millones) + ' MILLONES '; }
        }

        if (miles > 0) {
            if (miles === 1) { texto += 'MIL '; }
            else { texto += convertirMenorMil(miles) + ' MIL '; }
        }

        if (cientos > 0) { texto += convertirMenorMil(cientos); }
        return texto.trim();
    }

    const entero = Math.floor(amount);
    let decimal = Math.round((amount - entero) * 100);
    if (decimal === 100) { decimal = 0; }
    let letras = convertirNumero(entero);
    letras = letras
        .replace(/VEINTIUNO/g, 'VEINTIUN')
        .replace(/ Y UNO/g, ' Y UN')
        .replace(/UNO$/, 'UN');
    const decimalStr = decimal.toString().padStart(2, '0');
    return `${letras} CON ${decimalStr}/100 Bs.`;
}
