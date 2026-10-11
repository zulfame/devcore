#!/usr/bin/env bash
# Deteksi pelemahan pemeriksaan pada diff (AG-09, CI-07):
#   - test dilewati/difokuskan: .skip( .only( xit( xdescribe( @Ignore @Disabled pytest.mark.skip t.Skip(
#   - pemeriksaan dimatikan: eslint-disable @ts-ignore @ts-nocheck "type: ignore" noqa "pylint: disable" nosec nolint
#   - "any" baru pada file TypeScript
#   - continue-on-error: true pada workflow
# Baris yang sengaja dikecualikan harus memuat:  devcore-allow: <alasan>
# Folder docs/, .claude/, scripts/ dan berkas *.md tidak dipindai. Test yang dihapus hanya diberi PERINGATAN.
# Pakai: scripts/check-weakened-tests.sh <base-ref>
set -u
base=${1:-}
if [ -z "$base" ] || ! git rev-parse --verify -q "${base}^{commit}" >/dev/null 2>&1; then
  echo "DILEWATI: base-ref tidak valid atau kosong ('${base}'); tidak ada yang dibandingkan."
  exit 0
fi

common='\.(skip|only)\(|(^|[^A-Za-z0-9_])(xit|xdescribe|xtest)\(|@(Ignore|Disabled)([^A-Za-z]|$)|pytest\.(mark\.(skip|xfail)|skip\()|unittest\.skip|t\.(Skip|SkipNow)\(|eslint-disable|@ts-ignore|@ts-nocheck|#[[:space:]]*type:[[:space:]]*ignore|#[[:space:]]*noqa|#[[:space:]]*pylint:[[:space:]]*disable|#[[:space:]]*nosec|//[[:space:]]*nolint|continue-on-error:[[:space:]]*true'
tsany='(:[[:space:]]*|as[[:space:]]+|<)any([^A-Za-z0-9_]|$)'

raw=$(mktemp); added=$(mktemp); err=$(mktemp)
trap 'rm -f "$raw" "$added" "$err"' EXIT

if ! git diff --unified=0 --no-color "${base}...HEAD" -- . ':(exclude)docs' ':(exclude).claude' ':(exclude)scripts' ':(exclude)*.md' >"$raw" 2>"$err"; then
  echo "GAGAL membandingkan dengan '${base}': $(cat "$err")"
  exit 2
fi

awk '/^\+\+\+ /{ if ($2 == "/dev/null") f = ""; else f = substr($2, 3); next }
     /^\+/ { if (f != "") print f "\t" substr($0, 2) }' "$raw" >"$added"

fail=0
while IFS=$'\t' read -r f line; do
  case "$line" in *devcore-allow:*) continue ;; esac
  hit=0
  printf '%s' "$line" | grep -Eq "$common" && hit=1
  case "$f" in
    *.ts|*.tsx) printf '%s' "$line" | grep -Eq "$tsany" && hit=1 ;;
  esac
  if [ "$hit" -eq 1 ]; then
    echo "PELEMAHAN: $f: $(printf '%s' "$line" | cut -c1-140)"
    fail=1
  fi
done <"$added"

git diff --name-only --diff-filter=D "${base}...HEAD" 2>/dev/null \
  | grep -Ei '(^|/)(tests?|__tests__|spec)(/|$)|[._-](test|spec)\.[a-z]+$' \
  | while IFS= read -r d; do echo "PERINGATAN: berkas test dihapus: $d (pastikan fiturnya memang dihapus)"; done

if [ "$fail" -eq 1 ]; then
  echo
  echo "Perbaiki penyebabnya (AG-09). Jika pengecualian benar-benar perlu, tambahkan 'devcore-allow: <alasan>' pada baris tersebut."
  exit 1
fi
echo "Pelemahan pemeriksaan: tidak ditemukan"
exit 0
