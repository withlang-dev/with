//! expect-debug-alloc: leak count=0
// #1455: a payload discriminant enum whose discriminants are not the variant
// indices stores the discriminant as its tag; the drop glue, which selects the
// variant by that tag, frees each owned payload exactly once.

enum Msg: u8:
    Quit = 9
    Write(str) = 200
    Pair(str, str) = 17

fn size(m: &Msg) -> i64:
    match m:
        .Quit => 0
        .Write(s) => s.len()
        .Pair(a, b) => a.len() + b.len()

fn consume(m: Msg) -> str:
    match m:
        .Quit => "".clone()
        .Write(s) => s
        .Pair(a, b) => a ++ b

fn main:
    var total: i64 = 0
    for m in [Msg.Quit, Msg.Write("alpha".clone()), Msg.Pair("be".clone(), "ta".clone())]:
        total = total + size(m)
    print(total)
    print(consume(Msg.Pair("x".clone(), "y".clone())))
    print(consume(Msg.Write("z".clone())))
    let dropped = Msg.Pair("dropped".clone(), "whole".clone())
    print(size(dropped))
