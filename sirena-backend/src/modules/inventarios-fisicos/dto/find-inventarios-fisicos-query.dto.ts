// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\dto\find-inventarios-fisicos-query.dto.ts

import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindInventariosFisicosQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de ubicación debe ser un número entero.' })
    @Min(1, { message: 'El ID de ubicación debe ser un número entero mayor o igual a 1.' })
    ubicacion_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID del trabajador responsable debe ser un número entero.' })
    @Min(1, { message: 'El ID del trabajador responsable debe ser un número entero mayor o igual a 1.' })
    trabajador_responsable_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID del trabajador supervisor debe ser un número entero.' })
    @Min(1, { message: 'El ID del trabajador supervisor debe ser un número entero mayor o igual a 1.' })
    trabajador_supervisor_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasUbicacion = 'u';
        const aliasAlmacen = 'a';
        const aliasTrabajadorReg = 'tr';
        const aliasCargoReg = 'crc';
        const aliasTrabajadorSup = 'ts';
        const aliasCargoSup = 'csc';
        return [
            `${alias}.inventario_fisico_id`,
            `${alias}.almacen_id`,
            `${alias}.ubicacion_id`,
            `${alias}.fecha_conteo`,
            `${alias}.fecha_inicio`,
            `${alias}.fecha_fin`,
            `${alias}.trabajador_responsable_id`,
            `${alias}.trabajador_supervisor_id`,
            `${alias}.observaciones`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,

            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${aliasSucursal}.codigo_sin AS sucursal_codigo_sin`,

            `${aliasUbicacion}.codigo AS ubicacion_codigo`,
            `${aliasUbicacion}.descripcion AS ubicacion_descripcion`,
            `${aliasUbicacion}.jerarquia AS ubicacion_jerarquia`,
            `${aliasUbicacion}.almacen_id`,

            `${aliasAlmacen}.almacen AS almacen_nombre`,
            `${aliasAlmacen}.codigo AS almacen_codigo`,
            `${aliasAlmacen}.tipo_almacen_id`,
            `${aliasAlmacen}.tipo_operacion_almacen_id`,

            `CONCAT_WS(' ', ${aliasTrabajadorReg}.nombres, ${aliasTrabajadorReg}.paterno, ${aliasTrabajadorReg}.materno) AS trabajador_responsable_nombre`,
            `${aliasCargoReg}.cargo AS trabajador_responsable_cargo`,
            `${aliasCargoReg}.codigo_cargo AS trabajador_responsable_cargo_codigo`,

            `CONCAT_WS(' ', ${aliasTrabajadorSup}.nombres, ${aliasTrabajadorSup}.paterno, ${aliasTrabajadorSup}.materno) AS trabajador_supervisor_nombre`,
            `${aliasCargoSup}.cargo AS trabajador_supervisor_cargo`,
            `${aliasCargoSup}.codigo_cargo AS trabajador_supervisor_cargo_codigo`
        ];
    }

    static getCamposParaQ(): string[] {
        return [
            't.observaciones',
            's.sucursal',
            's.codigo',
            'u.codigo',
            'a.almacen',
            'a.codigo',
            'tr.nombres',
            'tr.paterno',
            'tr.materno',
            'crc.cargo',
            'crc.codigo_cargo',
            'ts.nombres',
            'ts.paterno',
            'ts.materno',
            'csc.cargo',
            'csc.codigo_cargo'
        ];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'inventario_fisico_id',
            'almacen_id',
            'ubicacion_id',
            'fecha_conteo',
            'fecha_inicio',
            'fecha_fin',
            'trabajador_responsable_id',
            'trabajador_supervisor_id',
            'sucursal_nombre',
            'sucursal_codigo',
            'sucursal_codigo_sin',
            'ubicacion_codigo',
            'almacen_nombre',
            'almacen_codigo',
            'tipo_almacen_id',
            'tipo_operacion_almacen_id',
            'trabajador_responsable_nombre',
            'trabajador_responsable_cargo',
            'trabajador_responsable_cargo_codigo',
            'trabajador_supervisor_nombre',
            'trabajador_supervisor_cargo',
            'trabajador_supervisor_cargo_codigo',
            'fecha_registro'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'inventarios_fisicos_detalle', campoFk: 'inventario_fisico_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['ubicacion_id', 'almacen_id', 'fecha_conteo', 'fecha_inicio', 'fecha_fin', 'trabajador_responsable_id', 'trabajador_supervisor_id'];                            // ✅ CORREGIDO (solo ubicacion_id)
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasUbicacion = 'u';
        const aliasAlmacen = 'a';
        const aliasTrabajadorReg = 'tr';
        const aliasCargoReg = 'crc';
        const aliasTrabajadorSup = 'ts';
        const aliasCargoSup = 'csc';
        return {
            'inventario_fisico_id': `${alias}.inventario_fisico_id`,
            'almacen_id': `${alias}.almacen_id`,
            'ubicacion_id': `${alias}.ubicacion_id`,
            'fecha_conteo': `${alias}.fecha_conteo`,
            'fecha_inicio': `${alias}.fecha_inicio`,
            'fecha_fin': `${alias}.fecha_fin`,
            'trabajador_responsable_id': `${alias}.trabajador_responsable_id`,
            'trabajador_supervisor_id': `${alias}.trabajador_supervisor_id`,
            'observaciones': `${alias}.observaciones`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,

            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'sucursal_codigo_sin': `${aliasSucursal}.codigo_sin`,
            'ubicacion_codigo': `${aliasUbicacion}.codigo`,
            'ubicacion_descripcion': `${aliasUbicacion}.descripcion`,
            'ubicacion_jerarquia': `${aliasUbicacion}.jerarquia`,
            'almacen_nombre': `${aliasAlmacen}.almacen`,
            'almacen_codigo': `${aliasAlmacen}.codigo`,
            'tipo_almacen_id': `${aliasAlmacen}.tipo_almacen_id`,
            'tipo_operacion_almacen_id': `${aliasAlmacen}.tipo_operacion_almacen_id`,
            'trabajador_responsable_nombre': `CONCAT_WS(' ', ${aliasTrabajadorReg}.nombres, ${aliasTrabajadorReg}.paterno, ${aliasTrabajadorReg}.materno)`,
            'trabajador_responsable_cargo': `${aliasCargoReg}.cargo`,
            'trabajador_responsable_cargo_codigo': `${aliasCargoReg}.codigo_cargo`,
            'trabajador_supervisor_nombre': `CONCAT_WS(' ', ${aliasTrabajadorSup}.nombres, ${aliasTrabajadorSup}.paterno, ${aliasTrabajadorSup}.materno)`,
            'trabajador_supervisor_cargo': `${aliasCargoSup}.cargo`,
            'trabajador_supervisor_cargo_codigo': `${aliasCargoSup}.codigo_cargo`
        };
    }
}

export { PaginatedResult };
