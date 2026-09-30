# Parallel sema: the body-checking field inventory (2026-09-30)

Working notes from the S2a campaign (order-independent body checking, then
parallel sema; see `docs/handoff.md`). Not normative.

- `all.tsv` — every Sema field body checking writes (name, type), the input
  to the classification.
- `result0.tsv` — classification of the first chunk (per-body scratch,
  per-node result, grow table, cross-body read).
- `notes.md` — the key facts per chunk: which tables grow during bodies,
  which reads cross bodies, which names embed TypeIds, which scratch is never
  cleared. The per-field tables for chunks 1–7 were produced in-session and
  are summarized here, not reproduced.
