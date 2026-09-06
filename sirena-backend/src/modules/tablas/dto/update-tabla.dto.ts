// C:\sirena\sirena-backend\src\modules\tablas\dto\update-tabla.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateTablaDto } from './create-tabla.dto';

export class UpdateTablaDto extends PartialType(CreateTablaDto) {}
