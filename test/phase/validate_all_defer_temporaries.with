//! args: --validate-all --prelude=core
//! expect-check-stdout: validate-all: ok

// The assertion message is created only on the return edge. It must not
// acquire a drop on the continuing edge, where it is uninitialized.
fn probe(early: bool):
    defer: assert(true)
    if early: return
    print("continued")

fn main:
    probe(false)
    probe(true)
