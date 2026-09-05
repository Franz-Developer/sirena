// C:\sirena\sirena-backend\src\modules\clientes\clientes.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientesController } from './clientes.controller';
import { ClientesService } from './clientes.service';
import { Cliente } from './entities/cliente.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Cliente]),
        ConfigModule,
    ],
    controllers: [ClientesController],
    providers: [ClientesService],
    exports: [ClientesService],
})
export class ClientesModule {}
