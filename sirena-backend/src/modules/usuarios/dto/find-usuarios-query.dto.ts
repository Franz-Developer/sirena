// C:\sirena\sirena-backend\src\modules\usuarios\dto\find-usuarios-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsString, IsIn, IsInt, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindUsuariosQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'trabajador_id debe ser un número entero.' })
    @Min(1, { message: 'trabajador_id debe ser mayor a 0.' })
    trabajador_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasTrabajador = 'tr';
        const aliasSucursal = 's';
        const aliasRol = 'r';
        return [
            `${alias}.usuario_id`,
            `${alias}.trabajador_id`,
            `${alias}.sucursal_id`,
            `${alias}.rol_id`,
            `${alias}.login`,
            `${alias}.contrasena`,
            `${alias}.avatar`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,
            `TRIM(CONCAT_WS(' ', ${aliasTrabajador}.nombres, ${aliasTrabajador}.paterno, ${aliasTrabajador}.materno)) AS trabajador_nombre_completo`,
            `${aliasTrabajador}.dni AS trabajador_dni`,
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${aliasSucursal}.codigo_sin AS sucursal_codigo_sin`,
            `${aliasRol}.rol AS rol_nombre`,
            `${aliasRol}.codigo AS rol_codigo`
        ];
    }

    static getCamposParaQ(): string[] {
        return [
            't.login',
            'tr.nombres',
            'tr.paterno',
            'tr.materno',
            'tr.dni',
            's.sucursal',
            's.codigo',
            'r.rol',
            'r.codigo'
        ];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'usuario_id',
            'trabajador_id',
            'sucursal_id',
            'rol_id',
            'login',
            'trabajador_nombre_completo',
            'trabajador_dni',
            'sucursal_nombre',
            'sucursal_codigo',
            'sucursal_codigo_sin',
            'rol_nombre',
            'rol_codigo'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id' },
            { tabla: 'cajas', campoFk: 'apertura_usuario_id' },
            { tabla: 'cajas', campoFk: 'cierre_usuario_id' },
            { tabla: 'cajas', campoFk: 'autorizacion_usuario_id' },
            { tabla: 'movimientos', campoFk: 'usuario_id' },
            { tabla: 'alertas_notificaciones', campoFk: 'usuario_asignado_id' },
            { tabla: 'alertas_notificaciones', campoFk: 'usuario_resolutor_id' },
            { tabla: 'pedidos_online', campoFk: 'repartidor_id' },
            { tabla: 'asistencias', campoFk: 'usuario_registro_id' },
            { tabla: 'planillas', campoFk: 'usuario_aprobacion_id' },
            { tabla: 'planillas', campoFk: 'usuario_pago_id' },
            { tabla: 'contratos', campoFk: 'usuario_firma_id' },
            { tabla: 'inventarios_fisicos', campoFk: 'usuario_registro_id' },
            { tabla: 'inventarios_fisicos', campoFk: 'usuario_supervisor_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['login', 'trabajador_id', 'sucursal_id', 'rol_id'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasTrabajador = 'tr';
        const aliasSucursal = 's';
        const aliasRol = 'r';
        return {
            'usuario_id': `${alias}.usuario_id`,
            'trabajador_id': `${alias}.trabajador_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'rol_id': `${alias}.rol_id`,
            'login': `${alias}.login`,
            'contrasena': `${alias}.contrasena`,
            'avatar': `${alias}.avatar`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,
            'trabajador_nombre_completo': `TRIM(CONCAT_WS(' ', ${aliasTrabajador}.nombres, ${aliasTrabajador}.paterno, ${aliasTrabajador}.materno))`,
            'trabajador_dni': `${aliasTrabajador}.dni`,
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'sucursal_codigo_sin': `${aliasSucursal}.codigo_sin`,
            'rol_nombre': `${aliasRol}.rol`,
            'rol_codigo': `${aliasRol}.codigo`
        };
    }
}

export { PaginatedResult };
