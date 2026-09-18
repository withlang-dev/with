# Primary verification — prelude facades (`lib/std/prelude.w`, `prelude_alloc.w`, `prelude_core.w`)

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source reads)
Source revision: `450733e5`
Source examined: prelude.w 14 lines, prelude_alloc.w 11 lines,
prelude_core.w 7 lines (each read in full — pure `use` lists)

## Scope examined

Ambient-import facades selected by target profile
(`src/Sema.w`, `src/compiler/Frontend.w`,
`src/compiler/BundleInterfaceEmit.w` reference the variants):
full (`string`+`collections`+`regex`+`task`+`thread`, ...), alloc
(`string`+`collections`+`box`+`rc`, no regex/task/thread), core
(`builtins`+`fixed_string`+`option`+`result`+`traits` only).

## Behavioral matrix

- Every `with run`/`check` in this audit executes under the full
  prelude (resolution exercised continuously, zero prelude
  errors observed across hundreds of compiles).
- Variant layering sane by review: alloc ⊃ core, full ⊃ alloc;
  each named module exists in-tree (no dangling `use`).

## Findings

None.

Verdict: COMPLETE
