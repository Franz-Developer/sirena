// C:\sirena\sirena-backend\src\common\services\file-validator.service.ts
import { Injectable, Logger } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class FileValidatorService {
    private readonly logger = new Logger(FileValidatorService.name);
    private readonly uploadsRoot = path.resolve(process.cwd(), 'uploads');

    async validarArchivoFisico(nombreArchivo: string, subCarpeta: string = ''): Promise<boolean> {
        if (!nombreArchivo) return false;
        try {
            const rutaCompleta = path.join(this.uploadsRoot, subCarpeta, nombreArchivo);
            await fs.promises.access(rutaCompleta, fs.constants.F_OK);
            return true;
        } catch {
            this.logger.warn(`Archivo físico no encontrado: ${subCarpeta}/${nombreArchivo}`);
            return false;
        }
    }
}
