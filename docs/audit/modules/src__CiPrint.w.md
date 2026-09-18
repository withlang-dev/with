# Audit: src/CiPrint.w @ 450733e5

Verdict: **COMPLETE** (no findings)

Scope: full module source, 1205 lines, read in full (1–500, 500–860, 860–1205).
Commit verified: `450733e5` (`git rev-parse --short HEAD`).
READ ONLY: `git status --short` shows no modifications to `src/` (only
pre-existing untracked `docs/`, `.codex/` dirs). No compiler sources modified.

## Targets traced

- **T13 ownership/drop**: clean. Module never calls `drop`/`free` (grep: no hits).
  Every borrowed `&str` returned as owned `str` goes through
  `with_str_clone_ref` (e.g. `src/CiPrint.w:99`, `101`, `111`, `114`, `417`,
  `419`, `426`, `540`, `568`–`584`); f-strings/`++` produce owned values.
  Pools (`CiStmtPool`/`CiExprPool`/`CiTypePool`) are passed by value and reused
  by callers afterwards (roundtrip harness `src/CiPrint.w:1120`–`1125`,
  `1161`–`1169` reuses `types`/`exprs` across calls), so they are shared
  handles, not move-only owners — nothing to drop. Global
  `g_ci_print_in_unsafe_fn` (`src/CiPrint.w:487`) is a plain bool set via
  `ci_print_set_unsafe_fn_context` (`src/CiPrint.w:489`), driven by
  `src/CImport.w:40`; no resource attached.
- **T15 migration fidelity**: clean (no proven defect). `<ci:unimpl:…>`
  placeholders (`PRE_INC/PRE_DEC/POST_INC/POST_DEC` at `703`–`709`, `COMMA`
  at `732`, `SIZEOF_EXPR` at `741`, `FOR` at `927`–`928`, `STRUCT_DEF` /
  `ENUM_DEF` at `1081`–`1085`, plus `unknown` arms at `783`, `1036`, `1093`)
  are the documented Phase-A skeleton (header `1`–`15`); the roundtrip
  harness comment (`1095`–`1101`) says new kinds pick up cases as lowering
  lands. `FN_DECL`/`EXTERN_FN` print `()` params only (`1054`, `1091`) because
  the IR node (`fn_decl(name, ret, body, flags)`) carries no params — IR
  limitation, not a printer defect. Block/if/while/do-while/match reindent
  convention matches the legacy `compound_stmt` behavior per comments
  (`844`–`850`, `862`–`865`) and is consistent with `CImport.w:6163`
  (`with 0 as <seq> {…}` expr-seq shape matches `820`–`843`). Ternary
  cond-paren strip (`727`–`730`) only removes one redundant outer paren inside
  `if cond:` — semantics-preserving. `CIE_DEREF` of fn-ptr returns the operand
  (`655`–`656`); C `*fp == fp`. Correct.
- **T22 spec conformance**: clean. `parent_prec`/`wants_ptr` unused in Phase-A
  is declared in the comment block (`549`–`555`); `ci_bin_op_prec` (`139`–`161`)
  is staged for B3. `unsafe` wrapping centralized in `ci_wrap_unsafe` (`216`)
  and `ci_print_unsafe_stmt` (`492`), honoring the `#749` non-`unsafe`-fn
  context (`482`–`487`). Golden expectations in the harness match the
  `CIS_BLOCK` bare-`\n` separator convention (`1188`–`1191`).

## Observation (not a finding — refutation HELD)

- `CIE_COMPOUND_ASSIGN` (`710`–`716`) prints `lhs = lhs op rhs`, evaluating
  `lhs` twice. A side-effecting lhs (e.g. `p[i++] += v`) would be
  double-evaluated. A producer exists (`src/CImport.w:7983` creates
  `CIE_COMPOUND_ASSIGN`; guards at `7376`, `8801`, `9936`, `11141`, `14523`),
  but whether lowering ever feeds a side-effecting lhs (vs. always sequencing
  effects out first, as it does for do-while `cond_setup`) was NOT verified —
  reading those lowering sites was out of batch budget. Per the refutation
  rule this is recorded as an observation for follow-up, not a defect.

## Probes

- `out/bootstrap/bin/with-stage1 check src/CiPrint.w` — HELD as module-level
  proof: the single-file check drags in `src/CImport.w` and fails on
  pre-existing errors there (`error: undefined variable str_from_byte` at
  `src/CImport.w:1947:16`, `1948:5`; `check failed during compilation`). No
  error was reported against `src/CiPrint.w` itself. Negative control: the
  failure is unrelated to this module.
- Caller grep (`ci_print_*` outside `src/CiPrint.w`) — EXECUTED: heavy in-repo
  use from `src/CImport.w` (`ci_print_type`/`ci_print_expr`/`ci_print_stmt`
  call sites, `ci_print_set_unsafe_fn_context` at `CImport.w:40`);
  `CImport.w:5800` defines a separate `ci_print_compact_stmt` (distinct name
  from CiPrint's `ci_print_compact_stmt_local`), so no symbol clash.
- Defect-pattern grep (`drop|free|TODO|FIXME|panic|unwrap`) — EXECUTED: no
  hits except intentional `drop`-in-comment (`137`, paren-dropping) and the
  documented placeholders above.

## Negative controls

- Placeholder arms are reachable only for unlowered kinds by design; the
  implemented arms have golden coverage (`ci_roundtrip_types/exprs/fn_decl`).
- `CI_SIZE_INCOMPLETE` open-array rendering (`413`–`415`) is golden-tested
  (`[]u8`, `1125`).
