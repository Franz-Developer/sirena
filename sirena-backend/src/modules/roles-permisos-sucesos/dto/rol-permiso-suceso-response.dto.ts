// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\dto\rol-permiso-suceso-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

export interface RolPermisoSucesoRawResult {
    rol_permiso_suceso_id: string | number;
    rol_permiso_tabla_id: string | number;
    suceso_id: string | number;
    rol_id?: string | number;
    rol_nombre?: string;
    rol_codigo?: string;
    tabla_nombre?: string;
    suceso_codigo?: string;
    suceso_nombre?: string;
    estado_id: string | number;
    estado_registro: string;
    usuario_operacion: string;
    usuario_id_registro: string | number;
    usuario_id_actualizacion?: string | number | null;
    usuario_id_baja?: string | number | null;
    fecha_registro: string | Date;
    fecha_actualizacion?: string | Date | null;
    fecha_baja?: string | Date | null;
    tiene_dependencias?: boolean;
    campos_protegidos?: string[];
}

const transformEstado = ({ obj }: { obj: RolPermisoSucesoRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export class RolPermisoSucesoResponseDto {
    @Expose() rol_permiso_suceso_id!: number;

    @Expose() rol_permiso_tabla_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.rol_id || null)
    rol_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.rol_nombre || null)
    rol_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.rol_codigo || null)
    rol_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.tabla_nombre || null)
    tabla_nombre!: string;

    @Expose() suceso_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.suceso_codigo || null)
    suceso_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.suceso_nombre || null)
    suceso_nombre!: string;

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
