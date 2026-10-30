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

if (-not (Test-Path $Payload)) { throw "Не найден патченный архив: $Payload" }

$srcSize = (Get-Item -LiteralPath $Payload).Length
$dstSize = (Get-Item -LiteralPath $asar).Length
Write-Host ("установка: {0}" -f $install)
Write-Host ("перевод: {0:N0} байт, сейчас: {1:N0} байт" -f $srcSize, $dstSize)

if (-not (Test-Path $backup)) {
    Write-Host "сохраняю оригинал в $backup ..."
    Copy-Item -LiteralPath $asar -Destination $backup -Force
} else {
    Write-Host "оригинал уже сохранён: $backup"
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
