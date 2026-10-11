@echo off
title Bodycam Outbreak - Live Diagnostics
echo Bodycam Outbreak live log viewer
echo Shows the UE4SS log live (F6 panel, F7/F10 messages, F8 diagnostics). Close any time.
powershell.exe -NoLogo -NoProfile -Command "$log = 'C:\Program Files (x86)\Steam\steamapps\common\Bodycam\Bodycam\Binaries\Win64\ue4ss\UE4SS.log'; if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Tail 60 -Wait } else { Write-Host 'Log not found. Start Bodycam once, then reopen this viewer.' }"
pause
