// C:\sirena\sirena-backend\src\modules\constantes\constantes.controller.ts
import { Controller, Get, Query, ValidationPipe, BadRequestException, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { ConstantesRateLimit } from '../../common/decorators/rate-limit.decorator';
import { AuthenticatedUser } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ConstantesService } from './constantes.service';
import { FindConstantesQueryDto } from './dto/find-constantes-query.dto';

@UseGuards(JwtAuthGuard)
@Controller('constantes')
export class ConstantesController {
    constructor(private readonly constantesService: ConstantesService) {}

    /**
     * GET /constantes - Listar todas las constantes del sistema
     *
     * @param query - Filtros: tipo, q, estado_id, id, paginación
     * @param user - Usuario autenticado
     * @returns Lista de constantes paginada
     *
     * @example
     * GET /api/constantes?tipo=estados
     * GET /api/constantes?q=ACTIVO
     * GET /api/constantes?tipo=monedas&offset=0&limit=10
     * GET /api/constantes?id=2300
     */
    @Get()
    @ConstantesRateLimit()
    @Cache('constantes:findAll', CACHE_LARGO)
    findAll(
        @Query(new ValidationPipe({
            transform: true,
            whitelist: true,
            forbidNonWhitelisted: true,
            exceptionFactory: (errors) => {
                const wrongProps = errors.map(err => err.property);
                return new BadRequestException({
                    message: `Parámetros inválidos: ${wrongProps.join(', ')}. Parámetros permitidos: tipo, q, estado_id, id, offset, limit, sortField, sortOrder.`,
                    error: 'Bad Request',
                    statusCode: 400,
                });
            },
        })) query: FindConstantesQueryDto,
        @GetUser() user: AuthenticatedUser
    ) {
        return this.constantesService.findAll(query, user.usuario_id);
    }

    /**
     * GET /constantes/tipos - Listar todos los tipos de constantes disponibles
     *
     * @returns Lista de tipos de constantes
     *
     * @example
     * GET /api/constantes/tipos
     */
    @Get('tipos')
    @ConstantesRateLimit()
    @Cache('constantes:tipos', CACHE_LARGO)
    getTipos() {
        return this.constantesService.getTipos();
    }

    /**
     * GET /constantes/estados - Obtener todos los estados (método helper)
     *
     * @returns Lista de estados
     *
     * @example
     * GET /api/constantes/estados
     */
    @Get('estados')
    @ConstantesRateLimit()
    @Cache('constantes:estados', CACHE_LARGO)
    getEstados() {
        return this.constantesService.getEstados();
    }

    /**
     * GET /constantes/monedas - Obtener todas las monedas (método helper)
     *
     * @returns Lista de monedas
     *
     * @example
     * GET /api/constantes/monedas
     */
    @Get('monedas')
    @ConstantesRateLimit()
    @Cache('constantes:monedas', CACHE_LARGO)
    getMonedas() {
        return this.constantesService.getMonedas();
    }

    /**
     * GET /constantes/generos - Obtener todos los géneros (método helper)
     *
     * @returns Lista de géneros
     *
     * @example
     * GET /api/constantes/generos
     */
    @Get('generos')
    @ConstantesRateLimit()
    @Cache('constantes:generos', CACHE_LARGO)
    getGeneros() {
        return this.constantesService.getGeneros();
    }

    /**
     * GET /constantes/tipos-pago - Obtener todos los tipos de pago (método helper)
     *
     * @returns Lista de tipos de pago
     *
     * @example
     * GET /api/constantes/tipos-pago
     */
    @Get('tipos-pago')
    @ConstantesRateLimit()
    @Cache('constantes:tipos-pago', CACHE_LARGO)
    getTiposPago() {
        return this.constantesService.getTiposPago();
    }

    /**
     * GET /constantes/tipos-venta - Obtener todos los tipos de venta (método helper)
     *
     * @returns Lista de tipos de venta
     *
     * @example
     * GET /api/constantes/tipos-venta
     */
    @Get('tipos-venta')
    @ConstantesRateLimit()
    @Cache('constantes:tipos-venta', CACHE_LARGO)
    getTiposVenta() {
        return this.constantesService.getTiposVenta();
    }

    /**
     * GET /constantes/tipos-documento - Obtener todos los tipos de documento (método helper)
     *
     * @returns Lista de tipos de documento
     *
     * @example
     * GET /api/constantes/tipos-documento
     */
    @Get('tipos-documento')
    @ConstantesRateLimit()
    @Cache('constantes:tipos-documento', CACHE_LARGO)
    getTiposDocumento() {
        return this.constantesService.getTiposDocumento();
    }

    /**
     * GET /constantes/eventos - Obtener todos los eventos (método helper)
     *
     * @returns Lista de eventos
     *
     * @example
     * GET /api/constantes/eventos
     */
    @Get('eventos')
    @ConstantesRateLimit()
    @Cache('constantes:eventos', CACHE_LARGO)
    getEventos() {
        return this.constantesService.getEventos();
    }

    @Get('tipos-ubicacion')
    @ConstantesRateLimit()
    @Cache('constantes:tipos-ubicacion', CACHE_LARGO)
    getTiposUbicacion() {
        return this.constantesService.getTiposUbicacion();
    }
}