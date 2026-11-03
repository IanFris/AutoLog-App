# AutoLog 🛵🚗 — Aplikasi Full-Stack Pencatatan & Pengingat Servis Kendaraan

**AutoLog** adalah aplikasi *full-stack* pencatatan dan pemantauan pemeliharaan kendaraan bermotor (sepeda motor & mobil) yang dikembangkan menggunakan **PHP Native (PDO) + MySQL di Laragon** pada sisi Backend dan **Flutter (Dart)** pada sisi Mobile Frontend.

Repository ini terbagi ke dalam **3 folder utama**:
- **`/database`**: Skrip SQL (`schema.sql`) berisi DDL (tabel & relasi Foreign Key) serta DML (data dummy siap pakai).
- **`/api`**: REST API berbasis PHP Native PDO yang berjalan di Laragon (`C:\laragon\www\autolog\api\`).
- **`/frontend`**: Source code aplikasi mobile berbasis Flutter (Dart) dengan State Management Provider.

---

## 📁 Struktur Repositori

```
AutoLog-App/
├── database/
│   ├── schema.sql                   # Skrip DDL & DML MySQL (Laragon / HeidiSQL)
│   └── migrations/
│       └── 001_user_sessions.sql    # Migrasi aman untuk instalasi database yang sudah ada
├── api/                             # REST API PHP Native PDO (di C:\laragon\www\autolog\api\)
│   ├── config/
│   │   └── database.php             # Koneksi PDO (localhost, autolog_db, root, password kosong)
│   ├── helpers/
│   │   ├── response.php             # Format respon JSON standar & header CORS
│   │   └── auth.php                 # Validasi token sesi API dan kepemilikan kendaraan
│   ├── auth/
│   │   ├── register.php             # POST: Registrasi pengguna baru (password_hash BCRYPT)
│   │   ├── login.php                # POST: Autentikasi pengguna (password_verify)
│   │   └── logout.php               # POST: Mencabut token sesi
│   ├── vehicles/
│   │   └── index.php                # GET: Ambil daftar kendaraan | POST: Tambah kendaraan baru
│   ├── service_types/
│   │   └── index.php                # GET: Katalog jenis pemeliharaan / servis
│   ├── service_logs/
│   │   └── index.php                # GET: Riwayat servis | POST: Tambah log + upload foto nota
│   ├── dashboard/
│   │   ├── reminders.php            # GET: Kalkulasi status komponen (Hijau, Kuning, Merah)
│   │   └── expenses.php             # GET: Rekapitulasi & statistik biaya perawatan
│   └── uploads/
│       ├── .htaccess                # Menonaktifkan indeks dan akses skrip
│       └── .gitkeep                 # Folder penyimpanan berkas foto nota servis
├── frontend/                        # Aplikasi Mobile Flutter (Dart)
│   ├── lib/
│   │   ├── main.dart                # Entry point & MultiProvider setup
│   │   ├── core/
│   │   │   ├── constants/           # ApiConstants (Konfigurasi URL Fleksibel)
│   │   │   ├── theme/               # Material 3 Automotive Teal Theme
│   │   │   └── utils/               # Formatter Rupiah & Tanggal Indonesia
│   │   ├── models/                  # User, Vehicle, ServiceType, ServiceLog, ComponentReminder, ExpenseSummary
│   │   ├── services/                # ApiService (HTTP client) & SessionService (SharedPreferences)
│   │   ├── providers/               # AuthProvider, VehicleProvider, ServiceProvider
│   │   ├── widgets/                 # CustomCard, ComponentStatusCard, VehicleHeaderCard, StatCard, EmptyState
│   │   └── screens/
│   │       ├── auth/                # LoginScreen & RegisterScreen
│   │       ├── dashboard/           # DashboardScreen (Status Komponen Hijau, Kuning, Merah)
│   │       ├── vehicles/            # AddEditVehicleScreen (Form Tambah Kendaraan)
│   │       ├── service_logs/        # ServiceLogListScreen & AddServiceLogScreen (Image Picker Nota)
│   │       ├── expenses/            # ExpenseSummaryScreen (Statistik & Tren Biaya)
│   │       └── main_navigation_screen.dart # Navigasi 3 Tab Utama
│   └── pubspec.yaml
└── README.md
```

Dashboard admin berada di dalam folder `api/admin`, sehingga folder utama project tetap hanya `api`, `frontend`, dan `database`.

---

## 🗄️ 1. Database MySQL (`/database/schema.sql`)

### Struktur Tabel & Relasi Relasional
1. **`users`**: `id` (PK), `name`, `email` (UNIQUE), `password_hash`, `created_at`.
2. **`user_sessions`**: hash token sesi, `user_id` (FK -> users.id), waktu kedaluwarsa.
3. **`vehicles`**: `id` (PK), `user_id` (FK -> users.id), `type` ('motor'/'mobil'), `brand_model`, `license_plate`, `current_odometer`, `created_at`.
4. **`service_types`**: `id` (PK), `name`, `default_km_interval`, `default_month_interval`, `icon`, `created_at`.
5. **`service_logs`**: `id` (PK), `vehicle_id` (FK -> vehicles.id), `service_type_id` (FK -> service_types.id), `service_date`, `odometer_km`, `cost`, `workshop_name`, `notes`, `receipt_photo_url`, `created_at`.
6. **`reminders`**: `id` (PK), `vehicle_id` (FK -> vehicles.id), `service_type_id` (FK -> service_types.id), `due_km`, `due_date`, `status` ('pending'/'completed'), `created_at`.

### Cara Impor Database di Laragon:
1. Buka aplikasi **Laragon**, lalu klik **Start All** (Apache & MySQL aktif).
2. Klik tombol **Database** di Laragon untuk membuka **HeidiSQL** (atau akses phpMyAdmin di `http://localhost/phpmyadmin`).
3. Buat database baru bernama `autolog_db` (atau langsung jalankan skrip `database/schema.sql` yang sudah memuat perintah `CREATE DATABASE IF NOT EXISTS autolog_db`).
4. Eksekusi seluruh skrip `schema.sql`.

### Dashboard Admin

Panel admin tersedia melalui `http://localhost/autolog/api/admin/`. Salin folder `api` ke `C:\laragon\www\autolog\`, lalu buat akun admin dari PowerShell atau terminal:

```powershell
cd C:\laragon\www\autolog
php api\admin\create_admin.php
```

Masukkan email dan password admin saat diminta. Password minimal 12 karakter. Akun admin disimpan terpisah di tabel `admin_users`; akun demo aplikasi biasa tidak bisa dipakai untuk login admin.

Dashboard memuat ringkasan statistik dan biaya servis, pencarian serta pengelolaan pengguna/kendaraan, riwayat servis, serta tambah/edit/hapus katalog servis. Penghapusan pengguna atau kendaraan juga menghapus data terkait melalui relasi database. Jenis servis yang sudah dipakai pada riwayat atau pengingat tidak dapat dihapus. Gunakan panel ini hanya di lingkungan yang memiliki HTTPS saat diakses melalui jaringan.

### Akun Dummy Siap Pakai:
| Email | Password | Nama | Kendaraan Sampel |
|---|---|---|---|
| `budi@autolog.com` | `password123` | Budi Santoso | Honda Vario 160 ABS (B 4589 SKM), Toyota Avanza 1.5 G (B 1842 KFL) |
| `siti@autolog.com` | `password123` | Siti Rahmawati | Yamaha NMAX 155 Connected (D 3214 ABZ) |

---

## 🌐 2. Backend REST API (`/api` di Laragon)

API dibuat menggunakan **PHP Native dengan PDO** untuk mencegah celah keamanan *SQL Injection*.

### Lokasi di Laragon:
Salin atau arahkan folder `/api` ke direktori root web Laragon:
```
C:\laragon\www\autolog\api\
```

API CORS headers and `OPTIONS` preflight responses are handled by `api/helpers/response.php`. Keep Apache-level CORS headers out of `.htaccess` to avoid duplicate headers that browsers reject.
Endpoint yang membaca atau mengubah data pengguna memerlukan header `Authorization: Bearer <token>` dari login/registrasi. Token disimpan sebagai hash di database dan kedaluwarsa setelah 30 hari. Untuk database yang sudah ada, jalankan `database/migrations/001_user_sessions.sql` satu kali sebelum login kembali.
Gunakan HTTPS saat API diakses melalui jaringan; URL HTTP bawaan hanya ditujukan untuk pengembangan lokal.

### Format Respon JSON Standar:
```json
{
  "status": "success",
  "message": "Pesan deskriptif status",
  "data": { ... }
}
```

### Daftar Endpoint REST API:
| Metode | Endpoint | Parameter / Body | Deskripsi |
|---|---|---|---|
| **POST** | `/auth/register.php` | `name`, `email`, `password` | Registrasi akun dan penerbitan token sesi |
| **POST** | `/auth/login.php` | `email`, `password` | Login dan penerbitan token sesi |
| **POST** | `/auth/logout.php` | Header `Authorization: Bearer ...` | Mencabut token sesi |
| **GET** | `/vehicles/index.php?user_id=1` | Token dan `user_id` | Mengambil seluruh kendaraan milik user yang terautentikasi |
| **POST** | `/vehicles/index.php` | Token, `user_id`, `type`, `brand_model`, `license_plate`, `current_odometer` | Menambah kendaraan milik user yang terautentikasi |
| **PUT** | `/vehicles/index.php` | Token, `id`, `current_odometer` | Memperbarui odometer kendaraan milik user yang terautentikasi |
| **GET** | `/service_types/index.php` | - | Katalog komponen dan jenis servis |
| **GET** | `/service_logs/index.php?vehicle_id=1` | Token dan `vehicle_id` | Riwayat servis terurut dari yang terbaru |
| **POST** | `/service_logs/index.php` | Token, `vehicle_id`, `service_type_id`, `service_date`, `odometer_km`, `cost`, `workshop_name`, `notes`, `receipt_photo` (JPG/PNG/WEBP, maks. 5 MB) | Tambah servis, auto-update KM, auto-reset reminder, dan upload foto nota |
| **GET** | `/dashboard/reminders.php?vehicle_id=1` | Token dan `vehicle_id` | Kalkulasi status komponen (Hijau, Kuning, Merah) |
| **GET** | `/dashboard/expenses.php?vehicle_id=1` | Token dan `vehicle_id` | Total biaya, biaya per KM, kategori, dan tren bulanan |

### Logika Kalkulasi Indikator Status Komponen:
- 🔴 **Merah / Wajib Servis**: `KM saat ini >= Target KM` ATAU `Tanggal saat ini > Tanggal Jatuh Tempo`.
- 🟡 **Kuning / Mendekati Servis**: Sisa jarak $\le 500\text{ KM}$ ATAU sisa waktu $\le 7\text{ hari}$.
- 🟢 **Hijau / Aman**: Masih berada dalam batas interval pemakaian yang aman.

---

## 📱 3. Frontend Flutter (`/frontend`)

Dibangun dengan arsitektur bersih dan modular menggunakan **Provider State Management**.

### Fitur Aplikasi Mobile:
1. **Login & Registrasi Pengguna**:
   - Validasi form interaktif.
   - Mode tamu tanpa registrasi; kendaraan, servis, pengingat, dan biaya tamu disimpan lokal di perangkat dan tidak dikirim ke database cloud. Data lokal dapat hilang jika aplikasi dihapus atau data aplikasi dibersihkan.
   - Konfigurasi server URL fleksibel langsung dari aplikasi (dialog tombol setting di kanan atas).
   - Penyimpanan sesi pengguna otomatis via `SharedPreferences`.
2. **Dashboard / Garasi Saya**:
   - Kartu kendaraan aktif dengan nomor plat dan odometer saat ini.
   - Pemilih kendaraan instan (*dropdown switcher*).
   - Dialog cepat **Update KM** odometer.
   - Kartu indikator komponen berstatus warna **Hijau, Kuning, Merah** lengkap dengan *progress bar* dan sisa KM/hari.
   - Tombol **"Servis Komponen Ini"** yang otomatis mengarahkan ke form servis dengan jenis komponen terisi.
3. **Form Tambah Kendaraan**:
   - Pilihan jenis kendaraan (Sepeda Motor / Mobil).
   - Merk & model, nomor polisi, dan odometer awal.
4. **Riwayat Pemeliharaan (Service Log List)**:
   - Menampilkan catatan pengerjaan servis terurut dari yang terbaru.
   - Fitur pencarian berdasarkan nama servis, bengkel, atau catatan.
   - Ekspor seluruh riwayat kendaraan aktif ke file CSV berformat UTF-8 yang bisa dibuka di Excel dan dibagikan.
   - Indikator badge dan dialog *preview* foto nota servis; nota akun tersimpan di server Laragon, sementara nota tamu tersimpan di perangkat.
5. **Form Tambah Log Servis**:
   - Pilihan jenis servis dari katalog API.
   - Input tanggal, KM servis, biaya dalam format Rupiah, nama bengkel, dan catatan mekanik.
   - Fitur **Image Picker**: Mengambil foto nota servis langsung via kamera atau galeri; foto akun diunggah ke server, sedangkan foto tamu disimpan lokal.
6. **Rekapitulasi Biaya Servis (Expense Summary)**:
   - Total pengeluaran sepanjang masa, tahun ini, dan bulan ini.
   - Estimasi biaya perawatan per kilometer (**Rp / KM**).
   - Visualisasi tren pengeluaran 6 bulan terakhir.
   - Diagram persentase biaya per kategori komponen.

### Konfigurasi Base URL API:
Base URL diatur di file `frontend/lib/core/constants/api_constants.dart`:
- **Android Emulator**: `http://10.0.2.2/autolog/api` (default)
- **Windows Desktop / Chrome Web**: `http://localhost/autolog/api`
- **HP Fisik Android**: Gunakan IP Wi-Fi komputer Anda, misalnya `http://192.168.1.15/autolog/api`

### Cara Menjalankan Flutter Frontend:
```bash
cd frontend

# Unduh dependensi
flutter pub get

# Jalankan pengujian
flutter test

# Jalankan pada Google Chrome (Web)
flutter run -d chrome

# Jalankan pada Windows Desktop
flutter run -d windows

# Jalankan pada Emulator / HP Android
flutter run -d android
```

---

## 🛠️ Lisensi & Pengembang
Dikembangkan untuk mempermudah pencatatan dan perawatan kendaraan bermotor.  
Hak Cipta © 2026 AutoLog Team.
