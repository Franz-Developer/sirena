// C:\sirena\sirena-backend\src\modules\trabajadores\trabajadores.service.ts
import { Injectable, HttpStatus, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ESTADOS_VIVOS, ESTADO_ACTIVO, Genero, EstadoCivilMasculino, ESTADO_CIVIL_MASCULINO_METADATA, EstadoCivilFemenino, ESTADO_CIVIL_FEMENINO_METADATA } from '../../common/constants/estados.constant';
import { DomainException } from '../../common/exceptions/domain.exception';
import { BaseService, BaseServiceConfig } from '../../common/services/base.service';
import { ConfiguracionService } from '../../common/services/configuracion.service';
import { FileValidatorService } from '../../common/services/file-validator.service';
import { GenerarQRUtil } from '../../common/services/generar-qr.service';
import { runInTransaction } from '../../common/utils/transaction.helper';
import { getEnumValues } from '../../common/utils/validation-helper.util';
import { TablaValidadorService } from '../../common/validators/tabla-validador.service';
import { UnicidadValidadorService } from '../../common/validators/unicidad-validador.service';
import { CreateTrabajadorDto } from './dto/create-trabajador.dto';
import { TrabajadorResponseDto } from './dto/trabajador-response.dto';
import { FindTrabajadoresQueryDto } from './dto/find-trabajadores-query.dto';
import { UpdateTrabajadorDto } from './dto/update-trabajador.dto';
import { Trabajador } from './entities/trabajador.entity';

@Injectable()
export class TrabajadoresService extends BaseService {
    private readonly customLogger = new Logger(TrabajadoresService.name);

    protected config: BaseServiceConfig = {
        nombreTabla: 'trabajadores',
        nombreEntidad: 'Trabajador',
        campoPK: 'trabajador_id',
        alias: 't',
        responseDto: TrabajadorResponseDto,
        camposBusquedaEnQ: FindTrabajadoresQueryDto.getCamposParaQ(),
        tablasDependientes: FindTrabajadoresQueryDto.getDependencias(),
        joins: [],
        configuracionFiltros: [
            {
                nombreCampo: 'genero_id',
                nombreColumna: 'genero_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'sucursal_id',
                nombreColumna: 'sucursal_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'cargo_id',
                nombreColumna: 'cargo_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
            {
                nombreCampo: 'empresa_id',
                nombreColumna: 'empresa_id',
                tipoDatoFiltro: 'number',
                operador: 'eq',
            },
        ],
        configuracionOrden: {
            campoOrdenPorDefecto: 'trabajador_id',
            camposPermitidosParaOrdenar: FindTrabajadoresQueryDto.getCamposPermitidosParaOrdenar(),
            equivalenciasMapeo: FindTrabajadoresQueryDto.getEquivalenciasMapeo(),
        },
        getCamposProtegidosConDependencias: () =>
            FindTrabajadoresQueryDto.getCamposProtegidosConDependencias(),
    };

    constructor(
        @InjectDataSource() dataSource: DataSource,
        tablaValidador: TablaValidadorService,
        private readonly unicidadValidador: UnicidadValidadorService,
        private readonly generarQRUtil: GenerarQRUtil,
        private readonly configuracionService: ConfiguracionService,
        private readonly fileValidator: FileValidatorService,
    ) {
        super(dataSource, tablaValidador);
    }

    private get nombreTabla(): string {
        return this.config.nombreTabla;
    }

    private get campoPK(): string {
        return this.config.campoPK;
    }

    private async validarEstadoCivilPorGenero(
        generoId: number,
        estadoCivilId: number,
    ): Promise<void> {
        const estadosMasculinos = getEnumValues(EstadoCivilMasculino);
        const estadosFemeninos = getEnumValues(EstadoCivilFemenino);

        if (generoId === Genero.MASCULINO && !estadosMasculinos.includes(estadoCivilId)) {
            const valoresValidos = estadosMasculinos
                .map(id => {
                    const meta = ESTADO_CIVIL_MASCULINO_METADATA[id as EstadoCivilMasculino];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');
            throw new DomainException(
                `El estado civil "${estadoCivilId}" no es válido para género masculino. Valores válidos: ${valoresValidos}.`,
                { httpStatus: HttpStatus.BAD_REQUEST },
            );
        }

        if (generoId === Genero.FEMENINO && !estadosFemeninos.includes(estadoCivilId)) {
            const valoresValidos = estadosFemeninos
                .map(id => {
                    const meta = ESTADO_CIVIL_FEMENINO_METADATA[id as EstadoCivilFemenino];
                    return `${id}(${meta?.abreviatura ?? 'DESCONOCIDO'})`;
                })
                .join(', ');
            throw new DomainException(
                `El estado civil "${estadoCivilId}" no es válido para género femenino. Valores válidos: ${valoresValidos}.`,
                { httpStatus: HttpStatus.BAD_REQUEST },
            );
        }
    }

    async create(dto: CreateTrabajadorDto, usuarioId: number): Promise<TrabajadorResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.validarEstadoCivilPorGenero(dto.genero_id, dto.estado_civil_id);

            if (!dto.foto) {
                throw new DomainException(
                    'La foto del trabajador es obligatoria.',
                    { httpStatus: HttpStatus.BAD_REQUEST }
                );
            }

            await Promise.all([
                this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'crear'),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campoPk: this.campoPK,
                    campos: [
                        { nombre: 'nombres', valor: dto.nombres },
                        { nombre: 'paterno', valor: dto.paterno },
                        { nombre: 'materno', valor: dto.materno ?? '' },
                    ],
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'dni', valor: dto.dni }],
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS],
                }),
            ]);

            const trabajador = manager.create(Trabajador, {
                ...dto,
                foto: dto.foto,
                usuario_id_registro: Number(usuarioId),
            });

            await this.sincronizarSecuencia(manager, this.nombreTabla, this.campoPK);
            const saved = await manager.save(trabajador);

            await this.generarQRUtil.generarQRParaTrabajador(
                saved.trabajador_id,
                false,
                manager
            );

            return this.findOne<TrabajadorResponseDto>(saved.trabajador_id, usuarioId, manager);
        });
    }

    async update(id: number, dto: UpdateTrabajadorDto, usuarioId: number): Promise<TrabajadorResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            let dtoNormalizado = { ...dto };

            await this.tablaValidador.validarPreUpdate(
                this.nombreTabla,
                id,
                dtoNormalizado,
                this.campoPK,
                usuarioId,
            );

            const trabajadorActual = await manager.findOne(Trabajador, {
                where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO },
            });

            if (!trabajadorActual) {
                throw new DomainException('Trabajador no encontrado.', {
                    httpStatus: HttpStatus.NOT_FOUND,
                });
            }

            if (dtoNormalizado.genero_id && dtoNormalizado.estado_civil_id) {
                await this.validarEstadoCivilPorGenero(dtoNormalizado.genero_id, dtoNormalizado.estado_civil_id);
            } else if (dtoNormalizado.genero_id && trabajadorActual.genero_id) {
                await this.validarEstadoCivilPorGenero(dtoNormalizado.genero_id, trabajadorActual.estado_civil_id);
            } else if (dtoNormalizado.estado_civil_id && trabajadorActual.genero_id) {
                await this.validarEstadoCivilPorGenero(trabajadorActual.genero_id, dtoNormalizado.estado_civil_id);
            }

            dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
                this.nombreTabla,
                id,
                dtoNormalizado,
                FindTrabajadoresQueryDto.getDependencias(),
                FindTrabajadoresQueryDto.getCamposProtegidosConDependencias(),
                this.campoPK,
                usuarioId
            );

            const validaciones: Promise<any>[] = [];

            if (dtoNormalizado.nombres || dtoNormalizado.paterno || dtoNormalizado.materno !== undefined) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campoPk: this.campoPK,
                        idExcluir: id,
                        campos: [
                            {
                                nombre: 'nombres',
                                valor: dtoNormalizado.nombres ?? trabajadorActual.nombres,
                            },
                            {
                                nombre: 'paterno',
                                valor: dtoNormalizado.paterno ?? trabajadorActual.paterno,
                            },
                            {
                                nombre: 'materno',
                                valor: dtoNormalizado.materno ?? trabajadorActual.materno ?? '',
                            },
                        ],
                        estadosValidos: [...ESTADOS_VIVOS],
                    }),
                );
            }

            if (dtoNormalizado.dni) {
                validaciones.push(
                    this.unicidadValidador.validarUnicidad({
                        tabla: this.nombreTabla,
                        campoPk: this.campoPK,
                        idExcluir: id,
                        campos: [{ nombre: 'dni', valor: dtoNormalizado.dni }],
                        estadosValidos: [...ESTADOS_VIVOS],
                    }),
                );
            }

            if (validaciones.length > 0) {
                await Promise.all(validaciones);
            }

            if (dtoNormalizado.foto) {
                if (dtoNormalizado.foto === trabajadorActual.foto) {
                    delete dtoNormalizado.foto;
                }
            }

            const camposAfectados = Object.keys(dtoNormalizado).filter(
                key => key !== 'foto' && key !== 'qr',
            );

            if (camposAfectados.length > 0 || dtoNormalizado.foto !== undefined) {
                manager.merge(Trabajador, trabajadorActual, dtoNormalizado);
                trabajadorActual.update(usuarioId);
                await manager.save(trabajadorActual);
            }

            const nombreCambio = dtoNormalizado.nombres || dtoNormalizado.paterno || dtoNormalizado.materno !== undefined;
            if (dtoNormalizado.dni || nombreCambio) {
                await this.generarQRUtil.regenerarQR(id, manager);
            }

            return this.findOne<TrabajadorResponseDto>(id, usuarioId, manager);
        });
    }

    async regenerarQR(id: number, usuarioId: number): Promise<TrabajadorResponseDto> {
        return runInTransaction(this.dataSource, async (manager) => {
            await this.tablaValidador.validarRegistrosActivos(this.nombreTabla, this.campoPK, id);
            await this.tablaValidador.validarPermisoTabla(usuarioId, this.nombreTabla, 'editar');
            await this.generarQRUtil.regenerarQR(id, manager);
            return this.findOne<TrabajadorResponseDto>(id, usuarioId, manager);
        });
    }

    async obtenerUrlFoto(trabajadorId: number): Promise<string | null> {
        try {
            const trabajador = await this.findOne<Trabajador>(trabajadorId, 1);
            if (!trabajador?.foto) return null;

            const nombreArchivo = trabajador.foto.replace(/^persons\//, '');
            const existe = await this.fileValidator.validarArchivoFisico(nombreArchivo, 'persons');

            if (!existe) return null;

            return `/api/persons/${nombreArchivo}`;
        } catch (error) {
            this.customLogger.error(`Error al obtener URL de foto para trabajador ${trabajadorId}: ${error}`);
            return null;
        }
    }

    async tieneFotoFisica(trabajadorId: number): Promise<boolean> {
        try {
            const trabajador = await this.findOne<Trabajador>(trabajadorId, 1);
            if (!trabajador?.foto) return false;

            const nombreArchivo = trabajador.foto.replace(/^persons\//, '');
            return this.fileValidator.validarArchivoFisico(nombreArchivo, 'persons');
        } catch (error) {
            this.customLogger.error(`Error al verificar foto física para trabajador ${trabajadorId}: ${error}`);
            return false;
        }
    }

    async obtenerConfiguracionFotoPublic(): Promise<any> {
        try {
            return await this.configuracionService.obtenerValorTipado<any>('foto_trabajador_config');
        } catch (error) {
            this.customLogger.error(`Error al obtener configuración de foto: ${error}`);
            return null;
        }
    }

    async validarFotoExistente(nombreFoto: string): Promise<boolean> {
        if (!nombreFoto) { return false; }

        const nombreArchivo = nombreFoto.replace(/^persons\//, '');
        return this.fileValidator.validarArchivoFisico(nombreArchivo, 'persons');
    }
}
