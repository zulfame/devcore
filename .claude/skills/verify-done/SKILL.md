---
name: verify-done
description: Gunakan SEBELUM menyatakan tugas selesai, lulus, atau siap. Menjalankan Definition of Done dan memastikan laporan akhir jujur dan berbasis bukti.
---

# Verifikasi sebelum menyatakan selesai

Dilarang menulis "selesai", "lulus", atau "sudah berfungsi" tanpa bukti yang **benar-benar dijalankan** (AG-08).

## 1. Temukan perintah proyek
Cari di `README.md`, `TESTING.md`, `package.json`/`Makefile`/`pyproject.toml`/sejenisnya. **Jangan mengarang perintah.** Jika tidak ditemukan, katakan demikian di laporan.

## 2. Jalankan dan baca hasilnya
- Test, lint, type check, build yang tersedia.
- Baca output sampai akhir. Kegagalan yang tidak terkait tetap dilaporkan.
- Jangan melemahkan pemeriksaan agar lulus (AG-09): tidak ada skip, ignore, `any`, atau menghapus test.

## 3. Periksa Definition of Done
- [ ] Perilaku yang diminta terbukti berfungsi.
- [ ] Test relevan ada (normal, negatif, batas; regression untuk bug).
- [ ] Semua pemeriksaan proyek lulus.
- [ ] Tidak ada secret, debug code, atau dead code yang ditinggalkan.
- [ ] Kontrak yang berubah sinkron di semua lapisan, dokumen, dan test.
- [ ] Dokumentasi/changelog terdampak diperbarui.
- [ ] Perubahan tidak keluar dari ruang lingkup yang diminta (AG-05).

## 4. Laporan akhir (format tetap)
1. **Ringkasan**: apa yang diubah (file dan alasan).
2. **Bukti**: perintah yang dijalankan dan hasilnya.
3. **Tidak dijalankan / gagal**: apa dan mengapa.
4. **Asumsi dan risiko tersisa**.
5. **Tindak lanjut** untuk pengguna atau tim infrastruktur bila ada (OS-03).
