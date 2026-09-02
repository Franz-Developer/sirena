// C:\sirena\sirena-backend\src\modules\puntos-venta\dto\find-puntos-venta-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, TipoPuntoVenta, TIPO_PUNTO_VENTA_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindPuntosVentaQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'sucursal_id debe ser un número entero mayor o igual a 1.' })
    @Min(1, { message: 'sucursal_id debe ser un número entero mayor o igual a 1.' })
    sucursal_id: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_punto_venta_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoPuntoVenta), {
        message: createEnumMessage(TIPO_PUNTO_VENTA_METADATA, getEnumValues(TipoPuntoVenta), 'tipo_punto_venta_id')
    })
    tipo_punto_venta_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'codigo debe ser un número entero.' })
    @Min(0, { message: 'codigo debe ser mayor o igual a 0.' })
    codigo?: number;

    // Todos los campos de la tabla principal (con soporte para join opcional a sucursales).
    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        return [
            `${alias}.punto_venta_id`,
            `${alias}.sucursal_id`,
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${alias}.codigo`,
            `${alias}.nombre`,
            `${alias}.tipo_punto_venta_id`,
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
        return ['nombre', 's.sucursal', 's.codigo'];
    }

    // Todos los campos de la tabla principal menos campos de auditoria aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'punto_venta_id',
            'sucursal_id',
            'codigo',
            'nombre',
            'tipo_punto_venta_id',
            'sucursal_nombre',
            'sucursal_codigo'
        ];
    }

    // Todas las dependencias.
    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'cuis', campoFk: 'punto_venta_id' },
            { tabla: 'cufd', campoFk: 'punto_venta_id' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'punto_venta_id' },
        ];
    }

    // Campos que no deben modificarse si la tabla tiene dependencias activas.
    static getCamposProtegidosConDependencias(): string[] {
        return ['sucursal_id', 'codigo', 'nombre'];
    }

    // Equivalencias de mapeo para consultas avanzadas y filtros.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasSucursal = 's';
        return {
            'punto_venta_id': `${alias}.punto_venta_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'codigo': `${alias}.codigo`,
            'nombre': `${alias}.nombre`,
            'tipo_punto_venta_id': `${alias}.tipo_punto_venta_id`,
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
