// C:\sirena\sirena-backend\src\modules\empresas-nits\dto\empresa-nit-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, Ambiente, AMBIENTE_METADATA, ModalidadFacturacion, MODALIDAD_FACTURACION_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate, formatOnlyDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: EmpresaNitRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformAmbiente = (ambienteId: unknown) => {
    const id = Number(ambienteId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = AMBIENTE_METADATA[id as Ambiente];
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

const transformModalidadFacturacion = (modalidadId: unknown) => {
    const id = Number(modalidadId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = MODALIDAD_FACTURACION_METADATA[id as ModalidadFacturacion];
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

export interface EmpresaNitRawResult {
    empresa_nit_id: string | number;
    empresa_id: string | number;
    empresa_nombre?: string;
    empresa_codigo?: string;
    ambiente_id: string | number;
    nit: string;
    razon_social: string;
    actividad_economica_principal: string;
    etiqueta: string;
    modalidad_facturacion_id: string | number;
    certificado_digital: string | null;
    certificado_password: string | null;
    token_siat: string | null;
    fecha_inicio_vigencia: string | Date | null;
    fecha_fin_vigencia: string | Date | null;
    email_fiscal: string;
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

export class EmpresaNitResponseDto {
    @Expose() empresa_nit_id!: number;
    @Expose() empresa_id!: number;

    @Expose()
    @Transform(({ obj }) => {
        return obj.empresa_nombre || null;
    })
    empresa_nombre!: string;

    @Expose()
    @Transform(({ obj }) => {
        return obj.empresa_codigo || null;
    })
    empresa_codigo!: string;

    @Expose() ambiente_id!: number;

    @Expose()
    @Transform(({ obj }) => transformAmbiente(obj.ambiente_id))
    ambiente!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() nit!: string;
    @Expose() razon_social!: string;
    @Expose() actividad_economica_principal!: string;
    @Expose() etiqueta!: string;
    @Expose() modalidad_facturacion_id!: number;

    @Expose()
    @Transform(({ obj }) => transformModalidadFacturacion(obj.modalidad_facturacion_id))
    modalidad_facturacion!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() certificado_digital?: string | null;
    @Expose() certificado_password?: string | null;
    @Expose() token_siat?: string | null;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_inicio_vigencia?: string | null;

    @Expose()
    @Transform(({ value }) => formatOnlyDate(value))
    fecha_fin_vigencia?: string | null;

    @Expose() email_fiscal!: string;
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
