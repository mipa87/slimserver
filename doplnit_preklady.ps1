# Skript pro doplnění chybějících českých překladů
# Zachovává konzistenci a styl, používá EN jako zdroj

$q1 = [char]0x201E  # opening Czech quote „
$q2 = [char]0x201C  # closing Czech quote "

# Slovník pro překlad běžných výrazů
$translations = @{
    # Názvy zařízení - ponechat anglicky
    'Lyrion Music Server' = 'Lyrion Music Server'
    'SLIMP3' = 'SLIMP3'
    'Squeezebox' = 'Squeezebox'
    'Squeezebox2/v3' = 'Squeezebox2/v3'
    'Transporter' = 'Transporter'
    'SoftSqueeze' = 'SoftSqueeze'
    'StereoXL' = 'StereoXL'
    
    # UI elementy
    'Artist Portraits' = 'Portréty umělců'
    "Don't show pictures when browsing artists" = 'Nezobrazovat obrázky při procházení umělců'
    'Show pictures when browsing artists' = 'Zobrazovat obrázky při procházení umělců'
    'Toggle between grid and list view' = 'Přepnout mezi mřížkou a seznamem'
    
    # Základní hudební výrazy
    'Album' = 'Album'
    'EP' = 'EP'
    'Demo' = 'Demo'
    'Demos' = 'Dema'
    'Live Recording' = 'Živý záznam'
    'Live Recordings' = 'Živé záznamy'
    'Mixtape' = 'Mixtape'
    'Mixtapes' = 'Mixtapy'
    'Bonus Albums' = 'Bonusová alba'
    'Collection' = 'Kolekce'
    'Collections' = 'Kolekce'
    'Remix' = 'Remix'
    'Remixes' = 'Remixy'
    'Compilation' = 'Kompilace'
    'Compilations' = 'Kompilace'
    'Bootleg' = 'Bootleg'
    'Bootlegs' = 'Bootlegy'
    'Soundtrack' = 'Soundtrack'
    'Soundtracks' = 'Soundtracky'
    'Spokenword' = 'Mluvené slovo'
    'Interview' = 'Rozhovor'
    'Interviews' = 'Rozhovory'
    'Audiobook' = 'Audiokniha'
    'Audiobooks' = 'Audioknihy'
    
    # Audio formáty - ponechat anglicky
    "Monkey's Audio" = "Monkey's Audio"
    'MP3' = 'MP3'
    'MP2' = 'MP2'
    'Apple Lossless' = 'Apple Lossless'
    'Apple Lossless leading audio' = 'Apple Lossless úvodní audio'
    'AAC' = 'AAC'
    'MPEG-4' = 'MPEG-4'
    'MPEG-4 leading audio' = 'MPEG-4 úvodní audio'
    'MPEG-4 SLS / HD-AAC' = 'MPEG-4 SLS / HD-AAC'
    'Musepack' = 'Musepack'
    'WavPack' = 'WavPack'
    'WavPack DSD' = 'WavPack DSD'
    'Shorten' = 'Shorten'
    'Windows Media' = 'Windows Media'
    'WMA Lossless' = 'WMA Lossless'
    'WMA Pro' = 'WMA Pro'
    'Microsoft Media Server' = 'Microsoft Media Server'
    'AIFF' = 'AIFF'
    'WAV' = 'WAV'
    'FLAC' = 'FLAC'
    'PCM' = 'PCM'
    'Ogg Vorbis' = 'Ogg Vorbis'
    'Ogg FLAC' = 'Ogg FLAC'
    'DFF' = 'DFF'
    'DSF' = 'DSF'
    'Opus' = 'Opus'
    
    # Technické výrazy
    ',' = ','
    'Server' = 'Server'
    'Model' = 'Model'
    'Firmware' = 'Firmware'
    'Port' = 'Port'
    'MAC' = 'MAC'
    ':' = ':'
    'S/PDIF' = 'S/PDIF'
    'AES/EBU' = 'AES/EBU'
    'Subwoofer' = 'Subwoofer'
    'Web Sockets Client Information' = 'Informace o klientovi Web Sockets'
    'Looking for contributor pictures' = 'Hledání obrázků přispěvatelů'
    'Check out changes on Github...' = 'Zobrazit změny na GitHubu...'
    
    # Plugin názvy - ponechat anglicky nebo lehce lokalizovat
    'AudioAddict' = 'AudioAddict'
    'Audioscrobbler' = 'Audioscrobbler'
    'Last.fm' = 'Last.fm'
    'ListenBrainz' = 'ListenBrainz'
    'ListenBrainz API (Experimental)' = 'ListenBrainz API (experimentální)'
    'Successfully validated your account information.' = 'Informace o účtu byly úspěšně ověřeny.'
    'There was an error validating your account information. Please try again later. (%s)' = 'Při ověřování informací o účtu došlo k chybě. Zkuste to prosím později. (%s)'
    'ClassicalRadio.com' = 'ClassicalRadio.com'
    'DI.FM - Digitally Imported' = 'DI.FM - Digitally Imported'
    'JAZZRADIO.com' = 'JAZZRADIO.com'
    'Find Artwork for Radio Stations' = 'Najít obrázky pro rádiové stanice'
    "Try to find artwork for tracks played from radio stations which don't provide their own artwork. It's based on the…" = "Pokusí se najít obrázky pro skladby přehrávané z rádiových stanic, které neposkytují vlastní obrázky. Je založeno na…"
    "Don't search for title artwork on this station" = 'Nehledat obrázky skladeb na této stanici'
    'Search for title artwork if possible' = 'Hledat obrázky skladeb, pokud je to možné'
    'Will no longer search for artwork' = 'Již nebude hledat obrázky'
    'Will search for track artwork' = 'Bude hledat obrázky skladeb'
    "Don't look up artwork for the following radio stations (one URL per line):" = 'Nehledat obrázky pro následující rádiové stanice (jedna URL na řádek):'
    'RadioTunes.com' = 'RadioTunes.com'
    'ROCKRADIO.COM' = 'ROCKRADIO.COM'
    'NEW YEAR !' = 'NOVÝ ROK!'
    'Zen Radio' = 'Zen Radio'
}

# Speciální překlad pro JIVE_ALLOWEDCHARS (ponechat stejné)
$jiveAllowedChars = ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+{}|:\"''<>?-=,./~`[];0123456789'
$jiveAllowedCharsNoCaps = ' abcdefghijklmnopqrstuvwxyz!@#$%^&*()_+{}|:\"''<>?-=,./~`[];0123456789'

# Načtení chybějících překladů
$missing = Import-Csv "chybejici_preklady.csv" -Encoding UTF8

Write-Host "`n=== DOPLŇOVÁNÍ ČESKÝCH PŘEKLADŮ ===" -ForegroundColor Cyan
Write-Host "Celkem chybějících: $($missing.Count)`n" -ForegroundColor Yellow

$grouped = $missing | Group-Object -Property File

foreach ($group in $grouped) {
    # Oprava cesty - pokud už obsahuje plnou cestu, nepoužívat Join-Path
    if ($group.Name -match '^[A-Z]:\\') {
        $filePath = $group.Name
    } else {
        $filePath = Join-Path "d:\repos\slimserver" $group.Name
    }
    Write-Host "📁 $($group.Name)" -ForegroundColor Green
    Write-Host "   Chybějících: $($group.Count)" -ForegroundColor Gray
    
    $content = Get-Content $filePath -Encoding UTF8
    $modified = $false
    
    foreach ($item in $group.Group) {
        $key = $item.Key
        $enText = $item.EN
        
        # Najít překlad
        $csText = $translations[$enText]
        if (-not $csText) {
            # Pokud není v slovníku, použít anglický text
            $csText = $enText
        }
        
        # Speciální případy
        if ($key -eq 'JIVE_ALLOWEDCHARS_WITHCAPS') {
            $csText = $jiveAllowedChars
        }
        elseif ($key -eq 'JIVE_ALLOWEDCHARS_NOCAPS') {
            $csText = $jiveAllowedCharsNoCaps
        }
        
        # Najít pozici klíče v souboru
        $keyIndex = -1
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -eq $key) {
                $keyIndex = $i
                break
            }
        }
        
        if ($keyIndex -ge 0) {
            # Najít řádek s EN překladem
            $enIndex = -1
            for ($i = $keyIndex + 1; $i -lt $content.Count; $i++) {
                if ($content[$i] -match '^\tEN\t') {
                    $enIndex = $i
                    break
                }
                # Pokud narazíme na další klíč, přestat hledat
                if ($content[$i] -match '^[A-Z_0-9]+$') {
                    break
                }
            }
            
            if ($enIndex -ge 0) {
                # Vložit CS překlad za EN
                $newLine = "`tCS`t$csText"
                $content = @($content[0..$enIndex]) + @($newLine) + @($content[($enIndex+1)..($content.Count-1)])
                $modified = $true
                Write-Host "   + $key" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($modified) {
        # Uložit soubor
        $content | Set-Content $filePath -Encoding UTF8
        Write-Host "   ✓ Uloženo" -ForegroundColor Green
    }
    
    Write-Host ""
}

Write-Host "✅ Hotovo!" -ForegroundColor Green
Write-Host "`n💡 Spusťte znovu kontrolu: .\kontrola_prekladu.ps1" -ForegroundColor Cyan
