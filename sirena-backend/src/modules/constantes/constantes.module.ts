// C:\sirena\sirena-backend\src\modules\constantes\constantes.module.ts
import { Module } from '@nestjs/common';
import { ConstantesController } from './constantes.controller';
import { ConstantesService } from './constantes.service';

@Module({
    imports: [
    ],
    controllers: [ConstantesController],
    providers: [ConstantesService],
    exports: [ConstantesService],
})
export class ConstantesModule {}
