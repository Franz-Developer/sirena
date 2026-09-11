// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\dto\create-rol-permiso-tabla.dto.ts
import { IsInt, IsNotEmpty, Min, IsIn, IsOptional } from 'class-validator';

export class CreateRolPermisoTablaDto {
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'rol_id es obligatorio.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id: number;

    @IsInt({ message: 'tabla_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'tabla_id es obligatorio.' })
    @Min(1, { message: 'tabla_id debe ser mayor a 0.' })
    tabla_id: number;

    @IsOptional()
    @IsInt({ message: 'leer debe ser un número entero.' })
    @IsIn([0, 1], { message: 'leer debe ser 0 o 1.' })
    leer?: number = 0;

    @IsOptional()
    @IsInt({ message: 'crear debe ser un número entero.' })
    @IsIn([0, 1], { message: 'crear debe ser 0 o 1.' })
    crear?: number = 0;

    @IsOptional()
    @IsInt({ message: 'editar debe ser un número entero.' })
    @IsIn([0, 1], { message: 'editar debe ser 0 o 1.' })
    editar?: number = 0;

    @IsOptional()
    @IsInt({ message: 'eliminar debe ser un número entero.' })
    @IsIn([0, 1], { message: 'eliminar debe ser 0 o 1.' })
    eliminar?: number = 0;

    @IsOptional()
    @IsInt({ message: 'anular debe ser un número entero.' })
    @IsIn([0, 1], { message: 'anular debe ser 0 o 1.' })
    anular?: number = 0;

    @IsOptional()
    @IsInt({ message: 'archivar debe ser un número entero.' })
    @IsIn([0, 1], { message: 'archivar debe ser 0 o 1.' })
    archivar?: number = 0;

    @IsOptional()
    @IsInt({ message: 'desarchivar debe ser un número entero.' })
    @IsIn([0, 1], { message: 'desarchivar debe ser 0 o 1.' })
    desarchivar?: number = 0;
}
