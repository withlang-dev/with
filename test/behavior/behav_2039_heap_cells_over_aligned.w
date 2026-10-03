//! expect-stdout: alignof 32 32 128 32 32
//! expect-stdout: box 32 true 7
//! expect-stdout: box128 true 9
//! expect-stdout: boxes aligned 8
//! expect-stdout: mutex true 5
//! expect-stdout: rwlock true 6
//! expect-stdout: inner 7

// #2039: a heap cell of an over-aligned T (§16.4 `@[align(N)]`) sits at T's
// TypeLayout alignment. Box.new, Mutex.new, RwLock.new and generator cores
// took `with_alloc(sizeof[T])`, whose payloads are 16-aligned, so `b.v` of a
// Box[Al] could sit at 16 mod 32. They now pass alignof[T].

use std.box.Box
use std.sync

type Al { a: i8, @[align(32)] v: i64 }
type Big { @[align(128)] n: i64 }

// The generic path: alignof[T] in a specialization reported LLVM's 8.
fn align_in_generic[T](value: &T) -> i64: alignof[T]()

fn main:
    let probe_al = Al { a: 0, v: 0 }
    let opt_al = Some(Al { a: 0, v: 0 })
    let pair_al = (Al { a: 0, v: 0 }, 1 as i8)
    print(f"alignof {alignof[Al]()} {align_in_generic(&probe_al)} {align_in_generic(&Big { n: 0 })} {align_in_generic(&opt_al)} {align_in_generic(&pair_al)}")
    let b = Box.new(Al { a: 1, v: 7 })
    print(f"box {comptime Al.align()} {(&raw const b.v as i64) % 32 == 0} {b.v}")
    let big = Box.new(Big { n: 9 })
    print(f"box128 {(&raw const big.n as i64) % 128 == 0} {big.n}")
    // Several in a row: the allocator's 16-aligned payloads land at both
    // residues mod 32, so one lucky cell proves nothing.
    var boxes: Vec[Box[Al]] = Vec.new()
    for i in 0..8: boxes.push(Box.new(Al { a: 2, v: i as i64 }))
    var ok = 0
    for i in 0..boxes.len() as i32:
        if (&raw const boxes[i].v as i64) % 32 == 0: ok += 1
    print(f"boxes aligned {ok}")
    let m = Mutex[Al].new(Al { a: 3, v: 5 })
    let (m_ok, m_v) = with m.enter() as data:
        ((&raw const data.v as i64) % 32 == 0, data.v)
    print(f"mutex {m_ok} {m_v}")
    let rw = RwLock[Al].new(Al { a: 4, v: 6 })
    let (rw_ok, rw_v) = with rw.enter() as data:
        ((&raw const data.v as i64) % 32 == 0, data.v)
    print(f"rwlock {rw_ok} {rw_v}")
    let back = b.into_inner()
    print(f"inner {back.v}")
