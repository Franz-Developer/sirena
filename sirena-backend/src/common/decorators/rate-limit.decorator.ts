// C:\sirena\sirena-backend\src\common\decorators\rate-limit.decorator.ts
import { applyDecorators } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Throttle } from '@nestjs/throttler';

// ═══════════════════════════════════════════
// OBTENER CONFIGURACIÓN DESDE .env
// ═══════════════════════════════════════════
const getConfig = (key: string, defaultValue: any): { limit: number; ttl: number } => {
    const configService = new ConfigService();
    const limit = configService.get<number>(`${key}_LIMIT`, defaultValue.limit);
    const ttl = configService.get<number>(`${key}_TTL`, defaultValue.ttl);
    return { limit, ttl };
};

// ═══════════════════════════════════════════
// AUTH - Endpoints de autenticación
// ═══════════════════════════════════════════
export const LoginRateLimit = () => {
    const config = getConfig('RATE_LIMIT_AUTH_LOGIN', { limit: 5, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

export const RegisterRateLimit = () => {
    const config = getConfig('RATE_LIMIT_AUTH_REGISTER', { limit: 3, ttl: 300 });
    return applyDecorators(Throttle({ default: config }));
};

export const RecoverRateLimit = () => {
    const config = getConfig('RATE_LIMIT_AUTH_RECOVER', { limit: 3, ttl: 300 });
    return applyDecorators(Throttle({ default: config }));
};

// ═══════════════════════════════════════════
// CRUD - Operaciones de escritura
// ═══════════════════════════════════════════
export const CreateRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CRUD_CREATE', { limit: 20, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

export const UpdateRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CRUD_UPDATE', { limit: 20, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

export const DeleteRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CRUD_DELETE', { limit: 10, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

export const ArchiveRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CRUD_ARCHIVE', { limit: 10, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

// ═══════════════════════════════════════════
// READ - Operaciones de lectura
// ═══════════════════════════════════════════
export const FindAllRateLimit = () => {
    const config = getConfig('RATE_LIMIT_READ_FIND_ALL', { limit: 100, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

export const FindOneRateLimit = () => {
    const config = getConfig('RATE_LIMIT_READ_FIND_ONE', { limit: 100, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

// ═══════════════════════════════════════════
// CONSTANTES - Datos estáticos (límite más alto)
// ═══════════════════════════════════════════
export const ConstantesRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CONSTANTES', { limit: 500, ttl: 60 });
    return applyDecorators(Throttle({ default: config }));
};

// ═══════════════════════════════════════════
// CRITICAL - Operaciones críticas
// ═══════════════════════════════════════════
export const DeletePermanentRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CRITICAL_DELETE_PERMANENT', { limit: 3, ttl: 300 });
    return applyDecorators(Throttle({ default: config }));
};

export const BulkOperationRateLimit = () => {
    const config = getConfig('RATE_LIMIT_CRITICAL_BULK_OPERATION', { limit: 5, ttl: 300 });
    return applyDecorators(Throttle({ default: config }));
};
