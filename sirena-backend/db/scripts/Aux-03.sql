import { obtenerNombreAmigableTabla } from '../constants/nombres-tablas.constant';

como uso en async validarPreDelete( para 
	
que no muestre este mensaje 
{
  "message": "No se puede eliminar Bancos porque tiene registros relacionados en: Cuentas Bancarias, Clientes y Comprobantes de Pagos."
}

sino que muestre 
{
  "message": "No se puede eliminar el banco porque tiene registros relacionados en: Cuentas Bancarias, Clientes y Comprobantes de Pagos."
}

y que pasa si solo existe una dependencia 
mostrara 
{
  "message": "No se puede eliminar el banco porque tiene registros relacionados en: Cuentas Bancarias."
}
	
async validarPreDelete(
        tablaOrigen: string,
        pkId: number,
        tablasDependientes: Array<string | { tabla: string; campoFk: string }>,
        campoFkDefault: string,
        usuarioId: number,
    ): Promise<void> {
        const tablaNormalizada = tablaOrigen.toLowerCase().trim();

        if (Number(pkId) === 1) {
            throw new DomainException(
                `Operación denegada: El registro con ID = 1 en la tabla '${tablaNormalizada}' es un registro comodín del sistema y no puede ser eliminado. Esta restricción protege la integridad referencial de los datos maestros.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'REGISTRO_COMODIN_PROTEGIDO'
                }
            );
        }

        if (tablaNormalizada === 'usuarios' && Number(pkId) === 2) {
            throw new DomainException(
                `Operación denegada: El usuario administrador principal del sistema ADMIN es un registro crítico que no puede ser eliminado. Esta restricción asegura que siempre exista un usuario con privilegios de administrador en el sistema.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'USUARIO_ADMIN_PROTEGIDO'
                }
            );
        }

        await this.validarPermisoTabla(usuarioId, tablaNormalizada, 'eliminar');

        const tablaSanitizada = this.dataSource.escapeIdentifier(tablaNormalizada);
        const campoPkSanitizado = this.dataSource.escapeIdentifier(campoFkDefault || 'id');

        const query = `
            SELECT estado_id, fecha_baja, ${tablaNormalizada === 'parametros_globales' ? 'editable' : '0 AS editable'}
            FROM ${tablaSanitizada}
            WHERE ${campoPkSanitizado} = $1
                AND estado_id = $2
                AND fecha_baja IS NULL
            LIMIT 1
        `;
        const params = [pkId, ESTADO_ACTIVO];
        logSqlQuery(query, params, `validarPreDelete - ${tablaSanitizada}`);

        let existeResult;
        try {
            existeResult = await this.dataSource.query(query, params);
        } catch (error) {
            if (isDomainException(error)) throw error;

            const errorMessage = getErrorMessage(error);
            throw new DomainException(
                `Error interno al verificar la existencia del registro con ${campoPkSanitizado} = ${pkId} en la tabla '${tablaNormalizada}'. Detalle técnico: ${errorMessage}. Por favor, contacte al administrador del sistema.`,
                {
                    tabla: tablaNormalizada,
                    pkId,
                    campoPk: campoFkDefault,
                    originalError: errorMessage,
                    httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                }
            );
        }

        if (!existeResult || existeResult.length === 0) {
            throw new DomainException(
                `No se encontró un registro activo con ID ${pkId}. La operación de eliminación requiere que el registro exista y esté activo.`,
                {
                    httpStatus: HttpStatus.NOT_FOUND,
                    tabla: tablaNormalizada,
                    campoPk: campoFkDefault,
                    pkId,
                }
            );
        }

        const registro = existeResult[0];

        if (tablaNormalizada === 'parametros_globales' && Number(registro['editable']) === 1) {
            throw new DomainException(
                `Operación denegada: El parámetro global con ID = ${pkId} en la tabla '${tablaNormalizada}' está marcado como NO editable y no puede ser eliminado. Solo los parámetros editables pueden ser eliminados.`,
                {
                    httpStatus: HttpStatus.FORBIDDEN,
                    tabla: tablaNormalizada,
                    pkId,
                    motivo: 'PARAMETRO_NO_EDITABLE'
                }
            );
        }

        if (tablasDependientes && tablasDependientes.length > 0) {
            let tieneDependencias = false;
            try {
                tieneDependencias = await this.validarDependencias(
                    tablaOrigen,
                    pkId,
                    tablasDependientes,
                    campoFkDefault,
                );
            } catch (error) {
                if (isDomainException(error)) throw error;

                const errorMessage = getErrorMessage(error);
                this.logger.error(`Error al validar dependencias para ${tablaNormalizada}#${pkId}: ${errorMessage}`, getErrorStack(error));

                const tablasDependientesStr = tablasDependientes
                    .map(item => typeof item === 'string' ? item : `${item.tabla}(${item.campoFk})`)
                    .join(', ');

                throw new DomainException(
                    `Error interno al validar dependencias del registro con ${campoFkDefault} = ${pkId} en la tabla '${tablaNormalizada}'. Tablas dependientes verificadas: [${tablasDependientesStr}]. Detalle técnico: ${errorMessage}. Por favor, contacte al administrador del sistema.`,
                    {
                        tabla: tablaNormalizada,
                        pkId,
                        campoPk: campoFkDefault,
                        tablasDependientes: tablasDependientesStr,
                        originalError: errorMessage,
                        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
                    }
                );
            }

            if (tieneDependencias) {
                const nombres = tablasDependientes.map(item =>
                    obtenerNombreAmigableTabla(typeof item === 'string' ? item : item.tabla)
                );

                const lista = nombres.length === 1
                    ? nombres[0]
                    : nombres.slice(0, -1).join(', ') + ' y ' + nombres[nombres.length - 1];

                const nombreEntidad = obtenerNombreAmigableTabla(tablaNormalizada);

                // Detalle técnico solo en consola
                console.warn(
                    `[DEPENDENCIAS_ACTIVAS] ${tablaNormalizada}#${pkId} (usuario ${usuarioId}) → ` +
                    tablasDependientes.map(i => typeof i === 'string' ? i : `${i.tabla}(${i.campoFk})`).join(', ')
                );

                throw new DomainException(
                    `No se puede eliminar ${nombreEntidad} porque tiene registros relacionados en: ${lista}. Primero debe archivar o eliminar los registros de esas secciones.`
                );
            }
        }
    }