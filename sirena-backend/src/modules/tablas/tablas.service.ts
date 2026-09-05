// C:\sirena\sirena-backend\src\modules\tablas\tablas.service.ts
import { Injectable } from '@nestjs/common';
import { FindTablasQueryDto } from './dto/find-tablas-query.dto';
import { TABLAS_ARRAY } from '../../common/constants/tablas.constant';

@Injectable()
export class TablasService {
    findAll(queryDto: FindTablasQueryDto): string[] {
        let tablas = TABLAS_ARRAY.map(t => t.toLowerCase());

        if (queryDto.q?.trim()) {
            const searchTerm = queryDto.q.trim().toLowerCase();
            tablas = tablas.filter(tabla => tabla.includes(searchTerm));
        }

        return tablas.sort();
		}
}
