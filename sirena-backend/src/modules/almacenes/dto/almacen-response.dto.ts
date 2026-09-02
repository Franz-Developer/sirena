// C:\sirena\sirena-backend\src\modules\almacenes\dto\almacen-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoAlmacen, TIPO_ALMACEN_METADATA, TipoOperacionAlmacen, TIPO_OPERACION_ALMACEN_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: AlmacenRawResult }) => {
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

export interface AlmacenRawResult {
    almacen_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    almacen: string;
    codigo: string;
    tipo_almacen_id: string | number;
    tipo_operacion_almacen_id: string | number;
    descripcion: string | null;
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

export class AlmacenResponseDto {
    @Expose() almacen_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose() almacen!: string;
    @Expose() codigo!: string;
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

    @Expose() descripcion?: string | null;
    @Expose() estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_registro!: string;

    @Expose() usuario_operacion!: string;
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

    @Expose() tiene_dependencias!: boolean;
    @Expose() campos_protegidos?: string[];
}
