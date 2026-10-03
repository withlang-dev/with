//! expect-stdout: 1
//! expect-stdout: 5
//! expect-stdout: 41 7
//! expect-stdout: 41
//! expect-stdout: 9
//! expect-stdout: 41
//! expect-stdout: 3
//! expect-stdout: 3
//! expect-stdout: 3

// #1903 (§21.1 rule 6): a returned view's origins are every parameter it
// derives from and every global the body returns a view of. What stays
// accepted: the accessor `peek`, a write of its global after the view's
// last use, a `from` clause that names exactly the origins (parameters,
// `self` and globals together), a global origin through a callee, a write
// of another global while the view is live, and mutual recursion and
// a self-recursive function, with no `from` (the sets come by fixpoint).

type Config { limit: i32 }

var CONFIG = Config { limit: 1 }
var HIDDEN: Vec[i32] = Vec.new()
var OTHER: Vec[i32] = Vec.new()
var G: Vec[i32] = Vec.new()

fn peek() -> &Config: &CONFIG

fn set(n: i32): CONFIG = Config { limit: n }

fn grow_other():
    for i in 0..100: OTHER.push(i)

fn pick(p: &Vec[i32], c: bool) -> &i32 from p, HIDDEN:
    if c: &p[0] else: &HIDDEN[0]

fn head() -> &i32 from HIDDEN: &HIDDEN[0]

fn outer(): head()

type Holder { n: i32 }

var SPARE = Holder { n: 9 }

impl Holder:
    fn own_or_spare(c: bool) -> &Holder from self, SPARE:
        if c: self else: &SPARE

fn down(n: i32) -> &i32:
    if n == 0: &G[0] else: up(n - 1)

fn up(n: i32) -> &i32: down(n)

// A `from` clause on a member of the cycle is checked against the
// completed set: G reaches `relay` only through `down`.
fn relay(n: i32) -> &i32 from G: down(n)

// A function that calls itself reads its globals before its
// body has met them; the fixpoint completes the set.
fn deep(n: i32) -> &i32:
    if n > 0: deep(n - 1) else: &G[0]

fn main:
    let c = peek()
    print(c.limit)
    set(5)
    print(peek().limit)
    HIDDEN.push(41)
    var x: Vec[i32] = Vec.new()
    x.push(7)
    let a = pick(&x, false)
    let b = pick(&x, true)
    grow_other()
    print(f"{*a} {*b}")
    let r = outer()
    grow_other()
    print(*r)
    let h = Holder { n: 2 }
    print(h.own_or_spare(false).n)
    print(*head())
    G.push(3)
    print(*up(4))
    print(*deep(2))
    print(*relay(1))
