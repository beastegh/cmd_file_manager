
@echo off

:: Получаем папку из параметра и удаляем кавычки
set "folder=%~1"
set folder=%folder:"=%

:: Если параметр пуст, берем текущую директорию
if not defined folder set "folder=%cd%"

:: Проверяем, что папка существует
if not exist "%folder%" (
  echo Ошибка: папка "%folder%" не существует.
  exit /b 1
)

:: Очищаем массивы и счётчики
for /L %%i in (0,1,9999) do (
  set "itemName[%%i]="
  set "itemType[%%i]="
)
set /a totalCount=0
set /a folderCount=0
set /a fileCount=0

:: Сбор папок (без системных и скрытых)
for /f "delims=" %%d in ('dir "%folder%" /A:D-H-S /B /O:N 2^>nul') do (
  set /a totalCount+=1
  set /a folderCount+=1
  set "itemName[!totalCount!]=%%d"
  set "itemType[!totalCount!]=p"
)

:: Сбор файлов (без системных и скрытых)
for /f "delims=" %%f in ('dir "%folder%" /A:-D-H-S /B /O:N 2^>nul') do (
  set /a totalCount+=1
  set /a fileCount+=1
  set "itemName[!totalCount!]=%%f"
  set "itemType[!totalCount!]=f"
)

exit /b 0

