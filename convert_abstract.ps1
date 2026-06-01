# PowerShell Script to Convert Abstract Markdown to beautiful Word Document (DOCX) using Word COM Object Selection
# Standar Skripsi Indonesia: A4, Margin 4-3-3-3cm, Times New Roman 12pt, Spacing 1.0 (Single), Justified, English Italicized.

$mdPath = "C:\Users\USER\.gemini\antigravity\brain\271748ec-f344-4f7d-bbae-75aa9ba0718a\abstrak_dan_abstract.md"
$docxPath = "d:\apk_edu\Abstrak_dan_Abstract_EduConnect.docx"

if (-not (Test-Path $mdPath)) {
    Write-Error "File Markdown tidak ditemukan di $mdPath"
    exit 1
}

Write-Host "Membuka Microsoft Word..."
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()

Write-Host "Mengatur format halaman skripsi (A4, Left=4cm, Top/Right/Bottom=3cm)..."
# Kertas A4
$doc.PageSetup.PaperSize = 7 # wdPaperA4 is 7
# Margin
$doc.PageSetup.TopMargin = $word.CentimetersToPoints(3.0)
$doc.PageSetup.BottomMargin = $word.CentimetersToPoints(3.0)
$doc.PageSetup.LeftMargin = $word.CentimetersToPoints(4.0)
$doc.PageSetup.RightMargin = $word.CentimetersToPoints(3.0)

# Ambil objek Selection
$selection = $word.Selection

# Set default style of selection (Single spacing for Abstract, Times New Roman, Justified)
$selection.Font.Name = "Times New Roman"
$selection.Font.Size = 12
$selection.ParagraphFormat.LineSpacingRule = 0 # wdLineSpaceSingle is 0
$selection.ParagraphFormat.Alignment = 3 # wdAlignParagraphJustify is 3
$selection.ParagraphFormat.SpaceAfter = 12 # 12pt space after paragraph for spacing

# Fungsi Helper untuk menulis teks berformat inline (bold, italic, code) ke Selection
function Add-FormattedText {
    param(
        [string]$text,
        [boolean]$forceItalic = $false
    )

    $sel = $word.Selection

    # Split markdown bold (**) and italic (*)
    $parts = [regex]::Split($text, '(\*\*.*?\*\*|\*.*?\*)')
    
    foreach ($part in $parts) {
        if ($part.Length -eq 0) { continue }
        
        if ($part.StartsWith("**") -and $part.EndsWith("**")) {
            $sel.Font.Bold = $true
            $sel.Font.Italic = $forceItalic # keep italic if forced
            $sel.Font.Name = "Times New Roman"
            $sel.Font.Size = 12
            $sel.TypeText($part.Substring(2, $part.Length - 4))
        } elseif ($part.StartsWith("*") -and $part.EndsWith("*")) {
            $sel.Font.Bold = $false
            $sel.Font.Italic = $true # italic
            $sel.Font.Name = "Times New Roman"
            $sel.Font.Size = 12
            $sel.TypeText($part.Substring(1, $part.Length - 2))
        } else {
            $sel.Font.Bold = $false
            $sel.Font.Italic = $forceItalic
            $sel.Font.Name = "Times New Roman"
            $sel.Font.Size = 12
            $sel.TypeText($part)
        }
    }
    
    # Reset formatting
    $sel.Font.Bold = $false
    $sel.Font.Italic = $forceItalic
    $sel.Font.Name = "Times New Roman"
    $sel.Font.Size = 12
}

Write-Host "Membaca dan memproses isi berkas abstrak..."
$lines = Get-Content -Path $mdPath -Encoding UTF8

$isEnglishAbstract = $false

foreach ($line in $lines) {
    $lineStripped = $line.Trim()
    
    if ($lineStripped.Length -eq 0) {
        continue
    }
    
    # Abaikan separator horizontal
    if ($lineStripped -eq "---") {
        # Menambahkan page break setelah abstrak Indonesia untuk meletakkan abstract Inggris di halaman berikutnya (jika standard skripsi)
        # Untuk kepraktisan abstrak digabungkan dengan pemisah page break:
        $selection.InsertBreak(7) # wdPageBreak is 7
        $isEnglishAbstract = $true
        continue
    }
    
    # ---------------------------------------------------------
    # PENANGANAN HEADINGS (ABSTRAK / ABSTRACT)
    # ---------------------------------------------------------
    if ($lineStripped.StartsWith("## ")) {
        $headingText = $lineStripped.Substring(3)
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 1 # Center
        $selection.ParagraphFormat.SpaceBefore = 24
        $selection.ParagraphFormat.SpaceAfter = 18
        $selection.ParagraphFormat.LineSpacingRule = 0 # Single space
        
        $selection.Font.Bold = $true
        $selection.Font.Italic = $false
        $selection.Font.Name = "Times New Roman"
        $selection.Font.Size = 12
        $selection.TypeText($headingText.ToUpper())
        
        # Reset selection formatting
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 3 # Justified
        $selection.ParagraphFormat.SpaceBefore = 0
        $selection.ParagraphFormat.SpaceAfter = 12
        $selection.Font.Bold = $false
        $selection.Font.Italic = $isEnglishAbstract
        $selection.Font.Size = 12
        continue
    }
    
    # ---------------------------------------------------------
    # PARAGRAF ABSTRAK ATAU KEYWORDS
    # ---------------------------------------------------------
    $selection.TypeParagraph()
    $selection.ParagraphFormat.Alignment = 3 # Justified
    $selection.ParagraphFormat.LineSpacingRule = 0 # Single Spacing
    $selection.ParagraphFormat.SpaceAfter = 12
    
    # Deteksi Baris Kata Kunci
    if ($lineStripped.StartsWith("**Kata Kunci:**") -or $lineStripped.StartsWith("**Keywords:**")) {
        $selection.ParagraphFormat.SpaceAfter = 24
    }
    
    Add-FormattedText -text $lineStripped -forceItalic $isEnglishAbstract
}

# Bersihkan paragraf kosong berlebih di awal dokumen jika ada
if ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Item(1).Range.Text.Trim().Length -eq 0) {
    $doc.Paragraphs.Item(1).Range.Delete()
}

Write-Host "Menyimpan file Word ke: $docxPath"
$doc.SaveAs([ref]$docxPath)
$doc.Close()
$word.Quit()

Write-Host "Proses Konversi Selesai! File Word sukses dibuat."
