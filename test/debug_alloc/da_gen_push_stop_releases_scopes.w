//! expect-debug-alloc: leak count=0
//! expect-stdout: defer a
//! expect-stdout: drop a
//! expect-stdout: break: a0 a1
//! expect-stdout: defer b
//! expect-stdout: drop b
//! expect-stdout: returned b0-kept
//! expect-stdout: defer c
//! expect-stdout: drop c
//! expect-stdout: try: bad c1
//! expect-stdout: done e
//! expect-stdout: defer e
//! expect-stdout: drop e
//! expect-stdout: defer e
//! expect-stdout: drop e
//! expect-stdout: defer d
//! expect-stdout: drop d
//! expect-stdout: labeled: d0e0 d0e1 d0e2 d1e0
//! expect-stdout: done f
//! expect-stdout: defer f
//! expect-stdout: drop f
//! expect-stdout: continue: f1 f3
//! expect-stdout: unconsumed: nothing ran

// D69 (§13.4): the consumer's `break`, `return`, `?` and a labeled `break`
// stop the generator at its `yield`; it leaves there as if by `return`, so
// its `defer` runs and its owned resource drops exactly once, before the
// consumer's continuation. A generator value never consumed releases only
// its arguments.
type Res {
    name: str,
}

impl Drop for Res:
    move fn drop():
        print(f"drop {self.name}")

gen fn items(tag: str, count: i32) -> str:
    let r = Res { name: tag.clone() }
    defer:
        print(f"defer {tag}")
    for i in 0..count:
        let item = f"{tag}{i}"
        yield item
    print(f"done {r.name}")

fn first_kept() -> str:
    var seen = ""
    for s in items("b", 5):
        seen = s.clone()
        return s ++ "-kept"
    seen

fn check(s: &str) -> Result[i32, str]:
    if s == "c1": return Err(s.clone())
    Ok(1)

fn count_until_bad() -> Result[i32, str]:
    var n = 0
    for s in items("c", 4):
        n += check(&s)?
    Ok(n)

fn main:
    var out = "break:"
    for s in items("a", 5):
        out = out ++ " " ++ s
        if s == "a1": break
    print(out)

    print("returned " ++ first_kept())
    match count_until_bad():
        Ok(_) => print("try: no error")
        Err(e) => print(f"try: bad {e}")
    var pairs = "labeled:"
    'outer for d in items("d", 3):
        for e in items("e", 3):
            if d == "d1" and e == "e1": break 'outer
            pairs = pairs ++ " " ++ d ++ e
    print(pairs)
    var odd = "continue:"
    for s in items("f", 4):
        if s == "f0" or s == "f2": continue
        odd = odd ++ " " ++ s
    print(odd)
    let unused = items("g", 2)
    print("unconsumed: nothing ran")
