# Primary verification — `tools/with-sha256.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-tools-misc (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 38 lines (single complete read)

## Scope examined

`sha256sum`-equivalent over `std.crypto.sha256`: `sha256_text`
(`:18`-`:21`, hash str then hex), `ewrite` stderr helper avoiding the
pre-flip prelude I/O (`:24`-`:26`, see #747 bootstrap note `:4`-`:12`),
`main` loop (`:28`-`:38`) — usage/exit-1 on no args, per-file
existence gate with `missing file` error/exit-1, `<hex>  <path>` per
file on stdout. Custom extern decls (`:13`-`:16`) deliberately avoid
prelude runtime symbols the seed still declares pre-flip.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED, `with-stage1 check tools/with-sha256.w` → ok (exit 0).
  Saved: `docs/audit/probes/tools_with_sha256/check.txt`.
- EXECUTED, hash oracle: `with run tools/with-sha256.w fixture.txt`
  → `72a81919...404e78d4e  .../fixture.txt`, exit 0 — BYTE-EXACT match
  with `sha256sum` on the same file (independent, OpenSSL-backed oracle).
  Saved: `docs/audit/probes/tools_with_sha256/hash.txt`, `fixture.txt`.
- EXECUTED, missing file → `with-sha256: missing file: .../nope.txt`,
  exit 1. Saved: `missing.txt`.
- EXECUTED, no-args → `usage: with-sha256 <file>...`, exit 1.
  Saved: `noargs.txt`.
- HELD: multi-file loop (single-file exercises the same loop body;
  no separate path).

## Findings

None. In-report notes (not filed):
- The #747 bootstrap note is load-bearing pinned context: if a reseed
  carries the str flip, the custom decls/`ewrite` workaround becomes
  dead weight — the note itself says so. Not a defect today.

Verdict: COMPLETE
