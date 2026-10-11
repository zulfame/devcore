# Brief 0022: Bukti penutupan brief diperiksa di CI
Status: done

## Tujuan
Temuan pemakaian nyata: agent melewati tinjauan independen (AG-19) dan tidak ada catatan bagian standar yang diperiksa; satu-satunya penegak AG-19 adalah ingatan agent. Pindahkan titik pengecekan ke luar agent: brief yang baru ditutup (`Status: done`) pada sebuah PR/commit harus memuat bukti penutupan, dan `run-checks.sh` (jadi CI) gagal bila tidak.

## Kriteria penerimaan
- Template brief memuat bagian "Tinjauan independen" (baris `Verdict:`) dan "Bagian standar yang diperiksa".
- `check-brief-closure.sh` memeriksa hanya brief yang berubah menjadi `done` pada diff terhadap base: butuh verdict (LAYAK / PERLU PERBAIKAN / TIDAK DAPAT DINILAI, atau TIDAK DIPERLUKAN dengan alasan hanya bila diff tanpa perubahan kode) dan bagian standar terisi dengan minimal satu ID aturan; brief lama yang sudah `done` tidak diperiksa (AG-16); tanpa base → DILEWATI.
- Keterlacakan (usulan pengguna: pengguna tidak perlu membaca standar, agent yang menerapkannya): template dan skill `write-brief` memuat bagian "Standar yang berlaku" (ID aturan dipilih agent saat menyusun brief, ditinjau pengguna saat menyetujui); pemeriksa penutupan mewajibkan tiap ID itu muncul dengan hasilnya di "Bagian standar yang diperiksa" (brief lama tanpa bagian itu tidak dikenai syarat ini; rename brief ikut diperiksa).
- Terpasang di `run-checks.sh`; tes otomatis mencakup lulus, gagal, dan dilewati; teks skill `verify-done`, `write-brief`, dan `rules.md` menegaskan aturan berlaku per tugas dan tidak gugur oleh catatan "sudah dipanggil" setelah konteks dipadatkan.
- Peta penegakan AG-19 mencatat penegakan baru dan batasnya (bukti bisa ditulis tanpa memanggil peninjau); hook pencatat dan pengingat Stop masuk backlog.
- Pekerjaan ini sendiri melewati tinjauan `review-changes`, dengan hasilnya dicatat di brief ini.

## Di luar ruang lingkup
- Hook runtime baru (PostToolUse pencatat, pengingat Stop), menilai kualitas isi tinjauan, memeriksa brief lama.

## Pertanyaan terbuka
Tidak ada.

## Standar yang berlaku
AG-19 (tinjauan independen), DC-06 (dokumen dan kode paralel), AG-16 (brief lama tidak diperiksa), AG-17 (status), AG-09 (tes tidak dilemahkan), TS-07 (test regresi untuk perilaku baru).

## Catatan penyelesaian
Selesai (0.8.0). `check-brief-closure.sh` terpasang di `run-checks.sh`/CI; template dan skill `write-brief` (langkah 3b), `verify-done`, serta `rules.md` diperbarui. Keterlacakan "Standar yang berlaku" -> "Bagian standar yang diperiksa" ditambahkan atas usulan pengguna (pengguna tidak perlu membaca standar). 15 tes baru di `test-scripts.sh` (total 49 lulus); `run-checks.sh` lulus. Backlog (hook pencatat, pengingat Stop) dicatat di `docs/status.md`.

## Tinjauan independen
Verdict: LAYAK
Putaran 1 (`review-changes`): PERLU PERBAIKAN. Temuan: backlog belum ada di `docs/status.md`; rename brief lolos dari pemeriksaan (`--diff-filter=AM`). Keduanya diperbaiki (backlog ditambah, filter `AMR`). Putaran 2: LAYAK, tanpa pelanggaran aturan. Risiko tersisa yang dicatat peninjau: tidak ada tes khusus rename, skrip diuji di macOS (CI Linux diperiksa di PR), dan hanya commit yang diperiksa.

## Bagian standar yang diperiksa
- AG-19: tinjauan dua putaran dicatat di atas; pemeriksa CI baru menegakkan bukti tertulis, batasnya di peta penegakan.
- DC-06: README, CHANGELOG, peta penegakan, template, dan skill diperbarui bersama kode; hasil silang diverifikasi peninjau.
- AG-16: hanya brief yang baru berubah menjadi done yang diperiksa; brief lama dibebaskan (tes "brief lama tidak diperiksa").
- AG-17: `docs/status.md` diperbarui (fokus dan backlog).
- AG-09: tidak ada tes atau pemeriksaan dilemahkan; hanya ditambah.
- TS-07: perilaku baru dicakup tes (gagal tanpa bukti, lulus dengan bukti, keterlacakan ID, dilewati tanpa base).
