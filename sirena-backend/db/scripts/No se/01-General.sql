tengo 
{
  "compilerOptions": {
    /* --- MÓDULO Y ENTORNO EJECUCIÓN --- */
    "module": "commonjs",                   // Define CommonJS como el sistema de módulos (Estándar nativo para NestJS/Node)
    "target": "ES2021",                     // Define la versión objetivo de ECMAScript a la que se transpilará el código JS final
    "outDir": "./dist",                     // Carpeta de salida donde se guardarán todos los archivos .js compilados
    "rootDir": "./src",                     // Carpeta raíz de los archivos fuente (.ts) para mantener la estructura al compilar

    /* --- CONFIGURACIÓN DE RUTAS Y ALIASES (Estándar Moderno TS 5.5+) --- */
    "paths": {                              // Mapeo de rutas cortas/aliases para evitar imports relativos largos
      "@/*": ["./src/*"]                    // Mapea directamente el alias '@/' hacia './src/' sin requerir 'baseUrl'
    },

    /* --- METADATOS Y DECORADORES (Requisito Vital NestJS) --- */
    "emitDecoratorMetadata": true,          // Emite metadatos de tipos para la inyección de dependencias en tiempo de ejecución
    "experimentalDecorators": true,         // Habilita el soporte para decoradores (@Injectable, @Controller, @Entity, etc.)

    /* --- RIGOR DE TIPADO Y CONTROL DE CALIDAD --- */
    "strict": true,                         // Activa de golpe todas las comprobaciones de tipado estricto en el proyecto
    "noImplicitOverride": true,             // Exige marcar explícitamente con 'override' métodos heredados que se sobreescriben
    "noUncheckedIndexedAccess": true,       // Añade 'undefined' al tipo devuelto al acceder a arreglos u objetos por índice
    "exactOptionalPropertyTypes": true,     // Diferencia strictly entre una propiedad ausente y una asignada como 'undefined'
    "noPropertyAccessFromIndexSignature": true, // Obliga a usar notación de corchetes obj['prop'] en mapas/diccionarios dinámicos
    "strictPropertyInitialization": false,  // Desactiva la inicialización obligatoria en constructor (Necesario por decoradores de Nest/TypeORM)
    "useUnknownInCatchVariables": true,     // Fuerza a que el error atrapado en bloques catch(err) sea de tipo 'unknown' en lugar de 'any'
    "noImplicitReturns": true,              // Asegura que todas las bifurcaciones (if/else) de una función devuelvan un valor explícito
    "noFallthroughCasesInSwitch": true,     // Evita que un caso en un switch continúe al siguiente sin un 'break' o 'return'
    "noImplicitThis": true,                 // Levanta error cuando el tipo del valor 'this' se infiere de forma implícita como 'any'
    "alwaysStrict": true,                   // Fuerza a que todo el JavaScript generado incluya "use strict" al inicio de cada archivo
    "noImplicitAny": true,                  // Prohíbe declarar variables o parámetros que infieran implícitamente el tipo 'any'
    "noUnusedLocals": true,                 // Emite error si existen variables locales declaradas que no se estén utilizando
    "noUnusedParameters": true,             // Emite error si existen parámetros de funciones o métodos que no se estén utilizando

    /* --- RENDIMIENTO Y SALIDA DE COMPILACIÓN --- */
    "noEmit": false,                        // Permite que TypeScript genere físicamente los archivos compilados en la carpeta /dist
    "sourceMap": true,                      // Genera archivos .js.map que mapean el código .js compilado con el .ts original
    "incremental": false,                    // Activa la caché (.tsbuildinfo) para que las recompilaciones al desarrollar sean instantáneas
    "skipLibCheck": true,                   // Omite la verificación de tipos de las librerías en node_modules para acelerar la compilación
    "allowSyntheticDefaultImports": true,    // Permite hacer 'import React from' aunque la librería no tenga un 'default export' explícito
    "esModuleInterop": true,                  // Garantiza interoperabilidad limpia entre librerías formato CommonJS y ES Modules
    "forceConsistentCasingInFileNames": true, // Fuerza a respetar estrictamente mayúsculas/minúsculas en nombres de archivos
    "removeComments": true                    // Compacta el código generado en /dist eliminando todos los comentarios del código fuente
  },
  "include": ["src/**/*"],                  // Especifica qué archivos deben ser procesados e incluidos por el compilador
  "exclude": [                              // Especifica qué carpetas o patrones deben ser ignorados por el compilador
    "node_modules",                         // Ignora el directorio de dependencias instaladas
    "dist",                                 // Ignora la carpeta de salida compilada
    "test",                                 // Ignora la carpeta de pruebas e2e/integración
    "**/*.spec.ts"                          // Ignora los archivos unitarios de prueba
  ]
}

