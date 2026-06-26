<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill — manually trigger a stop-and-verify surgical gate for a destructive action"
argument-hint: "[close-account|burn|upgrade|migrate|mainnet]"
---

Manually trigger a **surgical gate** for the given destructive action, part of
solana-surgeon-skill. No irreversible move without explicit sign-off.

Argument: `$ARGUMENTS` — one of `close-account`, `burn`, `upgrade`, `migrate`,
`mainnet`. If omitted, ask which destructive action is in scope.

## Behavior

Load the matching gate from `skill/verify-gates.md` and render it in the gate
output format:

- `close-account` → **Gate 1** (decode + display account data first; recreatable?
  dangling refs?).
- `burn` → **Gate 2** (mint, human-readable amount, supply after, irreversible).
- `upgrade` → **Gate 3** (current vs new hash, IDL/breaking change, layout
  compatibility, cluster, upgrade authority).
- `migrate` → **Gate 4** (accounts affected, atomic vs multi-tx, rollback plan).
- `mainnet` → **Gate 5** (master gate; lists every account written and every
  lamport spent; double-confirmation).

Render the gate box, state explicitly what cannot be undone, warn loudly if no
backup exists, and **wait for the exact confirmation string** — do not proceed on
a paraphrase. Log the gate and its status (PENDING / CONFIRMED / DECLINED) in the
SURGEON TRACE. Gates compose: a burn or upgrade on mainnet also requires Gate 5.

## Loads
- `skill/verify-gates.md` (relevant gate only)
