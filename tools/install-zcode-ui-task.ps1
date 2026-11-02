<#
    install-zcode-ui-task.ps1 — регистрирует задачу Windows «ZCodeUiRestore»,
    которая сама восстанавливает русификатор и счётчики после обновления ZCode.

    Задача запускается:
      • при входе пользователя (через 30 секунд),
      • каждые 15 минут,
      • по требованию: schtasks /run /tn ZCodeUiRestore
    и работает с правами администратора — без запросов UAC.

    Установка (один раз, запросит UAC):
      powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-zcode-ui-task.ps1
#>
param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Нужны права администратора. Запускаю через UAC...' -ForegroundColor Yellow
    $argLine = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath
    if ($Quiet) { $argLine += ' -Quiet' }
    Start-Process powershell -Verb RunAs -Wait -ArgumentList $argLine
    exit
}

$root = Split-Path $PSScriptRoot -Parent
$restore = Join-Path $PSScriptRoot 'restore-zcode-ui.ps1'
if (-not (Test-Path $restore)) { throw "Не найден $restore" }

$taskName = 'ZCodeUiRestore'
$arg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" -Auto' -f $restore

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg -WorkingDirectory $root

$tLogon = New-ScheduledTaskTrigger -AtLogOn
try { $tLogon.Delay = 'PT30S' } catch { }

$tRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 15) -Hidden

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($tLogon, $tRepeat) `
    -Principal $principal -Settings $settings `
    -Description 'Автовосстановление русификатора и счётчиков ZCode после обновления (rukazax/z-code).' `
    -Force | Out-Null

Write-Host "Задача '$taskName' зарегистрирована." -ForegroundColor Green

# первый прогон — сразу, чтобы проверить, что всё работает
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 4
$info = Get-ScheduledTaskInfo -TaskName $taskName
Write-Host ("Проверочный запуск: LastTaskResult={0}, время={1}" -f $info.LastTaskResult, $info.LastRunTime) -ForegroundColor Cyan
Write-Host ("Лог: " + (Join-Path $env:LOCALAPPDATA 'ZCodeUiRestore\zcode-ui-restore.log')) -ForegroundColor Gray
if (-not $Quiet) { Read-Host 'Нажмите Enter для выхода' }
