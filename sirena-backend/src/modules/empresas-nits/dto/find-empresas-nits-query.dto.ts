// C:\sirena\sirena-backend\src\modules\empresas-nits\dto\find-empresas-nits-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, IsDateString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, AMBIENTE_METADATA, Ambiente, MODALIDAD_FACTURACION_METADATA, ModalidadFacturacion } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindEmpresasNitsQueryDto extends BasePaginationQueryDto {
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

    @Type(() => Number)
    @IsInt({ message: 'El ID de empresa debe ser un número entero mayor o igual a 1.' })
    @Min(1, { message: 'El ID de empresa debe ser un número entero mayor o igual a 1.' })
    empresa_id: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'ambiente_id debe ser un número entero.' })
    @IsIn(getEnumValues(Ambiente), {
        message: createEnumMessage(AMBIENTE_METADATA, getEnumValues(Ambiente), 'ambiente_id')
    })
    ambiente_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'modalidad_facturacion_id debe ser un número entero.' })
    @IsIn(getEnumValues(ModalidadFacturacion), {
        message: createEnumMessage(MODALIDAD_FACTURACION_METADATA, getEnumValues(ModalidadFacturacion), 'modalidad_facturacion_id')
    })
    modalidad_facturacion_id?: number;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_inicio_vigencia_desde debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_inicio_vigencia_desde?: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_inicio_vigencia_hasta debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_inicio_vigencia_hasta?: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_fin_vigencia_desde debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_fin_vigencia_desde?: string;

    @IsOptional()
    @IsDateString({}, { message: 'fecha_fin_vigencia_hasta debe ser una fecha válida (YYYY-MM-DD).' })
    fecha_fin_vigencia_hasta?: string;

    // Todos los campos de la tabla principal (con soporte para join opcional a empresas).
    static getCampos(): string[] {
        const alias = 't';
        const aliasEmpresa = 'e';
        return [
            `${alias}.empresa_nit_id`,
            `${alias}.empresa_id`,
            `${aliasEmpresa}.empresa AS empresa_nombre`,
            `${aliasEmpresa}.codigo AS empresa_codigo`,
            `${alias}.ambiente_id`,
            `${alias}.nit`,
            `${alias}.razon_social`,
            `${alias}.etiqueta`,
            `${alias}.actividad_economica_principal`,
            `${alias}.modalidad_facturacion_id`,
            `${alias}.certificado_digital`,
            `${alias}.certificado_password`,
            `${alias}.token_siat`,
            `${alias}.fecha_inicio_vigencia`,
            `${alias}.fecha_fin_vigencia`,
            `${alias}.email_fiscal`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    // Todos los campos que son VARCHAR o texto para la búsqueda global 'q'
    static getCamposParaQ(): string[] {
        return ['nit', 'razon_social', 'etiqueta', 'actividad_economica_principal', 'email_fiscal', 'e.empresa', 'e.codigo'];
    }

    // Todos los campos de la tabla principal menos campos de auditoria aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'empresa_nit_id',
            'empresa_id',
            'nit',
            'razon_social',
            'etiqueta',
            'actividad_economica_principal',
            'email_fiscal',
            'fecha_inicio_vigencia',
            'fecha_fin_vigencia',
            'empresa_nombre',
            'empresa_codigo'
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

    // Equivalencias de mapeo para consultas avanzadas y filtros.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasEmpresa = 'e';
        return {
            'empresa_nit_id': `${alias}.empresa_nit_id`,
            'empresa_id': `${alias}.empresa_id`,
            'empresa_nombre': `${aliasEmpresa}.empresa`,
            'empresa_codigo': `${aliasEmpresa}.codigo`,
            'ambiente_id': `${alias}.ambiente_id`,
            'nit': `${alias}.nit`,
            'razon_social': `${alias}.razon_social`,
            'etiqueta': `${alias}.etiqueta`,
            'actividad_economica_principal': `${alias}.actividad_economica_principal`,
            'modalidad_facturacion_id': `${alias}.modalidad_facturacion_id`,
            'email_fiscal': `${alias}.email_fiscal`,
            'fecha_inicio_vigencia': `${alias}.fecha_inicio_vigencia`,
            'fecha_fin_vigencia': `${alias}.fecha_fin_vigencia`,
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
