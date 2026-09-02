// C:\sirena\sirena-backend\src\modules\cufds\dto\create-cufd.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min, MaxLength, IsDateString } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateCufdDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number;

    @IsInt({ message: 'punto_venta_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'punto_venta_id es obligatorio.' })
    @Min(1, { message: 'punto_venta_id debe ser mayor a 0.' })
    punto_venta_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'codigo_cufd debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo_cufd es obligatorio.' })
    @MaxLength(500, { message: 'codigo_cufd no puede exceder los 500 caracteres.' })
    @IsSafeText()
    codigo_cufd: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'codigo_control debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo_control es obligatorio.' })
    @MaxLength(100, { message: 'codigo_control no puede exceder los 100 caracteres.' })
    @IsSafeText()
    codigo_control: string;

    @IsDateString({}, { message: 'fecha_vigencia debe ser una fecha y hora válida (ISO 8601).' })
    @IsNotEmpty({ message: 'fecha_vigencia es obligatoria.' })
    fecha_vigencia: string;
}