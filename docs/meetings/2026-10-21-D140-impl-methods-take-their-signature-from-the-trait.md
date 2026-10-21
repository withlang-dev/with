# D140 — Impl methods take their signature from the trait

**Laws:** 1, 6 (docs/mission.md).

**Date:** 2026-10-21. **Status:** ruled by Eric ("blessed"). **Issue:** #2220
(step 2 review: `impl One for f64: fn one() -> f64: 1.0`).

**Ruling (Eric's words).** A method in an impl of a trait may omit its
parameter and return types; they are the trait's declaration, instantiated
for the impl. If written, they must match it.

"Instantiated for the impl" includes the `Self` substitution: on
`impl One for f64`, the trait's `fn one() -> Self` reads `-> f64`, so
`fn one(): 1.0` is complete.

**Why.** D7 and #727 let the compiler consult the trait for an impl method's
receiver; nothing extended that to parameter and return types. The trait
declaration is the published promise (Law 6), so an impl that omits what
the trait already states hides nothing from a reader, and writing it again
is a second spelling of one fact (Law 1).

**What the implementation did before.** The return half existed without a
ruling (`trait_impl_method_contract`, #652: an unannotated impl method's
return is the trait's). The parameter half was a silent fallback: Sema
accepted `impl Scale for P: fn scale(k): self.v * k` with `k` untyped, and
codegen died two stages later ("cannot lower FnAbi parameter 2 of 'P.scale'
to an LLVM source type"). Under this ruling `k` is the trait's `i32`; a
written type that differs from the trait's is an error naming both.

**Searched before ruling.** `docs/meetings`: no ruling on impl parameter or
return types; D7 covers the receiver keyword only; `#727` is not cited
anywhere in the log.

**What would reopen it.** A trait method whose parameter type cannot be
instantiated for the impl without information the impl alone has
(associated types beyond `Self`); then the impl writes that type, and the
"must match" clause still applies to what it writes.
