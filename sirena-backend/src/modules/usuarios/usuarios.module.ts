// C:\sirena\sirena-backend\src\modules\usuarios\usuarios.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Usuario } from './entities/usuario.entity';
import { UsuariosController } from './usuarios.controller';
import { UsuariosService } from './usuarios.service';

@Module({
    imports: [
        TypeOrmModule.forFeature([Usuario]),
    ],
    controllers: [UsuariosController],
    providers: [UsuariosService],
    exports: [
        UsuariosService,
        TypeOrmModule.forFeature([Usuario])
    ],
})
export class UsuariosModule {}
