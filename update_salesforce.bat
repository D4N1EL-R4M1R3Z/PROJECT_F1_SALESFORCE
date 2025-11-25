
@echo off
echo ============================================
echo   Flujo Automatizado: Salesforce DX + Git
echo ============================================

REM 1. Retrieve desde Salesforce Org
echo Recuperando metadatos desde el org Daniel...
sf project retrieve start --manifest manifest/package.xml
sf project retrieve start --classes

REM 2. Agregar cambios a Git
echo Agregando cambios a Git...
git add .

REM 3. Crear commit
set /p msg="Update changes in Project Final "
git commit -m "%msg%"

REM 4. Hacer push a GitHub
echo Subiendo cambios a GitHub de Daniel...
git push origin main

echo ============================================
echo   ¡Proceso completado con éxito.....!
echo ============================================
pause

