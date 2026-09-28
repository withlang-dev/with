//! expect-stdout: push 200
//! expect-stdout: veclit 200 200
//! expect-stdout: push64 4000000000
//! expect-stdout: contains true
//! expect-stdout: slot 200 -1
//! expect-stdout: range -1 200
//! expect-stdout: map 200 4000000000
//! expect-stdout: get 5 true 5
//! expect-stdout: set true true
//! expect-stdout: maplit 4000000000
//! expect-stdout: entry 4000000000
//! expect-stdout: or_insert 4000000000
//! expect-stdout: increment 1
//! expect-stdout: slotmap 4000000000 4000000000
//! expect-stdout: atomic 4000000000 8000000000
//! expect-stdout: chan 4000000000 200

// §4.2.6: an unsigned value widens into a wider element, key or value type
// by zero extension on every container argument, as it does at a `let` or
// a call. The container intrinsics took the LLVM value and sign-extended
// (`v.push(u8 200)` into a Vec[i16] read -56, a u32 key 4000000000 missed
// its i64 entry), and VecSlot/VecRange/Entry/Sender stored the narrow value
// at its own width, writing one byte of a two-byte element.
use std.collections.SlotMap
use std.collections.HashMap
use std.collections.HashSet
use std.channel
use std.sync

async fn produce(tx: Sender[i64]):
    let u: u32 = 4000000000
    let s: u8 = 200
    tx.send(u)
    tx.send(s)
    tx.close()

async fn consume(rx: Receiver[i64]):
    let a = rx.recv().unwrap()
    let b = rx.recv().unwrap()
    print(f"chan {a} {b}")

async fn main:
    let s: u8 = 200
    let u: u32 = 4000000000
    var v: Vec[i16] = Vec.new()
    v.push(s)
    print(f"push {v[0]}")
    let lit: Vec[i16] = [s, s]
    print(f"veclit {lit[0]} {lit[1]}")
    var v64: Vec[i64] = Vec.new()
    v64.push(u)
    print(f"push64 {v64[0]}")
    print(f"contains {v64.contains(u)}")

    let w: Vec[i16] = Vec.new()
    w.push(-1)
    w.push(-1)
    with w.slot(0) as mut slot:
        slot.set(s)
    print(f"slot {w[0]} {w[1]}")
    w[0] = -1
    with w.range(0..2) as mut r:
        r.set(1, s)
    print(f"range {w[0]} {w[1]}")

    var m: HashMap[i16, i64] = HashMap.new()
    m.insert(s, u)
    for (k, val) in m:
        print(f"map {k} {val}")
    var k: HashMap[i64, i64] = HashMap.new()
    k.insert(4000000000, 5)
    let got = k.get(u) ?? 0
    print(f"get {got} {k.contains(u)} {k.remove(u) ?? 0}")
    var hs: HashSet[i64] = HashSet.new()
    hs.insert(u)
    print(f"set {hs.contains(4000000000)} {hs.contains(u)}")
    let ml: HashMap[i64, i64] = [u: u]
    print(f"maplit {ml.get(4000000000) ?? 0}")

    var e: HashMap[str, i64] = HashMap.new()
    e.insert("k", -1)
    with e.entry("k") as mut en:
        en.set(u)
    print(f"entry {e.get("k") ?? 0}")
    with e.entry("n") as mut en2:
        en2.or_insert(u)
    print(f"or_insert {e.get("n") ?? 0}")
    var c: HashMap[i64, i64] = HashMap.new()
    c.increment(u)
    print(f"increment {c.get(4000000000) ?? 0}")

    var sm: SlotMap[i64] = SlotMap.new()
    let h = sm.insert(u)
    let first = sm.get(h).unwrap()
    with sm.slot(h) as mut s2:
        s2.set(u)
    print(f"slotmap {first} {sm.get(h).unwrap()}")

    let a: Atomic[i64] = Atomic.new(u)
    let a0 = a.load(.SeqCst)
    a.fetch_add(u, .SeqCst)
    print(f"atomic {a0} {a.load(.SeqCst)}")

    let pair = chan[i64](8)
    let (tx, rx) = pair
    let p = produce(move tx)
    let q = consume(move rx)
    q.await
    p.await
