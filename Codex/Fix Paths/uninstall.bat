@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM Context Menu Uninstaller for Python Scripts
REM Removes the script context menu entry that was added by install.bat
REM =============================================================================

echo.
echo ====================================================================
echo Context Menu Script Uninstaller
echo ====================================================================
echo.

REM Step 1: Check if running as administrator
echo [1/3] Checking administrator privileges...
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
echo [2/3] Analyzing directory structure...
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
    echo No context menu structure to remove.
    echo.
    pause
    exit /b 1
)

echo Found ContextScripts subdirectory: %RELATIVE_PATH%
echo Will remove context menu: %CONTEXT_NAME%
echo.

REM Step 3: Remove registry keys
echo [3/3] Removing registry entries...

REM Base registry path for directory background context menu
set "BASE_REG_PATH=HKEY_CLASSES_ROOT\Directory\Background\shell"

REM Build the full path to the command that needs to be removed
set "CURRENT_REG_PATH=%BASE_REG_PATH%\Scripts"

REM Parse the relative path to build the full registry path - handle spaces in folder names
set "TEMP_PATH=%RELATIVE_PATH%"

REM Split on backslashes, not spaces, to preserve folder names with spaces
:parse_loop_uninstall
for /f "tokens=1* delims=\" %%a in ("!TEMP_PATH!") do (
    set "CURRENT_REG_PATH=!CURRENT_REG_PATH!\shell\%%a"
    set "TEMP_PATH=%%b"
)
if defined TEMP_PATH goto parse_loop_uninstall

REM First, try to remove the specific command entry
echo Removing command: %CONTEXT_NAME%
reg delete "%CURRENT_REG_PATH%" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo SUCCESS: Removed command registry key
) else (
    echo WARNING: Command registry key may not exist or was already removed
)

REM Now work backwards to remove empty parent keys
set "CLEANUP_PATH=%CURRENT_REG_PATH%"

REM Parse the relative path parts for cleanup - handle spaces in folder names
set "TEMP_PATH_CLEANUP=%RELATIVE_PATH%"
set /a PART_COUNT=0

REM Split on backslashes to get individual folder names
:parse_cleanup_loop
for /f "tokens=1* delims=\" %%a in ("!TEMP_PATH_CLEANUP!") do (
    set /a PART_COUNT+=1
    set "PART_!PART_COUNT!=%%a"
    set "TEMP_PATH_CLEANUP=%%b"
)
if defined TEMP_PATH_CLEANUP goto parse_cleanup_loop

REM Now recursively remove empty parent directories from most specific to least specific
echo Checking for empty parent directories to clean up...

REM Start from the parent directories of the removed command and work backwards
REM Skip the last part (the command itself) and check from parent directories
set /a PARENT_COUNT=%PART_COUNT%-1
for /L %%i in (%PARENT_COUNT%,-1,1) do (
    REM Build the path to check
    set "CHECK_PATH=%BASE_REG_PATH%\Scripts"
    for /L %%j in (1,1,%%i) do (
        set "CHECK_PATH=!CHECK_PATH!\shell\!PART_%%j!"
    )
    
    REM Check if this directory's shell key has any subkeys (actual submenus)
    reg query "!CHECK_PATH!\shell" >nul 2>&1
    if %errorlevel% neq 0 (
        REM No shell subkey found at all, this directory is empty
        echo Removing empty directory: !PART_%%i!
        reg delete "!CHECK_PATH!" /f >nul 2>&1
        if %errorlevel% equ 0 (
            echo Successfully removed: !PART_%%i!
        ) else (
            echo Warning: Could not remove !PART_%%i! - may not be empty
        )
    ) else (
        REM Shell key exists, now check if it has any subkeys
        for /f %%k in ('reg query "!CHECK_PATH!\shell" 2^>nul ^| find /c "HKEY"') do set "SUBKEY_COUNT=%%k"
        if !SUBKEY_COUNT! equ 0 (
            REM Shell exists but is empty, safe to remove parent
            echo Removing directory with empty shell: !PART_%%i!
            reg delete "!CHECK_PATH!" /f >nul 2>&1
            if %errorlevel% equ 0 (
                echo Successfully removed: !PART_%%i!
            ) else (
                echo Warning: Could not remove !PART_%%i! - may not be empty
            )
        ) else (
            REM Shell has subkeys, meaning it has active submenus, so stop here
            echo Directory !PART_%%i! still has !SUBKEY_COUNT! submenus, stopping cleanup
            goto cleanup_complete
        )
    )
)

REM Finally, check if Scripts itself is empty and remove if so
echo Checking if Scripts directory is empty...
reg query "%BASE_REG_PATH%\Scripts\shell" >nul 2>&1
if %errorlevel% neq 0 (
    REM No shell subkey found in Scripts at all
    echo Removing Scripts directory (no shell key)
    reg delete "%BASE_REG_PATH%\Scripts" /f >nul 2>&1
    if %errorlevel% equ 0 (
        echo Successfully removed empty Scripts menu
    ) else (
        echo Warning: Could not remove Scripts directory
    )
) else (
    REM Shell key exists in Scripts, check if it has subkeys
    for /f %%k in ('reg query "%BASE_REG_PATH%\Scripts\shell" 2^>nul ^| find /c "HKEY"') do set "SCRIPTS_SUBKEY_COUNT=%%k"
    if !SCRIPTS_SUBKEY_COUNT! equ 0 (
        REM Scripts shell exists but is empty
        echo Removing Scripts directory (empty shell)
        reg delete "%BASE_REG_PATH%\Scripts" /f >nul 2>&1
        if %errorlevel% equ 0 (
            echo Successfully removed empty Scripts menu
        ) else (
            echo Warning: Could not remove Scripts directory
        )
    ) else (
        echo Scripts directory still has !SCRIPTS_SUBKEY_COUNT! submenus, keeping it
    )
)

:cleanup_complete

echo.
echo ====================================================================
echo SUCCESS: Context menu item has been removed!
echo ====================================================================
echo.
echo The following menu path has been removed:
echo Scripts\%RELATIVE_PATH:\=\%
echo.
echo The context menu entry "%CONTEXT_NAME%" will no longer appear
echo when you right-click in folder backgrounds.
echo.
echo To reinstall, run install.bat from this same directory.
echo.
pause
