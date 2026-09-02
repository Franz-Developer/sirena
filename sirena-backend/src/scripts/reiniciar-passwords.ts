// C:\sirena\sirena-backend\src\scripts\reiniciar-passwords.ts
// C:\sirena\sirena-backend\src\scripts\reiniciar-passwords.ts
import { join } from 'path';
import * as bcrypt from 'bcrypt';
import { config } from 'dotenv';
import { DataSource } from 'typeorm';


config({ path: join(process.cwd(), '.env') });

const SALT_ROUNDS = 12;
const BATCH_SIZE = 10;
const NUEVA_CONTRASENA = '12345678';

function getHashRounds(hash: string | undefined): number | null {
    if (!hash) return null;
    const match = hash.match(/^\$2[aby]\$(\d{2})\$/);
    if (!match || !match[1]) return null;
    return parseInt(match[1], 10);
}

async function generateSecureHash(password: string): Promise<string> {
    return bcrypt.hash(password, SALT_ROUNDS);
}

async function ejecutarActualizacion(): Promise<void> {
    console.log('============================================================');
    console.log('    SCRIPT - REINICIAR CONTRASEÑAS A 12345678 (ACTIVOS)      ');
    console.log('============================================================\n');

    const dbHost = process.env['DB_HOST'] || 'localhost';
    const dbPort = parseInt(process.env['DB_PORT'] || '5432', 10);
    const dbUser = process.env['DB_USERNAME'] || process.env['DB_USER'] || 'postgres';
    const dbPassword = process.env['DB_PASSWORD'] || '';
    const dbName = process.env['DB_DATABASE'] || process.env['DB_NAME'] || 'dbsirena';

    console.log(`🔗 Conectando a: ${dbHost}:${dbPort}/${dbName}`);
    console.log(`🔑 Nueva contraseña: "${NUEVA_CONTRASENA}" (salt rounds: ${SALT_ROUNDS})`);

    const dataSource = new DataSource({
        type: 'postgres',
        host: dbHost,
        port: dbPort,
        username: dbUser,
        password: dbPassword,
        database: dbName,
        synchronize: false,
        logging: false,
        poolSize: 5,
        extra: {
            connectionTimeoutMillis: 10000,
        },
    });

    try {
        await dataSource.initialize();
        console.log('✅ Conexión establecida correctamente.\n');
    } catch (error) {
        console.error('❌ Error al conectar a la base de datos:');
        console.error(error instanceof Error ? error.message : String(error));
        process.exit(1);
    }

    console.log('🔍 Obteniendo usuarios activos...');
    const usuarios = await dataSource.query(
        `SELECT usuario_id, login FROM usuarios WHERE estado_id = 1000 ORDER BY usuario_id`
    );

    if (usuarios.length === 0) {
        console.log('❌ No hay usuarios activos para actualizar.');
        await dataSource.destroy();
        process.exit(0);
    }

    console.log(`📊 Total usuarios activos a actualizar: ${usuarios.length}`);

    console.log('\n🔐 Generando hash para la nueva contraseña...');
    const hashNuevo = await generateSecureHash(NUEVA_CONTRASENA);
    console.log(`✅ Hash generado correctamente.\n`);

    console.log('🚀 Actualizando contraseñas...\n');

    let actualizados = 0;
    const startTime = Date.now();

    for (let i = 0; i < usuarios.length; i += BATCH_SIZE) {
        const lote = usuarios.slice(i, i + BATCH_SIZE);
        const numLote = Math.floor(i / BATCH_SIZE) + 1;
        const totalLotes = Math.ceil(usuarios.length / BATCH_SIZE);

        console.log(`📦 Lote ${numLote}/${totalLotes} (Usuarios ${i + 1} al ${Math.min(i + BATCH_SIZE, usuarios.length)})...`);

        for (const user of lote) {
            try {
                await dataSource.query(
                    `UPDATE usuarios
                     SET contrasena = $1,
                         fecha_actualizacion = CURRENT_TIMESTAMP,
                         usuario_id_actualizacion = 1
                     WHERE usuario_id = $2`,
                    [hashNuevo, user.usuario_id]
                );

                actualizados++;
                console.log(`   ✔ ${user.login} (ID: ${user.usuario_id}) - actualizado`);

            } catch (error) {
                console.log(`   ❌ ${user.login} (ID: ${user.usuario_id}) - ERROR: ${error instanceof Error ? error.message : String(error)}`);
            }
        }

        if (i + BATCH_SIZE < usuarios.length) {
            await new Promise(resolve => setTimeout(resolve, 100));
        }
    }

    const elapsedTime = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n============================================================');
    console.log('📊 RESUMEN DE ACTUALIZACIÓN:');
    console.log(`    ✅ Usuarios actualizados: ${actualizados}`);
    console.log(`    ⏱️  Tiempo total: ${elapsedTime}s`);
    console.log(`    🔑 Nueva contraseña: "${NUEVA_CONTRASENA}"`);
    console.log('============================================================\n');

    console.log('🔍 Verificando resultados...\n');

    const verifyUsuarios = await dataSource.query(
        `SELECT usuario_id, login, contrasena FROM usuarios WHERE estado_id = 1000 ORDER BY usuario_id`
    );

    let todosSeguros = true;
    console.log('ID   | Login      | Rounds | Estado');
    console.log('-----|------------|--------|------------------------');

    for (const user of verifyUsuarios) {
        const rounds = getHashRounds(user.contrasena);
        const isSecure = rounds !== null && rounds >= 12;
        const estado = isSecure ? '✅ Seguro' : rounds !== null ? `⚠️ ${rounds} rounds` : '❌ Inválido';
        if (!isSecure) todosSeguros = false;
        console.log(`${String(user.usuario_id).padEnd(5)}| ${user.login.padEnd(12)}| ${String(rounds ?? '?').padEnd(8)}| ${estado}`);
    }

    console.log('============================================================\n');

    if (todosSeguros) {
        console.log(`🎉 ¡TODOS los usuarios activos tienen contraseña "${NUEVA_CONTRASENA}" con salt rounds ${SALT_ROUNDS}!`);
    } else {
        console.log('⚠️ Algunos usuarios aún tienen hashes inseguros. Revisa el listado.');
    }

    await dataSource.destroy();
    console.log('🔌 Conexión con la base de datos cerrada.');
    console.log('\n✅ Script finalizado.');
}

ejecutarActualizacion().catch((error) => {
    console.error('❌ Error fatal no controlado:');
    console.error(error);
    process.exit(1);
});
