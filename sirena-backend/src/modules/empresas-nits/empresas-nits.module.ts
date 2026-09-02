// C:\sirena\sirena-backend\src\modules\empresas-nits\empresas-nits.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmpresasNitsController } from './empresas-nits.controller';
import { EmpresasNitsService } from './empresas-nits.service';
import { EmpresaNit } from './entities/empresa-nit.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([EmpresaNit]),
        ConfigModule,
    ],
    controllers: [EmpresasNitsController],
    providers: [EmpresasNitsService],
    exports: [EmpresasNitsService],
})
export class EmpresasNitsModule {}
