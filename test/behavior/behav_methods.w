//! expect-stdout: ok

// Tests: method definition on structs, self parameter, static methods,
//        method chaining, methods returning Self

type Point = { x: i32, y: i32 }

fn Point.new(x: i32, y: i32) -> Point:
    Point { x: x, y: y }

fn Point.origin() -> Point:
    Point { x: 0, y: 0 }

fn Point.sum(self: Point) -> i32:
    self.x + self.y

fn Point.translate(self: Point, dx: i32, dy: i32) -> Point:
    Point { x: self.x + dx, y: self.y + dy }

fn Point.scale(self: Point, factor: i32) -> Point:
    Point { x: self.x * factor, y: self.y * factor }

fn test_static_constructor:
    let p = Point.new(3, 4)
    assert(p.x == 3)
    assert(p.y == 4)

fn test_static_origin:
    let p = Point.origin()
    assert(p.x == 0)
    assert(p.y == 0)

fn test_method_call:
    let p = Point.new(3, 4)
    assert(p.sum() == 7)

fn test_method_with_params:
    let p = Point.new(1, 2)
    let q = p.translate(10, 20)
    assert(q.x == 11)
    assert(q.y == 22)

fn test_method_chain:
    let p = Point.new(1, 1).translate(2, 3).scale(2)
    assert(p.x == 6)
    assert(p.y == 8)

type Counter = { value: i32 }

fn Counter.new() -> Counter:
    Counter { value: 0 }

fn Counter.get(self: Counter) -> i32:
    self.value

fn test_counter_methods:
    let c = Counter.new()
    assert(c.get() == 0)

type Rect = { w: i32, h: i32 }

fn Rect.area(self: Rect) -> i32:
    self.w * self.h

fn Rect.perimeter(self: Rect) -> i32:
    2 * (self.w + self.h)

fn Rect.is_square(self: Rect) -> bool:
    self.w == self.h

fn test_rect_methods:
    let r = Rect { w: 3, h: 4 }
    assert(r.area() == 12)
    assert(r.perimeter() == 14)
    assert(not r.is_square())
    let sq = Rect { w: 5, h: 5 }
    assert(sq.is_square())

fn main:
    test_static_constructor()
    test_static_origin()
    test_method_call()
    test_method_with_params()
    test_method_chain()
    test_counter_methods()
    test_rect_methods()
    println("ok")
