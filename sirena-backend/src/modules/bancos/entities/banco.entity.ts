// C:\sirena\sirena-backend\src\modules\bancos\entities\banco.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'bancos' })
@Check('chk_bancos_banco_minlength', 'LENGTH(TRIM(banco)) >= 3')
@Check('chk_bancos_abreviatura_minlength', 'LENGTH(TRIM(abreviatura)) >= 2')
@Check('chk_bancos_codigoasfi_numerico', "codigo_asfi ~ '^[0-9]{2}$'")
@Check('chk_bancos_banco_mayusculas', "banco = UPPER(banco)")
@Check('chk_bancos_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Index('uix_bancos_codigoasfi_unique', ['codigo_asfi'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_bancos_abreviatura_unique', ['abreviatura'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('uix_bancos_banco_unique', ['banco'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class Banco extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'banco_id', type: 'bigint' })
    banco_id!: number;

    @Column({ name: 'banco', type: 'varchar', length: 60, nullable: false })
    banco!: string;

    @Column({ name: 'codigo_asfi', type: 'char', length: 2, nullable: false })
    codigo_asfi!: string;

    @Column({ name: 'abreviatura', type: 'varchar', length: 20, nullable: false })
    abreviatura!: string;

    @Column({ name: 'descripcion', type: 'varchar', length: 255, nullable: true })
    descripcion: string | null = null;
}
