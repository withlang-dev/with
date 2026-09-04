# Primary verification — `lib/std/re/pcre2_tables.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + bundle check)
Source revision: `450733e5`
Source examined: all 30 lines (single complete read).

## Scope examined

Pure re-export shim: 29 `use std.re.*` lines, zero declarations, zero
code. The real `_pcre2_default_tables_8` lives in `defs.w`; its content
is verified under `pcre2_maketables.w`/`defs.w`
(`maketables_bad=0`, `lccA=97`, `fcct=84` in `output_r1.txt`, plus prior
session probes T15b/T15c in `docs/audit/probes/pcre2_tables/`).

## Behavioral matrix

- No executable behavior by construction.
- `with-stage1 check lib/std/re/pcre2_tables.w` → `ok` (exit 0).
- Bundle check → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
