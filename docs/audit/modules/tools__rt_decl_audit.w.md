# Primary verification — `tools/rt_decl_audit.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 169 lines (single complete read)

## Scope examined

D30 R2c audit: every `extern fn with_*` decl (in rt, lib/std, src,
tools, test) against the rt definition of the same name. `scan` (`:33`:
token-walk signature normalizer, param names dropped, `->Unit` default),
`load_aliases`/`normalize_type_text`/`expand_aliases`
(`:99`–`:126`: rt `type X = ...` aliases + whitespace-insensitive
comparison key), `collect` (`:128`), top-level driver (`:143`–`:169`:
implicit-main; exits 1 on any divergence). Depends on `std.fs`
(`list_files_text`), `std.process`, and the compiler's own
`Lexer`/`Token` modules (run from repo root).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/tools_rt_decl_audit/run.txt`: `with run
  tools/rt_decl_audit.w` from repo root → `-- 0 divergent decls /
  528 rt defs / 856 extern with_* decls`, rc=0. The tool's full intended
  function ran to completion against the live tree. PASS.
- EXECUTED (negative control): `with check tools/rt_decl_audit.w`
  (seed and stage2, `check.txt`/`stage2_check.txt`) rejects the file
  with `expected declaration` at the top-level statements (`:147`,
  `:157`–`:165`). Refuted as a defect: the file is an implicit-main
  `with run` script (AGENTS.md: top-level statements ARE the program),
  and `with run` compiles it cleanly — `check` simply does not accept
  that form. Same rejection observed for every implicit-main tool in
  this batch; not a finding.
- HELD: mutation check (introducing a deliberate decl skew and
  confirming exit 1) — not run; would require modifying a repo file,
  forbidden in this read-only audit. The divergence-print path is
  straight-line code over the same records the passing run exercised.

## Findings

None. In-report notes (not filed):
- Must be run from the repo root (relative `rt`, `lib/std`, … paths);
  no usage guard — bare `with run` with no args just runs the audit.
- T13: pure readers (`read_file`, `list_files_text`) + stdout; writes
  nothing.

Verdict: COMPLETE
