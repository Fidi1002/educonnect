# PowerShell Script to Convert Bab 4 Markdown to beautiful Word Document (DOCX) using Word COM Object Selection
# Standar Skripsi Indonesia: A4, Margin 4-3-3-3cm, Times New Roman 12pt, Spacing 1.5, Justified, Table Grid formal.

$mdPath = "C:\Users\USER\.gemini\antigravity\brain\271748ec-f344-4f7d-bbae-75aa9ba0718a\bab_4_hasil_dan_pembahasan.md"
$docxPath = "d:\apk_edu\BAB_IV_Hasil_dan_Pembahasan_EduConnect.docx"

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
        [string]$text,
        [boolean]$isCode = $false
    )

    $sel = $word.Selection

    if ($isCode) {
        $sel.Font.Name = "Consolas"
        $sel.Font.Size = 9.5
        $sel.Font.Bold = $false
        $sel.Font.Italic = $false
        $sel.TypeText($text)
        return
    }

    # Split markdown bold (**), italic (*), and inline code (`)
    $parts = [regex]::Split($text, '(\*\*.*?\*\*|\*.*?\*|`.*?`)')
    
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
        } elseif ($part.StartsWith('`') -and $part.EndsWith('`')) {
            $sel.Font.Bold = $false
            $sel.Font.Italic = $false
            $sel.Font.Name = "Consolas"
            $sel.Font.Size = 10
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

$inCodeBlock = $false
$codeContent = @()

$inTable = $false
$tableRows = @()

foreach ($line in $lines) {
    $lineStripped = $line.Trim()
    
    # ---------------------------------------------------------
    # PENANGANAN CODE BLOCK (```)
    # ---------------------------------------------------------
    if ($lineStripped.StartsWith('```')) {
        if ($inCodeBlock) {
            $inCodeBlock = $false
            $codeText = $codeContent -join [Environment]::NewLine
            
            # Pindahkan cursor ke paragraf baru
            $selection.TypeParagraph()
            $selection.ParagraphFormat.Alignment = 0 # Left alignment
            
            # Membuat container tabel berkolom 1 dengan warna abu-abu lembut
            $tbl = $doc.Tables.Add($selection.Range, 1, 1)
            $tbl.Style = "Table Grid"
            $cell = $tbl.Cell(1, 1)
            $cell.Shading.BackgroundPatternColor = 15921906 # Light Gray (hex #F1F5F9 equivalent)
            $cell.TopPadding = 6
            $cell.BottomPadding = 6
            $cell.LeftPadding = 8
            $cell.RightPadding = 8
            
            $cp = $cell.Range.Paragraphs.Item(1)
            $cp.Format.LineSpacingRule = 0 # Single Spacing
            $cp.Format.SpaceAfter = 0
            
            # Tulis text ke cell range
            $cellRange = $cell.Range
            # collapse to start to avoid overwriting cell marker
            $cellRange.Collapse(1) 
            
            $cellRange.Font.Name = "Consolas"
            $cellRange.Font.Size = 9.5
            $cellRange.Font.Bold = $false
            $cellRange.Font.Italic = $false
            $cellRange.Text = $codeText
            
            # Reset
            $codeContent = @()
            
            # Pindahkan selection ke setelah tabel
            $selection.EndOf(6) # wdStory is 6, move cursor to the very end of the document
            $selection.TypeParagraph()
            $selection.ParagraphFormat.Alignment = 3 # Justify
            $selection.ParagraphFormat.SpaceBefore = 6
            $selection.ParagraphFormat.SpaceAfter = 6
        } else {
            $inCodeBlock = $true
        }
        continue
    }
    
    if ($inCodeBlock) {
        $codeContent += $line
        continue
    }
    
    # ---------------------------------------------------------
    # PENANGANAN TABLE ROWS (|)
    # ---------------------------------------------------------
    if ($lineStripped.StartsWith("|")) {
        # Abaikan baris separator |---|---|
        if ($lineStripped -match '^\|[\s\-\|]+$') {
            continue
        }
        
        # Ekstrak data kolom
        $cols = $lineStripped.Split('|') | ForEach-Object { $_.Trim() }
        $cols = $cols[1..($cols.Length-2)]
        
        $tableRows += ,$cols
        $inTable = $true
        continue
    } else {
        if ($inTable) {
            $inTable = $false
            if ($tableRows.Count -gt 0) {
                $rowCount = $tableRows.Count
                $colCount = $tableRows[0].Count
                
                $selection.TypeParagraph()
                $tbl = $doc.Tables.Add($selection.Range, $rowCount, $colCount)
                $tbl.Style = "Table Grid"
                
                for ($r = 1; $r -le $rowCount; $r++) {
                    $row = $tbl.Rows.Item($r)
                    $rowData = $tableRows[$r-1]
                    
                    for ($c = 1; $c -le $colCount; $c++) {
                        $cell = $tbl.Cell($r, $c)
                        $cell.TopPadding = 5
                        $cell.BottomPadding = 5
                        $cell.LeftPadding = 6
                        $cell.RightPadding = 6
                        
                        $cellValue = $rowData[$c-1]
                        $cp = $cell.Range.Paragraphs.Item(1)
                        $cp.Format.LineSpacingRule = 0 # Single space
                        $cp.Format.SpaceAfter = 2
                        
                        # Header Row Styling (Tema Ungu EduConnect)
                        if ($r -eq 1) {
                            $cell.Shading.BackgroundPatternColor = 7214859 # Deep Purple #4B176E
                            $run = $cp.Range
                            $run.Collapse(1)
                            $run.Text = $cellValue
                            $run.Font.Bold = $true
                            $run.Font.ColorIndex = 9 # White
                            $run.Font.Name = "Times New Roman"
                            $run.Font.Size = 10
                            $cp.Format.Alignment = 1 # Center header
                        } else {
                            # Tulis teks biasa dengan inline formatting ke range cell
                            $run = $cell.Range
                            $run.Collapse(1)
                            # Gunakan sub-function khusus agar inline formatting jalan
                            $parts = [regex]::Split($cellValue, '(\*\*.*?\*\*|\*.*?\*|`.*?`)')
                            foreach ($part in $parts) {
                                if ($part.Length -eq 0) { continue }
                                $runRange = $doc.Range($run.End, $run.End)
                                if ($part.StartsWith("**") -and $part.EndsWith("**")) {
                                    $runRange.Text = $part.Substring(2, $part.Length - 4)
                                    $runRange.Font.Bold = $true
                                    $runRange.Font.Italic = $false
                                    $runRange.Font.Name = "Times New Roman"
                                    $runRange.Font.Size = 10
                                } elseif ($part.StartsWith("*") -and $part.EndsWith("*")) {
                                    $runRange.Text = $part.Substring(1, $part.Length - 2)
                                    $runRange.Font.Bold = $false
                                    $runRange.Font.Italic = $true
                                    $runRange.Font.Name = "Times New Roman"
                                    $runRange.Font.Size = 10
                                } elseif ($part.StartsWith('`') -and $part.EndsWith('`')) {
                                    $runRange.Text = $part.Substring(1, $part.Length - 2)
                                    $runRange.Font.Bold = $false
                                    $runRange.Font.Italic = $false
                                    $runRange.Font.Name = "Consolas"
                                    $runRange.Font.Size = 9.5
                                } else {
                                    $runRange.Text = $part
                                    $runRange.Font.Bold = $false
                                    $runRange.Font.Italic = $false
                                    $runRange.Font.Name = "Times New Roman"
                                    $runRange.Font.Size = 10
                                }
                                $run.SetRange($run.Start, $runRange.End)
                            }
                        }
                    }
                }
                
                # Pindahkan selection ke setelah tabel
                $selection.EndOf(6)
                $selection.TypeParagraph()
                $selection.ParagraphFormat.Alignment = 3
                $selection.ParagraphFormat.SpaceBefore = 6
                $selection.ParagraphFormat.SpaceAfter = 6
            }
            $tableRows = @()
        }
    }
    
    if ($lineStripped.Length -eq 0) {
        continue
    }
    
    # ---------------------------------------------------------
    # PENANGANAN HEADINGS
    # ---------------------------------------------------------
    # H1 (BAB Title) - Contoh: # BAB IV
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
    
    # H2 (Sub-bab Utama) - Contoh: ## C. Hasil Implementasi ...
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
    
    # H3 (Sub-sub-bab) - Contoh: ### 1. Hasil Implementasi Sistem
    if ($lineStripped.StartsWith("### ")) {
        $headingText = $lineStripped.Substring(4)
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 0 # Left
        $selection.ParagraphFormat.SpaceBefore = 14
        $selection.ParagraphFormat.SpaceAfter = 6
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
    
    # H4 (Sub-sub-sub-bab) - Contoh: #### a. Halaman Login dan Registrasi
    if ($lineStripped.StartsWith("#### ")) {
        $headingText = $lineStripped.Substring(5)
        $selection.TypeParagraph()
        $selection.ParagraphFormat.Alignment = 0 # Left
        $selection.ParagraphFormat.SpaceBefore = 10
        $selection.ParagraphFormat.SpaceAfter = 4
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
        $selection.ParagraphFormat.LeftIndent = $word.CentimetersToPoints(0.6)
        
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
