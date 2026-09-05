// C:\sirena\sirena-backend\src\modules\clientes\entities\cliente.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'clientes' })
@Check('chk_clientes_tipoclienteid', 'tipo_cliente_id IN (1150, 1151)')
@Check('chk_clientes_tipodocumentoid', 'tipo_documento_id IN (2200, 2201, 2202, 2203, 2204)')
@Check('chk_clientes_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_clientes_cliente_notempty', "TRIM(cliente) <> ''")
@Check('chk_clientes_cliente_minlength', 'LENGTH(TRIM(cliente)) >= 3')
@Check('chk_clientes_nit_notempty', "nit IS NULL OR TRIM(nit) <> ''")
@Check('chk_clientes_razonsocial_notempty', "razon_social IS NULL OR TRIM(razon_social) <> ''")
@Check('chk_clientes_documento_notempty', "TRIM(documento) <> ''")
@Check('chk_clientes_documento_minlength', 'LENGTH(TRIM(documento)) >= 1')
@Check('chk_clientes_documentocomplemento_notempty', "documento_complemento IS NULL OR TRIM(documento_complemento) <> ''")
@Check('chk_clientes_direccion_notempty', "direccion IS NULL OR TRIM(direccion) <> ''")
@Check('chk_clientes_telefono_notempty', "telefono IS NULL OR TRIM(telefono) <> ''")
@Check('chk_clientes_email_formato', "email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'")
@Check('chk_clientes_numerocuenta_notempty', "numero_cuenta IS NULL OR TRIM(numero_cuenta) <> ''")
@Check('chk_clientes_habilitadoventas', 'habilitado_ventas IN (0, 1)')
@Check('chk_clientes_limitecredito', 'limite_credito >= 0.00')
@Check('chk_clientes_coherencia', '(limite_credito = 0.00) OR (limite_credito > 0.00 AND habilitado_ventas = 1)')
@Index('uix_clientes_tipodocumentoid_documento_unique', ['tipo_documento_id', 'documento'], {
    unique: true,
    where: "estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NULL",
})
@Index('uix_clientes_varios_unique', ['tipo_documento_id', 'documento_complemento', 'documento'], {
    unique: true,
    where: "estado_id IN (1000, 1002) AND documento <> '0' AND documento_complemento IS NOT NULL",
})
@Index('idx_clientes_documento_cliente_busqueda', ['documento', 'cliente'], {
    where: 'estado_id IN (1000, 1002)',
})
@Index('idx_clientes_bancoid', ['banco_base_id'])
export class Cliente extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'cliente_id', type: 'bigint' })
    cliente_id!: number;

    @Column({ name: 'tipo_cliente_id', type: 'smallint', nullable: false, default: 1150 })
    tipo_cliente_id!: number;

    @Column({ name: 'cliente', type: 'varchar', length: 100, nullable: false })
    cliente!: string;

    @Column({ name: 'nit', type: 'varchar', length: 20, nullable: true })
    nit?: string | null;

    @Column({ name: 'razon_social', type: 'varchar', length: 150, nullable: true })
    razon_social?: string | null;

    @Column({ name: 'documento', type: 'varchar', length: 30, nullable: false })
    documento!: string;

    @Column({ name: 'documento_complemento', type: 'varchar', length: 10, nullable: true })
    documento_complemento?: string | null;

    @Column({ name: 'tipo_documento_id', type: 'smallint', nullable: false, default: 2200 })
    tipo_documento_id!: number;

    @Column({ name: 'direccion', type: 'varchar', length: 255, nullable: true })
    direccion?: string | null;

    @Column({ name: 'telefono', type: 'varchar', length: 100, nullable: true })
    telefono?: string | null;

    @Column({ name: 'email', type: 'varchar', length: 100, nullable: true })
    email?: string | null;

    @Column({ name: 'banco_base_id', type: 'bigint', nullable: false, default: 1 })
    banco_base_id!: number;

    @Column({ name: 'numero_cuenta', type: 'varchar', length: 50, nullable: true })
    numero_cuenta?: string | null;

    @Column({ name: 'habilitado_ventas', type: 'smallint', nullable: false, default: 1 })
    habilitado_ventas!: number;

    @Column({ name: 'limite_credito', type: 'decimal', precision: 12, scale: 2, nullable: false, default: 0.00 })
    limite_credito!: number;
}
