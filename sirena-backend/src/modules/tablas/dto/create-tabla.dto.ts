// C:\sirena\sirena-backend\src\modules\tablas\dto\create-tabla.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, MaxLength, MinLength, Matches } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateTablaDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toLowerCase() : value)
    @IsString({ message: 'nombre debe ser un texto.' })
    @IsNotEmpty({ message: 'nombre es obligatorio.' })
    @MinLength(1, { message: 'nombre debe tener al menos 1 carácter.' })
    @MaxLength(100, { message: 'nombre no puede exceder los 100 caracteres.' })
    @Matches(/^[a-z][a-z0-9_]*$/, { message: 'nombre debe comenzar con letra minúscula y contener solo letras minúsculas, números y guiones bajos.' })
    @IsSafeText()
    nombre: string;
}
