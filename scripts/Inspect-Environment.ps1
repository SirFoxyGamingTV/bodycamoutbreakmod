[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$profile = Get-Content -LiteralPath (Join-Path $root 'config/compatibility.json') -Raw | ConvertFrom-Json
$manifestPath = Join-Path $profile.steamRoot "steamapps/appmanifest_$($profile.appId).acf"
$manifest = Get-Content -LiteralPath $manifestPath -Raw
function Read-ManifestField([string]$Name) {
    $match = [regex]::Match($manifest, '"' + [regex]::Escape($Name) + '"\s+"([^"]+)"')
    if (-not $match.Success) { throw "Missing Steam manifest field: $Name" }
    $match.Groups[1].Value
}
$installDir = Read-ManifestField 'installdir'
if ($installDir -ne $profile.installDirectory) { throw 'Install directory changed; inspect before continuing.' }
if ((Read-ManifestField 'appid') -ne $profile.appId) { throw 'Wrong Steam application.' }
$gameRoot = Join-Path $profile.steamRoot "steamapps/common/$installDir"
$exe = Join-Path $gameRoot $profile.executableRelativePath
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
$build = Read-ManifestField 'buildid'
$bin = Split-Path $exe -Parent
$commands = @{}
foreach ($name in @('git','lua','luajit','cmake','ninja','cl','dotnet')) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    $commands[$name] = if ($command) { $command.Source } else { $null }
}
$report = [ordered]@{
    timestampUtc = [DateTime]::UtcNow.ToString('o')
    gameRoot = $gameRoot
    executable = $exe
    buildId = $build
    executableSha256 = $hash
    fingerprintMatches = ($build -eq $profile.buildId -and $hash -eq $profile.executableSha256)
    productVersion = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    ue4ssDllPresent = ((Test-Path -LiteralPath (Join-Path $bin 'UE4SS.dll')) -or (Test-Path -LiteralPath (Join-Path $bin 'ue4ss/UE4SS.dll')))
    reshadePresent = (Test-Path -LiteralPath (Join-Path $bin 'ReShade.ini'))
    commandsOnPath = $commands
    os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    logicalProcessors = [Environment]::ProcessorCount
    gameLaunched = $false
    compatibilityVerified = $false
}
$output = Join-Path $root 'artifacts/reports'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'environment.json')
$report | ConvertTo-Json -Depth 5
if (-not $report.fingerprintMatches) { throw 'Game build changed. Integration must be revalidated.' }
