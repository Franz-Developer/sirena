// C:\sirena\sirena-backend\src\scripts\generar-llaves.ts
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import { Logger } from '@nestjs/common';

function generarLlaves(): void {
    const logger = new Logger('GenerarLlaves');
    const dir = path.join(process.cwd(), 'src/config/certs');

    logger.log(`Generando llaves en: ${dir}`);

    const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: {
            type: 'spki',
            format: 'pem',
        },
        privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem',
        },
    });

    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(path.join(dir, 'prisma-private.pem'), privateKey);
    fs.writeFileSync(path.join(dir, 'prisma-public.pem'), publicKey);

    logger.log('==========================================================');
    logger.log('✅ Llaves RSA de 2048 bits generadas con éxito');
    logger.log('📂 Ubicación: src/config/certs/');
    logger.log('==========================================================');
}

generarLlaves();
