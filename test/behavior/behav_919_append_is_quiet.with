//! expect-build-stderr-not: warning
//! expect-stdout: xxx xxxyyyyyyyyy x

// D219 (#919): what stays quiet. The plain append; an append in an inner
// loop while a copy made outside it is live (one copy, then the
// accumulator is alone again); a `let` in the body whose copy dies before
// the next append.
fn main:
    var s = ""
    for i in 0..3: s = s ++ "x"
    var u = s
    let keep = u
    for i in 0..3:
        for j in 0..3: u = u ++ "y"
    var t = ""
    var first = ""
    for i in 0..3:
        t = t ++ "x"
        let now = t
        if i == 0: first = now.slice(0, 1).to_owned()
    print(f"{keep} {u} {first}")
