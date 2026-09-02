// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\dto\create-almacen-punto-venta.dto.ts
import { IsInt, IsNotEmpty, IsOptional, Min, Max } from 'class-validator';

export class CreateAlmacenPuntoVentaDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number;

    @IsInt({ message: 'almacen_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'almacen_id es obligatorio.' })
    @Min(1, { message: 'almacen_id debe ser mayor a 0.' })
    almacen_id: number;

    @IsInt({ message: 'punto_venta_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'punto_venta_id es obligatorio.' })
    @Min(1, { message: 'punto_venta_id debe ser mayor a 0.' })
    punto_venta_id: number;

    @IsInt({ message: 'prioridad debe ser un número entero.' })
    @IsOptional()
    @Min(1, { message: 'prioridad debe ser mayor a 0.' })
    prioridad?: number;

    @IsInt({ message: 'es_principal debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'es_principal debe ser 0 o 1.' })
    @Max(1, { message: 'es_principal debe ser 0 o 1.' })
    es_principal?: number;
}
