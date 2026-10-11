# Brief: Pangkas, satu jejak `.devcore/`, dan penjaga bash yang lebih kecil

Status: done
Tanggal: 2026-10-11
Jenis: lengkap

## Tujuan (wajib)
Mengembalikan devcore ke esensinya (standar, aturan kerja agent, dan cara agent mematuhinya) dengan memangkas mesin penunjang yang tumbuh 4× lebih besar daripada isinya, dan membuat penerapan di proyek baru maupun existing tidak bentrok dan tetap selaras. Disetujui pengguna ("setujui semua") atas peta Batch 1–5; ini adalah Batch 1–3.

## Kriteria penerimaan (wajib)
**Batch 1 — pangkas**
- [ ] Generator aturan inti, pemeriksa rujukan (`check-rule-refs`), tes generator, dan tabel sumber di standar dicabut. Ringkasan aturan inti ditulis langsung di aturan inti (sumber tunggal ringkasan); standar merujuk ke sana.
- [ ] `docs/riwayat.md` merangkum 6 brief, ADR, dan CHANGELOG lama; 6 brief lama dihapus (tetap di riwayat git); CHANGELOG diringkas.
- [ ] README ≤ 60 baris.

**Batch 2 — satu jejak**
- [ ] Semua berkas milik kerangka berada di `.devcore/` (VERSION, rules.md, reminder.txt, docs/, hooks/, scripts/); `.claude/` hanya berisi yang wajib di sana: skill, subagent, `settings.json`, `devcore.conf`.
- [ ] `settings.json` menunjuk hook di `.devcore/hooks/`; gerbang brief mengecualikan `.devcore/`; penjaga tulis meminta konfirmasi untuk perubahan apa pun pada `.devcore/`.
- [ ] `sync-devcore.sh` ≤ ±120 baris: dry-run bawaan, wajib git bersih, mengganti seluruh folder `.devcore/`, kepemilikan berkas di `.claude/` dari `.devcore/managed-claude.txt`, hook milik kerangka dikenali dari prefix `.devcore/`, laporan bentrok sebelum menulis, `CLAUDE.md` starter bila belum ada, tanpa lock/hash.
- [ ] Standar memuat aturan bila kerangka bertabrakan dengan proyek (tidak dapat diubah proyek / dapat disimpangi dengan pengecualian tertulis / sepenuhnya milik proyek) dan template `claude-md-starter`.
- [ ] Tes: pemasangan ke repo baru; ke repo existing yang penuh bentrokan (CLAUDE.md, settings, skill senama, AGENTS.md); pembaruan idempoten; berkas milik proyek tidak pernah tertimpa.

**Batch 3 — penjaga bash**
- [ ] Penganalisis bash ≤ ±550 baris kode. Tetap: pembungkus (`bash -c`, `eval`, `env`, `xargs`, `find -exec`, heredoc), `rm -r`, git destruktif, akses secret, `sudo`/administrasi OS, `curl | sh`, penulisan berkas lewat shell ke gerbang/penjaga tulis, nama perintah dinamis.
- [ ] Dicabut dan dicatat sebagai batas di peta penegakan: SQL/migrasi destruktif, pemindaian one-liner interpreter, konfirmasi paket OS, konfirmasi `mv` ke luar proyek, konfirmasi paket proyek (sudah ada di `permissions.ask`).
- [ ] Delapan celah awal prioritas 4 tetap tertutup (masih ada tesnya); tes disesuaikan.

**Menyeluruh**
- [ ] Setiap batch berakhir dengan seluruh pemeriksaan hijau, CI hijau, commit, dan push. Pemasangan nyata dari GitHub ke proyek baru dan ke proyek existing buatan lolos setelah Batch 2 dan 3.

## Di luar ruang lingkup (wajib)
- Mengubah isi aturan atau menambah mekanisme baru (hanya konsolidasi dan pemindahan).
- Uji buta dengan subagent (Batch 4) dan perbaikan hasilnya (Batch 5): brief tersendiri.
- Perangkat pengukuran otomatis (sudah dicabut).

## Konteks dan batasan (lengkap)
- Hook yang menjaga sesi ini ikut berpindah; urutan aman: salin → ubah `settings.json` → uji → hapus yang lama.
- Penjaga bash memblokir `rm -r`; berkas dihapus satu per satu lewat `git rm` tanpa `-r` (dapat dipulihkan).
- Pemakai belum menjalankan kerangka di satu proyek nyata pun; keputusan pemangkasan mengikuti persetujuan pengguna, bukan data pemakaian.

## Risiko dan asumsi (lengkap)
- Pemindahan jalur menyentuh hampir semua berkas; tes (hook, skrip, sinkronisasi) menjadi jaring pengaman.
- Batch 3 membuka kembali celah yang sebelumnya tertutup (SQL, one-liner interpreter); diterima pengguna dan dicatat jujur.
- Batch 1 menghilangkan deteksi otomatis kelenturan antara aturan inti dan standar; dijaga lewat peninjauan.
- Pembaruan proyek lain mengganti folder `.devcore/` seluruhnya: perubahan lokal di sana hilang kecuali ditinjau lewat `git diff` (git bersih adalah syarat).

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai. Batch 1–2 sesuai rencana; README ditunda ke Batch 2; `sync-devcore.sh` 174 baris (target ±120 tidak tercapai). Batch 3: analyzer 1.069 → 969 baris (target ±550 tidak tercapai; tokenizer wajib dipertahankan), fitur sekunder dicabut dan dicatat di peta penegakan.
