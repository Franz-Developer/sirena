// C:\sirena\sirena-backend\src\modules\empresas-cuentas\dto\create-empresa-cuenta.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min, MaxLength, MinLength, IsIn } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoMoneda, TIPO_MONEDA_METADATA, TipoCuenta, TIPO_CUENTA_METADATA } from '../../../common/constants/estados.constant';
import { createEnumMessage, getEnumValues } from '../../../common/utils/validation-helper.util';


export class CreateEmpresaCuentaDto {
    @IsInt({ message: 'empresa_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'empresa_id es obligatorio.' })
    @Min(1, { message: 'empresa_id debe ser mayor a 0.' })
    empresa_id: number;

    @IsInt({ message: 'banco_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'banco_id es obligatorio.' })
    @Min(1, { message: 'banco_id debe ser mayor a 0.' })
    banco_id: number;

    @IsInt({ message: 'tipo_moneda_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'tipo_moneda_id es obligatorio.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'tipo_moneda_id')
    })
    tipo_moneda_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'nro_cuenta debe ser un texto.' })
    @IsNotEmpty({ message: 'nro_cuenta es obligatorio.' })
    @MinLength(5, { message: 'nro_cuenta debe tener al menos 5 caracteres.' })
    @MaxLength(50, { message: 'nro_cuenta no puede exceder los 50 caracteres.' })
    @IsSafeText()
    nro_cuenta: string;

    @IsInt({ message: 'tipo_cuenta_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'tipo_cuenta_id es obligatorio.' })
    @IsIn(getEnumValues(TipoCuenta), {
        message: createEnumMessage(TIPO_CUENTA_METADATA, getEnumValues(TipoCuenta), 'tipo_cuenta_id')
    })
    tipo_cuenta_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim().toUpperCase() : value)
    @IsString({ message: 'titular debe ser un texto.' })
    @IsNotEmpty({ message: 'titular es obligatorio.' })
    @MinLength(3, { message: 'titular debe tener al menos 3 caracteres.' })
    @MaxLength(150, { message: 'titular no puede exceder los 150 caracteres.' })
    @IsSafeText()
    titular: string;
}
