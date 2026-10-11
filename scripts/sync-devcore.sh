#!/usr/bin/env bash
# sync-devcore.sh — pasang atau perbarui kerangka devcore pada sebuah proyek.
#
# Sifat pengaman:
#   - dry-run adalah bawaan; tambahkan --apply untuk benar-benar menulis
#   - target harus akar repo git dan working tree-nya bersih (agar perubahan bisa ditinjau/dibuang dengan git)
#   - tidak pernah commit; tidak menghapus berkas milik proyek
#   - berkas kerangka yang sudah diubah lokal dilewati kecuali --overwrite-modified
#
# Pakai:
#   scripts/sync-devcore.sh --target <proyek> [--apply]                 (dijalankan dari klon devcore)
#   scripts/sync-devcore.sh --source <dir|url> [--ref <ref>] [--apply]  (dijalankan di dalam proyek)
# Opsi: --source, --target, --ref, --apply, --overwrite-modified, -h
set -u

usage() {
  sed -n '2,/^set -u/p' "$0" | sed -e '$d' -e 's/^# \{0,1\}//'
}
die() { echo "GALAT: $*" >&2; exit 2; }
say() { printf '%-9s %s\n' "$1" "$2"; }

script_root=$(cd "$(dirname "$0")/.." && pwd -P)
source_arg=""; target_arg=""; ref=""; apply=0; overwrite_modified=0
while [ $# -gt 0 ]; do
  case "$1" in
    --source) [ $# -ge 2 ] || die "--source butuh nilai"; source_arg=$2; shift 2 ;;
    --target) [ $# -ge 2 ] || die "--target butuh nilai"; target_arg=$2; shift 2 ;;
    --ref)    [ $# -ge 2 ] || die "--ref butuh nilai"; ref=$2; shift 2 ;;
    --apply) apply=1; shift ;;
    --overwrite-modified) overwrite_modified=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argumen tidak dikenal: $1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v jq  >/dev/null 2>&1 || die "jq diperlukan (brew install jq / apt install jq)"
command -v git >/dev/null 2>&1 || die "git diperlukan"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

hash_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

# ---------- sumber ----------
src_label=local
case "$source_arg" in
  "") src=$script_root ;;
  http://*|https://*|git@*|ssh://*|*.git)
    src="$tmp/src"; src_label=$source_arg
    clone_args=(--quiet --depth 1)
    [ -n "$ref" ] && clone_args+=(--branch "$ref")
    git clone "${clone_args[@]}" "$source_arg" "$src" 2>"$tmp/clone.err" || die "gagal clone $source_arg: $(cat "$tmp/clone.err")" ;;
  *) src=$(cd "$source_arg" 2>/dev/null && pwd -P) || die "sumber tidak ditemukan: $source_arg" ;;
esac
{ [ -f "$src/.claude/devcore.manifest" ] && [ -f "$src/VERSION" ]; } \
  || die "sumber bukan repo devcore (tidak ada .claude/devcore.manifest dan VERSION). Gunakan --source <dir|url>."
ver=$(tr -d '[:space:]' < "$src/VERSION")
commit=$(git -C "$src" rev-parse --short HEAD 2>/dev/null || echo unknown)

# ---------- target ----------
if [ -n "$target_arg" ]; then
  tgt=$(cd "$target_arg" 2>/dev/null && pwd -P) || die "target tidak ditemukan: $target_arg"
else
  tgt=$(git rev-parse --show-toplevel 2>/dev/null) || die "bukan repo git; gunakan --target <proyek>"
  tgt=$(cd "$tgt" && pwd -P)
fi
top=$(git -C "$tgt" rev-parse --show-toplevel 2>/dev/null) || die "target bukan repositori git: $tgt"
top=$(cd "$top" && pwd -P)
[ "$top" = "$tgt" ] || die "target harus akar repositori git ($top), bukan subfolder"
[ "$src" != "$tgt" ] || die "sumber dan target sama; jalankan dari klon devcore dengan --target <proyek>"

if [ -n "$(git -C "$tgt" status --porcelain --untracked-files=no)" ]; then
  [ "$apply" -eq 1 ] && die "working tree target tidak bersih; commit atau stash dulu agar perubahan devcore mudah ditinjau"
  echo "CATATAN: working tree target tidak bersih; --apply akan menolak."
fi

lockf="$tgt/.claude/devcore.lock"
old_ver=belum
[ -f "$lockf" ] && old_ver=$(grep '^version=' "$lockf" | head -1 | cut -d= -f2)
lock_hash() { [ -f "$lockf" ] && awk -v p="$1" '$1=="file" && $3==p {print $2; exit}' "$lockf"; }

mode=dry-run; [ "$apply" -eq 1 ] && mode=apply
echo "devcore sync [$mode]"
echo "  sumber : v$ver ($commit) $src_label"
echo "  target : $tgt (terpasang sebelumnya: $old_ver)"
echo

# ---------- manifest ----------
entries="$tmp/entries"; : > "$entries"
while IFS= read -r line; do
  case "$line" in ""|"#"*) continue ;; esac
  set -f; set -- $line; set +f
  type=$1; t=${2:-}; s=${3:-${2:-}}
  case "$type" in managed|seed) ;; *) die "manifest: jenis tidak dikenal '$type'" ;; esac
  case "$t$s" in /*|*..*|"") die "manifest: jalur tidak aman '$t'" ;; esac
  [ -f "$src/$s" ] || die "manifest menyebut berkas yang tidak ada di sumber: $s"
  echo "$type|$t|$s" >> "$entries"
done < "$src/.claude/devcore.manifest"

put() { # sumber tujuan
  [ "$apply" -eq 1 ] || return 0
  mkdir -p "$(dirname "$2")"
  # tulis ke berkas sementara lalu mv: aman bila yang diganti adalah skrip ini sendiri (inode baru)
  cp "$1" "$2.devcore-new"
  [ -x "$1" ] && chmod +x "$2.devcore-new"
  mv -f "$2.devcore-new" "$2"
  return 0
}

n_new=0; n_upd=0; n_same=0; n_skip=0; n_seed=0; n_del=0; n_other=0
newlock="$tmp/newlock"; : > "$newlock"
managed_set="$tmp/managed"; : > "$managed_set"

# ---------- berkas kerangka ----------
while IFS='|' read -r type t s; do
  if [ "$type" = managed ]; then
    echo "$t" >> "$managed_set"
    sh=$(hash_of "$src/$s")
    if [ ! -e "$tgt/$t" ]; then
      say BARU "$t"; n_new=$((n_new+1)); put "$src/$s" "$tgt/$t"; echo "file $sh $t" >> "$newlock"
    else
      ch=$(hash_of "$tgt/$t"); lh=$(lock_hash "$t")
      if [ "$ch" = "$sh" ]; then
        n_same=$((n_same+1)); echo "file $sh $t" >> "$newlock"
      elif [ -n "$lh" ] && [ "$ch" = "$lh" ]; then
        say PERBARUI "$t"; n_upd=$((n_upd+1)); put "$src/$s" "$tgt/$t"; echo "file $sh $t" >> "$newlock"
      elif [ "$overwrite_modified" -eq 1 ]; then
        say TIMPA "$t (diubah lokal)"; n_upd=$((n_upd+1)); put "$src/$s" "$tgt/$t"; echo "file $sh $t" >> "$newlock"
      else
        say LEWATI "$t (diubah lokal; pakai --overwrite-modified untuk menimpa)"; n_skip=$((n_skip+1))
        [ -n "$lh" ] && echo "file $lh $t" >> "$newlock"
      fi
    fi
  else
    if [ ! -e "$tgt/$t" ]; then
      say BARU "$t (seed: milik proyek sesudah ini)"; n_new=$((n_new+1)); put "$src/$s" "$tgt/$t"
    else
      n_seed=$((n_seed+1))
    fi
  fi
done < "$entries"

# ---------- berkas kerangka yang sudah tidak ada di sumber ----------
removed_hooks="$tmp/removed_hooks"; : > "$removed_hooks"
if [ -f "$lockf" ]; then
  while read -r lh p; do
    grep -qxF "$p" "$managed_set" && continue
    case "$p" in .claude/hooks/*) basename "$p" >> "$removed_hooks" ;; esac
    [ -e "$tgt/$p" ] || continue
    if [ "$(hash_of "$tgt/$p")" = "$lh" ]; then
      say HAPUS "$p (tidak ada lagi di kerangka)"; n_del=$((n_del+1))
      if [ "$apply" -eq 1 ]; then
        rm "$tgt/$p"
        d=$(dirname "$p")
        while [ "$d" != "." ] && rmdir "$tgt/$d" 2>/dev/null; do d=$(dirname "$d"); done
      fi
    else
      say LEWATI "$p (usang di kerangka tetapi diubah lokal; hapus manual bila tak dipakai)"; n_skip=$((n_skip+1))
    fi
  done < <(awk '$1=="file"{print $2" "$3}' "$lockf")
fi

# ---------- .claude/settings.json (digabung) ----------
cat > "$tmp/merge.jq" <<'JQ'
def dedupe: reduce .[] as $x ([]; if index([$x]) == null then . + [$x] else . end);
# perintah milik kerangka dipindahkan dari grup bermatcher lama (matcher berubah antar versi) agar tidak terpasang dua kali
def prune_other_matchers($sg):
  reduce $sg[] as $g (.;
    ($g.matcher // "") as $m
    | ([$g.hooks[]?.command]) as $cmds
    | map(if ((.matcher // "") != $m)
          then .hooks |= map(select((.command as $c | $cmds | index([$c])) == null))
          else . end))
  | map(select(((.hooks // []) | length) > 0));
def mergegroups($sg):
  prune_other_matchers($sg)
  | reduce $sg[] as $g (.;
    (map(.matcher // "") | index([$g.matcher // ""])) as $i
    | if $i == null then . + [$g]
      else (.[$i].hooks | map(.command)) as $have
        | .[$i].hooks += [ $g.hooks[] | select((.command as $c | $have | index([$c])) == null) ]
      end);
$s[0] as $src
| .permissions.deny = ((((.permissions.deny // []) + ($src.permissions.deny // []))) | dedupe)
| .permissions.ask  = ((((.permissions.ask  // []) + ($src.permissions.ask  // []))) | dedupe)
| .hooks = (reduce (($src.hooks // {}) | to_entries[]) as $e (.hooks // {};
      .[$e.key] = ((.[$e.key] // []) | mergegroups($e.value))))
| if ($removed | length) > 0 then
    .hooks |= with_entries(.value |= (
      map(.hooks |= map(select((((.command // "") | split("/") | last) as $b | ($removed | index([$b])) == null))))
      | map(select((.hooks | length) > 0))))
  else . end
JQ
src_settings="$src/.claude/settings.json"; dst_settings="$tgt/.claude/settings.json"
if [ -f "$src_settings" ]; then
  if [ ! -e "$dst_settings" ]; then
    say BARU ".claude/settings.json (dari kerangka)"; n_new=$((n_new+1)); put "$src_settings" "$dst_settings"
  elif ! jq empty "$dst_settings" >/dev/null 2>&1; then
    say LEWATI ".claude/settings.json (JSON tidak valid; perbaiki lalu ulangi)"; n_skip=$((n_skip+1))
  else
    removed_json=$(jq -R -s 'split("\n") | map(select(length > 0))' "$removed_hooks")
    merged=$(jq --slurpfile s "$src_settings" --argjson removed "$removed_json" -f "$tmp/merge.jq" "$dst_settings") \
      || die "gagal menggabungkan .claude/settings.json"
    if [ "$(printf '%s' "$merged" | jq -S -c .)" = "$(jq -S -c . "$dst_settings")" ]; then
      n_same=$((n_same+1))
    else
      say GABUNG ".claude/settings.json (izin dan hook kerangka ditambahkan; pengaturan proyek dipertahankan)"; n_other=$((n_other+1))
      [ "$apply" -eq 1 ] && printf '%s\n' "$merged" > "$dst_settings"
    fi
  fi
fi

# ---------- CLAUDE.md (hanya baris impor) ----------
imp='@.claude/devcore-rules.md'
claude_md="$tgt/CLAUDE.md"
if [ ! -e "$claude_md" ]; then
  say BARU "CLAUDE.md (berisi impor aturan devcore)"; n_new=$((n_new+1))
  if [ "$apply" -eq 1 ]; then
    { echo "# CLAUDE.md"; echo
      # AGENTS.md tidak lagi dibaca otomatis begitu CLAUDE.md ada, jadi diimpor agar tidak hilang
      [ -f "$tgt/AGENTS.md" ] && { echo "@AGENTS.md"; echo; }
      echo "$imp"; } > "$claude_md"
  fi
elif ! grep -qxF "$imp" "$claude_md"; then
  say TAMBAH "CLAUDE.md: baris impor $imp"; n_other=$((n_other+1))
  [ "$apply" -eq 1 ] && printf '\n%s\n' "$imp" >> "$claude_md"
  if [ -f "$tgt/AGENTS.md" ] && ! grep -qE '^@AGENTS\.md[[:space:]]*$' "$claude_md"; then
    echo "          catatan: AGENTS.md ada tetapi tidak diimpor CLAUDE.md Anda; tidak diubah."
  fi
fi

# ---------- .gitignore ----------
missing=""
for l in "CLAUDE.local.md" ".claude/settings.local.json"; do
  if [ ! -e "$tgt/.gitignore" ] || ! grep -qxF "$l" "$tgt/.gitignore"; then missing="$missing $l"; fi
done
if [ -n "$missing" ]; then
  say TAMBAH ".gitignore:$missing"; n_other=$((n_other+1))
  if [ "$apply" -eq 1 ]; then
    [ -s "$tgt/.gitignore" ] && [ -n "$(tail -c1 "$tgt/.gitignore")" ] && echo >> "$tgt/.gitignore"
    { echo "# devcore (lokal per proyek)"; for l in $missing; do echo "$l"; done; } >> "$tgt/.gitignore"
  fi
fi

# ---------- berkas kunci (versi terpasang) ----------
lock_src=local; case "$src_label" in local) ;; *) lock_src=$src_label ;; esac
body="$tmp/lockbody"
{ echo "# Dikelola oleh scripts/sync-devcore.sh — jangan diedit manual"
  echo "version=$ver"; echo "source=$lock_src"; echo "commit=$commit"
  sort -k3 "$newlock"; } > "$body"
if [ ! -f "$lockf" ] || ! diff -q "$body" <(grep -v '^synced=' "$lockf") >/dev/null 2>&1; then
  say KUNCI ".claude/devcore.lock (v$ver)"; n_other=$((n_other+1))
  if [ "$apply" -eq 1 ]; then
    mkdir -p "$tgt/.claude"
    { cat "$body"; echo "synced=$(date +%F)"; } > "$lockf"
  fi
fi

echo
echo "Ringkasan: baru=$n_new perbarui/gabung/lain=$((n_upd+n_other)) hapus=$n_del sama=$n_same dilewati=$n_skip milik-proyek=$n_seed"
if [ "$apply" -eq 1 ]; then
  echo "Perubahan BELUM di-commit. Tinjau dengan git status / git diff, jalankan scripts/run-checks.sh, lalu commit bila sesuai."
  echo "Proyek baru? Jalankan skill profile-project, dan pertimbangkan BRIEF_GATE=ask di .claude/devcore.conf untuk minggu awal."
else
  echo "Dry-run: tidak ada yang ditulis. Tambahkan --apply untuk menerapkan."
fi
exit 0
