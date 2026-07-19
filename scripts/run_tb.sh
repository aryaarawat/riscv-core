#!/usr/bin/env bash
# Run a single module testbench with Icarus Verilog.
# Usage: ./scripts/run_tb.sh <name>
#   name is one of: pc regfile immgen alu control imem dmem cpu
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <pc|regfile|immgen|alu|control|imem|dmem|cpu>" >&2
  exit 2
fi

OUT="tb_${NAME}.vvp"
VCD="tb_${NAME}.vcd"

case "$NAME" in
  pc)
    SRCS=(rtl/pc.v tb/tb_pc.v)
    ;;
  regfile)
    SRCS=(rtl/regfile.v tb/tb_regfile.v)
    ;;
  immgen)
    SRCS=(rtl/immgen.v tb/tb_immgen.v)
    ;;
  alu)
    SRCS=(rtl/alu.v tb/tb_alu.v)
    ;;
  control)
    SRCS=(rtl/control.v tb/tb_control.v)
    ;;
  imem)
    SRCS=(rtl/imem.v tb/tb_imem.v)
    ;;
  dmem)
    SRCS=(rtl/dmem.v tb/tb_dmem.v)
    ;;
  cpu)
    SRCS=(
      rtl/pc.v rtl/regfile.v rtl/immgen.v rtl/alu.v rtl/control.v
      rtl/imem.v rtl/dmem.v rtl/cpu.v tb/tb_cpu.v
    )
    ;;
  *)
    echo "Unknown testbench: $NAME" >&2
    exit 2
    ;;
esac

echo "==> Compiling $NAME"
iverilog -g2012 -o "$OUT" "${SRCS[@]}"

echo "==> Running $NAME"
# Capture output so callers (regress.sh) can grep PASS/FAIL.
# VCD is written next to the .vvp in the repo root (testbench $dumpfile path).
if ! OUTPUT="$(vvp "$OUT" 2>&1)"; then
  echo "$OUTPUT"
  echo "FAIL: vvp exited nonzero for $NAME" >&2
  exit 1
fi
echo "$OUTPUT"

if ! grep -q "ALL TESTS PASSED" <<<"$OUTPUT"; then
  echo "FAIL: $NAME did not report ALL TESTS PASSED" >&2
  exit 1
fi

echo "==> OK $NAME (waveform: $VCD)"
