# Brief: Gerbang brief tugas dan pemeriksaan otomatis di CI

Status: approved
Tanggal: 2026-10-11
Jenis: lengkap

## Tujuan (wajib)
Mengurangi hasil kerja agent yang "sesuai instruksi tetapi kurang" dengan (1) mewajibkan brief tugas yang disetujui sebelum kode diubah, dan (2) menambah lapisan pemeriksaan otomatis di repositori (CI) yang tidak bisa dilewati oleh kelalaian agent. Berasal dari tinjauan peran PM/BA dan Security/DevOps/QA (prioritas 1 dan 2).

## Kriteria penerimaan (wajib)
- [ ] Ada template brief (`docs/templates/task-brief.md`) dan skill `write-brief` yang memandu pengisiannya.
- [ ] Hook `pretool-brief-gate.sh` menolak Write/Edit ke file kode jika tidak ada brief berstatus `approved` dengan bagian Tujuan, Kriteria penerimaan, dan Di luar ruang lingkup terisi.
- [ ] Dokumen (`docs/`, `*.md`), `.claude/`, dan file di luar proyek tidak terkena gerbang.
- [ ] Mode gerbang dapat diatur (`block`, `ask`, `off`) lewat `.claude/devcore.conf`, dan perubahan konfigurasi itu butuh persetujuan pengguna.
- [ ] Menulis `Status: approved` ke brief memicu permintaan persetujuan kepada pengguna.
- [ ] `scripts/check-naming.sh`, `check-links.sh`, dan `check-weakened-tests.sh` ada, dapat dijalankan lokal dan di CI, serta punya tes (`scripts/test-scripts.sh`) yang mencakup kasus lulus dan gagal.
- [ ] Workflow `.github/workflows/ci.yml` menjalankan semua tes dan pemeriksaan di atas dengan permission minimum.
- [ ] Standar, `CLAUDE.md`, README, dan peta penegakan diperbarui; semua tes hook dan skrip lulus; workflow CI hijau di GitHub.

## Di luar ruang lingkup (wajib)
- Perbaikan celah dan false positive pada `pretool-bash-guard.sh` (prioritas 5).
- Berkas serah terima sesi, versi kerangka, dan jalur adopsi proyek lama (prioritas 3).
- Skenario evaluasi agent dan subagent reviewer (prioritas 4).
- Branch protection dan pengaturan GitHub lain (platform, bukan proyek).

## Konteks dan batasan (lengkap)
- Hook berjalan hanya di sesi Claude Code; CI adalah satu-satunya lapisan yang tetap berlaku untuk commit manual.
- Skrip harus kompatibel dengan bash 3.2 (macOS) dan bash 5 (runner Linux).
- Penamaan mengikuti `DC-05`. Perubahan pada `.claude/` melewati persetujuan pengguna.

## Contoh input dan output (lengkap)
- Edit `src/app.py` tanpa brief approved → ditolak dengan pesan menunjuk skill `write-brief`.
- Diff berisi `it.skip(` baru di file non-dokumen → CI gagal, kecuali baris diberi `devcore-allow: <alasan>`.

## Risiko dan asumsi (lengkap)
- Gerbang tidak menilai kualitas isi kriteria, hanya keberadaannya; kualitas dijaga skill dan review pengguna.
- Brief `approved` yang basi dapat membuka gerbang untuk pekerjaan lain; ditutup dengan mengubah status `done`.
- Penulisan file lewat shell (`echo > file`) melewati gerbang; dicatat sebagai celah di peta penegakan.
- Asumsi: pengguna menyetujui brief ini lewat permintaan "mulai dari prioritas 1 dan 2".

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
(diisi saat selesai)
