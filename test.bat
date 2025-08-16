@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Получаем стартовый путь
if "%~1"=="" (
  set "folder=%cd%"
) else (
  set "folder=%~1"
)
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

:: 25 пробелов установить отступ одинаковый
set "spc=                                                "

:loop
cls
echo Путь: !folder!
echo.

:: Вызываем path.cmd для получения списков и переменных
call path.cmd "!folder!"

:: Проверка переменных totalCount, folderCount, fileCount
if not defined totalCount set /a totalCount=0
if not defined folderCount set /a folderCount=0
if not defined fileCount set /a fileCount=0

:: Проверка, что переменные являются числами
set /a testTotal=!totalCount! 2>nul || set /a totalCount=0
set /a testFolder=!folderCount! 2>nul || set /a folderCount=0
set /a testFile=!fileCount! 2>nul || set /a fileCount=0

set "isRecycle=0"
if /i "!folder!"=="C:\Корзина" set "isRecycle=1"

:: Если в корзине, исключить log.txt из списков
if !isRecycle!==1 (
  set found=0
  set /a origTotal=!totalCount!
  for /L %%i in (1,1,!origTotal!) do (
    if !found!==0 (
      call set "name=%%itemName[%%i]%%"
      call set "type=%%itemType[%%i]%%"
      if /i "!name!"=="log.txt" (
        set found=1
        set /a totalCount-=1
        if "!type!"=="f" set /a fileCount-=1
        if "!type!"=="p" set /a folderCount-=1
      ) else (
        if !found!==1 (
          set /a newIdx=%%i -1
          set "itemName[!newIdx!]=!name!"
          set "itemType[!newIdx!]=!type!"
        )
      )
    ) else (
      call set "name=%%itemName[%%i]%%"
      call set "type=%%itemType[%%i]%%"
      set /a newIdx=%%i -1
      set "itemName[!newIdx!]=!name!"
      set "itemType[!newIdx!]=!type!"
    )
  )
  if !found!==1 (
    set "itemName[!totalCount!]="
    set "itemType[!totalCount!]="
  )
)

if !totalCount! equ 0 (
  echo Найдено: 0 элементов
  echo.
  goto choose
)

:: Вывод папок в 2 колонки (равномерно), только если есть папки
if !folderCount! gtr 0 (
  set "rows="
  set /a "rows=(folderCount+1)/2" 2>nul || set /a rows=1
  echo ***************************** Папки ********************************
  echo.
  for /L %%r in (1,1,!rows!) do (
    set /a leftIdx=%%r
    set /a rightIdx=%%r+!rows!
    if !leftIdx! leq !folderCount! (
      call set "nameLeft=%%itemName[!leftIdx!]%%"
      if defined nameLeft (
        set "nameLeft=!nameLeft:"=!"
        set "cellLeft=!leftIdx!. !nameLeft!!spc!"
        set "cellLeft=!cellLeft:~0,45!"
        <nul set /p =!cellLeft!
      ) else (
        <nul set /p ="                                             "
      )
    ) else (
      <nul set /p ="                                             "
    )
    if !rightIdx! leq !folderCount! (
      call set "nameRight=%%itemName[!rightIdx!]%%"
      if defined nameRight (
        set "nameRight=!nameRight:"=!"
        set "cellRight=!rightIdx!. !nameRight!!spc!"
        set "cellRight=!cellRight:~0,45!"
        echo !cellRight!
      ) else (
        echo.
      )
    ) else (
      echo.
    )
  )
  echo.
)

:: Вывод файлов в 2 колонки (равномерно), только если есть файлы
if !fileCount! gtr 0 (
  set "fileRows="
  set /a "fileRows=(fileCount+1)/2" 2>nul || set /a fileRows=1
  echo ***************************** Файлы ********************************
  echo.
  set /a fileStart=folderCount+1
  for /L %%r in (1,1,!fileRows!) do (
    set /a leftIdx=%%r + fileStart - 1
    set /a rightIdx=%%r + fileRows + fileStart - 1
    if !leftIdx! leq !totalCount! (
      call set "nameLeft=%%itemName[!leftIdx!]%%"
      if defined nameLeft (
        set "nameLeft=!nameLeft:"=!"
        set "cellLeft=!leftIdx!. !nameLeft!!spc!"
        set "cellLeft=!cellLeft:~0,45!"
        <nul set /p =!cellLeft!
      ) else (
        <nul set /p ="                                             "
      )
    ) else (
      <nul set /p ="                                             "
    )
    if !rightIdx! leq !totalCount! (
      call set "nameRight=%%itemName[!rightIdx!]%%"
      if defined nameRight (
        set "nameRight=!nameRight:"=!"
        set "cellRight=!rightIdx!. !nameRight!!spc!"
        set "cellRight=!cellRight:~0,45!"
        echo !cellRight!
      ) else (
        echo.
      )
    ) else (
      echo.
    )
  )
  echo.
)

echo ********************************************************************
echo Папок: !folderCount! ^| Файлов: !fileCount! ^| Всего: !totalCount!
echo.

:choose
set "selectedName="
set "selectedType="
set /p "choice=$" 2>nul
if not defined choice goto loop

:: Очищаем ввод от лишних пробелов и кавычек
set "choice=%choice:"=%"
for /f "tokens=*" %%a in ("!choice!") do set "choice=%%a"

:: Разбиваем ввод на команду и параметр
for /f "tokens=1*" %%a in ("!choice!") do (
  set "cmdInput=%%a"
  set "cmdParam=%%b"
)

if /i "!cmdInput!"=="q" goto end

:: Проверяем команду перехода в корень
if "!cmdInput!"=="/" (
  for %%A in ("!folder!") do set "folder=%%~dA\"
  goto loop
)

:: Проверяем команду вызова меню дисков
if /i "!cmdInput!"=="disk" (
  call disk.bat
  goto loop
)

:: Проверка команды перехода в Корзину
if /i "!cmdInput!"=="trash" (
  set "folder=C:\Корзина"
  goto loop
)

:: Проверка команды возврат
if /i "!cmdInput!"=="b" (
  for %%A in ("!folder!") do set "parent=%%~dpA"
  for %%A in ("!parent!") do set "parentRoot=%%~dA\"
  if /I "!parent!"=="!parentRoot!" (
    set "folder=!parent!"
  ) else (
    if "!parent:~-1!"=="\" (
      set "folder=!parent:~0,-1!"
    ) else (
      set "folder=!parent!"
    )
  )
  goto loop
)

:: Проверка команды удаления
if /i "!cmdInput!"=="del" (
  if not defined cmdParam (
    echo Укажите номер для удаления, например: del 3 или del all или del 1 ^| 5 ^| 7
    goto choose
  )
  :: Проверка команды del all
  if /i "!cmdParam!"=="all" (
    if !totalCount! equ 0 (
      echo Нет элементов для удаления.
      goto choose
    )
    echo DEBUG: Начало del all, totalCount=!totalCount!>>debug.log
    set /a tempTotal=!totalCount!
    set "success=1"
    for /L %%o in (1,1,!tempTotal!) do (
      call set "delName=%%itemName[%%o]%%"
      call set "delType=%%itemType[%%o]%%"
      set "delName=!delName:"=!"
      echo DEBUG: Обработка %%o: delName=[!delName!] delType=[!delType!]>>debug.log
      if defined delName if exist "!folder!\!delName!" (
        if !isRecycle!==0 (
          call del.cmd "!folder!\!delName!"
          if errorlevel 1 (
            echo DEBUG: Ошибка del.cmd для "!delName!">>debug.log
            set "success=0"
          ) else (
            echo DEBUG: Успешно удалено "!delName!">>debug.log
          )
        ) else if /i not "!delName!"=="log.txt" (
          call del.cmd "!folder!\!delName!"
          if errorlevel 1 (
            echo DEBUG: Ошибка del.cmd для "!delName!">>debug.log
            set "success=0"
          ) else (
            echo DEBUG: Успешно удалено "!delName!">>debug.log
          )
        )
      ) else (
        echo DEBUG: Пропуск %%o: delName=[!delName!] не определён или не существует>>debug.log
      )
    )
    if !success!==1 (
      echo DEBUG: Очистка массивов>>debug.log
      for /L %%d in (1,1,!tempTotal!) do (
        set "itemName[%%d]="
        set "itemType[%%d]="
      )
      set /a totalCount=0
      set /a folderCount=0
      set /a fileCount=0
    )
    echo DEBUG: Завершение del all, success=!success!>>debug.log
    goto loop
  )
  :: Проверка удаления по номерам (одиночный или множественный)
  echo DEBUG: Начало обработки номеров: cmdParam=[!cmdParam!]>>debug.log
  set "success=1"
  for /f "tokens=1-10 delims=|" %%n in ("!cmdParam!") do (
    for %%N in (%%n %%o %%p %%q %%r %%s %%t %%u %%v %%w) do (
      set "delNum=%%N"
      set "delNum=!delNum: =!"
      if defined delNum (
        set /a delNum=delNum 2>nul
        if !delNum! equ 0 (
          echo Некорректный номер: "!delNum!".
          set "success=0"
        ) else if !delNum! lss 1 (
          echo Номер для удаления должен быть >= 1: "!delNum!".
          set "success=0"
        ) else if !delNum! gtr !totalCount! (
          echo Номер превышает количество элементов: "!delNum!".
          set "success=0"
        ) else (
          call set "delName=%%itemName[!delNum!]%%"
          call set "delType=%%itemType[!delNum!]%%"
          echo DEBUG: Проверка номера !delNum!: delName=[!delName!] delType=[!delType!]>>debug.log
          if not defined delName (
            echo Элемент с номером !delNum! не найден.
            set "success=0"
          ) else if not exist "!folder!\!delName!" (
            echo Элемент "!delName!" не найден в каталоге.
            set "success=0"
          ) else (
            call del.cmd "!folder!\!delName!"
            if errorlevel 1 (
              echo DEBUG: Ошибка del.cmd для "!delName!" с номером !delNum!>>debug.log
              set "success=0"
            ) else (
              echo DEBUG: Успешно удалено "!delName!" с номером !delNum!>>debug.log
            )
          )
        )
      )
    )
  )
  if !success!==0 (
    echo Ошибка при удалении одного или нескольких элементов.
  )
  echo DEBUG: Завершение обработки номеров, success=!success!>>debug.log
  goto loop
)

:: Проверка команды создания (make)
if /i "!cmdInput!"=="make" (
  if not defined cmdParam (
    echo Укажите имя файла/папки для создания, например: make file.txt или make folder1 ^| folder two
    goto choose
  )
  call make.cmd "!folder!" "!cmdParam!"
  goto loop
)

:: Проверка команды обновления (r)
if /i "!cmdInput!"=="r" goto loop

:: Проверяем, число ли cmdInput 
set "isNumber=1"
for /f "delims=0123456789" %%x in ("!cmdInput!") do set "isNumber=0"

if "!isNumber!"=="1" (
  set /a selNum=!cmdInput! 2>nul
  if !selNum! lss 1 (
    echo Номер меньше 1.
    goto choose
  )
  if !selNum! gtr !totalCount! (
    echo Номер больше количества элементов.
    goto choose
  )
  call :getItemInfo !selNum!
  if not defined selectedType (
    echo Ошибка: не найден выбранный элемент.
    goto choose
  )
  if "!selectedType!"=="p" (
    if "!folder:~-1!"=="\" (
      set "folder=!folder!!selectedName!"
    ) else (
      set "folder=!folder!\!selectedName!"
    )
    goto loop
  )
  if "!selectedType!"=="f" (
    if "!folder:~-1!"=="\" (
      set "fullPath=!folder!!selectedName!"
    ) else (
      set "fullPath=!folder!\!selectedName!"
    )
    start "" cmd /c ""!fullPath!""
    goto loop
  )
)

echo Некорректный ввод.
goto choose

:getItemInfo
setlocal enabledelayedexpansion
set idx=%1
call set "nm=%%itemName[!idx!]%%"
call set "tp=%%itemType[!idx!]%%"
endlocal & (
  set "selectedName=%nm%"
  set "selectedType=%tp%"
)
goto :eof

:end
endlocal
exit /b 0