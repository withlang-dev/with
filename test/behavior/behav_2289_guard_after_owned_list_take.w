//! expect-stdout: big 9 [2, 3]
//! expect-stdout: small 1 [2, 3]
//! expect-stdout: last 3 [1, 2]
//! expect-stdout: drop 1
//! expect-stdout: drop 9
//! expect-stdout: drop 3
//! expect-stdout: drop 2

// #2289 (D115 Amendment 1, §9.7): a match guard may follow a pattern that
// takes elements out of an owned List. A failed guard puts them back: the
// head through the prefix its O(1) take left, a tail into the capacity it
// left, so the next arm sees the whole subject. Each element drops once
// (the remainder's elements first, at the arm's end, then the head).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): print(f"drop {self.id}")

fn classify(xs: List[i32]) -> str:
    match move xs:
        [first, ..rest] if first > 5 => f"big {first} {rest:?}"
        [first, ..rest] => f"small {first} {rest:?}"
        [] => "empty"

fn tail(xs: List[i32]) -> str:
    match move xs:
        [..init, last] if last > 100 => f"huge {last} {init:?}"
        [..init, last] => f"last {last} {init:?}"
        [] => "empty"

fn first_tok(toks: List[Tok]) -> i32:
    match move toks:
        [t, ..rest] if t.id > 5 => t.id
        [t, ..rest] => t.id + 100
        [] => 0

fn main:
    print(classify([9, 2, 3]))
    print(classify([1, 2, 3]))
    print(tail([1, 2, 3]))
    let a = first_tok([Tok { id: 9 }, Tok { id: 1 }])
    let b = first_tok([Tok { id: 2 }, Tok { id: 3 }])
    assert(a == 9 and b == 102)
