// C:\sirena\sirena-backend\src\common\base\base-audit.entity.ts
import { Column, BeforeUpdate } from 'typeorm';
import { HttpStatus } from '@nestjs/common';
import { ESTADO_ACTIVO, ESTADO_HISTORICO } from '../constants/estados.constant';
import { bigintTransformer } from '../utils/typeorm-transformers.util';
import { DomainException } from '../exceptions/domain.exception';

export abstract class BaseAuditEntity {
    @Column({
        name: 'estado_id',
        type: 'smallint',
        nullable: false,
        default: ESTADO_ACTIVO
    })
    estado_id: number;

    @Column({
        name: 'usuario_id_registro',
        type: 'bigint',
        nullable: false,
        default: 1,
        transformer: bigintTransformer
    })
    usuario_id_registro: number;

    @Column({
        name: 'usuario_id_actualizacion',
        type: 'bigint',
        nullable: true,
        transformer: bigintTransformer
    })
    usuario_id_actualizacion?: number | null;

    @Column({
        name: 'usuario_id_baja',
        type: 'bigint',
        nullable: true,
        transformer: bigintTransformer
    })
    usuario_id_baja?: number | null;

    @Column({
        name: 'fecha_registro',
        type: 'timestamptz',
        nullable: false,
        default: () => 'CURRENT_TIMESTAMP'
    })
    fecha_registro: Date;

    @Column({
        name: 'fecha_actualizacion',
        type: 'timestamptz',
        nullable: true
    })
    fecha_actualizacion?: Date | null;

    @Column({
        name: 'fecha_baja',
        type: 'timestamptz',
        nullable: true
    })
    fecha_baja?: Date | null;

    softDelete(usuarioId: number, estadoBorrado: number = ESTADO_HISTORICO): void {
        if (!usuarioId || usuarioId <= 0) {
            throw new DomainException(
                'Usuario ID inválido para realizar la baja',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (this.estado_id === ESTADO_HISTORICO) {
            throw new DomainException(
                'El registro ya está dado de baja',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        this.estado_id = estadoBorrado;
        this.usuario_id_baja = usuarioId;
    }

    update(usuarioId: number): void {
        if (!usuarioId || usuarioId <= 0) {
            throw new DomainException(
                'Usuario ID inválido para realizar la actualización',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        if (this.estado_id === ESTADO_HISTORICO) {
            throw new DomainException(
                'No se puede actualizar un registro dado de baja',
                { httpStatus: HttpStatus.BAD_REQUEST }
            );
        }

        this.usuario_id_actualizacion = usuarioId;
    }

    @BeforeUpdate()
    updateTimestamps() {
        const now = new Date();
        if (this.usuario_id_baja) {
            if (this.estado_id !== ESTADO_HISTORICO) {
                this.estado_id = ESTADO_HISTORICO;
            }
        } else if (this.usuario_id_actualizacion) {
            if (this.estado_id === ESTADO_HISTORICO) {
                this.estado_id = ESTADO_ACTIVO;
            }
            this.fecha_baja = undefined as any;
            this.fecha_actualizacion = now;
        }
    }
}
