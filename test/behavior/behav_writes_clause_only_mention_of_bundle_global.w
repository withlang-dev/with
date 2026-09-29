//! expect-stdout: x

// §21.1 (D79): a `writes` clause names a global. When the clause is the
// function's only mention of a bundle global, the interface demand still
// has to load its declaration: both the frontend's .wi merge and Sema's
// lazy interface collection count writes-clause names as mentions. (The
// parent compiler refused this with "is no global".)
use std.c_algorithms.defs

pub fn touch() writes allocation_limit:
    print("x")

fn main:
    touch()
