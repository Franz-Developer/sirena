// C:\sirena\sirena-backend\src\modules\constantes\dto\find-constantes-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsString, IsInt } from 'class-validator';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';

export class FindConstantesQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro tipo debe ser un texto.' })
    tipo?: string;

    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'id debe ser un número entero.' })
    id?: number;
}
