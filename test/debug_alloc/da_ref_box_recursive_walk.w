//! expect-debug-alloc: leak count=0
// #1443: recursing through Box payloads bound from `&Enum` match subjects
// reads each node through its box (not the node as the box), builds owned
// strings from the leaves, and every node, box and string is freed once when
// the owning tree goes out of scope.

use std.box.Box

enum T:
    Leaf(v: str)
    Node(l: Box[T], r: Box[T])

fn show(t: &T) -> str:
    match t:
        T.Leaf(v) => v.clone()
        T.Node(l, r) => "(" ++ show(l.as_ref()) ++ " " ++ show(r.as_ref()) ++ ")"

fn leaves(t: &T) -> i64:
    match t:
        T.Leaf(_) => 1
        T.Node(l, r) => leaves(l.as_ref()) + leaves(r.as_ref())

fn main:
    let t = T.Node(Box.new(T.Leaf("a".clone())), Box.new(T.Node(Box.new(T.Leaf("b".clone())), Box.new(T.Leaf("c".clone())))))
    print(show(&t))
    print(leaves(&t))
