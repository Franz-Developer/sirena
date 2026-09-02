// C:\sirena\sirena-backend\src\modules\usuarios\dto\create-usuario.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, MaxLength, MinLength, Matches, IsPositive } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateUsuarioDto {
    @IsInt({ message: 'trabajador_id debe ser un número entero.' })
    @IsPositive({ message: 'trabajador_id debe ser un número positivo.' })
    trabajador_id: number;

    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsPositive({ message: 'sucursal_id debe ser un número positivo.' })
    sucursal_id: number;

    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @IsPositive({ message: 'rol_id debe ser un número positivo.' })
    rol_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'login debe ser un texto.' })
    @IsNotEmpty({ message: 'login es obligatorio.' })
    @MinLength(4, { message: 'login debe tener al menos 4 caracteres.' })
    @MaxLength(10, { message: 'login no puede exceder los 10 caracteres.' })
    @Matches(/^[A-Z0-9._-]+$/, { message: 'login contiene caracteres no permitidos.' })
    @IsSafeText()
    login: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'contrasena debe ser un texto.' })
    @IsNotEmpty({ message: 'contrasena es obligatoria.' })
    @MinLength(8, { message: 'La nueva contraseña debe tener al menos 8 caracteres.' })
    @MaxLength(72, { message: 'La nueva contraseña no debe exceder los 72 caracteres.' })
    contrasena: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'avatar debe ser un texto.' })
    @IsNotEmpty({ message: 'avatar es obligatorio.' })
    @MaxLength(255, { message: 'avatar no puede exceder los 255 caracteres.' })
    @IsSafeText()
    avatar: string;
}
