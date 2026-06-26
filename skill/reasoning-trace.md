<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# Surgeon Trace
> solana-surgeon-skill reasoning trace format.
> Every decision the surgeon makes is logged. No black boxes.

The SURGEON TRACE is reasoning made visible. It is written **before** the output
it justifies, and it ships *with* that output so any engineer can audit the
decision from the trace alone — without re-deriving the agent's thinking.

---

## SURGEON TRACE format

```
╔═ SURGEON TRACE — solana-surgeon-skill ═══════════════╗
║ Task type:    [build | debug | deploy | audit | query]║
║ Cluster:      [devnet | testnet | mainnet | unknown]  ║
║ Framework:    [Anchor vX.Y.Z | native | unknown]      ║
║ Files read:   [list of files the agent actually read] ║
╠═ KNOWNS ═════════════════════════════════════════════╣
║ [facts confirmed from source or onchain]             ║
╠═ UNKNOWNS ═══════════════════════════════════════════╣
║ [facts the surgeon does not know]                    ║
╠═ ASSUMPTIONS ════════════════════════════════════════╣
║ [ASSUMPTION] [statement] — reason: [why assumed]     ║
╠═ PREFLIGHT ══════════════════════════════════════════╣
║ [checklist items run + PASS/FAIL]                    ║
╠═ GATES TRIGGERED ════════════════════════════════════╣
║ [any gates that fired + confirmation status]         ║
╠═ SURGICAL DECISION ══════════════════════════════════╣
║ [what the surgeon decided and the key reason]        ║
╚══════════════════════════════════════════════════════╝
```

The box-drawing characters are not decoration — they make the trace
grep-able and visually unmistakable in a scroll of agent output. Keep the
label line exactly as written.

---

## Field-by-field contract

- **Task type** — one of `build | debug | deploy | audit | query`. Picked in
  Step 1 of the surgical stack; drives which sub-skills loaded.
- **Cluster** — `devnet | testnet | mainnet | unknown`. If `unknown`, the
  mainnet gate is in force (Gate 5). Never leave this blank.
- **Framework** — `Anchor vX.Y.Z | native | unknown`. Record the detected
  version when known (e.g. `Anchor v0.30.1`); it determines which surgeon
  ruleset applies.
- **Files read** — the files the agent *actually opened* this task, not files it
  guessed about. If a fact came from a file, that file is listed here.
- **KNOWNS** — facts confirmed from source or onchain state, each traceable to a
  file+line or a decoded account.
- **UNKNOWNS** — facts the surgeon does not know. See the rules below.
- **ASSUMPTIONS** — each tagged `[ASSUMPTION]`, with a stated reason. See the
  rules below.
- **PREFLIGHT** — which checklist(s) ran and the PASS/FAIL of each box. Empty
  only when no onchain interaction is involved.
- **GATES TRIGGERED** — every gate that fired, with status `PENDING /
  CONFIRMED / DECLINED` and (for the mainnet gate) a timestamp.
- **SURGICAL DECISION** — the decision and its single key reason. This is the
  line a reviewer reads first.

---

## Rules

- **UNKNOWNS must never be empty if the task involves onchain state.** Onchain
  reality always exceeds what the agent has fetched (latest account state, the
  current cluster slot, who holds an authority right now). If the surgeon claims
  to know everything, that is suspicious — flag it explicitly with a note like
  `[no unknowns claimed — verify this is not overconfidence]`.
- **ASSUMPTIONS must never exceed 3.** If more than three assumptions are
  required to proceed, the surgeon **stops and asks for clarification** instead
  of stacking guesses. Three assumptions is the ceiling of acceptable
  uncertainty for an irreversible domain.
- **The trace is written BEFORE the output, not after.** It is the reasoning that
  produces the decision, not a justification retrofitted to it. If the trace and
  the output disagree, the output is wrong.
- **Label exactly `SURGEON TRACE — solana-surgeon-skill`** so traces are
  identifiable in logs that mix output from multiple skills.

---

## Minimal filled example

```
╔═ SURGEON TRACE — solana-surgeon-skill ═══════════════╗
║ Task type:    debug
║ Cluster:      devnet
║ Framework:    Anchor v0.30.1
║ Files read:   programs/escrow/src/lib.rs, tests/escrow.ts
╠═ KNOWNS ═════════════════════════════════════════════╣
║ Vault PDA seeds are [b"vault", maker] (lib.rs:51)
║ Stored bump persisted in VaultState.bump (lib.rs:88)
╠═ UNKNOWNS ═══════════════════════════════════════════╣
║ The bump value currently stored onchain for this vault
║ Whether the client re-derives or reuses a cached bump
╠═ ASSUMPTIONS ════════════════════════════════════════╣
║ [ASSUMPTION] maker == provider.wallet — reason: test
║   signs with the default wallet (escrow.ts:12)
╠═ PREFLIGHT ══════════════════════════════════════════╣
║ B/PDA: seeds bounded PASS; canonical bump PASS;
║   stored-bump-match FAIL (stored 254 ≠ canonical 255)
╠═ GATES TRIGGERED ════════════════════════════════════╣
║ none (read-only diagnosis)
╠═ SURGICAL DECISION ══════════════════════════════════╣
║ Root cause = stale stored bump. Fix: persist canonical
║   bump. Verify: rerun withdraw, expect no ConstraintSeeds.
╚══════════════════════════════════════════════════════╝
```

A reviewer who reads only this box can reconstruct the entire decision — that is
the standard the trace must meet.
