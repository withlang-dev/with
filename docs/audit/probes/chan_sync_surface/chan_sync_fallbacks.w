// T23 silent-drop fallback probe (sync context, no fibers live).
// Bounded chan[i32](1): fill it, send once more (must block, but with no
// fiber and no live runtime fibers the runtime escapes instead of blocking),
// then drain. Expected per rt/channel_runtime.w:179-180,203-204:
//   second send silently dropped; recv on empty-but-OPEN channel => None
//   (indistinguishable from closed-and-drained, cf. channel.w:7 doc claim
//   "None once closed and drained").
use std.channel
use std.builtins.print

fn main:
    let (tx, rx) = chan[i32](1)
    tx.send(10)
    tx.send(20)
    var first = -1
    match rx.recv():
        Some(v) => { first = v }
        None => { first = -999 }
    assert(first == 10)
    print("recv1-ok")
    var second_none = false
    match rx.recv():
        Some(v) => { second_none = false }
        None => { second_none = true }
    assert(second_none)
    print("recv2-none-ok")
