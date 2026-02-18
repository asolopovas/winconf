@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET "SSH_DIR=%USERPROFILE%\.ssh"
SET "WINSCP="

FOR %%P IN (
    "%ProgramFiles%\WinSCP\WinSCP.com"
    "%ProgramFiles(x86)%\WinSCP\WinSCP.com"
    "%LOCALAPPDATA%\Programs\WinSCP\WinSCP.com"
    "%LOCALAPPDATA%\Microsoft\WinGet\Links\WinSCP.com"
) DO (
    IF EXIST %%P SET "WINSCP=%%~P"
)

IF "%WINSCP%"=="" (
    WHERE WinSCP.com >nul 2>nul
    IF !ERRORLEVEL! EQU 0 (
        FOR /F "tokens=*" %%G IN ('where WinSCP.com') DO SET "WINSCP=%%G"
    )
)

IF "%WINSCP%"=="" (
    ECHO WinSCP not found. Installing via winget...
    winget install --id WinSCP.WinSCP --accept-source-agreements --accept-package-agreements
    IF !ERRORLEVEL! NEQ 0 (
        ECHO Failed to install WinSCP. Please install manually.
        EXIT /B 1
    )
    SET "WINSCP=%ProgramFiles%\WinSCP\WinSCP.com"
    IF NOT EXIST "!WINSCP!" (
        SET "WINSCP=%ProgramFiles(x86)%\WinSCP\WinSCP.com"
        IF NOT EXIST "!WINSCP!" (
            ECHO WinSCP.com not found after installation.
            EXIT /B 1
        )
    )
)

ECHO Using WinSCP: %WINSCP%
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
            "!WINSCP!" /keygen "%%F" /output="!PPK_FILE!"
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
