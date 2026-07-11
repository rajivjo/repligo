# RepliGo Flutter — Fasa 1 hingga 4 (Lengkap)

## Teknologi

| Kategori | Package |
|---|---|
| PDF render | `pdfx` |
| Text extraction | `syncfusion_flutter_pdf` |
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Local database | `drift` (SQLite) |
| File picker | `file_picker` |
| Share | `share_plus` |
| Color picker | `flutter_colorpicker` |
| Settings | `hive_flutter` |

---

## Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Generate Drift database code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Android permissions
Tambah dalam `android/app/src/main/AndroidManifest.xml` (lihat `android_manifest_snippet.xml`).

Dalam `android/app/build.gradle`:
```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 4. iOS permissions
Dalam `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>RepliGo perlukan akses untuk membuka PDF dari galeri</string>
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

### 5. Syncfusion license (untuk text extraction & search)
Syncfusion Community License adalah percuma untuk pendapatan bawah $1M.
Daftar di https://www.syncfusion.com/products/communitylicense dan tambah dalam `main.dart`:
```dart
import 'package:syncfusion_flutter_core/theme.dart';
// Dalam main():
SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY');
```

### 6. Run
```bash
flutter run
```

---

## Struktur Fail

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   └── database/
│       └── app_database.dart     ← Drift SQLite (annotations + bookmarks + progress)
└── features/
    ├── file_manager/             ← Fasa 1
    │   ├── presentation/
    │   │   ├── screens/file_manager_screen.dart
    │   │   └── widgets/
    │   │       ├── file_list_tile.dart
    │   │       ├── file_grid_item.dart
    │   │       └── sort_bottom_sheet.dart
    │   ├── domain/
    │   │   ├── entities/file_item.dart
    │   │   └── usecases/file_manager_provider.dart
    │   └── data/repositories/file_repository.dart
    │
    ├── pdf_viewer/               ← Fasa 1 (diperluaskan Fasa 2-4)
    │   ├── presentation/
    │   │   ├── screens/pdf_viewer_screen.dart     ← Hub utama semua feature
    │   │   └── widgets/
    │   │       ├── page_indicator.dart
    │   │       ├── viewer_bottom_bar.dart
    │   │       └── thumbnail_navigator.dart        ← Fasa 4
    │   └── domain/usecases/pdf_viewer_provider.dart
    │
    ├── annotation/               ← Fasa 2
    │   ├── presentation/widgets/
    │   │   ├── annotation_overlay.dart    ← Lukis overlay atas PDF
    │   │   ├── annotation_toolbar.dart    ← Toolbar highlight/nota/draw
    │   │   └── annotation_list_panel.dart ← Panel sisi anotasi
    │   ├── domain/
    │   │   ├── entities/annotation_model.dart
    │   │   └── usecases/annotation_provider.dart
    │   └── data/repositories/annotation_repository.dart
    │
    ├── text_reflow/              ← Fasa 3
    │   ├── presentation/screens/text_reflow_screen.dart
    │   └── domain/usecases/reflow_provider.dart
    │
    ├── bookmark/                 ← Fasa 4
    │   ├── presentation/widgets/bookmark_list_panel.dart
    │   └── domain/usecases/bookmark_provider.dart
    │
    └── search/                   ← Fasa 4
        └── presentation/screens/pdf_search_screen.dart
```

---

## Features Mengikut Fasa

### Fasa 1 — File Manager & PDF Viewer ✅
- Browse folder & subfolder
- List view & Grid view
- Sort (nama / tarikh / saiz)
- Search fail PDF
- Recent files (berdasarkan last opened)
- Buka PDF dari file picker
- Render PDF dengan pinch-to-zoom
- Page navigation (swipe, slider, prev/next)
- Pergi ke halaman tertentu
- Night mode (invert warna)
- Share PDF
- Auto-hide toolbar (tap untuk toggle)

### Fasa 2 — Annotation ✅
- **Highlight** — drag untuk pilih kawasan, warna boleh ditukar
- **Sticky Note** — tap untuk letak nota, simpan teks
- **Freehand Drawing** — lukis bebas atas PDF
- Color picker (5 warna preset + custom HUE picker)
- Stroke width slider untuk drawing
- Simpan semua anotasi ke SQLite (persist)
- Panel sisi — lihat & padam semua anotasi mengikut halaman
- Jump ke halaman dari panel anotasi

### Fasa 3 — Text Reflow ✅
- Extract teks dari PDF menggunakan Syncfusion
- Mod teks khusus — teks diformat semula ikut skrin
- Pilih saiz fon (10pt – 28pt) dengan slider
- Pilih jarak baris (1.0× – 2.5×)
- Preview perubahan langsung
- Teks boleh di-select/copy
- Navigasi halaman dalam mod reflow
- Cache teks (tidak perlu extract semula)

### Fasa 4 — Polish ✅
- **Bookmark** — bookmark sebarang halaman, simpan ke SQLite
- Toggle bookmark dari AppBar
- Panel sisi bookmark — lihat, jump, padam
- **Search dalam PDF** — cari teks dalam semua halaman
- Highlight perkataan yang dicari dalam hasil
- Beza huruf besar/kecil (toggle)
- Had 200 hasil, klik untuk jump ke halaman
- **Thumbnail navigator** — strip gambar kecil semua halaman
- **Reading progress** — sambung dari halaman terakhir dibuka
- Landscape/portrait mengikut orientasi peranti

---

## Nota Teknikal

### Annotation Overlay
Annotation disimpan sebagai koordinat ternormal (0.0–1.0) supaya ia berskala dengan betul untuk mana-mana saiz halaman PDF.

### Drift Database
Selepas `flutter pub get`, mesti jalankan:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Ini generate fail `app_database.g.dart` yang diperlukan.

### Syncfusion PDF
Package ini guna untuk extract teks (Fasa 3) dan search (Fasa 4). License komuniti percuma. Tanpa license, watermark akan muncul pada text extraction dalam release build.
