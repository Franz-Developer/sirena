// C:\sirena\sirena-backend\src\modules\parametros-globales\entities\parametro-global.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'parametros_globales' })
@Check('chk_parametrosglobales_tipodatoid', 'tipo_dato_id IN (1800, 1801, 1802, 1803, 1804, 1805)')
@Check('chk_parametrosglobales_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_parametrosglobales_clave', "TRIM(clave) = clave AND clave ~ '^[a-z0-9_-]+$' AND LENGTH(clave) >= 3")
@Check('chk_parametrosglobales_valor_notempty', "TRIM(valor) <> ''")
@Check('chk_parametrosglobales_descripcion', "descripcion IS NULL OR TRIM(descripcion) <> ''")
@Check('chk_parametrosglobales_editable', 'editable IN (0, 1)')
@Check('chk_parametrosglobales_jsonb_requerido', '(tipo_dato_id = 1805 AND datos_json IS NOT NULL) OR (tipo_dato_id <> 1805)')
@Index('uix_parametrosglobales_clave_unique', ['clave'], { unique: true, where: "estado_id IN (1000, 1002)" })
export class ParametroGlobal extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'parametro_id', type: 'bigint' })
    parametro_id!: number;

    @Column({ name: 'clave', type: 'varchar', length: 100, nullable: false })
    clave!: string;

    @Column({ name: 'valor', type: 'varchar', length: 500, nullable: false })
    valor!: string;

    @Column({ name: 'tipo_dato_id', type: 'smallint', nullable: false, default: 1800 })
    tipo_dato_id!: number;

    @Column({ name: 'datos_json', type: 'jsonb', nullable: true })
    datos_json?: any | null;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string | null;

    @Column({ name: 'editable', type: 'smallint', nullable: false, default: 1 })
    editable!: number;
}
