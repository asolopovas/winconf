@echo off
codex --dangerously-bypass-approvals-and-sandbox %*
exit /b %ERRORLEVEL%
