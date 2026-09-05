// C:\sirena\sirena-backend\src\modules\usuarios\dto\usuario-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: UsuarioRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface UsuarioRawResult {
    usuario_id: string | number;
    trabajador_id: string | number;
    trabajador_nombre_completo?: string;
    trabajador_nombres?: string;
    trabajador_paterno?: string;
    trabajador_materno?: string;
    trabajador_dni?: string;
    empresa_id: string | number;
    empresa_nombre?: string;
    empresa_codigo?: string;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    sucursal_codigo_sin?: string | number;
    rol_id: string | number;
    rol_nombre?: string;
    rol_codigo?: string;
    cargo_id?: string | number;
    cargo_nombre?: string;
    cargo_codigo?: string;
    login: string;
    avatar: string;
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

export class UsuarioResponseDto {
    @Expose() usuario_id!: number;
    @Expose() trabajador_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_nombre_completo || null)
    trabajador_nombre_completo!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_nombres || null)
    trabajador_nombres!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_paterno || null)
    trabajador_paterno!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_materno || null)
    trabajador_materno!: string;

    @Expose()
    @Transform(({ obj }) => obj.trabajador_dni || null)
    trabajador_dni!: string;

    @Expose() empresa_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.empresa_nombre || null)
    empresa_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.empresa_codigo || null)
    empresa_codigo!: string;

    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo_sin !== undefined && obj.sucursal_codigo_sin !== null ? Number(obj.sucursal_codigo_sin) : null)
    sucursal_codigo_sin!: number;

    @Expose() rol_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.rol_nombre || null)
    rol_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.rol_codigo || null)
    rol_codigo!: string;

    @Expose() cargo_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.cargo_nombre || null)
    cargo_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.cargo_codigo || null)
    cargo_codigo!: string;

    @Expose() login!: string;
    @Expose() avatar!: string;
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
