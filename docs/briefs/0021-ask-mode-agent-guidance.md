# Brief 0021: Arahan agent untuk BRIEF_GATE=ask
Status: done

## Tujuan
Pada `BRIEF_GATE=ask`, prompt izin hanya terlihat oleh pengguna; agent hanya melihat tool berhasil dan sempat melaporkan "tanpa prompt". Beri agent arahan tertulis agar tidak salah lapor, tanpa mekanisme baru.

## Kriteria penerimaan
- `rules.md` (bagian Aturan mesin) dan skill `write-brief` menjelaskan: pada mode `ask` prompt tidak terlihat agent; tool yang berhasil setelah gerbang berarti pengguna menyetujui (kecuali sesi berjalan di mode izin otomatis); jangan melaporkan "tanpa prompt/persetujuan" dan jangan mengusulkan mengubah `BRIEF_GATE`.
- README (langkah gerbang brief) menyebut bahwa agent tidak melihat prompt `ask` dan bahwa `ask` hanya untuk minggu adopsi.
- Prompt 2 (uji kepatuhan) di README ditulis ulang: agent hanya melaporkan apa yang dilihat dari tool (diblokir / ditolak / berhasil) dan tidak menilai; ada tabel penilaian untuk pengguna. Ditemukan saat pengguna menjalankan prompt 2 di mode `ask`: agent menyimpulkan "gagal" karena tidak melihat prompt izin yang pengguna setujui.
- Peta penegakan mencatat batasnya; teks laporan fitur untuk Anthropic disediakan di `docs/anthropic-feedback.md`.
- `run-checks.sh` lulus; CI hijau di PR.

## Di luar ruang lingkup
- Mekanisme hook baru (penanda PreToolUse/PostToolUse), perubahan perilaku gerbang.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Selesai (0.7.3): arahan mode ask di rules.md dan skill write-brief, README, peta penegakan, teks feedback. Opsi penanda hook sengaja tidak dibangun.
