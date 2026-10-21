-- ============================================================
-- SQL SCRIPT BIDANG & SEKSI BIDANG TIRTAFIELD (LARAGON / PHPMYADMIN)
-- Database: tirtafield
-- ============================================================

USE `tirtafield`;

-- 1. Buat Tabel ref_bidang
CREATE TABLE IF NOT EXISTS `ref_bidang` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nama` VARCHAR(150) NOT NULL UNIQUE,
    `kode` VARCHAR(50) NULL,
    `urutan` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Buat Tabel ref_seksi_bidang
CREATE TABLE IF NOT EXISTS `ref_seksi_bidang` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `bidang_id` INT NOT NULL,
    `nama` VARCHAR(150) NOT NULL,
    `kode` VARCHAR(50) NULL,
    `urutan` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (`bidang_id`),
    CONSTRAINT `fk_ref_seksi_bidang` FOREIGN KEY (`bidang_id`) REFERENCES `ref_bidang` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Tabel Alias `bidang` dan `seksi_bidang` (akses langsung phpMyAdmin)
CREATE TABLE IF NOT EXISTS `bidang` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nama` VARCHAR(150) NOT NULL UNIQUE,
    `kode` VARCHAR(50) NULL,
    `urutan` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `seksi_bidang` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `bidang_id` INT NOT NULL,
    `nama` VARCHAR(150) NOT NULL,
    `kode` VARCHAR(50) NULL,
    `urutan` INT DEFAULT 0,
    INDEX (`bidang_id`),
    CONSTRAINT `fk_seksi_bidang_alias` FOREIGN KEY (`bidang_id`) REFERENCES `bidang` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Tambahkan kolom seksi_bidang ke tabel employee jika belum ada
ALTER TABLE `employee` ADD COLUMN IF NOT EXISTS `seksi_bidang` VARCHAR(150) NULL DEFAULT NULL AFTER `occ_add_desc`;

-- 5. Seed Data Bidang & Seksi Bidang
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `ref_seksi_bidang`;
TRUNCATE TABLE `ref_bidang`;
TRUNCATE TABLE `seksi_bidang`;
TRUNCATE TABLE `bidang`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Dewan Direksi (Urutan Pertama, Pilihan: Direktur)
INSERT INTO `ref_bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (1, 'Dewan Direksi', 'DIREKSI', 1);
INSERT INTO `bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (1, 'Dewan Direksi', 'DIREKSI', 1);

INSERT INTO `ref_seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(1, 'Direktur', 'DIREKTUR', 1);

INSERT INTO `seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(1, 'Direktur', 'DIREKTUR', 1);

-- 2. Bidang Hubungan Langganan
INSERT INTO `ref_bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (2, 'Bidang Hubungan Langganan', 'HUB_LANGGANAN', 2);
INSERT INTO `bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (2, 'Bidang Hubungan Langganan', 'HUB_LANGGANAN', 2);

INSERT INTO `ref_seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(2, 'Seksi Pembacaan Meter', 'SEKSI_PEMBACAAN_METER', 1),
(2, 'Seksi Perawatan Meter', 'SEKSI_PERAWATAN_METER', 2);

INSERT INTO `seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(2, 'Seksi Pembacaan Meter', 'SEKSI_PEMBACAAN_METER', 1),
(2, 'Seksi Perawatan Meter', 'SEKSI_PERAWATAN_METER', 2);

-- 3. Bidang Teknik
INSERT INTO `ref_bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (3, 'Bidang Teknik', 'TEKNIK', 3);
INSERT INTO `bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (3, 'Bidang Teknik', 'TEKNIK', 3);

INSERT INTO `ref_seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(3, 'Seksi Perencanaan', 'SEKSI_PERENCANAAN', 1),
(3, 'Seksi Distribusi', 'SEKSI_DISTRIBUSI', 2),
(3, 'Seksi Survei & Verifikasi Teknis', 'SEKSI_SURVEI_VERIFIKASI_TEKNIS', 3);

INSERT INTO `seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(3, 'Seksi Perencanaan', 'SEKSI_PERENCANAAN', 1),
(3, 'Seksi Distribusi', 'SEKSI_DISTRIBUSI', 2),
(3, 'Seksi Survei & Verifikasi Teknis', 'SEKSI_SURVEI_VERIFIKASI_TEKNIS', 3);

-- 4. Satuan Pengendalian Kehilangan Air
INSERT INTO `ref_bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (4, 'Satuan Pengendalian Kehilangan Air', 'SPKA', 4);
INSERT INTO `bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (4, 'Satuan Pengendalian Kehilangan Air', 'SPKA', 4);

INSERT INTO `ref_seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(4, 'Bidang Kehilangan Air', 'BIDANG_KEHILANGAN_AIR', 1),
(4, 'Bidang Analisa Jaringan & GIS', 'BIDANG_ANALISA_JARINGAN_GIS', 2);

INSERT INTO `seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(4, 'Bidang Kehilangan Air', 'BIDANG_KEHILANGAN_AIR', 1),
(4, 'Bidang Analisa Jaringan & GIS', 'BIDANG_ANALISA_JARINGAN_GIS', 2);

-- 5. PUSIMPEL IT & System
INSERT INTO `ref_bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (5, 'PUSIMPEL IT & System', 'PUSIMPEL_IT', 5);
INSERT INTO `bidang` (`id`, `nama`, `kode`, `urutan`) VALUES (5, 'PUSIMPEL IT & System', 'PUSIMPEL_IT', 5);

INSERT INTO `ref_seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(5, 'Superadmin Pusimpel', 'SUPERADMIN_PUSIMPEL', 1),
(5, 'Staff IT & Jaringan', 'STAFF_IT_JARINGAN', 2);

INSERT INTO `seksi_bidang` (`bidang_id`, `nama`, `kode`, `urutan`) VALUES
(5, 'Superadmin Pusimpel', 'SUPERADMIN_PUSIMPEL', 1),
(5, 'Staff IT & Jaringan', 'STAFF_IT_JARINGAN', 2);
