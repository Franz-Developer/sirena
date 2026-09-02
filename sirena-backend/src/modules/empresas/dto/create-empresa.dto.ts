// C:\sirena\sirena-backend\src\modules\empresas\dto\create-empresa.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, IsOptional, MaxLength, MinLength, Matches, IsEmail } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateEmpresaDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo empresa debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo empresa es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo empresa debe tener al menos 3 caracteres.' })
    @MaxLength(200, { message: 'El campo empresa no puede exceder los 200 caracteres.' })
    @IsSafeText()
    empresa: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo codigo debe ser de tipo texto.' })
    @IsNotEmpty({ message: 'El campo codigo es obligatorio y no puede estar vacío.' })
    @MinLength(3, { message: 'El campo codigo debe tener al menos 3 caracteres.' })
    @MaxLength(30, { message: 'El campo codigo no puede exceder los 30 caracteres.' }) // Sincronizado a 30
    @Matches(/^[A-Z0-9_-]+$/, { message: 'El campo codigo solo puede contener letras mayúsculas, números, guiones y guiones bajos.' })
    codigo: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo logo debe ser de tipo texto.' })
    @MaxLength(255, { message: 'El campo logo no puede exceder los 255 caracteres.' })
    @IsSafeText()
    logo?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo eslogan debe ser de tipo texto.' })
    @MaxLength(150, { message: 'El campo eslogan no puede exceder los 150 caracteres.' })
    @IsSafeText()
    eslogan?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo descripcion debe ser de tipo texto.' })
    @MaxLength(500, { message: 'El campo descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo lugar debe ser de tipo texto.' })
    @MaxLength(60, { message: 'El campo lugar no puede exceder los 60 caracteres.' })
    @IsSafeText()
    lugar?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo representante debe ser de tipo texto.' })
    @MaxLength(100, { message: 'El campo representante no puede exceder los 100 caracteres.' })
    @IsSafeText()
    representante?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo direccion debe ser de tipo texto.' })
    @MaxLength(500, { message: 'El campo direccion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    direccion?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'El campo telefono debe ser de tipo texto.' })
    @MaxLength(100, { message: 'El campo telefono no puede exceder los 100 caracteres.' })
    @IsSafeText()
    telefono?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsEmail({}, { message: 'El campo email debe ser un correo electrónico válido.' })
    @MaxLength(100, { message: 'El campo email no puede exceder los 100 caracteres.' })
    email?: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'El campo matricula_comercio debe ser de tipo texto.' })
    @MaxLength(50, { message: 'El campo matricula_comercio no puede exceder los 50 caracteres.' })
    @IsSafeText()
    matricula_comercio: string;
}
