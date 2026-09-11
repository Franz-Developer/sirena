// C:\sirena\sirena-backend\src\modules\roles-permisos-tablas\entities\rol-permiso-tabla.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'roles_permisos_tablas' })
@Check('chk_rpt_estado', 'estado_id IN (1000, 1001)')
@Check('chk_rpt_leer', 'leer IN (0, 1)')
@Check('chk_rpt_crear', 'crear IN (0, 1)')
@Check('chk_rpt_editar', 'editar IN (0, 1)')
@Check('chk_rpt_eliminar', 'eliminar IN (0, 1)')
@Check('chk_rpt_anular', 'anular IN (0, 1)')
@Check('chk_rpt_archivar', 'archivar IN (0, 1)')
@Check('chk_rpt_desarchivar', 'desarchivar IN (0, 1)')
@Check('chk_rpt_no_vacio', 'leer = 1 OR crear = 1 OR editar = 1 OR eliminar = 1 OR anular = 1 OR archivar = 1 OR desarchivar = 1')
@Index('uix_rpt_unique', ['rol_id', 'tabla_id'], { unique: true, where: "estado_id = 1000" })
export class RolPermisoTabla extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'rol_permiso_tabla_id', type: 'bigint' })
    rol_permiso_tabla_id!: number;

    @Column({ name: 'rol_id', type: 'bigint', nullable: false, default: 1 })
    rol_id!: number;

    @Column({ name: 'tabla_id', type: 'bigint', nullable: false, default: 1 })
    tabla_id!: number;

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
}
