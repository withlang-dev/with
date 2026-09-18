# Primary verification — string cluster (`lib/std/str.w` + `lib/std/string.w` + `lib/std/alloc.w`)

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: str `d38fc0af817a95009881e51e7c426620ba6150a59d3a19225e2fa61b223d1bc6`;
string `48a751cd5e0b56167728fcf96c9e6f38d80ac0e850332f1e50df37e72fa77e9a`;
alloc `78c49a6e1078ee8e36c07c604488c3b6c07c0a663b3037d27fc68d2d5338d311`
Source examined: child all + rt/CodegenDispatch lowering + Mir kinds; primary:
doc block string.w:1-10 + TY_STR intrinsic table :7236-7251 (full reads),
is_empty abort re-run, ownership/utf8 probe re-runs below

## Scope examined

String ownership, indexing, method surface honesty.

Applicable overview targets examined: T5 (ownership), T10 (surface honesty), T23 (OOB).

## Behavioral matrix

- `p1_ownership.w`: concat/slice/split/clone/builder/replace/trim/case —
  all correct, rc=0, no aborts. Ownership exact (re-run by primary).
- `p2_index_utf8.w`: in-range 97; OOB high/neg/big → 0; OOR slice clamps —
  lenient-API choices, consistent, rc=0.
- `is_empty_ice.w` (primary): documented `s.is_empty()` → compiler BUG abort
  (core dump). Filed #1010.

## STR-001 — is_empty aborts the compiler (filed #1010)

Classification: **Confirmed compiler abort from documented API; #1010**
Severity: **High** — one-line call core-dumps the compiler
Confidence: **Very high** (doc-vs-table read + abort re-run)

Doc lists `is_empty`; table lacks the arm → NONE → generic-call lowering
hits the fatal contract assertion (MirLower.w:14570). Siblings all present —
one-arm omission. (Child's p3c2j/k variants corroborate across shapes.)

## Notes (no finding)

- byte_at-OOB→0 / slice-clamp / invalid-UTF8-passthrough are lenient but
  consistent API choices with no doc contradiction found — notes, not defects.
- alloc.w behavior corroborated through the ownership probes (no leaks/
  aborts across concat/split/clone/builder stress).
