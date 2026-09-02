// C:\sirena\sirena-backend\src\common\dto\base-pagination-query.dto.ts
import { BadRequestException } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsOptional, IsInt, IsString, Min, IsIn, Max } from 'class-validator';

export abstract class BasePaginationQueryDto {
    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'offset debe ser un número entero.' })
    @Min(0, { message: 'offset debe ser >= 0' })
    offset?: number;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'limit debe ser un número entero.' })
    @Min(1, { message: 'limit debe ser >= 1' })
    @Max(100, { message: 'limit no puede exceder 100 registros.' })
    limit?: number;

    @IsOptional()
    @IsString({ message: 'El campo sortField debe ser una cadena de texto.' })
    sortField?: string;

    @IsOptional()
    @Type(() => Number)
    @IsInt({ message: 'El campo sortOrder debe ser un número entero.' })
    @IsIn([1, -1] as const, { message: 'El campo sortOrder debe ser 1 (ascendente) o -1 (descendente).' })
    sortOrder?: 1 | -1;

    getOffset(): number {
        return this.offset ?? 0;
    }

    getLimit(): number {
        return this.limit ?? 10;
    }

    getSortOrder(): 1 | -1 {
        return this.sortOrder ?? -1;
    }

    getOrderDirection(): 'ASC' | 'DESC' {
        return this.getSortOrder() === 1 ? 'ASC' : 'DESC';
    }

    hasPagination(): boolean {
        return this.offset !== undefined || this.limit !== undefined;
    }

    hasSorting(): boolean {
        return this.sortField !== undefined || this.sortOrder !== undefined;
    }

    getPaginationClause(): string {
        return `LIMIT ${this.getLimit()} OFFSET ${this.getOffset()}`;
    }

    // 🔄 Métodos de ordenamiento centralizados en la clase base
    // Los DTOs hijos pueden sobreescribirlos si necesitan campos específicos,
    // pero si no lo hacen, usarán estos valores por defecto seguros.
    protected getDefaultSortField(): string {
        return 'id';
    }

    protected getAllowedSortFields(): string[] {
        return ['id', 'fecha_registro'];
    }

    protected getSortFieldMapping(): Record<string, string> {
        return {};
    }

    public getValidatedSortField(): string {
        const field = this.sortField ?? this.getDefaultSortField();
        const mapping = this.getSortFieldMapping();
        const targetField = mapping[field] ?? field;

        const allowed = this.getAllowedSortFields();
        if (!allowed.includes(targetField)) {
            return this.getDefaultSortField();
        }

        return targetField;
    }

    // 🔒 Métodos de seguridad para alias e identificadores SQL
    public validateAlias(alias: string): void {
        if (!alias || typeof alias !== 'string') {
            throw new BadRequestException('El alias de tabla es inválido');
        }
        if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(alias)) {
            throw new BadRequestException(`El alias "${alias}" contiene caracteres no permitidos`);
        }
        const sqlKeywords = ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER', 'CREATE', 'EXEC', 'UNION', 'WHERE'];
        if (sqlKeywords.some(keyword => alias.toUpperCase().includes(keyword))) {
            throw new BadRequestException(`El alias "${alias}" contiene palabras clave SQL no permitidas`);
        }
    }

    public escapeSqlIdentifier(identifier: string): string {
        const sanitized = identifier.replace(/[^a-zA-Z0-9_]/g, '');
        if (!sanitized) {
            throw new BadRequestException('Identificador SQL inválido');
        }
        if (/[A-Z]/.test(sanitized) || sanitized.includes('_')) {
            return `"${sanitized}"`;
        }
        return sanitized;
    }
}
