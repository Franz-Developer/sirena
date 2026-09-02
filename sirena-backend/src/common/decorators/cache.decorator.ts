// C:\sirena\sirena-backend\src\common\decorators\cache.decorator.ts

import { SetMetadata } from '@nestjs/common';
import { CACHE_KEY, CACHE_TTL } from '../interceptors/cache.interceptor';

export function getCacheTTL(envKey: string, fallbackMs: number): number {
    const value = process.env[envKey];
    if (value) {
        const parsed = parseInt(value, 10);
        if (!isNaN(parsed) && parsed > 0) {
            return parsed * 1000; // Convertir segundos a milisegundos
        }
    }
    return fallbackMs;
}

// =============================================
// TTL PREDEFINIDOS CON PROPÓSITO CLARO
// =============================================

// 1. CACHE_LARGO: Para datos maestros que cambian poco (24 horas)
export const CACHE_LARGO = getCacheTTL('CACHE_TTL_MAESTROS', 86400000);

// 2. CACHE_1H: Para datos que se actualizan cada hora
export const CACHE_1H = getCacheTTL('CACHE_TTL_TIPOS_CAMBIOS', 3600000);

// 3. CACHE_DEFAULT: Para la mayoría de endpoints (5 minutos)
export const CACHE_DEFAULT = getCacheTTL('CACHE_TTL_DEFAULT', 300000);

// =============================================
// NOTA: Las siguientes constantes han sido ELIMINADAS:
// - CACHE_24H  → Reemplazada por CACHE_LARGO
// - CACHE_5MIN → Reemplazada por CACHE_DEFAULT
// =============================================
export function Cache(key: string, ttl: number = CACHE_DEFAULT) {
    return (target: any, propertyKey: string, descriptor: PropertyDescriptor) => {
        SetMetadata(CACHE_KEY, key)(target, propertyKey, descriptor);
        SetMetadata(CACHE_TTL, ttl)(target, propertyKey, descriptor);
    };
}
