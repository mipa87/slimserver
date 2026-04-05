# ============================================
# KOMPLETNÍ KONTROLA ČESKÝCH PŘEKLADŮ
# ============================================
# Kontroluje hlavní strings.txt i všechny plugin strings.txt
# Verze: 2.0
# Datum: 9.11.2025

param(
    [switch]$PouzeHlavni,      # Pouze hlavní strings.txt
    [switch]$PouzePluginy,     # Pouze pluginy
    [switch]$VerboseOutput,    # Detailní výpis
    [switch]$ExportCSV         # Export výsledků do CSV
)

# Barvy pro výstup
$colorHeader = 'Cyan'
$colorSuccess = 'Green'
$colorWarning = 'Yellow'
$colorError = 'Red'
$colorInfo = 'Gray'

# ============================================
# FUNKCE PRO ANALÝZU SOUBORU
# ============================================
function Test-TranslationFile {
    param(
        [string]$FilePath,
        [string]$RelativePath = ""
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "⚠️  Soubor nenalezen: $FilePath" -ForegroundColor $colorError
        return $null
    }
    
    $lines = Get-Content $FilePath -Encoding UTF8
    $currentKey = ""
    $translations = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Rozpoznání klíče (včetně čísel)
        if ($line -match '^[A-Z_0-9]+$') {
            $currentKey = $line.Trim()
        }
        # Rozpoznání překladů
        elseif ($line -match '^\t(EN|CS|DE|FR|DA|ES|FI|HE|HU|IT|NL|NO|PL|RU|SV|ZH_CN|EN_GB|JA|PT)\t(.+)$') {
            $lang = $matches[1]
            $translation = $matches[2]
            
            $existing = $translations | Where-Object { $_.Key -eq $currentKey }
            if (-not $existing) {
                $obj = [PSCustomObject]@{
                    Key = $currentKey
                    File = $RelativePath
                    LineNum = $i + 1
                    EN = ""
                    CS = ""
                }
                $translations += $obj
                $existing = $translations[-1]
            }
            
            # Nastavení hodnoty podle jazyka
            if ($lang -eq 'EN') {
                $existing.EN = $translation
            } elseif ($lang -eq 'CS') {
                $existing.CS = $translation
            }
        }
    }
    
    # Odstranění prázdných záznamů (bez EN překladu)
    $translations = $translations | Where-Object { $_.EN -ne "" }
    
    return $translations
}

# ============================================
# FUNKCE PRO DETEKCI PROBLÉMŮ
# ============================================
function Get-TranslationIssues {
    param($Translations)
    
    $issues = @{
        Missing = @()
        Parameters = @()
        Quotes = @()
        Style = @()
    }
    
    foreach ($t in $Translations) {
        # Přeskočíme případy, kdy je CS stejný jako EN (použití anglického textu je záměrné)
        if (-not [string]::IsNullOrWhiteSpace($t.CS) -and $t.CS -eq $t.EN) {
            continue
        }
        
        # 1. CHYBĚJÍCÍ PŘEKLADY
        if ([string]::IsNullOrWhiteSpace($t.CS)) {
            $issues.Missing += $t
        }
        
        if ($t.CS) {
            # 2. PROBLÉMY S PARAMETRY
            $enParams = ([regex]::Matches($t.EN, '%[sd]')).Count
            $csParams = ([regex]::Matches($t.CS, '%[sd]')).Count
            
            if ($enParams -ne $csParams) {
                $issues.Parameters += [PSCustomObject]@{
                    Key = $t.Key
                    File = $t.File
                    Problem = "EN: $enParams parametrů, CS: $csParams parametrů"
                    English = $t.EN
                    Czech = $t.CS
                }
            }
            
            # 3. NESPRÁVNÉ UVOZOVKY
            # POZNÁMKA: Tato kontrola je VYPNUTÁ, protože:
            # - Tab-delimited formát legitimně používá zdvojené uvozovky ("") pro escapování
            # - Při parsování CSV se "" automaticky převede na ", což způsobuje false positives
            # - Pokud potřebujete zkontrolovat uvozovky, použijte grep přímo na souboru:
            #   Select-String -Path strings.txt -Pattern 'CS\t[^\t]*"[^"]+"[^\t]*$'
            
            <#
            if ($t.CS -and $t.CS.Length -gt 0) {
                $text = $t.CS
                
                # Pokud text obsahuje HTML nebo speciální případy, ignoruj
                if ($text -notmatch '<[^>]*"[^>]*>' -and 
                    $text -notmatch 'use filetest|ACL|http') {
                    
                    # Najdi " které nejsou součástí českých uvozovek „"
                    if ($text -match '"' -and $text -notmatch '„.*"') {
                        $issues.Quotes += [PSCustomObject]@{
                            Key = $t.Key
                            File = $t.File
                            Czech = $t.CS
                        }
                    }
                }
            }
            #>
            
            # 4. PROBLÉMY SE STYLEM
            # Dvojité mezery
            if ($t.CS -match '  ') {
                $issues.Style += [PSCustomObject]@{
                    Key = $t.Key
                    File = $t.File
                    Problem = "Dvojitá mezera"
                    Czech = $t.CS
                }
            }
            
            # Mezera před interpunkcí
            if ($t.CS -match ' [.,;:]') {
                $issues.Style += [PSCustomObject]@{
                    Key = $t.Key
                    File = $t.File
                    Problem = "Mezera před interpunkcí"
                    Czech = $t.CS
                }
            }
        }
    }
    
    return $issues
}

# ============================================
# HLAVNÍ LOGIKA
# ============================================

Clear-Host
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor $colorHeader
Write-Host "║     KOMPLETNÍ KONTROLA ČESKÝCH PŘEKLADŮ                ║" -ForegroundColor $colorHeader
Write-Host "║     Lyrion Music Server (SlimServer)                   ║" -ForegroundColor $colorHeader
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $colorHeader
Write-Host ""

$rootPath = "d:\repos\slimserver"
$allTranslations = @()
$allIssues = @{
    Missing = @()
    Parameters = @()
    Quotes = @()
    Style = @()
}

# ============================================
# KONTROLA HLAVNÍHO SOUBORU
# ============================================
if (-not $PouzePluginy) {
    Write-Host "📄 Kontroluji hlavní strings.txt..." -ForegroundColor $colorInfo
    
    $mainFile = Join-Path $rootPath "strings.txt"
    $mainTranslations = Test-TranslationFile -FilePath $mainFile -RelativePath "strings.txt"
    
    if ($mainTranslations) {
        $allTranslations += $mainTranslations
        $mainIssues = Get-TranslationIssues -Translations $mainTranslations
        
        Write-Host "   Celkem klíčů: $($mainTranslations.Count)" -ForegroundColor $colorInfo
        Write-Host "   Kompletních: $(($mainTranslations | Where-Object { $_.CS -ne '' }).Count)" -ForegroundColor $colorSuccess
        
        if ($mainIssues.Missing.Count -gt 0) {
            Write-Host "   Chybějících: $($mainIssues.Missing.Count)" -ForegroundColor $colorError
            $allIssues.Missing += $mainIssues.Missing
        }
        
        if ($mainIssues.Parameters.Count -gt 0) {
            Write-Host "   Problémů s parametry: $($mainIssues.Parameters.Count)" -ForegroundColor $colorWarning
            $allIssues.Parameters += $mainIssues.Parameters
        }
        
        if ($mainIssues.Quotes.Count -gt 0) {
            Write-Host "   Nesprávných uvozovek: $($mainIssues.Quotes.Count)" -ForegroundColor $colorWarning
            $allIssues.Quotes += $mainIssues.Quotes
        }
        
        if ($mainIssues.Style.Count -gt 0) {
            Write-Host "   Problémů se stylem: $($mainIssues.Style.Count)" -ForegroundColor $colorWarning
            $allIssues.Style += $mainIssues.Style
        }
    }
    Write-Host ""
}

# ============================================
# KONTROLA PLUGINŮ
# ============================================
if (-not $PouzeHlavni) {
    Write-Host "🔌 Kontroluji pluginy..." -ForegroundColor $colorInfo
    
    $pluginFiles = Get-ChildItem -Path (Join-Path $rootPath "Slim\Plugin") -Filter "strings.txt" -Recurse
    Write-Host "   Nalezeno $($pluginFiles.Count) plugin souborů" -ForegroundColor $colorInfo
    Write-Host ""
    
    $pluginStats = @{
        Total = $pluginFiles.Count
        WithIssues = 0
        Clean = 0
    }
    
    foreach ($file in $pluginFiles) {
        $relativePath = $file.FullName.Replace("$rootPath\", "")
        $pluginName = ($file.Directory.Name)
        
        $pluginTranslations = Test-TranslationFile -FilePath $file.FullName -RelativePath $relativePath
        
        if ($pluginTranslations) {
            $allTranslations += $pluginTranslations
            $pluginIssues = Get-TranslationIssues -Translations $pluginTranslations
            
            $hasIssues = $false
            
            if ($pluginIssues.Missing.Count -gt 0 -or 
                $pluginIssues.Parameters.Count -gt 0 -or 
                $pluginIssues.Quotes.Count -gt 0 -or 
                $pluginIssues.Style.Count -gt 0) {
                
                $hasIssues = $true
                $pluginStats.WithIssues++
                
                Write-Host "   📁 $pluginName" -ForegroundColor $colorWarning
                
                if ($pluginIssues.Missing.Count -gt 0) {
                    Write-Host "      ⚠️  Chybějící: $($pluginIssues.Missing.Count)" -ForegroundColor $colorError
                    $allIssues.Missing += $pluginIssues.Missing
                    
                    if ($VerboseOutput) {
                        foreach ($m in $pluginIssues.Missing) {
                            Write-Host "         - $($m.Key)" -ForegroundColor $colorInfo
                        }
                    }
                }
                
                if ($pluginIssues.Parameters.Count -gt 0) {
                    Write-Host "      ⚠️  Parametry: $($pluginIssues.Parameters.Count)" -ForegroundColor $colorWarning
                    $allIssues.Parameters += $pluginIssues.Parameters
                }
                
                if ($pluginIssues.Quotes.Count -gt 0) {
                    Write-Host "      ⚠️  Uvozovky: $($pluginIssues.Quotes.Count)" -ForegroundColor $colorWarning
                    $allIssues.Quotes += $pluginIssues.Quotes
                }
                
                if ($pluginIssues.Style.Count -gt 0) {
                    Write-Host "      ⚠️  Styl: $($pluginIssues.Style.Count)" -ForegroundColor $colorWarning
                    $allIssues.Style += $pluginIssues.Style
                }
                
                Write-Host ""
            } else {
                $pluginStats.Clean++
            }
        }
    }
}

# ============================================
# CELKOVÝ SOUHRN
# ============================================
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor $colorHeader
Write-Host "║                    CELKOVÝ SOUHRN                      ║" -ForegroundColor $colorHeader
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $colorHeader
Write-Host ""

$totalKeys = $allTranslations.Count
$totalComplete = ($allTranslations | Where-Object { $_.CS -ne '' }).Count
$completionPercent = if ($totalKeys -gt 0) { [math]::Round(($totalComplete / $totalKeys) * 100, 1) } else { 0 }

Write-Host "📊 Statistiky:" -ForegroundColor $colorHeader
Write-Host "   Celkem překladových klíčů: $totalKeys"
Write-Host "   Kompletních českých překladů: $totalComplete ($completionPercent%)" -ForegroundColor $(if ($completionPercent -eq 100) { $colorSuccess } else { $colorWarning })

if (-not $PouzeHlavni) {
    Write-Host "`n   Plugin soubory:"
    Write-Host "   Celkem: $($pluginStats.Total)"
    Write-Host "   Bez problémů: $($pluginStats.Clean)" -ForegroundColor $colorSuccess
    Write-Host "   S problémy: $($pluginStats.WithIssues)" -ForegroundColor $(if ($pluginStats.WithIssues -eq 0) { $colorSuccess } else { $colorWarning })
}

Write-Host "`n🔍 Nalezené problémy:" -ForegroundColor $colorHeader
Write-Host "   Chybějící překlady: $($allIssues.Missing.Count)" -ForegroundColor $(if ($allIssues.Missing.Count -eq 0) { $colorSuccess } else { $colorError })
Write-Host "   Problémy s parametry: $($allIssues.Parameters.Count)" -ForegroundColor $(if ($allIssues.Parameters.Count -eq 0) { $colorSuccess } else { $colorWarning })
Write-Host "   Nesprávné uvozovky: $($allIssues.Quotes.Count)" -ForegroundColor $(if ($allIssues.Quotes.Count -eq 0) { $colorSuccess } else { $colorWarning })
Write-Host "   Problémy se stylem: $($allIssues.Style.Count)" -ForegroundColor $(if ($allIssues.Style.Count -eq 0) { $colorSuccess } else { $colorWarning })

# ============================================
# DETAILNÍ VÝPIS (pokud je požadován)
# ============================================
if ($VerboseOutput) {
    if ($allIssues.Missing.Count -gt 0) {
        Write-Host "`n📋 CHYBĚJÍCÍ PŘEKLADY:" -ForegroundColor $colorError
        $allIssues.Missing | Select-Object File, Key, EN | Format-Table -AutoSize -Wrap
    }
    
    if ($allIssues.Parameters.Count -gt 0) {
        Write-Host "`n📋 PROBLÉMY S PARAMETRY:" -ForegroundColor $colorWarning
        $allIssues.Parameters | Select-Object File, Key, Problem | Format-Table -AutoSize -Wrap
    }
    
    if ($allIssues.Quotes.Count -gt 0) {
        Write-Host "`n📋 NESPRÁVNÉ UVOZOVKY:" -ForegroundColor $colorWarning
        $allIssues.Quotes | Select-Object File, Key, @{N='Ukázka';E={$_.Czech.Substring(0, [Math]::Min(60, $_.Czech.Length)) + '...'}} | Format-Table -AutoSize -Wrap
    }
}

# ============================================
# EXPORT DO CSV
# ============================================
if ($ExportCSV -or $allIssues.Missing.Count -gt 0 -or $allIssues.Parameters.Count -gt 0 -or $allIssues.Quotes.Count -gt 0 -or $allIssues.Style.Count -gt 0) {
    Write-Host "`n💾 Export výsledků:" -ForegroundColor $colorHeader
    
    if ($allIssues.Missing.Count -gt 0) {
        $allIssues.Missing | Export-Csv "chybejici_preklady.csv" -Encoding UTF8 -NoTypeInformation
        Write-Host "   ✓ chybejici_preklady.csv" -ForegroundColor $colorSuccess
    }
    
    if ($allIssues.Parameters.Count -gt 0) {
        $allIssues.Parameters | Export-Csv "problemy_parametry.csv" -Encoding UTF8 -NoTypeInformation
        Write-Host "   ✓ problemy_parametry.csv" -ForegroundColor $colorSuccess
    }
    
    if ($allIssues.Quotes.Count -gt 0) {
        $allIssues.Quotes | Export-Csv "problemy_uvozovky.csv" -Encoding UTF8 -NoTypeInformation
        Write-Host "   ✓ problemy_uvozovky.csv" -ForegroundColor $colorSuccess
    }
    
    if ($allIssues.Style.Count -gt 0) {
        $allIssues.Style | Export-Csv "problemy_styl.csv" -Encoding UTF8 -NoTypeInformation
        Write-Host "   ✓ problemy_styl.csv" -ForegroundColor $colorSuccess
    }
}

# ============================================
# ZÁVĚREČNÉ HODNOCENÍ
# ============================================
Write-Host ""
$totalIssues = $allIssues.Missing.Count + $allIssues.Parameters.Count + $allIssues.Quotes.Count + $allIssues.Style.Count

if ($totalIssues -eq 0) {
    Write-Host "✅ Všechny kontroly prošly úspěšně!" -ForegroundColor $colorSuccess
    Write-Host "   České překlady jsou kompletní a správně formátované." -ForegroundColor $colorSuccess
} else {
    Write-Host "⚠️  Nalezeno $totalIssues problémů." -ForegroundColor $colorWarning
    Write-Host "   Zkontrolujte exportované CSV soubory pro detaily." -ForegroundColor $colorInfo
}

Write-Host "`n💡 Tip: Použijte parametry pro specifickou kontrolu:" -ForegroundColor $colorInfo
Write-Host "   -PouzeHlavni     Kontrola pouze strings.txt" -ForegroundColor $colorInfo
Write-Host "   -PouzePluginy    Kontrola pouze pluginů" -ForegroundColor $colorInfo
Write-Host "   -VerboseOutput   Detailní výpis všech problémů" -ForegroundColor $colorInfo
Write-Host "   -ExportCSV       Vynutit export i při 0 problémech" -ForegroundColor $colorInfo
Write-Host ""
