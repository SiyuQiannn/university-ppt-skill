param(
    [Parameter(Mandatory = $true)]
    [string]$SpecPath,
    [string]$SkillRoot = "",
    [string]$OutputDir = "",
    [switch]$NoPreview
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function HexToRgbInt([string]$hex) {
    $h = $hex.TrimStart("#")
    $r = [Convert]::ToInt32($h.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($h.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($h.Substring(4, 2), 16)
    return ($r -bor ($g -shl 8) -bor ($b -shl 16))
}

function RgbIntToHex([int]$rgb) {
    $r = $rgb -band 255
    $g = ($rgb -shr 8) -band 255
    $b = ($rgb -shr 16) -band 255
    return ("{0:X2}{1:X2}{2:X2}" -f $r, $g, $b)
}

function Resolve-SkillPath([string]$relativePath) {
    if ([string]::IsNullOrWhiteSpace($relativePath)) { return $null }
    return Join-Path $script:SkillRoot ($relativePath -replace "/", "\")
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
    if (Test-Path -LiteralPath $path) {
        $size = Get-ImageSize $path
        $h = $w * $size.Height / $size.Width
        return $slide.Shapes.AddPicture($path, $false, $true, $x, $y, $w, $h)
    }
    return $null
}

function Add-Logo($slide, [double]$x, [double]$y, [double]$w, [string]$variant = "white") {
    $path = if ($variant -eq "color") { $script:LogoColor } elseif ($variant -eq "seal-white") { $script:LogoSealWhite } elseif ($variant -eq "seal-color") { $script:LogoSealColor } else { $script:LogoWhite }
    return Add-PictureByWidth $slide $path $x $y $w
}

function Insert-SlideFromFile($presentation, [string]$path, [int]$slideIndex) {
    $before = $presentation.Slides.Count
    $presentation.Slides.InsertFromFile($path, $before, $slideIndex, $slideIndex) | Out-Null
    return $presentation.Slides.Item($before + 1)
}

function Add-BlankSlide($presentation) {
    return $presentation.Slides.Add($presentation.Slides.Count + 1, 12)
}

function Map-ThemeColor([int]$rgb) {
    $hex = RgbIntToHex $rgb
    if ($script:ExactColorMap.ContainsKey($hex)) { return $script:ExactColorMap[$hex] }
    $r = $rgb -band 255
    $g = ($rgb -shr 8) -band 255
    $b = ($rgb -shr 16) -band 255
    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))
    if (($max - $min) -lt 18) {
        if ($max -lt 90) { return $script:Color.NeutralDark }
        if ($max -gt 220) { return $rgb }
        if ($max -gt 165) { return $script:Color.NeutralLight }
        return $script:Color.Neutral
    }
    if ($r -gt 120 -and $g -lt 170 -and $b -lt 170) {
        if ($r -lt 145 -and $g -lt 80 -and $b -lt 80) { return $script:Color.PrimaryDark }
        if ($g -gt 135 -or $b -gt 135) { return $script:Color.PrimaryLight25 }
        if ($g -gt 95 -or $b -gt 95) { return $script:Color.PrimaryLight50 }
        if ($g -gt 55 -or $b -gt 55) { return $script:Color.PrimaryLight75 }
        return $script:Color.Primary
    }
    if (($r -gt 150 -and $g -gt 105 -and $b -lt 120) -or ($r -gt 180 -and $g -gt 140 -and $b -lt 80)) {
        return $script:Color.Accent
    }
    if ($b -gt $r -and $b -gt $g -and $script:ThemeFamily -ne "blue") {
        return $script:Color.Neutral
    }
    if ($g -gt $r -and $g -gt $b -and $script:ThemeFamily -ne "green") {
        return $script:Color.Neutral
    }
    return $rgb
}

function Apply-ThemeToShape($shape) {
    try {
        if ($shape.Type -eq 6) {
            for ($i = 1; $i -le $shape.GroupItems.Count; $i++) {
                Apply-ThemeToShape $shape.GroupItems.Item($i)
            }
            return
        }
    } catch {}

    try {
        if ($shape.Fill.Visible) {
            $shape.Fill.ForeColor.RGB = Map-ThemeColor ([int]$shape.Fill.ForeColor.RGB)
        }
    } catch {}
    try {
        if ($shape.Line.Visible) {
            $shape.Line.ForeColor.RGB = Map-ThemeColor ([int]$shape.Line.ForeColor.RGB)
        }
    } catch {}
    try {
        if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            $range = $shape.TextFrame.TextRange
            $range.Font.Name = "Microsoft YaHei"
            try { $range.Font.NameFarEast = "Microsoft YaHei" } catch {}
            $range.Font.Color.RGB = Map-ThemeColor ([int]$range.Font.Color.RGB)
        }
    } catch {}
}

function Apply-ThemeToSlide($slide) {
    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        Apply-ThemeToShape $slide.Shapes.Item($i)
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

function Remove-ContentTextAndPictures($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $shape = $slide.Shapes.Item($i)
        try {
            if ($shape.Type -eq 13) {
                $shape.Delete()
            } elseif ($shape.Type -eq 14 -or $shape.Type -eq 17) {
                $shape.Delete()
            } elseif ($shape.Type -eq 6) {
                Clear-ShapeText $shape
            } elseif ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                $shape.TextFrame.TextRange.Text = ""
            }
        } catch {}
    }
}

function Remove-EdgeArtifacts($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $s = $slide.Shapes.Item($i)
        try {
            $left = [double]$s.Left; $top = [double]$s.Top
            $width = [double]$s.Width; $height = [double]$s.Height
            $right = $left + $width; $bottom = $top + $height
            $isFullSlide = ($left -le 2 -and $top -le 2 -and $width -ge 956 -and $height -ge 536 -and $s.Type -ne 13)
            $isTopChrome = ($top -lt 110 -and ($height -lt 80 -or $width -gt 180))
            $isFooter = ($bottom -gt 500 -and ($height -lt 42 -or ($width * $height) -lt 15000))
            if ($isFullSlide -or $isTopChrome -or $isFooter) { $s.Delete() }
        } catch {}
    }
}

function Remove-StructureLogos($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $s = $slide.Shapes.Item($i)
        try {
            $left = [double]$s.Left; $top = [double]$s.Top
            $width = [double]$s.Width; $height = [double]$s.Height
            $isLikelyLogo = ($s.Type -eq 13 -and $top -lt 130 -and $width -lt 260 -and $height -lt 130)
            $isSmallTemplatePicture = ($s.Type -eq 13 -and $width -lt 340 -and $height -lt 200)
            $deleteAllPicturesForNoPhotoSuite = ($s.Type -eq 13 -and $script:ImagePreference -eq "minimal")
            if ($isLikelyLogo -or $isSmallTemplatePicture -or $deleteAllPicturesForNoPhotoSuite) { $s.Delete() }
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
    $bw = $right - $left; $bh = $bottom - $top
    if ($bw -le 1 -or $bh -le 1) { return }
    $scale = [Math]::Min($safeW / $bw, $safeH / $bh)
    if ($scale -gt 1.18) { $scale = 1.18 }
    $newW = $bw * $scale; $newH = $bh * $scale
    $dx = $safeX + (($safeW - $newW) / 2)
    $dy = $safeY + (($safeH - $newH) / 2)
    foreach ($s in $items) {
        try {
            $oldL = [double]$s.Left; $oldT = [double]$s.Top
            $oldW = [double]$s.Width; $oldH = [double]$s.Height
            $s.Left = $dx + (($oldL - $left) * $scale)
            $s.Top = $dy + (($oldT - $top) * $scale)
            if ($oldW -gt 1) { $s.Width = $oldW * $scale }
            if ($oldH -gt 1) { $s.Height = $oldH * $scale }
        } catch {}
    }
}

function Add-ContentChrome($slide, [int]$slideNo, [string]$title, [string]$section) {
    Add-Rect $slide 0 0 960 56 $script:Color.PrimaryDark | Out-Null
    Add-Rect $slide 0 56 960 22 $script:Color.PrimaryLight25 | Out-Null
    Add-Logo $slide 24 13 132 "white" | Out-Null
    Add-Text $slide $title 176 14 300 30 20 $script:Color.White $true | Out-Null
    Add-Line $slide 48 78 912 78 $script:Color.Primary 1.1 | Out-Null
    Add-Rect $slide 0 516 960 24 $script:Color.PrimaryLight25 | Out-Null
    Add-Text $slide ("{0:D2}" -f $slideNo) 884 518 36 18 10 $script:Color.Neutral $false 3 | Out-Null
}

function Normalize-StructureSlide($slide, $slideSpec) {
    Apply-ThemeToSlide $slide
    Remove-StructureLogos $slide
    $pageType = [string]$slideSpec.page_type
    if ($pageType -eq "cover") {
        Add-Logo $slide 64 48 150 "color" | Out-Null
        Add-Text $slide ([string]$slideSpec.title) 138 222 520 54 32 $script:Color.Primary $true | Out-Null
        Add-Line $slide 138 282 590 282 $script:Color.Accent 2.2 | Out-Null
        if (-not [string]::IsNullOrWhiteSpace([string]$slideSpec.subtitle)) {
            Add-Text $slide ([string]$slideSpec.subtitle) 144 304 520 26 15 $script:Color.Neutral | Out-Null
        }
    } elseif ($pageType -eq "toc") {
        Add-Logo $slide 34 18 128 "white" | Out-Null
        Add-Text $slide "目录" 156 18 180 32 24 $script:Color.White $true | Out-Null
    } elseif ($pageType -eq "section") {
        Add-Logo $slide 34 18 128 "white" | Out-Null
        $sectionText = if ([string]::IsNullOrWhiteSpace([string]$slideSpec.section)) { "01" } else { [string]$slideSpec.section }
        Add-Text $slide ($sectionText + "  " + [string]$slideSpec.title) 156 206 520 50 30 $script:Color.Primary $true | Out-Null
        Add-Line $slide 156 278 610 278 $script:Color.Accent 2.0 | Out-Null
    } elseif ($pageType -eq "ending") {
        Add-Logo $slide 64 58 150 "color" | Out-Null
        Add-Text $slide ([string]$slideSpec.title) 138 228 520 58 34 $script:Color.Primary $true | Out-Null
    }
}

function Get-StructureSlideIndex([string]$pageType) {
    switch ($pageType) {
        "cover" { return 1 }
        "toc" { return 2 }
        "section" { return 3 }
        "ending" { return 5 }
        default { return 4 }
    }
}

function Get-PptxSlideCount([string]$path) {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
    try {
        return @($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide[0-9]+\.xml$' }).Count
    } finally {
        $zip.Dispose()
    }
}

function Add-ContentSlide($presentation, $slideSpec) {
    $relative = [string]$slideSpec.selected_layout_file
    $path = Resolve-SkillPath (Join-Path "assets" $relative)
    $slideIndex = 1
    if ($null -ne $slideSpec.selected_layout_slide_index) { $slideIndex = [int]$slideSpec.selected_layout_slide_index }
    $count = Get-PptxSlideCount $path
    if ($slideIndex -lt 1 -or $slideIndex -gt $count) { $slideIndex = 1 }
    $slide = Insert-SlideFromFile $presentation $path $slideIndex
    try { $slide.Layout = 12 } catch {}
    try { $slide.DisplayMasterShapes = 0 } catch {}
    Remove-EdgeArtifacts $slide
    Remove-ContentTextAndPictures $slide
    Fit-SlideContent $slide 58 110 844 372
    Apply-ThemeToSlide $slide
    Add-ContentChrome $slide ([int]$slideSpec.slide_number) ([string]$slideSpec.title) ([string]$slideSpec.section)
    return $slide
}

function Export-Preview($presentation, [string]$dir) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    for ($i = 1; $i -le $presentation.Slides.Count; $i++) {
        $file = Join-Path $dir ("slide_{0:D2}.png" -f $i)
        $presentation.Slides.Item($i).Export($file, "PNG", 1600, 900) | Out-Null
    }
}

function Build-ContactSheet([string]$dir, [string]$outPath, [int]$cols = 4) {
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

function Normalize-SavedPptxColors([string]$pptxPath) {
    if (-not (Test-Path -LiteralPath $pptxPath)) { return }
    $zip = [System.IO.Compression.ZipFile]::Open($pptxPath, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $entries = @($zip.Entries | Where-Object { $_.FullName -match "^ppt/.*\.xml$" })
        foreach ($entry in $entries) {
            $reader = New-Object System.IO.StreamReader($entry.Open())
            try { $xml = $reader.ReadToEnd() } finally { $reader.Dispose() }
            $newXml = [regex]::Replace($xml, '(val|lastClr)="([0-9A-Fa-f]{6})"', {
                param($m)
                $attr = $m.Groups[1].Value
                $hex = $m.Groups[2].Value.ToUpperInvariant()
                if ($script:XmlHexMap.ContainsKey($hex)) {
                    return $attr + '="' + $script:XmlHexMap[$hex] + '"'
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

if ([string]::IsNullOrWhiteSpace($SkillRoot)) {
    $SkillRoot = Split-Path -Parent $PSScriptRoot
}
$script:SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$SpecPath = (Resolve-Path -LiteralPath $SpecPath).Path
$validateScript = Join-Path $script:SkillRoot "scripts\validate_deck_spec.ps1"
& $validateScript -SkillRoot $script:SkillRoot -SpecPath $SpecPath -Strict | Out-Null

$spec = Get-Content -Raw -Encoding UTF8 -LiteralPath $SpecPath | ConvertFrom-Json
$tokens = $spec.theme.tokens
$script:ThemeFamily = [string]$spec.theme.family
$script:ImagePreference = [string]$spec.request.image_preference
$script:Color = @{
    Primary = HexToRgbInt $tokens.primary
    PrimaryDark = HexToRgbInt $tokens.primary_dark
    PrimaryLight75 = HexToRgbInt $tokens.primary_light_75
    PrimaryLight50 = HexToRgbInt $tokens.primary_light_50
    PrimaryLight25 = HexToRgbInt $tokens.primary_light_25
    NeutralDark = HexToRgbInt $tokens.neutral_dark
    Neutral = HexToRgbInt $tokens.neutral
    NeutralLight = HexToRgbInt $tokens.neutral_light
    Accent = if ($tokens.accent) { HexToRgbInt $tokens.accent } else { HexToRgbInt "#C8A85A" }
    White = HexToRgbInt "#FFFFFF"
}

$script:ExactColorMap = @{
    "A00000" = $script:Color.Primary
    "AA0000" = $script:Color.Primary
    "B00000" = $script:Color.Primary
    "B8202B" = $script:Color.Primary
    "C00000" = $script:Color.Primary
    "750000" = $script:Color.PrimaryDark
    "760000" = $script:Color.PrimaryDark
    "7A0000" = $script:Color.PrimaryDark
    "C94A4A" = $script:Color.PrimaryLight75
    "D46A6A" = $script:Color.PrimaryLight75
    "E18A8A" = $script:Color.PrimaryLight50
    "F5DADA" = $script:Color.PrimaryLight25
    "FBEDEE" = $script:Color.PrimaryLight25
    "4472C4" = $script:Color.Primary
    "5B9BD5" = $script:Color.PrimaryLight75
    "70AD47" = $script:Color.Neutral
    "ED7D31" = $script:Color.Accent
    "FFC000" = $script:Color.Accent
    "C8A85A" = $script:Color.Accent
    "E9D8B6" = $script:Color.Accent
    "808080" = $script:Color.Neutral
    "767676" = $script:Color.Neutral
    "E9E9E9" = $script:Color.NeutralLight
}
$script:XmlHexMap = @{}
foreach ($key in $script:ExactColorMap.Keys) {
    $script:XmlHexMap[$key] = RgbIntToHex $script:ExactColorMap[$key]
}

$script:LogoColor = Resolve-SkillPath $spec.assets.logos.color_horizontal.path
$script:LogoWhite = Resolve-SkillPath $spec.assets.logos.white_horizontal.path
$script:LogoSealColor = Resolve-SkillPath $spec.assets.logos.seal_color.path
$script:LogoSealWhite = Resolve-SkillPath $spec.assets.logos.seal_white.path

$structurePath = Resolve-SkillPath (Join-Path "assets" ([string]$spec.structure_suite.source))
if (-not (Test-Path -LiteralPath $structurePath)) { throw "Missing structure suite file: $structurePath" }

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    if ($spec.outputs.output_dir) {
        $OutputDir = [string]$spec.outputs.output_dir
        if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
            $OutputDir = Join-Path (Split-Path -Parent $SpecPath) $OutputDir
        }
    } else {
        $OutputDir = Join-Path (Split-Path -Parent $SpecPath) "assembled_deck"
    }
}
$OutputDir = (New-Item -ItemType Directory -Force -Path $OutputDir).FullName
$outFile = Join-Path $OutputDir "deck.pptx"
$previewDir = Join-Path $OutputDir "preview_png"
$contactSheet = Join-Path $OutputDir "preview_contact_sheet.png"
$validationReport = Join-Path $OutputDir "assembly_report.json"

$ppt = $null
$pres = $null
$savedPptxForCleanup = ""
try {
    $ppt = New-Object -ComObject PowerPoint.Application
    $ppt.Visible = -1
    $pres = $ppt.Presentations.Add()
    $pres.PageSetup.SlideWidth = 960
    $pres.PageSetup.SlideHeight = 540

    foreach ($slideSpec in @($spec.slides)) {
        $pageType = [string]$slideSpec.page_type
        if ($pageType -eq "content") {
            Add-ContentSlide $pres $slideSpec | Out-Null
        } else {
            $idx = Get-StructureSlideIndex $pageType
            $max = Get-PptxSlideCount $structurePath
            if ($idx -gt $max) { $idx = 1 }
            $slide = Insert-SlideFromFile $pres $structurePath $idx
            try { $slide.Layout = 12 } catch {}
            Normalize-StructureSlide $slide $slideSpec
        }
    }

    for ($i = 1; $i -le $pres.Slides.Count; $i++) {
        Apply-ThemeToSlide $pres.Slides.Item($i)
    }
    $pres.SaveAs($outFile)
    $savedPptxForCleanup = $outFile
    if (-not $NoPreview) {
        Export-Preview $pres $previewDir
        Build-ContactSheet $previewDir $contactSheet
    }
    $report = [ordered]@{
        spec_path = $SpecPath
        output_pptx = $outFile
        slide_count = $pres.Slides.Count
        preview_contact_sheet = if (Test-Path -LiteralPath $contactSheet) { $contactSheet } else { "" }
        status = "created"
        created_at = (Get-Date).ToString("s")
    }
    $report | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 -LiteralPath $validationReport
    [pscustomobject]$report | Format-List
} finally {
    if ($pres -ne $null) { $pres.Close() }
    if ($ppt -ne $null) { $ppt.Quit() }
    if ($pres -ne $null) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null 2>$null }
    if ($ppt -ne $null) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null 2>$null }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    if (-not [string]::IsNullOrWhiteSpace($savedPptxForCleanup)) {
        Normalize-SavedPptxColors $savedPptxForCleanup
    }
}
