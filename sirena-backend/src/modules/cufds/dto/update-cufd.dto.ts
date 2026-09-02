// C:\sirena\sirena-backend\src\modules\cufds\dto\update-cufd.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateCufdDto } from './create-cufd.dto';

export class UpdateCufdDto extends PartialType(CreateCufdDto) {}
