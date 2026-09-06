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
    @IsInt({ message: 'rol_id debe ser un número entero.' })
    @Min(1, { message: 'rol_id debe ser mayor a 0.' })
    rol_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'empresa_id debe ser un número entero.' })
    @Min(1, { message: 'empresa_id debe ser mayor a 0.' })
    empresa_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'cargo_id debe ser un número entero.' })
    @Min(1, { message: 'cargo_id debe ser mayor a 0.' })
    cargo_id?: number;

    static getCampos(): string[] {
        const alias = 't';
        const aliasTrabajador = 'tr';
        const aliasSucursal = 's';
        const aliasEmpresa = 'e';
        const aliasRol = 'r';
        const aliasCargo = 'c';
        return [
            `${alias}.usuario_id`,
            `${alias}.trabajador_id`,
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
            `${aliasTrabajador}.nombres AS trabajador_nombres`,
            `${aliasTrabajador}.paterno AS trabajador_paterno`,
            `${aliasTrabajador}.materno AS trabajador_materno`,
            `${aliasTrabajador}.dni AS trabajador_dni`,
            `${aliasEmpresa}.empresa_id AS empresa_id`,
            `${aliasEmpresa}.empresa AS empresa_nombre`,
            `${aliasEmpresa}.codigo AS empresa_codigo`,
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,
            `${aliasSucursal}.codigo_sin AS sucursal_codigo_sin`,
            `${aliasRol}.rol AS rol_nombre`,
            `${aliasRol}.codigo AS rol_codigo`,
            `${aliasCargo}.cargo_id AS cargo_id`,
            `${aliasCargo}.cargo AS cargo_nombre`,
            `${aliasCargo}.codigo AS cargo_codigo`
        ];
    }

    static getCamposParaQ(): string[] {
        return [
            't.login',
            'tr.nombres',
            'tr.paterno',
            'tr.materno',
            'tr.dni',
            'e.empresa',
            'e.codigo',
            's.sucursal',
            's.codigo',
            'r.rol',
            'r.codigo',
            'c.cargo',
            'c.codigo'
        ];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'usuario_id',
            'trabajador_id',
            'rol_id',
            'empresa_id',
            'cargo_id',
            'login',
            'trabajador_nombre_completo',
            'trabajador_nombres',
            'trabajador_paterno',
            'trabajador_materno',
            'trabajador_dni',
            'empresa_nombre',
            'empresa_codigo',
            'sucursal_nombre',
            'sucursal_codigo',
            'sucursal_codigo_sin',
            'rol_nombre',
            'rol_codigo',
            'cargo_nombre',
            'cargo_codigo'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'bancos', campoFk: 'usuario_id_registro' },
            { tabla: 'bancos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'bancos', campoFk: 'usuario_id_baja' },

            { tabla: 'tipos_cambios', campoFk: 'usuario_id_registro' },
            { tabla: 'tipos_cambios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tipos_cambios', campoFk: 'usuario_id_baja' },

            { tabla: 'empresas', campoFk: 'usuario_id_registro' },
            { tabla: 'empresas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'empresas', campoFk: 'usuario_id_baja' },

            { tabla: 'empresas_nits', campoFk: 'usuario_id_registro' },
            { tabla: 'empresas_nits', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'empresas_nits', campoFk: 'usuario_id_baja' },

            { tabla: 'empresas_cuentas', campoFk: 'usuario_id_registro' },
            { tabla: 'empresas_cuentas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'empresas_cuentas', campoFk: 'usuario_id_baja' },

            { tabla: 'sucursales', campoFk: 'usuario_id_registro' },
            { tabla: 'sucursales', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'sucursales', campoFk: 'usuario_id_baja' },

            { tabla: 'puntos_venta', campoFk: 'usuario_id_registro' },
            { tabla: 'puntos_venta', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'puntos_venta', campoFk: 'usuario_id_baja' },

            { tabla: 'cuis', campoFk: 'usuario_id_registro' },
            { tabla: 'cuis', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cuis', campoFk: 'usuario_id_baja' },

            { tabla: 'cufd', campoFk: 'usuario_id_registro' },
            { tabla: 'cufd', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cufd', campoFk: 'usuario_id_baja' },

            { tabla: 'unidades', campoFk: 'usuario_id_registro' },
            { tabla: 'unidades', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'unidades', campoFk: 'usuario_id_baja' },

            { tabla: 'almacenes', campoFk: 'usuario_id_registro' },
            { tabla: 'almacenes', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'almacenes', campoFk: 'usuario_id_baja' },

            { tabla: 'ubicaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'ubicaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ubicaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'almacenes_puntos_venta', campoFk: 'usuario_id_registro' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'almacenes_puntos_venta', campoFk: 'usuario_id_baja' },

            { tabla: 'cargos', campoFk: 'usuario_id_registro' },
            { tabla: 'cargos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cargos', campoFk: 'usuario_id_baja' },

            { tabla: 'trabajadores', campoFk: 'usuario_id_registro' },
            { tabla: 'trabajadores', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'trabajadores', campoFk: 'usuario_id_baja' },

            { tabla: 'trabajadores_cargos', campoFk: 'usuario_id_registro' },
            { tabla: 'trabajadores_cargos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'trabajadores_cargos', campoFk: 'usuario_id_baja' },

            { tabla: 'roles', campoFk: 'usuario_id_registro' },
            { tabla: 'roles', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles', campoFk: 'usuario_id_baja' },

            { tabla: 'usuarios', campoFk: 'usuario_id_registro' },
            { tabla: 'usuarios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'usuarios', campoFk: 'usuario_id_baja' },

            { tabla: 'tablas', campoFk: 'usuario_id_registro' },
            { tabla: 'tablas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tablas', campoFk: 'usuario_id_baja' },

            { tabla: 'sucesos', campoFk: 'usuario_id_registro' },
            { tabla: 'sucesos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'sucesos', campoFk: 'usuario_id_baja' },

            { tabla: 'roles_permisos_tablas', campoFk: 'usuario_id_registro' },
            { tabla: 'roles_permisos_tablas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles_permisos_tablas', campoFk: 'usuario_id_baja' },

            { tabla: 'roles_permisos_sucesos', campoFk: 'usuario_id_registro' },
            { tabla: 'roles_permisos_sucesos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles_permisos_sucesos', campoFk: 'usuario_id_baja' },

            { tabla: 'menus', campoFk: 'usuario_id_registro' },
            { tabla: 'menus', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'menus', campoFk: 'usuario_id_baja' },

            { tabla: 'roles_menus', campoFk: 'usuario_id_registro' },
            { tabla: 'roles_menus', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'roles_menus', campoFk: 'usuario_id_baja' },

            { tabla: 'inventarios_fisicos', campoFk: 'usuario_id_registro' },
            { tabla: 'inventarios_fisicos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'inventarios_fisicos', campoFk: 'usuario_id_baja' },

            { tabla: 'clientes', campoFk: 'usuario_id_registro' },
            { tabla: 'clientes', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'clientes', campoFk: 'usuario_id_baja' },

            { tabla: 'categorias', campoFk: 'usuario_id_registro' },
            { tabla: 'categorias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'categorias', campoFk: 'usuario_id_baja' },

            { tabla: 'laboratorios', campoFk: 'usuario_id_registro' },
            { tabla: 'laboratorios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'laboratorios', campoFk: 'usuario_id_baja' },

            { tabla: 'formas', campoFk: 'usuario_id_registro' },
            { tabla: 'formas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'formas', campoFk: 'usuario_id_baja' },

            { tabla: 'presentaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'presentaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'presentaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'concentraciones', campoFk: 'usuario_id_registro' },
            { tabla: 'concentraciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'concentraciones', campoFk: 'usuario_id_baja' },

            { tabla: 'vias', campoFk: 'usuario_id_registro' },
            { tabla: 'vias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'vias', campoFk: 'usuario_id_baja' },

            { tabla: 'rangos_edad', campoFk: 'usuario_id_registro' },
            { tabla: 'rangos_edad', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'rangos_edad', campoFk: 'usuario_id_baja' },

            { tabla: 'marcas', campoFk: 'usuario_id_registro' },
            { tabla: 'marcas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'marcas', campoFk: 'usuario_id_baja' },

            { tabla: 'productos', campoFk: 'usuario_id_registro' },
            { tabla: 'productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_vias', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_vias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_vias', campoFk: 'usuario_id_baja' },

            { tabla: 'equivalentes', campoFk: 'usuario_id_registro' },
            { tabla: 'equivalentes', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'equivalentes', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_rangos_edad', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_rangos_edad', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_rangos_edad', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_ubicaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_ubicaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_ubicaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'principios_activos', campoFk: 'usuario_id_registro' },
            { tabla: 'principios_activos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'principios_activos', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_principios', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_principios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_principios', campoFk: 'usuario_id_baja' },

            { tabla: 'registros_sanitarios', campoFk: 'usuario_id_registro' },
            { tabla: 'registros_sanitarios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'registros_sanitarios', campoFk: 'usuario_id_baja' },

            { tabla: 'productos_controlados', campoFk: 'usuario_id_registro' },
            { tabla: 'productos_controlados', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'productos_controlados', campoFk: 'usuario_id_baja' },

            { tabla: 'promociones', campoFk: 'usuario_id_registro' },
            { tabla: 'promociones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'promociones', campoFk: 'usuario_id_baja' },

            { tabla: 'promociones_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'promociones_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'promociones_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'conversiones_unidad', campoFk: 'usuario_id_registro' },
            { tabla: 'conversiones_unidad', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'conversiones_unidad', campoFk: 'usuario_id_baja' },

            { tabla: 'proveedores', campoFk: 'usuario_id_registro' },
            { tabla: 'proveedores', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'proveedores', campoFk: 'usuario_id_baja' },

            { tabla: 'proveedores_contactos', campoFk: 'usuario_id_registro' },
            { tabla: 'proveedores_contactos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'proveedores_contactos', campoFk: 'usuario_id_baja' },

            { tabla: 'proveedores_rating_historico', campoFk: 'usuario_id_registro' },
            { tabla: 'proveedores_rating_historico', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'proveedores_rating_historico', campoFk: 'usuario_id_baja' },

            { tabla: 'parametros_globales', campoFk: 'usuario_id_registro' },
            { tabla: 'parametros_globales', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'parametros_globales', campoFk: 'usuario_id_baja' },

            { tabla: 'tareas_programadas', campoFk: 'usuario_id_registro' },
            { tabla: 'tareas_programadas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tareas_programadas', campoFk: 'usuario_id_baja' },

            { tabla: 'control_facturas', campoFk: 'usuario_id_registro' },
            { tabla: 'control_facturas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'control_facturas', campoFk: 'usuario_id_baja' },

            { tabla: 'kardex', campoFk: 'usuario_id_registro' },
            { tabla: 'kardex', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'kardex', campoFk: 'usuario_id_baja' },

            { tabla: 'ordenes_compra', campoFk: 'usuario_id_registro' },
            { tabla: 'ordenes_compra', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ordenes_compra', campoFk: 'usuario_id_baja' },

            { tabla: 'instituciones', campoFk: 'usuario_id_registro' },
            { tabla: 'instituciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'instituciones', campoFk: 'usuario_id_baja' },

            { tabla: 'especialidades', campoFk: 'usuario_id_registro' },
            { tabla: 'especialidades', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'especialidades', campoFk: 'usuario_id_baja' },

            { tabla: 'medicos', campoFk: 'usuario_id_registro' },
            { tabla: 'medicos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'medicos', campoFk: 'usuario_id_baja' },

            { tabla: 'recetas', campoFk: 'usuario_id_registro' },
            { tabla: 'recetas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'recetas', campoFk: 'usuario_id_baja' },

            { tabla: 'lotes_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'lotes_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'lotes_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'kardex_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'kardex_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'kardex_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'inventarios_fisicos_detalle', campoFk: 'usuario_id_registro' },
            { tabla: 'inventarios_fisicos_detalle', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'inventarios_fisicos_detalle', campoFk: 'usuario_id_baja' },

            { tabla: 'ubicaciones_movimientos', campoFk: 'usuario_id_registro' },
            { tabla: 'ubicaciones_movimientos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ubicaciones_movimientos', campoFk: 'usuario_id_baja' },

            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id_registro' },
            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'ubicaciones_historial', campoFk: 'usuario_id_baja' },

            { tabla: 'tipos_planes_pago', campoFk: 'usuario_id_registro' },
            { tabla: 'tipos_planes_pago', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'tipos_planes_pago', campoFk: 'usuario_id_baja' },

            { tabla: 'planes_pagos', campoFk: 'usuario_id_registro' },
            { tabla: 'planes_pagos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'planes_pagos', campoFk: 'usuario_id_baja' },

            { tabla: 'comprobantes_pagos', campoFk: 'usuario_id_registro' },
            { tabla: 'comprobantes_pagos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'comprobantes_pagos', campoFk: 'usuario_id_baja' },

            { tabla: 'pagos', campoFk: 'usuario_id_registro' },
            { tabla: 'pagos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'pagos', campoFk: 'usuario_id_baja' },

            { tabla: 'cajas', campoFk: 'usuario_id_registro' },
            { tabla: 'cajas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'cajas', campoFk: 'usuario_id_baja' },

            { tabla: 'movimientos', campoFk: 'usuario_id_registro' },
            { tabla: 'movimientos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'movimientos', campoFk: 'usuario_id_baja' },

            { tabla: 'arqueos_detalle', campoFk: 'usuario_id_registro' },
            { tabla: 'arqueos_detalle', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'arqueos_detalle', campoFk: 'usuario_id_baja' },

            { tabla: 'alertas_notificaciones', campoFk: 'usuario_id_registro' },
            { tabla: 'alertas_notificaciones', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'alertas_notificaciones', campoFk: 'usuario_id_baja' },

            { tabla: 'modelos', campoFk: 'usuario_id_registro' },
            { tabla: 'modelos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'modelos', campoFk: 'usuario_id_baja' },

            { tabla: 'entrenamientos', campoFk: 'usuario_id_registro' },
            { tabla: 'entrenamientos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'entrenamientos', campoFk: 'usuario_id_baja' },

            { tabla: 'metricas_rendimiento', campoFk: 'usuario_id_registro' },
            { tabla: 'metricas_rendimiento', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'metricas_rendimiento', campoFk: 'usuario_id_baja' },

            { tabla: 'patrones_consumo', campoFk: 'usuario_id_registro' },
            { tabla: 'patrones_consumo', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'patrones_consumo', campoFk: 'usuario_id_baja' },

            { tabla: 'variables_exogenas', campoFk: 'usuario_id_registro' },
            { tabla: 'variables_exogenas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'variables_exogenas', campoFk: 'usuario_id_baja' },

            { tabla: 'umbrales_configuracion', campoFk: 'usuario_id_registro' },
            { tabla: 'umbrales_configuracion', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'umbrales_configuracion', campoFk: 'usuario_id_baja' },

            { tabla: 'logs_ejecucion', campoFk: 'usuario_id_registro' },
            { tabla: 'logs_ejecucion', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'logs_ejecucion', campoFk: 'usuario_id_baja' },

            { tabla: 'analitica_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'analitica_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'analitica_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'pedidos_online', campoFk: 'usuario_id_registro' },
            { tabla: 'pedidos_online', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'pedidos_online', campoFk: 'usuario_id_baja' },

            { tabla: 'detalles_pedidos_online', campoFk: 'usuario_id_registro' },
            { tabla: 'detalles_pedidos_online', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'detalles_pedidos_online', campoFk: 'usuario_id_baja' },

            { tabla: 'carritos_compra', campoFk: 'usuario_id_registro' },
            { tabla: 'carritos_compra', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'carritos_compra', campoFk: 'usuario_id_baja' },

            { tabla: 'detalles_carritos', campoFk: 'usuario_id_registro' },
            { tabla: 'detalles_carritos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'detalles_carritos', campoFk: 'usuario_id_baja' },

            { tabla: 'listas_precios', campoFk: 'usuario_id_registro' },
            { tabla: 'listas_precios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'listas_precios', campoFk: 'usuario_id_baja' },

            { tabla: 'precios_productos', campoFk: 'usuario_id_registro' },
            { tabla: 'precios_productos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'precios_productos', campoFk: 'usuario_id_baja' },

            { tabla: 'costos_promedio', campoFk: 'usuario_id_registro' },
            { tabla: 'costos_promedio', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'costos_promedio', campoFk: 'usuario_id_baja' },

            { tabla: 'politicas_precios', campoFk: 'usuario_id_registro' },
            { tabla: 'politicas_precios', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'politicas_precios', campoFk: 'usuario_id_baja' },

            { tabla: 'asistencias', campoFk: 'usuario_id_registro' },
            { tabla: 'asistencias', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'asistencias', campoFk: 'usuario_id_baja' },

            { tabla: 'planillas', campoFk: 'usuario_id_registro' },
            { tabla: 'planillas', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'planillas', campoFk: 'usuario_id_baja' },

            { tabla: 'planillas_detalle', campoFk: 'usuario_id_registro' },
            { tabla: 'planillas_detalle', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'planillas_detalle', campoFk: 'usuario_id_baja' },

            { tabla: 'contratos', campoFk: 'usuario_id_registro' },
            { tabla: 'contratos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'contratos', campoFk: 'usuario_id_baja' },

            { tabla: 'historicos', campoFk: 'usuario_id_registro' },
            { tabla: 'historicos', campoFk: 'usuario_id_actualizacion' },
            { tabla: 'historicos', campoFk: 'usuario_id_baja' },
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['login', 'trabajador_id', 'rol_id'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasTrabajador = 'tr';
        const aliasSucursal = 's';
        const aliasEmpresa = 'e';
        const aliasRol = 'r';
        const aliasCargo = 'c';
        return {
            'usuario_id': `${alias}.usuario_id`,
            'trabajador_id': `${alias}.trabajador_id`,
            'rol_id': `${alias}.rol_id`,
            'empresa_id': `${aliasEmpresa}.empresa_id`,
            'cargo_id': `${aliasCargo}.cargo_id`,
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
            'trabajador_nombres': `${aliasTrabajador}.nombres`,
            'trabajador_paterno': `${aliasTrabajador}.paterno`,
            'trabajador_materno': `${aliasTrabajador}.materno`,
            'trabajador_dni': `${aliasTrabajador}.dni`,
            'empresa_nombre': `${aliasEmpresa}.empresa`,
            'empresa_codigo': `${aliasEmpresa}.codigo`,
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,
            'sucursal_codigo_sin': `${aliasSucursal}.codigo_sin`,
            'rol_nombre': `${aliasRol}.rol`,
            'rol_codigo': `${aliasRol}.codigo`,
            'cargo_nombre': `${aliasCargo}.cargo`,
            'cargo_codigo': `${aliasCargo}.codigo`
        };
    }
}

export { PaginatedResult };
