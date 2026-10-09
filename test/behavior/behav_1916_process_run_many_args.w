//! expect-stdout: child saw 300 arguments
//! expect-stdout: ok

// #1916: the runtime's POSIX spawn kept argv in a fixed 256-entry array, and
// a command with more arguments came back as -1 with nothing said (the SDK
// build's archive step of 316 objects). The program runs itself with 300
// arguments; the child counts them.
use std.process

fn main:
    let argv = args()
    if argv.len() > 1 and argv[1] == "--child":
        print(f"child saw {argv.len() - 2} arguments")
        exit_code(if argv.len() - 2 == 300: 0 else: 3)
    var cmd: List[str] = List.new()
    cmd.push(argv[0])
    cmd.push("--child")
    for i in 0..300:
        cmd.push(f"a{i}")
    let rc = run(&cmd)
    if rc == 0:
        print("ok")
    else:
        print(f"run returned {rc}")
