@ECHO OFF
IF NOT "%1"=="" (
    SET machine=%1
    SHIFT
) ELSE (
    GOTO :help
)

SET identity_file=%userprofile%\.ssh\id_rsa.pub
:loop
IF NOT "%1"=="" (
    IF "%1"=="-i" (
        SET i_file=%2
        SHIFT
    )
    SHIFT
    GOTO :loop
)

SET linux_cmd="umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys"
TYPE %identity_file% | ssh %machine% %linux_cmd%
GOTO :theend

:help
ECHO target machine not specified, exiting
ECHO.
ECHO Command format: ssh-copy-id [user@]machine [-i [identity_file]]

:theend
