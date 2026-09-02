// C:\sirena\sirena-backend\src\modules\unidades\dto\find-unidades-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsString, IsIn, IsInt, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindUnidadesQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo exactMatch debe ser un número entero.' })
    @IsIn([0, 1], { message: 'El campo exactMatch debe ser 0 (flexible) o 1 (exacta).' })
    exactMatch: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'usuario_id debe ser un número entero.' })
    @Min(1, { message: 'usuario_id debe ser mayor a 0.' })
    usuario_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: createEnumMessage(ESTADO_METADATA, ESTADOS_CONSULTA, 'estado_id')
    })
    estado_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'codigo_sin debe ser un número entero.' })
    @Min(0, { message: 'codigo_sin debe ser mayor o igual a 0.' })
    codigo_sin?: number;

    // Todos los campos de la tabla principal.
    static getCampos(): string[] {
        const alias = 't';
        return [
            `${alias}.unidad_id`,
            `${alias}.codigo`,
            `${alias}.codigo_sin`,
            `${alias}.unidad`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    // Todos los campos que son VARCHAR para las búsquedas con 'q'
    static getCamposParaQ(): string[] {
        return ['codigo', 'unidad'];
    }

    // Todos los campos de la tabla principal menos campos de auditoria.
    static getCamposPermitidosParaOrdenar(): string[] {
        return ['unidad_id', 'codigo', 'codigo_sin', 'unidad'];
    }

    // Todas las dependencias de unidades.
    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'presentaciones', campoFk: 'unidad_id' },
            { tabla: 'ubicaciones', campoFk: 'unidad_id' },
            { tabla: 'concentraciones', campoFk: 'unidad_base_id' },
            { tabla: 'productos', campoFk: 'unidad_venta_id' },
            { tabla: 'conversiones_unidad', campoFk: 'unidad_origen_id' },
            { tabla: 'conversiones_unidad', campoFk: 'unidad_destino_id' },
        ];
    }

    // Campos que no deben modificarse si la tabla tiene dependencias activas.
    static getCamposProtegidosConDependencias(): string[] {
        return ['codigo', 'codigo_sin', 'unidad'];
    }

    // Todos los campos de la tabla principal para mapeo de ordenamiento.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        return {
            'unidad_id': `${alias}.unidad_id`,
            'codigo': `${alias}.codigo`,
            'codigo_sin': `${alias}.codigo_sin`,
            'unidad': `${alias}.unidad`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`
        };
    }
}

export { PaginatedResult };
