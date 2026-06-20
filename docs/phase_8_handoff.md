# Phase 8 Handoff — FFI, C Interop, Layout, Inline Assembly, Migrator

Audience: the next agent resuming Phase 8. This is the working state, the
mechanisms learned, the exact code/spec references, and what to do next.

Canonical plan: `docs/implementation_plan.md` (Phase 8 section — kept in sync
with this doc). Spec: `docs/with-specification.md`. Agent rules: `AGENTS.md`
(== `CLAUDE.md`, kept identical).

---

## 1. Status at a glance

Phase 8 originally enumerated 17 issues; 5 more were discovered during the work
and folded into the phase. Verify states with `gh issue view <n>` before acting
— other agents push concurrently.

**Done (closed):** #349, #370, #379, #412, #415, #416, #417, #418, #426, #427,
#436, #449, #453, #479, #542, #601, #603.

**Open:**
- **#348** — c_import macro helpers shell out to `cc -E`. *Partial:* the macro
  `-dM` path is libclang-only (commit landed); the migrator-only
  `with_cimport_preprocess_text` still runs `cc -E`.
- **#357** — proven-ownership Drop wrappers. *Partial:* removal half done; the
  positive path **first increment shipped** — curated owning-wrapper generation
  for `strdup`/`strndup`→`free` (`ci_owned_return_destructor` +
  `ci_emit_owning_wrapper` in `src/CImport.w` emit a `COwned_<fn>` type with
  `impl Drop` + safe constructor + `.handle()` accessor; test
  `behav_c_import_owning_wrapper_strdup`). Remaining: broader curated coverage
  (fopen/fclose…), refcount modeling, and an annotation/metadata evidence surface.
- **#604** — `[]mut T` arguments: collection→mutable-slice coercion missing.
  Blocks #379 `buf_out`. Maintainer flagged this as a **language-design decision**
  (whether `[]mut T` becomes real vs `VecRange` is the model) — do not change
  `[]mut T`/`VecRange`/spec semantics without the maintainer's call.
- **#605** — aggregate construction copied a non-Copy value instead of moving →
  double-free. *Substantially done:* struct + **tuple + array + enum-variant**
  construction now MOVE Drop values; transitive `Sema.type_needs_drop` predicate
  added. Conservative whole-base consume at tuple field-access (`pair.0`) and
  array index extraction. Remaining: precise per-element partial-extraction
  tracking (follow-ups A6 nested-in-struct, A7 wildcard discard, A8 per-element).
- **#606** — Drop propagation through contents. *Substantially done:*
  tuple/array/enum and generic enums **Option/Result** now drop their contents
  (variant-aware `mir_emit_drop_enum_ptr`; subject-consume at construction,
  match, if-let, let-else, and `?`). Remaining: **Vec** still leaks (no
  `with_vec_free`; A5 is active and must be finished), plus nested-in-struct and
  wildcard drops.

Each aggregate kind landed as its own verified commit (tuple → array → enum →
#357), each passing `with build` + `:fixpoint` + the full behavior/error/spec
suites. Last green: behavior 719, native-compile-error 617, native-spec 179;
**fixpoint holds**.

### A5 reset note — Vec drop backend ownership root cause

The first A5 attempt turned on real `Vec` drop and exposed a backend ownership
bug. Do **not** resume from a backend Sema clone or site-by-site symbol text
fallbacks.

Five whys:
1. Focused A5 tests failed in backend codegen with unresolved return types and
   misleading names (`CString.drop`, `Regex.drop`, `W.drop`,
   `Holder.replace_tail`; typed dumps showed `CString.drop` as `bool.drop`).
2. Those were not independent return/signature/primitive bugs; codegen was
   comparing symbol IDs from different pools.
3. The pool split was introduced after real `Vec` drop exposed
   double-free/invalid-free in backend-owned state cleanup.
4. The attempted workaround made the backend path copy/prepare Sema for Codegen
   (`backend_sema = backend_sema.prepare_comptime_eval_copy()`), while also
   using pools/intern tables from `last_sema`/frontend snapshots.
5. Codegen assumes one coherent symbol-ID domain in many places. A cloned or
   rematerialized Sema without either preserving exact pool identity or
   remapping all IDs breaks that invariant globally.

Ruled out:
- Parser/sema for the focused test: `with-stage2 check
  behav_mut_self_field_assign_vec_tail.w` passed before the failing run.
- A single missing primitive fallback: adding text fallback for primitive names
  did not fix the focused tests.
- A single sig lookup gap: sema signatures were present (`sema.sigs=174` in
  debug flow), and the issue persisted across several declaration sites.
- LLVM verifier as first failure: `wl_verify_module` did not hit; backend failed
  earlier, then cleanup hit invalid free.

Correct fix shape:
- Preferred: make Codegen not drop state it borrows, while keeping one
  symbol-pool/AST/Sema ID domain through backend Codegen.
- Audit Codegen fields that currently store borrowed ZCU/Sema vectors/strings.
  Clone only true leaf owned data where symbol IDs are not affected; do not
  clone symbol-bearing Sema/AST state as a workaround.
- If backend truly must own/mutate Sema, handle the pool boundary once by
  remapping every symbol-bearing structure or by adding one centralized
  cross-pool symbol resolver/equality abstraction. Do not patch individual call
  sites with ad hoc text fallback.

The dirty first attempt was reset. Its untracked tests were lost; rewrite the
A5/A6/A7 tests first from this behavior list before touching ownership:
`behav_drop_vec_elements`, `behav_mut_self_field_assign_vec_tail`,
`behav_mut_self_vec_owner_receiver`, `behav_drop_struct_field_move_reinit`,
`err_use_after_move_struct_field`, and
`err_use_after_move_vec_into_struct_field`.

---

## 2. Build / verify (always run before claiming done)

```
with build                       # seed → stage1 → stage2 → final (~5 min)
with build :fixpoint             # stage2 == stage3 byte-identical (MUST hold)
with build :behavior-tests
with build :native-compile-error-tests
with build :native-spec-tests
```
Fast single-file repro (no full rebuild): `./out/release/bin/with run file.w`
or `./out/release/bin/with build file.w`. Debug drop/codegen:
`WITH_DEBUG_MIR_CODEGEN=1 ./out/release/bin/with build file.w`.

Concurrent agents push to `main`: after committing, `git fetch && git rebase
origin/main` before `git push`. Never `git stash`. Commit author is Eric
Hartford only — no AI co-authors/trailers.

---

## 3. What shipped (mechanisms worth knowing)

### #379 curated libc contract overlay (`src/SemaDecl.w`, `src/CImport.w`)
The blanket `const char*`→cstring rule (commit 1e53f8aa) was **removed**;
modeling is now evidence-driven.
- `ci_overlay_cstr_in_param_count(name)` and `ci_overlay_return_is_borrowed_ptr(name)`
  in `src/SemaDecl.w` are the curated tables (ordered, deterministic).
- `Sema.ci_function_requires_raw_abi(fn_sym)` decides raw-vs-modeled; populates
  `ci_raw_syms`. A c_import fn with a **slice parameter** is exempt (it's a
  generated safe wrapper — C has no slices).
- `Sema.try_ci_coercion(fn_sym, ...)` (`src/SemaDiag.w`) gates the str→C-string
  coercion on the function being modeled (`ci_raw_syms.contains == 0`).
- **Shipped facts:** `cstr_in` (strlen/strcmp/atoi/…), `nullable_ptr` borrowed
  returns (strchr/getenv/… — raw C pointers are *natively nullable*: `== None` /
  `.unwrap()` work on a plain `*T`, so the return is NOT wrapped in Option),
  `buf_in` (memchr/memcmp via generated wrappers).
- **Cache:** the c_import cache key already hashes the compiler binary
  (`frontend_cimport_compiler_fingerprint_line`), so editing the overlay
  invalidates cached bindings — no separate fingerprint needed.

### `@[link_name("symbol")]` extern-fn attribute (new, general)
Parser stores it as a `link_name:` prefix on `pending_callconv`
(`src/Parser.w`, mirroring `c_export:`); codegen `Codegen.declare_extern_fn`
(`src/Codegen.w`) uses the given symbol as the LLVM name instead of
`canonical_extern_name`, keeping C ABI. This is the primitive buf_in's wrapper
gen needs (public name = wrapper, raw binding renamed but linking to the real
C symbol). Test: `test/behavior/behav_link_name_extern.w`.

### buf_in wrapper generation (`src/CImport.w`)
`ci_emit_buf_wrapper` emits a renamed `@[link_name]` raw extern + a safe `fn`
wrapper taking `[]u8`, deriving length from `slice.len()`, base pointer via
`&raw const s[0]` (empty slice → `null`). Curated by `ci_buf_count` /
`ci_buf_ptr_idx` / `ci_buf_len_idx` / `ci_buf_is_mut`. memcmp requires equal
lengths (panics). Tests: `behav_c_import_overlay_memchr.w`,
`behav_c_import_overlay_memcmp.w`.

### #601 match-arm drop corruption (`src/MirLower.w` `lower_match`)
Match-arm pattern bindings were dropped on every path leaving the match,
dropping uninitialized memory for `Result[DropType, E]`. Fixed by per-arm
push/pop drop scope. (Found via lldb backtrace.)

### #605 struct-literal double-free (shipped)
A non-Copy value placed in a struct-literal field was bitwise-**copied**, not
moved → use-after-move undetected + drop flag uncleared → **double-free**.
Fixed, gated on `type_has_drop_impl(field value type)`:
- `Sema.check_struct_literal` (`src/SemaCheck.w`): `mark_moved_if_consumed` on a
  whole non-Copy identifier field value (use-after-move detection).
- struct-literal lowering in `src/MirLower.w`: `consume_moved_operand` on the
  field operand (drop-once), explicit + defaulted fields.
- One compiler site relied on the copy — `CCodegen.c_emit_module` used `mir_mod`
  after moving it into the codegen struct; migrated to read through the field.
- Non-Drop value types are intentionally left to **copy** — the compiler/stdlib
  rely on it to *share* a value across constructions (e.g. `lib/std/build.w`
  puts one `fs_outputs` into both `ToolFs` and `ProcessRunner`); harmless
  without a destructor. Strict-move for all non-Copy would require a clone
  migration (out of scope). Tests: `behav_drop_move_into_struct_field.w`,
  `err_use_after_move_into_struct_field.w`.

---

## 4. The drop/move soundness cluster (#605 tuple/array/enum + #606) — READ THIS

This is the hard remaining work and the most error-prone. It surfaced from
#357's ownership matrix and is the gate for #357's wrappers being usable in
real code (resource handles live in structs/Option/Vec).

### The two distinct root causes
- **#605 (move):** aggregate construction (`struct`, `array`, `tuple`,
  `enum-variant`) bitwise-copies a named non-Copy initializer instead of moving
  it. Only the struct-literal case is fixed.
- **#606 (drop propagation):** `Drop` is never run on the *contents* of
  `Option`, `Vec`, array, tuple, or enum payloads → leak. Struct fields **do**
  drop (the control). Confirmed clean via literal-in-place tests
  (`[W{..}]`→no drop, `Some(W)` in own scope→no drop). The Vec case is the
  least-verified ("every Vec leaks" is grep-absence + a `push`-intrinsic
  confound — treat as unverified).

### Why they are entangled (severity differs by aggregate kind)
- **struct** drops its fields → copy caused **double-free** → fixed by moving.
- **array/tuple/enum** do NOT drop contents → copy causes a **leak**, not a
  double-free.
- Therefore: fixing #605-move alone for array/tuple/enum makes the moved-in
  value dropped nowhere (still a leak); fixing #606-drop alone turns those leaks
  into double-frees. **They must land together** per aggregate kind.

### Drop machinery (code map)
- Drop trait: `lib/std/traits.w`; `impl Drop for X: fn drop(move self: Self)`.
  **`lib/std/string.w` `CString` is the owning-wrapper template** (struct
  holding `*mut`, `drop` calls `with_free` once).
- `Sema.type_has_drop_impl(tid)` (`src/Sema.w`, ~3808) — **SHALLOW**: checks the
  type's own Drop impl only, NOT fields/elements. A transitive needs-drop
  predicate does not exist and is needed (a struct with a Drop field but no own
  Drop impl currently still copies → inner double-free).
- `Codegen.detect_drop_functions` (`src/Codegen.w`, ~4741) registers `drop` fns
  **only from explicit `impl Drop`** — no synthesis.
- `Codegen.mir_emit_drop_ptr_for_sema_type` (`src/CodegenDispatch.w`, ~3827) is
  the drop dispatcher. `mir_emit_drop_fields_ptr` recurses **struct fields
  only** (`if ty != struct_kind: return`) and honors per-field consumption via
  `drop_consumed_field`. There is no tuple/array/enum-payload recursion.
- MIR move tracking (`src/MirLower.w`): `consume_moved_operand` (~376) →
  `mark_local_value_moved` (~300) + `cancel_scheduled_value_drop_for_local`
  (~317, flips a scheduled `DK_VALUE` drop to `DK_STORAGE`). `schedule_drop`
  (~209). Drop suppression for a let-bound var flows from the **sema** mark
  influencing the operand kind (OK_MOVE) which the MIR consume then acts on.
- Sema move marking: `Sema.mark_moved_if_consumed` (`src/SemaCheck.w`, ~18242) —
  `NK_IDENT` → `scope_set_state(MOVED)`; `NK_FIELD_ACCESS` → "partial move from
  Drop type". Gate calls on `NK_IDENT` + `type_has_drop_impl` to avoid
  flagging legitimate partial reads (this was a real regression — `ctx.token`
  in capability tests).

### Templates to reuse for #606
- **Enum (variant-aware) drop:** `Codegen.gen_display_enum`
  (`src/CodegenDispatch.w`, ~2838) is the exact discriminant-switch skeleton
  (load tag → per-variant compare/branch → merge). Adapt it: per active variant,
  drop each payload **ptr** instead of formatting. Helpers:
  `mir_enum_variant_count`, `mir_enum_variant_discriminant`,
  `mir_enum_variant_payload_count`, `mir_enum_payload_sema_type`,
  `mir_enum_variant_payload_llvm_type`, `mir_enum_tag_value`.
- **Tuple element types/ptrs:** `mir_project_field_sema_type(agg_ty, i)` gives
  element i's sema type; `wl_build_struct_gep(builder, ty, ptr, i)` the element
  ptr. (A tuple drop branch using these *worked* for literal/moved cases.)

### What was attempted and reverted (so you don't repeat it)
A tuple #605+#606 pilot: CodegenDispatch `TY_TUPLE` drop branch + sema
`check_tuple` mark + MIR tuple-literal `consume_moved_operand`. Results:
- literal `(W{..},9)` → drop once ✅; moved `(tmp,9)` → drop once ✅ (sema mark).
- **destructure `let (a,b)=t` and `let (tx,rx)=channel()` → double-free** ❌
  (`panic: invalid free`). Channels return `(Sender, Receiver)` (both Drop);
  destructure moves the elements out, but the source tuple still drops them.

**Why destructure didn't converge:** the source must be fully consumed, but
`lower_tuple_destructure` (`src/MirLower.w`) does
`rhs_place = materialize_operand(rhs_op, ...)` which yields a **copy temp**, so
`cancel_scheduled_value_drop_for_local(mir_place_plain_local(rhs_place))`
cancels the *temp's* drop, not the real source local's. The sema mark on the
destructure `value` only helps when `value` is an `NK_IDENT` (named source),
not a call result (`channel()`).

**Concrete fix direction (de-risked, untried):** consume the *true source*
before materialization — `consume_moved_operand(rhs_op)` (the pre-materialize
operand) and/or thread the real source local — so the source tuple's value-drop
is cancelled for both named sources and call temporaries. More generally,
aggregates need **per-element drop-state** (the analogue of structs'
`drop_consumed_field`) so partial moves (`let (a,_)=t`) drop only the kept
elements rather than leaking or double-freeing.

### Recommended approach for the cluster (one aggregate kind at a time)
1. Build the regression matrix first (literal / moved / destructure / partial
   destructure / stored-in-struct / stored-in-Option/Vec), each asserting
   **drop exactly once** via a `*mut i32` counter (`drop` increments through the
   pointer). Run them before touching code — they currently fail (leak or
   double-free).
2. Land #605-move + #606-drop **together** per kind. Order: tuple → array →
   enum (enum is variant-aware, hardest; arrays use `[0,i]` GEP not struct-GEP).
3. After each, run the **full** behavior suite — channels/capability tests are
   the oracle that catches copy-reliance double-frees. Fixpoint must hold.
4. Add a transitive `needs_drop` predicate (recurse through fields/elements) to
   gate the move/drop correctly for nested Drop types.

---

## 5. #604 — `[]mut T` arguments (blocks #379 buf_out; maintainer-reserved)

`buf_out` (memset/explicit_bzero) needs a `[]mut u8` argument. **With cannot
construct one today.** Verified mechanism matrix (all run, not inferred):

| mechanism | result |
|---|---|
| free `mut param` (struct/Vec) | **moves** (consumes; caller loses binding) |
| `mut self` method | in-place, usable after |
| move-in / return `f(T)->T` | works |
| `[]mut T` parameter | type exists (`TY_SLICE` `d1`=mut flag), but **no expression produces a `[]mut` value** — slice exprs emit `d1=0`; compat check `Sema.w` ~4427 rejects `[]`→`[]mut` |
| `VecRange` parameter | **unspellable** (`unknown type: VecRange`; it's `self.syms.vecrange`, compiler-internal) |
| `&mut Vec[u8]` parameter | rejected (no safe `&mut`) |

So mutable buffers cross a function boundary only via `mut self` or
move-in/return — neither a clean free-function slice surface. Spec §4.8
(lines ~2083–2086) explicitly promises a collection→`[]mut T` coercion in
parameter position; the compiler doesn't implement it (a real gap). The
**reconciliation is a language-design call** (realize `[]mut T` with §21.1
exclusivity, vs bless `VecRange` and update the spec). The maintainer reserved
this. Do not change `[]mut T`/`VecRange`/spec without their decision. Once
resolved, buf_out is trivial: add overlay entries; `ci_emit_buf_wrapper` already
handles the mutable (`&raw mut`) path.

`buf_out` is intentionally **not** curated in `ci_buf_*` (a wrapper would be
uncallable and would regress the raw `memset` surface). `owned` returns
(fopen/strdup) are routed to #357.

---

## 6. #348 — c_import preprocess shell-out (partial)

Macro `-dM` collection is libclang-only (done). Remaining: migrator-only
`with_cimport_preprocess_text` (`src/CImport.w`) runs `cc -E` to reconstruct
macro-expanded text at source locations (via `#line` markers), feeding the
migrator's `ci_preprocessed_*` readers. libclang has no `-E`; options are a C++
bridge preprocessor function (over the statically-linked clang frontend) or a
migrator redesign using libclang cursor source-ranges + constant evaluation.
Self-contained-toolchain rule: never shell to system `cc`/LLVM. Substantial.

---

## 7. #357 — proven-ownership Drop wrappers (positive path)

Removal half done (heuristic auto-defer removed upstream; regression tests
`err_c_import_destroy_heuristic_no_owning_wrapper.w`,
`behav_c_import_destroy_heuristic_no_auto_defer.w` added). Spec: §16.2a
"Auto-Method Generation / Proven ownership cleanup"; `docs/requirements.md`
16.2.2.11–16.2.2.27.

Remaining (positive path): an ownership-evidence surface (explicit annotation;
author/imported metadata; conservative header analysis; curated convention)
that generates an owning wrapper type whose `Drop` calls the evidenced C
destructor, plus refcount modeling (+1 constructor vs borrowing accessor).
Name heuristics (`*_destroy`/`*_free`/…) may only emit manifest candidates,
never insert cleanup.

Wrapper shape is validated: a struct `{ handle: *mut CRaw }` with
`impl Drop: fn drop(move self): unsafe { c_destructor(self.handle) }`. The
**struct double-free fix (#605) makes such a wrapper safe to store in a struct**
(the common case). Stored in Option/Vec it still leaks until #606. Generation
reuses the c_import binding-gen + `@[link_name]` infra. The ownership-evidence
schema should be shared with #379's overlay (same `(domain, symbol)` keyed
metadata).

---

## 8. Lessons learned (now codified in AGENTS.md / CLAUDE.md "Verify by Running")

1. **Spell it and run it.** Before concluding a type/mechanism/API works, write
   the smallest program and compile it. Cost us repeatedly: `VecRange`
   unspellable as a param; `mut` params move (not borrow); `&raw` needs explicit
   `const`/`mut`; pointer returns become `Option` only via `_Nullable`, not by
   text-wrapping; the move/copy of aggregates differs by kind.
2. **Exhaust small answer-spaces in one pass.** "How many ways can a mutable
   buffer cross a function call?" / "which construction sites copy-not-move?" are
   small enumerable sets — build the *matrix* and test all of it at once. Verdicts
   flipped 3× when drawn from one or two cases. Don't conclude-and-patch.
3. **Code settles facts; intent is the maintainer's call.** Running code shows
   what *is* (what compiles, what's spellable, whether a feature has a producer);
   *which* model is canonical is a design decision — surface the contradiction,
   don't derive it. (`split_at_mut` returns `VecRange` vs spec's `[]mut T`.)
4. **A grep for absence is not evidence.** "No `impl Drop for Vec`" doesn't prove
   Vec doesn't drop — container drop is compiler glue. Trace the mechanism.
5. **The full behavior suite is the soundness oracle.** Channel/capability tests
   caught copy-reliance double-frees the targeted tests missed. Run it after any
   move/drop change; a self-hosting compiler relies pervasively on current
   semantics, so a "clean" core change can break the build or the suite.
6. **Stop only for a real maintainer decision** (intent, scope, go/no-go on
   risk). When the path is clear and self-scoped, proceed and report as you go;
   own a deferral with a reason rather than asking permission.

---

## 9. Bootstrap / safety reminders (from AGENTS.md)

- Move/drop changes are **fixpoint-sensitive core codegen**. Work in small
  increments; run `with build :fixpoint` every change. A wrong drop-glue change
  silently miscompiles or breaks stage2==stage3.
- No silent fallbacks: fail loudly with a diagnostic, never stub.
- Never change `Link.w` + runtime in the same commit; these tasks don't touch
  the link path, so normal `with build` + `:fixpoint` gates apply.
- Re-read files before editing after long sessions (concurrent agents + linters
  shift line numbers — prefer function names over line numbers).

---

## 10. Suggested next-session order

**Done (this session): the structural drop/move cluster + #357 first increment.**
A0 transitive `needs_drop` → tuple → array → enum (+ Option/Result) → #357
curated owning wrappers, each its own verified+pushed commit.

Remaining, required order unless the maintainer redirects:
1. **A5 Vec drop** (#606 tail) — give Vec a real Drop (add `with_vec_free` +
   compiler element-drop loop). Start by rewriting the focused tests listed in
   the A5 reset note, then fix backend Codegen ownership/borrowing so enabling
   Vec drop does not clone Sema or split symbol pools.
2. **A6/A7/A8** (precise drop tracking) — nested aggregate-in-struct-field drop;
   wildcard-element drop in irrefutable destructure; precise per-element
   partial-extraction tracking to replace the conservative whole-base consume.
3. **#348 preprocess_text** — replace the `cc -E` shell-out in
   `with_cimport_preprocess_text` (`src/compiler/ClangBridge.w` ~2309) with
   libclang token reconstruction. The token FFI already exists and is used
   (`clang_tokenize`/`clang_getTokenSpelling`/`clang_getExpansionLocation`,
   ClangBridge.w ~1474–1491). Independent of the drop codegen; substantial.
4. **#357 expansion** — more curated owning constructors (fopen/fclose…),
   refcount modeling (+1 ctor vs borrowing accessor), and an annotation/metadata
   evidence surface. Reuses the shipped `ci_emit_owning_wrapper`.
5. **#604 `[]mut T`** — awaits the maintainer's `[]mut T` vs `VecRange` decision.
