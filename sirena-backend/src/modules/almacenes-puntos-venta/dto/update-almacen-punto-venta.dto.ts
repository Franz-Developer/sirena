// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\dto\update-almacen-punto-venta.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateAlmacenPuntoVentaDto } from './create-almacen-punto-venta.dto';

export class UpdateAlmacenPuntoVentaDto extends PartialType(CreateAlmacenPuntoVentaDto) {}
