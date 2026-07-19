#!/usr/bin/env bash
# Run every module testbench. Fail fast on first failure.
# Usage: ./scripts/regress.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TESTS=(pc regfile immgen alu control imem dmem cpu)

PASS=0
FAIL=0

echo "========================================"
echo " RV32I core regression"
echo "========================================"

for t in "${TESTS[@]}"; do
  echo
  if ./scripts/run_tb.sh "$t"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo
    echo "Regression aborted: $t failed"
    echo "Passed: $PASS  Failed: $FAIL"
    exit 1
  fi
done

echo
echo "========================================"
echo " ALL REGRESSION TESTS PASSED ($PASS)"
echo "========================================"
echo "Open any tb_*.vcd in GTKWave for signal-level debug:"
echo "  brew install --cask gtkwave   # if needed"
echo "  gtkwave tb_cpu.vcd &"
