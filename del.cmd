@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "target=%~1"

echo [DEBUG] Входной путь: "%target%"

if not defined target (
  echo Ошибка: Не указан путь для удаления.
  exit /b 1
)

if not exist "%target%" (
  echo Ошибка: "%target%" не найден.
  exit /b 1
)

echo [DEBUG] Атрибуты до снятия:
attrib "%target%" 2>nul
attrib -h -s -r "%target%" 2>nul
echo [DEBUG] Атрибуты после снятия:
attrib "%target%" 2>nul

:: Проверяем, папка ли это
echo [DEBUG] Проверка: является ли "%target%" папкой...
if exist "%target%\*" (
  echo [DEBUG] Это папка
  echo Удаление папки "%target%" ...
  rd /s /q "%target%" 2>nul
  if errorlevel 1 (
    echo Ошибка при удалении папки "%target%".
    exit /b 1
  )
  :: Ждем пока папка удалится, максимум 10 попыток по 3 секунды
  set /a tries=0
  :wait_remove_folder
  if exist "%target%" (
    echo [DEBUG] Попытка !tries!: папка существует.
    if !tries! geq 10 (
      echo Папка "%target%" все еще существует после удаления.
      exit /b 1
    )
    ping -n 4 localhost >nul
    set /a tries+=1
    goto wait_remove_folder
  )
  echo Папка "%target%" успешно удалена.
) else (
  echo [DEBUG] Это файл
  echo Удаление файла "%target%" ...
  del /f /q "%target%" 2>nul
  if errorlevel 1 (
    echo Ошибка при удалении файла "%target%".
    exit /b 1
  )
  :: Ждем пока файл удалится, максимум 10 попыток по 3 секунды
  set /a tries=0
  :wait_remove_file
  if exist "%target%" (
    echo [DEBUG] Попытка !tries!: файл существует.
    if !tries! geq 10 (
      echo Файл "%target%" все еще существует после удаления.
      exit /b 1
    )
    ping -n 4 localhost >nul
    set /a tries+=1
    goto wait_remove_file
  )
  echo Файл "%target%" успешно удалён.
)

exit /b 0
































