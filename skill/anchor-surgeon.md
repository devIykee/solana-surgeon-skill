<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# Anchor Surgical Rules
> solana-surgeon-skill rules for Anchor programs (0.30+, 2026 stack).
> Load when: Anchor.toml present OR #[program] macro detected.

Anchor moves account validation into declarative `#[account(...)]` constraints.
That is a gift and a trap: a constraint you forget is a check that never runs.
The surgeon reads every constraint as an explicit invariant and knows precisely
what fails, where, and when.

---

## 1. Account constraint precision

For every constraint in `#[account(...)]`, the surgeon states three things: the
**invariant** it enforces, the **error** that fires on failure, and **when** it
is checked (at account deserialization vs. at instruction entry).

| Constraint | Invariant enforced | Error on failure | Checked |
|------------|--------------------|------------------|---------|
| `mut` | Account is writable; changes will persist | `ConstraintMut` | Deserialization |
| `signer` | Account signed the transaction | `ConstraintSigner` | Deserialization |
| `init` | Account is created + funded + owner set + discriminator written | `AccountAlreadyInitialized` (if exists) / funding errors | Instruction entry |
| `init_if_needed` | Inits only if not already initialized | re-init / funding errors | Instruction entry |
| `seeds` + `bump` | Address equals the PDA derived from these seeds | `ConstraintSeeds` | Deserialization |
| `has_one = x` | `account.x == x_account.key()` | `ConstraintHasOne` | Deserialization |
| `constraint = expr` | Arbitrary boolean `expr` holds | `ConstraintRaw` | Deserialization |
| `close = dest` | Account closed, lamports → `dest`, data zeroed | (closure logic) | Instruction exit |
| `realloc` | Account resized; delta funded/refunded, optionally zeroed | realloc errors | Instruction entry |

- **`init_if_needed` is the sharpest tool here.** It silently does nothing when
  the account exists — which means an attacker-supplied, already-initialized
  account skips your init logic. Treat every `init_if_needed` as a place to add
  an explicit post-condition check, and gate against re-initialization attacks.
- **`bump` without a stored bump** re-derives the canonical bump each time;
  **`bump = state.bump`** trusts a persisted value — and a wrong persisted value
  produces `ConstraintSeeds`. Know which form you are reading.

---

## 2. Discriminator hygiene

- **Never manually set discriminators.** Anchor writes them on `init`; a
  hand-set discriminator corrupts type identity.
- **Always verify the discriminator before assuming an account type.** Loading an
  account as the wrong type because its 8 prefix bytes were not checked is a
  classic confusion bug.
- **Watch for discriminator collisions** in custom account types — distinct
  account names with the same first 8 hash bytes are vanishingly rare but
  catastrophic; if you define account types dynamically, confirm uniqueness.
- **Document the derivation:** an account discriminator is
  `sha256("account:" + AccountStructName)[..8]`; an instruction discriminator is
  `sha256("global:" + instruction_name)[..8]`. Knowing this lets you decode raw
  bytes by hand during diagnosis.

---

## 3. IDL discipline

- **Any change to account fields, instruction args, or error codes is a breaking
  IDL change.** Flag it as such — every client built against the old IDL will
  mis-encode or mis-decode.
- **Never deploy with IDL drift** — code and IDL disagreeing means clients send
  instructions the program no longer accepts (`InstructionFallbackNotFound`) or
  decode accounts wrong (`InvalidAccountData`).
- **After any struct change, regenerate the IDL before testing.** Testing against
  a stale IDL produces failures that point at the wrong cause and burn a
  diagnosis cycle.

---

## 4. Anchor version footguns (2024–2026)

- **`init_if_needed` requires the `init-if-needed` feature flag** on
  `anchor-lang`. Without it the program will not compile; with it, you inherit
  the re-init responsibility described in §1.
- **Account compression** (compressed NFTs / concurrent merkle trees) requires
  the `spl-account-compression` crate and is *not* part of core Anchor — its
  accounts are not your program's accounts and follow different validation.
- **Anchor 0.30 changed constraint and codegen semantics.** Notable shifts the
  surgeon checks for when reading 0.30+ code:
  - The new IDL format and program-side `declare_program!` / generated client
    differ from pre-0.30 layouts — old tooling assumptions break.
  - `#[account]` codegen and discriminator handling were updated; do not assume
    a pre-0.30 mental model of generated accounts still holds.
  - `Program`/`Sysvar`/`Interface` account types tightened — confirm the exact
    wrapper type a constraint expects.
  When in doubt, pin the version from `Cargo.toml` / `Anchor.toml` into the
  SURGEON TRACE Framework field and read the constraint codegen for that version
  rather than from memory.
- **Zero-copy accounts (`#[account(zero_copy)]`) require `bytemuck`** and
  `AccountLoader`. They are `repr(C)`, are not Borsh-deserialized, and have
  strict alignment/padding rules — mixing a zero-copy account into Borsh
  deserialization logic is a layout bug.

---

This file governs Anchor context only. For native programs, load
`native-surgeon.md`; for CPI call chains (Anchor or native), load
`cpi-surgeon.md`. Never apply these constraint patterns to a native program
without flagging the framework boundary in the trace.
