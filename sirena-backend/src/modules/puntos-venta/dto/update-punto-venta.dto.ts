// C:\sirena\sirena-backend\src\modules\puntos-venta\dto\update-punto-venta.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreatePuntoVentaDto } from './create-punto-venta.dto';

export class UpdatePuntoVentaDto extends PartialType(CreatePuntoVentaDto) {}
