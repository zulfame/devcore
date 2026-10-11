# Brief: Adopsi proyek lama, serah terima sesi, dan versi kerangka

Status: approved
Tanggal: 2026-10-11
Jenis: lengkap

## Tujuan (wajib)
Membuat devcore mudah dan aman dipasang di proyek lama, diperbarui kemudian, dan tetap konsisten antar sesi agent: kerangka punya versi dan jalur pembaruan, agent membawa konteks dari sesi sebelumnya, dan proyek lama punya cara adopsi bertahap tanpa memaksa refactor. Berasal dari tinjauan peran Software Engineer dan Delivery Manager (prioritas 3).

## Kriteria penerimaan (wajib)
- [ ] `VERSION` (semver, awal 0.1.0) dan `CHANGELOG.md` yang merangkum riwayat sejauh ini.
- [ ] `.claude/devcore-rules.md` memuat aturan inti generik kerangka; `CLAUDE.md` devcore hanya memuat bagian khusus proyek dan mengimpor file itu dengan `@`. Masing-masing di bawah 200 baris.
- [ ] `.claude/devcore.manifest` mendefinisikan berkas `managed` (ditimpa saat pembaruan) dan `seed` (disalin sekali, lalu milik proyek).
- [ ] `scripts/sync-devcore.sh` memasang dan memperbarui kerangka ke proyek target dengan sifat: dry-run sebagai bawaan; `--apply` untuk menulis; menolak target non-git atau working tree kotor; menulis `.claude/devcore.lock` (versi, commit sumber, hash berkas); tidak menimpa berkas managed yang diubah lokal kecuali `--overwrite-modified`; menghapus berkas managed yang sudah tidak ada di sumber bila tidak diubah lokal; menggabungkan `.claude/settings.json` (union izin, hook ditambah, hook usang dibuang, pengaturan proyek dipertahankan); menambah impor `@.claude/devcore-rules.md` ke `CLAUDE.md` proyek, dan `@AGENTS.md` bila proyek punya `AGENTS.md` yang belum diimpor; menambah baris wajib ke `.gitignore`; tidak menyalin `CLAUDE.local.md`, `docs/briefs/`, `docs/adr/`, `README.md`; idempoten.
- [ ] `scripts/test-sync.sh` menguji: dry-run tanpa perubahan, instalasi baru, penggabungan settings yang sudah ada, penanganan `AGENTS.md`, idempoten, berkas managed dimodifikasi lokal, `--overwrite-modified`, pembaruan yang menghapus berkas usang dan hook usang, tolak working tree kotor, tolak non-git.
- [ ] `scripts/run-checks.sh` menjadi satu pintu pemeriksaan lokal dan CI; workflow diganti nama menjadi `devcore-checks.yml` dan memanggil skrip itu.
- [ ] Hook `session-status-loader.sh` (SessionStart) memuat ringkasan `docs/status.md` dan daftar brief berstatus approved ke konteks; diam bila tidak ada; keluaran dibatasi; ada tesnya.
- [ ] Templat `docs/templates/status.md` dan `docs/templates/project-profile.md`, `docs/status.md` untuk devcore sendiri, skill `profile-project`, dan `verify-done` memperbarui status serta membaca profil proyek.
- [ ] `docs/adopting-devcore.md` memandu adopsi bertahap pada proyek lama, termasuk aturan baseline utang teknis (`AG-16`) dan serah terima sesi (`AG-17`) di standar.
- [ ] Standar, peta penegakan, README, dan pemeriksa penamaan diselaraskan; semua tes lulus; CI hijau; instalasi nyata dari GitHub ke proyek percobaan sementara berhasil dan lolos `run-checks.sh`.

## Di luar ruang lingkup (wajib)
- Membuat tag/rilis GitHub (push tag butuh izin tersendiri) dan template repository GitHub (pengaturan platform).
- Perbaikan celah hook bash (prioritas 5), evaluasi agent dan subagent reviewer (prioritas 4), pengurangan duplikasi aturan (prioritas 6).
- Memigrasi proyek lama Anda yang sebenarnya; isinya belum diketahui.
- Pembaruan otomatis terjadwal.

## Konteks dan batasan (lengkap)
- Terverifikasi di dokumentasi Claude Code: impor `@path` relatif terhadap file pengimpor, maksimal empat tingkat, impor di dalam proyek tidak memicu dialog persetujuan; stdout hook SessionStart masuk ke konteks (juga setelah compaction); `additionalContext` di atas 10.000 karakter dipindah ke file.
- Jika proyek punya `AGENTS.md` tanpa `CLAUDE.md`/`CLAUDE.local.md`, Claude membaca `AGENTS.md`; menambah `CLAUDE.md` menghentikan itu kecuali `CLAUDE.md` mengimpor `@AGENTS.md`.
- Skrip kompatibel bash 3.2 (macOS) dan bash 5; membutuhkan `jq` dan `git`.
- Perubahan di `.claude/` melewati persetujuan pengguna.

## Contoh input dan output (lengkap)
- `scripts/sync-devcore.sh --target ~/proyek-lama` → menampilkan rencana (berkas baru/diperbarui/dilewati) tanpa menulis apa pun.
- `scripts/sync-devcore.sh --target ~/proyek-lama --apply` pada repo bersih → berkas terpasang, `devcore.lock` ditulis, perubahan belum di-commit sehingga bisa ditinjau atau dibuang dengan git.
- Pembaruan saat hook lokal diubah → berkas itu dilewati dengan pesan "diubah lokal".

## Risiko dan asumsi (lengkap)
- Skrip menyentuh proyek nyata. Mitigasi: dry-run bawaan, wajib git bersih, tidak menghapus berkas milik proyek, tidak melakukan commit.
- Penggabungan settings hanya mengenali hook devcore lewat nama berkas; hook proyek yang berbeda dipertahankan apa adanya.
- Asumsi: "lanjut prioritas 3" berarti menyetujui lingkup prioritas 3 dari tinjauan sebelumnya.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
(diisi saat selesai)
