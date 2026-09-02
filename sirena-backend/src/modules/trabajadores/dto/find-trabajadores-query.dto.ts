// C:\sirena\sirena-backend\src\modules\trabajadores\dto\find-trabajadores-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsString, IsIn, IsInt, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, Genero, GENERO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindTrabajadoresQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'genero_id debe ser un número entero.' })
    @IsIn(getEnumValues(Genero), {
        message: createEnumMessage(GENERO_METADATA, getEnumValues(Genero), 'genero_id')
    })
    genero_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        return [
            `${alias}.trabajador_id`,
            `${alias}.genero_id`,
            `${alias}.estado_civil_id`,
            `${alias}.nombres`,
            `${alias}.paterno`,
            `${alias}.materno`,
            `${alias}.dni`,
            `${alias}.telefono`,
            `${alias}.direccion`,
            `${alias}.email`,
            `${alias}.fecha_nacimiento`,
            `${alias}.fecha_contratacion`,
            `${alias}.foto`,
            `${alias}.qr`,
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
        return ['nombres', 'paterno', 'materno', 'dni', 'telefono', 'email'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return ['trabajador_id', 'nombres', 'paterno', 'materno', 'dni'];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'usuarios', campoFk: 'trabajador_id' },
            { tabla: 'trabajadores_cargos', campoFk: 'trabajador_id' },
            { tabla: 'planillas_detalle', campoFk: 'trabajador_id' },
            { tabla: 'contratos', campoFk: 'trabajador_id' },
            { tabla: 'asistencias', campoFk: 'trabajador_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['dni', 'nombres', 'paterno', 'materno'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        return {
            'trabajador_id': `${alias}.trabajador_id`,
            'genero_id': `${alias}.genero_id`,
            'estado_civil_id': `${alias}.estado_civil_id`,
            'nombres': `${alias}.nombres`,
            'paterno': `${alias}.paterno`,
            'materno': `${alias}.materno`,
            'dni': `${alias}.dni`,
            'telefono': `${alias}.telefono`,
            'direccion': `${alias}.direccion`,
            'email': `${alias}.email`,
            'fecha_nacimiento': `${alias}.fecha_nacimiento`,
            'fecha_contratacion': `${alias}.fecha_contratacion`,
            'foto': `${alias}.foto`,
            'qr': `${alias}.qr`,
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
