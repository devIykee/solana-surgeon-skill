<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill — run the 5-step surgical diagnosis on a Solana error"
argument-hint: "\"[error string]\""
---

Initiate the **5-step surgical diagnosis** for the given error, part of
solana-surgeon-skill. The surgeon diagnoses before cutting — never cuts to
diagnose.

Argument: `$ARGUMENTS` — the error string, ideally with program logs.
Example: `/diagnose "Error: ConstraintSeeds"`

## Behavior

Load `skill/diagnosis.md` and run all five steps **in order, none skippable**:

1. **COLLECT** — read the full error; decode the code against the program's error
   enum or IDL. Output: raw error + decoded meaning, with the decoding source
   cited.
2. **LOCATE** — identify the exact instruction/account/constraint that fired.
   Output: file + line + constraint/check name.
3. **HYPOTHESIZE** — exactly three falsifiable hypotheses, ranked by likelihood.
4. **ELIMINATE** — for each, the disproving evidence; check it; produce the
   hypothesis table with CONFIRMED / ELIMINATED and the deciding evidence.
5. **OPERATE** — only after one hypothesis is CONFIRMED, propose a minimal fix
   plus a concrete verification step.

**Do not propose a fix before Step 4 is complete** (enforced by
`rules/no-fix-without-diagnosis.md`). Use the error reference table in
`skill/diagnosis.md` §2 to seed hypotheses — not to skip Steps 1–2. Attach the
diagnosis artifact to the SURGEON TRACE.

## Loads
- `skill/diagnosis.md`
