# Handoff — modeled-C stage 4 (resource rendering with Drop)

Authority: `docs/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`
(§9 never half-model, §13.1 pre-initialization, §13.2 Drop arming, §14 several
resources over one representation, §67 zeroed() is consumed not defined);
spec §16.2b.3 (`docs/with-specification.md:9171-9208`);
plan `docs/modeled-c-implementation-plan.md:184-197` and the design decisions
at `:109-137`. This file is execution detail only; where it and the ruling
disagree, the ruling wins and this file is wrong.

## Where the facts are (verified 2026-09-22 on main f5198991)

- `Sema.w:405-420` `FacadeResource { name, facade, node, repr_tid, producer,
  out_param, init, preinit, drop, destroyers, ok_const, borrows, independent,
  thread_caps }`; `Sema.w:422-440` `ForeignContract`; stored on `Sema` at
  `:1039-1041`, filled by `SemaFacade.w:58-75 collect_facade_resource`
  (called from `SemaDecl.w:287`, after pass 3).
- The only consumers today: `facade_covers_return/param`
  (`SemaFacade.w:465-487`) read by `ci_function_requires_raw_abi`
  (`SemaDecl.w:754, 767`). Stage 4 is the first consumer of `repr_tid`,
  `drop`, `destroyers`, `init`, `preinit`, `producer`.
- No drop-flag / liveness facility exists in MIR (`MirLower.w:940` "M7 drop
  flags are retired"); a local of a Drop type is scheduled at binding and
  disarmed only by move. Arming must be expressed in ordinary With.
- Mechanism A (`CImport.w:1433-1460` eight libc rows, `:1602-1692` COwned
  wrappers) and its `owns:`/`borrows:` plumbing retire in 4c, not before.
- c_import synthetic file registration: `Frontend.w:480-536` (text →
  `<c_import HEADER>` → parse → splice with `decl_is_c_import = 1`).

## Design (execution detail)

**Rendering is a second synthetic file**, `<facade NAME>`, emitted by the
Frontend after every source file and every `<c_import …>` file is parsed and
before Sema, from the facade AST (`NK_C_FACADE`, kinds 132–138) plus the
imported `extern fn` declarations it names (looked up by name among the
c_import decls; their parameter/return types re-spelled from the AST). It is
registered and spliced exactly like a c_import file. Sema then sees ordinary
With; `collect_c_facades` still verifies §61 against the same facts, so a
rendering that assumed something false is caught there, never silently.

Emitted shape per resource `R wraps Repr`:

```
type R { repr: Repr }                       // non-Copy; never `impl Copy`
impl Drop for R:
    move fn drop(self: Self):
        unsafe { <drop>(self.repr) }        // pointer/by-value repr passed as C expects
impl R:
    move fn <destroys-op>(self: Self, <other args>) -> <ret>:   // one per `destroys`
        unsafe { <op>(self.repr, <args>) }  // consumes self; Drop must NOT run after
    fn <name>(<args minus the produced return>) -> R:            // direct-return producer
        R { repr: unsafe { <producer>(<args>) } }
```

A `move fn` destroyer must disarm the type's Drop after the raw call: render
it as `let repr = self.repr` then forget/`move` semantics — use whatever
existing With spelling makes the field's Drop not run (check how
`ci_emit_owning_wrapper`'s consumers and `drop_consumed_field`
`Sema.w:7640-7656` treat a field consumed inside `drop`; a destroyer method
that reads `self.repr` and then lets `self` drop would double-destroy — write
the test for it first).

In-place resource (repr is a by-value struct with `init`): stage 4b —
`type R { repr: Repr, live: bool }`; storage `Repr.zeroed()` (or the `preinit`
operation); `init` sets `live` on success; `drop` runs the destroyer only
when `live`. Not part of 4a.

Facade-level errors (§9 / spec "never half-model unsafely"), reported at the
resource's span with the ruling's wording:
- a producer (`from`/direct-return) with no `drop` and no `destroys`;
- an operation named as destroyer that is also callable as a lend (a `fn`
  contract with `lend` naming the same C function, or the raw function still
  reachable as a lend through the resource).

## Sub-batches

- **4a** (this handoff): pointer and by-value resources; `drop`; `destroys`
  as `move fn`; direct-return producer as safe constructor; the two errors;
  tests: Drop runs exactly once on every path (scope exit, early return,
  moved into a function, moved out and returned, in a Vec); a `destroys`
  call never double-destroys; the errors. Use a C prototype-only header +
  `//! expect-check-stdout: ok` in `test/phase/` where bodies are absent, and
  real libc (`fopen`/`fclose`, `strdup`/`free`) in `test/behavior/` for the
  drop-exactly-once runs (count via `--debug-alloc` where the destroyer is
  `free`; for `fclose`, a facade over a header you write in the test dir with
  a counter is fine).
- **4b**: in-place resources, `preinit`/`init`, `zeroed()`, `live`.
- **4c**: the toolchain libc facade (eight rows) replaces mechanism A; the
  five tests flip to it; `owns:`/`borrows:` become deprecated spellings with a
  diagnostic naming the facade clause.

Blast radius: 4a and 4b touch Drop scheduling only through ordinary With
(struct + `impl Drop`), but run `:move-audit` and `:drop-audit` at the
iterate tier before handing off, and the batch battery adds them.

## Traps

- The facade parser writes `init <fn>(self)` (Parser.w:4069-4080); `param`
  names in c_import are `__param_<name>` (strip when re-spelling).
- c_import and user files are separate InternPools; symbol text comparison
  is `safe_symbol_text` (see `SemaFacade.w:460-463 facade_same_fn`).
- Every imported struct is `impl Copy` (`CImport.w:2310`); the resource
  wrapper must be a distinct non-Copy struct, never the repr itself.
- Guard tests that must keep failing: `err_c_import_destroy_heuristic_no_owning_wrapper.w`,
  `err_c_import_uncurated_ptr_return_raw.w`, `err_c_import_raw_call_requires_unsafe.w`.
- Never emit a placeholder body or an `extern fn` to paper over a resource
  the renderer cannot express: fail with a diagnostic naming the resource.
