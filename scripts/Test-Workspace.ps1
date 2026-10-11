[CmdletBinding()]
param()
# Static checks that need neither the game nor Lua: PowerShell syntax, config, mod layout.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$failures = @()
$checks = 0
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1') {
    $tokens = $null; $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    $checks++
    if ($parseErrors.Count) { $failures += "$($file.Name): $parseErrors" }
}
$profile = Get-Content -LiteralPath (Join-Path $root 'config/compatibility.json') -Raw | ConvertFrom-Json
$checks++
if ($profile.executableSha256 -notmatch '^[A-F0-9]{64}$') { $failures += 'Invalid executable fingerprint in config/compatibility.json.' }
$mod = Join-Path $root 'mod/BodycamOutbreak/Scripts'
$checks++
if (-not (Test-Path -LiteralPath (Join-Path $mod 'main.lua'))) { $failures += 'mod/BodycamOutbreak/Scripts/main.lua is missing.' }
$checks++
if (Test-Path -LiteralPath (Join-Path $root 'mod/BodycamOutbreak/enabled.txt')) { $failures += 'Do not ship enabled.txt; mods.txt enables the mod.' }
if ($failures.Count) { throw ($failures -join "`n") }
Write-Output "PASS: $checks static checks. Run scripts/Test-Lua.py for the Lua tests."
