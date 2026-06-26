<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
name: solana-surgeon-skill
description: >-
  Surgical reasoning discipline for Solana protocol engineers. Installs a
  trace-before-act, diagnose-before-fix, preflight-before-execute,
  gate-before-destruction operating procedure into any Claude Code agent
  working on Solana (Anchor 0.30+ or native). A surgeon does not guess.
user-invocable: true
---

# solana-surgeon-skill
> Surgical reasoning discipline for Solana protocol engineers.
> A surgeon does not guess. Neither does this skill.

solana-surgeon-skill is a **meta-skill**: it does not solve one narrow Solana
problem, it installs an operating discipline. When active, the agent reads the
full picture before touching code, runs pre-operative checks before any onchain
interaction, diagnoses root cause before applying a fix, and stops at a visible
gate before any irreversible move. It is for Solana protocol engineers — working
in Anchor or native — who have been burned by a guessed PDA seed, a skipped
account check, or a fix shipped before the bug was understood, and who want their
AI agent to behave like a senior engineer who has been burned the same way.

This file is the **router**. Load only what the current task needs.

## Routing table

| Task                                  | Load this file              |
|---------------------------------------|-----------------------------|
| Any task (activate surgical mode)     | surgeon-protocol.md         |
| Account/PDA/seed validation           | preflight.md                |
| Debugging a bug / tracing an error    | diagnosis.md                |
| Irreversible or destructive action    | verify-gates.md             |
| Logging reasoning for review          | reasoning-trace.md          |
| Anchor program work                   | anchor-surgeon.md           |
| Native program work                   | native-surgeon.md           |
| CPI call chains                       | cpi-surgeon.md              |

All paths are relative to this directory (`skill/`). Each file is self-contained
and loadable independently — that is the whole point of progressive loading.

## Quick-load (tight token budget)

If the agent has **< 2000 tokens** of remaining budget:

1. Load **`surgeon-protocol.md`** — always. It is the master discipline and
   stands alone.
2. Load **the one domain file** that matches the task from the routing table
   above (e.g. a CPI question → `cpi-surgeon.md`, nothing else).
3. Defer everything else. Load `preflight.md`, `diagnosis.md`,
   `verify-gates.md`, and `reasoning-trace.md` on demand the moment a
   preflight, diagnosis, gate, or trace is actually required — not before.

The trace format in `reasoning-trace.md` is small; if any onchain *write* is in
scope, load it regardless of budget so the decision is auditable.

## Activation contract

When this skill is active the agent commits to the five surgical principles
defined in `surgeon-protocol.md`:

1. **Trace before act** — a visible reasoning trace precedes output.
2. **Diagnose before fix** — no fix without a completed diagnosis artifact.
3. **Preflight before execution** — no onchain interaction without its checklist.
4. **Gate before destruction** — no irreversible move without explicit sign-off.
5. **Anchor vs native awareness** — the correct ruleset for the detected context.

These are also installed as always-on rules under `rules/`.

---

solana-surgeon-skill enforces no shortcuts. Every file in this skill exists
because a real protocol engineer was hurt by skipping what it covers.
