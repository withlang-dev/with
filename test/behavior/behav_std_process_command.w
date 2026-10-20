//! expect-stdout: ok

use std.process
use std.sysinfo

fn main:
    if os() == "Windows":
        // Use a real System32 executable: `where /q` exits 0 when the program
        // is found and 1 when it is not, exercising run/status/arg/PATH the
        // same way /usr/bin/true and /bin/test do on Unix. `/q` because the
        // child shares our stdout, and like `true` it must print nothing.
        assert(command("where").arg("/q").arg("cmd").run() == 0)

        let found = command("where").arg("/q").arg("cmd")
        assert(found.status() == 0)

        let missing = command("where").arg("/q").arg("with_no_such_program_xyz123")
        assert(missing.status() != 0)
    else:
        assert(command("/usr/bin/true").run() == 0)

        let eq = command("/bin/test").arg("with").arg("=").arg("with")
        assert(eq.status() == 0)

        let ne = command("/bin/test").arg("with").arg("=").arg("shell")
        assert(ne.status() != 0)

    print("ok")
