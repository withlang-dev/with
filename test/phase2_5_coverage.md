# Phase 2-5 Coverage

This matrix tracks coverage against `docs/with-compiler-plan.md` for Phases 2-5.

## New pass tests added

- `test/cases/pipeline_chain.w`: pipeline chaining with function-call insertion.
- `test/cases/result_and_then.w`: `Result.and_then` chaining.
- `test/cases/expect_methods.w`: `Option.expect` and `Result.expect`.
- `test/cases/with_builder_expr.w`: `with` Form 2 non-Unit tail return behavior.
- `test/cases/with_nonlocal_return.w`: non-local `return` inside `with` body.
- `test/cases/async_sync_bridge.w`: async function call from sync function + `await`.
- `test/cases/select_await_three.w`: `select await` with 3 arms.
- `test/cases/trait_multibounds.w`: multiple trait bounds (`T: A + B`).
- `test/cases/dyn_default_dispatch.w`: dynamic dispatch calling a default trait method.

## Former gaps (now passing)

The regression set in `test/gaps/phase2_5/*.w` now runs as strict pass tests
via `test/run_phase2_5_gap_tests.sh` (no XFAIL entries):

- Phase 2:
  - advanced pipeline forms (`<|`, `>>`, `<<`, placeholders)
  - chained `if let`
  - parameter patterns
  - `match` in pipeline position
  - `error ... from`
  - record update shorthand in updates
  - enum accessor `_ref` / `_mut` codegen
  - `Result[Unit, E]` codegen path
- Phase 3:
  - raw pointer `.as_option()` runtime path
  - `std.fs` runtime path
- Phase 4:
  - `async:` blocks
  - `select await` branch blocks with `let...else`
  - `async scope`
  - `Task.cancel()`
  - `@[no_await_guard]`
- Phase 5:
  - `where` clauses
  - generic trait methods

## How to run

- Main case suite: `./zig-out/bin/with test test/cases`
- Gap suite: `./test/run_phase2_5_gap_tests.sh`
