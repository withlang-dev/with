//! expect-stdout: ok

// §3.8 companions to the consume rule: `copy x` keeps the binding live,
// `&T` parameters borrow without invalidating, and Copy types are
// copied rather than consumed.

@[derive(Clone)]
type Acc { buf: str, name: str }

fn touch(a: Acc) -> i32:
    a.buf.len() as i32

fn peek(a: &Acc) -> i32:
    a.buf.len() as i32

type Point { x: i32, y: i32 }
impl Copy for Point

fn take_point(p: Point) -> i32:
    p.x + p.y

fn test_copy_arg_keeps_binding:
    var a = Acc { buf: "abc", name: "n" }
    let n = touch(copy a)
    assert(n == 3)
    assert(a.buf == "abc")
    assert(a.name == "n")

fn test_ref_param_borrows:
    var a = Acc { buf: "abcd", name: "n" }
    let n = peek(a)
    assert(n == 4)
    assert(a.buf == "abcd")

fn test_copy_type_not_consumed:
    let p = Point { x: 2, y: 3 }
    let n = take_point(p)
    assert(n == 5)
    assert(p.x == 2)
    assert(p.y == 3)

fn main:
    test_copy_arg_keeps_binding()
    test_ref_param_borrows()
    test_copy_type_not_consumed()
    print("ok")
