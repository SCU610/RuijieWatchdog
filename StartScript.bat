cd /d %~dp0
powershell -ExecutionPolicy ByPass -File ".\Script\RuijieWatchdog.ps1" -AdapterAliasName "��̫��" -RuijiePath "D:\Program Files\�������\Ruijie Supplicant\8021x.exe" -RuijieProcessName "8021x" -CheckInterval 1
pause