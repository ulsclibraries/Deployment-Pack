@echo off
:: ============================================================
:: HideEdgeRestoreSession.bat
:: Suppresses the "Restore pages?" / session-restore dialog
:: that Edge shows after an unclean shutdown.
::
:: Registry policy path: HKLM\SOFTWARE\Policies\Microsoft\Edge
::   HideRestoreDialogEnabled = 1  -> hides the restore dialog
::   RestoreOnStartup          = 5  -> open New Tab on launch
::                                     (prevents session restore)
::
:: Must be run as Administrator.
:: ============================================================

:: Verify Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    exit /b 1
)

:: Create the Edge policy key if it does not already exist
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /f >nul 2>&1

:: Hide the "Restore pages?" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" ^
    /v HideRestoreDialogEnabled /t REG_DWORD /d 1 /f >nul 2>&1

:: Open New Tab page on startup instead of restoring the previous session
:: reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" ^
::     /v RestoreOnStartup /t REG_DWORD /d 5 /f >nul 2>&1
