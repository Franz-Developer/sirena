// C:\sirena\sirena-backend\src\common\decorators\safe-text.decorator.ts
import { registerDecorator, ValidationArguments, ValidationOptions } from 'class-validator';
import xss from 'xss';

export function IsSafeText(
    validationOptions?: ValidationOptions,
): PropertyDecorator {
    return (
        target: object,
        propertyKey: string | symbol,
    ): void => {
        const decoratorOptions = {
            name: 'isSafeText',
            target: target.constructor,
            propertyName: String(propertyKey),
            validator: {
                validate(value: unknown): boolean {
                    if (
                        value === null ||
                        value === undefined ||
                        value === ''
                    ) {
                        return true;
                    }

                    if (typeof value !== 'string') {
                        return false;
                    }

                    // Caracteres de control no permitidos.
                    const controlChars =
                        /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u202E]/;

                    if (controlChars.test(value)) {
                        return false;
                    }

                    // Rechazar HTML, scripts y etiquetas.
                    const sanitized = xss(value, {
                        whiteList: {},
                        stripIgnoreTag: true,
                        stripIgnoreTagBody: [
                            'script',
                            'style',
                            'iframe',
                        ],
                    });

                    return sanitized === value;
                },

                defaultMessage(
                    args: ValidationArguments,
                ): string {
                    return `${args.property} contiene caracteres o contenido no permitido.`;
                },
            },

            ...(validationOptions !== undefined
                ? { options: validationOptions }
                : {}),
        };

        registerDecorator(decoratorOptions);
    };
}
