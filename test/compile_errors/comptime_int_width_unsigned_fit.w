//! expect-error: integer literal does not fit expected type

// #943: pins the misleading diagnostic on the unsigned path. There is no
// ill-fitting literal here — 3000000001u64 fits u64 exactly. The comptime
// evaluator truncates the operand to 32 bits, producing -1294967295, and the
// unsigned fit check then rejects that negative value at materialization
// while blaming a literal.
//
// The message points away from the actual fault, which is why it is pinned:
// fixing #943 should remove this error entirely, and any interim change to the
// wording should be visible in the diff.

comptime fn uadd -> u64:
    3000000001u64 + 0u64

const U: u64 = comptime uadd()

fn main:
    print(f"{U}")
