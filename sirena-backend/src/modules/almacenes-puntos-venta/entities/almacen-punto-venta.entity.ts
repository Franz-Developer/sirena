// C:\sirena\sirena-backend\src\modules\almacenes-puntos-venta\entities\almacen-punto-venta.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'almacenes_puntos_venta' })
@Check('chk_almacenespuntosventa_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_almacenespuntosventa_esprincipal', 'es_principal IN (0, 1)')
@Check('chk_almacenespuntosventa_prioridad', 'prioridad > 0')
@Index('uix_almacenespuntosventa_varios_unique', ['sucursal_id', 'almacen_id', 'punto_venta_id'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_almacenespuntosventa_puntoventaid_unique', ['punto_venta_id'], { unique: true, where: 'es_principal = 1 AND estado_id IN (1000, 1002)' })
@Index('idx_almacenespuntosventa_sucursal_almacen', ['sucursal_id', 'almacen_id'])
export class AlmacenPuntoVenta extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'almacen_punto_venta_id', type: 'bigint' })
    almacen_punto_venta_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'almacen_id', type: 'bigint', nullable: false, default: 1 })
    almacen_id!: number;

    @Column({ name: 'punto_venta_id', type: 'bigint', nullable: false, default: 1 })
    punto_venta_id!: number;

    @Column({ name: 'prioridad', type: 'smallint', nullable: false, default: 1 })
    prioridad!: number;

    @Column({ name: 'es_principal', type: 'smallint', nullable: false, default: 0 })
    es_principal!: number;
}
