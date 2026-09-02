// C:\sirena\sirena-backend\src\common\interceptors\cache-invalidation.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Inject } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable, tap } from 'rxjs';
import { ICacheService } from '../interfaces/cache.interface';

export const CACHE_INVALIDATION_KEY = 'cache_invalidation_key';

@Injectable()
export class CacheInvalidationInterceptor implements NestInterceptor {
    constructor(
        @Inject('ICacheService') private readonly cacheService: ICacheService,
        private readonly reflector: Reflector,
    ) {}

    intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        const prefix = this.reflector.getAllAndOverride<string>(
            CACHE_INVALIDATION_KEY,
            [context.getHandler(), context.getClass()],
        );

        if (!prefix) {
            return next.handle();
        }

        const normalizedPrefix = prefix.endsWith(':')
            ? prefix
            : `${prefix}:`;

        return next.handle().pipe(
            tap({
                next: async () => {
                    try {
                        if (this.cacheService.deleteByPrefix) {
                            const deletedCount = await this.cacheService.deleteByPrefix(normalizedPrefix);

                            if (process.env['NODE_ENV'] === 'development' && deletedCount > 0) {
                                console.log(`🗑️ [Cache] Invalidado: ${normalizedPrefix} (${deletedCount} claves eliminadas)`);
                            }
                        }
                    } catch (error) {
                        if (process.env['NODE_ENV'] === 'development') {
                            const errorMessage = error instanceof Error
                                ? error.message
                                : 'Error desconocido al invalidar caché';

                            console.warn(`⚠️ [Cache] Error al invalidar ${normalizedPrefix}:`, errorMessage);
                        }
                    }
                }
            })
        );
    }
}
