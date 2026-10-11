#!/usr/bin/env bash
# sync-devcore.sh — pasang atau perbarui kerangka devcore pada sebuah proyek.
#
# Kerangka = folder .devcore/ (SELURUHNYA diganti saat pembaruan) + skill/subagent di .claude/
# (daftar: .devcore/managed-claude.txt) + entri hook di .claude/settings.json + satu baris impor di CLAUDE.md.
# Berkas milik proyek (CLAUDE.md, .claude/devcore.conf, docs/*) tidak pernah ditimpa.
#
# Pengaman: dry-run bawaan; target harus akar repo git dengan working tree bersih (perubahan ditinjau lewat
# git diff); tidak pernah commit; berkas senama di .claude/ yang bukan milik devcore dilaporkan BENTROK dan dilewati.
#
# Pakai:
#   .devcore/scripts/sync-devcore.sh --target <proyek> [--apply]                 (dijalankan dari klon devcore)
#   .devcore/scripts/sync-devcore.sh --source <dir|url> [--ref <ref>] [--apply]  (dijalankan di dalam proyek)
set -u

main() {
  die() { echo "GALAT: $*" >&2; exit 2; }
  say() { printf '%-8s %s\n' "$1" "$2"; }
  local script_root source_arg="" target_arg="" ref="" apply=0
  script_root=$(cd "$(dirname "$0")/../.." && pwd -P)
  while [ $# -gt 0 ]; do
    case "$1" in
      --source) [ $# -ge 2 ] || die "--source butuh nilai"; source_arg=$2; shift 2 ;;
      --target) [ $# -ge 2 ] || die "--target butuh nilai"; target_arg=$2; shift 2 ;;
      --ref)    [ $# -ge 2 ] || die "--ref butuh nilai"; ref=$2; shift 2 ;;
      --apply) apply=1; shift ;;
      -h|--help) sed -n '2,/^set -u/p' "$0" | sed -e '$d' -e 's/^# \{0,1\}//'; exit 0 ;;
      *) die "argumen tidak dikenal: $1" ;;
    esac
  done
  command -v jq  >/dev/null 2>&1 || die "jq diperlukan"
  command -v git >/dev/null 2>&1 || die "git diperlukan"
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT   # global: trap EXIT berjalan setelah main selesai

  # ---------- sumber ----------
  local src label=lokal
  case "$source_arg" in
    "") src=$script_root ;;
    http://*|https://*|git@*|ssh://*|*.git)
      src="$tmp/src"; label=$source_arg
      local cargs=(--quiet --depth 1); [ -n "$ref" ] && cargs+=(--branch "$ref")
      git clone "${cargs[@]}" "$source_arg" "$src" 2>"$tmp/err" || die "gagal clone $source_arg: $(cat "$tmp/err")" ;;
    *) src=$(cd "$source_arg" 2>/dev/null && pwd -P) || die "sumber tidak ditemukan: $source_arg" ;;
  esac
  [ -f "$src/.devcore/VERSION" ] && [ -f "$src/.devcore/managed-claude.txt" ] \
    || die "sumber bukan repo devcore (tidak ada .devcore/VERSION dan managed-claude.txt); gunakan --source <dir|url>"
  local ver old_ver=belum; ver=$(tr -d '[:space:]' < "$src/.devcore/VERSION")

  # ---------- target ----------
  local tgt top
  if [ -n "$target_arg" ]; then tgt=$(cd "$target_arg" 2>/dev/null && pwd -P) || die "target tidak ditemukan: $target_arg"
  else tgt=$(git rev-parse --show-toplevel 2>/dev/null) || die "bukan repo git; gunakan --target <proyek>"; tgt=$(cd "$tgt" && pwd -P); fi
  top=$(git -C "$tgt" rev-parse --show-toplevel 2>/dev/null) || die "target bukan repositori git: $tgt"
  [ "$(cd "$top" && pwd -P)" = "$tgt" ] || die "target harus akar repositori git ($top)"
  [ "$src" != "$tgt" ] || die "sumber dan target sama; jalankan dari klon devcore dengan --target <proyek>"
  if [ -d "$tgt/.devcore" ] && [ ! -f "$tgt/.devcore/VERSION" ]; then
    die ".devcore/ sudah ada di target tetapi bukan milik devcore (tanpa VERSION); pindahkan atau ganti namanya dulu"
  fi
  if [ -n "$(git -C "$tgt" status --porcelain --untracked-files=no)" ]; then
    [ "$apply" -eq 1 ] && die "working tree target tidak bersih; commit atau stash dulu agar perubahan devcore mudah ditinjau"
    echo "CATATAN: working tree target tidak bersih; --apply akan menolak."
  fi
  [ -f "$tgt/.devcore/VERSION" ] && old_ver=$(tr -d '[:space:]' < "$tgt/.devcore/VERSION")
  # kepemilikan berkas .claude = yang BENAR-BENAR dipasang devcore sebelumnya (owned-claude.txt), dibaca sebelum folder diganti.
  # Daftar sumber (managed-claude.txt) tidak dipakai di sini: ia memuat juga berkas yang dilewati karena bentrok.
  cp "$tgt/.devcore/owned-claude.txt" "$tmp/owned" 2>/dev/null || : > "$tmp/owned"
  : > "$tmp/newowned"

  echo "devcore sync [$([ "$apply" -eq 1 ] && echo apply || echo dry-run)]"
  echo "  sumber : v$ver $label"
  echo "  target : $tgt (terpasang: $old_ver)"
  echo

  local n_new=0 n_upd=0 n_same=0 n_conf=0 changed_dir=1
  put() { [ "$apply" -eq 1 ] || return 0; mkdir -p "$(dirname "$2")"; rm -rf "$2"; cp -R "$1" "$2"; }

  # ---------- skill dan subagent milik kerangka (di .claude/) ----------
  local p
  while IFS= read -r p; do
    case "$p" in ""|"#"*) continue ;; esac
    if [ ! -e "$tgt/$p" ]; then say BARU "$p"; n_new=$((n_new+1)); put "$src/$p" "$tgt/$p"; echo "$p" >> "$tmp/newowned"
    elif grep -qxF "$p" "$tmp/owned"; then
      echo "$p" >> "$tmp/newowned"
      if diff -rq "$src/$p" "$tgt/$p" >/dev/null 2>&1; then n_same=$((n_same+1))
      else say PERBARUI "$p"; n_upd=$((n_upd+1)); put "$src/$p" "$tgt/$p"; fi
    else say BENTROK "$p (sudah ada dan bukan milik devcore; dilewati, milik proyek tetap utuh)"; n_conf=$((n_conf+1)); fi
  done < "$src/.devcore/managed-claude.txt"

  # ---------- folder .devcore/ (diganti seluruhnya; owned-claude.txt khusus target, tidak dibandingkan) ----------
  if [ -d "$tgt/.devcore" ] && diff -rq -x owned-claude.txt "$src/.devcore" "$tgt/.devcore" >/dev/null 2>&1; then changed_dir=0; n_same=$((n_same+1))
  else say GANTI ".devcore/ ($old_ver → $ver)"; n_upd=$((n_upd+1)); fi
  if [ "$apply" -eq 1 ]; then
    if [ "$changed_dir" -eq 1 ]; then
      rm -rf "$tgt/.devcore.baru"; cp -R "$src/.devcore" "$tgt/.devcore.baru"
      rm -rf "$tgt/.devcore"; mv "$tgt/.devcore.baru" "$tgt/.devcore"
    fi
    cp "$tmp/newowned" "$tgt/.devcore/owned-claude.txt"
  fi

  # ---------- .claude/settings.json: hook milik kerangka dikenali dari prefix .devcore/ ----------
  cat > "$tmp/merge.jq" <<'JQ'
def dedupe: reduce .[] as $x ([]; if index([$x]) == null then . + [$x] else . end);
def own: startswith("$CLAUDE_PROJECT_DIR/.devcore/");
def strip: map(.hooks |= map(select(((.command // "") | own) | not))) | map(select((.hooks | length) > 0));
def merge($sg): reduce $sg[] as $g (.;
    (map(.matcher // "") | index([$g.matcher // ""])) as $i
    | if $i == null then . + [$g] else .[$i].hooks += $g.hooks end);
$s[0] as $src
| .permissions.deny = (((.permissions.deny // []) + ($src.permissions.deny // [])) | dedupe)
| .permissions.ask  = (((.permissions.ask  // []) + ($src.permissions.ask  // [])) | dedupe)
| .hooks = (((.hooks // {}) | with_entries(.value |= strip) | with_entries(select(.value | length > 0)))
            | reduce (($src.hooks // {}) | to_entries[]) as $e (.; .[$e.key] = ((.[$e.key] // []) | merge($e.value))))
JQ
  local ss="$src/.claude/settings.json" ds="$tgt/.claude/settings.json" merged
  if [ ! -e "$ds" ]; then say BARU ".claude/settings.json"; n_new=$((n_new+1)); put "$ss" "$ds"
  elif ! jq empty "$ds" >/dev/null 2>&1; then say LEWATI ".claude/settings.json (JSON tidak valid; perbaiki lalu ulangi)"
  else
    merged=$(jq --slurpfile s "$ss" -f "$tmp/merge.jq" "$ds") || die "gagal menggabungkan settings.json"
    if [ "$(printf '%s' "$merged" | jq -S -c .)" = "$(jq -S -c . "$ds")" ]; then n_same=$((n_same+1))
    else say GABUNG ".claude/settings.json (izin dan hook devcore; pengaturan proyek dipertahankan)"; n_upd=$((n_upd+1))
      [ "$apply" -eq 1 ] && printf '%s\n' "$merged" > "$ds"; fi
  fi

  # ---------- CLAUDE.md: hanya baris impor ----------
  local imp='@.devcore/rules.md'
  if [ ! -e "$tgt/CLAUDE.md" ]; then
    say BARU "CLAUDE.md (starter + impor aturan devcore)"; n_new=$((n_new+1))
    if [ "$apply" -eq 1 ]; then
      # AGENTS.md tidak lagi dibaca otomatis begitu CLAUDE.md ada; impor agar tidak hilang
      if [ -f "$tgt/AGENTS.md" ]; then awk -v imp="$imp" '$0==imp{print "@AGENTS.md"; print ""} {print}' "$src/.devcore/docs/templates/claude-md-starter.md" > "$tgt/CLAUDE.md"
      else cp "$src/.devcore/docs/templates/claude-md-starter.md" "$tgt/CLAUDE.md"; fi
    fi
  elif ! grep -qxF "$imp" "$tgt/CLAUDE.md"; then
    say TAMBAH "CLAUDE.md: baris impor $imp"; n_upd=$((n_upd+1))
    [ "$apply" -eq 1 ] && printf '\n%s\n' "$imp" >> "$tgt/CLAUDE.md"
  else n_same=$((n_same+1)); fi

  # ---------- .gitignore dan seed (disalin sekali, sesudahnya milik proyek) ----------
  local missing="" l
  for l in "CLAUDE.local.md" ".claude/settings.local.json"; do
    { [ -e "$tgt/.gitignore" ] && grep -qxF "$l" "$tgt/.gitignore"; } || missing="$missing $l"
  done
  if [ -n "$missing" ]; then
    say TAMBAH ".gitignore:$missing"; n_upd=$((n_upd+1))
    if [ "$apply" -eq 1 ]; then
      [ -s "$tgt/.gitignore" ] && [ -n "$(tail -c1 "$tgt/.gitignore")" ] && echo >> "$tgt/.gitignore"
      { echo "# devcore (lokal per proyek)"; for l in $missing; do echo "$l"; done; } >> "$tgt/.gitignore"
    fi
  fi
  seed() { # sumber-relatif tujuan-relatif
    if [ ! -e "$tgt/$2" ]; then say BARU "$2 (seed: milik proyek sesudah ini)"; n_new=$((n_new+1)); put "$src/$1" "$tgt/$2"; fi
  }
  seed .claude/devcore.conf .claude/devcore.conf
  seed .github/workflows/devcore-checks.yml .github/workflows/devcore-checks.yml
  seed .devcore/docs/templates/status.md docs/status.md
  seed .devcore/docs/templates/project-profile.md docs/project-profile.md

  # ---------- laporan pra-pasang: hal yang perlu diperhatikan di proyek existing ----------
  echo
  local lines=0
  [ -f "$tgt/CLAUDE.md" ] && lines=$(wc -l < "$tgt/CLAUDE.md" | tr -d ' ')
  [ "$n_conf" -gt 0 ] && echo "INFO: $n_conf berkas .claude/ bentrok dengan milik proyek dan dilewati; ubah namanya bila ingin memakai versi devcore."
  [ "$lines" -gt 150 ] && echo "INFO: CLAUDE.md proyek sudah $lines baris; aturan devcore menambah ±70 baris konteks (anjuran maksimal 200)."
  [ -f "$tgt/AGENTS.md" ] && [ -e "$tgt/CLAUDE.md" ] && ! grep -qE '^@AGENTS\.md' "$tgt/CLAUDE.md" && echo "INFO: AGENTS.md ada tetapi tidak diimpor CLAUDE.md; tidak diubah."
  if [ -d "$tgt/.github/workflows" ]; then
    local nwf; nwf=$(ls "$tgt/.github/workflows" 2>/dev/null | grep -vc '^devcore-checks\.yml$')
    [ "$nwf" -gt 0 ] && echo "INFO: ada $nwf workflow CI lain; devcore-checks.yml berjalan terpisah dan hanya memeriksa kerangka, tambahkan test proyek Anda di workflow yang ada."
  fi
  if [ -e "$ds" ] && jq empty "$ds" >/dev/null 2>&1; then
    local ph; ph=$(jq '[.hooks // {} | .[][]?.hooks[]? | select(((.command // "") | startswith("$CLAUDE_PROJECT_DIR/.devcore/")) | not)] | length' "$ds")
    [ "${ph:-0}" -gt 0 ] && echo "INFO: settings.json punya $ph hook milik proyek; dipertahankan dan berjalan berdampingan dengan hook devcore."
  fi
  echo "Ringkasan: baru=$n_new perbarui=$n_upd sama=$n_same bentrok=$n_conf"
  if [ "$apply" -eq 1 ]; then echo "Perubahan BELUM di-commit. Tinjau dengan git status / git diff, jalankan .devcore/scripts/run-checks.sh, lalu commit."
  else echo "Dry-run: tidak ada yang ditulis. Tambahkan --apply untuk menerapkan."; fi
  return 0
}

main "$@"
exit $?
