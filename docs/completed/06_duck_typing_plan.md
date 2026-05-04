# Duck Typing — Implementation Plan

## Current State

The compiler already does most of the work:

- **Parser** (`src/Parser.w:3554-3658`): parses optional `[T: Trait]` bounds and `where` clauses; `bound_count` is 0 when no bounds are written
- **Sema** (`src/Sema.w:4720-4743`): `check_generic_trait_bounds` only iterates explicit bounds — if `bound_count == 0`, the inner loop is a no-op, so unbounded generics already pass sema
- **Sema** (`src/Sema.w:2524-2535`): `ensure_generic_substitutions` infers T from call arguments; only errors if T is unresolvable (doesn't appear in any parameter)
- **Codegen** (`src/Codegen.w:7476-7770`): `monomorphize_generic_call` substitutes concrete types and compiles the body — this is where duck typing is actually checked

**What this means:** unbounded `fn double[T](x: T): x + x` called with `double(5)` likely already compiles. The feature gap is not "make it work" — it's "make failures useful."

**What was broken:**
1. Binary op failures emit a warning and return undef (`gen_binary`, line ~6413) — bad code silently compiles
2. Method call failures emit a warning and return undef (`gen_method_call`, line ~8315) — same problem
3. No instantiation context in any diagnostic — user can't tell which `fn[T=concrete]` caused the failure
4. No test coverage for unbounded generic success or failure paths

## Phase 0 — Verify assumptions

- [x] Write a throwaway `fn double[T](x: T): x + x` with `double(5)` — confirm it compiles and runs correctly today
- [x] Write `double("hi")` — confirm it either silently miscompiles or crashes (not a clean error)
- [x] Write an unbounded generic that calls a method (`x.len()`) on a type that has it — confirm it works
- [x] Write the same calling a method on a type that doesn't have it — confirm the failure mode

## Phase 1 — Sema: make unbounded generics explicitly legal

**File:** `src/Sema.w`

- [x] Trace `check_generic_call` (line ~4596) end-to-end for an unbounded generic call — confirm `bound_count == 0` causes no rejection
- [x] Trace `ensure_generic_substitutions` (lines 2524-2535) — confirm inferrable params don't hit the `"unknown type"` fallback
- [x] If any code path rejects unbounded generics that should be allowed, remove the rejection — **no changes needed, already works**
- [x] Verify explicit bounds still work: `[T: Trait]` and `where T: Trait` must still fail early via `check_generic_trait_bounds` (lines 4720-4743)

## Phase 2 — Codegen: upgrade failure paths to real errors with context

**File:** `src/Codegen.w`

### 2a — Thread instantiation context through monomorphization

- [x] Add to Codegen struct: `mono_inst_name: i32` (symbol for "double__str"), `mono_inst_node: i32` (call-site node for source location)
- [x] Set both at the top of `monomorphize_generic_call` before compiling the body
- [x] Save/restore both when monomorphization completes (supports nested monomorphization)

### 2b — Binary operator failures → errors

- [x] In `gen_binary`: added early type-kind guard — non-integer, non-float types emit error before reaching integer ops
- [x] Error includes: operator symbol, concrete type name, instantiation context if available
- [x] Sets `had_error = 1`

### 2c — Method call failures → errors

- [x] In `gen_method_call`: upgraded warning to error with type name and method name
- [x] Error includes instantiation context if available
- [x] Sets `had_error = 1`

### 2d — Operator overload lookup

- [x] `try_op_overload` returns 0 on failure, falling through to builtin dispatch — confirmed; the error surfaces in 2b when builtin dispatch also fails

### Helper: `op_symbol`

- [x] Added `Codegen.op_symbol(op) -> str` mapping operator codes to human-readable symbols (`+`, `-`, `*`, etc.)

**Actual diagnostic output:**
```
error: unsupported operator '+' for type 'str' in instantiation of 'double__str'
error: no method 'len' on type 'i32' in instantiation of 'get_len__i32'
```

## Phase 3 — Tests

### Existing bound tests verified

- [x] `test/cases/err_trait_bound.w` — `[T: Show]` with wrong type → early error
- [x] `test/cases/where_violation.w` — `where T: Printable` violated → early error
- [x] `test/wave5/cases/generic_bound_pass.w` — `[T: Show]` with correct type → success

### New duck-typing tests

- [x] `test/cases/duck_binop_ok.w` — `fn double[T](x: T): x + x` with `i32` → `//! expect-stdout: 10`
- [x] `test/cases/duck_binop_fail.w` — `fn double[T](x: T): x + x` with `str` → `//! expect-build-fail: unsupported operator`
- [x] `test/cases/duck_method_ok.w` — unbounded generic calling `.len()` on `str` → success
- [x] `test/cases/duck_method_fail.w` — unbounded generic calling `.len()` on `i32` → `//! expect-build-fail: no method 'len'`
- [x] `test/cases/duck_unused_generic.w` — `fn broken[T](x: T): x.nope()` never called → `//! check-only` → no error

## Phase 4 — Docs

- [x] `docs/with-specification.md` — generics may omit bounds, checked at instantiation
- [x] `docs/with-idiomatic-guide.md` — when to use bounds vs duck typing
- [x] `docs/with-migration-guide.md` — unbounded generics now legal

## Phase 5 — Self-host validation

- [x] `make build`
- [x] `./out/bin/with-stage2 check src/main.w`
- [x] `make fixpoint` (byte-identical stage2 == stage3)

## Done criteria

All of the following are true:

- [x] Unbounded generics compile when the concrete type supports the required operations
- [x] Unbounded generics fail with a clear error when the concrete type does not support the required operations
- [x] The failure message mentions the concrete type, the operation, and the instantiation being compiled
- [x] Explicit `[T: Trait]` and `where T: Trait` bounds still fail early at the call site
- [x] Unused generic functions with broken bodies produce no error
- [x] The focused test set passes
- [x] `make build`, `./out/bin/with-stage2 check src/main.w`, and `make fixpoint` all pass
