@echo off
setlocal enabledelayedexpansion

set "currentFolder=%~1"
set "makeParam=%~2"

if not defined currentFolder (
  echo Ошибка: Не указана текущая папка.
  exit /b 1
)

if not defined makeParam (
  echo Ошибка: Не указаны параметры для создания.
  exit /b 1
)

:: Убираем пробелы вокруг разделителей | и > (включая односторонние и множественные)
:trim_sep
set "temp=!makeParam!"
set "makeParam=!makeParam: | =|!"
set "makeParam=!makeParam:| =|!"
set "makeParam=!makeParam: |=|!"
set "makeParam=!makeParam:  |=|!"
set "makeParam=!makeParam: | =|!"
set "makeParam=!makeParam: > = >!"
set "makeParam=!makeParam:> = >!"
set "makeParam=!makeParam: >=>!"
set "makeParam=!makeParam:  >=>!"
set "makeParam=!makeParam: > = >!"
if not "!makeParam!"=="!temp!" goto trim_sep

:: Определяем тип: множественное (|), вложенное (>), или одиночное
set "hasPipe=0"
set "hasArrow=0"
if "!makeParam!" NEQ "!makeParam:|=#!" set "hasPipe=1"
if "!makeParam!" NEQ "!makeParam:>=#!" set "hasArrow=1"

if !hasPipe! equ 1 if !hasArrow! equ 1 (
  echo Ошибка: Нельзя смешивать | и > в одной команде.
  exit /b 0
)

if !hasPipe! equ 1 (
  :: Множественное создание папок
  set "params=!makeParam!"
  set "created=0"
  :loop_multiple
  if not defined params goto end_multiple
  for /f "tokens=1* delims=|" %%a in ("!params!") do (
    set "name=%%a"
    call :trim "!name!" name
    if "!name!"=="" goto skip_multiple
    if exist "!currentFolder!\!name!" (
      echo Папка "!name!" уже существует.
    ) else (
      mkdir "!currentFolder!\!name!" 2>nul
      if errorlevel 1 (
        echo Ошибка создания папки "!name!".
      ) else (
        echo Папка "!name!" создана.
        set /a created+=1
      )
    )
    :skip_multiple
    set "params=%%b"
  )
  goto loop_multiple
  :end_multiple
  if !created! equ 0 echo Нет новых папок для создания.
  exit /b 0
)

if !hasArrow! equ 1 (
  :: Вложенное создание папок
  set "params=!makeParam!"
  set "nestedPath="
  :loop_nested
  if not defined params goto end_nested
  for /f "tokens=1* delims=>" %%a in ("!params!") do (
    set "name=%%a"
    call :trim "!name!" name
    if "!name!"=="" goto skip_nested
    if "!nestedPath!"=="" (
      set "nestedPath=!name!"
    ) else (
      set "nestedPath=!nestedPath!\!name!"
    )
    :skip_nested
    set "params=%%b"
  )
  goto loop_nested
  :end_nested
  if "!nestedPath!"=="" (
    echo Ошибка: Пустой путь для создания.
    exit /b 0
  )
  if exist "!currentFolder!\!nestedPath!" (
    echo Папка "!nestedPath!" уже существует.
    exit /b 0
  )
  mkdir "!currentFolder!\!nestedPath!" 2>nul
  if errorlevel 1 (
    echo Ошибка создания вложенной папки "!nestedPath!".
  ) else (
    echo Вложенная папка "!nestedPath!" создана.
  )
  exit /b 0
)

:: Одиночное создание (файл или папка) — без изменений
set "name=!makeParam!"
call :trim "!name!" name
if "!name!"=="" (
  echo Ошибка: Пустое имя для создания.
  exit /b 0
)

set "isFile=0"
if "!name!" NEQ "!name:.=#!" set "isFile=1"

if !isFile! equ 1 (
  if exist "!currentFolder!\!name!" (
    echo Файл "!name!" уже существует.
    exit /b 0
  )
  type nul > "!currentFolder!\!name!" 2>nul
  if errorlevel 1 (
    echo Ошибка создания файла "!name!".
  ) else (
    echo Файл "!name!" создан.
  )
) else (
  if exist "!currentFolder!\!name!" (
    echo Папка "!name!" уже существует.
    exit /b 0
  )
  mkdir "!currentFolder!\!name!" 2>nul
  if errorlevel 1 (
    echo Ошибка создания папки "!name!".
  ) else (
    echo Папка "!name!" создана.
  )
)

exit /b 0

:trim
setlocal enabledelayedexpansion
set "str=%~1"
:trimleft
if "!str:~0,1!"==" " set "str=!str:~1!" & goto trimleft
:trimright
if "!str:~-1!"==" " set "str=!str:~0,-1!" & goto trimright
endlocal & set "%2=%str%"
goto :eof