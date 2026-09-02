// C:\sirena\sirena-backend\src\modules\menus\dto\create-menu.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, MaxLength, MinLength, IsOptional, IsInt, Min, IsNumber } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateMenuDto {
    @Transform(({ value }) => (value === '' || value === null ? undefined : value))
    @IsOptional()
    @IsNumber({}, { message: 'El campo menu_padre_id debe ser de tipo numérico.' })
    menu_padre_id?: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo titulo debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo titulo es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo titulo debe tener al menos 3 caracteres.' })
    @MaxLength(150, { message: 'El campo titulo no puede exceder los 150 caracteres.' })
    @IsSafeText()
    titulo: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'El campo icono debe ser de tipo texto.' })
    @MaxLength(50, { message: 'El campo icono no puede exceder los 50 caracteres.' })
    @IsSafeText()
    icono?: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'El campo url debe ser de tipo texto.' })
    @MaxLength(255, { message: 'El campo url no puede exceder los 255 caracteres.' })
    @IsSafeText()
    url?: string;

    @Transform(({ value }) => (value !== undefined && value !== null ? Number(value) : 0))
    @IsInt({ message: 'El campo orden debe ser un número entero.' })
    @Min(0, { message: 'El campo orden debe ser mayor o igual a 0.' })
    orden: number;
}
