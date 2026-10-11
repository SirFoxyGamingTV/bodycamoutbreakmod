[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'Test-Workspace.ps1')
$stage=Join-Path $root ('artifacts/host-package/'+[guid]::NewGuid().ToString('N'))
$payload=Join-Path $stage 'payload'
$loader=Join-Path $root 'artifacts/loader-review/5e627997'
New-Item -ItemType Directory -Path (Join-Path $payload 'ue4ss/Mods') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $loader 'dwmapi.dll') -Destination $payload
foreach ($name in @('UE4SS.dll','LICENSE')) { Copy-Item -LiteralPath (Join-Path $loader "ue4ss/$name") -Destination (Join-Path $payload 'ue4ss') }
$profile=Get-Content -LiteralPath (Join-Path $root 'config/compatibility.json') -Raw | ConvertFrom-Json
$bin=Split-Path (Join-Path $profile.steamRoot "steamapps/common/$($profile.installDirectory)/$($profile.executableRelativePath)")
Copy-Item -LiteralPath (Join-Path $bin 'ue4ss/UE4SS-settings.ini') -Destination (Join-Path $payload 'ue4ss')
Copy-Item -LiteralPath (Join-Path $root 'mod/BodycamOutbreak') -Destination (Join-Path $payload 'ue4ss/Mods') -Recurse
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Install-Host.ps1') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'docs/HOST-PACKAGE.md') -Destination (Join-Path $stage 'README.md')
$manifest=@(Get-ChildItem -LiteralPath $payload -File -Recurse | ForEach-Object { @{path=[IO.Path]::GetRelativePath($payload,$_.FullName);sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} })
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stage 'manifest.json')
$zip=Join-Path $root 'artifacts/BodycamOutbreak-Host.zip'
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
Write-Output $zip
