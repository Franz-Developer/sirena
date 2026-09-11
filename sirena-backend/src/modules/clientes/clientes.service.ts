// C:\sirena\sirena-backend\src\modules\clientes\clientes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { ClienteResponseDto } from './dto/cliente-response.dto';
import { FindClientesQueryDto } from './dto/find-clientes-query.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';
import { Cliente } from './entities/cliente.entity';
import { crearError, getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';

@Injectable()
export class ClientesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'clientes',
        nombreEntidad: 'Cliente',
        campoPK: 'cliente_id',
        alias: 'c',
        responseDto: ClienteResponseDto,
        camposBusquedaEnQ: FindClientesQueryDto.getCamposParaQ(),
        tablasDependientes: FindClientesQueryDto.getDependencias(),
        joins: [
            {
                table: 'bancos',
                alias: 'b',
                onCondition: 'b.banco_id = c.banco_base_id',
                selectColumns: [
                    'b.banco AS banco_base_nombre',
                    'b.abreviatura AS banco_base_abreviatura'
                ],
                type: 'LEFT'
            }
        ],
        configuracionFiltros: [
            {
                nombreCampo: 'tipo_cliente_id',
                nombreColumna: 'tipo_cliente_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'tipo_documento_id',
                nombreColumna: 'tipo_documento_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'banco_base_id',
                nombreColumna: 'banco_base_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'habilitado_ventas',
                nombreColumna: 'habilitado_ventas',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'cliente_id',
            camposPermitidosParaOrdenar: FindClientesQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindClientesQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindClientesQueryDto.getCamposProtegidosConDependencias(),
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

    async create(dto: CreateClienteDto, usuarioId: number): Promise<ClienteResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const validacionesPromise: Promise<any>[] = [
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ];

            if (dto.banco_base_id) {
                validacionesPromise.push(
                    this.tablaValidador.validarRegistrosActivos('bancos', 'banco_id', dto.banco_base_id)
                );
            }

            const camposUnicidad: Array<{ nombre: string; valor: any }> = [
                { nombre: 'tipo_documento_id', valor: dto.tipo_documento_id },
                { nombre: 'documento', valor: dto.documento }
            ];

            if (dto.documento_complemento !== undefined && dto.documento_complemento !== null && dto.documento_complemento !== '') {
                camposUnicidad.push({ nombre: 'documento_complemento', valor: dto.documento_complemento });
            }

            if (dto.documento !== '0') {
                validacionesPromise.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: camposUnicidad,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK
                    })
                );
            }

            await Promise.all(validacionesPromise);

            const cliente = manager.create(Cliente, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(cliente);
                return this.findOne<ClienteResponseDto>(saved.cliente_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en create: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el cliente', 'crear');
            }
        });
    }

    async update(id: number, dto: UpdateClienteDto, usuarioId: number): Promise<ClienteResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const clienteActual = await manager.findOne(Cliente, {
                where: { [this.campoPK]: id },
                lock: { mode: 'pessimistic_write' }
            });

            if (!clienteActual) {
                throw new DomainException(
                    `Cliente no encontrado.`,
                    { id, httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            const dtoProcesado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindClientesQueryDto.getDependencias(),
                FindClientesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoProcesado.banco_base_id !== undefined && dtoProcesado.banco_base_id !== clienteActual.banco_base_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('bancos', 'banco_id', dtoProcesado.banco_base_id)
                );
            }

            const nuevoTipoDoc = dtoProcesado.tipo_documento_id ?? clienteActual.tipo_documento_id;
            const nuevoDocumento = dtoProcesado.documento ?? clienteActual.documento;
            const nuevoComplemento = dtoProcesado.documento_complemento !== undefined ? dtoProcesado.documento_complemento : clienteActual.documento_complemento;

            const cambioDocumento =
                (dtoProcesado.tipo_documento_id !== undefined && dtoProcesado.tipo_documento_id !== clienteActual.tipo_documento_id) ||
                (dtoProcesado.documento !== undefined && dtoProcesado.documento !== clienteActual.documento) ||
                (dtoProcesado.documento_complemento !== undefined && dtoProcesado.documento_complemento !== clienteActual.documento_complemento);

            if (cambioDocumento && nuevoDocumento !== '0') {
                const camposUnicidad: Array<{ nombre: string; valor: any }> = [
                    { nombre: 'tipo_documento_id', valor: nuevoTipoDoc },
                    { nombre: 'documento', valor: nuevoDocumento }
                ];

                if (nuevoComplemento !== undefined && nuevoComplemento !== null && nuevoComplemento !== '') {
                    camposUnicidad.push({ nombre: 'documento_complemento', valor: nuevoComplemento });
                }

                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: camposUnicidad,
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK,
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(clienteActual, dtoProcesado);
            clienteActual.update(usuarioId);

            try {
                await manager.save(clienteActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error inesperado en update: ${errorMessage}`, getErrorStack(error));
                throw crearError(error, 'el cliente', 'actualizar');
            }
        });
    }
}
