// C:\sirena\sirena-backend\src\common\interceptors\cache.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { CacheService } from '../services/cache.service';

export const CACHE_KEY = 'cache_key';
export const CACHE_TTL = 'cache_ttl';

@Injectable()
export class CacheInterceptor implements NestInterceptor {
    constructor(
        private readonly cacheService: CacheService,
        private readonly reflector: Reflector,
    ) {}

    async intercept(
        context: ExecutionContext,
        next: CallHandler,
    ): Promise<Observable<any>> {
        // Solo GET requests
        const request = context.switchToHttp().getRequest();
        if (request.method !== 'GET') {
            return next.handle();
        }

        // Obtener metadatos del decorador
        const cacheKey = this.reflector.get<string>(
            CACHE_KEY,
            context.getHandler(),
        );
        const ttl = this.reflector.get<number>(
            CACHE_TTL,
            context.getHandler(),
        );

        // Si no hay cacheKey, no cachear
        if (!cacheKey) {
            return next.handle();
        }

        // Generar key con parámetros de consulta
        const queryString = JSON.stringify(request.query || {});
        const fullKey = `${cacheKey}:${queryString}`;

        // Intentar obtener del caché
        const cached = await this.cacheService.get(fullKey);
        if (cached) {
            return of(cached);
        }

        // Si no está en caché, ejecutar y guardar
        return next.handle().pipe(
            tap(async (data) => {
                await this.cacheService.set(fullKey, data, ttl || 300000);
            }),
        );
    }
}