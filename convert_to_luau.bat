@echo off
setlocal enabledelayedexpansion

REM Simple batch script to convert .lua files to .luau with --!strict

echo Converting .lua files to .luau with --!strict...

set "srcDir=src"
set "converted=0"
set "skipped=0"

if not exist "%srcDir%" (
    echo Error: %srcDir% directory not found
    exit /b 1
)

echo Searching for .lua files in %srcDir%...

for /r "%srcDir%" %%f in (*.lua) do (
    set "luauFile=%%~dpnf.luau"
    
    if exist "!luauFile!" (
        echo Skipping (already exists): %%~nxf.luau
        set /a skipped+=1
    ) else (
        echo Converting: %%~nxf
        
        REM Add --!strict to the beginning of the file
        (
            echo --!strict
            echo.
            type "%%f"
        ) > "!luauFile!"
        
        set /a converted+=1
    )
)

echo.
echo Conversion complete!
echo - Converted: %converted% files
echo - Skipped: %skipped% files (already converted)
echo.
echo Next steps:
echo 1. Review the converted files for any type errors
echo 2. Run your test suite to ensure everything works as expected
echo 3. Consider using a Luau type checker for more comprehensive validation

pause
