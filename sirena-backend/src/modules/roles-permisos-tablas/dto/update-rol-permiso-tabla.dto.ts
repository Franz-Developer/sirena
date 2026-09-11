// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\dto\update-rol-permiso-tabla.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateRolPermisoTablaDto } from './create-rol-permiso-tabla.dto';

export class UpdateRolPermisoTablaDto extends PartialType(CreateRolPermisoTablaDto) {}
