// C:\sirena\sirena-backend\src\modules\roles-tablas\roles-tablas.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolesTablasController } from './roles-tablas.controller';
import { RolesTablasService } from './roles-tablas.service';
import { RolTabla } from './entities/rol-tabla.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([RolTabla]),
        ConfigModule,
    ],
    controllers: [RolesTablasController],
    providers: [RolesTablasService],
    exports: [RolesTablasService],
})
export class RolesTablasModule {}
