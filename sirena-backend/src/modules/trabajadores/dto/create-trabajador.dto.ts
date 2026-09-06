// C:\sirena\sirena-backend\src\modules\trabajadores\dto\create-trabajador.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, MaxLength, Min, MinLength, IsDate, IsEmail } from 'class-validator';
import { Type } from 'class-transformer';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { Genero, GENERO_METADATA, EstadoCivilMasculino, EstadoCivilFemenino } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateTrabajadorDto {
    @IsOptional()
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @Min(1, { message: 'sucursal_id debe ser válido.' })
    sucursal_id?: number;

    @IsInt({ message: 'genero_id debe ser un número entero.' })
    @IsIn(getEnumValues(Genero), {
        message: createEnumMessage(GENERO_METADATA, getEnumValues(Genero), 'genero_id')
    })
    genero_id: number;

    @IsInt({ message: 'estado_civil_id debe ser un número entero.' })
    @IsIn([...getEnumValues(EstadoCivilMasculino), ...getEnumValues(EstadoCivilFemenino)], {
        message: 'estado_civil_id debe ser un valor válido según el género seleccionado.'
    })
    estado_civil_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'nombres debe ser un texto.' })
    @IsNotEmpty({ message: 'nombres es obligatorio.' })
    @MinLength(3, { message: 'nombres debe tener al menos 3 caracteres.' })
    @MaxLength(150, { message: 'nombres no puede exceder los 150 caracteres.' })
    @IsSafeText()
    nombres: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'paterno debe ser un texto.' })
    @IsNotEmpty({ message: 'paterno es obligatorio.' })
    @MinLength(3, { message: 'paterno debe tener al menos 3 caracteres.' })
    @MaxLength(80, { message: 'paterno no puede exceder los 80 caracteres.' })
    @IsSafeText()
    paterno: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsOptional()
    @IsString({ message: 'materno debe ser un texto.' })
    @MinLength(3, { message: 'materno debe tener al menos 3 caracteres.' })
    @MaxLength(80, { message: 'materno no puede exceder los 80 caracteres.' })
    @IsSafeText()
    materno?: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'dni debe ser un texto.' })
    @IsNotEmpty({ message: 'dni es obligatorio.' })
    @MinLength(5, { message: 'dni debe tener al menos 5 caracteres.' })
    @MaxLength(20, { message: 'dni no puede exceder los 20 caracteres.' })
    @IsSafeText()
    dni: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'telefono debe ser un texto.' })
    @MaxLength(100, { message: 'telefono no puede exceder los 100 caracteres.' })
    @IsSafeText()
    telefono?: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'direccion debe ser un texto.' })
    @MaxLength(255, { message: 'direccion no puede exceder los 255 caracteres.' })
    @IsSafeText()
    direccion?: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toLowerCase() : value)
    @IsOptional()
    @IsEmail({}, { message: 'email debe ser un correo electrónico válido.' })
    @MaxLength(100, { message: 'email no puede exceder los 100 caracteres.' })
    email?: string;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_nacimiento debe ser una fecha válida.' })
    fecha_nacimiento?: Date;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_contratacion debe ser una fecha válida.' })
    fecha_contratacion?: Date;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsOptional()
    @IsString({ message: 'foto debe ser un texto.' })
    @MaxLength(255, { message: 'foto no puede exceder los 255 caracteres.' })
    foto?: string;
}
