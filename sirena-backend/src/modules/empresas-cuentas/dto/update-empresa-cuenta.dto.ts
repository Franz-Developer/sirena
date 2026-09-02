// C:\sirena\sirena-backend\src\modules\empresas-cuentas\dto\update-empresa-cuenta.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateEmpresaCuentaDto } from './create-empresa-cuenta.dto';

export class UpdateEmpresaCuentaDto extends PartialType(CreateEmpresaCuentaDto) {}
