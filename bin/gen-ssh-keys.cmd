@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET "SSH_DIR=%USERPROFILE%\.ssh"
SET "PUTTYGEN="

FOR %%P IN (
    "%ProgramFiles%\PuTTY\puttygen.exe"
    "%ProgramFiles(x86)%\PuTTY\puttygen.exe"
    "%LOCALAPPDATA%\Microsoft\WinGet\Links\puttygen.exe"
) DO (
    IF EXIST %%P SET "PUTTYGEN=%%~P"
)

IF "%PUTTYGEN%"=="" (
    WHERE puttygen >nul 2>nul
    IF !ERRORLEVEL! EQU 0 (
        FOR /F "tokens=*" %%G IN ('where puttygen') DO SET "PUTTYGEN=%%G"
    )
)

IF "%PUTTYGEN%"=="" (
    ECHO PuTTY not found. Installing via winget...
    winget install --id PuTTY.PuTTY --accept-source-agreements --accept-package-agreements
    IF !ERRORLEVEL! NEQ 0 (
        ECHO Failed to install PuTTY. Please install manually.
        EXIT /B 1
    )
    SET "PUTTYGEN=%ProgramFiles%\PuTTY\puttygen.exe"
    IF NOT EXIST "!PUTTYGEN!" (
        ECHO puttygen.exe not found after installation.
        EXIT /B 1
    )
)

ECHO Using puttygen: %PUTTYGEN%
ECHO.

IF NOT EXIST "%SSH_DIR%" (
    ECHO SSH directory not found: %SSH_DIR%
    EXIT /B 1
)

SET COUNT=0

FOR %%F IN ("%SSH_DIR%\id_*") DO (
    SET "FILE=%%~nxF"
    SET "EXT=%%~xF"
    IF /I NOT "!EXT!"==".pub" IF /I NOT "!EXT!"==".ppk" (
        SET "PPK_FILE=%SSH_DIR%\%%~nF.ppk"
        IF EXIST "!PPK_FILE!" (
            ECHO [SKIP] %%~nxF -- !PPK_FILE! already exists
        ) ELSE (
            ECHO [CONVERT] %%~nxF -- generating %%~nF.ppk
            "%PUTTYGEN%" "%%F" -o "!PPK_FILE!"
            IF !ERRORLEVEL! EQU 0 (
                ECHO [OK] %%~nF.ppk created
            ) ELSE (
                ECHO [FAIL] Could not convert %%~nxF
            )
        )
        SET /A COUNT+=1
    )
)

IF %COUNT%==0 (
    ECHO No private keys found in %SSH_DIR%
    EXIT /B 1
)

ECHO.
ECHO Done. PPK files are in %SSH_DIR%
