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
