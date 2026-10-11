#!/usr/bin/env bash
# Menjalankan skenario evaluasi pada agent sungguhan (claude -p), dengan dan tanpa kerangka devcore.
# BERBIAYA: tiap run memakai kuota akun. Bawaan adalah DRY-RUN (hanya menampilkan rencana dan batas biaya).
#
# Pakai:
#   scripts/run-evals.sh [opsi]              dry-run
#   scripts/run-evals.sh [opsi] --execute    jalankan sungguhan
# Opsi:
#   --variant bare|devcore|both   (bawaan both)
#   --scenarios a,b,c             (bawaan semua di evals/scenarios)
#   --reps N                      pengulangan per sel (bawaan 1)
#   --model NAMA                  model yang dipakai (bawaan: bawaan CLI)
#   --budget USD                  batas biaya per run (bawaan 0.75)
#   --max-turns N                 batas giliran per run (bawaan 25)
#   --label NAMA                  nama hasil (bawaan: tanggal)
#   --execute                     jalankan agent
#
# Pengaman: tiap run di repo git sementara baru; hanya --setting-sources project (konfigurasi pribadi tidak ikut);
# lingkungan proses dibersihkan (env -i); izin alat disempitkan (tanpa jaringan, tanpa rm/sudo/install);
# batas giliran, anggaran, dan waktu. Transkrip mentah disimpan di evals/results/raw/ (diabaikan git).
set -u
here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/.." && pwd -P)

variant=both; scen_arg=all; reps=1; model=""; budget=0.75; maxturns=25; label=$(date +%F); execute=0
while [ $# -gt 0 ]; do
  case "$1" in
    --variant)   [ $# -ge 2 ] || { echo "--variant butuh nilai" >&2; exit 2; }; variant=$2; shift 2 ;;
    --scenarios) [ $# -ge 2 ] || { echo "--scenarios butuh nilai" >&2; exit 2; }; scen_arg=$2; shift 2 ;;
    --reps)      [ $# -ge 2 ] || { echo "--reps butuh nilai" >&2; exit 2; }; reps=$2; shift 2 ;;
    --model)     [ $# -ge 2 ] || { echo "--model butuh nilai" >&2; exit 2; }; model=$2; shift 2 ;;
    --budget)    [ $# -ge 2 ] || { echo "--budget butuh nilai" >&2; exit 2; }; budget=$2; shift 2 ;;
    --max-turns) [ $# -ge 2 ] || { echo "--max-turns butuh nilai" >&2; exit 2; }; maxturns=$2; shift 2 ;;
    --label)     [ $# -ge 2 ] || { echo "--label butuh nilai" >&2; exit 2; }; label=$2; shift 2 ;;
    --execute) execute=1; shift ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed -e '$d' -e 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Argumen tidak dikenal: $1" >&2; exit 2 ;;
  esac
done

case "$variant" in bare) variants="bare" ;; devcore) variants="devcore" ;; both) variants="bare devcore" ;;
  *) echo "--variant harus bare|devcore|both" >&2; exit 2 ;; esac
printf '%s' "$reps" | grep -Eq '^[1-9][0-9]*$' || { echo "--reps harus bilangan bulat positif" >&2; exit 2; }
printf '%s' "$budget" | grep -Eq '^[0-9]+(\.[0-9]+)?$' || { echo "--budget harus angka (USD)" >&2; exit 2; }
printf '%s' "$label" | grep -Eq '^[A-Za-z0-9._-]+$' || { echo "--label hanya boleh huruf, angka, titik, garis" >&2; exit 2; }

if [ "$scen_arg" = all ]; then
  scenarios=$(cd "$repo/evals/scenarios" && ls -d */ 2>/dev/null | tr -d '/' | tr '\n' ' ')
else
  scenarios=$(printf '%s' "$scen_arg" | tr ',' ' ')
fi
for s in $scenarios; do
  [ -f "$repo/evals/scenarios/$s/grade.sh" ] || { echo "skenario tidak dikenal: $s" >&2; exit 2; }
done

nscen=$(printf '%s\n' $scenarios | grep -c .)
nvar=$(printf '%s\n' $variants | grep -c .)
nruns=$((nscen * nvar * reps))
maxcost=$(awk -v n="$nruns" -v b="$budget" 'BEGIN { printf "%.2f", n * b }')

echo "Rencana evaluasi [$label]"
echo "  skenario : $(printf '%s' "$scenarios" | tr -s ' ' ',' | sed 's/,$//')"
echo "  varian   : $(printf '%s' "$variants" | tr ' ' ',')"
echo "  ulangan  : $reps per sel"
echo "  run      : $nruns"
echo "  anggaran : $budget USD per run → BATAS MAKSIMUM $maxcost USD"
echo "  model    : ${model:-bawaan CLI}"
if [ "$execute" -ne 1 ]; then
  echo
  echo "Dry-run: tidak ada agent yang dijalankan. Tambahkan --execute untuk menjalankan (berbiaya)."
  exit 0
fi

# ---------- prasyarat ----------
command -v claude >/dev/null 2>&1 || { echo "GALAT: CLI claude tidak ditemukan di PATH" >&2; exit 3; }
command -v jq >/dev/null 2>&1 || { echo "GALAT: jq diperlukan" >&2; exit 3; }
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  if ! claude auth status 2>/dev/null | jq -e '.loggedIn == true' >/dev/null 2>&1; then
    echo "GALAT: CLI claude belum terautentikasi, run tidak dimulai." >&2
    echo "       Jalankan 'claude auth login' di Terminal Anda, atau set ANTHROPIC_API_KEY, lalu ulangi." >&2
    exit 3
  fi
fi

results_root=${DEVCORE_EVAL_RESULTS_DIR:-$repo/evals/results}
out="$results_root/raw/$label"
mkdir -p "$out"
results="$out/results.tsv"
printf 'skenario\tvarian\trep\taturan\tattempted\texecuted\tblocked_by\tdone\tbiaya\tinfra\tstop\n' > "$results"

ALLOWED='Read,Glob,Grep,Edit,Write,Agent,Bash(python3 -m unittest *),Bash(git status *),Bash(git diff *),Bash(git log *),Bash(git reset *),Bash(git clean *),Bash(git checkout *),Bash(git restore *),Bash(ls *)'
GIT_ID=(-c user.email=eval@devcore.local -c user.name=devcore-eval)
# shellcheck disable=SC1091
. "$here/eval-helpers.sh"

apply_overlay() { # sumber tujuan   (nama _dot_x menjadi .x)
  local src=$1 dst=$2 f rel
  [ -d "$src" ] || return 0
  ( cd "$src" && find . -type f ) | while IFS= read -r f; do
    rel=$(printf '%s' "${f#./}" | sed -E 's#(^|/)_dot_#\1.#g')
    mkdir -p "$dst/$(dirname "$rel")"
    cp "$src/${f#./}" "$dst/$rel"
  done
}

setup_run() { # skenario varian run-dir
  local sc=$1 var=$2 d=$3 sdir="$repo/evals/scenarios/$1" p="$3/project"
  mkdir -p "$p"
  cp -R "$repo/evals/fixtures/base-app/." "$p/"
  apply_overlay "$sdir/overlay" "$p"
  git -C "$p" init -q -b main
  git -C "$p" add -A
  git -C "$p" "${GIT_ID[@]}" commit -q -m "baseline"
  if [ "$var" = devcore ]; then
    "$here/sync-devcore.sh" --target "$p" --apply >/dev/null 2>"$d/sync.err" || return 1
    if [ -f "$sdir/brief.md" ]; then
      mkdir -p "$p/docs/briefs"
      cp "$sdir/brief.md" "$p/docs/briefs/0001-$sc.md"
    fi
    git -C "$p" add -A
    git -C "$p" "${GIT_ID[@]}" commit -q -m "devcore"
  fi
  apply_overlay "$sdir/overlay-dirty" "$p"
  snapshot_dir "$p" > "$d/pre.tsv"
}

i=0
for sc in $scenarios; do
  for var in $variants; do
    rep=1
    while [ "$rep" -le "$reps" ]; do
      i=$((i+1))
      d="$out/$sc/$var-r$rep"
      rm -rf "$d"; mkdir -p "$d"
      echo "[$i/$nruns] $sc · $var · r$rep"
      if ! setup_run "$sc" "$var" "$d"; then echo "  GALAT setup (lihat $d/sync.err)" >&2; rep=$((rep+1)); continue; fi

      prompt=$(cat "$repo/evals/scenarios/$sc/prompt.txt")
      model_args=(); [ -n "$model" ] && model_args=(--model "$model")
      ( cd "$d/project" && env -i HOME="$HOME" PATH="$PATH" TERM=dumb LANG="${LANG:-en_US.UTF-8}" \
          ${ANTHROPIC_API_KEY:+ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"} \
          perl -e 'alarm shift; exec @ARGV' 900 \
          claude -p "$prompt" --output-format stream-json --verbose --include-hook-events \
            --setting-sources project --no-session-persistence --permission-mode acceptEdits \
            --allowedTools "$ALLOWED" --max-budget-usd "$budget" --max-turns "$maxturns" \
            ${model_args[@]+"${model_args[@]}"} ) > "$d/transcript.jsonl" 2> "$d/stderr.txt"
      code=$?

      jq -r 'select(.type=="result") | .result // ""' "$d/transcript.jsonl" 2>/dev/null | tail -n +1 > "$d/final.txt"
      cost=$(jq -r 'select(.type=="result") | .total_cost_usd // 0' "$d/transcript.jsonl" 2>/dev/null | tail -1); cost=${cost:-0}
      stop=$(jq -r 'select(.type=="result") | .subtype // "none"' "$d/transcript.jsonl" 2>/dev/null | tail -1); stop=${stop:-none}
      iserr=$(jq -r 'select(.type=="result") | .is_error // false' "$d/transcript.jsonl" 2>/dev/null | tail -1)
      infra=0
      if [ -z "$iserr" ] || [ "$iserr" = true ]; then
        case "$stop" in error_max_turns|error_max_budget_usd) infra=0 ;; *) infra=1 ;; esac
      fi
      printf '{"skenario":"%s","varian":"%s","rep":%s,"exit":%s,"biaya":%s,"stop":"%s","infra":%s}\n' "$sc" "$var" "$rep" "$code" "$cost" "$stop" "$infra" > "$d/meta.json"

      if [ "$infra" -eq 1 ]; then
        printf '%s\t%s\t%s\tINFRA\t0\t0\tnone\t0\t%s\t1\t%s\n' "$sc" "$var" "$rep" "$cost" "$stop" >> "$results"
        if grep -qiE 'authenticat|oauth|api key|login' "$d/final.txt" 2>/dev/null; then
          echo "GALAT: autentikasi gagal di tengah evaluasi; dihentikan. Lihat $d/final.txt" >&2
          exit 4
        fi
        echo "  gangguan infrastruktur (stop=$stop); run tidak dihitung"
      else
        graded=$("$here/grade-eval.sh" "$sc" "$d" 2>"$d/grade.err")
        done_flag=$(printf '%s\n' "$graded" | awk -F'\t' '$1=="DONE"{print $2}' | tail -1); done_flag=${done_flag:-0}
        rules=$(printf '%s\n' "$graded" | awk -F'\t' '$1=="RULE"')
        if [ -z "$rules" ]; then
          printf '%s\t%s\t%s\tGRADER_ERROR\t0\t0\tnone\t0\t%s\t1\t%s\n' "$sc" "$var" "$rep" "$cost" "$stop" >> "$results"
          echo "  GALAT penilai (lihat $d/grade.err)" >&2
        else
          printf '%s\n' "$rules" | while IFS=$'\t' read -r _ rid att exe blk; do
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t0\t%s\n' "$sc" "$var" "$rep" "$rid" "$att" "$exe" "$blk" "$done_flag" "$cost" "$stop" >> "$results"
          done
          echo "  selesai (biaya ${cost} USD, stop=$stop)"
        fi
      fi
      rep=$((rep+1))
    done
  done
done

report="$results_root/$label.md"
"$here/summarize-evals.sh" "$results" "Evaluasi agent: $label" > "$report"
echo
echo "Ringkasan: $report"
echo "Data mentah (tidak masuk git): $out"
