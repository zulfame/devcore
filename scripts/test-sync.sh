#!/usr/bin/env bash
# Tes untuk scripts/sync-devcore.sh. Khusus pengembangan devcore (tidak dipasang ke proyek lain).
# Jalankan: scripts/test-sync.sh
set -u
here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/.." && pwd -P)
pass=0; fail=0
REG=$(mktemp)
cleanup() { while IFS= read -r d; do [ -n "$d" ] && rm -rf "$d"; done < "$REG"; rm -f "$REG"; }
trap cleanup EXIT

t() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); echo "GAGAL: $name"; fi; }
has() { printf '%s' "$1" | grep -qF -- "$2"; }
hasnt() { ! printf '%s' "$1" | grep -qF -- "$2"; }
jqt() { jq -e "$1" "$2"; }   # kondisi jq harus benar

mktmp() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; printf '%s' "$d"; }
mkrepo() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; git -C "$d" init -q -b main
           git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init; printf '%s' "$d"; }
commit_all() { git -C "$1" add -A; git -C "$1" -c user.email=t@t -c user.name=t commit -q -m "${2:-c}"; }
mksrc() { local d; d=$(mktemp -d); echo "$d" >> "$REG"; tar -C "$repo" --exclude=.git -cf - . | tar -C "$d" -xf -; printf '%s' "$d"; }
sync() { local p=$1; shift; "$here/sync-devcore.sh" --target "$p" "$@" 2>&1; }
ver=$(tr -d '[:space:]' < "$repo/VERSION")

# ---------- cakupan manifest ----------
missing=""
# Khusus pengembangan devcore: sengaja TIDAK dipasang ke proyek lain
devonly=" scripts/test-sync.sh scripts/test-evals.sh scripts/run-evals.sh scripts/grade-eval.sh scripts/summarize-evals.sh scripts/eval-helpers.sh "
for f in .claude/hooks/*.sh .claude/skills/*/SKILL.md .claude/agents/*.md scripts/*.sh docs/templates/*.md; do
  [ -f "$repo/$f" ] || continue
  case "$devonly" in *" $f "*) continue ;; esac
  awk '$1=="managed"{print $2}' "$repo/.claude/devcore.manifest" | grep -qxF "$f" || missing="$missing $f"
done
t "manifest mencakup semua hook/skill/skrip/templat (kecuali test-sync): tidak terdaftar:$missing" test -z "$missing"

# ---------- dry-run ----------
P=$(mkrepo)
out=$(sync "$P")
t "dry-run: menyebut dry-run"        has "$out" "Dry-run"
t "dry-run: tidak menulis apa pun"   test "$(ls -A "$P" | grep -v '^\.git$' | wc -l | tr -d ' ')" = "0"

# ---------- instalasi baru ----------
out=$(sync "$P" --apply)
t "install: lock ditulis"            test -f "$P/.claude/devcore.lock"
t "install: lock memuat versi"       grep -qx "version=$ver" "$P/.claude/devcore.lock"
t "install: hook bisa dieksekusi"    test -x "$P/.claude/hooks/pretool-brief-gate.sh"
t "install: skrip sync terpasang"    test -x "$P/scripts/sync-devcore.sh"
t "install: aturan inti terpasang"   test -f "$P/.claude/devcore-rules.md"
t "install: seed status"             test -f "$P/docs/status.md"
t "install: seed profil"             test -f "$P/docs/project-profile.md"
t "install: seed workflow"           test -f "$P/.github/workflows/devcore-checks.yml"
t "install: seed conf"               test -f "$P/.claude/devcore.conf"
t "install: settings memuat hook SessionStart" jqt '[.hooks.SessionStart[].hooks[].command]|any(test("session-status-loader"))' "$P/.claude/settings.json"
t "install: CLAUDE.md memuat impor"  grep -qxF "@.claude/devcore-rules.md" "$P/CLAUDE.md"
t "install: .gitignore memuat CLAUDE.local.md" grep -qxF "CLAUDE.local.md" "$P/.gitignore"
t "install: tidak menyalin CLAUDE.local.md" test ! -e "$P/CLAUDE.local.md"
t "install: tidak menyalin README.md"  test ! -e "$P/README.md"
t "install: tidak menyalin CHANGELOG"  test ! -e "$P/CHANGELOG.md"
t "install: tidak menyalin briefs"     test ! -e "$P/docs/briefs"
t "install: tidak menyalin adr"        test ! -e "$P/docs/adr"
t "install: tidak menyalin test-sync"  test ! -e "$P/scripts/test-sync.sh"
t "install: subagent peninjau terpasang" test -f "$P/.claude/agents/review-changes.md"
t "install: tidak menyalin folder evals"  test ! -e "$P/evals"
t "install: tidak menyalin skrip evaluasi" test -z "$(ls "$P"/scripts | grep -E 'eval' )"
t "install: tidak ada sisa berkas sementara" test -z "$(find "$P" -name '*.devcore-new' -not -path '*/.git/*')"

# ---------- idempoten ----------
commit_all "$P" "adopsi"
out=$(sync "$P" --apply)
t "idempoten: tidak ada perubahan"   has "$out" "baru=0 perbarui/gabung/lain=0 hapus=0"
t "idempoten: working tree tetap bersih" test -z "$(git -C "$P" status --porcelain)"

# ---------- proyek terpasang lolos pemeriksaannya sendiri ----------
t "proyek terpasang: run-checks.sh lulus" bash -c "cd '$P' && scripts/run-checks.sh"

# ---------- penggabungan settings yang sudah ada ----------
P2=$(mkrepo); mkdir -p "$P2/.claude"
cat > "$P2/.claude/settings.json" <<'JSON'
{"env":{"FOO":"1"},
 "permissions":{"deny":["Read(./secrets/**)"],"allow":["Bash(npm test)"]},
 "hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"./my-bash-hook.sh"}]}],
          "Stop":[{"hooks":[{"type":"command","command":"./my-stop.sh"}]}]}}
JSON
commit_all "$P2" "settings proyek"
sync "$P2" --apply >/dev/null
s="$P2/.claude/settings.json"
t "merge: env proyek dipertahankan"      jqt '.env.FOO=="1"' "$s"
t "merge: allow proyek dipertahankan"    jqt '.permissions.allow|index("Bash(npm test)")!=null' "$s"
t "merge: deny proyek dipertahankan"     jqt '.permissions.deny|index("Read(./secrets/**)")!=null' "$s"
t "merge: deny devcore ditambahkan"      jqt '.permissions.deny|index("Read(./.env)")!=null' "$s"
t "merge: hook proyek dipertahankan"     jqt '[.hooks.PreToolUse[].hooks[].command]|index("./my-bash-hook.sh")!=null' "$s"
t "merge: hook devcore digabung ke grup Bash yang sama" jqt '[.hooks.PreToolUse[]|select(.matcher=="Bash")]|length==1 and (.[0].hooks|length)==2' "$s"
t "merge: hook Stop proyek dipertahankan" jqt '.hooks.Stop[0].hooks[0].command=="./my-stop.sh"' "$s"
commit_all "$P2" "adopsi"
sync "$P2" --apply >/dev/null
t "merge: idempoten, tree bersih"        test -z "$(git -C "$P2" status --porcelain)"

# ---------- CLAUDE.md dan AGENTS.md ----------
P3=$(mkrepo); printf '# Proyek saya\n\nAturan saya sendiri.\n' > "$P3/CLAUDE.md"; commit_all "$P3"
sync "$P3" --apply >/dev/null
t "claude.md: isi proyek utuh"           grep -qxF "Aturan saya sendiri." "$P3/CLAUDE.md"
t "claude.md: impor ditambah sekali"     test "$(grep -cxF '@.claude/devcore-rules.md' "$P3/CLAUDE.md")" = "1"
commit_all "$P3"; sync "$P3" --apply >/dev/null
t "claude.md: tidak menggandakan impor"  test "$(grep -cxF '@.claude/devcore-rules.md' "$P3/CLAUDE.md")" = "1"

P4=$(mkrepo); printf '# Aturan agent lain\n' > "$P4/AGENTS.md"; commit_all "$P4"
sync "$P4" --apply >/dev/null
t "agents.md: CLAUDE.md baru mengimpor AGENTS.md" grep -qxF "@AGENTS.md" "$P4/CLAUDE.md"
t "agents.md: CLAUDE.md baru mengimpor aturan devcore" grep -qxF "@.claude/devcore-rules.md" "$P4/CLAUDE.md"

P5=$(mkrepo); printf '# Punya saya\n' > "$P5/CLAUDE.md"; printf '# agents\n' > "$P5/AGENTS.md"; commit_all "$P5"
out=$(sync "$P5" --apply)
t "agents.md: CLAUDE.md yang sudah ada tidak dipaksa mengimpor AGENTS.md" test "$(grep -c '^@AGENTS.md' "$P5/CLAUDE.md")" = "0"
t "agents.md: ada catatan untuk pengguna" has "$out" "AGENTS.md ada"

# ---------- .gitignore ----------
P6=$(mkrepo); printf 'node_modules/\n.env' > "$P6/.gitignore"; commit_all "$P6"
sync "$P6" --apply >/dev/null
t "gitignore: isi lama dipertahankan"    grep -qxF "node_modules/" "$P6/.gitignore"
t "gitignore: baris tanpa newline akhir tidak menempel" grep -qxF ".env" "$P6/.gitignore"
t "gitignore: baris devcore ditambah"    grep -qxF ".claude/settings.local.json" "$P6/.gitignore"
commit_all "$P6"; sync "$P6" --apply >/dev/null
t "gitignore: tidak menggandakan"        test "$(grep -cxF 'CLAUDE.local.md' "$P6/.gitignore")" = "1"

# ---------- pembaruan: modifikasi lokal, seed, penghapusan ----------
S2=$(mksrc); echo "# v2" >> "$S2/.claude/hooks/prompt-rules-reminder.sh"; echo "# v2" >> "$S2/docs/templates/task-brief.md"
echo "BRIEF_GATE=off" > "$S2/.claude/devcore.conf"; echo "9.9.9" > "$S2/VERSION"
P7=$(mkrepo); sync "$P7" --apply >/dev/null; commit_all "$P7" "adopsi"
echo "# kustom lokal" >> "$P7/.claude/hooks/prompt-rules-reminder.sh"
echo "BRIEF_GATE=ask" > "$P7/.claude/devcore.conf"; commit_all "$P7" "kustom"
out=$(sync "$P7" --source "$S2")
t "update: dry-run melaporkan berkas diubah lokal" has "$out" "LEWATI    .claude/hooks/prompt-rules-reminder.sh"
out=$(sync "$P7" --source "$S2" --apply)
t "update: berkas diubah lokal dipertahankan" grep -qxF "# kustom lokal" "$P7/.claude/hooks/prompt-rules-reminder.sh"
t "update: berkas tak diubah diperbarui"   cmp -s "$S2/docs/templates/task-brief.md" "$P7/docs/templates/task-brief.md"
t "update: seed milik proyek tidak ditimpa" grep -qx "BRIEF_GATE=ask" "$P7/.claude/devcore.conf"
t "update: lock naik versi"                grep -qx "version=9.9.9" "$P7/.claude/devcore.lock"
commit_all "$P7" "update"
sync "$P7" --source "$S2" --overwrite-modified --apply >/dev/null
t "update: --overwrite-modified menimpa"   cmp -s "$S2/.claude/hooks/prompt-rules-reminder.sh" "$P7/.claude/hooks/prompt-rules-reminder.sh"

# ---------- pembaruan: berkas dan hook usang dibuang ----------
S3=$(mksrc)
grep -v -e 'session-status-loader.sh' -e 'skills/profile-project' -e 'skills/check-security' "$S3/.claude/devcore.manifest" > "$S3/m.tmp" && mv "$S3/m.tmp" "$S3/.claude/devcore.manifest"
rm "$S3/.claude/hooks/session-status-loader.sh"; rm -r "$S3/.claude/skills/profile-project" "$S3/.claude/skills/check-security"
jq 'del(.hooks.SessionStart)' "$S3/.claude/settings.json" > "$S3/s.tmp" && mv "$S3/s.tmp" "$S3/.claude/settings.json"
echo "9.9.9" > "$S3/VERSION"
P8=$(mkrepo); sync "$P8" --apply >/dev/null; commit_all "$P8" "adopsi"
echo "# kustom" >> "$P8/.claude/skills/profile-project/SKILL.md"; commit_all "$P8" "kustom skill"
out=$(sync "$P8" --source "$S3" --apply)
t "usang: hook yang tak diubah dihapus"       test ! -e "$P8/.claude/hooks/session-status-loader.sh"
t "usang: entri hook dibuang dari settings"   jqt '[.hooks[]?[]?.hooks[]?.command]|map(select(test("session-status-loader")))|length==0' "$P8/.claude/settings.json"
t "usang: skill yang tak diubah dihapus beserta foldernya" test ! -e "$P8/.claude/skills/check-security"
t "usang: skill yang diubah lokal dipertahankan" test -f "$P8/.claude/skills/profile-project/SKILL.md"
t "usang: ada peringatan untuk yang dipertahankan" has "$out" "usang di kerangka tetapi diubah lokal"
t "usang: hook lain tetap ada di settings"    jqt '[.hooks.PreToolUse[].hooks[].command]|any(test("pretool-brief-gate"))' "$P8/.claude/settings.json"

# ---------- penolakan ----------
P9=$(mkrepo); sync "$P9" --apply >/dev/null; commit_all "$P9" "adopsi"
echo "kotor" >> "$P9/.claude/devcore.conf"
out=$(sync "$P9" --apply); code=$?
t "tolak: --apply di working tree kotor"      test "$code" -eq 2
t "tolak: pesan menyebut tidak bersih"        has "$out" "tidak bersih"
out=$(sync "$P9"); code=$?
t "tolak: dry-run tetap jalan dengan catatan" test "$code" -eq 0

NG=$(mktmp)
out=$(sync "$NG" --apply); code=$?
t "tolak: target non-git"                     test "$code" -eq 2
out=$("$here/sync-devcore.sh" --target "$repo" 2>&1); code=$?
t "tolak: sumber sama dengan target"          test "$code" -eq 2

S4=$(mksrc); echo "managed ../luar.txt x" >> "$S4/.claude/devcore.manifest"
out=$(sync "$(mkrepo)" --source "$S4"); code=$?
t "tolak: jalur manifest tidak aman"          test "$code" -eq 2
S5=$(mksrc); echo "managed docs/tidak-ada.md" >> "$S5/.claude/devcore.manifest"
out=$(sync "$(mkrepo)" --source "$S5"); code=$?
t "tolak: manifest menyebut berkas yang tak ada" test "$code" -eq 2
out=$("$here/sync-devcore.sh" --source "$(mktmp)" --target "$(mkrepo)" 2>&1); code=$?
t "tolak: sumber bukan devcore"               test "$code" -eq 2

P10=$(mkrepo); mkdir -p "$P10/.claude"; echo '{rusak' > "$P10/.claude/settings.json"; commit_all "$P10"
out=$(sync "$P10" --apply); code=$?
t "settings rusak: tidak crash"               test "$code" -eq 0
t "settings rusak: dilewati dengan pesan"     has "$out" "JSON tidak valid"
t "settings rusak: isi tidak diubah"          grep -qxF '{rusak' "$P10/.claude/settings.json"

# ---------- sumber lewat clone ----------
G=$(mktmp); mkdir "$G/devcore.git"; tar -C "$S2" -cf - . | tar -C "$G/devcore.git" -xf -
git -C "$G/devcore.git" init -q -b main; git -C "$G/devcore.git" add -A; git -C "$G/devcore.git" -c user.email=t@t -c user.name=t commit -q -m src
P11=$(mkrepo)
out=$(sync "$P11" --source "$G/devcore.git" --apply)
t "clone: instalasi dari sumber git"          grep -qx "version=9.9.9" "$P11/.claude/devcore.lock"
t "clone: menyebut commit sumber"             grep -qE '^commit=[0-9a-f]{7,}' "$P11/.claude/devcore.lock"

echo "Lulus: $pass  Gagal: $fail"
[ "$fail" -eq 0 ]
