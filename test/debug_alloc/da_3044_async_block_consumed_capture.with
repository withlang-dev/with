//! expect-debug-alloc: leak count=0
//! expect-stdout: drop:t
//! expect-stdout: hello
//! expect-stdout: ok

// #3044 (§14.6): an `async:` block follows a closure's capture rules — a
// binding it consumes (`drop(tx)`, a `move`) is the block's to drop, once;
// the outer scope never drops it again. The `Tracked` value moved into the
// block drops exactly once, inside it.

use std.channel.chan

var DROPS: i32 = 0

type Tracked { tag: str }
impl Drop for Tracked:
    move fn drop():
        print(f"drop:{self.tag}")

fn consume(t: Tracked):
    assert(t.tag == "t")

fn main:
    let (tx, rx) = chan[str](4)
    let t = Tracked { tag: "t" }
    async scope s =>
        let producer = s.track(async:
            tx.send("hello")
            drop(tx)
            consume(t)
        )
        let consumer = s.track(async:
            for msg in rx:
                print(msg)
        )
        producer.await
        consumer.await
    print("ok")
