//! expect-stdout: a 3 b 4
//! expect-stdout: a 3 b 4 c 5
//! expect-stdout: names 2 kept 1
//! expect-stdout: sum 6
//! expect-stdout: tail 19999
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

fn tail_last_after_cow_write(xs0: List[i64]) -> i64:
    var xs = xs0
    let n = xs.len()
    xs[n - 1] = 19999
    xs[n - 1]

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
    var big: List[i64] = List.with_capacity(20000)
    for i in 0..20000:
        big.push(i)
    print(f"tail {tail_last_after_cow_write(big)}")
    print(f"{a.len() == 3 and big.len() == 20000}".replace("true", "ok"))
