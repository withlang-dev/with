# Primary verification — `tools/wrap_diag_spans.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-tools-misc (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 453 lines (single complete read)

## Scope examined

#747 Phase C step 2: wraps flipped-checker diagnostic spans in
`<file>_owned_text(...)` by byte edit; dry-run default. `classify`
(`:66`-`:82`, kinds 1-9 incl. vec-push, d22 call-arg/struct-field,
struct-field/assignment/return mismatches, wrong-arg, borrowed-read,
typed-binding), caret counting (`:84`), ident/field shape gate
(`:90`), assign-RHS finder (`:99`), `push_label_ok` (`:143`) and
`wrong_arg_label_ok` (`:158`) label gates, `collect_sites` (`:170`,
loc/caret shape, span-length, dedup), `plan_edits` (`:236`, skip-list /
line-range / multiline / span-shape / branch-RHS / shorthand / overlap
guards; kind-2 `with_str_clone(` rename; kind-5/9 RHS-only wrap; kind-6
`return `-prefix strip), back-to-front `apply_edits` with explicit
order sort (`:328`; #755 seed-miscompile workaround via `splice`,
`:325`), `ensure_decl` (`:351`), `finalize_existing` (`:374`),
`process_file`/`main` (`:391`/`:407`, `--apply`/`--skip`/
`--finalize-existing`). Bootstrap note (`:24`-`:26`): prelude/std
surface only, no direct `with_*` externs.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED, `with-stage1 check tools/wrap_diag_spans.w` → ok (exit 0).
  Saved: `docs/audit/probes/tools_wrap_diag_spans/check.txt`.
- EXECUTED, no-args run → `usage: wrap_diag_spans [--apply]
  [--skip skips.txt] diags.txt`, exit 1. Saved: `noargs.txt`.
- EXECUTED, dry-run return-mismatch on synthetic fixture
  (`fixture.w:2:5`, span `name`) → `sites collected: 1`,
  `wrap ... kind=return span='name'`, `planned/applied 1 edits`,
  `dry run: re-run with --apply to write`, exit 0 — and the fixture
  is byte-unchanged after (`sha256sum -c` OK), proving dry-run is
  read-only. Saved: `diags.txt`, `fixture.w`, `dryrun.txt`, `before.sha`.
- EXECUTED, dry-run vec-push with `has type &str` label → `kind=vec-push
  span='name'`, 1 edit planned, exit 0 (label gate passes, no write).
  Saved: `diags_push.txt`, `push.w`, `dryrun_push.txt`.
- HELD: `--apply` write path, `--skip` list, `--finalize-existing`
  (all mutate repo files; excluded by the read-only mandate).
  `ensure_decl`/`finalize_existing`/`apply_edits` verified by read only.

## Findings

None. In-report notes (not filed):
- Kinds 8/9 (`borrowed-read`, `typed-binding`) extend beyond the header's
  kinds 1-6 list; the header predates them. Doc drift only — `kind_name`
  (`:120`) covers all, behavior verified by read.
- `collect_sites` silently drops unparseable entries (`continue`);
  correct for a best-effort batch wrapper driven by compiler-owned
  diagnostics (loud failure would false-block the bootstrap).

Verdict: COMPLETE
