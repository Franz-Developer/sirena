// C:\sirena\sirena-backend\src\modules\clientes\clientes.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADO_ACTIVO, ESTADOS_VIVOS } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { logSqlQuery } from '../../common/utils/sql-logger.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { FindClientesQueryDto } from './dto/find-clientes-query.dto';
import { ClienteResponseDto } from './dto/cliente-response.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';
import { Cliente } from './entities/cliente.entity';

@Injectable()
export class ClientesService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'clientes',
        nombreEntidad: 'Cliente',
        campoPK: 'cliente_id',
        alias: 't',
        responseDto: ClienteResponseDto,
        camposBusquedaEnQ: FindClientesQueryDto.getCamposParaQ(),
        tablasDependientes: FindClientesQueryDto.getDependencias(),
        joins: [
            {
                table: 'bancos',
                alias: 'b',
                onCondition: 'b.banco_id = t.banco_base_id',
                selectColumns: [
                    'b.banco AS banco_base_nombre',
                    'b.abreviatura AS banco_base_abreviatura'
                ],
                type: 'INNER'
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
            {
                nombreCampo: 'estado_id',
                nombreColumna: 'estado_id',
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
            const validaciones: Promise<any>[] = [
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear')
            ];

            if (dto.banco_base_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('bancos', 'banco_id', dto.banco_base_id)
                );
            }

            if (dto.documento && dto.documento !== '0') {
                const camposUnicidad = [
                    { nombre: 'tipo_documento_id', valor: dto.tipo_documento_id ?? 2200 },
                    { nombre: 'documento', valor: dto.documento }
                ];

                if (dto.documento_complemento) {
                    camposUnicidad.push({ nombre: 'documento_complemento', valor: dto.documento_complemento });
                }

                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: camposUnicidad,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK
                    })
                );
            }

            await Promise.all(validaciones);

            const query = `
                INSERT INTO ${this.nombreTabla} (
                    tipo_cliente_id,
                    cliente,
                    nit,
                    razon_social,
                    documento,
                    documento_complemento,
                    tipo_documento_id,
                    direccion,
                    telefono,
                    email,
                    banco_base_id,
                    numero_cuenta,
                    habilitado_ventas,
                    limite_credito,
                    estado_id,
                    usuario_id_registro,
                    fecha_registro
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, CURRENT_TIMESTAMP)
                RETURNING ${this.campoPK}
            `;

            const params = [
                dto.tipo_cliente_id,
                dto.cliente,
                dto.nit || null,
                dto.razon_social || null,
                dto.documento,
                dto.documento_complemento || null,
                dto.tipo_documento_id,
                dto.direccion || null,
                dto.telefono || null,
                dto.email || null,
                dto.banco_base_id,
                dto.numero_cuenta || null,
                dto.habilitado_ventas,
                dto.limite_credito,
                ESTADO_ACTIVO,
                Number(usuarioId)
            ];

            logSqlQuery(query, params, `create - ${this.nombreTabla}`);

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const insertResult = await manager.query(query, params);
                const newId = Number(insertResult[0]?.[this.campoPK] ?? 0);

                if (newId === 0) {
                    throw new DomainException(
                        'Error al registrar el cliente.',
                        { httpStatus: HttpStatus.INTERNAL_SERVER_ERROR }
                    );
                }

                return this.findOne(newId, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateClienteDto, usuarioId: number): Promise<ClienteResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const clienteActual = await manager.findOne(Cliente, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!clienteActual) {
                throw new DomainException(
                    'Cliente no encontrado.',
                    { httpStatus: HttpStatus.NOT_FOUND }
                );
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindClientesQueryDto.getDependencias(),
                FindClientesQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dto.banco_base_id !== undefined && dto.banco_base_id !== clienteActual.banco_base_id) {
                validaciones.push(
                    this.tablaValidador.validarRegistrosActivos('bancos', 'banco_id', dto.banco_base_id)
                );
            }

            const tipoDocumentoEvaluado = dto.tipo_documento_id ?? clienteActual.tipo_documento_id;
            const documentoEvaluado = dto.documento ?? clienteActual.documento;
            const complementoEvaluado = dto.documento_complemento !== undefined
                ? dto.documento_complemento
                : clienteActual.documento_complemento;

            const huboCambioDocumentacion =
                (dto.tipo_documento_id !== undefined && dto.tipo_documento_id !== clienteActual.tipo_documento_id) ||
                (dto.documento !== undefined && dto.documento !== clienteActual.documento) ||
                (dto.documento_complemento !== undefined && dto.documento_complemento !== clienteActual.documento_complemento);

            if (huboCambioDocumentacion && documentoEvaluado !== '0') {
                const camposUnicidad = [
                    { nombre: 'tipo_documento_id', valor: tipoDocumentoEvaluado },
                    { nombre: 'documento', valor: documentoEvaluado }
                ];

                if (complementoEvaluado) {
                    camposUnicidad.push({ nombre: 'documento_complemento', valor: complementoEvaluado });
                }

                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campos: camposUnicidad,
                        idExcluir: id,
                        estadosValidos: [...ESTADOS_VIVOS],
                        campoPk: this.campoPK
                    })
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            Object.assign(clienteActual, dto);
            clienteActual.update(usuarioId);

            try {
                await manager.save(clienteActual);
                return this.findOne(id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }
}
