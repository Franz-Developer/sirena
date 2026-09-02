// C:\sirena\sirena-backend\src\modules\almacenes\dto\find-almacenes-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindAlmacenesQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de sucursal debe ser un número entero mayor o igual a 1.' })
    @Min(1, { message: 'El ID de sucursal debe ser un número entero mayor o igual a 1.' })
    sucursal_id: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoAlmacen), {
        message: createEnumMessage(TIPO_ALMACEN_METADATA, getEnumValues(TipoAlmacen), 'tipo_almacen_id')
    })
    tipo_almacen_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_operacion_almacen_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoOperacionAlmacen), {
        message: createEnumMessage(TIPO_OPERACION_ALMACEN_METADATA, getEnumValues(TipoOperacionAlmacen), 'tipo_operacion_almacen_id')
    })
    tipo_operacion_almacen_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        return [
            `${alias}.almacen_id`,
            `${alias}.sucursal_id`,
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${alias}.almacen`,
            `${alias}.codigo`,
            `${alias}.tipo_almacen_id`,
            `${alias}.tipo_operacion_almacen_id`,
            `${alias}.descripcion`,
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
        return ['almacen', 'codigo', 'descripcion', 's.sucursal', 's.codigo'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'almacen_id',
            'sucursal_id',
            'almacen',
            'codigo',
            'tipo_almacen_id',
            'tipo_operacion_almacen_id',
            'sucursal_nombre',
            'sucursal_codigo'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'ubicaciones', campoFk: 'almacen_id' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'almacen_id' },
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['sucursal_id'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasSucursal = 's';
        return {
            'almacen_id': `${alias}.almacen_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'almacen': `${alias}.almacen`,
            'codigo': `${alias}.codigo`,
            'tipo_almacen_id': `${alias}.tipo_almacen_id`,
            'tipo_operacion_almacen_id': `${alias}.tipo_operacion_almacen_id`,
            'descripcion': `${alias}.descripcion`,
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
