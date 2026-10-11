# Brief: Memperkuat penjaga bash dan menutup false positive

Status: done
Tanggal: 2026-10-11
Jenis: lengkap

## Tujuan (wajib)
Mengganti pencocokan regex atas teks mentah pada `pretool-bash-guard.sh` dengan analisis terstruktur atas perintah shell, sehingga celah yang terbukti pada uji (8 perintah destruktif/rahasia yang lolos) tertutup dan false positive (teks di pesan commit, isi heredoc, pola grep) hilang. Berasal dari tinjauan Security Engineer dan temuan selama prioritas 3–4 (prioritas 5).

## Kriteria penerimaan (wajib)
- [ ] `.claude/hooks/lib/bash-analyzer.py` menokenisasi perintah shell (kutip, escape, operator, substitusi `$(...)`/backtick/`<(...)`, heredoc, here-string) dan memutuskan `block`, `ask`, atau `allow` dari argv per perintah sederhana, termasuk membuka pembungkus: `bash/sh -c`, `eval`, `env`, `nohup`, `time`, `timeout`, `command`, `xargs`, `find -exec`, dan isi heredoc yang dialirkan ke shell.
- [ ] Delapan celah yang ditemukan di prioritas 4 kini terblokir, masing-masing dengan tes: `bash -c 'rm -rf …'`, `sh -c "…"`, `python3 -c "…rmtree…"`, `find … -delete`, `git push origin +main`, `git push origin :main`, menulis kunci AWS lewat `echo … > file`, `mv .git …`, dan `echo $(cat .env)`.
- [ ] Tiga false positive hilang, masing-masing dengan tes: kata `rm -rf` di pesan `git commit -m`, di isi heredoc teks, dan di pola `grep`; perintah legal umum (`ls`, `git status/diff/log`, `npm test`, `python3 -m unittest`, `cat README.md`, `ls .env`, `grep -r ".env" src`) tetap lolos.
- [ ] Perintah shell yang menulis berkas (redirect `>` `>>`, `tee`, `cp`/`mv`/`install`, `sed -i`, `dd of=`, `truncate`) diperiksa dengan kebijakan yang sama dengan tool Write/Edit: gerbang brief (AG-15), berkas secret dan lockfile, berkas aturan mesin (`.claude/settings.json`, `.claude/hooks/*`, `.claude/devcore.conf`) meminta konfirmasi, dan konten dipindai untuk pola secret. Persetujuan brief lewat shell (`Status: approved`) juga meminta konfirmasi.
- [ ] Aturan baru yang terblokir: `sudo`/`su`/`doas` dan perintah administrasi OS (OS-01), dump environment (`env`/`printenv` tanpa argumen), penulisan ulang riwayat (`filter-branch`, `filter-repo`, `reflog expire`, `gc --prune`), `git stash drop|clear`, `git restore`/`checkout --` yang membuang perubahan, `git rm -r`, hapus branch remote, dekode-lalu-eksekusi (`base64 -d | sh`), dan varian `curl|sh` (pipa, `<(curl …)`, `$(curl …)`). One-liner interpreter yang memakai `subprocess`/`os.system` meminta konfirmasi.
- [ ] `pretool-write-guard.sh` dan penganalisis memakai satu berkas pola secret bersama (`.claude/hooks/lib/secret-patterns.txt`). Nilai yang mirip rahasia di berkas uji/fixture (`tests/`, `fixtures/`, `evals/`, `*.test.*`, dst.) memicu `ask`, bukan blokir; pola kuat (kunci AWS, private key, token) tetap diblokir di mana pun.
- [ ] Fallback aman: bila `python3` tidak ada, atau analisis gagal/tidak dapat memparse, penjaga regex lama dipakai (bukan allow); ada tesnya.
- [ ] Batas yang tersisa dicatat jujur di peta penegakan; tidak ada klaim sandbox.
- [ ] Minimal 120 kasus tes baru di `test-hooks.sh` (blokir, lolos, ask, false positive, fallback); semua suite lulus; CI hijau; instalasi nyata dari GitHub berhasil; `VERSION` 0.3.0 dan CHANGELOG.

## Di luar ruang lingkup (wajib)
- Sandbox tingkat OS (fitur sandbox Claude Code) dan Windows/PowerShell.
- Menganalisis isi skrip yang dijalankan dari berkas (`python3 script.py`, `./build.sh`).
- Pengurangan duplikasi aturan dan contoh benar/salah (prioritas 6); pilot evaluasi.
- Mengubah izin `permissions.deny/ask` di `settings.json` kecuali bila perlu untuk konsistensi.

## Konteks dan batasan (lengkap)
- Bukti celah: 14 kasus uji prioritas 4 (9 lolos yang seharusnya terblokir/diperiksa, 1 false positive, 1 inkonsisten).
- Penganalisis ditulis dengan Python 3 stdlib saja, sintaks kompatibel 3.6+, berjalan di macOS dan Linux CI.
- Penjaga ini adalah pagar pengaman, bukan sandbox: agent gigih tetap dapat melewatinya dengan skrip dari berkas, variabel yang tidak terselesaikan, atau obfuscation lain.
- Hanya satu penjaga bash yang tertulis di `settings.json`; `pretool-write-guard.sh` dan `pretool-brief-gate.sh` dipanggil penganalisis sebagai subproses dengan JSON sintetis agar kebijakan tidak terduplikasi.
- Perubahan di `.claude/hooks/` melewati persetujuan pengguna.

## Contoh input dan output (lengkap)
- `bash -c 'rm -rf build'` → `block` AG-06 "rm rekursif".
- `git commit -m "docs: jelaskan mengapa rm -rf diblokir"` → `allow`.
- `cat > notes.md <<'EOF'` … `rm -rf /` … `EOF` → `allow` (teks yang ditulis ke dokumen).
- `echo "k=AKIA…" > a.js` → `block` SC-07 (konten ditolak penjaga tulis).
- `sed -i 's/x/y/' .claude/hooks/pretool-bash-guard.sh` → `ask` (mengubah aturan mesin).

## Risiko dan asumsi (lengkap)
- Penganalisis menjadi komponen kritis dan kompleks; bug dapat memblokir pekerjaan sah. Mitigasi: banyak tes allow/block, `ask` untuk kasus ambigu, fallback ke penjaga lama saat gagal.
- Ketergantungan baru pada `python3` untuk hook. Mitigasi: fallback; didokumentasikan sebagai prasyarat.
- Tokenisasi shell bukan parser penuh (mis. fungsi shell, alias, variabel, `cd` dinamis). Ketidakpastian ditangani dengan `allow` (variabel tak terselesaikan) atau `ask` (eval dinamis) dan dicatat sebagai batas.
- Asumsi: "lanjut prioritas 5" berarti menyetujui lingkup prioritas 5 di atas.

## Pertanyaan terbuka
Tidak ada.

## Catatan penyelesaian
Bukti per kriteria (2026-10-11):
- Penganalisis `lib/bash-analyzer.py`: tokenizer shell sendiri (kutip, escape, operator, `$(…)`, backtick, `<(…)`, heredoc, here-string, komentar), pembungkus (`bash/sh -c`, `eval`, `env`, `nohup`, `time`, `timeout`, `nice`, `command`, `xargs`, `find -exec`, heredoc/here-string/pipa-echo ke shell), keputusan dari argv. `shlex` bawaan Python diuji lebih dulu dan terbukti tidak cukup (baris baru dianggap spasi, isi heredoc dianggap perintah). Terpenuhi.
- Delapan celah prioritas 4 tertutup, masing-masing dengan kasus uji; jalur pemindai secret terbukti tersendiri (SC-07/DP-01 dari penjaga tulis pada kasus `@brief`, bukan kebetulan dari gerbang brief). Terpenuhi.
- Tiga false positive hilang (pesan commit, heredoc teks, pola grep) plus ±60 perintah sehari-hari tetap lolos. Terpenuhi.
- Penulisan berkas lewat shell memakai kebijakan Write/Edit (gerbang brief, secret, lockfile, aturan mesin → ask, persetujuan brief → ask). Terpenuhi.
- Aturan baru (OS-01, dump environment, riwayat, stash, restore/checkout, `git rm -r`, ref remote, dekode-eksekusi, varian `curl|sh`, ask untuk one-liner exec): terpenuhi.
- Fallback: python3 hilang → regex lama (6 kasus tanpa python, termasuk false positive yang dicatat sebagai perilaku terdegradasi); perintah tak dapat diparse → regex lama (2 kasus). Terpenuhi.
- `test-hooks.sh`: 55 → **309** kasus (254 baru), `bash-guard-cases.tsv` ±250 baris. Uji mutasi (mematikan deteksi force push; mematikan penelusuran `bash -c`): masing-masing 5 kegagalan, jadi tertangkap. Suite lain: skrip 34, sinkronisasi 79, evaluasi 86; penamaan dan tautan OK; `run-checks.sh` ±72 detik lokal. Terpenuhi.
- Batas yang tersisa dicatat jujur di peta penegakan ("Batas yang jujur"). Terpenuhi.
- CI hijau, instalasi nyata dari GitHub, VERSION 0.3.0 + CHANGELOG: lihat bagian akhir (diisi setelah push).

Temuan selama pengerjaan:
- **Celah lama pada pola `assign`**: gaya JSON `"api_key": "nilai"` tidak terdeteksi karena kutip penutup sebelum titik dua; diperbaiki dan diuji (JSON dan YAML).
- **`NotebookEdit` tidak dijaga**: mengedit `.ipynb` melewati gerbang brief dan pemindai secret; matcher dan skrip diperbaiki, diuji.
- **Hook terpasang dua kali** pada proyek yang sudah terinstal bila matcher berubah antar versi; `sync-devcore.sh` kini memindahkan hook milik kerangka ke grup bermatcher yang benar, diuji idempoten.
- **Nama perintah dinamis** (`$X -rf y`, `$(echo rm) …`) tidak terbaca; kini `ask`.
- **Kode di heredoc yang dialirkan ke interpreter** (`python3 - <<EOF`) belum diperiksa; kini dipindai.
- Pola `npm_`, `sk_live_`, `glpat-` ditambahkan; data uji sendiri sempat ditangkap guard (bukti guard bekerja).

Penyimpangan dari brief:
- Pola secret **tidak dibaca langsung oleh penganalisis**; penganalisis mendelegasikan penulisan ke `pretool-write-guard.sh` dan `pretool-brief-gate.sh` sehingga kebijakan punya satu sumber. Berkas pola dipakai penjaga tulis. Tujuan kriteria (satu sumber) tercapai dengan cara yang lebih sederhana.
- Ditambah di luar brief: perlindungan `NotebookEdit`, nama perintah dinamis, normalisasi matcher di `sync-devcore.sh`.

Tindak lanjut:
- Penjaga ini belum diuji pada penggunaan nyata yang luas; false positive pada perintah sah yang tidak terpikirkan masih mungkin. Bila ada yang terblokir keliru, laporkan perintahnya: tambahkan ke `bash-guard-cases.tsv` sebagai kasus `allow`.
- Prioritas 6 (duplikasi aturan) dan pilot evaluasi (menunggu login CLI) masih terbuka.
