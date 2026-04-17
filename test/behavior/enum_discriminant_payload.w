//! expect-stdout: quit
//! expect-stdout: move 10 20
//! expect-stdout: write hello
//! expect-stdout: ok

enum Msg: i32:
    Quit = 0
    Move(i32, i32) = 1
    Write(str) = 2

fn describe(m: Msg) -> str:
    match m:
        .Quit => "quit"
        .Move(x, y) => "move " ++ int_to_string(x) ++ " " ++ int_to_string(y)
        .Write(s) => "write " ++ s

fn main:
    let q = Msg.Quit
    print(describe(q))
    let mv = Msg.Move(10, 20)
    print(describe(mv))
    let w = Msg.Write("hello")
    print(describe(w))
    print("ok")
