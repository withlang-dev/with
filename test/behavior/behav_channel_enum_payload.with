//! expect-stdout: ok

// D10 (decisions.md): recv() -> Option[T], so a sent None element arrives
// as Some(None) — delivery is distinguishable from closed-and-drained by
// type, not by sentinel. Enum elements round-trip intact through the
// channel, including matching on a received user enum.
// Also pins #671 (constructor args in statement position).

enum Msg:
    Ping(i32)
    Stop

fn main:
    let (tx, rx) = chan[Option[i32]](4)
    tx.send(None)
    assert(rx.recv().unwrap().is_none())
    tx.send(Some(3))
    assert(rx.recv().unwrap().unwrap() == 3)

    let (tx2, rx2) = chan[Msg](4)
    tx2.send(Ping(9))
    match rx2.recv().unwrap():
        Ping(v) => assert(v == 9)
        Stop => assert(false)
    print("ok")
