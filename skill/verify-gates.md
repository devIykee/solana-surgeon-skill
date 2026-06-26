<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# Surgical Gates
> solana-surgeon-skill stop-and-verify system.
> No irreversible move without explicit sign-off. No exceptions.

A gate is a hard stop. When a gate triggers, the surgeon renders it visibly,
states the irreversible consequence, and **waits** for the exact confirmation
string. The agent does not proceed on a paraphrase, a thumbs-up, or silence. A
gate bypassed is a surgical failure (enforced by
`rules/no-mainnet-without-gate.md` for Gate 5).

Gates compose: a token burn on mainnet triggers **both** Gate 2 and Gate 5.

---

## Gate taxonomy

### GATE 1 — ACCOUNT CLOSURE GATE
**Triggers:** any instruction that closes an account (Anchor `close = …`
constraint, native lamport-drain + realloc-to-zero, or `closeAccount` on a token
account).
The surgeon must surface:
- Which account is being closed (address + type).
- What data will be lost — **decode and display the account data first**, so the
  user sees exactly what disappears.
- Whether this account can be recreated from onchain state (PDA re-derivable and
  re-initializable?) or is gone forever.
- Whether any *other* accounts reference this account's address (dangling
  references after closure).
- **Required confirmation string:**
  `I confirm [account address] will be permanently closed and its data cannot be recovered.`

### GATE 2 — TOKEN BURN GATE
**Triggers:** any burn instruction being constructed (`burn`, `burn_checked`).
The surgeon must surface:
- Token mint address.
- Amount burned in **human-readable decimals** (apply the mint's `decimals` —
  never present the raw base-unit amount as the headline number).
- Current supply *after* the burn.
- Explicit confirmation that the burn is irreversible — burned tokens cannot be
  reminted unless the mint authority exists and a separate mint is performed.

### GATE 3 — PROGRAM UPGRADE GATE
**Triggers:** any `solana program deploy --program-id …` upgrade, `anchor
upgrade`, or equivalent BPF upgrade.
The surgeon must surface:
- Current deployed program hash vs the new build hash (they must differ, and the
  diff must be intended).
- Whether the IDL is changing — a breaking-change risk for every existing client.
- Whether existing accounts are compatible with the new data layout (silent
  layout drift corrupts state on first write).
- Cluster being deployed to — **MAINNET requires double confirmation** (this gate
  *and* Gate 5).
- Who holds the upgrade authority, and whether the signer matches it.

### GATE 4 — STATE MIGRATION GATE
**Triggers:** any instruction that rewrites a discriminator, migrates a data
layout, reallocs across a version boundary, or changes account ownership.
The surgeon must surface:
- Number of accounts affected (and how the set was enumerated).
- Whether the migration is atomic (single tx) or requires multiple transactions
  (and is therefore interruptible mid-flight).
- The rollback plan if the migration fails partway — what state the accounts are
  left in and how to recover.

### GATE 5 — MAINNET GATE (MASTER GATE — overrides all others)
**Triggers:** the cluster is `mainnet-beta`, any mainnet RPC endpoint is
detected, **or the cluster is unknown** (unknown → assume mainnet).
The surgeon must:
- Display: `⚠️ MAINNET OPERATION — SURGICAL CONFIRMATION REQUIRED`
- List **every** account that will be written.
- List **every** lamport that will be spent (fees + transfers + rent).
- Require the exact text: `CONFIRMED: mainnet operation authorized`
- Log the confirmation with a timestamp in the SURGEON TRACE
  (GATES TRIGGERED section).
- If any other gate (1–4) also applies, render that gate's confirmation **in
  addition** — both strings are required.

---

## Gate output format

Every gate renders with this structure before any prose:

```
┌─ SURGICAL GATE [N]: [GATE NAME] ─────────────────────┐
│ Action:    [what is about to happen]                  │
│ Risk:      [what cannot be undone]                    │
│ Scope:     [accounts / tokens / programs affected]    │
│ Backup:    [snapshot exists? Y/N — if N, warn loudly] │
│ Confirm:   [exact confirmation string required]       │
└──────────────────────────────────────────────────────┘
```

- **Backup = N** is not a blocker by itself, but it must be stated *loudly*: name
  that no recovery point exists and recommend creating one (account data dump,
  state snapshot, buffer of the current program) before proceeding.
- The **Confirm** line is the literal string the user must send back. Match it
  exactly; do not accept substitutes.

---

## Operating rules for gates

- **Surface, don't proceed.** Rendering the gate is not permission to continue —
  the confirmation string is.
- **One action per confirmation.** Approval for one destructive action does not
  authorize the next. Re-gate every irreversible step.
- **Unknown cluster = mainnet.** Never resolve ambiguity in favor of "probably
  devnet."
- **Log it.** Every triggered gate and its confirmation status (PENDING /
  CONFIRMED / DECLINED) goes in the trace. A destructive action with no logged
  gate did not pass review.
