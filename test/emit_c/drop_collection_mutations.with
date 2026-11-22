//! expect-debug-alloc: leak count=0
//! expect-stdout: 0
//! expect-stdout: new
//! expect-stdout: 1
//! expect-stdout: b2
//! expect-stdout: c3
//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: x
//! expect-stdout: 4

// #983: every mutation that ends an element's life drops it — clear, an
// overwriting insert, remove, an element store, pop, remove — and every
// read that copies one out takes its hold, as the LLVM backend does.
use std.collections.HashMap
use std.collections.HashSet

fn heap(s: &str) -> str: s ++ ""

fn main:
    var xs = [heap("a1"), heap("b2"), heap("c3")]
    var ys = [heap("p"), heap("q")]
    ys.clear()
    print(ys.len())
    var m: HashMap[str, str] = HashMap.new()
    m.insert(heap("k"), heap("old"))
    m.insert(heap("k"), heap("new"))
    print(m.get("k").unwrap())
    let removed = m.remove("k")
    m.insert(heap("j"), heap("v"))
    print(m.len())
    xs[0] = heap("z")
    print(xs[1])
    let last = xs.pop().unwrap()
    print(last)
    let gone = xs.remove(1)
    print(xs.len())
    var set: HashSet[str] = HashSet.new()
    set.insert(heap("s"))
    set.insert(heap("s"))
    set.insert(heap("t"))
    print(set.len())
    let first: str = xs[0]
    xs[0] = heap("x")
    print(xs[0])
    print(first.len() + removed.unwrap().len() + gone.len() - 2)
