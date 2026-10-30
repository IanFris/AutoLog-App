# AutoLog 🛵🚗 — Aplikasi Pencatatan Pemeliharaan Kendaraan Bermotor

**AutoLog** adalah aplikasi mobile berbasis **Flutter** yang dirancang khusus untuk pemilik kendaraan bermotor (sepeda motor dan mobil) di Indonesia guna mencatat, memantau, dan mengelola jadwal pemeliharaan, servis rutin, penggantian suku cadang, serta pengeluaran bahan bakar (BBM).

---

## 🌟 Fitur Unggulan

### 1. 🏍️ & 🚙 Manajemen Multi-Kendaraan (Garasi Digital)
- Kelola lebih dari satu kendaraan (motor & mobil) dalam satu aplikasi.
- Informasi lengkap: Nama/Panggilan, Merk (Honda, Yamaha, Toyota, dll), Model, Tahun Pembuatan, Nomor Polisi (Plat), Jenis BBM, dan Odometer (KM).
- Tombol cepat **Update KM** langsung dari kartu kendaraan di dashboard.
- Alih kendaraan aktif secara instan via pemilih kendaraan interaktif.

### 2. 🔧 Riwayat & Pencatatan Pemeliharaan Komprehensif
- Pencatatan servis dengan kategori lengkap khas otomotif Indonesia:
  - **Ganti Oli Mesin** (dengan rekomendasi interval KM)
  - **Ganti Oli Gardan / Transmisi**
  - **Servis Berkala / Tune-Up**
  - **Kampas Rem Depan / Belakang**
  - **Ganti Busi**
  - **Filter Udara**
  - **Ganti Ban & Spooring**
  - **Aki / Battery Accu**
  - **CVT Belt & Roller / Rantai & Gear**
  - **Air Radiator / Coolant**
  - **Pajak STNK / PKB Tahunan**
  - **Cuci & Detailing Kendaraan**
  - **Perbaikan / Suku Cadang Lainnya**
- Input nama bengkel (AHASS, Planet Ban, Auto2000, Nawilis, Bengkel Mandiri, dll).
- Tag suku cadang yang diganti (misal: *Oli SPX 2 0.8L*, *Busi CPR9EA-9*, *Kampas Rem Nissin*).
- Rincian biaya dalam format mata uang Rupiah (`Rp 150.000`).
- Catatan dan rekomendasi mekanik untuk pengerjaan servis selanjutnya.

### 3. ⏰ Pengingat & Jadwal Servis Pintar (Smart Reminder)
- Pengingat otomatis dihitung berdasarkan **Target Odometer (KM)** dan/atau **Target Tanggal**.
- Indikator status visual dengan progress bar:
  - 🟢 **Jadwal Aman** (Sisa > 500 KM / > 14 hari)
  - 🟡 **Mendekati Waktu Servis** (Sisa ≤ 500 KM / ≤ 7 hari)
  - 🔴 **Lewat Batas Servis!** (KM atau tanggal telah terlampaui)
- Tombol **"Servis Sekarang"**: Membuka formulir servis dengan data yang telah terisi otomatis dan memperbarui pengingat saat selesai.

### 4. ⛽ Catatan Bahan Bakar (BBM Log)
- Catat setiap pengisian bensin (liter, harga per liter, total biaya, jenis BBM, nama SPBU).
- Kalkulasi otomatis estimasi efisiensi konsumsi bahan bakar (**KM / Liter**).
- Penanda tangki penuh (*Full Tank*).

### 5. 📊 Statistik & Analisis Biaya Pengeluaran
- Ringkasan total pengeluaran: Sepanjang Masa, Tahun Ini, dan Bulan Ini.
- Estimasi biaya pemeliharaan per kilometer (**Rp / KM**).
- Grafik batang tren pengeluaran 6 bulan terakhir.
- Diagram persentase biaya per kategori perawatan.

### 6. 💾 Penyimpanan Lokal & Cadangan Data (Backup/Restore)
- Data tersimpan permanen di perangkat menggunakan `SharedPreferences` + serialisasi JSON terstruktur.
- **Ekspor Cadangan (JSON)**: Salin seluruh data ke clipboard untuk backup.
- **Impor Cadangan (JSON)**: Pulihkan data dengan mudah.
- **Muat Data Demo**: Contoh realistis Honda Vario 160 ABS & Toyota Avanza 1.5 G CVT lengkap dengan riwayat servis dan jadwal pengingat.
- **Mode Gelap (Dark Mode)** & **Mode Terang (Light Mode)**.

---

## 🏗️ Struktur Arsitektur Proyek

```
lib/
├── main.dart                          # Titik masuk aplikasi & konfigurasi tema
├── models/
│   ├── vehicle.dart                   # Model Kendaraan (Motor / Mobil, Plat, KM)
│   ├── maintenance_record.dart        # Model Catatan Servis & Kategori Perawatan
│   ├── fuel_record.dart               # Model Catatan Pengisian BBM
│   └── service_reminder.dart          # Model Pengingat Jadwal Servis & Perhitungan Status
├── providers/
│   └── autolog_provider.dart          # State management (ChangeNotifier & Reaktif)
├── services/
│   ├── storage_service.dart           # Layanan penyimpanan lokal SharedPreferences
│   └── mock_data.dart                 # Data awal / demo realistis
├── theme/
│   └── app_theme.dart                 # Material 3 tema otomotif (Light & Dark)
├── utils/
│   ├── currency_formatter.dart        # Format mata uang Rupiah (Rp)
│   └── date_formatter.dart            # Format tanggal bahasa Indonesia
├── widgets/
│   ├── custom_card.dart               # Kartu kustom dengan efek elevasi & border
│   ├── vehicle_selector_card.dart     # Kartu header kendaraan dengan tombol update KM
│   ├── reminder_card.dart             # Kartu jadwal servis dengan progress bar
│   ├── service_record_tile.dart       # Baris ringkasan servis
│   ├── expense_chart.dart             # Grafik pengeluaran bulanan & kategori
│   ├── stat_card.dart                 # Kartu ringkasan metrik statistik
│   ├── empty_state.dart               # Tampilan saat data kosong
│   └── update_odometer_dialog.dart    # Dialog cepat pembaruan KM odometer
└── screens/
    ├── main_navigation_screen.dart    # Navigasi utama (5 Tab + Tombol Tindakan Cepat)
    ├── dashboard_screen.dart          # Beranda dengan ringkasan status & riwayat terkini
    ├── service_history_screen.dart    # Riwayat servis lengkap dengan filter & pencarian
    ├── service_detail_screen.dart     # Rincian nota/struk pengerjaan servis
    ├── add_edit_service_screen.dart   # Formulir input/edit pemeliharaan kendaraan
    ├── reminder_list_screen.dart      # Daftar pengingat & jadwal servis
    ├── statistics_screen.dart         # Statistik & grafik pengeluaran
    ├── fuel_history_screen.dart       # Riwayat pengisian BBM & efisiensi
    ├── add_fuel_screen.dart           # Formulir pengisian BBM
    ├── garage_screen.dart             # Manajemen garasi kendaraan & pengaturan data
    └── add_edit_vehicle_screen.dart   # Formulir tambah/ubah data kendaraan
```

---

## 🚀 Cara Menjalankan

### Persyaratan:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi 3.0.0 atau lebih baru)
- Perangkat Android, iOS, Windows, atau Web Browser (Chrome/Edge)

### Langkah-langkah:
1. Clone repositori:
   ```bash
   git clone https://github.com/IanFris/AutoLog-App.git
   cd AutoLog-App
   ```

2. Unduh dependensi:
   ```bash
   flutter pub get
   ```

3. Jalankan tes:
   ```bash
   flutter test
   ```

4. Jalankan aplikasi:
   ```bash
   # Di Chrome (Web)
   flutter run -d chrome

   # Di Windows Desktop
   flutter run -d windows

   # Di Perangkat / Emulator Android
   flutter run -d android
   ```

---

## 📄 Lisensi
Hak Cipta © 2026 AutoLog Team.
Aplikasi ini dikembangkan untuk kemudahan perawatan kendaraan bermotor.
