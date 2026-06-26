<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# Surgical Diagnosis
> solana-surgeon-skill diagnostic protocol.
> The surgeon diagnoses before cutting. Never cuts to diagnose.

A fix is the *last* step, not the first. This file defines a 5-step diagnosis
that is **non-skippable and in order**. A fix proposed before Step 4 is complete
is a surgical failure (enforced by `rules/no-fix-without-diagnosis.md`).

---

## 1. The 5-step surgical diagnosis

### STEP 1 — COLLECT
Read the *full* error, not the first line. Decode the error code using the
program's error enum (`#[error_code]` in Anchor, the `ProgramError`/custom enum
in native) or the IDL `errors` array. Never guess what an error code means — look
it up in source or IDL.

- **Required output:** the raw error (code + message + logs) *and* its decoded
  meaning, with the source of the decoding cited (file + enum variant, or IDL
  entry).
- A custom program error like `0x1771` is meaningless until mapped: `0x1771` =
  `6001` = the second variant of the program's error enum. Map it before moving.

### STEP 2 — LOCATE
Identify exactly which instruction, account, or constraint fired the error.

- **Anchor:** the error message names the failing constraint (e.g.
  `ConstraintSeeds`, `ConstraintHasOne`). Trace it to the `#[account(...)]`
  attribute that declares it.
- **Native:** trace to the exact `require!`, `if … return Err(...)`, or `msg!`
  that produced the failure, following the program log order.
- **Required output:** file + line number + the constraint/check name that
  fired. "Somewhere in the deposit instruction" is not a location.

### STEP 3 — HYPOTHESIZE
Generate **exactly three** hypotheses for the root cause. Rank them by
likelihood. Each must be *falsifiable* — phrased so that a specific piece of
evidence could prove it false.

- Do not generate fewer than three. If only one cause seems possible, you have
  not looked hard enough — force two alternatives (client-side, account-state,
  program-logic are usually distinct candidate families).
- **Required output:** a ranked list of three falsifiable hypotheses.

### STEP 4 — ELIMINATE
For each hypothesis, state the evidence that would disprove it, then go check
that evidence. Cross off the hypotheses the evidence eliminates.

- **Required output:** a hypothesis table with a status of **CONFIRMED** or
  **ELIMINATED** for each row, and the specific evidence that decided it.

  | # | Hypothesis | Disproving evidence to check | Status | Evidence found |
  |---|-----------|------------------------------|--------|----------------|
  | 1 | …         | …                            | CONFIRMED / ELIMINATED | … |
  | 2 | …         | …                            | ELIMINATED | … |
  | 3 | …         | …                            | ELIMINATED | … |

- Exactly one hypothesis should survive as CONFIRMED before you proceed. If two
  survive, keep eliminating. If none survive, return to Step 3 with what you
  learned.

### STEP 5 — OPERATE
Only after a hypothesis is CONFIRMED may a fix be proposed.

- The fix must be **minimal** — it changes only what the diagnosis identified,
  nothing else. No drive-by refactors, no "while I'm here" edits.
- Include a **verification step**: exactly how the engineer confirms the fix
  worked (rerun this instruction, expect this log, check this account field
  equals this value).
- Change one thing, then verify. Never bundle the confirmed fix with speculative
  changes for the eliminated hypotheses.

---

## 2. Common Solana error patterns (reference)

Use to seed Step 3 hypotheses — not to skip Steps 1–2. The *most common* root
cause is listed; it is a starting point, not a verdict.

| Error | Most common root cause |
|-------|------------------------|
| `0x1` (insufficient funds) | Fee payer / source account lacks lamports or tokens for the transfer + fees. |
| `0x0` (custom program error 0) | First variant of the program's error enum — usually a require!/constraint the program defines as error 0. Decode against source. |
| `AccountNotInitialized` | Account read before it was created/initialized, or wrong address derived so an empty account is loaded. |
| `AccountOwnedByWrongProgram` | Account's `owner` is not the expected program — wrong account passed, or not yet assigned to the program. |
| `ConstraintSeeds` | Derived PDA ≠ provided address: wrong seeds, wrong order, non-canonical/mismatched bump, or wrong program ID. |
| `ConstraintSigner` | An account required to sign is not marked `is_signer` in the client, or the wrong key was passed. |
| `InvalidAccountData` | Data could not deserialize into the expected layout — wrong account type, version skew, or truncated data. |
| `InvalidProgramId` | Program ID passed to a CPI (or in the client) does not match the expected program — often a hardcoded ID out of sync with `declare_id!`. |
| `AccountAlreadyInitialized` | `init` ran against an account that already exists — re-init attempt, or `init` used where `init_if_needed` was intended. |
| `InstructionMissing` / `InstructionFallbackNotFound` | Instruction discriminator does not match any handler — client/IDL out of sync with the deployed program, or wrong program targeted. |

---

## 3. Surgical anti-patterns — the surgeon must never:

- **Propose a fix before completing Steps 1–4.** A fix without a CONFIRMED
  hypothesis is a guess wearing a lab coat.
- **Assume the error is in the client if it could be in the program** — and vice
  versa. Carry both families into Step 3 until evidence eliminates one.
- **Assume the error is in the program if it could be in the accounts.** Wrong
  account state (owner, discriminator, bump) masquerades as a code bug constantly.
- **Suggest "try redeploying"** as a diagnosis step. Redeploy is an action, not
  evidence; it hides the cause and resets nothing you understand.
- **Modify more than one thing between verification runs.** Two simultaneous
  changes make the next result uninterpretable.

---

The diagnosis artifact — collected error, located constraint, three hypotheses,
elimination table, minimal fix, verification step — is attached to the SURGEON
TRACE. No fix ships without it.
