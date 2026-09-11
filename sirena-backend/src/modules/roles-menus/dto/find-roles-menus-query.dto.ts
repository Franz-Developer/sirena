// C:\sirena\sirena-backend\src\modules\roles-menus\dto\find-roles-menus-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindRolesMenusQueryDto extends BasePaginationQueryDto {
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
    @Type(() => Number)
    @IsInt({ message: 'El ID de menú debe ser un número entero.' })
    @Min(1, { message: 'El ID de menú debe ser un número entero mayor o igual a 1.' })
    menu_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasRol = 'r';
        const aliasMenu = 'm';
        return [
            `${alias}.rol_menu_id`,
            `${alias}.rol_id`,
            `${alias}.menu_id`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,
            `${aliasRol}.rol AS rol_nombre`,
            `${aliasRol}.codigo AS rol_codigo`,
            `${aliasMenu}.titulo AS menu_titulo`,
            `${aliasMenu}.url AS menu_url`
        ];
    }

    static getCamposParaQ(): string[] {
        return ['r.rol', 'r.codigo', 'm.titulo', 'm.url'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'rol_menu_id',
            'rol_id',
            'menu_id',
            'rol_nombre',
            'rol_codigo',
            'menu_titulo',
            'menu_url'
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
        const aliasMenu = 'm';
        return {
            'rol_menu_id': `${alias}.rol_menu_id`,
            'rol_id': `${alias}.rol_id`,
            'menu_id': `${alias}.menu_id`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,
            'rol_nombre': `${aliasRol}.rol`,
            'rol_codigo': `${aliasRol}.codigo`,
            'menu_titulo': `${aliasMenu}.titulo`,
            'menu_url': `${aliasMenu}.url`,
        };
    }
}

export { PaginatedResult };
