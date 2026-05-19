use std.build

fn main:
    let env = process_env().set("NAME", "value").set("OTHER", "second")
    assert(env.vars.len() == 2)
    assert(env.vars.get(0).name == "NAME")
    assert(env.vars.get(0).value == "value")
    assert(env.vars.get(1).name == "OTHER")
    assert(env.vars.get(1).value == "second")
    print("ok")
