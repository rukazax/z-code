<#
    zcode-ru: полный цикл — собрать патченный app.asar из установленного ZCode
    и поставить его. Сборка идёт от текущего пользователя, установка запросит UAC.

    Использование:
      powershell -NoProfile -ExecutionPolicy Bypass -File apply.ps1 [-Quiet]
#>

param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

$assets     = $PSScriptRoot
$patch      = Join-Path $assets 'patch.js'
$translation = Join-Path $assets 'translations\ru-RU.json'
$profileDir = Join-Path $env:LOCALAPPDATA 'ZCodeRu'
$out        = Join-Path $profileDir 'app.asar.patched'

foreach ($f in @($patch, $translation)) {
    if (-not (Test-Path $f)) { throw "Не хватает файла плагина: $f" }
}

$candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
$install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
if (-not $install) { throw 'Не найден установленный ZCode.' }

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

Write-Host "Сборка перевода из $install ..." -ForegroundColor Cyan
$env:ELECTRON_RUN_AS_NODE = '1'
$env:ELECTRON_NO_ASAR = '1'
& (Join-Path $install 'ZCode.exe') $patch $install $out
if ($LASTEXITCODE -ne 0) { throw "patch.js завершился с кодом $LASTEXITCODE" }
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
