// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\trabajadores-cargos.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrabajadoresCargosController } from './trabajadores-cargos.controller';
import { TrabajadoresCargosService } from './trabajadores-cargos.service';
import { TrabajadorCargo } from './entities/trabajador-cargo.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([TrabajadorCargo]),
        ConfigModule,
    ],
    controllers: [TrabajadoresCargosController],
    providers: [TrabajadoresCargosService],
    exports: [TrabajadoresCargosService],
})
export class TrabajadoresCargosModule {}
