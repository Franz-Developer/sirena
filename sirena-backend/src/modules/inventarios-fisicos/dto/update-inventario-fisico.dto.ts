// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\dto\update-inventario-fisico.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateInventarioFisicoDto } from './create-inventario-fisico.dto';

export class UpdateInventarioFisicoDto extends PartialType(CreateInventarioFisicoDto) {}
