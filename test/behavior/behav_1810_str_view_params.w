//! expect-stdout: alpha
//! expect-stdout: beta
//! expect-stdout: alpha
//! expect-stdout: alpha
//! expect-stdout: 5
//! expect-stdout: alpha
//! expect-stdout: gamma
//! expect-stdout: gamma
//! expect-stdout: d1
//! expect-stdout: d0
//! expect-stdout: d1
//! expect-stdout: generic alpha
//! expect-stdout: closure 5
//! expect-stdout: fnref alpha!
//! expect-stdout: if beta
//! expect-stdout: tuple alpha 7
//! expect-stdout: 104
//! expect-stdout: ello
//! expect-stdout: hello!
//! expect-stdout: cap hello 5
//! expect-stdout: refref hello 5
//! expect-stdout: raw hello
//! expect-stdout: name ada

// #1810: a `&str` is a `{ptr, len}` view value — passed, returned and held
// by value, never a pointer to a str header. Every producer of a view into
// a `&str` parameter (explicit `&`, auto-reference of a local, a literal, a
// field, a Vec element, iteration), forwarding, returning a parameter view,
// generic and callable consumers, str receivers (`fn` reads a view, `mut fn`
// takes the caller's place), a closure capturing a view, a reference to a
// view, raw pointers to a header, and a distinct type over str.

extend str:
    fn first_byte() -> i32: self[0] as i32
    fn rest() -> str: self.slice(1, self.len())
    mut fn bang(): self = self ++ "!"

type Name = distinct str

fn show(s: &str): print(s)
fn len_of(s: &str) -> i64: s.len()
fn fwd(s: &str): show(s)
fn first(s: &str) -> &str: s
fn id[T](x: T) -> T: x
fn apply(s: &str, read: &fn(&str) -> str) -> str: read(s)
fn shout(s: &str) -> str: s.clone() ++ "!"
fn pick(c: bool, a: &str, b: &str) -> &str: if c: a else: b
fn call0(f: fn() -> str) -> str: f()
fn len2(r: &&str) -> i64: r.len()
fn name_text(n: &Name) -> str: n as str

type Named { name: str, n: i32 }
impl Named:
    fn name_view() -> &str: self.name

fn main:
    let owned = "alpha"
    show(owned)
    show("beta")
    show(&owned)
    let r: &str = owned
    fwd(r)
    print(len_of(r))
    print(first(r))
    let nm = Named { name: "gamma", n: 1 }
    show(nm.name)
    print(nm.name_view())
    var xs: Vec[str] = Vec.new()
    xs.push("d0")
    xs.push("d1")
    show(xs[1])
    for s in xs: show(s)
    print("generic " ++ id(r))
    let f = (s: &str) => s.len()
    print(f"closure {f(r)}")
    print("fnref " ++ apply(r, &shout))
    print("if " ++ pick(false, r, "beta"))
    let t = (r, 7)
    print(f"tuple {t.0} {t.1}")
    let h = "hello"
    let hv: &str = h
    print(hv.first_byte())
    print(hv.rest())
    var m = "hello"
    m.bang()
    show(m)
    print(call0(() => f"cap {hv} {hv.len()}"))
    let rr = &hv
    print(f"refref {rr} {len2(rr)}")
    let p = hv as *const str
    let back: &str = unsafe { &*p }
    print("raw " ++ back)
    let n = Name("ada")
    print("name " ++ name_text(&n))
