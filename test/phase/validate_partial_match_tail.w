//! args: --validate-all --no-prelude
//! expect-check-stdout: validate-all: ok

enum Event { Click | Key | Scroll }
global var seen: i32

fn partial(e: Event):
    match e:
        Key => seen = 5
