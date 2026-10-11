# Status Proyek

Diperbarui: 2026-10-11 oleh agent

## Fokus saat ini
Audit final selesai dan ter-merge (v0.7.0 bertag; laporan `docs/audit-final.md`). Kerangka dibekukan: perbaikan hanya dari temuan pemakaian nyata.
Terakhir: panduan pemasangan di README ditulis ulang linear (brief 0019, 0.7.1) karena pengguna bingung dengan urutan dan istilah `BRIEF_GATE`.
Berikutnya: pengguna menguji pemasangan di proyek nyata (folder Laravel uji) dengan prompt 1 dan 2 di README.

## Keadaan kerangka
- Versi terpasang: lihat `.devcore/VERSION`; riwayat perubahan di `CHANGELOG.md`; latar belakang di `docs/history.md`.
- Terbukti (dijalankan): tes hook, tes skrip, tes sync, `run-checks.sh`, CI, pemasangan baru/existing/starter kit/pembaruan.
- Terbukti juga: tiga putaran uji buta dan satu tinjauan independen (`docs/blind-test/results.md`, `docs/audit-final.md`).
- Belum terbukti: efektivitas jangka panjang, agent yang lebih lemah atau nekat, Grafana dan HTML statis.
- Batas yang diterima: lihat bagian "Batas yang jujur" di `.devcore/docs/enforcement-map.md`.

## Keputusan penting
- Penegakan berlapis: `docs/adr/0001-layered-enforcement.md`.
- Ringkasan aturan inti hanya di `.devcore/rules.md`; aturan lengkap ber-ID di `.devcore/docs/engineering-standard.md`.
- Bila bertabrakan dengan proyek: keamanan tak dapat diubah; aturan proses boleh disimpangi lewat `CLAUDE.md`; gaya kode milik proyek.
- Alur repo ini: branch `kerja/<topik>` + brief + PR; `main` hanya berisi yang lolos pemeriksaan dan CI. Tag dibuat pengguna.
- Pagar anti-melebar: tidak ada mekanisme baru tanpa pelanggaran nyata teramati.

## Backlog (belum dikerjakan; jangan dibangun tanpa temuan nyata)
- Penegakan bahasa nama berkas (daftar kata terlarang kecil, bisa dikecualikan di `CLAUDE.md`).
- Uji fixture Grafana dan HTML statis.
- Pemakaian nyata di satu proyek asli selama 2-3 minggu; catat pelanggaran dan false positive.
- Batas yang dicatat di audit tetapi tidak diperbaiki: lihat `docs/audit-final.md` bagian "Diterima".

## Catatan jebakan
- Penjaga bash membaca struktur perintah: teks `rm -rf` di pesan commit lolos, `rm -r` sungguhan diblokir.
- Skrip interpreter yang menyebut `rmtree` atau berkas rahasia dalam string ikut terblokir; tulis skrip dengan tool Write/Edit.
- Perubahan di `.devcore/`, `.claude/settings*.json`, `.claude/skills|agents/`, `CLAUDE.local.md` meminta konfirmasi pengguna.
- Nilai mirip rahasia di berkas ditolak/dikonfirmasi; rakit nilai palsu lewat variabel di skrip uji.
- Skrip tes mencatat folder sementara ke berkas, bukan array (subshell). Skrip yang menimpa foldernya sendiri dibungkus fungsi `main`.
- `managed-claude.txt` = daftar sumber; kepemilikan di proyek = `owned-claude.txt`.
- Jangan ubah isi rubrik terkunci di `docs/blind-test/` (cek `hashes.sha256`).
- `.gitignore` proyek yang mengabaikan `/.claude` atau `/CLAUDE.md` membuat berkas devcore tidak ter-commit (sync memberi INFO).
- Perintah hook di `settings.json` harus mengutip `"$CLAUDE_PROJECT_DIR"` agar jalur berspasi tidak membuat hook mati diam-diam.

- 0.7.2: tes dibuat kedap terhadap konfigurasi git global pengguna (penandatanganan commit dapat membuat tes menggantung); run-checks menampilkan progres langsung.
