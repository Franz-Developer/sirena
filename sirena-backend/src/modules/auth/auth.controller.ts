// C:\sirena\sirena-backend\src\modules\auth\auth.controller.ts
import { Controller, Post, Body } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';
import { LoginRateLimit } from '../../common/decorators/rate-limit.decorator';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
    constructor(private readonly authService: AuthService) {}

    /**
     * ✅ Endpoint de autenticación con rate limiting centralizado
     * - Límite: 5 intentos por minuto (configurado en RATE_LIMIT_CONFIG.AUTH.LOGIN)
     * - Previene ataques de fuerza bruta
     */
    @Public()
    @LoginRateLimit()
    @Post('validar')
    validar(@Body() dto: LoginDto) {
        return this.authService.validarLogin(dto);
    }
}
