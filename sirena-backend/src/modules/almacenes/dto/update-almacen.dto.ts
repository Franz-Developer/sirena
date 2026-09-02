// C:\sirena\sirena-backend\src\modules\almacenes\dto\update-almacen.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateAlmacenDto } from './create-almacen.dto';

export class UpdateAlmacenDto extends PartialType(CreateAlmacenDto) {}
