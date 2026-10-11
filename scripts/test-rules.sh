#!/usr/bin/env bash
# Tes untuk pembangun aturan inti (scripts/build-rules.sh) dan hook pengingat turunan. Khusus pengembangan devcore.
# Jalankan: scripts/test-rules.sh
set -u
here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/.." && pwd -P)
pass=0; fail=0
REG=$(mktemp)
cleanup() { while IFS= read -r d; do [ -n "$d" ] && rm -rf "$d"; done < "$REG"; rm -f "$REG"; }
trap cleanup EXIT
mktmp() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; printf '%s' "$d"; }
t() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); echo "GAGAL: $name"; fi; }
code_of() { "$@" >/dev/null 2>&1; echo $?; }

# Salinan kerja: standar, aturan, hook, dan generator
newroot() {
  local r; r=$(mktmp); mkdir -p "$r/docs" "$r/.claude/hooks" "$r/scripts"
  cp "$repo/docs/engineering-standard.md" "$r/docs/"
  cp "$repo/.claude/devcore-rules.md" "$r/.claude/"
  cp "$repo/.claude/devcore-reminder.txt" "$r/.claude/"
  cp "$repo/.claude/hooks/prompt-rules-reminder.sh" "$r/.claude/hooks/"
  cp "$repo/scripts/build-rules.sh" "$r/scripts/"
  printf '%s' "$r"
}
build() { # root [flag]
  local r=$1 flag=${2:-}
  if [ -n "$flag" ]; then "$r/scripts/build-rules.sh" "$flag" "$r" 2>&1; else "$r/scripts/build-rules.sh" "$r" 2>&1; fi
}
has() { printf '%s' "$1" | grep -qF -- "$2"; }

# ---------- repositori sebenarnya ----------
t "repo: hasil bangun segar (--check)"            "$here/build-rules.sh" --check
rows=$(awk '/<!-- inti:mulai -->/{f=1;next} /<!-- inti:selesai -->/{f=0} f && /^\| (AG|SC|OS|VL|CD)/' "$repo/docs/engineering-standard.md" | wc -l | tr -d ' ')
crit=$(awk '/<!-- inti:mulai -->/{f=1;next} /<!-- inti:selesai -->/{f=0} f && /^\| (AG|SC|OS|VL|CD)/' "$repo/docs/engineering-standard.md" | awk -F'|' '{gsub(/ /,"",$5); if ($5=="ya") n++} END{print n+0}')
t "repo: minimal 15 aturan inti dan 6 kritis"      test "$rows" -ge 15 -a "$crit" -ge 6
nsalah=$(grep -c '^   - Salah: ' "$repo/.claude/devcore-rules.md")
nbenar=$(grep -c '^   - Benar: ' "$repo/.claude/devcore-rules.md")
t "repo: contoh Salah dan Benar hanya untuk aturan kritis ($crit)" test "$nsalah" -eq "$crit" -a "$nbenar" -eq "$crit"
nlist=$(grep -cE '^[0-9]+\. \*\*' "$repo/.claude/devcore-rules.md")
t "repo: jumlah butir daftar = jumlah baris tabel"   test "$nlist" -eq "$rows"
nrem=$(grep -c '^- ' "$repo/.claude/devcore-reminder.txt")
t "repo: pengingat = aturan kritis + 2 baris tetap"  test "$nrem" -eq $((crit+2))

# ---------- membangun dari tabel yang diubah ----------
R=$(newroot)
sed -i.bak 's/Kerjakan yang diminta saja; temuan lain dilaporkan, tidak diperbaiki diam-diam\./Kerjakan HANYA yang diminta; sisanya dilaporkan./' "$R/docs/engineering-standard.md"; rm -f "$R/docs/engineering-standard.md.bak"
out=$(build "$R" --check); code=$?
t "ubah tabel tanpa bangun: --check gagal (exit 1)" test "$code" -eq 1
t "ubah tabel tanpa bangun: pesan menyebut BASI"      has "$out" "BASI"
t "ubah tabel tanpa bangun: pesan menyebut perintah perbaikan" has "$out" "scripts/build-rules.sh"
out=$(build "$R"); code=$?
t "bangun: exit 0"                                 test "$code" -eq 0
t "bangun: ringkasan baru masuk ke devcore-rules.md" grep -q 'Kerjakan HANYA yang diminta' "$R/.claude/devcore-rules.md"
t "bangun: ringkasan lama hilang"                   bash -c "! grep -q 'tidak diperbaiki diam-diam' '$R/.claude/devcore-rules.md'"
t "bangun: setelah bangun --check lulus"            "$R/scripts/build-rules.sh" --check "$R"
cp "$R/.claude/devcore-rules.md" "$R/rules.1"; build "$R" >/dev/null
t "bangun: idempoten (hasil sama pada bangun kedua)" cmp -s "$R/.claude/devcore-rules.md" "$R/rules.1"

# bagian di luar penanda tidak boleh tersentuh
R=$(newroot)
before=$(awk 'f{print} /<!-- inti:selesai -->/{f=1}' "$R/.claude/devcore-rules.md" | cksum)
head_before=$(awk '/<!-- inti:mulai -->/{exit} {print}' "$R/.claude/devcore-rules.md" | cksum)
sed -i.bak 's/Hanya dengan alasan tertulis dan izin pengguna\./Hanya dengan alasan tertulis./' "$R/docs/engineering-standard.md"; rm -f "$R/docs/engineering-standard.md.bak"
build "$R" >/dev/null
after=$(awk 'f{print} /<!-- inti:selesai -->/{f=1}' "$R/.claude/devcore-rules.md" | cksum)
head_after=$(awk '/<!-- inti:mulai -->/{exit} {print}' "$R/.claude/devcore-rules.md" | cksum)
t "bangun: bagian setelah penanda tidak berubah"    test "$before" = "$after"
t "bangun: bagian sebelum penanda tidak berubah"    test "$head_before" = "$head_after"

# ---------- validasi masukan ----------
R=$(newroot); sed -i.bak 's/^| AG-05 |/| AG-98 |/' "$R/docs/engineering-standard.md"; rm -f "$R/docs/engineering-standard.md.bak"
out=$(build "$R"); code=$?
t "ID tidak terdefinisi: exit 2"                    test "$code" -eq 2
t "ID tidak terdefinisi: pesan menyebut ID"         has "$out" "AG-98"

R=$(newroot); sed -i.bak 's/| ya | Menulis fungsi `format_tanggal` baru tanpa mencari lebih dulu\. |/| ya |  |/' "$R/docs/engineering-standard.md"; rm -f "$R/docs/engineering-standard.md.bak"
out=$(build "$R"); code=$?
t "aturan kritis tanpa contoh Salah: exit 2"        test "$code" -eq 2
t "aturan kritis tanpa contoh: pesan menyebut contoh" has "$out" "contoh Salah dan Benar"

R=$(newroot); sed -i.bak 's/| AG-10 | Jangan mengarang | \(.*\) | tidak |/| AG-10 | Jangan mengarang | \1 | mungkin |/' "$R/docs/engineering-standard.md"; rm -f "$R/docs/engineering-standard.md.bak"
t "kolom Kritis tidak valid: exit 2"                test "$(code_of "$R/scripts/build-rules.sh" "$R")" -eq 2

R=$(newroot); sed -i.bak '/<!-- inti:mulai -->/d' "$R/.claude/devcore-rules.md"; rm -f "$R/.claude/devcore-rules.md.bak"
t "penanda hilang di devcore-rules.md: exit 2"      test "$(code_of "$R/scripts/build-rules.sh" "$R")" -eq 2

R=$(newroot); sed -i.bak 's/<!-- inti:selesai -->//' "$R/docs/engineering-standard.md"; rm -f "$R/docs/engineering-standard.md.bak"
t "penanda hilang di standar: exit 2"               test "$(code_of "$R/scripts/build-rules.sh" "$R")" -eq 2

R=$(mktmp)
t "standar tidak ada: exit 2"                        test "$(code_of "$here/build-rules.sh" "$R")" -eq 2

# ---------- hook pengingat turunan ----------
hook="$repo/.claude/hooks/prompt-rules-reminder.sh"
t "hook: keluaran sama dengan berkas pengingat"      bash -c "[ \"\$('$hook')\" = \"\$(cat '$repo/.claude/devcore-reminder.txt')\" ]"
R=$(newroot); printf 'PENGINGAT KHUSUS UJI\n' > "$R/.claude/devcore-reminder.txt"
t "hook: mengikuti isi berkas (bukan teks bawaan)"   bash -c "[ \"\$('$R/.claude/hooks/prompt-rules-reminder.sh')\" = 'PENGINGAT KHUSUS UJI' ]"
rm "$R/.claude/devcore-reminder.txt"
out=$("$R/.claude/hooks/prompt-rules-reminder.sh" 2>&1); code=$?
t "hook: tanpa berkas pengingat -> diam dan exit 0"  test -z "$out" -a "$code" -eq 0
t "hook: tidak memuat teks aturan sendiri"           bash -c "! grep -qE 'tindakan destruktif|Jangan melemahkan' '$hook'"

# ---------- uji mutasi: generator yang dirusak harus tertangkap ----------
M=$(newroot)
perl -pi -e "s/^(\s+)if krit == 'ya':\$/\$1if False:/" "$M/scripts/build-rules.sh"
t "mutasi: perusakan benar-benar mengubah generator" grep -q 'if False:' "$M/scripts/build-rules.sh"
"$M/scripts/build-rules.sh" "$M" >/dev/null 2>&1
nm=$(grep -c '^   - Salah: ' "$M/.claude/devcore-rules.md")
t "mutasi: generator rusak tidak lagi menulis contoh (tertangkap oleh uji contoh)" test "$nm" -ne "$crit"

echo "Lulus: $pass  Gagal: $fail"
[ "$fail" -eq 0 ]
