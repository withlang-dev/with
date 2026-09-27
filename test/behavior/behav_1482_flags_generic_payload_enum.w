//! expect-stdout: 4
//! expect-stdout: 2

// D71 / §4.4a (#1482): an `@[flags]` enum with no representation type
// doubles in its default integer representation, and the attribute is never
// ignored. A generic one with a payload variant was refused until its
// payloads resolved (#1768); it doubles like any other.

@[flags]
enum Slot[T]:
    Empty
    Full(T)
    Gone

fn bits(s: Slot[i32]) -> i32: s as i32

fn main:
    print(bits(Slot.Gone))
    print(bits(Slot.Full(7)))
