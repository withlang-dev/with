//! expect-stdout: yes no yes
//! expect-stdout: ready
//! expect-stdout: empty
//! expect-stdout: 3
//! expect-stdout: both one neither
//! expect-stdout: x
//! expect-stdout: element
//! expect-stdout: 7 7

// D177 (§4.2a): an integer in a boolean-test context is true when nonzero,
// negatives included; `not`, `and` and `or` take integer operands and
// produce bool, short-circuiting; the integer's own type is unchanged and
// no `bool` demand reaches a literal. An assignment tests its stored value.
const READY: i32 = 4

fn say(n: i32) -> str: if n: "yes" else: "no"

fn side(mut hits: List[i32]) -> i32:
    hits.push(1)
    1

fn next_value(mut counter: List[i32]) -> i32:
    if counter.len() < 1:
        counter.push(7)
        return 7
    0

fn main:
    print(f"{say(1)} {say(0)} {say(-5)}")
    let flags: i32 = 5
    if flags & READY: print("ready")
    let count: isize = 0
    if not count: print("empty")
    var n: u8 = 3
    var steps = 0
    while n:
        n -= 1
        steps += 1
    print(f"{steps}")
    let a = 2
    let b = 0
    let both = if a and a: "both" else: "x"
    let one = if b or a: "one" else: "x"
    let neither = if b or b: "x" else: "neither"
    print(f"{both} {one} {neither}")
    var hits: List[i32] = List.new()
    if b and side(hits): print("x")
    if a or side(hits): print("x")
    if hits.len() == 0: print("element")
    var counter: List[i32] = List.new()
    var got = 0
    if got = next_value(counter): print(f"{got} {counter[0]}")
