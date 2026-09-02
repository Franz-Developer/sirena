// C:\sirena\sirena-backend\src\modules\sucursales\dto\sucursal-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: SucursalRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface SucursalRawResult {
    sucursal_id: string | number;
    empresa_id: string | number;
    empresa_nombre?: string;
    empresa_codigo?: string;
    sucursal: string;
    sucursal_largo: string;
    codigo: string;
    codigo_sin: string | number;
    telefono?: string | null;
    ubicacion?: string | null;
    horario_atencion?: string | null;
    factor_venta: string | number;
    factor_facturacion: string | number;
    estado_id: string | number;
    estado_registro: string;
    usuario_operacion: string;
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

export class SucursalResponseDto {
    @Expose() sucursal_id!: number;
    @Expose() empresa_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.empresa_nombre || null)
    empresa_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.empresa_codigo || null)
    empresa_codigo!: string;

    @Expose() sucursal!: string;
    @Expose() sucursal_largo!: string;
    @Expose() codigo!: string;
    @Expose() codigo_sin!: number;

    @Expose()
    @Transform(({ value }) => value ?? null)
    telefono?: string | null;

    @Expose()
    @Transform(({ value }) => value ?? null)
    ubicacion?: string | null;

    @Expose()
    @Transform(({ value }) => value ?? null)
    horario_atencion?: string | null;

    @Expose()
    @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : 1.50))
    factor_venta!: number;

    @Expose()
    @Transform(({ value }) => (value !== null && value !== undefined ? Number(value) : 1.19))
    factor_facturacion!: number;

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
