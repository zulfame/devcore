#!/usr/bin/env bash
# Tes untuk skrip pemeriksa. Jalankan: .devcore/scripts/test-scripts.sh
set -u
# Kedap terhadap konfigurasi git pengguna: tanpa penandatanganan commit, hook global, editor, atau prompt
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_EDITOR=true
here=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
REG=$(mktemp)
cleanup() { while IFS= read -r d; do [ -n "$d" ] && rm -rf "$d"; done < "$REG"; rm -f "$REG"; }
trap cleanup EXIT
# Catat folder sementara di berkas (aman dipakai dalam $(...))
mkd() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; printf '%s' "$d"; }

check() { # nama exit_harapan pola_output(boleh kosong) perintah...
  local name=$1 exp=$2 pat=$3; shift 3
  local out code; out=$("$@" 2>&1); code=$?
  if [ "$code" -ne "$exp" ]; then fail=$((fail+1)); echo "GAGAL: $name (harapan exit $exp, dapat $code) $out"; return; fi
  if [ -n "$pat" ] && ! printf '%s' "$out" | grep -q "$pat"; then
    fail=$((fail+1)); echo "GAGAL: $name (output tidak memuat '$pat') $out"; return; fi
  pass=$((pass+1))
}

# ---------- check-naming ----------
N=$(mkd)
mkdir -p "$N/docs/adr" "$N/.claude/skills/change-thing" "$N/.claude/agents" \
         "$N/.devcore/docs" "$N/.devcore/hooks/lib" "$N/.devcore/scripts"
printf -- '---\nname: review-thing\n---\n' > "$N/.claude/agents/review-thing.md"
printf -- '---\nname: change-thing\n---\n' > "$N/.claude/skills/change-thing/SKILL.md"
printf '.claude/skills/change-thing\n.claude/agents/review-thing.md\n' > "$N/.devcore/managed-claude.txt"
touch "$N/README.md" "$N/CLAUDE.md" "$N/CHANGELOG.md" "$N/docs/ARCHITECTURE.md" "$N/docs/adr/0001-pilih-stack.md" \
      "$N/.devcore/docs/engineering-standard.md" "$N/.devcore/hooks/pretool-a-guard.sh" "$N/.devcore/hooks/test-hooks.sh" \
      "$N/.devcore/hooks/lib/bash-analyzer.py" "$N/.devcore/scripts/check-x.sh"
mkdir -p "$N/scripts"; touch "$N/scripts/test-sync.sh"   # penanda repo devcore sendiri = mode ketat
check "naming: struktur benar lulus" 0 "OK" "$here/check-naming.sh" "$N"

# proyek terpasang (tanpa penanda): dokumen lama proyek tidak diperiksa, yang dibuat kerangka tetap
M=$(mkd); mkdir -p "$M/docs/briefs" "$M/.devcore/docs" "$M/.devcore/hooks" "$M/.devcore/scripts"
touch "$M/TODO.md" "$M/RELEASE_NOTES.md" "$M/docs/API_v2.md" "$M/docs/briefs/0001-ok.md"
check "naming proyek: dokumen lama tidak diperiksa" 0 "OK" "$here/check-naming.sh" "$M"
touch "$M/docs/briefs/jelek.md"
check "naming proyek: brief salah nama tetap gagal" 1 "PENAMAAN" "$here/check-naming.sh" "$M"

bad_file() { # nama path
  : > "$N/$2"; check "naming: $1" 1 "PENAMAAN" "$here/check-naming.sh" "$N"; rm "$N/$2"; }
bad_file "dokumen snake_case"        "docs/Bad_Name.md"
bad_file "dokumen camelCase"         "docs/myDoc.md"
bad_file "dokumen kerangka salah"    ".devcore/docs/Bad_Doc.md"
bad_file "ADR tanpa nomor"           "docs/adr/pilih-stack.md"
bad_file "ADR nomor 1 digit"         "docs/adr/1-x.md"
bad_file "hook tanpa event"          ".devcore/hooks/guard.sh"
bad_file "skrip kerangka huruf besar" ".devcore/scripts/Do_It.sh"
bad_file "pustaka hook huruf besar"  ".devcore/hooks/lib/BadName.py"
printf -- '---\nname: lain-nama\n---\n' > "$N/.claude/agents/review-thing.md"
check "naming: name subagent != berkas" 1 "tidak sama" "$here/check-naming.sh" "$N"
printf -- '---\nname: review-thing\n---\n' > "$N/.claude/agents/review-thing.md"
printf -- '---\nname: lain-nama\n---\n' > "$N/.claude/skills/change-thing/SKILL.md"
check "naming: name skill != folder" 1 "tidak sama" "$here/check-naming.sh" "$N"
printf -- '---\nname: change-thing\n---\n' > "$N/.claude/skills/change-thing/SKILL.md"
mkdir "$N/.claude/skills/single"; printf -- '---\nname: single\n---\n' > "$N/.claude/skills/single/SKILL.md"
printf '.claude/skills/single\n' >> "$N/.devcore/managed-claude.txt"
check "naming: skill kerangka satu kata" 1 "PENAMAAN" "$here/check-naming.sh" "$N"
printf '.claude/skills/change-thing\n.claude/agents/review-thing.md\n' > "$N/.devcore/managed-claude.txt"
check "naming: skill milik proyek (tidak terdaftar) tidak diperiksa" 0 "OK" "$here/check-naming.sh" "$N"
mkdir "$N/docs/BadDir"
check "naming: folder docs huruf besar" 1 "PENAMAAN" "$here/check-naming.sh" "$N"; rmdir "$N/docs/BadDir"
mkdir -p "$N/src/MyComponent" "$N/scripts"; : > "$N/scripts/Do_It.sh"   # kode dan skrip proyek tidak diperiksa
check "naming: folder kode dan skrip proyek diabaikan" 0 "OK" "$here/check-naming.sh" "$N"

# ---------- check-links ----------
L=$(mkd); mkdir -p "$L/docs"
printf '# b\n' > "$L/docs/b.md"
printf '[ok](docs/b.md) [anchor](docs/b.md#bagian) [web](https://example.com) [self](#atas) [dir](docs/)\n' > "$L/a.md"
check "links: semua valid lulus" 0 "OK" "$here/check-links.sh" "$L"
printf '[rusak](docs/tidak-ada.md)\n' > "$L/c.md"
check "links: tautan rusak gagal" 1 "TAUTAN RUSAK" "$here/check-links.sh" "$L"
rm "$L/c.md"
printf '[naik](../a.md)\n' > "$L/docs/d.md"
check "links: relatif ../ valid" 0 "OK" "$here/check-links.sh" "$L"
printf 'Contoh sintaks: `[x](tidak-ada.md)`\n\n```\n[y](juga-tidak-ada.md)\n```\n' > "$L/docs/contoh.md"
check "links: tautan di dalam kode inline/blok diabaikan" 0 "OK" "$here/check-links.sh" "$L"
printf '# spasi\n' > "$L/docs/dengan spasi.md"; printf '[s](docs/dengan%%20spasi.md)\n' > "$L/e.md"
check "links: %20 pada tautan didekode" 0 "OK" "$here/check-links.sh" "$L"

# ---------- check-weakened-tests ----------
R=$(mkd)
( cd "$R" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir -p src docs && printf 'test("a", () => {})\n' > src/a.test.js && printf '# doc\n' > docs/x.md \
  && git add -A && git commit -qm base )
base=$(cd "$R" && git rev-parse HEAD)

scenario() { # nama exit pola berkas isi
  local name=$1 exp=$2 pat=$3 file=$4 content=$5
  ( cd "$R" && git reset -q --hard "$base" && mkdir -p "$(dirname "$file")" && printf '%s\n' "$content" >> "$file" \
    && git add -A && git commit -qm change )
  check "weakened: $name" "$exp" "$pat" bash -c "cd '$R' && '$here/check-weakened-tests.sh' '$base'"
}
scenario "it.skip baru gagal"        1 "PELEMAHAN" src/a.test.js 'it.skip("b", () => {})'
scenario "describe.only gagal"       1 "PELEMAHAN" src/a.test.js 'describe.only("b", () => {})'
scenario "pytest skip gagal"         1 "PELEMAHAN" src/test_a.py '@pytest.mark.skip(reason="x")'
scenario "noqa gagal"                1 "PELEMAHAN" src/a.py 'import os  # noqa'
scenario "eslint-disable gagal"      1 "PELEMAHAN" src/a.js '// eslint-disable-next-line'
scenario "any di TypeScript gagal"   1 "PELEMAHAN" src/a.ts 'const a: any = 1;'
scenario "any di JavaScript lulus"   0 "tidak ditemukan" src/a.js '// any value works here: any'
scenario "devcore-allow lulus"       0 "tidak ditemukan" src/a.test.js 'it.skip("b", () => {}) // devcore-allow: flaky, tiket 12'
scenario "markdown diabaikan"        0 "tidak ditemukan" docs/x.md 'contoh: it.skip( dijelaskan di sini'
scenario "perubahan biasa lulus"     0 "tidak ditemukan" src/a.js 'const total = a + b;'
scenario "continue-on-error gagal"   1 "PELEMAHAN" .github/workflows/ci.yml '    continue-on-error: true'

( cd "$R" && git reset -q --hard "$base" && git rm -q src/a.test.js && git commit -qm hapus )
check "weakened: test dihapus -> peringatan" 0 "PERINGATAN" bash -c "cd '$R' && '$here/check-weakened-tests.sh' '$base'"
check "weakened: base tidak valid dilewati" 0 "DILEWATI" bash -c "cd '$R' && '$here/check-weakened-tests.sh' 0000000000000000000000000000000000000000"
check "weakened: base kosong dilewati" 0 "DILEWATI" bash -c "cd '$R' && '$here/check-weakened-tests.sh' ''"

# ---------- check-analyzer-size ----------
check "ukuran analyzer: di bawah batas lulus" 0 "OK" "$here/check-analyzer-size.sh"
check "ukuran analyzer: melebihi batas gagal" 1 "melebihi batas" env ANALYZER_MAX_LINES=10 "$here/check-analyzer-size.sh"

echo "Lulus: $pass  Gagal: $fail"
[ "$fail" -eq 0 ]
