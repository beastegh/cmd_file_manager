@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Определяем корень гит-репозитория
for /f "delims=" %%r in ('git rev-parse --show-toplevel 2^>nul') do set "repoRoot=%%r"
if not defined repoRoot (
    echo Not inside a git repository.
    exit /b 1
)

REM Если аргументов нет, запрашиваем ввод
if "%~1"=="" (
    set /p query=Enter search term: 
) else (
    set "query=%*"
)

set "tempfile=%TEMP%\grep_results_%RANDOM%.txt"

git -C "%repoRoot%" -c core.quotepath=false grep -n --heading -I -i "%query%" > "%tempfile%"

set /a count=0
set "currentFile="

for /f "usebackq tokens=* delims=" %%a in ("%tempfile%") do (
    set "line=%%a"
    REM Заменяем табы на 2 пробела
    set "line=!line:	=  !"
    echo !line! | findstr ":" >nul
    if errorlevel 1 (
        set "currentFile=!line!"
        echo !currentFile!
    ) else (
        for /f "tokens=1* delims=:" %%i in ("!line!") do (
            set /a count+=1
            set "linenumber=%%i"
            set "matchtext=%%j"

            REM Убираем ведущие пробелы и табы из matchtext
            for /f "tokens=* delims= " %%x in ("!matchtext!") do set "matchtext=%%x"
            for /f "tokens=* delims=	" %%x in ("!matchtext!") do set "matchtext=%%x"

            REM Обрезаем matchtext до 40 символов с добавлением ...
            set "text=!matchtext:~0,80!"
            if not "!matchtext:~40,1!"=="" set "text=!text!..."

            REM Вывод с двумя пробелами после номера и точки
            echo !count!.  !text!

            set "line[!count!]=!currentFile!:!linenumber!"
        )
    )
)

if %count%==0 (
    echo No matches found.
    del "%tempfile%"
    exit /b 1
)

:choose
set /p choice=Enter number to open (q to exit): 

REM Выход по q или Q
if /i "%choice%"=="q" (
    del "%tempfile%"
    exit /b 0
)

REM Проверка пустого ввода
if "%choice%"=="" goto choose

REM Проверка на нечисловой ввод (если не q)
for /f "delims=0123456789" %%x in ("%choice%") do goto choose

REM Проверка диапазона
if %choice% lss 1 goto choose
if %choice% gtr %count% goto choose

set "selected=!line[%choice%]!"

for /f "tokens=1,2 delims=:" %%f in ("!selected!") do (
    set "filepath=%%f"
    set "linenum=%%g"
)

if "%filepath%"=="" goto choose
if "%linenum%"=="" set "linenum=1"

pushd "%repoRoot%"
@REM start "" codium . -g "%filepath%:%linenum%"
start cmd /c codium . -g "%filepath%:%linenum%"
@REM codium . -g "%filepath%:%linenum%"
popd

goto choose