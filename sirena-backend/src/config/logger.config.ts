import * as fs from 'fs';
import { resolve } from 'path';
import { Params } from 'nestjs-pino';

const logDir = resolve(process.cwd(), 'logs');
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

const getLogLevel = (): string => {
    const env = process.env['NODE_ENV'] || 'development';
    if (env === 'production') return 'info';
    return 'debug';
};

export const loggerConfig: Params = {
    pinoHttp: {
        level: getLogLevel(),
        timestamp: () => `,"timestamp":"${new Date().toISOString()}"`,

        transport: {
            targets: [
                ...(process.env['NODE_ENV'] !== 'production'
                    ? [
                          {
                              target: 'pino-pretty',
                              options: {
                                  colorize: true,
                                  translateTime: 'SYS:yyyy-mm-dd HH:MM:ss.l',
                                  ignore: 'pid,hostname,environment,service,version,context',
                                  singleLine: false,
                              },
                          },
                      ]
                    : []),
                {
                    target: 'pino-roll',
                    options: {
                        file: resolve(logDir, 'app.log'),
                        frequency: 'daily',
                        size: '10m',
                        compress: true,
                        limit: { count: 30 },
                    },
                },
            ],
        },

        redact: {
            paths: [
                'password',
                'contrasena',
                'token',
                'authorization',
                '*.contrasena',
                '*.password',
                '*.token',
                '*.secret',
            ],
            censor: '***REDACTED***',
        },
        serializers: {
            req: (req: any) => {
                const statusCode = req.res?.statusCode || req.raw?.res?.statusCode;
                if (statusCode === 400) {
                    return {
                        method: req.method,
                        url: req.url,
                    };
                }
                return {
                    method: req.method,
                    url: req.url,
                    query: req.query,
                    params: req.params,
                };
            },
            res: (res: any) => {
                return {
                    statusCode: res.statusCode,
                };
            },
            err: (err: any) => {
                if (err?.context === 'LegacyRouteConverter') {
                    return undefined;
                }
                return {
                    type: err.type,
                    message: err.message,
                    stack: err.stack,
                    code: err.code,
                    name: err.name,
                };
            },
        },
    },
};