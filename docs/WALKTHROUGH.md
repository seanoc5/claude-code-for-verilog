# Walkthrough: From "Asking Claude" to "Closing the Loop"

For an experienced hardware engineer who already uses Claude (or another LLM)
in a browser to draft code and explain things. The goal is to show, in one
small repo, what the *next step up* looks like — and why it's well-suited to
the verification culture you already work in.

## The five levels (rough mental model)

| Level | What you do                                                | What the LLM does                                       | Guard rails                                       |
| ----- | ---------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------- |
| 0     | Write all code yourself                                    | Nothing                                                 | Your own review + simulator                       |
| 1     | Describe a problem, paste code into chat, copy answer back | Drafts code, explains, suggests fixes                   | You re-run the sim manually                       |
| 2     | Run Claude Code in the project; let it edit files          | Edits files, runs the sim, reads output, iterates       | Testbench + lint = the LLM's seatbelt             |
| 3     | Give intent + a `CLAUDE.md`; review diffs                  | Plans changes, runs tests, commits, opens PRs           | CI is the final gate; you review the diff         |
| 4     | Parallel agents, scheduled tasks, MCP tools                | Drives multi-step workflows on top of the above         | Multiple agents review each other; logs + tracing |

Most people are at **Level 1**. The jump from 1 → 2 is the highest-leverage
one, and is what this repo demonstrates.

## Why hardware engineers have an advantage

The reason LLM-driven coding is unsettling in pure software is that the LLM
can write plausible code that *runs* but is subtly wrong. In hardware you
already have a culture of writing self-checking testbenches before, or
alongside, the RTL.

**Your testbench is the contract. The simulator is the judge.**

That's exactly what an agentic LLM needs to operate safely. The LLM edits
code → runs the sim → reads the pass/fail → iterates. If it cheats, the
testbench catches it. Software folks are reinventing this discipline and
calling it "verification-driven development". You're ahead — you just need to
plug the LLM into the loop you already have.

## What's in this repo

- `rtl/uart_rx.sv` — a small 8-N-1 UART receiver, parameterised by
  `CLKS_PER_BIT`.
- `sim/tb_uart_rx.sv` — a self-checking SystemVerilog testbench that drives
  the rx line, sends a handful of bytes, and asserts the receiver delivers
  them correctly.
- `Makefile` — `make test`, `make lint`, `make clean`. Runs under Verilator.
- `CLAUDE.md` — standing orders the agent reads before doing anything.
- `.github/workflows/ci.yml` — installs Verilator and runs the same targets
  in CI on every push.

Total size: ~300 lines of code. Small enough to read before lunch.

## Level 1 — what you're probably doing today

1. Open Claude in the browser
2. Paste the spec, get back some Verilog
3. Drop it into your editor
4. Run your testbench
5. If it fails, paste the failure back into the chat
6. Repeat

This works. It's just slow, because **you** are the messenger between the
model and the simulator.

## Level 2 — close the loop

Install Claude Code (the CLI):

```bash
npm install -g @anthropic-ai/claude-code
```

In this repo, run:

```bash
claude
```

Then give it a real exercise. Try this prompt verbatim:

> Add framing-error detection: when the stop bit is sampled low, the receiver
> should still emit `valid` but also assert `frame_err` on the same cycle.
> Then add a testbench case that drives a bad stop bit and asserts the error
> fires.

Watch what happens:

- Claude reads `CLAUDE.md`, `uart_rx.sv`, and `tb_uart_rx.sv` first.
- It proposes an edit and shows you the diff before writing.
- After the edit, it runs `make test` itself.
- If the test fails, it reads the simulator output, adjusts, and tries again.
- When it lands a green build, it stops and tells you what it changed.

You went from being the messenger to being the reviewer. **That's the level
1 → 2 jump.** Same testbench, same simulator, same RTL — you just removed
yourself from the inner loop.

> Note: `uart_rx.sv` already implements `frame_err`. That's deliberate — the
> first time you try this, Claude should notice and tell you so, rather than
> redo work. That itself is a useful trust-building moment.

## Level 3 — encode the conventions

Open `CLAUDE.md`. That file is the agent's standing orders. In this repo it
covers:

- Coding style (`always_ff`, `rst_n`, named enums for FSMs)
- How to run tests (`make test`, `make lint`)
- What files NOT to touch without asking
- When to use plan mode

In *your own* Verilog/Perforce project, your `CLAUDE.md` would also cover:

- "All new modules need a matching `tb_<name>.sv` testbench"
- "Run `make lint` before declaring work done"
- "Before editing read-only Perforce files, run `p4 edit <file>`"
- "Vendor-specific primitive instantiations are never to be modified by the
  agent — leave them alone"

The `CLAUDE.md` is also the right place to write down lessons you learn
about how the LLM screws up. Every time you correct it, ask: *is there a
rule I could write down so it doesn't make that mistake next time?* Over a
few weeks, that file accumulates into a high-leverage style guide that is
read on every session.

## On Perforce

Claude Code edits files. It doesn't care about your VCS. The only wrinkle is
that Perforce keeps files read-only until you `p4 edit` them. Three options,
from simplest to most polished:

- **Manual.** Run `p4 edit <files>` yourself before starting a session.
- **Wrapper.** A small shell function or pre-edit hook that runs `p4 edit`
  before any modification. Claude Code supports user-defined hooks for this
  (`PreToolUse` on `Edit`/`Write`).
- **Lazy.** Let Claude try to edit, fail, run `p4 edit`, retry. Works, just
  noisier.

For the *learning* phase, ignore the VCS — clone this GitHub repo, play,
absorb the loop. The lessons transfer to Perforce verbatim.

## On "guard rails"

For an EE, guard rails aren't exotic. They're what you already do. In rough
priority order:

1. **Self-checking testbench** — assertions, expected vs. actual, non-zero
   exit on failure.
2. **Lint** — Verilator `-Wall`, Verible. Catches typos, latches, width
   mismatches.
3. **Formal** — SymbiYosys / sby. Proves invariants across all inputs.
   Catches what simulation misses.
4. **CI** — runs all of the above on every push, independently of your
   local machine. The CI in this repo is six lines of YAML.

Claude Code is good *because* of these, not in spite of them. The agent
loop relies on them to know whether its change worked. The more rigorous
your existing verification flow, the more rope you can give the agent.

## Exercises to try in this repo

Each of these is a real exercise. Open `claude` in this directory and try
one. Start small.

1. **(easy)** Add a parameterisable parity option
   (`PARITY = "NONE" | "EVEN" | "ODD"`). Update the testbench to cover the
   added cases.
2. **(easy)** Add a `tb_uart_rx_random.sv` that sends 100 random bytes (use a
   fixed seed) and checks every one.
3. **(medium)** Add a `uart_tx.sv` transmitter. Then add a loopback test that
   ties tx → rx and checks bytes round-trip.
4. **(medium)** Add an oversampling counter so the receiver rejects glitches
   shorter than one bit time. *Write the test first.*
5. **(harder)** Wrap rx + tx in a small AXI-Lite or register-file interface so
   a CPU could drive it. Use plan mode for this one — it touches multiple
   files and design boundaries.

Suggestion: do exercise (1) yourself in chat (Level 1 style). Do exercise
(2) with `claude` running locally (Level 2). By exercise (3) you'll have a
feel for what's worth handing off and what's worth doing by hand.

## When *not* to use the agent

Honest answer:

- Anything involving timing closure, P&R, or vendor toolchains. The LLM
  doesn't have ground truth there.
- Anything safety-critical without independent formal verification.
- Anything where the cost of a subtle bug exceeds the cost of writing it
  yourself by hand. (For now.)

The LLM is a junior engineer with infinite stamina and zero ego. Treat it
that way: useful for grunt work, first drafts, explaining unfamiliar code,
and writing exhaustive test cases. Always reviewed.

## Further reading

- Claude Code docs: https://docs.claude.com/en/docs/claude-code
- Verilator: https://verilator.org
- SymbiYosys (formal verification): https://symbiyosys.readthedocs.io
- Verible (lint + format for SV): https://github.com/chipsalliance/verible
