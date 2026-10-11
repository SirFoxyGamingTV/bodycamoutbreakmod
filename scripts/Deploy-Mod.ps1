[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (Get-Process -Name 'Bodycam-Win64-Shipping' -ErrorAction SilentlyContinue) { throw 'Close Bodycam before deployment.' }
& (Join-Path $PSScriptRoot 'Inspect-Environment.ps1') | Out-Null
$profile = Get-Content -LiteralPath (Join-Path $root 'config/compatibility.json') -Raw | ConvertFrom-Json
$bin = Split-Path (Join-Path $profile.steamRoot "steamapps/common/$($profile.installDirectory)/$($profile.executableRelativePath)") -Parent
$destination = [IO.Path]::GetFullPath((Join-Path $bin 'ue4ss/Mods/BodycamOutbreak'))
$source = Join-Path $root 'mod/BodycamOutbreak'
$files = @(Get-ChildItem -LiteralPath $source -File -Recurse)
$backup = Join-Path $root ('artifacts/backups/mod-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
$receipt = @()
foreach ($file in $files) {
    $relative = [IO.Path]::GetRelativePath($source, $file.FullName)
    $target = [IO.Path]::GetFullPath((Join-Path $destination $relative))
    if (-not $target.StartsWith($destination + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe path' }
    $previous = $null
    if (Test-Path -LiteralPath $target) {
        $previous = (Get-FileHash -LiteralPath $target).Hash
        $backupFile = Join-Path $backup $relative
        New-Item -ItemType Directory -Path (Split-Path $backupFile -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $target -Destination $backupFile
    }
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    $hash = (Get-FileHash -LiteralPath $target).Hash
    if ($hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) { throw 'Copy verification failed' }
    $receipt += [ordered]@{path=$target;sha256=$hash;previousSha256=$previous}
}
# Remove installed scripts that were deleted from the repo (kept in the backup).
$removed = @()
$installedScripts = Join-Path $destination 'Scripts'
if (Test-Path -LiteralPath $installedScripts) {
    foreach ($stale in Get-ChildItem -LiteralPath $installedScripts -Filter '*.lua' -File) {
        if (-not (Test-Path -LiteralPath (Join-Path $source "Scripts/$($stale.Name)"))) {
            $backupFile = Join-Path $backup "Scripts/$($stale.Name)"
            New-Item -ItemType Directory -Path (Split-Path $backupFile -Parent) -Force | Out-Null
            Move-Item -LiteralPath $stale.FullName -Destination $backupFile
            $removed += $stale.Name
        }
    }
}
[ordered]@{timestampUtc=[DateTime]::UtcNow.ToString('o');backup=$backup;files=$receipt;removed=$removed} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'artifacts/reports/mod-deployment.json')
Write-Output "Deployed $($files.Count) mod files with backups and hashes; removed $($removed.Count) stale scripts."
