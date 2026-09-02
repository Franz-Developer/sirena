// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\dto\inventario-fisico-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: InventarioFisicoRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface InventarioFisicoRawResult {
    inventario_fisico_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    sucursal_codigo_sin?: string | number;
    ubicacion_id: string | number;
    ubicacion_codigo?: string;
    ubicacion_descripcion?: string;
    ubicacion_jerarquia?: any;
    almacen_id: string | number;
    almacen_nombre?: string;
    almacen_codigo?: string;
    tipo_almacen_id?: string | number;
    tipo_operacion_almacen_id?: string | number;
    fecha_conteo: string | Date;
    fecha_inicio: string | Date;
    fecha_fin?: string | Date | null;
    trabajador_responsable_id: string | number;
    trabajador_responsable_nombre?: string;
    trabajador_responsable_cargo?: string;
    trabajador_supervisor_id: string | number;
    trabajador_supervisor_nombre?: string;
    trabajador_supervisor_cargo?: string;
    observaciones?: string | null;
    estado_id: string | number;
    estado_registro?: string;
    usuario_operacion?: string;
    usuario_id_registro: string | number;
    usuario_id_actualizacion?: string | number | null;
    usuario_id_baja?: string | number | null;
    fecha_registro: string | Date;
    fecha_actualizacion?: string | Date | null;
    fecha_baja?: string | Date | null;
    total_count?: string | number;
    tiene_dependencias?: boolean;
    campos_protegidos?: string[];
}

export class InventarioFisicoResponseDto {
    @Expose() inventario_fisico_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo_sin ?? null)
    sucursal_codigo_sin!: number;

    @Expose() ubicacion_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.ubicacion_codigo || null)
    ubicacion_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.ubicacion_descripcion || null)
    ubicacion_descripcion!: string;

    @Expose()
    @Transform(({ obj }) => obj.ubicacion_jerarquia || null)
    ubicacion_jerarquia!: any;

    @Expose() almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.almacen_nombre || null)
    almacen_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.almacen_codigo || null)
    almacen_codigo!: string;

    @Expose() tipo_almacen_id!: number;

    @Expose() tipo_operacion_almacen_id!: number;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_conteo!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_inicio!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_fin!: string | null;

    @Expose() trabajador_responsable_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_responsable_nombre ? obj.trabajador_responsable_nombre.trim() : null)
    trabajador_responsable_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_responsable_cargo ? obj.trabajador_responsable_cargo.trim() : null)
    trabajador_responsable_cargo!: string;

    @Expose() trabajador_supervisor_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_supervisor_nombre ? obj.trabajador_supervisor_nombre.trim() : null)
    trabajador_supervisor_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_supervisor_cargo ? obj.trabajador_supervisor_cargo.trim() : null)
    trabajador_supervisor_cargo!: string;

    @Expose()
    @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
    observaciones!: string | null;

    @Expose() estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_registro!: string;

    @Expose()
    usuario_operacion!: string;

    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion?: number | null;
    @Expose() usuario_id_baja?: number | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_registro!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_actualizacion?: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_baja?: string | null;

    @Expose()
    tiene_dependencias!: boolean;

    @Expose()
    campos_protegidos?: string[];
}
