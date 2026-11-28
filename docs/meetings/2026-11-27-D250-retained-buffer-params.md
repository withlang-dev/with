# D250 — Retained buffer and value-record parameters (`retains param N by param 0`)

- **Date:** 2026-11-27
- **Status:** Delegated (D237 — settled by `docs/mission.md` Law 3, Law 5, Law 9; #3149)

## Context

Many C libraries configure a resource to read from or write into caller-owned
storage that must remain alive until the resource is destroyed (or reconfigured):
for example libyaml's `yaml_parser_set_input_string(parser, input, size)`
(retains `input`) and `yaml_emitter_set_output_string(emitter, output, size, size_written)`
(retains both `output` and `size_written`).

Previously, `retains param A by param 0` only accepted callbacks, `void *`
userdata, and C strings, forcing buffer/scalar-retaining setters to remain raw.

## Decision

1. Permit `retains param A by param 0` on non-variadic `fn` items when `param A`
   is paired by a `buffer` clause or described by a value-record/scalar clause
   (`reads`, `updates`, `fills`), regardless of clause order inside the `fn` item.
2. Hook non-variadic paired retentions (supporting up to two retained parameters
   per setter) into MIR's existing D194 `FOREIGN_PAIR_RETAIN` CFG checker
   (`MirForeignPairs.with`), tracing slice origins through `RK_SLICE`, `RK_REF`,
   `RK_USE`, and slice-returning borrows (e.g. `s.as_bytes()`).
3. Restrict `FOREIGN_PAIR_UNKNOWN` on unmodeled borrows to resources that carry
   a variadic callback/userdata pair, while enforcing `FOREIGN_STEP_ESCAPE` if a
   retention-only resource is moved out of scope or into an unmodeled callee.

## Mission fit

- **Law 3 (Memory Safety Without Suffering):** *Test: Can safe code produce UB,
  use-after-free, data race, or silent leak?* No; MIR rejects any path where the
  retained buffer or `mut` scalar drops, moves, or outlives-escape before the
  retaining resource is destroyed.
- **Law 5 (The Signature Is the Contract):** *Test: Can a reader determine
  ownership, borrowing, mutability, and fallibility from the signature alone?*
  `parser.set_input_string(input)` and `emitter.set_output_string(out_buf, mut written)`
  present exact slice and `mut` storage borrows with compiler-verified lifetimes.
- **Law 9 (First-Class C Interop):** *Test: Does calling a modeled C library
  require `unsafe`, a manual wrapper, or a foreign build step?* No; callers use
  libyaml's string parser/emitter safely with zero `unsafe`.
