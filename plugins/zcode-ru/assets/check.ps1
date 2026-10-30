<#
    zcode-ru: состояние локализации — установлен ли ZCode, есть ли бэкап,
    русский ли интерфейс, сколько строк каталога и какая версия приложения.
    Только чтение, права администратора не нужны.
#>

$ErrorActionPreference = 'Stop'

function Write-Status($text, $ok) {
    $color = if ($ok -eq $true) { 'Green' } elseif ($ok -eq $false) { 'Red' } else { 'White' }
    Write-Host $text -ForegroundColor $color
}

$candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
$install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
if (-not $install) {
    Write-Status 'ZCode не найден.' $false
    exit 2
}
$asar = Join-Path $install 'resources\app.asar'
Write-Status ("ZCode: {0}" -f $install) $null
Write-Host ("app.asar: {0:N0} байт, изменён {1:yyyy-MM-dd HH:mm}" -f `
    (Get-Item -LiteralPath $asar).Length, (Get-Item -LiteralPath $asar).LastWriteTime)

$backup = Join-Path (Join-Path $env:LOCALAPPDATA 'ZCodeRu') 'app.asar.backup'
if (Test-Path $backup) {
    Write-Status ("Бэкап оригинала: есть ({0:N0} байт)" -f (Get-Item -LiteralPath $backup).Length) $true
} else {
    Write-Status 'Бэкап оригинала: нет' $false
}

# читаем заголовок asar и ищем каталог интерфейса
$fs = [IO.File]::OpenRead($asar)
try {
    $head = New-Object byte[] 16
    [void]$fs.Read($head, 0, 16)
    $jsonLen = [BitConverter]::ToUInt32($head, 12)
    $jsonBytes = New-Object byte[] $jsonLen
    [void]$fs.Read($jsonBytes, 0, $jsonLen)
    $header = [Text.Encoding]::UTF8.GetString($jsonBytes) | ConvertFrom-Json
    $dataStart = 16 + $jsonLen + ((4 - ($jsonLen % 4)) % 4)

    $appVersion = 'неизвестна'
    $pkg = $header.files.'package.json'
    if ($pkg) {
        $fs.Position = $dataStart + [int64]$pkg.offset
        $b = New-Object byte[] $pkg.size
        [void]$fs.Read($b, 0, $b.Length)
        $appVersion = ($b | ForEach-Object { [char]$_ }) -join ''
        if ($appVersion -match '"version"\s*:\s*"([^"]+)"') { $appVersion = $Matches[1] }
    }
    Write-Host ("Версия приложения: {0}" -f $appVersion)

    $intl = $null
    foreach ($name in $header.files.'out'.files.'renderer'.files.'assets'.files.PSObject.Properties.Name) {
        if ($name -like 'IntlProvider-*.js') {
            $intl = $header.files.'out'.files.'renderer'.files.'assets'.files.$name
            break
        }
    }
    if (-not $intl) { Write-Status 'Каталог интерфейса не найден (структура изменилась).' $false; exit 3 }

    $fs.Position = $dataStart + [int64]$intl.offset
    $buf = New-Object byte[] $intl.size
    [void]$fs.Read($buf, 0, $buf.Length)
    $text = [Text.Encoding]::UTF8.GetString($buf)

    $ru = ($text.Contains('Русский') -and $text.Contains('Настройки модели'))
    Write-Status $(if ($ru) { 'Интерфейс: русский' } else { 'Интерфейс: английский (локализация не установлена)' }) $ru

    # сколько ключей каталога переведено — грубая оценка по числу кириллических символов
    $cyr = ([regex]::Matches($text, '[\u0400-\u04FF]')).Count
    Write-Host ("Кириллических символов в каталоге: {0:N0}" -f $cyr)
} finally {
    $fs.Dispose()
}

if (Test-Path $backup) { exit 0 } else { exit 1 }
