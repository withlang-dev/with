//! args: --dump-mir
//! expect-check-stdout: _2 = str_concat_n([move _2, copy _9]);

// #1491: the append after a separator `if` grows `out` in place. lower_if
// forgot every string flow fact at its join, and an assignment lowered in
// discard position (a one-statement `if` arm) marked its place may-alias as
// if its value were used, so `out = out ++ elem(i)` after the `if` copied
// all of `out` each iteration (`_10 = str_concat_n([copy _2, copy _9])`):
// n=64000 took 9.47 s, n=256000 117.6 s. In place, the append is
// `_2 = str_concat_n([move _2, copy _9])`. (The line is this function's:
// `copy _9` is `elem(i)`'s result.)

fn elem(i: i32): f"{i}"

fn lit(n: i32) -> str:
    var out = "["
    for i in 0..n:
        if i > 0:
            out = out ++ ", "
        out = out ++ elem(i)
    out ++ "]"

fn main:
    print(lit(4))
