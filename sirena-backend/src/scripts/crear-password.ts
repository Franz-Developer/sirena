// C:\sirena\sirena-backend\src\scripts\crear-password.ts
import { Logger } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

const logger = new Logger('CrearPassword');

async function run(): Promise<void> {
    const plainPassword = process.argv[2];

    if (!plainPassword) {
        logger.error('Debes pasar la contraseña como argumento.');
        logger.error('Ejemplo: npm run hash:password miClave123');
        process.exit(1);
    }

    const saltRounds = 10;
    const salt = await bcrypt.genSalt(saltRounds);
    const hash = await bcrypt.hash(plainPassword, salt);

    logger.log('-------------------------------------------');
    logger.log(`✅ Contraseña original: ${plainPassword}`);
    logger.log(`🚀 Hash (${saltRounds} rounds): ${hash}`);
    logger.log('-------------------------------------------');
}

run().catch((err: unknown) => {
    const errMessage = err instanceof Error ? err.message : JSON.stringify(err);
    const errStack = err instanceof Error ? err.stack : undefined;
    logger.error(`Error al generar el hash: ${errMessage}`, errStack);
    process.exit(1);
});
