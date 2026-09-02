// C:\sirena\sirena-backend\src\common\utils\sql-logger.util.ts

const COLORS = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
    green: '\x1b[32m',
    greenBright: '\x1b[92m',
    yellow: '\x1b[33m',
    red: '\x1b[31m',
    magenta: '\x1b[35m',
    white: '\x1b[37m',
    whiteBright: '\x1b[97m',
    gray: '\x1b[90m',
};

export function formatSqlWithParams(query: string, params: any[]): string {
    if (!params || params.length === 0) {
        return query;
    }

    let formattedQuery = query;

    for (let i = params.length - 1; i >= 0; i--) {
        const param = params[i];
        let value: string;

        if (param === null) {
            value = 'NULL';
        } else if (typeof param === 'string') {
            value = `'${param.replace(/'/g, "''")}'`;
        } else if (param instanceof Date) {
            value = `'${param.toISOString()}'`;
        } else if (typeof param === 'boolean') {
            value = param ? 'true' : 'false';
        } else if (typeof param === 'object') {
            value = `'${JSON.stringify(param)}'`;
        } else {
            value = String(param);
        }

        formattedQuery = formattedQuery.replace(new RegExp(`\\$${i + 1}(?![0-9])`, 'g'), value);
    }

    return formattedQuery;
}

export function logSqlQuery(
    query: string,
    params: any[],
    label: string,
): void {
    if (process.env['NODE_ENV'] === 'development') {
        const fullSql = formatSqlWithParams(query, params);

        console.log(`${COLORS.blue}${'═'.repeat(80)}${COLORS.reset}`);
        console.log(`${COLORS.cyan}📝 ${label}`);
        console.log(`${COLORS.blue}${'═'.repeat(80)}${COLORS.reset}`);
        console.log(`${COLORS.greenBright}${fullSql}${COLORS.reset}`);
        console.log(`${COLORS.magenta}${'─'.repeat(80)}${COLORS.reset}`);
    }
}
