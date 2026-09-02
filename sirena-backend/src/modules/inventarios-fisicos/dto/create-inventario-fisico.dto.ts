// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\dto\create-inventario-fisico.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min, MaxLength, IsDateString } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateInventarioFisicoDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number;

    @IsInt({ message: 'ubicacion_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'ubicacion_id es obligatorio.' })
    @Min(1, { message: 'ubicacion_id debe ser mayor a 0.' })
    ubicacion_id: number;

    @IsDateString({}, { message: 'fecha_conteo debe ser una fecha válida (ISO 8601).' })
    @IsNotEmpty({ message: 'fecha_conteo es obligatoria.' })
    fecha_conteo: string;

    @IsDateString({}, { message: 'fecha_inicio debe ser una fecha y hora válida (ISO 8601).' })
    @IsNotEmpty({ message: 'fecha_inicio es obligatoria.' })
    fecha_inicio: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_fin debe ser una fecha y hora válida (ISO 8601).' })
    fecha_fin?: string;

    @IsInt({ message: 'trabajador_responsable_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'trabajador_responsable_id es obligatorio.' })
    @Min(1, { message: 'trabajador_responsable_id debe ser mayor a 0.' })
    trabajador_responsable_id: number;

    @IsInt({ message: 'trabajador_supervisor_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'trabajador_supervisor_id es obligatorio.' })
    @Min(1, { message: 'trabajador_supervisor_id debe ser mayor a 0.' })
    trabajador_supervisor_id: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'observaciones debe ser un texto.' })
    @MaxLength(500, { message: 'observaciones no puede exceder los 500 caracteres.' })
    @IsSafeText()
    observaciones?: string;
}
