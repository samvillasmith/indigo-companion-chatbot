@echo off
:: ============================================================
:: Indigo Companion Chatbot - Local Launcher
:: ============================================================
:: Starts SillyTavern and VMagicMirror with one click.
:: RunPod (Orpheus TTS) must be started separately from the
:: RunPod dashboard before launching this script.
:: ============================================================

echo ============================================
echo   Indigo Companion Chatbot - Starting...
echo ============================================
echo.

:: --- Configuration ---
:: Update these paths if you installed to different locations
set SILLYTAVERN_DIR=C:\AI\SillyTavern
set VMAGICMIRROR_EXE=C:\AI\VMagicMirror\VMagicMirror.exe

:: --- Preflight Checks ---
if not exist "%SILLYTAVERN_DIR%\start.bat" (
    echo [ERROR] SillyTavern not found at %SILLYTAVERN_DIR%
    echo         Update SILLYTAVERN_DIR in this script.
    pause
    exit /b 1
)

if not exist "%VMAGICMIRROR_EXE%" (
    echo [WARNING] VMagicMirror not found at %VMAGICMIRROR_EXE%
    echo           Avatar will not load. Update VMAGICMIRROR_EXE in this script.
    echo.
)

:: --- Start VMagicMirror ---
if exist "%VMAGICMIRROR_EXE%" (
    echo [1/2] Starting VMagicMirror...
    start "" "%VMAGICMIRROR_EXE%"
    echo       Done.
) else (
    echo [1/2] Skipping VMagicMirror (not found)
)

:: --- Start SillyTavern ---
echo [2/2] Starting SillyTavern...
cd /d "%SILLYTAVERN_DIR%"
start "" cmd /c start.bat
echo       Done.

:: --- Wait and open browser ---
echo.
echo Waiting for SillyTavern to start...
timeout /t 5 /nobreak >nul
start http://localhost:8000

echo.
echo ============================================
echo   Everything is running!
echo ============================================
echo.
echo   SillyTavern:   http://localhost:8000
echo   VMagicMirror:   Running
echo.
echo   REMINDER: Start your RunPod pod for voice!
echo   Then update the TTS endpoint URL in
echo   SillyTavern if the pod ID changed.
echo.
echo   Close this window when you're done.
echo ============================================
pause
