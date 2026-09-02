// C:\sirena\sirena-backend\src\modules\usuarios\dto\update-usuario.dto.ts
import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CreateUsuarioDto } from './create-usuario.dto';

export class UpdateUsuarioDto extends PartialType(
    OmitType(CreateUsuarioDto, ['contrasena'] as const)
) {}
