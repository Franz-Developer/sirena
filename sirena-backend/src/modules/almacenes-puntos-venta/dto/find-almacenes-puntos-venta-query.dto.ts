// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\dto\find-almacenes-puntos-venta-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindAlmacenesPuntosVentaQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de almacén debe ser un número entero.' })
    @Min(1, { message: 'El ID de almacén debe ser un número entero mayor o igual a 1.' })
    almacen_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID de punto de venta debe ser un número entero.' })
    @Min(1, { message: 'El ID de punto de venta debe ser un número entero mayor o igual a 1.' })
    punto_venta_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'es_principal debe ser 0 (No) o 1 (Sí).' })
    es_principal?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasAlmacen = 'a';
        const aliasPuntoVenta = 'pv';
        return [
            `${alias}.almacen_punto_venta_id`,
            `${alias}.sucursal_id`,
            `${alias}.almacen_id`,
            `${alias}.punto_venta_id`,
            `${alias}.prioridad`,
            `${alias}.es_principal`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${aliasAlmacen}.almacen AS almacen_nombre`,
            `${aliasAlmacen}.codigo AS almacen_codigo`,
            `${aliasPuntoVenta}.nombre AS punto_venta_nombre`,
            `${aliasPuntoVenta}.codigo AS punto_venta_codigo`
        ];
    }

    static getCamposParaQ(): string[] {
        return ['s.sucursal', 's.codigo', 'a.almacen', 'a.codigo', 'pv.nombre', 'pv.codigo'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'almacen_punto_venta_id',
            'sucursal_id',
            'almacen_id',
            'punto_venta_id',
            'prioridad',
            'es_principal',
            'sucursal_nombre',
            'sucursal_codigo',
            'almacen_nombre',
            'almacen_codigo',
            'punto_venta_nombre',
            'punto_venta_codigo'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return [];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasAlmacen = 'a';
        const aliasPuntoVenta = 'pv';
        return {
            'almacen_punto_venta_id': `${alias}.almacen_punto_venta_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'almacen_id': `${alias}.almacen_id`,
            'punto_venta_id': `${alias}.punto_venta_id`,
            'prioridad': `${alias}.prioridad`,
            'es_principal': `${alias}.es_principal`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'almacen_nombre': `${aliasAlmacen}.almacen`,
            'almacen_codigo': `${aliasAlmacen}.codigo`,
            'punto_venta_nombre': `${aliasPuntoVenta}.nombre`,
            'punto_venta_codigo': `${aliasPuntoVenta}.codigo`,
        };
    }
}

export { PaginatedResult };
