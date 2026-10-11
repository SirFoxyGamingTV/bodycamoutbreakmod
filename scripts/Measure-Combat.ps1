[CmdletBinding()]
param([string]$Path = (Join-Path $PSScriptRoot '../artifacts/reports/combat-telemetry-first.txt'))
$ErrorActionPreference = 'Stop'
$records = [Collections.Generic.List[object]]::new()
$time = $null
$actor = $null
foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^TIME (.+)$') { $time = $Matches[1]; $actor = $null }
    elseif ($line -match '^(PLAYER|ZOMBIE) (.+)$') {
        $actor = [ordered]@{time=$time;kind=$Matches[1];name=$Matches[2];x=$null;y=$null;z=$null;health=$null;dead=$null}
        $records.Add($actor)
    }
    elseif ($null -ne $actor -and $line -match '^  POSITION ([\d.-]+) ([\d.-]+) ([\d.-]+)$') {
        $actor.x=[double]::Parse($Matches[1],[cultureinfo]::InvariantCulture)
        $actor.y=[double]::Parse($Matches[2],[cultureinfo]::InvariantCulture)
        $actor.z=[double]::Parse($Matches[3],[cultureinfo]::InvariantCulture)
    }
    elseif ($null -ne $actor -and $line -match '^  HEALTH ([\d.-]+)$') {
        $actor.health=[double]::Parse($Matches[1],[cultureinfo]::InvariantCulture)
    }
    elseif ($null -ne $actor -and $line -match '^  DEAD (true|false)$') { $actor.dead=$Matches[1] -eq 'true' }
}
if (-not $records.Count) { throw 'No combat records found.' }
$zombies=@($records | Where-Object { $_.kind -eq 'ZOMBIE' })
$players=@($records | Where-Object { $_.kind -eq 'PLAYER' })
$report=[ordered]@{
    source=[IO.Path]::GetFullPath($Path)
    samples=$records.Count
    zombieActors=@($zombies | ForEach-Object { $_.name } | Select-Object -Unique)
    observedLivingZombie=@($zombies | Where-Object { $_.health -gt 0 -and $_.dead -eq $false }).Count -gt 0
    observedZombieDeath=@($zombies | Where-Object { $_.dead -eq $true }).Count -gt 0
    minimumPlayerHealth=($players | ForEach-Object { $_.health } | Measure-Object -Minimum).Minimum
    meleeDamageAttribution='unverified: health samples alone do not identify damage source'
}
$output=Join-Path $PSScriptRoot '../artifacts/reports/combat-summary.json'
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $output
$report | ConvertTo-Json -Depth 5
