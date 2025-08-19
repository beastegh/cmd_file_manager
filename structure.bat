mkdir c:\cli
cd c:\cli
echo.>main.bat
mkdir core
cd core
echo.>ui.bat
echo.>input.bat
echo.>navigation.bat
echo.>history_stack.bat
echo.>paths.bat
cd ..
mkdir features\nav
cd features\nav
echo.>breadcrumbs.bat
echo.>favorites.bat
echo.>goto.bat
echo.>find.bat
echo.>disks.bat
cd ..\..
mkdir features\system
cd features\system
echo.>tasks.bat
echo.>programs.bat
echo.>windows.bat
cd ..\..
mkdir features\git
mkdir features\files
cd features\files
echo.>file_ops.bat
echo.>hide_show.bat
echo.>buffer.bat
echo.>trash.bat
cd ..\..
mkdir features\utils
cd features\utils
echo.>logger.bat
echo.>temp.bat
echo.>helpers.bat
cd ..\..
mkdir data
cd data
echo.>history.txt
echo.>favorites.txt
echo.>buffer.list
echo.>trash_log.txt
cd ..
mkdir temp
mkdir tools
echo.>README.txt