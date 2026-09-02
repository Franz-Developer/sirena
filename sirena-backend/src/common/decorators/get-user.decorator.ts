// C:\sirena\sirena-backend\src\common\decorators\get-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Decorador personalizado para extraer el usuario autenticado del objeto `request`.
 *
 * Este decorador mapea el objeto de usuario y asegura que la propiedad `id`
 * esté disponible, evaluando alternativamente `usuario_id` o `sub` si `id` no viene definido por defecto.
 *
 * @example
 * ```typescript
 * @Get('profile')
 * getProfile(@GetUser() user: any) {
 *   return user;
 * }
 *
 * // O extrayendo una propiedad específica si pasas un parámetro (opcional si extiendes _data)
 * @Get('profile')
 * getProfile(@GetUser('email') email: string) { ... }
 * ```
 */
export const GetUser = createParamDecorator(
    (_data, ctx: ExecutionContext) => {
        const request = ctx.switchToHttp().getRequest();
        const user = request.user;

        return {
            id: user.usuario_id ?? user.sub ?? null,
            ...user,
        };
    },
);
