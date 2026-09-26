//! expect-stdout: ran

// #1494 / §4.10: `main` does not infer; an early `return 1` with a
// fall-off is the exit-status idiom and stays green.

fn check(p: bool) -> i32: if p: 1 else: 0

fn main:
    if check(false) != 0: return 1
    print("ran")
