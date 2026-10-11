# Brief: Satu sumber untuk aturan inti dan contoh salah→benar

Status: done
Tanggal: 2026-10-11
Jenis: lengkap

## Tujuan (wajib)
Mencegah aturan inti yang dibaca agent melenceng dari standar karena disalin dan diubah terpisah, dan membuat aturan yang paling sering dilanggar lebih mudah dipatuhi lewat contoh konkret salah→benar. Berasal dari tinjauan Technical Writer dan AI/Agent Engineer (prioritas 6).

## Kriteria penerimaan (wajib)
- [ ] Hasil pengukuran duplikasi dicatat di brief ini (salinan persis, parafrase, ID menggantung) dan keputusan mengikuti data, bukan asumsi.
- [ ] Standar memuat tabel **Aturan Inti untuk Agent** sebagai satu-satunya sumber ringkasan: ID, judul, ringkasan, penanda kritis, contoh salah, contoh benar.
- [ ] `scripts/build-rules.sh` membangun daftar aturan inti dan blok pengingat di `.claude/devcore-rules.md` dari tabel itu; `--check` gagal bila hasil bangun basi; ditambahkan ke `run-checks.sh` dan CI.
- [ ] Hook `prompt-rules-reminder.sh` tidak lagi memuat teks aturan sendiri: ia membaca blok pengingat dari `.claude/devcore-rules.md`.
- [ ] `scripts/check-rule-refs.sh` (dipasang ke proyek) gagal bila ada ID aturan yang dirujuk tetapi tidak terdefinisi di standar, atau bila berkas yang selalu dimuat melewati batas ukuran (`devcore-rules.md`, `CLAUDE.md`, blok pengingat); melaporkan ID tak pernah dirujuk sebagai informasi.
- [ ] Definition of Done punya satu rumah kanonik (skill `verify-done`); Bagian 3 standar menunjuk ke sana tanpa menyalin daftarnya.
- [ ] Contoh salah→benar: pada aturan inti kritis (di konteks yang selalu dimuat), serta di skill `write-brief` (kriteria buruk/baik), `verify-done` (laporan jujur vs menyesatkan), `change-function` (ruang lingkup dan sinkronisasi kontrak), `check-security` (pasangan kode tidak aman/aman), dan `profile-project` (contoh temuan utang teknis). Contoh sengaja berbeda dari skenario evaluasi, dan risiko kontaminasi dicatat di `docs/evaluating-agents.md`.
- [ ] Tes untuk generator, pengingat turunan, dan pemeriksa rujukan (kasus lulus dan gagal, termasuk uji mutasi); semua suite lulus; CI hijau; instalasi nyata dari GitHub berhasil; `VERSION` 0.4.0 dan CHANGELOG.

## Di luar ruang lingkup (wajib)
- Mengukur dampak perilaku dari contoh dan penyederhanaan (butuh pilot evaluasi yang menunggu login CLI).
- Merombak 20 bagian standar atau menghapus aturan; deduplikasi berbasis LLM.
- Mengubah gerbang, penjaga, atau sinkronisasi di luar yang dibutuhkan untuk pembangunan aturan.

## Konteks dan batasan (lengkap)
- `.claude/devcore-rules.md` dimuat ke setiap sesi (via impor `CLAUDE.md`); dokumentasi Claude Code menyarankan di bawah 200 baris per berkas dan menyebut berkas yang lebih panjang menurunkan kepatuhan.
- Berkas yang dipasang ke proyek lain tidak boleh bergantung pada alat devcore-only; generator `build-rules.sh` khusus devcore, `check-rule-refs.sh` dipasang.
- Tabel standar dibaca manusia; hasil bangun dibaca agent.

## Contoh input dan output (lengkap)
- Mengubah ringkasan `AG-05` di tabel standar lalu menjalankan `scripts/run-checks.sh` tanpa membangun ulang → gagal dengan pesan "devcore-rules.md basi; jalankan scripts/build-rules.sh".
- Menulis `AG-99` di skill → `check-rule-refs.sh` gagal "AG-99 dirujuk tetapi tidak terdefinisi".

## Risiko dan asumsi (lengkap)
- Generator menambah satu langkah kerja bagi pemelihara; mitigasi: `--check` di CI memberi pesan jelas.
- Contoh yang mirip skenario evaluasi akan menggelembungkan hasil pilot ("mengajar untuk tes"). Mitigasi: contoh sengaja berbeda domain dan nilai, serta catatan di dokumen evaluasi; skenario cadangan (holdout) dianjurkan sebelum pilot.
- Menambah contoh memperpanjang konteks yang selalu dimuat; batas ukuran ditegakkan oleh `check-rule-refs.sh`.
- Asumsi: "lanjut prioritas 6" berarti menyetujui lingkup di atas.

## Pengukuran duplikasi (2026-10-11, sebelum perubahan)
- Klausa ≥70 karakter yang persis sama di ≥2 berkas: **0**. ID aturan yang dirujuk tetapi tidak terdefinisi: **0** dari 135 terdefinisi.
- Kemiripan makna (Jaccard ≥ 0,30 terhadap butir standar): `devcore-rules.md` 8 dari 53 baris; `check-security` 10 baris (daftar periksa yang memang merujuk ID); `prompt-rules-reminder.sh`, `write-brief`, `review-changes` 0.
- Kesimpulan: klaim awal "empat salinan" berlebihan. Risiko nyata = parafrase aturan inti (rules↔standar), blok pengingat, dan daftar DoD. Keputusan: satu sumber untuk aturan inti + pengingat; DoD kanonik di skill; checklist keamanan tetap (fungsinya memang merujuk ID) dengan penjaga rujukan.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Bukti per kriteria (2026-10-11):
- Pengukuran duplikasi: dicatat di atas (0 salinan persis, 0 ID menggantung, parafrase sebagai risiko nyata). Terpenuhi.
- Tabel **Aturan Inti untuk Agent** di standar: 16 aturan (naik dari 15: `AG-14` ditambahkan), 8 kritis, kolom ID/Judul/Ringkasan/Kritis/Salah/Benar. Terpenuhi.
- `scripts/build-rules.sh`: membangun daftar inti di `devcore-rules.md` dan `devcore-reminder.txt`; `--check` gagal (exit 1) bila basi; validasi (ID tak terdefinisi, kritis tanpa contoh, nilai Kritis tidak valid, penanda hilang → exit 2); idempoten; tidak menyentuh bagian di luar penanda. Dipasang di `run-checks.sh` (dan karena itu CI). Terpenuhi.
- Hook pengingat: 0 teks aturan sendiri, membaca `devcore-reminder.txt`; terbukti mengikuti isi berkas (tes dengan isi kustom) dan diam bila berkas tak ada. Terpenuhi.
- `scripts/check-rule-refs.sh` (dipasang ke proyek): rujukan menggantung, batas ukuran (110/200/15 baris), kesegaran build (di devcore), info ID tak dirujuk (53 dari 135 dirujuk di luar standar). Terpenuhi.
- DoD: Bagian 3 standar kini menunjuk ke `verify-done` (7 butir checklist di standar → 0; 8 butir kanonik di skill). Terpenuhi.
- Contoh salah→benar: 8 aturan kritis di konteks selalu-dimuat (dan 16 pasang di tabel standar), plus `write-brief`, `verify-done`, `change-function`, `check-security`, `profile-project`. Domain/nilai dibedakan dari skenario evaluasi; risiko kontaminasi dicatat di `docs/evaluating-agents.md`. Terpenuhi.
- Tes: `test-rules.sh` 29 (termasuk uji mutasi: generator dirusak → tertangkap), `test-scripts.sh` 34 → 43, `test-sync.sh` 79 → 82; hook 309, evaluasi 86; `run-checks.sh` ±70 detik. CI dan instalasi nyata: lihat akhir.

Perbandingan sebelum → sesudah (terukur):
- `devcore-rules.md` 54 → 72 baris (+18 untuk 8 pasang contoh; batas 110 ditegakkan mesin).
- Teks aturan di hook pengingat: 6 baris tulisan tangan → 0 (diturunkan).
- Daftar DoD di standar: 7 butir → 0 (satu rumah di skill).
- Aturan inti yang ditulis tangan di dua tempat: 15 → 0 (tabel di standar adalah sumbernya).

Temuan selama pengerjaan:
- Klaim saya di tinjauan awal ("empat salinan aturan") **berlebihan**: pengukuran menunjukkan nol klausa persis sama. Rancangan diubah mengikuti data: bukan menghapus ringkasan, melainkan satu sumber + penjaga.
- `check-rule-refs.sh` langsung menangkap cacat rancangannya sendiri pada run pertama: ia memindai skrip tes yang sengaja memuat ID palsu. Skrip `test-*.sh` kini dikecualikan; tes sinkronisasi di proyek terpasang ikut gagal karena hal yang sama sebelum diperbaiki.
- Pemindaian dibatasi ke berkas kerangka agar nomor tiket milik proyek (mis. `CI-12`) tidak memicu galat palsu di proyek lain.

Penyimpangan dari brief: `AG-14` (gagal berulang → berhenti) ditambahkan ke aturan inti, yang sebelumnya hanya ada di standar. Checklist `check-security` tidak dihapus: fungsinya memang merujuk ID, dijaga oleh pemeriksa rujukan, bukan dihilangkan.

Batas yang jujur:
- Penjaga ini menjaga **keselarasan** (teks inti selalu berasal dari tabel; ID yang dirujuk ada; ukuran terkendali), bukan **ketaatan** agent. Apakah contoh benar-benar meningkatkan kepatuhan **belum diukur** dan baru bisa diukur lewat pilot evaluasi (menunggu login CLI), idealnya dengan skenario cadangan.
- Ringkasan yang ditulis tangan di skill (checklist keamanan, dsb.) masih bisa melenceng maknanya dari standar; hanya ID-nya yang dijaga.
- 82 dari 135 ID aturan tidak dirujuk di luar standar; aturan tersebut hanya hidup sebagai teks.

Tindak lanjut: pilot evaluasi + skenario cadangan; bila pilot menunjukkan contoh tidak membantu atau malah membingungkan, tabel tinggal diubah dan dibangun ulang.
