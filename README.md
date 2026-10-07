# SPV-Track Mobile (Flutter)

Aplikasi mobile **SPV-Track** untuk operator lapangan warehouse dan supervisor di **PT. South Pacific Viscose**. Aplikasi ini dirancang persis sesuai alur kerja, logika bisnis, dan estetika web dashboard SPV-Track, mempermudah dokumentasi digital evidence staging kontainer dan truk sesuai standar kepatuhan **27 Titik Foto SOP**.

---

## 🌟 Fitur Utama (Mirroring Sistem Web SPV-Track)

### 1. Dashboard Eksekutif & KPI Operasional
- **Welcome Banner**: Identitas warehouse, status koneksi *Live Online* dengan indikator waktu server (WIB).
- **KPI Metrics Cards**: Total Staging, Selesai (Submitted), Draft / Proses, Petugas Aktif, serta persentase kepatuhan SOP.
- **Distribusi Operasional**: Visualisasi rasio jenis produk (**Fiber vs Sodium**) dan jenis armada pengiriman (**Export vs Lokal**).
- **Staging Terbaru**: Feed data real-time dengan status badge dinamis.

### 2. Field App — Mulai Staging Baru
- **Scan & OCR Shipment Order**: Fitur kamera/galeri untuk memindai dokumen SO resmi, secara otomatis mengekstrak 5 data utama:
  1. *Nomor Surat Jalan / Delivery / Packing List* (Wajib 9 digit angka)
  2. *Nomor Shipment Group* (Wajib 9 digit angka)
  3. *Nomor Shipment* (Wajib 9 digit angka)
  4. *Plat Nomor Truk*
  5. *Nomor Kontainer*
- **Parameter Kondisi Lapangan**:
  - Jenis Produk: Fiber / Sodium
  - Jenis Pengiriman: Export (Kontainer) / Lokal (Trucking)
  - Cuaca: Kering / Mendung / Hujan / Gerimis
  - Waktu / Shift: Siang / Sore / Malam
  - Lokasi Warehouse: Atas / Tengah / Bawah
  - Tanggal Staging & Petugas Lapangan (multi-select dari master karyawan).

### 3. Timeline Evidence 27 Titik SOP (Immutable / Append-Only)
- **Header Identitas Monospace**: Packing List, Group, Shpt, Plat, dan Kontainer.
- **Progress Counter**:
  - Titik Total: 27 Titik
  - Titik Terupload
  - Wajib Terverifikasi (26 Titik foto wajib + 1 video singkat)
- **Banner Rekomendasi Kamera Horizontal / Landscape** untuk keterbacaan barcode & nomor kontainer.
- **27 Titik SOP Cards**:
  - Ambil foto kamera langsung atau pilih dari galeri.
  - Tampilan timestamp burn-in berformat `Y-m-d H:i:s WIB`.
  - Tombol (+) Foto Tambahan di luar 27 titik standar.
- **Pencatatan Waktu Operasional**:
  - Waktu Mulai Staging (Kedatangan Container) + tombol *Sekarang*.
  - Waktu Selesai Staging (Keberangkatan Container) + tombol *Sekarang*.
- **Validasi Ketat Sebelum Submit**: Memastikan seluruh 26 titik wajib dan jam operasional telah terisi sebelum dapat disubmit secara permanen.

### 4. Kelola & Riwayat Shipment
- Pencarian cerdas berdasarkan nomor packing list, plat nomor, nomor kontainer, atau nama sopir.
- Filter cepat: Jenis Pengiriman (*Semua, Export, Lokal*) dan Status (*Semua, Submitted, Draft*).
- Halaman **Detail Shipment**: Ringkasan data operasional dan galeri grid foto evidence dengan nomor titik serta timestamp.

### 5. Pengaturan & Konektivitas
- Fleksibilitas konfigurasi alamat endpoint backend Laravel (Laragon / localhost / IP LAN / Android emulator `10.0.2.2`).
- Tombol **Uji Koneksi Server** yang memvalidasi koneksi langsung ke endpoint `/api/server-time`.
- Mode fallback offline cerdas agar aplikasi tetap dapat dioperasikan meskipun server sedang restart.

---

## 🚀 Panduan Menjalankan Aplikasi

Pastikan backend Laravel di folder `d:\laragon\www\spv-track\web` aktif (misal via Laragon atau `php artisan serve`).

### 1. Masuk ke direktori mobile
```powershell
cd d:\laragon\www\spv-track\mobile
```

### 2. Menjalankan di Chrome / Browser Web
```powershell
flutter run -d chrome
```

### 3. Menjalankan di Windows Desktop
```powershell
flutter run -d windows
```

### 4. Menjalankan di Android Emulator / Perangkat Fisik
Pastikan perangkat Android terhubung via USB debugging atau emulator aktif, lalu jalankan:
```powershell
flutter run
```
> **Catatan untuk Android Emulator:** Di halaman Pengaturan, set server base URL ke `http://10.0.2.2:8000` (atau IP LAN komputer Anda jika menggunakan perangkat fisik di jaringan WiFi yang sama).

---

## 📁 Struktur Direktori `mobile/`

```text
mobile/
├── lib/
│   ├── main.dart                          # Entry point aplikasi
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart            # Warna & styling SPV-Track web
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Material 3 tema & tipografi
│   │   └── network/
│   │       └── api_service.dart           # HTTP client terintegrasi Laravel
│   ├── models/
│   │   ├── dashboard_stats_model.dart     # Model metrik KPI
│   │   ├── karyawan_model.dart            # Model master data karyawan
│   │   ├── shipment_model.dart            # Model shipment & evidence item
│   │   └── sop_point_model.dart           # Model master 27 titik SOP
│   └── screens/
│       ├── home_navigation_screen.dart    # Bottom Navigation Bar
│       ├── dashboard/
│       │   └── dashboard_screen.dart      # Halaman utama Dashboard
│       ├── field_app/
│       │   ├── field_app_create_screen.dart # Form Staging & OCR SO
│       │   └── timeline_screen.dart       # Timeline 27 titik SOP & submit
│       ├── shipments/
│       │   ├── shipments_list_screen.dart # List & filter shipment
│       │   └── shipment_detail_screen.dart# Detail & galeri evidence
│       └── settings/
│           └── settings_screen.dart       # Konfigurasi server & info sistem
└── test/
    └── widget_test.dart                   # Smoke test unit & UI
```
