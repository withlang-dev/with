//! expect-error: iterator over `xs` retains access; cannot also mutably capture `xs` (§15.8)

// docs/mut.md Rev 8 §15.8 — closure capture conflict via iterator.
// `xs.iter()` is marked `@[iter_of_self]` (Vec.iter is a builtin in this set),
// so the produced VecIter retains shared access to `xs` for the duration of
// the enclosing call. The sibling closure mutably captures `xs` and conflicts.

fn try_extend(iter: VecIter[i32], cb: fn(i32) -> i32) -> i32:
    var sum = 0
    for x in iter:
        sum = sum + cb(x)
    sum

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let n = try_extend(xs.iter(), item => xs.push(item))
    print("done")
