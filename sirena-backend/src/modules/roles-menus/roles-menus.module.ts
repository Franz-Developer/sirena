// C:\sirena\sirena-backend\src\modules\roles-menus\roles-menus.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolesMenusController } from './roles-menus.controller';
import { RolesMenusService } from './roles-menus.service';
import { RolMenu } from './entities/rol-menu.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([RolMenu]),
        ConfigModule,
    ],
    controllers: [RolesMenusController],
    providers: [RolesMenusService],
    exports: [RolesMenusService],
})
export class RolesMenusModule {}
