// C:\sirena\sirena-backend\src\modules\almacenes\almacenes.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AlmacenesController } from './almacenes.controller';
import { AlmacenesService } from './almacenes.service';
import { Almacen } from './entities/almacen.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Almacen]),
        ConfigModule,
    ],
    controllers: [AlmacenesController],
    providers: [AlmacenesService],
    exports: [AlmacenesService],
})
export class AlmacenesModule {}
