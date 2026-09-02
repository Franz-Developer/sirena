// C:\sirena\sirena-backend\src\modules\cuis\cuis.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CuisController } from './cuis.controller';
import { CuisService } from './cuis.service';
import { Cui } from './entities/cui.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Cui]),
        ConfigModule,
    ],
    controllers: [CuisController],
    providers: [CuisService],
    exports: [CuisService],
})
export class CuisModule {}
