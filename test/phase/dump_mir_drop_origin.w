//! args: --dump-mir
//! expect-check-stdout: @ drop#
//! expect-check-stdout: std.drop

type Resource { id: i32 }

impl Drop for Resource:
    fn drop(move self: Self):
        let _ = self.id

fn main:
    let r = Resource { id: 7 }
    drop(r)
