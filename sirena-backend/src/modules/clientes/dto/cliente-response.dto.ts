// C:\sirena\sirena-backend\src\modules\clientes\dto\cliente-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoCliente, TIPO_CLIENTE_METADATA, TipoDocumento, TIPO_DOCUMENTO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: ClienteRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoCliente = (tipoClienteId: unknown) => {
    const id = Number(tipoClienteId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_CLIENTE_METADATA[id as TipoCliente];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

const transformTipoDocumento = (tipoDocumentoId: unknown) => {
    const id = Number(tipoDocumentoId);
    if (!Number.isInteger(id)) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    const metadata = TIPO_DOCUMENTO_METADATA[id as TipoDocumento];
    if (!metadata) {
        return { abreviatura: '', valor: 0, prefijo: '' };
    }
    return {
        abreviatura: metadata.abreviatura,
        valor: metadata.valor,
        prefijo: metadata.prefijo ?? '',
    };
};

export interface ClienteRawResult {
    cliente_id: string | number;
    tipo_cliente_id: string | number;
    cliente: string;
    nit?: string | null;
    razon_social?: string | null;
    documento: string;
    documento_complemento?: string | null;
    tipo_documento_id: string | number;
    direccion?: string | null;
    telefono?: string | null;
    email?: string | null;
    banco_base_id: string | number;
    banco_base_nombre?: string | null;
    banco_base_abreviatura?: string | null;
    numero_cuenta?: string | null;
    habilitado_ventas: string | number;
    limite_credito: string | number;
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

export class ClienteResponseDto {
    @Expose() cliente_id!: number;
    @Expose() tipo_cliente_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoCliente(obj.tipo_cliente_id))
    tipo_cliente!: {
        abreviatura: string;
        descripcion: string;
    };

    @Expose() cliente!: string;
    @Expose() nit?: string | null;
    @Expose() razon_social?: string | null;
    @Expose() documento!: string;
    @Expose() documento_complemento?: string | null;

    @Expose() tipo_documento_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoDocumento(obj.tipo_documento_id))
    tipo_documento!: {
        abreviatura: string;
        prefijo: string;
    };

    @Expose() direccion?: string | null;
    @Expose() telefono?: string | null;
    @Expose() email?: string | null;
    @Expose() banco_base_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.banco_base_nombre || null)
    banco_base_nombre?: string | null;

    @Expose()
    @Transform(({ obj }) => obj.banco_base_abreviatura || null)
    banco_base_abreviatura?: string | null;

    @Expose() numero_cuenta?: string | null;

    @Expose()
    @Transform(({ value }) => Number(value))
    habilitado_ventas!: number;

    @Expose()
    @Transform(({ value }) => Number(value))
    limite_credito!: number;

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
