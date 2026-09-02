// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\dto\create-trabajador-cargo.dto.ts
import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, Min, MaxLength, IsNumber, IsDate, } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoMoneda, TIPO_MONEDA_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateTrabajadorCargoDto {
    @IsInt({ message: 'trabajador_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'trabajador_id es obligatorio.' })
    @Min(1, { message: 'trabajador_id debe ser mayor a 0.' })
    trabajador_id: number;

    @IsInt({ message: 'cargo_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'cargo_id es obligatorio.' })
    @Min(1, { message: 'cargo_id debe ser mayor a 0.' })
    cargo_id: number;

    @IsNumber({ maxDecimalPlaces: 2 }, { message: 'sueldo_base debe ser un número con máximo 2 decimales.' })
    @IsNotEmpty({ message: 'sueldo_base es obligatorio.' })
    @Min(0, { message: 'sueldo_base no puede ser negativo.' })
    sueldo_base: number;

    @IsInt({ message: 'tipo_moneda_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'tipo_moneda_id')
    })
    tipo_moneda_id: number;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_desde debe ser una fecha válida.' })
    fecha_desde?: Date;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_hasta debe ser una fecha válida.' })
    fecha_hasta?: Date;

    @IsOptional()
    @IsInt({ message: 'es_activo debe ser un número entero.' })
    @IsIn([0, 1], { message: 'es_activo debe ser 0 (No) o 1 (Sí).' })
    es_activo?: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'observaciones debe ser un texto.' })
    @MaxLength(500, { message: 'observaciones no puede exceder los 500 caracteres.' })
    @IsSafeText()
    observaciones?: string;
}
