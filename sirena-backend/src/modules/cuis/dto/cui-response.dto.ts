// C:\sirena\sirena-backend\src\modules\cuis\dto\cui-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: CuiRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface CuiRawResult {
    cuis_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    punto_venta_id: string | number;
    punto_venta_nombre?: string;
    punto_venta_codigo?: string | number;
    codigo_cuis: string;
    fecha_vigencia: string | Date;
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

export class CuiResponseDto {
    @Expose() cuis_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose() punto_venta_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.punto_venta_nombre || null)
    punto_venta_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.punto_venta_codigo !== undefined && obj.punto_venta_codigo !== null ? Number(obj.punto_venta_codigo) : null)
    punto_venta_codigo!: number;

    @Expose() codigo_cuis!: string;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_vigencia!: string | null;

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
