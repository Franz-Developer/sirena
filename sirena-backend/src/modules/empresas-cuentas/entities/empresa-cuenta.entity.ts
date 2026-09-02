// C:\sirena\sirena-backend\src\modules\empresas-cuentas\entities\empresa-cuenta.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'empresas_cuentas' })
@Check('chk_empresascuentas_tipomonedaid', 'tipo_moneda_id IN (2300, 2301, 2302, 2303)')
@Check('chk_empresascuentas_tipocuentaid', 'tipo_cuenta_id IN (1750, 1751, 1752, 1753, 1754, 1755)')
@Check('chk_empresascuentas_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_empresascuentas_nrocuenta_minlength', 'LENGTH(TRIM(nro_cuenta)) >= 5')
@Check('chk_empresascuentas_titular_notempty', "TRIM(titular) <> ''")
@Check('chk_empresascuentas_titular_minlength', 'LENGTH(TRIM(titular)) >= 3')
@Index('uix_empresascuentas_varios_unique', ['empresa_id', 'banco_id', 'nro_cuenta', 'tipo_moneda_id', 'tipo_cuenta_id'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class EmpresaCuenta extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'empresa_cuenta_id', type: 'bigint' })
    empresa_cuenta_id!: number;

    @Column({ name: 'empresa_id', type: 'bigint', nullable: false, default: 1 })
    empresa_id!: number;

    @Column({ name: 'banco_id', type: 'bigint', nullable: false, default: 1 })
    banco_id!: number;

    @Column({ name: 'tipo_moneda_id', type: 'smallint', nullable: false, default: 2300 })
    tipo_moneda_id!: number;

    @Column({ name: 'nro_cuenta', type: 'varchar', length: 50, nullable: false })
    nro_cuenta!: string;

    @Column({ name: 'tipo_cuenta_id', type: 'smallint', nullable: false, default: 1755 })
    tipo_cuenta_id!: number;

    @Column({ name: 'titular', type: 'varchar', length: 150, nullable: false })
    titular!: string;
}
