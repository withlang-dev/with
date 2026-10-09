//! expect-stdout: 4 -1
//! expect-stdout: 4 -1
//! expect-stdout: 1 4 one
//! expect-stdout: 6 1 2 3
//! expect-stdout: 3 ab cd
//! expect-stdout: 2 -2 9
//! expect-stdout: empty one many
//! expect-stdout: 6 1

// #1389 (§9.7 slice patterns): a slice pattern over a sequence that is not an
// owned fixed-size array observes it in place and binds element views: a
// borrowed List, an owned List, a borrowed array (length decided at compile
// time), and a slice (length tested at run time). In match and let-else,
// with head and tail elements, over owned `str` elements.
fn g(v: &List[i32]) -> i32:
    match v:
        [first, ..] => first
        _ => -1

fn h(v: &List[i32]) -> i32:
    let [first, ..] = v else: return -1
    first

fn ends(v: List[i32]) -> str:
    match v:
        [a, .., z] => f"{a} {z}"
        [_] => "one"
        _ => "two"

fn arr_sum(a: &[3]i32) -> i32:
    match a:
        [x, y, z] => x + y + z

fn names(v: &List[str]) -> str:
    match v:
        [x, .., y] => f"{v.len()} {x} {y}"
        _ => "short"

fn slice_head(s: []i32) -> i32:
    match s:
        [a, b] => a - b
        [a, ..] => a
        [] => -2
        _ => -3

fn kind(v: &List[i32]) -> str:
    match v:
        [] => "empty"
        [_] => "one"
        _ => "many"

fn main:
    var a: List[i32] = List.new()
    let b: List[i32] = List.new()
    a.push(4)
    print(f"{g(a)} {g(b)}")
    print(f"{h(a)} {h(b)}")
    var c: List[i32] = List.new()
    c.push(1)
    c.push(2)
    c.push(4)
    print(f"{ends(c)} {ends(a.clone())}")
    let arr = [1, 2, 3]
    let [p, q, r] = &arr
    print(f"{arr_sum(&arr)} {p} {q} {r}")
    var s: List[str] = List.new()
    s.push("ab")
    s.push("xx")
    s.push("cd")
    print(names(s))
    let nums = [9, 2, 7, 5]
    print(f"{slice_head(nums[2..4])} {slice_head(nums[0..0])} {slice_head(nums[0..1])}")
    var many: List[i32] = List.new()
    many.push(1)
    many.push(2)
    print(f"{kind(b)} {kind(a)} {kind(many)}")
    // Brackets make a List (D113); the borrowed array is demanded.
    let six: [i32; 3] = [6, 0, 1]
    let [first, .., last] = &six
    print(f"{first} {last}")
