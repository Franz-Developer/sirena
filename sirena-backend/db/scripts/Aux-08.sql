async update(id: number, dto: UpdateBancoDto, usuarioId: number): Promise<BancoResponseDto> {
    return runInTransaction(this.dataSource, async (manager) => {
        let dtoNormalizado = { ...dto };

        if (dtoNormalizado.banco) {
            dtoNormalizado.banco = dtoNormalizado.banco.trim().toUpperCase();
        }

        if (dtoNormalizado.codigo_asfi) {
            dtoNormalizado.codigo_asfi = dtoNormalizado.codigo_asfi.trim().padStart(2, '0');
        }

        await this.tablaValidador.validarPreUpdate(this.nombreTabla, id, dtoNormalizado, this.campoPK, usuarioId);

        const bancoActual = await manager.findOne(Banco, {
            where: { [this.campoPK]: id, estado_id: ESTADO_ACTIVO }
        });

        if (!bancoActual) {
			throw new DomainException(
				`Banco no encontrado.`,
				{ httpStatus: HttpStatus.NOT_FOUND }
			);
		}

        // Centralización de dependencias y permisos de Administrador (1 sola línea)
        dtoNormalizado = await this.tablaValidador.procesarCamposProtegidos(
            this.nombreTabla,
            id,
            dtoNormalizado,
            FindBancosQueryDto.getDependencias(),
            FindBancosQueryDto.getCamposProtegidosConDependencias(),
            this.campoPK,
            usuarioId
        );

        // Las validaciones de unicidad continúan ejecutándose sobre los campos que sobrevivieron al DTO
        const validaciones: Promise<any>[] = [];

        if (dtoNormalizado.codigo_asfi && dtoNormalizado.codigo_asfi !== bancoActual.codigo_asfi) {
            validaciones.push(
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'codigo_asfi', valor: dtoNormalizado.codigo_asfi }],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                })
            );
        }

        if (dtoNormalizado.abreviatura && dtoNormalizado.abreviatura !== bancoActual.abreviatura) {
            validaciones.push(
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'abreviatura', valor: dtoNormalizado.abreviatura }],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                })
            );
        }

        if (dtoNormalizado.banco && dtoNormalizado.banco !== bancoActual.banco) {
            validaciones.push(
                this.unicidadValidador.validarUnicidad({
                    tabla: this.nombreTabla,
                    campos: [{ nombre: 'banco', valor: dtoNormalizado.banco }],
                    idExcluir: id,
                    campoPk: this.campoPK,
                    estadosValidos: [...ESTADOS_VIVOS]
                })
            );
        }

        if (validaciones.length > 0) {
            await Promise.all(validaciones);
        }

        Object.assign(bancoActual, dtoNormalizado);
        bancoActual.update(usuarioId);

        try {
            await manager.save(bancoActual);
            return this.findOne(id, usuarioId, manager);
        } catch (error: unknown) {
            if (isDomainException(error)) throw error;
            this.logger.error(`Error: ${getErrorMessage(error)}`, getErrorStack(error));
            throw error;
        }
    });
}