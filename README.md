# 🃏 Title Card Maker

A powerful **Windows desktop application** built with Flutter for creating, designing, and exporting professional title cards — perfect for conferences, table name placards, board game cards, label sheets, and any other print-ready card layout.

---

## ✨ Features

### 🎨 Card Design Editor
- **Drag & drop elements** freely on each card — text blocks and images
- **Resize elements** using eight-directional handles
- **Snap-to-grid** for precise alignment (5% grid step, toggleable)
- **Zoom** the editor canvas for fine-grained placement
- **Keyboard shortcuts** for pixel-perfect nudging of selected elements
- **Color picker** for card background colors
- **Rich text styling** — font family, size, weight (bold), style (italic), underline, color, and alignment

### 📐 Page Layout Configuration
| Setting | Range | Default |
|---|---|---|
| Columns | 1 – 20 | 2 |
| Rows | 1 – 20 | 3 |
| Card width | 30 – 150 mm | 90 mm |
| Card height | 30 – 150 mm | 50 mm |
| Horizontal spacing | 0 – 20 mm | 5 mm |
| Vertical spacing | 0 – 20 mm | 5 mm |
| Page margins (all sides) | 0 – unlimited mm | 0 mm |

### 📊 Data Import
Bulk-populate card text from external data sources:
- **Excel files** (`.xlsx`, `.xls`)
- **CSV files** (`.csv`)
- **Clipboard paste** — supports tab-separated and comma-separated data
- **Multi-column selection** — select multiple columns; values are joined with ` | ` per card

### 🖼️ Layout Modes
- **Individual mode** — each card has its own independent layout and content
- **Global mode** — define one master layout that is applied to all cards simultaneously

### 📤 Export
#### PDF Export
- Exports to A4 PDF, one sheet per page
- **Card selection dialog** — choose exactly which cards to export; deselected cards leave blank spaces (their exact size is preserved, no stretching)
- Page-level and individual card-level selection with tri-state checkboxes
- Auto-generated release notes in GitHub Releases

#### Image Export
- Export page sheets as **PNG** or **JPG**
- Choose resolution: **150 DPI**, **300 DPI**, or **600 DPI**
- Page size: **A4** or fully **custom dimensions** (mm)

### 💾 Project Save & Load
- Save your entire project (layout, all cards, images, table data) to a `.json` file
- Reload and continue editing at any time
- Embedded image paths are stored for portability

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.9.2
- Windows 10 or later (64-bit)
- Visual Studio 2022 with **Desktop development with C++** workload

### Build from Source

```bash
git clone https://github.com/your-username/title_card_maker.git
cd title_card_maker

flutter pub get
flutter build windows --release
```

The built executable and all required DLLs will be located at:
```
build\windows\x64\runner\Release\
```

### Run in Debug Mode

```bash
flutter run -d windows
```

---

## 📦 Download

Pre-built Windows releases are available on the [**Releases page**](../../releases).

Download `title_card_maker-windows.zip`, extract it, and run `title_card_maker.exe` — no installation required.

> A new release is automatically built and published every time changes are pushed to the `master` branch via GitHub Actions.

---

## 🔧 CI/CD Pipeline

The project includes a GitHub Actions workflow (`.github/workflows/build-release.yml`):

| Trigger | Action |
|---|---|
| Push to **any branch** | Build the Windows EXE and upload as a workflow artifact (available for 90 days) |
| Push to **`master`** | Build + automatically create a **GitHub Release** with the downloadable ZIP |

---

## 🗂️ Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/
│   ├── card_data.dart          # Card data model (text, image, layout)
│   ├── card_element.dart       # Individual draggable element on a card
│   ├── card_layout.dart        # Layout container for a single card
│   ├── element_type.dart       # Enum: text or image
│   ├── layout_config.dart      # Page grid configuration (columns, rows, sizes)
│   ├── layout_mode.dart        # Enum: global or individual layout mode
│   ├── project_data.dart       # Full project save/load model
│   ├── image_export_options.dart
│   ├── save_options.dart
│   └── text_mode.dart
├── providers/
│   └── project_provider.dart   # Central state management (Provider)
├── screens/
│   └── home_screen.dart        # Main application screen
├── services/
│   ├── pdf_service.dart        # PDF generation & export logic
│   ├── image_service.dart      # Image rendering & export logic
│   └── import_service.dart     # Project file import/export
└── widgets/
    ├── card_layout_editor.dart  # Drag-and-drop card editor canvas
    ├── card_preview.dart        # Read-only card preview thumbnail
    ├── card_selection_dialog.dart # Export card picker dialog
    ├── config_panel.dart        # Page layout configuration sidebar
    ├── image_export_dialog.dart # Image export settings dialog
    ├── preview_canvas.dart      # Full A4 page preview
    ├── save_options_dialog.dart # Save/load dialog
    ├── table_import_panel.dart  # Excel/CSV/clipboard import panel
    └── text_mode_panel.dart     # Text input mode controls
```

---

## 🛠️ Tech Stack

| Library | Purpose |
|---|---|
| [Flutter](https://flutter.dev) | UI framework (Windows desktop) |
| [provider](https://pub.dev/packages/provider) | State management |
| [pdf](https://pub.dev/packages/pdf) | PDF generation |
| [printing](https://pub.dev/packages/printing) | PDF preview & printing |
| [file_picker](https://pub.dev/packages/file_picker) | Native file open/save dialogs |
| [excel](https://pub.dev/packages/excel) | Excel file parsing |
| [csv](https://pub.dev/packages/csv) | CSV file parsing |
| [desktop_drop](https://pub.dev/packages/desktop_drop) | Drag & drop files onto the app |
| [flex_color_picker](https://pub.dev/packages/flex_color_picker) | Color picker widget |
| [dotted_border](https://pub.dev/packages/dotted_border) | Dashed border decoration |
| [path_provider](https://pub.dev/packages/path_provider) | File system path access |

---

## 📄 License

This project is provided as-is for personal and internal use.
