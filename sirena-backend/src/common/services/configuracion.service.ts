// C:\sirena\sirena-backend\src\common\services\configuracion.service.ts
import { Injectable, Logger, Inject, OnModuleInit, HttpStatus } from '@nestjs/common';
import { IDataSource } from '../interfaces/repository.interface';
import { ESTADO_ACTIVO, TipoDato } from '../constants/estados.constant';
import { DomainException } from '../exceptions/domain.exception';

export interface ParametroGlobalConfig {
    parametro_id: number;
    clave: string;
    valor: string;
    tipo_dato_id: number;
    datos_json: any | null;
    editable: number;
}

@Injectable()
export class ConfiguracionService implements OnModuleInit {
    private readonly logger = new Logger(ConfiguracionService.name);
    private cacheParametros: Map<string, ParametroGlobalConfig> = new Map();
    private ultimaCargaTimestamp: number = 0;
    private readonly CACHE_TTL_MS: number;

    constructor(
        @Inject('IDataSource') private readonly dataSource: IDataSource,
    ) {
        this.CACHE_TTL_MS = parseInt(process.env['CONFIG_CACHE_TTL'] || '3600000', 10);
    }

    async onModuleInit(): Promise<void> {
        await this.cargarConfiguracionCompleta();
        this.logger.log('Configuración global cargada exitosamente');
    }

    private async cargarConfiguracionCompleta(): Promise<void> {
        const query = `
            SELECT parametro_id, clave, valor, tipo_dato_id, datos_json, editable
            FROM parametros_globales
            WHERE estado_id = $1
        `;
        const params = [ESTADO_ACTIVO];

        try {
            const resultados = await this.dataSource.query(query, params);

            this.cacheParametros.clear();
            if (Array.isArray(resultados)) {
                for (const row of resultados) {
                    this.cacheParametros.set(row.clave, {
                        parametro_id: Number(row.parametro_id),
                        clave: row.clave,
                        valor: row.valor,
                        tipo_dato_id: Number(row.tipo_dato_id),
                        datos_json: row.datos_json ?? null,
                        editable: Number(row.editable),
                    });
                }
            }
            this.ultimaCargaTimestamp = Date.now();
            this.logger.debug(`Se cargaron ${this.cacheParametros.size} parámetros globales en memoria.`);
        } catch (error) {
            this.logger.error(`Error al cargar configuración global: ${error}`);
            throw new DomainException(
                `Error crítico al cargar la configuración global desde la base de datos.`,
                { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
            );
        }
    }

    private async asegurarCacheVigente(): Promise<void> {
        const ahora = Date.now();
        if (ahora - this.ultimaCargaTimestamp > this.CACHE_TTL_MS || this.cacheParametros.size === 0) {
            await this.cargarConfiguracionCompleta();
        }
    }

    public async invalidarCache(): Promise<void> {
        this.logger.log('Invalidando caché de configuración global. Recargando...');
        await this.cargarConfiguracionCompleta();
    }

    async obtenerParametro(clave: string): Promise<ParametroGlobalConfig | null> {
        await this.asegurarCacheVigente();
        return this.cacheParametros.get(clave) || null;
    }

    async obtenerValorTipado<T = any>(clave: string): Promise<T | null> {
        const param = await this.obtenerParametro(clave);
        if (!param) return null;

        switch (param.tipo_dato_id) {
            case TipoDato.INTEGER:
                return parseInt(param.valor, 10) as unknown as T;
            case TipoDato.DECIMAL:
                return parseFloat(param.valor) as unknown as T;
            case TipoDato.BOOLEAN:
                return (param.valor === '1' || param.valor.toLowerCase() === 'true') as unknown as T;
            case TipoDato.TIMESTAMP:
                return new Date(param.valor) as unknown as T;
            case TipoDato.JSONB:
                return param.datos_json as T;
            case TipoDato.STRING:
            default:
                return param.valor as unknown as T;
        }
    }
}
