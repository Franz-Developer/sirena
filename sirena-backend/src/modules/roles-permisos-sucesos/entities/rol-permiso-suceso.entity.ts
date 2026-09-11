// C:\sirena\sirena-backend\src\modules\roles-permisos-sucesos\entities\rol-permiso-suceso.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'roles_permisos_sucesos' })
@Check('chk_rps_estado', 'estado_id IN (1000, 1001)')
@Index('uix_rps_unique', ['rol_permiso_tabla_id', 'suceso_id'], { unique: true, where: "estado_id = 1000" })
export class RolPermisoSuceso extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'rol_permiso_suceso_id', type: 'bigint' })
    rol_permiso_suceso_id!: number;

    @Column({ name: 'rol_permiso_tabla_id', type: 'bigint', nullable: false, default: 1 })
    rol_permiso_tabla_id!: number;

    @Column({ name: 'suceso_id', type: 'int', nullable: false, default: 1 })
    suceso_id!: number;
}
