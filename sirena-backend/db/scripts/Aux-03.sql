CREATE TABLE cuis (
    cuis_id BIGSERIAL PRIMARY KEY,
    sucursal_id BIGINT NOT NULL DEFAULT 1,
    punto_venta_id BIGINT NOT NULL DEFAULT 1,
    codigo_cuis VARCHAR(100) NOT NULL,
    fecha_vigencia TIMESTAMPTZ NOT NULL,
	estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO, 1002=HISTORICO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_cuis_sucursal_id FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_cuis_punto_venta_id FOREIGN KEY (punto_venta_id) REFERENCES puntos_venta(punto_venta_id),
    CONSTRAINT chk_cuis_estadoid CHECK (estado_id IN (1000, 1001, 1002)),
    CONSTRAINT chk_cuis_codigo_notempty CHECK (TRIM(codigo_cuis) <> ''),
    CONSTRAINT chk_cuis_fechavigencia CHECK (fecha_vigencia > CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX uix_cuis_varios_unique ON cuis (sucursal_id, punto_venta_id) WHERE estado_id IN (1000, 1002);
CREATE INDEX idx_cuis_puntoventaid ON cuis(punto_venta_id);

// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts

export interface ConstanteMetadata {
    id: number;
    abreviatura: string;
    prefijo: string | null;
    valor: number;
    descripcion: string;
}

// ==========================================
// ESTADO
// ==========================================
export enum Estado {
    ACTIVO = 1000,
    BORRADO = 1001,
    HISTORICO = 1002,
    ANULADO = 1003,
}

export const ESTADO_ACTIVO = Estado.ACTIVO;
export const ESTADO_HISTORICO = Estado.HISTORICO;
export const ESTADO_BORRADO = Estado.BORRADO;
export const ESTADO_ANULADO = Estado.ANULADO;

export const ESTADOS_CONSULTA = [
    Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO,
	] as const;

export const ESTADOS_PERMITIDOS = [
    Estado.ACTIVO,
    Estado.BORRADO,
    Estado.HISTORICO,
    Estado.ANULADO,
] as const;

export const ESTADOS_VIVOS = [
    Estado.ACTIVO,
    Estado.HISTORICO
	] as const;

export const ESTADOS_VIVOS_ESPECIAL = [
Estado.ACTIVO,
    Estado.HISTORICO,
    Estado.ANULADO
] as const;

export const ESTADO_METADATA: Record<Estado, ConstanteMetadata & { es_defecto?: boolean }> = {
    [Estado.ACTIVO]: { id: Estado.ACTIVO, abreviatura: 'ACTIVO', prefijo: null, valor: 0, descripcion: 'Registro operativo y vigente. Habilitado en combos y reportes operativos. Permite modificaciones y transiciona a BORRADO, HISTORICO o ANULADO. CONSTANTE POR DEFECTO.', es_defecto: true },
    [Estado.BORRADO]: { id: Estado.BORRADO, abreviatura: 'BORRADO', prefijo: null, valor: 0, descripcion: 'Baja lógica definitiva e irreversible. Excluido de interfaces, reportes y cálculos. Requiere que sus dependencias estén borradas o históricas. Sin reactivación.' },
    [Estado.HISTORICO]: { id: Estado.HISTORICO, abreviatura: 'HISTORICO', prefijo: null, valor: 0, descripcion: 'Registro inmutable al finalizar su ciclo operativo. Excluido de selects para evitar nuevas transacciones pero incluido en históricos. Reversible a ACTIVO por administración.' },
    [Estado.ANULADO]: { id: Estado.ANULADO, abreviatura: 'ANULADO', prefijo: null, valor: 0, descripcion: 'Transacción abortada irreversible e inmutable. Uso exclusivo en las tablas kardex y control_facturas.' },
};
// C:\sirena\sirena-backend\src\modules\cuis\dto\create-cui.dto.ts
import { Transform } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, Min, MaxLength, IsDateString } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateCuiDto {
    @IsInt({ message: 'sucursal_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'sucursal_id es obligatorio.' })
    @Min(1, { message: 'sucursal_id debe ser mayor a 0.' })
    sucursal_id: number;

    @IsInt({ message: 'punto_venta_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'punto_venta_id es obligatorio.' })
    @Min(1, { message: 'punto_venta_id debe ser mayor a 0.' })
    punto_venta_id: number;

    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'codigo_cuis debe ser un texto.' })
    @IsNotEmpty({ message: 'codigo_cuis es obligatorio.' })
    @MaxLength(100, { message: 'codigo_cuis no puede exceder los 100 caracteres.' })
    @IsSafeText()
    codigo_cuis: string;

    @IsDateString({}, { message: 'fecha_vigencia debe ser una fecha y hora válida (ISO 8601).' })
    @IsNotEmpty({ message: 'fecha_vigencia es obligatoria.' })
    fecha_vigencia: string;
}

// C:\sirena\sirena-backend\src\modules\cuis\dto\update-cui.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateCuiDto } from './create-cui.dto';

export class UpdateCuiDto extends PartialType(CreateCuiDto) {}

// C:\sirena\sirena-backend\src\modules\cuis\dto\cui-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: CuiRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface CuiRawResult {
    cuis_id: string | number;
    sucursal_id: string | number;
    sucursal_nombre?: string;
    sucursal_codigo?: string;
    punto_venta_id: string | number;
    punto_venta_nombre?: string;
    punto_venta_codigo?: string | number;
    codigo_cuis: string;
    fecha_vigencia: string | Date;
    estado_id: string | number;
    estado_registro?: string;
    usuario_operacion?: string;
    usuario_id_registro: string | number;
    usuario_id_actualizacion?: string | number | null;
    usuario_id_baja?: string | number | null;
    fecha_registro: string | Date;
    fecha_actualizacion?: string | Date | null;
    fecha_baja?: string | Date | null;
    total_count?: string | number;
    tiene_dependencias?: boolean;
    campos_protegidos?: string[];
}

export class CuiResponseDto {
    @Expose() cuis_id!: number;
    @Expose() sucursal_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_nombre || null)
    sucursal_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.sucursal_codigo || null)
    sucursal_codigo!: string;

    @Expose() punto_venta_id!: number;

    @Expose()
    @Transform(({ obj }) => obj.punto_venta_nombre || null)
    punto_venta_nombre!: string;

    @Expose()
    @Transform(({ obj }) => obj.punto_venta_codigo !== undefined && obj.punto_venta_codigo !== null ? Number(obj.punto_venta_codigo) : null)
    punto_venta_codigo!: number;

    @Expose() codigo_cuis!: string;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_vigencia!: string | null;

    @Expose() estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_registro!: string;

    @Expose()
    usuario_operacion!: string;

    @Expose() usuario_id_registro!: number;
    @Expose() usuario_id_actualizacion?: number | null;
    @Expose() usuario_id_baja?: number | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_registro!: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_actualizacion?: string | null;

    @Expose()
    @Transform(({ value }) => formatLocalDate(value))
    fecha_baja?: string | null;

    @Expose()
    tiene_dependencias!: boolean;

    @Expose()
    campos_protegidos?: string[];
}

// C:\sirena\sirena-backend\src\modules\cuis\dto\find-cuis-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString, Min } from 'class-validator';
import { ESTADOS_CONSULTA, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindCuisQueryDto extends BasePaginationQueryDto {
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
    @IsInt({ message: 'usuario_id debe ser un número entero.' })
    usuario_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El estado_id debe ser un número entero.' })
    @IsIn(ESTADOS_CONSULTA, {
        message: createEnumMessage(ESTADO_METADATA, ESTADOS_CONSULTA, 'estado_id')
    })
    estado_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID de sucursal debe ser un número entero.' })
    @Min(1, { message: 'El ID de sucursal debe ser un número entero mayor o igual a 1.' })
    sucursal_id?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El ID de punto de venta debe ser un número entero.' })
    @Min(1, { message: 'El ID de punto de venta debe ser un número entero mayor o igual a 1.' })
    punto_venta_id?: number;

    // Todos los campos de la tabla principal (con soporte para joins a sucursales y puntos_venta).
    static getCampos(): string[] {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasPuntoVenta = 'pv';
        return [
            // Tabla principal.
            `${alias}.cuis_id`,
            `${alias}.sucursal_id`,
            `${alias}.punto_venta_id`,
            `${alias}.codigo_cuis`,
            `${alias}.fecha_vigencia`,
            `${alias}.estado_id`,
            `${alias}.usuario_id_registro`,
            `${alias}.usuario_id_actualizacion`,
            `${alias}.usuario_id_baja`,
            `${alias}.fecha_registro`,
            `${alias}.fecha_actualizacion`,
            `${alias}.fecha_baja`,

            // Campos de la tabla sucursales.
            `${aliasSucursal}.sucursal AS sucursal_nombre`,
            `${aliasSucursal}.codigo AS sucursal_codigo`,

            // Campos de la tabla puntos_venta.
            `${aliasPuntoVenta}.nombre AS punto_venta_nombre`,
            `${aliasPuntoVenta}.codigo AS punto_venta_codigo`
        ];
    }

    // Todos los campos que son VARCHAR o texto para la búsqueda global 'q'
    static getCamposParaQ(): string[] {
        return ['codigo_cuis', 's.sucursal', 's.codigo', 'pv.nombre'];
    }

    // Todos los campos de la tabla principal menos campos de auditoria aptos para ordenamiento.
    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            // Tabla principal.
            'cuis_id',
            'sucursal_id',
            'punto_venta_id',
            'codigo_cuis',
            'fecha_vigencia',

            // Tabla sucursales (JOIN).
            'sucursal_nombre',
            'sucursal_codigo',

            // Tabla puntos_venta (JOIN).
            'punto_venta_nombre',
            'punto_venta_codigo'
        ];
    }

    // Todas las dependencias.
    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [];
    }

    // Campos que no deben modificarse si la tabla tiene dependencias activas.
    static getCamposProtegidosConDependencias(): string[] {
        return [];
    }

    // Equivalencias de mapeo para consultas avanzadas y filtros.
    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        const aliasSucursal = 's';
        const aliasPuntoVenta = 'pv';
        return {
            // Tabla principal.
            'cuis_id': `${alias}.cuis_id`,
            'sucursal_id': `${alias}.sucursal_id`,
            'punto_venta_id': `${alias}.punto_venta_id`,
            'codigo_cuis': `${alias}.codigo_cuis`,
            'fecha_vigencia': `${alias}.fecha_vigencia`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`,

            // Tabla sucursales (JOIN).
            'sucursal_nombre': `${aliasSucursal}.sucursal`,
            'sucursal_codigo': `${aliasSucursal}.codigo`,

            // Tabla puntos_venta (JOIN).
            'punto_venta_nombre': `${aliasPuntoVenta}.nombre`,
            'punto_venta_codigo': `${aliasPuntoVenta}.codigo`,
        };
    }
}

export { PaginatedResult };

// C:\sirena\sirena-backend\src\modules\cuis\entities\cui.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'cuis' })
@Check('chk_cuis_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_cuis_codigo_notempty', "TRIM(codigo_cuis) <> ''")
@Index('uix_cuis_varios_unique', ['sucursal_id', 'punto_venta_id'], { unique: true, where: 'estado_id = 1000' })
@Index('idx_cuis_puntoventaid', ['punto_venta_id'])
export class Cui extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'cuis_id', type: 'bigint' })
    cuis_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'punto_venta_id', type: 'bigint', nullable: false, default: 1 })
    punto_venta_id!: number;

    @Column({ name: 'codigo_cuis', type: 'varchar', length: 100, nullable: false })
    codigo_cuis!: string;

    @Column({ name: 'fecha_vigencia', type: 'timestamptz', nullable: false })
    fecha_vigencia!: Date;
}

// C:\sirena\sirena-backend\src\modules\cuis\cuis.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, ArchiveRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateCuiDto } from './dto/create-cui.dto';
import { CuiResponseDto } from './dto/cui-response.dto';
import { FindCuisQueryDto } from './dto/find-cuis-query.dto';
import { UpdateCuiDto } from './dto/update-cui.dto';
import { CuisService } from './cuis.service';

@UseGuards(JwtAuthGuard)
@Controller('cuis')
export class CuisController {
    constructor(
        private readonly cuisService: CuisService,
    ) {}

    // GET /cuis - Listar códigos CUIS
    @Get()
    @FindAllRateLimit()
    @Cache('cuis', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindCuisQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<CuiResponseDto>> {
        return this.cuisService.findAll(query, user.usuario_id);
    }

    // GET /cuis/:id - Obtener un código CUIS por ID
    @Get(':id')
    @FindOneRateLimit()
    @Cache('cuis', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.findOne(id, user.usuario_id);
    }

    // POST /cuis - Crear código CUIS
    @Post()
    @CreateRateLimit()
    @InvalidateCache('cuis')
    create(
        @Body() dto: CreateCuiDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.create(dto, user.usuario_id);
    }

    // PATCH /cuis/:id - Actualizar código CUIS
    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('cuis')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateCuiDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.update(id, dto, user.usuario_id);
    }

    // DELETE /cuis/:id - Eliminar código CUIS (borrado lógico)
    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('cuis')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.remove<CuiResponseDto>(id, user.usuario_id);
    }

    // PATCH /cuis/:id/archivar - Archivar código CUIS (histórico)
    @Patch(':id/archivar')
    @ArchiveRateLimit()
    @InvalidateCache('cuis')
    archivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.archivar<CuiResponseDto>(id, user.usuario_id);
    }

    // PATCH /cuis/:id/desarchivar - Desarchivar código CUIS (activo)
    @Patch(':id/desarchivar')
    @ArchiveRateLimit()
    @InvalidateCache('cuis')
    desarchivar(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<CuiResponseDto> {
        return this.cuisService.desarchivar<CuiResponseDto>(id, user.usuario_id);
    }
}
