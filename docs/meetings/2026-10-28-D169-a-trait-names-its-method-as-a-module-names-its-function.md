# D169 — A trait names its method as §11.4's qualifier names an extension's: `Trait.method(args)`, the receiver the first argument, a static method's `Self` from its use (ruled)

**Laws:** every character the program has already determined is a compiler
failure if the programmer still writes it; one spelling.

**Date:** 2026-10-28. **Status:** ruled (Eric, "blessed", on the brief
below; the §11.4 words blessed verbatim). **Issue:** #2520.

**Decision.** When two traits of equal rank give a type a method of one
name, a bare call is §11.4's ambiguity, and the call names the trait the
way §11.4 already names an extension's package:

- an instance method: `Name1.name(p)` — the receiver is the first
  argument, passed as the signature's receiver mode states (`&Self`
  borrows with no `&` written);
- a static method: `let x: f64 = Unit1.one()` — `Self` is the type the
  call's use demands (D165, D93); with no demand the call is refused and
  asks for one, never guessed.

The ambiguity diagnostic names this spelling as its fix.

**Context.** #2520 (reopened 2026-10-28): with two program traits giving
`f64` a static `one`, every spelling of a choice was refused —
`Unit1.one()` "undefined variable", `f64.Unit1.one()` "unknown field
'Unit1'" — and the diagnostic's advice, "name the trait through a bound",
left only a wrapper generic (`fn get[T: Unit1]() -> T: T.one()`).

**What the others do** (checked in `.reference`). Rust: `<Test as
Trait1>::foo()` (E0034), or `Trait1::foo(&x)` with `Self` inferred. Swift:
"ambiguous use of"; a cast to the protocol picks. Scala 3: a class mixing
both traits overrides and picks with `super[Trait1].m`; typeclasses use
`summon[Unit1[Double]].one`. Go and Zig have no traits.

**What the spec said.** §11.4 rules this for extensions: "The caller must
disambiguate using the fully-qualified syntax: `pkg_a.method_name(value)`"
(`slug.to_slug(&s)`). It had no trait-qualified form.

**Alternatives.** Rust's `<T as Trait>::m()`: new syntax, and it spells a
type the use already states. `f64.Unit1.one()`: a second spelling of the
same call. Both dropped.

**Reopens if** a call needs `Self` that neither its receiver argument nor
its use can supply.
