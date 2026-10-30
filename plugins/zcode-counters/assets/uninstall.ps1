<#
    zcode-ru: откат к оригинальному app.asar из бэкапа плагина.
    Требует прав администратора (сам запросит UAC).
#>

param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

$profileDir = Join-Path $env:LOCALAPPDATA 'ZCodeCounters'
$backup     = Join-Path $profileDir 'app.asar.backup'
$log        = Join-Path $profileDir 'uninstall.log'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Требуются права администратора. Запускаю через UAC...' -ForegroundColor Yellow
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Quiet) { $args += '-Quiet' }
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

