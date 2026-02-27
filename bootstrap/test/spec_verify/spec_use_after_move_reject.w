// NEGATIVE: use after move should be rejected for non-Copy types (§2.2)
// Drop types are non-Copy — passing to function consumes them
// EXPECT: check fails with "use of moved value"
extern fn puts(s: *const i8) -> i32

type Resource = { value: i32 }

impl Resource
    fn drop(self: Resource):
        puts("dropped")

fn consume(r: Resource) -> i32: r.value

fn main -> i32:
    let r = Resource { value: 42 }
    let x = consume(r)
    let y = consume(r)
    println(x + y)
