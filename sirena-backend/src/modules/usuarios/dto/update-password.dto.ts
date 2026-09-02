// C:\sirena\sirena-backend\src\modules\usuarios\dto\update-password.dto.ts
import { IsString, MinLength, MaxLength, IsNotEmpty } from 'class-validator';

export class UpdatePasswordDto {
    @IsString({ message: 'La contraseña actual debe ser texto.' })
    @IsNotEmpty({ message: 'La contraseña actual es obligatoria.' })
    contrasenaActual!: string;

    @IsString({ message: 'La nueva contraseña debe ser texto.' })
    @IsNotEmpty({ message: 'La nueva contraseña es obligatoria.' })
    @MinLength(8, { message: 'La nueva contraseña debe tener al menos 8 caracteres.' })
    @MaxLength(72, { message: 'La nueva contraseña no debe exceder los 72 caracteres.' })
    nuevaContrasena!: string;

    @IsString({ message: 'La confirmación de contraseña debe ser texto.' })
    @IsNotEmpty({ message: 'La confirmación de contraseña es obligatoria.' })
    confirmarContrasena!: string;
}
