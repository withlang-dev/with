//! args: --trace-ownership main:
//! expect-check-stdout: trace-ownership main:
//! expect-check-stdout: event=
//! expect-check-stdout: after=

type Resource { id: i32 }

impl Drop for Resource:
    fn drop(move self: Self):
        let _ = self.id

fn consume(r: Resource):
    let _ = r.id

fn main:
    let r = Resource { id: 7 }
    consume(r)
