// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\dto\trabajador-cargo-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoMoneda, TIPO_MONEDA_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: TrabajadorCargoRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoMoneda = (tipoMonedaId: unknown) => {
    const id = Number(tipoMonedaId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_MONEDA_METADATA[id as TipoMoneda];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

export interface TrabajadorCargoRawResult {
    trabajador_cargo_id: string | number;
    trabajador_id: string | number;
    trabajador_nombres?: string;
    trabajador_paterno?: string;
    trabajador_materno?: string | null;
    trabajador_dni?: string;
    cargo_id: string | number;
    cargo_nombre?: string;
    cargo_codigo?: string;
    sueldo_base: string | number;
    tipo_moneda_id: string | number;
    fecha_desde: string | Date;
    fecha_hasta?: string | Date | null;
    es_activo: string | number;
    observaciones?: string | null;
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

export class TrabajadorCargoResponseDto {
    @Expose() trabajador_cargo_id!: number;
    @Expose() trabajador_id!: number;

    @Expose()
    @Transform(({ obj }) => {
        const partes = [obj.trabajador_nombres, obj.trabajador_paterno, obj.trabajador_materno].filter(Boolean);
        return partes.join(' ');
    })
    trabajador_nombre_completo!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_dni || null)
    trabajador_dni!: string;

    @Expose() cargo_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.cargo_nombre || null)
    cargo_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.cargo_codigo || null)
    cargo_codigo!: string;

    @Expose()
    @Transform(({ value }) => Number(value))
    sueldo_base!: number;

    @Expose() tipo_moneda_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoMoneda(obj.tipo_moneda_id))
    tipo_moneda!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_desde!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_hasta?: string | null;

    @Expose() es_activo!: number;
    @Expose() observaciones?: string | null;
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
