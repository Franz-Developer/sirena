// C:\sirena\sirena-backend\src\modules\roles-menus\dto\create-rol-menu.dto.ts
import { IsInt, IsNotEmpty, Min } from 'class-validator';

export class CreateRolMenuDto {
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'rol_id es obligatorio.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id: number;

    @IsInt({ message: 'menu_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'menu_id es obligatorio.' })
    @Min(1, { message: 'menu_id debe ser mayor a 0.' })
    menu_id: number;
}
