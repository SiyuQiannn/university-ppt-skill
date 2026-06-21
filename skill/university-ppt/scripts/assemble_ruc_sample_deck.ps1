param(
    [string]$OutputDir = "",
    [string]$CoverSuitePath = "",
    [string]$ContentDir = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function U([int[]]$codes) {
    return (-join ($codes | ForEach-Object { [char]$_ }))
}

function Rgb([int]$r, [int]$g, [int]$b) {
    return ($r -bor ($g -shl 8) -bor ($b -shl 16))
}

$T = @{
    ReportTitle = U @(0x6B64,0x5904,0x586B,0x5199,0x6C47,0x62A5,0x6807,0x9898)
    Subtitle = U @(0x6B64,0x5904,0x586B,0x5199,0x526F,0x6807,0x9898)
    SlideTitle = U @(0x6B64,0x5904,0x586B,0x5199,0x6807,0x9898)
    Body = U @(0x6B64,0x5904,0x586B,0x5199,0x6587,0x5B57)
    Title = U @(0x6807,0x9898)
    Label = U @(0x6807,0x7B7E)
    ChapterTitle = U @(0x7AE0,0x8282,0x6807,0x9898)
    Ruc = U @(0x4E2D,0x56FD,0x4EBA,0x6C11,0x5927,0x5B66)
    Catalog = U @(0x76EE,0x5F55)
    EndingTitle = U @(0x6B64,0x5904,0x586B,0x5199,0x7ED3,0x5C3E,0x6807,0x9898)
}

$C = @{
    Red = Rgb 165 0 0
    RedDark = Rgb 118 0 0
    Red2 = Rgb 184 32 43
    RedLight = Rgb 247 229 231
    Gold = Rgb 201 164 92
    GoldLight = Rgb 233 216 182
    Gray = Rgb 118 118 118
    LightGray = Rgb 244 244 244
    White = Rgb 255 255 255
}

function Set-RucThemeColors($pres) {
    $themeMap = @{
        3 = $C.RedDark
        4 = $C.LightGray
        5 = $C.Red2
        6 = $C.Gold
        7 = $C.Gray
        8 = $C.GoldLight
        9 = $C.Red
        10 = $C.RedLight
        11 = $C.RedDark
        12 = $C.Red2
    }

    foreach ($design in @($pres.Designs)) {
        foreach ($idx in $themeMap.Keys) {
            try {
                $design.SlideMaster.Theme.ThemeColorScheme.Colors($idx).RGB = $themeMap[$idx]
            } catch {}
        }
    }

    try {
        foreach ($idx in $themeMap.Keys) {
            $pres.SlideMaster.Theme.ThemeColorScheme.Colors($idx).RGB = $themeMap[$idx]
        }
    } catch {}
}

function Normalize-SavedPptxOfficeThemeDefaults([string]$pptxPath) {
    if (-not (Test-Path $pptxPath)) { return }
    $replacements = @{
        "44546A" = "767676"
        "4472C4" = "B8202B"
        "ED7D31" = "C9A45C"
        "FFC000" = "E9D8B6"
        "5B9BD5" = "A50000"
        "70AD47" = "767676"
        "0563C1" = "760000"
        "954F72" = "B8202B"
    }
    $zip = [System.IO.Compression.ZipFile]::Open($pptxPath, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $entries = @($zip.Entries | Where-Object { $_.FullName -match "^ppt/.*\.xml$" })
        foreach ($entry in $entries) {
            $reader = New-Object System.IO.StreamReader($entry.Open())
            try { $xml = $reader.ReadToEnd() } finally { $reader.Dispose() }
            $newXml = [regex]::Replace($xml, 'val="([0-9A-Fa-f]{6})"', {
                param($m)
                $hex = $m.Groups[1].Value.ToUpperInvariant()
                if ($replacements.ContainsKey($hex)) {
                    return 'val="' + $replacements[$hex] + '"'
                }
                return $m.Value
            })
            $newXml = [regex]::Replace($newXml, 'lastClr="([0-9A-Fa-f]{6})"', {
                param($m)
                $hex = $m.Groups[1].Value.ToUpperInvariant()
                if ($replacements.ContainsKey($hex)) {
                    return 'lastClr="' + $replacements[$hex] + '"'
                }
                return $m.Value
            })
            if ($newXml -ne $xml) {
                $name = $entry.FullName
                $entry.Delete()
                $newEntry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
                $encoding = New-Object System.Text.UTF8Encoding($false)
                $writer = New-Object System.IO.StreamWriter($newEntry.Open(), $encoding)
                try { $writer.Write($newXml) } finally { $writer.Dispose() }
            }
        }
    } finally {
        $zip.Dispose()
    }
}

$runRoot = (Resolve-Path ".").Path
$skillRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($CoverSuitePath)) {
    $CoverSuitePath = Join-Path $skillRoot "assets\structure-suites\ruc_no_image\00_no_image_cover_catalog_chapter_content_ending_suites.pptx"
}
if ([string]::IsNullOrWhiteSpace($ContentDir)) {
    $ContentDir = Join-Path $skillRoot "assets\content-layouts\ruc_core"
}
if (-not (Test-Path $CoverSuitePath)) {
    $CoverSuitePath = Join-Path $skillRoot "assets\structure-suites\ruc_thesis_exact\00_ruc_thesis_exact_cover_catalog_chapter_content_ending_suite.pptx"
}
$coverPath = (Resolve-Path $CoverSuitePath).Path
$contentPath = (Resolve-Path $ContentDir).Path
$useExactThesisBase = ($coverPath -like "*ruc_thesis_exact*")
$useThesisStructure = (($coverPath -like "*ruc_thesis*") -or $useExactThesisBase)
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $runRoot ("RUC_skill_sample_deck_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
}
$OutputDir = (New-Item -ItemType Directory -Force -Path $OutputDir).FullName
$outFile = Join-Path $OutputDir "RUC_skill_sample_deck.pptx"
$previewDir = Join-Path $OutputDir "preview_png"
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

$assetRoot = Join-Path $skillRoot "assets\schools\ruc"
$logoGold = Join-Path $assetRoot "logos\seal-full-color.png"
$logoRed = Join-Path $assetRoot "logos\full-color.png"
$logoWhiteHorizontal = Join-Path $assetRoot "logos\white.png"
$logoWhiteSeal = Join-Path $assetRoot "logos\seal-white.png"
$photos = @{
    Gate = Join-Path $assetRoot "photos\ruc_gate_sign.jpg"
    Aerial = Join-Path $assetRoot "photos\campus_aerial_sunset.jpg"
    Old = Join-Path $assetRoot "photos\old_campus_front.jpg"
    Hall = Join-Path $assetRoot "photos\ruc_conference_hall.jpg"
}

function Find-ContentDeck([string]$prefix) {
    $file = Get-ChildItem -Path $contentPath -Filter "$prefix*.pptx" | Select-Object -First 1
    if (-not $file) { throw "Missing content deck prefix $prefix in $contentPath" }
    return $file.FullName
}

function Add-Rect($slide, [double]$x, [double]$y, [double]$w, [double]$h, [int]$fill, [int]$line = -1, [double]$trans = 0) {
    $shape = $slide.Shapes.AddShape(1, $x, $y, $w, $h)
    $shape.Fill.ForeColor.RGB = $fill
    $shape.Fill.Transparency = $trans
    if ($line -lt 0) {
        $shape.Line.Visible = 0
    } else {
        $shape.Line.Visible = -1
        $shape.Line.ForeColor.RGB = $line
    }
    return $shape
}

function Add-Line($slide, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [int]$color, [double]$weight = 1.2) {
    $shape = $slide.Shapes.AddLine($x1, $y1, $x2, $y2)
    $shape.Line.ForeColor.RGB = $color
    $shape.Line.Weight = $weight
    return $shape
}

function Add-Text($slide, [string]$text, [double]$x, [double]$y, [double]$w, [double]$h, [double]$size, [int]$color, [bool]$bold = $false, [int]$align = 1) {
    $shape = $slide.Shapes.AddTextbox(1, $x, $y, $w, $h)
    $shape.TextFrame.TextRange.Text = $text
    $shape.TextFrame.TextRange.Font.Name = "Microsoft YaHei"
    try { $shape.TextFrame.TextRange.Font.NameFarEast = "Microsoft YaHei" } catch {}
    $shape.TextFrame.TextRange.Font.Size = $size
    $shape.TextFrame.TextRange.Font.Color.RGB = $color
    $shape.TextFrame.TextRange.Font.Bold = $(if ($bold) { -1 } else { 0 })
    $shape.TextFrame.TextRange.ParagraphFormat.Alignment = $align
    $shape.Line.Visible = 0
    $shape.Fill.Visible = 0
    return $shape
}

function Get-ImageSize([string]$path) {
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        return @{ Width = [double]$img.Width; Height = [double]$img.Height }
    } finally {
        $img.Dispose()
    }
}

function Add-PictureByWidth($slide, [string]$path, [double]$x, [double]$y, [double]$w) {
    if (Test-Path $path) {
        $size = Get-ImageSize $path
        $h = $w * $size.Height / $size.Width
        return $slide.Shapes.AddPicture($path, $false, $true, $x, $y, $w, $h)
    }
    return $null
}

function Add-PictureInBox($slide, [string]$path, [double]$x, [double]$y, [double]$w, [double]$h) {
    if (Test-Path $path) {
        $size = Get-ImageSize $path
        $scale = [Math]::Min($w / $size.Width, $h / $size.Height)
        $newW = $size.Width * $scale
        $newH = $size.Height * $scale
        $newX = $x + (($w - $newW) / 2)
        $newY = $y + (($h - $newH) / 2)
        return $slide.Shapes.AddPicture($path, $false, $true, $newX, $newY, $newW, $newH)
    }
    return $null
}

function Add-Logo($slide, [double]$x, [double]$y, [double]$w, [string]$variant = "red") {
    $path = switch ($variant) {
        "white-horizontal" { $logoWhiteHorizontal }
        "white-seal" { $logoWhiteSeal }
        "gold" { $logoGold }
        default { $logoRed }
    }
    return Add-PictureByWidth $slide $path $x $y $w
}

function Add-Photo($slide, [string]$path, [double]$x, [double]$y, [double]$w, [double]$h, [double]$trans = 0) {
    return Add-PictureInBox $slide $path $x $y $w $h
}

function Normalize-ShapeText($shape, [bool]$placeholderOnly = $false) {
    try {
        if ($shape.Type -eq 6) {
            for ($i = 1; $i -le $shape.GroupItems.Count; $i++) {
                Normalize-ShapeText $shape.GroupItems.Item($i) $placeholderOnly
            }
            return
        }
    } catch {}

    try {
        if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            $range = $shape.TextFrame.TextRange
            $text = ($range.Text -replace '\s+', ' ').Trim()
            $range.Font.Name = "Microsoft YaHei"
            try { $range.Font.NameFarEast = "Microsoft YaHei" } catch {}

            if ($placeholderOnly -and -not [string]::IsNullOrWhiteSpace($text)) {
                if ($text -match '^[0-9０-９]+(\.[0-9０-９]+)?%?$') {
                    return
                }
                if ($text -match '^[0-9０-９]+$') {
                    return
                }
                if ($text.Length -le 5) {
                    $range.Text = $T.Label
                } elseif ([double]$range.Font.Size -ge 17) {
                    $range.Text = $T.Title
                } else {
                    $range.Text = $T.Body
                }
            }
        }
    } catch {}
}

function Normalize-SlideFonts($slide, [bool]$placeholderOnly = $false) {
    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        Normalize-ShapeText $slide.Shapes.Item($i) $placeholderOnly
    }
}

function Clear-ShapeText($shape) {
    try {
        if ($shape.Type -eq 6) {
            for ($i = 1; $i -le $shape.GroupItems.Count; $i++) {
                Clear-ShapeText $shape.GroupItems.Item($i)
            }
            return
        }
    } catch {}
    try {
        if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            $shape.TextFrame.TextRange.Text = ""
        }
    } catch {}
}

function Clear-SlideText($slide) {
    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        Clear-ShapeText $slide.Shapes.Item($i)
    }
}

function Remove-TextBoxesAndClearShapeText($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $shape = $slide.Shapes.Item($i)
        try {
            if ($shape.Type -eq 14 -or $shape.Type -eq 17) {
                $shape.Delete()
            } elseif ($shape.Type -eq 6) {
                Clear-ShapeText $shape
            } elseif ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                $shape.TextFrame.TextRange.Text = ""
            }
        } catch {}
    }
}

function Remove-FullSlideBackgrounds($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $s = $slide.Shapes.Item($i)
        try {
            $left = [double]$s.Left; $top = [double]$s.Top
            $width = [double]$s.Width; $height = [double]$s.Height
            if ($left -le 2 -and $top -le 2 -and $width -ge 956 -and $height -ge 536 -and $s.Type -ne 13) {
                $s.Delete()
            }
        } catch {}
    }
}

function Remove-EdgeArtifacts($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $s = $slide.Shapes.Item($i)
        try {
            $left = [double]$s.Left
            $top = [double]$s.Top
            $width = [double]$s.Width
            $height = [double]$s.Height
            $right = $left + $width
            $bottom = $top + $height
            $area = $width * $height

            $isSmallTopLogo = ($top -lt 118 -and $left -lt 220 -and $width -lt 220 -and $height -lt 95)
            $isTopLine = ($top -lt 105 -and $height -lt 8 -and $width -gt 180)
            $isTopTitleText = ($top -lt 118 -and $left -lt 360 -and $s.HasTextFrame -and $s.TextFrame.HasText)
            $isTopRightLogo = ($top -lt 118 -and $right -gt 690 -and $width -lt 250 -and $height -lt 95)
            $isFooter = ($bottom -gt 500 -and ($height -lt 38 -or $area -lt 12000))

            if ($isSmallTopLogo -or $isTopLine -or $isTopTitleText -or $isTopRightLogo -or $isFooter) {
                $s.Delete()
            }
        } catch {}
    }
}

function Remove-ContentPictures($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $s = $slide.Shapes.Item($i)
        try {
            if ($s.Type -eq 13) {
                $s.Delete()
            }
        } catch {}
    }
}

function Fit-SlideContent($slide, [double]$safeX, [double]$safeY, [double]$safeW, [double]$safeH) {
    $items = @()
    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        $s = $slide.Shapes.Item($i)
        try {
            if ([double]$s.Width -lt 1 -or [double]$s.Height -lt 1) { continue }
            $items += $s
        } catch {}
    }
    if ($items.Count -eq 0) { return }

    $left = 999999.0; $top = 999999.0; $right = -999999.0; $bottom = -999999.0
    foreach ($s in $items) {
        try {
            $l = [double]$s.Left; $t = [double]$s.Top
            $r = $l + [double]$s.Width; $b = $t + [double]$s.Height
            if ($l -lt $left) { $left = $l }
            if ($t -lt $top) { $top = $t }
            if ($r -gt $right) { $right = $r }
            if ($b -gt $bottom) { $bottom = $b }
        } catch {}
    }
    $bw = $right - $left
    $bh = $bottom - $top
    if ($bw -le 1 -or $bh -le 1) { return }

    $scale = [Math]::Min($safeW / $bw, $safeH / $bh)
    if ($scale -gt 1.18) { $scale = 1.18 }
    $newW = $bw * $scale
    $newH = $bh * $scale
    $dx = $safeX + (($safeW - $newW) / 2)
    $dy = $safeY + (($safeH - $newH) / 2)

    foreach ($s in $items) {
        try {
            $oldL = [double]$s.Left
            $oldT = [double]$s.Top
            $oldW = [double]$s.Width
            $oldH = [double]$s.Height
            $s.Left = $dx + (($oldL - $left) * $scale)
            $s.Top = $dy + (($oldT - $top) * $scale)
            if ($oldW -gt 1) { $s.Width = $oldW * $scale }
            if ($oldH -gt 1) { $s.Height = $oldH * $scale }
        } catch {}
    }
}

function Add-ContentChrome($slide, [int]$slideNo, [int]$tabIndex) {
    if ($script:useThesisStructure) {
        Add-Rect $slide 0 0 960 60 $C.Red | Out-Null
        Add-Logo $slide 16 12 150 "white-horizontal" | Out-Null
        Add-Text $slide $T.SlideTitle 186 13 310 34 22 $C.White $true | Out-Null
        for ($i = 0; $i -lt 4; $i++) {
            $x = 528 + ($i * 92)
            Add-Text $slide $T.Title $x 18 72 18 11 $C.White ($i -eq ($tabIndex - 1)) 2 | Out-Null
            if ($i -eq ($tabIndex - 1)) {
                Add-Line $slide ($x + 8) 46 ($x + 64) 46 $C.White 1.5 | Out-Null
            }
        }
        Add-Rect $slide 0 60 960 42 $C.RedLight | Out-Null
        Add-Text $slide (">  " + $T.SlideTitle) 44 70 540 26 18 $C.Red $true | Out-Null
        Add-Line $slide 44 102 916 102 $C.Red 1.1 | Out-Null
        Add-Text $slide ("{0:D2}" -f $slideNo) 906 512 20 14 9 $C.Gray $false 3 | Out-Null
        return
    }

    Add-Rect $slide 0 0 960 56 $C.Red | Out-Null
    Add-Rect $slide 0 56 960 22 $C.RedLight | Out-Null
    Add-Logo $slide 24 12 132 "white-horizontal" | Out-Null
    Add-Text $slide $T.SlideTitle 176 14 300 30 20 $C.White $true | Out-Null

    for ($i = 0; $i -lt 4; $i++) {
        $x = 505 + ($i * 96)
        Add-Text $slide $T.Title $x 18 76 22 12 $C.White ($i -eq ($tabIndex - 1)) 2 | Out-Null
        if ($i -eq ($tabIndex - 1)) {
            Add-Line $slide ($x + 8) 46 ($x + 68) 46 $C.White 1.5 | Out-Null
        }
    }

    Add-Line $slide 48 78 912 78 $C.Red 1.1 | Out-Null
    Add-Rect $slide 0 516 960 24 $C.RedLight | Out-Null
    Add-Text $slide ("{0:D2}" -f $slideNo) 884 518 36 18 10 $C.Gray $false 3 | Out-Null
}

function Insert-SlideFromFile($presentation, [string]$path, [int]$slideIndex) {
    $before = $presentation.Slides.Count
    $presentation.Slides.InsertFromFile($path, $before, $slideIndex, $slideIndex) | Out-Null
    return $presentation.Slides.Item($before + 1)
}

function Add-BlankSlide($presentation) {
    return $presentation.Slides.Add($presentation.Slides.Count + 1, 12)
}

function Add-ChapterSlide($presentation, [string]$sectionNumber) {
    $slide = Add-BlankSlide $presentation
    Add-Rect $slide 0 0 960 540 $C.White | Out-Null
    Add-Rect $slide 0 0 960 70 $C.Red | Out-Null
    Add-Rect $slide 0 70 960 34 $C.RedLight | Out-Null
    Add-Logo $slide 24 16 36 "white-seal" | Out-Null
    Add-Text $slide $T.ChapterTitle 82 19 360 28 22 $C.White $true | Out-Null

    Add-Rect $slide 112 182 530 154 $C.White $C.RedLight | Out-Null
    Add-Rect $slide 112 182 10 154 $C.Red | Out-Null
    Add-Line $slide 160 292 600 292 $C.Gold 2 | Out-Null
    Add-Text $slide $sectionNumber 164 208 86 48 34 $C.Red $true | Out-Null
    Add-Text $slide $T.SlideTitle 276 214 320 40 24 $C.Red $true | Out-Null
    return $slide
}

function Add-StructureChapterSlide($presentation, [string]$sectionNumber) {
    $slide = Insert-SlideFromFile $presentation $coverPath 3
    Normalize-SlideFonts $slide $false
    $replaced = $false
    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        $shape = $slide.Shapes.Item($i)
        try {
            if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                $text = $shape.TextFrame.TextRange.Text
                if (-not $replaced -and $text -match '01') {
                    $shape.TextFrame.TextRange.Text = ($text -replace '01', $sectionNumber)
                    $replaced = $true
                }
            }
        } catch {}
    }
    return $slide
}

function Sanitize-StructureSlide($slide, [string]$sectionNumber = "") {
    Normalize-SlideFonts $slide $false
    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        $shape = $slide.Shapes.Item($i)
        try {
            if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                $txt = $shape.TextFrame.TextRange.Text
                if (-not [string]::IsNullOrWhiteSpace($sectionNumber)) {
                    $shape.TextFrame.TextRange.Text = [regex]::Replace($txt, '[0-9０-９]{2}', $sectionNumber, 1)
                }
                if ($txt -match '模板|作者|网址|版权|PPT') {
                    $shape.TextFrame.TextRange.Text = $T.SlideTitle
                }
            }
        } catch {}
    }
    if (-not [string]::IsNullOrWhiteSpace($sectionNumber)) {
        Add-Rect $slide 48 70 420 48 $C.RedLight -1 0 | Out-Null
        Add-Text $slide ($sectionNumber + "  " + $T.SlideTitle) 70 78 380 34 20 $C.Red $true | Out-Null
    }
}

function Export-Preview($presentation, [string]$dir) {
    for ($i = 1; $i -le $presentation.Slides.Count; $i++) {
        $file = Join-Path $dir ("slide_{0:D2}.png" -f $i)
        $presentation.Slides.Item($i).Export($file, "PNG", 1600, 900) | Out-Null
    }
}

function Build-ContactSheet([string]$dir, [string]$outPath, [int]$cols = 4) {
    Add-Type -AssemblyName System.Drawing
    $files = Get-ChildItem -Path $dir -Filter "slide_*.png" | Sort-Object Name
    if ($files.Count -eq 0) { return }

    $thumbW = 320; $thumbH = 180; $labelH = 20; $gap = 12
    $rows = [Math]::Ceiling($files.Count / $cols)
    $sheetW = ($cols * $thumbW) + (($cols + 1) * $gap)
    $sheetH = ($rows * ($thumbH + $labelH)) + (($rows + 1) * $gap)
    $bmp = New-Object System.Drawing.Bitmap $sheetW, $sheetH
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $font = New-Object System.Drawing.Font "Arial", 10
    $brush = [System.Drawing.Brushes]::DimGray

    for ($idx = 0; $idx -lt $files.Count; $idx++) {
        $row = [Math]::Floor($idx / $cols)
        $col = $idx % $cols
        $x = $gap + ($col * ($thumbW + $gap))
        $y = $gap + ($row * ($thumbH + $labelH + $gap))
        $img = [System.Drawing.Image]::FromFile($files[$idx].FullName)
        $g.DrawImage($img, $x, $y, $thumbW, $thumbH)
        $img.Dispose()
        $g.DrawString(("p{0}" -f ($idx + 1)), $font, $brush, $x, ($y + $thumbH + 2))
    }

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

$contentSelections = @(
    @{ Prefix = "01"; Slide = 10; Tab = 1 },
    @{ Prefix = "01"; Slide = 18; Tab = 1 },
    @{ Prefix = "01"; Slide = 24; Tab = 1 },
    @{ Prefix = "03"; Slide = 13; Tab = 1 },
    @{ Prefix = "03"; Slide = 24; Tab = 1 },
    @{ Prefix = "06"; Slide = 6; Tab = 1 },
    @{ Prefix = "06"; Slide = 15; Tab = 1 },
    @{ Prefix = "04"; Slide = 3; Tab = 2 },
    @{ Prefix = "04"; Slide = 5; Tab = 2 },
    @{ Prefix = "05"; Slide = 8; Tab = 2 },
    @{ Prefix = "05"; Slide = 4; Tab = 2 },
    @{ Prefix = "08"; Slide = 8; Tab = 2 },
    @{ Prefix = "08"; Slide = 13; Tab = 2 },
    @{ Prefix = "07"; Slide = 1; Tab = 2 },
    @{ Prefix = "07"; Slide = 3; Tab = 2 },
    @{ Prefix = "06"; Slide = 22; Tab = 3 },
    @{ Prefix = "06"; Slide = 27; Tab = 3 },
    @{ Prefix = "08"; Slide = 16; Tab = 3 },
    @{ Prefix = "08"; Slide = 17; Tab = 3 }
)

$ppt = $null
$pres = $null
try {
    $ppt = New-Object -ComObject PowerPoint.Application
    $ppt.Visible = -1
    if ($script:useExactThesisBase) {
        Copy-Item -LiteralPath $coverPath -Destination $outFile -Force
        $pres = $ppt.Presentations.Open($outFile, $false, $false, $false)
        while ($pres.Slides.Count -gt 5) {
            $pres.Slides.Item($pres.Slides.Count).Delete()
        }
        # Keep cover, catalog, chapter, and ending. Content pages are added in between.
        $pres.Slides.Item(4).Delete()
    } else {
        $pres = $ppt.Presentations.Add()
        $pres.PageSetup.SlideWidth = 960
        $pres.PageSetup.SlideHeight = 540

        # Use suite 4 from the structure deck: cover, catalog, chapter, content master, ending.
        $coverSlide = Insert-SlideFromFile $pres $coverPath 1
        Sanitize-StructureSlide $coverSlide

        $catalogSlide = Insert-SlideFromFile $pres $coverPath 2
        Sanitize-StructureSlide $catalogSlide

        Add-StructureChapterSlide $pres "01" | Out-Null
    }

    foreach ($sel in $contentSelections[0..6]) {
        $deck = Find-ContentDeck $sel.Prefix
        $slide = Insert-SlideFromFile $pres $deck $sel.Slide
        try { $slide.Layout = 12 } catch {}
        try { $slide.DisplayMasterShapes = 0 } catch {}
        Remove-FullSlideBackgrounds $slide
        Remove-EdgeArtifacts $slide
        Remove-ContentPictures $slide
        Remove-TextBoxesAndClearShapeText $slide
        Fit-SlideContent $slide 58 110 844 372
        $pageNo = if ($script:useExactThesisBase) { $pres.Slides.Count - 1 } else { $pres.Slides.Count }
        Add-ContentChrome $slide $pageNo $sel.Tab
    }

    Add-StructureChapterSlide $pres "02" | Out-Null

    foreach ($sel in $contentSelections[7..14]) {
        $deck = Find-ContentDeck $sel.Prefix
        $slide = Insert-SlideFromFile $pres $deck $sel.Slide
        try { $slide.Layout = 12 } catch {}
        try { $slide.DisplayMasterShapes = 0 } catch {}
        Remove-FullSlideBackgrounds $slide
        Remove-EdgeArtifacts $slide
        Remove-ContentPictures $slide
        Remove-TextBoxesAndClearShapeText $slide
        Fit-SlideContent $slide 58 110 844 372
        $pageNo = if ($script:useExactThesisBase) { $pres.Slides.Count - 1 } else { $pres.Slides.Count }
        Add-ContentChrome $slide $pageNo $sel.Tab
    }

    Add-StructureChapterSlide $pres "03" | Out-Null

    foreach ($sel in $contentSelections[15..18]) {
        $deck = Find-ContentDeck $sel.Prefix
        $slide = Insert-SlideFromFile $pres $deck $sel.Slide
        try { $slide.Layout = 12 } catch {}
        try { $slide.DisplayMasterShapes = 0 } catch {}
        Remove-FullSlideBackgrounds $slide
        Remove-EdgeArtifacts $slide
        Remove-ContentPictures $slide
        Remove-TextBoxesAndClearShapeText $slide
        Fit-SlideContent $slide 58 110 844 372
        $pageNo = if ($script:useExactThesisBase) { $pres.Slides.Count - 1 } else { $pres.Slides.Count }
        Add-ContentChrome $slide $pageNo $sel.Tab
    }

    if ($script:useExactThesisBase) {
        $pres.Slides.Item(4).MoveTo($pres.Slides.Count)
    } else {
        $endingSlide = Insert-SlideFromFile $pres $coverPath 5
        Sanitize-StructureSlide $endingSlide
    }

    for ($i = 1; $i -le $pres.Slides.Count; $i++) {
        Normalize-SlideFonts $pres.Slides.Item($i) $false
    }

    Set-RucThemeColors $pres

    if ($script:useExactThesisBase) {
        $pres.Save()
    } else {
        $pres.SaveAs($outFile)
    }
    $script:SavedOutputForXmlCleanup = $outFile
    Export-Preview $pres $previewDir
    Build-ContactSheet $previewDir (Join-Path $OutputDir "preview_contact_sheet.png")

    $validation = [PSCustomObject]@{
        Output = $outFile
        Slides = $pres.Slides.Count
        Preview = (Join-Path $OutputDir "preview_contact_sheet.png")
        Status = "created"
    }
    $validation | Export-Csv -Path (Join-Path $OutputDir "validation.csv") -NoTypeInformation -Encoding UTF8
    $validation | Format-List
} finally {
    if ($pres -ne $null) { $pres.Close() }
    if ($ppt -ne $null) { $ppt.Quit() }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null 2>$null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null 2>$null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    if (-not [string]::IsNullOrWhiteSpace($script:SavedOutputForXmlCleanup)) {
        Normalize-SavedPptxOfficeThemeDefaults $script:SavedOutputForXmlCleanup
    }
}
