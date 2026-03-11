//! check-only

// Behavior test: default function parameters (spec SS9.1a)
// TODO: default parameter values not yet implemented.
// This test will exercise fn f(x: i32 = 5) once available.

fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    assert(add(3, 4) == 7)
