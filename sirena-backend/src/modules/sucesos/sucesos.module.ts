// C:\sirena\sirena-backend\src\modules\sucesos\sucesos.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { SucesosController } from './sucesos.controller';
import { SucesosService } from './sucesos.service';
import { Suceso } from './entities/suceso.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Suceso]),
        ConfigModule,
    ],
    controllers: [SucesosController],
    providers: [SucesosService],
    exports: [SucesosService],
})
export class SucesosModule {}
