-- ================================================================================================

Actúa como un DBA (Database Administrator) experto en PostgreSQL. 

Tengo una base de datos completa y necesito que hagas una auditoría estricta exclusivamente de las restricciones de llaves foráneas (FOREIGN KEY).

### Regla Estricta de Nombrado para los FK:
Cada FOREIGN KEY debe seguir exactamente esta estructura de nomenclatura:
CONSTRAINT fk_[nombre_tabla_sin_guiones]_[columna_local] FOREIGN KEY ([columna_local]) REFERENCES [tabla_ref]([columna_ref])

Ejemplo correcto: 
CONSTRAINT fk_tiposcambios_origen_moneda_id FOREIGN KEY (origen_moneda_id) REFERENCES dominios(dominio_id)

### Instrucciones Críticas (Obligatorias):
1. **IGNORA por completo las restricciones tipo CHECK:** No menciones, evalúes ni listes ningún `CHECK` bajo ninguna circunstancia. Concéntrate únicamente en las líneas que dicen `FOREIGN KEY`.
2. **FILTRADO ESTRICTO DE SALIDA:** No muestres absolutamente nada sobre las llaves foráneas que SÍ cumplen con la regla. 
3. **EXCLUSIÓN DE FALSOS POSITIVOS:** Si una llave foránea cumple perfectamente con la regla, **no la incluyas en el reporte**.
4. **FORMATO DE REPORTE:** Lista **únicamente** los FK que fallen. Para cada uno, muestra estrictamente este formato:
   - **Tabla:** [nombre]
   - **FK Incorrecto:** [nombre actual]
   - **Debería llamarse:** [nombre correcto según la regla]

Aquí está el código SQL de la base de datos:
[PEGA TU CÓDIGO SQL DE TODA LA BD AQUÍ]

-- ================================================================================================

