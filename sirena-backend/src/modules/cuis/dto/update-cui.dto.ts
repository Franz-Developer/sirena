// C:\sirena\sirena-backend\src\modules\cuis\dto\update-cui.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateCuiDto } from './create-cui.dto';

export class UpdateCuiDto extends PartialType(CreateCuiDto) {}
