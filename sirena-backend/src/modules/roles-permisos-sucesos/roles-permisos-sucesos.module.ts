// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\roles-permisos-sucesos.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolesPermisosSucesosController } from './roles-permisos-sucesos.controller';
import { RolesPermisosSucesosService } from './roles-permisos-sucesos.service';
import { RolPermisoSuceso } from './entities/rol-permiso-suceso.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([RolPermisoSuceso]),
        ConfigModule,
    ],
    controllers: [RolesPermisosSucesosController],
    providers: [RolesPermisosSucesosService],
    exports: [RolesPermisosSucesosService],
})
export class RolesPermisosSucesosModule {}
