//! expect-stdout: 7
//! expect-stdout: alpha alpha
//! expect-stdout: ok

// D111: only an owning parameter takes a hold on a str. `clone(&self)`
// borrows its receiver, so a key view cloned in a loop leaked one count per
// call; and an element without drop glue (a plain struct) iterates by value,
// as Sema binds it, never as a view MIR invented (a field read of the view
// slot built a GEP into a pointer and crashed LLVM). Run under the debug
// allocator: leak count 0.
use std.collections.HashMap

type Pair { a: i64, b: i64 }

fn first_seven(ps: &List[Pair]) -> i64:
    for p in ps.iter():
        if p.a + p.b == 7:
            return p.a + p.b
    0

fn main:
    var ps: List[Pair] = List.new()
    ps.push(Pair { a: 3, b: 4 })
    print(first_seven(ps))
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("alpha".to_owned(), 1)
    var ks: List[str] = List.new()
    for k in m.keys():
        let c = k.clone()
        ks.push(k.clone())
        print(f"{c} {ks[0]}")
    print("ok")
