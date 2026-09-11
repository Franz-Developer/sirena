// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\dto\find-roles-permisos-tablas-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsString, IsIn, IsInt, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindRolesPermisosTablasQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tabla_id debe ser un número entero.' })
    @Min(1, { message: 'tabla_id debe ser mayor a 0.' })
    tabla_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: createEnumMessage(ESTADO_METADATA, ESTADOS_CONSULTA, 'estado_id')
    })
    estado_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasRol = 'r';
        const aliasTabla = 'tb';
        return [
            `${alias}.rol_permiso_tabla_id`,
            `${alias}.rol_id`,
            `${alias}.tabla_id`,
            `${alias}.leer`,
            `${alias}.crear`,
            `${alias}.editar`,
            `${alias}.eliminar`,
            `${alias}.anular`,
            `${alias}.archivar`,
            `${alias}.desarchivar`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,
            `${aliasRol}.rol AS rol_nombre`,
            `${aliasRol}.codigo AS rol_codigo`,
            `${aliasTabla}.nombre AS tabla_nombre`
        ];
    }

    static getCamposParaQ(): string[] {
        return [
            'r.rol',
            'r.codigo',
            'tb.nombre'
        ];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'rol_permiso_tabla_id',
            'rol_id',
            'tabla_id',
            'rol_nombre',
            'rol_codigo',
            'tabla_nombre'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'roles_permisos_sucesos', campoFk: 'rol_permiso_tabla_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['rol_id', 'tabla_id'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasRol = 'r';
        const aliasTabla = 'tb';
        return {
            'rol_permiso_tabla_id': `${alias}.rol_permiso_tabla_id`,
            'rol_id': `${alias}.rol_id`,
            'tabla_id': `${alias}.tabla_id`,
            'leer': `${alias}.leer`,
            'crear': `${alias}.crear`,
            'editar': `${alias}.editar`,
            'eliminar': `${alias}.eliminar`,
            'anular': `${alias}.anular`,
            'archivar': `${alias}.archivar`,
            'desarchivar': `${alias}.desarchivar`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,
            'rol_nombre': `${aliasRol}.rol`,
            'rol_codigo': `${aliasRol}.codigo`,
            'tabla_nombre': `${aliasTabla}.nombre`
        };
    }
}

export { PaginatedResult };
