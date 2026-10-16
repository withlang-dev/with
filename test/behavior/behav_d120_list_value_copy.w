//! expect-stdout: a 3 b 4
//! expect-stdout: a 3 b 4 c 5
//! expect-stdout: names 2 kept 1
//! expect-stdout: sum 6
//! expect-stdout: ok

// D120 (§2.3): a List of values is a value. `let b = a` copies it in O(1)
// (the buffer is shared under a count); the first mutation of a shared
// buffer copies it, so `a` never sees `b`'s push. A List of str is a List
// of values too: the copy retains each element. Passing a value list
// copies it, so the caller still has it afterwards.
fn total(xs: List[isize]) -> isize:
    var s = 0
    for x in xs: s += x
    s

fn main:
    var a = [1, 2, 3]
    var b = a
    b.push(4)
    print(f"a {a.len()} b {b.len()}")
    var c = b
    c.push(5)
    print(f"a {a.len()} b {b.len()} c {c.len()}")
    var names = ["x", "y"]
    var kept = names
    kept.pop()
    print(f"names {names.len()} kept {kept.len()}")
    print(f"sum {total(a)}")
    print(f"{a.len() == 3}".replace("true", "ok"))
