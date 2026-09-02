// C:\sirena\sirena-backend\src\modules\roles\entities\rol.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'roles' })
@Check('chk_roles_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_roles_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_roles_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_roles_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_roles_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Check('chk_roles_rol_not_empty', "TRIM(rol) <> ''")
@Check('chk_roles_rol_minlength', 'LENGTH(TRIM(rol)) >= 3')
@Check('chk_roles_rol_mayusculas', 'rol = UPPER(rol)')
@Check('chk_roles_descripcion_notempty', 'descripcion IS NULL OR TRIM(descripcion) <> \'\'')
@Index('uix_roles_codigo_unique', ['codigo'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_roles_rol_unique', ['rol'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class Rol extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'rol_id', type: 'bigint' })
    rol_id!: number;

    @Column({ name: 'rol', type: 'varchar', length: 60, nullable: false })
    rol!: string;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string;
}
