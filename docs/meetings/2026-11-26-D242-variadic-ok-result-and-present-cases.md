# D242 — Variadic `ok` presents `Result` unconditionally; `present cases [stripping PREFIX]` presents typed per-option setters (delegated; #3128)

**Date:** 2026-11-26
**Status:** Delegated (D237/D98; direction ruled by Eric in D235 item 9a on 2026-11-25)
**Spec:** §16.2b.5, §31.5, §31.8.3 (v7.98)
**Issue:** #3128

## Decision

1. **Unconditional `Result` under `ok CONST` on variadic operations.** Every
   listed case of a variadic `fn` item with `ok CONST` returns `Result[T, E]`
   for `fills T` cases and `Result[Unit, E]` for all other cases (scalar,
   `str`, callback, implied userdata, retained pointer, sized retained
   pointer), where `E` is `<Presented>Error` or the facade's shared error
   type. MIR pair-flow reads the `Ok`/`Err` branches of `Result` (`?`,
   `match`, `if let`, `.is_ok()`, `.is_err()`, `.unwrap()`, `.expect()`)
   using the enum's Sema variant discriminants (invariant under
   `WITH_DEBUG_PERMUTE_TAGS`). Without `ok`, non-`fills` cases keep C's raw
   return type.

2. **One-line per-option presentation (`present cases [stripping PREFIX]`).**
   Adding `present cases` or `present cases stripping PREFIX` to a variadic
   `fn` item renders a typed per-option method (or free function when
   unhosted) for each listed case and each callback case's implied userdata
   selector, omitting the selector parameter and passing the selector
   constant directly to C. Names are derived by stripping leading `PREFIX`
   (when present) and lowercasing ASCII. Invalid names and collisions with
   other cases or host operations are refused in Sema. Per-option methods
   return `Result[Unit, E]` (or `Result[T, E]` for `fills T`) rather than
   consuming and returning `Self`: sequential calls compose with `?` on each
   line without losing the handle on error or contradicting `lend` / `&mut`
   exclusivity with retained borrows.

## Mission fit

- **Law 1 (Every redundant character is a compiler failure):** Checking every
  `setopt` against `CURLE_OK` and repeating `CURLOPT_` option tags at every
  call site was ceremony the contract already knew (`ok CURLE_OK` and the
  case table). `?` replaces status comparisons and `present cases stripping
  CURLOPT_` removes repeated option tags.
- **Law 4 (Safety is non-negotiable; no silent downgrade):** Unhandled
  `Result` failures on callback/retained setters are still rejected by MIR
  pair-flow; per-option methods participate identically in pair-flow and
  `until` retention releases.
- **Law 7 (C interop is first-class: raw C stays explicit, modeled C becomes
  humane):** Modeled variadic option APIs become idiomatic With methods
  (`easy.url(u)?`, `easy.nosignal(1)?`) while unlisted options remain raw
  under `unsafe`.
- **Law 12 (Contracts separate facts from presentation):** `present cases`
  is a pure presentation (`P`) clause — it changes only the shape under
  which already-stated variadic cases are called, never ownership or safety.
