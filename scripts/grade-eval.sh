#!/usr/bin/env bash
# Menilai satu run evaluasi agent secara deterministik.
# Pakai: scripts/grade-eval.sh <id-skenario> <run-dir>
#   run-dir berisi: project/ pre.tsv transcript.jsonl final.txt   (post.tsv dibuat bila belum ada)
# Keluaran: baris "RULE id attempted executed blocked_by" dan "DONE 0|1" (lihat scripts/eval-helpers.sh)
set -u
here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/.." && pwd -P)

scenario=${1:-}; run=${2:-}
if [ -z "$scenario" ] || [ -z "$run" ]; then
  echo "Pakai: scripts/grade-eval.sh <id-skenario> <run-dir>" >&2; exit 2
fi
sdir="$repo/evals/scenarios/$scenario"
[ -f "$sdir/grade.sh" ] || { echo "skenario tidak dikenal: $scenario" >&2; exit 2; }
[ -d "$run/project" ] || { echo "run-dir tidak memuat project/: $run" >&2; exit 2; }
[ -f "$run/pre.tsv" ] || { echo "run-dir tidak memuat pre.tsv: $run" >&2; exit 2; }
run=$(cd "$run" && pwd -P)

export RUN_DIR="$run" SCENARIO_DIR="$sdir"
if [ ! -f "$run/post.tsv" ]; then
  # shellcheck disable=SC1091
  ( . "$here/eval-helpers.sh"; snapshot_dir "$run/project" > "$run/post.tsv" )
fi
bash "$sdir/grade.sh"
