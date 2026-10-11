# Brief 0013: Temuan uji starter kit Laravel
Status: done

## Tujuan
Memperbaiki dua masalah yang ditemukan saat memasang devcore ke starter kit Laravel asli: (1) `check-links.sh` memindai `vendor/` dan `node_modules/` sehingga `run-checks.sh` gagal di proyek sehat; (2) `.gitignore` proyek yang mengabaikan berkas devcore (`/.claude`, `/CLAUDE.md`) tidak dilaporkan sync, padahal berkas itu tidak akan ter-commit.

## Kriteria penerimaan
- `check-links.sh` hanya memindai berkas markdown yang dilacak atau tidak diabaikan git; di proyek terpasang (bukan repo devcore) cakupannya `CLAUDE.md`, `docs/`, dan `.devcore/`. Di starter kit Laravel hasil pemasangan, `run-checks.sh` lulus.
- `sync-devcore.sh` (dry-run dan apply) mencetak INFO untuk tiap berkas devcore yang diabaikan `.gitignore` target (`CLAUDE.md`, `.claude/settings.json`, `.claude/devcore.conf`, `.claude/skills/*`, `.devcore/*`), tanpa mengubah `.gitignore` milik proyek.
- Tes baru untuk keduanya; `run-checks.sh` dan `test-sync.sh` lulus; CI hijau di PR.

## Di luar ruang lingkup
- Mengubah `.gitignore` proyek otomatis, pemeriksa lain, aturan per stack.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.6.3), dibuktikan di starter kit Laravel asli: run-checks lulus (sebelumnya gagal karena tautan di vendor/) dan sync memberi INFO bahwa .gitignore mengabaikan CLAUDE.md dan .claude/. 4 tes baru.
