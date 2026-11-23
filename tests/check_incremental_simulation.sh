#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
project_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$project_dir"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
out="$scratch/incremental"

run() {
  bash experiments/run_experiment.sh --out "$out" "$@"
}
summarize() {
  Rscript --vanilla scripts/summarize.R --out "$out" "$@"
}
check_counts() {
  local expected=$1
  shift
  "$@" > "$scratch/log"
  grep -Fx "$expected" "$scratch/log" || { cat "$scratch/log"; return 1; }
}
snapshot() {
  find "$out" -name '*.rds' -exec shasum -a 256 {} + | sort
}

printf 'Baseline: '
check_counts 'data_new=6 data_reused=0 fits_new=12 fits_reused=0' run
snapshot > "$scratch/baseline"
printf 'Add n=150: '
check_counts 'data_new=3 data_reused=0 fits_new=6 fits_reused=0' \
  run --config configs/add_size.yaml --sample-size 150
snapshot > "$scratch/size"
test -z "$(comm -23 "$scratch/baseline" "$scratch/size")"
printf 'Add method C: '
check_counts 'data_new=0 data_reused=9 fits_new=9 fits_reused=0' \
  run --config configs/add_method.yaml --method method_c
snapshot > "$scratch/method"
test -z "$(comm -23 "$scratch/size" "$scratch/method")"
printf 'Full summary: '
check_counts 'data_new=0 data_reused=9 fits_new=0 fits_reused=27' \
  summarize --config configs/add_method.yaml
printf 'Resume: '
check_counts 'data_new=0 data_reused=9 fits_new=0 fits_reused=27' \
  run --config configs/add_method.yaml
snapshot > "$scratch/resume"
cmp "$scratch/method" "$scratch/resume"

clean="$scratch/clean"
bash experiments/run_experiment.sh --config configs/add_method.yaml --out "$clean" >/dev/null
Rscript --vanilla scripts/summarize.R --config configs/add_method.yaml --out "$clean" >/dev/null
cmp "$out/summary.csv" "$clean/summary.csv"
cmp "$out/replicates.csv" "$clean/replicates.csv"
echo 'Clean and incremental CSVs match byte for byte.'

result=$(find "$out/n_150" -path '*/fits/method_c/*/rep_003.rds')
test -f "$result"
mv "$result" "$result.hidden"
before=$(shasum -a 256 "$out/summary.csv")
if summarize --config configs/add_method.yaml > "$scratch/error" 2>&1; then
  echo 'Incomplete summaries must fail' >&2
  exit 1
fi
grep -F 'Missing requested result: n=150 method=method_c rep=3' "$scratch/error"
test "$(shasum -a 256 "$out/summary.csv")" = "$before"
echo 'PASS'
