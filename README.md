# Encore Converter

A native macOS app that converts **Encore music notation files** (`.enc`) to **MusicXML** (`.musicxml`), so you can open your old scores in [MuseScore](https://musescore.org/) or any other modern notation software.

![macOS](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## How It Works

The app chains two open-source tools to perform the conversion:

```
.enc  ──▶  go-enc2ly  ──▶  .ly (LilyPond)  ──▶  python-ly  ──▶  .musicxml
```

1. **[go-enc2ly](https://github.com/hanwen/go-enc2ly)** reads the proprietary Encore binary format and outputs LilyPond notation.
2. **[python-ly](https://pypi.org/project/python-ly/)** parses the LilyPond file and exports it as MusicXML.

The intermediate `.ly` file is automatically cleaned up after conversion.

## Features

- **Drag & drop** `.enc` files onto the window (or click to browse)
- **Batch conversion** — add as many files as you want
- **Output folder picker** — choose where the `.musicxml` files go
- **Per-file status** — see which files succeeded, failed, or are still processing
- **Error details** — click on any error to see the full message in a popover, with a copy button for easy debugging
- **Stop button** — cancel a running batch at any time
- **Dependency check** — the app verifies that the required tools are installed on launch

## Prerequisites

You need **Go** and **Python 3** installed on your Mac. Then install the two conversion tools:

```bash
# Install go-enc2ly
go install github.com/hanwen/go-enc2ly@latest

# Install python-ly
pip3 install python-ly
```

> Make sure `~/go/bin` is in your `PATH` so the app can find `go-enc2ly`.

Or simply run the included setup script:

```bash
./tools/setup.sh
```

## Build & Run

1. Open `EncoreConverter.xcodeproj` in Xcode.
2. Select the **EncoreConverter** scheme.
3. Press **Cmd+R** to build and run.

Alternatively, build from the command line:

```bash
xcodebuild -project EncoreConverter.xcodeproj -scheme EncoreConverter -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/EncoreConverter-*/Build/Products/Release/EncoreConverter.app`.

## Usage

1. Launch the app.
2. If any dependencies are missing, you'll see a warning banner with install instructions.
3. Drag your `.enc` files into the window.
4. Click **"Seleccionar..."** to choose an output folder.
5. Click **"Convertir"** to start the batch conversion.
6. Open the resulting `.musicxml` files in MuseScore.

## Limitations

- **Encore version support**: `go-enc2ly` was reverse-engineered from Encore 4.55. Files from Encore 5 generally work, but some features may not convert perfectly.
- **python-ly MusicXML export** is marked as "in development" by its authors — complex scores may have missing elements (dynamics, lyrics, tablature, etc.).
- Line breaks and page layout are not preserved in the conversion.
- Note velocity / playback dynamics are lost (use MIDI export from Encore if you need those).

## Project Structure

```
EncoreConverter/
├── EncoreConverterApp.swift     # App entry point
├── ContentView.swift            # Main UI (drag & drop, file list, controls)
├── FileItem.swift               # Data model and conversion state
├── ConversionEngine.swift       # Subprocess orchestration (go-enc2ly + python-ly)
├── DependencyChecker.swift      # Finds and validates required tools
└── Assets.xcassets/             # App icon
tools/
└── setup.sh                     # Dependency installer script
```

## Acknowledgments

- [go-enc2ly](https://github.com/hanwen/go-enc2ly) by Han-Wen Nienhuys — Encore to LilyPond converter
- [python-ly](https://github.com/frescobaldi/python-ly) by the Frescobaldi project — LilyPond manipulation and MusicXML export
- [enc2ly](https://enc2ly.sourceforge.io/) by Felipe Castro — original reverse-engineering of the Encore format
