// C:\sirena\sirena-backend\src\common\decorators\invalidate-cache.decorator.ts
import { applyDecorators, SetMetadata, UseInterceptors } from '@nestjs/common';
import { CacheInvalidationInterceptor, CACHE_INVALIDATION_KEY } from '../interceptors/cache-invalidation.interceptor';

export function InvalidateCache(prefix: string) {
    return applyDecorators(
        SetMetadata(CACHE_INVALIDATION_KEY, prefix),
        UseInterceptors(CacheInvalidationInterceptor)
    );
}
