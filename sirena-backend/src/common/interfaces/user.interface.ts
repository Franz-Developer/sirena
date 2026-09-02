// C:\sirena\sirena-backend\src\common\interfaces\user.interface.ts
export interface AuthenticatedUser {
    usuario_id: number;
    login?: string;
    email?: string;
    [key: string]: any;
}
