@echo off
chcp 65001 >nul
cls
color 0A
setlocal enabledelayedexpansion

:MENU
cls
echo =======================================================
echo   1. Iniciar Backend (start:dev)
echo   2. Backend-menu
echo   3. Iniciar Frontend
echo   4. Consolidar Archivos TypeScript (.ts)
echo   5. Consolidar Archivos Vue (.vue)
echo   6. Consolidar Archivos Python (.py)
echo   7. Crear Backup Completo (Excluyendo node_modules/venv)
echo   8. Exportar la dbsirena
echo   9. Cerrar Puerto de Red
echo  10. Ejecutar SQL
echo  11. Ejecutar DDL
echo  12. Generar Constantes (Ejecutar genera.py)
echo  13. Actualizar nombres de archivos (Ejecutar actualizar_nombre_archivo.py)
echo  14. Salir
echo =======================================================

set /p op="Seleccione una opcion [1-14]: "

if "%op%"=="1" goto INICIAR_BACKEND_DIRECTO
if "%op%"=="2" goto MENU_BACKEND
if "%op%"=="3" goto FRONTEND
if "%op%"=="4" goto CONSOLIDAR_TS
if "%op%"=="5" goto CONSOLIDAR_VUE
if "%op%"=="6" goto CONSOLIDAR_PY
if "%op%"=="7" goto BACKUP
if "%op%"=="8" goto EXPORTAR_DB
if "%op%"=="9" goto PUERTO
if "%op%"=="10" goto SQL
if "%op%"=="11" goto DDL
if "%op%"=="12" goto GENERAR_CONSTANTES
if "%op%"=="13" goto ACTUALIZAR_NOMBRES
if "%op%"=="14" goto SALIR

echo. Opcion no valida. Intente de nuevo.
timeout /t 2 >nul
goto MENU

:: =======================================================
:: OPT 1: INICIAR BACKEND DIRECTO
:: =======================================================
:INICIAR_BACKEND_DIRECTO
cls
cd /d C:\sirena\sirena-backend
echo Iniciando Backend (start:dev)...
npm run start:dev
goto SALIR

:: =======================================================
:: OPT 2: MENU BACKEND
:: =======================================================
:MENU_BACKEND
cls
cd /d C:\sirena\sirena-backend
echo ==========================
echo sirena BACKEND
echo ==========================
echo 1. Iniciar Backend (start:dev)
echo 2. Compilar (build)
echo 3. Limpiar (clean)
echo 4. Generar Llaves (gen:keys)
echo 5. Crear Password (crear:password)
echo 6. Reiniciar Password (reiniciar:password)
echo 7. Ejecutar Query (db:query)
echo 8. Volver al Menu Principal
echo 9. Salir
echo ==========================

set /p op_b="Seleccione una opcion [1-9]: "

if "%op_b%"=="1" ( npm run start:dev & goto SALIR )
if "%op_b%"=="2" ( npm run build & goto SALIR )
if "%op_b%"=="3" ( npm run clean & goto SALIR )
if "%op_b%"=="4" ( npm run gen:keys & goto SALIR )
if "%op_b%"=="5" ( npm run crear:password & goto SALIR )
if "%op_b%"=="6" ( npm run reiniciar:password & goto SALIR )
if "%op_b%"=="7" ( npm run db:query & goto SALIR )
if "%op_b%"=="8" goto MENU
if "%op_b%"=="9" goto SALIR

echo Opcion no valida.
timeout /t 2 >nul
goto MENU_BACKEND

:: =======================================================
:: OPT 3: FRONTEND
:: =======================================================
:FRONTEND
cls
title Limpiando Proyecto Prisma / Frontend
echo ===========================================
echo    Limpiando cache y archivos temporales...
echo ===========================================

cd /d "C:\sirena\sirena-frontend"

if exist ".nuxt" (
    echo Borrando .nuxt...
    rd /s /q ".nuxt"
)
if exist "node_modules\.cache" (
    echo Borrando node_modules\.cache...
    rd /s /q "node_modules\.cache"
)
if exist "dist" (
    echo Borrando dist...
    rd /s /q "dist"
)

echo.
echo ===========================================
echo    Limpieza completada. Iniciando Frontend...
echo ===========================================
echo.

npm run dev
goto SALIR

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

:: =======================================================
:: OPT 5: CONSOLIDAR ARCHIVOS .VUE
:: =======================================================
:CONSOLIDAR_VUE
cls
echo ============================================
echo Consolidando archivos Vue (.vue)
echo ============================================
echo.

set /p "USER_PATH=Ingrese la ruta o carpeta a buscar (Dejar en blanco para usar por defecto): "
set FRONTEND_DIR=sirena-frontend
set DEFAULT_OUTPUT=frontend_consolidado_vue.txt

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
    set SOURCE_DIR=%FRONTEND_DIR%
) else (
    if exist "%USER_PATH%" (
        set SOURCE_DIR=%USER_PATH%
    ) else if exist "%FRONTEND_DIR%\%USER_PATH%" (
        set SOURCE_DIR=%FRONTEND_DIR%\%USER_PATH%
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
echo ARCHIVO CONSOLIDADO VUE (.VUE) > "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo Generado: %date% %time% >> "%OUTPUT_FILE%"
echo Directorio analizado: %SOURCE_DIR% >> "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

set COUNT=0
echo Buscando archivos .vue ...

for /R "%SOURCE_DIR%" %%f in (*.vue) do (
    echo "%%f" | findstr /i "node_modules" >nul
    if errorlevel 1 (
        echo "%%f" | findstr /i "\.nuxt" >nul
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

:: =======================================================
:: OPT 6: CONSOLIDAR ARCHIVOS .PY
:: =======================================================
:CONSOLIDAR_PY
cls
echo ============================================
echo Consolidando archivos Python (.py)
echo ============================================
echo.

set /p "USER_PATH=Ingrese la ruta o carpeta a buscar (Dejar en blanco para usar por defecto): "
set MOTOR_DIR=sirena-motor-python
set DEFAULT_OUTPUT=motor_python_py.txt

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
    set SOURCE_DIR=%MOTOR_DIR%
) else (
    if exist "%USER_PATH%" (
        set SOURCE_DIR=%USER_PATH%
    ) else if exist "%MOTOR_DIR%\%USER_PATH%" (
        set SOURCE_DIR=%MOTOR_DIR%\%USER_PATH%
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
echo ARCHIVO CONSOLIDADO PYTHON (.PY) > "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo Generado: %date% %time% >> "%OUTPUT_FILE%"
echo Directorio analizado: %SOURCE_DIR% >> "%OUTPUT_FILE%"
echo ============================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

set COUNT=0
echo Buscando archivos .py ...

for /R "%SOURCE_DIR%" %%f in (*.py) do (
    echo "%%f" | findstr /i "venv" >nul
    if errorlevel 1 (
        echo "%%f" | findstr /i "__pycache__" >nul
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

:: =======================================================
:: OPT 7: BACKUP COMPLETO
:: =======================================================
:BACKUP
cls
echo Generando respaldo del proyecto...

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set FECHAHORA=%%i

set BASE=C:\sirena
set DESTINO=C:\sirena-%FECHAHORA%

mkdir "%DESTINO%"

echo.
echo Copiando BACKEND...
robocopy "%BASE%\sirena-backend" "%DESTINO%\sirena-backend" /E /XD node_modules

echo.
echo Copiando FRONTEND...
robocopy "%BASE%\sirena-frontend" "%DESTINO%\sirena-frontend" /E /XD node_modules .nuxt dist

echo.
echo Copiando MOTOR PRONOSTICO (excluyendo venv)...
robocopy "%BASE%\sirena-motor-python" "%DESTINO%\sirena-motor-python" /E /XD venv __pycache__

echo.
echo =======================================================
echo PROCESO COMPLETADO EXITOSAMENTE
echo Carpeta creada en: %DESTINO%
echo =======================================================
goto SALIR

:: =======================================================
:: OPT 8: EXPORTAR BASE DE DATOS DBSIRENA
:: =======================================================
:EXPORTAR_DB
cls
echo ========================================================
echo Exportando base de datos dbsirena...
echo ========================================================

:: Configuración de la Base de Datos
set "DB_HOST=localhost"
set "DB_PORT=5432"
set "DB_USERNAME=postgres"
set "DB_PASSWORD=123456"
set "DB_DATABASE=dbsirena"

:: Ruta y nombre del archivo de salida
set "OUTPUT_FILE=C:\sirena\sirena-backend\db\dbsirena_completo.sql"

:: Crear el directorio db si no existe
if not exist "C:\sirena\sirena-backend\db" (
    mkdir "C:\sirena\sirena-backend\db"
    echo [INFO] Carpeta db creada en sirena-backend
)

echo ========================================================
echo Iniciando exportacion completa y avanzada de la base de datos...
echo ========================================================

:: Configurar la variable de entorno para la contraseña y evitar que la pida en consola
set "PGPASSWORD=%DB_PASSWORD%"

:: Ejecutar pg_dump incluyendo funciones, triggers, vistas, esquemas, datos y limpieza de comandos de propiedad
pg_dump -h %DB_HOST% -p %DB_PORT% -U %DB_USERNAME% -d %DB_DATABASE% -F p -b -v --no-owner --no-privileges -f "%OUTPUT_FILE%"

echo.
echo ========================================================
echo Proceso finalizado. Archivo guardado en:
echo %OUTPUT_FILE%
echo ========================================================
goto SALIR

:: =======================================================
:: OPT 9: BUSCAR Y CERRAR PUERTO
:: =======================================================
:PUERTO
cls
set /p puerto="Ingrese el numero de puerto a consultar/liberar (Ej: 3010): "

if "%puerto%"=="" (
    echo [ERROR] Debes especificar un puerto.
    goto SALIR
)

echo Buscando procesos en el puerto: %puerto%
echo -------------------------------------------

set "found_pid="

for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%puerto% ^| findstr LISTENING') do (
    set "found_pid=%%a"
)

if "!found_pid!"=="" (
    echo No se encontraron procesos activos en el puerto %puerto%
    echo -------------------------------------------
) else (
    netstat -ano | findstr :%puerto% | findstr LISTENING
    echo -------------------------------------------

    echo DETALLE DEL PROCESO ENCONTRADO:
    tasklist /FI "PID eq !found_pid!"
    echo -------------------------------------------

    set /p respuesta="Deseas cerrar este proceso? (y/n): "

    if /i "!respuesta!"=="y" (
        taskkill /F /PID !found_pid!
        echo.
        echo Puerto %puerto% liberado con exito.
    ) else (
        echo.
        echo Operacion cancelada. El proceso sigue activo.
    )
)
goto SALIR

:: =======================================================
:: OPT 10: EJECUTAR SQL (db:query)
:: =======================================================
:SQL
cls
cd /d C:\sirena\sirena-backend
echo ========================================================
echo Ejecutando db:query...
echo ========================================================
echo.
npm run db:query
echo.
echo ========================================================
echo Proceso finalizado.
echo ========================================================
goto SALIR

:: =======================================================
:: OPT 11: EJECUTAR DDL (db:ddl)
:: =======================================================
:DDL
cls
cd /d C:\sirena\sirena-backend
echo ========================================================
echo Generacion de DDL de Tablas (db:ddl)
echo ========================================================
echo.
set /p "tablas=Ingrese los nombres de las tablas separados por espacios (Ej: clientes sucursales productos): "

if "%tablas%"=="" (
    echo [ERROR] No ingresaste ninguna tabla.
    timeout /t 2 >nul
    goto SALIR
)

echo.
echo Ejecutando: npm run db:ddl -- %tablas%
echo --------------------------------------------------------
npm --silent run db:ddl -- %tablas%
echo.
echo ========================================================
echo Proceso finalizado. Archivo guardado en:
echo C:\sirena\sirena-backend\db\query\salida.sql
echo ========================================================
goto SALIR

:: =======================================================
:: OPT 12: GENERAR CONSTANTES (genera.py)
:: =======================================================
:GENERAR_CONSTANTES
cls
echo ========================================================
echo Ejecutando script de generacion de constantes...
echo ========================================================
echo.
if exist "C:\sirena\script-python\genera.py" (
    python C:\sirena\script-python\genera.py
) else (
    echo [ERROR] No se encuentra el archivo C:\sirena\script-python\genera.py
)
echo.
echo ========================================================
echo Proceso finalizado.
echo ========================================================
goto SALIR

:: =======================================================
:: OPT 13: ACTUALIZAR NOMBRES DE ARCHIVOS (actualizar_nombre_archivo.py)
:: =======================================================
:ACTUALIZAR_NOMBRES
cls
echo ========================================================
echo Ejecutando script de actualizacion de nombres de archivos...
echo ========================================================
echo.
if exist "C:\sirena\script-python\actualizar_nombre_archivo.py" (
    python C:\sirena\script-python\actualizar_nombre_archivo.py
) else (
    echo [ERROR] No se encuentra el archivo C:\sirena\script-python\actualizar_nombre_archivo.py
)
echo.
echo ========================================================
echo Proceso finalizado.
echo ========================================================
goto SALIR

:: =======================================================
:: OPT 14: SALIR
:: =======================================================
:SALIR
endlocal
exit /b