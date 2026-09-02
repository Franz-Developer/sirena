// C:\sirena\sirena-backend\src\common\common.module.ts
import { Module, Global } from '@nestjs/common';
import { CacheModule } from './services/cache.module';
import { ServicesModule } from './services/services.module';
import { ValidatorsModule } from './validators/validators.module';

@Global()
@Module({
    imports: [
        ValidatorsModule,
        ServicesModule,
        CacheModule,
    ],
    exports: [
        ValidatorsModule,
        ServicesModule,
        CacheModule,
    ],
})
export class CommonModule {}
