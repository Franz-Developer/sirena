// C:\sirena\sirena-backend\src\common\exceptions\domain.exception.ts
import { BadRequestException } from '@nestjs/common';

/**
 * Excepción personalizada para el manejo de errores de dominio.
 */
export class DomainException extends BadRequestException {
    constructor(
        message: string,
        metadata?: Record<string, any>
    ) {
        super({
            message,
            metadata,
        });
    }
}
