El uso de customWhere y customParams en async findAll<T>

Es para casos especiales 
// empresas-cuentas.service.ts
@Injectable()
export class EmpresasCuentasService extends BaseService {
    // ...

    /**
     * Calcula el próximo índice de parámetro disponible
     */
    private getNextParamIndex(queryDto: FindEmpresasCuentasQueryDto): number {
        let index = 0;
        
        // 1. Estados (siempre hay al menos 1)
        const estados = queryDto.estado_id !== undefined ? [queryDto.estado_id] : ESTADOS_CONSULTA;
        index += estados.length;
        
        // 2. fechaInicioGestion (siempre 1)
        index += 1;
        
        // 3. configuracionFiltros (si hay)
        if (this.config.configuracionFiltros && this.config.configuracionFiltros.length > 0) {
            const filtrosActivos = this.config.configuracionFiltros.filter(
                f => queryDto[f.nombreCampo] !== undefined && queryDto[f.nombreCampo] !== null
            );
            index += filtrosActivos.length;
        }
        
        // 4. usuario_id (si está definido)
        if (queryDto.usuario_id !== undefined) {
            index += 1;
        }
        
        // 5. búsqueda q (si hay)
        if (queryDto.q?.trim()) {
            const words = queryDto.q.trim().split(/\s+/).filter(Boolean);
            index += queryDto.exactMatch === 1 ? 1 : words.length;
        }
        
        // +1 porque el próximo índice es el siguiente
        return index + 1;
    }

    /**
     * Obtiene cuentas por rango de fechas
     */
    async findCuentasByFechaRango(
        queryDto: FindEmpresasCuentasQueryDto,
        usuarioId: number,
        fechaInicio: Date,
        fechaFin: Date
    ): Promise<PaginatedResult<EmpresaCuentaResponseDto>> {
        const nextIdx = this.getNextParamIndex(queryDto);
        
        const customWhere = `t.fecha_registro >= $${nextIdx} AND t.fecha_registro <= $${nextIdx + 1}`;
        const customParams = [fechaInicio, fechaFin];
        
        return this.findAll(queryDto, usuarioId, customWhere, customParams);
    }

    /**
     * Obtiene cuentas con múltiples filtros
     */
    async findCuentasComplejas(
        queryDto: FindEmpresasCuentasQueryDto,
        usuarioId: number,
        empresaId: number,
        bancoId: number,
        fechaInicio?: Date,
        fechaFin?: Date
    ): Promise<PaginatedResult<EmpresaCuentaResponseDto>> {
        const nextIdx = this.getNextParamIndex(queryDto);
        let idx = nextIdx;
        
        let customWhere = `t.empresa_id = $${idx}`;
        const customParams: any[] = [empresaId];
        idx++;
        
        customWhere += ` AND t.banco_id = $${idx}`;
        customParams.push(bancoId);
        idx++;
        
        if (fechaInicio && fechaFin) {
            customWhere += ` AND t.fecha_registro BETWEEN $${idx} AND $${idx + 1}`;
            customParams.push(fechaInicio, fechaFin);
            idx += 2;
        }
        
        return this.findAll(queryDto, usuarioId, customWhere, customParams);
    }
}
        
// find-empresas-cuentas-query.dto.ts
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { IsOptional, IsInt, IsIn, IsString, IsDate, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ESTADOS_CONSULTA, ESTADOS_VIVOS } from '../../../common/constants/estados.constant';

export class FindEmpresasCuentasQueryDto extends BasePaginationQueryDto {
    @IsOptional()
    @IsString({ message: 'El parámetro q debe ser un texto.' })
    q?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo exactMatch debe ser un número entero.' })
    @IsIn([0, 1], { message: 'El campo exactMatch debe ser 0 (flexible) o 1 (exacta).' })
    exactMatch: number = 0;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'empresa_id debe ser un número entero.' })
    @Min(1, { message: 'empresa_id debe ser mayor a 0.' })
    empresa_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'banco_id debe ser un número entero.' })
    @Min(1, { message: 'banco_id debe ser mayor a 0.' })
    banco_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_moneda_id debe ser un número entero.' })
    tipo_moneda_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'tipo_cuenta_id debe ser un número entero.' })
    tipo_cuenta_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'usuario_id debe ser un número entero.' })
    @Min(1, { message: 'usuario_id debe ser mayor a 0.' })
    usuario_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: `estado_id debe ser uno de: ${ESTADOS_CONSULTA.join(', ')}`
    })
    estado_id?: number;

    // 📌 CAMPOS PARA CUSTOMWHERE (filtros excepcionales)
    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_desde debe ser una fecha válida.' })
    fecha_desde?: Date;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_hasta debe ser una fecha válida.' })
    fecha_hasta?: Date;

    getEstados(): number[] {
        if (this.estado_id !== undefined) {
            return [this.estado_id];
        }
        return [...ESTADOS_VIVOS];
    }

    static getCampos(): string[] {
        const alias = 't';
        return [
            `${alias}.empresa_cuenta_id`,
            `${alias}.empresa_id`,
            `${alias}.banco_id`,
            `${alias}.tipo_moneda_id`,
            `${alias}.nro_cuenta`,
            `${alias}.tipo_cuenta_id`,
            `${alias}.titular`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`
        ];
    }

    static getCamposParaQ(): string[] {
        return [`t.nro_cuenta`, `t.titular`];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'empresa_cuenta_id',
            'empresa_id',
            'banco_id',
            'nro_cuenta',
            'titular',
            'fecha_registro'
        ];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        return {
            'empresa_cuenta_id': `${alias}.empresa_cuenta_id`,
            'empresa_id': `${alias}.empresa_id`,
            'banco_id': `${alias}.banco_id`,
            'nro_cuenta': `${alias}.nro_cuenta`,
            'titular': `${alias}.titular`,
            'fecha_registro': `${alias}.fecha_registro`,
        };
    }
}

export { PaginatedResult };

// empresas-cuentas.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DomainException } from '../../common/exceptions/domain.exception';
import { DataSource } from 'typeorm';
import { EmpresaCuenta } from './entities/empresa-cuenta.entity';
import { CreateEmpresaCuentaDto } from './dto/create-empresa-cuenta.dto';
import { UpdateEmpresaCuentaDto } from './dto/update-empresa-cuenta.dto';
import { FindEmpresasCuentasQueryDto } from './dto/find-empresas-cuentas-query.dto';
import { ESTADO_ACTIVO, ESTADOS_CONSULTA, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { EmpresaCuentaResponseDto } from './dto/empresa-cuenta-response.dto';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { BaseService, BaseServiceConfig, PaginatedResult } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';

@Injectable()
export class EmpresasCuentasService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'empresas_cuentas',
        campoPK: 'empresa_cuenta_id',
        alias: 't',
        responseDto: EmpresaCuentaResponseDto,
        camposBusquedaEnQ: FindEmpresasCuentasQueryDto.getCamposParaQ(),
        tablasDependientes: [],
        joins: [
            {
                table: 'empresas',
                alias: 'e',
                onCondition: 'e.empresa_id = t.empresa_id',
                selectColumns: [
                    'e.empresa AS empresa_nombre',
                    'e.codigo AS empresa_codigo'
                ],
                type: 'INNER'
            },
            {
                table: 'bancos',
                alias: 'b',
                onCondition: 'b.banco_id = t.banco_id',
                selectColumns: [
                    'b.banco AS banco_nombre',
                    'b.codigo_asfi AS banco_codigo_asfi',
                    'b.abreviatura AS banco_abreviatura'
                ],
                type: 'INNER'
            }
        ],
        // ✅ Filtros comunes (siempre disponibles)
        configuracionFiltros: [
            {
                nombreCampo: 'empresa_id',
                nombreColumna: 'empresa_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'banco_id',
                nombreColumna: 'banco_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_moneda_id',
                nombreColumna: 'tipo_moneda_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_cuenta_id',
                nombreColumna: 'tipo_cuenta_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'empresa_cuenta_id',
            camposPermitidosParaOrdenar: FindEmpresasCuentasQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindEmpresasCuentasQueryDto.getEquivalenciasMapeo(),
        },
    };

    constructor(
        @InjectDataSource()
        dataSource: DataSource,
        override readonly tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    // ============================================
    // 📌 MÉTODO AUXILIAR PARA CALCULAR ÍNDICES
    // ============================================

    /**
     * Calcula el próximo índice de parámetro disponible para customWhere
     * 
     * Orden de parámetros en buildBaseWhereClause:
     * 1. Estados (1 o más)
     * 2. fechaInicioGestion (1)
     * 3. configuracionFiltros (0 o más)
     * 4. usuario_id (0 o 1)
     * 5. búsqueda q (0 o más palabras)
     */
    private getNextParamIndex(queryDto: FindEmpresasCuentasQueryDto): number {
        let index = 0;
        
        // 1. Estados (siempre hay al menos 1)
        const estados = queryDto.estado_id !== undefined ? [queryDto.estado_id] : ESTADOS_CONSULTA;
        index += estados.length;
        
        // 2. fechaInicioGestion (siempre 1)
        index += 1;
        
        // 3. configuracionFiltros (filtros activos)
        if (this.config.configuracionFiltros && this.config.configuracionFiltros.length > 0) {
            const filtrosActivos = this.config.configuracionFiltros.filter(
                f => queryDto[f.nombreCampo] !== undefined && queryDto[f.nombreCampo] !== null
            );
            index += filtrosActivos.length;
        }
        
        // 4. usuario_id (si está definido)
        if (queryDto.usuario_id !== undefined) {
            index += 1;
        }
        
        // 5. búsqueda q (si hay)
        if (queryDto.q?.trim()) {
            const words = queryDto.q.trim().split(/\s+/).filter(Boolean);
            index += queryDto.exactMatch === 1 ? 1 : words.length;
        }
        
        // +1 porque el próximo índice es el siguiente
        return index + 1;
    }

    // ============================================
    // 📌 CRUD PRINCIPAL
    // ============================================

    async create(dto: CreateEmpresaCuentaDto, usuarioId: number): Promise<EmpresaCuentaResponseDto> {
        // ... (código existente)
    }

    async update(id: number, dto: UpdateEmpresaCuentaDto, usuarioId: number): Promise<EmpresaCuentaResponseDto> {
        // ... (código existente)
    }

    // ============================================
    // 📌 MÉTODOS CON CUSTOMWHERE (CASOS ESPECIALES)
    // ============================================

    /**
     * Obtiene cuentas bancarias por rango de fechas
     * 📌 Caso especial: filtro por fecha que no está en configuracionFiltros
     */
    async findCuentasByFechaRango(
        queryDto: FindEmpresasCuentasQueryDto,
        usuarioId: number,
        fechaInicio: Date,
        fechaFin: Date
    ): Promise<PaginatedResult<EmpresaCuentaResponseDto>> {
        const nextIdx = this.getNextParamIndex(queryDto);
        
        const customWhere = `t.fecha_registro >= $${nextIdx} AND t.fecha_registro <= $${nextIdx + 1}`;
        const customParams = [fechaInicio, fechaFin];
        
        return this.findAll(queryDto, usuarioId, customWhere, customParams);
    }

    /**
     * Obtiene cuentas con múltiples filtros complejos
     * 📌 Caso especial: combinación de filtros que no están en configuracionFiltros
     */
    async findCuentasComplejas(
        queryDto: FindEmpresasCuentasQueryDto,
        usuarioId: number,
        empresaId: number,
        bancoId: number,
        fechaInicio?: Date,
        fechaFin?: Date
    ): Promise<PaginatedResult<EmpresaCuentaResponseDto>> {
        const nextIdx = this.getNextParamIndex(queryDto);
        let idx = nextIdx;
        
        let customWhere = `t.empresa_id = $${idx}`;
        const customParams: any[] = [empresaId];
        idx++;
        
        customWhere += ` AND t.banco_id = $${idx}`;
        customParams.push(bancoId);
        idx++;
        
        if (fechaInicio && fechaFin) {
            customWhere += ` AND t.fecha_registro BETWEEN $${idx} AND $${idx + 1}`;
            customParams.push(fechaInicio, fechaFin);
            idx += 2;
        }
        
        return this.findAll(queryDto, usuarioId, customWhere, customParams);
    }

    /**
     * Obtiene cuentas que tienen saldo mayor al promedio
     * 📌 Caso especial: subconsulta compleja
     */
    async findCuentasConSaldoSuperiorAlPromedio(
        queryDto: FindEmpresasCuentasQueryDto,
        usuarioId: number
    ): Promise<PaginatedResult<EmpresaCuentaResponseDto>> {
        const nextIdx = this.getNextParamIndex(queryDto);
        
        const customWhere = `
            t.empresa_cuenta_id IN (
                SELECT empresa_cuenta_id 
                FROM saldos 
                WHERE saldo > (SELECT AVG(saldo) FROM saldos)
            )
        `;
        
        return this.findAll(queryDto, usuarioId, customWhere);
    }
}
		
		// empresas-cuentas.controller.ts
@Controller('empresas-cuentas')
export class EmpresasCuentasController {
    constructor(private readonly service: EmpresasCuentasService) {}

    // ✅ Uso normal: filtros de configuracionFiltros
    @Get()
    findAll(@Query() queryDto: FindEmpresasCuentasQueryDto, @GetUser() user: AuthenticatedUser) {
        return this.service.findAll(queryDto, user.usuario_id);
    }

    // ✅ Uso con customWhere: rango de fechas
    @Get('reporte-fechas')
    findCuentasByFechaRango(
        @Query() queryDto: FindEmpresasCuentasQueryDto,
        @Query('fechaInicio') fechaInicio: string,
        @Query('fechaFin') fechaFin: string,
        @GetUser() user: AuthenticatedUser
    ) {
        return this.service.findCuentasByFechaRango(
            queryDto,
            user.usuario_id,
            new Date(fechaInicio),
            new Date(fechaFin)
        );
    }

    // ✅ Uso con customWhere: filtros complejos
    @Get('reporte-complejo')
    findCuentasComplejas(
        @Query() queryDto: FindEmpresasCuentasQueryDto,
        @Query('empresaId') empresaId: number,
        @Query('bancoId') bancoId: number,
        @Query('fechaInicio') fechaInicio?: string,
        @Query('fechaFin') fechaFin?: string,
        @GetUser() user: AuthenticatedUser
    ) {
        return this.service.findCuentasComplejas(
            queryDto,
            user.usuario_id,
            empresaId,
            bancoId,
            fechaInicio ? new Date(fechaInicio) : undefined,
            fechaFin ? new Date(fechaFin) : undefined
        );
    }
}