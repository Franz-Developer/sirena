// C:\sirena\sirena-backend\src\modules\empresas\dto\empresa-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: EmpresaRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface EmpresaRawResult {
    empresa_id: string | number;
    empresa: string;
    codigo: string;
    logo: string;
    eslogan: string | null;
    descripcion: string | null;
    lugar: string | null;
    representante: string | null;
    direccion: string | null;
    telefono: string | null;
    email: string | null;
    matricula_comercio: string | null;
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

export class EmpresaResponseDto {
    @Expose() empresa_id!: number;
    @Expose() empresa!: string;
    @Expose() codigo!: string;
    @Expose() logo!: string;
    @Expose() eslogan?: string | null;
    @Expose() descripcion?: string | null;
    @Expose() lugar?: string | null;
    @Expose() representante?: string | null;
    @Expose() direccion?: string | null;
    @Expose() telefono?: string | null;
    @Expose() email?: string | null;
    @Expose() matricula_comercio?: string | null;
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
