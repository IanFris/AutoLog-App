-- ====================================================================
-- AutoLog Database Schema & Dummy Data (DDL & DML)
-- Kompatibel dengan HeidiSQL, phpMyAdmin, dan MySQL di Laragon
-- Database: autolog_db
-- ====================================================================

CREATE DATABASE IF NOT EXISTS `autolog_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `autolog_db`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `reminders`;
DROP TABLE IF EXISTS `service_logs`;
DROP TABLE IF EXISTS `service_types`;
DROP TABLE IF EXISTS `vehicles`;
DROP TABLE IF EXISTS `user_sessions`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------------------------------------------------
-- 1. TABEL: users
-- --------------------------------------------------------------------
CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `token_hash` CHAR(64) NOT NULL UNIQUE,
  `expires_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_user_sessions_expiry` (`expires_at`),
  CONSTRAINT `fk_user_sessions_user` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin accounts are created separately with `php admin/create_admin.php`.
CREATE TABLE IF NOT EXISTS `admin_users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 2. TABEL: vehicles
-- --------------------------------------------------------------------
CREATE TABLE `vehicles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `type` ENUM('motor', 'mobil') NOT NULL DEFAULT 'motor',
  `brand_model` VARCHAR(120) NOT NULL,
  `license_plate` VARCHAR(20) NOT NULL,
  `current_odometer` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_vehicles_user` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 3. TABEL: service_types (Katalog Jenis Servis)
-- --------------------------------------------------------------------
CREATE TABLE `service_types` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `default_km_interval` INT NOT NULL DEFAULT 3000,
  `default_month_interval` INT NOT NULL DEFAULT 3,
  `icon` VARCHAR(50) DEFAULT 'build',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 4. TABEL: service_logs (Riwayat Pemeliharaan & Servis)
-- --------------------------------------------------------------------
CREATE TABLE `service_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT NOT NULL,
  `service_type_id` INT NOT NULL,
  `service_date` DATE NOT NULL,
  `odometer_km` INT NOT NULL,
  `cost` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `workshop_name` VARCHAR(150) NULL DEFAULT 'Bengkel Umum',
  `notes` TEXT NULL,
  `receipt_photo_url` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_logs_vehicle` FOREIGN KEY (`vehicle_id`)
    REFERENCES `vehicles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_logs_service_type` FOREIGN KEY (`service_type_id`)
    REFERENCES `service_types` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 5. TABEL: reminders (Pengingat Servis Mendatang)
-- --------------------------------------------------------------------
CREATE TABLE `reminders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT NOT NULL,
  `service_type_id` INT NOT NULL,
  `due_km` INT NULL,
  `due_date` DATE NULL,
  `status` ENUM('pending', 'completed') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_reminders_vehicle` FOREIGN KEY (`vehicle_id`)
    REFERENCES `vehicles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_reminders_service_type` FOREIGN KEY (`service_type_id`)
    REFERENCES `service_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- DML: DUMMY DATA SEEDING
-- ====================================================================

-- 1. Users Dummy (Password default: password123)
INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'Budi Santoso', 'budi@autolog.com', '$2y$12$bYYl1pnoKHc3WvODcxieLuzSnJgBG2dRL3kioznIEXK7RpflA1a8O', NOW()),
(2, 'Siti Rahmawati', 'siti@autolog.com', '$2y$12$bYYl1pnoKHc3WvODcxieLuzSnJgBG2dRL3kioznIEXK7RpflA1a8O', NOW());

-- 2. Vehicles Dummy (Motor & Mobil)
INSERT INTO `vehicles` (`id`, `user_id`, `type`, `brand_model`, `license_plate`, `current_odometer`, `created_at`) VALUES
(1, 1, 'motor', 'Honda Vario 160 ABS', 'B 4589 SKM', 14850, NOW()),
(2, 1, 'mobil', 'Toyota Avanza 1.5 G CVT', 'B 1842 KFL', 42600, NOW()),
(3, 2, 'motor', 'Yamaha NMAX 155 Connected', 'D 3214 ABZ', 8200, NOW());

-- 3. Service Types (Standar Komponen Pemeliharaan)
INSERT INTO `service_types` (`id`, `name`, `default_km_interval`, `default_month_interval`, `icon`, `created_at`) VALUES
(1, 'Ganti Oli Mesin', 3000, 2, 'opacity', NOW()),
(2, 'Ganti Oli Gardan / Transmisi', 8000, 6, 'settings', NOW()),
(3, 'Servis Berkala / Tune Up', 4000, 3, 'build', NOW()),
(4, 'Kampas Rem Depan / Belakang', 10000, 8, 'album', NOW()),
(5, 'Ganti Busi', 8000, 6, 'flash_on', NOW()),
(6, 'Filter Udara', 12000, 10, 'air', NOW()),
(7, 'Ganti Ban & Spooring', 20000, 18, 'adjust', NOW()),
(8, 'Aki / Battery Accu', 24000, 24, 'battery_charging_full', NOW()),
(9, 'CVT Belt & Roller / Rantai', 15000, 12, 'sync', NOW()),
(10, 'Air Radiator / Coolant', 12000, 12, 'waves', NOW());

-- 4. Service Logs Sample
INSERT INTO `service_logs` (`id`, `vehicle_id`, `service_type_id`, `service_date`, `odometer_km`, `cost`, `workshop_name`, `notes`, `receipt_photo_url`, `created_at`) VALUES
-- Log Vario 160
(1, 1, 1, DATE_SUB(CURDATE(), INTERVAL 65 DAY), 12000, 115000.00, 'AHASS 0712 Cawang', 'Ganti oli mesin SPX2 0.8L dan oli gardan AHM.', NULL, NOW()),
(2, 1, 3, DATE_SUB(CURDATE(), INTERVAL 140 DAY), 10000, 185000.00, 'AHASS 0712 Cawang', 'Servis rutin berkala 10.000 KM, tune-up injeksi, dan ganti busi.', NULL, NOW()),
(3, 1, 7, DATE_SUB(CURDATE(), INTERVAL 18 DAY), 14200, 395000.00, 'Planet Ban Kalimalang', 'Ganti ban belakang tubeless Maxxis Victra 120/70-14 + kampas rem depan.', NULL, NOW()),

-- Log Avanza
(4, 2, 3, DATE_SUB(CURDATE(), INTERVAL 80 DAY), 40050, 1450000.00, 'Auto2000 Tebet Supomo', 'Servis besar 40.000 KM: oli TMO 10W-40 4L, filter oli, busi 4 pcs, kuras minyak rem.', NULL, NOW()),
(5, 2, 7, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 41500, 290000.00, 'Nawilis Ban Radio Dalam', 'Spooring 3D, balancing 4 roda, dan cek tekanan nitrogen.', NULL, NOW()),

-- Log NMAX (User 2)
(6, 3, 1, DATE_SUB(CURDATE(), INTERVAL 45 DAY), 6000, 125000.00, 'Yamaha Flagship Shop Bandung', 'Ganti oli Yamalube Super Matic dan pembersihan saringan udara.', NULL, NOW());

-- 5. Reminders Sample
INSERT INTO `reminders` (`id`, `vehicle_id`, `service_type_id`, `due_km`, `due_date`, `status`, `created_at`) VALUES
-- Vario 160: Oli mesin target 15000 KM (KM saat ini 14850 -> Sisa 150 KM = KUNING / MENDEKATI)
(1, 1, 1, 15000, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'pending', NOW()),
-- Vario 160: CVT Belt target 16000 KM (Sisa 1150 KM = HIJAU / AMAN)
(2, 1, 9, 16000, DATE_ADD(CURDATE(), INTERVAL 45 DAY), 'pending', NOW()),
-- Avanza: Oli mesin target 45000 KM (Sisa 2400 KM = HIJAU / AMAN)
(3, 2, 1, 45000, DATE_ADD(CURDATE(), INTERVAL 60 DAY), 'pending', NOW()),
-- Avanza: Radiator coolant target 50000 KM (Sisa 7400 KM = HIJAU / AMAN)
(4, 2, 10, 50000, DATE_ADD(CURDATE(), INTERVAL 150 DAY), 'pending', NOW()),
-- NMAX: Oli mesin target 8000 KM (KM saat ini 8200 -> Terlewat 200 KM = MERAH / WAJIB SERVIS)
(5, 3, 1, 8000, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'pending', NOW());
