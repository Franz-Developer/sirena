// C:\sirena\sirena-backend\src\common\services\services.module.ts
import { Module, Global } from '@nestjs/common'; // ← Importar Global
import { ConfigModule } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { CacheModule } from './cache.module';
import { CacheService } from './cache.service';
import { DataSourceAdapter } from './data-source-adapter.service';
import { FileUrlService } from './file-url.service';
import { FileValidatorService } from './file-validator.service';
import { ConfiguracionService } from './configuracion.service';
import { GenerarQRUtil } from './generar-qr.service';

@Global()
@Module({
    imports: [
        ConfigModule,
        CacheModule,
    ],
    providers: [
        CacheService,
        FileUrlService,
        FileValidatorService,
        ConfiguracionService,
        GenerarQRUtil,
        {
            provide: 'IDataSource',
            useFactory: (dataSource: DataSource) => new DataSourceAdapter(dataSource),
            inject: [DataSource],
        },
    ],
    exports: [
        CacheService,
        FileUrlService,
        FileValidatorService,
        ConfiguracionService,
        'IDataSource',
        CacheModule,
        GenerarQRUtil,
    ],
})
export class ServicesModule {}
