//! expect-stdout: 3 0 2
//! expect-stdout: 1 0
//! expect-stdout: 5 0 0
//! expect-stdout: 15 0 5 0
//! expect-stdout: 0 1 0 1 0 1 0 1 0 1 0 1
//! expect-stdout: 1 1 0 0
//! expect-stdout: 6 0

// #1373: a let pattern is the pattern grammar a match arm accepts (§9.7,
// §30.4 LET_STMT, §30.6): qualified `Type.Variant(..)`, qualified unit,
// bare variant, nested, `var`, annotated, literals, ranges, or, at-binding.
// Struct patterns with literal fields are left to #1388; slice patterns over &Vec to #1389.

enum Shape:
    Named(i32)
    Other(i32)
    Empty

fn qualified(s: Shape) -> i32:
    let Shape.Named(n) = s else: return 0
    n

fn bare(s: Shape) -> i32:
    let Named(n) = s else: return 0
    n

fn qualified_unit(s: Shape) -> i32:
    let Shape.Empty = s else: return 1
    0

fn nested(o: Option[Shape]) -> i32:
    let Some(Shape.Named(n)) = o else: return 0
    n

fn var_qualified(s: Shape) -> i32:
    var Shape.Named(n) = s else: return 0
    n = n + 10
    n

fn annotated(s: Shape) -> i32:
    let Shape.Named(n): Shape = s else: return 0
    n

fn int_lit(k: i32) -> i32:
    let 0 = k else: return 1
    0

fn neg_lit(k: i32) -> i32:
    let -1 = k else: return 1
    0

fn str_lit(s: str) -> i32:
    let "hi" = s else: return 1
    0

fn bool_lit(b: bool) -> i32:
    let true = b else: return 1
    0

fn char_lit(c: u8) -> i32:
    let 'a' = c else: return 1
    0

fn range(k: i32) -> i32:
    let 1..=5 = k else: return 1
    0

fn one_or_two(o: Option[i32]) -> i32:
    let Some(1) | Some(2) = o else: return 0
    1

fn at_binding(o: Option[i32]) -> i32:
    let whole @ Some(v) = o else: return 0
    v + whole.unwrap()

fn main:
    print(f"{qualified(Shape.Named(3))} {qualified(Shape.Other(4))} {bare(Shape.Named(2))}")
    print(f"{qualified_unit(Shape.Named(3))} {qualified_unit(Shape.Empty)}")
    print(f"{nested(Some(Shape.Named(5)))} {nested(Some(Shape.Empty))} {nested(None)}")
    print(f"{var_qualified(Shape.Named(5))} {var_qualified(Shape.Empty)} {annotated(Shape.Named(5))} {annotated(Shape.Empty)}")
    print(f"{int_lit(0)} {int_lit(5)} {neg_lit(-1)} {neg_lit(5)} {str_lit("hi")} {str_lit("no")} {bool_lit(true)} {bool_lit(false)} {char_lit('a')} {char_lit('b')} {range(3)} {range(9)}")
    print(f"{one_or_two(Some(1))} {one_or_two(Some(2))} {one_or_two(Some(3))} {one_or_two(None)}")
    print(f"{at_binding(Some(3))} {at_binding(None)}")
