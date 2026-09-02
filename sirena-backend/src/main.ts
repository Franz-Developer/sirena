// C:\sirena\sirena-backend\src\main.ts
import { join } from 'path';
import { Logger, ValidationPipe, LogLevel, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import compression from 'compression';
import helmet from 'helmet';
import { Logger as PinoLogger } from 'nestjs-pino';
import { AppModule } from './app.module';

process.stdout.setDefaultEncoding('utf8');
process.stderr.setDefaultEncoding('utf8');

function getLogLevels(): LogLevel[] {
    const env = process.env['NODE_ENV'] || 'development';
    if (env === 'production') return ['error', 'warn'];
    if (env === 'development') return ['log', 'error', 'warn'];  // Se quito , 'debug', 'verbose'
    return ['log', 'error', 'warn'];
}

async function bootstrap() {
    const logger = new Logger('Bootstrap');
    const isDev = (process.env['NODE_ENV'] || 'development') === 'development';

    try {
        const app = await NestFactory.create<NestExpressApplication>(AppModule, {
            logger: getLogLevels(),
        });

        const configService = app.get(ConfigService);
        const uploadDir = configService.get<string>('UPLOAD_DIR', 'uploads');

        app.useLogger(app.get(PinoLogger));
        app.enableShutdownHooks();
        app.use(compression());
        app.use(helmet({ crossOriginResourcePolicy: false, contentSecurityPolicy: false }));
        app.enableCors();
        app.setGlobalPrefix('api');

        const root = process.cwd();
        app.useStaticAssets(join(root, uploadDir, 'logos'), { prefix: '/api/logos/' });
        app.useStaticAssets(join(root, uploadDir, 'products'), { prefix: '/api/products/' });
        app.useStaticAssets(join(root, uploadDir, 'avatars'), { prefix: '/api/avatars/' });
        app.useStaticAssets(join(root, uploadDir, 'persons'), { prefix: '/api/persons/' });
        app.useStaticAssets(join(root, uploadDir, 'persons_qr'), { prefix: '/api/persons_qr/' });

        app.useGlobalPipes(
            new ValidationPipe({
                whitelist: true,
                forbidNonWhitelisted: true,
                transform: true,
                transformOptions: {
                    enableImplicitConversion: true,
                },
                exceptionFactory: (errors) => {
                    const invalidParams = errors
                        .filter(error => error.constraints && error.constraints["whitelistValidation"])
                        .map(error => error.property);

                    if (invalidParams.length > 0) {
                        return new BadRequestException({
                            message: `❌ Parámetro(s) no permitido(s): ${invalidParams.join(', ')}`,
                            error: 'Bad Request',
                            statusCode: 400,
                            details: {
                                invalidParams,
                                hint: 'Revise los parámetros enviados en la URL. Consulte la documentación de la API para los parámetros permitidos.'
                            }
                        });
                    }

                    const messages: string[] = [];

                    for (const error of errors) {
                        if (error.constraints) {
                            for (const [key, message] of Object.entries(error.constraints)) {
                                if (key === 'isIn') {
                                    messages.push(message);
                                } else {
                                    messages.push(message);
                                }
                            }
                        }
                    }

                    if (messages.length > 0) {
                        const message = messages.length === 1
                            ? messages[0]
                            : messages;

                        return new BadRequestException({
                            message,
                            error: 'Bad Request',
                            statusCode: 400
                        });
                    }

                    return new BadRequestException({
                        message: 'Error de validación en los datos enviados.',
                        error: 'Bad Request',
                        statusCode: 400,
                        details: errors.map(error => ({
                            property: error.property,
                            value: error.value,
                            constraints: error.constraints,
                            children: error.children?.map(child => ({
                                property: child.property,
                                constraints: child.constraints,
                            })),
                        })),
                    });
                },
            })
        );

        let isShuttingDown = false;
        const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM', 'SIGQUIT'];

        signals.forEach(signal => {
            process.on(signal, async () => {
                if (isShuttingDown) {
                    logger.warn('Cierre ya en progreso, ignorando señal...');
                    return;
                }
                isShuttingDown = true;

                logger.warn(`Señal ${signal} recibida. Cerrando backend de forma ordenada...`);

                const timeout = setTimeout(() => {
                    logger.error('⏱️ Timeout en cierre gracioso (10s), forzando salida...');
                    process.exit(1);
                }, 10000);

                try {
                    await app.close();
                    clearTimeout(timeout);
                    logger.log('✅ Aplicación cerrada correctamente.');
                    process.exit(0);
                } catch (err) {
                    clearTimeout(timeout);
                    logger.error('❌ Error durante el cierre gracioso:', err);
                    process.exit(1);
                }
            });
        });

        const port = process.env['PORT'] || 3010;
        const env = process.env['NODE_ENV'] || 'development';
        await app.listen(port);

        logger.log(`Servidor escuchando en el puerto ${port}`);

        if (isDev) {
            console.log(`==========================================================`);
            console.log(`🚀 PORTAL VALKIRIA - BACKEND INICIADO`);
            console.log(`==========================================================`);
            console.log(`✅ Entorno:   ${env.toUpperCase()}`);
            console.log(`📡 URL Base:  http://localhost:${port}/api`);
            console.log(`🗄️  Database: PostgreSQL (${process.env['DB_DATABASE']})`);
            console.log(`📡 Host:      ${process.env['DB_HOST']}:${process.env['DB_PORT']}`);
            console.log(`🗜️  Estado:   COMPRESIÓN GZIP Y HELMET ACTIVADOS`);
            console.log(`⏱️  Hora:      ${new Date().toLocaleString('es-BO', { timeZone: 'America/La_Paz' })}`);
            console.log(`==========================================================`);
        }
    } catch (error: unknown) {
        const err = error as { code?: string; message?: string };
        const currentPort = process.env['PORT'] || 3010;
        if (err.code === 'EADDRINUSE') {
            logger.error(`Error: El puerto ${currentPort} ya está en uso.`);
        } else {
            logger.error(`Error crítico al iniciar el backend: ${err.message ?? 'Error desconocido'}`);
        }
        process.exit(1);
    }
}
bootstrap();
