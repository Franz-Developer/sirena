
ANALIZALO a fondo 
Dime si existe un error o algo que no se esta validando en el modulo bancos
Debes advertirme si algo no se esta controlando o algo es ilogico o algo no es coherente con el DDL de la tabla 
La validación y normalización de datos DEBE estar en el DTO. El servicio NO debe duplicar esta lógica.
La validación y normalización de datos DEBE estar en el DTO. El servicio NO debe duplicar esta lógica.
EN EL DTO no puede haber valores por defecto eso debe esta en el archivo entity
Si esta bien no solo responde SIN ERROR
Si encuentras errores 
has una lista de ERRORES No. XXX PERO AYUPADOS POR archivo 
Explicacion: nombre de archivo, funcion, corta y simple  
USAR LENGUAJE tecnico y formal 
TODOS LOS ERRORES de un archivo deben estar separados por archivo debe ir estrictamente dentro de las comillas invertidas de Markdown o backticks.

LUEGO mostrar el archivo completo y mejorado solo AUMENTAR comentarios que indique que se aumento o elimino usar emoji 👈 
LUEGO mostrar el archivo completo y mejorado solo AUMENTAR comentarios que indique que se aumento o elimino usar emoji 👈 




ANALIZALO A FONDO y haz una lista de todas las tablas en orden de creacion y quiero una descripcion completa que es lo que hace y que constantes controla no tomar en estado_id
FORMATO DE SALDA: 

NOMBRE_TABLA: Descripcion 


que aumento para que no tome en cuenta las carpetas 
C:\sirena\sirena-backend\node_modules
C:\sirena\sirena-backend\dist
C:\sirena\sirena-frontend\node_modules
C:\sirena\sirena-frontend\.nuxt


:: =======================================================
:: OPT 4: CONSOLIDAR ARCHIVOS .TS
:: =======================================================
:CONSOLIDAR_TS
cls
echo ============================================
echo Consolidando archivos TypeScript (.ts)
echo ============================================
echo.

set /p "USER_PATH=Ingrese la ruta o carpeta a buscar (Dejar en blanco para usar por defecto): "
set BACKEND_DIR=sirena-backend
set DEFAULT_OUTPUT=backend_consolidado_ts.txt

set /p "USER_OUTPUT=Ingrese el nombre del archivo de salida [Por defecto: %DEFAULT_OUTPUT%]: "
if "%USER_OUTPUT%"==" " set USER_OUTPUT=
if "%USER_OUTPUT%"=="" (
    set OUTPUT_NAME=%DEFAULT_OUTPUT%
) else (
    set OUTPUT_NAME=%USER_OUTPUT%
)

set OUTPUT_DIR=C:\sirena\salida
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
    echo [INFO] Carpeta de salida creada: %OUTPUT_DIR%
)

set OUTPUT_FILE=%OUTPUT_DIR%\%OUTPUT_NAME%

if "%USER_PATH%"=="" (
    set SOURCE_DIR=%BACKEND_DIR%\src
) else (
    if exist "%USER_PATH%" (
        set SOURCE_DIR=%USER_PATH%
    ) else if exist "%BACKEND_DIR%\%USER_PATH%" (
        set SOURCE_DIR=%BACKEND_DIR%\%USER_PATH%
    ) else if exist "%BACKEND_DIR%\src\%USER_PATH%" (
        set SOURCE_DIR=%BACKEND_DIR%\src\%USER_PATH%
    ) else (
        echo [ERROR] La ruta especificada no existe: %USER_PATH%
        goto SALIR
    )
)

if not exist "%SOURCE_DIR%" (
    echo [ERROR] No se encuentra la carpeta de busqueda: %SOURCE_DIR%
    goto SALIR
)

echo Directorio en uso: %SOURCE_DIR%
echo Archivo de salida: %OUTPUT_FILE%

if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"
echo ARCHIVO CONSOLIDADO TYPESCRIPT (.TS) > "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo Generado: %date% %time% >> "%OUTPUT_FILE%"
echo Directorio analizado: %SOURCE_DIR% >> "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

set COUNT=0
echo Buscando archivos .ts ...

for /R "%SOURCE_DIR%" %%f in (*.ts) do (
    echo "%%f" | findstr /i "node_modules" >nul
    if errorlevel 1 (
        echo "%%f" | findstr /i "dist" >nul
        if errorlevel 1 (
            set /a COUNT+=1
            echo Procesando: %%f
            set "FILE_PATH[!COUNT!]=%%f"
            echo. >> "%OUTPUT_FILE%"
            echo ---- %%f ---- >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            type "%%f" >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
        )
    )
)

echo. >> "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo RESUMEN DE ARCHIVOS CONSOLIDADOS: >> "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
for /l %%i in (1,1,%COUNT%) do (
    echo [%%i] !FILE_PATH[%%i]! >> "%OUTPUT_FILE%"
)
echo ============================================ >> "%OUTPUT_FILE%"
echo Total de archivos procesados: !COUNT! >> "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"

echo.
echo ============================================
echo PROCESO COMPLETADO
echo Archivos procesados: !COUNT!
echo Archivo generado en: %OUTPUT_FILE%
echo ============================================
goto SALIR
