// C:\sirena\sirena-backend\src\modules\cufds\cufds.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CufdsController } from './cufds.controller';
import { CufdsService } from './cufds.service';
import { Cufd } from './entities/cufd.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Cufd]),
        ConfigModule,
    ],
    controllers: [CufdsController],
    providers: [CufdsService],
    exports: [CufdsService],
})
export class CufdsModule {}
