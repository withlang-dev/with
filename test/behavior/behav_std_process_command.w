//! expect-stdout: ok

use std.process

fn main:
    assert(command("/usr/bin/true").run() == 0)

    let eq = command("/bin/test").arg("with").arg("=").arg("with")
    assert(eq.status() == 0)

    let ne = command("/bin/test").arg("with").arg("=").arg("shell")
    assert(ne.status() != 0)

    print("ok")
