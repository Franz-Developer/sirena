// C:\sirena\sirena-backend\src\modules\ubicaciones\dto\update-ubicacion.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateUbicacionDto } from './create-ubicacion.dto';

export class UpdateUbicacionDto extends PartialType(CreateUbicacionDto) {}
