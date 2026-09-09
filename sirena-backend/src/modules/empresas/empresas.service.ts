// C:\sirena\sirena-backend\src\modules\empresas\empresas.service.ts
import { Injectable, HttpStatus } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { getErrorMessage, getErrorStack, isDomainException } from '../../common/utils/error.util';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateEmpresaDto } from './dto/create-empresa.dto';
import { EmpresaResponseDto } from './dto/empresa-response.dto';
import { FindEmpresasQueryDto } from './dto/find-empresas-query.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { Empresa } from './entities/empresa.entity';

@Injectable()
export class EmpresasService extends BaseService {
    protected config: BaseServiceConfig = {
        nombreTabla: 'empresas',
        nombreEntidad: 'Empresa',
        campoPK: 'empresa_id',
        alias: 't',
        responseDto: EmpresaResponseDto,
        camposBusquedaEnQ: FindEmpresasQueryDto.getCamposParaQ(),
        tablasDependientes: FindEmpresasQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [],
        configuracionOrden: {
            campoOrdenPorDefecto: 'empresa_id',
            camposPermitidosParaOrdenar: FindEmpresasQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindEmpresasQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () => FindEmpresasQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource() dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string { return this.config.nombreTabla; }
    private get campoPK(): string { return this.config.campoPK; }

    async create(dto: CreateEmpresaDto, usuarioId: number): Promise<EmpresaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({ tabla: this.nombreTabla, campos: [{ nombre: 'empresa', valor: dto.empresa }], campoPk: this.campoPK, estadosValidos: [...ESTADOS_VIVOS] }),
                this.unicidadValidador.validarUnicidad({ tabla: this.nombreTabla, campos: [{ nombre: 'codigo', valor: dto.codigo }], campoPk: this.campoPK, estadosValidos: [...ESTADOS_VIVOS] }),
                this.unicidadValidador.validarUnicidad({ tabla: this.nombreTabla, campos: [{ nombre: 'matricula_comercio', valor: dto.matricula_comercio }], campoPk: this.campoPK, estadosValidos: [...ESTADOS_VIVOS] }),
                this.tablaValidador.validarRegistrosActivos('usuarios', 'usuario_id', usuarioId)
            ]);

            const empresa = manager.create(Empresa, {
                ...dto,
                usuario_id_registro: Number(usuarioId),
            });

            try {
                await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
                const saved = await manager.save(empresa);
                return this.findOne<EmpresaResponseDto>(saved.empresa_id, usuarioId, manager);
            } catch (error: unknown) {
                if (isDomainException(error)) {
                    throw error;
                }
                this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
                throw error;
            }
        });
    }

    async update(id: number, dto: UpdateEmpresaDto, usuarioId: number): Promise<EmpresaResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            const hasFields = Object.values(dto).some(val => val !== undefined);
            if (!hasFields) {
                throw new DomainException(
                    'No se enviaron campos para actualizar.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dto, this.campoPK, usuarioId);

            const empresaActual = await manager.findOne(Empresa, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
                lock: { mode: 'pessimistic_write' }
            });

            if (!empresaActual) {
                throw new DomainException('Empresa no encontrada.', { httpStatus: HttpStatus.NOT_FOUND });
            }

            dto = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dto,
                FindEmpresasQueryDto.getDependencias(),
                FindEmpresasQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            manager.merge(Empresa, empresaActual, dto);
            empresaActual.update(usuarioId);

            try {
                const saved = await manager.save(empresaActual);
                return this.findOne(saved.empresa_id, usuarioId, manager);
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
