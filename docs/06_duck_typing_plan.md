# Duck Typing Plan

## Decision

Resolve the operator question up front:

- operators are methods
- duck typing means "the concrete instantiated type has the required method or operator support"
- traits and `where` clauses remain valid as explicit contracts, but they are optional

This matches the current backend shape better than trying to move checking into sema first.

## Current Reality

The existing compiler already does most of the hard work:

- [src/Parser.w](/Users/eric/with/src/Parser.w) already parses optional bounds and `where` clauses
- [src/Sema.w](/Users/eric/with/src/Sema.w) currently enforces explicit bounds in `check_generic_call`
- [src/Sema.w](/Users/eric/with/src/Sema.w) skips generic bodies during normal body checking
- [src/Codegen.w](/Users/eric/with/src/Codegen.w) already monomorphizes generic calls and generic methods with concrete types

That means the minimal feature is not "build a second generic checker in sema." The minimal feature is:

1. stop rejecting unbounded generic calls in sema
2. let the existing monomorphizer instantiate concrete code
3. improve the backend failure message when the concrete type does not support an operation

## Implementation Plan

### Phase 1: make unbounded generics legal

Primary file: [src/Sema.w](/Users/eric/with/src/Sema.w)

Change `check_generic_call` so that:

- type argument inference still happens exactly as it does now
- explicit inline bounds are still enforced when they are written
- explicit `where` bounds are still enforced when they are written
- missing bounds are not treated as an error
- the call is allowed to proceed to codegen monomorphization

Important constraint:

- do not add a new sema-side instantiation engine
- do not add a new sema specialization cache beyond what is required for current behavior
- do not try to sema-check generic bodies abstractly

The feature here is removing the current eager rejection path for generic operations that are only meant to be checked after substitution.

### Phase 2: use codegen monomorphization as the concrete checker

Primary file: [src/Codegen.w](/Users/eric/with/src/Codegen.w)

Keep the current architecture:

- `monomorphize_generic_call` remains the place where concrete substitutions become real generated code
- generic method monomorphization remains in the existing codegen path

Required work:

- identify the existing failure paths for:
  - unsupported operators
  - missing methods
  - failed generic method dispatch
  - unresolved generic type substitution during monomorphization
- improve those messages so they mention the specialization being instantiated

Minimum acceptable diagnostic for first ship:

- error mentions the unsupported operation or missing method
- error mentions the concrete type
- error mentions `in instantiation of foo[T...]`

Example target shape:

```text
error: type `str` does not support operator `*`
  = note: in instantiation of triple[str]
```

Do not block the feature on full dual-site span rendering. That can come later.

### Phase 3: keep explicit bounds working

Primary files:

- [src/Sema.w](/Users/eric/with/src/Sema.w)
- existing bound-related tests under `test/`

Regression requirement:

- `[T: Trait]` still fails early when the concrete type does not satisfy the bound
- `where T: Trait` still fails early when the concrete type does not satisfy the bound
- boundless generics fall through to monomorphization-time checking instead

This preserves the useful distinction:

- write bounds when you want a contract and earlier caller-facing errors
- omit bounds when you want duck typing

## Test Plan

### Keep existing bound tests

These should continue to pass with minimal or no change:

- [test/cases/err_trait_bound.w](/Users/eric/with/test/cases/err_trait_bound.w)
- [test/cases/where_violation.w](/Users/eric/with/test/cases/where_violation.w)
- [test/wave5/cases/generic_bound_pass.w](/Users/eric/with/test/wave5/cases/generic_bound_pass.w)
- [test/wave5/cases/generic_bound_error.w](/Users/eric/with/test/wave5/cases/generic_bound_error.w)
- [test/wave5/cases/where_bound_failure_error.w](/Users/eric/with/test/wave5/cases/where_bound_failure_error.w)

### Add new duck-typing tests

Add a small focused set first, not a large matrix.

Suggested new cases:

- `test/cases/duck_generic_binop_ok.w`
  - `fn double[T](x: T): x + x`
  - instantiate with `i32` and `f64`
- `test/cases/duck_generic_binop_fail.w`
  - `fn triple[T](x: T): x * 3`
  - instantiate with `str`
  - expected error substring should mention unsupported `*` and the specialization name
- `test/cases/duck_generic_method_ok.w`
  - unbounded generic method call that succeeds for a concrete type with the method
- `test/cases/duck_generic_method_fail.w`
  - unbounded generic method call that fails for a concrete type without the method
- `test/wave10/cases/unused_generic.w`
  - keep as the regression that broken-but-unused generics still do not fail

### Only extend the harness if the first diagnostics need it

Primary file: [scripts/run_tests.sh](/Users/eric/with/scripts/run_tests.sh)

Do not pre-emptively redesign the runner.

If one `//! expect-error:` substring is enough, keep the harness as-is.
Only add repeated error/note expectations if the new diagnostics genuinely need it.

## Docs Plan

Docs should follow the implementation, not lead it.

### After the feature works, update:

- [docs/with-specification.md](/Users/eric/with/docs/with-specification.md)
- [docs/with-idiomatic-guide.md](/Users/eric/with/docs/with-idiomatic-guide.md)
- [docs/with-migration-guide.md](/Users/eric/with/docs/with-migration-guide.md)

Required doc changes:

- generics may omit bounds
- explicit bounds and `where` clauses are optional contracts
- unbounded generics are checked when instantiated
- operators are method-based for duck typing
- explicit bounds still provide earlier and clearer call-site errors

Keep the first doc pass small. The goal is to make the docs match the compiler, not to rewrite the entire generic chapter before the code lands.

## Delivery Sequence

### 1. Land the compiler behavior

- update `check_generic_call`
- preserve explicit bound enforcement
- let unbounded calls reach codegen monomorphization

Validation:

- `make build`
- `./out/bin/with-stage2 check src/main.w`

### 2. Improve the backend error message

- thread specialization context through the existing codegen failure path
- get the first useful duck-typing diagnostic shipped

Validation:

- targeted duck-typing failure tests
- targeted generic method tests

### 3. Add the small regression set

- bound tests still pass
- new duck-typing success and failure tests pass
- unused broken generics still stay lazy

Validation:

- `./scripts/run_tests.sh test/cases/duck_generic_*.w`
- `./scripts/run_tests.sh test/cases/err_trait_bound.w test/cases/where_violation.w`
- `./scripts/run_tests.sh test/wave5/cases/generic_bound_*.w test/wave5/cases/where_bound_failure_error.w`
- `./scripts/run_tests.sh test/wave10/cases/unused_generic.w`

### 4. Update docs to match shipped behavior

- spec
- idiomatic guide
- migration guide

### 5. Run full self-host validation

- `make build`
- `./out/bin/with-stage2 check src/main.w`
- `make fixpoint`

## Non-Goals For The First Landing

Do not turn the first implementation into a compiler rewrite.

Out of scope for the first pass:

- a new sema-side instantiation framework
- nested instantiation stacks and rich multi-site diagnostic plumbing
- full generic-body rechecking infrastructure in sema
- a large doc rewrite before the compiler behavior exists
- perfect diagnostics on day one

## Done Criteria

The first landing is done when all of the following are true:

- unbounded generics compile when the instantiated concrete type supports the required operations
- unbounded generics fail when the instantiated concrete type does not support the required operations
- explicit bounds and `where` clauses still fail early
- the failure message mentions the concrete operation/type and the specialization being instantiated
- the focused regression set passes
- `make build`, `./out/bin/with-stage2 check src/main.w`, and `make fixpoint` all pass
