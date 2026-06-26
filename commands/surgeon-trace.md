<!--
SPDX-License-Identifier: MIT
solana-surgeon-skill — https://github.com/devIykee/solana-surgeon-skill
-->
---
description: "solana-surgeon-skill — toggle full SURGEON TRACE mode for the session"
argument-hint: "[on|off]"
---

Activate or deactivate **SURGEON TRACE mode** for the current session, part of
solana-surgeon-skill.

Argument: `$ARGUMENTS` — `on` (default if omitted) or `off`.

## Behavior

**On:** Load `skill/reasoning-trace.md`. From this point, every substantive
output in the session is preceded by a SURGEON TRACE header, written *before* the
output it justifies:

```
╔═ SURGEON TRACE — solana-surgeon-skill ═══════════════╗
║ Task type / Cluster / Framework / Files read         ║
╠═ KNOWNS / UNKNOWNS / ASSUMPTIONS ════════════════════╣
╠═ PREFLIGHT / GATES TRIGGERED ════════════════════════╣
╠═ SURGICAL DECISION ══════════════════════════════════╣
╚══════════════════════════════════════════════════════╝
```

Enforce the trace rules: UNKNOWNS is never empty when onchain state is involved;
ASSUMPTIONS never exceed three (otherwise stop and ask); the label line stays
exactly `SURGEON TRACE — solana-surgeon-skill`.

**Off:** Stop prepending the trace header. The underlying surgical discipline
(diagnosis, preflight, gates) remains active — only the visible trace is silenced.

## Loads
- `skill/reasoning-trace.md`
