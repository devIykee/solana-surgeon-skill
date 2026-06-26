<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill — run the surgical pre-flight checklist for accounts, PDA, transaction, or deploy"
argument-hint: "[accounts|pda|transaction|deploy]"
---

Run the surgical **pre-flight checklist** for the given operation type, part of
solana-surgeon-skill. The surgeon checks before every procedure.

Argument: `$ARGUMENTS` — one of `accounts`, `pda`, `transaction`, `deploy`. If
omitted, ask which operation is in scope rather than guessing.

## Behavior

Load **only** the matching checklist from `skill/preflight.md`:

- `accounts` → **Checklist A** (ownership, discriminator/layout, writable,
  signer, rent, balance, existence).
- `pda` → **Checklist B** (seeds, program ID, stored vs canonical bump, bounded
  seeds, collision).
- `transaction` → **Checklist C** (cluster, fee payer, ordering, compute budget,
  duplicate accounts, signers).
- `deploy` → **Checklist D** (program ID vs `declare_id!`, buffer lamports,
  upgrade authority, build/version, IDL sync, mainnet authorization).

For each box, gather **evidence** (a source line, a decoded account, a CLI
output) — never tick a box from memory. Report each box as PASS / FAIL / UNKNOWN.

**On any FAIL or UNKNOWN: STOP.** Do not build, sign, or submit. Name the failing
box, record it in the SURGEON TRACE PREFLIGHT section, and resolve it first. If
the cluster check resolves to mainnet-beta or stays unknown, escalate to the
mainnet gate (`/gate mainnet`).

## Loads
- `skill/preflight.md` (relevant checklist only)
