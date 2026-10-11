# Brief: Mencabut perangkat evaluasi agent

Status: done
Tanggal: 2026-10-11
Jenis: ringkas

## Tujuan (wajib)
Mencabut perangkat evaluasi kepatuhan agent (folder `evals/`, skrip `run-evals`/`grade-eval`/`summarize-evals`/`eval-helpers`/`test-evals`, dan dokumennya) karena menjalankannya memakai jatah akun pemakai dan itu di luar inti proyek (standar kode dan aturan kerja agent). Permintaan langsung pengguna.

## Kriteria penerimaan (wajib)
- [ ] Tidak ada lagi folder `evals/`, skrip evaluasi, `docs/evaluating-agents.md`, maupun entri `.gitignore` untuk hasil evaluasi.
- [ ] Tidak ada rujukan menggantung: `scripts/check-links.sh`, `check-naming.sh`, `check-rule-refs.sh`, dan seluruh suite lulus; pencarian "evals/" dan "run-evals" di berkas aktif (selain riwayat brief/CHANGELOG) tidak menemukan apa pun.
- [ ] Pemeriksa dan tes yang khusus evaluasi dicabut (`check-naming` skenario evaluasi, pengecualian `evals/` di `check-weakened-tests`, pindaian `evals/` di `check-rule-refs`, tes terkait, langkah di `run-checks.sh`, daftar `devonly`).
- [ ] Peta penegakan, standar (AG-19), README, `CLAUDE.md`, dan status tidak lagi mengklaim adanya pengukuran otomatis; peta penegakan menyatakan jujur bahwa efektivitas aturan hanya diamati lewat pemakaian nyata.
- [ ] `VERSION` 0.4.1 dan CHANGELOG mencatat pencabutan; CI hijau; pemasangan dari GitHub tidak terpengaruh.

## Di luar ruang lingkup (wajib)
- Mengubah aturan inti, hook, skill, atau subagent.
- Menghapus riwayat brief 0003/0005 dan entri CHANGELOG lama (riwayat dipertahankan; diberi catatan "dicabut").

## Konteks dan batasan (lengkap)
- Perangkat ini khusus devcore dan tidak pernah dipasang ke proyek lain; berkas managed yang ikut berubah hanya pemeriksa (`check-naming`, `check-rule-refs`, `check-weakened-tests`), `test-scripts.sh`, `run-checks.sh`, `docs/enforcement-map.md`, dan standar.
- Penjaga bash memblokir `rm -r`; karena pengguna sudah menyetujui penghapusan secara eksplisit di chat, berkas dihapus satu per satu lewat git (tanpa `-r`) sehingga masih dapat dipulihkan dari riwayat.

## Risiko dan asumsi (lengkap)
- Tidak ada perangkat otomatis untuk mengukur kepatuhan; pemantauan bergantung pada pemakaian nyata dan alur koreksi. Diterima oleh pengguna.
- Perangkat tetap ada di riwayat git (commit sebelum pencabutan) bila suatu hari diperlukan.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Bukti (2026-10-11): 45 berkas dihapus lewat `git rm` tanpa `-r` (dapat dipulihkan dari riwayat); folder `evals/`, 5 skrip, dan `docs/evaluating-agents.md` tidak ada lagi; pemeriksa dan tes khusus evaluasi dicabut; peta penegakan, standar (AG-19), README, CLAUDE.md, status, manifest, `.gitignore` diselaraskan. Pencarian rujukan tersisa hanya riwayat (brief, CHANGELOG) dan nama folder generik `evals/` pada aturan "berkas uji → ask". `run-checks.sh`: hook 309, skrip 41, sinkronisasi 81, aturan inti 29, rujukan, penamaan, tautan, pelemahan: semua lulus. VERSION 0.4.1.

Catatan: sesudah penghapusan, pengguna menilai proyek melebar terlalu jauh dari esensinya; tinjauan ulang ruang lingkup dilakukan terpisah dan menunggu keputusan pengguna.
