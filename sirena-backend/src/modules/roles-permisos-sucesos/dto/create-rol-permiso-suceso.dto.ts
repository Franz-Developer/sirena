// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\dto\create-rol-permiso-suceso.dto.ts
import { IsInt, IsNotEmpty, Min } from 'class-validator';

export class CreateRolPermisoSucesoDto {
    @IsInt({ message: 'rol_permiso_tabla_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'rol_permiso_tabla_id es obligatorio.' })
    @Min(1, { message: 'rol_permiso_tabla_id debe ser mayor a 0.' })
    rol_permiso_tabla_id: number;

    @IsInt({ message: 'suceso_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'suceso_id es obligatorio.' })
    @Min(1, { message: 'suceso_id debe ser mayor a 0.' })
    suceso_id: number;
}
