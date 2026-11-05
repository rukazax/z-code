<#
    zcode-ru: установка готового патченного архива в каталог ZCode.
    Требует прав администратора (сам запросит UAC).

    Параметры:
      -Payload <путь>  патченный app.asar (обязательно)
      -Quiet           без паузы в конце (для автоматического запуска)
#>

param(
    [Parameter(Mandatory = $true)][string]$Payload,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$profileDir = Join-Path $env:LOCALAPPDATA 'ZCodeRu'
$backup     = Join-Path $profileDir 'app.asar.backup'
$log        = Join-Path $profileDir 'install.log'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Требуются права администратора. Запускаю через UAC...' -ForegroundColor Yellow
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
              '-Payload', "`"$Payload`"")
    if ($Quiet) { $args += '-Quiet' }
    Start-Process powershell -Verb RunAs -Wait -ArgumentList $args
    exit
}

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
Start-Transcript -Path $log -Force | Out-Null | Out-Null
trap {
    Write-Host ("ОШИБКА: " + $_.Exception.Message) -ForegroundColor Red
    Stop-Transcript | Out-Null
    if (-not $Quiet) { Read-Host 'Нажмите Enter для выхода' }
    exit 1
}

$candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
$install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
if (-not $install) { throw 'Не найден установленный ZCode (ни в Program Files, ни в LOCALAPPDATA).' }
$asar = Join-Path $install 'resources\app.asar'

function Read-Fully([IO.FileStream]$stream, [byte[]]$buffer, [int]$count) {
    $read = 0
    while ($read -lt $count) {
        $n = $stream.Read($buffer, $read, $count - $read)
        if ($n -le 0) { break }
        $read += $n
    }
    return $read
}

function Get-AsarVersion([string]$asarPath) {
    try {
        $fs = [IO.File]::OpenRead($asarPath)
        try {
            $head = New-Object byte[] 16
            if ((Read-Fully $fs $head 16) -ne 16) { return $null }
            $jsonLen = [BitConverter]::ToUInt32($head, 12)
            if ($jsonLen -le 0 -or $jsonLen -gt 64MB) { return $null }
            $jsonBytes = New-Object byte[] $jsonLen
            if ((Read-Fully $fs $jsonBytes $jsonLen) -ne $jsonLen) { return $null }
            $header = [Text.Encoding]::UTF8.GetString($jsonBytes) | ConvertFrom-Json
            $entry = $header.files.'package.json'
            if (-not $entry) { return $null }
            $dataStart = 16 + $jsonLen + ((4 - ($jsonLen % 4)) % 4)
            $fs.Position = $dataStart + [int64]$entry.offset
            $buf = New-Object byte[] $entry.size
            if ((Read-Fully $fs $buf $entry.size) -ne $entry.size) { return $null }
            $pkg = [Text.Encoding]::UTF8.GetString($buf) | ConvertFrom-Json
            return [string]$pkg.version
        } finally { $fs.Dispose() }
    } catch {
        return $null
    }
}

function Get-BackupVersion([string]$backupPath) {
    $sidecar = "$backupPath.version"
    if (Test-Path -LiteralPath $sidecar) {
        return ([string](Get-Content -LiteralPath $sidecar -Raw)).Trim()
    }
    return $null
}

if (-not (Test-Path $Payload)) { throw "Не найден патченный архив: $Payload" }

$srcSize = (Get-Item -LiteralPath $Payload).Length
$dstSize = (Get-Item -LiteralPath $asar).Length
Write-Host ("установка: {0}" -f $install)
Write-Host ("перевод: {0:N0} байт, сейчас: {1:N0} байт" -f $srcSize, $dstSize)

# Бэкап привязан к версии приложения: после обновления ZCode старый архив
# не годится для отката, поэтому он уезжает в файл со версией в имени.
$currentVersion = Get-AsarVersion $asar
$versionFile = "$backup.version"
$backupVersion = Get-BackupVersion $backup
if (-not $backupVersion -and (Test-Path -LiteralPath $backup)) {
    # метки нет — пробуем прочитать версию прямо из архива бэкапа
    $backupVersion = Get-AsarVersion $backup
}
Write-Host ("версия приложения: {0}; бэкап: {1}" -f `
    ($(if ($currentVersion) { $currentVersion } else { 'неизвестна' })), `
    ($(if (Test-Path -LiteralPath $backup) { $(if ($backupVersion) { $backupVersion } else { 'без метки' }) } else { 'нет' })))

if (-not (Test-Path -LiteralPath $backup)) {
    Write-Host "сохраняю оригинал в $backup ..."
    Copy-Item -LiteralPath $asar -Destination $backup -Force
    Set-Content -LiteralPath $versionFile -Value $currentVersion -Encoding UTF8
} elseif ($backupVersion -ne $currentVersion) {
    $label = if ($backupVersion) { $backupVersion } else { 'unknown' }
    $archived = Join-Path $profileDir ("app.asar.{0}.backup" -f $label)
    if (-not (Test-Path -LiteralPath $archived)) {
        Move-Item -LiteralPath $backup -Destination $archived -Force
        Write-Host ("старый бэкап {0} отложен в {1}" -f $label, $archived)
    } else {
        Remove-Item -LiteralPath $backup -Force
        Write-Host ("старый бэкап {0} уже сохранён как {1}, перезаписываю текущий" -f $label, $archived)
    }
    Write-Host "сохраняю оригинал версии $currentVersion ..."
    Copy-Item -LiteralPath $asar -Destination $backup -Force
    Set-Content -LiteralPath $versionFile -Value $currentVersion -Encoding UTF8
} else {
    Write-Host "оригинал этой версии уже сохранён: $backup"
}

$done = $false
try {
    Copy-Item -LiteralPath $Payload -Destination $asar -Force
    Write-Host 'архив заменён копированием'
    $done = $true
} catch {
    Write-Host ("копирование не удалось: " + $_.Exception.Message)
}

if (-not $done) {
    Write-Host 'пишу поверх существующего архива (ZCode запущен)...'
    $src = [IO.File]::OpenRead($Payload)
    try {
        $dst = [IO.File]::Open($asar, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
        try {
            $buf = New-Object byte[] 8388608
            $pos = 0L
            while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) {
                $dst.Write($buf, 0, $n)
                $pos += $n
            }
            $dst.SetLength($pos)
            Write-Host "записано $pos байт"
            $done = $true
        } finally { $dst.Dispose() }
    } finally { $src.Dispose() }
}

$now = (Get-Item -LiteralPath $asar).Length
$ok = ($now -eq $srcSize)
Write-Host ("итоговый размер: {0:N0} (ожидался {1:N0})" -f $now, $srcSize)
Write-Host $(if ($ok) { 'РЕЗУЛЬТАТ: OK' } else { 'РЕЗУЛЬТАТ: FAIL' })
Stop-Transcript | Out-Null

Write-Host ''
Write-Host 'Полностью закройте ZCode (трей → «Выйти») и запустите снова.' -ForegroundColor Cyan
Write-Host "Откат: uninstall.ps1  (бэкап: $backup)"
if (-not $Quiet) { Read-Host 'Нажмите Enter для выхода' }
if (-not $ok) { exit 1 }
