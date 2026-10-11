#!/usr/bin/env bash
# Bukti penutupan brief (AG-19, DC-06): brief yang BARU berubah menjadi "Status: done" pada diff terhadap base
# harus memuat bagian "Tinjauan independen" (baris Verdict:) dan "Bagian standar yang diperiksa".
# Bila brief memuat "Standar yang berlaku", tiap ID di sana harus muncul di "Bagian standar yang diperiksa" (keterlacakan).
# Brief lama yang sudah done tidak diperiksa (AG-16). Tanpa base-ref: DILEWATI.
# Batas: pemeriksa ini memeriksa BUKTI tertulis, bukan memastikan tinjauan benar-benar dipanggil atau berkualitas.
# Pakai: .devcore/scripts/check-brief-closure.sh <base-ref>
set -u
base=${1:-}
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root" || exit 2

if [ -z "$base" ] || ! git rev-parse --verify -q "${base}^{commit}" >/dev/null 2>&1; then
  echo "DILEWATI: base-ref tidak valid atau kosong ('${base}'); bukti penutupan brief tidak diperiksa."
  exit 0
fi

status_of() { # isi brief di stdin -> status huruf kecil
  awk 'tolower($0) ~ /^status:[ \t]*/ { sub(/^[^:]*:[ \t]*/, ""); gsub(/[ \t\r]+$/, ""); print tolower($0); exit }'
}

# Bagian terisi = ada baris selain kosong / placeholder <...>
section_filled() { # berkas heading
  awk -v h="$2" '
    /^## / { insec = (index($0, "## " h) == 1); next }
    insec && $0 !~ /^[[:space:]]*$/ \
          && $0 !~ /^[[:space:]]*([-*][[:space:]]+)?(\[[ xX]\][[:space:]]+)?<[^>]*>[[:space:]]*$/ { found = 1 }
    END { exit !found }' "$1"
}
section_text() { # berkas heading
  awk -v h="$2" '/^## / { insec = (index($0, "## " h) == 1); next } insec { print }' "$1"
}

# Perubahan kode pada diff (repo devcore sendiri menghitung .devcore/ dan scripts/ sebagai kode)
if [ -f scripts/test-sync.sh ]; then excl='^(docs/|\.claude/|\.github/)|\.md$|\.gitignore$'
else excl='^(docs/|\.claude/|\.devcore/|\.github/)|\.md$|\.gitignore$'; fi
code_changed=$(git diff --name-only "${base}...HEAD" 2>/dev/null | grep -vE "$excl" | wc -l | tr -d ' ')

fail=0; checked=0
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
while IFS= read -r f; do
  [ -n "$f" ] || continue
  git show "HEAD:$f" > "$tmp" 2>/dev/null || continue
  [ "$(status_of < "$tmp")" = "done" ] || continue
  bs=$(git show "${base}:$f" 2>/dev/null | status_of)
  [ "$bs" = "done" ] && continue            # sudah done sejak sebelum diff: bukan penutupan baru
  checked=$((checked+1))
  problems=""
  if ! section_filled "$tmp" "Tinjauan independen"; then
    problems="$problems bagian 'Tinjauan independen' kosong;"
  else
    v=$(section_text "$tmp" "Tinjauan independen" | grep -iE 'Verdict:' | head -1)
    case "$(printf '%s' "$v" | tr 'a-z' 'A-Z')" in
      *"TIDAK DIPERLUKAN"*)
        [ "$code_changed" -gt 0 ] && problems="$problems 'TIDAK DIPERLUKAN' tidak sah karena diff mengubah $code_changed berkas kode;"
        printf '%s' "$v" | grep -qiE 'TIDAK DIPERLUKAN[[:space:]]*[:-][[:space:]]*.{10,}' || problems="$problems 'TIDAK DIPERLUKAN' butuh alasan (min. 10 karakter);" ;;
      *"PERLU PERBAIKAN"*|*"TIDAK DAPAT DINILAI"*|*"LAYAK"*) ;;
      *) problems="$problems tidak ada baris 'Verdict: LAYAK | PERLU PERBAIKAN | TIDAK DAPAT DINILAI';" ;;
    esac
  fi
  # Keterlacakan: tiap ID di "Standar yang berlaku" (dijanjikan saat brief disetujui) harus muncul di "Bagian standar yang diperiksa".
  # Brief lama tanpa bagian "Standar yang berlaku" tidak dikenai syarat ini; bila bagian ada dan ada perubahan kode, ia wajib terisi.
  if grep -q '^## Standar yang berlaku' "$tmp"; then
    if section_filled "$tmp" "Standar yang berlaku"; then
      checked_text=$(section_text "$tmp" "Bagian standar yang diperiksa")
      for id in $(section_text "$tmp" "Standar yang berlaku" | grep -oE '\b[A-Z]{2,3}-[0-9]{2}\b' | sort -u); do
        printf '%s' "$checked_text" | grep -qE "\b$id\b" || problems="$problems ID $id dijanjikan di 'Standar yang berlaku' tetapi tidak ada hasilnya di 'Bagian standar yang diperiksa';"
      done
    elif [ "$code_changed" -gt 0 ]; then
      problems="$problems bagian 'Standar yang berlaku' kosong padahal diff mengubah kode;"
    fi
  fi
  if ! section_filled "$tmp" "Bagian standar yang diperiksa"; then
    problems="$problems bagian 'Bagian standar yang diperiksa' kosong;"
  elif [ "$code_changed" -gt 0 ] && ! section_text "$tmp" "Bagian standar yang diperiksa" | grep -qE '\b[A-Z]{2,3}-[0-9]{2}\b'; then
    problems="$problems 'Bagian standar yang diperiksa' tidak menyebut satu pun ID aturan (mis. SC-07);"
  fi
  if [ -n "$problems" ]; then
    echo "PENUTUPAN BRIEF: $f ditutup (done) tanpa bukti lengkap:$problems"
    fail=1
  fi
done < <(git diff --name-only --diff-filter=AMR "${base}...HEAD" -- 'docs/briefs/*.md' 2>/dev/null)

if [ "$fail" -eq 0 ]; then echo "Penutupan brief: OK ($checked brief baru ditutup diperiksa)"; fi
exit "$fail"
