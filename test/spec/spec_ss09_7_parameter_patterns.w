// Spec test: Section 9.7 — Parameter Patterns
//
// A function parameter can be an irrefutable pattern (struct or tuple). The
// incoming argument is destructured at entry, binding the pattern's variables
// in the body. Field shorthand and field renaming both work, and pattern
// parameters compose with ordinary parameters in any position.
//
// (The spec sketch's `distance` example uses f64 `.sqrt()`, an unrelated
// stdlib gap; the Manhattan distance below exercises the same destructuring.)

type Point { x: i32, y: i32 }

// Struct parameter with field shorthand.
fn sum_pt({ x, y }: Point) -> i32:
    x + y

// Two struct parameters with renamed fields.
fn manhattan({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> i32:
    let dx = if x2 > x1: x2 - x1 else: x1 - x2
    let dy = if y2 > y1: y2 - y1 else: y1 - y2
    dx + dy

// Tuple parameter destructuring.
fn swap((a, b): (i32, i32)) -> (i32, i32):
    (b, a)

// A pattern parameter followed by an ordinary parameter.
fn offset_sum({ x, y }: Point, z: i32) -> i32:
    x + y + z

fn option_value(Some(x): Option[i32]) -> i32:
    x

fn option_value(None: Option[i32]) -> i32:
    0

fn test_struct_param_shorthand:
    assert(sum_pt(Point { x: 3, y: 4 }) == 7)

fn test_struct_param_rename:
    assert(manhattan(Point { x: 0, y: 0 }, Point { x: 3, y: 4 }) == 7)

fn test_tuple_param:
    let s = swap((1, 2))
    assert(s.0 == 2 and s.1 == 1)

fn test_pattern_then_ordinary_param:
    assert(offset_sum(Point { x: 1, y: 2 }, 3) == 6)

fn test_refutable_param_clauses:
    assert(option_value(Some(8)) == 8)
    assert(option_value(None) == 0)

fn test_for_loop_destructure:
    var pairs: Vec[(i32, i32)] = Vec.new()
    pairs.push((1, 10))
    pairs.push((2, 20))
    var sum = 0
    for (a, b) in pairs:
        sum += a + b
    assert(sum == 33)
