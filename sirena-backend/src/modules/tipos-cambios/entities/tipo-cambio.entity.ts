// C:\sirena\sirena-backend\src\modules\tipos-cambios\entities\tipo-cambio.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'tipos_cambios' })
@Check('chk_tiposcambios_origenmonedaid', 'origen_moneda_id IN (2300, 2301, 2302, 2303)')
@Check('chk_tiposcambios_destinomonedaid', 'destino_moneda_id IN (2300, 2301, 2302, 2303)')
@Check('chk_tiposcambios_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_tiposcambios_factorcompra', 'factor_compra > 0')
@Check('chk_tiposcambios_factorventa', 'factor_venta > 0')
@Check('chk_tiposcambios_factores', 'factor_compra <= factor_venta')
@Check('chk_tiposcambios_distinto', 'origen_moneda_id <> destino_moneda_id')
@Index('uix_tiposcambios_varios_unique', ['origen_moneda_id', 'destino_moneda_id', 'fecha_cotizacion'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class TipoCambio extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'tipo_cambio_id', type: 'bigint' })
    tipo_cambio_id!: number;

    @Column({ name: 'origen_moneda_id', type: 'smallint', nullable: false, default: 2300 })
    origen_moneda_id!: number;

    @Column({ name: 'destino_moneda_id', type: 'smallint', nullable: false, default: 2300 })
    destino_moneda_id!: number;

    @Column({ name: 'factor_compra', type: 'decimal', precision: 12, scale: 4, nullable: false, default: 1.0000 })
    factor_compra!: number;

    @Column({ name: 'factor_venta', type: 'decimal', precision: 12, scale: 4, nullable: false, default: 1.0000 })
    factor_venta!: number;

    @Column({ name: 'fecha_cotizacion', type: 'date', nullable: false })
    fecha_cotizacion!: Date;
}
