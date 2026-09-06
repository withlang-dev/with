# Primary verification — `tools/rename_rt_libc_externs.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 97 lines (single complete read)
Last touched: `1aaae73b` (rt/tools: rename every bare libc extern to rt_libc_* via @[link_name], D30 R2c)

## Scope examined

D30 R2c renamer: every bare (non-`rt_`/`with_`/`wl_`-prefixed)
`extern fn` in an rt source becomes `rt_libc_<name>` (leading
underscores stripped: `_exit` → `rt_libc_exit`) with
`@[link_name("<name>")]` prepended, indentation preserved; every
same-spelling IDENT token in the file is retargeted, Lexer-accurate
(comments/strings never rewritten). `slice` (`:14`), `is_bare`
(`:16`), `renamed` (`:19`), Pass 1 bare-extern collection
(`:36`–`:50`, deduped), Pass 2 text rebuild (`:54`–`:87`: decl
vs use distinguished by preceding `extern fn` tokens, attribute
inserted after the line's leading whitespace), top-level driver
(`:92`–`:97`, implicit-main style, per-file status, nonzero exit
on unreadable input).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/tools_rename_rt_libc_externs/check.txt` (seed)
  / `check_stage2.txt` (stage2): `with check` rejects the
  implicit-main driver (`:94`, "expected declaration") — same
  expected non-defect as the other run-scripts in this batch
  (isolated in `docs/audit/probes/tools_implicit_main/`).
- `run_noargs.txt` (stage2, exit 0, empty output) and
  `run_installed_noargs.txt` (installed `with`, exit 0): tool
  parses and runs; zero argv is a silent no-op (no usage text —
  noted below, not a defect).
- `fixture.w` → `work.w` (`run_fixture1.txt`, stage2, exit 0):
  `renamed 3 tokens across 2 externs`. Diff verified by read:
  `open` → `rt_libc_open` (decl + call site),
  `_exit` → `rt_libc_exit` (decl) with `@[link_name("open")]` /
  `@[link_name("_exit")]` prepended; `with_helper`,
  `rt_already` untouched; comment line, string literal, and the
  `call_open` fn name (substring, distinct token) untouched. PASS.
- `run_fixture2.txt` (rerun on `work.w`, exit 0): `no bare
  externs`, sha256 identical before/after
  (`1cd3b84…`). Idempotent. PASS.
- `check_renamed.txt`: `with-stage2 check work.w` → `ok`
  (exit 0). Renamed output is valid source. PASS.

## Findings

None. In-report notes (not filed):
- No-args invocation exits 0 silently (no `usage:` line, unlike
  the other four tools in this batch). Harmless for its
  `rt/*.w ...` call convention (zero files = zero work), but a
  typo'd path that matches no file would also pass silently —
  the per-file loop only errors on unreadable files.
- Attribute insertion anchors at column 0 for top-level decls
  (no indent to preserve); indented/nested decl handling is by
  code read only (whitespace splice `:75`–`:81`), not executed.

Verdict: COMPLETE
