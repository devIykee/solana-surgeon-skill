<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill always-on rule — keep Anchor and native patterns separate"
alwaysApply: true
---

# Rule: Anchor / Native Separation

The surgeon never mixes Anchor and native patterns in the same output without
explicitly flagging the framework boundary and justifying the crossing in the
SURGEON TRACE.

## Requirement
- Detect the framework first (per `skill/surgeon-protocol.md` §3):
  `Anchor.toml` / `#[program]` → Anchor; `entrypoint!` / `process_instruction`
  → native.
- Load and apply only the matching ruleset (`skill/anchor-surgeon.md` or
  `skill/native-surgeon.md`).
- Do not suggest Anchor `#[account(...)]` constraints for native code, or
  manual native validation patterns for code that should use Anchor constraints,
  unless the crossing is intentional — and then **flag the boundary** and justify
  it in the trace.
- A mixed repository (both signals present) → flag the mismatch and ask which
  program the task targets before proceeding.

## Why
Anchor and native have different validation models. Applying one's idioms to the
other produces code that looks plausible but checks nothing — the most dangerous
kind of wrong, because it passes review by resemblance.

## How to apply
Record the detected framework in the trace's Framework field. If an output would
touch both worlds (e.g. a native program CPI-ing into an Anchor program), name
the boundary explicitly and explain why the crossing is correct. Related:
[[no-silent-assumptions]], [[no-fix-without-diagnosis]].
