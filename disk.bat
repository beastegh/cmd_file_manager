@echo off
setlocal enabledelayedexpansion

set "GB=1073741824"

:: Получаем список доступных дисков
set /a diskCount=0
for /f "skip=1 tokens=1,2,3,4" %%A in ('wmic logicaldisk get caption^,drivetype^,freespace^,size 2^>nul') do (
  if not "%%A"=="" (
    set "type=%%B"
    set "caption=%%A"
    set "freeSpace=%%C"
    set "size=%%D"
    :: Пропускаем пустые записи (например, пустой пятый элемент)
    if defined caption (
      set "diskCaption[!diskCount!]=!caption!"
      set "diskType[!diskCount!]=!type!"
      set "diskFreeSpace[!diskCount!]=!freeSpace!"
      set "diskSize[!diskCount!]=!size!"
      set /a diskCount+=1
    )
  )
)

cls
echo Меню дисков
echo.

:: Счётчик для вывода (нумерация меню с 1)
set /a displayIndex=0
for /L %%k in (0,1,!diskCount!-1) do (
  call set "caption=%%diskCaption[%%k]%%"
  call set "type=%%diskType[%%k]%%"
  call set "freeSpace=%%diskFreeSpace[%%k]%%"
  call set "size=%%diskSize[%%k]%%"

  set "typeLabel=Неизвестный"
  if "!type!"=="2" set "typeLabel=Съемный"
  if "!type!"=="3" set "typeLabel=Локальный"
  if "!type!"=="4" set "typeLabel=Облако"
  if "!type!"=="5" set "typeLabel=CD-ROM"
  if "!type!"=="6" set "typeLabel=RAM Disk"

  :: Пропускаем записи с пустыми или неизвестными данными
  if "!typeLabel!" neq "Неизвестный" if defined caption if defined freeSpace if defined size (
    set /a displayIndex+=1
    set "freeDisplay=Н/Д"
    set "totalDisplay=Н/Д"

    if not "!freeSpace!"=="" call :BytesToGB "!freeSpace!" freeDisplay
    if not "!size!"=="" call :BytesToGB "!size!" totalDisplay

    echo !displayIndex!. !caption! !typeLabel! ^| !freeDisplay! ГБ свободно из !totalDisplay! ГБ
  )
)
echo.

:: Чтение выбора пользователя
:choose_disk
set /p "choice=$:" 2>nul
if /i "%choice%"=="b" exit /b 0

rem Проверяем что введено число
set /a sel=%choice% 2>nul
if "%sel%"=="" (
  echo Некорректный ввод.
  goto choose_disk
)

if %sel% lss 1 (
  echo Некорректный ввод.
  goto choose_disk
)

if %sel% gtr %displayIndex% (
  echo Некорректный ввод.
  goto choose_disk
)

:: Находим индекс диска в массиве, соответствующий выбору
set /a count=0
set /a foundIndex=-1
for /L %%k in (0,1,!diskCount!-1) do (
  call set "type=%%diskType[%%k]%%"
  call set "caption=%%diskCaption[%%k]%%"
  call set "freeSpace=%%diskFreeSpace[%%k]%%"
  call set "size=%%diskSize[%%k]%%"

  set "typeLabel=Неизвестный"
  if "!type!"=="2" set "typeLabel=Съемный"
  if "!type!"=="3" set "typeLabel=Локальный"
  if "!type!"=="4" set "typeLabel=Облако"
  if "!type!"=="5" set "typeLabel=CD-ROM"
  if "!type!"=="6" set "typeLabel=RAM Disk"

  if "!typeLabel!" neq "Неизвестный" if defined caption if defined freeSpace if defined size (
    set /a count+=1
    if !count! equ %sel% set /a foundIndex=%%k
  )
)

if %foundIndex% equ -1 (
  echo Ошибка: выбранный диск не найден.
  goto choose_disk
)

call set "caption=%%diskCaption[%foundIndex%]%%"
set "selected=!caption!\"

cd /d "!selected!" 2>nul || (
  echo Ошибка: Не удалось перейти на диск !caption!.
  set /p "dummy=Нажмите Enter для продолжения..."
  goto choose_disk
)

endlocal & set "folder=%selected%"
exit /b 0

:: Функции для конвертации байт в ГБ оставляю без изменений
:DivBy1024
setlocal enabledelayedexpansion
set "num=%~1"
set "q="
set /a rem=0
for /l %%i in (0,1,255) do (
  set "ch=!num:~%%i,1!"
  if "!ch!"=="" goto DivBy1024_done
  set /a rem = rem * 10 + ch
  set /a dq = rem / 1024
  set /a rem = rem %% 1024
  if defined q (
    set "q=!q!!dq!"
  ) else (
    if !dq! neq 0 (
      set "q=!dq!"
    )
  )
)
:DivBy1024_done
if not defined q set "q=0"
endlocal & (
  set "%~2=%q%"
  set "%~3=%rem%"
)
exit /b

:BytesToGB
setlocal enabledelayedexpansion
set "bytes=%~1"
set "outVar=%~2"

if "%bytes%"=="" (
  endlocal & set "%outVar%=Н/Д"
  exit /b
)

:: Разделим байты на КБ
call :DivBy1024 "%bytes%" kb rem1
:: КБ на МБ
call :DivBy1024 "%kb%" mb rem2
:: МБ на ГБ
call :DivBy1024 "%mb%" gb rem3

:: теперь gb - целая часть в ГБ
:: rem3 - остаток МБ (0..1023), возьмём 1 знак дроби - 1/10 ГБ = 100 МБ, значит дробь будет rem3 * 10 / 1024

set /a frac=(rem3 * 10 + 512) / 1024

:: если дробь == 10, то увеличим целую часть
if %frac% equ 10 (
  set /a gb+=1
  set frac=0
)

set "result=%gb%.%frac%"

endlocal & set "%outVar%=%result%"
exit /b

