// C:\sirena\sirena-backend\src\modules\sucursales\dto\find-sucursales-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindSucursalesQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'El ID de empresa debe ser un número entero.' })
    @Min(1, { message: 'El ID de empresa debe ser un número entero mayor o igual a 1.' })
    empresa_id: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'codigo_sin debe ser un número entero.' })
    codigo_sin?: number;

    // Todos los campos de la tabla principal (con soporte para join opcional a empresas si se requiere).
    static getCampos(): string[] {
        const alias = 't';
        const aliasEmpresa = 'e';
        return [
            `${alias}.sucursal_id`,
            `${alias}.empresa_id`,
            `${aliasEmpresa}.empresa AS empresa_nombre`,
            `${aliasEmpresa}.codigo AS empresa_codigo`,
            `${alias}.sucursal`,
            `${alias}.sucursal_largo`,
            `${alias}.codigo`,
            `${alias}.codigo_sin`,
            `${alias}.telefono`,
            `${alias}.ubicacion`,
            `${alias}.horario_atencion`,
            `${alias}.factor_venta`,
            `${alias}.factor_facturacion`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    // Todos los campos que son VARCHAR o texto para la búsqueda global 'q'
    static getCamposParaQ(): string[] {
        return ['sucursal', 'sucursal_largo', 'codigo', 'telefono', 'ubicacion', 'horario_atencion', 'e.empresa', 'e.codigo'];
    }

    // Todos los campos de la tabla principal menos auditoría aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'sucursal_id',
            'empresa_id',
            'sucursal',
            'sucursal_largo',
            'codigo',
            'codigo_sin',
            'telefono',
            'ubicacion',
            'horario_atencion',
            'factor_venta',
            'factor_facturacion',
            'empresa_nombre',
            'empresa_codigo'
        ];
    }

    // Todas las dependencias.
    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            // Tablas que dependen directamente de sucursales
            { tabla: 'puntos_venta', campoFk: 'sucursal_id' },
            { tabla: 'cuis', campoFk: 'sucursal_id' },
            { tabla: 'cufd', campoFk: 'sucursal_id' },
            { tabla: 'almacenes', campoFk: 'sucursal_id' },
            { tabla: 'usuarios', campoFk: 'sucursal_id' },
            { tabla: 'inventarios_fisicos', campoFk: 'sucursal_id' },
            { tabla: 'control_facturas', campoFk: 'sucursal_id' },
            { tabla: 'kardex', campoFk: 'sucursal_id' },
            { tabla: 'kardex', campoFk: 'sucursal_destino_id' },
            { tabla: 'recetas', campoFk: 'sucursal_id' },
            { tabla: 'kardex_productos', campoFk: 'sucursal_id' },
            { tabla: 'cajas', campoFk: 'sucursal_id' },
            { tabla: 'alertas_notificaciones', campoFk: 'sucursal_id' },
            { tabla: 'patrones_consumo', campoFk: 'sucursal_id' },
            { tabla: 'variables_exogenas', campoFk: 'sucursal_id' },
            { tabla: 'umbrales_configuracion', campoFk: 'sucursal_id' },
            { tabla: 'analitica_productos', campoFk: 'sucursal_id' },
            { tabla: 'pedidos_online', campoFk: 'sucursal_id' },
            { tabla: 'asistencias', campoFk: 'sucursal_id' },
            { tabla: 'planillas', campoFk: 'sucursal_id' },
            { tabla: 'historicos', campoFk: 'sucursal_id' },
        ];
    }

    // Campos que no deben modificarse si la tabla tiene dependencias activas.
    static getCamposProtegidosConDependencias(): string[] {
        return ['empresa_id', 'sucursal', 'sucursal_largo', 'codigo', 'codigo_sin'];
    }

    // Equivalencias de mapeo para consultas avanzadas y filtros.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasEmpresa = 'e';
        return {
            'sucursal_id': `${alias}.sucursal_id`,
            'empresa_id': `${alias}.empresa_id`,
            'empresa_nombre': `${aliasEmpresa}.empresa`,
            'empresa_codigo': `${aliasEmpresa}.codigo`,
            'sucursal': `${alias}.sucursal`,
            'sucursal_largo': `${alias}.sucursal_largo`,
            'codigo': `${alias}.codigo`,
            'codigo_sin': `${alias}.codigo_sin`,
            'telefono': `${alias}.telefono`,
            'ubicacion': `${alias}.ubicacion`,
            'horario_atencion': `${alias}.horario_atencion`,
            'factor_venta': `${alias}.factor_venta`,
            'factor_facturacion': `${alias}.factor_facturacion`,
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
