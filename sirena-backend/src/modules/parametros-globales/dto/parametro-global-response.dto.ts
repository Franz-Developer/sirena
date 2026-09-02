// C:\sirena\sirena-backend\src\modules\parametros-globales\dto\parametro-global-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoDato, TIPO_DATO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: ParametroGlobalRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoDato = (tipoDatoId: unknown) => {
    const id = Number(tipoDatoId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = TIPO_DATO_METADATA[id as TipoDato];
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

export interface ParametroGlobalRawResult {
    parametro_id: string | number;
    clave: string;
    valor: string;
    tipo_dato_id: string | number;
    datos_json?: any | null;
    descripcion?: string | null;
    editable: string | number;
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

export class ParametroGlobalResponseDto {
    @Expose() parametro_id!: number;
    @Expose() clave!: string;
    @Expose() valor!: string;
    @Expose() tipo_dato_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoDato(obj.tipo_dato_id))
    tipo_dato!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() datos_json?: any | null;
    @Expose() descripcion?: string | null;
    @Expose() editable!: number;
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
