//! expect-check-fail: use of moved value

// §3.8 full enforcement: a plain `T` parameter consumes its argument
// for every non-Copy type — not only types with a drop impl. The
// caller's binding is invalidated even when the callee only reads.

type Acc { items: Vec[i32] }

fn touch(a: Acc) -> i32:
    a.items.len() as i32

fn main:
    var a = Acc { items: Vec.new() }
    a.items.push(7)
    let n = touch(a)
    let m = a.items.len() as i32
    print(f"{n} {m}")
