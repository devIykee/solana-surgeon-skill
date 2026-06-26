<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# Native Surgical Rules
> solana-surgeon-skill rules for native Solana programs.
> Load when: entrypoint! or process_instruction detected.

Native programs have no `#[account(...)]` safety net — every check Anchor would
generate, you write by hand, in the right order, or it does not happen. The
surgeon validates everything explicitly and never deserializes data it has not
first measured.

---

## 1. Account info validation order (non-negotiable sequence)

Validate each account in this exact order. Skipping or reordering opens a hole.

```
a. Check the account count matches the expected number
b. Check account keys against expected addresses (PDAs, known programs)
c. Check account ownership (the owner field)
d. Check is_signer and is_writable flags
e. Check data length before deserialization
f. Deserialize and check the discriminator / version byte if present
```

- **(a) count first:** indexing into `accounts` before confirming length panics
  or reads the wrong account. Use `next_account_info` against a known-length
  iterator.
- **(b) keys:** confirm fixed addresses (system program, token program,
  sysvars) and re-derive PDAs to confirm the supplied address.
- **(c) ownership before trust:** an account is only your program's state if its
  `owner` is your program ID. The system program owns uninitialized accounts.
- **(d) flags before effect:** an account you will mutate must be `is_writable`;
  an account that authorizes must be `is_signer`. Check before you act on either.
- **(e) length before bytes:** never deserialize without first confirming
  `data.len()` is at least the struct's expected size.
- **(f) discriminator/version last:** if your layout carries a tag or version
  byte, verify it before treating the bytes as a given struct version.
- **Deviation from this order must be justified in the SURGEON TRACE** with the
  reason and what compensating check covers the gap.

---

## 2. Borsh deserialization safety

- **Always check data length before deserializing.** A short buffer turns a
  deserialize into an error or, worse, a partial read.
- **Use `try_from_slice_unchecked` only with an explicit length check** in front
  of it. The `_unchecked` variant tolerates trailing bytes; it does not excuse
  you from validating the prefix length.
- **Never assume the data layout** — read the full struct definition and confirm
  field order and types match the bytes you are decoding. A field added in a
  newer program version shifts every offset after it.
- **Watch for padding bytes in packed/`repr(C)` structs.** Alignment padding is
  real bytes on chain; off-by-padding errors corrupt the field after the gap.

---

## 3. CPI safety (native context — full treatment in cpi-surgeon.md)

This section is the *native-context pointer* only. For the full CPI protocol —
call-graph construction, privilege escalation, re-entrancy, account ordering, and
return data — load **`cpi-surgeon.md`**. In native code specifically:

- **Never invoke a CPI without validating the target program ID** against the
  expected program. A wrong callee ID routes your accounts to an attacker.
- **Always pass signer seeds explicitly** for PDA signers via `invoke_signed`;
  the seeds must match the PDA's derivation exactly.
- **Check that the CPI accounts match what the target program expects** — order,
  count, and writable/signer flags — by reading the callee's instruction
  processor or IDL, not by assumption.

---

## 4. Entrypoint discipline

- **`process_instruction` validates all accounts before any state change.**
  Complete the §1 validation sequence first; do not write a single byte until
  every account has passed.
- **Use early returns on validation failure**, not deep nested conditionals. A
  flat `if invalid { return Err(...) }` ladder is auditable; a pyramid of nested
  `if`s hides the path where a check was skipped.
- **Log meaningful error context with `msg!` before returning an error.** A bare
  `ProgramError::Custom(0)` with no log forces the next engineer to guess; a
  `msg!("vault owner mismatch: expected {} got {}", …)` makes Step 2 of
  diagnosis trivial.

---

This file governs native context only. For Anchor programs, load
`anchor-surgeon.md`. Never apply Anchor constraint macros to native code, or
native manual-validation patterns to Anchor code, without flagging the framework
boundary in the trace.
