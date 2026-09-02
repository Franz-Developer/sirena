// C:\sirena\sirena-backend\src\modules\cuis\dto\create-cui.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min, MaxLength, IsDateString } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateCuiDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number;

    @IsInt({ message: 'punto_venta_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'punto_venta_id es obligatorio.' })
    @Min(1, { message: 'punto_venta_id debe ser mayor a 0.' })
    punto_venta_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'codigo_cuis debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo_cuis es obligatorio.' })
    @MaxLength(100, { message: 'codigo_cuis no puede exceder los 100 caracteres.' })
    @IsSafeText()
    codigo_cuis: string;

    @IsDateString({}, { message: 'fecha_vigencia debe ser una fecha y hora válida (ISO 8601).' })
    @IsNotEmpty({ message: 'fecha_vigencia es obligatoria.' })
    fecha_vigencia: string;
}
