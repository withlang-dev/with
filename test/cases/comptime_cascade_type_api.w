type Point = { x: i32, y: i32 }

comptime fn count_fields[T: type](x: T) -> i32 =
    let mut n = 0
    for _f in T.fields():
        n += 1
    n

comptime fn type_name_of[T: type](x: T) -> str = T.name()

fn main() -> i32 =
    let p = Point { x: 3, y: 4 }

    assert(count_fields(p) == 2)
    assert(type_name_of(1) == "i32")

    assert(Point.fields().len() == 2)
    assert(Point.size() > 0)
    assert(Point.align() > 0)
    assert(Point.is_copy())
    0
