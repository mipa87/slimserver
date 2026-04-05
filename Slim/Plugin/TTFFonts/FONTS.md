# Font Licenses and Recommendations for TTFFonts Plugin

## Included Fonts and Their Licenses

### Noto Sans
- **License:** SIL Open Font License 1.1
- **Authors:** The Noto Project Authors
- **License file:** Noto Fonts License.txt
- **Source:** https://fonts.google.com/noto/specimen/Noto+Sans

### DejaVu Sans
- **License:** Bitstream Vera License (with DejaVu public domain changes)
- **Authors:** Bitstream, Inc. / DejaVu contributors
- **License file:** DejaVu Fonts License.txt
- **Source:** https://dejavu-fonts.github.io/

### Bruno Ace
- **License:** SIL Open Font License 1.1
- **Authors:** Astigmatic
- **Source:** https://fonts.google.com/specimen/Bruno+Ace

### Better VCR
- **License:** SIL Open Font License 1.1
- **Authors:** Typodermic Fonts
- **Source:** https://fonts.google.com/specimen/Better+VCR

### Tomorrow
- **License:** SIL Open Font License 1.1
- **Authors:** Jovanny Lemonad
- **Source:** https://fonts.google.com/specimen/Tomorrow


## Recommended Additional Fonts for Small LCD Displays

### IBM Plex Mono
- **License:** SIL Open Font License 1.1
- **Source:** https://fonts.google.com/specimen/IBM+Plex+Mono
- **Notes:** Monospaced, excellent legibility at 9–32 px, optimized for code and UI.

### Fira Mono
- **License:** SIL Open Font License 1.1
- **Source:** https://fonts.google.com/specimen/Fira+Mono
- **Notes:** Monospaced, designed for clarity at small sizes.

### Roboto Mono
- **License:** SIL Open Font License 1.1
- **Source:** https://fonts.google.com/specimen/Roboto+Mono
- **Notes:** Modern, monospaced, good for technical displays.

### JetBrains Mono
- **License:** SIL Open Font License 1.1
- **Source:** https://www.jetbrains.com/lp/mono/
- **Notes:** Designed for code, optimized for small sizes, monospaced.

### Source Code Pro
- **License:** SIL Open Font License 1.1
- **Source:** https://fonts.google.com/specimen/Source+Code+Pro
- **Notes:** Adobe, monospaced, very readable.

### Unifont
- **License:** GNU GPL v2+ with font exception
- **Source:** https://unifoundry.com/unifont/index.html
- **Notes:** Bitmap font, covers nearly all Unicode, designed for 8–16 px, ideal for extreme small sizes.


## Example ttfmetrics.conf Entries for New Fonts

[ttf:IBMPlexMono-Regular.ttf]
standard.1  7   8
standard.2  13  28
# ... add more mappings as needed

[ttf:unifont.ttf]
standard.1  8   8
standard.2  16  16
# ... add more mappings as needed


## How to Add New Fonts
- Download font files from the official sources above.
- Place the .ttf files into the Graphics or plugin Graphics directory.
- Add appropriate entries to ttfmetrics.conf as shown above.
- Ensure the license file is included in the plugin or distribution.

---
For full license texts, see the respective .txt files in this directory.
