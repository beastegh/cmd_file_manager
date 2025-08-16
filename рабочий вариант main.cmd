@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: �������� ��������� ����
if "%~1"=="" (
  set "folder=%cd%"
) else (
  set "folder=%~1"
)
set "folder=%folder:"=%"

:: ���������� ������� �����
:fix_slashes
set "temp=!folder!"
set "folder=!temp:\\=\!"
if not "!folder!"=="!temp!" goto fix_slashes

:: ������� ����������� ����, ����� ����� �����
:fix_trailing_slash
if not "!folder:~-1!"=="\" goto no_slash_to_remove
if "!folder:~1,2!"==":\" goto no_slash_to_remove
set "folder=!folder:~0,-1!"
:no_slash_to_remove

set "spc=                                                "

:loop
cls
echo ����: !folder!
echo.

:: �������� path.cmd ��� ��������� ������� � ����������
call path.cmd "!folder!"

if !totalCount! equ 0 (
  echo �������: 0 ���������
  echo.
  goto choose
)

:: ����� ����� � 2 ������� (����������)
set /a rows=(folderCount + 1) / 2
echo ***************************** ����� ********************************
echo.
for /L %%r in (1,1,!rows!) do (
  set /a leftIdx=%%r
  set /a rightIdx=%%r+!rows!

  if !leftIdx! leq !folderCount! (
    call set "nameLeft=%%itemName[!leftIdx!]%%"
    set "cellLeft=!leftIdx!. !nameLeft!!spc!"
    set "cellLeft=!cellLeft:~0,45!"
    <nul set /p =!cellLeft!
  ) else (
    <nul set /p ="                                             "
  )

  if !rightIdx! leq !folderCount! (
    call set "nameRight=%%itemName[!rightIdx!]%%"
    set "cellRight=!rightIdx!. !nameRight!!spc!"
    set "cellRight=!cellRight:~0,45!"
    echo !cellRight!
  ) else (
    echo.
  )
)
echo.

:: ����� ������ � 2 ������� (����������)
echo ***************************** ����� ********************************
echo.
set /a fileStart=folderCount+1
set /a fileRows=(fileCount + 1) / 2
for /L %%r in (1,1,!fileRows!) do (
  set /a leftIdx=%%r + fileStart - 1
  set /a rightIdx=%%r + fileRows + fileStart - 1

  if !leftIdx! leq !totalCount! (
    call set "nameLeft=%%itemName[!leftIdx!]%%"
    set "cellLeft=!leftIdx!. !nameLeft!!spc!"
    set "cellLeft=!cellLeft:~0,45!"
    <nul set /p =!cellLeft!
  ) else (
    <nul set /p ="                                             "
  )

  if !rightIdx! leq !totalCount! (
    call set "nameRight=%%itemName[!rightIdx!]%%"
    set "cellRight=!rightIdx!. !nameRight!!spc!"
    set "cellRight=!cellRight:~0,45!"
    echo !cellRight!
  ) else (
    echo.
  )
)
echo.
echo ********************************************************************
echo �����: !folderCount! ^| ������: !fileCount! ^| �����: !totalCount!
echo.

:: ����� ��������� ������
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
@REM echo �����: !drives!
@REM echo.

:choose
set "selectedName="
set "selectedType="
set /p "choice=$"
if not defined choice goto loop

:: ��������� ���� �� ������� � ��������
for /f "tokens=1*" %%a in ("!choice!") do (
  set "cmdInput=%%a"
  set "cmdParam=%%b"
)

if /i "!cmdInput!"=="q" goto end

if "!cmdInput!"=="/" (
  for %%A in ("!folder!") do set "folder=%%~dA\"
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

:: ������� �� ����� �����
set "foundDrive="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  if /i "!cmdInput!"=="%%D" (
    set "folder=%%D:\"
    set "foundDrive=1"
  )
)
if defined foundDrive goto loop

:: �������� ������� ��������
if /i "!cmdInput!"=="del" (
  if not defined cmdParam (
    echo ������� ����� ��� ��������, ��������: del 3
    goto choose
  )
  for /f "tokens=1" %%n in ("!cmdParam!") do set "delNum=%%~n"
  set /a delNum=delNum 2>nul
  if "!delNum!"=="" (
    echo ������������ ����� ��� ��������.
    goto choose
  )
  if !delNum! lss 1 (
    echo ����� ��� �������� ������ ���� >= 1.
    goto choose
  )
  if !delNum! gtr !totalCount! (
    echo ����� ��� �������� ��������� ���������� ���������.
    goto choose
  )
  call set "delName=%%itemName[!delNum!]%%"
  call set "delType=%%itemType[!delNum!]%%"
  if not defined delName (
    echo ������� � ������� !delNum! �� ������.
    goto choose
  )
  if not exist "!folder!\!delName!" (
    echo ������� "!delName!" �� ������ � ��������.
    goto choose
  )
  call del.cmd "!folder!\!delName!"
  goto loop
)

:: �������� ������� �������� (make)
if /i "!cmdInput!"=="make" (
  if not defined cmdParam (
    echo ������� ��� �����/����� ��� ��������, ��������: make file.txt ��� make folder1 | folder two
    goto choose
  )
  call make.cmd "!folder!" "!cmdParam!"
  goto loop
)

:: ���������, ����� �� cmdInput
set "isNumber=1"
for /f "delims=0123456789" %%x in ("!cmdInput!") do set "isNumber=0"

if "!isNumber!"=="1" (
  set /a selNum=!cmdInput! 2>nul
  if !selNum! lss 1 (
    echo ����� ������ 1.
    goto choose
  )
  if !selNum! gtr !totalCount! (
    echo ����� ������ ���������� ���������.
    goto choose
  )

  call :getItemInfo !selNum!
  if not defined selectedType (
    echo ������: �� ������ ��������� �������.
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
    @REM start "" cmd /c codium . -g "!fullPath!"
    @REM start "" "!fullPath!" 2>nul
    @REM start "" /b cmd /c ""!fullPath!" >nul 2>&1"
    start "" cmd /c ""!fullPath!""
    goto loop
  )
)

echo ������������ ����.
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







