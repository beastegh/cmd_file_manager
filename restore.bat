@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "recycle=%~1"
set "name=%~2"

echo DEBUG: Входные параметры: recycle=[!recycle!] name=[!name!]>>debug.log

if not defined recycle (
  echo Ошибка: Не указана папка Корзина.
  exit /b 1
)

if not defined name (
  echo Ошибка: Не указано имя для восстановления.
  exit /b 1
)

set "log_file=!recycle!\log.txt"
dir "!log_file!" >nul 2>nul
if errorlevel 1 (
  echo Ошибка: log.txt не найден в Корзине.
  echo DEBUG: Ошибка: log.txt не найден в "!recycle!" (errorlevel=!errorlevel!)>>debug.log
  exit /b 1
)

if /i "!name!"=="log.txt" (
  echo Нельзя восстановить log.txt.
  echo DEBUG: Пропуск: name=[!name!] это log.txt>>debug.log
  exit /b 1
)

if not exist "!recycle!\!name!" (
  echo Ошибка: "!name!" не найден в Корзине.
  echo DEBUG: Ошибка: "!recycle!\!name!" не существует>>debug.log
  exit /b 1
)

:: Чтение log.txt
set "orig_path="
echo DEBUG: Чтение log.txt>>debug.log
echo DEBUG: Содержимое log.txt:>>debug.log
type "!log_file!" >>debug.log
for /f "delims=" %%a in ('type "!log_file!"') do (
  for /f "tokens=1,2,3,4 delims=|" %%b in ("%%a") do (
    set "log_name=%%b"
    set "log_path=%%c"
    set "log_name=!log_name: =!"
    set "log_path=!log_path: =!"
    echo DEBUG: Проверка строки: log_name=[!log_name!] log_path=[!log_path!]>>debug.log
    if /i "!log_name!"=="!name!" (
      set "orig_path=!log_path!"
    )
  )
)
echo DEBUG: После чтения log.txt, orig_path=[!orig_path!]>>debug.log
if not defined orig_path (
  echo Ошибка: Исходный путь для "!name!" не найден в log.txt.
  echo DEBUG: Ошибка: Исходный путь для "!name!" не найден>>debug.log
  exit /b 1
)

:: Проверка валидности пути
echo "!orig_path!" | findstr /r /c:":" >nul
if errorlevel 1 (
  echo Ошибка: Некорректный путь "!orig_path!" для "!name!".
  echo DEBUG: Ошибка: Некорректный путь "!orig_path!" для "!name!">>debug.log
  exit /b 1
)

:: Проверка и создание пути
echo DEBUG: orig_path=[!orig_path!]>>debug.log
set "parent_path=!orig_path!"
for %%q in ("!orig_path!") do set "parent_path=%%~dpq"
set "parent_path=!parent_path:~0,-1!"
echo DEBUG: parent_path=[!parent_path!]>>debug.log
if not exist "!parent_path!" (
  echo DEBUG: Создание родительского пути "!parent_path!">>debug.log
  mkdir "!parent_path!" 2>nul
  if errorlevel 1 (
    echo Ошибка создания пути "!parent_path!" для "!name!".
    echo DEBUG: Ошибка mkdir "!parent_path!" (errorlevel=!errorlevel!)>>debug.log
    exit /b 1
  )
)
if exist "!orig_path!\!name!" (
  echo Элемент "!name!" уже существует в "!orig_path!".
  echo DEBUG: Ошибка: "!orig_path!\!name!" уже существует>>debug.log
  exit /b 1
)

:: Перемещение файла или папки
echo DEBUG: Перемещение "!recycle!\!name!" в "!orig_path!\">>debug.log
move "!recycle!\!name!" "!orig_path!\" >nul 2>nul
if errorlevel 1 (
  echo Ошибка при восстановлении "!name!" в "!orig_path!".
  echo DEBUG: Ошибка move "!recycle!\!name!" "!orig_path!\" (errorlevel=!errorlevel!)>>debug.log
  exit /b 1
)
echo Восстановлен "!name!" в "!orig_path!".

:: Обновление log.txt
echo DEBUG: Обновление log.txt для "!name!">>debug.log
set "temp_log=%temp%\log_temp_%random%.txt"
type nul > "!temp_log!"
set "found=0"
for /f "delims=" %%a in ('type "!log_file!"') do (
  for /f "tokens=1,2,3,4 delims=|" %%b in ("%%a") do (
    set "log_name=%%b"
    set "log_name=!log_name: =!"
    if /i "!log_name!"=="!name!" (
      set "found=1"
    ) else (
      echo %%b^|%%c^|%%d^|%%e>>"!temp_log!"
    )
  )
)
if !found! equ 1 (
  move /y "!temp_log!" "!log_file!" >nul 2>nul
  if errorlevel 1 (
    echo Ошибка при обновлении log.txt для "!name!".
    echo DEBUG: Ошибка move "!temp_log!" "!log_file!" (errorlevel=!errorlevel!)>>debug.log
    del "!temp_log!" 2>nul
    exit /b 1
  ) else (
    echo DEBUG: Удалена запись для "!name!" из log.txt>>debug.log
    del "!temp_log!" 2>nul
  )
) else (
  echo DEBUG: Запись для "!name!" не найдена в log.txt>>debug.log
  del "!temp_log!" 2>nul
)
echo DEBUG: Завершение обработки, success=1>>debug.log
exit /b 0