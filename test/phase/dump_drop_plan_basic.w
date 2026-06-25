//! args: --dump-drop-plan
//! expect-check-stdout: drop-plan module
//! expect-check-stdout: action=
//! expect-check-stdout: place=

type Resource { id: i32 }

impl Drop for Resource:
    fn drop(move self: Self):
        let _ = self.id

fn consume(r: Resource):
    let _ = r.id

fn main:
    let r = Resource { id: 7 }
    consume(r)
