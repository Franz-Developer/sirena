// C:\sirena\sirena-backend\src\modules\roles-menus\dto\update-rol-menu.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateRolMenuDto } from './create-rol-menu.dto';

export class UpdateRolMenuDto extends PartialType(CreateRolMenuDto) {}
