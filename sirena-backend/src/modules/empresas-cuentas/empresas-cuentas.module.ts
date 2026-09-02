// C:\sirena\sirena-backend\src\modules\empresas-cuentas\empresas-cuentas.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmpresasCuentasController } from './empresas-cuentas.controller';
import { EmpresasCuentasService } from './empresas-cuentas.service';
import { EmpresaCuenta } from './entities/empresa-cuenta.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([EmpresaCuenta]),
        ConfigModule,
    ],
    controllers: [EmpresasCuentasController],
    providers: [EmpresasCuentasService],
    exports: [EmpresasCuentasService],
})
export class EmpresasCuentasModule {}
