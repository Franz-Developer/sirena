// C:\sirena\sirena-backend\src\modules\empresas\empresas.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmpresasController } from './empresas.controller';
import { EmpresasService } from './empresas.service';
import { Empresa } from './entities/empresa.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Empresa]),
        ConfigModule,
    ],
    controllers: [EmpresasController],
    providers: [EmpresasService],
    exports: [EmpresasService],
})
export class EmpresasModule {}
