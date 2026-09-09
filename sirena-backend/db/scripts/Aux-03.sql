CREATE TABLE tablas (
    tabla_id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT chk_tablas_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_tablas_nombre_notempty CHECK (TRIM(nombre) <> ''),
    CONSTRAINT chk_tablas_nombre_formato CHECK (nombre = LOWER(TRIM(nombre)) AND nombre ~ '^[a-z][a-z0-9_]*$')
);
CREATE UNIQUE INDEX uix_tablas_nombre_unique ON tablas (nombre) WHERE estado_id = 1000;
CREATE INDEX idx_tablas_estado ON tablas (estado_id) WHERE estado_id = 1000;

COMMENT ON TABLE tablas IS 'Reglas de la tabla - tablas
R.0: La tabla tablas define los nombres de las tablas que pertenecen a la base de datos del sistema.';

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

// C:\sirena\sirena-backend\src\modules\tablas\dto\create-tabla.dto.ts
import { Transform } from 'class-transformer';
import { IsString, IsNotEmpty, MaxLength, MinLength, Matches } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';

export class CreateTablaDto {
    @Transform(({ value }) => typeof value === 'string' ? value.trim().toLowerCase() : value)
    @IsString({ message: 'nombre debe ser un texto.' })
    @IsNotEmpty({ message: 'nombre es obligatorio.' })
    @MinLength(1, { message: 'nombre debe tener al menos 1 carácter.' })
    @MaxLength(100, { message: 'nombre no puede exceder los 100 caracteres.' })
    @Matches(/^[a-z][a-z0-9_]*$/, { message: 'nombre debe comenzar con letra minúscula y contener solo letras minúsculas, números y guiones bajos.' })
    @IsSafeText()
    nombre: string;
}

// C:\sirena\sirena-backend\src\modules\tablas\dto\update-tabla.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateTablaDto } from './create-tabla.dto';

export class UpdateTablaDto extends PartialType(CreateTablaDto) {}

// C:\sirena\sirena-backend\src\modules\tablas\dto\find-tablas-query.dto.ts
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsIn, IsString } from 'class-validator';
import { ESTADO_METADATA, ESTADOS_CONSULTA } from '../../../common/constants/estados.constant';
import { BasePaginationQueryDto } from '../../../common/dto/base-pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/pagination.interface';
import { createEnumMessage } from '../../../common/utils/validation-helper.util';

export class FindTablasQueryDto extends BasePaginationQueryDto {
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

    static getCampos(): string[] {
        const alias = 't';
        return [
            `${alias}.tabla_id`,
            `${alias}.nombre`,
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
        return ['t.nombre'];
    }

    static getCamposPermitidosParaOrdenar(): string[] {
        return [
            'tabla_id',
            'nombre',
            'estado_id',
            'fecha_registro'
        ];
    }

    static getDependencias(): Array<string | { tabla: string; campoFk: string }> {
        return [
            { tabla: 'roles_permisos_tablas', campoFk: 'tabla_id' },
            { tabla: 'sucesos', campoFk: 'tabla_id' }
        ];
    }

    static getCamposProtegidosConDependencias(): string[] {
        return ['nombre'];
    }

    static getEquivalenciasMapeo(): Record<string, string> {
        const alias = 't';
        return {
            'tabla_id': `${alias}.tabla_id`,
            'nombre': `${alias}.nombre`,
            'estado_id': `${alias}.estado_id`,
            'usuario_id_registro': `${alias}.usuario_id_registro`,
            'usuario_id_actualizacion': `${alias}.usuario_id_actualizacion`,
            'usuario_id_baja': `${alias}.usuario_id_baja`,
            'fecha_registro': `${alias}.fecha_registro`,
            'fecha_actualizacion': `${alias}.fecha_actualizacion`,
            'fecha_baja': `${alias}.fecha_baja`
        };
    }
}

export { PaginatedResult };

// C:\sirena\sirena-backend\src\modules\tablas\dto\tabla-response.dto.ts
import { Expose, Transform } from 'class-transformer';
import { Estado, ESTADO_METADATA } from '../../../common/constants/estados.constant';
import { formatLocalDate } from '../../../common/utils/date-formatter.util';

const transformEstado = ({ obj }: { obj: TablaRawResult }) => {
    const estadoId = Number(obj.estado_id);
    const metadata = ESTADO_METADATA[estadoId as Estado];
    return metadata ? metadata.abreviatura : '';
};

export interface TablaRawResult {
    tabla_id: string | number;
    nombre: string;
    estado_id: string | number;
    estado_registro: string;
    usuario_operacion: string;
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

export class TablaResponseDto {
    @Expose()
    @Transform(({ value }) => Number(value))
    tabla_id!: number;

    @Expose()
    nombre!: string;

    @Expose()
    @Transform(({ value }) => Number(value))
    estado_id!: number;

    @Expose()
    @Transform(transformEstado)
    estado_registro!: string;

    @Expose()
    usuario_operacion!: string;

    @Expose()
    @Transform(({ value }) => Number(value))
    usuario_id_registro!: number;

    @Expose()
    @Transform(({ value }) => value ? Number(value) : null)
    usuario_id_actualizacion?: number | null;

    @Expose()
    @Transform(({ value }) => value ? Number(value) : null)
    usuario_id_baja?: number | null;

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

// C:\sirena\sirena-backend\src\modules\tablas\entities\tabla.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'tablas' })
@Check('chk_tablas_estadoid', 'estado_id IN (1000, 1001)')
@Check('chk_tablas_nombre_notempty', "TRIM(nombre) <> ''")
@Check('chk_tablas_nombre_formato', "nombre = LOWER(TRIM(nombre)) AND nombre ~ '^[a-z][a-z0-9_]*$'")
@Index('uix_tablas_nombre_unique', ['nombre'], { unique: true, where: 'estado_id = 1000' })
@Index('idx_tablas_estado', ['estado_id'], { where: 'estado_id = 1000' })
export class Tabla extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'tabla_id', type: 'bigint' })
    tabla_id!: number;

    @Column({ name: 'nombre', type: 'varchar', length: 100, nullable: false })
    nombre!: string;
}

// C:\sirena\sirena-backend\src\modules\tablas\tablas.controller.ts
import { Controller, Get, Post, Body, Patch, Param, Delete, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { InvalidateCache } from '../../common/decorators/invalidate-cache.decorator';
import { CreateRateLimit, UpdateRateLimit, DeleteRateLimit, FindAllRateLimit, FindOneRateLimit } from '../../common/decorators/rate-limit.decorator';
import { CustomValidationPipe } from '../../common/decorators/validation-message.decorator';
import { PaginatedResult } from '../../common/interfaces/pagination.interface';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TablasService } from './tablas.service';
import { CreateTablaDto } from './dto/create-tabla.dto';
import { FindTablasQueryDto } from './dto/find-tablas-query.dto';
import { TablaResponseDto } from './dto/tabla-response.dto';
import { UpdateTablaDto } from './dto/update-tabla.dto';

@UseGuards(JwtAuthGuard)
@Controller('tablas')
export class TablasController {
    constructor(
        private readonly tablasService: TablasService,
    ) {}

    @Get()
    @FindAllRateLimit()
    @Cache('tablas', CACHE_LARGO)
    findAll(
        @Query(CustomValidationPipe({ concise: true }))
        query: FindTablasQueryDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<PaginatedResult<TablaResponseDto>> {
        return this.tablasService.findAll(query, user.usuario_id);
    }

    @Get(':id')
    @FindOneRateLimit()
    @Cache('tablas', CACHE_LARGO)
    findOne(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.findOne(id, user.usuario_id);
    }

    @Post()
    @CreateRateLimit()
    @InvalidateCache('tablas')
    create(
        @Body() dto: CreateTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.create(dto, user.usuario_id);
    }

    @Patch(':id')
    @UpdateRateLimit()
    @InvalidateCache('tablas')
    update(
        @Param('id', ParseIntPipe) id: number,
        @Body() dto: UpdateTablaDto,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.update(id, dto, user.usuario_id);
    }

    @Delete(':id')
    @DeleteRateLimit()
    @InvalidateCache('tablas')
    remove(
        @Param('id', ParseIntPipe) id: number,
        @GetUser() user: AuthenticatedUser
    ): Promise<TablaResponseDto> {
        return this.tablasService.remove<TablaResponseDto>(id, user.usuario_id);
    }
}

ESTA BIEN 
