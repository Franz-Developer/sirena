// C:\sirena\sirena-backend\src\modules\empresas-cuentas\dto\empresa-cuenta-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA, TipoMoneda, TIPO_MONEDA_METADATA, TipoCuenta, TIPO_CUENTA_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: EmpresaCuentaRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

const transformTipoMoneda = (tipoMonedaId: unknown) => {
    const id = Number(tipoMonedaId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = TIPO_MONEDA_METADATA[id as TipoMoneda];
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

const transformTipoCuenta = (tipoCuentaId: unknown) => {
    const id = Number(tipoCuentaId);
    if (!Number.isInteger(id)) {
        return {
            abreviatura: '',
            valor: 0,
            prefijo: '',
        };
    }

    const metadata = TIPO_CUENTA_METADATA[id as TipoCuenta];
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

export interface EmpresaCuentaRawResult {
    empresa_cuenta_id: string | number;
    empresa_id: string | number;
    empresa_nombre?: string;
    empresa_codigo?: string;
    banco_id: string | number;
    banco_nombre?: string;
    banco_codigo_asfi?: string;
    banco_abreviatura?: string;
    tipo_moneda_id: string | number;
    nro_cuenta: string;
    tipo_cuenta_id: string | number;
    titular: string;
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

export class EmpresaCuentaResponseDto {
    @Expose() empresa_cuenta_id!: number;
    @Expose() empresa_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.empresa_nombre || null)
    empresa_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.empresa_codigo || null)
    empresa_codigo!: string;

    @Expose() banco_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.banco_nombre || null)
    banco_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.banco_codigo_asfi || null)
    banco_codigo_asfi!: string;

    @Expose()
    @Transform(({ obj }) => obj.banco_abreviatura || null)
    banco_abreviatura!: string;

    @Expose() tipo_moneda_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoMoneda(obj.tipo_moneda_id))
    tipo_moneda!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() nro_cuenta!: string;

    @Expose() tipo_cuenta_id!: number;

    @Expose()
    @Transform(({ obj }) => transformTipoCuenta(obj.tipo_cuenta_id))
    tipo_cuenta!: {
        abreviatura: string;
        valor: number;
        prefijo: string;
    };

    @Expose() titular!: string;

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
