// C:\sirena\sirena-backend\src\common\decorators\validation-message.decorator.ts
import { BadRequestException, ValidationPipe, Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

export const CustomValidationPipe = (options?: { concise?: boolean }) => {
    return new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
        exceptionFactory: (errors) => {
            if (options?.concise) {
                const messages = errors.filter(e => e.constraints).flatMap(e => Object.values(e.constraints!));
                return new BadRequestException({
                    message: messages.length === 1 ? messages[0] : messages,
                    error: 'Bad Request',
                    statusCode: 400
                });
            }

            return new BadRequestException({
                message: 'Error de validación en los datos enviados.',
                error: 'Bad Request',
                statusCode: 400,
                details: errors.map(({ property, value, constraints, children }) => ({ property, value, constraints, children }))
            });
        }
    });
};

@Injectable()
export class ValidationLogInterceptor implements NestInterceptor {
    constructor(private readonly pinoLogger: PinoLogger) {}

    intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        return next.handle().pipe(
            catchError(error => {
                if (error instanceof BadRequestException) {
                    const res: any = error.getResponse();
                    let msg = res.message || 'Error de validación';
                    if (Array.isArray(msg)) msg = msg.join(', ');

                    const req = context.switchToHttp().getRequest();
                    this.pinoLogger.setContext(context.getClass().name);
                    this.pinoLogger.warn(`❌ ${req.method} ${req.url} - ${error.getStatus()} - ${msg}`);
                }
                return throwError(() => error);
            })
        );
    }
}
