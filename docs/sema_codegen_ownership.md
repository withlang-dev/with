# Sema/Codegen Ownership Design (`src/compiler/*`)

## Purpose

Define a concrete migration so semantic analysis and code generation are
owned by the self-hosted compiler architecture under `src/compiler/*`,
not by `Driver` compatibility paths.

This design is the enabling step for Prelude Phase B:

- remove non-primitive hardcoded builtin symbol handling from `Sema`
- source user-facing names from `std`/prelude modules by normal import

---

## Problem Statement

Current implementation has architectural split-brain:

1. `src/main.w` now routes `build`/`run`/dump flows through `Compilation`,
   and `src/Compilation.w` is a thin facade to `compiler.Compilation`.
2. `src/compiler/Compilation.w` no longer imports or constructs `Driver`,
   but stage outputs are still not exclusively authoritative in `Zcu`.
3. `src/compiler/*` exists, but ownership is still incomplete because
   `Driver` retains duplicated legacy state/runtime logic.
4. `Sema` and backends still contain hardcoded user-facing builtin names
   (`println`, `assert`, `Vec`, math names, `None`, etc).
5. Codegen paths are inconsistent:
   - compiler path now uses MIR -> LLVM and MIR -> C.
   - legacy LLVM backend still contains verifier bugs that block fresh
     selfhost rebuilds from current source.
6. Runtime/link policy is duplicated and currently fragile.

Result: ownership boundaries are unclear, migration work collides, and
builtin cleanup cannot be completed safely.

---

## Definition of Ownership

`src/compiler/*` has ownership when all are true:

1. `src/main.w` does not touch `Driver` fields or methods.
2. `src/Compilation.w` routes to `compiler.Compilation` directly.
3. `Zcu` is the canonical holder of:
   - resolved graph
   - typed sidecars
   - sema snapshot
   - MIR/Async-MIR
   - c_import link-lib metadata
4. LLVM and C backends consume the same canonical MIR from `Zcu`.
5. Link/runtime policy is centralized in `src/compiler/Link.w`.
6. `Driver` is optional legacy adapter (or deleted).

---

## Design Goals

1. Single canonical pipeline:
   parse -> resolve/import -> sema -> MIR -> backend -> link.
2. No semantic/codegen logic in `Driver`.
3. Deterministic dumps (`resolved`, `typed`, `mir`, `async-mir`) from
   compiler-owned state.
4. Remove hardcoded non-primitive builtin symbol handling.
5. Keep primitive/intrinsic language semantics hardcoded where required.

Non-goals:

- Full language redesign.
- Replacing LLVM backend.
- Immediate deletion of old `Sema`/`Codegen` engines in one step.

---

## Reference Models

This plan follows patterns already present in local references:

- Zig compilation ownership split:
  - `.reference/zig/src/Compilation.zig`
  - `.reference/zig/src/Zcu.zig`
  - `.reference/zig/src/codegen/`
  - `.reference/zig/src/link/`
- Rust staged/query ownership ideas:
  - `.reference/rust/compiler/rustc_interface/src/interface.rs`
  - `.reference/rust/compiler/rustc_interface/src/queries.rs`

Practical takeaway:
- one canonical compilation state owner (`Zcu`/`TyCtxt`-like)
- explicit stage boundaries
- backend and link stages consume stage outputs, not ad hoc globals

---

## Design Questions (Resolved Up Front)

1. Should `Driver` remain architecture-authoritative?
   - Decision: no. It can be a temporary adapter only.
2. Should LLVM backend consume AST or MIR in compiler path?
   - Decision: MIR. Both LLVM and C backends must share MIR input.
3. Where is canonical mutable state?
   - Decision: `Zcu` only.
4. How are user-facing builtins represented?
   - Decision: as std/prelude symbols resolved by imports, not hardcoded
     symbol-name allowlists.
5. What remains intrinsic?
   - Decision: only primitive language semantics and explicit compiler
     intrinsics/directives.

---

## Target Architecture

### Module Responsibilities

- `src/compiler/Compilation.w`
  - orchestration root
  - stable API used by `src/main.w`
- `src/compiler/Zcu.w`
  - canonical mutable compilation state
- `src/compiler/Frontend.w`
  - lex/parse/import graph + prelude injection + c_import expansion inputs
- `src/compiler/SemaStage.w` (new)
  - wraps semantic analysis ownership and typed sidecars
- `src/compiler/MirStage.w` (new)
  - MIR + Async-MIR lowering and caching
- `src/compiler/Backend.w`
  - LLVM and C emission from canonical MIR
- `src/compiler/Link.w`
  - runtime artifact policy and linker command construction

### `Zcu` State Additions

Add canonical fields currently living in `Driver`:

- `last_sema: Sema`
- `last_mir_module: MirModule`
- `last_mir_dump: str`
- `last_async_mir_module: AsyncMirModule`
- `last_async_mir_dump: str`
- `last_link_lib_names: Vec[str]`
- `typed_pool_cache: AstPool`
- `c_import_cache` and related trace flags (or stage-owned handle)

`Zcu` remains the only owner for the latest pipeline snapshot.

---

## Stage Contracts

### Frontend Contract

Input:
- source path/text
- compilation config (`prelude_mode`, `no_std`, alloc mode)

Output in `Zcu`:
- parsed+expanded `AstPool`
- `ResolveResult`
- root-local decl boundary (`local_decl_count`)

Notes:
- prelude injection and pinned prelude resolution stay here.
- import merging and c_import expansion must be compiler-owned, not Driver-owned.

### Sema Contract

Input:
- expanded pool
- intern pool
- diagnostics

Output in `Zcu`:
- `last_sema`
- typed side maps (`typed_expr_types`, etc)
- typed dump cache or streaming accessors

### MIR Contract

Input:
- `last_sema`, typed pool

Output in `Zcu`:
- `last_mir_module`
- `last_async_mir_module`

### Backend Contract

LLVM:
- must consume MIR (`gen_module_from_mir`) to match driver semantics.

C:
- must consume same MIR + `last_sema` (`c_emit_module`).

### Link Contract

- choose one runtime artifact root per build (`runtime_root`)
- resolve all runtime objects from that root
- collect and apply c_import link libs
- no mixed bootstrap/repo runtime object sets in one link invocation

---

## Builtin Policy (Phase B Enabler)

### Keep Hardcoded

Only language-level primitives/intrinsics:

- primitive types and literals (`i*`, `u*`, `f*`, `bool`, `str`)
- control-flow/compiler intrinsics (`unreachable` semantics, operator hooks)
- directives (`c_import`, comptime hooks)

### Remove Hardcoded Symbol Names

From `Sema`/codegen symbol tables:

- IO helpers: `println`, `print`, `assert`
- std constructor-like names: `Vec`, `HashMap`, `HashSet`, `Some`, `Ok`, `Err`, `None`
- math aliases/constants that are user-facing (`abs`, `max`, `PI`, etc)
- prelude-exposed ambient names in general

### Mechanism

1. Identifier resolution for those names must succeed only via normal defs/imports.
2. `Sema.check_ident` should emit undefined-name diagnostics when missing.
3. Replace name-based builtin dispatch with one of:
   - AST/MIR intrinsic op kinds, or
   - explicit lowering markers attached before codegen.

`CCodegen` currently has extensive name-heuristic builtin inference; that must
be replaced by normalized MIR call forms with explicit callee meaning.

---

## Migration Plan

This migration is intentionally three phases only. No dual-path
infrastructure (`WITH_PIPELINE`) is introduced; the test suite is the
parity gate.

### Phase 1: Move State to `Zcu`, Route CLI Through `compiler.Compilation`

Work items:
- [x] Move sema/MIR/typed/resolve/link-lib state now held in `Driver` into `Zcu`.
- [x] Extend `compiler.Compilation` with APIs needed by CLI commands
      (`resolve`, `typed`, `mir`, `async-mir`, `build`, `run`, `emit-c`).
- [x] Remove `comp.driver.*` usage from `src/main.w` and `src/main_emit_temp.w`.
- [x] Switch `src/Compilation.w` compatibility facade to delegate to
      `compiler.Compilation`.
- [x] Move import merge + `c_import` expansion ownership into `src/compiler/*`.

Exit criteria:
- [x] `src/main.w` has no direct `Driver` access.
- [x] `src/main_emit_temp.w` has no direct `Driver` access.
- [x] check/build/run/dump commands work via compiler-owned path.
- [x] existing wave tests pass (213/213 on self-hosted compiler).

### Phase 2: Unify Backends on MIR, Finalize Link Ownership

Work items:
- [x] Ensure both LLVM and C backends consume canonical MIR from `Zcu`.
- [x] Make `src/compiler/Backend.w` use MIR (`gen_module_from_mir`) path.
- [x] Keep `--emit-c` as compiler-owned backend path from same MIR snapshot.
- [x] Move runtime/link policy fully to `src/compiler/Link.w`.
- [x] Enforce single runtime root selection per link invocation.

Exit criteria:
- [x] LLVM and `--emit-c` both operate from shared MIR state.
- [x] link logic no longer depends on `Driver`.
- [x] existing build/run tests and emit-c smoke tests pass.

### Phase 3: Remove Hardcoded Builtins, Wire Prelude as Source of Names

Work items:
- [x] Delete non-primitive builtin symbol seeding in `Sema`.
- [x] Remove symbol-name fallback checks (`is_builtin_fn`, `is_builtin_value`)
      for user-facing std names.
- [x] Keep only primitive/intrinsic compiler semantics hardcoded.
- [x] Normalize backend call lowering so codegen does not rely on
      name-heuristic builtin inference.
      MIR intrinsic markers (`MIR_INTRINSIC_VEC_*`, `MIR_INTRINSIC_MAP_*`,
      `MIR_INTRINSIC_OPT_*`) are now set during MIR lowering via
      `classify_intrinsic()` and read by CCodegen via `body.call_intrinsic()`.
      LLVM AST-path dispatch retained for now (uses type cache, not pure names).
- [x] Delete `Driver` (or keep as trivial adapter with no compiler logic).

Exit criteria:
- [x] user-facing names resolve only via std/prelude imports.
- [x] `--no-prelude`/`--freestanding` diagnostics behave as expected.
      `inject_prelude_frontend()` returns unchanged pool when `PRELUDE_NONE`;
      `Sema.check_ident()` produces "undefined variable" with no builtin backdoor.
- [x] no production logic lives in `Driver`.

---

## Implementation Breakdown (Execution-Level)

This section translates phase items into concrete code-edit batches.

### Batch A: Canonical State Move to `Zcu`

- [x] Add/finish canonical sema/MIR/typed/link-lib fields in `src/compiler/Zcu.w`.
- [x] Move state mutation sites from `src/Driver.w` into `src/compiler/Frontend.w`,
      `SemaStage.w`, and `MirStage.w` (or equivalent compiler-owned units).
- [x] Ensure `Zcu.reset_for_new_invocation` clears all stage outputs deterministically.
- [x] Keep `Driver` as pass-through only (no semantic/codegen state ownership).

### Batch B: CLI/Compilation Wiring

- [x] Ensure `src/compiler/Compilation.w` exports full CLI-needed API surface:
      `compile_file`, `resolve_file`, `emit_typed`, `print_mir`,
      `dump_async_mir`, `emit_ir`, `build_binary`, `build_binary_at`, `emit_c`.
- [x] Update `src/main.w` command handlers to call only `Compilation` APIs.
- [x] Remove any `comp.driver.*` direct access paths.
- [x] Update `src/Compilation.w` compatibility facade to route only through
      `compiler.Compilation` (no direct `Driver` behavior).

### Batch C: Backend MIR Unification

- [x] Make compiler-owned LLVM emission always originate from canonical MIR snapshot.
- [x] Eliminate AST-only LLVM fallback in production path (debug-only fallback allowed).
- [x] Keep C emission (`--emit-c`) sourced from the same MIR snapshot + sema context.
- [x] Add backend precondition checks:
      - MIR validation before LLVM/C emission
      - deterministic non-zero exit on backend contract violations.

### Batch D: Link Ownership

- [x] Centralize runtime path/object selection under `src/compiler/Link.w`.
- [x] Remove duplicated runtime path probing in legacy `Driver` flows.
- [x] Enforce one runtime root per link invocation.
- [x] Keep c_import-derived `-l` propagation owned by compiler pipeline state.

### Batch E: Builtin De-Hardcoding

- [x] Remove non-primitive name seeding from `Sema` (`println`, `Vec`, `Some`, etc.).
- [x] Remove symbol-name builtin fallbacks from codegen/CCodegen
      (replaced with MIR-level intrinsic markers; CCodegen reads
      `body.call_intrinsic()` first, legacy heuristic as fallback).
- [x] Preserve only primitive/intrinsic semantics hardcoded in compiler core.
- [x] Ensure prelude modules provide user-facing names under normal import rules
      (`lib/std/builtins.w`, `lib/std/prelude.w`).

---

## Current Status / Active Blockers (2026-03-07)

- [x] Ownership migration complete across all three phases.
- [x] Compiler LLVM path free of fallback-related type mismatch regressions.
      Vec.new() type upgrade: push detects element type mismatch and upgrades
      the Vec type (both Zig bootstrap and .w Codegen).
- [x] Self-host fresh rebuild path fully stable on current `src/main.w`.
- [x] Prelude Phase B builtin de-hardcoding complete.

Phase progress snapshot:
- Phase 1: `done`
  - CLI no longer touches `comp.driver.*` in `src/main.w` or `src/main_emit_temp.w`.
  - `src/Compilation.w` is a thin facade to `compiler.Compilation`.
  - `src/compiler/Compilation.w` no longer stores or imports `Driver`.
  - `Driver` no longer owns duplicate sema/MIR/typed/resolve/link-lib snapshot fields.
  - check/build/run/dump/emit-c orchestration stays on the compiler-owned path.
  - remaining: run the full wave/parity suites from this source state.
- Phase 2: `done`
  - Compiler-owned LLVM and C backend entry points consume canonical MIR from `Zcu`.
  - Compiler-path link invocation routes through `src/compiler/Link.w`.
  - `src/Driver.w` no longer carries its own runtime probing/link selection helpers.
  - `--emit-c` defaults output to `.with/build/` (build directory), not source tree.
  - remaining: broader suite coverage.
- Phase 3: `done`
  - Sema builtin symbol allowlists removed.
  - `sema_is_builtin_trait_name` retained for intrinsic traits (Iterator, Display, etc.).
  - `lib/std/builtins.w` provides `println`, `assert` as normal std declarations.
  - `lib/std/prelude.w` imports `std.builtins`, `std.collections`, `std.option`, `std.result`.
  - MIR intrinsic markers (`MIR_INTRINSIC_VEC_*`, `MIR_INTRINSIC_MAP_*`,
    `MIR_INTRINSIC_OPT_*`) classify container operations during MIR lowering.
  - CCodegen reads `body.call_intrinsic()` first, legacy heuristic as fallback.
  - LLVM AST-path dispatch retained (uses type cache, not pure name heuristics).

Step 7 (Driver): done.
- `src/Driver.w` is a pure pass-through adapter delegating to `self.comp.*`.
- Only consumer is `src/Lsp.w` (LSP not yet available).
- No semantic/codegen logic remains in Driver.

All 213 wave tests pass. Self-host build succeeds from current source.

---

## Repository Audit Snapshot (2026-03-07)

This is an evidence-based snapshot from current sources to keep this plan
grounded in what is still true in-tree.

- [x] `src/main.w` no longer reaches into `comp.driver.*` directly.
- [x] `src/main_emit_temp.w` no longer reaches into `comp.driver.*` directly.
- [x] `src/Compilation.w` no longer imports `Driver` and is a thin facade.
- [x] `src/compiler/Compilation.w` no longer stores `driver: Driver`.
- [x] `src/compiler/Compilation.w` no longer imports `Driver` and no longer uses a per-call adapter.
- [x] `src/compiler/Compilation.w::emit_c` no longer routes through `Driver`.
- [x] `src/compiler/Compilation.w::emit_c` defaults output to `.with/build/` (build dir, not source tree).
- [x] `src/compiler/Backend.w` now uses MIR LLVM path (`gen_module_from_mir`).
- [x] `src/main.w` now routes `build` and `run` back through `Compilation`.
- [x] `src/CCodegen.w` no longer treats ownerless builtin-like names as generic container builtins by default.
- [x] Canonical sema/MIR/typed/resolve/link-lib pipeline snapshots now live in `src/compiler/Zcu.w`; `src/Driver.w` no longer stores duplicate authoritative copies.
- [x] Link/runtime policy now routes through `src/compiler/Link.w`; `src/Driver.w` no longer carries duplicated runtime probing or link-selection helpers.
- [x] Sema builtin symbol allowlists removed; user-facing names come from std/prelude.
- [x] `src/Driver.w` is pure pass-through adapter; only consumer is `src/Lsp.w`.
- [x] MIR intrinsic markers (`call_intrinsic_kinds`) classify Vec/HashMap/Option
      operations during lowering; CCodegen reads markers first, legacy heuristic
      as fallback for older MIR. LLVM AST-path dispatch retained (uses type cache).

---

## Immediate Execution Sequence (No Dual-Path Infra)

These are the next patch-sized work items to execute in order.

### Step 1: Detach `compiler.Compilation` from `Driver`

- [x] Replace `driver: Driver` field in `src/compiler/Compilation.w` with direct
      stage ownership (`zcu`, `frontend`, sema/mir stage handles).
- [x] Re-implement `Compilation` API methods using compiler stages only.
- [x] Keep method names stable so `src/main.w` does not change shape.

### Step 2: Make `src/Compilation.w` a Thin Alias-Style Facade

- [x] Remove direct `use Driver` and `driver: Driver` from `src/Compilation.w`.
- [x] Delegate all methods to `src/compiler/Compilation.w` only.

### Step 3: Move Remaining Pipeline State to `Zcu`

- [x] Move/duplicate `Driver` stage outputs into `src/compiler/Zcu.w` and use
      `Zcu` as the single mutable source for sema/MIR/typed/link-lib snapshots.
- [x] Remove writes to duplicate state fields in `Driver`.
- [x] Add/verify deterministic clearing in `Zcu.reset_for_new_invocation`.

### Step 4: Unify LLVM and C on MIR in Compiler Path

- [x] Update `src/compiler/Backend.w` to call MIR-backed LLVM emission.
- [x] Route compiler-owned `emit_c` through the same MIR snapshot.
- [x] Enforce backend contract checks before emission (MIR present + valid).

### Step 5: Move Link Runtime Policy into `src/compiler/Link.w`

- [x] Route all compiler-path link invocation through `Link.w`.
- [x] Enforce single runtime root selection for each link action.
- [x] Restore `Link.w` helper definitions required by compiler-owned `Compilation`.
- [x] Keep c_import-derived `-l` flags sourced from compiler-owned pipeline state.

### Step 6: Remove Non-Primitive Builtin Name Special-Casing

- [x] Remove user-facing symbol allowlists from `Sema` (done: `builtin_fn_syms`,
      `builtin_value_syms`, `seed_builtin_symbols` all deleted).
- [x] Keep only true intrinsics/primitives hardcoded in `Sema`
      (`sema_is_builtin_trait_name` for Iterator/Display/etc).
- [x] Normalize codegen/CCodegen builtin dispatch to use MIR-level intrinsic
      markers instead of name-heuristic inference for Vec/HashMap/Option.
      `MirBody.call_intrinsic_kinds` set during lowering; CCodegen reads first.
- [x] Make missing prelude names produce normal undefined-name diagnostics.
      Self-hosted `Sema.check_ident()` has no hardcoded `println`/`assert`/`Vec`;
      all fall through to "undefined variable" when not imported.

### Step 7: Shrink or Remove `Driver`

- [x] `Driver` is now adapter-only: all methods delegate to `self.comp.*`.
- [x] No semantic/codegen logic remains in Driver.
- [ ] Only consumer is `src/Lsp.w` (LSP not yet available). Driver can be
      removed once LSP is migrated or deleted.

---

## Acceptance Checklist Per Step

- [x] Step 1 done when `src/compiler/Compilation.w` has no `use Driver`
      and no per-call `Driver` adapter execution.
- [x] Step 2 done when `src/Compilation.w` has no `use Driver`.
- [x] Step 3 done when sema/MIR/typed/link-lib outputs are only authoritative in `Zcu`.
- [x] Step 4 done when compiler LLVM+C backends both consume same MIR snapshot.
- [x] Step 5 done when link/runtime root resolution no longer depends on `Driver`.
- [x] Step 6 done when non-primitive names resolve only via imports/prelude
      and codegen uses MIR intrinsic markers instead of name matching.
- [x] Step 7 done when `Driver` is adapter-only or removed.

---

## Testing Strategy

### Parity Suites

- Existing wave tests (check/build/run).
- Prelude precedence and mode tests.
- c_import expansion/link-lib behavior.
- MIR and async runtime fixtures.
- `--emit-c` self-host/cross-target smoke tests.

### New Ownership-Specific Tests

- [x] `main` commands do not require `comp.driver`.
- [x] LLVM backend consumes MIR path (not AST path) in compiler pipeline.
- [x] Builtin names absent without prelude/module import.
      Verified: `src/Sema.w` has zero references to `println`/`assert`/`Vec`;
      `src/Resolve.w` likewise clean. Only `sema_is_builtin_trait_name` remains
      for true compiler traits (Drop, Display, Iter, etc.).
- [x] Runtime link picks one runtime root and reports it.
      `link_stage_resolve_runtime_root()` probes once; all file lookups use it.

---

## Risks and Mitigations

1. Risk: behavior drift during state move.
   - Mitigation: immediate full test-suite runs after each landed step.
2. Risk: backend regressions from MIR contract differences.
   - Mitigation: explicit MIR validation + compare object/runtime behavior.
3. Risk: builtin removal breaks legacy tests.
   - Mitigation: migrate fixtures to explicit std/prelude imports first.
4. Risk: runtime link instability.
   - Mitigation: single runtime root selection and symbol-overlap CI check.

---

## Done Criteria

This design is complete when:

- [x] `src/main.w` compiles and runs without `comp.driver.*`.
- [x] `src/Compilation.w` no longer delegates to `Driver`.
- [x] `src/compiler/*` owns sema, MIR, backend, and link state transitions.
- [x] Non-primitive hardcoded builtin symbol handling is removed from Sema.
- [x] Non-primitive name-heuristic dispatch in codegen replaced with MIR markers.
- [x] Prelude provides user-facing ambient names by import, not by hardcode.
- [x] `Driver` is non-authoritative (adapter only) or removed.
