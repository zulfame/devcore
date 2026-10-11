---
name: write-brief
description: Gunakan SEBELUM mengerjakan tugas non-trivial (lebih dari satu file, mengubah kontrak/skema/keamanan, atau permintaan yang kriterianya belum jelas). Menyusun brief tugas dari template, memastikan kriteria penerimaan dapat diuji, dan mendapat persetujuan pengguna sebelum kode diubah.
---

# Menyusun brief tugas (AG-15)

Tanpa brief berstatus `approved`, hook menolak perubahan pada file kode. Tujuan skill ini bukan birokrasi, melainkan memastikan "selesai" punya definisi yang bisa diuji.

## 1. Perlu brief?
- **Perlu:** fitur baru, perubahan perilaku/kontrak/skema, hal menyentuh keamanan atau data, permintaan yang hasil akhirnya belum jelas.
- **Tidak perlu:** perubahan dokumen, typo, komentar. File dokumen memang tidak terkena gerbang.
- Tugas kecil tetap butuh brief **ringkas** (3 bagian wajib saja).

## 2. Periksa yang sudah ada
Lihat `docs/briefs/`. Jika sudah ada brief untuk tugas yang sama, perbarui, jangan duplikat.

## 3. Gali kebutuhan dengan ringkas
- Baca permintaan dan kode terkait dulu. **Jangan bertanya hal yang bisa dijawab dari kode.**
- Ajukan hanya pertanyaan yang jawabannya mengubah hasil, maksimal 3–5 sekaligus, dengan usulan default di tiap pertanyaan agar pengguna cukup menjawab "ya".
- Hal kecil dan mudah dibatalkan: pilih default wajar, catat di *Risiko dan asumsi*.

## 4. Tulis brief
- Salin `.devcore/docs/templates/task-brief.md` ke `docs/briefs/NNNN-judul-singkat.md` (NNNN = nomor berikutnya, 4 digit; judul `kebab-case` bahasa Inggris). Status: `draft`.
- **Kriteria penerimaan harus dapat diuji:** setiap butir bisa dijawab "terpenuhi/belum" dengan bukti (tes, perintah, contoh I/O). Ganti kata kabur ("cepat", "bagus", "aman") dengan angka atau perilaku.
- Tulis **Di luar ruang lingkup** secara aktif; ini penjaga `AG-05`.
- Kosongkan *Pertanyaan terbuka* sebelum meminta persetujuan.

### Contoh kriteria dan batas lingkup
| | Buruk (tidak dapat diuji) | Baik (dapat dijawab "terpenuhi/belum" dengan bukti) |
|---|---|---|
| Kriteria | "Login berjalan baik dan cepat." | "`POST /login` dengan sandi salah → 401 dan tidak membuat sesi; 5 kegagalan beruntun dari satu IP dalam 1 menit → 429." |
| Kriteria | "Validasi tanggal lahir sudah benar." | "Tanggal di masa depan ditolak (422, 'tidak boleh di masa depan'); '29-02-2023' ditolak; '29-02-2024' diterima." |
| Di luar lingkup | "Tidak ada." | "Tidak mengubah format respons ekspor; tidak menyentuh modul `laporan`; tidak menambah dependency." |

## 5. Minta persetujuan
Ringkas brief di chat (tujuan, kriteria, di luar lingkup, asumsi) dan minta persetujuan eksplisit.
- **Dilarang** mengubah status ke `approved` sebelum pengguna menyatakan setuju di chat.
- Setelah setuju, ubah `Status: approved`. Hook akan meminta konfirmasi pengguna sekali lagi; itu normal.

## 6. Selama dan setelah pekerjaan
- Kebutuhan berubah di tengah jalan → perbarui brief, minta persetujuan ulang, baru lanjut.
- Selesai → skill `verify-done`: periksa tiap kriteria, isi *Catatan penyelesaian*, ubah `Status: done`.
