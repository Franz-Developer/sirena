// C:\sirena\sirena-backend\src\common\utils\crypto.util.ts
import * as bcrypt from 'bcrypt';

const SALT_ROUNDS = 12; // ✅ 12 es el estándar recomendado

/**
 * Encripta una contraseña usando bcrypt con salt rounds 12
 */
export async function hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * Verifica una contraseña contra un hash
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
}

/**
 * Verifica si un hash usa salt rounds adecuados (>= 12)
 *
 * @param hash - El hash de bcrypt a verificar
 * @returns true si el hash usa salt rounds >= 12, false en caso contrario
 */
export function isSecureHash(hash: string | undefined | null): boolean {
    if (!hash || typeof hash !== 'string') {
        return false;
    }

    const match = hash.match(/^\$2[aby]\$(\d{2})\$/);
    // ✅ Validar que match exista y que el grupo 1 esté definido antes de usarlo
    if (!match || !match[1]) return false;

    const rounds = parseInt(match[1], 10);
    return rounds >= 12;
}

/**
 * Obtiene el número de salt rounds de un hash
 */
export function getSaltRounds(hash: string | undefined | null): number | null {
    if (!hash || typeof hash !== 'string') {
        return null;
    }

    const match = hash.match(/^\$2[aby]\$(\d{2})\$/);
    if (!match || !match[1]) return null;

    return parseInt(match[1], 10);
}
