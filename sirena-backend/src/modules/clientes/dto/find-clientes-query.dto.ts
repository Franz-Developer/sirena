// C:\sirena\sirena-backend\src\modules\clientes\dto\find-clientes-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA, TipoCliente, TIPO_CLIENTE_METADATA, TipoDocumento, TIPO_DOCUMENTO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';

export class FindClientesQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo exactMatch debe ser un número entero.' })
    @IsIn([0, 1], { message: 'El campo exactMatch debe ser 0 (flexible) o 1 (exacta).' })
    exactMatch: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'usuario_id debe ser un número entero.' })
    usuario_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: createEnumMessage(ESTADO_METADATA, ESTADOS_CONSULTA, 'estado_id')
    })
    estado_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_cliente_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoCliente), {
        message: createEnumMessage(TIPO_CLIENTE_METADATA, getEnumValues(TipoCliente), 'tipo_cliente_id')
    })
    tipo_cliente_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_documento_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoDocumento), {
        message: createEnumMessage(TIPO_DOCUMENTO_METADATA, getEnumValues(TipoDocumento), 'tipo_documento_id')
    })
    tipo_documento_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'banco_base_id debe ser un número entero.' })
    @Min(1, { message: 'banco_base_id debe ser mayor o igual a 1.' })
    banco_base_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'habilitado_ventas debe ser un número entero.' })
    @IsIn([0, 1], { message: 'habilitado_ventas debe ser 0 o 1.' })
    habilitado_ventas?: number;

    static getCampos(): string[] {
        const alias = 'c';
        const aliasBanco = 'b';
        return [
            `${alias}.cliente_id`,
            `${alias}.tipo_cliente_id`,
            `${alias}.cliente`,
            `${alias}.nit`,
            `${alias}.razon_social`,
            `${alias}.documento`,
            `${alias}.documento_complemento`,
            `${alias}.tipo_documento_id`,
            `${alias}.direccion`,
            `${alias}.telefono`,
            `${alias}.email`,
            `${alias}.banco_base_id`,
            `${aliasBanco}.banco AS banco_base_nombre`,
            `${aliasBanco}.abreviatura AS banco_base_abreviatura`,
            `${alias}.numero_cuenta`,
            `${alias}.habilitado_ventas`,
            `${alias}.limite_credito`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    static getCamposParaQ(): string[] {
        return ['cliente', 'nit', 'razon_social', 'documento', 'email', 'telefono', 'b.banco', 'b.abreviatura'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'cliente_id',
            'tipo_cliente_id',
            'cliente',
            'nit',
            'razon_social',
            'documento',
            'tipo_documento_id',
            'banco_base_id',
            'habilitado_ventas',
            'limite_credito'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'sucursales', campoFk: 'empresa_id' },
            { tabla: 'empresas_nits', campoFk: 'empresa_id' },
            { tabla: 'empresas_cuentas', campoFk: 'empresa_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['documento', 'tipo_documento_id', 'cliente'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 'c';
        const aliasBanco = 'b';
        return {
            'cliente_id': `${alias}.cliente_id`,
            'tipo_cliente_id': `${alias}.tipo_cliente_id`,
            'cliente': `${alias}.cliente`,
            'nit': `${alias}.nit`,
            'razon_social': `${alias}.razon_social`,
            'documento': `${alias}.documento`,
            'documento_complemento': `${alias}.documento_complemento`,
            'tipo_documento_id': `${alias}.tipo_documento_id`,
            'direccion': `${alias}.direccion`,
            'telefono': `${alias}.telefono`,
            'email': `${alias}.email`,
            'banco_base_id': `${alias}.banco_base_id`,
            'banco_base_nombre': `${aliasBanco}.banco`,
            'banco_base_abreviatura': `${aliasBanco}.abreviatura`,
            'numero_cuenta': `${alias}.numero_cuenta`,
            'habilitado_ventas': `${alias}.habilitado_ventas`,
            'limite_credito': `${alias}.limite_credito`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`
        };
    }
}

export { PaginatedResult };
