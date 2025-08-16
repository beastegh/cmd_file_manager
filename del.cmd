@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "target=%~1"

echo [DEBUG] Входной путь: "%target%" >>debug.log

if not defined target (
  echo Ошибка: Не указан путь для удаления.
  exit /b 1
)

if not exist "%target%" (
  echo Ошибка: "%target%" не найден.
  exit /b 1
)

echo [DEBUG] Атрибуты до снятия:>>debug.log
attrib "%target%" >>debug.log 2>nul
attrib -h -s -r "%target%" 2>nul
echo [DEBUG] Атрибуты после снятия:>>debug.log
attrib "%target%" >>debug.log 2>nul

set "recycle=C:\Корзина"
set "is_trash=0"
if /i "%~dp1"=="!recycle!\" set "is_trash=1"

if !is_trash!==1 (
  :: Проверяем, не является ли файл log.txt
  if /i "%~nx1"=="log.txt" (
    echo Нельзя удалить log.txt.
    exit /b 1
  )
  :: Permanent delete
  echo [DEBUG] Проверка: является ли "%target%" папкой...>>debug.log
  if exist "%target%\*" (
    echo [DEBUG] Это папка>>debug.log
    rd /s /q "%target%" 2>nul
    if errorlevel 1 (
      echo Ошибка при удалении папки "%target%".
      exit /b 1
    )
    :: Ждем пока папка удалится, максимум 10 попыток по 3 секунды
    set /a tries=0
    :wait_remove_folder
    if exist "%target%" (
      echo [DEBUG] Попытка !tries!: папка существует.>>debug.log
      if !tries! geq 10 (
        echo Папка "%target%" все еще существует после удаления.
        exit /b 1
      )
      ping -n 4 localhost >nul
      set /a tries+=1
      goto wait_remove_folder
    )
  ) else (
    echo [DEBUG] Это файл>>debug.log
    del /f /q "%target%" 2>nul
    if errorlevel 1 (
      echo Ошибка при удалении файла "%target%".
      exit /b 1
    )
    :: Ждем пока файл удалится, максимум 10 попыток по 3 секунды
    set /a tries=0
    :wait_remove_file
    if exist "%target%" (
      echo [DEBUG] Попытка !tries!: файл существует.>>debug.log
      if !tries! geq 10 (
        echo Файл "%target%" все еще существует после удаления.
        exit /b 1
      )
      ping -n 4 localhost >nul
      set /a tries+=1
      goto wait_remove_file
    )
  )
  :: Удаляем соответствующую строку из log.txt
  set "log_file=!recycle!\log.txt"
  if exist "!log_file!" (
    set "temp_log=%temp%\log_temp_%random%.txt"
    set "found=0"
    type nul > "!temp_log!"
    for /f "delims=" %%l in ('type "!log_file!"') do (
      set "line=%%l"
      set "write_line=1"
      for /f "tokens=1 delims=|" %%a in ("!line!") do (
        set "log_name=%%a"
        set "log_name=!log_name: =!"
        if /i "!log_name!"=="%~nx1" (
          set "write_line=0"
          set "found=1"
        )
      )
      if !write_line! equ 1 (
        echo !line!>>"!temp_log!"
      )
    )
    if !found! equ 1 (
      move /y "!temp_log!" "!log_file!" >nul 2>nul
      if errorlevel 1 (
        echo Ошибка при обновлении log.txt.
        del "!temp_log!" 2>nul
        exit /b 1
      )
    ) else (
      del "!temp_log!" 2>nul
    )
  )
) else (
  :: Проверяем, не является ли файл log.txt
  if /i "%~nx1"=="log.txt" (
    echo Нельзя переместить log.txt в Корзину.
    exit /b 1
  )
  :: Move to recycle
  if not exist "!recycle!" (
    echo [DEBUG] Создание папки Корзина: "!recycle!">>debug.log
    mkdir "!recycle!" 2>nul
    if errorlevel 1 (
      echo Ошибка при создании папки Корзина.
      exit /b 1
    )
  )

  set "name=%~nx1"
  set "orig_path=%~dp1"
  set "orig_path=!orig_path:~0,-1!"
  set "timestamp=%date% в %time:~0,8%"
  set "log_file=!recycle!\log.txt"

  :: Проверяем, папка ли это
  echo [DEBUG] Проверка: является ли "%target%" папкой...>>debug.log
  if exist "%target%\*" (
    echo [DEBUG] Это папка>>debug.log
    :: Рассчитываем размер папки
    for /f "tokens=3" %%a in ('dir /s /a /-c "%target%" 2^>nul ^| find "File(s)"') do set "size=%%a"
    move "%target%" "!recycle!\" >nul 2>nul
    if errorlevel 1 (
      echo Ошибка при перемещении папки "%target%".
      exit /b 1
    )
    :: Ждем пока папка переместится, максимум 10 попыток по 3 секунды
    set /a tries=0
    :wait_move_folder
    if exist "%target%" (
      echo [DEBUG] Попытка !tries!: папка существует.>>debug.log
      if !tries! geq 10 (
        echo Папка "%target%" все еще существует после перемещения.
        exit /b 1
      )
      ping -n 4 localhost >nul
      set /a tries+=1
      goto wait_move_folder
    )
  ) else (
    echo [DEBUG] Это файл>>debug.log
    :: Рассчитываем размер файла
    for /f "tokens=3" %%a in ('dir /a /-c "%target%" 2^>nul ^| find "File(s)"') do set "size=%%a"
    move "%target%" "!recycle!\" >nul 2>nul
    if errorlevel 1 (
      echo Ошибка при перемещении файла "%target%".
      exit /b 1
    )
    :: Ждем пока файл переместится, максимум 10 попыток по 3 секунды
    set /a tries=0
    :wait_move_file
    if exist "%target%" (
      echo [DEBUG] Попытка !tries!: файл существует.>>debug.log
      if !tries! geq 10 (
        echo Файл "%target%" все еще существует после перемещения.
        exit /b 1
      )
      ping -n 4 localhost >nul
      set /a tries+=1
      goto wait_move_file
    )
  )

  :: Добавляем запись в лог без лишних пробелов
  echo !name!^|!timestamp!^|!orig_path!^|!size!>>"!log_file!"
)

exit /b 0