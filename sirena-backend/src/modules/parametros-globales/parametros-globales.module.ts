// C:\sirena\sirena-backend\src\modules\parametros-globales\parametros-globales.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ParametroGlobal } from './entities/parametro-global.entity';
import { ParametrosGlobalesController } from './parametros-globales.controller';
import { ParametrosGlobalesService } from './parametros-globales.service';

@Module({
    imports: [
        TypeOrmModule.forFeature([ParametroGlobal]),
    ],
    controllers: [ParametrosGlobalesController],
    providers: [ParametrosGlobalesService],
    exports: [ParametrosGlobalesService],
})
export class ParametrosGlobalesModule {}
