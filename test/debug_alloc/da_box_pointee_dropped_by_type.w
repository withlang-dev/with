//! expect-debug-alloc: leak count=0
// #1456: a Box dropped as a Box (a local at scope exit, a by-value
// parameter, a payload moved out of a match, a reassigned var) drops its
// pointee by type, then frees. By its LLVM type alone an enum pointee found
// no fields and no Drop impl, so Box.new(L.Cons(5, Box.new(L.Nil))) leaked
// the inner box; Box[str], Box[Vec[str]], a Box of a struct with owned
// fields and Box[Option[str]] leaked their pointee too (23 leaks here on
// base).

use std.box.Box

enum L:
    Cons(v: i64, next: Box[L])
    Nil

enum T:
    Leaf(s: str)
    Node(kids: Vec[Box[T]])

type Rec { name: str, tags: Vec[str] }

fn take(b: Box[L]) -> i64:
    match b.as_ref():
        .Cons(v, _) => v
        .Nil => 0

fn head(l: L) -> i64:
    match l:
        L.Cons(v, next) => v
        L.Nil => 0

fn sum(l: &L) -> i64:
    match l:
        .Cons(v, next) => v + sum(next.as_ref())
        .Nil => 0

fn main:
    let b = Box.new(L.Cons(5, Box.new(L.Nil)))
    print("made")
    let deep = Box.new(L.Cons(1, Box.new(L.Cons(2, Box.new(L.Cons(3, Box.new(L.Nil)))))))
    print(sum(deep.as_ref()))
    print(head(L.Cons(4, Box.new(L.Cons(5, Box.new(L.Nil))))))
    print(take(Box.new(L.Cons(6, Box.new(L.Cons(7, Box.new(L.Nil)))))))
    let s = Box.new("boxed".clone())
    print(s.as_ref().len())
    let strs: Vec[str] = Vec.new()
    strs.push("a".clone())
    strs.push("b".clone())
    let bv = Box.new(strs)
    print(bv.as_ref().len())
    let tags: Vec[str] = Vec.new()
    tags.push("t".clone())
    let rec = Box.new(Rec { name: "r".clone(), tags })
    print(rec.as_ref().name)
    let opt = Box.new(Some("maybe".clone()))
    print(opt.as_ref().is_some())
    let kids: Vec[Box[T]] = Vec.new()
    kids.push(Box.new(T.Leaf("x".clone())))
    kids.push(Box.new(T.Leaf("y".clone())))
    let tree = Box.new(T.Node(kids))
    match tree.as_ref():
        .Node(k) => print(k.len())
        .Leaf(_) => print(0)
    let list: Vec[Box[L]] = Vec.new()
    list.push(Box.new(L.Cons(8, Box.new(L.Nil))))
    print(list.len())
    var re = Box.new(L.Cons(9, Box.new(L.Nil)))
    re = Box.new(L.Cons(10, Box.new(L.Cons(11, Box.new(L.Nil)))))
    print(sum(re.as_ref()))
