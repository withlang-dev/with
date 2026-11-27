# D245 — `ok >= C` status predicate for non-negative-count C APIs (delegated)

**Date:** 2026-11-27. **Status:** delegated under D237 (mission-settled; Eric vetoes by revert).

**Laws:** Law 1 (*The compiler never asks for what it already knows*), Law 4 (*A fact is inferred only when being wrong cannot create unsafety*), Law 11 (*The compiler guarantees safety, not correctness of intent*), Law 12 (*The programmer has the last word on what the compiler cannot see*).

---

## Question

Many C APIs signal failure with negative error codes and signal success with a non-negative integer count (`>= 0`, or `>= C`):
- `pcre2_substitute_8` (`c.pcre2`, #3152): returns the number of substitutions (`>= 0`) and writes back `outlengthptr` (`capacity ... inout`), or returns a negative `PCRE2_ERROR_*` code.
- `pcre2_match_8` / `pcre2_dfa_match_8` (`c.pcre2`, #3152): returns the number of captured substrings (`>= 0`), or a negative `PCRE2_ERROR_*` code.
- POSIX and libc-style counted APIs (`read`, `write`, `snprintf`-like bounds checks): return `>= 0` on success, `< 0` on error.

Currently `ok` only accepts an equality list of constants (`ok C` or `ok C1, C2, ...`). It cannot express `ok >= 0` because the set of non-negative counts is unbounded, blocking `capacity ... inout` on `pcre2_substitute_8` (which requires a status contract per §16.2b.8) and leaving non-negative-count operations unable to project into `Result`.

Should `ok` accept a lower-bound status predicate `ok >= C` (where `C` is a compile-time integer constant or integer literal) alongside `ok C` and `ok C1, C2, ...`?

## What the spec says

- §16.2b.4 ("Production and status"): an `ok` clause states the status convention explicitly ("There is no rule that `0` means success"); with one constant `ok C`, the matched status is uniquely known so `Ok` omits it; with several constants `ok C1, C2`, `Ok` carries the matched status alongside any produced/filled value.
- §16.2b.8: `buffer param P capacity param L inout` requires an `ok` status contract when the C function returns a status, presenting `Result[usize, E]`.

## Mission fit

- **Law 1:** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* A non-negative status convention cannot be enumerated as `ok 0, 1, 2, ...`; spelling `ok >= 0` states the exact C convention once so the facade can present `Result` without forcing users into raw calls or `unsafe`.
- **Law 4:** *Test: what happens if this inference is wrong?* Nothing is inferred. The contract explicitly states `ok >= C` with a citation, never assuming `>= 0` by default. Failure (`status < C`) returns `Err(E.Failed(status))`, and `capacity ... inout` still performs its runtime bounds check before slicing.
- **Law 11:** *Test: is this needed to keep a guarantee, or does it only protect the programmer from themselves?* Restricting `ok` to equality tests keeps no safety guarantee that `>= C` lacks; refusing `ok >= C` on variadic setters (where MIR guards a single equality edge) keeps the existing invariant intact.
- **Law 12:** The contract author states the foreign status predicate (`ok C`, `ok C1, C2`, or `ok >= C`), and the compiler verifies the constant and generates the checked wrapper.

## Decision

Extend `ok` in contracts and registry facts to accept a lower-bound predicate `ok >= C` (where `C` is an imported compile-time integer constant or integer literal):

- Failure test: `status < C`.
- On a status-returning `fn` item without `capacity ... inout`, the matched status is not a single constant, so `Ok` carries it just as for multi-constant `ok C1, C2`:
  - Plain `fn`: `Result[StatusT, E]`.
  - With `fills`: `Result[(StatusT, T), E]`.
  - Resource `from` / `init`: `Result[(StatusT, R), RError]`.
- On a `fn` item with `buffer param P capacity param L inout`: `Result[usize, E]` (the validated written length, matching `ok C`).
- On a variadic setter (`variadic param ...`), `ok >= C` is refused (variadic setters guard an equality edge on one constant).
