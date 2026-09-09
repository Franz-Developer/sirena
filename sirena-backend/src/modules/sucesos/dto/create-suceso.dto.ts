// C:\sirena\sirena-backend\src\modules\sucesos\dto\create-suceso.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateSucesoDto {
    @IsInt({ message: 'tabla_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'tabla_id es obligatorio.' })
    tabla_id: number;

    @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
    @IsNotEmpty({ message: 'codigo es obligatorio.' })
    @IsString({ message: 'codigo debe ser un texto.' })
    @MinLength(3, { message: 'codigo debe tener al menos 3 caracteres.' })
    @MaxLength(15, { message: 'codigo no puede exceder los 15 caracteres.' })
    @IsSafeText()
    codigo: string;

    @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
    @IsNotEmpty({ message: 'suceso es obligatorio.' })
    @IsString({ message: 'suceso debe ser un texto.' })
    @MinLength(3, { message: 'suceso debe tener al menos 3 caracteres.' })
    @MaxLength(30, { message: 'suceso no puede exceder los 30 caracteres.' })
    @IsSafeText()
    suceso: string;

    @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
    @IsNotEmpty({ message: 'descripcion es obligatoria.' })
    @IsString({ message: 'descripcion debe ser un texto.' })
    @MaxLength(200, { message: 'descripcion no puede exceder los 200 caracteres.' })
    @IsSafeText()
    descripcion: string;
}
