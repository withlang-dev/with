//! expect-stdout: call ifexpr cast nested match while

// §4.2a (D177): an integer expression may stand in a boolean test, and a
// condition is a value wherever its `if` or loop stands. An `if` or `match`
// expression tested by a statement `if` was checked as a statement itself
// (type Unit) and refused: "if condition must be bool". C's `isnan(x)`
// migrates to exactly this on Darwin (#3371).
fn one(x: i32) -> i32: x

fn main:
    let a = 3
    var out = ""
    if one(a) { out = out ++ "call" }
    if (if a == 3: one(1) else: one(0)) { out = out ++ " ifexpr" }
    if (if a == 3: one(1) else: (one(0) as i32)) { out = out ++ " cast" }
    if (if a == 4: one(1) else: ((if a == 3: one(1) else: one(0)) as i32)) { out = out ++ " nested" }
    if (match a { 3 => one(2), _ => one(0) }) { out = out ++ " match" }
    var n = 1
    while (if n > 0: one(n) else: one(0)) { n -= 1 }
    if n == 0 { out = out ++ " while" }
    print(out)
