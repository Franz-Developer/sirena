// C:\sirena\sirena-backend\src\modules\cargos\entities\cargo.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'cargos' })
@Check('chk_cargos_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_cargos_cargo_notempty', "TRIM(cargo) <> ''")
@Check('chk_cargos_cargo_minlength', 'LENGTH(TRIM(cargo)) >= 3')
@Check('chk_cargos_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_cargos_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 2')
@Check('chk_cargos_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_cargos_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Check('chk_cargos_descripcion_notempty', "descripcion IS NULL OR TRIM(descripcion) <> ''")
@Index('uix_cargos_cargo_unique', ['cargo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_cargos_codigo_unique', ['codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class Cargo extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'cargo_id', type: 'bigint' })
    cargo_id!: number;

    @Column({ name: 'cargo', type: 'varchar', length: 100, nullable: false })
    cargo!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'descripcion', type: 'varchar', length: 255, nullable: true })
    descripcion?: string | null;
}
