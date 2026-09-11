// C:\sirena\sirena-backend\src\modules\clientes\dto\create-cliente.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, Min, MaxLength, IsNumber, IsEmail, MinLength } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoCliente, TIPO_CLIENTE_METADATA, TipoDocumento, TIPO_DOCUMENTO_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateClienteDto {
    @IsOptional()
    @IsInt({ message: 'tipo_cliente_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoCliente), {
        message: createEnumMessage(TIPO_CLIENTE_METADATA, getEnumValues(TipoCliente), 'tipo_cliente_id')
    })
    tipo_cliente_id?: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsNotEmpty({ message: 'cliente es obligatorio.' })
    @IsString({ message: 'cliente debe ser un texto.' })
    @MinLength(3, { message: 'cliente debe tener al menos 3 caracteres.' })
    @MaxLength(100, { message: 'cliente no puede exceder los 100 caracteres.' })
    @IsSafeText()
    cliente: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'nit debe ser un texto.' })
    @MaxLength(20, { message: 'nit no puede exceder los 20 caracteres.' })
    @IsSafeText()
    nit?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'razon_social debe ser un texto.' })
    @MaxLength(150, { message: 'razon_social no puede exceder los 150 caracteres.' })
    @IsSafeText()
    razon_social?: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsNotEmpty({ message: 'documento es obligatorio.' })
    @IsString({ message: 'documento debe ser un texto.' })
    @MinLength(1, { message: 'documento debe tener al menos 1 carácter.' })
    @MaxLength(30, { message: 'documento no puede exceder los 30 caracteres.' })
    @IsSafeText()
    documento: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'documento_complemento debe ser un texto.' })
    @MaxLength(10, { message: 'documento_complemento no puede exceder los 10 caracteres.' })
    @IsSafeText()
    documento_complemento?: string;

    @IsOptional()
    @IsInt({ message: 'tipo_documento_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoDocumento), {
        message: createEnumMessage(TIPO_DOCUMENTO_METADATA, getEnumValues(TipoDocumento), 'tipo_documento_id')
    })
    tipo_documento_id?: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'direccion debe ser un texto.' })
    @MaxLength(255, { message: 'direccion no puede exceder los 255 caracteres.' })
    @IsSafeText()
    direccion?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'telefono debe ser un texto.' })
    @MaxLength(100, { message: 'telefono no puede exceder los 100 caracteres.' })
    @IsSafeText()
    telefono?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsEmail({}, { message: 'email debe ser un correo electrónico válido.' })
    @MaxLength(100, { message: 'email no puede exceder los 100 caracteres.' })
    email?: string;

    @IsOptional()
    @IsInt({ message: 'banco_base_id debe ser un número entero.' })
    @Min(1, { message: 'banco_base_id debe ser mayor a 0.' })
    banco_base_id?: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'numero_cuenta debe ser un texto.' })
    @MaxLength(50, { message: 'numero_cuenta no puede exceder los 50 caracteres.' })
    @IsSafeText()
    numero_cuenta?: string;

    @IsOptional()
    @IsInt({ message: 'habilitado_ventas debe ser un número entero.' })
    @IsIn([0, 1], { message: 'habilitado_ventas debe ser 0 (No) o 1 (Sí).' })
    habilitado_ventas?: number;

    @IsOptional()
    @IsNumber({ maxDecimalPlaces: 2 }, { message: 'limite_credito debe ser un número con máximo 2 decimales.' })
    @Min(0, { message: 'limite_credito no puede ser negativo.' })
    limite_credito?: number;
}
