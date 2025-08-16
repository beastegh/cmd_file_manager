@echo off
chcp 65001 >nul
REM Проверяем есть ли аргумент
if "%1"=="" (
    echo Использование: show полный_путь_к_папке
    exit /b 1
)

set TARGET=%1

if not exist "%TARGET%" (
    echo Ошибка: папка "%TARGET%" не найдена
    exit /b 1
)

attrib -h -s "%TARGET%"
echo Папка "%TARGET%" показана (атрибуты -h -s сняты).