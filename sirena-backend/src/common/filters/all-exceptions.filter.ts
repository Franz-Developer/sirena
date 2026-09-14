// C:\sirena\sirena-backend\src\common\filters\all-exceptions.filter.ts
import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus } from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
    constructor(private readonly logger: PinoLogger) {}

    catch(exception: unknown, host: ArgumentsHost) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();

        const status = exception instanceof HttpException
            ? exception.getStatus()
            : HttpStatus.INTERNAL_SERVER_ERROR;

        // Solo registramos lo que importa
        if (status >= 500) {
            // Error real del sistema
            this.logger.error({
                msg: 'Error no controlado',
                method: request.method,
                url: request.url,
                status,
                error: exception instanceof Error ? exception.message : String(exception),
                stack: exception instanceof Error ? exception.stack : undefined,
            });
        } else if (status === 403 || status === 401) {
            // Evento de seguridad
            this.logger.warn({
                msg: 'Evento de seguridad',
                method: request.method,
                url: request.url,
                status,
                userId: request.user?.usuario_id,
                ip: request.ip,
                detalle: exception instanceof HttpException
                    ? (exception.getResponse() as any)?.message
                    : String(exception),
            });
        }
        // 400, 404, 409 → NO se loguean (flujo normal)

        response.status(status).json(
            exception instanceof HttpException
                ? exception.getResponse()
                : { statusCode: 500, message: 'Error interno del servidor' }
        );
    }
}
