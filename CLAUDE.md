# CLAUDE.md

Standing orders for Claude Code in this repo. Read this first.

## What this repo is

A teaching sandbox demonstrating the closed-loop agentic workflow on a small
SystemVerilog project (a UART receiver). The audience is an EE moving from
"paste code from chat" to running Claude Code locally against a real testbench.

The point isn't the UART. The point is the *workflow*.

## The loop

When you change RTL or testbench code, run the testbench and read the output.
The simulator is the source of truth.

```
make test     # build + run the SV testbench under Verilator
make lint     # Verilator lint pass over the RTL only
make clean    # remove build/
```

Exit code 0 ⇒ all checks passed. Non-zero ⇒ read the FAIL lines and fix the
RTL (usually) or the testbench. Don't claim success without seeing a clean
`=== ALL TESTS PASSED ===`.

## Style

- SystemVerilog (`.sv`), not Verilog-2001.
- `always_ff` for sequential logic, `always_comb` for combinational.
- Named `typedef enum` for state machines — not `parameter` constants.
- Active-low resets are named `rst_n`.
- `snake_case` for signals and modules. Module names match their filename.
- Every new RTL module needs a matching `tb_<name>.sv` with at least one
  self-checking case.

## What NOT to touch without asking

- `Makefile` — CI depends on these targets.
- `.github/workflows/` — only touch if explicitly asked.
- `docs/WALKTHROUGH.md` — this is the teaching artefact. Small clarifications
  OK, structural changes need a heads-up.

## Plan-mode-worthy changes

Use plan mode (Shift+Tab twice) for:

- Adding new RTL modules (TX side, FIFO, bus interface).
- Refactoring the FSM structure of `uart_rx`.
- Changing the testbench harness style (e.g., moving to a C++ Verilator TB).

Single-file bug fixes inside `uart_rx.sv` don't need plan mode.
