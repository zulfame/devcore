# Mengadopsi devcore di Proyek yang Sudah Berjalan

Panduan ini untuk memasang devcore pada proyek lama tanpa mengganggunya, lalu menjaganya tetap mutakhir. Sumber kerangka: https://github.com/zulfame/devcore

## Prinsip
1. **Baseline, bukan refactor.** Kondisi proyek saat adopsi dicatat apa adanya. Penyimpangan lama tidak diperbaiki kecuali lewat brief tersendiri (`AG-16`).
2. **Semua perubahan bisa ditinjau dan dibuang.** Sinkronisasi tidak pernah commit dan menolak berjalan di working tree yang kotor.
3. **Naik bertahap.** Mulai dari gerbang brief mode `ask`, naikkan ke `block` setelah alurnya nyaman.
4. **Kustomisasi tidak ditimpa.** Berkas milik kerangka dipisahkan dari berkas milik proyek (tabel di bawah).

## Prasyarat
`git` dan `jq` terpasang; proyek adalah repositori git dengan working tree bersih; Claude Code. CI GitHub bersifat opsional.

## Langkah adopsi
1. **Siapkan.** Buat cabang, mis. `chore/adopt-devcore`. Pastikan `git status` bersih.
2. **Dry-run** (dari klon devcore): `scripts/sync-devcore.sh --target /jalur/proyek`. Baca rencananya. Tidak ada yang ditulis.
3. **Terapkan:** tambahkan `--apply`. Perubahan belum di-commit. Tinjau dengan `git status` dan `git diff`.
4. **Periksa tiga hal khusus:**
   - `CLAUDE.md`: hanya bertambah satu baris impor `@.claude/devcore-rules.md`; isi Anda utuh. Bila belum ada, dibuat baru.
   - `.claude/settings.json`: izin dan hook Anda tetap ada; milik devcore ditambahkan.
   - `AGENTS.md`: bila proyek punya `AGENTS.md` tetapi belum punya `CLAUDE.md`, `CLAUDE.md` baru mengimpornya agar tetap terbaca. Bila `CLAUDE.md` sudah ada dan tidak mengimpornya, skrip tidak mengubah perilaku itu dan hanya memberi catatan.
5. **Atur mode gerbang** di `.claude/devcore.conf`: `BRIEF_GATE=ask` untuk minggu pertama (setiap perubahan kode ditanyakan ke Anda), lalu `block`.
6. **Profilkan proyek.** Di sesi Claude Code, jalankan skill `profile-project`. Ia menemukan perintah proyek, mengukur baseline, mencatat konvensi dan utang teknis ke `docs/project-profile.md`, tanpa mengubah kode. Tinjau hasilnya.
7. **Jalankan pemeriksaan:** `scripts/run-checks.sh`. Bila ada yang gagal karena berkas lama proyek (mis. nama dokumen di `docs/` yang tidak sesuai `DC-05`), catat sebagai utang teknis, jangan diubah massal.
8. **Commit** sebagai satu commit terpisah, mis. `chore: adopsi devcore v0.1.0`.
9. **Tambahkan test proyek ke CI.** `.github/workflows/devcore-checks.yml` hanya menjalankan pemeriksaan kerangka. Berkas itu milik proyek setelah dipasang, jadi tambahkan langkah test/lint/build proyek Anda di sana.

## Milik kerangka vs milik proyek
| Jenis | Berkas | Perilaku saat pembaruan |
|---|---|---|
| **Managed** | `.claude/devcore-rules.md`, hook, skill, `scripts/`, `docs/engineering-standard.md`, `docs/enforcement-map.md`, templat | Ditimpa bila belum diubah lokal; dilewati bila diubah lokal |
| **Seed** | `.claude/devcore.conf`, `.github/workflows/devcore-checks.yml`, `docs/status.md`, `docs/project-profile.md` | Disalin sekali; sesudahnya milik proyek, tidak disentuh |
| **Digabung** | `.claude/settings.json` | Izin dan hook ditambah, hook usang dibuang, pengaturan proyek dipertahankan |
| **Hanya ditambah** | `CLAUDE.md` (baris impor), `.gitignore` (baris wajib) | Isi proyek tidak disentuh |
| **Tidak dipasang** | `CLAUDE.local.md`, `README.md`, `CHANGELOG.md`, `docs/briefs/`, `docs/adr/` milik devcore | — |

Aturan praktis: **jangan mengedit berkas managed di proyek.** Kustomisasi ditulis di `CLAUDE.md` proyek, `.claude/devcore.conf`, dan berkas seed.

## Memperbarui
Dari dalam proyek (working tree bersih):
```bash
scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git
scripts/sync-devcore.sh --source https://github.com/zulfame/devcore.git --apply
```
Versi terpasang tercatat di `.claude/devcore.lock`; riwayat perubahan ada di `CHANGELOG.md` repositori devcore. Baca rencana dry-run sebelum `--apply`.

Bila ada baris `LEWATI ... (diubah lokal)`:
- Bandingkan berkas Anda dengan versi kerangka.
- Kalau perubahan Anda layak dipakai semua proyek, kirimkan ke devcore.
- Kalau tidak, terima versi kerangka dengan `--overwrite-modified` dan pindahkan kustomisasi ke tempat yang benar.

Berkas managed yang sudah dihapus dari kerangka ikut dihapus dari proyek bila belum diubah lokal.

## Serah terima sesi
Agent tidak mengingat sesi sebelumnya. Hook `session-status-loader.sh` memuat awal `docs/status.md` dan daftar brief `approved` di setiap awal sesi (termasuk setelah compaction). Agent memperbarui `docs/status.md` di akhir tugas lewat skill `verify-done` (`AG-17`). Jaga berkas itu singkat (sekitar 40 baris).

## Hal yang perlu diketahui
- Hook hanya berjalan di sesi Claude Code. Commit manual Anda tetap diperiksa oleh CI, bukan oleh hook.
- Impor `@` di `CLAUDE.md` dan stdout hook `SessionStart` mengikuti dokumentasi Claude Code. Bila aturan tidak termuat, periksa dengan `/memory` di terminal Claude Code Anda.
- Sinkronisasi hanya mengenali hook devcore dari nama berkasnya; hook proyek dengan nama lain dipertahankan.

## Melepas devcore
Hapus berkas managed yang tercatat di `.claude/devcore.lock`, baris impor di `CLAUDE.md`, entri hook devcore di `.claude/settings.json`, lalu `.claude/devcore.lock`. Berkas seed dan isi proyek tetap milik Anda.
