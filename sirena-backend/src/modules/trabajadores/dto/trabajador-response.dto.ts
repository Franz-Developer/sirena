// C:\sirena\sirena-backend\src\modules\trabajadores\dto\trabajador-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, Genero, GENERO_METADATA, EstadoCivilMasculino, ESTADO_CIVIL_MASCULINO_METADATA, EstadoCivilFemenino, ESTADO_CIVIL_FEMENINO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate, formatOnlyDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: TrabajadorRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformGenero = ({ obj }: { obj: TrabajadorRawResult }) => {
    const id = Number(obj.genero_id);
    const metadata = GENERO_METADATA[id as Genero];
    return metadata ? metadata.abreviatura : '';
};

const transformEstadoCivil = ({ obj }: { obj: TrabajadorRawResult }) => {
    const id = Number(obj.estado_civil_id);
    const metadata = ESTADO_CIVIL_MASCULINO_METADATA[id as EstadoCivilMasculino] ||
                     ESTADO_CIVIL_FEMENINO_METADATA[id as EstadoCivilFemenino];
    return metadata ? metadata.abreviatura : '';
};

const transformNombreCompleto = ({ obj }: { obj: TrabajadorRawResult }) => {
    const partes = [
        obj.nombres,
        obj.paterno,
        obj.materno
    ].filter(val => val !== null && val !== undefined && String(val).trim() !== '');

    return partes.join(' ');
};

export interface TrabajadorRawResult {
    trabajador_id: string | number;
    sucursal_id: string | number;
    sucursal?: string;
    sucursal_codigo?: string;
    empresa?: string;
    empresa_codigo?: string;
    cargo?: string;
    cargo_codigo?: string;
    genero_id: string | number;
    estado_civil_id: string | number;
    nombres: string;
    paterno: string;
    materno?: string | null;
    trabajador_nombre_completo?: string;
    dni: string;
    telefono?: string | null;
    direccion?: string | null;
    email?: string | null;
    fecha_nacimiento?: string | Date | null;
    fecha_contratacion?: string | Date | null;
    foto: string;
    qr: string;
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

export class TrabajadorResponseDto {
    @Expose() trabajador_id!: number;
    @Expose() sucursal_id!: number;

    @Expose() sucursal!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || obj.codigo_sucursal)
    sucursal_codigo!: string;

    @Expose()
    @Transform(({ obj }) => obj.empresa || obj.empesa)
    empresa!: string;

    @Expose() empresa_codigo!: string;
    @Expose() cargo!: string;
    @Expose() cargo_codigo!: string;

    @Expose() genero_id!: number;

    @Expose()
    @Transform(transformGenero)
    genero!: string;

    @Expose() estado_civil_id!: number;

    @Expose()
    @Transform(transformEstadoCivil)
    estado_civil!: string;

    @Expose() nombres!: string;
    @Expose() paterno!: string;
    @Expose() materno?: string | null;

    @Expose()
    @Transform(transformNombreCompleto)
    nombre_completo!: string;

    @Expose()
    @Transform(transformNombreCompleto)
    trabajador_nombre_completo!: string;

    @Expose() dni!: string;
    @Expose() telefono?: string | null;
    @Expose() direccion?: string | null;
    @Expose() email?: string | null;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_nacimiento?: string | null;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_contratacion?: string | null;

    @Expose() foto!: string;
    @Expose() qr!: string;
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
