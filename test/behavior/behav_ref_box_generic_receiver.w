//! expect-stdout: sum=6
//! expect-stdout: eval=7
//! expect-stdout: first=41
//! expect-stdout: double=10
//! expect-stdout: wrap=42
//! expect-stdout: rc=77
//! expect-stdout: field=11
//! expect-stdout: box-deref=33 33
//! expect-stdout: vec-box=7

// #1443: a generic method whose receiver is `&Self` called through a
// reference to the receiver — a `Box` bound from a `&Enum` match subject, a
// `&Box` parameter, `&&Box`, a `for` view over `Vec[Box[T]]`. The autoderef
// walk reaches the place behind the reference, and the call must pass that
// place's address. It passed the Box value (a `ptr`, like `&Box`), so the
// callee read the list node as the box: the sum returned the head (1) and
// the other shapes crashed.

use std.box.Box
use std.rc.Rc

enum L:
    Cons(v: i64, next: Box[L])
    Nil

enum Expr:
    Num(n: i64)
    Neg(e: Box[Expr])
    Add(a: Box[Expr], b: Box[Expr])

type Wrap[T] { inner: T, tag: i64 }

impl[T] Wrap[T]:
    fn get(self: &Self) -> &T: &self.inner
    fn tag_of(self: &Self) -> i64: self.tag

type Node { val: i64, child: Box[i64] }

fn sum(l: &L) -> i64:
    match l:
        L.Cons(v, next) => v + sum(next.as_ref())
        L.Nil => 0

fn eval(e: &Expr) -> i64:
    match e:
        Expr.Num(n) => n
        Expr.Neg(inner) => 0 - eval(inner.as_ref())
        Expr.Add(a, b) => eval(a.as_ref()) + eval(b.as_ref())

fn first(b: &Box[i64]) -> i64:
    let r = b.as_ref()
    r + 0

fn double(b: &Box[i64]) -> i64:
    let rr = &b
    let r = rr.as_ref()
    r + 1

fn via_ref(w: &Wrap[i64]) -> i64:
    let g = w.get()
    g + w.tag_of()

fn peek(r: &Rc[i64]) -> i64:
    let v = r.as_ref()
    v + 0

fn child_of(n: &Node) -> i64:
    let c = n.child.as_ref()
    c + n.val

fn via_box(b: &Box[Wrap[i64]]) -> i64: b.tag_of()

fn main:
    let l = L.Cons(1, Box.new(L.Cons(2, Box.new(L.Cons(3, Box.new(L.Nil))))))
    print(f"sum={sum(&l)}")
    let e = Expr.Add(Box.new(Expr.Neg(Box.new(Expr.Num(5)))), Box.new(Expr.Num(12)))
    print(f"eval={eval(&e)}")
    let b = Box.new(41)
    print(f"first={first(&b)}")
    let nine = Box.new(9)
    print(f"double={double(&nine)}")
    let w = Wrap { inner: 40, tag: 2 }
    print(f"wrap={via_ref(&w)}")
    let r = Rc.new(77)
    print(f"rc={peek(&r)}")
    let n = Node { val: 1, child: Box.new(10) }
    print(f"field={child_of(&n)}")
    let bw = Box.new(Wrap { inner: 1, tag: 33 })
    print(f"box-deref={bw.tag_of()} {via_box(&bw)}")
    var v: Vec[Box[i64]] = Vec.new()
    v.push(Box.new(3))
    v.push(Box.new(4))
    var t: i64 = 0
    for bx in v:
        t = t + bx.as_ref()
    print(f"vec-box={t}")
