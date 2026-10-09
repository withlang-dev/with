//! expect-error: argument retains access to `xs` which is mutably captured by a closure in the same call (§15.7)

// docs/mut.md Rev 8 §15.8 — closure capture conflict via iterator.
// `xs.iter()` is marked `@[iter_of_self]` (List.iter is a builtin in this set),
// so the produced ListIter retains shared access to `xs` for the duration of
// the enclosing call. The sibling closure mutably captures `xs` and conflicts.

use std.collections.ListIter

fn try_extend(iter: ListIter[i32], cb: fn(i32) -> i32) -> i32:
    var sum = 0
    for x in iter:
        sum = sum + cb(x)
    sum

fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let n = try_extend(xs.iter(), item => xs.push(item))
    print("done")
