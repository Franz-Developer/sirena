// C:\sirena\sirena-backend\src\modules\ubicaciones\dto\create-ubicacion.dto.ts
import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min, MaxLength, IsOptional, IsEnum, Max, } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TIPO_UBICACION, TipoUbicacion } from '../../../common/constants/ubicaciones.constants';

export class CreateUbicacionDto {
    @IsInt({ message: 'almacen_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'almacen_id es obligatorio.' })
    @Min(1, { message: 'almacen_id debe ser mayor a 0.' })
    almacen_id: number;

    @IsEnum(TIPO_UBICACION, { message: 'tipo de ubicación no válido.' })
    @IsNotEmpty({ message: 'El tipo de ubicación es obligatorio.' })
    tipo: TipoUbicacion;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'niveles debe ser un número entero.' })
    @Min(1, { message: 'niveles debe ser mayor o igual a 1.' })
    @Max(50, { message: 'niveles no puede exceder 50.' })
    niveles: number;

    @IsOptional()
    @IsString({ message: 'descripcion debe ser un texto.' })
    @MaxLength(500, { message: 'descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;
}
