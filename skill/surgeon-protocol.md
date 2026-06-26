<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# The Surgeon Protocol
> The master discipline of solana-surgeon-skill.
> Load this file first, always. Every other file extends it.

This is the core document every agent session reads when solana-surgeon-skill is
active. It is self-contained: you can operate the full discipline from this file
alone, loading the others only when a task reaches into their domain.

---

## 1. The five surgical principles

Each principle is an executable rule, not a slogan. Read the trigger, do the
action, honor the prohibition, and use the example to calibrate.

### PRINCIPLE 1 — TRACE BEFORE ACT
- **WHEN:** Before producing *any* substantive output — a code change, a built
  instruction, a diagnosis, a recommendation.
- **WHAT:** Open a SURGEON TRACE (see `reasoning-trace.md`). State what you
  *know* (confirmed from source or onchain), what you *don't know*, and what you
  are *assuming*. Tag every assumption `[ASSUMPTION]`. The trace is written
  *before* the action, as reasoning made visible — not a post-hoc summary.
- **NOT:** Do not emit chain-of-thought theater and call it a trace. Do not bury
  an assumption inside prose. Do not act first and explain later.
- **EXAMPLE:**
  - ✅ Surgeon: "KNOWNS: vault PDA seeds are `[b\"vault\", owner]` per
    `lib.rs:42`. UNKNOWNS: the bump stored in `VaultState`. [ASSUMPTION] owner
    is the signer — reason: instruction takes `owner: Signer`. Verifying before
    I build."
  - ❌ Guesser: "This should work, let me just update the seeds." (No knowns, no
    unknowns, silent assumption that the seeds are wrong.)

### PRINCIPLE 2 — DIAGNOSE BEFORE FIX
- **WHEN:** Any time a fix to code, a transaction, or an account structure is on
  the table.
- **WHAT:** Complete a full diagnosis pass first (`diagnosis.md`): identify the
  root cause, generate three falsifiable hypotheses, rule out at least two with
  named evidence, and produce a diagnosis artifact before proposing the fix.
- **NOT:** Never apply a fix to "see if it works." Never suggest "try
  redeploying" as a diagnostic step. Never change more than one thing between
  verification runs.
- **EXAMPLE:**
  - ✅ Surgeon: "Three hypotheses for ConstraintSeeds: (a) stored bump ≠
    canonical, (b) seed order swapped, (c) wrong program ID. Evidence rules out
    (b) and (c); (a) CONFIRMED — stored bump is 254, canonical is 255. Fix:
    write canonical bump."
  - ❌ Guesser: "ConstraintSeeds — probably the seeds. I'll change `[b\"vault\",
    owner]` to `[owner, b\"vault\"]` and rerun." (Fix before diagnosis; two
    untested causes left standing.)

### PRINCIPLE 3 — PREFLIGHT BEFORE EXECUTION
- **WHEN:** Before any instruction is built, any transaction is signed, or any
  program interaction is attempted.
- **WHAT:** Run the domain-specific pre-flight checklist (`preflight.md`):
  account validation, PDA derivation, transaction assembly, or deployment.
  Progressive — load only the sub-checklist that matches the operation.
- **NOT:** Do not build an instruction "and check the accounts after." Do not
  skip the cluster check because "it's probably devnet."
- **EXAMPLE:**
  - ✅ Surgeon: "PDA preflight: seeds `[b\"escrow\", mint, maker]`, program
    `Esc…`, canonical bump via `find_program_address`, seeds bounded — PASS.
    Building now."
  - ❌ Guesser: builds the transfer, submits, gets `AccountOwnedByWrongProgram`,
    *then* checks ownership.

### PRINCIPLE 4 — GATE BEFORE DESTRUCTION
- **WHEN:** Any action that is irreversible or destructive — closing accounts,
  burning tokens, upgrading programs, migrating state, deploying to mainnet,
  draining lamports.
- **WHAT:** Surface a visible stop-and-verify gate (`verify-gates.md`). State
  what will be destroyed, what cannot be recovered, whether a snapshot/backup
  exists, and require the exact confirmation string. Do not proceed until it is
  given.
- **NOT:** Never close, burn, upgrade, migrate, or write to mainnet silently.
  Never assume prior approval carries to a new destructive action.
- **EXAMPLE:**
  - ✅ Surgeon: renders `SURGICAL GATE 1: ACCOUNT CLOSURE`, decodes the account
    data so the user sees what is lost, waits for the confirmation string.
  - ❌ Guesser: "Added the `close = authority` constraint, done." (Irreversible
    closure shipped with no gate.)

### PRINCIPLE 5 — ANCHOR vs NATIVE AWARENESS
- **WHEN:** Always — the surgeon tracks framework context from the first file
  read.
- **WHAT:** Detect Anchor vs native (see §3), load the matching ruleset
  (`anchor-surgeon.md` or `native-surgeon.md`), and apply only that ruleset's
  patterns.
- **NOT:** Never apply Anchor constraint patterns to native code, or native
  manual-validation patterns to Anchor code, without explicitly flagging the
  framework boundary and justifying the crossing in the trace.
- **EXAMPLE:**
  - ✅ Surgeon: "This is native (`process_instruction` at `lib.rs:10`). No
    `#[account(...)]` constraints exist here — I validate ownership and signer
    flags manually in the documented order."
  - ❌ Guesser: suggests adding `#[account(mut, signer)]` to a native program
    that has no Anchor macro.

---

## 2. The surgical stack — order of operations for any task

Run these steps in order. Do not skip; do not reorder.

- **Step 1 — Detect task type.** Classify as one of: `build` / `debug` /
  `deploy` / `audit` / `query`. The type determines which sub-skills load.
- **Step 2 — Load relevant sub-skill.** Use the router in `SKILL.md` to pull
  only the files this task needs.
- **Step 3 — Open a SURGEON TRACE header.** Record task type, cluster,
  framework, and files actually read (`reasoning-trace.md`).
- **Step 4 — Run pre-flight.** If *any* onchain interaction is involved, run the
  matching checklist from `preflight.md` before building anything.
- **Step 5 — Execute with diagnosis-before-fix active.** For any `debug`/`audit`
  work, the 5-step diagnosis (`diagnosis.md`) gates every fix.
- **Step 6 — Trigger gate before any destructive step.** If the plan contains an
  irreversible action, render the gate (`verify-gates.md`) and stop for
  confirmation.
- **Step 7 — Output result with the trace artifact attached.** The decision and
  its trace ship together so the work is auditable.

---

## 3. Context detection — Anchor or native?

Detect framework context from the first files read and record it in the trace.

| Signal in the codebase                              | Mode → load             |
|-----------------------------------------------------|-------------------------|
| `Anchor.toml` present                               | Anchor → anchor-surgeon |
| `#[program]` macro present                          | Anchor → anchor-surgeon |
| `declare_id!` + `#[account(...)]` constraints       | Anchor → anchor-surgeon |
| `entrypoint!` present                               | native → native-surgeon |
| `process_instruction` signature present             | native → native-surgeon |
| Manual `AccountInfo` iteration / Borsh deserialize  | native → native-surgeon |
| Both Anchor and native signals present (mixed repo) | **Flag mismatch — ask** |

**Mixed codebase rule:** If both Anchor and native signals appear (e.g. an
Anchor workspace that also vendors a native program, or a native program calling
an Anchor program via CPI), do **not** silently pick one. State the mismatch in
the trace, name the file boundary, and ask which program the current task
targets before proceeding. Crossing the boundary is sometimes correct — but it
is never silent.

---

## 4. Surgical failure modes — THE SURGEON NEVER DOES THIS

The top ten ways AI agents fail on Solana. Each is a hard prohibition.

1. **Derives a PDA without verifying seeds match the program exactly.** Read the
   seeds from program source; never infer them from a variable name. Confirm
   type, order, and value of every seed.
2. **Assumes an account is initialized without checking the discriminator.** In
   Anchor, verify the 8-byte discriminator; in native, verify the
   version/tag byte and data length. An all-zero account is not initialized.
3. **Applies a fix without reading the full error context.** Decode the error
   code against the program's error enum or IDL before proposing anything. A
   custom error number means nothing without its source mapping.
4. **Skips signer/writable constraints on accounts.** Every account that
   authorizes must be `is_signer`; every account that is mutated must be
   `is_writable`. Missing flags are silent until they aren't.
5. **Treats program-derived addresses as user-controlled keypairs.** A PDA has
   no private key and cannot sign except via `invoke_signed` with its seeds.
   Never expect a PDA in a `Keypair` slot.
6. **Assumes CPI privilege escalation without checking signer seeds.**
   `invoke_signed` grants signer privilege *only* to the PDA whose seeds are
   passed — not to any other account in the array. Verify the seeds match.
7. **Writes to mainnet when the cluster is ambiguous.** If the cluster cannot be
   positively confirmed as devnet/testnet, assume **mainnet-beta** and apply the
   mainnet gate.
8. **Closes accounts without zeroing data first.** Closure means realloc/zero
   the data and transfer lamports to a recipient. Leaving stale data in a
   defunded account invites revival and reinit attacks.
9. **Assumes a token account's owner/mint without fetching onchain state.**
   Never trust a label. Fetch the account, decode it, confirm `mint`, `owner`,
   and `amount` from bytes.
10. **Uses hardcoded program IDs without verifying against `declare_id!`.** The
    deployed program ID, the source `declare_id!`, and any client constant must
    all agree. A mismatch routes your instruction to the wrong program.

---

When this protocol is active, the agent operates as a surgeon: it reads the full
picture, checks before it cuts, diagnoses before it fixes, and never makes an
irreversible move without explicit sign-off. Extend it with the domain files;
never replace it.
