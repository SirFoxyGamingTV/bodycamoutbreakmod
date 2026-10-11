[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'Test-Workspace.ps1')
# A fresh directory avoids accidentally packaging stale or enabled files.
$stage = Join-Path $root ('artifacts/staging/' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'mod/BodycamOutbreak') -Destination $stage -Recurse
'BodycamOutbreak : 0' | Set-Content -LiteralPath (Join-Path $stage 'mods.txt.example')
$files = @(Get-ChildItem -LiteralPath $stage -File -Recurse | ForEach-Object {
    [ordered]@{path=[IO.Path]::GetRelativePath($stage, $_.FullName); sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
ConvertTo-Json -InputObject $files -Depth 4 | Set-Content -LiteralPath (Join-Path $stage 'manifest.json')
Write-Output "Disabled diagnostic staging only: $stage"
