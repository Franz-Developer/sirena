// C:\sirena\sirena-backend\src\modules\almacenes\dto\create-almacen.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, Min, MaxLength, MinLength, Matches } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateAlmacenDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number = 1;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'almacen debe ser un texto.' })
    @IsNotEmpty({ message: 'almacen es obligatorio.' })
    @MinLength(1, { message: 'almacen debe tener al menos 1 carácter.' })
    @MaxLength(200, { message: 'almacen no puede exceder los 200 caracteres.' })
    @IsSafeText()
    almacen: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'codigo debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo es obligatorio.' })
    @MinLength(3, { message: 'codigo debe tener al menos 3 caracteres.' })
    @MaxLength(60, { message: 'codigo no puede exceder los 60 caracteres.' })
    @Matches(/^[A-Z0-9_-]+$/, { message: 'codigo debe contener solo letras mayúsculas, números, guiones y guiones bajos.' })
    @IsSafeText()
    codigo: string;

    @IsInt({ message: 'tipo_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoAlmacen), {
        message: createEnumMessage(TIPO_ALMACEN_METADATA, getEnumValues(TipoAlmacen), 'tipo_almacen_id')
    })
    tipo_almacen_id: number;

    @IsInt({ message: 'tipo_operacion_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoOperacionAlmacen), {
        message: createEnumMessage(TIPO_OPERACION_ALMACEN_METADATA, getEnumValues(TipoOperacionAlmacen), 'tipo_operacion_almacen_id')
    })
    tipo_operacion_almacen_id: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'descripcion debe ser un texto.' })
    @MaxLength(500, { message: 'descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;
}
