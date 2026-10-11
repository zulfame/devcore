---
name: profile-project
description: Gunakan saat devcore baru dipasang di proyek yang sudah berjalan, atau bila docs/project-profile.md kosong atau usang. Menemukan perintah proyek, mencatat kondisi baseline, konvensi, dan utang teknis tanpa mengubah kode.
---

# Memprofilkan proyek yang sudah ada (AG-16)

Tujuan: agent tahu cara menjalankan, menguji, dan menilai proyek **tanpa menebak**, dan penyimpangan lama tercatat sebagai baseline, bukan menjadi pekerjaan tersembunyi. **Skill ini tidak mengubah kode.** Hanya `docs/project-profile.md` (dan bila perlu `docs/status.md`) yang ditulis.

## 1. Temukan perintah proyek
Baca berurutan: `README`, `CONTRIBUTING`, `package.json` / `Makefile` / `pyproject.toml` / `composer.json` / `go.mod` / `Cargo.toml`, file CI yang sudah ada (`.github/workflows/`, dll.), dan `docker-compose` bila ada. Catat perintah untuk: pasang dependency, jalankan, test, lint/format, type check, build.
- Perintah yang **tidak ditemukan** ditulis "tidak ada" — jangan mengarang (AG-10).
- Sumbernya dicatat (mis. "dari package.json scripts.test").

## 2. Ukur baseline
Jalankan test, lint, type check, dan build **hanya bila aman**: tidak menyentuh database/layanan nyata, tidak mengirim data keluar, tidak mengubah berkas milik proyek. Ragu → tanya pengguna dulu.
- Catat hasil apa adanya: jumlah lulus dan gagal, daftar test yang sudah gagal sebelum adopsi, jumlah peringatan lint.
- Yang tidak bisa dijalankan dicatat beserta alasannya.

## 3. Temukan konvensi
Ambil sampel beberapa berkas yang mewakili. Catat struktur folder, penamaan, gaya, pola penanganan error, cara tes ditulis. Ini menjadi acuan `AG-02` untuk kode baru.

## 4. Catat utang teknis (hanya mengamati)
Bandingkan dengan standar secara ringan dan catat **temuan yang terbukti dari kode**, lengkap dengan jalur berkas dan aturan terkait. Contoh yang layak dicari:
- Secret atau berkas `.env` asli yang ter-commit (SC-07).
- Validasi hanya di UI tanpa pemeriksaan ulang di backend (VL-03).
- Query dari string input mentah (SC-03).
- Tidak ada test pada alur kritis; test yang di-skip (TS-*).
- Dependency tanpa lockfile (DP-01).
Jangan memperbaikinya. Temuan keamanan serius **dilaporkan ke pengguna segera**, bukan hanya dicatat.

Contoh baris utang teknis. Salah: "Kodenya kurang rapi." (tanpa lokasi atau aturan). Benar:

| Temuan | Lokasi | Dampak | Aturan terkait |
|---|---|---|---|
| Validasi hanya di formulir; endpoint tidak memeriksa ulang | `src/api/pendaftaran.js:41` | Data tidak valid bisa masuk lewat API langsung | VL-03 |

## 5. Catat prasyarat lingkungan
Hal yang dibutuhkan proyek tetapi dikelola di luar proyek (TLS, backup, monitoring, dsb.) ditulis di bagian *Prasyarat lingkungan* (OS-01).

## 6. Tinjau bersama pengguna
Ringkas isi profil di chat: perintah yang ditemukan, baseline, tiga utang teknis teratas, dan pertanyaan yang tersisa. Profil baru dianggap final setelah pengguna meninjau.

## Setelah itu
- Atur `BRIEF_GATE=ask` di `.claude/devcore.conf` untuk minggu-minggu awal (atas persetujuan pengguna), lalu naikkan ke `block` bila alurnya sudah nyaman.
- Utang teknis dikerjakan hanya lewat brief tersendiri.
