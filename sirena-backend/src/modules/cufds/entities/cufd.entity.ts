// C:\sirena\sirena-backend\src\modules\cufds\entities\cufd.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'cufd' })
@Check('chk_cufd_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_cufd_codigocufd_notempty', "TRIM(codigo_cufd) <> ''")
@Check('chk_cufd_codigocontrol_notempty', "TRIM(codigo_control) <> ''")
@Check('chk_cufd_fechavigencia', 'fecha_vigencia > CURRENT_TIMESTAMP')
@Index('uix_cufd_varios_unique', ['sucursal_id', 'punto_venta_id'], { unique: true, where: 'estado_id = 1000' })
@Index('idx_cufd_puntoventaid', ['punto_venta_id'])
export class Cufd extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'cufd_id', type: 'bigint' })
    cufd_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'punto_venta_id', type: 'bigint', nullable: false, default: 1 })
    punto_venta_id!: number;

    @Column({ name: 'codigo_cufd', type: 'varchar', length: 500, nullable: false })
    codigo_cufd!: string;

    @Column({ name: 'codigo_control', type: 'varchar', length: 100, nullable: false })
    codigo_control!: string;

    @Column({ name: 'fecha_vigencia', type: 'timestamptz', nullable: false })
    fecha_vigencia!: Date;
}
