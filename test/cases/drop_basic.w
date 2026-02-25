extern fn puts(s: *const i8) -> i32

type Resource = { value: i32 }

impl Resource
    fn drop(self: Resource) =
        puts("dropped")

fn main() -> i32 =
    let r = Resource { value: 42 }
    assert(r.value == 42)
    0
