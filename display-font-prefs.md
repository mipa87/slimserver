# Display Font Preferences by Player Type

Reference document for `Slim::Display::*` class hierarchy, per-player font defaults,
and the font selection logic used by the web UI.

---

## 1. Player → Display Class Mapping

Assigned in `Slim/Networking/Slimproto.pm` based on the `deviceid` field in the HELO frame.

| Player / Device                  | DeviceID                           | Player Class                    | Display Class                     | Display Type    | Resolution        |
| -------------------------------- | ---------------------------------- | ------------------------------- | --------------------------------- | --------------- | ----------------- |
| SLIMP3                           | `slimp3`                           | `Slim::Player::SLIMP3`          | `Slim::Display::Text`             | character (VFD) | 40 × 2 chars      |
| Squeezebox 1 (non-G)             | `squeezebox`                       | `Slim::Player::Squeezebox1`     | `Slim::Display::Text`             | character (VFD) | ~40 × 2 chars     |
| Squeezebox 1 Graphical           | `squeezebox`                       | `Slim::Player::Squeezebox1`     | `Slim::Display::SqueezeboxG`      | graphic bitmap  | 280 × 16 px       |
| Squeezebox 2 / 3                 | `squeezebox2`                      | `Slim::Player::Squeezebox2`     | `Slim::Display::Squeezebox2`      | graphic bitmap  | 320 × 32 px       |
| Boom                             | `boom`                             | `Slim::Player::Boom`            | `Slim::Display::Boom`             | graphic bitmap  | 160 × 32 px       |
| Transporter                      | `transporter`                      | `Slim::Player::Transporter`     | `Slim::Display::Transporter`      | graphic bitmap  | 320 × 32 px × 2¹  |
| SoftSqueeze (v1/v2)              | `softsqueeze`                      | `Slim::Player::SoftSqueeze`     | `Slim::Display::Squeezebox2`      | graphic virtual | 320 × 32 px       |
| SoftSqueeze 3                    | `softsqueeze3`                     | `Slim::Player::SoftSqueeze`     | `Slim::Display::Transporter`      | graphic virtual | 320 × 32 px × 2¹  |
| SoftBoom                         | `softboom`                         | `Slim::Player::SoftSqueeze`     | `Slim::Display::Boom`             | graphic virtual | 160 × 32 px       |
| SqueezeSlave                     | `squeezeslave`                     | `Slim::Player::SqueezeSlave`    | `Slim::Display::Text`             | character       | software only     |
| squeezelite-esp32 (with display) | `squeezeesp32-basic` (class 100)   | `Plugins::SqueezeESP32::Player` | `Plugins::SqueezeESP32::Graphics` | graphic bitmap  | variable × 32 px³ |
| squeezelite-esp32 (no display)   | `squeezeesp32-graphic` (class 101) | `Plugins::SqueezeESP32::Player` | `Slim::Display::NoDisplay`        | none            | —                 |
| SqueezePlay / piCorePlayer       | `squeezeplay` / `controller`       | `Slim::Player::SqueezePlay`     | `Slim::Display::NoDisplay`⁴       | none            | —                 |
| Receiver                         | `receiver`                         | `Slim::Player::Receiver`        | `Slim::Display::NoDisplay`        | none            | —                 |

> ¹ Transporter / SoftSqueeze3 have two independent 320×32 screens.  
> ² Registered via `Slim::Networking::Slimproto::addPlayerClass` in `Plugins::SqueezeESP32::Plugin`.  
> ³ Display width is reported dynamically by the device (default 128 px); height is always 32 px. `vfdmodel` is set to `graphic-160x32` for compatibility.  
> ⁴ SqueezePlay uses `NoDisplay` by default. When a CLI `displaystatus bits` subscription
>   is opened, the server temporarily promotes the client to `Slim::Display::EmulatedSqueezebox2`
>   to stream rendered pixel data (see `Slim/Control/Queries.pm`).

---

## 2. Display Class Inheritance

```
Slim::Utils::Accessor
  └── Slim::Display::Display
        ├── Slim::Display::NoDisplay
        ├── Slim::Display::Text
        └── Slim::Display::Graphics
              ├── Slim::Display::SqueezeboxG
              └── Slim::Display::Squeezebox2
                    ├── Slim::Display::Boom
                    ├── Slim::Display::Transporter
                    ├── Slim::Display::EmulatedSqueezebox2
                    └── Plugins::SqueezeESP32::Graphics
```

---

## 3. Graphic Player Font Preferences

Font preferences are stored per-client. Defaults are declared in each display class and
initialised via `initPrefs()`.  The `_curr` value is a **0-based** index into the list.

| Display Class     | `activeFont` list               | default (curr)   | `idleFont` list                 | default (curr) |
| ----------------- | ------------------------------- | ---------------- | ------------------------------- | -------------- |
| SqueezeboxG       | `[small, medium, large, huge]`  | `medium` (1)     | `[small, medium, large, huge]`  | `medium` (1)   |
| Squeezebox2       | `[light, standard, full]`       | `standard` (1)   | `[light, standard, full]`       | `standard` (1) |
| Transporter       | `[light, standard, full]` ³     | `standard` (1)   | `[light, standard, full]` ³     | `standard` (1) |
| Boom              | `[light_n, standard_n, full_n]` | `standard_n` (1) | `[light_n, standard_n, full_n]` | `full_n` (2)   |
| squeezelite-esp32 | `[light, standard, full]` ³     | `standard` (1)   | `[light, standard, full]` ³     | `standard` (1) |

> ³ Transporter and squeezelite-esp32 do not override `$defaultFontPrefs`; they inherit from `Squeezebox2`.

The `_n` (narrow) font variants (`light_n`, `standard_n`, `full_n`) are designed for
Boom's 160 px-wide display, using narrower glyphs so that more characters fit per line.
They are technically selectable on any 32 px display through the web UI.

---

## 4. Web UI Font Picker

Implemented in `Slim::Web::Settings::Player::Display::getFontOptions()`.  
A font is **included** in the picker when all three conditions hold:

```
fontheight("$fontname.2")  ==  $client->displayHeight
fontchars("$fontname.2")   >   255
```

### Why the `.2` sub-font?

Each bitmap font is split into sub-fonts by display line (`.1` for the top line,
`.2` for the bottom line, `.3` for a third line, etc.).  Using `.2` as the probe
ensures the font is designed for at least **two rows** on the target display height.

### Fonts available per display height

| Display height                                     | Fonts shown in web UI                                                               | Excluded (reason)                   |
| -------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------- |
| **16 px** (SqueezeboxG)                            | `small`, `medium`, `large`, `huge`                                                  | — all 32 px fonts (height mismatch) |
| **32 px** (SB2/Boom/Transporter/squeezelite-esp32) | `high`, `light`, `light_n`, `standard`, `standard_n`, `full`, `full_n`, `threeline` | all 16 px fonts (height mismatch)   |

---

## 5. Text Player (VFD) Font Settings

Text players have no bitmap font picker.  Their display settings are per-client prefs
managed by `Slim::Display::Text`:

| Preference       | Default | Meaning                                                            |
| ---------------- | ------- | ------------------------------------------------------------------ |
| `doublesize`     | `0`     | Double-height text when player is **on** (0 = off, 1 = on)         |
| `offDisplaySize` | `0`     | Double-height text when player is **off/idle**                     |
| `largeTextFont`  | `1`     | Font used for double-height rendering: `0` = Classic, `1` = Modern |

The label strings for `largeTextFont` option values come from `strings.txt`:

| Value | String key              | English label |
| ----- | ----------------------- | ------------- |
| `0`   | `SETUP_LARGETEXTFONT_0` | Classic       |
| `1`   | `SETUP_LARGETEXTFONT_1` | Modern        |

---

## 6. TTF (TrueType) Text Rendering

TTF font support is implemented in `Slim::Display::Lib::TTFFonts` and is available
on **all graphic players** (SqueezeboxG, Squeezebox2, Boom, Transporter, EmulatedSqueezebox2, squeezelite-esp32).

| Condition                                                 | TTF used?                              |
| --------------------------------------------------------- | -------------------------------------- |
| Character codepoint ≤ 255, `ttfText` off                  | No — bitmap glyph only                 |
| Character codepoint ≤ 255, `ttfText` on                   | Yes — TTF substitutes the bitmap glyph |
| Character codepoint > 255 (e.g. Latin Extended, Cyrillic) | Yes — TTF always used                  |

`ttfText` is a **global server-level** setting (not per-player).  It is configured
under **Server → Interface** in the web UI and stored in `preferences('server')`.

> **Important:** TTF rendering requires a metrics entry in `ttfmetrics.conf` for the
> specific bitmap font (e.g. `standard.1   9   8`).  If no entry exists — not even in
> the `[ttf:*]` fallback section — `ttfMetricsForFont()` returns `undef` and TTF is
> silently skipped regardless of `ttfText` or character codepoint.
>
> The following fonts currently have **no** metrics entries in any section of
> `ttfmetrics.conf` and therefore **never use TTF**:
>
> | Font        | Display                                        | Reason metrics are absent             |
> | ----------- | ---------------------------------------------- | ------------------------------------- |
> | `threeline` | SB2/Boom/Transporter/squeezelite-esp32 (32 px) | No entry added for this 3-row font    |
> | `huge`      | SqueezeboxG (16 px)                            | 16 px fonts never had metrics defined |
> | `large`     | SqueezeboxG (16 px)                            | same                                  |
> | `medium`    | SqueezeboxG (16 px)                            | same                                  |
> | `small`     | SqueezeboxG (16 px)                            | same                                  |

Uppercase conversion (`uc`) and its suppression (`no-uc`) are per-font directives
in `ttfmetrics.conf`; they apply only when the TTF renderer is active.

### BMP (bitmap) fonts

Bitmap fonts are **always** the primary renderer.  When TTF is active it substitutes
individual glyphs; it does not replace the bitmap renderer entirely.  On text
(character-mode VFD) players and `NoDisplay` players, neither BMP graphic fonts
nor TTF are used.

---

## 7. Bitmap Font Inventory

All bitmap fonts live in `Graphics/` as `<name>.<line>.bmp` files.

| Font         | Height | Lines | Designed for                                                         | Boundary rows                         |
| ------------ | ------ | ----- | -------------------------------------------------------------------- | ------------------------------------- |
| `small`      | 16 px  | 2     | SqueezeboxG (280×16)                                                 | top: 0–7 · bottom: 8–15               |
| `medium`     | 16 px  | 2     | SqueezeboxG (280×16)                                                 | top: 0–6 · bottom: 6–15               |
| `large`      | 16 px  | 2     | SqueezeboxG (280×16)                                                 | top: 0–15 (single zone)               |
| `huge`       | 16 px  | 2     | SqueezeboxG (280×16)                                                 | top: 0–15 (single zone)               |
| `light`      | 32 px  | 2     | SB2/Transporter (320×32), squeezelite-esp32 (variable×32)            | top: 0–13 · bottom: 17–31             |
| `light_n`    | 32 px  | 2     | Boom (160×32)                                                        | top: 0–13 · bottom: 17–31             |
| `standard`   | 32 px  | 2     | SB2/Transporter (320×32), squeezelite-esp32 (variable×32)            | top: 0–9 · bottom: 13–31              |
| `standard_n` | 32 px  | 2     | Boom (160×32)                                                        | top: 0–9 · bottom: 13–31              |
| `full`       | 32 px  | 1     | SB2/Transporter (320×32), squeezelite-esp32 (variable×32)            | full: 0–31                            |
| `full_n`     | 32 px  | 1     | Boom (160×32)                                                        | full: 0–31                            |
| `high`       | 32 px  | 1     | 32 px displays (top only), including squeezelite-esp32 (variable×32) | top: 0–8                              |
| `threeline`  | 32 px  | 3     | SB2/Transporter/Boom (32 px), squeezelite-esp32 (variable×32)        | row1: 0–8 · row2: 11–19 · row3: 22–30 |

> **squeezelite-esp32 note:** All fonts are 32 px tall and rendered identically to
> Squeezebox2. The display **width** is variable — reported dynamically by the device
> (default 128 px, typical range 128–320 px) — so fewer or more characters fit per line
> depending on the hardware. The fonts themselves have no fixed-width layout assumption;
> the server simply renders as many glyph columns as needed and clips to the reported width.

Boundary values are stored in `_fontYRangeOverrides` in `Slim/Display/Lib/Fonts.pm`
and are used by `_rowBoundsOverlayMask` in `Slim/Display/Graphics.pm` to draw the
optional on-screen row-boundary overlay (controlled by `$showTextRowBoundsOverlay`).

---

## 8. TTF Metrics Configuration (`ttfmetrics.conf`)

The file `Graphics/ttfmetrics.conf` defines rendering metrics for each TrueType font
when substituting glyphs of a specific bitmap font.  Plugins can ship their own
`ttfmetrics.conf` in their `Graphics/` directory; entries from later-loaded files
override earlier ones per-section.

### File format

Sections group settings per TTF font file (filename without path, case-sensitive).
Use `[ttf:*]` as a fallback for any TTF font not explicitly listed.

```
[ttf:<filename>]
```

Directives inside a section:

| Directive     | Syntax                                 | Description                                                                                                                                        |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| metrics       | `<bmp-font> <FTFontSize> <FTBaseline>` | Metrics for one bitmap font rendered via this TTF. Wildcard suffix `*.1` / `*.2` matches any font ending in `.1` / `.2` without an explicit entry. |
| uppercase     | `uc <bmp-font>`                        | Convert string to uppercase before TTF rendering. Typically used for top-line fonts (e.g. `standard.1`).                                           |
| no-uppercase  | `no-uc <bmp-font>`                     | Disable uppercase even if a `[ttf:*]` fallback sets `uc` for this font.                                                                            |
| alias         | `alias <new-bmp> <existing-bmp>`       | Reuse metrics from an existing entry for a different bitmap font name (e.g. map `_n` variants to base fonts).                                      |
| section alias | `alias * <other-ttf-filename>`         | Redirect the entire section to inherit settings from another TTF section.                                                                          |

### Example

```conf
[ttf:CODE2000.TTF]
standard.1  9   8
standard.2  14  28
uc standard.1
alias standard_n.1 standard.1

[ttf:*]
*.1  10  10
*.2  14  28
```
