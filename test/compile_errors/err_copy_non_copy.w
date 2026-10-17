//! expect-check-fail: 'copy' requires the type to implement Copy or Clone
// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Buffer:
    data: i32
    len: i32

impl Buffer:
    fn drop(mut self: Self):
        self.len = 0

fn callee(b: Buffer):
    let _x = b.len

fn main:
    let buf = Buffer { data: 0, len: 10 }
    callee(copy buf)   // error: Buffer has Drop, so it is non-Copy
