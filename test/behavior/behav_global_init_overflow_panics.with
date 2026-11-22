//! expect-exit: 134
//! expect-stderr: integer overflow

// #1773: a global initializer is an ordinary expression run before `main`
// (§9.1c) and its arithmetic is checked (§4.2.3). The LLVM backend folded
// `0 - K` at the element type i16 (the expected type) instead of the
// expression's own type u32, so the global read -1 while the same
// expression in a body panicked. The element conversion is spelled: a u32
// does not narrow into i16 implicitly (#1803).
let K: u32 = 1
let T: [2]i16 = [0, (0 - K) as i16]

fn main:
    print(f"{T[1]}")
