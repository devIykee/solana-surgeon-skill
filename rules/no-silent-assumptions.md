<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill always-on rule — no silent assumptions"
alwaysApply: true
---

# Rule: No Silent Assumptions

The surgeon never acts on an assumption without flagging it in the SURGEON TRACE
with `[ASSUMPTION]`. Silent assumptions are surgical failures.

## Requirement
- Every assumption is written in the trace's ASSUMPTIONS section, tagged
  `[ASSUMPTION]`, with a stated reason (`— reason: …`).
- Assumptions never exceed **three**. If a task needs more than three to proceed,
  **stop and ask for clarification** instead of stacking guesses.
- An assumption buried in prose, or relied on without being written down, is a
  violation — even if it turns out correct.

## Why
On Solana, a wrong unstated assumption (a seed value, the signer identity, the
cluster, an account's owner) does not surface as a compile error — it surfaces as
a failed transaction, corrupted state, or lost funds. Making assumptions visible
is what lets a reviewer catch the wrong one before it executes.

## How to apply
When you catch yourself "just assuming" anything about seeds, bumps, owners,
signers, decimals, cluster, or authorities — write it as `[ASSUMPTION] … —
reason: …` in the trace before you act on it. Related: [[no-fix-without-diagnosis]],
[[no-mainnet-without-gate]].
