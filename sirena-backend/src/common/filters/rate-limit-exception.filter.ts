// C:\sirena\sirena-backend\src\common\filters\rate-limit-exception.filter.ts
import { ExceptionFilter, Catch, ArgumentsHost, HttpStatus, Logger } from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import { Response, Request } from 'express';

/**
 * Filtro global para manejar excepciones de rate limiting
 * Siguiendo la filosofía AK-47: simple, directo y sin complicaciones
 */
@Catch(ThrottlerException)
export class RateLimitExceptionFilter implements ExceptionFilter {
    private readonly logger = new Logger(RateLimitExceptionFilter.name);

    catch(exception: ThrottlerException, host: ArgumentsHost) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse<Response>();
        const request = ctx.getRequest<Request>();

        // ✅ Log simple para auditoría
        this.logger.warn(
            `🚨 Rate limit excedido: ${request.method} ${request.url} - IP: ${request.ip}.`
        );

        // ✅ Extracción segura evitando el error de tipo con TypeScript
        const message = exception.message ?? '';
        const retryAfterMatch = message.match(/TTL: (\d+)/);

        // Si hay coincidencia y el grupo 1 existe, lo parseamos; de lo contrario, usamos 60 por defecto
        const retryAfter = retryAfterMatch && retryAfterMatch[1]
            ? parseInt(retryAfterMatch[1], 10)
            : 60;

        // ✅ Una respuesta, siempre igual
        response.status(HttpStatus.TOO_MANY_REQUESTS).json({
            statusCode: HttpStatus.TOO_MANY_REQUESTS,
            error: 'Too Many Requests',
            message: 'Has excedido el límite de peticiones. Por favor, espera un momento.',
            retryAfter: retryAfter,
            timestamp: new Date().toISOString(),
            path: request.url,
        });
    }
}
