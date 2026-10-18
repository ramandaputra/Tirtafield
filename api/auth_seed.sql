-- ============================================================
-- SQL SCRIPT AUTENTIKASI TIRTAFIELD (LARAGON / PHPMYADMIN)
-- Database: tirtafield
-- Tabel: employee
-- ============================================================

USE `tirtafield`;

-- 1. Setup Admin Direktur
-- NIK: D001
-- PASS / PIN: 123456
UPDATE `employee` 
SET 
    `pin` = 123456, 
    `password` = '123456', 
    `occ_add_desc` = 'Dewan Direksi',
    `ishapus` = 0
WHERE `pgw_nup` = 'D001' OR `pgw_id` = 4;

-- 2. Setup Superadmin Pusimpel
-- NIK: P242101
-- PASS / PIN: 123456
-- Hapus entri lama jika ada untuk mencegah duplikasi
DELETE FROM `employee` WHERE `pgw_nup` = 'P242101';

-- Masukkan entri baru Superadmin Pusimpel
INSERT INTO `employee` (
    `pgw_nup`, 
    `pgw_nama`, 
    `occ_add_desc`, 
    `pin`, 
    `password`, 
    `ishapus`
) VALUES (
    'P242101', 
    'Superadmin Pusimpel', 
    'PUSIMPEL IT & System', 
    123456, 
    '123456', 
    0
);

-- Verifikasi data yang baru diupdate
SELECT `pgw_id`, `pgw_nup`, `pgw_nama`, `occ_add_desc`, `pin`, `password` 
FROM `employee` 
WHERE `pgw_nup` IN ('D001', 'P242101');
