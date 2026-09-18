# Audit results

Inventory snapshot: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Results are organized by audit target. A target remains in progress until its full source inventory, negative-control matrix, findings, blast radius, and repair boundary are recorded.

| ID | Target | Status | Result |
|---:|---|---|---|
| 001 | Validator trustworthiness | In progress | [audit](001-validator-trustworthiness/audit.md) |
| 002 | Call/return correctness and function ABI | In progress | [audit](002-call-return-abi/audit.md) |
| 003 | Suspension and cancellation | In progress | [audit](003-suspension-cancellation/audit.md) |
| 004 | Move/drop correctness and cleanup control flow | In progress | [audit](004-move-drop-cleanup/audit.md) |
| 005 | Borrow and view provenance | In progress | [audit](005-borrow-view-provenance/audit.md) |
| 006 | Type identity, generic specialization, and comptime | In progress | [audit](006-type-identity-generics/audit.md) |
| 007 | Name resolution, closures/dynamic calls, and C interop | In progress | [audit](007-names-closures-interop/audit.md) |
| 008 | MIR/codegen, optimization, fallbacks, and duplicated decisions | In progress | [audit](008-mir-codegen-optimization/audit.md) |
| 009 | Build, platforms, harness, and specification coverage | In progress | [audit](009-build-platform-harness-spec/audit.md) |
| 010 | Runtime and standard-library foundations | In progress | [audit](010-runtime-stdlib-foundations/audit.md) |

## Status meanings

- **In progress:** evidence exists, but the target matrix is incomplete.
- **Complete:** every required evidence item in the overview is satisfied.
- **Blocked:** a concrete external dependency prevents further evidence collection.
