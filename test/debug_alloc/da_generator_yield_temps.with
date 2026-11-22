//! expect-debug-alloc: leak count=0

// #1412: every str a generator builds for a yield — the yielded value, its
// f-string parts, a `let` it moves into the yield — frees exactly once, on
// full and on early-stopped iteration. Before the fix the resume path
// dropped temporaries it never initialized and the next-body transform
// dropped the wrong place (double frees under the debug allocator).
gen fn names(count: i32) -> str:
    var i = 0
    while i < count:
        yield f"n{i}" ++ "!"
        i += 1

gen fn words(count: i32) -> str:
    var i = 0
    while i < count:
        let w = f"w{i}"
        yield w
        i += 1

fn main:
    var n = 0
    for s in names(3): n = n + s.len() as i32
    for s in words(3): n = n + s.len() as i32
    for s in names(5):
        n = n + s.len() as i32
        if s == "n1!": break
    assert(n == 9 + 6 + 6)
    print("ok")
