@echo off
REM Batch file to run the python script in the current directory

echo Running python script...
echo Current directory: %CD%

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python and try again
    pause
    exit /b 1
)

REM Check if requirements.txt exists and install dependencies
if exist "%SCRIPT_DIR%requirements.txt" (
    echo Installing dependencies from requirements.txt...
    pip install -r "%SCRIPT_DIR%requirements.txt"
    if errorlevel 1 (
        echo Failed to install dependencies from requirements.txt
        echo Please check the requirements.txt file and try again
        pause
        exit /b 1
    )
) else (
    echo Warning: requirements.txt not found in script directory
    echo Attempting to run script anyway...
)

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Run the Python script from the script directory, but it will process files in current directory
python "%SCRIPT_DIR%script.py"

if errorlevel 1 (
    echo Script execution failed
    pause
    exit /b 1
)

echo.
echo Python script completed successfully!
pause
