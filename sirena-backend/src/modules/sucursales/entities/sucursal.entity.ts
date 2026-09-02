// C:\sirena\sirena-backend\src\modules\sucursales\entities\sucursal.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'sucursales' })
@Check('chk_sucursales_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_sucursales_codigosin', 'codigo_sin >= 0')
@Check('chk_sucursales_sucursal_notempty', "TRIM(sucursal) <> ''")
@Check('chk_sucursales_sucursallargo_notempty', "TRIM(sucursal_largo) <> ''")
@Check('chk_sucursales_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_sucursales_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_sucursales_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_sucursales_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Check('chk_sucursales_factorventa', 'factor_venta > 1')
@Check('chk_sucursales_factorfacturacion', 'factor_facturacion > 1')
@Index('uix_sucursales_empresaid_sucursal_unique', ['empresa_id', 'sucursal'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_sucursales_empresaid_sucursallargo_unique', ['empresa_id', 'sucursal_largo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_sucursales_empresaid_codigo_unique', ['empresa_id', 'codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_sucursales_empresaid_codigosin_unique', ['empresa_id', 'codigo_sin'], { unique: true, where: 'estado_id = 1000' })
export class Sucursal extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'sucursal_id', type: 'bigint' })
    sucursal_id!: number;

    @Column({ name: 'empresa_id', type: 'bigint', nullable: false, default: 1 })
    empresa_id!: number;

    @Column({ name: 'sucursal', type: 'varchar', length: 150, nullable: false })
    sucursal!: string;

    @Column({ name: 'sucursal_largo', type: 'varchar', length: 300, nullable: false })
    sucursal_largo!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 30, nullable: false })
    codigo!: string;

    @Column({ name: 'codigo_sin', type: 'integer', nullable: false })
    codigo_sin!: number;

    @Column({ name: 'telefono', type: 'varchar', length: 100, nullable: true })
    telefono?: string | null;

    @Column({ name: 'ubicacion', type: 'varchar', length: 500, nullable: true })
    ubicacion?: string | null;

    @Column({ name: 'horario_atencion', type: 'varchar', length: 200, nullable: true })
    horario_atencion?: string | null;

    @Column({ name: 'factor_venta', type: 'decimal', precision: 12, scale: 2, nullable: false, default: 1.50 })
    factor_venta!: number;

    @Column({ name: 'factor_facturacion', type: 'decimal', precision: 12, scale: 2, nullable: false, default: 1.19 })
    factor_facturacion!: number;
}
