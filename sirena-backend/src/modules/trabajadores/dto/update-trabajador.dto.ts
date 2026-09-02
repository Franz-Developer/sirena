// C:\sirena\sirena-backend\src\modules\trabajadores\dto\update-trabajador.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateTrabajadorDto } from './create-trabajador.dto';

export class UpdateTrabajadorDto extends PartialType(CreateTrabajadorDto) {}
