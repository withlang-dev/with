//! expect-stdout: 1 2 3
//! expect-stdout: 2

// #1766, D69 (§13.4 Pulling): `g.pull()` runs the generator on its own
// coroutine; std.task's gen_pull holds the generator in a move closure and
// the consumer body is a closure capturing the pull core by place.
gen fn units(n: i32) -> i32:
    for i in 1..n + 1:
        yield i

fn main:
    var p = units(3).pull()
    let a = p.next().unwrap()
    let b = p.next().unwrap()
    let c = p.next().unwrap()
    print(f"{a} {b} {c}")
    var q = units(5).pull()
    let _ = q.next()
    print(q.next().unwrap())
