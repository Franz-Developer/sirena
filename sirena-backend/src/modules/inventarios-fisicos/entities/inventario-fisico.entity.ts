// C:\sirena\sirena-backend\src\modules\inventarios-fisicos\entities\inventario-fisico.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'inventarios_fisicos' })
@Check('chk_inventariosfisicos_estadoid', 'estado_id IN (1000, 1001)')
@Check('chk_inventariosfisicos_observaciones_notempty', "observaciones IS NULL OR TRIM(observaciones) <> ''")
@Check('chk_inventariosfisicos_fechas', 'fecha_fin IS NULL OR fecha_fin >= fecha_inicio')
@Index('idx_inventariosfisicos_activo_unique', ['sucursal_id', 'ubicacion_id', 'fecha_conteo'], { unique: true, where: 'estado_id = 1000' })
@Index('idx_inventariosfisicos_trabajadorrespid', ['trabajador_responsable_id'])
@Index('idx_inventariosfisicos_trabajadorsupid', ['trabajador_supervisor_id'])
export class InventarioFisico extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'inventario_fisico_id', type: 'bigint' })
    inventario_fisico_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'ubicacion_id', type: 'bigint', nullable: false, default: 1 })
    ubicacion_id!: number;

    @Column({ name: 'fecha_conteo', type: 'date', nullable: false })
    fecha_conteo!: string;

    @Column({ name: 'fecha_inicio', type: 'timestamptz', nullable: false })
    fecha_inicio!: Date;

    @Column({ name: 'fecha_fin', type: 'timestamptz', nullable: true })
    fecha_fin!: Date | null;

    @Column({ name: 'trabajador_responsable_id', type: 'bigint', nullable: false, default: 1 })
    trabajador_responsable_id!: number;

    @Column({ name: 'trabajador_supervisor_id', type: 'bigint', nullable: false, default: 1 })
    trabajador_supervisor_id!: number;

    @Column({ name: 'observaciones', type: 'varchar', length: 500, nullable: true })
    observaciones!: string | null;
}
