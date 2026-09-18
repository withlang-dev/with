# Primary verification — `lib/std/fixed_string.w`

Status: **INCOMPLETE** (one execution-verified defect; three pins HELD)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 10 lines (single complete read)

## Scope examined

`lib/std/fixed_string.w` declares only the shape: `FixedString[Storage]`
(`buf: Storage`, `len_value: usize`) plus a blanket `Copy` impl.
The entire method surface is compiler-intrinsic: length validation
in `src/Sema.w:3726-3740` (comptime-const, positive, capped),
method contracts in `src/SemaCheck.w:20738-20771` (`new`,
`push_byte`, `push_str`, `equals`, `clear`, `is_empty`, `as_view`,
`capacity`, `len`/`len_i32`/`len_i64`, `set`, index), lowering in
`src/CodegenDispatch.w:7298`. Re-exported by all three preludes
(`prelude.w`, `prelude_alloc.w`, `prelude_core.w`); spec §-table
`docs/with-specification.md:10782` (+`:10877`). No FixedString
test files. Type/value use requires explicit
`use std.fixed_string.FixedString` (§18.1; probe-verified).

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/fixed_string/basic.w` (`with-stage1 run`):
  `new`/`is_empty`/`len_i32`/`capacity` (16) PASS (EXECUTED);
  `push_byte(65)`+`push_str("BC")` then `len_i32()==3` PASS;
  `equals("ABC")` PASS; `as_view()=="ABC"` evaluated true
  (PASS printed) — then see F1. All against hardcoded
  `"ABC"`/length literals (no external oracle exists for an
  intrinsic buffer type; literals are the oracle).
- HELD (never reached — crash precedes them): index (`s[0]`,
  `s[2]`), `clear`, capacity-overflow `push_str("ABCDE")`
  into `FixedString[4]`.

## Findings

- F1 (execution-verified, deterministic across 2 runs): after
  `PASS as_view` prints, the `else` branch ALSO executes —
  observed verbatim output ends:
  `PASS as_view` / `FAIL as_view got: ABC` / exit=139 (SIGSEGV),
  with the index/clear/overflow pins never printing.
  Expected: exactly one branch prints, exit 0.
  Refutation attempt: `cat` of the probe confirms a single
  ordinary if/else (no duplicated print); rerun reproduces
  byte-identical output including the signal. Flakiness and
  probe-edit corruption ruled out — not refuted, genuine
  control-flow + memory defect in the `as_view()` temporary's
  branch/cleanup path (second `as_view()` evaluation in the
  else, or the view drop, precedes the segfault). Root cause
  at the exact-line level NOT yet located (needs `lldb` /
  `--debug-alloc` on a minimized repro) — no GitHub issue
  filed per audit instructions.

Verdict: INCOMPLETE

## Close-out (primary, 2026-09-04)

F1 reproduced and bisected by primary: `s[i]` reads garbage
(fs10: 7, 1 for 65, 67); with a trailing index-if both branches
print then SIGTRAP/SIGSEGV (fs4/fs5: A+B+139; fs7: A+133;
false-cond: B+133). MIR correct; LLVM IR ends value-case with
`ret i32 undef`; disassembly shows then-block falling into else
(missing join-jump) + `int3` at the join. Seed reproduces (old).
`as_view` exonerated (fs7/fs11 controls). Filed #1059.
