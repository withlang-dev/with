# Phase 6 Coverage

This file tracks implemented Phase 6 milestone coverage for the current compiler state.

## Positive tests

- `test/cases/derive_all.w`
  - `@[derive(all)]` syntax acceptance
  - value `.clone()` behavior
  - copy-style assignment behavior on simple structs
- `test/cases/comptime_cascade_type_api.w`
  - `comptime fn` top-level syntax
  - `let mut` inside comptime functions
  - `T: type` generic bound parsing/checking
  - type-as-object methods: `T.fields()`, `T.name()`, `Type.size()`, `Type.align()`, `Type.is_copy()`
- `test/cases/derive_builder_generated.w`
  - `@[derive(Builder)]` syntax acceptance
  - `Type.builder()` static builder entry
  - chained builder field setters (`.field(value)`)
  - `.build().unwrap()` flow

## Negative tests

- `test/gaps/phase6/p6_derive_copy_ineligible.check_fail.w`
  - explicit `@[derive(Copy)]` on obviously non-copy field types is rejected.

## How to run

- Targeted Phase 6 suite: `./test/run_phase6_tests.sh`
- Full case suite: `./zig-out/bin/with test test/cases`
