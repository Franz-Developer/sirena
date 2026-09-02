# VALKIRIA Backend

## Comandos principales

### Limpiar compilación

```bash
npm run clean
```

Borra la carpeta `dist` y la caché incremental de TypeScript (`tsconfig.tsbuildinfo`).

### Compilar

```bash
npm run build
```

Compila el proyecto NestJS y genera la carpeta `dist`.

### Desarrollo

```bash
npm run start:dev
```

Inicia el backend en modo desarrollo con recompilación automática.

### Producción

```bash
npm run start:prod
```

Ejecuta el backend compilado desde `dist/main.js`.

### Generar llaves RSA

```bash
npm run gen:keys
```

Ejecuta:

```text
src/scripts/generar-llaves.ts
```

### Crear contraseña encriptada

```bash
npm run crear:password
```

Ejecuta:

```text
src/scripts/crear-password.ts
```