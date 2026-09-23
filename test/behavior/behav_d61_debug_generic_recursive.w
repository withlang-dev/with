//! expect-stdout: ok

// §15.4.7 / D61: generic structs and enums format per instantiation, and a
// type recursive through Box formats to its full depth — each type's
// formatter is one function, so the recursion is a call, not an expansion.
// A Box is transparent: it formats what it owns. (A user generic enum's
// payload-less variant, `Maybe.Nothing`, cannot be constructed yet — #1558;
// Option's None covers the generic unit variant.)

use std.box.Box

type Pair[T] { left: T, right: T }
enum Maybe[T]:
    Just(T)
    Nothing
type Cell[K, V] { key: K, values: Vec[V] }

enum List:
    Cons(i32, Box[List])
    Nil

type Node { label: str, left: Option[Box[Node]], right: Option[Box[Node]] }

fn leaf(label: str) -> Node: Node { label, left: None, right: None }

fn check(got: &str, want: &str):
    if got != want:
        print(f"mismatch\n  got:  {got}\n  want: {want}")
        assert(false)

fn main:
    let ints = Pair { left: 1, right: 2 }
    check(f"{ints:?}", "Pair { left: 1, right: 2 }")
    let strs = Pair { left: "a", right: "b" }
    check(f"{strs:?}", r#"Pair { left: "a", right: "b" }"#)
    let nested = Pair { left: Pair { left: 1, right: 2 }, right: Pair { left: 3, right: 4 } }
    check(f"{nested:?}", "Pair { left: Pair { left: 1, right: 2 }, right: Pair { left: 3, right: 4 } }")
    let just: Maybe[Pair[str]] = Maybe.Just(Pair { left: "x", right: "y" })
    check(f"{just:?}", r#"Just(Pair { left: "x", right: "y" })"#)
    let cell_values: Vec[Maybe[i32]] = Vec.new()
    cell_values.push(Maybe.Just(1))
    cell_values.push(Maybe.Just(2))
    let cell = Cell { key: "k", values: cell_values }
    check(f"{cell:?}", r#"Cell { key: "k", values: [Just(1), Just(2)] }"#)

    let boxed = Box.new(5)
    check(f"{boxed:?}", "5")
    let boxed_pair = Box.new(Pair { left: "l", right: "r" })
    check(f"{boxed_pair:?}", r#"Pair { left: "l", right: "r" }"#)

    let list = List.Cons(1, Box.new(List.Cons(2, Box.new(List.Cons(3, Box.new(List.Nil))))))
    check(f"{list:?}", "Cons(1, Cons(2, Cons(3, Nil)))")
    check(f"{List.Nil:?}", "Nil")

    let tree = Node { label: "root", left: Some(Box.new(leaf("l"))), right: Some(Box.new(Node { label: "r", left: None, right: Some(Box.new(leaf("rr"))) })) }
    check(f"{tree:?}", r#"Node { label: "root", left: Some(Node { label: "l", left: None, right: None }), right: Some(Node { label: "r", left: None, right: Some(Node { label: "rr", left: None, right: None }) }) }"#)
    print("ok")
