// C:\sirena\sirena-backend\src\modules\tablas\tablas.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { TablasController } from './tablas.controller';
import { TablasService } from './tablas.service';
import { Tabla } from './entities/tabla.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Tabla]),
        ConfigModule,
    ],
    controllers: [TablasController],
    providers: [TablasService],
    exports: [TablasService],
})
export class TablasModule {}
