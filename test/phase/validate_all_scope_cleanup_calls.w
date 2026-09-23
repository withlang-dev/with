//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #1411: a scope's cleanup calls (the thread scope's join-all and destroy,
// the async scope's await-all and destroy) had untyped destinations, so
// validate-all stopped every scope program at "ownership terminator place
// has no concrete MIR type". Each now yields its i32 status into an i32 temp.

async fn square(x: i32) -> i32:
    x * x

async fn tracked() -> i32:
    async scope s =>:
        s.track(square(3))
        s.track(square(4))
        0
    7

fn joined() -> i32:
    let a = scope s =>:
        let h = s.spawn(() => 8)
        h.join()
    a

async fn main:
    assert(joined() == 8)
    assert(tracked().await == 7)
    print("ok")
