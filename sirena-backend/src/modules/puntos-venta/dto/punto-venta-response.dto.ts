// C:\sirena\sirena-backend\src\modules\puntos-venta\dto\punto-venta-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoPuntoVenta, TIPO_PUNTO_VENTA_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: PuntoVentaRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoPuntoVenta = (tipoPuntoVentaId: unknown) => {
    const id = Number(tipoPuntoVentaId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = TIPO_PUNTO_VENTA_METADATA[id as TipoPuntoVenta];
    if (!metadata) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

export interface PuntoVentaRawResult {
    punto_venta_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    codigo: string | number;
    nombre: string;
    tipo_punto_venta_id: string | number;
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

export class PuntoVentaResponseDto {
    @Expose() punto_venta_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose() codigo!: number;
    @Expose() nombre!: string;

    @Expose() tipo_punto_venta_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoPuntoVenta(obj.tipo_punto_venta_id))
    tipo_punto_venta!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

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
