// C:\sirena\sirena-backend\src\modules\parametros-globales\dto\find-parametros-globales-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, TipoDato, TIPO_DATO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindParametrosGlobalesQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'tipo_dato_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoDato), {
        message: createEnumMessage(TIPO_DATO_METADATA, getEnumValues(TipoDato), 'tipo_dato_id')
    })
    tipo_dato_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'editable debe ser un número entero.' })
    @IsIn([0, 1], { message: 'editable debe ser 0 o 1.' })
    editable?: number;

    static getCampos(): string[] {
        const alias = 't';
        return [
            `${alias}.parametro_id`,
            `${alias}.clave`,
            `${alias}.valor`,
            `${alias}.tipo_dato_id`,
            `${alias}.datos_json`,
            `${alias}.descripcion`,
            `${alias}.editable`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    static getCamposParaQ(): string[] {
        return ['clave', 'valor', 'descripcion'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'parametro_id',
            'clave',
            'valor',
            'tipo_dato_id',
            'descripcion',
            'editable',
            'fecha_registro'
        ];
    }

    // Todas las dependencias.
    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [];
    }

    // Campos que no deben modificarse si la tabla tiene dependencias activas.
    static getCamposProtegidosConDependencias(): string[] {
        return [];
    }

    // Todos los campos de la tabla principal.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        return {
            'parametro_id': `${alias}.parametro_id`,
            'clave': `${alias}.clave`,
            'valor': `${alias}.valor`,
            'tipo_dato_id': `${alias}.tipo_dato_id`,
            'datos_json': `${alias}.datos_json`,
            'descripcion': `${alias}.descripcion`,
            'editable': `${alias}.editable`,
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
