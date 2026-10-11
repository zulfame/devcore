#!/usr/bin/env bash
# Tes untuk skrip pemeriksa. Jalankan: scripts/test-scripts.sh
set -u
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
mkdir -p "$N/docs/adr" "$N/.claude/skills/change-thing" "$N/.claude/hooks" "$N/.claude/agents" "$N/scripts"
printf -- '---\nname: review-thing\n---\n' > "$N/.claude/agents/review-thing.md"
touch "$N/README.md" "$N/CLAUDE.md" "$N/CHANGELOG.md" "$N/docs/engineering-standard.md" "$N/docs/ARCHITECTURE.md" "$N/docs/adr/0001-pilih-stack.md" \
      "$N/.claude/hooks/pretool-a-guard.sh" "$N/.claude/hooks/test-hooks.sh" "$N/scripts/check-x.sh"
printf -- '---\nname: change-thing\n---\n' > "$N/.claude/skills/change-thing/SKILL.md"
check "naming: struktur benar lulus" 0 "OK" "$here/check-naming.sh" "$N"

bad_file() { # nama path
  : > "$N/$2"; check "naming: $1" 1 "PENAMAAN" "$here/check-naming.sh" "$N"; rm "$N/$2"; }
bad_file "dokumen snake_case"   "docs/Bad_Name.md"
bad_file "dokumen camelCase"    "docs/myDoc.md"
bad_file "ADR tanpa nomor"      "docs/adr/pilih-stack.md"
bad_file "ADR nomor 1 digit"    "docs/adr/1-x.md"
bad_file "hook tanpa event"     ".claude/hooks/guard.sh"
bad_file "skrip huruf besar"    "scripts/Do_It.sh"
bad_file "subagent satu kata"   ".claude/agents/reviewer.md"
mkdir -p "$N/.claude/hooks/lib"; : > "$N/.claude/hooks/lib/bash-analyzer.py"
check "naming: pustaka hook kebab-case lulus" 0 "OK" "$here/check-naming.sh" "$N"
bad_file "pustaka hook huruf besar" ".claude/hooks/lib/BadName.py"
printf -- '---\nname: lain-nama\n---\n' > "$N/.claude/agents/review-thing.md"
check "naming: name subagent != berkas" 1 "tidak sama" "$here/check-naming.sh" "$N"
printf -- '---\nname: review-thing\n---\n' > "$N/.claude/agents/review-thing.md"
mkdir "$N/.claude/skills/single"; printf -- '---\nname: single\n---\n' > "$N/.claude/skills/single/SKILL.md"
check "naming: skill satu kata" 1 "PENAMAAN" "$here/check-naming.sh" "$N"; rm -r "$N/.claude/skills/single"
printf -- '---\nname: lain-nama\n---\n' > "$N/.claude/skills/change-thing/SKILL.md"
check "naming: name != folder" 1 "tidak sama" "$here/check-naming.sh" "$N"
printf -- '---\nname: change-thing\n---\n' > "$N/.claude/skills/change-thing/SKILL.md"
mkdir "$N/docs/BadDir"
check "naming: folder docs huruf besar" 1 "PENAMAAN" "$here/check-naming.sh" "$N"; rmdir "$N/docs/BadDir"
mkdir -p "$N/src/MyComponent"   # folder kode tidak diperiksa
check "naming: folder kode diabaikan" 0 "OK" "$here/check-naming.sh" "$N"

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

echo "Lulus: $pass  Gagal: $fail"
[ "$fail" -eq 0 ]
