// C:\sirena\sirena-backend\src\modules\empresas-nits\dto\create-empresa-nit.dto.ts
import { Type, Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsEmail, IsDate, IsIn, Min, MaxLength, MinLength, Matches } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { Ambiente, AMBIENTE_METADATA, ModalidadFacturacion, MODALIDAD_FACTURACION_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateEmpresaNitDto {
    @IsInt({ message: 'empresa_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'empresa_id es obligatorio.' })
    @Min(1, { message: 'empresa_id debe ser mayor a 0.' })
    empresa_id: number;

    @IsInt({ message: 'ambiente_id debe ser un número entero.' })
    @IsIn(getEnumValues(Ambiente), {
        message: createEnumMessage(AMBIENTE_METADATA, getEnumValues(Ambiente), 'ambiente_id')
    })
    ambiente_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'nit debe ser un texto.' })
    @IsNotEmpty({ message: 'nit es obligatorio.' })
    @MinLength(7, { message: 'nit debe tener al menos 7 caracteres.' })
    @MaxLength(20, { message: 'nit no puede exceder los 20 caracteres.' })
    @Matches(/^[0-9]+$/, { message: 'nit debe contener solo números.' })
    @IsSafeText()
    nit: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'razon_social debe ser un texto.' })
    @IsNotEmpty({ message: 'razon_social es obligatorio.' })
    @MinLength(3, { message: 'razon_social debe tener al menos 3 caracteres.' })
    @MaxLength(500, { message: 'razon_social no puede exceder los 500 caracteres.' })
    @IsSafeText()
    razon_social: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'actividad_economica_principal debe ser un texto.' })
    @IsNotEmpty({ message: 'actividad_economica_principal es obligatorio.' })
    @MinLength(3, { message: 'actividad_economica_principal debe tener al menos 3 caracteres.' })
    @MaxLength(2000, { message: 'actividad_economica_principal no puede exceder los 2000 caracteres.' })
    @IsSafeText()
    actividad_economica_principal: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'etiqueta debe ser un texto.' })
    @IsNotEmpty({ message: 'etiqueta es obligatorio.' })
    @MinLength(1, { message: 'etiqueta debe tener al menos 1 carácter.' })
    @MaxLength(30, { message: 'etiqueta no puede exceder los 30 caracteres.' })
    @Matches(/^[A-Z_]+$/, { message: 'etiqueta debe contener solo mayúsculas y guiones bajos.' })
    @IsSafeText()
    etiqueta: string;

    @IsInt({ message: 'modalidad_facturacion_id debe ser un número entero.' })
    @IsIn(getEnumValues(ModalidadFacturacion), {
        message: createEnumMessage(MODALIDAD_FACTURACION_METADATA, getEnumValues(ModalidadFacturacion), 'modalidad_facturacion_id')
    })
    modalidad_facturacion_id: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'certificado_digital debe ser un texto.' })
    @MaxLength(2000, { message: 'certificado_digital no puede exceder los 2000 caracteres.' }) // Sincronizado a 2000
    @IsSafeText()
    certificado_digital?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'certificado_password debe ser un texto.' })
    @MaxLength(500, { message: 'certificado_password no puede exceder los 500 caracteres.' })
    @IsSafeText()
    certificado_password?: string;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'token_siat debe ser un texto.' })
    @MaxLength(2000, { message: 'token_siat no puede exceder los 2000 caracteres.' })
    @IsSafeText()
    token_siat?: string;

    @Type(() => Date)
    @IsDate({ message: 'fecha_inicio_vigencia debe ser una fecha válida.' })
    fecha_inicio_vigencia: Date;

    @Type(() => Date)
    @IsDate({ message: 'fecha_fin_vigencia debe ser una fecha válida.' })
    fecha_fin_vigencia: Date;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsEmail({}, { message: 'email_fiscal debe ser un correo electrónico válido.' })
    @IsNotEmpty({ message: 'email_fiscal es obligatorio.' })
    @MaxLength(200, { message: 'email_fiscal no puede exceder los 200 caracteres.' })
    email_fiscal: string;
}
