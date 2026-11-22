//! expect-check-fail: @[repr(packed(N))] caps the alignment of a struct's fields; it applies to a struct declaration

// Spec §16.4 (#1421): the cap is a struct layout; on another declaration
// it is refused, never dropped silently.

@[repr(packed(2))]
enum Mode:
    A
    B

fn main:
    print("unreachable")
