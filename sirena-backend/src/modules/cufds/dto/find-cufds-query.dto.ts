// C:\sirena\sirena-backend\src\modules\cufds\dto\find-cufds-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindCufdsQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de sucursal debe ser un número entero.' })
    @Min(1, { message: 'El ID de sucursal debe ser un número entero mayor o igual a 1.' })
    sucursal_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID de punto de venta debe ser un número entero.' })
    @Min(1, { message: 'El ID de punto de venta debe ser un número entero mayor o igual a 1.' })
    punto_venta_id?: number;

    // Todos los campos de la tabla principal (con soporte para joins a sucursales y puntos_venta).
    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasPuntoVenta = 'pv';
        return [
            // Tabla principal.
            `${alias}.cufd_id`,
            `${alias}.sucursal_id`,
            `${alias}.punto_venta_id`,
            `${alias}.codigo_cufd`,
            `${alias}.codigo_control`,
            `${alias}.fecha_vigencia`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,

            // Campos de la tabla sucursales.
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,

            // Campos de la tabla puntos_venta.
            `${aliasPuntoVenta}.nombre AS punto_venta_nombre`,
            `${aliasPuntoVenta}.codigo AS punto_venta_codigo`
        ];
    }

    // Todos los campos que son VARCHAR o texto para la búsqueda global 'q'
    static getCamposParaQ(): string[] {
        return ['codigo_cufd', 'codigo_control', 's.sucursal', 's.codigo', 'pv.nombre'];
    }

    // Todos los campos de la tabla principal menos campos de auditoria aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            // Tabla principal.
            'cufd_id',
            'sucursal_id',
            'punto_venta_id',
            'codigo_cufd',
            'codigo_control',
            'fecha_vigencia',

            // Tabla sucursales (JOIN).
            'sucursal_nombre',
            'sucursal_codigo',

            // Tabla puntos_venta (JOIN).
            'punto_venta_nombre',
            'punto_venta_codigo'
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
        const aliasSucursal = 's';
        const aliasPuntoVenta = 'pv';
        return {
            // Tabla principal.
            'cufd_id': `${alias}.cufd_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'punto_venta_id': `${alias}.punto_venta_id`,
            'codigo_cufd': `${alias}.codigo_cufd`,
            'codigo_control': `${alias}.codigo_control`,
            'fecha_vigencia': `${alias}.fecha_vigencia`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,

            // Tabla sucursales (JOIN).
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,

            // Tabla puntos_venta (JOIN).
            'punto_venta_nombre': `${aliasPuntoVenta}.nombre`,
            'punto_venta_codigo': `${aliasPuntoVenta}.codigo`,
        };
    }
}

export { PaginatedResult };
