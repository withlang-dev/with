//! args: --validate-all --no-prelude
//! expect-check-stdout: validate-all: ok
// #2555: std.sync names what it uses (`use std.result`), so a program
// compiled without the prelude can import it. Its Result matches read the
// prelude's `Ok`/`Err` and failed "variant pattern requires an enum subject".
use std.sync

fn main -> i32:
    let counter = Mutex.new(1)
    0
