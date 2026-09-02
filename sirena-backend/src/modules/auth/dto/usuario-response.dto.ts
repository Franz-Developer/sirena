// C:\sirena\sirena-backend\src\modules\usuarios\dto\usuario-response.dto.ts
import { Expose } from 'class-transformer';

export class UsuarioResponseDto {
    @Expose() usuario_id: number;
    @Expose() login: string;
    @Expose() sucursal_id: number;
    @Expose() avatar: string;
    @Expose() rol_id: number;
    @Expose() trabajadorID: number;
    @Expose() nombres: string;
    @Expose() rolCodigo: string;
    @Expose() rol: string;
    @Expose() trabajadorNombreCompleto: string;
    @Expose() trabajadorNombres: string;
    @Expose() trabajadorPaterno: string;
    @Expose() trabajadorMaterno: string;
    @Expose() trabajadorDNI: string;
    @Expose() sucursalNombre: string;
    @Expose() sucursalCodigo: string;
    @Expose() empresaID: number;
    @Expose() empresaNombre: string;
    @Expose() empresaCodigo: string;
}
