// C:\sirena\sirena-backend\src\modules\almacenes\entities\almacen.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'almacenes' })
@Check('chk_almacenes_tipoalmacenid', `
    tipo_almacen_id IN (1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712)
    AND (
        (tipo_operacion_almacen_id = 4050 AND tipo_almacen_id IN (1704, 1709, 1710, 1711, 1712))
        OR
        (tipo_operacion_almacen_id = 4051 AND tipo_almacen_id IN (1700, 1701, 1702, 1703, 1705, 1706, 1707, 1708))
    )
`)
@Check('chk_almacenes_tipooperacionalmacenid', 'tipo_operacion_almacen_id IN (4050, 4051)')
@Check('chk_almacenes_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_almacenes_almacen_notempty', "TRIM(almacen) <> ''")
@Check('chk_almacenes_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_almacenes_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_almacenes_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_almacenes_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Index('uix_almacenes_sucursalid_almacenid_unique', ['sucursal_id', 'almacen_id'], { unique: true })
@Index('uix_almacenes_sucursalid_almacen_unique', ['sucursal_id', 'almacen'], { unique: true, where: "estado_id IN (1000, 1002)" })
@Index('uix_almacenes_sucursalid_codigo_unique', ['sucursal_id', 'codigo'], { unique: true, where: "estado_id IN (1000, 1002)" })
export class Almacen extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'almacen_id', type: 'bigint' })
    almacen_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'almacen', type: 'varchar', length: 200, nullable: false })
    almacen!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'tipo_almacen_id', type: 'smallint', nullable: false, default: 1700 })
    tipo_almacen_id!: number;

    @Column({ name: 'tipo_operacion_almacen_id', type: 'smallint', nullable: false, default: 4050 })
    tipo_operacion_almacen_id!: number;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string | null;
}
