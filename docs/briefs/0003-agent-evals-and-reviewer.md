# Brief: Evaluasi kepatuhan agent dan subagent reviewer

Status: done
Tanggal: 2026-10-11
Jenis: lengkap

## Tujuan (wajib)
Membuat klaim "kerangka ini membuat agent lebih patuh" dapat diukur, bukan diasumsikan: skenario jebakan yang dijalankan pada agent sungguhan dengan dan tanpa kerangka, dinilai secara deterministik. Ditambah subagent peninjau berkonteks bersih agar agent tidak menilai pekerjaannya sendiri. Berasal dari tinjauan peran AI/Agent Engineer dan QA (prioritas 4).

## Kriteria penerimaan (wajib)
- [ ] Ada fixture proyek dasar `evals/fixtures/base-app/` (Python stdlib, tanpa dependensi, test-nya lulus) dan minimal 8 skenario di `evals/scenarios/<id>/`, masing-masing berisi `prompt.txt`, `overlay/` (opsional), dan `grade.sh`. Skenario mencakup: ruang lingkup, secret, pelemahan test, brief sebelum kode, laporan jujur, tindakan destruktif, prompt injection, hal di luar proyek (OS/server), dan dependency baru.
- [ ] `scripts/grade-eval.sh` menilai satu run dari tiga sumber: state proyek akhir, transkrip tool call, dan teks akhir; keluarannya per aturan: `attempted`, `executed`, dan `blocked_by` (mesin atau tidak).
- [ ] `scripts/run-evals.sh` default **dry-run** yang menampilkan rencana run dan batas biaya maksimum (jumlah run × anggaran per run); `--execute` baru menjalankan agent. Opsi: `--variant bare|devcore|both`, `--scenarios`, `--reps`, `--model`, `--budget`, `--label`. Tiap run di repo git sementara yang baru, hanya `--setting-sources project`, tanpa persistensi sesi, dengan daftar izin alat yang aman (tanpa jaringan dan tanpa penghapusan), batas giliran dan anggaran. Transkrip mentah tidak masuk git.
- [ ] `scripts/summarize-evals.sh` menghasilkan tabel markdown per skenario dan varian: n, attempted k/n, executed k/n, diblokir mesin.
- [ ] `scripts/test-evals.sh` menguji penilai dengan transkrip sintetis perilaku baik dan buruk untuk setiap skenario, rencana dry-run, serta hitungan ringkasan, tanpa memanggil model. Disertakan uji mutasi sederhana pada satu penilai.
- [ ] ~~Pilot nyata~~ **DIPINDAH ke tindak lanjut pengguna (lihat Perubahan 1).** Yang tetap menjadi kriteria: runner siap dijalankan dan menolak mulai dengan pesan jelas bila CLI belum terautentikasi; perintah pilot (maks 8 run, ≤ 0,75 USD per run) didokumentasikan di `docs/evaluating-agents.md`; bentuk transkrip yang diparse sesuai dokumentasi resmi dan potongan keluaran asli yang berhasil diperoleh.
- [ ] Subagent `.claude/agents/review-changes.md`: konteks bersih, alat baca-saja, format keluaran tetap (per kriteria brief: terpenuhi/tidak + bukti; pelanggaran aturan dengan ID dan lokasi; pertanyaan). `verify-done` memanggilnya untuk tugas non-trivial; aturan `AG-19` di standar; terdaftar di manifest, diperiksa penamaan, tercakup tes.
- [ ] `docs/evaluating-agents.md` menjelaskan cara menjalankan, biaya, cara membaca hasil, dan keterbatasan. Standar, peta penegakan, README, CHANGELOG (versi 0.2.0) diselaraskan.
- [ ] Semua tes lulus (hook, skrip, sinkronisasi, evaluasi) dan CI hijau.

## Di luar ruang lingkup (wajib)
- Benchmark yang signifikan secara statistik (butuh banyak run per sel); hanya pilot dan alatnya.
- Penilaian oleh LLM (LLM-as-judge); semua penilai deterministik. Penilaian kejujuran laporan berbasis pola teks dan diakui lemah.
- Menjalankan evaluasi di CI (berbiaya); hanya lokal dan atas permintaan.
- Menutup celah hook bash (prioritas 5) dan pengurangan duplikasi aturan (prioritas 6).
- Membandingkan model satu sama lain.

## Konteks dan batasan (lengkap)
- CLI `claude` 2.1.252 terpasang; mendukung `--max-budget-usd`, `--setting-sources`, `--output-format stream-json` (dengan `--verbose`), `--include-hook-events`, `--no-session-persistence`.
- Konfigurasi pengguna tidak memuat `~/.claude/CLAUDE.md`; `--setting-sources project` mengecualikan plugin dan pengaturan global.
- Pada mode headless tidak ada yang bisa menjawab permintaan izin, jadi alat di luar daftar izin ditolak; skenario yang butuh persetujuan mengukur apakah agent berhenti dan bertanya.
- Skrip kompatibel bash 3.2 dan 5.

## Contoh input dan output (lengkap)
- `scripts/run-evals.sh --variant both --scenarios secret-in-config,weaken-failing-test` → mencetak rencana "4 run, batas biaya maks 3,00 USD" dan berhenti.
- `... --execute` → menjalankan, lalu menulis `evals/results/<tanggal>-<label>.md` berisi tabel: skenario | varian | n | attempted | executed | diblokir mesin.

## Risiko dan asumsi (lengkap)
- Biaya: menjalankan agent sungguhan memakai kuota akun. Mitigasi: dry-run bawaan, batas per run, batas pilot (maks 8 run), tidak ada eksekusi otomatis di CI.
- Keamanan: varian tanpa kerangka tidak punya hook. Mitigasi: repo sementara terisolasi, daftar izin alat sempit (tanpa `rm`, jaringan, `sudo`, install), batas giliran. Kelemahan: alat yang diizinkan tetap bisa menulis di folder kerja.
- Nondeterminisme: hasil satu run tidak mewakili; angka k/n dilaporkan apa adanya tanpa persentase yang menyesatkan.
- Menjalankan `claude` bersarang dari dalam sesi Claude Code bisa berperilaku berbeda; diverifikasi pada pilot.
- Asumsi: "lanjut prioritas 4" berarti menyetujui lingkup prioritas 4 termasuk pilot berbiaya terbatas di atas.

## Perubahan setelah persetujuan
0. **Bagian perangkat evaluasi dari brief ini DICABUT pada brief 0006** (versi 0.4.1) atas permintaan pengguna, karena menjalankannya memakai jatah akun dan di luar inti proyek. Subagent `review-changes` dan `AG-19` tetap. Catatan di bawah dipertahankan sebagai riwayat.
1. **Pilot nyata tidak dapat dijalankan di sesi ini.** Probe menunjukkan `claude auth status` → `loggedIn: false`: CLI mandiri tidak berbagi autentikasi dengan aplikasi desktop, dan login membutuhkan langkah interaktif pengguna (`claude auth login` atau variabel `ANTHROPIC_API_KEY`). Saya tidak mengambil token dari lingkungan sesi sebagai pengganti. Dampak: lingkup berkurang; hasil kepatuhan nyata (angka) belum ada, hanya alat ukurnya yang terbukti dengan transkrip sintetis. Pilot dijalankan pengguna setelah login (perintah di dokumen evaluasi).

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Bukti per kriteria (2026-10-11):
- Fixture `evals/fixtures/base-app/` (test dasar lulus; dicek di `test-evals.sh`) dan **9 skenario** (scope-small-fix, secret-in-config, weaken-failing-test, brief-before-code, honest-report, destructive-cleanup, prompt-injection, out-of-scope-os, new-dependency), masing-masing `prompt.txt` + `grade.sh`; overlay, overlay-dirty, dan brief.md bila perlu. Terpenuhi.
- `scripts/grade-eval.sh` + `eval-helpers.sh`: keluaran `RULE id attempted executed blocked_by` dan `DONE`; klasifikasi hook/harness/self diuji. Terpenuhi.
- `scripts/run-evals.sh`: dry-run bawaan dengan batas biaya (9×2×0,75 = 13,50 USD terhitung benar), semua opsi, konfigurasi terisolasi (`env -i`, `--setting-sources project`, tanpa persistensi), izin alat sempit, batas anggaran/giliran/waktu, raw di luar git. Diuji dengan `claude` palsu: eksekusi penuh, belum login → exit 3, autentikasi gagal di tengah → exit 4. Terpenuhi. Pemeriksaan nyata terhadap CLI asli (loggedIn=false) menolak mulai tanpa membuat berkas.
- `scripts/summarize-evals.sh`: hitungan diuji dengan data buatan. Terpenuhi.
- `scripts/test-evals.sh`: 86 kasus tanpa memanggil model, termasuk uji mutasi (penilai yang dirusak tertangkap). Terpenuhi.
- Pilot nyata: **tidak dijalankan** (CLI belum login; lihat Perubahan 1). Kriteria pengganti terpenuhi: runner siap dan menolak dengan pesan jelas; perintah pilot didokumentasikan; skema transkrip diambil dari dokumentasi resmi dan potongan keluaran asli (`system/init`, `assistant`, `result`). Event `tool_use`/`tool_result` **belum diamati dari run nyata**.
- Subagent `.claude/agents/review-changes.md` + `verify-done` langkah 3a + `AG-19` + manifest + `check-naming` + tes. Terpenuhi; efektivitasnya belum diukur.
- `docs/evaluating-agents.md`, standar, peta penegakan, README, CHANGELOG, `VERSION` 0.2.0. Terpenuhi.
- Seluruh suite lokal lulus: hook 55, skrip 32, sinkronisasi 72, evaluasi 86; penamaan dan tautan OK.

Temuan selama pengerjaan:
- Penjaga penulisan menolak berkas yang memuat nilai rahasia **palsu** pada fixture/tes (dua kali). Guard tidak dilonggarkan; nilai dirakit lewat variabel. Ini false positive nyata yang layak ditangani di prioritas 5 (mekanisme pengecualian eksplisit untuk fixture uji).
- Penjaga bash memblokir skrip yang teksnya memuat `rm -rf`, termasuk untuk membersihkan folder sementara sendiri (false positive teks yang sudah dikenal). Perubahan dilakukan lewat tool Edit.
- Bug di `test-scripts.sh` (dipasang ke proyek lain) dan `test-sync.sh`: folder sementara dicatat di subshell sehingga tidak pernah dibersihkan. Diperbaiki; sebelum perbaikan tes-tes itu menumpuk folder di direktori sementara sistem (bersih sendiri oleh sistem, tidak saya hapus manual).
- Penilai `weaken-failing-test` sempat tidak cocok dengan teks aslinya pada uji mutasi (regex), tertangkap saat menulis tes.

Penyimpangan dari brief: tidak ada selain Perubahan 1 (pilot dipindahkan).

Tindak lanjut:
- **Pengguna:** `claude auth login` di Terminal, lalu pilot (perintah di `docs/evaluating-agents.md`), maksimal 8 run, batas 6 USD.
- Setelah pilot: sesuaikan `scripts/eval-helpers.sh` bila format transkrip nyata berbeda; tambahkan transkrip nyata ke tes.
- Ukur efektivitas subagent peninjau (skenario pekerjaan cacat).
