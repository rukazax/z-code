<#
    zcode-counters: полный цикл — собрать патченный app.asar из установленного ZCode
    (index.html получает полосу счётчиков) и поставить его. Сборка от текущего
    пользователя, установка запросит UAC.

    Использование:
      powershell -NoProfile -ExecutionPolicy Bypass -File apply.ps1 [-Quiet]
#>
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

$assets = $PSScriptRoot
$patch  = Join-Path $assets 'patch.cjs'
$profileDir = Join-Path $env:LOCALAPPDATA 'ZCodeCounters'
$out    = Join-Path $profileDir 'app.asar.patched'

if (-not (Test-Path $patch)) { throw "Не хватает файла плагина: $patch" }

$candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
$install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
if (-not $install) { throw 'Не найден установленный ZCode.' }

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

Write-Host "Сборка полосы счётчиков из $install ..." -ForegroundColor Cyan
$env:ELECTRON_RUN_AS_NODE = '1'
$env:ELECTRON_NO_ASAR = '1'
& (Join-Path $install 'ZCode.exe') $patch $install $out
if ($LASTEXITCODE -eq 2) { Write-Host 'Полоса уже установлена.' -ForegroundColor Yellow; exit 0 }
if (-not (Test-Path $out)) { throw 'Патченный архив не создан.' }

$size = (Get-Item -LiteralPath $out).Length
Write-Host ("Собрано: {0:N0} байт" -f $size) -ForegroundColor Green
if ($size -lt 100MB) { throw 'Размер архива подозрительно мал — сборка не удалась.' }

Write-Host 'Установка...' -ForegroundColor Cyan
$installArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                 (Join-Path $assets 'install.ps1'), '-Payload', $out)
if ($Quiet) { $installArgs += '-Quiet' }
& powershell @installArgs
exit $LASTEXITCODE
