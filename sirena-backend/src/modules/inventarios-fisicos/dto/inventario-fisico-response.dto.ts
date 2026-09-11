// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\dto\inventario-fisico-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: InventarioFisicoRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoAlmacen = (tipoAlmacenId: unknown) => {
    const id = Number(tipoAlmacenId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_ALMACEN_METADATA[id as TipoAlmacen];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

const transformTipoOperacionAlmacen = (tipoOperacionId: unknown) => {
    const id = Number(tipoOperacionId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_OPERACION_ALMACEN_METADATA[id as TipoOperacionAlmacen];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

export interface InventarioFisicoRawResult {
    inventario_fisico_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    sucursal_codigo_sin?: string | number;
    empresa_id?: string | number;
    empresa_nombre?: string;
    empresa_codigo?: string;
    ubicacion_id: string | number;
    ubicacion_codigo?: string;
    ubicacion_descripcion?: string;
    ubicacion_jerarquia?: string;
    almacen_id?: string | number;
    almacen_nombre?: string;
    almacen_codigo?: string;
    tipo_almacen_id?: string | number;
    tipo_operacion_almacen_id?: string | number;
    fecha_conteo?: string | Date;
    fecha_inicio?: string | Date;
    fecha_fin?: string | Date;
    trabajador_responsable_id: string | number;
    trabajador_responsable_nombre?: string;
    trabajador_responsable_cargo?: string;
    trabajador_responsable_cargo_codigo?: string;
    trabajador_supervisor_id: string | number;
    trabajador_supervisor_nombre?: string;
    trabajador_supervisor_cargo?: string;
    trabajador_supervisor_cargo_codigo?: string;
    observaciones?: string;
    estado_id: string | number;
    usuario_id_registro: string | number;
    usuario_id_actualizacion?: string | number;
    usuario_id_baja?: string | number;
    fecha_registro: string | Date;
    fecha_actualizacion?: string | Date;
    fecha_baja?: string | Date;
}

export class InventarioFisicoResponseDto {
    @Expose() inventario_fisico_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre ? obj.sucursal_nombre.trim() : null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo ? obj.sucursal_codigo.trim() : null)
    sucursal_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo_sin ?? null)
    sucursal_codigo_sin!: number;

    @Expose() empresa_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.empresa_nombre ? obj.empresa_nombre.trim() : null)
    empresa_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.empresa_codigo ? obj.empresa_codigo.trim() : null)
    empresa_codigo!: string;

    @Expose() ubicacion_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.ubicacion_codigo ? obj.ubicacion_codigo.trim() : null)
    ubicacion_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.ubicacion_descripcion ? obj.ubicacion_descripcion.trim() : null)
    ubicacion_descripcion!: string;

    @Expose()
    @Transform(({ obj }) => obj.ubicacion_jerarquia ? obj.ubicacion_jerarquia.trim() : null)
    ubicacion_jerarquia!: string;

    @Expose() almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.almacen_nombre ? obj.almacen_nombre.trim() : null)
    almacen_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.almacen_codigo ? obj.almacen_codigo.trim() : null)
    almacen_codigo!: string;

    @Expose() tipo_almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoAlmacen(obj.tipo_almacen_id))
    tipo_almacen!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() tipo_operacion_almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoOperacionAlmacen(obj.tipo_operacion_almacen_id))
    tipo_operacion_almacen!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose()
    @Transform(({ obj }) => formatLocalDate(obj.fecha_conteo))
    fecha_conteo!: string;

    @Expose()
    @Transform(({ obj }) => formatLocalDate(obj.fecha_inicio))
    fecha_inicio!: string;

    @Expose()
    @Transform(({ obj }) => formatLocalDate(obj.fecha_fin))
    fecha_fin!: string;

    @Expose() trabajador_responsable_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_responsable_nombre ? obj.trabajador_responsable_nombre.trim() : null)
    trabajador_responsable_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_responsable_cargo ? obj.trabajador_responsable_cargo.trim() : null)
    trabajador_responsable_cargo!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_responsable_cargo_codigo ? obj.trabajador_responsable_cargo_codigo.trim() : null)
    trabajador_responsable_cargo_codigo!: string;

    @Expose() trabajador_supervisor_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_supervisor_nombre ? obj.trabajador_supervisor_nombre.trim() : null)
    trabajador_supervisor_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_supervisor_cargo ? obj.trabajador_supervisor_cargo.trim() : null)
    trabajador_supervisor_cargo!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_supervisor_cargo_codigo ? obj.trabajador_supervisor_cargo_codigo.trim() : null)
    trabajador_supervisor_cargo_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.observaciones ? obj.observaciones.trim() : null)
    observaciones!: string;

    @Expose() estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_abreviatura!: string;

    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion!: number;
    @Expose() usuario_id_baja!: number;

    @Expose()
    @Transform(({ obj }) => formatLocalDate(obj.fecha_registro))
    fecha_registro!: string;

    @Expose()
    @Transform(({ obj }) => formatLocalDate(obj.fecha_actualizacion))
    fecha_actualizacion!: string;

    @Expose()
    @Transform(({ obj }) => formatLocalDate(obj.fecha_baja))
    fecha_baja!: string;
}
