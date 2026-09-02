// C:\sirena\sirena-backend\src\modules\tipos-cambios\dto\update-tipo-cambio.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateTipoCambioDto } from './create-tipo-cambio.dto';

export class UpdateTipoCambioDto extends PartialType(CreateTipoCambioDto) {}
