# Primary verification — `lib/std/re/pcre2_maketables.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 231 lines (single complete read).

## Scope examined

`pcre2_maketables_8` (`:33-125`, gcontext-only signature — matches C
10.47 exactly, verified against `/usr/include/pcre2.h`): null-context
→ default path; builds the 1088-byte table — 256-bit main case-fold run
with `t++`/UTF-mode lowercasing (`:37-61`), lcc/fcc case tables,
8×32-bit ctypes bit runs (computed from `ucp_gentype`), ctype runs —
returns fresh `with_alloc`'d tables. `pcre2_maketables_free_8`
(`:222-231`): null-context→null-tables no-op, else `with_free`.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`):
  `maketables_bad=0` — fresh `pcre2_maketables_8(null)` byte-identical
  to `_pcre2_default_tables_8` over all 1088 bytes (reproduces prior
  session T15c). PASS.
- `docs/audit/probes/re_support/r9_jit_maketables.w` (`output_r9.txt`):
  `ctx-tables-bad=0` with a live general context; free path runs clean
  (exit 0). PASS.
- `with-stage1 check lib/std/re/pcre2_maketables.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
