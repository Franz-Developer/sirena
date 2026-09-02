// C:\sirena\sirena-backend\src\modules\tipos-cambios\dto\tipo-cambio-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { formatOnlyDate, formatLocalDate } from '../../../common/utils/date-formatter.util';
import { Estado, ESTADO_METADATA, TipoMoneda, TIPO_MONEDA_METADATA } from '../../../common/constants/estados.constant';

const transformEstado = ({ obj }: { obj: TipoCambioRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformMoneda = (monedaId: unknown) => {
    const id = Number(monedaId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = TIPO_MONEDA_METADATA[id as TipoMoneda];
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

export interface TipoCambioRawResult {
    tipo_cambio_id: string | number;
    origen_moneda_id: string | number;
    destino_moneda_id: string | number;
    factor_compra: string | number;
    factor_venta: string | number;
    fecha_cotizacion: string | Date;
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

export class TipoCambioResponseDto {
    @Expose() tipo_cambio_id!: number;

    @Expose() origen_moneda_id!: number;
    @Expose()
    @Transform(({ obj }) => transformMoneda(obj.origen_moneda_id))
    origen_moneda!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() destino_moneda_id!: number;
    @Expose()
    @Transform(({ obj }) => transformMoneda(obj.destino_moneda_id))
    destino_moneda!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() factor_compra!: number;
    @Expose() factor_venta!: number;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_cotizacion!: string;

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
