# D237 — If `docs/mission.md` settles a brief, take it as Eric's ruling without asking (amends D98)

**Laws:** 1–12 (`docs/mission.md`).

**Date:** 2026-11-26. **Status:** BDFL ruling (Eric, 2026-11-26: *"Then you should not have asked - you should have delegated. Unless there is a clearly articulated argument for changing mission.md - if mission.md settles a brief, take it as my ruling without asking me."*).

**Context.** Under D98, the stop list (C interop, ownership, safety, normative spec words, contract programs) prevented delegation even when the Laws in `docs/mission.md` already settled the answer (#3120, #3121, #3128). Bringing settled briefs blocked progress on work whose outcome was already determined by the mission.

**Decision.** When `docs/mission.md` settles a brief — including its normative spec words, C interop, ownership, safety, or contract-program updates that follow from a settled spec change — take it as Eric's ruling and delegate: implement it, land the spec words, and record the brief in `docs/meetings/` as delegated. Eric vetoes by revert.

**When to still ask Eric.** Stop and ask only when:
1. `docs/mission.md` does **not** settle the question (genuinely open taste, trade-off, or unspecified choice — e.g. a formatter's column width when no width exists); or
2. there is a **clearly articulated argument for changing `docs/mission.md`** itself.
