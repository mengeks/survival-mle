#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd "$(dirname "$0")/.." && pwd)
Rscript --vanilla "$project_dir/scripts/run_simulation.R" "$@"
