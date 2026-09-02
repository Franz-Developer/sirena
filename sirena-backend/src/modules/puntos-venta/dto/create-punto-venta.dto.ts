// C:\sirena\sirena-backend\src\modules\puntos-venta\dto\create-punto-venta.dto.ts
import { IsInt, IsNotEmpty, IsString, Min, MaxLength, IsIn, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { TipoPuntoVenta, TIPO_PUNTO_VENTA_METADATA } from '../../../common/constants/estados.constant';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class CreatePuntoVentaDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number;

    @IsInt({ message: 'codigo debe ser un número entero.' })
    @IsNotEmpty({ message: 'codigo es obligatorio.' })
    @Min(0, { message: 'codigo debe ser mayor o igual a 0.' })
    codigo: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsNotEmpty({ message: 'nombre es obligatorio.' })
    @IsString({ message: 'nombre debe ser un texto.' })
    @MinLength(4, { message: 'nombre debe tener más de 3 caracteres.' })
    @MaxLength(500, { message: 'nombre no puede exceder los 500 caracteres.' })
    nombre: string;

    @IsInt({ message: 'tipo_punto_venta_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoPuntoVenta), {
        message: createEnumMessage(
            TIPO_PUNTO_VENTA_METADATA,
            getEnumValues(TipoPuntoVenta),
            'tipo_punto_venta_id'
        )
    })
    tipo_punto_venta_id?: number;
}
