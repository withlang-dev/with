//! expect-stdout: 3 0 7 11
//! expect-stdout: one-9 move quit
//! expect-stdout: true false true
//! expect-stdout: as_move 1 2
//! expect-stdout: hi
//! expect-stdout: stop
//! expect-stdout: yo
//! expect-stdout: 1 42 2
//! expect-stdout: 100 11 300
//! expect-stdout: opt 42

// #1455 (§4.4a): a payload discriminant enum whose discriminants are not
// 0, 1, 2 — the tag is the discriminant, the payload layout is the variant's.
// MIR built the variant as its discriminant (`Move(i32, i32) = 7` as variant 7
// of 2) and codegen found no payload type. Forms: qualified call, shorthand,
// payloadless variant, fn return, literal payload pattern, is_/as_ accessors,
// u8 / i64 / u16 reprs, variants out of value order, auto-increment after an
// explicit value, an Option of the enum.

enum Msg: i32:
    Quit = 0
    Move(i32, i32) = 7

enum Byte: u8:
    Write(str) = 200
    Stop = 3

enum Wide: i64:
    Lo = 40
    Pair(i64, i64) = 41
    Hi = 90

enum Auto: u16:
    Start = 10
    Step(i32)
    End

fn msg_code(m: &Msg) -> i32:
    match m:
        .Quit => 0
        .Move(x, y) => x + y

fn byte_text(b: &Byte) -> str:
    match b:
        .Write(s) => s.clone()
        .Stop => "stop".clone()

fn wide_sum(w: Wide) -> i64:
    match w:
        Wide.Lo => 1
        Wide.Pair(a, b) => a * b
        Wide.Hi => 2

fn auto_code(a: &Auto) -> i32:
    match a:
        .Start => 100
        .Step(n) => n
        .End => 300

fn make_move(n: i32) -> Msg: .Move(n, n + 1)

fn literal_payload(m: &Msg) -> str:
    match m:
        .Move(1, y) => f"one-{y}"
        .Move(_, _) => "move".clone()
        .Quit => "quit".clone()

fn main:
    // qualified call, shorthand with expected type, bare payloadless
    let m = Msg.Move(1, 2)
    let q = Msg.Quit
    let s: Msg = .Move(3, 4)
    print(f"{msg_code(m)} {msg_code(q)} {msg_code(s)} {msg_code(make_move(5))}")
    print(f"{literal_payload(Msg.Move(1, 9))} {literal_payload(Msg.Move(2, 9))} {literal_payload(Msg.Quit)}")
    // accessors
    print(f"{m.is_move()} {q.is_move()} {q.is_quit()}")
    match m.as_move():
        Some((x, y)) => print(f"as_move {x} {y}")
        None => print("as_move none")
    // u8 repr, owned payload, variant order not by value
    let bs = [Byte.Write("hi".clone()), Byte.Stop, .Write("yo".clone())]
    for b in bs:
        print(byte_text(b))
    // i64 repr, payloadless on both sides of a payload variant
    print(f"{wide_sum(Wide.Lo)} {wide_sum(Wide.Pair(6, 7))} {wide_sum(Wide.Hi)}")
    // auto-increment after an explicit value
    print(f"{auto_code(Auto.Start)} {auto_code(Auto.Step(11))} {auto_code(Auto.End)}")
    // Option of a payload disc enum
    let o: Option[Msg] = Some(Msg.Move(20, 22))
    match o:
        Some(.Move(a, b)) => print(f"opt {a + b}")
        Some(.Quit) => print("opt quit")
        None => print("none")
