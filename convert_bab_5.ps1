# PowerShell Script to Convert Bab 5 Markdown to beautiful Word Document (DOCX) using Word COM Object Selection
# Standar Skripsi Indonesia: A4, Margin 4-3-3-3cm, Times New Roman 12pt, Spacing 1.5, Justified.

$mdPath = "C:\Users\USER\.gemini\antigravity\brain\271748ec-f344-4f7d-bbae-75aa9ba0718a\bab_5_kesimpulan_dan_saran.md"
$docxPath = "d:\apk_edu\BAB_V_Kesimpulan_dan_Saran_EduConnect.docx"

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

# Set default style of selection
$selection.Font.Name = "Times New Roman"
$selection.Font.Size = 12
$selection.ParagraphFormat.LineSpacingRule = 5 # wdLineSpace1pt5 is 5
$selection.ParagraphFormat.Alignment = 3 # wdAlignParagraphJustify is 3
$selection.ParagraphFormat.SpaceAfter = 6 # 6pt

# Fungsi Helper untuk menulis teks berformat inline (bold, italic, code) ke Selection
function Add-FormattedText {
    param(
        [string]$text
    )

    $sel = $word.Selection

    # Split markdown bold (**) and italic (*)
    $parts = [regex]::Split($text, '(\*\*.*?\*\*|\*.*?\*)')
    
    foreach ($part in $parts) {
        if ($part.Length -eq 0) { continue }
        
        if ($part.StartsWith("**") -and $part.EndsWith("**")) {
            $sel.Font.Bold = $true
            $sel.Font.Italic = $false
            $sel.Font.Name = "Times New Roman"
            $sel.Font.Size = 12
            $sel.TypeText($part.Substring(2, $part.Length - 4))
        } elseif ($part.StartsWith("*") -and $part.EndsWith("*")) {
            $sel.Font.Bold = $false
            $sel.Font.Italic = $true
            $sel.Font.Name = "Times New Roman"
            $sel.Font.Size = 12
            $sel.TypeText($part.Substring(1, $part.Length - 2))
        } else {
            $sel.Font.Bold = $false
            $sel.Font.Italic = $false
            $sel.Font.Name = "Times New Roman"
            $sel.Font.Size = 12
            $sel.TypeText($part)
        }
    }
    
    # Reset formatting to normal body text
    $sel.Font.Bold = $false
    $sel.Font.Italic = $false
    $sel.Font.Name = "Times New Roman"
    $sel.Font.Size = 12
}

Write-Host "Membaca dan memproses isi berkas skripsi..."
$lines = Get-Content -Path $mdPath -Encoding UTF8

foreach ($line in $lines) {
    $lineStripped = $line.Trim()
    
    if ($lineStripped.Length -eq 0) {
        continue
    }
    
    # ---------------------------------------------------------
    # PENANGANAN HEADINGS
    # ---------------------------------------------------------
    # H1 (BAB Title) - Contoh: # BAB V
    if ($lineStripped.StartsWith("# ")) {
        $headingText = $lineStripped.Substring(2)
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 1 # Center
        $selection.ParagraphFormat.SpaceBefore = 12
        $selection.ParagraphFormat.SpaceAfter = 12
        $selection.ParagraphFormat.LineSpacingRule = 5
        
        $selection.Font.Bold = $true
        $selection.Font.Name = "Times New Roman"
        $selection.Font.Size = 14
        $selection.TypeText($headingText.ToUpper())
        
        # Reset selection formatting
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 3 # Justified
        $selection.ParagraphFormat.SpaceBefore = 0
        $selection.ParagraphFormat.SpaceAfter = 6
        $selection.Font.Bold = $false
        $selection.Font.Size = 12
        continue
    }
    
    # H2 (Sub-bab Utama) - Contoh: ## A. Kesimpulan
    if ($lineStripped.StartsWith("## ")) {
        $headingText = $lineStripped.Substring(3)
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 0 # Left
        $selection.ParagraphFormat.SpaceBefore = 18
        $selection.ParagraphFormat.SpaceAfter = 12
        $selection.ParagraphFormat.KeepWithNext = $true
        
        $selection.Font.Bold = $true
        $selection.Font.Name = "Times New Roman"
        $selection.Font.Size = 12
        $selection.TypeText($headingText)
        
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 3 # Justify
        $selection.ParagraphFormat.SpaceBefore = 0
        $selection.ParagraphFormat.SpaceAfter = 6
        $selection.Font.Bold = $false
        $selection.ParagraphFormat.KeepWithNext = $false
        continue
    }
    
    # ---------------------------------------------------------
    # PENANGANAN LISTS
    # ---------------------------------------------------------
    # Bullet list (* item)
    if ($lineStripped.StartsWith("* ")) {
        $listText = $lineStripped.Substring(2)
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 3
        $selection.ParagraphFormat.LineSpacingRule = 5
        $selection.ParagraphFormat.SpaceAfter = 4
        $selection.ParagraphFormat.LeftIndent = $word.CentimetersToPoints(0.6) # Indentasi bullet
        
        $selection.Font.Bold = $true
        $selection.Font.Name = "Times New Roman"
        $selection.Font.Size = 12
        $selection.TypeText("• ")
        
        Add-FormattedText -text $listText
        
        # Reset indentasi
        $selection.ParagraphFormat.LeftIndent = 0
        continue
    }
    
    # Numbered list (1. item)
    if ($lineStripped -match '^(\d+)\.\s(.*)$') {
        $num = $Matches[1]
        $listText = $Matches[2]
        
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 3
        $selection.ParagraphFormat.LineSpacingRule = 5
        $selection.ParagraphFormat.SpaceAfter = 4
        $selection.ParagraphFormat.LeftIndent = $word.CentimetersToPoints(0.6)
        
        $selection.Font.Bold = $false
        $selection.Font.Name = "Times New Roman"
        $selection.Font.Size = 12
        $selection.TypeText("$num. ")
        
        Add-FormattedText -text $listText
        
        # Reset indentasi
        $selection.ParagraphFormat.LeftIndent = 0
        continue
    }
    
    # ---------------------------------------------------------
    # PARAGRAF STANDAR (JUSTIFIED, TIMES NEW ROMAN 12pt, 1.5 SPACING)
    # ---------------------------------------------------------
    $selection.TypeParagraph()
    $selection.ParagraphFormat.Alignment = 3 # Justified
    $selection.ParagraphFormat.LineSpacingRule = 5 # 1.5 Spacing
    $selection.ParagraphFormat.SpaceAfter = 6
    
    Add-FormattedText -text $lineStripped
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
