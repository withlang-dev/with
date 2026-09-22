//! expect-stdout: 42
//! expect-stdout: 3.5
//! expect-stdout: true
//! expect-stdout: Green
//! expect-stdout: lit
//! expect-stdout: owned
//! expect-stdout: owned
//! expect-stdout: ref
//! expect-stdout: global
//! expect-stdout: Pt(7)
//! expect-stdout: 5
//! expect-stdout: 8
//! expect-stdout: 2
//! expect-stdout: yes
//! expect-stdout: ok
//! expect-stderr: 9
//! expect-stderr: err

// D55 ruling 6 (§18.2): `print[T: Display](v: &T)` is a plain generic that
// observes (§3.8) — any Display value prints, the `str` instance is today's
// `print(&str)`; an owned string or a global is printed and kept. A
// `match`/`if` argument joins its arms under the ordinary join rule; arms
// that share a Display type print.

@[derive(Display)]
enum Color { Red | Green }

type Pt { x: i32 }

impl Display for Pt:
    fn to_str() -> str: f"Pt({self.x})"

var G: str = ""

fn main:
    let s: str = "owned"
    let r: &str = "ref"
    print(42)
    print(3.5)
    print(true)
    print(Color.Green)
    print("lit")
    print(s)
    print(s)
    print(r)
    G = G ++ "global"
    print(G)
    print(Pt { x: 7 })
    let n = 5
    print(&n)
    let xs: Vec[i32] = Vec.new()
    xs.push(8)
    for v in xs:
        print(v)
    let x = 3
    print(match x:
        0 => 1
        _ => 2)
    print(if x > 1: "yes" else: "no")
    eprint(9)
    eprint("err")
    print("ok")
