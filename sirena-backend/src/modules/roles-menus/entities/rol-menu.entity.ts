// C:\sirena\sirena-backend\src\modules\roles-menus\entities\rol-menu.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'roles_menus' })
@Check('chk_rolesmenus_estadoid', 'estado_id IN (1000, 1001, 1002)')
@Index('uix_rolesmenus_varios_unique', ['rol_id', 'menu_id'], { unique: true, where: 'estado_id IN (1000, 1002)' })
export class RolMenu extends BaseAuditEntity {
    @PrimaryGeneratedColumn({ name: 'rol_menu_id', type: 'bigint' })
    rol_menu_id!: number;

    @Column({ name: 'rol_id', type: 'bigint', nullable: false, default: 1 })
    rol_id!: number;

    @Column({ name: 'menu_id', type: 'bigint', nullable: false, default: 1 })
    menu_id!: number;
}
