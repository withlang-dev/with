# D257 — Demand-site builder finalization via `Finalize[T]`

**Date:** 2026-11-28. **Status:** Delegated under D237 (implementing Eric's D34-A Phase 1 ruling, #920).

## Context

D34 (2026-09-02) ruled Phase 1 verbatim: *"ok we want both A and C. A should apply to all Builder patterns"*. At an owned-demand site — return position against a declared return type, typed binding, typed call argument, assignment, struct field, or collection literal element — a builder value whose type declares a canonical finalization to the demanded type satisfies the demand without writing `.to_str()` or `.finalize()`.

The remaining Phase 1 surface detail is the trait name and method signature:
- `pub trait Finalize[T]: move fn finalize() -> T` in `std.traits` (registered as a language trait alongside `Scoped`/`ScopedMut`, and avoiding collision with `std.build.Build`).
- `impl Finalize[str] for StringBuilder: pub move fn finalize() -> str: self.to_str()` in `std.string`.
- Consulted strictly in Law 2 Phase 2: only between two concrete known types (`expected` and `actual`, neither with unresolved type parameters), only when `expected` is an owned type (never `&T` or raw pointers) and `actual` is an owned value (never a borrow), never chaining with another conversion (e.g., `Option` wrapping), and never binding an unknown type parameter.

The broader wrapper-elimination question ("Option or Promise") stays out of scope here as D34 requires.

## Mission fit

- **Law 1:** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* Requiring `.to_str()` or `.finalize()` when a builder with a single declared finalization to `T` stands at an owned `T` demand makes the programmer write ceremony the type and demand already determine.
- **Law 2:** *Test: is this "the compiler figures X out from context" written as an instance of this law, with both guardrails and the order?* Yes: Phase 1 binds any unknowns from the expression's own operands (`id(b)` binds `T := StringBuilder` before outer demand applies); Phase 2 applies `Finalize[T]` only between two concrete known types, once at the outermost demand, and never binds an unknown or chains conversions.
- **Law 5:** *Test: does this operation create an owner the type system does not know about?* No: `move fn finalize() -> T` consumes the owned builder at the demand site, marks the builder moved, and transfers ownership of the built `T`. Borrowed demands (`&T`) and borrowed builders (`&Builder`) are never finalized.
- **Law 6:** *Test: is the programmer promising something to a reader who cannot see the body? Then spell it. Otherwise never.* A type opts in explicitly by implementing `pub trait Finalize[T]`; no finalization is inferred from method names.
- **Law 10:** *Test: what program would fail if this rule were quietly lost? If there is none, write it before the rule lands.* Covered by `test/behavior/behav_920_demand_site_finalization.with`, `test/debug_alloc/da_920_demand_site_finalization.with`, `test/compile_errors/err_920_finalize_use_after_move.with`, and `test/compile_errors/err_920_finalize_ref_demand_refused.with`.
