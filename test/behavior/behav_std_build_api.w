//! expect-stdout: ok

use std.build

fn main:
    let pkg = Package { name: "demo", version: "0.1.0" }
    var b = new_build(pkg)
    var exe = target_new(.Executable, "demo", "src/main.w")
    exe = exe.optimize(OptimizeMode.debug)
    exe = exe.link_system_lib("m")
    b = b.add_target(exe)
    assert(b.targets.len() == 1)
    let recorded = b.targets.get(0)
    assert((recorded.kind as i32) == 0)
    assert(recorded.name == "demo")
    assert(recorded.entry == "src/main.w")
    assert(recorded.optimize_mode == OptimizeMode.debug)
    assert(recorded.system_libs.len() == 1)
    assert(recorded.system_libs.get(0) == "m")
    b = b.library("demo_lib", "src/lib.w")
    assert(b.targets.len() == 2)
    assert((b.targets.get(1).kind as i32) == 1)
    print("ok")
