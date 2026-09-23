//! expect-stdout: ok

// §15.4.7 / D61: every row of the `:?` table, at depth 0, 1 and 2. Debug is
// recursive — every struct field, enum payload and collection element is
// formatted with `:?`, so a value formats the same at every depth.

use std.collections.HashMap
use std.collections.BTreeMap

type Point { x: i32, y: i32 }
type Empty {}
type Named { name: str, at: Point }
type Holder { inner: Named, flag: bool }
enum Shape:
    Dot
    Circle(f64)
    Tagged(str)
type ShapeBox { shape: Shape, all: Vec[Shape] }

fn slice_form(xs: []i32) -> str: f"{xs:?}"
fn view_form(xs: &[str]) -> str: f"{xs:?}"
fn points_form(xs: []Point) -> str: f"{xs:?}"

fn check(got: &str, want: &str):
    if got != want:
        print(f"mismatch\n  got:  {got}\n  want: {want}")
        assert(false)

fn main:
    // Integers, floats, bool: the default display at every depth.
    let i: i32 = -42
    let big: u64 = 18446744073709551615
    let small: i64 = -9223372036854775807
    let byte: u8 = 255
    let tiny: i8 = -128
    let f: f64 = 3.5
    let yes = true
    check(f"{i:?} {big:?} {small:?} {byte:?} {tiny:?} {f:?} {yes:?}", "-42 18446744073709551615 -9223372036854775807 255 -128 3.5 true")
    let ints: Vec[u64] = Vec.new()
    ints.push(big)
    ints.push(0)
    check(f"{ints:?}", "[18446744073709551615, 0]")

    // Struct: `TypeName { field: value, field: value }`; no fields reads `TypeName {}`.
    let p = Point { x: 1, y: -2 }
    check(f"{p:?}", "Point { x: 1, y: -2 }")
    let e = Empty {}
    check(f"{e:?}", "Empty {}")
    let named = Named { name: "n", at: Point { x: 3, y: 4 } }
    check(f"{named:?}", r#"Named { name: "n", at: Point { x: 3, y: 4 } }"#)
    let holder = Holder { inner: Named { name: "deep", at: Point { x: 5, y: 6 } }, flag: false }
    check(f"{holder:?}", r#"Holder { inner: Named { name: "deep", at: Point { x: 5, y: 6 } }, flag: false }"#)

    // Enum: `Variant`, or `Variant(payload)`.
    check(f"{Shape.Dot:?}", "Dot")
    let circle = Shape.Circle(1.5)
    check(f"{circle:?}", "Circle(1.5)")
    let tagged = Shape.Tagged("t, u")
    check(f"{tagged:?}", r#"Tagged("t, u")"#)
    let shapes: Vec[Shape] = Vec.new()
    shapes.push(Shape.Dot)
    shapes.push(Shape.Tagged("x"))
    let sb = ShapeBox { shape: Shape.Circle(0.5), all: shapes }
    check(f"{sb:?}", r#"ShapeBox { shape: Circle(0.5), all: [Dot, Tagged("x")] }"#)

    // Option / Result: `Some(value)` / `None`, `Ok(value)` / `Err(error)`.
    let some: Option[Point] = Some(Point { x: 7, y: 8 })
    let none: Option[Point] = None
    let ok: Result[str, str] = Ok("fine")
    let err: Result[str, str] = Err("bad")
    check(f"{some:?} {none:?} {ok:?} {err:?}", r#"Some(Point { x: 7, y: 8 }) None Ok("fine") Err("bad")"#)
    let nested: Option[Option[str]] = Some(Some("in"))
    check(f"{nested:?}", r#"Some(Some("in"))"#)
    let unit: Option[Unit] = Some(())
    check(f"{unit:?}", "Some(())")

    // Vec, array, slice: `[elem, elem]`; empty reads `[]`.
    let names: Vec[str] = Vec.new()
    names.push("a")
    names.push("b, c")
    check(f"{names:?}", r#"["a", "b, c"]"#)
    let none_yet: Vec[str] = Vec.new()
    check(f"{none_yet:?}", "[]")
    let grid: Vec[Vec[i32]] = Vec.new()
    let row: Vec[i32] = Vec.new()
    row.push(1)
    row.push(2)
    grid.push(row)
    grid.push(Vec.new())
    check(f"{grid:?}", "[[1, 2], []]")
    let arr: [3]i32 = [4, 5, 6]
    check(f"{arr:?}", "[4, 5, 6]")
    let words: [2]str = ["x", "y\"z"]
    check(f"{words:?}", r#"["x", "y\"z"]"#)
    let points: [2]Point = [Point { x: 1, y: 1 }, Point { x: 2, y: 2 }]
    check(f"{points:?}", "[Point { x: 1, y: 1 }, Point { x: 2, y: 2 }]")

    let four: [4]i32 = [1, 2, 3, 4]
    check(slice_form(four[1..3]), "[2, 3]")
    check(slice_form(four[0..0]), "[]")
    check(view_form(&words[..]), r#"["x", "y\"z"]"#)
    check(points_form(points[..]), "[Point { x: 1, y: 1 }, Point { x: 2, y: 2 }]")

    // Tuple: `(a, b)`.
    let pair = (1, "one")
    check(f"{pair:?}", r#"(1, "one")"#)

    // HashMap: `{key: value, ...}` ordered by the Debug text of the keys —
    // byte order of that text, so `10` sorts before `2` and a str key's
    // quote is part of it. Empty reads `{}`.
    var scores: HashMap[str, i32] = HashMap.new()
    scores.insert("zeta", 1)
    scores.insert("alpha", 2)
    scores.insert("mid", 3)
    check(f"{scores:?}", r#"{"alpha": 2, "mid": 3, "zeta": 1}"#)
    var by_num: HashMap[i32, str] = HashMap.new()
    by_num.insert(10, "ten")
    by_num.insert(2, "two")
    by_num.insert(-1, "minus")
    check(f"{by_num:?}", r#"{-1: "minus", 10: "ten", 2: "two"}"#)
    let empty_map: HashMap[str, i32] = HashMap.new()
    check(f"{empty_map:?}", "{}")
    var lists: HashMap[str, Vec[Point]] = HashMap.new()
    let pts: Vec[Point] = Vec.new()
    pts.push(Point { x: 0, y: 0 })
    lists.insert("origin", pts)
    lists.insert("none", Vec.new())
    check(f"{lists:?}", r#"{"none": [], "origin": [Point { x: 0, y: 0 }]}"#)

    // BTreeMap: `{key: value, ...}` in key order.
    var tree: BTreeMap[i32, str] = BTreeMap.new()
    tree.insert(10, "ten")
    tree.insert(2, "two")
    check(f"{tree:?}", r#"{2: "two", 10: "ten"}"#)
    let empty_tree: BTreeMap[i32, str] = BTreeMap.new()
    check(f"{empty_tree:?}", "{}")

    // A view formats its pointee, at any depth.
    let view: &Point = &p
    check(f"{view:?}", "Point { x: 1, y: -2 }")
    let viewed: Option[&Point] = Some(&p)
    check(f"{viewed:?}", "Some(Point { x: 1, y: -2 })")
    let absent: Option[&Point] = None
    check(f"{absent:?}", "None")
    print("ok")
