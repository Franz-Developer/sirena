// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\almacenes-puntos-venta.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AlmacenesPuntosVentaController } from './almacenes-puntos-venta.controller';
import { AlmacenesPuntosVentaService } from './almacenes-puntos-venta.service';
import { AlmacenPuntoVenta } from './entities/almacen-punto-venta.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([AlmacenPuntoVenta]),
        ConfigModule,
    ],
    controllers: [AlmacenesPuntosVentaController],
    providers: [AlmacenesPuntosVentaService],
    exports: [AlmacenesPuntosVentaService],
})
export class AlmacenesPuntosVentaModule {}
