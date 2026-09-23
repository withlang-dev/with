//! expect-error: dependency loop with length 2

// #1439: W[i32] embeds W, whose field e: E closes the loop.
type W[T] { e: E, t: T }

enum E:
    A(w: W[i32])
    B

fn main:
    print(1)
