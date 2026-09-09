// C:\sirena\sirena-backend\src\modules\tipos-cambios\dto\create-tipo-cambio.dto.ts
import { IsInt, IsNotEmpty, IsPositive, IsDateString, IsIn, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
import { TipoMoneda, TIPO_MONEDA_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateTipoCambioDto {
    @IsInt({ message: 'origen_moneda_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'origen_moneda_id es obligatorio.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'origen_moneda_id')
    })
    origen_moneda_id: number;

    @IsInt({ message: 'destino_moneda_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'destino_moneda_id es obligatorio.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'destino_moneda_id')
    })
    destino_moneda_id: number;

    @Type(() => Number)
    @IsNumber(
        { maxDecimalPlaces: 4, },
        { message: 'factor_compra debe ser un número con hasta 4 decimales.'})
    @IsPositive({
        message: 'factor_compra debe ser un número positivo.'
    })
    factor_compra: number;

    @Type(() => Number)
    @IsNumber(
        { maxDecimalPlaces: 4, },
        { message: 'factor_venta debe ser un número con hasta 4 decimales.' }
    )
    @IsPositive({
        message: 'factor_venta debe ser un número positivo.'
    })
    factor_venta: number;

    @IsDateString(
        {},
        { message: 'fecha_cotizacion debe ser una fecha válida en formato YYYY-MM-DD.' }
    )
    @IsNotEmpty({
        message: 'fecha_cotizacion es obligatorio.'
    })
    fecha_cotizacion: string;
}
