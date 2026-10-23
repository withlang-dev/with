# D154 — A `Drop` impl's bounds are the type's own; drop glue runs a bounded impl for every instantiation (delegated)

**Laws:** 5, 2 (docs/mission.md).

**Date:** 2026-10-23. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2571.

**Decision.** `impl[T: Clone] Drop for Holder[T]` is `Holder`'s
destructor for every `Holder[T]`, exactly as `impl[T] Drop for Holder[T]`
is: drop glue (`Sema.type_has_drop_impl`) sees the blanket impl over the
base. For that to be sound the impl may not demand a bound the type's
declaration does not: `type Holder[T]` with `impl[T: Clone] Drop` is
refused ("a `Drop` impl's bounds are the type's own … a destructor runs
for every instantiation", §2.4); `type Holder[T: Clone]` with the same
impl is accepted.

**Context.** A `Holder[Tag]` local with the bounded impl ran no destructor
at scope end (the issue's std `BTreeMap` leaked every entry until its impl
was made unbounded); an explicit `drop(h)` ran it. The per-symbol trait
query checked the impl's bounds against `Holder` itself, so the blanket
impl never matched, and nothing said so: a leak by silence (§ leaks are
defects).

**What the others do.** Rust: E0367, "the requirement `T: Clone` is added
only by the Drop impl" — a Drop impl's bounds must be exactly the struct's.
Swift/Go/Zig/Mojo: destructors are per type, never per instantiation;
Mojo's `__del__` has no bounds. Vale: a destructor is the type's.

**Alternatives.** (a) Honor a stricter bound as "no destructor for the
other instantiations": a conditional destructor is a leak no reader can
see from the type. (b) Infer the bound onto the type: changes the type's
interface from an impl. (c) Refuse every bounded Drop impl: the bound is
sometimes the type's own, restated (D140's spirit: say it once), and
refusing the restatement would be ceremony in reverse.

**Prediction.** 90%: it is Rust's rule where Rust's rule is the safety
bar, and the issue asked for exactly this ("a check that refuses a
bounded Drop impl that drop glue cannot see would at least be loud").

**Reopens if** With gains specialization (`impl Drop for Holder[i32]`
beside the generic one): then the per-instantiation question returns.
