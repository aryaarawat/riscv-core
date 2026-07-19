# riscv-core

Educational single-cycle **RV32I** CPU built module-by-module in Verilog.

## What's here

| Module | Role |
|--------|------|
| `rtl/pc.v` | Program counter register |
| `rtl/regfile.v` | 32×32 register file (`x0` hardwired 0) |
| `rtl/immgen.v` | Immediate generator (I/S/B/U/J) |
| `rtl/alu.v` | ALU + zero flag |
| `rtl/control.v` | Main decoder (opcodes → control signals) |
| `rtl/imem.v` | Instruction memory (`$readmemh`) |
| `rtl/dmem.v` | Data memory (byte/half/word loads & stores) |
| `rtl/cpu.v` | Top-level single-cycle datapath |

## Prerequisites

```bash
# Icarus Verilog (simulation)
brew install icarus-verilog

# GTKWave (waveform viewer) — optional but recommended
brew install --cask gtkwave
```

## Run one testbench

```bash
./scripts/run_tb.sh pc        # or regfile, immgen, alu, control, imem, dmem, cpu
```

After a run, open the VCD in GTKWave:

```bash
gtkwave tb_pc.vcd &
```

## Run full regression

```bash
./scripts/regress.sh
```

Exits nonzero if any testbench fails (missing `ALL TESTS PASSED`).

## Smoke program

[`sw/smoke.hex`](sw/smoke.hex) is a tiny hand-assembled program exercised by `tb_cpu`. It ends with `ebreak`, which the CPU treats as a simulation halt.
