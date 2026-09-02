// C:\sirena\sirena-backend\src\modules\roles\roles.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolesController } from './roles.controller';
import { RolesService } from './roles.service';
import { Rol } from './entities/rol.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Rol]),
    ],
    controllers: [RolesController],
    providers: [RolesService],
    exports: [RolesService],
})
export class RolesModule {}
