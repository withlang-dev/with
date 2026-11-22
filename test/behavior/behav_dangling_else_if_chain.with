//! expect-stdout: 4 -1
// #629 (§7.5 dangling-else variant): an inner if-chain whose LAST arm is
// `else if` must not capture the outer chain's following `else if`/`else` at
// the outer column. The whole chain keys the dangling-else check off the
// ORIGINAL if's column, not each arm's (column-shifted) `if` token.
fn classify(a: bool, b: bool, c: bool, d: bool, e: bool) -> i32:
    var r: i32 = -1
    if a:
        r = 1
    else if b:
        if c:
            r = 2
        else if d:
            r = 3
    else if e:
        r = 4
    else:
        r = 5
    r

fn main:
    // a=F b=F e=T: the outer `else if e` must fire -> 4 (buggy parse gave 5,
    // then -1 once both outer arms were swallowed by the inner chain)
    let x = classify(false, false, false, false, true)
    // a=F b=T c=F d=F: b's arm runs, inner chain no-ops, outer else must NOT
    // fire -> -1 (buggy parse gave 4: the swallowed `else if e` ran inside b)
    let y = classify(false, true, false, false, true)
    print(f"{x} {y}")
