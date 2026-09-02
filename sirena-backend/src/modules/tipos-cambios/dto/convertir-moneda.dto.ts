// C:\sirena\sirena-backend\src\modules\tipos-cambios\dto\convertir-moneda.dto.ts
import { IsNotEmpty, IsNumber, IsPositive, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';

export class ConvertirMonedaDto {
    @Type(() => Number)
    @IsNumber({ maxDecimalPlaces: 2 }, { message: 'monto_bolivianos debe ser un número válido.' })
    @IsPositive({ message: 'El monto en bolivianos debe ser mayor a 0.' })
    @IsNotEmpty({ message: 'monto_bolivianos es obligatorio.' })
    monto_bolivianos: number;

    @IsDateString({}, { message: 'fecha_cotizacion debe ser una fecha válida en formato YYYY-MM-DD.' })
    @IsNotEmpty({ message: 'fecha_cotizacion es obligatorio.' })
    fecha_cotizacion: string;
}
