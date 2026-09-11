// C:\sirena\sirena-backend\src\modules\empresas-cuentas\empresas-cuentas.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateEmpresaCuentaDto } from './dto/create-empresa-cuenta.dto';
import { EmpresaCuentaResponseDto } from './dto/empresa-cuenta-response.dto';
import { FindEmpresasCuentasQueryDto } from './dto/find-empresas-cuentas-query.dto';
import { UpdateEmpresaCuentaDto } from './dto/update-empresa-cuenta.dto';
import { EmpresaCuenta } from './entities/empresa-cuenta.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class EmpresasCuentasService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'empresas_cuentas',
        nombreEntidad: 'Cuenta Bancaria',
        campoPK: 'empresa_cuenta_id',
        alias: 't',
        responseDto: EmpresaCuentaResponseDto,
        camposBusquedaEnQ: FindEmpresasCuentasQueryDto.getCamposParaQ(),
        tablasDependientes: FindEmpresasCuentasQueryDto.getDependencias(),
        joins: [
            {
                table: 'empresas',
                alias: 'e',
                onCondition: 'e.empresa_id = t.empresa_id',
                selectColumns: [
                    'e.empresa AS empresa_nombre',
                    'e.codigo AS empresa_codigo'
                ],
                type: 'INNER'
            },
            {
                table: 'bancos',
                alias: 'b',
                onCondition: 'b.banco_id = t.banco_id',
                selectColumns: [
                    'b.banco AS banco_nombre',
                    'b.codigo_asfi AS banco_codigo_asfi',
                    'b.abreviatura AS banco_abreviatura'
                ],
                type: 'INNER'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'empresa_id',
                nombreColumna: 'empresa_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'banco_id',
                nombreColumna: 'banco_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_moneda_id',
                nombreColumna: 'tipo_moneda_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_cuenta_id',
                nombreColumna: 'tipo_cuenta_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'empresa_cuenta_id',
            camposPermitidosParaOrdenar: FindEmpresasCuentasQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindEmpresasCuentasQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindEmpresasCuentasQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
         @InjectDataSource()
        dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    async create(dto: CreateEmpresaCuentaDto, usuarioId: number): Promise<EmpresaCuentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id),
                this.tablaValidador.validarRegistrosActivos('bancos', 'banco_id', dto.banco_id),
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            await this.unicidadValidador.validarUnicidad({
                tabla: this.nombreTabla,
                campos: [
                    { nombre: 'empresa_id', valor: dto.empresa_id },
                    { nombre: 'banco_id', valor: dto.banco_id },
                    { nombre: 'nro_cuenta', valor: dto.nro_cuenta },
                    { nombre: 'tipo_moneda_id', valor: dto.tipo_moneda_id },
                    { nombre: 'tipo_cuenta_id', valor: dto.tipo_cuenta_id }
                ],
                estadosValidos: [...ESTADOS_VIVOS],
                campoPk: this.campoPK,
            });

            const empresaCuenta = manager.create(EmpresaCuenta, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(empresaCuenta);
                return this.findOne<EmpresaCuentaResponseDto>(saved.empresa_cuenta_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la cuenta bancaria', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateEmpresaCuentaDto, usuarioId: number): Promise<EmpresaCuentaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const cuentaActual = await manager.findOne(EmpresaCuenta, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!cuentaActual) {
                throw new DomainException(
                    `Cuenta bancaria de empresa no encontrada.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindEmpresasCuentasQueryDto.getDependencias(),
                FindEmpresasCuentasQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dto.empresa_id !== undefined && dto.empresa_id !== cuentaActual.empresa_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('empresas', 'empresa_id', dto.empresa_id)
                );
            }

            if (dto.banco_id !== undefined && dto.banco_id !== cuentaActual.banco_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('bancos', 'banco_id', dto.banco_id)
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            const nuevoEmpresaId = dto.empresa_id ?? cuentaActual.empresa_id;
            const nuevoBancoId = dto.banco_id ?? cuentaActual.banco_id;
            const nuevoNroCuenta = dto.nro_cuenta ?? cuentaActual.nro_cuenta;
            const nuevoTipoMonedaId = dto.tipo_moneda_id ?? cuentaActual.tipo_moneda_id;
            const nuevoTipoCuentaId = dto.tipo_cuenta_id ?? cuentaActual.tipo_cuenta_id;

            if (
                dto.empresa_id !== undefined ||
                dto.banco_id !== undefined ||
                dto.nro_cuenta !== undefined ||
                dto.tipo_moneda_id !== undefined ||
                dto.tipo_cuenta_id !== undefined
            ) {
                await this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [
                        { nombre: 'empresa_id', valor: nuevoEmpresaId },
                        { nombre: 'banco_id', valor: nuevoBancoId },
                        { nombre: 'nro_cuenta', valor: nuevoNroCuenta },
                        { nombre: 'tipo_moneda_id', valor: nuevoTipoMonedaId },
                        { nombre: 'tipo_cuenta_id', valor: nuevoTipoCuentaId }
                    ],
                    idExcluir: id,
                    estadosValidos: [...ESTADOS_VIVOS],
                    campoPk: this.campoPK,
                });
            }

            Object.assign(cuentaActual, dto);
            cuentaActual.update(usuarioId);

            try {
                await manager.save(cuentaActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'la cuenta bancaria', 'actualizar');
            }
        });
    }
}
