// C:\sirena\sirena-backend\src\modules\sucesos\dto\update-suceso.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateSucesoDto } from './create-suceso.dto';

export class UpdateSucesoDto extends PartialType(CreateSucesoDto) {}
