# Audit: src/Types.w @ 450733e5

## Source (full, 6 lines)
```
1|// Types — Facade re-exporting Sema type definitions.
2|//
3|// The implementation lives in Sema; this facade provides
4|// a stable module boundary matching the phase plan terminology.
5|
6|use Sema
```

## Targets
- T13 ownership/drop: N/A — no values, allocations, ctors/dtors, move/borrow in facade; single `use Sema` import has no ownership semantics. No drop glue needed.
- T15 migration fidelity: N/A — no migrated logic; facade only. Counterpart check: no legacy `Types` implementation to compare; Sema is the canonical owner per header comment.
- T22 spec conformance: PASS — `use Sema` re-export pattern matches other facades; module compiles under seed compiler (see probe P1).

## Callers / refutation
- Search: `grep -rn "use Types\|Types\." src --include=*.w` returned no direct consumers of `Types.`-qualified symbols in this snapshot (facade reserved for phase-plan boundary stability). No caller contradicts facade role. No defect to refute.

## Probes
- P1 EXECUTED: `out/bootstrap/bin/with-stage1 check src/Types.w` → exit 0, no diagnostics (seed compiler accepts facade).
- Negative control HELD: reason — facade has no runtime behavior to negate; a negative probe (e.g. asserting a type error) would test Sema, not this module, and is out of scope for a pure re-export.

## Findings
None.

## Verdict
VERDICT: COMPLETE
