[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\Bodycam',
    # Install even if Bodycam has updated since this package was tested.
    [switch]$Force
)
$ErrorActionPreference='Stop'
$bin=[IO.Path]::GetFullPath((Join-Path $GameRoot 'Bodycam/Binaries/Win64'))
$exe=Join-Path $bin 'Bodycam-Win64-Shipping.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw 'GameRoot must be the Steam Bodycam installation folder.' }
if (Get-Process -Name 'Bodycam-Win64-Shipping' -ErrorAction SilentlyContinue) { throw 'Close Bodycam first.' }
if ((Get-FileHash -LiteralPath $exe).Hash -ne '2792EA9A5E062BFC69883F496E9517D2F1308CA573DADE7F8DB108F722DB127C') {
    if (-not $Force) { throw 'Bodycam has been updated since this package was tested. Re-run with -Force to install anyway (UE4SS may need updating if the game fails to start).' }
    Write-Warning 'Different Bodycam build; installing anyway because -Force was given.'
}
$payload=Join-Path $PSScriptRoot 'payload'
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest) {
    $source=[IO.Path]::GetFullPath((Join-Path $payload $entry.path))
    if (-not $source.StartsWith([IO.Path]::GetFullPath($payload)+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package path.' }
    if ((Get-FileHash -LiteralPath $source).Hash -ne $entry.sha256) { throw "Package hash mismatch: $($entry.path)" }
    $target=Join-Path $bin $entry.path
    if ($entry.path -match '\.dll$' -and (Test-Path -LiteralPath $target) -and (Get-FileHash -LiteralPath $target).Hash -ne $entry.sha256) { throw "Conflicting loader: $target. Resolve manually before installation." }
}
if (-not $PSCmdlet.ShouldProcess($bin,'Install Bodycam Outbreak host prototype with backups')) { return }
$backup=Join-Path $bin ('OutbreakBackups/'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$receipt=@()
foreach ($entry in $manifest) {
    $target=Join-Path $bin $entry.path
    $existed=Test-Path -LiteralPath $target
    if ($existed) {
        $saved=Join-Path $backup $entry.path
        New-Item -ItemType Directory -Path (Split-Path $saved) -Force | Out-Null
        Copy-Item -LiteralPath $target -Destination $saved
    }
    New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $payload $entry.path) -Destination $target -Force
    if ((Get-FileHash -LiteralPath $target).Hash -ne $entry.sha256) { throw "Installed hash mismatch: $target. Backup: $backup" }
    $receipt+=@{path=$entry.path;existed=$existed;sha256=$entry.sha256}
    $receipt | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'receipt.json')
}
$mods=Join-Path $bin 'ue4ss/Mods/mods.txt'
if (Test-Path -LiteralPath $mods) { Copy-Item -LiteralPath $mods -Destination (Join-Path $backup 'mods.txt'); $lines=@(Get-Content -LiteralPath $mods) } else { $lines=@() }
$lines=@($lines | Where-Object { $_ -notmatch '^\s*BodycamOutbreak\s*:' })
@($lines+'BodycamOutbreak : 1') | Set-Content -LiteralPath $mods
Write-Output "Installed. Backup: $backup. Start Bodycam, host a match, then press F6 (settings) or F7 (zombie waves)."
