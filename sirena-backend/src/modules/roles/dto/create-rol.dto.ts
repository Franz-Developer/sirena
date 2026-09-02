// C:\sirena\sirena-backend\src\modules\roles\dto\create-rol.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, MaxLength, MinLength, Matches, IsOptional } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateRolDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo rol debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo rol es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo rol debe tener al menos 3 caracteres.' })
    @MaxLength(60, { message: 'El campo rol no puede exceder los 60 caracteres.' })
    @IsSafeText()
    rol: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo codigo debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo codigo es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo codigo debe tener al menos 3 caracteres.' })
    @MaxLength(60, { message: 'El campo codigo no puede exceder los 60 caracteres.' })
    @Matches(/^[A-Z0-9_-]+$/, { message: 'El campo codigo solo puede contener letras mayúsculas, números, guiones y guiones bajos.' })
    @IsSafeText()
    codigo: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'El campo descripcion debe ser de tipo texto.' })
    @MaxLength(500, { message: 'El campo descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;
}
