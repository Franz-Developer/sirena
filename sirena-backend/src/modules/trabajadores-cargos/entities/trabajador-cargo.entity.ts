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
