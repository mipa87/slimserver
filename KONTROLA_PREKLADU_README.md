# Kontrola českých překladů - Dokumentace

## 📋 Přehled

Sjednocený PowerShell skript pro komplexní kontrolu českých překladů v Lyrion Music Server (SlimServer).

## 🚀 Použití

### Základní kontrola (vše)
```powershell
.\kontrola_prekladu.ps1
```

### Specifické kontroly

**Pouze hlavní strings.txt:**
```powershell
.\kontrola_prekladu.ps1 -PouzeHlavni
```

**Pouze plugin soubory:**
```powershell
.\kontrola_prekladu.ps1 -PouzePluginy
```

**S detailním výpisem:**
```powershell
.\kontrola_prekladu.ps1 -VerboseOutput
```

**S exportem do CSV:**
```powershell
.\kontrola_prekladu.ps1 -ExportCSV
```

**Kombinace parametrů:**
```powershell
.\kontrola_prekladu.ps1 -PouzePluginy -VerboseOutput
```

## 🔍 Co skript kontroluje

### 1. Chybějící překlady
- Detekuje klíče, které mají anglický překlad (EN), ale chybí český (CS)
- Podporuje klíče s čísly (např. `SETUP_WORKSSCAN_1`)
- **Automaticky ignoruje** případy, kdy je český překlad záměrně shodný s anglickým textem

### 2. Problémy s parametry
- Kontroluje shodu počtu formátovacích parametrů `%s` a `%d`
- Upozorní, pokud EN má 2 parametry, ale CS pouze 1

### 3. Nesprávné uvozovky
- Detekuje anglické uvozovky `" "` v českém textu
- Správné české uvozovky jsou: `„ "`
- Ignoruje HTML tagy a speciální případy

### 4. Problémy se stylem
- Dvojité mezery
- Mezery před interpunkcí (tečka, čárka, středník, dvojtečka)

## 📊 Výstup

### Konzolový výpis

```
╔════════════════════════════════════════════════════════╗
║     KOMPLETNÍ KONTROLA ČESKÝCH PŘEKLADŮ               ║
║     Lyrion Music Server (SlimServer)                  ║
╚════════════════════════════════════════════════════════╝

📄 Kontroluji hlavní strings.txt...
   Celkem klíčů: 1571
   Kompletních: 1571

🔌 Kontroluji pluginy...
   Nalezeno 46 plugin souborů

╔════════════════════════════════════════════════════════╗
║                    CELKOVÝ SOUHRN                      ║
╚════════════════════════════════════════════════════════╝

📊 Statistiky:
   Celkem překladových klíčů: 1800
   Kompletních českých překladů: 1795 (99.7%)

   Plugin soubory:
   Celkem: 46
   Bez problémů: 43
   S problémy: 3

🔍 Nalezené problémy:
   Chybějící překlady: 5
   Problémy s parametry: 0
   Nesprávné uvozovky: 2
   Problémy se stylem: 1
```

### Exportované CSV soubory

Při nalezení problémů automaticky vytvoří:

- **chybejici_preklady.csv** - Seznam chybějících českých překladů
- **problemy_parametry.csv** - Nesoulad v počtu parametrů
- **problemy_uvozovky.csv** - Anglické uvozovky v českém textu
- **problemy_styl.csv** - Formátovací problémy

## 📝 Příklady problémů

### Chybějící překlad
```
Key: PLUGIN_EXAMPLE_NAME
EN:  Example Plugin
CS:  [prázdné]
```

### Ignorované případy (CS = EN)
Pokud je český překlad záměrně stejný jako anglický, skript to nehlásí jako chybějící:
```
Key: USB
EN:  USB
CS:  USB
     ^^^ ignorováno - mezinárodní zkratka, která se nepřekládá
```

Toto je užitečné pro:
- Technické zkratky (USB, HTTP, FLAC)
- Vlastní názvy (Spotify, YouTube)
- Číselné hodnoty nebo kódy

### Problém s parametry
```
Key: SETUP_MESSAGE
EN:  Found %s items in %s folders
CS:  Nalezeno %s položek
Problem: EN: 2 parametry, CS: 1 parametr
```

### Nesprávné uvozovky
```
Key: SETUP_INFO
CS:  Použijte "Nový režim"
     ^^^^^^^^^^^^^^^^^^ - mělo by být „Nový režim"
```

### Problém se stylem
```
Key: MENU_OPTION
CS:  Možnost  číslo  1
            ^^ dvojitá mezera
```

## 🔧 Technické detaily

### Podporované jazyky
Skript rozpoznává tyto jazykové kódy:
- EN, CS, DE, FR, DA, ES, FI, HE, HU, IT, NL, NO, PL, RU, SV
- ZH_CN, EN_GB, JA, PT

### Formát souborů
- Kódování: **UTF-8**
- Formát klíčů: `^[A-Z_0-9]+$`
- Formát překladů: `\t[LANG]\t[text]`

### Ignorované případy pro uvozovky
- HTML tagy: `<a href="...">` ✓
- Speciální kódy: `use filetest`, `ACL` ✓
- HTTP odkazy ✓

## 📦 Migrace ze starých skriptů

Tento skript **nahrazuje** následující původní skripty:

1. ~~`check_translations.ps1`~~ → použij `kontrola_prekladu.ps1 -PouzeHlavni`
2. ~~`analyze_all_translations.ps1`~~ → použij `kontrola_prekladu.ps1 -VerboseOutput`
3. ~~`check_all_plugins.ps1`~~ → použij `kontrola_prekladu.ps1 -PouzePluginy`

## 💡 Tipy

**Rychlá kontrola před commitem:**
```powershell
.\kontrola_prekladu.ps1
```

**Hledám konkrétní problém v pluginech:**
```powershell
.\kontrola_prekladu.ps1 -PouzePluginy -VerboseOutput
```

**Chci exportovat i když není problém:**
```powershell
.\kontrola_prekladu.ps1 -ExportCSV
```

## 🐛 Řešení problémů

**Q: Skript hlásí uvozovky i když jsou české**  
A: České uvozovky `„"` obsahují znak `"` (pravá uvozovka), který skript detekuje. Zkontrolujte CSV - pokud vidíte `„text"`, je to v pořádku (false positive).

**Q: Skript nevidí můj nový plugin**  
A: Zkontrolujte, že soubor se jmenuje přesně `strings.txt` a je v `Slim\Plugin\[NázevPluginu]\strings.txt`

**Q: Chci ignorovat konkrétní upozornění**  
A: Upravte funkci `Get-TranslationIssues` v sekci kontroly stylu/uvozovek

## 📅 Historie verzí

### Verze 2.0 (9.11.2025)
- ✅ Sjednocení 3 skriptů do jednoho
- ✅ Přidány parametry pro flexibilní použití
- ✅ Lepší vizualizace výstupu
- ✅ Podpora klíčů s čísly
- ✅ Automatický export CSV

### Verze 1.x (staré skripty)
- `check_translations.ps1` - Základní kontrola
- `analyze_all_translations.ps1` - Detailní analýza
- `check_all_plugins.ps1` - Kontrola pluginů

## 🤝 Přispívání

Pokud najdete problém nebo máte nápad na vylepšení:
1. Testujte na kopii souborů
2. Dokumentujte změny
3. Sdílejte zpětnou vazbu

## 📄 Licence

Stejná jako Lyrion Music Server projekt.
