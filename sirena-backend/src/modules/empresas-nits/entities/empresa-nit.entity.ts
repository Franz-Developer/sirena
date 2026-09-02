// C:\sirena\sirena-backend\src\modules\empresas-nits\entities\empresa-nit.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'empresas_nits' })
@Check('chk_empresasnits_ambienteid', 'ambiente_id IN (2750, 2751)')
@Check('chk_empresasnits_modalidadfacturacionid', 'modalidad_facturacion_id IN (3900, 3901, 3902, 3903)')
@Check('chk_empresasnits_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_empresasnits_nit_numerico', "nit ~ '^[0-9]+$'")
@Check('chk_empresasnits_nit_notempty', "TRIM(nit) <> ''")
@Check('chk_empresasnits_nit_minlength', 'LENGTH(TRIM(nit)) >= 7')
@Check('chk_empresasnits_razonsocial_notempty', "TRIM(razon_social) <> ''")
@Check('chk_empresasnits_razonsocial_minlength', 'LENGTH(TRIM(razon_social)) >= 3')
@Check('chk_empresasnits_actividadeconomicaprincipal_notempty', "TRIM(actividad_economica_principal) <> ''")
@Check('chk_empresasnits_actividadeconomicaprincipal_minlength', 'LENGTH(TRIM(actividad_economica_principal)) >= 3')
@Check('chk_empresasnits_emailfiscal_formato', "email_fiscal ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'")
@Check('chk_empresasnits_emailfiscal_notempty', "TRIM(email_fiscal) <> ''")
@Check('chk_empresasnits_fechas', 'fecha_inicio_vigencia IS NULL OR fecha_fin_vigencia IS NULL OR fecha_inicio_vigencia <= fecha_fin_vigencia')
@Check('chk_empresasnits_etiqueta_notempty', "TRIM(etiqueta) <> ''")
@Check('chk_empresasnits_etiqueta_formato', "etiqueta ~ '^[A-Z_]+$'")
@Index('uix_empresasnits_nit_unique', ['nit', 'empresa_id', 'etiqueta'], { unique: true, where: 'estado_id IN (1000, 1002)' })

export class EmpresaNit extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'empresa_nit_id', type: 'bigint' })
    empresa_nit_id!: number;

    @Column({ name: 'empresa_id', type: 'bigint', nullable: false, default: 1 })
    empresa_id!: number;

    @Column({ name: 'ambiente_id', type: 'smallint', nullable: false, default: 2751 })
    ambiente_id!: number;

    @Column({ name: 'nit', type: 'varchar', length: 20, nullable: false })
    nit!: string;

    @Column({ name: 'razon_social', type: 'varchar', length: 500, nullable: false })
    razon_social!: string;

    @Column({ name: 'actividad_economica_principal', type: 'varchar', length: 2000, nullable: false })
    actividad_economica_principal!: string;

    @Column({ name: 'etiqueta', type: 'varchar', length: 30, nullable: false })
    etiqueta!: string;

    @Column({ name: 'modalidad_facturacion_id', type: 'smallint', nullable: false, default: 3900 })
    modalidad_facturacion_id!: number;

    @Column({ name: 'certificado_digital', type: 'varchar', length: 2000, nullable: true })
    certificado_digital?: string | null;

    @Column({ name: 'certificado_password', type: 'varchar', length: 500, nullable: true })
    certificado_password?: string | null;

    @Column({ name: 'token_siat', type: 'varchar', length: 2000, nullable: true })
    token_siat?: string | null;

    @Column({ name: 'fecha_inicio_vigencia', type: 'date', nullable: true })
    fecha_inicio_vigencia?: Date | null;

    @Column({ name: 'fecha_fin_vigencia', type: 'date', nullable: true })
    fecha_fin_vigencia?: Date | null;

    @Column({ name: 'email_fiscal', type: 'varchar', length: 200, nullable: false })
    email_fiscal!: string;
}
