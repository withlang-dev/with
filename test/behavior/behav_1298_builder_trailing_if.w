//! expect-stdout: ok

// #1298 (§7.2): `with expr as mut x:` always returns x, so the body's last
// statement is a statement — a trailing `if` needs no `else`, in the block
// and single-line spellings, and whether the builder is bound or returned.
// (A builder's heap-owning contents are lost on return — #723 — so the
// struct here observes the rule through plain i32 fields.)

type Changes { n: i32 = 0, last: i32 = 0 }

fn describe(x: i32) -> Changes:
    let changes = with Changes { } as mut c:
        if x > 1:
            c.n += 1
            c.last = 1
        if x > 2: c.n += 1
    changes

fn returned(x: i32) -> Changes:
    with Changes { } as mut c:
        if x > 0: c.last = 7

fn main:
    let a = describe(3)
    assert(a.n == 2)
    assert(a.last == 1)
    let b = describe(0)
    assert(b.n == 0)
    assert(b.last == 0)
    assert(returned(1).last == 7)
    assert(returned(-1).last == 0)
    print("ok")
