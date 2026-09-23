//! expect-stdout: 6
//! expect-stdout: L0-L1
//! expect-stdout: L1-L2
//! expect-stdout: w0
//! expect-stdout: w1
//! expect-stdout: w2
//! expect-stdout: a0
//! expect-stdout: b0!
//! expect-stdout: a1
//! expect-stdout: b1!
//! expect-stdout: n0
//! expect-stdout: n1
//! expect-stdout: e0!
//! expect-stdout: o1
//! expect-stdout: e2!
//! expect-stdout: o3

// #1412 (§13.4): a yield suspends the generator; only its named state
// crosses the suspension. The yielded expression's statement temporaries
// (the `{i}` part of an f-string, the parts of a `++`) now drop on the
// suspending path, before the state is saved — they used to drop on the
// resume path, which never initialized them (garbage drops, double frees),
// and a Drop statement's place was remapped as a local by the next-body
// transform, dropping whichever place came next (`yield w` freed the str
// the caller received).
fn label(i: i32) -> str: f"L{i}"

gen fn names(count: i32) -> str:
    var i = 0
    while i < count:
        yield f"n{i}"
        i += 1

gen fn labels(count: i32) -> str:
    var i = 0
    while i < count:
        yield label(i) ++ "-" ++ label(i + 1)
        i += 1

gen fn words(count: i32) -> str:
    var i = 0
    while i < count:
        let w = f"w{i}"
        yield w
        i += 1

gen fn pairs(count: i32) -> str:
    var i = 0
    while i < count:
        yield f"a{i}"
        yield f"b{i}" ++ "!"
        i += 1

gen fn evens(count: i32) -> str:
    var i = 0
    while i < count:
        if i % 2 == 0:
            yield f"e{i}" ++ "!"
        else:
            let odd = f"o{i}"
            yield odd
        i += 1

fn main:
    var n = 0
    for s in names(3):
        n = n + s.len() as i32
    print(n)
    for s in labels(2): print(s)
    for s in words(3): print(s)
    for s in pairs(2): print(s)
    for s in names(5):
        print(s)
        if s == "n1": break
    for s in evens(4): print(s)
