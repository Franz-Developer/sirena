// C:\sirena\sirena-backend\src\scripts\query.ts
import * as fs from 'fs';
import * as path from 'path';
import { Client, QueryResult } from 'pg';
import { typeOrmConfig } from '../config/database.config';
import { formatLocalDate } from '../common/utils/date-formatter.util';

function formatAsciiTable(rows: any[]): string {
    if (!rows || rows.length === 0) return "No hay resultados\n";

    const timestampFields = ['fecha_registro', 'fecha_actualizacion', 'fecha_baja'];

    const processedRows = rows.map(row => {
        const newRow = { ...row };

        Object.keys(newRow).forEach(col => {
            if (newRow[col] === null || newRow[col] === undefined) {
                newRow[col] = 'NULL';
            } else if (typeof newRow[col] === 'object') {
                if (!(newRow[col] instanceof Date)) {
                    newRow[col] = JSON.stringify(newRow[col]);
                }
            }
        });

        timestampFields.forEach(field => {
            if (field in newRow && newRow[field] !== 'NULL') {
                const formatted = formatLocalDate(newRow[field]);
                if (formatted) {
                    newRow[field] = formatted;
                }
            }
        });

        return newRow;
    });

    const columns = Object.keys(processedRows[0]);
    const colWidths: Record<string, number> = {};

    columns.forEach(col => {
        const lengths = processedRows.map(row => String(row[col] ?? '').length);
        const maxDataWidth = Math.max(col.length, ...lengths);
        colWidths[col] = maxDataWidth + 1;
    });

    const separatorLine = columns.map(col => '-'.repeat(colWidths[col]!)).join('+');
    const headerLine = columns.map(col => col.padEnd(colWidths[col]!)).join('|');

    let result = `--- Resultado (SELECT command) ---\n`;
    result += separatorLine + '\n' + headerLine + '\n' + separatorLine + '\n';

    processedRows.forEach(row => {
        const rowLine = columns.map(col => String(row[col] ?? '').padEnd(colWidths[col]!)).join('|');
        result += rowLine + '\n';
    });

    result += separatorLine + `\nTotal de filas: ${processedRows.length}\n\n\n`;
    return result;
}

async function ejecutarConsultaSql() {
    const sqlFilePath = path.resolve(process.cwd(), 'db/query/consulta.sql');
    const outputFilePath = path.resolve(process.cwd(), 'db/query/salida.sql');

    if (!fs.existsSync(sqlFilePath)) {
        console.error(`Error: El archivo ${sqlFilePath} no existe.`);
        process.exit(1);
    }

    const rawSqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    const sqlQuery = rawSqlContent
        .split('\n')
        .filter(line => !line.trim().startsWith('//'))
        .join('\n')
        .trim();

    if (!sqlQuery) {
        console.error(`Error: El archivo ${sqlFilePath} está vacío o solo contiene comentarios.`);
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
        const result: QueryResult | QueryResult[] = await client.query(sqlQuery);

        let outputContent = "";
        const resultsArray = Array.isArray(result) ? result : [result];

        resultsArray.forEach((res, index) => {
            const header = `--- Resultado #${index + 1} (${res.command} command) ---\n`;

            if (res.rows && res.rows.length > 0) {
                if (res.command === 'SELECT') {
                    outputContent += formatAsciiTable(res.rows);
                } else {
                    outputContent += header + JSON.stringify(res.rows, null, 2) + `\nFilas afectadas: ${res.rowCount ?? 0}\n`;
                }
            } else {
                outputContent += header + `Estado: OK\nFilas afectadas: ${res.rowCount ?? 0}\n`;
                if (res.command === 'INSERT') {
                    const tableMatch = sqlQuery.match(/INSERT\s+INTO\s+([^\s(]+)/i);
                    const tableName = tableMatch ? tableMatch[1] : 'tabla_desconocida';
                    outputContent += `Tabla: ${tableName}\n`;
                }
            }
        });

        const outputDir = path.dirname(outputFilePath);
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        // Se sobrescribe el archivo con la nueva ejecución (limpiando el contenido anterior) y se imprime en consola
        //const timestampHeader = `========================================\nEjecución: ${new Date().toLocaleString()}\n========================================\n\n`;
        const finalOutput = outputContent;

        fs.writeFileSync(outputFilePath, finalOutput, 'utf8');
        //console.log(finalOutput);
    } catch (error: any) {
        const errorMsg = `Error en SQL:\n${error.message}\nPosición: ${error.position ?? 'N/A'}\nCódigo: ${error.code ?? 'N/A'}`;
        console.error(`\n${errorMsg}`);

        const errorDir = path.resolve(process.cwd(), 'db/query');
        if (!fs.existsSync(errorDir)) {
            fs.mkdirSync(errorDir, { recursive: true });
        }

        const errorFilePath = path.resolve(errorDir, 'error.log');
        fs.writeFileSync(errorFilePath, `[${new Date().toISOString()}] ${errorMsg}\n\nSQL:\n${sqlQuery}`, 'utf8');
        console.log(`Error guardado en: ${errorFilePath}`);

        process.exit(1);
    } finally {
        await client.end();
    }
}

ejecutarConsultaSql();
