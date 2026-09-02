// C:\sirena\sirena-backend\src\modules\unidades\dto\create-unidad.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, MaxLength, MinLength, IsInt, Min } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateUnidadDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo codigo debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo codigo es obligatorio y no puede estar vacío.' })
    @MinLength(1, { message: 'El campo codigo debe tener al menos 1 carácter.' })
    @MaxLength(60, { message: 'El campo codigo no puede exceder los 60 caracteres.' })
    @IsSafeText()
    codigo: string;

    @Transform(({ value }) => value !== undefined && value !== null ? Number(value) : value)
    @IsInt({ message: 'El campo codigo_sin debe ser un número entero.' })
    @Min(0, { message: 'El campo codigo_sin debe ser mayor o igual a 0.' })
    codigo_sin: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo unidad debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo unidad es obligatorio y no puede estar vacío.' })
    @MinLength(1, { message: 'El campo unidad debe tener al menos 1 carácter.' })
    @MaxLength(100, { message: 'El campo unidad no puede exceder los 100 caracteres.' })
    @IsSafeText()
    unidad: string;
}
