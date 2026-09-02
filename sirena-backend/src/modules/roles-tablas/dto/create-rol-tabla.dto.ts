// C:\sirena\sirena-backend\src\modules\roles-tablas\dto\create-rol-tabla.dto.ts
import { IsInt, IsNotEmpty, IsOptional, IsString, IsObject, Min, Max } from 'class-validator';
import { IsValidTable, IsEventosPermitidos, IsKardexEventosPermitidos, IsUniqueEventKeys } from '../../../common/validators/is-eventos-permitidos.validator.service';

export class CreateRolTablaDto {
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'rol_id es obligatorio.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id: number;

    @IsString({ message: 'tabla debe ser un texto.' })
    @IsNotEmpty({ message: 'tabla es obligatoria.' })
    @IsValidTable({ message: 'tabla debe ser una tabla válida.' })
    tabla: string;

    @IsInt({ message: 'leer debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'leer debe ser 0 o 1.' })
    @Max(1, { message: 'leer debe ser 0 o 1.' })
    leer?: number;

    @IsInt({ message: 'crear debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'crear debe ser 0 o 1.' })
    @Max(1, { message: 'crear debe ser 0 o 1.' })
    crear?: number;

    @IsInt({ message: 'editar debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'editar debe ser 0 o 1.' })
    @Max(1, { message: 'editar debe ser 0 o 1.' })
    editar?: number;

    @IsInt({ message: 'eliminar debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'eliminar debe ser 0 o 1.' })
    @Max(1, { message: 'eliminar debe ser 0 o 1.' })
    eliminar?: number;

    @IsInt({ message: 'anular debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'anular debe ser 0 o 1.' })
    @Max(1, { message: 'anular debe ser 0 o 1.' })
    anular?: number;

    @IsInt({ message: 'archivar debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'archivar debe ser 0 o 1.' })
    @Max(1, { message: 'archivar debe ser 0 o 1.' })
    archivar?: number;

    @IsInt({ message: 'desarchivar debe ser un número entero.' })
    @IsOptional()
    @Min(0, { message: 'desarchivar debe ser 0 o 1.' })
    @Max(1, { message: 'desarchivar debe ser 0 o 1.' })
    desarchivar?: number;

    @IsObject({ message: 'eventos_permitidos debe ser un objeto JSON.' })
    @IsOptional()
    @IsUniqueEventKeys({
        message: 'eventos_permitidos contiene claves duplicadas o inválidas. Las claves permitidas son: crear, editar, anular.'
    })
    @IsEventosPermitidos()
    @IsKardexEventosPermitidos()
    eventos_permitidos?: Record<string, any>;
}
