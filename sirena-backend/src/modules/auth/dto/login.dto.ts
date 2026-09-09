// C:\sirena\sirena-backend\src\modules\auth\dto\login.dto.ts
import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, Matches, Length } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class LoginDto {
    @IsString({ message: 'El usuario debe ser una cadena de texto.' })
    @IsNotEmpty({ message: 'El usuario no puede estar vacío.' })
    @Length(3, 50, { message: 'El usuario debe tener entre 3 y 50 caracteres.' })
    @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
    @Matches(/^[a-zA-Z0-9._@-]+$/, {
        message: 'El usuario solo puede contener letras, números, puntos, guiones y @.'
    })
    @IsSafeText()
    username: string;

    @IsString({ message: 'La contraseña debe ser una cadena de texto.' })
    @IsNotEmpty({ message: 'La contraseña no puede estar vacía.' })
    password: string;
}
