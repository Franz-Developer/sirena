// C:\sirena\sirena-backend\src\common\services\cache.module.ts
import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CacheService } from './cache.service';
import { RedisCacheService } from './redis-cache.service';

@Global()
@Module({
    imports: [ConfigModule],
    providers: [
        RedisCacheService,
        CacheService,
        {
            provide: 'ICacheService',
            useExisting: RedisCacheService,
        },
    ],
    exports: ['ICacheService', CacheService, RedisCacheService],
})
export class CacheModule {}