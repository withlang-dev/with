//! expect-stdout: option of str: true false true
//! expect-stdout: enum payloads: true false false true
//! expect-stdout: vec: true false false true
//! expect-stdout: nested: true false
//! expect-stdout: result: true false false
//! expect-stdout: box: true false
//! expect-stdout: tuple and array: true false true false
//! expect-stdout: struct fields: true false true
//! expect-stdout: part with its own eq: true false
//! expect-stdout: generic part with its own eq: true false
//! expect-stdout: views: true false true true
//! expect-stdout: recursive: true false
//! expect-stdout: not equal: true false
//! expect-stdout: ok

// #2137 (§11.7, §11.8): `==` on a value with no `eq` of its own compares
// it by its With type — field by field, element by element, variant by
// variant — and a part that has an `eq` is compared by that method. It was
// compared as the bytes of its representation: an enum's payload as raw
// bytes, so `Option[str] == Some("a")` was false, and a `Vec` by its buffer
// pointer. Each case builds its operands apart (`to_lower`, separate
// vectors), so nothing is equal by sharing storage.
use std.box.Box

enum Token:
    Name(str)
    Pair(str, i32)
    End

type Holder { tag: Option[str], items: Vec[str], n: i32 }

// Equal when the text matches without regard to case.
type Loose { text: str }
impl Eq for Loose:
    fn eq(other: &Loose): self.text.to_lower() == other.text.to_lower()

// Equal when the keys match; the note is not compared.
type Keyed[T] { key: T, note: str }
impl[T] Eq for Keyed[T]:
    fn eq(other: &Keyed[T]): self.key == other.key

enum Tree:
    Leaf(str)
    Node(Box[Tree], Box[Tree])

fn same_holder(a: &Holder, b: &Holder): a == b
fn same_names(a: &Vec[str], b: &Vec[str]): a == b

fn a: "A".to_lower()

fn tree(text: str): Tree.Node(Box.new(.Leaf(text)), Box.new(.Node(Box.new(.Leaf("x")), Box.new(.Leaf("y")))))

fn main:
    let some: Option[str] = Some(a())
    let none: Option[str] = None
    print(f"option of str: {some == Some("a")} {some == Some("b")} {none == None}")
    print(f"enum payloads: {Token.Name(a()) == Token.Name("a")} {Token.Name(a()) == Token.Pair("a", 1)} {Token.Pair(a(), 1) == Token.Pair("a", 2)} {Token.End == Token.End}")
    let names: Vec[str] = [a(), "b"]
    let same: Vec[str] = ["a", "b"]
    let shorter: Vec[str] = ["a"]
    let other: Vec[str] = ["a", "c"]
    let empty: Vec[str] = Vec.new()
    let none_yet: Vec[str] = Vec.new()
    print(f"vec: {names == same} {names == shorter} {names == other} {empty == none_yet}")
    let deep: Option[Option[Vec[str]]] = Some(Some([a()]))
    print(f"nested: {deep == Some(Some(["a"]))} {deep == Some(None)}")
    let failed: Result[i32, str] = Err("bad".to_lower())
    print(f"result: {failed == Err("bad")} {failed == Err("worse")} {failed == Ok(1)}")
    print(f"box: {Box.new(a()) == Box.new("a")} {Box.new(a()) == Box.new("b")}")
    let grid: [2]Option[str] = [Some(a()), None]
    let absent: (Option[str], i32) = (None, 1)
    print(f"tuple and array: {(Some(a()), 1) == (Some("a"), 1)} {(Some(a()), 1) == absent} {grid == [Some("a"), None]} {grid == [Some("a"), Some("a")]}")
    let held = Holder { tag: Some(a()), items: [a()], n: 1 }
    print(f"struct fields: {held == Holder { tag: Some("a"), items: ["a"], n: 1 }} {held == Holder { tag: Some("a"), items: ["b"], n: 1 }} {same_holder(held, Holder { tag: Some("a"), items: ["a"], n: 1 })}")
    let loose: Option[Loose] = Some(Loose { text: "A" })
    print(f"part with its own eq: {loose == Some(Loose { text: "a" })} {loose == Some(Loose { text: "b" })}")
    let keyed: Vec[Keyed[i32]] = [Keyed { key: 1, note: "first" }]
    let rekeyed: Vec[Keyed[i32]] = [Keyed { key: 1, note: "again" }]
    let unkeyed: Vec[Keyed[i32]] = [Keyed { key: 2, note: "first" }]
    print(f"generic part with its own eq: {keyed == rekeyed} {keyed == unkeyed}")
    let view: Option[&str] = Some("a")
    print(f"views: {same_names(names, same)} {same_names(names, other)} {view == Some(a())} {(a() in names) and (Some(a()) == some)}")
    print(f"recursive: {tree(a()) == tree("a")} {tree(a()) == tree("b")}")
    print(f"not equal: {some != Some("b")} {names != same}")
    print("ok")
