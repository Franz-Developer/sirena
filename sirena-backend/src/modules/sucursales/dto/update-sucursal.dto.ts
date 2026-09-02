// C:\sirena\sirena-backend\src\modules\sucursales\dto\update-sucursal.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateSucursalDto } from './create-sucursal.dto';

export class UpdateSucursalDto extends PartialType(CreateSucursalDto) {}
