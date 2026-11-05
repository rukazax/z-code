<#
    zcode-ru: SessionStart-проверка.
    Молчит, когда локализация на месте. Если интерфейс снова английский
    (например, обновление ZCode вернуло оригинальный app.asar), выдаёт
    strict-JSON с additionalContext — обычный текст ZCode отклонил бы.
    Всегда завершается с кодом 0.
#>

$ErrorActionPreference = 'Stop'

function Write-Context([string]$message) {
    $json = '{"additionalContext":' + (ConvertTo-Json $message -Compress) + '}'
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $stdout = [Console]::OpenStandardOutput()
    $stdout.Write($bytes, 0, $bytes.Length)
    $stdout.Flush()
}

try {
    $candidates = @('C:\Program Files\ZCode', (Join-Path $env:LOCALAPPDATA 'Programs\ZCode'))
    $install = $candidates | Where-Object { Test-Path (Join-Path $_ 'resources\app.asar') } | Select-Object -First 1
    if (-not $install) { exit 0 }

    $asar = Join-Path $install 'resources\app.asar'
    $fs = [IO.File]::OpenRead($asar)
    try {
        $head = New-Object byte[] 16
        [void]$fs.Read($head, 0, 16)
        $jsonLen = [BitConverter]::ToUInt32($head, 12)
        $jsonBytes = New-Object byte[] $jsonLen
        [void]$fs.Read($jsonBytes, 0, $jsonLen)
        $header = [Text.Encoding]::UTF8.GetString($jsonBytes) | ConvertFrom-Json
        $dataStart = 16 + $jsonLen + ((4 - ($jsonLen % 4)) % 4)

        $intl = $null
        $assets = $header.files.'out'.files.'renderer'.files.'assets'.files
        if ($assets) {
            foreach ($name in $assets.PSObject.Properties.Name) {
                if ($name -like 'IntlProvider-*.js') { $intl = $assets.$name; break }
            }
        }
        if (-not $intl) { exit 0 }

        $fs.Position = $dataStart + [int64]$intl.offset
        $buf = New-Object byte[] $intl.size
        [void]$fs.Read($buf, 0, $buf.Length)
        $text = [Text.Encoding]::UTF8.GetString($buf)
    } finally {
        $fs.Dispose()
    }

    if (-not $text.Contains('Русский')) {
        Write-Context 'zcode-ru: интерфейс ZCode сейчас на английском — похоже, приложение обновилось и вернуло оригинальный app.asar. Поставьте перевод заново: /rusifikator'
    }
} catch {
    # диагностика не должна мешать старту сессии
}
exit 0
