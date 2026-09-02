// C:\sirena\sirena-backend\src\modules\empresas\entities\empresa.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'empresas' })
@Check('chk_empresas_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_empresas_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_empresas_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_empresas_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_empresas_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Check('chk_empresas_empresa_notempty', "TRIM(empresa) <> ''")
@Check('chk_empresas_empresa_mayusculas', 'empresa = UPPER(empresa)')
@Check('chk_empresas_empresa_minlength', 'LENGTH(TRIM(empresa)) >= 3')
@Check('chk_empresas_email_formato', "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'")
@Check('chk_empresas_logo_notempty', "logo IS NULL OR TRIM(logo) <> ''")
@Check('chk_empresas_eslogan_notempty', "eslogan IS NULL OR TRIM(eslogan) <> ''")
@Check('chk_empresas_lugar_notempty', "lugar IS NULL OR TRIM(lugar) <> ''")
@Check('chk_empresas_representante_notempty', "representante IS NULL OR TRIM(representante) <> ''")
@Check('chk_empresas_direccion_notempty', "direccion IS NULL OR TRIM(direccion) <> ''")
@Check('chk_empresas_matricula_notempty', "matricula_comercio IS NULL OR TRIM(matricula_comercio) <> ''")
@Index('uix_empresas_empresa_unique', ['empresa'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_empresas_codigo_unique', ['codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_empresas_matriculacomercio_unique', ['matricula_comercio'], { unique: true, where: 'estado_id IN (1000, 1002)' })

export class Empresa extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'empresa_id', type: 'bigint' })
    empresa_id!: number;

    @Column({ name: 'empresa', type: 'varchar', length: 200, nullable: false })
    empresa!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 30, nullable: false })
    codigo!: string;

    @Column({ name: 'logo', type: 'varchar', length: 255, nullable: true })
    logo?: string;

    @Column({ name: 'eslogan', type: 'varchar', length: 150, nullable: true })
    eslogan?: string;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string;

    @Column({ name: 'lugar', type: 'varchar', length: 60, nullable: true })
    lugar?: string;

    @Column({ name: 'representante', type: 'varchar', length: 100, nullable: true })
    representante?: string;

    @Column({ name: 'direccion', type: 'varchar', length: 500, nullable: true })
    direccion?: string;

    @Column({ name: 'telefono', type: 'varchar', length: 100, nullable: true })
    telefono?: string;

    @Column({ name: 'email', type: 'varchar', length: 100, nullable: true })
    email?: string;

    @Column({ name: 'matricula_comercio', type: 'varchar', length: 50, nullable: false })
    matricula_comercio!: string;
}
