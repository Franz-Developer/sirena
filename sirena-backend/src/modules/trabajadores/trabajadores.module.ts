// C:\sirena\sirena-backend\src\modules\trabajadores\trabajadores.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrabajadoresController } from './trabajadores.controller';
import { TrabajadoresService } from './trabajadores.service';
import { Trabajador } from './entities/trabajador.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Trabajador]),
        ConfigModule,
    ],
    controllers: [TrabajadoresController],
    providers: [TrabajadoresService],
    exports: [TrabajadoresService],
})
export class TrabajadoresModule {}
