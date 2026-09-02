// C:\sirena\sirena-backend\src\modules\empresas-nits\dto\update-empresa-nit.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateEmpresaNitDto } from './create-empresa-nit.dto';

export class UpdateEmpresaNitDto extends PartialType(CreateEmpresaNitDto) {}
