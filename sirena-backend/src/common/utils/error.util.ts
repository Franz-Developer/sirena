// C:\sirena\sirena-backend\src\common\utils\error.util.ts
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
