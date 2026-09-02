// C:\sirena\sirena-backend\src\modules\parametros-globales\dto\update-parametro-global.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateParametroGlobalDto } from './create-parametro-global.dto';

export class UpdateParametroGlobalDto extends PartialType(CreateParametroGlobalDto) {}
