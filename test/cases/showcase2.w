// Test: Comprehensive showcase of With language features
// Tests: structs, enums, traits, generics, closures, pipelines, options, results

type Point = { x: i32, y: i32 }

impl Point =
    fn new(x: i32, y: i32) -> Point = Point { x, y }
    fn distance_sq(self: Point) -> i32 = self.x * self.x + self.y * self.y

trait HasArea =
    fn area(self: Self) -> i32

type Shape = Circle(i32) | Square(i32)

fn shape_area(s: Shape) -> i32 =
    match s
        Circle(r) -> r * r * 3
        Square(side) -> side * side

fn double(x: i32) -> i32 = x * 2
fn add10(x: i32) -> i32 = x + 10

fn safe_div(a: i32, b: i32) -> Result[i32, str] =
    if b == 0 then Err("div by zero") else Ok(a / b)

fn main() -> i32 =
    // Structs with methods
    let p = Point.new(3, 4)
    assert(p.distance_sq() == 25)

    // Enums with pattern matching
    let c = Circle(5)
    let s = Square(4)
    assert(shape_area(c) == 75)
    assert(shape_area(s) == 16)

    // Pipelines
    let piped = 5 |> double |> add10
    assert(piped == 20)

    // Options
    let some: ?i32 = Some(42)
    let none: ?i32 = None
    assert(some ?? 0 == 42)
    assert(none ?? 99 == 99)

    // Results
    let ok = safe_div(10, 2)
    let err = safe_div(10, 0)
    assert(ok ?? -1 == 5)
    assert(err ?? -1 == -1)

    // Generics
    let id_val = id(42)
    assert(id_val == 42)

    // For loop with range
    var sum = 0
    for i in 0..10:
        sum = sum + i
    assert(sum == 45)

    println("all showcase2 tests passed")
    0

fn id[T](x: T) -> T = x
