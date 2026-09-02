// C:\sirena\sirena-backend\src\modules\ubicaciones\ubicaciones.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UbicacionesController } from './ubicaciones.controller';
import { UbicacionesService } from './ubicaciones.service';
import { Ubicacion } from './entities/ubicacion.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Ubicacion]),
        ConfigModule,
    ],
    controllers: [UbicacionesController],
    providers: [UbicacionesService],
    exports: [UbicacionesService],
})
export class UbicacionesModule {}
