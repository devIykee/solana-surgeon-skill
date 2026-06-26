<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->

# CPI Surgical Analysis
> solana-surgeon-skill CPI protocol.
> Cross-program invocation is where the most dangerous Solana
> bugs live. The surgeon traces every call chain before trusting it.

A cross-program invocation hands your accounts — and sometimes your signing
authority — to another program. The surgeon never trusts a callee it has not
mapped, and never assumes a privilege it has not verified.

---

## 1. CPI trace protocol

Before executing or analyzing any CPI, construct an explicit call graph:

```
Caller → [instruction] → Callee → [instruction] → ...
```

For **each edge** in the graph, answer:

- **What accounts are passed?** List them with their `is_signer` / `is_writable`
  flags as the callee will see them.
- **Which accounts gain signer privilege via `invoke_signed`?** Name the exact
  PDA(s) and the seeds used.
- **Does the callee re-invoke?** If the callee makes its own CPIs, extend the
  graph — a two-hop chain hides three-hop risk.
- **Is the callee program ID validated?** Confirm the program account passed
  equals the expected program ID; never CPI into an address supplied by an
  untrusted account.

Draw the full graph before reasoning about any single edge. A chain understood
one hop at a time is a chain not understood.

---

## 2. Privilege escalation checks

- **PDA signer seeds must match exactly.** List the seeds (type, order, value)
  used in `invoke_signed` and confirm they derive the PDA you intend to sign for.
- **`invoke_signed` grants signer privilege ONLY for the derived PDA** — not for
  any other account in the accounts array. A common misbelief is that
  `invoke_signed` "signs the whole CPI"; it does not. Every *other* account that
  needs to sign must already be a signer on the outer transaction.
- **If the callee modifies accounts the caller passed, trace what state changes
  propagate back.** After the CPI returns, the caller's view of those accounts
  reflects the callee's writes — re-read them before relying on pre-CPI values.

---

## 3. Re-entrancy analysis

Solana's runtime forbids *direct* self-recursion within a single instruction, but
**indirect re-entrancy through a chain is possible**. Flag any CPI chain where:

- **Program A calls Program B which calls back into Program A.** Even mediated by
  B, this re-enters A's logic with A's accounts possibly mid-mutation.
- **State is modified before the CPI and the CPI could invalidate it.** If A
  writes a balance, then CPIs to B, and B (directly or transitively) changes the
  same account, A's post-CPI assumptions are stale. Read-after-CPI, or move the
  write after the CPI, or take a lock-style guard flag.

The runtime's max CPI depth (4) and the no-direct-reentrancy rule are *not* a
substitute for this analysis — they bound the shape, not the hazard.

---

## 4. CPI account ordering

- **Never assume ordering is flexible.** A callee reads its accounts positionally
  (native) or by IDL order (Anchor CPI). One transposed account is a different
  instruction.
- **Always read the target program's instruction processor or IDL** to confirm
  the exact account order, count, and per-account flags the callee expects —
  then assemble the CPI account list to match precisely.

---

## 5. Return data handling

If the CPI returns data via `set_return_data` / `get_return_data`:

- **Validate return data length before reading.** A shorter-than-expected buffer
  means the callee did not set what you assume; decoding it blindly reads garbage.
- **Document what the return data represents** — its type, units, and which
  program set it (`get_return_data` returns the setting program ID; confirm it
  is the callee you expect, not a deeper hop).
- **Handle the absent case.** `get_return_data` returns `None` when nothing was
  set. Treat absence as a real branch, not an impossibility.

---

CPI analysis applies to both Anchor and native programs. The framework-specific
account rules live in `anchor-surgeon.md` and `native-surgeon.md`; this file
governs the call chain that crosses between programs. When a CPI crosses an
Anchor/native boundary, flag the crossing in the SURGEON TRACE.
