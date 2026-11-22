//! expect-debug-alloc: leak count=0
//! expect-stdout: x!
//! expect-stdout: 3
//! expect-stdout: 7
//! expect-stdout: bb
//! expect-stdout: cc
//! expect-stdout: xxx
//! expect-stdout: abb

// #1486 (§12.4: "For non-`Copy` values, default capture is by place: the
// closure observes or mutates the original place according to its body.")
// A non-escaping closure that assigns a captured non-Copy place drops the
// old value at the ORIGINAL place and stores the new one there, exactly
// once each. Before the fix codegen dropped the old value at the closure's
// pointer slot instead of through it — freeing the slot's bytes as a str
// (SIGSEGV) — while the store right after wrote through the pointer.

type S { name: str, n: i32 }

fn compute(s: &str): s ++ "!"
fn run_unit(f: fn() -> Unit): f()
fn run_twice(f: fn() -> Unit):
    f()
    f()

fn main:
    var c = ""
    run_unit(() => c = compute("x"))
    print(c)

    var v: List[i32] = List.new()
    v.push(1)
    run_unit(() => v = [7, 8, 9])
    print(v.len())
    run_unit(() => v.push(5))
    print(v[0])

    var s = S { name: "a", n: 1 }
    run_unit(() => s.name = "bb")
    print(s.name)
    run_unit(() => s = S { name: "cc", n: 2 })
    print(s.name)

    var acc = ""
    for i in 0..3:
        run_unit(() => acc = acc ++ "x")
    print(acc)

    var t = "a"
    run_twice(() => t = t ++ "b")
    print(t)
