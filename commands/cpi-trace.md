<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill — construct the CPI call graph for the current instruction"
argument-hint: ""
---

Trigger **CPI call-graph construction** for the current instruction, part of
solana-surgeon-skill. Cross-program invocation is where the most dangerous Solana
bugs live — the surgeon traces every call chain before trusting it.

## Behavior

Load `skill/cpi-surgeon.md` and apply the CPI protocol to the instruction in
scope:

1. **Build the call graph** — `Caller → [ix] → Callee → [ix] → ...`. For each
   edge: accounts passed (with signer/writable flags), which accounts gain signer
   privilege via `invoke_signed` (and the seeds), whether the callee re-invokes,
   and whether the callee program ID is validated.
2. **Privilege escalation** — confirm `invoke_signed` seeds derive the intended
   PDA, and remember it signs *only* for that PDA, not the whole accounts array.
3. **Re-entrancy** — flag any A→B→A chain or any state written before a CPI that
   the CPI could invalidate.
4. **Account ordering** — confirm exact order/count/flags against the callee's
   processor or IDL.
5. **Return data** — validate length, document meaning and setting program,
   handle the absent case.

Draw the full graph before reasoning about any single edge. If a CPI crosses an
Anchor/native boundary, flag the crossing in the SURGEON TRACE.

## Loads
- `skill/cpi-surgeon.md`
