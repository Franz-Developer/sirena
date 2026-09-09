// C:\sirena\sirena-backend\src\modules\sucesos\entities\suceso.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'sucesos' })
@Check('chk_suceso_estadoid', 'estado_id IN (1000, 1001)')
@Check('chk_sucesos_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_sucesos_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_sucesos_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_sucesos_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Check('chk_sucesos_suceso_not_empty', "TRIM(suceso) <> ''")
@Check('chk_sucesos_suceso_minlength', 'LENGTH(TRIM(suceso)) >= 3')
@Check('chk_sucesos_suceso_mayusculas', 'suceso = UPPER(suceso)')
@Check('chk_sucesos_descripcion_notempty', "TRIM(descripcion) <> ''")
@Index('uix_sucesos_codigo_unique', ['codigo'], { unique: true, where: "estado_id = 1000" })
@Index('uix_sucesos_suceso_unique', ['suceso'], { unique: true, where: "estado_id = 1000" })
export class Suceso extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'suceso_id', type: 'int' })
    suceso_id!: number;

    @Column({ name: 'tabla_id', type: 'bigint', nullable: false, default: 1 })
    tabla_id!: number;

    @Column({ name: 'codigo', type: 'varchar', length: 15, nullable: false })
    codigo!: string;

    @Column({ name: 'suceso', type: 'varchar', length: 30, nullable: false })
    suceso!: string;

    @Column({ name: 'descripcion', type: 'varchar', length: 200, nullable: false })
    descripcion!: string;
}
