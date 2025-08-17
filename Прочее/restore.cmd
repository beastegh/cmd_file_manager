@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "recycle=%~1"
set "name=%~2"

echo DEBUG: restore.cmd - Входные параметры: recycle=[!recycle!] name=[!name!]>>"!recycle!\debug.log"

if "!recycle!"=="" (
  echo Ошибка: Не указана папка Корзина.
  echo DEBUG: Ошибка: Не указана папка Корзина>>"!recycle!\debug.log"
  exit /b 1
)

if "!name!"=="" (
  echo Ошибка: Не указано имя для восстановления.
  echo DEBUG: Ошибка: Не указано имя для восстановления>>"!recycle!\debug.log"
  exit /b 1
)

set "log_file=!recycle!\log.txt"
if not exist "!log_file!" (
  echo Ошибка: log.txt не найден в Корзине.
  echo DEBUG: Ошибка: log.txt не найден в "!recycle!">>"!recycle!\debug.log"
  exit /b 1
)

if /i "!name!"=="log.txt" (
  echo Нельзя восстановить log.txt.
  echo DEBUG: Пропуск: name=[!name!] это log.txt>>"!recycle!\debug.log"
  exit /b 1
)

if not exist "!recycle!\!name!" (
  echo Ошибка: "!name!" не найден в Корзине.
  echo DEBUG: Ошибка: "!recycle!\!name!" не существует>>"!recycle!\debug.log"
  exit /b 1
)

:: Чтение log.txt и поиск записи для файла
set "orig_path="
set "found_entry=0"
echo DEBUG: Чтение log.txt для поиска "!name!">>"!recycle!\debug.log"
echo DEBUG: Содержимое log.txt:>>"!recycle!\debug.log"
type "!log_file!" >>"!recycle!\debug.log" 2>&1

for /f "usebackq delims=" %%a in ("!log_file!") do (
  set "line=%%a"
  if not "!line!"=="" (
    echo DEBUG: Обработка строки: [!line!]>>"!recycle!\debug.log"
    
    :: Разделяем строку по символу |
    :: Формат: name|timestamp|path|size
    for /f "tokens=1,3 delims=|" %%b in ("!line!") do (
      set "log_name=%%b"
      set "log_path=%%c"
      
      :: Убираем возможные пробелы в начале и конце
      call :trim "!log_name!" log_name
      call :trim "!log_path!" log_path
      
      echo DEBUG: Парсинг: log_name=[!log_name!] log_path=[!log_path!]>>"!recycle!\debug.log"
      
      if "!log_name!"=="!name!" (
        set "orig_path=!log_path!"
        set "found_entry=1"
        echo DEBUG: Найдена запись для "!name!", orig_path=[!orig_path!]>>"!recycle!\debug.log"
        goto found_in_log
      )
    )
  )
)

:found_in_log

if !found_entry!==0 (
  echo Ошибка: Исходный путь для "!name!" не найден в log.txt.
  echo DEBUG: Ошибка: Исходный путь для "!name!" не найден в log.txt>>"!recycle!\debug.log"
  exit /b 1
)

if "!orig_path!"=="" (
  echo Ошибка: Исходный путь для "!name!" пустой в log.txt.
  echo DEBUG: Ошибка: Исходный путь для "!name!" пустой>>"!recycle!\debug.log"
  exit /b 1
)

echo DEBUG: Найденный orig_path=[!orig_path!]>>"!recycle!\debug.log"

:: Проверка и создание целевой папки если не существует
if not exist "!orig_path!" (
  echo DEBUG: Создание целевой папки "!orig_path!">>"!recycle!\debug.log"
  mkdir "!orig_path!" 2>nul
  if errorlevel 1 (
    echo Ошибка создания папки "!orig_path!" для "!name!".
    echo DEBUG: Ошибка mkdir "!orig_path!" (errorlevel=!errorlevel!)>>"!recycle!\debug.log"
    exit /b 1
  )
)

:: Проверка, не существует ли уже файл в целевом месте
if exist "!orig_path!\!name!" (
  echo Элемент "!name!" уже существует в "!orig_path!".
  echo DEBUG: Ошибка: "!orig_path!\!name!" уже существует>>"!recycle!\debug.log"
  exit /b 1
)

:: Перемещение файла или папки из корзины в исходное место
echo DEBUG: Перемещение "!recycle!\!name!" в "!orig_path!\">>"!recycle!\debug.log"
move "!recycle!\!name!" "!orig_path!\" >nul 2>&1
if errorlevel 1 (
  echo Ошибка при восстановлении "!name!" в "!orig_path!".
  echo DEBUG: Ошибка move "!recycle!\!name!" "!orig_path!\" (errorlevel=!errorlevel!)>>"!recycle!\debug.log"
  exit /b 1
)

echo Восстановлен "!name!" в "!orig_path!".
echo DEBUG: Успешно восстановлен "!name!" в "!orig_path!">>"!recycle!\debug.log"

:: Удаление записи из log.txt
echo DEBUG: Удаление записи для "!name!" из log.txt>>"!recycle!\debug.log"
set "temp_log=%temp%\log_temp_%random%.txt"
set "record_removed=0"

if exist "!temp_log!" del "!temp_log!" >nul 2>&1

for /f "usebackq delims=" %%a in ("!log_file!") do (
  set "line=%%a"
  set "write_line=1"
  
  if not "!line!"=="" (
    :: Проверяем, содержит ли строка наш файл
    for /f "tokens=1 delims=|" %%b in ("!line!") do (
      set "line_name=%%b"
      call :trim "!line_name!" line_name
      
      if "!line_name!"=="!name!" (
        set "write_line=0"
        set "record_removed=1"
        echo DEBUG: Удаляем запись: [!line!]>>"!recycle!\debug.log"
      )
    )
  )
  
  if !write_line!==1 (
    echo !line!>>"!temp_log!"
  )
)

if !record_removed!==1 (
  move /y "!temp_log!" "!log_file!" >nul 2>&1
  if errorlevel 1 (
    echo Ошибка при обновлении log.txt для "!name!".
    echo DEBUG: Ошибка move "!temp_log!" "!log_file!" (errorlevel=!errorlevel!)>>"!recycle!\debug.log"
    if exist "!temp_log!" del "!temp_log!" >nul 2>&1
    exit /b 1
  ) else (
    echo DEBUG: Запись для "!name!" успешно удалена из log.txt>>"!recycle!\debug.log"
  )
) else (
  echo DEBUG: Запись для "!name!" не найдена в log.txt для удаления>>"!recycle!\debug.log"
  if exist "!temp_log!" del "!temp_log!" >nul 2>&1
)

echo DEBUG: Завершение restore.cmd, успешно>>"!recycle!\debug.log"
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