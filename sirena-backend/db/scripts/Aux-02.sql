para la tabla sucesos 

CREATE TABLE sucesos (
    suceso_id INT PRIMARY KEY,
    tabla_id BIGINT NOT NULL,
    codigo VARCHAR(15) NOT NULL,
    suceso VARCHAR(30) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    estado_id SMALLINT NOT NULL DEFAULT 1000,			-- 1000=ACTIVO, 1001=BORRADO
    usuario_id_registro BIGINT NOT NULL DEFAULT 1,
    usuario_id_actualizacion BIGINT NULL,
    usuario_id_baja BIGINT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NULL,
    fecha_baja TIMESTAMPTZ NULL,
    CONSTRAINT fk_sucesos_tabla FOREIGN KEY (tabla_id) REFERENCES tablas(tabla_id),
    CONSTRAINT chk_suceso_estadoid CHECK (estado_id IN (1000, 1001)),
    CONSTRAINT chk_sucesos_codigo_notempty CHECK (TRIM(codigo) <> ''),
    CONSTRAINT chk_sucesos_codigo_minlength CHECK (LENGTH(TRIM(codigo)) >= 3),
    CONSTRAINT chk_sucesos_codigo_mayusculas CHECK (codigo = UPPER(codigo)),
    CONSTRAINT chk_sucesos_codigo_formato CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT chk_sucesos_suceso_not_empty CHECK (TRIM(suceso) <> ''),
    CONSTRAINT chk_sucesos_suceso_minlength CHECK (LENGTH(TRIM(suceso)) >= 3),
    CONSTRAINT chk_sucesos_suceso_mayusculas CHECK (suceso = UPPER(suceso)),
    CONSTRAINT chk_sucesos_descripcion_notempty CHECK (TRIM(descripcion) <> '')
);
CREATE UNIQUE INDEX uix_sucesos_codigo_unique ON sucesos (codigo) WHERE estado_id = 1000;
CREATE UNIQUE INDEX uix_sucesos_suceso_unique ON sucesos (suceso) WHERE estado_id = 1000;

COMMENT ON TABLE sucesos IS 'Reglas de la tabla - sucesos
R.0: La tabla sucesos define los nombres de los eventos.';

// C:\sirena\sirena-backend\src\common\constants\estados.constant.ts
// ==========================================
// INTERFAZ GENERAL PARA CONSTANTES PARAMÉTRICOS
// ==========================================
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




como sera 
C:\sirena\sirena-backend\src\modules\sucesos\dto\create-suceso.dto.ts
C:\sirena\sirena-backend\src\modules\sucesos\dto\update-suceso.dto.ts
C:\sirena\sirena-backend\src\modules\sucesos\entities\suceso.entity.ts
C:\sirena\sirena-backend\src\modules\sucesos\sucesos.module.ts

EJEMPLOS 
// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\dto\create-trabajador-cargo.dto.ts
import { Transform, Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, IsIn, Min, MaxLength, IsNumber, IsDate, } from 'class-validator';
import { IsSafeText } from '../../../common/decorators/safe-text.decorator';
import { TipoMoneda, TIPO_MONEDA_METADATA } from '../../../common/constants/estados.constant';
import { getEnumValues, createEnumMessage } from '../../../common/utils/validation-helper.util';

export class CreateTrabajadorCargoDto {
    @IsInt({ message: 'trabajador_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'trabajador_id es obligatorio.' })
    @Min(1, { message: 'trabajador_id debe ser mayor a 0.' })
    trabajador_id: number;

    @IsInt({ message: 'cargo_id debe ser un número entero.' })
    @IsNotEmpty({ message: 'cargo_id es obligatorio.' })
    @Min(1, { message: 'cargo_id debe ser mayor a 0.' })
    cargo_id: number;

    @IsNumber({ maxDecimalPlaces: 2 }, { message: 'sueldo_base debe ser un número con máximo 2 decimales.' })
    @IsNotEmpty({ message: 'sueldo_base es obligatorio.' })
    @Min(0, { message: 'sueldo_base no puede ser negativo.' })
    sueldo_base: number;

    @IsInt({ message: 'tipo_moneda_id debe ser un número entero.' })
    @IsIn(getEnumValues(TipoMoneda), {
        message: createEnumMessage(TIPO_MONEDA_METADATA, getEnumValues(TipoMoneda), 'tipo_moneda_id')
    })
    tipo_moneda_id: number;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_desde debe ser una fecha válida.' })
    fecha_desde?: Date;

    @IsOptional()
    @Type(() => Date)
    @IsDate({ message: 'fecha_hasta debe ser una fecha válida.' })
    fecha_hasta?: Date;

    @IsOptional()
    @IsInt({ message: 'es_activo debe ser un número entero.' })
    @IsIn([0, 1], { message: 'es_activo debe ser 0 (No) o 1 (Sí).' })
    es_activo?: number;

    @IsOptional()
    @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
    @IsString({ message: 'observaciones debe ser un texto.' })
    @MaxLength(500, { message: 'observaciones no puede exceder los 500 caracteres.' })
    @IsSafeText()
    observaciones?: string;
}

// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\dto\update-trabajador-cargo.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateTrabajadorCargoDto } from './create-trabajador-cargo.dto';

export class UpdateTrabajadorCargoDto extends PartialType(CreateTrabajadorCargoDto) {}

// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\entities\trabajador-cargo.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'trabajadores_cargos' })
@Check('chk_trabajadorescargos_tipomonedaid', 'tipo_moneda_id IN (2300, 2301, 2302, 2303)')
@Check('chk_trabajadorescargos_estadoid', 'estado_id IN (1000, 1001)')
@Check('chk_trabajadorescargos_sueldobase', 'sueldo_base >= 0')
@Check('chk_trabajadorescargos_esactivo', 'es_activo IN (0, 1)')
@Check('chk_trabajadorescargos_observaciones_notempty', "observaciones IS NULL OR TRIM(observaciones) <> ''")
@Check('chk_trabajadorescargos_fechas', 'fecha_hasta IS NULL OR fecha_hasta >= fecha_desde')
@Index('uix_trabajadorescargos_varios_unique', ['trabajador_id', 'cargo_id'], { unique: true, where: "es_activo = 1 AND estado_id = 1000" })
export class TrabajadorCargo extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'trabajador_cargo_id', type: 'bigint' })
    trabajador_cargo_id!: number;

    @Column({ name: 'trabajador_id', type: 'bigint', nullable: false, default: 1 })
    trabajador_id!: number;

    @Column({ name: 'cargo_id', type: 'bigint', nullable: false, default: 1 })
    cargo_id!: number;

    @Column({ name: 'sueldo_base', type: 'decimal', precision: 12, scale: 2, nullable: false, default: 0.00 })
    sueldo_base!: number;

    @Column({ name: 'tipo_moneda_id', type: 'smallint', nullable: false, default: 2300 })
    tipo_moneda_id!: number;

    @Column({ name: 'fecha_desde', type: 'date', nullable: false, default: () => 'CURRENT_DATE' })
    fecha_desde!: Date;

    @Column({ name: 'fecha_hasta', type: 'date', nullable: true })
    fecha_hasta?: Date | null;

    @Column({ name: 'es_activo', type: 'smallint', nullable: false, default: 1 })
    es_activo!: number;

    @Column({ name: 'observaciones', type: 'varchar', length: 500, nullable: true })
    observaciones?: string | null;
}

// C:\sirena\sirena-backend\src\modules\trabajadores-cargos\trabajadores-cargos.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrabajadoresCargosController } from './trabajadores-cargos.controller';
import { TrabajadoresCargosService } from './trabajadores-cargos.service';
import { TrabajadorCargo } from './entities/trabajador-cargo.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([TrabajadorCargo]),
        ConfigModule,
    ],
    controllers: [TrabajadoresCargosController],
    providers: [TrabajadoresCargosService],
    exports: [TrabajadoresCargosService],
})
export class TrabajadoresCargosModule {}
