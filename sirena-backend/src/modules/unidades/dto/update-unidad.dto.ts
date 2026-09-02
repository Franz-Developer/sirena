// C:\sirena\sirena-backend\src\modules\unidades\dto\update-unidad.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateUnidadDto } from './create-unidad.dto';

export class UpdateUnidadDto extends PartialType(CreateUnidadDto) {}
