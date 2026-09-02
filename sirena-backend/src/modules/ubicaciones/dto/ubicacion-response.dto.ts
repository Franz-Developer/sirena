// C:\sirena\sirena-backend\src\modules\ubicaciones\dto\ubicacion-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: UbicacionRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface UbicacionRawResult {
    ubicacion_id: string | number;
    almacen_id: string | number;
    almacen_nombre?: string;
    almacen_codigo?: string;
    codigo: string;
    jerarquia: Record<string, any>;
    descripcion?: string | null;
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

export class UbicacionResponseDto {
    @Expose() ubicacion_id!: number;
    @Expose() almacen_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.almacen_nombre || null)
    almacen_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.almacen_codigo || null)
    almacen_codigo!: string;

    @Expose() codigo!: string;
    @Expose() jerarquia!: Record<string, any>;
    @Expose() descripcion!: string | null;

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
