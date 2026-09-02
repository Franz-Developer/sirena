// C:\sirena\sirena-backend\src\common\guards\user-validation.guard.ts
import { Injectable, ExecutionContext, BadRequestException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

@Injectable()
export class UserValidationGuard extends AuthGuard('jwt') {
    constructor(private reflector: Reflector) {
        super();
    }

    override async canActivate(context: ExecutionContext): Promise<boolean> {
        // 1. Verificar si la ruta es pública
        const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        if (isPublic) {
            return true;
        }

        // 2. Ejecutar la autenticación de Passport (JwtAuthGuard) automáticamente
        const isValid = await super.canActivate(context);
        if (!isValid) {
            return false;
        }

        // 3. Obtener el request y validar el usuario inyectado por el token
        const request = context.switchToHttp().getRequest();
        const user = request.user;

        if (!user?.usuario_id) {
            throw new BadRequestException('Usuario no identificado en el token.');
        }

        return true;
    }
}
