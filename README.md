# claude-code-for-verilog

A tiny SystemVerilog project — a UART receiver and its testbench — set up so
**Claude Code** can edit, simulate, and iterate on it in a closed loop.

This is a **teaching sandbox**, not a hardware library. The point isn't the
UART. The point is the workflow.

## Audience

An experienced hardware engineer who already uses Claude (or another LLM) by
chatting in a browser and copying code back and forth, and who wants to see
what the next step up looks like in their own workflow.

## Quick start

Install Verilator (5.x or newer — needs `--timing` and `--binary`):

```bash
sudo apt install verilator        # Ubuntu / Linux Mint 24.04+
brew install verilator            # macOS
```

Then:

```bash
make test
```

You should see five `PASS [...]` lines and then `=== ALL TESTS PASSED ===`.

```bash
make lint       # lint the RTL
make clean      # nuke build/
```

## What's in the box

```
rtl/uart_rx.sv          # the design under test — 8-N-1 UART receiver
sim/tb_uart_rx.sv       # self-checking SV testbench
Makefile                # make test / make lint / make clean
CLAUDE.md               # standing orders for Claude Code
.github/workflows/ci.yml  # CI runs make lint + make test on every push
docs/WALKTHROUGH.md     # the teaching doc — start here
```

## The walkthrough

Read **[docs/WALKTHROUGH.md](docs/WALKTHROUGH.md)**. That document is the whole
point of the repo. It explains the level-1 → level-2 → level-3 progression and
gives concrete exercises to try with Claude Code running locally.

## Claude Code

The CLI lives at https://docs.claude.com/en/docs/claude-code. Once installed,
just run `claude` in this directory.
