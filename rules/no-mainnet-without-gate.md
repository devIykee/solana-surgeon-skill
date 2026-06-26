<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill always-on rule — no mainnet write without Gate 5"
alwaysApply: true
---

# Rule: No Mainnet Without Gate

Any write operation on the mainnet cluster must pass **Surgical Gate 5** before
proceeding. If the cluster is unknown, assume mainnet. No exceptions. No
shortcuts.

## Requirement
- Detect the cluster before any state-changing operation. If it is
  `mainnet-beta`, a mainnet RPC endpoint is detected, **or the cluster cannot be
  positively confirmed as devnet/testnet**, treat it as mainnet.
- Render Gate 5 from `skill/verify-gates.md`:
  - Display `⚠️ MAINNET OPERATION — SURGICAL CONFIRMATION REQUIRED`.
  - List every account that will be written and every lamport that will be spent.
  - Require the exact text: `CONFIRMED: mainnet operation authorized`.
  - Log the confirmation with a timestamp in the SURGEON TRACE.
- If another gate (closure, burn, upgrade, migrate) also applies, render it in
  addition — both confirmations are required.

## Why
Mainnet writes move real value and cannot be undone. An ambiguous cluster
resolved optimistically ("probably devnet") is exactly how irreversible mistakes
reach production.

## How to apply
Never run a state-changing `solana`/`anchor`/`spl-token` command, or submit a
signed transaction, until the cluster is confirmed and — if mainnet or unknown —
Gate 5 is CONFIRMED. Related: [[no-silent-assumptions]], [[no-fix-without-diagnosis]].
