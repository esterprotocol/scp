#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
validation_log="$(mktemp)"
trap 'rm -f "$validation_log"' EXIT
run_check() {
  bash tools/godot.sh "$@" 2>&1 | tee "$validation_log"
  # Godot can return zero on some script/import errors; inspect diagnostics too.
  if grep -Eq '(^|[[:space:]])(SCRIPT ERROR:|ERROR:)' "$validation_log"; then
    return 1
  fi
}
run_check --headless --editor --import
run_check --headless --script res://tests/test_runner.gd
grep -Eq '^RESULT: [1-9][0-9]* checks, 0 failures$' "$validation_log"
run_check --headless --quit-after 120
