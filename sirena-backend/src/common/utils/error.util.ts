// C:\sirena\sirena-backend\src\common\utils\error.util.ts
import { HttpStatus } from '@nestjs/common';
import { DomainException } from '../exceptions/domain.exception';

export function getErrorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error ?? 'Error desconocido');
}

export function getErrorStack(error: unknown): string | undefined {
    return error instanceof Error ? error.stack : undefined;
}

export function isDomainException(error: unknown): error is DomainException {
    return error instanceof DomainException;
}

export function crearError(
    error: unknown,
    modulo: string,
    operacion: 'crear' | 'actualizar'
): DomainException {
    const errorMessage = getErrorMessage(error);

    const mensajes = {
        crear: `No se pudo crear ${modulo}.`,
        actualizar: `No se pudo actualizar ${modulo}.`
    };

    return new DomainException(
        mensajes[operacion],
        {
            httpStatus: HttpStatus.INTERNAL_SERVER_ERROR,
            userMessage: `Ocurrió un problema al intentar ${operacion} ${modulo}.`,
            suggestion: operacion === 'crear'
                ? 'Verifica los datos e intenta nuevamente. Si el problema persiste, contacta a soporte.'
                : 'Verifica los datos e intenta nuevamente.',
            details: errorMessage
        }
    );
}
