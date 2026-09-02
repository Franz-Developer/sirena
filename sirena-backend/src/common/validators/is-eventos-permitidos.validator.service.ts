// C:\sirena\sirena-backend\src\common\validators\is-eventos-permitidos.validator.service.ts
import { registerDecorator, ValidationOptions, ValidationArguments, ValidatorConstraint, ValidatorConstraintInterface } from 'class-validator';
import { Evento, EVENTO_METADATA } from '../constants/estados.constant';
import { TABLAS_ARRAY } from '../constants/tablas.constant';

export const ACCIONES_EVENTOS_PERMITIDAS = ['crear', 'editar', 'anular'] as const;
export type AccionEventoPermitida = typeof ACCIONES_EVENTOS_PERMITIDAS[number];

export const EVENTOS_POR_ACCION: Record<AccionEventoPermitida, Evento[]> = {
    crear: [
        Evento.COMPRA,
        Evento.VENTA,
        Evento.PROFORMA,
        Evento.EGRESO_TRASPASO,
        Evento.INGRESO_TRASPASO,
        Evento.ANULACION,
        Evento.AJUSTE_INGRESO,
        Evento.AJUSTE_EGRESO,
        Evento.SOLICITUD_COMPRA,
        Evento.VENTA_RESERVA,
        Evento.DEVOLUCION_CLIENTE,
        Evento.DEVOLUCION_PROVEEDOR,
        Evento.ROBO,
        Evento.PERDIDA_CADUCIDAD,
        Evento.MERMA_ROTURA,
        Evento.INVENTARIO_FISICO_SOBRANTE,
        Evento.INVENTARIO_FISICO_FALTANTE,
        Evento.CONVERSION_UNIDADES,
        Evento.RETIRO_CUARENTENA,
        Evento.INGRESO_DONACION,
        Evento.LIBERACION_RESERVA,
    ],
    editar: [
        Evento.COMPRA,
        Evento.VENTA,
    ],
    anular: [
        Evento.ANULACION,
    ],
};

@ValidatorConstraint({ name: 'isEventosPermitidos', async: false })
export class IsEventosPermitidosConstraint implements ValidatorConstraintInterface {
    private customMessage = '';

    validate(value: unknown, args: ValidationArguments): boolean {
        if (value === undefined || value === null) {
            return true;
        }

        if (typeof value !== 'object' || Array.isArray(value)) {
            this.customMessage = `${args.property} debe ser un objeto JSON.`;
            return false;
        }

        const obj = value as Record<string, any>;
        const keys = Object.keys(obj);

        if (keys.length === 0) {
            return true;
        }

        for (const key of keys) {
            if (!ACCIONES_EVENTOS_PERMITIDAS.includes(key as AccionEventoPermitida)) {
                this.customMessage =
                    `La clave "${key}" no es permitida en ${args.property}. ` +
                    `Claves válidas: ${ACCIONES_EVENTOS_PERMITIDAS.join(', ')}.`;
                return false;
            }

            if (!Array.isArray(obj[key])) {
                this.customMessage =
                    `${args.property}.${key} debe ser un arreglo de números de evento.`;
                return false;
            }

            if (obj[key].length === 0) {
                this.customMessage =
                    `${args.property}.${key} no puede estar vacío. Debe contener al menos un evento.`;
                return false;
            }

            for (const evento of obj[key]) {
                if (typeof evento !== 'number' || !Number.isInteger(evento)) {
                    this.customMessage =
                        `${args.property}.${key} contiene un valor no numérico: "${evento}".`;
                    return false;
                }

                if (!EVENTO_METADATA[evento as Evento]) {
                    const eventosValidos = Object.keys(EVENTO_METADATA)
                        .map(Number)
                        .sort((a, b) => a - b)
                        .map(id => {
                            const meta = EVENTO_METADATA[id as Evento];
                            return `${id}(${meta.abreviatura})`;
                        })
                        .join(', ');
                    this.customMessage =
                        `El evento "${evento}" en ${args.property}.${key} no es válido. ` +
                        `Eventos válidos: ${eventosValidos}.`;
                    return false;
                }
            }

            const eventosPermitidosParaAccion = EVENTOS_POR_ACCION[key as AccionEventoPermitida] || [];
            const eventosNoPermitidos = obj[key].filter(
                (e: number) => !eventosPermitidosParaAccion.includes(e)
            );

            if (eventosNoPermitidos.length > 0) {
                this.customMessage =
                    `eventos_permitidos.${key} debe contener solo eventos válidos para la acción "${key}": ` +
                    eventosPermitidosParaAccion.map((e) => `${e}(${Evento[e]})`).join(', ');
                return false;
            }
        }

        return true;
    }

    defaultMessage(args: ValidationArguments): string {
        return this.customMessage || `${args.property} no cumple con el formato esperado.`;
    }
}

export function IsEventosPermitidos(
    validationOptions?: ValidationOptions,
): PropertyDecorator {
    return function (object: object, propertyName: string | symbol) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName as string,
            validator: IsEventosPermitidosConstraint,
            ...(validationOptions && { options: validationOptions }),
        });
    };
}

@ValidatorConstraint({ name: 'isValidTable', async: false })
export class IsValidTableConstraint implements ValidatorConstraintInterface {
    validate(value: unknown): boolean {
        if (typeof value !== 'string') {
            return false;
        }
        return TABLAS_ARRAY.includes(value as any);
    }

    defaultMessage(args: ValidationArguments): string {
        return `${args.property} debe ser una tabla válida. Valores permitidos: ${TABLAS_ARRAY.join(', ')}.`;
    }
}

export function IsValidTable(
    validationOptions?: ValidationOptions,
): PropertyDecorator {
    return function (object: object, propertyName: string | symbol) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName as string,
            validator: IsValidTableConstraint,
            ...(validationOptions && { options: validationOptions }),
        });
    };
}

export function validarConsistenciaPermisos(
    eventosPermitidos: Record<string, number[]> | undefined,
    permisos: { crear?: number; editar?: number; anular?: number }
): void {
    const accionesHabilitadas: AccionEventoPermitida[] = [];

    if (permisos.crear === 1) accionesHabilitadas.push('crear');
    if (permisos.editar === 1) accionesHabilitadas.push('editar');
    if (permisos.anular === 1) accionesHabilitadas.push('anular');

    if (accionesHabilitadas.length === 0) {
        return;
    }

    if (!eventosPermitidos || typeof eventosPermitidos !== 'object') {
        throw new Error(
            `eventos_permitidos es requerido cuando se habilita: ${accionesHabilitadas.join(', ')}.`
        );
    }

    for (const accion of accionesHabilitadas) {
        if (!eventosPermitidos[accion]) {
            throw new Error(
                `eventos_permitidos.${accion} es requerido cuando la acción "${accion}" está habilitada.`
            );
        }

        if (!Array.isArray(eventosPermitidos[accion]) || eventosPermitidos[accion].length === 0) {
            throw new Error(
                `eventos_permitidos.${accion} debe ser un arreglo con al menos un evento.`
            );
        }
    }
}

@ValidatorConstraint({ name: 'isKardexEventosPermitidos', async: false })
export class IsKardexEventosPermitidosConstraint implements ValidatorConstraintInterface {
    validate(_value: any, args: ValidationArguments): boolean {
        const dto = args.object as any;
        const eventos = dto.eventos_permitidos;
        const tabla = dto.tabla;

        const tieneEventos = eventos && typeof eventos === 'object' && Object.keys(eventos).length > 0;

        if (tieneEventos && tabla !== 'kardex') {
            return false;
        }
        return true;
    }

    defaultMessage(_args: ValidationArguments): string {
        return 'Los eventos permitidos solo se pueden configurar para la tabla kardex.';
    }
}

export function IsKardexEventosPermitidos(validationOptions?: ValidationOptions): PropertyDecorator {
    return function (object: object, propertyName: string | symbol) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName as string,
            validator: IsKardexEventosPermitidosConstraint,
            ...(validationOptions && { options: validationOptions }),
        });
    };
}

@ValidatorConstraint({ name: 'isUniqueEventKeys', async: false })
export class IsUniqueEventKeysConstraint implements ValidatorConstraintInterface {
    private customMessage = '';

    validate(value: unknown, args: ValidationArguments): boolean {
        if (value === undefined || value === null) {
            return true;
        }

        if (typeof value !== 'object' || Array.isArray(value)) {
            this.customMessage = `${args.property} debe ser un objeto.`;
            return false;
        }

        const obj = value as Record<string, any>;
        const keys = Object.keys(obj);

        const validKeys = ['crear', 'editar', 'anular'];
        const invalidKeys = keys.filter(key => !validKeys.includes(key));

        if (invalidKeys.length > 0) {
            this.customMessage =
                `Las claves "${invalidKeys.join(', ')}" no son permitidas en ${args.property}. ` +
                `Claves permitidas: ${validKeys.join(', ')}.`;
            return false;
        }

        for (const key of keys) {
            if (!Array.isArray(obj[key])) {
                this.customMessage = `${args.property}.${key} debe ser un arreglo.`;
                return false;
            }

            if (obj[key].length === 0) {
                this.customMessage = `${args.property}.${key} no puede estar vacío.`;
                return false;
            }

            for (const item of obj[key]) {
                if (typeof item !== 'number' || !Number.isInteger(item)) {
                    this.customMessage = `${args.property}.${key} contiene un valor no numérico: "${item}".`;
                    return false;
                }
            }
        }

        return true;
    }

    defaultMessage(_args: ValidationArguments): string {
        return this.customMessage || 'El formato de eventos_permitidos no es válido.';
    }
}

export function IsUniqueEventKeys(
    validationOptions?: ValidationOptions,
): PropertyDecorator {
    return function (object: object, propertyName: string | symbol) {
        registerDecorator({
            target: object.constructor,
            propertyName: propertyName as string,
            validator: IsUniqueEventKeysConstraint,
            ...(validationOptions && { options: validationOptions }),
        });
    };
}
