// C:\sirena\sirena-backend\src\modules\roles-tablas\dto\rol-tabla-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: RolTablaRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface RolTablaRawResult {
    rol_tabla_id: string | number;
    rol_id: string | number;
    rol_nombre?: string;
    rol_codigo?: string;
    tabla: string;
    leer: number;
    crear: number;
    editar: number;
    eliminar: number;
    anular: number;
    archivar: number;
    desarchivar: number;
    eventos_permitidos: Record<string, any>;
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

export class RolTablaResponseDto {
    @Expose() rol_tabla_id!: number;
    @Expose() rol_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.rol_nombre || null)
    rol_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.rol_codigo || null)
    rol_codigo!: string;

    @Expose() tabla!: string;
    @Expose() leer!: number;
    @Expose() crear!: number;
    @Expose() editar!: number;
    @Expose() eliminar!: number;
    @Expose() anular!: number;
    @Expose() archivar!: number;
    @Expose() desarchivar!: number;

    @Expose()
    @Transform(({ value }) => (typeof value === 'string' ? JSON.parse(value) : value))
    eventos_permitidos!: Record<string, any>;

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
