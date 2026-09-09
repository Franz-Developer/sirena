// C:\sirena\sirena-backend\src\common\validators\validators.module.ts
import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ParametroGlobal } from '../../modules/parametros-globales/entities/parametro-global.entity';
import { ImagenValidatorService } from './imagen-validator.service';
import { TablaValidadorService } from './tabla-validador.service';
import { UnicidadValidadorService } from './unicidad-validador.service';

@Global()
@Module({
    imports: [
        TypeOrmModule.forFeature([ParametroGlobal]),
    ],
    providers: [
        TablaValidadorService,
        UnicidadValidadorService,
        ImagenValidatorService,
    ],
    exports: [
        TablaValidadorService,
        UnicidadValidadorService,
        ImagenValidatorService,
    ],
})
export class ValidatorsModule {}
