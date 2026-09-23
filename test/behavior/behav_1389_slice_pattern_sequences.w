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
// borrowed Vec, an owned Vec, a borrowed array (length decided at compile
// time), and a slice (length tested at run time). In match and let-else,
// with head and tail elements, over owned `str` elements.
fn g(v: &Vec[i32]) -> i32:
    match v:
        [first, ..] => first
        _ => -1

fn h(v: &Vec[i32]) -> i32:
    let [first, ..] = v else: return -1
    first

fn ends(v: Vec[i32]) -> str:
    match v:
        [a, .., z] => f"{a} {z}"
        [_] => "one"
        _ => "two"

fn arr_sum(a: &[3]i32) -> i32:
    match a:
        [x, y, z] => x + y + z

fn names(v: &Vec[str]) -> str:
    match v:
        [x, .., y] => f"{v.len()} {x} {y}"
        _ => "short"

fn slice_head(s: []i32) -> i32:
    match s:
        [a, b] => a - b
        [a, ..] => a
        [] => -2
        _ => -3

fn kind(v: &Vec[i32]) -> str:
    match v:
        [] => "empty"
        [_] => "one"
        _ => "many"

fn main:
    var a: Vec[i32] = Vec.new()
    let b: Vec[i32] = Vec.new()
    a.push(4)
    print(f"{g(a)} {g(b)}")
    print(f"{h(a)} {h(b)}")
    var c: Vec[i32] = Vec.new()
    c.push(1)
    c.push(2)
    c.push(4)
    print(f"{ends(c)} {ends(a.clone())}")
    let arr = [1, 2, 3]
    let [p, q, r] = &arr
    print(f"{arr_sum(&arr)} {p} {q} {r}")
    var s: Vec[str] = Vec.new()
    s.push("ab".clone())
    s.push("xx".clone())
    s.push("cd".clone())
    print(names(s))
    let nums = [9, 2, 7, 5]
    print(f"{slice_head(nums[2..4])} {slice_head(nums[0..0])} {slice_head(nums[0..1])}")
    var many: Vec[i32] = Vec.new()
    many.push(1)
    many.push(2)
    print(f"{kind(b)} {kind(a)} {kind(many)}")
    let [first, .., last] = &[6, 0, 1]
    print(f"{first} {last}")
