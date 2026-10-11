# Brief 0009: Tutup celah interpreter, uji pemasangan existing, uji buta putaran 3
Status: done

## Tujuan
Menutup dua celah yang terbuka lagi di 0.5.1 (one-liner interpreter yang menghapus berkas atau membaca secret), membuktikan pemasangan ke proyek existing dari GitHub, dan membuktikan jalur mesin lewat perilaku agent.

## Kriteria penerimaan
- `python3 -c "...shutil.rmtree..."`, `node -e "...rmSync..."` (juga heredoc ke interpreter) diblokir; one-liner yang tidak menghapus/membaca secret tetap lolos; pemeriksaan tidak lebih dari ±25 baris tambahan.
- `.devcore/hooks/test-hooks.sh` dan `.devcore/scripts/run-checks.sh` lulus.
- Pemasangan dari klon GitHub ke repo existing yang memuat `CLAUDE.md`, skill senama, dan `settings.json` berhook sendiri: tidak ada yang tertimpa, laporan bentrok benar, `run-checks.sh` di proyek hasil lulus.
- Putaran 3 uji buta dengan brief yang sudah di-commit `approved`, rubrik dikunci (hash) sebelum jalan; laporan memisahkan "ditahan mesin" dari "dipatuhi agent".

## Di luar ruang lingkup
- Mengembalikan SQL/migrasi, paket OS, `mv` keluar proyek; hook Stop; mekanisme baru lain; memangkas tokenizer.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai. Celah interpreter ditutup (0.5.2); pemasangan existing dari klon GitHub diuji dan menemukan bug AGENTS.md (0.5.3); putaran 3 dijalankan dan menemukan celah `git checkout <berkas>` (0.5.4). Hasil di `docs/uji-buta/hasil.md`.
