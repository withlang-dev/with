//! expect-debug-alloc: leak count=0
// #1444: matching a u8-repr discriminant enum whose variants carry owned
// payloads reads the u8 tag at its own width; the right arm binds the str
// payload and every payload is freed exactly once.

enum Msg: u8:
    Quit = 0
    Write(str) = 1
    Pair(str, str) = 2

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
