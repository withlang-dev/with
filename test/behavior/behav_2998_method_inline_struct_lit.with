//! expect-stdout: 1 2
//! expect-stdout: 4 7 9
//! expect-stdout: 5 2
//! expect-stdout: ok

// #2998: in a script (and inside generic instances), on-demand D43 return
// inference (`ensure_body_typed`) types instance, static, extension, operator,
// and optional-chained methods before reading their return type — including
// one-line colon bodies returning a struct literal.

type P { a: i32, b: i32 }
type S { n: i32 }

impl S:
    fn doubled(): S { n: self.n * 2 }

fn S.make(v: i32): S { n: v }

extend S:
    fn pair(x: i32): P { a: x, b: self.n }
    fn add(rhs: &S): S { n: self.n + rhs.n }

let s = S.make(2)
let p = s.pair(1)
print(f"{p.a} {p.b}")

let d = s.doubled()
let seven = S.make(7)
let sum = s + seven
print(f"{d.n} {seven.n} {sum.n}")

let opt: Option[S] = Some(s)
let op = (opt?.pair(5)).unwrap()
print(f"{op.a} {op.b}")
print("ok")
