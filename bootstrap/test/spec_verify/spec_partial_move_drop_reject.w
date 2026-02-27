// NEGATIVE: record update on Drop type should be rejected (§2.4)
// Drop types require whole-value semantics; record update does partial copy
// EXPECT: check fails with error about Drop type in record update
extern fn puts(s: *const i8) -> i32

type Resource = { value: i32, name: i32 }

impl Resource
    fn drop(self: Resource):
        puts("dropped")

fn main -> i32:
    let r = Resource { value: 10, name: 1 }
    let r2 = { r with value: 20 }
    puts("done")
