//! args: --dump-drop-state
//! expect-check-stdout: drop-state module
//! expect-check-stdout: _1=Moved

type Resource { id: i32 }

impl Drop for Resource:
    fn drop(move self: Self):
        let _ = self.id

fn consume(r: Resource):
    let _ = r.id

fn main:
    let r = Resource { id: 7 }
    consume(r)
