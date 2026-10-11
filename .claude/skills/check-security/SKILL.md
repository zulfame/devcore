---
name: check-security
description: Gunakan saat perubahan menyentuh autentikasi, otorisasi, input pengguna, file upload, query database, secret, konfigurasi, atau integrasi eksternal. Memeriksa perubahan terhadap Bagian 6–8 standar.
---

# Pemeriksaan keamanan perubahan

Periksa perubahan Anda terhadap daftar ini. Laporkan tiap butir sebagai OK, tidak berlaku, atau temuan.

## Akses
- [ ] Setiap operasi dilindungi authN dan authZ, termasuk kepemilikan objek / IDOR (SC-01).
- [ ] Peran dan akun memakai hak minimum (SC-02).

## Input
- [ ] Backend memvalidasi ulang input; tidak mengandalkan UI (VL-03).
- [ ] Query parameterized; tidak ada string query/perintah dari input mentah (SC-03).
- [ ] Ada batas ukuran request, jumlah item, ukuran dan jenis file (VL-07).
- [ ] XSS, CSRF, SSRF, path traversal dipertimbangkan sesuai konteks (SC-04).

## Data dan secret
- [ ] Tidak ada secret di kode, log, test, atau dokumen (SC-07, LG-02).
- [ ] Password hanya disimpan sebagai hash adaptif (SC-05).
- [ ] Respons error tidak membocorkan stack trace atau detail internal (SC-12).
- [ ] Data sensitif di-mask pada log dan respons yang tidak memerlukannya (SC-10).

## Ketahanan
- [ ] Panggilan eksternal punya timeout dan retry terbatas (API-04).
- [ ] Endpoint sensitif punya rate limit/proteksi brute force di level aplikasi (SC-08).
- [ ] Konfigurasi gagal aman bila hilang/tidak valid (CF-02, CF-03).

## Lapor
Sebut temuan, tingkat dampak, dan usulan perbaikan. Jangan menyatakan "aman"; nyatakan apa yang diperiksa dan apa yang tidak.
Hal di luar proyek (TLS, firewall, dll.) → catat sebagai prasyarat lingkungan (Bagian 18), bukan dikerjakan.
