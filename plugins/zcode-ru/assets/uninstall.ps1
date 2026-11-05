<#
    zcode-ru: откат к оригинальному app.asar из бэкапа плагина.
    Требует прав администратора (сам запросит UAC).
#>

param([switch]$Quiet, [switch]$Force)

$ErrorActionPreference = 'Stop'

$profileDir = Join-Path $env:LOCALAPPDATA 'ZCodeRu'
$backup     = Join-Path $profileDir 'app.asar.backup'
$log        = Join-Path $profileDir 'uninstall.log'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Требуются права администратора. Запускаю через UAC...' -ForegroundColor Yellow
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Quiet) { $args += '-Quiet' }
    if ($Force) { $args += '-Force' }
    Start-Process powershell -Verb RunAs -Wait -ArgumentList $args
    exit
}

Start-Transcript -Path $log -Force | Out-Null

if (-not (Test-Path $backup)) {
    Stop-Transcript | Out-Null
    throw "Бэкап не найден: $backup`nВосстановить оригинал можно переустановкой ZCode."
}

$candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
$install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
if (-not $install) { Stop-Transcript | Out-Null; throw 'Не найден установленный ZCode.' }
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
$currentVersion = Get-AsarVersion $asar
$backupVersion = Get-BackupVersion $backup
if (-not $backupVersion -and (Test-Path -LiteralPath $backup)) {
    # метки нет — пробуем прочитать версию прямо из архива бэкапа
    $backupVersion = Get-AsarVersion $backup
}
Write-Host ("версия приложения: {0}; бэкап: {1}" -f `
    ($(if ($currentVersion) { $currentVersion } else { 'неизвестна' })), `
    ($(if ($backupVersion) { $backupVersion } else { 'без метки' })))

# Архив другой версии в текущей установке сломает приложение: откат только
# при совпадении версий либо по явному -Force.
if ($backupVersion -and $currentVersion -and $backupVersion -ne $currentVersion -and -not $Force) {
    Stop-Transcript | Out-Null
    throw ("Бэкап от версии {0}, а установлена {1}. Восстановление сломает ZCode.`nПереустановите ZCode либо повторите с -Force, если откат версии осознан." -f `
        $backupVersion, $currentVersion)
}

$srcSize = (Get-Item -LiteralPath $backup).Length
Write-Host ("Восстанавливаю оригинал: {0:N0} байт" -f $srcSize)

try {
    Copy-Item -LiteralPath $backup -Destination $asar -Force
} catch {
    Write-Host 'Файл занят запущенным ZCode — пишу поверх...'
    $src = [IO.File]::OpenRead($backup)
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
        } finally { $dst.Dispose() }
    } finally { $src.Dispose() }
}

$now = (Get-Item -LiteralPath $asar).Length
Write-Host $(if ($now -eq $srcSize) { 'РЕЗУЛЬТАТ: OK — оригинал восстановлен.' } else { 'РЕЗУЛЬТАТ: FAIL — размер не совпал.' })
Stop-Transcript | Out-Null
Write-Host 'Закройте и запустите ZCode заново.' -ForegroundColor Cyan
if (-not $Quiet) { Read-Host 'Нажмите Enter для выхода' }
if ($now -ne $srcSize) { exit 1 }
