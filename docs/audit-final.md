# Audit final (brief 0018)

Cakupan: tes mekanis, silang dokumen↔kode (DC-06), pemasangan segar dan pembaruan dari GitHub, serta tinjauan independen oleh subagent berkonteks bersih terhadap v0.6.7. Setiap temuan peninjau saya verifikasi sendiri sebelum diperbaiki; bukti "sebelum" diambil dari hook versi lama (HEAD) atau pemeriksaan langsung. Perbaikan dirilis sebagai 0.7.0.

## Hasil pemeriksaan mekanis
Semua lulus sebelum perbaikan: 305 tes hook, 34 tes skrip, 83 tes sync, `run-checks.sh`, sintaks bash 3.2 dan Python. Pemasangan segar dan pembaruan 0.6.0 → 0.6.7 dari GitHub mulus (tanpa hook ganda). Setelah perbaikan: 341 tes hook, 38 tes skrip, 84 tes sync.

## Diperbaiki (terbukti, dengan tes baru)
| # | Temuan | Bukti sebelum | Perbaikan |
|---|---|---|---|
| 1 | Semua hook mati diam-diam bila jalur proyek berspasi | perintah hook tanpa kutip → exit 127 (fail-open); dengan kutip → jalan | perintah hook di `settings.json` memakai `"$CLAUDE_PROJECT_DIR"/…`; sync mengenali bentuk lama dan baru; tes jalur berspasi |
| 2 | Gerbang brief dilewati dengan `docs/../src/app.py` atau jalur relatif | exit 0 tanpa brief | normalisasi jalur di gerbang dan penjaga tulis |
| 3 | Persetujuan brief lewat Edit parsial (`draft`→`approved`) tanpa konfirmasi | exit 0 | `new_string` yang hanya berisi `approved` kini meminta konfirmasi |
| 4 | `settings.local.json`, skill, subagent, `CLAUDE.local.md` tidak dijaga walau dokumen mengklaimnya | penjaga tulis exit 0 | keempatnya meminta konfirmasi; `CLAUDE.md` biasa tetap bebas |
| 5 | Klaim "dilarang… diblokir hook" untuk git tidak sesuai kode | `git switch -f`, `worktree remove --force` lolos | keduanya diblokir; klaim di `rules.md` dipersempit sesuai kenyataan |
| 6 | False positive: URL `/credentials`, `secrets.json`, `.env.local.example` | diblokir AG-07 | argumen URL tidak dianggap jalur; semua varian `.env.*.example` lolos |
| 7 | Pesan commit berbentuk `$(cat <<'EOF' … EOF)` dengan satu apostrof diblokir salah | exit 2 pada hook lama | `scan_balanced` mengenali heredoc di dalam `$(…)` |
| 8 | `os.system("rm -rf …")`, `execSync`, brace expansion `{rm,-rf,x}` lolos | exit 0 | pola shell-out + `rm -r` dikenali; nama perintah berawalan `{` berkoma meminta konfirmasi |
| 9 | `git show HEAD:.env`, `export` tanpa argumen lolos | exit 0 | regex jalur menerima `:` sebagai pemisah; `export` kosong diblokir; `permissions.deny` Read diperluas (`.env.staging`, `.env.development`, `id_rsa`, `id_ed25519`, `~/.ssh`, `~/.aws`) |
| 10 | `curl -o`, `wget -O`, `patch`, `git apply` menulis kode tanpa melewati gerbang brief | exit 0 | dimasukkan ke target penulisan (patch/apply sebagai penulisan kode umum) |
| 11 | `sed -i -e "…" README.md` diblokir salah | skrip sed dianggap berkas | `positional` menghabiskan nilai `-e`/`-f` |
| 12 | `sync-devcore.sh` tidak memeriksa kegagalan `cp` sebelum menghapus yang lama | pembacaan kode | salin ke samping, ganti hanya bila berhasil; gagal → `die` dengan pemasangan lama utuh |
| 13 | `check-naming` menggagalkan CI proyek existing sejak hari pertama (`TODO.md`, `docs/API_v2.md`) | terbukti pada proyek uji | di proyek terpasang hanya yang dibuat kerangka diperiksa (AG-16); repo devcore tetap ketat; tes |
| 14 | Selisih dokumen: daftar peran baku DC-05, urutan "Melepas devcore" (daftar kepemilikan hilang bersama folder, workflow CI tersisa), `--ref` tanpa penjelasan, hook Stop tak ada di pohon README, komentar `managed-claude.txt` usang, DC-06/07 tak ada di peta, jumlah aturan (137), status.md usang | pembacaan dokumen vs kode | semua diselaraskan |
| 15 | `status.md` terpotong diam-diam saat dimuat (40 baris/200 karakter) | terbukti | pemuat menambahkan tanda terpotong; status.md diringkas; tes |
| 17 | OS-01 memblokir diagnosis hanya-baca (`systemctl status`, `crontab -l`, `nginx -t`) | exit 2 | daftar subperintah hanya-baca diizinkan |
| 19 | `check-links` menganggap tautan di dalam kode inline/blok dan `%20` sebagai tautan | false positive | kode dibuang sebelum ekstraksi; `%20` didekode; tes |
| 20 | `check-weakened-tests` mengecualikan `scripts/` milik proyek; "LULUS" walau pemeriksaan DILEWATI | pembacaan kode | `scripts/` dikecualikan hanya di repo devcore; `run-checks.sh` mencetak catatan bila ada pemeriksaan dilewati |
| D | Definisi "non-trivial" tidak konsisten dengan gerbang hook | dokumen vs hook | `rules.md` dan skill `write-brief` menyatakan: gerbang tidak menilai ukuran, tugas kecil cukup brief ringkas |

## Diterima (dicatat di peta penegakan "Batas yang jujur", tidak dibangun)
- Penghapusan yang dibungkus program lain (`ssh`, `docker run`, `rsync --delete`), `git -C … rebase`, `commit --amend`/`reset` non-hard/`tag -d`/`branch -d`, `/proc/*/environ`, `gh auth token`, `~/.docker/config.json`: pagar, bukan sandbox.
- Satu brief `approved` membuka gerbang untuk seluruh kode; berkas kode di `docs/` dikecualikan; AG-13 tanpa penjaga mesin.
- `.npmrc` dan `*.key` tetap diperlakukan sebagai berkas rahasia (lebih aman salah-blokir); terjemahan `*.key` dapat ditulis lewat konfirmasi.
- Pola placeholder pada deteksi secret berbasis substring dan tidak menangkap semua format (sudah tercatat).
- Hook Stop dapat mengingatkan berulang tiap giliran selama kode kotor dan status belum berubah (perilaku yang disengaja).
- Pemasangan menyalin berkas liar seperti `.DS_Store` dari sumber lokal; pembaruan tidak menghapus izin/skill yang dicabut dari versi kerangka (didokumentasikan sebagai "tanpa penghapusan").
- Ukuran konteks (aturan inti, pengingat per pesan, standar 328 baris): dipertahankan; belum ada bukti pelanggaran akibat ukuran.
- Perilaku runtime Claude Code (apakah exit 127 non-blocking, Grep/Glob terhadap `deny Read`): tidak diuji langsung.

## Tidak diperiksa
Windows/PowerShell, git worktree, pemasangan dari URL klon selain GitHub ini, kompatibilitas Python 3.6 dan bash di luar 3.2, skenario kegagalan sync yang disuntikkan (hanya dianalisis dari kode).
