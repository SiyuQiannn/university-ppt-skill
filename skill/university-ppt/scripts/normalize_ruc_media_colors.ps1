param(
    [Parameter(Mandatory = $true)]
    [string]$InputDir,

    [int]$MaxPixels = 160000
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Convert-HexToRgb([string]$hex) {
    $clean = $hex.TrimStart("#").ToUpperInvariant()
    return @{
        R = [Convert]::ToInt32($clean.Substring(0, 2), 16)
        G = [Convert]::ToInt32($clean.Substring(2, 2), 16)
        B = [Convert]::ToInt32($clean.Substring(4, 2), 16)
    }
}

function Get-ColorInfo([int]$r8, [int]$g8, [int]$b8) {
    $r = $r8 / 255.0
    $g = $g8 / 255.0
    $b = $b8 / 255.0
    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))
    $delta = $max - $min

    if ($delta -eq 0) {
        $h = 0
    } elseif ($max -eq $r) {
        $h = 60 * ((($g - $b) / $delta) % 6)
    } elseif ($max -eq $g) {
        $h = 60 * ((($b - $r) / $delta) + 2)
    } else {
        $h = 60 * ((($r - $g) / $delta) + 4)
    }
    if ($h -lt 0) { $h += 360 }

    $l = ($max + $min) / 2.0
    if ($delta -eq 0) {
        $s = 0
    } else {
        $s = $delta / (1 - [Math]::Abs(2 * $l - 1))
    }
    return @{ H = $h; S = $s; L = $l }
}

function Get-RucRgb([int]$r, [int]$g, [int]$b) {
    $info = Get-ColorInfo $r $g $b
    if ($info.S -lt 0.16) { return $null }
    if ($info.H -le 25 -or $info.H -ge 335) { return $null }

    if ($info.H -ge 25 -and $info.H -le 75) {
        if ($info.L -lt 0.45) { return Convert-HexToRgb "9C7A32" }
        if ($info.L -lt 0.72) { return Convert-HexToRgb "C9A45C" }
        return Convert-HexToRgb "E9D8B6"
    }

    if ($info.L -lt 0.22) { return Convert-HexToRgb "7C0000" }
    if ($info.L -lt 0.42) { return Convert-HexToRgb "A50000" }
    if ($info.L -lt 0.62) { return Convert-HexToRgb "C73342" }
    if ($info.L -lt 0.80) { return Convert-HexToRgb "D96A78" }
    return Convert-HexToRgb "F4CCD2"
}

function Normalize-PngBytes([byte[]]$bytes, [ref]$changedPixels) {
    $inputStream = New-Object System.IO.MemoryStream(,$bytes)
    $bitmap = [System.Drawing.Bitmap]::FromStream($inputStream)
    try {
        if (($bitmap.Width * $bitmap.Height) -gt $MaxPixels) {
            $changedPixels.Value = 0
            return $null
        }
        $changed = 0
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -lt 20) { continue }
                $mapped = Get-RucRgb $pixel.R $pixel.G $pixel.B
                if ($null -ne $mapped) {
                    $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $mapped.R, $mapped.G, $mapped.B))
                    $changed++
                }
            }
        }
        $changedPixels.Value = $changed
        if ($changed -eq 0) { return $null }
        $output = New-Object System.IO.MemoryStream
        $bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
        return $output.ToArray()
    } finally {
        $bitmap.Dispose()
        $inputStream.Dispose()
    }
}

function Normalize-SvgText([string]$svg, [ref]$changedColors) {
    $count = 0
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $hex = $m.Groups[1].Value
        $rgb = Convert-HexToRgb $hex
        $mapped = Get-RucRgb $rgb.R $rgb.G $rgb.B
        if ($null -eq $mapped) { return $m.Value }
        $count++
        return ("#{0:X2}{1:X2}{2:X2}" -f $mapped.R, $mapped.G, $mapped.B)
    }
    $newSvg = [regex]::Replace($svg, "#([0-9A-Fa-f]{6})", $evaluator)
    $changedColors.Value = $count
    if ($count -eq 0) { return $null }
    return $newSvg
}

function Read-EntryBytes($entry) {
    $stream = $entry.Open()
    try {
        $memory = New-Object System.IO.MemoryStream
        try {
            $stream.CopyTo($memory)
            return $memory.ToArray()
        } finally {
            $memory.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

function Replace-EntryBytes($zip, $entry, [byte[]]$bytes) {
    $name = $entry.FullName
    $entry.Delete()
    $newEntry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
    $stream = $newEntry.Open()
    try {
        $stream.Write($bytes, 0, $bytes.Length)
    } finally {
        $stream.Dispose()
    }
}

$inputPath = (Resolve-Path $InputDir).Path
$report = @()

foreach ($pptx in Get-ChildItem -LiteralPath $inputPath -Filter "*.pptx") {
    $zip = [System.IO.Compression.ZipFile]::Open($pptx.FullName, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $targets = @($zip.Entries | Where-Object { $_.FullName -match "^ppt/media/.*\.(png|svg)$" })
        foreach ($entry in $targets) {
            $ext = [System.IO.Path]::GetExtension($entry.FullName).ToLowerInvariant()
            $bytes = Read-EntryBytes $entry
            if ($ext -eq ".png") {
                $changedPixels = 0
                $newBytes = Normalize-PngBytes $bytes ([ref]$changedPixels)
                if ($null -ne $newBytes) {
                    Replace-EntryBytes $zip $entry $newBytes
                    $report += [pscustomobject]@{
                        Pptx = $pptx.Name
                        Entry = $entry.FullName
                        Type = "png"
                        Changed = $changedPixels
                    }
                }
            } elseif ($ext -eq ".svg") {
                $svg = [System.Text.Encoding]::UTF8.GetString($bytes)
                $changedColors = 0
                $newSvg = Normalize-SvgText $svg ([ref]$changedColors)
                if ($null -ne $newSvg) {
                    $newBytes = [System.Text.Encoding]::UTF8.GetBytes($newSvg)
                    Replace-EntryBytes $zip $entry $newBytes
                    $report += [pscustomobject]@{
                        Pptx = $pptx.Name
                        Entry = $entry.FullName
                        Type = "svg"
                        Changed = $changedColors
                    }
                }
            }
        }
    } finally {
        $zip.Dispose()
    }
}

$reportPath = Join-Path $inputPath "media_color_cleanup_report.csv"
$report | Export-Csv -LiteralPath $reportPath -Encoding UTF8 -NoTypeInformation
[pscustomobject]@{
    InputDir = $inputPath
    UpdatedEntries = $report.Count
    Report = $reportPath
}
