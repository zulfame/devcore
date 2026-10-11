#!/usr/bin/env bash
# Tes untuk .devcore/scripts/sync-devcore.sh. Khusus pengembangan devcore (tidak dipasang ke proyek lain).
# Jalankan: scripts/test-sync.sh
set -u
here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/.." && pwd -P)
sync="$repo/.devcore/scripts/sync-devcore.sh"
pass=0; fail=0
REG=$(mktemp)
cleanup() { while IFS= read -r d; do [ -n "$d" ] && rm -rf "$d"; done < "$REG"; rm -f "$REG"; }
trap cleanup EXIT

t() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); echo "GAGAL: $name"; fi; }
has() { printf '%s' "$1" | grep -qF -- "$2"; }
jqt() { jq -e "$1" "$2"; }
mktmp() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; printf '%s' "$d"; }
mkrepo() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; git -C "$d" init -q -b main
           git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init; printf '%s' "$d"; }
commit_all() { git -C "$1" add -A; git -C "$1" -c user.email=t@t -c user.name=t commit -q -m "${2:-c}"; }
mksrc() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; tar -C "$repo" --exclude=.git -cf - . | tar -C "$d" -xf -; printf '%s' "$d"; }
sy() { local p=$1; shift; "$sync" --target "$p" "$@" 2>&1; }
ver=$(tr -d '[:space:]' < "$repo/.devcore/VERSION")

# ---------- konsistensi sumber ----------
missing=""
while IFS= read -r p; do case "$p" in ""|"#"*) continue ;; esac; [ -e "$repo/$p" ] || missing="$missing $p"; done < "$repo/.devcore/managed-claude.txt"
t "managed-claude.txt: semua jalur ada (hilang:$missing)" test -z "$missing"
unlisted=""
for d in "$repo"/.claude/skills/*/; do p=".claude/skills/$(basename "$d")"; grep -qxF "$p" "$repo/.devcore/managed-claude.txt" || unlisted="$unlisted $p"; done
for f in "$repo"/.claude/agents/*.md; do p=".claude/agents/$(basename "$f")"; grep -qxF "$p" "$repo/.devcore/managed-claude.txt" || unlisted="$unlisted $p"; done
t "semua skill/subagent di sumber tercatat (belum tercatat:$unlisted)" test -z "$unlisted"
t "settings sumber hanya memuat hook di .devcore/" jqt '[.hooks[][]?.hooks[]?.command]|all(startswith("$CLAUDE_PROJECT_DIR/.devcore/"))' "$repo/.claude/settings.json"

# ---------- dry-run ----------
P=$(mkrepo)
out=$(sy "$P")
t "dry-run: menyebut dry-run"        has "$out" "Dry-run"
t "dry-run: tidak menulis apa pun"   test "$(ls -A "$P" | grep -vc '^\.git$')" = "0"

# ---------- repo baru ----------
out=$(sy "$P" --apply)
t "baru: .devcore terpasang dengan versi"   grep -qx "$ver" "$P/.devcore/VERSION"
t "baru: hook dapat dieksekusi"             test -x "$P/.devcore/hooks/pretool-brief-gate.sh"
t "baru: skrip sinkronisasi terpasang"      test -x "$P/.devcore/scripts/sync-devcore.sh"
t "baru: skill dan subagent terpasang"      test -f "$P/.claude/skills/write-brief/SKILL.md" -a -f "$P/.claude/agents/review-changes.md"
t "baru: settings memuat hook SessionStart" jqt '[.hooks.SessionStart[].hooks[].command]|any(test("\\.devcore/hooks/session-status-loader"))' "$P/.claude/settings.json"
t "baru: CLAUDE.md starter memuat impor"    grep -qxF "@.devcore/rules.md" "$P/CLAUDE.md"
t "baru: CLAUDE.md starter memuat tabel pengecualian" grep -q "Pengecualian devcore" "$P/CLAUDE.md"
t "baru: .gitignore memuat CLAUDE.local.md" grep -qxF "CLAUDE.local.md" "$P/.gitignore"
t "baru: seed conf, workflow, status, profil" test -f "$P/.claude/devcore.conf" -a -f "$P/.github/workflows/devcore-checks.yml" -a -f "$P/docs/status.md" -a -f "$P/docs/project-profile.md"
t "baru: workflow memanggil run-checks di .devcore" grep -q "\.devcore/scripts/run-checks.sh" "$P/.github/workflows/devcore-checks.yml"
for x in CLAUDE.local.md README.md CHANGELOG.md docs/briefs docs/riwayat.md docs/adr scripts evals; do
  t "baru: tidak menyalin milik sumber ($x)" test ! -e "$P/$x"
done
t "baru: tidak ada berkas sementara tertinggal" test -z "$(find "$P" -name '*.baru' -not -path '*/.git/*')"

# ---------- idempoten dan proyek hasil pasang lolos pemeriksaannya sendiri ----------
commit_all "$P" "adopsi"
out=$(sy "$P" --apply)
t "idempoten: tidak ada perubahan"          has "$out" "baru=0 perbarui=0"
t "idempoten: working tree tetap bersih"    test -z "$(git -C "$P" status --porcelain)"
t "proyek terpasang: run-checks lulus"      bash -c "cd '$P' && .devcore/scripts/run-checks.sh"

# ---------- repo existing penuh bentrokan ----------
PX=$(mkrepo)
mkdir -p "$PX/.claude/skills/write-brief" "$PX/.claude/skills/pdf-reader" "$PX/scripts" "$PX/docs/adr" "$PX/.github/workflows"
printf -- '---\nname: write-brief\n---\nmilik proyek\n' > "$PX/.claude/skills/write-brief/SKILL.md"
printf -- '---\nname: pdf-reader\n---\nmilik proyek\n' > "$PX/.claude/skills/pdf-reader/SKILL.md"
printf '# Proyek saya\n\nAturan saya sendiri.\n' > "$PX/CLAUDE.md"
printf '# aturan agent lain\n' > "$PX/AGENTS.md"
printf 'echo punya-saya\n' > "$PX/scripts/check-links.sh"
printf '# adr proyek\n' > "$PX/docs/adr/0001-x.md"
printf 'name: ci\n' > "$PX/.github/workflows/ci.yml"
printf 'node_modules/\n.env' > "$PX/.gitignore"
cat > "$PX/.claude/settings.json" <<'JSON'
{"env":{"FOO":"1"},
 "permissions":{"allow":["Bash(npm test)"],"deny":["Read(./secrets/**)"]},
 "hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"./hook-proyek.sh"}]}],
          "Stop":[{"hooks":[{"type":"command","command":"./my-stop.sh"}]}]}}
JSON
commit_all "$PX" "proyek existing"
out=$(sy "$PX")
t "existing dry-run: melaporkan bentrok skill"     has "$out" "BENTROK  .claude/skills/write-brief"
t "existing dry-run: tidak menulis"                test "$(git -C "$PX" status --porcelain | wc -l | tr -d ' ')" = "0"
out=$(sy "$PX" --apply)
t "existing: skill senama milik proyek utuh"       grep -qx "milik proyek" "$PX/.claude/skills/write-brief/SKILL.md"
t "existing: skill lain milik proyek tak tersentuh" grep -qx "milik proyek" "$PX/.claude/skills/pdf-reader/SKILL.md"
t "existing: skill devcore lain tetap terpasang"   test -f "$PX/.claude/skills/verify-done/SKILL.md"
t "existing: isi CLAUDE.md proyek utuh"            grep -qx "Aturan saya sendiri." "$PX/CLAUDE.md"
t "existing: impor ditambah tepat sekali"          test "$(grep -cxF '@.devcore/rules.md' "$PX/CLAUDE.md")" = "1"
t "existing: AGENTS.md ada catatan"                has "$out" "AGENTS.md ada tetapi tidak diimpor"
t "existing: skrip proyek senama tak tersentuh"    grep -qx 'echo punya-saya' "$PX/scripts/check-links.sh"
t "existing: ADR proyek tak tersentuh"             grep -qx '# adr proyek' "$PX/docs/adr/0001-x.md"
t "existing: workflow CI proyek tak tersentuh"     grep -qx 'name: ci' "$PX/.github/workflows/ci.yml"
t "existing: workflow devcore berdampingan"        test -f "$PX/.github/workflows/devcore-checks.yml"
t "existing: ada info workflow CI lain"            has "$out" "workflow CI lain"
t "existing: settings env proyek dipertahankan"    jqt '.env.FOO=="1"' "$PX/.claude/settings.json"
t "existing: izin allow/deny proyek dipertahankan" jqt '.permissions.allow|index("Bash(npm test)")!=null' "$PX/.claude/settings.json"
t "existing: deny devcore ditambahkan"             jqt '.permissions.deny|index("Read(./.env)")!=null' "$PX/.claude/settings.json"
t "existing: hook proyek dipertahankan"            jqt '[.hooks.PreToolUse[].hooks[].command]|index("./hook-proyek.sh")!=null' "$PX/.claude/settings.json"
t "existing: hook Stop proyek dipertahankan"       jqt '.hooks.Stop[0].hooks[0].command=="./my-stop.sh"' "$PX/.claude/settings.json"
t "existing: hook devcore bergabung di grup Bash yang sama" jqt '[.hooks.PreToolUse[]|select(.matcher=="Bash")]|length==1' "$PX/.claude/settings.json"
t "existing: .gitignore lama utuh, baris tanpa newline tidak menempel" bash -c "grep -qxF 'node_modules/' '$PX/.gitignore' && grep -qxF '.env' '$PX/.gitignore'"
t "existing: pemeriksa penamaan lulus (AGENTS.md sah)" bash -c "cd '$PX' && .devcore/scripts/check-naming.sh"
commit_all "$PX" "adopsi"
out=$(sy "$PX" --apply)
t "existing idempoten: hanya bentrok yang sama"    has "$out" "baru=0 perbarui=0"
t "existing: kepemilikan hanya untuk yang dipasang (bukan skill bentrok)" bash -c "! grep -qx '.claude/skills/write-brief' '$PX/.devcore/owned-claude.txt' && grep -qx '.claude/skills/verify-done' '$PX/.devcore/owned-claude.txt'"
t "existing: skill proyek senama TIDAK ditimpa pada pemasangan kedua" grep -qx "milik proyek" "$PX/.claude/skills/write-brief/SKILL.md"
t "existing idempoten: tree bersih"                test -z "$(git -C "$PX" status --porcelain)"

# ---------- pembaruan ----------
P2=$(mkrepo); sy "$P2" --apply >/dev/null
jq '.hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"./hook-proyek.sh"}]}]' "$P2/.claude/settings.json" > "$P2/s.tmp" && mv "$P2/s.tmp" "$P2/.claude/settings.json"
echo "BRIEF_GATE=ask" > "$P2/.claude/devcore.conf"
commit_all "$P2" "adopsi + kustom proyek"
S2=$(mksrc)
echo "# aturan versi baru" >> "$S2/.devcore/rules.md"
echo "# v2" >> "$S2/.claude/skills/verify-done/SKILL.md"
echo "isi baru" > "$S2/.devcore/docs/baru.md"
rm "$S2/.devcore/docs/adopting.md"
echo "9.9.9" > "$S2/.devcore/VERSION"
echo "BRIEF_GATE=off" > "$S2/.claude/devcore.conf"
jq '(.hooks.PreToolUse[] | select(.matcher | test("Write")) | .matcher) = "Write|Edit"' "$S2/.claude/settings.json" > "$S2/s.tmp" && mv "$S2/s.tmp" "$S2/.claude/settings.json"
out=$(sy "$P2" --source "$S2")
t "pembaruan dry-run: melaporkan penggantian versi" has "$out" "$ver → 9.9.9"
out=$(sy "$P2" --source "$S2" --apply)
t "pembaruan: versi naik"                          grep -qx "9.9.9" "$P2/.devcore/VERSION"
t "pembaruan: isi folder .devcore diganti"         grep -qx "# aturan versi baru" "$P2/.devcore/rules.md"
t "pembaruan: berkas baru muncul"                  test -f "$P2/.devcore/docs/baru.md"
t "pembaruan: berkas yang dihapus di sumber hilang" test ! -e "$P2/.devcore/docs/adopting.md"
t "pembaruan: skill milik kerangka diperbarui"     grep -qx "# v2" "$P2/.claude/skills/verify-done/SKILL.md"
t "pembaruan: devcore.conf milik proyek tidak ditimpa" grep -qx "BRIEF_GATE=ask" "$P2/.claude/devcore.conf"
t "pembaruan: hook proyek dipertahankan"           jqt '[.hooks.PreToolUse[].hooks[].command]|index("./hook-proyek.sh")!=null' "$P2/.claude/settings.json"
t "pembaruan: penjaga tulis hanya satu entri"      jqt '[.hooks.PreToolUse[].hooks[].command|select(test("pretool-write-guard"))]|length==1' "$P2/.claude/settings.json"
t "pembaruan: matcher mengikuti sumber"            jqt '[.hooks.PreToolUse[]|select(.hooks[].command|test("pretool-write-guard"))|.matcher]|.[0]=="Write|Edit"' "$P2/.claude/settings.json"
t "pembaruan: tidak ada grup hook kosong"          jqt '[.hooks[][]?|select((.hooks|length)==0)]|length==0' "$P2/.claude/settings.json"
commit_all "$P2" "update 9.9.9"
out=$(sy "$P2" --source "$S2" --apply)
t "pembaruan idempoten"                            has "$out" "baru=0 perbarui=0"
# perubahan lokal di .devcore ikut tertimpa (dan terlihat lewat git diff sebelum commit)
echo "# kustom lokal" >> "$P2/.devcore/rules.md"; commit_all "$P2" "kustom di .devcore"
sy "$P2" --source "$S2" --apply >/dev/null
t "perubahan lokal di .devcore ditimpa (terlihat di git diff)" bash -c "! grep -q 'kustom lokal' '$P2/.devcore/rules.md' && [ -n \"\$(git -C '$P2' status --porcelain)\" ]"

# ---------- penolakan ----------
P3=$(mkrepo); sy "$P3" --apply >/dev/null; commit_all "$P3" "adopsi"
echo "kotor" >> "$P3/.claude/devcore.conf"
out=$(sy "$P3" --apply); code=$?
t "tolak: --apply di working tree kotor"           test "$code" -eq 2
t "tolak: pesan menyebut tidak bersih"             has "$out" "tidak bersih"
out=$(sy "$P3"); code=$?
t "dry-run di tree kotor tetap jalan"              test "$code" -eq 0
NG=$(mktmp); out=$(sy "$NG" --apply); code=$?
t "tolak: target bukan git"                        test "$code" -eq 2
out=$("$sync" --target "$repo" 2>&1); code=$?
t "tolak: sumber sama dengan target"               test "$code" -eq 2
PO=$(mkrepo); mkdir -p "$PO/.devcore"; echo x > "$PO/.devcore/milik-orang.txt"; commit_all "$PO"
out=$(sy "$PO" --apply); code=$?
t "tolak: .devcore bukan milik devcore"            test "$code" -eq 2
t "tolak: .devcore asing tidak disentuh"           test -f "$PO/.devcore/milik-orang.txt"
out=$("$sync" --source "$(mktmp)" --target "$(mkrepo)" 2>&1); code=$?
t "tolak: sumber bukan devcore"                    test "$code" -eq 2
PB=$(mkrepo); mkdir -p "$PB/.claude"; echo '{rusak' > "$PB/.claude/settings.json"; commit_all "$PB"
out=$(sy "$PB" --apply); code=$?
t "settings rusak: tidak crash dan dilewati"       bash -c "[ $code -eq 0 ] && printf '%s' \"$out\" | grep -q 'JSON tidak valid'"
t "settings rusak: isi tidak diubah"               grep -qxF '{rusak' "$PB/.claude/settings.json"
"$sync" --bogus >/dev/null 2>&1; t "argumen tak dikenal: exit 2" test $? -eq 2

# ---------- sumber lewat clone ----------
G=$(mktmp); mkdir "$G/devcore.git"; tar -C "$repo" --exclude=.git -cf - . | tar -C "$G/devcore.git" -xf -
git -C "$G/devcore.git" init -q -b main; git -C "$G/devcore.git" add -A; git -C "$G/devcore.git" -c user.email=t@t -c user.name=t commit -q -m src
P4=$(mkrepo); sy "$P4" --source "$G/devcore.git" --apply >/dev/null
t "clone: instalasi dari sumber git"               grep -qx "$ver" "$P4/.devcore/VERSION"

echo "Lulus: $pass  Gagal: $fail"
[ "$fail" -eq 0 ]
