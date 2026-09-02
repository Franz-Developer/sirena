// C:\sirena\sirena-backend\src\modules\cargos\dto\create-cargo.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, MaxLength, MinLength, Matches, IsOptional } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateCargoDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo cargo debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo cargo es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo cargo debe tener al menos 3 caracteres.' })
    @MaxLength(100, { message: 'El campo cargo no puede exceder los 100 caracteres.' })
    @IsSafeText()
    cargo: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo codigo debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo codigo es obligatorio y no puede estar vacío.' })
    @MinLength(2, { message: 'El campo codigo debe tener al menos 2 caracteres.' })
    @MaxLength(60, { message: 'El campo codigo no puede exceder los 60 caracteres.' })
    @Matches(/^[A-Z0-9_-]+$/, { message: 'El campo codigo debe contener solo letras mayúsculas, números, guiones y guiones bajos.' })
    @IsSafeText()
    codigo: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'El campo descripcion debe ser de tipo texto.' })
    @MaxLength(255, { message: 'El campo descripcion no puede exceder los 255 caracteres.' })
    @IsSafeText()
    descripcion?: string;
}
