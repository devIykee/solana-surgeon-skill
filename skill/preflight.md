<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# Surgical Pre-Flight
> solana-surgeon-skill pre-operative checklist.
> The surgeon checks before every procedure. No exceptions.

Four checklists, each loadable independently. Load only the one that matches the
operation in front of you (the `/preflight` command takes the type as an
argument). Every checklist ends with the same contract: **PASS** means proceed,
**FAIL** means stop — do not build, sign, or submit anything until the failing
item is resolved or explicitly waived in the SURGEON TRACE.

A checklist item is only "checked" when you have **evidence** — a line of source,
a decoded onchain account, a CLI output. A checkbox ticked from memory or
assumption is a surgical failure. If you cannot gather the evidence, mark the
item `UNKNOWN`, record it under UNKNOWNS in the trace, and treat it as FAIL.

---

## CHECKLIST A — ACCOUNT VALIDATION PRE-FLIGHT

Run once per account involved in the instruction.

```
□ Is this account owned by the expected program?
□ Is the discriminator correct (Anchor) or the data layout correct (native)?
□ Is the account marked writable if it will be modified?
□ Is the account marked as signer if it must authorize?
□ Is the account rent-exempt, or is rent being paid in this instruction?
□ Is the account's lamport balance sufficient for the operation?
□ Does the account exist onchain, or is it being created in this tx?
```

- **How to run it:** Fetch each account with `getAccountInfo` (or `solana account
  <pubkey>`). Read `owner`, `lamports`, and `data`. Cross-check `is_signer` /
  `is_writable` against the instruction's account metas in the client. For
  existence-vs-creation, confirm whether an `init`/`create_account` step targets
  this address earlier in the same transaction.
- **PASS:** Every box is checked with evidence; ownership, flags, and rent all
  match the operation's needs.
- **FAIL:** Any box unchecked or contradicted — e.g. owner is the System Program
  when you expected your program, the account is read-only but the instruction
  mutates it, or balance is below rent-exempt minimum with no funding step.
- **On failure:** STOP. Do not build the instruction. Name the failing account
  and box in the trace, fix the account setup, and re-run the checklist.

---

## CHECKLIST B — PDA DERIVATION PRE-FLIGHT

Run before using any program-derived address.

```
□ List all seeds explicitly (type, order, value)
□ List the program ID used for derivation
□ Verify the bump seed matches what is stored in the program's state
□ Confirm canonical bump (find_program_address, not create_program_address)
□ Check that seeds are bounded (no unbounded string/vector seeds)
□ Verify no seed collision is possible with another PDA in the same program
```

- **How to run it:** Read the seeds directly from program source — the
  `seeds = [...]` constraint (Anchor) or the `find_program_address(&[...], ...)`
  call (native). Re-derive the address yourself and compare to the address being
  used. Confirm the bump matches the stored bump (if the program persists one).
  Enumerate other PDAs in the program and confirm their seed prefixes cannot
  collide with this one.
- **PASS:** Re-derived address equals the address in use; bump is canonical and
  matches stored state; seeds are bounded and collision-free.
- **FAIL:** Derived address differs, bump is non-canonical or mismatched, a seed
  is an unbounded user string, or two PDAs could derive to the same address.
- **On failure:** STOP. This is the single most common Solana bug class. Do not
  paper over it by changing the client — diagnose which side is wrong
  (`diagnosis.md`) before any change.

---

## CHECKLIST C — TRANSACTION PRE-FLIGHT

Run before building or submitting any transaction.

```
□ Confirm the target cluster (devnet / testnet / mainnet-beta) explicitly
□ Confirm the fee payer has sufficient SOL including priority fees
□ Confirm instruction ordering is correct (init before use)
□ Confirm compute budget is set if instructions are complex
□ Confirm no account is listed twice with conflicting constraints
□ Confirm all required signers are available and will sign
```

- **How to run it:** Print the RPC endpoint and resolve it to a named cluster —
  never assume. Check the fee payer balance against the worst-case fee plus
  priority fee. Walk the instruction list in order and confirm every account is
  created/initialized before it is read or written. Sum compute usage; add a
  `ComputeBudget` instruction if any instruction is non-trivial. Scan account
  metas for duplicates with conflicting `is_writable`/`is_signer`.
- **PASS:** Cluster is named and intended; payer funded; ordering valid; signers
  present; no conflicting duplicate accounts.
- **FAIL:** Cluster unknown or unexpected, payer underfunded, a use-before-init,
  a duplicate account with conflicting flags, or a missing signer.
- **On failure:** STOP. If the failing box is the **cluster** check and the
  cluster resolves to mainnet-beta (or stays unknown), escalate to the mainnet
  gate in `verify-gates.md` before anything else.

---

## CHECKLIST D — PROGRAM DEPLOYMENT PRE-FLIGHT

Run before any deploy or upgrade.

```
□ Confirm the program ID matches declare_id! in source
□ Confirm the buffer account has sufficient lamports
□ Confirm the upgrade authority is the correct keypair
□ Confirm the program is built with the correct feature flags / Solana version
□ Confirm the IDL will be updated if this is Anchor
□ Confirm this is NOT mainnet unless explicitly authorized
```

- **How to run it:** Diff the deployed program ID, the `declare_id!` in source,
  and any client-side constant — all three must agree. Check buffer lamports
  against program size. Confirm the upgrade authority via `solana program show
  <program_id>` and match it to the signing keypair. Verify the build toolchain
  (Anchor/Solana/Agave version, feature flags). For Anchor, confirm the IDL is
  regenerated and will be published.
- **PASS:** IDs agree, buffer funded, authority correct, build verified, IDL in
  sync, and the target is a non-mainnet cluster or has explicit mainnet
  authorization.
- **FAIL:** Any ID mismatch, underfunded buffer, wrong/lost authority, stale
  build, IDL drift, or an unauthorized mainnet target.
- **On failure:** STOP immediately. A deploy is irreversible in effect — a wrong
  program ID or lost authority can brick the program. If the target is mainnet,
  the deployment gate (`verify-gates.md`, Gate 3 + Gate 5) is mandatory and must
  pass before this checklist is considered complete.

---

**Preflight discipline:** record which checklist ran and the PASS/FAIL of each
box in the trace's PREFLIGHT section. A passed preflight that was never written
down did not happen — the audit trail is part of the procedure.
