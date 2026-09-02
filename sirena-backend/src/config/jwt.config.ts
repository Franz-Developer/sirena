// C:\sirena\sirena-backend\src\config\jwt.config.ts
import { readFileSync, existsSync } from 'fs';
import { isAbsolute, resolve } from 'path';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StringValue } from 'ms';

export class JwtConfig {
    private static readonly logger = new Logger('JwtConfig');

    static create(configService: ConfigService) {
        const { privateKey, publicKey, source } = this.getKeys(configService);
        this.validateKeys(privateKey, publicKey);

        const expiresIn = configService.get<StringValue>('JWT_EXPIRES_IN', '8h');
        this.logger.log(`🔐 JWT Configuration loaded [Source: ${source}] (Expires: ${expiresIn})`);

        return {
            privateKey,
            publicKey,
            signOptions: {
                algorithm: 'RS256' as const,
                expiresIn,
            },
        };
    }

    private static getKeys(configService: ConfigService): {
        privateKey: string;
        publicKey: string;
        source: string;
    } {
        // 📌 PRIORIDAD 1: Variables de entorno (Contenedores/Cloud)
        const envPrivateKey = configService.get<string>('JWT_PRIVATE_KEY');
        const envPublicKey = configService.get<string>('JWT_PUBLIC_KEY');

        if (envPrivateKey && envPublicKey) {
            return {
                // ✅ Normalizar saltos de línea (\n) en variables de entorno
                privateKey: envPrivateKey.replace(/\\n/g, '\n'),
                publicKey: envPublicKey.replace(/\\n/g, '\n'),
                source: 'Environment Variables',
            };
        }

        // 📌 PRIORIDAD 2: Archivos .pem (Desarrollo/Producción local)
        const rawPrivatePath = configService.get<string>(
            'JWT_PRIVATE_KEY_PATH',
            'src/config/certs/prisma-private.pem'
        );

        const rawPublicPath = configService.get<string>(
            'JWT_PUBLIC_KEY_PATH',
            'src/config/certs/prisma-public.pem'
        );

        // ✅ Resolver rutas absolutas para evitar dependencia del CWD
        const privateKeyPath = isAbsolute(rawPrivatePath)
            ? rawPrivatePath
            : resolve(process.cwd(), rawPrivatePath);

        const publicKeyPath = isAbsolute(rawPublicPath)
            ? rawPublicPath
            : resolve(process.cwd(), rawPublicPath);

        // Validar existencia
        if (!existsSync(privateKeyPath)) {
            throw new Error(
                `❌ JWT Private Key file not found:\n` +
                `   📁 Path: ${privateKeyPath}\n` +
                `   💡 Solution: Create the .pem file OR set JWT_PRIVATE_KEY in .env`
            );
        }

        if (!existsSync(publicKeyPath)) {
            throw new Error(
                `❌ JWT Public Key file not found:\n` +
                `   📁 Path: ${publicKeyPath}\n` +
                `   💡 Solution: Create the .pem file OR set JWT_PUBLIC_KEY in .env`
            );
        }

        // Leer archivos.
        try {
            const privateKey = readFileSync(privateKeyPath, 'utf8');
            const publicKey = readFileSync(publicKeyPath, 'utf8');

            return {
                privateKey,
                publicKey,
                source: `.pem Files (${rawPrivatePath})`,
            };
        } catch (error) {
            // ✅ CORRECCIÓN: Tipar error como Error o unknown
            const errorMessage = error instanceof Error ? error.message : String(error);
            throw new Error(`❌ Failed to read JWT key files: ${errorMessage}`);
        }
    }

    private static validateKeys(privateKey: string, publicKey: string): void {
        // Validar que no estén vacías
        if (!privateKey || privateKey.trim().length === 0) {
            throw new Error('❌ JWT private key is empty');
        }

        if (!publicKey || publicKey.trim().length === 0) {
            throw new Error('❌ JWT public key is empty');
        }

        // Validar formato RSA
        if (!privateKey.includes('PRIVATE KEY')) {
            throw new Error('❌ Invalid JWT private key format (must be RSA/PEM)');
        }

        if (!publicKey.includes('PUBLIC KEY')) {
            throw new Error('❌ Invalid JWT public key format (must be RSA/PEM)');
        }
    }
}
