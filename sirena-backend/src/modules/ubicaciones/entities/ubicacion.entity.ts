// C:\sirena\sirena-backend\src\modules\ubicaciones\entities\ubicacion.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'ubicaciones' })
@Check('chk_ubicaciones_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Check('chk_ubicaciones_codigo_notempty', "TRIM(codigo) <> ''")
@Check('chk_ubicaciones_codigo_minlength', 'LENGTH(TRIM(codigo)) >= 3')
@Check('chk_ubicaciones_codigo_mayusculas', 'codigo = UPPER(codigo)')
@Check('chk_ubicaciones_codigo_formato', "codigo ~ '^[A-Z0-9_-]+$'")
@Check('chk_ubicaciones_jerarquia_estructura', "jerarquia IS NULL OR (jsonb_typeof(jerarquia) = 'object' AND (jerarquia ? 'niveles' OR jerarquia ? 'camino'))")
@Index('uix_ubicaciones_varios_unique', ['almacen_id', 'codigo'], { unique: true, where: "estado_id IN (1000, 1002)" })
@Index('idx_ubicaciones_jerarquia', ['jerarquia'])
export class Ubicacion extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'ubicacion_id', type: 'bigint' })
    ubicacion_id!: number;

    @Column({ name: 'almacen_id', type: 'bigint', nullable: false, default: 1 })
    almacen_id!: number;

    @Column({ name: 'codigo', type: 'varchar', length: 60, nullable: false })
    codigo!: string;

    @Column({ name: 'jerarquia', type: 'jsonb', nullable: false, default: () => "'{}'::jsonb" })
    jerarquia!: Record<string, any>;

    @Column({ name: 'descripcion', type: 'varchar', length: 500, nullable: true })
    descripcion?: string;
}