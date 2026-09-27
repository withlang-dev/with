//! expect-check-fail: @[flags] cannot double the discriminants of a generic enum with a payload variant

// D71 / §4.4a (#1482): an `@[flags]` enum with no representation type
// doubles in its default integer representation, and the attribute is never
// ignored. A generic enum with a payload variant cannot be a discriminant
// enum yet (#1768: its payload type reaches MIR unresolved), so the
// attribute is refused, not dropped — it was silently ignored (tags 0 1 2).

@[flags]
enum Slot[T]:
    Empty
    Full(T)
    Gone

fn bits(s: Slot[i32]) -> i32: s as i32

fn main:
    print(bits(Slot.Gone))
