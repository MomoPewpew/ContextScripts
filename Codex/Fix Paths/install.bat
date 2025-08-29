@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM Context Menu Installer for Python Scripts
REM Automatically adds the script in this directory to Windows right-click context menu
REM =============================================================================

echo.
echo ====================================================================
echo Context Menu Script Installer
echo ====================================================================
echo.

REM Step 1: Check if running as administrator
echo [1/4] Checking administrator privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator to modify the registry.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)
echo SUCCESS: Running with administrator privileges.
echo.

REM Step 2: Find the current directory and parse the path structure
echo [2/4] Analyzing directory structure...
set "CURRENT_DIR=%~dp0"
set "CURRENT_DIR=%CURRENT_DIR:~0,-1%"
echo Current directory: %CURRENT_DIR%

REM Find the ContextScripts directory in the path
set "CONTEXTSCRIPTS_FOUND=0"
set "RELATIVE_PATH="
set "CONTEXT_NAME="

REM Split the path to find ContextScripts and everything after it
for %%i in ("%CURRENT_DIR:\=" "%") do (
    if "!CONTEXTSCRIPTS_FOUND!"=="1" (
        if "!RELATIVE_PATH!"=="" (
            set "RELATIVE_PATH=%%~i"
        ) else (
            set "RELATIVE_PATH=!RELATIVE_PATH!\%%~i"
        )
        set "CONTEXT_NAME=%%~i"
    )
    if /i "%%~i"=="ContextScripts" (
        set "CONTEXTSCRIPTS_FOUND=1"
    )
)

if "!CONTEXTSCRIPTS_FOUND!"=="0" (
    echo ERROR: Could not find 'ContextScripts' directory in the current path.
    echo This script must be run from within a ContextScripts subdirectory.
    echo.
    pause
    exit /b 1
)

if "!RELATIVE_PATH!"=="" (
    echo ERROR: Script appears to be directly in ContextScripts directory.
    echo Please place script in a subdirectory to define the context menu structure.
    echo.
    pause
    exit /b 1
)

echo Found ContextScripts subdirectory: %RELATIVE_PATH%
echo Context menu name will be: %CONTEXT_NAME%
echo.

REM Step 3: Verify script.bat exists
if not exist "%CURRENT_DIR%\script.bat" (
    echo ERROR: script.bat not found in current directory.
    echo Expected: %CURRENT_DIR%\script.bat
    echo.
    pause
    exit /b 1
)

REM Step 4: Create registry keys for context menu
echo [3/4] Creating registry entries...

REM Base registry path for directory background context menu
set "BASE_REG_PATH=HKEY_CLASSES_ROOT\Directory\Background\shell"

REM Split the relative path to create nested menu structure
set "CURRENT_REG_PATH=%BASE_REG_PATH%\Scripts"

REM Create the Scripts base key first (no default value)
reg add "%CURRENT_REG_PATH%" /f >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to create base Scripts registry key
    pause
    exit /b 1
)

REM Add SubCommands to Scripts base key to make it a submenu
reg add "%CURRENT_REG_PATH%" /v "SubCommands" /t REG_SZ /d "" /f >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to add SubCommands value to Scripts
    pause
    exit /b 1
)

REM Parse the relative path and create nested keys - handle spaces in folder names
set "TEMP_PATH=%RELATIVE_PATH%"
set /a PART_COUNT=0

REM Split on backslashes, not spaces, to preserve folder names with spaces
:parse_loop
for /f "tokens=1* delims=\" %%a in ("!TEMP_PATH!") do (
    set /a PART_COUNT+=1
    set "PART_!PART_COUNT!=%%a"
    set "TEMP_PATH=%%b"
)
if defined TEMP_PATH goto parse_loop

REM Create nested menu structure
for /L %%i in (1,1,%PART_COUNT%) do (
    set "CURRENT_PART=!PART_%%i!"
    
    if %%i lss %PART_COUNT% (
        REM This is a submenu - add SubCommands and shell key
        set "CURRENT_REG_PATH=!CURRENT_REG_PATH!\shell\!CURRENT_PART!"
        
        REM Create the submenu key (no default value)
        reg add "!CURRENT_REG_PATH!" /f >nul 2>&1
        if %errorlevel% neq 0 (
            echo ERROR: Failed to create registry key for !CURRENT_PART!
            pause
            exit /b 1
        )
        
        REM Add SubCommands value (empty) to make it a submenu
        reg add "!CURRENT_REG_PATH!" /v "SubCommands" /t REG_SZ /d "" /f >nul 2>&1
        if %errorlevel% neq 0 (
            echo ERROR: Failed to add SubCommands value for !CURRENT_PART!
            pause
            exit /b 1
        )
        
        echo Created submenu: !CURRENT_PART!
    ) else (
        REM This is the final command - create shell and command keys
        set "CURRENT_REG_PATH=!CURRENT_REG_PATH!\shell\!CURRENT_PART!"
        
        REM Create the command key (no default value)
        reg add "!CURRENT_REG_PATH!" /f >nul 2>&1
        if %errorlevel% neq 0 (
            echo ERROR: Failed to create registry key for !CURRENT_PART!
            pause
            exit /b 1
        )
        
        REM Create the Command subkey and set the command (this is where we set the default value)
        set "COMMAND_REG_PATH=!CURRENT_REG_PATH!\command"
        reg add "!COMMAND_REG_PATH!" /ve /d "\"%CURRENT_DIR%\script.bat\" \"%%V\"" /f >nul 2>&1
        if %errorlevel% neq 0 (
            echo ERROR: Failed to create command registry key
            pause
            exit /b 1
        )
        
        echo Created command: !CURRENT_PART!
        echo Command path: "%CURRENT_DIR%\script.bat" "%%V"
    )
)

echo.
echo [4/4] Installation complete!
echo.
echo ====================================================================
echo SUCCESS: Context menu item has been installed!
echo ====================================================================
echo.
echo Menu location: Scripts\%RELATIVE_PATH:\=\%
echo Command name: %CONTEXT_NAME%
echo Script location: %CURRENT_DIR%\script.bat
echo.
echo You can now right-click in any folder and find your script under:
echo Right-click in folder background → Scripts → %RELATIVE_PATH:\= → %
echo.
echo To uninstall, run uninstall.bat from this same directory.
echo.
pause
