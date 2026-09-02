// C:\sirena\sirena-backend\src\modules\unidades\unidades.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UnidadesController } from './unidades.controller';
import { UnidadesService } from './unidades.service';
import { Unidad } from './entities/unidad.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Unidad]),
    ],
    controllers: [UnidadesController],
    providers: [UnidadesService],
    exports: [UnidadesService],
})
export class UnidadesModule {}
