//! expect-stdout: ok

use std.build

fn main:
    let env = process_env().set("NAME", "value").set("OTHER", "second")
    assert(env.vars.len() == 2)
    assert(env.vars[0].name == "NAME")
    assert(env.vars[0].value == "value")
    assert(env.vars[1].name == "OTHER")
    assert(env.vars[1].value == "second")

    var named = process_env()
    named = (move named).set("NAMED", "reassigned")
    assert(named.vars[0].name == "NAMED")

    let spec = process_spec("/bin/echo")
        |> arg("hello")
        |> working_dir("/tmp")
        |> timeout(42)
        |> stdin("input.txt")
        |> env_var("MODE", "test")
        |> capture(true, false)
    assert(spec.executable == "/bin/echo")
    assert(spec.args[0] == "hello")
    assert(spec.cwd == "/tmp")
    assert(spec.timeout_ms == 42)
    assert(spec.stdin_path == "input.txt")
    assert(spec.env.vars[0].name == "MODE")
    assert(spec.capture_stdout)
    assert(not spec.capture_stderr)
    print("ok")
