<#
    restore-zcode-ui.ps1 — вернуть русский интерфейс и полосу счётчиков
    после обновления ZCode. Собирает объединённый app.asar (русификатор +
    счётчики) и ставит его.

    Использование:
      powershell -NoProfile -ExecutionPolicy Bypass -File tools\restore-zcode-ui.ps1
      ... -BuildOnly   — только собрать архив, ничего не устанавливать
      ... -Force       — пересобрать, даже если патчи уже стоят
      ... -Auto        — тихий режим для планировщика (нужны права администратора)
      ... -Log <path>  — свой файл лога
#>
param(
    [switch]$Quiet,
    [switch]$BuildOnly,
    [switch]$Force,
    [switch]$Auto,
    [string]$Log = $null
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$root = Split-Path $PSScriptRoot -Parent
$logPath = if ($Log) { $Log } else { Join-Path $env:LOCALAPPDATA 'ZCodeUiRestore\zcode-ui-restore.log' }

function Log([string]$m) {
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null
        Add-Content -LiteralPath $logPath -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $m) -Encoding UTF8
    } catch { }
}
function Say([string]$m) {
    if ($Auto) { Log $m } else { Write-Host $m -ForegroundColor Cyan; Log $m }
}
trap {
    $e = $_.Exception.Message
    Log ('ОШИБКА: ' + $e)
    if (-not $Auto) { Write-Host ('ОШИБКА: ' + $e) -ForegroundColor Red }
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if ($Auto -and -not $isAdmin) {
    throw 'Auto-режим требует прав администратора — запускай через задачу ZCodeUiRestore.'
}

$repo = Join-Path $root 'z-code-repo\z-code-main'
if (-not (Test-Path (Join-Path $repo 'plugins\zcode-ru\assets\patch.js'))) {
    # раскладка репозитория: tools\ лежит рядом с plugins\
    $repo = $root
}
$node = $null
$cmd = Get-Command node.exe -ErrorAction SilentlyContinue
if ($cmd) { $node = $cmd.Source }
elseif (Test-Path 'C:\Program Files\nodejs\node.exe') { $node = 'C:\Program Files\nodejs\node.exe' }
if (-not $node) { throw 'Не найден node.exe (нужен Node.js в PATH).' }

$check = Join-Path $root 'ctxdb\tools\asar-check.cjs'
if (-not (Test-Path $check)) { $check = Join-Path $PSScriptRoot 'asar-check.cjs' }
$audit = Join-Path $root 'ctxdb\tools\audit-asar.cjs'
if (-not (Test-Path $audit)) { $audit = Join-Path $PSScriptRoot 'audit-asar.cjs' }
$ruPatch = Join-Path $repo 'plugins\zcode-ru\assets\patch.js'
$countersPatch = Join-Path $repo 'plugins\zcode-counters\assets\patch.cjs'
foreach ($f in @($check, $audit, $ruPatch, $countersPatch)) {
    if (-not (Test-Path $f)) { throw "Не хватает файла: $f" }
}

$candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
$install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
if (-not $install) { throw 'Не найден установленный ZCode.' }
$asar = Join-Path $install 'resources\app.asar'

$state = & $node $check $asar | ConvertFrom-Json
if ($state.ru -and $state.counters -and -not $Force) {
    if (-not $Auto) {
        Write-Host ("ZCode {0} · русификатор и счётчики уже на месте (для пересборки: -Force)." -f $state.version) -ForegroundColor Yellow
    }
    exit 0
}

# обновлятор ZCode мог ещё дописывать архив — ждём, пока размер и mtime
# не меняются ~2 секунды (не дольше 3 минут), и перечитываем состояние
$deadline = (Get-Date).AddMinutes(3)
$sigPrev = ''
while ((Get-Date) -lt $deadline) {
    $fi = Get-Item -LiteralPath $asar
    $sig = "$($fi.Length)|$($fi.LastWriteTimeUtc.Ticks)"
    if ($sigPrev -eq $sig) { break }
    $sigPrev = $sig
    Start-Sleep -Seconds 2
}
$state = & $node $check $asar | ConvertFrom-Json
if ($state.ru -and $state.counters -and -not $Force) {
    if (-not $Auto) { Write-Host 'Патчи уже на месте — ничего не делаю.' -ForegroundColor Yellow }
    exit 0
}

Say ("Обнаружено: ZCode {0}, asar {1:N0} байт, русификатор {2}, счётчики {3} — восстанавливаю." -f `
    $state.version, (Get-Item $asar).Length, $state.ru, $state.counters)

$profileRu = Join-Path $env:LOCALAPPDATA 'ZCodeRu'
$profileCnt = Join-Path $env:LOCALAPPDATA 'ZCodeCounters'
New-Item -ItemType Directory -Force -Path $profileRu, $profileCnt | Out-Null

$env:ELECTRON_RUN_AS_NODE = '1'
$env:ELECTRON_NO_ASAR = '1'
$exe = Join-Path $install 'ZCode.exe'

# 1) русификатор
$ruOut = Join-Path $profileRu 'app.asar.new'
Remove-Item $ruOut -Force -ErrorAction SilentlyContinue
Say 'Сборка русификатора...'
$argLine = '"{0}" "{1}" "{2}"' -f $ruPatch, $install, $ruOut
$p = Start-Process -FilePath $exe -ArgumentList $argLine -Wait -PassThru -NoNewWindow
if (-not (Test-Path $ruOut) -or (Get-Item $ruOut).Length -lt 100MB) {
    throw 'Русификатор не собрался (нет app.asar.new или он слишком мал).'
}
Say ("Русификатор: {0:N0} байт" -f (Get-Item $ruOut).Length)

# 2) счётчики поверх русифицированного архива
$stageRoot = Join-Path $profileCnt 'stage'
$stageRes = Join-Path $stageRoot 'resources'
New-Item -ItemType Directory -Force -Path $stageRes | Out-Null
Copy-Item -LiteralPath $ruOut -Destination (Join-Path $stageRes 'app.asar') -Force

$final = Join-Path $profileCnt 'app.asar.final'
Remove-Item $final -Force -ErrorAction SilentlyContinue
Say 'Сборка счётчиков поверх русификатора...'
$argLine = '"{0}" "{1}" "{2}"' -f $countersPatch, $stageRoot, $final
$p = Start-Process -FilePath $exe -ArgumentList $argLine -Wait -PassThru -NoNewWindow
if (-not (Test-Path $final) -or (Get-Item $final).Length -lt 100MB) {
    throw 'Счётчики не собрались (нет app.asar.final или он слишком мал).'
}
Say ("Итоговый архив: {0:N0} байт" -f (Get-Item $final).Length)

# 3) аудит целостности: SHA-256 каждого файла против заголовка
Say 'Аудит целостности архива...'
& $node $audit $final
if ($LASTEXITCODE -ne 0) { throw 'Аудит целостности не прошёл — архив не ставим.' }

# 4) бэкап оригинала: install.ps1 сохраняет его только один раз
$backup = Join-Path $profileCnt 'app.asar.backup'
if (-not $state.counters -and (Test-Path $backup)) {
    if ((Get-FileHash $backup).Hash -ne (Get-FileHash $asar).Hash) {
        $old = "$backup.pre-" + (Get-Date -Format 'yyyyMMdd-HHmm')
        Move-Item -LiteralPath $backup -Destination $old -Force
        Say "Старый бэкап сохранён как $old"
    }
}

if ($BuildOnly) {
    Say "Готово (без установки): $final"
    exit 0
}

# 5) установка (в Auto-режиме уже под администратором — без UAC)
Say 'Установка в ZCode...'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'plugins\zcode-counters\assets\install.ps1') -Payload $final -Quiet

$now = & $node $check $asar | ConvertFrom-Json
if ($now.ru -and $now.counters) {
    Say ("OK: русификатор и счётчики установлены (ZCode {0}). Нужен рестарт ZCode." -f $now.version)
    if ($Auto) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing
            $ni = New-Object System.Windows.Forms.NotifyIcon
            $ni.Icon = [System.Drawing.SystemIcons]::Information
            $ni.Visible = $true
            $ni.ShowBalloonTip(10000, 'ZCode',
                'Русификатор и счётчики восстановлены. Перезапусти ZCode, чтобы увидеть русский интерфейс.',
                [System.Windows.Forms.ToolTipIcon]::Info)
            Start-Sleep -Seconds 8
            $ni.Visible = $false
            $ni.Dispose()
        } catch { }
    }
} else {
    throw 'После установки патчи не обнаружены — проверь install.log.'
}
