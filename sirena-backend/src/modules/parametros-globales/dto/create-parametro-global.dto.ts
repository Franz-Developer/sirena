// C:\sirena\sirena-backend\src\modules\parametros-globales\dto\create-parametro-global.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, MaxLength, MinLength, Matches, ValidateIf, IsDefined, IsObject } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoDato, TIPO_DATO_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateParametroGlobalDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toLowerCase() : value)
    @IsString({ message: 'clave debe ser un texto.' })
    @IsNotEmpty({ message: 'clave es obligatoria.' })
    @MinLength(3, { message: 'clave debe tener al menos 3 caracteres.' })
    @MaxLength(100, { message: 'clave no puede exceder los 100 caracteres.' })
    @Matches(/^[a-z0-9_-]+$/, { message: 'clave debe contener solo letras minúsculas, números, guiones y guiones bajos.' })
    @IsSafeText()
    clave: string;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'valor debe ser un texto.' })
    @IsNotEmpty({ message: 'valor es obligatorio.' })
    @MaxLength(500, { message: 'valor no puede exceder los 500 caracteres.' })
    @IsSafeText()
    valor: string;

    @IsInt({ message: 'tipo_dato_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoDato), {
        message: createEnumMessage(TIPO_DATO_METADATA, getEnumValues(TipoDato), 'tipo_dato_id')
    })
    tipo_dato_id: number;

    @ValidateIf((o) => o.tipo_dato_id === TipoDato.JSONB)
    @IsDefined({ message: 'datos_json es obligatorio cuando el tipo de dato es JSON.' })
    @IsObject({ message: 'datos_json debe ser un objeto o estructura JSON válida.' })
    @Transform(({ value }) => {
        if (typeof value === 'string') {
            try {
                return JSON.parse(value);
            } catch {
                return value;
            }
        }
        return value;
    })
    datos_json?: any;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'descripcion debe ser un texto.' })
    @MaxLength(500, { message: 'descripcion no puede exceder los 500 caracteres.' })
    @IsSafeText()
    descripcion?: string;

    @IsOptional()
    @IsInt({ message: 'editable debe ser un número entero.' })
    @IsIn([0, 1], { message: 'editable debe ser 0 o 1.' })
    editable: number;
}
