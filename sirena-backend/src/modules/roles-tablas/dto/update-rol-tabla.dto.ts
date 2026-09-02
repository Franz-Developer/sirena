// C:\sirena\sirena-backend\src\modules\roles-tablas\dto\update-rol-tabla.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateRolTablaDto } from './create-rol-tabla.dto';

export class UpdateRolTablaDto extends PartialType(CreateRolTablaDto) {}
