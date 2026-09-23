//! expect-stdout: 3
//! expect-stdout: 5
//! expect-stdout: 3
//! expect-stdout: 9
//! expect-stdout: 0
//! expect-stdout: wrapped

// #1439: the type-cycle check follows a generic's by-value arguments
// (Option[E] is infinite); recursion behind an indirection stays legal —
// Vec[E], Option[Box[E]], HashMap[str, E], a user generic holding Box[E],
// a generic node behind Option[Box[..]], and a user type named `T` beside
// Option[T] (a generic's parameter is not that type).
use std.box.Box
use std.collections.HashMap

type T { x: Option[i32] }

type Node[V] { next: Option[Box[Node[V]]], v: V }

type Wrap[V] { w: V }

enum Tree:
    Leaf(n: i64)
    Branch(kids: Vec[Tree])

enum List:
    Cons(v: i64, next: Option[Box[List]])
    Nil

enum Named:
    Many(m: HashMap[str, Named])
    One(n: i64)

enum Boxed:
    Wrapped(w: Wrap[Box[Boxed]])
    End

fn tree_sum(t: &Tree) -> i64:
    match t:
        .Leaf(n) => n
        .Branch(kids) =>
            var total: i64 = 0
            for k in kids:
                total = total + tree_sum(k)
            total

fn list_sum(l: &List) -> i64:
    match l:
        .Cons(v, next) =>
            match next:
                Some(b) => v + list_sum(b.as_ref())
                None => v
        .Nil => 0

fn main:
    let t = T { x: Some(3) }
    print(t.x ?? 0)
    let n = Node { next: None, v: 5 }
    print(n.v)
    let kids: Vec[Tree] = Vec.new()
    kids.push(Tree.Leaf(1))
    kids.push(Tree.Leaf(2))
    print(tree_sum(Tree.Branch(kids)))
    print(list_sum(List.Cons(4, Some(Box.new(List.Cons(5, None))))))
    let m: HashMap[str, Named] = HashMap.new()
    let named = Named.Many(m)
    match named:
        .Many(inner) => print(inner.len())
        .One(v) => print(v)
    let b = Boxed.Wrapped(Wrap { w: Box.new(Boxed.End) })
    match b:
        .Wrapped(_) => print("wrapped")
        .End => print("end")
