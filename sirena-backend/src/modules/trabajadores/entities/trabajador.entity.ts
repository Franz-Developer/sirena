// C:\sirena\sirena-backend\src\modules\trabajadores\entities\trabajador.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'trabajadores' })
@Check('chk_trabajadores_generoid', 'genero_id IN (1200, 1201)')
@Check('chk_trabajadores_estadocivil', `
    (genero_id = 1200 AND estado_civil_id IN (1250, 1251, 1252, 1253, 1254)) OR
    (genero_id = 1201 AND estado_civil_id IN (1300, 1301, 1302, 1303, 1304))
`)
@Check('chk_trabajadores_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_trabajadores_nombres_notempty', "TRIM(nombres) <> ''")
@Check('chk_trabajadores_nombres_minlength', 'LENGTH(TRIM(nombres)) >= 3')
@Check('chk_trabajadores_paterno_notempty', "TRIM(paterno) <> ''")
@Check('chk_trabajadores_paterno_minlength', 'LENGTH(TRIM(paterno)) >= 3')
@Check('chk_trabajadores_materno_notempty', "materno IS NULL OR TRIM(materno) <> ''")
@Check('chk_trabajadores_materno_minlength', 'materno IS NULL OR LENGTH(TRIM(materno)) >= 3')
@Check('chk_trabajadores_nombres_mayus', 'nombres = UPPER(nombres)')
@Check('chk_trabajadores_paterno_mayus', 'paterno = UPPER(paterno)')
@Check('chk_trabajadores_materno_mayus', 'materno IS NULL OR materno = UPPER(materno)')
@Check('chk_trabajadores_dni_notempty', "TRIM(dni) <> ''")
@Check('chk_trabajadores_dni_minlength', 'LENGTH(TRIM(dni)) >= 5')
@Check('chk_trabajadores_telefono_notempty', "telefono IS NULL OR TRIM(telefono) <> ''")
@Check('chk_trabajadores_direccion_notempty', "direccion IS NULL OR TRIM(direccion) <> ''")
@Check('chk_trabajadores_email_formato', "email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'")
@Check('chk_trabajadores_foto_notempty', "TRIM(foto) <> ''")
@Check('chk_trabajadores_fechanacimiento', 'fecha_nacimiento IS NULL OR fecha_nacimiento <= CURRENT_DATE')
@Check('chk_trabajadores_fechacontratacion', 'fecha_contratacion IS NULL OR fecha_contratacion <= CURRENT_DATE')
@Index('uix_trabajadores_dni_unique', ['dni'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_trabajadores_nombre_completo_unique', ['nombres', 'paterno', 'materno'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_trabajadores_trabajador_unique', ['trabajador_id', 'sucursal_id'], { unique: true, where: 'estado_id = 1000' })
@Index('idx_trabajadores_sucursal', ['sucursal_id'], { where: 'estado_id = 1000' })
export class Trabajador extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'trabajador_id', type: 'bigint' })
    trabajador_id!: number;

    @Column({ name: 'sucursal_id', type: 'bigint', nullable: false, default: 1 })
    sucursal_id!: number;

    @Column({ name: 'genero_id', type: 'smallint', nullable: false, default: 1200 })
    genero_id!: number;

    @Column({ name: 'estado_civil_id', type: 'smallint', nullable: false, default: 1250 })
    estado_civil_id!: number;

    @Column({ name: 'nombres', type: 'varchar', length: 150, nullable: false })
    nombres!: string;

    @Column({ name: 'paterno', type: 'varchar', length: 80, nullable: false })
    paterno!: string;

    @Column({ name: 'materno', type: 'varchar', length: 80, nullable: true })
    materno?: string | null;

    @Column({ name: 'dni', type: 'varchar', length: 20, nullable: false })
    dni!: string;

    @Column({ name: 'telefono', type: 'varchar', length: 100, nullable: true })
    telefono?: string | null;

    @Column({ name: 'direccion', type: 'varchar', length: 255, nullable: true })
    direccion?: string | null;

    @Column({ name: 'email', type: 'varchar', length: 100, nullable: true })
    email?: string | null;

    @Column({ name: 'fecha_nacimiento', type: 'date', nullable: true })
    fecha_nacimiento?: Date | null;

    @Column({ name: 'fecha_contratacion', type: 'date', nullable: true })
    fecha_contratacion?: Date | null;

    @Column({ name: 'foto', type: 'varchar', length: 255, nullable: false })
    foto!: string;

    @Column({ name: 'qr', type: 'varchar', length: 255, nullable: true })
    qr?: string | null;
}
