# Primary verification — `lib/std/re/pcre2_context.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 526 lines (single complete read).

## Scope examined

Context lifecycle for all four context kinds: general create/copy/free
(`:32-120`, custom malloc/free passthrough, null→-51), compile-context
create/copy/free + all setters (`:122-346`: bsr/newline/max-lengths/
parens/extra-options/varlookbehind/optimize, invalid→-29/-34,
null-context→-51 — note `set_optimize` allows only 0/1/7), match-context
(`:346-497`: depth/heap/match/offset/recursion limits), convert-context
(`:346+`: glob escape/separator with ASCII-printable validation),
`pcre2_set_character_tables_8` (`:440-450`: null→-51), `default_malloc`
(`:512-517`, `with_alloc`) / `default_free` (`:519-524`, `with_free`),
`globpunct` table (`:526`). These two allocator shims are what
`defs.w`'s default contexts reference (hence the standalone-check note
in the `defs.w` report).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r7_context_newline.w`
  (`output_r7.txt`):
  `g-null=1`,
  `set-bsrok=0 set-badbsr=-29 set-nlok=0 set-badnl=-29`,
  `set-maxpat=0 set-maxcompl=0 set-parens=0 set-xopt=0 set-varlook=0`,
  `set-opt-null=0 set-opt-full=0 set-opt-bad=-34`,
  `set-opt-nullctx=-51`,
  `set-depth=0 set-heap=0 set-match=0 set-off=0 set-rec=0`,
  `glob-esc=0 glob-esc-bad=-29 glob-sep=0 glob-sep-bad=-29`,
  `copies=4`. Error codes match PCRE2 (`-29` baddata, `-34` badopt,
  `-51` nullctx). PASS.
- `with-stage1 check lib/std/re/pcre2_context.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
