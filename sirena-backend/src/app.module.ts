// C:\sirena\sirena-backend\src\app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LoggerModule } from 'nestjs-pino';
import { CommonModule } from './common/common.module';
import { ValidationLogInterceptor } from './common/decorators/validation-message.decorator';
import { UserValidationGuard } from './common/guards/user-validation.guard';
import { CacheInterceptor } from './common/interceptors/cache.interceptor';
import { typeOrmConfig } from './config/database.config';
import { loggerConfig } from './config/logger.config';
import { AuthModule } from './modules/auth/auth.module';
import { ConstantesModule } from './modules/constantes/constantes.module';
import { TablasModule } from './modules/tablas/tablas.module';
import { BancosModule } from './modules/bancos/bancos.module';
import { TiposCambiosModule } from './modules/tipos-cambios/tipos-cambios.module';
import { EmpresasModule } from './modules/empresas/empresas.module';
import { EmpresasCuentasModule } from './modules/empresas-cuentas/empresas-cuentas.module';
import { EmpresasNitsModule } from './modules/empresas-nits/empresas-nits.module';
import { SucursalesModule } from './modules/sucursales/sucursales.module';
import { PuntosVentaModule } from './modules/puntos-venta/puntos-venta.module';
import { CuisModule } from './modules/cuis/cuis.module';
import { CufdsModule } from './modules/cufds/cufds.module';
import { UnidadesModule } from './modules/unidades/unidades.module';
import { AlmacenesModule } from './modules/almacenes/almacenes.module';
import { UbicacionesModule } from './modules/ubicaciones/ubicaciones.module';
import { AlmacenesPuntosVentaModule } from './modules/almacenes-puntos-venta/almacenes-puntos-venta.module';
import { CargosModule } from './modules/cargos/cargos.module';
import { TrabajadoresModule } from './modules/trabajadores/trabajadores.module';
import { TrabajadoresCargosModule } from './modules/trabajadores-cargos/trabajadores-cargos.module';
import { RolesModule } from './modules/roles/roles.module';
import { UsuariosModule } from './modules/usuarios/usuarios.module';

import { MenusModule } from './modules/menus/menus.module';

import { InventariosFisicosModule } from './modules/inventarios-fisicos/inventarios-fisicos.module';
import { ClientesModule } from './modules/clientes/clientes.module';
import { SucesosModule } from './modules/sucesos/sucesos.module';


import { ParametrosGlobalesModule } from './modules/parametros-globales/parametros-globales.module';

@Module({
    imports: [
        ConfigModule.forRoot({
            isGlobal: true,
        }),
        ScheduleModule.forRoot(),
        TypeOrmModule.forRoot(typeOrmConfig),

        ThrottlerModule.forRootAsync({
            imports: [ConfigModule],
            inject: [ConfigService],
            useFactory: (config: ConfigService) => ({
                throttlers: [
                    {
                        name: 'default',
                        ttl: config.get<number>('THROTTLE_TTL', 60),
                        limit: config.get<number>('THROTTLE_LIMIT', 100),
                    },
                ],
            }),
        }),
        LoggerModule.forRoot(loggerConfig),
        AuthModule,
        CommonModule,
        ConstantesModule,
        TablasModule,
        BancosModule,
        TiposCambiosModule,
        EmpresasModule,
        EmpresasNitsModule,
        EmpresasCuentasModule,
        SucursalesModule,
        PuntosVentaModule,
        CuisModule,
        CufdsModule,
        UnidadesModule,
        AlmacenesModule,
        UbicacionesModule,
        AlmacenesPuntosVentaModule,
        ParametrosGlobalesModule,
        CargosModule,
        TrabajadoresModule,
        TrabajadoresCargosModule,
        RolesModule,
        UsuariosModule,

        MenusModule,

        InventariosFisicosModule,
        ClientesModule,
        SucesosModule,
    ],
    controllers: [],
    providers: [
        {
            provide: APP_GUARD,
            useClass: ThrottlerGuard,
        },
        {
            provide: APP_GUARD,
            useClass: UserValidationGuard,
        },
        {
            provide: APP_INTERCEPTOR,
            useClass: CacheInterceptor,
        },
        {
            provide: APP_INTERCEPTOR,
            useClass: ValidationLogInterceptor,
        },
    ],
})
export class AppModule {}
