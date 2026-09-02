// C:\sirena\sirena-backend\src\common\services\file-url.service.ts
import { basename } from 'path';
import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class FileUrlService {
    private readonly logger = new Logger(FileUrlService.name);
    private readonly DANGEROUS_CHARS = /[<>"{}|\\^`[\]]/g;
    private readonly uploadDir = path.resolve(process.cwd(), 'uploads');

    constructor(private readonly configService: ConfigService) {}

    getFileUrl(filename: string | null, prefix: string = 'logos'): string | null {
        if (!filename) return null;

        if (this.isValidUrl(filename)) {
            return this.sanitizeUrl(filename);
        }

        // VERIFICAR QUE EL ARCHIVO EXISTE FÍSICAMENTE
        if (!this.fileExists(filename, prefix)) {
            this.logger.warn(`Archivo no encontrado: ${prefix}/${filename}`);
            return null; // O devolver un default
        }

        const sanitizedFilename = this.sanitizeFilename(filename);
        const sanitizedPrefix = this.sanitizePrefix(prefix);
        this.validatePrefix(sanitizedPrefix);

        const baseUrl = this.getBaseUrl();
        return `${baseUrl}/api/${sanitizedPrefix}/${encodeURIComponent(sanitizedFilename)}`;
    }

    private fileExists(filename: string, prefix: string): boolean {
        const filePath = path.join(this.uploadDir, prefix, path.basename(filename));
        try {
            return fs.existsSync(filePath);
        } catch {
            return false;
        }
    }

    getLogoUrl(filename: string | null): string | null {
        return this.getFileUrl(filename, 'logos');
    }

    getProductUrl(filename: string | null): string | null {
        return this.getFileUrl(filename, 'products');
    }

    getPersonUrl(filename: string | null): string | null {
        return this.getFileUrl(filename, 'persons');
    }

    getPersonQrUrl(filename: string | null): string | null {
        return this.getFileUrl(filename, 'persons_qr');
    }

    getAvatarUrl(filename: string | null): string | null {
        return this.getFileUrl(filename, 'avatars');
    }

    private isValidUrl(url: string): boolean {
        try {
            const parsedUrl = new URL(url);
            return ['http:', 'https:'].includes(parsedUrl.protocol);
        } catch {
            return false;
        }
    }

    private sanitizeUrl(url: string): string {
        return url.replace(this.DANGEROUS_CHARS, '');
    }

    private sanitizeFilename(filename: string): string {
        let sanitized = basename(filename);

        sanitized = sanitized.replace(this.DANGEROUS_CHARS, '');
        sanitized = sanitized.trim();

        if (!sanitized) {
            this.logger.warn(`Intento de nombre de archivo vacío en FileUrlService: "${filename}"`);
            throw new BadRequestException('Nombre de archivo inválido.');
        }

        this.logger.debug(`Archivo sanitizado correctamente: "${filename}" → "${sanitized}"`);

        return sanitized;
    }

    private sanitizePrefix(prefix: string): string {
        let sanitized = prefix.replace(this.DANGEROUS_CHARS, '');
        sanitized = basename(sanitized);
        sanitized = sanitized.trim();

        return sanitized;
    }

    private validatePrefix(prefix: string): void {
        if (!prefix) {
            throw new BadRequestException('Prefijo de ruta inválido.');
        }

        if (!/^[a-zA-Z0-9_-]+$/.test(prefix)) {
            this.logger.warn(`Intento de prefix inválido en FileUrlService: "${prefix}"`);
            throw new BadRequestException('El prefijo contiene caracteres no permitidos. Solo se permiten letras, números, guiones y guiones bajos.');
        }
    }

    private getBaseUrl(): string {
        const port = this.configService.get<number>('PORT') || 3010;
        const host = this.configService.get<string>('APP_URL') || `http://localhost:${port}`;
        return host;
    }
}
