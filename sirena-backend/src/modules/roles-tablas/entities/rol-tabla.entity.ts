// C:\sirena\sirena-backend\src\modules\roles-tablas\entities\rol-tabla.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'roles_tablas' })
@Check('chk_rolestablas_estadoid', 'estado_id IN (1000, 1001)')
@Check('chk_rolestablas_leer', 'leer IN (0, 1)')
@Check('chk_rolestablas_crear', 'crear IN (0, 1)')
@Check('chk_rolestablas_editar', 'editar IN (0, 1)')
@Check('chk_rolestablas_eliminar', 'eliminar IN (0, 1)')
@Check('chk_rolestablas_anular', 'anular IN (0, 1)')
@Check('chk_rolestablas_archivar', 'archivar IN (0, 1)')
@Check('chk_rolestablas_desarchivar', 'desarchivar IN (0, 1)')
@Check('chk_rolestablas_tabla_notempty', "TRIM(tabla) <> ''")
@Check('chk_rolestablas_tabla_formato', "tabla = LOWER(TRIM(tabla)) AND tabla ~ '^[a-z][a-z0-9_]*$'")
@Check('chk_rolestablas_eventos_objeto', "jsonb_typeof(eventos_permitidos) = 'object'")
@Index('uix_rolestablas_activo', ['rol_id', 'tabla'], { unique: true, where: 'estado_id = 1000' })
@Index('idx_rolestablas_rol', ['rol_id'], { where: 'estado_id = 1000' })
export class RolTabla extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'rol_tabla_id', type: 'bigint' })
    rol_tabla_id!: number;

    @Column({ name: 'rol_id', type: 'bigint', nullable: false, default: 1 })
    rol_id!: number;

    @Column({ name: 'tabla', type: 'varchar', length: 100, nullable: false, default: '' })
    tabla!: string;

    @Column({ name: 'leer', type: 'smallint', nullable: false, default: 0 })
    leer!: number;

    @Column({ name: 'crear', type: 'smallint', nullable: false, default: 0 })
    crear!: number;

    @Column({ name: 'editar', type: 'smallint', nullable: false, default: 0 })
    editar!: number;

    @Column({ name: 'eliminar', type: 'smallint', nullable: false, default: 0 })
    eliminar!: number;

    @Column({ name: 'anular', type: 'smallint', nullable: false, default: 0 })
    anular!: number;

    @Column({ name: 'archivar', type: 'smallint', nullable: false, default: 0 })
    archivar!: number;

    @Column({ name: 'desarchivar', type: 'smallint', nullable: false, default: 0 })
    desarchivar!: number;

    @Column({ name: 'eventos_permitidos', type: 'jsonb', nullable: false, default: () => "'{}'::jsonb" })
    eventos_permitidos!: Record<string, any>;
}
