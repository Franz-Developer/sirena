// C:\sirena\sirena-backend\src\modules\puntos-venta\puntos-venta.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { PuntosVentaService } from './puntos-venta.service';
import { PuntosVentaController } from './puntos-venta.controller';
import { PuntoVenta } from './entities/punto-venta.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([PuntoVenta]),
        ConfigModule,
    ],
    controllers: [PuntosVentaController],
    providers: [PuntosVentaService],
    exports: [PuntosVentaService],
})
export class PuntosVentaModule {}
