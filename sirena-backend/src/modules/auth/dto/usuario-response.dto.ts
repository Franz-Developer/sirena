// C:\sirena\sirena-backend\src\modules\auth\dto\usuario-response.dto.ts
import { Expose } from 'class-transformer';

export class UsuarioResponseDto {
    @Expose() usuario_id: number;
    @Expose() login: string;
    @Expose() sucursal_id: number;
    @Expose() avatar: string;
    @Expose() rol_id: number;
    @Expose() trabajador_id: number;
    @Expose() nombres: string;
    @Expose() rol_codigo: string;
    @Expose() rol: string;
    @Expose() trabajador_nombre_completo: string;
    @Expose() trabajador_nombres: string;
    @Expose() trabajador_paterno: string;
    @Expose() trabajador_materno: string;
    @Expose() trabajador_dni: string;
    @Expose() sucursal_nombre: string;
    @Expose() sucursal_codigo: string;
    @Expose() empresa_id: number;
    @Expose() empresa_nombre: string;
    @Expose() empresa_codigo: string;
}
