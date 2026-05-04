# Complete Test Cases TODO

Goal: close remaining test-automation gaps across Waves 1-11 while keeping Stage0 as oracle and self-host as required pass target.

## Wave 1 (Foundations)

- [x] Add InternPool stress test for determinism across large insert volumes and table growth.
- [x] Add SourceMap UTF-8/CRLF line-column mapping test cases.
- [x] Add Diagnostic rendering test for multi-label ordering determinism.

## Wave 2 (Lexer)

- [x] Add invalid-token tests for unterminated raw/triple strings and invalid escapes.
- [x] Add numeric-literal edge tests (invalid separators/suffix combinations).
- [x] Add lexer fuzz-smoke corpus for deterministic tokenization on malformed input.

## Wave 3 (Parser + AST)

- [x] Add parser multi-error recovery golden tests (ensure recovery reaches later top-level items).
- [x] Add malformed `c_import` syntax matrix tests.
- [x] Add deeper precedence/associativity edge tests around chained sugar forms.

## Wave 4 (Resolve / HIR)

- [x] Add resolved-content golden assertions for representative module graphs (not just header/determinism).
- [x] Add duplicate-import and alias-cycle graph tests.
- [x] Add `c_import` link-lib ordering/dedup tests in resolve output.
- [x] Add nested unresolved-import diagnostics coverage.

## Wave 5 (Types + Traits Core)

- [x] Add dedicated orphan-rule violation test coverage.
- [x] Add shadowing diagnostic span-accuracy tests.
- [x] Add associated-type and where-clause bound failure tests.

## Wave 6 (Sema / Typed IR)

- [x] Add method resolution ambiguity/order tests.
- [x] Add branch/join type unification edge cases for break-with-value control flow.
- [x] Add nested pattern-binding shadowing tests across control-flow branches.
- [x] Add chained `if let` typed-coverage tests after parser support is enabled.

## Wave 7 (MIR)

- [x] Add dedicated MIR cleanup-edge and unwind-shape tests.
- [x] Add loop-drop interaction tests with explicit MIR structural assertions.
- [x] Add storage live/dead pairing validation tests for complex control flow.
- [x] Add MIR boundary tests for async/generator constructs before Async-MIR lowering.
- [x] Expand `test/wave7/cases/` beyond drop-only focus.

## Wave 8 (Borrow Checking)

- [x] Close and remove KNOWN_DIVERGENCE for `copy_drop_exclusive_copy_drop_conflict_fail`.
- [x] Close and remove KNOWN_DIVERGENCE for `copy_drop_exclusive_noncopy_field_fail`.
- [x] Close and remove KNOWN_DIVERGENCE for `task_ephemeral_borrow_warn`.
- [x] Close and remove KNOWN_DIVERGENCE for `task_ephemeral_assign_warn`.
- [x] Close and remove KNOWN_DIVERGENCE for `task_ephemeral_async_block_warn`.
- [x] Close and remove KNOWN_DIVERGENCE for `may_suspend_guard_fail`.
- [x] Add MIR dataflow-style borrow tests (predecessor/successor/liveness-sensitive cases).
- [x] Add branch+loop NLL stress cases with disjoint field borrows and reborrows.

## Wave 9 (Async-MIR)

- [x] Add run-mode channel close/error/cancel interaction tests.
- [x] Add `select await` tie/ordering determinism tests.
- [x] Add Async-MIR structure checks for suspend/resume state transitions.
- [x] Add runtime-linkage negative tests for sync-vs-async symbol requirements.

## Wave 10 (Codegen)

- [x] Add successful `ir` mode structural parity checks (not status-only).
- [x] Add vtable slot-ordering assertions for deterministic dyn dispatch layout.
- [x] Add enum layout/tag/payload offset runtime probes (unit + parity).
- [x] Add ABI aggregate pass/return strategy tests.
- [x] Add cross-module monomorphization dedup and missing-instantiation regression tests.

## Wave 11 (Driver + CLI + Linking + c_import)

- [x] Create `test/wave11/cases/` corpus files.
- [x] Create `test/wave11/driver_corpus.txt`.
- [x] Create `scripts/run_wave11_driver_unit_tests.sh`.
- [x] Create `scripts/run_wave11_driver_parity.sh`.
- [x] Create `test/wave11/coverage_manifest.txt` and `test/wave11/coverage_matrix.md`.
- [x] Create `scripts/verify_wave11_coverage.sh`.
- [x] Add CLI command/flag diagnostics tests (`help`, `version`, unknown command, bad flags).
- [x] Add `check/build/run/test/clean` orchestration behavior tests.
- [x] Add import-path regression tests (relative/package-qualified/nested).
- [x] Add link command/runtime object selection tests.
- [x] Add `c_import` cache hit/miss/invalidation tests.
- [x] Add `c_import` macro diagnostics tests.

## Cross-Wave Harness Hardening

- [x] Add coverage-manifest verification gates for Waves 2-8 (Wave 9/10 style anti-shrink checks).
- [x] Add CI target that runs all wave unit+parity harnesses in one command.
- [x] Add periodic report script for PASS/FAIL/KNOWN_DIVERGENCE counts per wave.
