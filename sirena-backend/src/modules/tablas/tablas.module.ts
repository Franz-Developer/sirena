// C:\sirena\sirena-backend\src\modules\tablas\tablas.module.ts
import { Module } from '@nestjs/common';
import { TablasController } from './tablas.controller';
import { TablasService } from './tablas.service';

@Module({
    imports: [],
    controllers: [TablasController],
    providers: [TablasService],
    exports: [TablasService],
})
export class TablasModule {}
