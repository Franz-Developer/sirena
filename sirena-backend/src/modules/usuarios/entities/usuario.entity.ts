// C:\sirena\sirena-backend\src\modules\usuarios\entities\usuario.entity.ts
import { Entity, Column, Index, Check } from 'typeorm';
import { BaseAuditEntity } from '../../../common/base/base-audit.entity';

@Entity({ name: 'usuarios' })
@Check('chk_usuarios_estadoid', 'estado_id IN (1000, 1002)')
@Check('chk_usuarios_login_notempty', "TRIM(login) <> ''")
@Check('chk_usuarios_login_mayusculas', 'login = UPPER(login)')
@Check('chk_usuarios_login_minlength', 'LENGTH(TRIM(login)) >= 4')
@Check('chk_usuarios_login_formato', "login ~ '^[A-Z0-9._-]+$'")
@Check('chk_usuarios_contrasena_notempty', "TRIM(contrasena) <> ''")
@Check('chk_usuarios_avatar_notempty', "TRIM(avatar) <> ''")
@Index('uix_usuarios_login_unique', ['login'], { unique: true, where: 'estado_id IN (1000, 1002)' })
@Index('idx_usuarios_usuario_id_registro', ['usuario_id_registro'])
@Index('idx_usuarios_usuario_id_actualizacion', ['usuario_id_actualizacion'], { where: 'usuario_id_actualizacion IS NOT NULL' })
@Index('idx_usuarios_operacion_covering', ['usuario_id_registro', 'usuario_id_actualizacion', 'login'], { where: 'estado_id IN (1000, 1002)' })
@Index('idx_usuarios_trabajadorid', ['trabajador_id'])
@Index('idx_usuarios_rolid', ['rol_id'])
export class Usuario extends BaseAuditEntity {
    @Column({ name: 'usuario_id', type: 'bigint', primary: true, generated: 'increment' })
    usuario_id!: number;

    @Column({ name: 'trabajador_id', type: 'bigint', nullable: false, default: 1 })
    trabajador_id!: number;

    @Column({ name: 'rol_id', type: 'bigint', nullable: false, default: 1 })
    rol_id!: number;

    @Column({ name: 'login', type: 'varchar', length: 10, nullable: false })
    login!: string;

    @Column({ name: 'contrasena', type: 'varchar', length: 500, nullable: false })
    contrasena!: string;

    @Column({ name: 'avatar', type: 'varchar', length: 255, nullable: false })
    avatar!: string;
}
