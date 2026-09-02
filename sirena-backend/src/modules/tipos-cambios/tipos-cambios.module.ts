// C:\sirena\sirena-backend\src\modules\tipos-cambios\tipos-cambios.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TiposCambiosService } from './tipos-cambios.service';
import { TiposCambiosController } from './tipos-cambios.controller';
import { TipoCambio } from './entities/tipo-cambio.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([TipoCambio]),
    ],
    controllers: [TiposCambiosController],
    providers: [TiposCambiosService],
    exports: [TiposCambiosService],
})
export class TiposCambiosModule {}
