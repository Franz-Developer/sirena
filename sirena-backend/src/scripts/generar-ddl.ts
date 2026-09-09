// C:\sirena\sirena-backend\src\scripts\generar-ddl.ts
import * as fs from 'fs';
import * as path from 'path';
import { Client } from 'pg';
import { typeOrmConfig } from '../config/database.config';

async function obtenerDdlTabla(client: Client, tabla: string): Promise<string> {
    // 1. Obtener columnas
    const colQueryClean = `
        SELECT
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position;
    `;
    const colRes = await client.query(colQueryClean, [tabla]);

    if (colRes.rows.length === 0) {
        return `-- La tabla "${tabla}" no existe en la base de datos o no tiene columnas.\n\n`;
    }

    let ddl = `CREATE TABLE public.${tabla} (\n`;
    const definiciones: string[] = [];

    colRes.rows.forEach(col => {
        let tipo = col.data_type.toUpperCase();
        if (col.data_type === 'character varying' && col.character_maximum_length) {
            tipo = `VARCHAR(${col.character_maximum_length})`;
        } else if (col.data_type === 'character' && col.character_maximum_length) {
            tipo = `CHAR(${col.character_maximum_length})`;
        } else if (col.data_type === 'numeric' && col.numeric_precision !== null) {
            tipo = col.numeric_scale !== null
                ? `NUMERIC(${col.numeric_precision},${col.numeric_scale})`
                : `NUMERIC(${col.numeric_precision})`;
        }

        let def = `    ${col.column_name} ${tipo}`;

        if (col.column_default !== null) {
            def += ` DEFAULT ${col.column_default}`;
        }

        if (col.is_nullable === 'NO') {
            def += ` NOT NULL`;
        }

        definiciones.push(def);
    });

    // 2. Obtener Primary Keys
    const pkQuery = `
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'PRIMARY KEY'
            AND tc.table_schema = 'public'
            AND tc.table_name = $1;
    `;
    const pkRes = await client.query(pkQuery, [tabla]);
    if (pkRes.rows.length > 0) {
        const pkCols = pkRes.rows.map(r => r.column_name).join(', ');
        definiciones.push(`    PRIMARY KEY (${pkCols})`);
    }

    // 3. Obtener Foreign Keys
    const fkQuery = `
        SELECT
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            rc.update_rule,
            rc.delete_rule
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
            AND tc.table_name = $1;
    `;
    const fkRes = await client.query(fkQuery, [tabla]);
    fkRes.rows.forEach(fk => {
        let fkDef = `    FOREIGN KEY (${fk.column_name}) REFERENCES public.${fk.foreign_table_name}(${fk.foreign_column_name})`;
        if (fk.update_rule && fk.update_rule !== 'NO ACTION') fkDef += ` ON UPDATE ${fk.update_rule}`;
        if (fk.delete_rule && fk.delete_rule !== 'NO ACTION') fkDef += ` ON DELETE ${fk.delete_rule}`;
        definiciones.push(fkDef);
    });

    ddl += definiciones.join(',\n') + `\n);\n\n`;
    return ddl;
}

async function generarDdlScript() {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.error('Error: Debes proporcionar al menos el nombre de una tabla.');
        console.error('Ejemplo: npx ts-node src/scripts/generar-ddl.ts clientes sucursales');
        process.exit(1);
    }

    const dbConfig = typeOrmConfig as any;
    const client = new Client({
        host: dbConfig.host,
        port: dbConfig.port,
        user: dbConfig.username,
        password: dbConfig.password,
        database: dbConfig.database,
    });

    try {
        await client.connect();
        let outputContent = `-- DDL Generado automáticamente (${new Date().toLocaleString()})\n\n`;

        for (const tabla of args) {
            const nombreTabla = tabla.trim();
            if (!nombreTabla) continue;
            console.log(`Generando DDL para la tabla: ${nombreTabla}...`);
            const ddlTabla = await obtenerDdlTabla(client, nombreTabla);
            outputContent += ddlTabla;
        }

        const outputFilePath = path.resolve(process.cwd(), 'db/query/salida.sql');
        const outputDir = path.dirname(outputFilePath);

        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        fs.writeFileSync(outputFilePath, outputContent, 'utf8');
        console.log(`\n¡Éxito! DDL guardado correctamente en: ${outputFilePath}`);

    } catch (error: any) {
        console.error(`Error al generar DDL:\n${error.message}`);
        process.exit(1);
    } finally {
        await client.end();
    }
}

generarDdlScript();
