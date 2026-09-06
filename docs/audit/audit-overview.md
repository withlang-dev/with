# With compiler integrity audit

Status: local working artifact  
Purpose: discover correctness and safety risks before choosing between in-place
re-engineering and a replacement compiler  
Authority: checked-out source and executable behavior; issue reports are
locators, not proof

## Definition of done

The audit is done only when the primary agent has personally:

- examined the complete source of all 287 tracked implementation modules;
- traced every applicable audit target through each module;
- inspected the exact source branch behind every retained finding;
- rerun every finding and negative control that is executable on the available
  toolchain; and
- recorded inline evidence sufficient to support every checked module.

Subagent reports are candidate evidence and discovery aids. They do not complete
a target or module until the primary agent independently verifies them.
Amendment 2026-09-04 (maintainer-authorized): subagents may perform COMPLETE
module examinations — full source read, target tracing, probe authoring and
execution, draft evidence. Check-off still requires primary-agent independent
verification (inspect exact source branches, re-run key probes/controls)
before the checklist box is ticked. Max 8 concurrent subagents (terminal
stability limit); subagents never edit the checklist or `modules/` evidence
files — they return evidence text and leave probes under `docs/audit/probes/`.

## Audit navigation

- [Module checklist](module-checklist.md) — 287 tracked implementation modules
- [Results index](results/README.md)

| Report | Audit targets | Result | Status |
|---:|---|---|---|
| 001 | 1 — validator trustworthiness | [audit](results/001-validator-trustworthiness/audit.md) | In progress |
| 002 | 2–3 — call/return correctness and function ABI | [audit](results/002-call-return-abi/audit.md) | In progress |
| 003 | 4 — suspension and cancellation | [audit](results/003-suspension-cancellation/audit.md) | In progress |
| 004 | 5, 7 — move/drop correctness and cleanup control flow | [audit](results/004-move-drop-cleanup/audit.md) | In progress |
| 005 | 6 — borrow and view provenance | [audit](results/005-borrow-view-provenance/audit.md) | In progress |
| 006 | 8–9, 12 — type identity, generics, and comptime | [audit](results/006-type-identity-generics/audit.md) | In progress |
| 007 | 10–11, 17 — names, closures, and C interop | [audit](results/007-names-closures-interop/audit.md) | In progress |
| 008 | 13–14, 23–24 — MIR/codegen, optimization, fallbacks, and duplicated decisions | [audit](results/008-mir-codegen-optimization/audit.md) | In progress |
| 009 | 18–19, 21–22 — build, platforms, harness, and specification coverage | [audit](results/009-build-platform-harness-spec/audit.md) | In progress |
| 010 | 15–16, 20 — runtime and standard-library foundations | [audit](results/010-runtime-stdlib-foundations/audit.md) | In progress |

First-pass progress:

- 10 of 10 assigned auditors completed bounded reports.
- All 24 audit targets have first-pass evidence.
- Primary-agent source examination: 78 of 287 modules complete.
- Primary-agent inline finding verification: in progress; no report is accepted
  wholesale from a subagent.
- 0 of 24 targets are complete; every target retains open matrices, confirmed
  defects, or both.
- 78 of 287 implementation modules are marked complete.

## Decision gate

The audit determines defect topology:

- If failures cluster around a small number of duplicated semantic seams,
  replace those subsystems in place.
- If phases pervasively and independently re-derive types, ownership, ABI,
  effects, cleanup, and identity, evaluate a smaller replacement compiler.
- If verification cannot distinguish correct output from output that merely
  compiles, repair verification before either path proceeds.

## Critical foundations

1. **Validator trustworthiness**
   Feed intentionally invalid MIR into every validator and prove it rejects the
   defect class it claims to cover.

2. **Call and return correctness**
   Audit return-slot initialization, indirect returns, caller/callee agreement,
   ignored results, divergence, and alternate exits.

3. **Function ABI authority**
   Verify every callee and call path consumes the same FnAbi, including
   methods, generics, closures, traits, externs, and receivers.

4. **Suspension and cancellation**
   Audit direct await, may-suspend calls, nested calls, cleanup calls,
   cancellation propagation, panic interaction, and task-result ownership.

5. **Move and drop correctness**
   Audit moves, partial moves, conditional initialization, reverse drop order,
   early returns, loops, branches, patterns, and aggregate fields.

6. **Borrow and view provenance**
   Trace references through Option, Result, patterns, the question-mark
   operators, collections, projections, closures, and contextual-Copy
   materialization.

7. **Cleanup control flow**
   Prove that defer, errdefer, with, cancellation, panic, question-mark, break,
   continue, goto, and ordinary return share correct cleanup semantics.

## Compiler consistency

8. **Type identity and sidecar completeness**
   Require every typed AST node to have valid, provenance-correct type
   information with no identifier-space or cross-file collisions.

9. **Generic specialization**
   Audit substitution identity, specialization caching, ownership modes, drop
   classification, ABI calculation, and recursive generic calls.

10. **Name and symbol resolution**
    Audit prelude precedence, imports, aliases, module identity, shadowing,
    cross-file spans, methods, traits, and generated symbols.

11. **Closure and dynamic-call semantics**
    Audit capture ownership, callable ABI, indirect may-suspend calls, closure
    lifetime, trait dispatch, and cleanup of captured values.

12. **Comptime/runtime equivalence**
    Prove that types, collections, ownership, errors, control flow, and generic
    behavior do not change meaning between comptime and runtime.

13. **MIR/codegen agreement**
    Prove that every MIR type, place, ABI mode, drop, cleanup edge, and return
    path is emitted faithfully at -O1.

14. **Optimization robustness**
    Test for latent undefined behavior and miscompilation exposed by -O1.
    Use -O0 only as an explicitly justified temporary diagnostic.

## Runtime and toolchain integrity

15. **Allocator and container ownership**
    Audit Vec, string, Box, and collection buffers; reallocations; slices;
    transferred storage; custom allocators; leaks; invalid frees; and double
    drops.

16. **Fiber, channel, and synchronization runtime**
    Audit lifecycle state, result buffers, cancellation races, cleanup joins,
    channel payload ownership, worker scheduling, and Windows parity.

17. **C interop and migration boundaries**
    Audit imported ABI, ownership overlays, layouts, callbacks, variadics, link
    names, C strings, macros, and the prohibition on silent translation stubs.

18. **Build and artifact provenance**
    Audit stage inputs, cache keys, generated sources, embedded stdlib/runtime,
    stale binaries, hybrid artifacts, fixpoint, seed updates, and release
    packaging.

19. **Platform agreement**
    Prove Darwin, Linux, Windows, x86_64, and arm64 agree on ABI, runtime
    behavior, panic codes, async behavior, and required test coverage.

20. **Standard-library unsafe foundations**
    Audit the small set of primitives underlying collections, strings, tasks,
    regex, zlib, filesystem, and networking.

## Verification integrity

21. **Test-harness honesty**
    Audit known-issue handling, skips, expected failures, exit-code parsing,
    crash detection, allocator verdict parsing, and false-green paths.

22. **Specification coverage**
    Map every normative rule to executable positive, negative, edge-case, and
    composition tests.

23. **Silent fallback inventory**
    Inspect every compiler, migrator, and codegen failure path for placeholders,
    dropped constructs, default values, or continued compilation.

24. **Duplicated semantic decisions**
    Find every question answered in more than one place, including ABI, Copy,
    drop needs, may-suspend, type identity, layout, reachability, and ownership.

## Required evidence for each target

Each completed audit target must record:

- exact source authorities;
- every competing producer or consumer of the audited fact;
- executable evidence and negative controls;
- minimal reproductions for each confirmed defect;
- existing issues touched and candidate unreported issues;
- severity, blast radius, and confidence;
- the root cause at the exact function, branch, and condition;
- the recommended repair boundary and regression matrix.

Passing builds and tests are supporting evidence, not correctness proof.
