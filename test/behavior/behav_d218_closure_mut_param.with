//! expect-stdout: 11 111
//! expect-stdout: 6
//! expect-stdout: 7
//! expect-stdout: 2
//! expect-stdout: 4

// D218 (§9.3, §3.2): a closure checked against a function type with a
// `mut` parameter receives that parameter as `mut`; the literal need not
// repeat it. This is how a callee that brackets work on its receiver
// passes it to the closure: `x.scope((s) => …)`. A literal may also state
// the mode itself, `(mut b: Bag) => …`.
type Bag { n: i32 }

impl Bag:
    mut fn scope(body: fn(mut Bag) -> i32) -> i32:
        self.n += 1
        let r = body(self)
        self.n += 100
        r

fn main:
    var x = Bag { n: 0 }
    let r = x.scope((s) => {
        s.n += 10
        s.n
    })
    print(f"{r} {x.n}")
    var bag = Bag { n: 0 }
    var other = Bag { n: 5 }
    let f = (mut b: Bag) => {
        b.n += 1
        b.n + other.n
    }
    print(f(bag))
    print(f(bag))
    print(bag.n)
    let g: fn(mut Bag) -> i32 = (b) => b.n * 2
    print(g(bag))
