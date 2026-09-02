// C:\sirena\sirena-backend\src\modules\unidades\entities\unidad.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'unidades' })
@Check('chk_unidades_unidad_minlength', 'LENGTH(TRIM(unidad)) >= 1')
@Check('chk_unidades_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 1')
@Check('chk_unidades_codigosin', 'codigo_sin >= 0')
@Check('chk_unidades_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Index('uix_unidades_codigo_unique', ['codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_unidades_unidad_unique', ['unidad'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class Unidad extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'unidad_id', type: 'bigint' })
    unidad_id!: number;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'codigo_sin', type: 'integer', nullable: false })
    codigo_sin!: number;

    @Column({ name: 'unidad', type: 'varchar', length: 100, nullable: false })
    unidad!: string;
}
