// C:\sirena\sirena-backend\src\modules\tablas\dto\find-tablas-query.dto.ts
import { IsOptional, IsString } from 'class-validator';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';

export class FindTablasQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;
}
