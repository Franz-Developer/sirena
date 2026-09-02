// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\inventarios-fisicos.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventariosFisicosController } from './inventarios-fisicos.controller';
import { InventariosFisicosService } from './inventarios-fisicos.service';
import { InventarioFisico } from './entities/inventario-fisico.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([InventarioFisico]),
        ConfigModule,
    ],
    controllers: [InventariosFisicosController],
    providers: [InventariosFisicosService],
    exports: [InventariosFisicosService],
})
export class InventariosFisicosModule {}
