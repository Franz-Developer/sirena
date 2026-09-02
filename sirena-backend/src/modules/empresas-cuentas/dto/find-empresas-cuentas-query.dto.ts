// C:\sirena\sirena-backend\src\modules\empresas-cuentas\dto\find-empresas-cuentas-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA,TipoMoneda, TIPO_MONEDA_METADATA, TipoCuenta, TIPO_CUENTA_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindEmpresasCuentasQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de empresa debe ser un número entero.' })
    @Min(1, { message: 'El ID de empresa debe ser un número entero mayor o igual a 1.' })
    empresa_id: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID de banco debe ser un número entero.' })
    @Min(1, { message: 'El ID de banco debe ser un número entero mayor o igual a 1.' })
    banco_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_moneda_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'tipo_moneda_id')
    })
    tipo_moneda_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_cuenta_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoCuenta), {
        message: createEnumMessage(TIPO_CUENTA_METADATA, getEnumValues(TipoCuenta), 'tipo_cuenta_id')
    })
    tipo_cuenta_id?: number;

    // Todos los campos de la tabla principal (con soporte para joins a empresas y bancos).
    static getCampos(): string[] {
        const alias = 't';
        const aliasEmpresa = 'e';
        const aliasBanco = 'b';
        return [
            // Tabla principal.
            `${alias}.empresa_cuenta_id`,
            `${alias}.empresa_id`,
            `${alias}.banco_id`,
            `${alias}.tipo_moneda_id`,
            `${alias}.nro_cuenta`,
            `${alias}.tipo_cuenta_id`,
            `${alias}.titular`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,

            // Campos de la tabla empresas.
            `${aliasEmpresa}.empresa AS empresa_nombre`,
            `${aliasEmpresa}.codigo AS empresa_codigo`,

            // Campos de la tabla bancos.
            `${aliasBanco}.banco AS banco_nombre`,
            `${aliasBanco}.codigo_asfi AS banco_codigo_asfi`,
            `${aliasBanco}.abreviatura AS banco_abreviatura`
        ];
    }

    // Todos los campos que son VARCHAR o texto para la búsqueda global 'q'
    static getCamposParaQ(): string[] {
        return ['nro_cuenta', 'titular', 'e.empresa', 'e.codigo', 'b.banco', 'b.abreviatura', 'b.codigo_asfi'];
    }

    // Todos los campos de la tabla principal menos campos de auditoria aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            // Tabla principal.
            'empresa_cuenta_id',
            'empresa_id',
            'banco_id',
            'tipo_moneda_id',
            'nro_cuenta',
            'tipo_cuenta_id',
            'titular',

            // Tabla empresas (JOIN).
            'empresa_nombre',
            'empresa_codigo',

            // Tabla bancos (JOIN).
            'banco_nombre',
            'banco_abreviatura',
            'banco_codigo_asfi'
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
        const aliasBanco = 'b';
        return {
            // Tabla principal.
            'empresa_cuenta_id': `${alias}.empresa_cuenta_id`,
            'empresa_id': `${alias}.empresa_id`,
            'banco_id': `${alias}.banco_id`,
            'tipo_moneda_id': `${alias}.tipo_moneda_id`,
            'nro_cuenta': `${alias}.nro_cuenta`,
            'tipo_cuenta_id': `${alias}.tipo_cuenta_id`,
            'titular': `${alias}.titular`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,

            // Tabla empresas (JOIN).
            'empresa_nombre': `${aliasEmpresa}.empresa`,
            'empresa_codigo': `${aliasEmpresa}.codigo`,

            // Tabla bancos (JOIN).
            'banco_nombre': `${aliasBanco}.banco`,
            'banco_codigo_asfi': `${aliasBanco}.banco_codigo_asfi`,
            'banco_abreviatura': `${aliasBanco}.abreviatura`,
        };
    }
}

export { PaginatedResult };
