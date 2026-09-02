// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\dto\find-trabajadores-cargos-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, TipoMoneda, TIPO_MONEDA_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindTrabajadoresCargosQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'trabajador_id debe ser un número entero.' })
    @Min(1, { message: 'trabajador_id debe ser mayor o igual a 1.' })
    trabajador_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'cargo_id debe ser un número entero.' })
    @Min(1, { message: 'cargo_id debe ser mayor o igual a 1.' })
    cargo_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_moneda_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'tipo_moneda_id')
    })
    tipo_moneda_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasTrabajador = 'tr';
        const aliasCargo = 'c';
        return [
            `${alias}.trabajador_cargo_id`,
            `${alias}.trabajador_id`,
            `${aliasTrabajador}.nombres AS trabajador_nombres`,
            `${aliasTrabajador}.paterno AS trabajador_paterno`,
            `${aliasTrabajador}.materno AS trabajador_materno`,
            `${aliasTrabajador}.dni AS trabajador_dni`,
            `${alias}.cargo_id`,
            `${aliasCargo}.cargo AS cargo_nombre`,
            `${aliasCargo}.codigo AS cargo_codigo`,
            `${alias}.sueldo_base`,
            `${alias}.tipo_moneda_id`,
            `${alias}.fecha_desde`,
            `${alias}.fecha_hasta`,
            `${alias}.es_activo`,
            `${alias}.observaciones`,
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
        return ['observaciones', 'tr.nombres', 'tr.paterno', 'tr.materno', 'tr.dni', 'c.cargo', 'c.codigo'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'trabajador_cargo_id',
            'trabajador_id',
            'cargo_id',
            'sueldo_base',
            'tipo_moneda_id',
            'fecha_desde',
            'fecha_hasta',
            'es_activo',
            'trabajador_dni',
            'cargo_nombre',
            'cargo_codigo'
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
        const aliasTrabajador = 'tr';
        const aliasCargo = 'c';
        return {
            'trabajador_cargo_id': `${alias}.trabajador_cargo_id`,
            'trabajador_id': `${alias}.trabajador_id`,
            'trabajador_dni': `${aliasTrabajador}.dni`,
            'cargo_id': `${alias}.cargo_id`,
            'cargo_nombre': `${aliasCargo}.cargo`,
            'cargo_codigo': `${aliasCargo}.codigo`,
            'sueldo_base': `${alias}.sueldo_base`,
            'tipo_moneda_id': `${alias}.tipo_moneda_id`,
            'fecha_desde': `${alias}.fecha_desde`,
            'fecha_hasta': `${alias}.fecha_hasta`,
            'es_activo': `${alias}.es_activo`,
            'observaciones': `${alias}.observaciones`,
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
