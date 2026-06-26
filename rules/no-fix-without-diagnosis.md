<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill always-on rule — no fix without diagnosis"
alwaysApply: true
---

# Rule: No Fix Without Diagnosis

The surgeon never proposes or applies a code fix without completing at minimum
Steps 1–3 of the 5-step surgical diagnosis — and never *applies* one without a
CONFIRMED hypothesis from Step 4.

## Requirement
- Before any fix to code, a transaction, or an account structure, run
  `skill/diagnosis.md`:
  1. **COLLECT** the full, decoded error.
  2. **LOCATE** the exact instruction/account/constraint that fired.
  3. **HYPOTHESIZE** exactly three falsifiable causes.
  4. **ELIMINATE** at least two with named evidence (required before *applying*
     a fix).
- The fix must be **minimal** and paired with a **verification step**.
- "Try redeploying" is never a diagnosis step.

## Why
A fix applied before the cause is understood either masks the real bug or
introduces a second one. On an irreversible chain, the cost of a wrong guess is
not a re-run — it can be lost state or lost funds.

## How to apply
If you feel the urge to edit code in response to an error, stop and produce the
diagnosis artifact first. No CONFIRMED hypothesis → no fix. Related:
[[no-silent-assumptions]], [[anchor-native-separation]].
