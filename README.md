<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# solana-surgeon-skill
> Surgical reasoning discipline for Claude Code agents on Solana.
> A surgeon does not guess. Neither does this skill.

solana-surgeon-skill is a **meta-skill** for [Claude Code](https://claude.com/claude-code).
It does not solve one narrow Solana problem — it installs an operating
discipline. When active, your agent reads the full picture before touching code,
runs pre-operative checks before any onchain interaction, diagnoses root cause
before applying a fix, and stops at a visible gate before any irreversible move.
It is built for Solana protocol engineers working in **Anchor 0.30+** or
**native** programs on the 2026 stack.

---

## The problem

AI coding agents are fast but imprecise on Solana. They guess at PDA seeds, skip
the account-validation order, treat program-derived addresses like keypairs,
apply fixes before diagnosing the bug, and walk straight through destructive
operations — closing accounts, burning tokens, deploying to mainnet — without
confirmation. On a chain where a wrong move is irreversible, speed without
precision is a liability. This skill installs the reasoning discipline that
prevents those failures.

## What this skill does *not* do

It does **not** replace a security audit. It does **not** write your Solana
programs for you. It does **not** manage DeFi positions, custody keys, or handle
legal/compliance questions. It makes the agent that does those things operate
with surgical precision — visible reasoning, pre-flight checks, diagnosis before
fixes, and hard gates before anything irreversible.

## Installation

**One-liner:**

```bash
bash <(curl -s https://raw.githubusercontent.com/devIykee/solana-surgeon-skill/main/install.sh)
```

**Manual:**

```bash
git clone https://github.com/devIykee/solana-surgeon-skill.git
cd solana-surgeon-skill
./install.sh            # installs into ~/.claude
./install.sh --dry-run  # preview without writing
./install.sh --uninstall
```

The installer copies `skill/`, `agents/`, `commands/`, and `rules/` into your
`.claude` directory and registers the skill in `settings.json`. It is idempotent
— safe to run repeatedly.

## The five surgical principles

1. **Trace before act** — a visible SURGEON TRACE (knowns / unknowns /
   assumptions) precedes every output. Assumptions are tagged `[ASSUMPTION]` and
   capped at three.
2. **Diagnose before fix** — no fix ships without a completed 5-step diagnosis
   and a CONFIRMED root cause.
3. **Preflight before execution** — no instruction is built, no transaction
   signed, until the matching pre-flight checklist PASSes.
4. **Gate before destruction** — closing accounts, burning tokens, upgrading
   programs, migrating state, or writing to mainnet triggers a stop-and-verify
   gate requiring an exact confirmation string.
5. **Anchor vs native awareness** — the agent detects the framework and applies
   only that ruleset, never mixing the two without flagging the boundary.

## Slash commands

| Command | Usage | What it does |
|---------|-------|--------------|
| `/surgeon-trace [on\|off]` | `/surgeon-trace on` | Toggle visible SURGEON TRACE headers for the session. |
| `/preflight [accounts\|pda\|transaction\|deploy]` | `/preflight pda` | Run the surgical pre-flight checklist for that operation. |
| `/diagnose "[error]"` | `/diagnose "Error: ConstraintSeeds"` | Run the 5-step surgical diagnosis on an error. |
| `/gate [close-account\|burn\|upgrade\|migrate\|mainnet]` | `/gate mainnet` | Trigger a stop-and-verify gate for a destructive action. |
| `/cpi-trace` | `/cpi-trace` | Build the CPI call graph for the current instruction. |

## Routing table

The agent loads only what the task needs (progressive loading).

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

---

## Worked example — a `ConstraintSeeds` error

A real debugging scenario: a withdraw instruction on a vault PDA fails with
`ConstraintSeeds`. The vault stores its bump in state, and the wrong bump was
persisted at initialization. Here is the full 5-step surgical diagnosis.

### Step 1 — COLLECT

```
Error: AnchorError caused by account: vault.
  Error Code: ConstraintSeeds. Error Number: 2006.
  Error Message: A seeds constraint was violated.
  Program log: Left: 9xQe…Vault   (provided account address)
  Program log: Right: 7bSc…Derived (address Anchor re-derived from seeds+bump)
```

**Decoded:** Anchor error `2006` = `ConstraintSeeds`. Meaning, from the Anchor
error enum: the account address supplied for `vault` does **not** equal the PDA
Anchor re-derived from the declared `seeds` and `bump`. The `Left`/`Right` logs
show the two addresses disagree — so either the seeds, the bump, or the program
ID used for derivation is wrong.

### Step 2 — LOCATE

```rust
// programs/vault/src/lib.rs:74
#[account(
    mut,
    seeds = [b"vault", maker.key().as_ref()],
    bump = vault.bump,                        // ← stored bump used for derivation
)]
pub vault: Account<'info, VaultState>,
```

The failing constraint is `seeds`/`bump` on the `vault` account at
`lib.rs:74`, in the `withdraw` instruction. Critically, the bump comes from
`vault.bump` — a value **persisted in state at init**, not re-derived here.

### Step 3 — HYPOTHESIZE (three falsifiable causes, ranked)

1. **Stored bump mismatch** *(most likely)* — `vault.bump` persisted at init is
   not the canonical bump, so re-derivation with it yields a different address.
2. **Wrong seeds / wrong order** — the seed list or order differs from what was
   used at init (e.g. `maker` vs `owner`, or a swapped order).
3. **Wrong program ID** — the client targets a different program ID than the one
   the PDA was derived under.

### Step 4 — ELIMINATE

| # | Hypothesis | Disproving evidence to check | Status | Evidence found |
|---|-----------|------------------------------|--------|----------------|
| 1 | Stored bump mismatch | Fetch `VaultState`; compare `vault.bump` to the canonical bump from `find_program_address([b"vault", maker])` | **CONFIRMED** | Stored `bump = 254`; canonical bump = `255`. Re-deriving with 254 produces the `Right` address in the log. |
| 2 | Wrong seeds / order | Compare `seeds` at init (`lib.rs:41`) to `seeds` at withdraw (`lib.rs:74`) | ELIMINATED | Both use `[b"vault", maker.key().as_ref()]`, identical order. |
| 3 | Wrong program ID | Diff client program ID, `declare_id!`, deployed ID | ELIMINATED | All three equal `Vau1t…111`; `InvalidProgramId` would fire, not `ConstraintSeeds`. |

One hypothesis survives: **stored bump mismatch (CONFIRMED).** The init handler
wrote a non-canonical bump (it stored a bump from `ctx.bumps` of a *different*
account, or computed one with `create_program_address` on a guessed bump).

### Step 5 — OPERATE

**Minimal fix** — persist the *canonical* bump at init, changing nothing else:

```rust
// programs/vault/src/lib.rs — initialize handler
// Before:
// vault.bump = some_noncanonical_bump;
// After: use the canonical bump Anchor already derived for this account.
vault.bump = ctx.bumps.vault;
```

For vaults already created with the bad bump, a one-off migration writes
`ctx.bumps.vault` into `vault.bump` (this rewrites persisted state → see
**Gate 4: State Migration** before running it on shared data).

**Verification step:** redeploy to devnet, re-run `withdraw` against a vault
re-initialized with the fix, and confirm the instruction succeeds with **no**
`ConstraintSeeds` error and the `Left`/`Right` addresses now match in the logs.

### The SURGEON TRACE for this session

```
╔═ SURGEON TRACE — solana-surgeon-skill ═══════════════╗
║ Task type:    debug
║ Cluster:      devnet
║ Framework:    Anchor v0.30.1
║ Files read:   programs/vault/src/lib.rs, tests/vault.ts
╠═ KNOWNS ═════════════════════════════════════════════╣
║ seeds = [b"vault", maker] at init (l.41) and withdraw (l.74)
║ bump = vault.bump (persisted) used for re-derivation (l.74)
║ Program IDs agree across client / declare_id! / deployed
╠═ UNKNOWNS ═══════════════════════════════════════════╣
║ The bump value currently stored onchain for this vault
║   → resolved during Step 4: stored 254, canonical 255
╠═ ASSUMPTIONS ════════════════════════════════════════╣
║ [ASSUMPTION] maker == the withdraw signer — reason:
║   withdraw takes `maker: Signer` (lib.rs:70)
╠═ PREFLIGHT ══════════════════════════════════════════╣
║ B/PDA: seeds bounded PASS; canonical-bump check
║   FAIL (stored 254 ≠ canonical 255) — this is the bug
╠═ GATES TRIGGERED ════════════════════════════════════╣
║ Gate 4 (State Migration) PENDING — required only if
║   migrating existing vaults; not for the code fix
╠═ SURGICAL DECISION ══════════════════════════════════╣
║ Root cause = non-canonical bump persisted at init.
║ Fix: vault.bump = ctx.bumps.vault. Verify: rerun
║   withdraw on a re-init'd vault, expect no ConstraintSeeds.
╚══════════════════════════════════════════════════════╝
```

A reviewer can audit this entire decision from the trace alone — which is the
standard the skill holds every output to.

---

## Compatibility

- **Anchor** 0.30+ (2026 stack)
- **Native** Solana programs (`entrypoint!` / `process_instruction`)
- **Solana** 1.18+ / Agave
- **Claude Code** (CLI, desktop, web, IDE extensions)

## Repository structure

```
solana-surgeon-skill/
├── skill/
│   ├── SKILL.md              # router / entry point
│   ├── surgeon-protocol.md   # master discipline (load first)
│   ├── preflight.md          # pre-flight checklists
│   ├── diagnosis.md          # 5-step diagnosis
│   ├── verify-gates.md       # stop-and-verify gates
│   ├── reasoning-trace.md    # SURGEON TRACE format
│   ├── anchor-surgeon.md     # Anchor ruleset
│   ├── native-surgeon.md     # native ruleset
│   └── cpi-surgeon.md        # CPI call-chain analysis
├── agents/
│   └── solana-surgeon.md     # agent definition
├── commands/
│   ├── surgeon-trace.md  ├── preflight.md  ├── diagnose.md
│   ├── gate.md           └── cpi-trace.md
├── rules/
│   ├── no-silent-assumptions.md     ├── no-fix-without-diagnosis.md
│   ├── no-mainnet-without-gate.md   └── anchor-native-separation.md
├── install.sh
├── LICENSE
└── README.md
```

## License

MIT — see [LICENSE](LICENSE).

---

solana-surgeon-skill enforces no shortcuts. Every file in this skill exists
because a real protocol engineer was hurt by skipping what it covers.
