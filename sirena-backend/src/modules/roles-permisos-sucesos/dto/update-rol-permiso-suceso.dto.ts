// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\dto\update-rol-permiso-suceso.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateRolPermisoSucesoDto } from './create-rol-permiso-suceso.dto';

export class UpdateRolPermisoSucesoDto extends PartialType(CreateRolPermisoSucesoDto) {}
