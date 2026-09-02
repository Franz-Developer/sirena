// C:\sirena\sirena-backend\src\scripts\generar-qr-todos.ts
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { GenerarQRUtil } from '../common/services/generar-qr.service';
import { DataSource } from 'typeorm';
import { Logger } from '@nestjs/common';

async function bootstrap() {
    const logger = new Logger('GenerarQRMavisoScript');

    try {
        const app = await NestFactory.createApplicationContext(AppModule, {
            logger: ['error', 'warn', 'log'],
        });

        const generarQRUtil = app.get(GenerarQRUtil);
        const dataSource = app.get(DataSource);

        logger.log('Buscando trabajadores activos sin QR...');

        // Obtener IDs de trabajadores activos (1000) sin QR
        const trabajadores = await dataSource.query(`
            SELECT trabajador_id
            FROM trabajadores
            WHERE (qr IS NULL OR qr = '')
              AND estado_id = 1000
            ORDER BY trabajador_id ASC
        `);

        if (trabajadores.length === 0) {
            logger.log('Todos los trabajadores activos ya tienen su QR.');
            await app.close();
            process.exit(0);
        }

        logger.log(`Se encontraron ${trabajadores.length} trabajadores. Iniciando generación...`);

        let generados = 0;
        for (const t of trabajadores) {
            try {
                await generarQRUtil.generarQRParaTrabajador(t.trabajador_id);
                generados++;
            } catch (error: any) {
                logger.error(`Error en ID ${t.trabajador_id}: ${error.message}`);
            }
        }

        console.log('\n' + '='.repeat(60));
        console.log(`✅ PROCESO MASIVO COMPLETADO: ${generados}/${trabajadores.length} QRs generados`);
        console.log('='.repeat(60) + '\n');

        await app.close();
        process.exit(0);
    } catch (error) {
        console.error('Error crítico en la ejecución masiva:', error);
        process.exit(1);
    }
}

bootstrap();
