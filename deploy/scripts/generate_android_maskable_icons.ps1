# Android maskable PWA icons from source PNG (uniform scale only, no recolor).
param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [int[]]$Sizes = @(512, 192)
)

Add-Type -AssemblyName System.Drawing

function New-MaskableIcon {
    param([string]$Source, [int]$Size, [string]$Dest)

    $srcBmp = [System.Drawing.Bitmap]::FromFile($Source)
    try {
        # Background from bottom-center pixel (dark navy from the artwork).
        $bgColor = $srcBmp.GetPixel([int]($srcBmp.Width / 2), $srcBmp.Height - 8)

        $canvas = New-Object System.Drawing.Bitmap $Size, $Size
        $g = [System.Drawing.Graphics]::FromImage($canvas)
        try {
            $g.Clear($bgColor)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            # Maskable safe zone ~80% — scale artwork to 76% canvas (same pixels, no edits).
            $target = [int]($Size * 0.76)
            $ratio = [Math]::Min($target / $srcBmp.Width, $target / $srcBmp.Height)
            $w = [int]($srcBmp.Width * $ratio)
            $h = [int]($srcBmp.Height * $ratio)
            $x = [int](($Size - $w) / 2)
            $y = [int](($Size - $h) / 2)
            $g.DrawImage($srcBmp, $x, $y, $w, $h)
        } finally {
            $g.Dispose()
        }

        $canvas.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
        $canvas.Dispose()
    } finally {
        $srcBmp.Dispose()
    }
}

if (-not (Test-Path $SourcePath)) { throw "Source not found: $SourcePath" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

foreach ($s in $Sizes) {
    $dest = Join-Path $OutDir "Icon-maskable-$s.png"
    New-MaskableIcon -Source $SourcePath -Size $s -Dest $dest
    Write-Host "OK $dest"
}
