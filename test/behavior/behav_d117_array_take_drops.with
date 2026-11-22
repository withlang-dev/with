//! expect-stdout: 1 drops=2
//! expect-stdout: 2 drops=1
//! expect-stdout: 1 drops=2
//! expect-stdout: place 7 drops=0

// D117: an owned array's first()/last()/rest() drops the elements it
// leaves behind at the take — exactly once, like the slice pattern's
// discards — and the observing forms drop nothing.

var drops: i32 = 0

type T { n: i32 }

impl Drop for T:
    move fn drop():
        drops = drops + 1

fn mk() -> [T; 3]: [T { n: 1 }, T { n: 2 }, T { n: 3 }]

fn main:
    let f = mk().first()
    print(f"{if f.is_some(): 1 else: 0} drops={drops}")
    drops = 0
    let r = mk().rest()
    print(f"{r.len()} drops={drops}")
    drops = 0
    let l = mk().last()
    print(f"{if l.is_some(): 1 else: 0} drops={drops}")
    drops = 0
    let p: [T; 2] = [T { n: 7 }, T { n: 8 }]
    let v = p.first()
    print(f"place {v.unwrap().n} drops={drops}")
