# ADR-0001: Penegakan Aturan Berlapis untuk Agent

- **Status:** Diterima
- **Tanggal:** 2026-10-11

## Konteks
Aturan yang hanya ditulis di markdown sering dilanggar agent: saat menambah/mengubah/menghapus fungsi, pengguna harus menjelaskan atau menginstruksikan ulang. Penyebabnya, aturan teks hanyalah bagian dari konteks model:
- bersaing dengan isi tugas dan tersaring oleh perhatian model;
- dokumen panjang diperlakukan sebagai saran, bukan batasan;
- dapat hilang/terkompres pada percakapan panjang;
- tidak ada yang memeriksa kepatuhannya.

## Keputusan
Gunakan penegakan **berlapis**, makin ke atas makin pasti:
1. **Mesin (deterministik):** hook dan `permissions` di `.claude/settings.json` menolak/menahan tindakan; lint, test, dan CI memeriksa hasil. Tidak bergantung pada ingatan model.
2. **Prosedur:** skill di `.claude/skills/` memuat langkah kerja untuk situasi tertentu (ubah fungsi, verifikasi, keamanan), dimuat saat dibutuhkan.
3. **Konteks inti:** `CLAUDE.md` ringkas (dimuat tiap sesi) + hook `UserPromptSubmit` yang menyisipkan pengingat singkat setiap pesan.
4. **Referensi:** standar lengkap di `docs/standards/`, dibaca sesuai kebutuhan, bukan dimuat seluruhnya.
5. **Manusia:** review untuk aturan yang bersifat penilaian.

Setiap aturan dipetakan ke tingkat penegakannya di [enforcement-map.md](../enforcement-map.md). Saat agent dikoreksi karena melanggar aturan, tindak lanjutnya adalah menaikkan penegakan aturan itu ke tingkat mesin bila memungkinkan.

## Konsekuensi
- (+) Pelanggaran paling berbahaya dicegah, bukan hanya dilarang.
- (+) `CLAUDE.md` tetap singkat sehingga aturan inti tidak terdilusi.
- (−) Hook berbasis pola teks bisa dikelabui; ia pagar pengaman, bukan sandbox.
- (−) Hook dan tes perlu dirawat; perubahan pada hook butuh persetujuan pengguna.
- (−) Aturan yang bersifat penilaian tetap bergantung pada kepatuhan model dan review manusia.
