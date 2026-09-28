// Consumer of the D39 demo bundle: built with --link-bundle <store>/wi_demo it
// sees only wi_demo.wi (declarations) and links the bundle's object.
use std.wi_demo

// Consumes its argument, so a closure calling it consumes its capture.
fn owned_len(s: str) -> i32: s.len() as i32

fn main:
    assert(sizeof[VarArgs]() == sizeof[c_va_list]())
    var p = Pair { a: 3, b: 4 }
    let s = p.sum()
    p.scale(2)
    unsafe { set_first(&raw mut p, 10) }
    let a = add(p)
    let q = Pair { a: 1, b: 2 }
    let w = q.into_word()
    let xs: [3]i32 = [1, 2, 3]
    COUNTER = COUNTER + 5
    let packet = Packet { tag: 7, word: 42 }
    // §12.4 (D75): a consuming closure crosses to the `once` parameter the
    // interface records; a plain one takes a closure that consumes nothing.
    let word = "four".clone()
    let once_len = call_once(() => owned_len(word))
    let twice = call_twice(() => 3)
    print(f"{a} {s} {take(p)} {table_at(2)} {K} {TABLE[1]} {sum_slice(xs)} {level_value(Level.High)} {GREETING.len()} {w} {COUNTER} {packet_word(packet)} {sizeof[Packet]()} {once_len} {twice}")
