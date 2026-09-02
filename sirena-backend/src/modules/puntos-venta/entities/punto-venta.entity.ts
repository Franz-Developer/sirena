// C:\sirena\sirena-backend\src\modules\puntos-venta\entities\punto-venta.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'puntos_venta' })
@Check('chk_puntosventa_tipopuntoventaid', 'tipo_punto_venta_id IN (3950, 3951)')
@Check('chk_puntosventa_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_puntosventa_codigopuntoventa', 'codigo >= 0')
@Check('chk_puntosventa_longitud', 'LENGTH(TRIM(UPPER(nombre))) > 3')
@Index('uix_puntosventa_sucursalid_puntoventaid_unique', ['sucursal_id', 'punto_venta_id'], { unique: true })
@Index('uix_puntosventa_codigo_unique', ['sucursal_id', 'codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_puntosventa_nombre_unique', ['sucursal_id', 'nombre'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class PuntoVenta extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'punto_venta_id', type: 'bigint' })
    punto_venta_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'codigo', type: 'integer', nullable: false })
    codigo!: number;

    @Column({ name: 'nombre', type: 'varchar', length: 500, nullable: false })
    nombre!: string;

    @Column({ name: 'tipo_punto_venta_id', type: 'smallint', nullable: false, default: 3950 })
    tipo_punto_venta_id!: number;
}
