// C:\sirena\sirena-backend\src\modules\sucesos\dto\find-sucesos-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsString, IsIn, IsInt, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindSucesosQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'suceso_id debe ser un número entero.' })
    @Min(1, { message: 'suceso_id debe ser mayor a 0.' })
    suceso_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tabla_id debe ser un número entero.' })
    @Min(1, { message: 'tabla_id debe ser mayor a 0.' })
    tabla_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: createEnumMessage(ESTADO_METADATA, ESTADOS_CONSULTA, 'estado_id')
    })
    estado_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasTabla = 'tb';
        const aliasRol = 'r';
        return [
            `${alias}.suceso_id`,
            `${alias}.tabla_id`,
            `${alias}.codigo`,
            `${alias}.suceso`,
            `${alias}.descripcion`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,
            `${aliasTabla}.nombre AS tabla_nombre`,
            `${aliasRol}.rol_id AS rol_id`,
            `${aliasRol}.rol AS rol_nombre`,
            `${aliasRol}.codigo AS rol_codigo`
        ];
    }

    static getCamposParaQ(): string[] {
        return [
            't.codigo',
            't.suceso',
            't.descripcion',
            'tb.nombre',
            'r.rol',
            'r.codigo'
        ];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'suceso_id',
            'tabla_id',
            'codigo',
            'suceso',
            'descripcion',
            'tabla_nombre',
            'rol_id',
            'rol_nombre',
            'rol_codigo'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'roles_permisos_sucesos', campoFk: 'suceso_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['codigo', 'suceso', 'tabla_id'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasTabla = 'tb';
        const aliasRol = 'r';
        return {
            'suceso_id': `${alias}.suceso_id`,
            'tabla_id': `${alias}.tabla_id`,
            'codigo': `${alias}.codigo`,
            'suceso': `${alias}.suceso`,
            'descripcion': `${alias}.descripcion`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,
            'tabla_nombre': `${aliasTabla}.nombre`,
            'rol_id': `${aliasRol}.rol_id`,
            'rol_nombre': `${aliasRol}.rol`,
            'rol_codigo': `${aliasRol}.codigo`
        };
    }
}

export { PaginatedResult };
