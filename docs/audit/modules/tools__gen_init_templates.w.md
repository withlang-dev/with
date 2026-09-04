# Primary verification — `tools/gen_init_templates.w`

Status: **DEFECT** (documented invocation broken; generation logic verified correct)
Primary verifier: audit-tools-misc (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 55 lines (single complete read)

## Scope examined

Regenerates `src/InitTemplates.w` from `docs/with_for_ai.md`
(`with run tools/gen_init_templates.w`): `esc` byte-escaper
(`:10`-`:26`, backslash/quote/LF/TAB/CR), 4000-byte chunking with `++`
join (`:33`-`:46`), header + `pub fn init_ai_guide_template` emission
(`:47`-`:51`), write to `src/InitTemplates.w` (`:52`). Implicit-main
style (top-level statements `:28`-`:55`), so `with check` rejection is
expected, not a defect. The tool itself was NOT run (it hardcodes a
write to `src/`); all executions used path-rewritten copies under
`docs/audit/probes/tools_gen_init_templates/`, writing only there.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED, `with-stage1 check` → exit 1,
  `expected declaration (fn, type, enum, let, use, extern)` at `:29`.
  Expected limitation (implicit main); same for stage2.
  Saved: `docs/audit/probes/tools_gen_init_templates/check.txt`,
  `check_stage2.txt`.
- EXECUTED (defect proof): path-rewritten copy run under THREE
  compilers — stage1, seed `with v0.15.1.6`, stage2 — all fail
  identically, exit 1:
  `error: manual extern function call requires unsafe context`
  at `:28` (`let doc = with_fs_read_file(...)`) and `:52`
  (`if with_fs_write_file(...) ...`).
  Saved: `docs/audit/probes/tools_gen_init_templates/regen.txt`,
  `regen_stage2.txt`.
- EXECUTED (logic oracle): same copy with only those two calls wrapped
  in `unsafe { }` runs clean (exit 0,
  `wrote .../regen.w (28652 bytes embedded)`) and the output is
  BYTE-IDENTICAL to the checked-in `src/InitTemplates.w` (`cmp` clean).
  So the escaping/chunking/emission logic is fully correct; the only
  defect is the two missing `unsafe` blocks.
  Saved: `gen_probe_fixed.w`, `regen_fixed.txt`, `regen.w`.
- HELD: the committed file run as documented (would overwrite
  `src/InitTemplates.w`; forbidden by the read-only mandate — the
  sandboxed equivalent above is conclusive instead).

## Findings

1. DEFECT (execution-verified, exact output above, NOT filed per
   primary-file instructions): the header comment's documented command
   `with run tools/gen_init_templates.w` fails on every current
   compiler — bare `with_fs_read_file` (`:28`) and
   `with_fs_write_file` (`:52`) calls outside `unsafe`. Sibling tool
   `nightly_release_metadata.w` (`:9`, `:60`) shows the required shape
   (`unsafe { with_fs_... }`). Fix is two `unsafe` wraps (proven: the
   fixed copy regenerates the checked-in file byte-exact). Fix NOT
   applied — read-only mandate (`tools/` unmodifiable); left for the
   owning lane. Risk if unfixed: the next `docs/with_for_ai.md` edit
   cannot regenerate templates, and the cli-selfhost-project-tests lane
   (byte-exact doc comparison) has no working producer.

Verdict: DEFECT (one blocking defect; logic otherwise byte-verified)
