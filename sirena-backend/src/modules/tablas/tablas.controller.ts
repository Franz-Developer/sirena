// C:\sirena\sirena-backend\src\modules\tablas\tablas.controller.ts
import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { Cache, CACHE_LARGO } from '../../common/decorators/cache.decorator';
import { ConstantesRateLimit } from '../../common/decorators/rate-limit.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TablasService } from './tablas.service';
import { FindTablasQueryDto } from './dto/find-tablas-query.dto';

@UseGuards(JwtAuthGuard)
@Controller('tablas')
export class TablasController {
    constructor(private readonly tablasService: TablasService) {}

    @Get()
    @ConstantesRateLimit()
    @Cache('tablas:findAll', CACHE_LARGO)
    findAll(@Query() query: FindTablasQueryDto) {
        return this.tablasService.findAll(query);
    }
}
