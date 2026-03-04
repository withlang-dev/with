// Wave 10: enum tag/payload runtime behavior probe.

type Packet = Ping(i32) | Pong(i32) | Done

fn score(p: Packet) -> i32:
    match p
        Ping(v) -> v + 1
        Pong(v) -> v + 2
        Done -> 0

fn main -> i32:
    assert(score(Ping(4)) == 5)
    assert(score(Pong(4)) == 6)
    assert(score(Done) == 0)

    let p = Ping(9)
    assert(p.is_Ping())
    let maybe = p.as_Ping()
    assert(maybe.is_some())
    assert(maybe.unwrap() == 9)
    0
