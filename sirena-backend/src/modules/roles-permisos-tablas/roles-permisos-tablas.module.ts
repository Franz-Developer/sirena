// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\roles-permisos-tablas.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolesPermisosTablasController } from './roles-permisos-tablas.controller';
import { RolesPermisosTablasService } from './roles-permisos-tablas.service';
import { RolPermisoTabla } from './entities/rol-permiso-tabla.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([RolPermisoTabla]),
        ConfigModule,
    ],
    controllers: [RolesPermisosTablasController],
    providers: [RolesPermisosTablasService],
    exports: [RolesPermisosTablasService],
})
export class RolesPermisosTablasModule {}
