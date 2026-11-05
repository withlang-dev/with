//! expect-stdout: msg-0
//! expect-stdout: msg-1
//! expect-stdout: boxed=42
//! expect-stdout: ok

// #3038 (§14.6): monomorphizing a generic function (`print[str]`, `box_id[T]`)
// on demand while emitting an `async:` block trampoline must not leak
// `async_block_rbuf` into the monomorphized callee's return block.

use std.channel.chan

type Boxed[T] { val: T }
fn box_id[T](v: T) -> Boxed[T]:
    Boxed { val: v }

fn main:
    let (tx, rx) = chan[str](4)
    async scope s =>
        let t1 = s.track(async:
            for i in 0..2:
                tx.send(f"msg-{i}")
            tx.close()
        )
        let t2 = s.track(async:
            for msg in rx:
                print(msg)
        )
        t1.await
        t2.await
    let t = async:
        let b = box_id(42)
        b.val
    print(f"boxed={t.await}")
    print("ok")
