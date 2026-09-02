// C:\sirena\sirena-backend\src\common\services\generar-qr.service.ts
import { Injectable, Logger, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, EntityManager } from 'typeorm';
import * as QRCode from 'qrcode';
import * as path from 'path';
import * as fs from 'fs/promises';
import { ConfiguracionService } from './configuracion.service';
import { DomainException } from '../exceptions/domain.exception';
import { ESTADO_ACTIVO } from '../constants/estados.constant';
import { getErrorMessage } from '../utils/error.util';
import { logSqlQuery } from '../utils/sql-logger.util';

export interface QRConfig {
    width: number;
    height: number;
    margin: number;
    color_dark: string;
    color_light: string;
    format: 'png';
    error_correction_level: 'L' | 'M' | 'Q' | 'H';
}

@Injectable()
export class GenerarQRUtil {
    private readonly logger = new Logger(GenerarQRUtil.name);
    private readonly uploadDir = path.resolve(process.cwd(), 'uploads', 'persons_qr');

    constructor(
        @InjectDataSource()
        private readonly dataSource: DataSource,
        private readonly configuracionService: ConfiguracionService,
    ) {}

    async generarQRParaTrabajador(
        trabajadorId: number,
        forceRegenerate: boolean = false,
        manager?: EntityManager,
    ): Promise<string> {
        this.logger.log(`Generando QR para trabajador ID: ${trabajadorId}`);

        const trabajador = await this.obtenerTrabajadorActivo(trabajadorId, manager);

        if (trabajador.qr && trabajador.qr !== '' && !forceRegenerate) {
            this.logger.debug(`El trabajador ${trabajadorId} ya tiene QR: ${trabajador.qr}`);
            return trabajador.qr;
        }

        const config = await this.obtenerConfiguracionQR();
        const qrContent = this.construirContenidoQR(trabajador);
        const qrBuffer = await this.generarBufferQR(qrContent, config);
        const fileName = `${trabajadorId}.png`;

        await this.guardarArchivoQR(qrBuffer, fileName);
        await this.actualizarQRenBD(trabajadorId, fileName, manager);

        this.logger.log(`QR generado exitosamente: ${fileName}`);
        return fileName;
    }

    private async obtenerTrabajadorActivo(
        trabajadorId: number,
        manager?: EntityManager,
    ): Promise<{
        trabajador_id: number;
        nombres: string;
        paterno: string;
        materno: string | null;
        dni: string;
        qr: string;
    }> {
        const query = `
            SELECT trabajador_id, nombres, paterno, materno, dni, qr
            FROM trabajadores
            WHERE trabajador_id = $1
              AND estado_id = $2
        `;
        const params = [trabajadorId, ESTADO_ACTIVO];
        logSqlQuery(query, params, 'obtenerTrabajadorActivo');

        const executor = manager ?? this.dataSource;
        const result = await executor.query(query, params);

        if (!result || result.length === 0) {
            throw new DomainException(
                `No se encontró un trabajador activo con ID ${trabajadorId}. Verifique que el ID exista y que el trabajador esté en estado ACTIVO.`,
                { httpStatus: HttpStatus.NOT_FOUND }
            );
        }

        return result[0];
    }

    private async actualizarQRenBD(
        trabajadorId: number,
        fileName: string,
        manager?: EntityManager,
    ): Promise<void> {
        const query = `
            UPDATE trabajadores
            SET qr = $1
            WHERE trabajador_id = $2
              AND estado_id = $3
        `;
        const params = [fileName, trabajadorId, ESTADO_ACTIVO];
        logSqlQuery(query, params, 'actualizarQRenBD');

        try {
            const executor = manager ?? this.dataSource;
            const result = await executor.query(query, params);

            if (result?.[0]?.rowCount === 0) {
                throw new DomainException(
                    `No se pudo actualizar el QR del trabajador ${trabajadorId}. El trabajador podría haber sido desactivado.`,
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            this.logger.debug(`QR actualizado en BD para trabajador ${trabajadorId}: ${fileName}`);
        } catch (error) {
            if (error instanceof DomainException) {
                throw error;
            }
            throw new DomainException(
                `Error al actualizar el QR en la base de datos: ${getErrorMessage(error)}`,
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
            );
        }
    }

    private async obtenerConfiguracionQR(): Promise<QRConfig> {
        try {
            const config = await this.configuracionService.obtenerValorTipado<QRConfig>('qr_trabajador_config');

            if (!config) {
                throw new DomainException(
                    'No se encontró la configuración del QR en parámetros globales. ' +
                    'Verifique que el parámetro "qr_trabajador_config" exista y esté activo.',
                    { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                );
            }

            if (!config.width || !config.height || !config.margin) {
                throw new DomainException(
                    'La configuración del QR está incompleta. Se requieren: width, height, margin.',
                    { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                );
            }

            this.logger.debug(`Configuración QR cargada: ${JSON.stringify(config)}`);
            return config;
        } catch (error) {
            if (error instanceof DomainException) {
                throw error;
            }
            throw new DomainException(
                `Error al obtener la configuración del QR: ${getErrorMessage(error)}`,
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
            );
        }
    }

    private construirContenidoQR(trabajador: {
        nombres: string;
        paterno: string;
        materno: string | null;
        dni: string;
    }): string {
        const lines = [
            `DNI: ${trabajador.dni}`,
            `NOMBRES: ${trabajador.nombres}`,
            `PATERNO: ${trabajador.paterno}`,
        ];

        if (trabajador.materno) {
            lines.push(`MATERNO: ${trabajador.materno}`);
        }

        return lines.join('\n');
    }

    private async generarBufferQR(
        content: string,
        config: QRConfig
    ): Promise<Buffer> {
        try {
            return await QRCode.toBuffer(content, {
                width: config.width,
                margin: config.margin,
                color: {
                    dark: config.color_dark || '#000000',
                    light: config.color_light || '#FFFFFF',
                },
                errorCorrectionLevel: config.error_correction_level || 'M',
                type: config.format || 'png',
            });
        } catch (error) {
            throw new DomainException(
                `Error al generar el código QR: ${getErrorMessage(error)}`,
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
            );
        }
    }

    private async guardarArchivoQR(buffer: Buffer, fileName: string): Promise<void> {
        try {
            await fs.mkdir(this.uploadDir, { recursive: true });

            const filePath = path.join(this.uploadDir, fileName);
            await fs.writeFile(filePath, buffer);

            this.logger.debug(`Archivo QR guardado: ${filePath}`);
        } catch (error) {
            throw new DomainException(
                `Error al guardar el archivo QR: ${getErrorMessage(error)}`,
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
            );
        }
    }

    async eliminarQRFisico(fileName: string): Promise<void> {
        if (!fileName || fileName === '') {
            return;
        }

        try {
            const filePath = path.join(this.uploadDir, fileName);
            await fs.unlink(filePath);
            this.logger.debug(`Archivo QR eliminado: ${filePath}`);
        } catch (error) {
            this.logger.warn(`No se pudo eliminar el archivo QR: ${getErrorMessage(error)}`);
        }
    }

    async regenerarQR(
        trabajadorId: number,
        manager?: EntityManager,
    ): Promise<string> {
        const trabajador = await this.obtenerTrabajadorActivo(trabajadorId, manager);

        if (trabajador.qr && trabajador.qr !== '') {
            await this.eliminarQRFisico(trabajador.qr);
        }

        return this.generarQRParaTrabajador(trabajadorId, true, manager);
    }
}
