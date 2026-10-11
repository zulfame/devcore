# Riwayat Keputusan devcore

Ringkasan singkat bagaimana kerangka ini terbentuk, apa yang dicabut, dan apa yang dipelajari. Rincian lengkap ada di riwayat git (commit `docs/briefs/0001`–`0006`).

## Tujuan
Standar untuk membangun sistem bersama agent AI (terbatas pada proyek, bukan server/OS) dan aturan kerja agent yang **benar-benar dipatuhi**, bukan hanya ditulis. Diterapkan lewat bentuk yang dikenali Claude Code: `CLAUDE.md`, skill, subagent, dan hook.

## Yang dibangun, berurutan
| # | Isi | Keputusan | Batas yang diketahui |
|---|---|---|---|
| 1 | Gerbang brief (AG-15), CI pemeriksa | Kode hanya boleh diubah bila ada brief `approved` (tujuan, kriteria yang dapat diuji, di luar lingkup); `approved` meminta konfirmasi pengguna | Gerbang hanya memeriksa keberadaan dan keterisian, bukan kualitas; brief `approved` yang basi membuka gerbang untuk tugas lain |
| 2 | Pemasangan di proyek lain, serah terima sesi, panduan adopsi | `CLAUDE.md` proyek hanya ditambah satu baris impor; status sesi dimuat otomatis di awal sesi; proyek lama: baseline, bukan refactor | Aturan di `status.md` tidak dipaksa mesin |
| 3 | Subagent peninjau independen (AG-19) | Agent tidak menilai pekerjaannya sendiri | Tidak ada yang memaksa pemanggilannya |
| 4 | Penjaga bash berbasis analisis struktur perintah | Keputusan dari argumen perintah, bukan teks mentah: celah bypass tertutup dan teks di pesan commit/heredoc tidak lagi memblokir | Pagar pengaman, bukan sandbox: skrip dari berkas dan variabel tak terselesaikan tidak terjangkau |
| 5 | Contoh salah→benar pada aturan kritis | Ringkasan aturan inti punya satu tempat; Definition of Done satu rumah di skill `verify-done` | Dampak contoh pada kepatuhan tidak pernah diukur |

## Yang dicabut, dan mengapa
- **Perangkat evaluasi kepatuhan agent** (9 skenario, runner, penilai): menjalankannya memakai jatah akun pemakai dan di luar inti proyek. Dicabut atas permintaan pengguna.
- **Generator aturan inti, pemeriksa rujukan, dan tabel sumber di standar**: pengukuran menunjukkan nol salinan persis dan nol ID menggantung; mesinnya lebih besar daripada masalahnya. Ringkasan kini ditulis langsung di aturan inti.
- **Enam brief lama dan CHANGELOG yang panjang**: dilebur ke berkas ini.

## Yang dipelajari
1. **Ukur sebelum mengklaim.** Klaim "empat salinan aturan" ternyata berlebihan (nol salinan persis); ukuran penganalisis bash yang saya sebut ±700 baris sebenarnya ±1.000.
2. **Ulasan multi-peran adalah bahan pertimbangan, bukan mandat membangun.** Setiap temuan ulasan sempat menjadi satu mesin; mesin penunjang tumbuh sekitar 4× lebih besar daripada isi kerangka (±3.050 baris mesin vs ±800 baris isi). Itu penyebab pemangkasan ini.
3. **Tes dan penjaga menangkap cacatnya sendiri**: pemeriksa baru memindai fixture tesnya sendiri; hook memblokir skrip yang menyebut `rm -rf`; guard menolak nilai rahasia palsu di data uji. Ini bukti penjaga bekerja, sekaligus sumber false positive yang perlu dikelola.
4. **Tidak ada pengukuran kepatuhan otomatis** (sengaja). Efektivitas diamati dari pemakaian nyata dan satu uji buta independen; selebihnya dugaan.
