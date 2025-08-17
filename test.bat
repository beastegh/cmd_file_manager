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
call path.cmd "!folder!" || (
  echo DEBUG: Ошибка вызова path.cmd, errorlevel=!errorlevel!>>"!folder!\debug.log"
  goto choose
)

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
      if not "!nameLeft!"=="" (
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
      if not "!nameRight!"=="" (
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
      if not "!nameLeft!"=="" (
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
      if not "!nameRight!"=="" (
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
set /p "choice=$ " 2>nul
if "!choice!"=="" (
  echo DEBUG: Пустой ввод, повтор>>"!folder!\debug.log"
  goto loop
)

:: Очищаем ввод
set "choice=%choice:"=%"
for /f "tokens=*" %%a in ("!choice!") do set "choice=%%a"

:: Разбиваем ввод на команду и параметр
for /f "tokens=1* delims= " %%a in ("!choice!") do (
  set "cmdInput=%%a"
  set "cmdParam=%%b"
)

if /i "!cmdInput!"=="q" (
  echo DEBUG: Выход по команде q>>"!folder!\debug.log"
  goto end
)

if "!cmdInput!"=="/" (
  echo DEBUG: Переход к корню диска>>"!folder!\debug.log"
  for %%A in ("!folder!") do set "folder=%%~dA\"
  goto loop
)

if /i "!cmdInput!"=="disk" (
  echo DEBUG: Вызов disk.bat>>"!folder!\debug.log"
  call disk.bat
  goto loop
)

if /i "!cmdInput!"=="trash" (
  echo DEBUG: Переход в C:\Корзина>>"!folder!\debug.log"
  set "folder=C:\Корзина"
  goto loop
)

if /i "!cmdInput!"=="b" (
  echo DEBUG: Переход на уровень выше>>"!folder!\debug.log"
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

if /i "!cmdInput!"=="del" goto handle_del
if /i "!cmdInput!"=="make" goto handle_make
if /i "!cmdInput!"=="restore" goto handle_restore
if /i "!cmdInput!"=="r" goto handle_refresh

:: Проверка, является ли ввод числом
set "isNumber=1"
for /f "delims=0123456789" %%x in ("!cmdInput!") do set "isNumber=0"

if !isNumber!==1 goto handle_number

echo Некорректный ввод.
echo DEBUG: Ошибка: Некорректный ввод "!cmdInput!">>"!folder!\debug.log"
goto choose

:handle_del
if "!cmdParam!"=="" (
  echo Укажите номер для удаления, например: del 3 или del all или del 1 5 7
  echo DEBUG: Ошибка: Не указан параметр для del>>"!folder!\debug.log"
  goto choose
)
if /i "!cmdParam!"=="all" goto del_all

echo DEBUG: Начало обработки номеров для del: cmdParam=[!cmdParam!]>>"!folder!\debug.log"
set "success=1"
for %%N in (!cmdParam!) do (
  set "delNum=%%N"
  set "delNum=!delNum: =!"
  if not "!delNum!"=="" (
    call :process_del_number !delNum!
  )
)
if !success!==0 (
  echo Ошибка при удалении одного или нескольких элементов.
)
echo DEBUG: Завершение обработки номеров для del, success=!success!>>"!folder!\debug.log"
goto loop

:del_all
if !totalCount! equ 0 (
  echo Нет элементов для удаления.
  echo DEBUG: Нет элементов для удаления в del all>>"!folder!\debug.log"
  goto choose
)
echo DEBUG: Начало del all, totalCount=!totalCount!>>"!folder!\debug.log"

:: Создаем список всех файлов для удаления
set "delList="
set /a validCount=0
for /L %%q in (1,1,!totalCount!) do (
  set "delName=!itemName[%%q]!"
  set "delType=!itemType[%%q]!"
  set "delName=!delName:"=!"
  echo DEBUG: Проверка элемента %%q: delName=[!delName!] delType=[!delType!]>>"!folder!\debug.log"
  if not "!delName!"=="" if exist "!folder!\!delName!" if /i not "!delName!"=="log.txt" (
    if "!delList!"=="" (
      set "delList=!delName!"
    ) else (
      set "delList=!delList!|!delName!"
    )
    set /a validCount+=1
    echo DEBUG: Добавлен в список: [!delName!]>>"!folder!\debug.log"
  ) else (
    if "!delName!"=="" (
      echo DEBUG: Пустое имя элемента %%i>>"!folder!\debug.log"
    ) else if not exist "!folder!\!delName!" (
      echo DEBUG: Пропуск несуществующего: [!delName!]>>"!folder!\debug.log"
    ) else if /i "!delName!"=="log.txt" (
      echo DEBUG: Пропуск log.txt>>"!folder!\debug.log"
    )
  )
)
if !validCount! equ 0 (
  echo Нет элементов для удаления.
  echo DEBUG: Нет валидных элементов для удаления>>"!folder!\debug.log"
  goto choose
)

echo DEBUG: Список для удаления: [!delList!], количество: !validCount!>>"!folder!\debug.log"

:: Если в корзине, делаем массовое удаление через специальный батник
if !isRecycle!==1 (
  echo DEBUG: Массовое удаление в корзине>>"!folder!\debug.log"
  call :mass_delete_from_recycle "!delList!"
) else (
  echo DEBUG: Массовое перемещение в корзину>>"!folder!\debug.log"
  call :mass_move_to_recycle "!delList!"
)

:: Обновляем массивы
echo DEBUG: Очистка массивов>>"!folder!\debug.log"
for /L %%d in (1,1,!totalCount!) do (
  set "itemName[%%d]="
  set "itemType[%%d]="
)
set /a totalCount=0
set /a folderCount=0
set /a fileCount=0

echo DEBUG: Завершение del all>>"!folder!\debug.log"
goto loop

:mass_delete_from_recycle
setlocal enabledelayedexpansion
set "itemList=%~1"
set "recycle=!folder!"
set "log_file=!recycle!\log.txt"

echo DEBUG: mass_delete_from_recycle, itemList=[!itemList!]>>"!recycle!\debug.log"

:: Удаляем физически все файлы/папки
for %%F in ("!itemList:|=" "!") do (
  set "itemName=%%~F"
  set "itemName=!itemName:"=!"
  if not "!itemName!"=="" (
    set "fullPath=!recycle!\!itemName!"
    echo DEBUG: Удаление физического элемента: [!fullPath!]>>"!recycle!\debug.log"
    
    if exist "!fullPath!\*" (
      rd /s /q "!fullPath!" 2>nul
      echo DEBUG: Удалена папка [!itemName!]>>"!recycle!\debug.log"
    ) else if exist "!fullPath!" (
      del /f /q "!fullPath!" 2>nul
      echo DEBUG: Удален файл [!itemName!]>>"!recycle!\debug.log"
    )
  )
)

:: Обновляем log.txt - удаляем все записи для удаленных элементов
if exist "!log_file!" (
  echo DEBUG: Обновление log.txt>>"!recycle!\debug.log"
  set "temp_log=!recycle!\log_temp_!random!!time:~6,2!.txt"
  
  if exist "!temp_log!" del "!temp_log!" >nul 2>&1
  
  for /f "usebackq delims=" %%l in ("!log_file!") do (
    set "line=%%l"
    set "write_line=1"
    
    if not "!line!"=="" (
      for /f "tokens=1 delims=|" %%a in ("!line!") do (
        set "log_name=%%a"
        
        :: Проверяем, есть ли этот элемент в списке для удаления
        for %%F in ("!itemList:|=" "!") do (
          set "checkName=%%~F"
          set "checkName=!checkName:"=!"
          if "!log_name!"=="!checkName!" (
            set "write_line=0"
            echo DEBUG: Удаляем запись из log.txt: [!line!]>>"!recycle!\debug.log"
          )
        )
      )
    )
    
    if !write_line! equ 1 (
      echo !line!>>"!temp_log!"
    )
  )
  
  if exist "!temp_log!" (
    move /y "!temp_log!" "!log_file!" >nul 2>&1
    if errorlevel 1 (
      echo DEBUG: Ошибка обновления log.txt>>"!recycle!\debug.log"
      del "!temp_log!" >nul 2>&1
    ) else (
      echo DEBUG: log.txt успешно обновлен>>"!recycle!\debug.log"
    )
  ) else (
    :: Если временный файл пуст, создаем пустой log.txt
    echo DEBUG: Временный файл пуст, создаем пустой log.txt>>"!recycle!\debug.log"
    echo.>"!log_file!"
    del "!log_file!" >nul 2>&1
    type nul > "!log_file!"
  )
)

endlocal
goto :eof

:mass_move_to_recycle
setlocal enabledelayedexpansion
set "itemList=%~1"
set "recycle=C:\Корзина"
set "log_file=!recycle!\log.txt"

echo DEBUG: mass_move_to_recycle, itemList=[!itemList!]>>"!folder!\debug.log"

if not exist "!recycle!" (
  mkdir "!recycle!" 2>nul
)

:: Перемещаем все файлы/папки в корзину и собираем информацию для лога
set "timestamp=!date! в !time:~0,8!"
set "orig_path=!folder!"

for %%F in ("!itemList:|=" "!") do (
  set "itemName=%%~F"
  set "itemName=!itemName:"=!"
  if not "!itemName!"=="" (
    set "fullPath=!folder!\!itemName!"
    echo DEBUG: Перемещение элемента: [!fullPath!] в корзину>>"!folder!\debug.log"
    
    if exist "!fullPath!" (
      :: Определяем размер
      if exist "!fullPath!\*" (
        set "size=папка"
        for /f "tokens=3" %%a in ('dir /s /a /-c "!fullPath!" 2^>nul ^| find "File(s)"') do if not "%%a"=="" set "size=%%a байт"
      ) else (
        set "size=0 байт"
        for /f "tokens=3" %%a in ('dir /a /-c "!fullPath!" 2^>nul ^| find "File(s)"') do if not "%%a"=="" set "size=%%a байт"
      )
      
      move "!fullPath!" "!recycle!\" >nul 2>&1
      if not errorlevel 1 (
        echo DEBUG: Добавление в log.txt: !itemName!^|!timestamp!^|!orig_path!^|!size!>>"!folder!\debug.log"
        echo !itemName!^|!timestamp!^|!orig_path!^|!size!>>"!log_file!"
      ) else (
        echo DEBUG: Ошибка перемещения [!itemName!]>>"!folder!\debug.log"
      )
    )
  )
)

endlocal
goto :eof

:process_del_number
set /a delNum=%1 2>nul
if !delNum! equ 0 (
  echo Некорректный номер: "%1".
  echo DEBUG: Ошибка: Некорректный номер "%1" для del>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if !delNum! lss 1 (
  echo Номер для удаления должен быть >= 1: "!delNum!".
  echo DEBUG: Ошибка: Номер меньше 1 "!delNum!" для del>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if !delNum! gtr !totalCount! (
  echo Номер превышает количество элементов: "!delNum!".
  echo DEBUG: Ошибка: Номер превышает totalCount "!delNum!" для del>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
set "delName=!itemName[%delNum%]!"
set "delType=!itemType[%delNum%]!"
echo DEBUG: Проверка номера !delNum!: delName=[!delName!] delType=[!delType!]>>"!folder!\debug.log"
if "!delName!"=="" (
  echo Элемент с номером !delNum! не найден.
  echo DEBUG: Ошибка: delName не определён для номера !delNum!>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if not exist "!folder!\!delName!" (
  echo Элемент "!delName!" не найден в каталоге.
  echo DEBUG: Ошибка: "!folder!\!delName!" не существует>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
echo DEBUG: Вызов del.cmd "!folder!\!delName!">>"!folder!\debug.log"
call del.cmd "!folder!\!delName!"
if errorlevel 1 (
  echo DEBUG: Ошибка del.cmd для "!delName!" (errorlevel=!errorlevel!)>>"!folder!\debug.log"
  set "success=0"
) else (
  echo DEBUG: Успешно удалено "!delName!" с номером !delNum!>>"!folder!\debug.log"
)
goto :eof

:handle_make
if "!cmdParam!"=="" (
  echo Укажите имя файла/папки для создания, например: make file.txt или make folder1 folder2
  echo DEBUG: Ошибка: Не указан параметр для make>>"!folder!\debug.log"
  goto choose
)
echo DEBUG: Вызов make.cmd "!folder!" "!cmdParam!">>"!folder!\debug.log"
call make.cmd "!folder!" "!cmdParam!"
goto loop

:handle_restore
if !isRecycle! neq 1 (
  echo Команда restore доступна только в C:\Корзина.
  echo DEBUG: Ошибка: restore вызван не в C:\Корзина>>"!folder!\debug.log"
  goto choose
)
if "!cmdParam!"=="" (
  echo Укажите номер для восстановления, например: restore 3 или restore all или restore 1 5 7
  echo DEBUG: Ошибка: Не указан параметр для restore>>"!folder!\debug.log"
  goto choose
)
echo DEBUG: Начало обработки restore: cmdParam=[!cmdParam!]>>"!folder!\debug.log"
if /i "!cmdParam!"=="all" goto restore_all

echo DEBUG: Начало обработки номеров для restore: cmdParam=[!cmdParam!]>>"!folder!\debug.log"
set "success=1"
for %%N in (!cmdParam!) do (
  set "restoreNum=%%N"
  set "restoreNum=!restoreNum: =!"
  if not "!restoreNum!"=="" (
    call :process_restore_number !restoreNum!
  ) else (
    set "success=0"
  )
)
if !success!==0 (
  echo Ошибка при восстановлении одного или нескольких элементов.
)
echo DEBUG: Завершение обработки номеров для restore, success=!success!>>"!folder!\debug.log"
goto loop

:restore_all
if !isRecycle! neq 1 (
  echo Команда restore доступна только в C:\Корзина.
  echo DEBUG: Ошибка: restore all вызван не в C:\Корзина>>"!folder!\debug.log"
  goto choose
)

if !totalCount! equ 0 (
  echo Нет элементов для восстановления.
  echo DEBUG: Нет элементов для восстановления в restore all>>"!folder!\debug.log"
  goto choose
)

echo DEBUG: Начало restore all, totalCount=!totalCount!>>"!folder!\debug.log"

:: Создаем список всех файлов для восстановления (кроме log.txt)
set "restoreList="
set /a validCount=0
for /L %%i in (1,1,!totalCount!) do (
  set "restoreName=!itemName[%%i]!"
  set "restoreName=!restoreName:"=!"
  echo DEBUG: Проверка элемента %%i: restoreName=[!restoreName!]>>"!folder!\debug.log"
  if not "!restoreName!"=="" if exist "!folder!\!restoreName!" if /i not "!restoreName!"=="log.txt" (
    if "!restoreList!"=="" (
      set "restoreList=!restoreName!"
    ) else (
      set "restoreList=!restoreList!|!restoreName!"
    )
    set /a validCount+=1
    echo DEBUG: Добавлен в список: [!restoreName!]>>"!folder!\debug.log"
  ) else (
    if "!restoreName!"=="" (
      echo DEBUG: Пустое имя элемента %%i>>"!folder!\debug.log"
    ) else if not exist "!folder!\!restoreName!" (
      echo DEBUG: Пропуск несуществующего: [!restoreName!]>>"!folder!\debug.log"
    ) else if /i "!restoreName!"=="log.txt" (
      echo DEBUG: Пропуск log.txt>>"!folder!\debug.log"
    )
  )
)

if !validCount! equ 0 (
  echo Нет элементов для восстановления.
  echo DEBUG: Нет валидных элементов для восстановления>>"!folder!\debug.log"
  goto choose
)

echo DEBUG: Список для восстановления: [!restoreList!], количество: !validCount!>>"!folder!\debug.log"
call :mass_restore_from_recycle "!restoreList!"

:: Обновляем массивы
echo DEBUG: Очистка массивов>>"!folder!\debug.log"
for /L %%d in (1,1,!totalCount!) do (
  set "itemName[%%d]="
  set "itemType[%%d]="
)
set /a totalCount=0
set /a folderCount=0
set /a fileCount=0

echo DEBUG: Завершение restore all>>"!folder!\debug.log"
goto loop

:mass_restore_from_recycle
setlocal enabledelayedexpansion
set "itemList=%~1"
set "recycle=!folder!"
set "log_file=!recycle!\log.txt"

echo DEBUG: mass_restore_from_recycle, itemList=[!itemList!]>>"!recycle!\debug.log"

if not exist "!log_file!" (
  echo DEBUG: log.txt не найден для массового восстановления>>"!recycle!\debug.log"
  echo Файл log.txt не найден. Восстановление невозможно.
  endlocal
  goto :eof
)

:: Создаем временный файл для хранения обработанных записей лога
set "temp_log=!recycle!\log_temp_!random!!time:~6,2!.txt"
if exist "!temp_log!" del "!temp_log!" >nul 2>&1

:: Восстанавливаем каждый элемент из списка
for %%F in ("!itemList:|=" "!") do (
  set "itemName=%%~F"
  set "itemName=!itemName:"=!"
  if not "!itemName!"=="" (
    echo DEBUG: Обработка элемента для восстановления: [!itemName!]>>"!recycle!\debug.log"
    
    :: Ищем путь для этого элемента в log.txt
    set "orig_path="
    set "found_entry=0"
    set "log_line="
    
    for /f "usebackq delims=" %%a in ("!log_file!") do (
      set "line=%%a"
      if not "!line!"=="" (
        for /f "tokens=1,3 delims=|" %%i in ("!line!") do (
          set "log_name=%%i"
          set "log_path=%%j"
          
          if "!log_name!"=="!itemName!" (
            set "orig_path=!log_path!"
            set "found_entry=1"
            set "log_line=!line!"
            echo DEBUG: Найден путь для [!itemName!]: [!orig_path!]>>"!recycle!\debug.log"
          )
        )
      )
    )
    
    if !found_entry!==1 if not "!orig_path!"=="" (
      :: Создаем целевую папку если не существует
      if not exist "!orig_path!" (
        echo DEBUG: Создание папки [!orig_path!]>>"!recycle!\debug.log"
        mkdir "!orig_path!" 2>nul
      )
      
      :: Проверяем, не существует ли уже элемент в целевом месте
      if not exist "!orig_path!\!itemName!" (
        :: Перемещаем элемент
        set "sourcePath=!recycle!\!itemName!"
        echo DEBUG: Перемещение [!sourcePath!] в [!orig_path!]>>"!recycle!\debug.log"
        
        move "!sourcePath!" "!orig_path!\" >nul 2>&1
        if not errorlevel 1 (
          echo DEBUG: Успешно восстановлен [!itemName!] в [!orig_path!]>>"!recycle!\debug.log"
          echo Восстановлен "!itemName!" в "!orig_path!".
        ) else (
          echo DEBUG: Ошибка перемещения [!itemName!]>>"!recycle!\debug.log"
          echo Ошибка при восстановлении "!itemName!".
        )
      ) else (
        echo DEBUG: [!itemName!] уже существует в [!orig_path!]>>"!recycle!\debug.log"
        echo Элемент "!itemName!" уже существует в "!orig_path!".
      )
    ) else (
      echo DEBUG: Путь не найден для [!itemName!]>>"!recycle!\debug.log"
      echo Исходный путь для "!itemName!" не найден в log.txt.
    )
  )
)

:: Обновляем log.txt - удаляем записи для успешно восстановленных элементов
echo DEBUG: Обновление log.txt после массового восстановления>>"!recycle!\debug.log"

for /f "usebackq delims=" %%l in ("!log_file!") do (
  set "line=%%l"
  set "write_line=1"
  
  if not "!line!"=="" (
    for /f "tokens=1 delims=|" %%a in ("!line!") do (
      set "log_name=%%a"
      
      :: Проверяем, был ли этот элемент успешно восстановлен (не существует в корзине)
      for %%F in ("!itemList:|=" "!") do (
        set "checkName=%%~F"
        set "checkName=!checkName:"=!"
        if "!log_name!"=="!checkName!" (
          set "itemPath=!recycle!\!checkName!"
          if not exist "!itemPath!" (
            set "write_line=0"
            echo DEBUG: Удаляем запись из log.txt для восстановленного: [!line!]>>"!recycle!\debug.log"
          )
        )
      )
    )
  )
  
  if !write_line! equ 1 (
    echo !line!>>"!temp_log!"
  )
)

if exist "!temp_log!" (
  move /y "!temp_log!" "!log_file!" >nul 2>&1
  if errorlevel 1 (
    echo DEBUG: Ошибка обновления log.txt после массового восстановления>>"!recycle!\debug.log"
    del "!temp_log!" >nul 2>&1
  ) else (
    echo DEBUG: log.txt успешно обновлен после массового восстановления>>"!recycle!\debug.log"
  )
)

endlocal
goto :eof

:process_restore_number
set /a restoreNum=%1 2>nul
if !restoreNum! equ 0 (
  echo Некорректный номер: "%1".
  echo DEBUG: Ошибка: Некорректный номер "%1" для restore>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if !restoreNum! lss 1 (
  echo Номер для восстановления должен быть >= 1: "!restoreNum!".
  echo DEBUG: Ошибка: Номер меньше 1 "!restoreNum!" для restore>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if !restoreNum! gtr !totalCount! (
  echo Номер превышает количество элементов: "!restoreNum!".
  echo DEBUG: Ошибка: Номер превышает totalCount "!restoreNum!" для restore>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
set "restoreName=!itemName[%restoreNum%]!"
set "restoreType=!itemType[%restoreNum%]!"
echo DEBUG: Проверка номера !restoreNum!: restoreName=[!restoreName!] restoreType=[!restoreType!]>>"!folder!\debug.log"
if "!restoreName!"=="" (
  echo Элемент с номером !restoreNum! не найден.
  echo DEBUG: Ошибка: restoreName не определён для номера !restoreNum!>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if not exist "!folder!\!restoreName!" (
  echo Элемент "!restoreName!" не найден в каталоге.
  echo DEBUG: Ошибка: "!folder!\!restoreName!" не существует>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
if /i "!restoreName!"=="log.txt" (
  echo Нельзя восстановить log.txt.
  echo DEBUG: Пропуск: restoreName=[!restoreName!] это log.txt>>"!folder!\debug.log"
  set "success=0"
  goto :eof
)
echo DEBUG: Вызов restore.bat "!folder!" "!restoreName!">>"!folder!\debug.log"
call restore.bat "!folder!" "!restoreName!"
set "restore_result=!errorlevel!"
echo DEBUG: restore.cmd вернул errorlevel=!restore_result!>>"!folder!\debug.log"
if !restore_result! neq 0 (
  echo Ошибка при восстановлении "!restoreName!" с номером !restoreNum!.
  echo DEBUG: Ошибка restore.bat для "!restoreName!" с номером !restoreNum! (errorlevel=!restore_result!)>>"!folder!\debug.log"
  set "success=0"
) else (
  echo Восстановлен "!restoreName!" с номером !restoreNum!.
  echo DEBUG: Успешно восстановлено "!restoreName!" с номером !restoreNum!>>"!folder!\debug.log"
)
goto :eof

:handle_refresh
echo DEBUG: Обновление по команде r>>"!folder!\debug.log"
goto loop

:handle_number
echo DEBUG: Проверка числового ввода: cmdInput=[!cmdInput!]>>"!folder!\debug.log"
set /a selNum=!cmdInput! 2>nul
if !selNum! equ 0 goto number_error
if !selNum! lss 1 goto number_too_small
if !selNum! gtr !totalCount! goto number_too_big

call :getItemInfo !selNum!
echo DEBUG: Выбор элемента !selNum!: selectedName=[!selectedName!] selectedType=[!selectedType!]>>"!folder!\debug.log"
if "!selectedName!"=="" goto item_not_found

if "!selectedType!"=="p" goto navigate_to_folder
if "!selectedType!"=="f" goto open_file
goto unknown_item_type

:number_error
echo Некорректный номер: "!cmdInput!".
echo DEBUG: Ошибка: Некорректный номер "!cmdInput!" для перехода>>"!folder!\debug.log"
goto choose

:number_too_small
echo Номер меньше 1.
echo DEBUG: Ошибка: Номер меньше 1 "!selNum!" для перехода>>"!folder!\debug.log"
goto choose

:number_too_big
echo Номер больше количества элементов.
echo DEBUG: Ошибка: Номер превышает totalCount "!selNum!" для перехода>>"!folder!\debug.log"
goto choose

:item_not_found
echo Ошибка: не найден выбранный элемент.
echo DEBUG: Ошибка: selectedName не определён для номера !selNum!>>"!folder!\debug.log"
goto choose

:navigate_to_folder
echo DEBUG: Переход в папку "!selectedName!">>"!folder!\debug.log"
if "!folder:~-1!"=="\" (
  set "folder=!folder!!selectedName!"
) else (
  set "folder=!folder!\!selectedName!"
)
goto loop

:open_file
echo DEBUG: Открытие файла "!selectedName!">>"!folder!\debug.log"
if "!folder:~-1!"=="\" (
  set "fullPath=!folder!!selectedName!"
) else (
  set "fullPath=!folder!\!selectedName!"
)
start "" cmd /c ""!fullPath!""
goto loop

:unknown_item_type
echo Ошибка: Неизвестный тип элемента для "!selectedName!".
echo DEBUG: Ошибка: Неизвестный тип элемента "!selectedType!" для "!selectedName!">>"!folder!\debug.log"
goto choose

:getItemInfo
setlocal enabledelayedexpansion
set idx=%1
set "nm=!itemName[%idx%]!"
set "tp=!itemType[%idx%]!"
endlocal & (
  set "selectedName=%nm%"
  set "selectedType=%tp%"
)
goto :eof

:end
echo DEBUG: Завершение работы>>"!folder!\debug.log"
endlocal
exit /b 0