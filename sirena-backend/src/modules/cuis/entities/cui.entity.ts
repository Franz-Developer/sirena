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
