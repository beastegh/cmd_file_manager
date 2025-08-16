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

:: 25 пробелов для отступа
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
    call set "name=%%itemName[%%i]%%"
    call set "type=%%itemType[%%i]%%"
    if /i "!name!"=="log.txt" (
      set found=1
      set /a totalCount-=1
      if "!type!"=="f" set /a fileCount-=1
      if "!type!"=="p" set /a folderCount-=1
    ) else if !found!==1 (
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

:: Вывод папок в 2 колонки
if !folderCount! gtr 0 (
  set /a "rows=(folderCount+1)/2"
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

:: Вывод файлов в 2 колонки
if !fileCount! gtr 0 (
  set /a "fileRows=(fileCount+1)/2"
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

:: Очищаем ввод
set "choice=%choice:"=%"
for /f "tokens=*" %%a in ("!choice!") do set "choice=%%a"

:: Разбиваем ввод на команду и параметр
for /f "tokens=1* delims= " %%a in ("!choice!") do (
  set "cmdInput=%%a"
  set "cmdParam=%%b"
)

if /i "!cmdInput!"=="q" goto end

if "!cmdInput!"=="/" (
  for %%A in ("!folder!") do set "folder=%%~dA\"
  goto loop
)

if /i "!cmdInput!"=="disk" (
  call disk.bat
  goto loop
)

if /i "!cmdInput!"=="trash" (
  set "folder=C:\Корзина"
  goto loop
)

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

if /i "!cmdInput!"=="del" (
  if not defined cmdParam (
    echo Укажите номер для удаления, например: del 3 или del all или del 1 5 7
    goto choose
  )
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
      if defined delName (
        if exist "!folder!\!delName!" (
          if /i not "!delName!"=="log.txt" (
            echo DEBUG: Вызов del.cmd "!folder!\!delName!">>debug.log
            call del.cmd "!folder!\!delName!"
            if errorlevel 1 (
              echo DEBUG: Ошибка del.cmd для "!delName!" (errorlevel=!errorlevel!)>>debug.log
              set "success=0"
            ) else (
              echo DEBUG: Успешно удалено "!delName!">>debug.log
            )
          ) else (
            echo DEBUG: Пропуск log.txt>>debug.log
          )
        ) else (
          echo DEBUG: Пропуск %%o: delName=[!delName!] не существует>>debug.log
        )
      ) else (
        echo DEBUG: Пропуск %%o: delName не определён>>debug.log
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
  echo DEBUG: Начало обработки номеров для del: cmdParam=[!cmdParam!]>>debug.log
  set "success=1"
  for %%N in (!cmdParam!) do (
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
          echo DEBUG: Вызов del.cmd "!folder!\!delName!">>debug.log
          call del.cmd "!folder!\!delName!"
          if errorlevel 1 (
            echo DEBUG: Ошибка del.cmd для "!delName!" (errorlevel=!errorlevel!)>>debug.log
            set "success=0"
          ) else (
            echo DEBUG: Успешно удалено "!delName!" с номером !delNum!>>debug.log
          )
        )
      )
    )
  )
  if !success!==0 (
    echo Ошибка при удалении одного или нескольких элементов.
  )
  echo DEBUG: Завершение обработки номеров для del, success=!success!>>debug.log
  goto loop
)

if /i "!cmdInput!"=="make" (
  if not defined cmdParam (
    echo Укажите имя файла/папки для создания, например: make file.txt или make folder1 folder2
    goto choose
  )
  echo DEBUG: Вызов make.cmd "!folder!" "!cmdParam!">>debug.log
  call make.cmd "!folder!" "!cmdParam!"
  goto loop
)

if /i "!cmdInput!"=="restore" (
  if !isRecycle! neq 1 (
    echo Команда restore доступна только в C:\Корзина.
    goto choose
  )
  if not defined cmdParam (
    echo Укажите номер для восстановления, например: restore 3 или restore all или restore 1 5 7
    goto choose
  )
  set "cmdParam=!cmdParam: =!"
  echo DEBUG: Начало обработки restore: cmdParam=[!cmdParam!]>>debug.log
  if /i "!cmdParam!"=="all" (
    if !totalCount! equ 0 (
      echo Нет элементов для восстановления.
      goto choose
    )
    echo DEBUG: Начало restore all, totalCount=!totalCount!>>debug.log
    set /a tempTotal=!totalCount!
    set "success=1"
    for /L %%o in (1,1,!tempTotal!) do (
      call set "restoreName=%%itemName[%%o]%%"
      call set "restoreType=%%itemType[%%o]%%"
      set "restoreName=!restoreName:"=!"
      echo DEBUG: Обработка %%o: restoreName=[!restoreName!] restoreType=[!restoreType!]>>debug.log
      if not defined restoreName (
        echo DEBUG: Пропуск %%o: restoreName не определён>>debug.log
        set "success=0"
      ) else if not exist "!folder!\!restoreName!" (
        echo DEBUG: Пропуск %%o: restoreName=[!restoreName!] не существует>>debug.log
        set "success=0"
      ) else if /i "!restoreName!"=="log.txt" (
        echo DEBUG: Пропуск log.txt>>debug.log
      ) else (
        echo DEBUG: Вызов restore.cmd "!folder!" "!restoreName!">>debug.log
        call restore.cmd "!folder!" "!restoreName!"
        if errorlevel 1 (
          echo DEBUG: Ошибка restore.cmd для "!restoreName!" (errorlevel=!errorlevel!)>>debug.log
          set "success=0"
        ) else (
          echo DEBUG: Успешно восстановлено "!restoreName!">>debug.log
        )
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
    echo DEBUG: Завершение restore all, success=!success!>>debug.log
    goto loop
  )
  echo DEBUG: Начало обработки номеров для restore: cmdParam=[!cmdParam!]>>debug.log
  set "success=1"
  for %%N in (!cmdParam!) do (
    set "restoreNum=%%N"
    set "restoreNum=!restoreNum: =!"
    if not defined restoreNum (
      echo DEBUG: Пропуск: restoreNum не определён>>debug.log
      set "success=0"
    ) else (
      set /a restoreNum=restoreNum 2>nul
      if !restoreNum! equ 0 (
        echo Некорректный номер: "!restoreNum!".
        echo DEBUG: Ошибка: Некорректный номер "!restoreNum!">>debug.log
        set "success=0"
      ) else if !restoreNum! lss 1 (
        echo Номер для восстановления должен быть >= 1: "!restoreNum!".
        echo DEBUG: Ошибка: Номер меньше 1 "!restoreNum!">>debug.log
        set "success=0"
      ) else if !restoreNum! gtr !totalCount! (
        echo Номер превышает количество элементов: "!restoreNum!".
        echo DEBUG: Ошибка: Номер превышает totalCount "!restoreNum!">>debug.log
        set "success=0"
      ) else (
        call set "restoreName=%%itemName[!restoreNum!]%%"
        call set "restoreType=%%itemType[!restoreNum!]%%"
        echo DEBUG: Проверка номера !restoreNum!: restoreName=[!restoreName!] restoreType=[!restoreType!]>>debug.log
        if not defined restoreName (
          echo Элемент с номером !restoreNum! не найден.
          echo DEBUG: Ошибка: restoreName не определён для номера !restoreNum!>>debug.log
          set "success=0"
        ) else if not exist "!folder!\!restoreName!" (
          echo Элемент "!restoreName!" не найден в каталоге.
          echo DEBUG: Ошибка: "!folder!\!restoreName!" не существует>>debug.log
          set "success=0"
        ) else if /i "!restoreName!"=="log.txt" (
          echo Нельзя восстановить log.txt.
          echo DEBUG: Пропуск: restoreName=[!restoreName!] это log.txt>>debug.log
          set "success=0"
        ) else (
          echo DEBUG: Вызов restore.cmd "!folder!" "!restoreName!">>debug.log
          call restore.cmd "!folder!" "!restoreName!"
          if errorlevel 1 (
            echo Ошибка при восстановлении "!restoreName!" с номером !restoreNum!.
            echo DEBUG: Ошибка restore.cmd для "!restoreName!" с номером !restoreNum! (errorlevel=!errorlevel!)>>debug.log
            set "success=0"
          ) else (
            echo Восстановлен "!restoreName!" с номером !restoreNum!.
            echo DEBUG: Успешно восстановлено "!restoreName!" с номером !restoreNum!>>debug.log
          )
        )
      )
    )
  )
  if !success!==0 (
    echo Ошибка при восстановлении одного или нескольких элементов.
  )
  echo DEBUG: Завершение обработки номеров для restore, success=!success!>>debug.log
  goto loop
)

if /i "!cmdInput!"=="r" goto loop

set "isNumber=1"
for /f "delims=0123456789" %%x in ("!cmdInput!") do set "isNumber=0"

if !isNumber!==1 (
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