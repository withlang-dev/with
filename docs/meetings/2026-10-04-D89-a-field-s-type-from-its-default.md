# D89 — A field with a default may omit its type; an unsuffixed numeric default takes the type its uses demand

**Date:** 2026-10-04. **Status:** BDFL ruling (Eric: "spec words blessed").
Spec v7.20: types.md §4.3 (Default field values), grammar.md `FIELD`.
Issue #2097. **The compiler is NON-COMPLIANT**: `type T { ticks = 0 }`
fails to parse ("expected ':'").

**Context.** #2097, from the same raylib game as D88: `ticks: i32 = 0`,
`alive: bool = true`, `ship: Vector2 = Vector2 { … }` repeat what the
default already says.

**Decision.** A field with a default may omit its type; the field then has
the type of its default. When the default is an unsuffixed numeric constant
expression, the field's numeric type is decided as a literal's is (§4.2.1):
by what the field's uses in its module demand, and by the default (`i32`,
`f64`) when no use demands anything. Uses that demand two different types
are an error that asks for the type to be written. A field without a
default states its type.

**Why uses, and why the module.** A field is storage, so unlike a `const`
(D88) it has one type. `radius = 10.0` in a raylib program is `f32`
because every use says so; making it `f64` would bring the annotation
back. The uses that count are those in the declaring module: the type of a
field cannot depend on which other modules import it.

**Alternatives.** The default type always (`f64`): rejected by the issue —
it is the annotation by another name wherever the program is `f32`.
Whole-program uses: rejected — a type's layout would change with its
importers. Picking one of two demanded types: rejected — the compiler
never chooses a meaning.

**References.** Swift and Mojo infer a stored property's type from its
default, without looking at uses; Go, Rust and Zig require the type. No
reference infers a field's type from its uses: that part is With's own.

**Reopen if** use-directed field types make a type's layout hard to read
from its declaration in practice; the escape is the written type.
