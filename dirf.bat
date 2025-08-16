@REM @echo off
@REM chcp 65001 >nul
@REM setlocal enabledelayedexpansion

@REM :: Получаем стартовый путь
@REM if "%~1"=="" (
@REM   set "folder=%cd%"
@REM ) else (
@REM   set "folder=%~1"
@REM )

@REM :: Убираем кавычки из пути (на всякий случай)
@REM set "folder=%folder:"=%"

@REM :: Исправляем двойные слеши
@REM :fix_slashes
@REM set "temp=!folder!"
@REM set "folder=!temp:\\=\!"
@REM if not "!folder!"=="!temp!" goto fix_slashes

@REM :: Убираем завершающий слэш, кроме корня диска
@REM :fix_trailing_slash
@REM if not "!folder:~-1!"=="\" goto no_slash_to_remove
@REM if "!folder:~1,2!"==":\" goto no_slash_to_remove
@REM set "folder=!folder:~0,-1!"
@REM :no_slash_to_remove

@REM :: Определяем ширину окна консоли (default 80)
@REM for /f "tokens=2 delims=:" %%a in ('mode con ^| findstr "Columns"') do set "cols=%%a"
@REM set "cols=%cols: =%"
@REM if "%cols%"=="" set "cols=80"

@REM set "spc=                                                "
@REM set "colWidth=45"
@REM if %colWidth% gtr %cols% set "colWidth=%cols%"

@REM :loop
@REM cls
@REM echo Путь: "!folder!"
@REM echo.

@REM :: Очистка массивов
@REM for /L %%i in (0,1,9999) do (
@REM     set "itemName[%%i]="
@REM     set "itemType[%%i]="
@REM )
@REM set /a totalCount=0
@REM set /a folderCount=0
@REM set /a fileCount=0

@REM :: Определяем корень диска
@REM for %%A in ("!folder!") do set "root=%%~dA\"

@REM :: Сбор папок
@REM for /f "delims=" %%d in ('dir "!folder!" /A:D-H /B /O:N 2^>nul') do (
@REM   set /a totalCount+=1
@REM   set /a folderCount+=1
@REM   set "itemName[!totalCount!]=%%d"
@REM   set "itemType[!totalCount!]=p"
@REM )

@REM :: Сбор файлов
@REM for /f "delims=" %%f in ('dir "!folder!" /A:-D-H /B /O:N 2^>nul') do (
@REM   set /a totalCount+=1
@REM   set /a fileCount+=1
@REM   set "itemName[!totalCount!]=%%f"
@REM   set "itemType[!totalCount!]=f"
@REM )

@REM if !totalCount! equ 0 (
@REM   echo Найдено: 0 элементов
@REM   echo.
@REM   goto choose
@REM )

@REM :: Вывод папок в 2 колонки
@REM set /a rows=(folderCount + 1) / 2
@REM echo ***************************** Папки ********************************
@REM echo.
@REM for /L %%r in (1,1,!rows!) do (
@REM   set /a leftIdx=%%r
@REM   set /a rightIdx=%%r+!rows!

@REM   if !leftIdx! leq !folderCount! (
@REM     call set "nameLeft=%%itemName[!leftIdx!]%%"
@REM     set "cellLeft=!leftIdx!. !nameLeft!!spc!"
@REM     set "cellLeft=!cellLeft:~0,%colWidth%!"
@REM     <nul set /p =!cellLeft!
@REM   ) else (
@REM     <nul set /p ="!spc:~0,%colWidth%!"
@REM   )

@REM   if !rightIdx! leq !folderCount! (
@REM     call set "nameRight=%%itemName[!rightIdx!]%%"
@REM     set "cellRight=!rightIdx!. !nameRight!!spc!"
@REM     set "cellRight=!cellRight:~0,%colWidth%!"
@REM     echo !cellRight!
@REM   ) else (
@REM     echo.
@REM   )
@REM )
@REM echo.

@REM :: Вывод файлов в 2 колонки
@REM echo ***************************** Файлы ********************************
@REM echo.
@REM set /a fileStart=folderCount+1
@REM set /a fileRows=(fileCount + 1) / 2
@REM for /L %%r in (1,1,!fileRows!) do (
@REM   set /a leftIdx=%%r + fileStart - 1
@REM   set /a rightIdx=%%r + fileRows + fileStart - 1

@REM   if !leftIdx! leq !totalCount! (
@REM     call set "nameLeft=%%itemName[!leftIdx!]%%"
@REM     set "cellLeft=!leftIdx!. !nameLeft!!spc!"
@REM     set "cellLeft=!cellLeft:~0,%colWidth%!"
@REM     <nul set /p =!cellLeft!
@REM   ) else (
@REM     <nul set /p ="!spc:~0,%colWidth%!"
@REM   )

@REM   if !rightIdx! leq !totalCount! (
@REM     call set "nameRight=%%itemName[!rightIdx!]%%"
@REM     set "cellRight=!rightIdx!. !nameRight!!spc!"
@REM     set "cellRight=!cellRight:~0,%colWidth%!"
@REM     echo !cellRight!
@REM   ) else (
@REM     echo.
@REM   )
@REM )
@REM echo.
@REM echo ********************************************************************
@REM echo Папок: !folderCount! ^| Файлов: !fileCount! ^| Всего: !totalCount!
@REM echo.

@REM :: Вывод доступных дисков
@REM set "drives="
@REM for /f "skip=1 tokens=1" %%D in ('wmic logicaldisk get name 2^>nul') do (
@REM   if not "%%D"=="" (
@REM     if defined drives (
@REM       set "drives=!drives! | %%D"
@REM     ) else (
@REM       set "drives=%%D"
@REM     )
@REM   )
@REM )

@REM :choose
@REM set /p "choice=Введите команду или номер: "

@REM :: Разбираем ввод на команду и параметр
@REM set "cmdInput="
@REM set "cmdParam="
@REM for /f "tokens=1,2*" %%a in ("!choice!") do (
@REM   set "cmdInput=%%a"
@REM   set "cmdParam=%%b"
@REM )

@REM :: Команда выхода
@REM if /i "!cmdInput!"=="q" goto end

@REM :: Переход в корень
@REM if "!cmdInput!"=="/" (
@REM   for %%A in ("!folder!") do set "folder=%%~dA\"
@REM   goto loop
@REM )

@REM :: Назад
@REM if /i "!cmdInput!"=="b" (
@REM   for %%A in ("!folder!") do set "parent=%%~dpA"
@REM   for %%A in ("!parent!") do set "parentRoot=%%~dA\"
@REM   if /I "!parent!"=="!parentRoot!" (
@REM     set "folder=!parent!"
@REM   ) else (
@REM     if "!parent:~-1!"=="\" (
@REM       set "folder=!parent:~0,-1!"
@REM     ) else (
@REM       set "folder=!parent!"
@REM     )
@REM   )
@REM   goto loop
@REM )

@REM :: Переключение на диск
@REM set "foundDrive="
@REM for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
@REM   if /i "!cmdInput!"=="%%D" (
@REM     set "folder=%%D:\"
@REM     set "foundDrive=1"
@REM   )
@REM )
@REM if defined foundDrive goto loop

@REM :: Удаление
@REM if /i "!cmdInput!"=="del" (
@REM   if "!cmdParam!"=="" (
@REM     echo Не указан номер для удаления.
@REM     timeout /t 1 >nul
@REM     goto choose
@REM   )
@REM   set /a delNum=!cmdParam! 2>nul
@REM   if errorlevel 1 (
@REM     echo Некорректный номер для удаления.
@REM     timeout /t 1 >nul
@REM     goto choose
@REM   )
@REM   if !delNum! lss 1 (
@REM     echo Номер меньше 1.
@REM     timeout /t 1 >nul
@REM     goto choose
@REM   )
@REM   if !delNum! gtr !totalCount! (
@REM     echo Номер больше количества элементов.
@REM     timeout /t 1 >nul
@REM     goto choose
@REM   )
@REM   call set "delName=%%itemName[!delNum!]%%"
@REM   call set "delType=%%itemType[!delNum!]%%"
@REM   set "fullPath=!folder!\!delName!"
  
@REM   :: Проверяем системный атрибут
@REM   for /f "tokens=1" %%a in ('attrib "!fullPath!" 2^>nul') do set "attr=%%a"
@REM   echo !attr! | findstr /i "S" >nul
@REM   if not errorlevel 1 (
@REM       echo Ошибка: Нельзя удалить системный файл или папку.
@REM       timeout /t 2 >nul
@REM       goto choose
@REM   )
@REM   echo Вы действительно хотите удалить "!delName!"? (y/n):
@REM   set /p "ans=>"
@REM   if /i "!ans!"=="y" (
@REM       if "!delType!"=="p" (
@REM           rd /s /q "!fullPath!"
@REM       ) else (
@REM           del /f /q "!fullPath!"
@REM       )
@REM       echo Удалено.
@REM   ) else (
@REM       echo Отменено.
@REM   )
@REM   timeout /t 1 >nul
@REM   goto loop
@REM )

@REM :: Проверяем, число ли cmdInput — если да, переходим или открываем файл
@REM set /a selNum=!cmdInput! 2>nul
@REM if errorlevel 1 (
@REM   echo Некорректный ввод, пожалуйста введите число или команду.
@REM   timeout /t 1 >nul
@REM   goto choose
@REM )

@REM if !selNum! lss 1 (
@REM   echo Номер меньше 1.
@REM   timeout /t 1 >nul
@REM   goto choose
@REM )
@REM if !selNum! gtr !totalCount! (
@REM   echo Номер больше количества элементов.
@REM   timeout /t 1 >nul
@REM   goto choose
@REM )

@REM :: Получаем выбранный элемент
@REM set "selectedName="
@REM set "selectedType="
@REM for /f "delims=" %%a in ('cmd /v:on /c echo !itemName[!selNum!]!') do set "selectedName=%%a"
@REM for /f "delims=" %%a in ('cmd /v:on /c echo !itemType[!selNum!]!') do set "selectedType=%%a"

@REM if "!selectedType!"=="p" (
@REM   if "!folder:~-1!"=="\" (
@REM     set "folder=!folder!!selectedName!"
@REM   ) else (
@REM     set "folder=!folder!\!selectedName!"
@REM   )
@REM   goto loop
@REM )

@REM if "!selectedType!"=="f" (
@REM   if "!folder:~-1!"=="\" (
@REM     set "fullPath=!folder!!selectedName!"
@REM   ) else (
@REM     set "fullPath=!folder!\!selectedName!"
@REM   )
@REM   start "" cmd /c codium . -g "!fullPath!"
@REM   goto loop
@REM )

@REM echo Некорректный ввод.
@REM timeout /t 1 >nul
@REM goto choose

@REM :end
@REM endlocal
@REM exit /b 0









@REM call set "var=%%itemName[!idx!]%%" — позволяет дважды раскрыть переменную: сначала call раскрывает % один уровень, затем delayed expansion раскрывает !idx!.
@REM Прямая попытка написать !itemName[!idx!]! внутри цикла не сработает, т.к. delayed expansion раскрывается один раз, и вложенная переменная не раскрывается.


@REM Ошибка «: was unexpected at this time.» в данном случае почти наверняка связана с тем, что внутри условного оператора if или цикла используется конструкция с неправильным раскрытием переменных.

@REM Самая частая причина — попытка использовать !selectedName! или другие переменные с вложенным ! внутри if, но без корректного setlocal enabledelayedexpansion или с неправильным смешиванием расширений.

@REM Как я вижу решение:
@REM Во всех местах, где происходит выбор элемента по индексу, используем корректный способ получить значение из массива через call set или через for с enabledelayedexpansion, но аккуратно.

@REM При переходе в папку или открытии файла — все переменные должны быть уже «развернуты» и не содержать вложенных !.
















@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Получаем стартовый путь
if "%~1"=="" (
  set "folder=%cd%"
) else (
  set "folder=%~1"
)

:: Убираем кавычки из пути (на всякий случай)
set "folder=%folder:"=%"

:: Исправляем двойные слеши
:fix_slashes
set "temp=!folder!"
set "folder=!temp:\\=\!"
if not "!folder!"=="!temp!" goto fix_slashes

:: Убираем завершающий слэш, кроме корня диска
:fix_trailing_slash
if not "!folder:~-1!"=="\" goto no_slash_to_remove
if "!folder:~1,2!"==":\" goto no_slash_to_remove
set "folder=!folder:~0,-1!"
:no_slash_to_remove

:: Определяем ширину окна консоли (default 80)
for /f "tokens=2 delims=:" %%a in ('mode con ^| findstr "Columns"') do set "cols=%%a"
set "cols=%cols: =%"
if "%cols%"=="" set "cols=80"

set "spc=                                                "
set "colWidth=45"
if %colWidth% gtr %cols% set "colWidth=%cols%"

:loop
cls
echo Путь: "!folder!"
echo.

:: Очистка массивов
for /L %%i in (0,1,9999) do (
    set "itemName[%%i]="
    set "itemType[%%i]="
)
set /a totalCount=0
set /a folderCount=0
set /a fileCount=0

:: Определяем корень диска
for %%A in ("!folder!") do set "root=%%~dA\"

:: Сбор папок (без системных и скрытых)
for /f "delims=" %%d in ('dir "!folder!" /A:D-H-S /B /O:N 2^>nul') do (
  set /a totalCount+=1
  set /a folderCount+=1
  set "itemName[!totalCount!]=%%d"
  set "itemType[!totalCount!]=p"
)

:: Сбор файлов (без системных и скрытых)
for /f "delims=" %%f in ('dir "!folder!" /A:-D-H-S /B /O:N 2^>nul') do (
  set /a totalCount+=1
  set /a fileCount+=1
  set "itemName[!totalCount!]=%%f"
  set "itemType[!totalCount!]=f"
)

if !totalCount! equ 0 (
  echo Найдено: 0 элементов
  echo.
  goto choose
)

:: Вывод папок в 2 колонки
set /a rows=(folderCount + 1) / 2
echo ***************************** Папки ********************************
echo.
for /L %%r in (1,1,!rows!) do (
  set /a leftIdx=%%r
  set /a rightIdx=%%r+!rows!

  if !leftIdx! leq !folderCount! (
    call set "nameLeft=%%itemName[!leftIdx!]%%"
    set "cellLeft=!leftIdx!. !nameLeft!!spc!"
    set "cellLeft=!cellLeft:~0,%colWidth%!"
    <nul set /p =!cellLeft!
  ) else (
    <nul set /p ="!spc:~0,%colWidth%!"
  )

  if !rightIdx! leq !folderCount! (
    call set "nameRight=%%itemName[!rightIdx!]%%"
    set "cellRight=!rightIdx!. !nameRight!!spc!"
    set "cellRight=!cellRight:~0,%colWidth%!"
    echo !cellRight!
  ) else (
    echo.
  )
)
echo.

:: Вывод файлов в 2 колонки
echo ***************************** Файлы ********************************
echo.
set /a fileStart=folderCount+1
set /a fileRows=(fileCount + 1) / 2
for /L %%r in (1,1,!fileRows!) do (
  set /a leftIdx=%%r + fileStart - 1
  set /a rightIdx=%%r + fileRows + fileStart - 1

  if !leftIdx! leq !totalCount! (
    call set "nameLeft=%%itemName[!leftIdx!]%%"
    set "cellLeft=!leftIdx!. !nameLeft!!spc!"
    set "cellLeft=!cellLeft:~0,%colWidth%!"
    <nul set /p =!cellLeft!
  ) else (
    <nul set /p ="!spc:~0,%colWidth%!"
  )

  if !rightIdx! leq !totalCount! (
    call set "nameRight=%%itemName[!rightIdx!]%%"
    set "cellRight=!rightIdx!. !nameRight!!spc!"
    set "cellRight=!cellRight:~0,%colWidth%!"
    echo !cellRight!
  ) else (
    echo.
  )
)
echo.
echo ********************************************************************
echo Папок: !folderCount! ^| Файлов: !fileCount! ^| Всего: !totalCount!
echo.

:: Вывод доступных дисков
set "drives="
for /f "skip=1 tokens=1" %%D in ('wmic logicaldisk get name 2^>nul') do (
  if not "%%D"=="" (
    if defined drives (
      set "drives=!drives! | %%D"
    ) else (
      set "drives=%%D"
    )
  )
)

:choose
set /p "choice=Введите команду или номер: "
echo DEBUG: Введено: "!choice!"
pause

for /f "tokens=1*" %%a in ("!choice!") do (
  set "cmdInput=%%a"
  set "cmdParam=%%b"
)

echo DEBUG: cmdInput = "!cmdInput!", cmdParam = "!cmdParam!"
pause

:: Далее используем переменные !cmdInput! и !cmdParam! (включая проверки и переходы)


:: Выход
if /i "%cmdInput%"=="q" goto end

:: Переход в корень
if "%cmdInput%"=="/" (
  for %%A in ("%folder%") do set "folder=%%~dA\"
  goto loop
)

:: Назад
if /i "%cmdInput%"=="b" (
  for %%A in ("%folder%") do set "parent=%%~dpA"
  for %%A in ("%parent%") do set "parentRoot=%%~dA\"
  if /I "%parent%"=="%parentRoot%" (
    set "folder=%parent%"
  ) else (
    if "%parent:~-1%"=="\" (
      set "folder=%parent:~0,-1%"
    ) else (
      set "folder=%parent%"
    )
  )
  goto loop
)

:: Переключение на диск
set "foundDrive="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  if /i "%cmdInput%"=="%%D" (
    set "folder=%%D:\"
    set "foundDrive=1"
  )
)
if defined foundDrive goto loop

:: Удаление файла/папки по номеру
if /i "%cmdInput%"=="del" (
  if "%cmdParam%"=="" (
    echo Не указан номер для удаления.
    timeout /t 1 >nul
    goto choose
  )
  
  setlocal enabledelayedexpansion
  set /a delNum=%cmdParam% 2>nul
  if errorlevel 1 (
    endlocal
    echo Некорректный номер для удаления.
    timeout /t 1 >nul
    goto choose
  )
  
  if !delNum! lss 1 (
    endlocal
    echo Номер меньше 1.
    timeout /t 1 >nul
    goto choose
  )
  
  if !delNum! gtr !totalCount! (
    endlocal
    echo Номер больше количества элементов.
    timeout /t 1 >nul
    goto choose
  )
  
  set "delName="
  set "delType="
  for /L %%i in (1,1,!totalCount!) do (
    if %%i==!delNum! (
      set "delName=!itemName[%%i]!"
      set "delType=!itemType[%%i]!"
    )
  )
  
  set "fullPath=!folder!\!delName!"
  
  :: Проверка системного атрибута
  for /f "tokens=1" %%a in ('attrib "!fullPath!" 2^>nul') do set "attr=%%a"
  echo DEBUG: Атрибуты для "!fullPath!": !attr!
  pause
  echo !attr! | findstr /i "S" >nul
  if not errorlevel 1 (
    endlocal
    echo Ошибка: Нельзя удалить системный файл или папку.
    timeout /t 2 >nul
    goto choose
  )
  
  endlocal
  
  echo Вы действительно хотите удалить "!delName!"? (y/n):
  set /p "ans=>"
  if /i "!ans!"=="y" (
    if "!delType!"=="p" (
      rd /s /q "!fullPath!"
    ) else (
      del /f /q "!fullPath!"
    )
    echo Удалено.
  ) else (
    echo Отменено.
  )
  timeout /t 1 >nul
  goto loop
)

:: Обработка выбора по номеру
setlocal enabledelayedexpansion

set /a selNum=0
set /a err=0
for /f "delims=" %%x in ("!cmdInput!") do (
  set /a selNum=%%x 2>nul || set /a err=1
)

if !err! equ 1 (
  endlocal
  echo Некорректный ввод, пожалуйста введите число или команду.
  timeout /t 1 >nul
  goto choose
)

if !selNum! lss 1 (
  endlocal
  echo Номер меньше 1.
  timeout /t 1 >nul
  goto choose
)

if !selNum! gtr !totalCount! (
  endlocal
  echo Номер больше количества элементов.
  timeout /t 1 >nul
  goto choose
)

set "selectedName="
set "selectedType="
for /L %%i in (1,1,!totalCount!) do (
  if %%i==!selNum! (
    set "selectedName=!itemName[%%i]!"
    set "selectedType=!itemType[%%i]!"
  )
)

endlocal & set "selectedName=%selectedName%" & set "selectedType=%selectedType%"

echo DEBUG: selectedName="%selectedName%", selectedType="%selectedType%"
pause

if "%selectedType%"=="p" (
  echo DEBUG: Переход в папку "%selectedName%"
  pause
  if "%folder:~-1%"=="\" (
    set "folder=%folder%%selectedName%"
  ) else (
    set "folder=%folder%\%selectedName%"
  )
  goto loop
)

if "%selectedType%"=="f" (
  echo DEBUG: Открытие файла "%selectedName%"
  pause
  if "%folder:~-1%"=="\" (
    set "fullPath=%folder%%selectedName%"
  ) else (
    set "fullPath=%folder%\%selectedName%"
  )
  start "" cmd /c codium . -g "%fullPath%"
  goto loop
)

echo Некорректный ввод.
timeout /t 1 >nul
goto choose

:end
endlocal
exit /b 0

