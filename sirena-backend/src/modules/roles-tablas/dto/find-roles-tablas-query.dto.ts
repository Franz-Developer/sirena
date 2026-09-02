// C:\sirena\sirena-backend\src\modules\roles-tablas\dto\find-roles-tablas-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';
import { ACCIONES_EVENTOS_PERMITIDAS } from '../../../common/validators/is-eventos-permitidos.validator.service';

export class FindRolesTablasQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de rol debe ser un número entero.' })
    @Min(1, { message: 'El ID de rol debe ser un número entero mayor o igual a 1.' })
    rol_id?: number;

    @IsOptional()
    @IsString({ message: 'tabla debe ser un texto.' })
    tabla?: string;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'leer debe ser 0 o 1.' })
    leer?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'crear debe ser 0 o 1.' })
    crear?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'editar debe ser 0 o 1.' })
    editar?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'eliminar debe ser 0 o 1.' })
    eliminar?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'anular debe ser 0 o 1.' })
    anular?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'archivar debe ser 0 o 1.' })
    archivar?: number;

    @IsOptional()
    @Type(() => Number)
    @IsIn([0, 1], { message: 'desarchivar debe ser 0 o 1.' })
    desarchivar?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID de evento debe ser un número entero.' })
    @Min(1, { message: 'El ID de evento debe ser un número entero mayor o igual a 1.' })
    evento_id?: number;

    @IsOptional()
    @IsString({ message: 'El campo evento_clave debe ser un texto.' })
    @IsIn(ACCIONES_EVENTOS_PERMITIDAS as unknown as string[], {
        message: `La clave de evento debe ser una acción válida (${ACCIONES_EVENTOS_PERMITIDAS.join(', ')}).`
    })
    evento_clave?: string;

    static getCampos(): string[] {
        const alias = 't';
        const aliasRol = 'r';
        return [
            `${alias}.rol_tabla_id`,
            `${alias}.rol_id`,
            `${alias}.tabla`,
            `${alias}.leer`,
            `${alias}.crear`,
            `${alias}.editar`,
            `${alias}.eliminar`,
            `${alias}.anular`,
            `${alias}.archivar`,
            `${alias}.desarchivar`,
            `${alias}.eventos_permitidos`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,
            `${aliasRol}.rol AS rol_nombre`,
            `${aliasRol}.codigo AS rol_codigo`
        ];
    }

    static getCamposParaQ(): string[] {
        return ['t.tabla', 'r.rol', 'r.codigo', 'tabla'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'rol_tabla_id',
            'rol_id',
            'tabla',
            'leer',
            'crear',
            'editar',
            'eliminar',
            'anular',
            'archivar',
            'desarchivar',
            'rol_nombre',
            'rol_codigo'
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
        const aliasRol = 'r';
        return {
            'rol_tabla_id': `${alias}.rol_tabla_id`,
            'rol_id': `${alias}.rol_id`,
            'tabla': `${alias}.tabla`,
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
        };
    }
}

export { PaginatedResult };
